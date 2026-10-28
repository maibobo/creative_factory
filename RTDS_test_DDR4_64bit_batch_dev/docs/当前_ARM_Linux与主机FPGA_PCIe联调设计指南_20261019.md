# 当前 ARM Linux 与主机 FPGA PCIe 联调设计指南

> 版本：2026-10-19  
> 适用范围：ARM Linux CPU ↔ 主机 FPGA 的 PCIe/XDMA/DDR 板内数据通路与软件接入  
> GitHub 基线：`maibobo/creative_factory`，`main`，提交 `3d01e531d517c2e2a42f893dfdbeb289c414e560`（2026-10-19 16:16:16 UTC+8）  
> 当前结论边界：**基础 H2C/C2H、DDR 往返、VIO 上行队列/ACK 已验证；真实 Aurora 对端、真实下行业务发送、用户 MSI、长时间性能和完整业务应用尚未验收。**

---

## 1. 本指南依据与事实优先级

过去 1 小时内仓库只有一个新提交，即上述 `3d01e531...`。该提交新增 200 个文件，包含当前 Linux 设计输入、ARM/PC/Vivado 源码、FPGA 参考 RTL、历史文档和板测证据。提交整体 diff 约 81 万字符、约 1.98 万新增文本行；其中包括 27 个 Markdown、12 个 Python、1 个 C、1 个 Shell、5 个 Tcl、17 个 Verilog、27 个 JSON、22 个 CSV、18 个日志，以及 DOCX/PNG/BIN 等非纯文本证据。

本指南按以下优先级取舍冲突信息：

1. 2026-10-19 板上实测结果及对应当前源码；
2. 2026-10-19 更正/说明；
3. 2026-10-16 联调手册；
4. 2026-10-15 / 2026-10-13 历史联调文档；
5. 更早的寄存器协议说明。

旧文档中写的“当前实现”，只代表当时版本；若与 2026-10-19 源码或实测冲突，以后者为准。

---

## 2. 先给出最重要的分层结论

当前系统必须区分下面 6 层，不能把它们混为“驱动”。

| 层级 | 运行位置 | 当前源码/实体 | 作用 |
|---|---|---|---|
| 业务/实验主程序 | ARM Linux 用户态 | `hardware_joint_lab_20261016/arm/rtds_lab.py` | 设备发现、BAR 寄存器、实验状态机、DMA 调度、数据校验、队列 ACK、日志 |
| DMA helper | ARM Linux 用户态 | `hardware_joint_lab_20261016/arm/rtds_dma.c` → `rtds_dma` | 打开 XDMA H2C/C2H 字符设备，一次进程提交一次同步 DMA |
| Linux XDMA 驱动 | ARM Linux 内核态 | 当前只确认 `/sys/bus/pci/drivers/xdma`、`/sys/module/xdma`；**源码未取得** | PCIe 设备绑定、DMA 描述符/页映射/引擎、字符设备、完成处理 |
| XDMA 用户接口 | `/dev` | `/dev/xdma0_h2c_0`、`/dev/xdma0_c2h_0`、`/dev/xdma0_user` 等 | 用户态进入内核驱动的设备节点 |
| FPGA XDMA IP | FPGA | `design_1_xdma_0_0.xci`、`design_1.bd` | PCIe ↔ FPGA AXI-MM 硬件数据通路；当前参考配置为 Xilinx XDMA 4.1 |
| FPGA 业务 FDMA/寄存器 | FPGA RTL | `INFO_EXCH.v`、`PCIe.v`、`pcie_fdma_aurora_brg_adapter.v`、`rtds_rx_block_writer.v` 等 | 业务 DDR 读写、上行块队列、下行任务、通知/ACK、Aurora/VIO 测试源 |

**`rtds_dma.c` 不是内核驱动。**  
它只是调用已有内核 XDMA 驱动的用户态程序。

**FPGA 的 XDMA IP 也不是 Linux 驱动。**  
它是 FPGA 内的 PCIe/DMA 硬件 IP。

---

## 3. 当前真实调用链

### 3.1 用户态到 FPGA 的调用关系

