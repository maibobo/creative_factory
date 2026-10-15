# NVMe_1.3定向学习与FPGA_DDR_SSD接口理解

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_1.3定向学习与FPGA_DDR_SSD接口理解.md`
- SHA-256: `703fe43e52d46f8c5d3db1571202139562bebbad33563bee8b55e01df60e2869`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

# NVMe 1.3 定向学习与 FPGA–DDR–SSD 接口理解

> 适用项目：XCKU040 FPGA + 外部 DDR + 第三方 NVMe Host Controller IP + PCIe Root Complex + 商用 NVMe SSD
> 当前目标：理解第三方 Host IP 的接口边界，完成 DDR→SSD→DDR 的 Write / Read / Flush 闭环；不是自行实现完整 NVMe Host Controller，也不是开发 SSD 内部 FTL/NAND 控制器。
> 文档日期：2026-07-28

---

## 1. 先回答核心问题

### 1.1 `opcode, ddr_addr, byte_len, slba, user_tag` 是不是 NVMe 与 SSD 之间的交互信号？

**不是严格意义上的“NVMe Host 与 SSD 之间的原生交互信号”。**

它们更准确地说是：

> **本项目应用逻辑 / Segment 调度器与第三方 NVMe Host IP Adapter 之间的一组高层请求字段。**

```text
ADC / Pattern / 上层控制
          │
          │ 项目级请求
          │ opcode
          │ ddr_addr
          │ byte_len
          │ slba
          │ user_tag
          ▼
NVMe Application Adapter
          │
          │ 厂商 API、Mailbox、寄存器或 RTL 命令接口
          ▼
第三方 NVMe Host Controller IP
          │
          │ 构造 SQE、CID、PRP、Doorbell
          ▼
PCIe Root Complex
          │
          │ PCIe TLP
          ▼
NVMe SSD Endpoint
```

也就是说，这 5 个字段是为了让上层不用直接理解 SQ、CQ、PRP、CID 和 PCIe TLP，而建立的一层**项目级抽象接口**。

NVMe 1.3 在 Host 与 SSD 之间真正定义的是：

```text
Controller BAR 寄存器
Admin Submission / Completion Queue
I/O Submission / Completion Queue
64 Byte SQE
16 Byte CQE
PRP / SGL
SQ Tail Doorbell
CQ Head Doorbell
MSI / MSI-X
Read / Write / Flush 等命令语义
```

在线路上实际传输的则是 PCIe 事务，例如：

```text
Memory Read Request
Completion with Data
Memory Write
Configuration Read / Write
MSI / MSI-X Memory Write
```

所以不能把项目接口中的 5 根字段直接理解成“接到 SSD 引脚上的 NVMe 信号”。

---

## 2. 三层接口必须分清

### 2.1 第一层：项目应用接口

```text
req_valid
req_ready
req_opcode
req_ddr_addr
req_byte_len
req_slba
req_user_tag

cpl_valid
cpl_ready
cpl_user_tag
cpl_status
```

职责：

- 说明要执行 Write、Read 还是 Flush；
- 指定 FPGA DDR 中的源/目标 Buffer；
- 指定有效字节长度；
- 指定 SSD Namespace 中的起始 LBA；
- 用 `user_tag` 关联项目中的 Segment、Capture 或测试事务；
- 返回项目级完成状态。

这层不应直接管理：

```text
SQ Tail
CQ Head
Phase Tag
CID Busy Bitmap
PRP List Page
PCIe TLP Tag
MSI-X Vector
```

### 2.2 第二层：NVMe Host IP 内部协议层

第三方 IP 或其 MicroBlaze 驱动通常负责：

```text
读取 CAP / VS
配置 AQA / ASQ / ACQ
设置 CC.EN
等待 CSTS.RDY
Identify Controller
Identify Namespace
创建 I/O CQ
创建 I/O SQ
分配 CID
构造 PRP1 / PRP2 / PRP List
构造 64 Byte SQE
写 SQ Tail Doorbell
轮询或中断处理 CQE
解析 Status
写 CQ Head Doorbell
```

### 2.3 第三层：PCIe 链路事务层

SSD 不会接收一组名为 `ddr_addr`、`byte_len` 的实体引脚。SSD 看到的是：

1. Host 对 SSD BAR 的 MMIO 访问；
2. SSD 从 Host Memory 读取 SQE；
3. SSD 根据 PRP 访问 Payload；
4. SSD 向 Host Memory 写 CQE；
5. 必要时产生中断。

---

## 3. 项目字段如何映射到 NVMe 1.3

| 项目字段 | NVMe 中的对应物 | 说明 |
|---|---|---|
| `opcode` | SQE CDW0.OPC | 映射到 Read、Write、Flush；Admin 与 I/O Command Set 中可能存在相同数值但属于不同队列 |
| `ddr_addr` | PRP1、PRP2、PRP List 或厂商 DMA 描述符 | 表示 FPGA DDR Buffer 地址；Host IP 可能需要先做 AXI 地址到 PCIe Bus Address 的映射 |
| `byte_len` | 由 LBA Size 换算成 SQE CDW12.NLB | `NLB = byte_len / LBA_SIZE - 1`；大于 MDTS 时可能由 IP 拆分为多条 SQE |
| `slba` | SQE CDW10、CDW11 | 64 bit Starting LBA |
| `user_tag` | 项目级上下文标识 | 通常由 Adapter 建立 `user_tag ↔ CID ↔ Segment` 映射，不等同于原生 CID |
| `cpl_status` | CQE Status Field 的归一化结果 | 项目层可简化为 0 成功、非 0 失败，同时保留原始 SCT/SC 更利于调试 |

### 3.1 `user_tag` 为什么不能直接说成 CID

NVMe 原生 CID 位于 SQE CDW0[31:16]，并在 CQE 中返回。其唯一性范围至少要结合 SQID 判断：

```text
SQID + CID
```

项目中的 `user_tag` 可能是：

```text
{generation, segment_id}
```

它用于防止：

- Segment 被重复利用后，旧 Completion 误释放新 Buffer；
- 大请求被 IP 按 MDTS 拆成多条 SQE 后，多个内部 CID 无法直接对应一个应用请求；
- 不同后端实现对 CID 的分配方式不同。

因此推荐维护：

```text
user_tag
   ↕
