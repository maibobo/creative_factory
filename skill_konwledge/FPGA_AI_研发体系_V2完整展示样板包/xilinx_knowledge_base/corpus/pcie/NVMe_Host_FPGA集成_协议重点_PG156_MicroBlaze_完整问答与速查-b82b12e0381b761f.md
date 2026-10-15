# NVMe_Host_FPGA集成_协议重点_PG156_MicroBlaze_完整问答与速查

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_Host_FPGA集成_协议重点_PG156_MicroBlaze_完整问答与速查.md`
- SHA-256: `b82b12e0381b761f17365f11bbcd37cbd94bb12d7535787a9739247d0e4bbf4e`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

# NVMe Host FPGA 集成速查与协议补充
## ——汇总本轮全部问题、详细解析、NVMe 1.3 / PG156 / MicroBlaze 重点章节，以及“看完后应回答的问题”标准答案

**适用项目**

- FPGA：Xilinx Kintex UltraScale XCKU040
- 工具基线：Vivado / Vitis 2020.2
- 设备角色：FPGA 作为 PCIe Root Complex / NVMe Host，商用 NVMe SSD 作为 PCIe Endpoint
- 数据通路：ADC → FPGA DDR → 第三方 NVMe Host IP → PCIe → SSD
- 当前目标：不自行实现完整 NVMe/PCIe 协议，在第三方 IP 到位前建立正确的架构、接口和验证判断能力
- 文档性质：学习速查、协议补充、供应商源码阅读指南、现场验收检查表
- 更新时间：2026-07-28

---

# 0. 先看这一页：当前最重要的结论

## 0.1 当前采用什么规范

当前以 **NVM Express Revision 1.3 / 1.3d 系列**作为实现和阅读基线。

供应商正式自测报告明确标注：

```text
NVMe Host Controller：NOPHAE V4.5
FPGA：XCKU040
CPU：MicroBlaze
PCIe：Gen3 x4
SSD：Samsung 980 PRO 1TB
NVMe：1.3
```

因此当前不要以 NVMe 2.x 的拆分规范作为主线。NVMe 2.x 可用于以后系统学习，但供应商源码、寄存器行为、命令流程和测试口径首先应与 1.3 对齐。

推荐主文档：

- NVM Express Revision 1.3 官方 PDF
  https://nvmexpress.org/wp-content/uploads/NVM_Express_Revision_1.3.pdf
- NVM Express 历史规范入口
  https://nvmexpress.org/nvm-express-specification-archives/
- 当前 NVMe 规范入口，用于了解后续版本结构
  https://nvmexpress.org/specifications/

网上即使能找到中文翻译，也只能辅助理解；所有位域、偏移、零基编码、`shall/should/may`、状态码和对齐要求，应以英文原文为准。

## 0.2 当前还要不要深入 PG194

**暂时不需要。**

供应商答疑已经确认：

```text
外部 DDR 可直接作为 NVMe Read/Write Buffer
用户侧采用 AXI4-MM
IP 自动生成 PRP / PRP List
PCIe Memory Read/Write 经 PCIe Hard IP 和 NVMe IP 转换为 AXI
PCIe Bus Address 到 AXI/DDR Address 的映射包含在 IP 内
不需要用户额外实现 PCIe-to-AXI Bridge 或 AXI-Stream DataMover
```

所以 PG194 目前只需理解：

```text
PCIe请求 ↔ AXI4事务
AXI地址 ↔ PCIe地址
```

不用研究其全部 BAR Translation 寄存器和 Bridge 配置。

## 0.3 PG156 看到什么程度

PG156 要看，但目的是：

1. 看懂第三方 NVMe IP 与 PCIe Hard IP 的边界；
2. 理解 SSD 对 FPGA DDR 的真实 PCIe 事务方向；
3. 根据 ILA / RTL 判断事务卡在 RQ、RC、CQ、CC、AXI DDR 还是上层 NVMe；
4. 理解 Root Port Link、枚举、BAR、Bus Master、复位和错误状态。

不要求你自行实现：

```text
完整TLP解析
Requester Tag引擎
Split Completion引擎
Flow Control Credit引擎
LTSSM
Replay
物理层均衡
```

## 0.4 当前精力分配

在还没有拿到完整 Demo 源码时：

```text
NVMe 1.3 最小协议与命令流程       50%
PG156 Root Port和RQ/RC/CQ/CC     25%
MicroBlaze/Vitis应用阅读能力      15%
项目架构、验证和供应商资料整理     10%
```

拿到供应商工程后应迅速调整为：

```text
供应商main.c/API/寄存器/RTL       50%
NVMe规范对照                     25%
PG156底层定位                    15%
MicroBlaze/Vitis操作              10%
```

## 0.5 你现在只需要牢记三条主路径

### NVMe Write：把 FPGA DDR 数据写入 SSD

```text
ADC/Pattern 写 FPGA DDR
→ Host 提交 NVMe Write SQE
→ SSD 读取 SQE 和 PRP
→ SSD 发 PCIe Memory Read
→ PG156 CQ 接收请求
→ NVMe IP 发 AXI Read 读取 FPGA DDR
→ PG156 CC 返回 Completion with Data
→ SSD 写入目标 LBA
→ SSD 把 NVMe CQE 写入 FPGA Host Memory
```

**所以 NVMe Write 在 FPGA DDR 侧表现为读。**

### NVMe Read：把 SSD 数据读到 FPGA DDR

```text
Host 提交 NVMe Read SQE
→ SSD 读取 SQE 和 PRP
→ SSD 从内部介质取数据
→ SSD 发 PCIe Memory Write + Payload
→ PG156 CQ 接收请求和数据
→ NVMe IP 发 AXI Write 写 FPGA DDR
→ SSD 把 NVMe CQE 写入 FPGA Host Memory
```

**所以 NVMe Read 在 FPGA DDR 侧表现为写。**

### Host 访问 SSD BAR / Doorbell

```text
MicroBlaze或NVMe Host逻辑
→ PG156 RQ 发 Memory Read/Write
→ SSD BAR寄存器
→ 读请求的返回结果从PG156 RC回来
```

---

# 1. 本轮全部问题与直接结论

## 问题 1：从 UFS 控制器设计转到 NVMe，哪些能力可以迁移

### 结论

你已有的 UFS 3.x 控制器经验可以大量迁移：

| UFS | NVMe | 可迁移能力 |
|---|---|---|
| UTRD / UTP Transfer Request | SQE | 命令描述符构造 |
| UTR List / MCQ | Submission Queue | 环形队列管理 |
| Response UPIU / OCS | CQE Status | 完成状态解析 |
| UTR Doorbell 位图 | SQ Tail Doorbell | 命令发布 |
| Task Tag | CID | 命令上下文关联 |
| PRDT | PRP / SGL | Host Buffer 描述 |
| LUN | Namespace / NSID | 逻辑设备选择 |
| SCSI LBA | SLBA / NLB | 块地址 |
| DMA Buffer | Host Memory Buffer | 数据所有权和生命周期 |
| UFS Reset / Error | NVMe Reset / CQE / PCIe Error | 分层恢复 |

真正新增的重点不是“存储控制器概念”，而是：

```text
PCIe Root Complex
PCIe枚举、BAR和Bus Master
SSD作为PCIe Bus Master访问FPGA DDR
SQ/CQ环形指针和Phase Tag
PRP/PRP List
NVMe寄存器初始化
```

## 问题 2：1～2 天内最应该先看什么，PCIe细节能否暂缓

### 结论

可以暂缓和应用工程无直接关系的 PCIe 细节。

当前顺序是：

```text
NVMe最小控制流程
→ SQ/CQ、PRP、Read/Write/Flush
→ PG156 Root Port与四个事务接口
→ MicroBlaze Demo主流程
→ 自己的DDR Segment与通用请求接口
```

暂缓：

```text
DLLP编码
Replay Buffer细节
全部LTSSM跳转
Gen3均衡算法
Flow Control Credit更新协议
ECRC
SR-IOV
ATS/PASID/PRI
Atomic TLP
完整PCIe一致性测试
```

## 问题 3：应该看 NVMe 哪个版本，有没有中文版

### 结论

- 主读：**NVM Express Revision 1.3**；若有 1.3d 维护版，也可作为 1.3 系列的勘误整合参考。
- 原因：供应商自测明确采用 NVMe 1.3。
- 暂时不以 2.x 为主线。
- 没有找到官方完整中文版。
- 中文资料只用于理解，位域和实现以英文规范为准。

## 问题 4：PG194 还需要看吗

### 结论

当前只需 30～60 分钟理解其核心概念：

```text
AXI Master/Slave事务与PCIe TLP互转
AXI→PCIe地址映射
PCIe→AXI地址映射
```

只有以下情况才深入：

1. 供应商 Block Design 明确例化 `AXI Bridge for PCI Express Gen3`；
2. 供应商要求你配置 PCIe→AXI 地址窗口；
3. PRP 地址不能直接映射到项目 DDR；
4. SSD 请求已进入 PCIe，但没有进入 DDR AXI；
5. 你决定绕开供应商桥接部分自行搭建 Root Port。

## 问题 5：什么是 MicroBlaze 软件测试程序

### 结论

它是运行在 FPGA 内部 MicroBlaze 软核上的 **裸机 C 程序**，用于：

```text
等待DDR和PCIe
初始化PCIe/NVMe
Identify Controller/Namespace
创建Admin和IO Queue
配置测试DDR地址、长度、SLBA和方向
提交Write/Read/Flush
等待完成
读取错误状态
比较DDR数据
UART打印PASS/FAIL和性能
```

它不是：

```text
SystemVerilog testbench
Windows/Linux主机程序
实时搬运ADC数据的软件
NVMe协议硬件本身
```

正式数据面不应经过 MicroBlaze memcpy。项目 V2 的正确边界是：

```text
MicroBlaze：提交描述符、初始化、错误和恢复
RTL/IP：直接访问DDR Payload
```

## 问题 6：要不要详细看 PG156 的 Completer Request Interface Port Description

### 结论

要看，但学习比例应为：

```text
端口表和Sideband：约20%
Operation、Descriptor和时序：约80%
```

必须认识：

```text
m_axis_cq_tdata
m_axis_cq_tkeep
m_axis_cq_tvalid
m_axis_cq_tready
m_axis_cq_tlast
m_axis_cq_tuser
```

但不需要背全部 `tuser` 位域。重点理解：

```text
valid && ready 才传输
valid=1而ready=0时，data/keep/last/user必须保持稳定
Memory Read只有Descriptor，无Payload
Memory Write带Descriptor和Payload
```

## 问题 7：4～5 天现场测试是否够

### 结论

**5 个完整工作日较稳妥。**

足够完成：

```text
供应商原始Demo复现
PCIe Link/枚举/NVMe初始化
固定DDR Buffer Write/Read/Compare
验证外部DDR直接作为Payload
参数修改
初步连续写
错误状态读取
工程和源码交接
```

不够完成：

```text
正式产品级ADC全链路
完整异常恢复
满盘/温度/掉电长期验证
多SSD兼容性认证
系统级文件管理
```

---

# 2. 当前供应商 IP 已知事实、限制与需要警惕的口径

以下内容来自供应商自测、答疑和当前项目设计资料。

## 2.1 已确认的积极结论

```text
外部DDR可以直接作为NVMe数据Buffer
用户侧采用AXI4-MM
IP自动生成PRP/PRP List
支持2TB访问空间
供应商API要求4KiB对齐
最大命令长度依据MDTS协商
跨4KiB Page自动生成PRP List
PCIe请求到AXI事务及地址映射由IP内部完成
不需要额外AXI-Stream DataMover
提供MicroBlaze裸机Demo和驱动源码
支持DDR地址+长度+起始LBA的异步Read/Write
支持Flush
不支持FUA
```

## 2.2 自测性能口径

正式报告给出的平台和结果：

```text
XCKU040
MicroBlaze
PCIe Gen3 x4
Samsung 980 PRO 1TB
NVMe 1.3
```

顺序传输：

```text
应用一次提交1GB DMA请求
IP按MDTS拆分为多条SQE
MDTS=7时单条SQE为512KiB
顺序写约3313 MiB/s
顺序读约3368 MiB/s
```

随机测试：

```text
4KiB
内部BIST生成
Q1D2与Q8D8
最高随机写约764K IOPS
最高随机读约752K IOPS
```

注意：

> “1GB 单次 I/O”在供应商答疑中更准确地理解为上层一次提交的 DMA 大请求，不是一个 NVMe SQE 传输 1GB；IP 会依据 MDTS 拆为 512KiB 等多条 SQE。

## 2.3 当前硬限制

```text
应用层并发度目前为1
单Namespace
Flush支持，FUA不支持
不支持异常恢复
无NVMe Command Timeout机制
PCIe Replay状态IP不感知
CQE错误写入ECQE FIFO供用户读取
用户接口当前125MHz，最高频率未验证
长期测试没有记录最低1秒带宽和最长停顿
```

## 2.4 两个容易误解的地方

### “稳定性测试无 Command Timeout”不等于“实现了 Timeout”

报告说 64GiB 测试中没有观察到 Command Timeout；答疑又明确说 IP 没有 NVMe Timeout 机制。

正确理解：

```text
该次测试过程未出现可见卡死
≠
IP内部有定时检测、终止和恢复机制
```

所以项目层必须自己增加：

```text
command_age
timeout_sticky
冻结INFLIGHT Segment
停止新Capture/新命令
MicroBlaze执行Reset/重初始化
```

### “4KiB 对齐”不完全等于 NVMe 协议只允许4KiB对齐

NVMe PRP1 在协议上允许带第一页内偏移；但供应商 API 可能为了简化硬件，要求 Buffer 地址和长度按 4KiB 对齐。

工程实施时应遵守供应商限制：

```text
req_ddr_addr % 4096 == 0
req_byte_len % 4096 == 0
```

同时知道这属于该 IP/API 的约束，不是所有 NVMe Host 的普遍硬性要求。

---

# 3. NVMe 1.3 重点章节速读与直接讲解

以下页码以官方 **NVM Express Revision 1.3，282页 PDF** 为基准。PDF 阅读器显示页和规范印刷页可能相差 1。

## 3.1 阅读地图

| 优先级 | 章节 | 规范页 | 你需要得到什么 |
|---|---|---:|---|
| A | 1.4 Theory of Operation | 6 | 全局流程 |
| A | 3 Controller Registers | 36 | CAP/CC/CSTS/AQA/ASQ/ACQ/Doorbell |
| A | 4.1 SQ/CQ Definition | 49 | 队列所有权、Head/Tail、Full/Empty |
| A | 4.2 SQE Command Format | 51 | 64B SQE、CID、NSID、PRP、CDW |
| A | 4.3 PRP Entry and List | 54 | Payload页描述 |
| A | 4.6 CQE | 61～64 | CID、SQID、SQHD、Phase、Status |
| A | 7.2 Submission/Completion | 200～202 | 命令完整生命周期 |
| A | 7.6 Initialization | 212 | 初始化状态机 |
| B | 5.3 Create I/O CQ | 80～82 | 创建完成队列 |
| B | 5.4 Create I/O SQ | 82～84 | 创建提交队列 |
| B | 5.15 Identify | 112起 | 控制器/Namespace能力 |
| B | 5.21 Set Features | 145起 | Number of Queues等 |
| B | 5.21.1.7 Number of Queues | 151 | 请求队列数量 |
| B | 6.1 Namespaces | 173 | NSID、LBA Format |
| B | 6.8 Flush | 185 | 写缓存持久化 |
| B | 6.9 Read | 185起 | SSD→DDR |
| B | 6.14 Write | 194起 | DDR→SSD |
| C | 5.14 Get Log Page | 95起 | Error/SMART/温度 |
| C | 7.3 Resets | 207 | Reset边界 |
| C | 7.4 Queue Management | 208 | 队列创建顺序 |
| C | 10 Error Reporting/Recovery | 后部 | 规范错误模型 |

## 3.2 Theory of Operation：一条命令到底怎样跑

```text
Host分配CID和Buffer
→ 准备Payload或目标Buffer
→ 准备PRP/PRP List
→ 构造SQE
→ 写入SQ内存
→ 保证前述内容对SSD可见
→ 写SQ Tail Doorbell
→ SSD获取SQE
→ SSD依据PRP访问Host Memory
→ SSD执行命令
→ SSD写CQE
→ Host检查CQE Phase
→ 按SQID+CID找到上下文
→ 处理状态
→ 写CQ Head Doorbell
→ 释放Buffer/PRP/CID
```

UFS 类比：

```text
UTRD/PRDT准备
→ UTR Doorbell
→ UFSHCI执行
→ OCS/Response完成
```

NVMe 的区别是 Doorbell 推进的是队列指针，而不是单纯的 Slot bit。

## 3.3 Controller Registers：初始化所需寄存器

### CAP

```text
MQES     最大队列Entry数，0-based
CQR      是否要求队列物理连续
TO       Controller Ready切换超时
DSTRD    Doorbell间距
CSS      支持的Command Set
MPSMIN   最小Host Memory Page Size
MPSMAX   最大Host Memory Page Size
```

### CC

```text
EN       Controller Enable
CSS      选择NVM Command Set
MPS      Host Memory Page Size
AMS      仲裁方式
IOSQES   I/O SQE大小编码，常用6表示64B
IOCQES   I/O CQE大小编码，常用4表示16B
```

### CSTS

```text
RDY      Controller是否Ready
CFS      Controller Fatal Status
```

### AQA / ASQ / ACQ

```text
AQA：Admin SQ/CQ深度
ASQ：Admin SQ的SSD可访问Host Memory地址
ACQ：Admin CQ的SSD可访问Host Memory地址
```

### Doorbell

从 BAR 偏移 `0x1000` 开始。对 Queue ID = y：

```text
SQ Tail Doorbell：
0x1000 + (2*y)*(4 << CAP.DSTRD)