```text
rtds_lab.py
  |
  | 1. BAR 控制/状态
  |    subprocess -> io -4 -r/-w <BAR0物理地址+offset>
  |
  | 2. DMA
  v
rtds_dma  (C 用户态进程)
  |
  | open("/dev/xdma0_h2c_0" 或 "/dev/xdma0_c2h_0")
  | lseek(fd, card_addr, SEEK_SET)
  | write(fd, CPU_buf, size)   [H2C]
  | read (fd, CPU_buf, size)   [C2H]
  v
Linux 内核 XDMA 驱动
  |
  v
PCIe
  |
  v
FPGA XDMA IP
  |
  +---- M_AXI / DDR 数据路径
  |
  +---- M_AXI_LITE / 业务寄存器路径
```

当前 `rtds_lab.py` 会检查 `/dev/xdma0_user` 存在且属于所选 BDF，但**当前寄存器访问实际使用 `io` 工具直接访问 BAR0 物理地址**，不是通过 `/dev/xdma0_user` 做 mmap。

因此正式应用若以后改成 `mmap(/dev/xdma0_user)`，属于软件实现变化，需要重新验证；不要把它描述成当前已经验证的路径。

---

## 4. `rtds_lab.py`、`rtds_dma.c` 与内核驱动到底如何联系

### 4.1 Python 主程序

`rtds_lab.py` 是当前联调主入口，其主要职责是：

- 在 `/sys/bus/pci/devices` 查找 Xilinx `10ee:8032` PCIe 端点；
- 读取 BAR0 资源；
- 确认端点已经绑定到 `xdma`；
- 确认 `/dev/xdmaN_user`、`h2c_0`、`c2h_0` 是字符设备且确实属于选中的 PCIe BDF；
- 扫描其他进程是否已占用这些 XDMA 节点；
- 通过 `io` 读写允许访问的 BAR 寄存器；
- 通过 `subprocess.run()` 启动 `rtds_dma`；
- 对 DMA 设置超时；
- 校验 helper JSON 返回值、完成字节数和实际数据；
- 管理上行队列的“读取 → 校验 → ACK”所有权；
- 保存 `run.log`、`result.json`、`summary.csv`、数据文件和程序 SHA256。

主程序还通过：

```text
/run/lock/rtds_joint_lab.lock
```

持有非阻塞 `flock`，防止两个实验实例同时消费/ACK 同一个硬件队列。

### 4.2 C helper

命令形式：

```sh
./arm/rtds_dma h2c|c2h DEVICE CARD_ADDR SIZE FILE
```

关键动作只有：

```c
dev = open(DEVICE, ...);
lseek(dev, CARD_ADDR, SEEK_SET);
write(dev, buf, SIZE);   // H2C
// 或
read(dev, buf, SIZE);    // C2H
```

这里：

- `open()` 打开的不是普通文件，而是 XDMA 字符设备；
- `lseek()` 对 XDMA 设备设置的是**FPGA 卡内 AXI-MM 地址**；
- `write()` / `read()` 进入内核驱动并触发 DMA；
- helper 自身不构造 XDMA 描述符、不处理中断、不做 PCIe TLP，也不直接操作 FPGA DMA 引擎寄存器；
- 这些工作属于内核 XDMA 驱动。

### 4.3 普通文件 `fd` 与 XDMA 字符设备 `fd` 的区别

代码中二者都使用 `read/write`，但语义完全不同。

普通文件：

```text
input.bin -> read(file_fd) -> CPU 用户态 buffer
CPU buffer -> write(file_fd) -> output.bin
```

XDMA 设备：

```text
CPU buffer -> write(xdma_h2c_fd) -> FPGA DDR
FPGA DDR   -> read(xdma_c2h_fd)  -> CPU buffer
```

普通文件允许短读/短写时循环补齐。

**XDMA DMA 返回短传输时不能循环补交。**  
当前 helper 明确只提交一次 DMA；如果返回长度小于请求长度，直接失败并上报。原因是第一次 DMA 后硬件状态可能已经不确定，自动补传会带来重复写、重复读或所有权错误。

---

## 5. 三类地址必须严格区分

这是当前软件最容易混淆的地方。