项目请求上下文
   ↕
一个或多个内部 CID
```

### 3.2 还缺哪些原生 NVMe 字段？

这 5 个字段只覆盖最小 Read/Write/Flush 通路。完整 NVMe 命令还可能涉及：

```text
NSID
FUA
LR
PRINFO
Metadata Pointer
SGL
Directive
DSM Hint
Queue ID / Queue Priority
Timeout
Completion 原始 SCT / SC
```

第一版可以由 Adapter 使用固定值：

```text
NSID = Identify 后选定的活动 Namespace
FUA = 0
Metadata = 不使用
Protection Information = 不使用
SGL = 不使用，采用 PRP
单 I/O SQ / CQ
```

Flush 通常不需要 Payload，因此：

```text
opcode   = FLUSH
ddr_addr = 0 或忽略
byte_len = 0 或忽略
slba     = 0 或忽略
NSID     = 指定 Namespace
user_tag = Flush 事务标签
```

---

## 4. 一条 NVMe Write 真正发生了什么

### 4.1 业务语义

```text
把 FPGA DDR 中的数据写入 SSD 的指定 LBA。
```

### 4.2 NVMe 与 PCIe 的真实过程

```text
1. ADC / Pattern Generator 把 Payload 写入 FPGA DDR_SRC
2. 项目层提交：
   opcode   = WRITE
   ddr_addr = DDR_SRC
   byte_len = LEN
   slba     = TEST_SLBA
   user_tag = TAG_W

3. NVMe Host IP：
   - 检查地址、长度和 MDTS
   - 分配一个或多个 CID
   - 生成 PRP1 / PRP2 / PRP List
   - 构造 Write SQE
   - 写入 I/O SQ
   - 推进 SQ Tail
   - 写 SQ Tail Doorbell

4. SSD 通过 PCIe Memory Read 获取 SQE

5. SSD 解析 Write SQE 后，根据 PRP：
   - 发 PCIe Memory Read Request
   - FPGA Root Complex / 地址转换逻辑访问外部 DDR
   - DDR AXI 侧出现 Read Burst
   - PCIe 返回 Completion with Data

6. SSD 接收 Payload，执行内部缓存、FTL、ECC 和 NAND 操作

7. SSD 通过 PCIe Memory Write 把 CQE 写入 Host 的 I/O CQ

8. NVMe Host IP：
   - 检查 CQ Phase
   - 读取 SQID、CID、Status
   - 找到内部请求上下文
   - 汇总为项目级 `user_tag/status`
   - 推进 CQ Head
   - 写 CQ Head Doorbell
```

### 4.3 最容易反直觉的一点

NVMe 业务上是 **Write 到 SSD**，但 Payload 的 PCIe 方向通常是：

```text
SSD 读取 FPGA DDR
```

因此执行 NVMe Write 时，ILA 中应看到：

```text
DDR AXI Read
```

而不是 DDR AXI Write。

---

## 5. 一条 NVMe Read 真正发生了什么

```text
1. 项目层提交：
   opcode   = READ
   ddr_addr = DDR_DST
   byte_len = LEN
   slba     = TEST_SLBA
   user_tag = TAG_R

2. Host IP 构造 Read SQE 和 PRP

3. SSD 获取 SQE，读取内部 NAND / Cache

4. SSD 根据 PRP 发 PCIe Memory Write

5. FPGA PCIe→AXI 映射把数据写入 DDR_DST

6. DDR AXI 侧出现 Write Burst

7. SSD 写 CQE