CQ Head Doorbell：
0x1000 + (2*y+1)*(4 << CAP.DSTRD)
```

`DSTRD=0` 时：

```text
Admin SQ0 Tail  0x1000
Admin CQ0 Head  0x1004
IO SQ1 Tail     0x1008
IO CQ1 Head     0x100C
```

---

# 4. SQ/CQ、SQE/CQE 深度解析

## 4.1 所有权

| 对象 | Host | SSD |
|---|---|---|
| SQ内存 | 创建、写SQE | 读取、消费 |
| SQ Tail | 维护并写Doorbell | 观察 |
| SQ Head | 通过CQE.SQHD间接获知 | 内部维护 |
| CQ内存 | 创建、读取CQE | 写CQE |
| CQ Head | 维护并写Doorbell | 观察以回收槽位 |
| CQ Tail | 不直接可见 | 内部维护 |

## 4.2 Queue Size 是零基编码

```text
QSIZE字段=7
实际Entry数=8
```

SQ 满判定通常保留一个空位置用于区分 Full/Empty，具体实现应看供应商 Queue Engine。

## 4.3 SQE

普通命令 SQE 为 64 Byte / 16 Dword。

重点字段：

```text
DW0：Opcode、FUSE、PSDT、CID
DW1：NSID
DW4-5：MPTR
DW6-7：PRP1
DW8-9：PRP2
DW10-15：命令特定字段
```

Read/Write 中：

```text
DW10-11：SLBA
DW12低16bit：NLB，0-based
```

例如：

```text
LBA Size = 4096B
传输256KiB
实际块数 = 256KiB / 4KiB = 64
NLB字段 = 64 - 1 = 63
```

## 4.4 CID

CID 是 Host 为命令分配的标识。

关键原则：

```text
同一个SQ内，未完成CID不能重复使用
CQE中的SQID+CID唯一定位原命令
完成顺序可能与提交顺序不同
```

项目 V2 的 `user_tag={generation,segment_id}` 是项目级 Tag，不一定等同于供应商内部每条 SQE 的 CID。供应商可能把一个项目大请求拆成多条 SQE并使用多个内部 CID，最后再合并成项目完成。

## 4.5 CQE

CQE 通常为 16 Byte。

重点字段：

```text
DW0：Command Specific Result
DW2：SQHD + SQID
DW3：CID + Phase + Status
```

### SQHD 不是什么

`SQHD` 表示 SSD 已经消费到的 Submission Queue Head 位置。

它不等于：

```text
之前的命令全部完成
```

它只能帮助 Host 判断哪些 SQ Entry 槽位可以重新使用。

### Phase Tag

CQ Tail 对 Host 不可见，因此 Host通过 Phase 判断 CQE 是否是新条目。

典型做法：

```text
CQ内存初始化P=0
Host expected_phase=1
CQ[head].P == expected_phase → 新完成
CQ Head回绕时 expected_phase翻转
```

### Status

不能只看整个16bit字段是否为0而不解码。至少要保存：

```text
SC   Status Code
SCT  Status Code Type
DNR  Do Not Retry
M    More，可能存在Error Log
```

---

# 5. PRP / PRP List 直接讲解

## 5.1 PRP描述什么

PRP 描述的是：

```text
SSD通过PCIe可以访问的Host Memory地址
```

在本项目中它最终对应 FPGA DDR。

它不是：

```text
SSD的LBA
DDR Segment编号
文件偏移
虚拟地址
```

## 5.2 必须区分五种地址

```text
1. SSD Namespace地址：NSID + SLBA + NLB
2. FPGA本地DDR AXI地址
3. SSD可见的PCIe Host Memory地址
4. SSD BAR的PCIe地址
5. MicroBlaze本地访问SSD BAR的映射地址
```

供应商说地址映射已集成，这意味着应用 API 很可能直接填写项目 DDR 地址；但拿到源码后仍应确认其到底接受：

```text
AXI物理地址
PCIe Bus Address
或内部偏移
```

## 5.3 三种 PRP 情况

假设 Host Page 为4KiB。

### 只使用第一页

```text
PRP1 = Buffer起始地址
PRP2 = 0
```

### 跨两个数据页

```text
PRP1 = 第一页中的起始地址
PRP2 = 第二页页基地址
```

### 跨两个以上数据页

```text
PRP1 = 第一数据页
PRP2 = PRP List页地址