### 5.1 BAR 寄存器地址

当前板测 BAR0 基址：

```text
0xf0200000
```

例如读取 `0x30`：

```text
物理地址 = 0xf0200000 + 0x30 = 0xf0200030
```

当前程序从 PCI resource 自动发现 BAR0，不应手工再叠加一层 FPGA AXI 基地址。

### 5.2 FPGA DDR / 卡内 DMA 地址

例如：

```text
0x00008000   下行测试 DDR
0x00100000   上行环形区 slot 0
0x00140000   上行环形区 slot 1
...
0x002C0000   上行环形区 slot 7
```

这些地址传给：

```c
lseek(xdma_fd, card_addr, SEEK_SET)
```

它们不是 BAR 地址。

### 5.3 CPU 用户态虚拟缓冲区

`rtds_dma.c` 使用：

```c
posix_memalign(&buf, 4096, size)
```

得到 CPU 用户态虚拟地址。

它：

- 不是 FPGA DDR 地址；
- 不是 BAR 地址；
- 不保证等同于 CPU 物理地址；
- 不应该把 `buf` 的数值写进 `0x24`。

CPU 虚拟页如何被映射/固定、如何构造 DMA 描述符，是内核 XDMA 驱动负责的事情。

---

## 6. 当前寄存器软件接口

| 偏移 | 名称 | 软件语义 |
|---:|---|---|
| `0x00` | VERSION | 当前期望 `0x00002001` |
| `0x04` | PROG_TIME | 当前期望 `0x20260914` |
| `0x08` | BUF_LEN_MAX | 当前期望 `0x00040000` |
| `0x0C` | FPGA_TEMP | 温度原始值 |
| `0x10` | INT_STATE | **读后清通知**；读操作有副作用 |
| `0x14` | CPU_REC_STATE | 写 `1` 产生一次上行块消费 ACK |
| `0x18` | FPGA_CPU_START_ADDR | 当前最老待读上行块 DDR 地址 |
| `0x1C` | FPGA_CPU_LEN | 当前最老待读上行块有效字节数 |
| `0x20` | CPU_WR_DONE | 写 1 启动真实下行业务；读为 busy |
| `0x24` | CPU_FPGA_START_ADDR | 下行业务 DDR 起始地址 |
| `0x28` | CPU_FPGA_LEN | 下行业务长度 |
| `0x2C` | DDR_STATUS | DDR/校准/错误状态 |
| `0x30` | UP_READY_BLOCK_CNT | 待 CPU 消费的完整上行块数 |
| `0x34` | UP_BLOCK_SEQ | 当前队头序号 |
| `0x38` | UP_DROP_WORD_CNT | 累计丢失的 32bit 字数 |

关键规则：

- `0x10` 的“清通知”和 `0x14` 的“释放数据块”是两件完全不同的事；
- 读 `0x10` **不应弹出队头**；
- 只有数据 DMA 完成且内容验证通过后，才能写 `0x14=1`；
- `0x14` 写一次就够，不能因为不确定而自动重试；
- `0x30` 才是“还有多少块”的核心判断；
- 每消费一块，都重新读取 `0x18 / 0x1C / 0x34`，不能提前缓存整批地址。

---

## 7. 下行设计：CPU → FPGA DDR → 业务发送

### 7.1 当前已经验证的下行部分

2026-10-19 实测做的是：

```text
CPU 文件
  -> H2C
  -> FPGA DDR 0x8000
  -> C2H 从同一地址读回
  -> CPU 逐字节比较
```

数据：

```text
00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
```

实测：

- H2C 请求 16 Byte，完成 16 Byte；
- C2H 请求 16 Byte，完成 16 Byte；
- 16 Byte 全部一致；
- ILA 可见 1 次写地址、2 个 64bit 写拍、1 次写响应；
- C2H 可见 1 次读地址、2 个 64bit 读拍；
- AXI 响应为 OKAY。

代表性 run：

```text
20261019_091019_ddr_3159c
```

### 7.2 当前没有验证的下行部分

上午测试**没有写 `0x20=1` 启动真实业务发送**。

因此当前不能写成：