8. Host IP 返回项目级 Completion
```

因此执行 NVMe Read 时，ILA 中应看到：

```text
DDR AXI Write
```

Read SQE 的 Data Pointer 指向**目标 Buffer**，Write SQE 的 Data Pointer 指向**源 Buffer**。

---

## 6. NVMe 1.3 应该读哪些章节

NVMe 1.3 是一份 282 页左右的一体化规范。当前不需要顺序通读。应按“数据通路集成”目标定向阅读。

## 6.1 必读优先级总表

| 优先级 | 章节 | 页码起点 | 当前需要掌握的内容 |
|---|---|---:|---|
| A | 1.4 Theory of Operation | 6 | 建立 Host、Controller、SQ/CQ、Doorbell 的整体模型 |
| B | Chapter 3 Controller Registers | 36 | CAP、VS、CC、CSTS、AQA、ASQ、ACQ、Doorbell |
| A | 4.1 SQ/CQ Definition | 49 | 环形队列、Head/Tail、Full/Empty、Phase |
| A | 4.2 SQE Command Format | 51 | 64 Byte SQE、OPC、CID、NSID、PRP、CDW10～15 |
| A | 4.3 PRP Entry and List | 54 | DDR Buffer 如何描述给 SSD |
| B | 4.6 CQE | 62 | 16 Byte CQE、SQID、CID、Phase、SCT/SC |
| B | 5.3 Create I/O CQ | 81 | 创建 I/O CQ 的地址、QID、QSIZE、Interrupt |
| B | 5.4 Create I/O SQ | 82 | 创建 I/O SQ，关联 CQID |
| A | 5.15 Identify | 112 | Controller / Namespace 能力和 LBA Format |
| B | 5.13/5.21 Get/Set Features | 93/145 | Number of Queues、VWC 等 |
| B | 5.14 Get Log Page | 95 | Error Log、SMART/Health、温度 |
| A | 6.1 Namespaces | 173 | NSID、Namespace 与 LBA 空间 |
| B | 6.3 Command Ordering | 175 | 多命令乱序及软件顺序假设 |
| B | 6.4 Atomic Operations | 176 | 原子性与持久性的区别 |
| A | 6.8 Flush | 185 | Flush 的范围和完成含义 |
| A | 6.9 Read | 185 | SLBA、NLB、PRP、Read 数据方向 |
| A | 6.14 Write | 194 | SLBA、NLB、FUA、Write 数据方向 |
| A | 7.2 Submission/Completion | 200 | 从构造 SQE 到消费 CQE 的完整流程 |
| B | 7.3 Reset | 207 | Controller / Subsystem / Queue Reset |
| B | 7.4 Queue Management | 208 | Admin 队列和 I/O 队列创建顺序 |
| C | 7.5 Interrupts | 209 | Polling、MSI、MSI-X 的基本关系 |
| A | 7.6 Initialization/Shutdown | 212 | 完整初始化和正常关机顺序 |
| B | Chapter 10 Error Reporting | 281 | 命令错误、介质错误、Fatal 状态 |

说明：

- A：必须认真读并画流程图；
- B：结合厂商 Example Design 定向读；
- C：第一阶段知道用途即可，不必深入所有细节。

---

# 7. 各章节内容总结

## 7.1 1.4 Theory of Operation：先建立全局模型

这一节的目标不是记字段，而是理解 NVMe 的基本思想：

```text
Host 在内存中准备命令
→ 放入 Submission Queue
→ 写 Doorbell 通知 Controller
→ Controller 获取命令并执行
→ Controller 把 Completion 写入 Completion Queue
→ Host 通过 Phase / Interrupt 发现 Completion
→ Host 消费 CQE
→ 写 CQ Head Doorbell 释放 CQ Entry
```

关键认知：

1. SQ/CQ 是内存中的数据结构，不是简单的一组寄存器；
2. Doorbell 只是“指针更新通知”，不是命令本体；
3. 命令可以并发、乱序执行和乱序完成；
4. Host 必须依靠 CID 找回命令上下文；
5. 数据 Payload 不在 SQE 内，SQE 只保存数据地址描述。

与你的 UFS 经验类比：

| UFS | NVMe |
|---|---|
| UTRD / MCQ Entry | SQE |
| UTR Doorbell Slot 位 | SQ Tail Doorbell 指针 |
| Task Tag | CID |
| PRDT | PRP / SGL |
| Response UPIU / OCS | CQE Status |
| LUN | Namespace / NSID |
| SCSI LBA | NVMe SLBA / NLB |

---

## 7.2 Chapter 3：Controller Registers

### 7.2.1 CAP — Controller Capabilities

重点字段：

```text
MQES    最大队列 Entry 数减 1
CQR     队列是否要求物理连续
TO      Controller Ready 等待超时基准
DSTRD   Doorbell 间距
CSS     支持的 Command Set
MPSMIN  最小 Host Memory Page Size
MPSMAX  最大 Host Memory Page Size
```

与项目直接相关：

- `CAP.MQES` 限制 Admin / I/O Queue 深度；
- `CAP.DSTRD` 决定每个 SQ/CQ Doorbell 的地址；
- `CAP.MPSMIN/MAX` 约束 `CC.MPS`，也决定 PRP 页大小；
- `CAP.TO` 用于初始化阶段等待 `CSTS.RDY`，不等于每条 I/O 命令的 Timeout。

Doorbell 地址概念：

```text
SQyTDBL = BAR0 + 0x1000 + (2*y)     * (4 << DSTRD)
CQyHDBL = BAR0 + 0x1000 + (2*y + 1) * (4 << DSTRD)
```

### 7.2.2 VS — Version

用于确认 Controller 报告的 NVMe 版本。例如 1.3 对应：

```text
Major = 1
Minor = 3
Tertiary = 0
```

### 7.2.3 CC — Controller Configuration

重点字段：

```text
EN       Controller Enable
CSS      选择 I/O Command Set
MPS      Host Memory Page Size
AMS      Arbitration
SHN      Shutdown Notification
IOSQES   I/O SQ Entry Size
IOCQES   I/O CQ Entry Size
```

典型：

```text
IOSQES = 6  → 2^6 = 64 Byte SQE
IOCQES = 4  → 2^4 = 16 Byte CQE
```

### 7.2.4 CSTS — Controller Status

重点：

```text
RDY   Controller 是否可处理命令
CFS   Controller Fatal Status
SHST  Shutdown Status
```

常见调试：

```text
CC.EN 已置 1，但 CSTS.RDY 长期为 0：
- AQA / ASQ / ACQ 配置错误
- CC.MPS 不合法
- IOSQES / IOCQES 错误
- PCIe 地址映射错误
- Controller 初始化失败
```

### 7.2.5 AQA / ASQ / ACQ

```text
AQA：Admin SQ / CQ 的 Queue Size
ASQ：Admin Submission Queue Base Address
ACQ：Admin Completion Queue Base Address
```

这些地址是 Controller 可通过 PCIe 访问的 Host Physical / Bus Address，而不一定等于用户逻辑看到的本地 AXI 地址。

### 7.2.6 Doorbell

```text
SQ Tail Doorbell：
Host 告知 Controller：SQ Tail 已推进