PRP List[0] = 第二数据页地址
PRP List[1] = 第三数据页地址
...
```

## 5.4 256KiB示例

```text
Page = 4KiB
Buffer页对齐
Transfer = 256KiB
页数 = 64
```

所以：

```text
PRP1：第1页
PRP2：PRP List地址
PRP List：63个后续数据页地址
```

## 5.5 MDTS

MDTS 限制单条 NVMe 命令的最大数据量。

常见计算思路：

```text
Max Transfer = 2^MDTS × Controller Minimum Page Size
```

供应商报告中：

```text
MDTS=7
Page=4KiB
Max SQE Payload=2^7×4KiB=512KiB
```

所以 1GB 应用请求会被拆分为多条 512KiB SQE。

---

# 6. NVMe 初始化完整流程

## 6.1 PCIe阶段

```text
参考时钟稳定
→ SSD供电稳定
→ 释放PERST#
→ LTSSM训练
→ Link Up
→ Configuration Read
→ 读取Vendor/Device ID
→ BAR探测与分配
→ 设置Memory Space Enable
→ 设置Bus Master Enable
→ 配置MPS/MRRS
```

### 为什么 Bus Master Enable 必须开

SSD 必须主动发起：

```text
Memory Read：读取Host SQ/PRP/Write Payload
Memory Write：写Host CQ/Read Payload
```

BME未使能时，SSD不允许发这些请求。

## 6.2 NVMe Controller阶段

```text
读取CAP和VS
→ 若CC.EN=1，清零并等待CSTS.RDY=0
→ 分配并清零Admin SQ/CQ
→ 写AQA/ASQ/ACQ
→ 配置CC.CSS/MPS/IOSQES/IOCQES
→ 设置CC.EN=1
→ 等待CSTS.RDY=1
```

## 6.3 Admin命令阶段

```text
Identify Controller
→ Identify Namespace
→ Set Features / Number of Queues
→ Create I/O Completion Queue
→ Create I/O Submission Queue
→ IO Ready
```

### 为什么先创建 CQ 再创建 SQ

每个 I/O SQ 创建时必须指定其关联的 CQID。若 CQ 还不存在，SQ 创建会失败。

## 6.4 Identify重点字段

### Identify Controller

```text
MDTS
SQES/CQES
NN
VWC
ONCS
OACS
SGLS
```

### Identify Namespace

```text
NSZE
NCAP
FLBAS
LBAF[n].LBADS
Metadata Size
```

LBA大小：

```text
LBA_BYTES = 2^LBADS
```

不要写死 SSD 一定是 512B LBA。供应商测试常见 512B，但正式代码必须解析 Identify Namespace。

---

# 7. Read、Write、Flush 与持久性

## 7.1 NVMe Write

命令语义：

```text
把Host Memory数据写到SSD的SLBA
```

数据指针是数据源。

```text
PRP → FPGA DDR源Buffer
SLBA/NLB → SSD目的逻辑块
```

底层事务：

```text
SSD发PCIe Memory Read读取FPGA DDR
```

## 7.2 NVMe Read

命令语义：

```text
从SSD的SLBA读取数据到Host Memory
```

数据指针是数据目的地。

底层事务：

```text
SSD发PCIe Memory Write把数据写入FPGA DDR
```

## 7.3 Flush

Flush 将此前已经完成的相关写入数据和元数据提交到非易失介质。

必须区分：

```text
Write CQE成功
≠ 一定已经掉电持久化
```

供应商情况：

```text
支持Flush
不支持FUA
性能测试开启SSD Cache
性能测试未逐命令Flush
```

项目 V2 的 Capture 完成顺序：

```text
停止采集
→ 排空所有Payload WRITE
→ FLUSH #1
→ Commit Metadata WRITE
→ FLUSH #2
→ capture_done
```

这样做的意图：

1. 先让 Payload 落盘；
2. 再写能描述本次 Capture 的 Commit；
3. 再 Flush Commit；
4. 电脑端只有看到有效 Commit 才认为 Capture 可恢复。

即便如此，真实掉电保证仍取决于 SSD 的 Volatile Write Cache 和 PLP 能力。

---

# 8. PG156 协议补充：四个接口到底是什么

官方文档：

- PG156 在线文档
  https://docs.amd.com/r/en-US/pg156-ultrascale-pcie-gen3
- 文档版本可能随 AMD 网站更新；Vivado 2020.2 工程中的接口和参数应以安装目录配套版本及供应商 XCI 为准。

## 8.1 四接口总览

| 接口 | 方向 | 含义 | 当前NVMe场景 |
|---|---|---|---|
| RQ | User → PCIe Core | 本地发起请求 | 访问SSD BAR、Doorbell、配置/Memory请求 |
| RC | PCIe Core → User | 本地请求的Completion | SSD返回BAR读/配置读结果 |
| CQ | PCIe Core → User | 远端发来的请求 | SSD访问FPGA Host Memory |
| CC | User → PCIe Core | 响应远端Non-Posted请求 | SSD Memory Read的数据返回 |

## 8.2 AXI4-Stream握手

所有 RQ/RC/CQ/CC 都基于类似：

```text
tdata
tkeep
tvalid
tready
tlast
tuser
```

规则：

```text
只有tvalid && tready的时钟沿发生传输
```

当：

```text
tvalid=1
tready=0
```

发送方必须保持：

```text
tdata
tkeep
tlast
tuser
```

稳定，直到真正握手。

这条规则与 AXI-Stream、你熟悉的 valid/ready 数据通路完全一致。

---

# 9. PG156 具体章节和页码

以下页码对应常见 **PG156 v4.4、约337页 PDF**。AMD 在线版排版或 Vivado 2020.2 附带版页码可能略有变化。查找时优先依赖英文标题和表名，页码作为辅助。

## 9.1 A级：必须认真看

### CQ端口与SSD入站请求

```text
第14～17页
Completer Request Interface
Table：Completer Request Interface Port Descriptions
m_axis_cq_tuser Sideband
```

掌握：

```text
m_axis_cq_tdata
m_axis_cq_tkeep
m_axis_cq_tvalid
m_axis_cq_tready
m_axis_cq_tlast
m_axis_cq_tuser
```

### CQ Operation与Descriptor

```text
第125～130页
Completer Request Interface Operation
Completer Request Descriptor
```

重点字段：

```text
Address
Dword Count
Request Type
Requester ID
Tag
First/Last Byte Enable
Traffic Class
Attributes
```

目标不是背bit位，而是能回答：

```text
这是Memory Read还是Memory Write？
地址是什么？
长度是多少？
谁发来的？
Tag是什么？
是否带Payload？
```

### Completer Memory Write

```text
第131～136页
Completer Memory Write Operation
```

对应项目：

```text
NVMe Read
SSD发PCIe Memory Write + Payload
→ CQ
→ NVMe IP写DDR
```

### Completer Memory Read

```text
第137～140页
Completer Memory Read Operation
```

对应项目：

```text
NVMe Write
SSD发PCIe Memory Read
→ CQ
→ NVMe IP读DDR
→ CC返回数据
```

这是 PG156 中与你项目最关键的一节。

### CC端口和Operation

```text
第17～19页
Completer Completion Interface Port Descriptions