> “CPU 数据已经经 FPGA/Aurora 真正发给外部对端并验证成功。”

正确说法是：

> **CPU → XDMA H2C → FPGA DDR 写入，以及同地址 C2H 回读闭环已通过。下行业务启动/Aurora 对端发送仍待验收。**

### 7.3 正式业务下行应采用的顺序

```text
1. 等待 0x20 == 0
2. H2C(card_addr, cpu_buf, len)
3. 确认 H2C 完整成功
4. 写 0x24 = card_addr
5. 写 0x28 = len
6. 写 0x20 = 1
7. 轮询 0x20 回到 0
8. 同时检查 0x2C 错误位、业务侧/对端结果
```

最重要的顺序约束是：

**先把数据 H2C 写进 DDR，再提交业务地址/长度并启动。**

寄存器 `0x24/0x28` 只告诉 FPGA 业务“去 DDR 的哪里取多少数据”，它们本身不承载载荷。

---

## 8. 上行设计：FPGA → DDR 队列 → CPU

当前 VIO 测试路径：

```text
VIO 固定测试源
  -> FPGA 业务 FDMA
  -> DDR 上行环形缓冲区
  -> 0x18/0x1C/0x34 暴露队头
  -> ARM C2H
  -> 数据比较
  -> 0x14 = 1 ACK
  -> FPGA 释放/复用该 slot
```

当前上行环形区：

```text
base   = 0x00100000
stride = 0x00040000
count  = 8
```

即 8 个 256 KiB slot。

### 8.1 当前测试块

VIO 测试源产生两个 32bit 字：

```text
0x00000011
0x00000022
```

DDR 中有效数据共 8 Byte：

```text
11 00 00 00 22 00 00 00
```

由于当前 helper 的实验策略要求 DMA 请求 16 Byte 对齐，因此：

```text
effective = 8 Byte
requested = 16 Byte
completed = 16 Byte
```

只比较前 8 Byte。

**不要把“请求 16 Byte”改写成“该上行块有效长度是 16 Byte”。**

### 8.2 正确消费算法

```text
while 0x30 > 0:
    before_count = read(0x30)

    addr = read(0x18)
    len  = read(0x1C)
    seq  = read(0x34)

    C2H(addr, aligned_request_len)

    verify DMA completed
    verify valid payload
    verify 0x2C / 0x38 health
    verify head still equals (addr, len, seq)

    write(0x14, 1)        # exactly once
    wait until 0x30 == before_count - 1
```

### 8.3 “失败不归还”原则

下面任何一个条件失败：

- DMA 超时；
- XDMA `read()` 返回错误；
- 短传输；
- 数据不一致；
- 队头在 DMA 期间异常变化；
- DDR/FDMA 错误；
- ACK 写入状态不确定；

都应：

```text
停止本次消费
保留当前块
保存日志/寄存器
不再发 DMA
不写或不重写 0x14
```

这条原则比“出错自动恢复”更重要，因为它保护块所有权，避免 FPGA 已经复用 DDR 后 CPU 仍把旧地址当作有效数据。

---

## 9. 内核 XDMA 驱动现状

2026-10-19 15:36 的板端只读核查：

```text
kernel  = 5.10.226-v1.0.4-008a05487-rt89
machine = aarch64
BDF     = 0000:01:00.0
driver  = /sys/bus/pci/drivers/xdma
module  = /sys/module/xdma
```

存在的关键设备节点包括：

```text
/dev/xdma0_user
/dev/xdma0_h2c_0
/dev/xdma0_c2h_0
/dev/xdma0_control
/dev/xdma0_events_0 ... events_15
/dev/xdma0_xvc
```

同时观察到：

- `/proc/modules` 未列出 `xdma`；
- `modinfo xdma` 找不到独立模块；
- 未在常见目录找到 `xdma.ko`；
- `/sys/module/xdma/initstate` 不存在；
- 只从 config 信息看到 `# CONFIG_XDMA_DEBUG is not set`。

这些现象**更像 XDMA 被编进当前内核或由 BSP 特殊方式集成**，但现有证据不足以证明其完整构建方式。

因此当前文档只能确定：