CQ Head Doorbell：
Host 告知 Controller：CQE 已处理，可复用
```

不能把 Doorbell 理解成“启动脉冲”。它写入的是新的环形队列指针值。

---

## 7.3 Chapter 4：Data Structures

## 7.3.1 4.1 SQ/CQ 环形队列

所有权关系：

| 对象 | Producer | Consumer |
|---|---|---|
| Submission Queue | Host | SSD Controller |
| Completion Queue | SSD Controller | Host |
| SQ Tail | Host 管理 | 写 Doorbell 通知 SSD |
| SQ Head | SSD 内部推进 | 通过 CQE.SQHD 告知 Host |
| CQ Tail | SSD 内部管理 | Host 不直接读取 |
| CQ Head | Host 管理 | 写 Doorbell 告知 SSD |

Empty：

```text
Head == Tail
```

Full：

通常环形队列保留一个空 Slot：

```text
next(Tail) == Head
```

Queue Size 是零基编码，但应结合具体字段定义区分：

```text
QSIZE = 实际 Entry 数 - 1
```

例如：

```text
QSIZE = 7
实际 Queue Entry 数 = 8
典型最多可占用 Slot = 7
```

### 7.3.2 Phase Tag

CQ 的 Tail 是 Controller 内部状态，Host 不能直接读取。Host 通过 CQE 的 Phase Tag 判断该 Entry 是否是新完成。

```text
expected_phase 初始值
每次 CQ Wrap 后翻转
```

消费流程：

```text
CQE.P == expected_phase → 新 Completion
CQE.P != expected_phase → 暂无新 Completion
```

### 7.3.3 Entry 何时允许复用

- SQE 写完并 Doorbell 后，在被 Controller 消费前不能修改；
- CQE 被 Controller 发布后，在 Host 写 CQ Head Doorbell 消费前不能修改；
- Write 源 Buffer 在成功完成前不能被 ADC 覆盖；
- Read 目标 Buffer 在成功完成前不能被 CPU 当作有效数据读取。

---

## 7.4 4.2：64 Byte SQE

常规 SQE 由 16 个 DWORD 组成：

```text
DW0       OPC / FUSE / PSDT / CID
DW1       NSID
DW2-DW3   Reserved
DW4-DW5   MPTR
DW6-DW7   PRP1
DW8-DW9   PRP2
DW10-DW15 Command Specific
```

重点字段：

### OPC

指定命令类型。注意 Admin 命令和 NVM I/O 命令使用不同队列，Opcode 数值可能重复，不能脱离 Queue 类型解释。

### CID

```text
Command Identifier
```

同一个 SQ 中尚未完成的命令不能重复使用同一 CID。

### NSID

指定命令作用于哪个 Namespace。第一版通常固定为 Identify 后确认的活动 Namespace，例如 NSID 1，但不能在没有 Identify 的情况下盲目假定。

### PSDT

指定 Data Pointer 使用 PRP 还是 SGL。当前供应商明确推荐 AXI4-MM 外部 DDR 并自动生成 PRP List，因此第一阶段重点看 PRP。

### PRP1 / PRP2

指向 Payload Buffer 或 PRP List。

### CDW10～CDW15

由具体命令定义：

- Read/Write：SLBA、NLB、FUA、LR 等；
- Identify：CNS；
- Create Queue：QID、QSIZE、CQID、Interrupt Vector 等。

---

## 7.5 4.3：PRP

PRP 是当前 FPGA DDR 直连 NVMe 数据路径最关键的章节。

### 7.5.1 PRP 描述什么？

```text
SSD 可访问的 Host Memory Page 地址
```

不是：

```text
SSD LBA
SSD 内部 DRAM 地址
NAND Page 地址
普通软件虚拟地址
```

### 7.5.2 三种典型情况

#### 情况 A：数据只落在第一页

```text
PRP1 = 第一段数据起始地址，可带页内 Offset
PRP2 = 0
```

#### 情况 B：数据跨两页

```text
PRP1 = 第一页中的实际起始地址，可带 Offset
PRP2 = 第二页 Page Base，必须页对齐
```

#### 情况 C：数据跨两页以上

```text
PRP1 = 第一页实际起始地址
PRP2 = PRP List Page 地址
PRP List[0] = 第二个数据页
PRP List[1] = 第三个数据页
...
```

如果一个 PRP List Page 不够，最后一个 Entry 可指向下一个 PRP List Page。

### 7.5.3 页大小和 LBA 大小不是一回事

```text
PRP Page Size = 2^(12 + CC.MPS)
LBA Size      = 2^LBADS
```

可能出现：

```text
PRP Page = 4 KiB
LBA Size = 512 B
```

它们分别属于：

- Host Memory 地址描述；
- SSD Namespace 逻辑块格式。

### 7.5.4 当前供应商接口的含义

供应商已回复：

- 支持直接使用外部 DDR 数据地址；
- 支持自动生成 PRP/PRP List；
- 支持 2 TB 地址空间；
- 要求 4 KiB 对齐；
- 最大命令长度依据 MDTS 自动协商；
- 跨 4 KiB Page 自动生成 PRP List；
- PCIe Bus Address 到 AXI/DDR Address 的映射包含在 IP 内。

因此当前项目层一般不需要自行生成 PRP List，但必须理解它，才能检查：

```text
传入的 ddr_addr 属于哪个地址域
4 KiB 对齐为何必要
大请求如何跨页
为什么 Write 会触发 DDR AXI Read
为什么 Read 会触发 DDR AXI Write
```

---

## 7.6 4.6：16 Byte CQE

重点字段：

```text
DW0      Command Specific Result
DW1      Reserved
DW2      SQ Head Pointer / SQ Identifier
DW3      CID / Phase / Status
```

### SQHD

表示 Controller 生成该 CQE 时的 SQ Head 状态，可用于判断哪些 SQ Slot 已被消费；它不表示相应命令都已执行完成。

### SQID + CID

用于找到原命令上下文：

```text
outstanding_table[SQID][CID]
```

### Phase

用于判断 CQE 是否为新 Entry。

### Status

至少要保留：

```text
SCT = Status Code Type
SC  = Status Code
```

项目层只返回“0/非0”虽然简单，但调试时最好额外输出：

```text
raw_cqe
sct
sc
dnr
more
```

---

## 7.7 Chapter 5：Admin Command Set

## 7.7.1 Create I/O Completion Queue

先建 CQ，再建 SQ，因为 SQ 需要指定关联的 CQID。

关键字段：

```text
PRP1   CQ 内存地址
QID    Queue Identifier
QSIZE  Queue Size，零基编码
IV     Interrupt Vector
IEN    是否使能中断
PC     是否物理连续
```

### 7.7.2 Create I/O Submission Queue

关键字段：

```text
PRP1   SQ 内存地址
QID    SQ ID
QSIZE  Queue Size
CQID   关联的 Completion Queue
QPRIO  Queue Priority
PC     是否物理连续
```

第一版推荐：

```text
Admin SQ/CQ：1 对
I/O SQ/CQ：1 对
Queue Depth：2～8 起步
Polling CQ：优先
```

先用小 Queue Depth 方便波形观察，再做性能测试。

---

## 7.8 5.15 Identify

Identify 返回 4096 Byte 数据结构。

## 7.8.1 Identify Controller 必看字段

建议至少记录：

```text
VID / SSVID       Vendor
SN                Serial Number
MN                Model Number
FR                Firmware Revision
MDTS              Maximum Data Transfer Size
CNTLID            Controller ID
VER               NVMe Version
OACS              Optional Admin Command Support
ACL               Abort Command Limit
AERL              Async Event Request Limit
LPA               Log Page Attributes
SQES              SQ Entry Size
CQES              CQ Entry Size
NN                Namespace 数量
ONCS              Optional NVM Command Support
VWC               Volatile Write Cache
AWUN / AWUPF      Atomic Write Unit
SGLS              SGL Support
```

### MDTS 换算

MDTS 不是直接的字节数，通常结合最小 Memory Page Size：

```text
MAX_TRANSFER = 2^MDTS × 2^(12 + CAP.MPSMIN)
```

但供应商 IP 可能在内部完成 MDTS 协商和拆分，因此上层仍要问清：

- API 最大 `byte_len`；
- IP 是拒绝超限，还是拆成多条 SQE；
- 大请求只返回一个 Completion 还是多个；
- 出错时如何汇总状态。

## 7.8.2 Identify Namespace 必看字段

```text
NSZE     Namespace 总 LBA 数
NCAP     可用容量
NUSE     已使用容量
NLBAF    LBA Format 数量
FLBAS    当前使用的 LBA Format
LBAF[n]  MS / LBADS / RP
DPC/DPS  Protection Information
NAWUN
NAWUPF
NGUID / EUI64
```

### LBA Size

```text
LBA_SIZE = 2^LBADS Byte
```

示例：

```text
LBADS = 9   → 512 Byte
LBADS = 12  → 4096 Byte
```

不要把供应商示例中的 512 Byte 当成所有 SSD 的固定值，必须读取 Identify Namespace。

---

## 7.9 Get / Set Features 与 Get Log Page

当前最有用的 Feature：

```text
Number of Queues
Volatile Write Cache
Interrupt Coalescing
Interrupt Vector Configuration
Write Atomicity Normal
```

当前最有用的 Log Page：

```text
Error Information Log
SMART / Health Information
Firmware Slot Information
```

长稳测试应至少记录：

```text
Composite Temperature
Available Spare
Percentage Used
Data Units Read / Written
Power Cycles
Power On Hours
Unsafe Shutdowns
Media and Data Integrity Errors
Error Information Log Entries
```

供应商回复中提到可通过 Get Log Page 读取 SSD 温度，也会在 ECQE FIFO 中提供 CQE Error。

---

## 7.10 Chapter 6：NVM Command Set

## 7.10.1 Namespace 和 LBA

```text
NVMe Controller
└─ Namespace
   └─ LBA 0 ... LBA NSZE-1