第143～154页
Completer Completion Interface Operation
Completion Descriptor
Successful Completion
```

重点字段：

```text
Requester ID
Tag
Lower Address
Byte Count
Dword Count
Completion Status
Payload
```

## 9.2 B级：认真理解

### RQ端口和Operation

```text
第19～23页
Requester Request Interface Port Descriptions

第155～171页
Requester Request Interface
Requester Descriptor
Requester Memory Write
Non-Posted Transaction with No Payload
```

应用：

```text
写Doorbell：Posted Memory Write
读SSD BAR：Non-Posted Memory Read
```

### RC端口和Operation

```text
第24～26页
Requester Completion Interface Port Descriptions

第176～191页
Requester Completion Interface Operation
Requester Completion Descriptor
Handling of Completion Errors
```

重点错误：

```text
Unsupported Request
Completer Abort
Completion Timeout
Unexpected Completion
Malformed Completion
Poisoned Completion
```

## 9.3 C级：Bring-up必看

### Configuration Management / Status

```text
第26～35页
Configuration Management Interface
Configuration Status Interface
```

重点信号概念：

```text
cfg_phy_link_down
cfg_phy_link_status
cfg_negotiated_width
cfg_current_speed
cfg_max_payload
cfg_max_read_req
cfg_ltssm_state
pcie_cq_np_req
```

### Clock and Reset

```text
第59～60页
Clock and Reset Interface
```

区分：

```text
PHY Ready
user_reset解除
user_lnk_up
PCIe枚举完成
NVMe Controller Ready
I/O Queue Ready
DDR init_calib_complete
```

这些都不是同一个 Ready。

### Configurator Example Design

```text
第247～252页
Configurator Example Design
System Overview
Configurator Block
File Structure
```

理解最小枚举：

```text
Link Up
→ Vendor/Device ID
→ BAR探测
→ BAR分配
→ MSE
→ BME
→ MPS/MRRS
→ NVMe BAR访问
```

---

# 10. RQ/RC/CQ/CC 与 NVMe的逐层关系

## 10.1 Host写Doorbell

```text
MicroBlaze写NVMe IP控制寄存器
→ NVMe IP形成PCIe Memory Write
→ RQ
→ SSD BAR Doorbell
```

Doorbell是 Posted Write，不要求PCIe Completion，但 NVMe 命令稍后会通过CQE完成。

## 10.2 Host读CAP/CSTS

```text
MicroBlaze请求读取NVMe BAR
→ RQ Memory Read
→ SSD返回PCIe Completion with Data
→ RC
→ NVMe IP/软件获得寄存器值
```

## 10.3 SSD读取SQE、PRP和Write Payload

```text
SSD发PCIe Memory Read
→ CQ
→ 地址译码
→ AXI DDR Read
→ CC Completion with Data
→ SSD
```

## 10.4 SSD写CQE和Read Payload

```text
SSD发PCIe Memory Write + Payload
→ CQ
→ AXI DDR Write
```

Memory Write是 Posted Transaction，通常没有CC响应。

---

# 11. “看完以后应回答的问题”——标准答案版

这一章直接替你回答此前提出的学习检查题。即使没有时间看完规范，也应先掌握这些标准答案。

## 11.1 能看懂供应商 RTL 的 PCIe 边界，具体是什么意思

你要能在 RTL / Block Design 中定位：

```text
PCIe Hard IP实例
RQ/RC/CQ/CC连接
NVMe Queue Engine
PCIe请求到AXI转换
DDR AXI Master
AXI-Lite控制接口
MicroBlaze连接
Link/Reset/Config状态
```

并能判断某个模块属于：

```text
PCIe事务层
NVMe队列层
DDR数据面
MicroBlaze控制面
项目应用适配层
```

不要求能逐bit重写TLP。

## 11.2 能理解 NVMe Read/Write 对应的底层 PCIe 数据方向

标准答案：

```text
NVMe Write：SSD从Host DDR取数据，所以SSD发PCIe Memory Read
NVMe Read：SSD把数据放到Host DDR，所以SSD发PCIe Memory Write
```

## 11.3 能根据 ILA 判断事务卡在 CQ、DDR AXI、CC、RQ 还是 RC

### NVMe Write卡住

依次查：

```text
1. Host是否提交SQE并写SQ Tail Doorbell
2. SSD的Memory Read是否进入CQ
3. CQ地址/长度是否正确
4. NVMe IP是否发AXI DDR Read
5. DDR AR/R是否握手
6. CC是否返回Completion with Data
7. SSD是否最终写NVMe CQE
```

### NVMe Read卡住

依次查：

```text
1. Host是否提交Read SQE
2. SSD Memory Write是否进入CQ
3. CQ Payload是否完整
4. NVMe IP是否发AXI DDR Write
5. DDR AW/W/B是否成功
6. SSD是否写NVMe CQE
```

### BAR读卡住

```text
RQ是否发出Memory Read
→ Tag是否分配
→ RC是否收到Completion
→ Completion Status是否成功
```

## 11.4 为什么不需要自行编写完整TLP解析、Tag、Split Completion和Flow Control

因为供应商答疑表明：

```text
PCIe Hard IP包含在IP内
PCIe请求转AXI包含在IP内
地址映射包含在IP内
PRP自动生成
```

你需要验证这些模块存在且工作正确，但不是重新实现它们。

## 11.5 Link Up 是否代表 NVMe 已经可用

不是。

正确层级：

```text
PCIe PHY/GT Ready
→ PCIe user_reset解除
→ PCIe Link Up
→ PCIe枚举完成
→ SSD BAR可访问
→ NVMe Controller Ready
→ Identify完成
→ I/O SQ/CQ创建
→ nvme_init_done
```

任何一层失败都不能提交业务 I/O。

## 11.6 为什么CQ Memory Read没有Payload，而Memory Write有Payload

```text
Memory Read请求只告诉对方：从地址A读取长度L
数据由对方稍后通过Completion返回