> **板上有可工作的 XDMA 驱动，并已绑定 PCIe 端点。**

不能确定：

> **驱动源码精确对应哪个 Xilinx commit、是否有厂商修改、具体 Kconfig/.config/DTS/补丁是什么。**

---

## 10. 当前缺失的“驱动开发输入”

若要把本指南提升为“可从源码重建整套 Linux BSP”的设计文档，必须向软件/BSP 同事补齐：

1. 当前 ARM Linux 内核完整源码；
2. 内核 commit/tag；
3. XDMA 实际源码目录；
4. 对 XDMA 的修改补丁；
5. 当前 `.config`；
6. PCIe/DMA 相关 DTS/DTB 与补丁；
7. 内核构建、安装、升级和回滚方式；
8. 若不是 built-in，则提供当前匹配内核的 `xdma.ko` 和安装路径；
9. `io` 工具的源码/来源/构建方式；
10. 最终业务应用源码以及它计划采用的 BAR/DMA API。

Xilinx 官方 `dma_ip_drivers/XDMA/linux-kernel` 可以作为接口理解参考，但在没有版本核对前，**不能把官方源码当成当前板端驱动源码**。

---

## 11. ARM 用户态依赖

### 11.1 核心联调程序

`rtds_lab.py` 当前只使用 Python 标准库：

```text
argparse
csv
datetime
fcntl
hashlib
json
os
platform
re
shutil
stat
subprocess
sys
time
uuid
pathlib
```

因此 ARM 核心程序不依赖 Paramiko。

运行依赖：

```text
Python 3
Linux procfs/sysfs
io 命令
已绑定的 XDMA 驱动
/dev/xdma* 字符设备访问权限
可写的结果目录
flock 支持
```

### 11.2 C helper

依赖：

```text
Linux libc
POSIX open/read/write/lseek
posix_memalign
clock_gettime
C11 编译器
```

编译：

```sh
cd /root/rtds_joint_lab_20261016
sh arm/build.sh
```

实际命令：

```sh
cc -std=c11 -O2 -Wall -Wextra -Werror rtds_dma.c -o rtds_dma.new
mv rtds_dma.new rtds_dma
```

脚本不会安装、重载或修改内核驱动。

### 11.3 Windows/PC 远程控制层

仅远程联动需要：

```text
Python 3
Paramiko 5.0.0
Windows OpenSSH
已配置的 SSH host key
vivado-srv 等现有 SSH alias
```

它不是 DMA 必需依赖。

实际 DMA 始终在 ARM 上执行；PC 只是通过 SSH 启动 ARM 进程、传递 Vivado 控制请求并回收证据。

### 11.4 Vivado 调试层

需要：

```text
Vivado 2020.2
已连接正确器件
匹配当前 bit 的 LTX
现有 GUI 会话
vivado/*.tcl
```

GUI bridge 只负责控制 VIO/ILA、保存采样等，不承担 Linux DMA。

---

## 12. 建议正式业务应用如何接入

当前不建议业务同事“重新写 XDMA 驱动”。已有驱动已经满足基础 DMA，首先应复用。

有两种接入方式。

### 12.1 方式 A：业务程序调用现有 helper

适合快速联调。

业务程序：

```text
业务 main
  -> 启动 rtds_dma 子进程
  -> 解析 JSON
  -> 检查 returncode/completed
  -> 再决定是否继续业务或 ACK
```

优点：

- 改动少；
- 与当前实测路径一致；
- 失败边界清晰；
- 容易保留日志。

缺点：

- 每次 DMA 都创建一个进程；
- 不适合最终高频/低延迟数据面。

### 12.2 方式 B：把 helper 的核心逻辑抽成 C 函数

适合最终产品程序。

推荐形式：

```c
int xdma_h2c(
    const char *dev,
    uint64_t card_addr,
    const void *buf,
    size_t len);

int xdma_c2h(
    const char *dev,
    uint64_t card_addr,
    void *buf,
    size_t len);
```

然后：

```text
现有业务 main
  -> 自己维护业务状态机
  -> 调 xdma_h2c()/xdma_c2h()
  -> 调 BAR read32()/write32()
```