```

`SLBA` 是第一个逻辑块地址。

`NLB` 是零基编码：

```text
实际逻辑块数 = NLB + 1
传输字节数   = (NLB + 1) × LBA_SIZE
```

合法性：

```text
byte_len > 0
byte_len % LBA_SIZE == 0
SLBA + NLB < NSZE
```

示例一：512 B LBA，长度 4 KiB

```text
block_count = 4096 / 512 = 8
NLB         = 8 - 1 = 7
```

示例二：4 KiB LBA，长度 256 KiB

```text
block_count = 256 KiB / 4 KiB = 64
NLB         = 64 - 1 = 63
```

### 注意：项目要求 4 KiB 对齐不等于 SSD LBA 一定为 4 KiB

供应商的 4 KiB 对齐要求主要可能来自：

- PRP 页对齐；
- IP 内部 DMA 设计；
- 地址转换和性能约束。

Namespace 的 LBA Size 仍须 Identify 确认。

---

## 7.10.2 6.8 Flush

Flush 的语义：

> 将指定 Namespace 中，在 Flush 提交之前已经完成的相关数据和元数据提交到非易失介质。

关键点：

1. Flush 是独立 I/O 命令，也会产生自己的 CQE；
2. 不能只检查 Write CQE，还要等待 Flush CQE；
3. Flush 不带 Payload，命令专有字段基本保留；
4. Flush 的范围是此前完成的命令，不是任意尚未完成的 Write；
5. Flush 会影响吞吐和尾延迟，不应每个大 Segment 都无脑执行。

当前项目建议：

```text
连续 Payload WRITE
→ Flush #1
→ Commit Metadata WRITE
→ Flush #2
→ capture_done
```

供应商 IP 支持 Flush、不支持 Write FUA，自测性能是在 SSD Cache 开启且未执行 Flush 的条件下得到。因此性能基线和持久化基线必须分开测试。

---

## 7.10.3 6.9 Read

核心字段：

```text
DPTR      目标 Host Buffer
SLBA      CDW10 / CDW11
NLB       CDW12[15:0]，零基
FUA       CDW12[30]
LR        CDW12[31]
PRINFO    可选
```

数据方向：

```text
SSD → FPGA DDR
```

PCIe 方向：

```text
SSD 发 Memory Write
```

项目 Adapter 检查：

```text
DDR_DST 地址合法
byte_len 是 LBA Size 整数倍
目标 Buffer 未被其它模块占用
SLBA 范围合法
命令完成后再比较 DDR
```

---

## 7.10.4 6.14 Write

核心字段：

```text
DPTR      源 Host Buffer
SLBA      CDW10 / CDW11
NLB       CDW12[15:0]
FUA       CDW12[30]
LR        CDW12[31]
```

数据方向：

```text
FPGA DDR → SSD
```

PCIe 方向：

```text
SSD 发 Memory Read
```

### FUA

FUA=1 要求命令报告成功前将数据提交到非易失介质。

但供应商明确回复当前 IP 不支持 FUA，因此本项目持久化应依赖：

```text
Write Completion
→ Flush
→ Flush Completion
```

---

## 7.10.5 6.3 Command Ordering

除规范明确规定的情况外，不能假定多个命令按提交顺序执行或完成。

所以必须区分：

```text
提交顺序
执行顺序
Completion 顺序
持久化顺序
```

第一版项目层只允许一个大请求在途，可以显著简化：

- CID；
- Completion 乱序；
- Buffer 生命周期；
- Flush 顺序；
- 错误恢复。

第三方 IP 内部仍可能把大请求拆成多个 SQE 并流水执行。

---

## 7.10.6 6.4 Atomic Operations

必须区分四个概念：

| 概念 | 含义 |
|---|---|
| Completion | Controller 报告命令结果 |
| Atomicity | 失败或并发时不会出现部分旧、部分新的可见结果 |
| Persistence | 掉电后数据仍然存在 |
| Ordering | 多条命令之间的先后可见关系 |

相关字段：

```text
AWUN / AWUPF
NAWUN / NAWUPF
NABSN / NABO / NABSPF
```

大块采集数据不能假设整个 256 KiB 或 1 MiB Write 是原子的。更稳妥的盘上格式是：

```text
Payload
+ CRC
+ Sequence
+ 小的 Commit Metadata
```

---

## 7.11 Chapter 7：Controller Architecture

## 7.11.1 7.2 Command Submission and Completion

完整流程：

```text
1. 检查 SQ 不满
2. 分配 CID
3. 准备 Payload / Read Buffer
4. 生成 PRP List
5. 构造 SQE
6. 确保 Payload、PRP、SQE 对 SSD 可见
7. 推进 SQ Tail
8. 写 SQ Tail Doorbell
9. SSD 获取并执行命令
10. SSD 写 CQE
11. 可选产生 MSI / MSI-X
12. Host 检查 Phase
13. 用 SQID + CID 找到上下文
14. 检查 Status
15. 释放或冻结 Buffer
16. 推进 CQ Head
17. 写 CQ Head Doorbell
```

### Doorbell 前的数据可见性

顺序必须是：

```text
DDR Payload 完成
→ PRP List 完成
→ SQE 完成
→ 内存屏障 / AXI 写响应确认
→ 最后写 Doorbell
```

不能先 Doorbell，再补写 SQE 或 PRP。

---

## 7.11.2 7.6 Initialization

规范推荐的顺序可以简化为：

```text
1. PCIe Link Training 与枚举
2. 配置 PCI / PCIe 寄存器和初始中断
3. 等待 CSTS.RDY = 0，确认旧 Reset 完成
4. 配置 AQA / ASQ / ACQ
5. 配置 CC.AMS / CC.MPS / CC.CSS / Entry Size
6. 设置 CC.EN = 1
7. 等待 CSTS.RDY = 1
8. Identify Controller
9. Identify Namespace
10. Set Features(Number of Queues)
11. 创建 I/O Completion Queue
12. 创建 I/O Submission Queue
13. 配置需要的 MSI / MSI-X / Async Event
14. 开始提交 Read / Write / Flush
```

现场调试应把以下状态打印或接 ILA：

```text
pcie_link_up
configure_finished
CSTS.RDY
CSTS.CFS
Identify Controller status
Identify Namespace status
I/O CQ create status
I/O SQ create status
nvme_init_done
```

---

## 7.11.3 7.3 Reset 与异常恢复

需要区分：

```text
PCIe Link Reset / Retrain
Controller Reset：CC.EN 1→0→1
NVM Subsystem Reset
Queue Delete / Recreate
板级复位
SSD 掉电重启
```

当前供应商回复“不支持异常恢复”，因此这是集成风险。第一版项目应采取保守策略：

```text
命令超时 / Link Down / Tag 错误 / CQE Error
→ 禁止新 Capture
→ 冻结 INFLIGHT / ERROR_HOLD Segment
→ 不自动覆盖原数据
→ 由 MicroBlaze 或系统控制执行厂商定义的重新初始化
→ 无可靠恢复流程时执行系统级复位
```

---

## 7.12 Chapter 10：Error Reporting and Recovery

需要建立分层错误观：

### PCIe 层

```text
Link Down
Malformed TLP
Unsupported Request
Replay / AER
Completion Timeout
```

### NVMe Controller 层

```text
CSTS.CFS
Controller Reset
Queue 创建失败
Invalid Field
Invalid Namespace
PRP Offset Invalid
```

### I/O Command 层

```text
CQE SCT / SC
Media Error
Read Only Range
LBA Out of Range
Data Transfer Error
Abort
```

### 项目层

```text
Command Timeout
user_tag 不匹配
Segment 状态非法
DDR AXI BRESP/RRESP 错误
CRC mismatch
FIFO overflow
```

不能把所有错误都压成一个 `error=1`，建议至少保留：

```text
error_layer
raw_cqe_status
pcie_status
nvme_status
ddr_axi_status
project_error_code
first_error_timestamp
first_error_tag
```

---

# 8. 当前可以暂缓的章节

第一阶段不用深入：

```text
Chapter 8 大部分高级 Feature
Reservations
Virtualization Enhancements
Host Memory Buffer
RPMB
Boot Partition
Telemetry
Sanitize
Namespace Management
Streams Directives
Security Send / Receive
Firmware Update
End-to-end Protection Information
SGL 复杂类型
```

但以下内容在后续长期运行和产品化阶段应补：

```text
SMART / Health Log
Error Log
Controller Reset
正常 Shutdown
Atomicity
VWC / Flush
温度和降速
```

---

# 9. 结合当前项目的最小阅读路线

## 第 1 阶段：2～3 小时，建立完整图

阅读：

```text
1.4
3.1 寄存器总表
4.1
4.2
4.3
4.6
7.2
```

输出：

1. 一张 SQ/CQ 所有权图；
2. 一张 Write / Read PCIe 数据方向图；
3. 一张 PRP1 / PRP2 / PRP List 三情况图；
4. 一张 `user_tag ↔ CID ↔ Segment` 映射图。

## 第 2 阶段：2～3 小时，理解初始化

阅读：

```text
3.1 CAP / CC / CSTS / AQA / ASQ / ACQ / Doorbell
5.3
5.4
5.15
7.4
7.6
```

输出：

1. 初始化伪代码；
2. Identify Controller / Namespace 字段表；
3. Queue 地址和 Queue Depth 表；
4. Doorbell 地址计算表。

## 第 3 阶段：2 小时，理解数据命令

阅读：

```text
6.1
6.3
6.4
6.8
6.9
6.14
```

输出：

1. `byte_len → NLB` 换算函数；
2. 4 KiB / 256 KiB Write SQE 示例；
3. Flush 与 FUA 的差异表；
4. Write 后 Read 回闭环流程。

## 第 4 阶段：结合厂商工程

重点不再是继续读规范，而是查清：

```text
1. `ddr_addr` 是本地 AXI 地址、PCIe Bus Address，还是 IP 内部 Offset？
2. 地址高位如何配置？
3. 4 KiB 对齐是硬限制还是 Demo 限制？
4. IP 如何生成 PRP List？
5. 单个项目请求最多拆成多少 SQE？
6. `user_tag` 是否透传；内部 CID 如何分配？
7. Completion 是逐 SQE 返回还是大请求聚合返回？
8. Write Completion 与 DDR 读取结束之间是什么关系？
9. Read Completion 与 DDR 写响应全部完成之间是什么关系？
10. Flush 的 NSID、提交和完成 API 是什么？
11. Error CQE 从哪里读取？
12. Timeout 和 Reset 如何处理？
```

---

# 10. 推荐的项目接口定义

```systemverilog
typedef enum logic [1:0] {
    NVME_REQ_WRITE = 2'd0,
    NVME_REQ_READ  = 2'd1,
    NVME_REQ_FLUSH = 2'd2
} nvme_req_opcode_e;