Memory Write请求本身就是把数据写过去
所以请求包中同时携带地址、长度和Payload
```

## 11.7 Tag有什么用

PCIe Tag：

```text
把RC返回的Completion关联到原RQ Memory Read
```

NVMe CID：

```text
把NVMe CQE关联到原SQE
```

项目 user_tag：

```text
把供应商IP完成关联到项目Segment/Capture
```

三者位于不同层，不应混为一个概念。

## 11.8 为什么会有Split Completion

若 SSD 请求读取的数据量大于单个 PCIe Completion允许携带的数据量，Completer需要拆成多个 Completion with Data。

供应商 IP 应负责：

```text
MPS/RCB边界
Byte Count
Lower Address
Tag保持
多Completion顺序
```

项目层只需要确认数据无缺失、无重复、无错位。

## 11.9 为什么要更新CQ Head Doorbell

Host消费CQE后，必须告诉SSD这些CQ槽位可复用。

不更新会导致：

```text
CQ最终填满
SSD不能继续投递完成
关联SQ可能停止处理
```

## 11.10 为什么Write完成前不能覆盖DDR Buffer

因为 CQE 成功前，SSD可能仍在读取 PRP 指向的DDR页。提前覆盖会让一条 NVMe Write 读取到前后不一致的数据。

所以 Segment必须：

```text
READY → INFLIGHT → 成功Completion → FREE
```

错误或超时不能直接 FREE。

## 11.11 为什么超时后不能直接重用Segment

超时只表示 Host没按期看到完成，不代表 SSD 一定没访问过DDR或没写盘。

可能情况：

```text
命令仍在执行
CQE丢失/未处理
PCIe链路异常
SSD内部卡顿
```

所以 V2 采用：

```text
INFLIGHT → ERROR_HOLD
冻结内容
禁止覆盖
Reset/重初始化后人工或系统处理
```

## 11.12 MicroBlaze在正式系统里应该干什么

应该：

```text
PCIe/NVMe初始化
Identify
创建Queue
调用供应商API
处理完成
读ECQE
Flush
错误和Reset
UART/寄存器状态
```

不应该：

```text
逐字节搬运ADC Payload
在CPU循环中承担1GB/s数据复制
参与每个ADC采样
```

## 11.13 PG194和PG156的差别

```text
PG156：底层PCIe Hard IP，用户侧看到RQ/RC/CQ/CC TLP流
PG194：在PCIe上增加AXI Bridge，把TLP转换成AXI-MM
```

当前第三方 IP 已封装类似桥接功能，所以 PG194 只作概念补充。

---

# 12. MicroBlaze 软件测试程序速查

## 12.1 工程关系

```text
Vivado硬件设计
→ 生成Bitstream
→ 导出XSA
→ Vitis创建Platform/BSP
→ 编译C程序生成ELF
→ ELF下载到MicroBlaze
→ 程序通过AXI-Lite访问NVMe IP
```

## 12.2 拿到Demo后的阅读顺序

1. `main.c`
2. NVMe API头文件
3. NVMe底层驱动 `.c`
4. 寄存器定义
5. `xparameters.h`
6. `lscript.ld`
7. Cache/Interrupt/UART相关代码
8. BSP设置

## 12.3 搜索关键词

```text
init
link_up
enumerate
identify
namespace
create_cq
create_sq
read
write
flush
ecqe
reset
timeout
Xil_In32
Xil_Out32
Xil_DCacheFlushRange
Xil_DCacheInvalidateRange
```

## 12.4 Cache一致性

若 MicroBlaze 开启 Data Cache：

### CPU写DDR后让SSD读取

```text
CPU填Pattern
→ Xil_DCacheFlushRange
→ Memory Barrier
→ 提交NVMe Write
```

### SSD写DDR后CPU读取

```text
收到Read Completion
→ Xil_DCacheInvalidateRange
→ CPU比较DDR
```

若 Payload完全由RTL写、MicroBlaze不访问，Cache问题可减少，但队列、描述符或测试Buffer仍需检查。

## 12.5 推荐手册

### UG1400：Vitis 2020.2 Embedded Software Development

https://docs.amd.com/r/2020.2-English/ug1400-vitis-embedded

重点：

```text
Vitis Software Development Workflow
Creating Hardware Design / XSA
Creating Platform Project
Adding Standalone Domain
Creating Standalone Application
Building Projects
Debugging Projects
Linker Scripts
BSP Settings
```

### UG984：MicroBlaze Processor Reference Guide

https://docs.amd.com/r/en-US/ug984-vivado-microblaze-ref

只看：

```text
Architecture Overview
AXI和Memory Addressing
Data Types / Endianness
Cache
Interrupts
Debug
```

不用学完指令集和汇编。

---

# 13. 项目 V2 如何映射到协议

当前项目抽象：

```text
req_opcode
req_ddr_addr
req_byte_len
req_slba
req_user_tag