这里是**抽取函数**，不是把两个 `main()` 拼接。

也不需要：

- 把内核驱动源码链接进应用；
- 链接 `libxdma` 私有库；
- 包含驱动内部私有头文件；
- 重写 DMA 描述符管理。

### 12.3 建议应用内部再分 4 个小模块

```text
app_main
├── pcie_device
│   ├── 端点发现 / BDF 绑定
│   └── 设备节点核对
├── fpga_regs
│   ├── read32(offset)
│   └── write32(offset, value)
├── dma_transport
│   ├── h2c(card_addr, buf, len)
│   └── c2h(card_addr, buf, len)
└── rtds_protocol
    ├── downlink_submit()
    ├── uplink_peek()
    ├── uplink_read()
    └── uplink_ack()
```

这样“XDMA 传输”和“RTDS 业务协议”不会互相混在一起。

---

## 13. 正式软件最需要保留的安全策略

当前实验代码中有一些策略应保留到正式软件：

### 必须保留

- 一个块只能有一个消费者；
- DMA 成功前不 ACK；
- 数据校验失败不 ACK；
- 短 DMA 不自动补传；
- ACK 状态不确定时不重写；
- `0x10` 通知清除与 `0x14` 块归还分离；
- 上行每块重新读取队头；
- 同一设备避免多个进程无序并发；
- 所有错误必须记录 BDF、card address、requested/completed、errno、寄存器状态。

### 当前测试限定，不应误写成硬件绝对限制

`rtds_dma.c` 当前人为限制：

```text
地址 16 Byte 对齐
长度 16 Byte 对齐
单次最大 32 KiB
```

这是本实验 helper 的安全策略。

其中部分约束也与当前下行业务协议一致，但不能由 helper 代码推导出“所有 XDMA 硬件模式都只能这样传”。

---

## 14. 当前 FPGA / XDMA 硬件依赖关系

当前参考 FPGA 工程显示：

```text
Xilinx XDMA IP: 4.1
M_AXI data width: 64 bit
M_AXI clock: 250 MHz
M_AXI protocol: AXI4
```

业务数据关系：

```text
PCIe XDMA
   |
   v
AXI Interconnect
   |
   +--> DDR4
   |
   +--> INFO_EXCH / 业务控制
```

FPGA 业务 FDMA 与 Linux XDMA 是不同层：

- Linux XDMA/H2C/C2H：CPU 与 FPGA DDR 间搬运；
- FPGA 业务 FDMA：FPGA 内部逻辑从 DDR 取数据发 Aurora，或把接收数据写 DDR；
- 二者通过 DDR 和寄存器协议交接。

这也是为什么：

> “H2C 成功”不能等价于“业务 Aurora 已发送成功”。

---

## 15. 部署与运行

当前 ARM 持久部署目录：

```text
/root/rtds_joint_lab_20261016
```

文件在根文件系统中，断电后保留，但当前没有证据表明自动开机启动。

### 15.1 编译

```sh
cd /root/rtds_joint_lab_20261016
sh arm/build.sh
```

### 15.2 只读检查

```sh
python3 arm/rtds_lab.py env
python3 arm/rtds_lab.py regs
```

### 15.3 配置测试

```sh
python3 arm/rtds_lab.py config --exclusive
```

### 15.4 DDR H2C/C2H 闭环

不使用 JTAG/VIO：

```sh
python3 arm/rtds_lab.py ddr --exclusive --no-jtag
```

带 ILA 采集：

```sh
python3 arm/rtds_lab.py ddr --exclusive --capture
```

### 15.5 VIO 上行队列

```sh
python3 arm/rtds_lab.py single --exclusive --capture
python3 arm/rtds_lab.py multi --exclusive
```

带真实写操作的用例运行前必须停止其他会访问相同 XDMA 节点或队列的业务程序。

---

## 16. 当前监视与日志体系

### 16.1 寄存器监视器

```text
arm/rtds_regs_watch.py
```

职责：

- 只读；
- 不发 DMA；
- 不写 `0x14`；
- 不读 `0x10`；
- 默认只在状态变化时追加日志。