typedef struct packed {
    nvme_req_opcode_e opcode;
    logic [63:0]      ddr_addr;
    logic [31:0]      byte_len;
    logic [63:0]      slba;
    logic [31:0]      nsid;
    logic [15:0]      user_tag;
    logic             fua;
} nvme_app_req_t;

typedef struct packed {
    logic [15:0] user_tag;
    logic [15:0] status;
    logic [2:0]  sct;
    logic [7:0]  sc;
    logic [31:0] completed_bytes;
} nvme_app_cpl_t;
```

第一版厂商不支持 FUA，可以固定：

```text
fua = 0
```

但保留该字段有利于接口长期稳定。

请求握手规则：

```text
req_valid && !req_ready：
opcode / ddr_addr / byte_len / slba / nsid / user_tag 必须保持稳定
```

完成规则：

```text
cpl_valid && cpl_ready：
才算项目层接收 Completion
```

---

# 11. 上板最小测试建议

## 11.1 基础参数

```text
单 Namespace
单 I/O SQ / CQ
Queue Depth = 2～8
单项目请求在途
DDR_SRC / DDR_DST 均 4 KiB 对齐
LEN 从 4 KiB 开始
TEST_SLBA 使用专用安全区域
```

禁止直接在带重要数据的 SSD 上覆盖 LBA 0。

## 11.2 递进长度

```text
4 KiB
8 KiB
64 KiB
256 KiB
512 KiB
1 MiB
跨 MDTS 的大请求
```

每一档检查：

```text
Write CQE
Flush CQE
Read CQE
逐字节比较
CRC32C
PRP 页数
拆分 SQE 数
最低带宽
最长停顿
```

## 11.3 ILA / 日志信号

应用层：

```text
req_valid / ready
opcode
ddr_addr
byte_len
slba
user_tag
cpl_valid
cpl_status
```

NVMe 层：

```text
nvme_init_done
SQID
SQ Tail
CQ Head
CID
PRP1
PRP2
PRP List 地址
CQ Phase
CQE SCT / SC
Flush state
```

DDR 层：

```text
AXI ARADDR / ARLEN / ARVALID / ARREADY
AXI RVALID / RREADY / RLAST
AXI AWADDR / AWLEN / AWVALID / AWREADY
AXI WVALID / WREADY / WLAST
AXI BRESP / RRESP
```

PCIe 层：

```text
link_up
negotiated_speed
negotiated_width
Memory Read Request
Memory Write
Completion with Data
AER / error
```

核心判据：

```text
NVMe Write → DDR AXI Read
NVMe Read  → DDR AXI Write
```

---

# 12. 最终结论

`opcode, ddr_addr, byte_len, slba, user_tag` 应理解为：

> **项目层向 NVMe Host IP 提交一次块 I/O 请求所需的最小语义集合。**

它们不是 SSD 物理接口，也不是完整 SQE，更不是 PCIe TLP 信号。

其转换关系是：

```text
项目请求字段
→ Adapter 检查和上下文管理
→ CID / PRP / SQE / Doorbell
→ PCIe TLP
→ SSD NVMe Controller
→ CQE
→ CID 关联
→ 项目 user_tag / status
```

你当前最需要深入掌握的是：

```text
Controller Registers
SQ/CQ
SQE/CQE
Doorbell
CID
PRP
Identify
Create I/O Queue
Read
Write
Flush
Controller Initialization
```

而不是：

```text
SSD 内部 FTL
NAND Page / Block 时序
完整 PCIe PHY
完整 TLP Parser
NVMe 所有可选特性
```

---

# 13. 资料依据与边界

本总结基于：

1. NVM Express Revision 1.3，2017-05-01，官方规范；
2. 当前项目的 `ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md`；
3. `NVME 测评答疑_2026_7_25.docx` 中的供应商回复；
4. `NVMe-SSD数字逻辑开发与FPGA集成_完整会话记录.md`；
5. `NVMe_LBA_SQ_CQ_Doorbell_CID_讨论整理.md`；
6. `NVMe协议研究报告.doc`。

需要注意：

- 项目级 `user_tag` 是自研抽象，不是 NVMe 1.3 规定的原生字段；
- 厂商实际寄存器、Mailbox/API、地址映射和 Completion 聚合方式必须以交付工程为准；
- 供应商当前回复“不支持异常恢复”，因此 Reset、Timeout 和 Link Down 的真实处理仍需现场或源码确认；
- 仿真 Stub 通过不能等同于真实 SSD 通路完成。