cpl_user_tag
cpl_status
```

供应商适配层应完成：

```text
项目大请求
→ 检查4KiB对齐
→ 依据Identify结果计算NLB
→ 按MDTS拆分
→ 分配内部CID
→ 生成PRP/PRP List
→ 写SQE和Doorbell
→ 聚合内部CQE
→ 返回项目级Completion
```

## 13.1 Segment生命周期

```text
FREE
→ FILLING
→ READY
→ INFLIGHT
→ FREE
       └─错误/超时→ERROR_HOLD
```

协议含义：

| 项目状态 | NVMe/DDR含义 |
|---|---|
| FREE | 允许ADC Writer分配 |
| FILLING | DDR写事务尚未完全完成 |
| READY | DDR最后B响应成功，可提交 |
| INFLIGHT | PRP已引用该Buffer，禁止覆盖 |
| FREE | 收到匹配Tag的成功完成 |
| ERROR_HOLD | 命令结果不确定或失败，冻结数据 |

## 13.2 项目层一次一个大请求

当前项目只允许一个大请求在途并不代表 SSD只有一个SQE在途。

```text
项目层：1个Segment请求
供应商IP内部：按MDTS拆成多条SQE，可内部流水
```

这样先降低：

```text
项目Tag管理
乱序完成
多Segment同时错误
恢复复杂度
```

后续验证稳定后再增加项目级 Outstanding。

---

# 14. 真实验证应该看什么信号

## 14.1 最小状态

```text
ddr_init_done
pcie_user_reset_done
pcie_link_up
pcie_enum_done
nvme_controller_ready
io_queue_ready
capture_ready
```

## 14.2 NVMe项目层

```text
req_valid/ready
req_opcode
req_ddr_addr
req_byte_len
req_slba
req_user_tag
cpl_valid
cpl_user_tag
cpl_status
command_age
timeout_sticky
ecqe_error_valid
```

## 14.3 Segment

```text
segment_state
free_mask
ready_count
inflight_count
generation
current_segment
submitted_segments
completed_segments
error_hold_count
```

## 14.4 DDR AXI

```text
ARADDR/ARLEN/ARVALID/ARREADY
RDATA/RVALID/RREADY/RLAST/RRESP
AWADDR/AWLEN/AWVALID/AWREADY
WDATA/WVALID/WREADY/WLAST
BVALID/BREADY/BRESP
```

## 14.5 PG156边界

```text
m_axis_cq_*
s_axis_cc_*
s_axis_rq_*
m_axis_rc_*
cfg_current_speed
cfg_negotiated_width
cfg_ltssm_state
cfg_phy_link_down
```

## 14.6 现场最关键的两条证据

### Write证据链

```text
NVMe Write请求
→ SSD Memory Read进入CQ
→ DDR AR/R读活动
→ CC Completion with Data
→ NVMe CQE成功
```

### Read证据链

```text
NVMe Read请求
→ SSD Memory Write进入CQ
→ DDR AW/W/B写活动
→ NVMe CQE成功
→ DDR数据逐字节正确
```

---

# 15. 测试通过的四个等级

不要把不同层级的PASS混写。

| 等级 | 能证明什么 | 不能证明什么 |
|---|---|---|
| RTL仿真通过 | 状态机、握手、Segment、错误策略 | 真实DDR/PCIe/SSD |
| 真实DDR通过 | MIG、地址、带宽、CRC、仲裁 | NVMe SSD可用 |
| 供应商IP通过 | Demo和黑盒Read/Write/Flush | 已集成到我方工程 |
| 完整SSD闭环通过 | ADC→DDR→SSD→DDR全链路 | 后续产品长期认证仍需继续 |

当前项目文档明确说明：NVMe Stub 不读取DDR、不生成SQE/PRP、不运行PCIe、不访问SSD。所以 Stub PASS不能写成“NVMe已打通”。

---

# 16. 现场五天建议

## 第1天：基线复现

```text
原始工程不修改
→ 重新编译
→ Link Up
→ 枚举
→ NVMe初始化
→ 原始Read/Write PASS
```

记录：

```text
Vivado/Vitis版本
XCI/IP版本
FPGA Part
SSD型号/固件
XDC
时钟复位
配置截图
日志
```

## 第2天：外部DDR直接DMA

```text
DDR写递增Pattern
→ NVMe Write
→ NVMe Read到另一DDR
→ 全量逐字节Compare
```

并用ILA证明：

```text
Write时DDR读
Read时DDR写
```

## 第3天：改地址、长度、SLBA和方向

测试：

```text
4KiB
64KiB
256KiB
512KiB
1MiB大请求
不同DDR区
不同安全SLBA
Write/Read/Flush
```

确认 1MiB / 1GB 如何按 MDTS 拆分。

## 第4天：连续、边界和异常

```text
连续写至少10分钟，条件允许1小时
记录最低1秒带宽
记录最长停顿
SSD温度
非对齐参数
越界LBA
ECQE读取
Link Reset后重初始化
Flush延迟
```

## 第5天：源码讲解与独立复现

必须拿到：

```text
完整Vivado工程
NVMe RTL源码
MicroBlaze软件
BSP
XSA
XCI/Tcl/DCP
XDC
寄存器/API文档
仿真环境
测试脚本
ILA配置
已知问题
License
```

并要求供应商指出代码位置：

```text
PCIe枚举
Controller初始化
Admin SQ/CQ
IO SQ/CQ
PRP生成
MDTS拆分
CID管理
Doorbell
CQE/ECQE
DDR地址映射
Reset
```

---

# 17. 当前最小阅读计划：只有半天时怎么做

## 17.1 第一小时：NVMe全局

```text
Theory of Operation
五种地址
Write/Read方向
初始化顺序
```

## 17.2 第二小时：SQ/CQ/PRP

```text
SQ Tail
CQ Head
Phase
CID
PRP1/PRP2/List
MDTS
```

## 17.3 第三小时：PG156

```text
RQ/RC/CQ/CC总图
CQ Memory Read
CQ Memory Write
CC Completion
Clock/Reset
Configurator
```

## 17.4 第四小时：MicroBlaze和项目

```text
main.c阅读顺序
Xil_In32/Xil_Out32
DDR地址+长度+SLBA
Flush/Invalidate
V2通用请求接口
Segment冻结策略
```

做到这里，已经足够参加第一次供应商现场测试并提出有效问题。

---

# 18. 当前不需要掌握的内容

## NVMe

```text
Reservations
Namespace Management
Sanitize
Firmware Download
Security Send/Receive
ZNS
Virtualization
SR-IOV
Host Memory Buffer
复杂Power State
Fused Compare+Write
Protection Information
```

## PCIe / PG156

```text
全部TLP逐bit编码
DLLP
Replay协议
完整LTSSM条件
Gen3 Equalization算法
ATS/PASID/PRI
SR-IOV/VF
Atomic
TPH
复杂Credit计算
PCIe Compliance Pattern
```

## MicroBlaze

```text
全部汇编指令
处理器流水线实现
MMU全部细节
ABI全部寄存器约定
FreeRTOS/Linux
```

---

# 19. 术语速查

| 术语 | 简明含义 |
|---|---|
| Host | 当前为FPGA NVMe Host |
| Controller | NVMe语境通常指SSD内NVMe Controller |
| RC | PCIe Root Complex；PG156中也可指Requester Completion接口，需看上下文 |
| EP | PCIe Endpoint，当前是SSD |
| SQ | Host写、SSD读的提交队列 |
| CQ | SSD写、Host读的完成队列 |
| SQE | 64B命令描述符 |
| CQE | 16B完成描述符 |
| CID | NVMe命令标识 |
| PRP | Host Memory页指针 |
| SLBA | SSD起始逻辑块 |
| NLB | 0-based块数量 |
| MDTS | 单条NVMe命令最大数据量 |
| Doorbell | 通知队列Head/Tail推进的MMIO寄存器 |
| Phase | 区分CQE新旧代次的bit |
| RQ | 本地向PCIe发请求 |
| RC | 本地请求的Completion返回 |
| CQ接口 | 远端向本地发来的PCIe请求 |
| CC | 本地对远端Read等请求返回Completion |
| MSE | 允许访问SSD BAR Memory Space |
| BME | 允许SSD作为Bus Master发DMA请求 |
| ECQE | 供应商定义的扩展错误完成FIFO/信息，非标准通用名称，需看其文档 |
| Segment | 项目对同一DDR地址空间的固定逻辑分块 |
| user_tag | 项目级请求关联标识 |
| BIST | IP内部高速测试发生器 |
| Raw LBA | 不使用文件系统，按固定LBA直接存储 |

---

# 20. 来源与依据

## 20.1 当前项目和供应商资料

1. `NVMe_Host_Controller_自测报告_正式版.docx`
2. `NVME 测评答疑_2026_7_25.docx`
3. `NVME 测评答疑_补充_回复.docx`
4. `NVMe_ADC_DDR_FPGA基础通路设计方案_V2.0_单双通道与分阶段验证版.docx`
5. `ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md`
6. `ADC_DDR_NVMe验证用例与测试过程_V1.0.docx`
7. `NVMe_ADC_DDR_FPGA基础通路设计方案_V1.0_接口与时序补充版.docx`
8. `pcie_fdma_aurora_brg_adapter总体设计与验证方案.docx`
9. `CPU-FPGA PCIe交互方案V1.0.docx`
10. `RTDS_test-1ch_XDMA_Aurora设计与验证方案规格书.docx`

其中 PCIe–Aurora 文档不是 NVMe 协议依据，但其中“Adapter只保留应用语义、完整桥承担数据面重活”“Buffer所有权”“valid/ready”“IRQ/status”和分阶段验证方法，可直接迁移到 NVMe 项目。

## 20.2 官方规范和手册

### NVMe

- NVM Express Revision 1.3
  https://nvmexpress.org/wp-content/uploads/NVM_Express_Revision_1.3.pdf
- NVMe Specification Archives
  https://nvmexpress.org/nvm-express-specification-archives/
- Current NVMe Specification Set
  https://nvmexpress.org/specifications/

### AMD / Xilinx

- PG156 — UltraScale Devices Gen3 Integrated Block for PCI Express
  https://docs.amd.com/r/en-US/pg156-ultrascale-pcie-gen3
- UG1400 — Vitis Embedded Software Development 2020.2
  https://docs.amd.com/r/2020.2-English/ug1400-vitis-embedded
- UG984 — MicroBlaze Processor Reference Guide
  https://docs.amd.com/r/en-US/ug984-vivado-microblaze-ref

---

# 21. 最终行动清单

在供应商工程到手前：

```text
[ ] 熟记Write/Read底层方向
[ ] 掌握SQ/CQ/PRP/Phase/CID
[ ] 掌握NVMe初始化顺序
[ ] 掌握PG156 RQ/RC/CQ/CC映射
[ ] 准备DDR Pattern→Write→Read→Compare用例
[ ] 准备ILA信号清单
[ ] 保持V2通用req/cpl边界
[ ] 保持Segment ERROR_HOLD
[ ] 不把Stub PASS写成SSD PASS
```

拿到工程后：

```text
[ ] 看main.c
[ ] 看API和寄存器
[ ] 看xparameters.h和地址图
[ ] 看PRP/MDTS拆分
[ ] 看CID/CQE/ECQE
[ ] 确认Cache策略
[ ] 确认Reset/Link Down流程
[ ] 在自己的环境重新构建
```

最核心验收句：

> 由我方 RTL 写入外部 DDR 的递增或 PRBS 数据，能够不经 MicroBlaze memcpy，由 SSD 依据第三方 IP 自动生成的 PRP 通过 PCIe Memory Read 直接读取，写入指定安全 SLBA；随后由 NVMe Read 通过 PCIe Memory Write 写回另一 DDR Buffer，并完成全量逐字节或 CRC 一致性校验。

只有这条证据链成立，才说明“FPGA DDR ↔ NVMe SSD 基础数据通路”真正打通。