因此它适合作为联调旁路观察器。

### 16.2 每个用例结果目录

主要证据：

```text
run.log
result.json
summary.csv
ddr_tx.bin / ddr_rx.bin
up_*.bin
program_sha256
```

原则：

- 新 run 使用新目录；
- 不覆盖旧证据；
- 用单调时钟做超时；
- ARM 墙钟当前不可信；
- PC 时间只作为辅助关联。

---

## 17. 2026-10-19 已验证内容

### 17.1 DDR H2C/C2H

代表性 run：

```text
20261019_091019_ddr_3159c
```

已验证：

- `0x8000` H2C 16 Byte 完整成功；
- 同地址 C2H 16 Byte 完整成功；
- `00..0F` 逐字节一致；
- ILA1 写/读 AXI 握手完整；
- BRESP/RRESP 正常。

### 17.2 VIO 单块上行

代表性 run：

```text
20261019_091052_single_b260f
```

已验证：

- FPGA 业务 FDMA 向 DDR 写入固定 8 Byte；
- 队头地址/长度/序号正确；
- `0x10` 读清通知不释放块；
- ARM C2H 请求/完成 16 Byte；
- 前 8 Byte 数据一致；
- 数据通过后写一次 `0x14`；
- ACK 后队列数减 1。

### 17.3 多块环形队列

代表性 run：

```text
20261019_091120_multi_01905
```

已验证：

- 2 / 8 / 2 三批；
- 共覆盖 8 个 slot；
- 地址发生环回；
- 序号连续；
- 每块数据正确后才 ACK。

整个 2026-10-19 联调共三轮、18 个用例 PASS，累计验证 39 个上行块。

---

## 18. 当前不能宣称通过的内容

以下仍是待验收：

- 真实 Aurora RX；
- 真实子机/外部对端；
- 真实下行业务 `0x20` 启动后的端到端发送；
- 用户 MSI 实际投递到 CPU；
- 长时间稳定性；
- DMA 性能/吞吐/CPU 占用；
- 大包；
- 非 16 Byte 尾部和更多边界长度；
- 多业务并发；
- DMA/PCIe/Aurora 故障恢复专项；
- 外部 I/O；
- Flash 与 JTAG 两种启动方式的独立回归；
- reboot 专项；
- 从源码重建当前 XDMA 内核驱动。

当前 `RX_VIO_TEST_ENABLE=1` 的结果只能证明：

> **内部 VIO 测试源 → FPGA 业务 FDMA → DDR → 队列寄存器 → Linux C2H → ACK 的链路。**

不能把它写成：

> **真实 Aurora 接收已通过。**

---

## 19. 下一阶段建议验收顺序

建议不要先重写软件，而按当前已验证边界继续向外扩展：

```text
阶段 1：固化当前 Linux 基线
  - 取得真实内核/XDMA源码
  - 固定版本、.config、BSP构建方式

阶段 2：把测试 helper 接入正式应用
  - 先复用同样的 one-shot DMA 语义
  - 保持失败不 ACK
  - 建立统一日志

阶段 3：真实下行业务
  - H2C -> 0x24/0x28 -> 0x20
  - 对端逐帧比对

阶段 4：真实 Aurora 上行
  - RX_VIO_TEST_ENABLE=0
  - 真实对端发数
  - 同样按队列 C2H + ACK

阶段 5：MSI
  - 中断只做“有数据”通知
  - 队列数量仍以 0x30 为准

阶段 6：压力与故障
  - 长时间
  - 环形持续回绕
  - 满队列
  - 慢消费者
  - DMA timeout/error
  - PCIe/Aurora 重链
```

---

## 20. 软件同事最常见的几个误区

### 误区 1：`rtds_dma.c` 就是驱动

不是。它是用户态 helper。

### 误区 2：写 `0x24/0x28` 就把数据放进 DDR

不是。真正的数据靠 H2C DMA 搬运。

### 误区 3：`0x20=1` 是启动 H2C DMA

不是。H2C 通过 `/dev/xdma0_h2c_0` 提交；`0x20` 启动的是 FPGA 后续下行业务。

### 误区 4：读了 `0x10` 就等于这块数据消费完了

不是。`0x10` 只清通知，`0x14` 才释放当前块。

### 误区 5：一次看到 `0x30=N` 后，可以把 N 个地址一次缓存下来

不建议。当前协议暴露的是“最老队头”，每 ACK 一块后必须重新读下一块队头。

### 误区 6：C2H 返回成功就立即 ACK

还不够。至少还要确认：

```text
completed == requested
有效数据内容正确
队头没有异常变化
错误/丢字状态正常
```

之后才能 ACK。

### 误区 7：基础 DMA PASS 就代表完整 Linux/FPGA 业务 PASS

不成立。DMA、FPGA 业务 FDMA、Aurora、队列协议和最终业务应用是不同层。

---

## 21. 当前推荐的软件接口边界

最终正式代码最好保持如下职责边界：

```text
┌──────────────────────────────────┐
│           Business App           │
│  业务状态机 / 数据处理 / 策略     │
└───────────────┬──────────────────┘
                │
┌───────────────v──────────────────┐
│          RTDS Protocol           │
│ downlink / uplink / queue / ACK  │
└───────┬─────────────────┬────────┘
        │                 │
┌───────v───────┐  ┌──────v────────┐
│ FPGA Reg API  │  │ XDMA Transfer │
│ read32/write32│  │ h2c/c2h       │
└───────┬───────┘  └──────┬────────┘
        │                 │
        │          /dev/xdma*_h2c/c2h
        │                 │
        └───────┬─────────┘
                v
        Linux XDMA Kernel Driver
                │
                v
             PCIe
                │
                v
        FPGA XDMA + DDR + FDMA
```

这套边界的核心是：

> **驱动只负责可靠搬运；RTDS 协议负责“什么时候搬、搬哪里、什么时候释放”；业务应用负责数据含义。**

---

## 22. 主要源码与文档索引

### 当前 Linux 用户态代码

```text
hardware_joint_lab_20261016/arm/rtds_lab.py
hardware_joint_lab_20261016/arm/rtds_dma.c
hardware_joint_lab_20261016/arm/build.sh
hardware_joint_lab_20261016/arm/rtds_regs_watch.py
```

### PC/Vivado 联动

```text
hardware_joint_lab_20261016/pc/lab_remote.py
hardware_joint_lab_20261016/pc/verify_gui.py
hardware_joint_lab_20261016/vivado/gui_bridge.tcl
hardware_joint_lab_20261016/vivado/rtds_lab.tcl
hardware_joint_lab_20261016/vivado/pcie_joint_debug_base.tcl
```

### FPGA 参考

```text
fpga_reference/ip_config/design_1.bd
fpga_reference/ip_config/design_1_xdma_0_0.xci
fpga_reference/new/INFO_EXCH.v
fpga_reference/new/PCIe.v
fpga_reference/new/pcie_fdma_aurora_brg_adapter.v
fpga_reference/rtl/rtds_rx_block_writer.v
```

### 本指南重点使用的历史/当前文档

```text
guide_input/01_网页端编写任务与事实边界.md
guide_input/02_驱动应用代码与依赖关系.md
guide_input/03_近期讨论与DMA证据摘要.md

hardware_joint_lab_20261016/docs/RTDS_ARM测试程序源码说明_20261019.md
hardware_joint_lab_20261016/docs/RTDS_板内联动实测记录_20261019.md

history_docs/CPU-FPGA_PCIe软件寄存器说明_V2.01_当前实现.md
history_docs/RTDS_驱动与主机单机联调_上下行完整操作步骤_20261013.md
history_docs/RTDS_当前软件联调推荐配置与操作顺序_20261013.md
history_docs/主机_软件配置与操作说明_20261013.md
```

---

## 23. 一句话设计结论

**当前 Linux 侧不需要再发明一套 PCIe/DMA 驱动；正确方向是继续使用已工作的内核 XDMA 驱动，在用户态建立清晰的“BAR 控制 + H2C/C2H 数据搬运 + 上行队列所有权/ACK”三层接口，并把当前经过板测的失败不重试、失败不 ACK 语义原样带入正式业务应用。**
