# fdma_aurora_brg_added_files_theory_design_registers

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\fdma_aurora_brg_added_files_theory_design_registers.md`
- SHA-256: `de572342323ea31a405bd6b4c93e9b29edee658b8089033fcf6433cbced50902`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# fdma_aurora_brg 新增文件理论依据、集成设计方案与寄存器建议

## 1. 文档目的

本文用于说明 `fdma_aurora_brg` 近期新增设计、验证和工程脚本文件的背景、理论依据、作用，以及后续接入现有 PCIe/XDMA 工程时推荐采用的集成方案。

本文还给出一份寄存器表建议，并说明如果后续真的把这些寄存器加入 RTL 工程，代码应放在哪里、如何连接、哪些逻辑必须可综合、哪些内容仍只属于仿真或 bring-up 辅助。

本文面向后续整理 Word 版“集成/设计方案”。当前内容只作为设计说明和工程指导，不表示已经实现 AXI-Lite 寄存器 RTL。

**当前修正说明：**早上新增的 `fdma_aurora_pcie_conv_dma_wrapper.v` 只适合作为 `fdma_aurora_brg + CONV_DMA + AXI RAM model` 的局部仿真参考，它不是 `RTDS_test` 原 PCIe 工程的真实系统集成层。真实工程集成应保持 `TOP.v` 为板级顶层，在 `TOP.v -> PCIe.v -> design_1_wrapper` 这条现有路径内嵌入 `pcie_fdma_aurora_brg_adapter.v`，由 adapter 连接现有 66-bit `{SOF,data,EOF}` 数据边界、`INFO_EXCH` 控制语义和 `design_1_wrapper/CONV_DMA` 暴露的 FDMA 口。

## 2. 背景与设计依据

现有系统中，PCIe 侧工程通过 XDMA 暴露 AXI-Lite 寄存器和共享数据窗口，FPGA 侧通过 `CONV_DMA` 把 FDMA 风格接口转换为 AXI 读写。CPU 侧负责配置寄存器、读写 payload buffer、处理中断和状态。

`fdma_aurora_brg` 原工程重点验证 Aurora LocalLink 与 FDMA 风格接口之间的桥接关系：

```text
FDMA read -> TX async FIFO -> Aurora LocalLink TX
Aurora LocalLink RX -> RX async FIFO -> FDMA write
```

早上新增 wrapper 和 integration testbench 的目的不是替代原 PCIe 工程的软件控制面，而是在原 bridge 单元验证和完整 PCIe 上板 bring-up 之间补上一层最小集成验证：

```text
LocalLink BFM
  <-> fdma_aurora_pcie_conv_dma_wrapper
  <-> CONV_DMA
  <-> AXI RAM model
```

这样可以先证明 `fdma_aurora_brg` 接到 `CONV_DMA` 之后，关键语义没有错。该结论可作为真实集成 adapter 的接口依据，但不能等同于 `TOP.v/PCIe.v` 已完成系统集成。它覆盖的重点包括：

- 512B Aurora frame 到 `CONV_DMA` 的 64 个 64-bit beat size 转换。
- RX 写 RAM 的地址、数据顺序和帧边界。
- TX 从 RAM 读出后的 `SOF/EOF/REM/data`。
- FDMA/AXI 停顿时不丢字、不重复。
- 8KB 地址窗口回绕。
- Aurora RX 不接受反压时，风险通过 FIFO 水位和 sticky 状态暴露。

现有 `CPU-FPGA PCIe 交互方案V1.0` 中已经定义了 CPU 与 FPGA 通过 PCIe/XDMA 交互的基本模型：寄存器负责控制和状态，数据区负责大块 payload，FPGA 写完后用中断通知 CPU，CPU 写完后用寄存器通知 FPGA。因此后续集成应优先兼容这套软件协议，而不是重写一套新的主机交互方式。

## 3. 新增文件清单、理论依据与意义

| 文件 | 类型 | 理论依据 | 工程意义 |
| --- | --- | --- | --- |
| `fdma_aurora_pcie_conv_dma_wrapper.v` | 可综合设计文件 | `CONV_DMA` 的 `fdma_*size` 单位是 64-bit beat，不是 byte；Aurora bridge 内部 frame 以 512B 为语义单位 | 在 bridge 和 `CONV_DMA` 之间做 size 适配、地址窗口配置和 sticky 状态汇总 |
| `fdma_aurora_brg_tx.v` 修改 | 可综合设计文件 | TX 方向需要支持可配置 memory window，而不是固定 4KB | 后续 wrapper 可配置 8KB 或其他 PCIe buffer 窗口，并验证地址回绕 |
| `fdma_aurora_brg_rx.v` 修改 | 可综合设计文件 | Aurora RX 输出不能反压，必须持续接收；风险应通过 FIFO 状态观测 | 导出 `almost_full/full/overflow`，给 ILA、状态寄存器和软件策略使用 |
| `fdma_aurora_brg_top.v` 修改 | 可综合设计文件 | 顶层需要透传地址窗口参数和 RX FIFO 状态 | 让 wrapper 或未来 PCIe 顶层能统一配置和观测 bridge |
| `axi_ram_model.sv` | 仿真模型 | 最小集成仿真不需要真实 PCIe Root Complex/XDMA，只需模拟 AXI RAM 语义 | 替代 CPU/BRAM/XDMA 侧，验证 AXI 写入、读出、stall 和地址 |
| `tb_fdma_aurora_brg_conv_dma_integration.sv` | 仿真 testbench | 集成风险集中在 `LocalLink <-> wrapper <-> CONV_DMA <-> AXI` 的 size、地址、握手和帧边界 | 覆盖 RX、TX、stall、8KB wrap、FIFO sticky、link/reset 等关键场景 |
| `run_integration_xsim.ps1` | 命令行脚本 | 仿真应脱离 GUI 可重复运行，减少手动设置差异 | 直接调用 XSim 编译、elaborate、运行 integration TB 并检查 PASS |
| `run_bridge_tc_xsim.ps1` | 命令行脚本 | 新增 wrapper 后仍需确认原 bridge 单元回归未破坏 | 可指定原 `loop_validate` testcase 做补充回归 |
| `add_integration_sources_to_project.tcl` | Vivado 工程脚本 | 工程收录关系应可复现，不依赖 GUI 手动逐个添加 | 将 wrapper、integration TB、AXI RAM model 和 `CONV_DMA.v` 加入 Vivado 工程 |
| `vivado_gui_project_add_steps.md` | 工程说明文档 | 用户需要在 GUI 中检查 Design Sources 和 Simulation Sources | 记录 Tcl 添加方式、GUI 手动添加方式和实际命令顺序 |

这些文件共同解决的问题是：先在小范围内证明 `fdma_aurora_brg` 与 `CONV_DMA` 的接口语义正确，再进入完整 PCIe 工程集成。它们不是完整产品形态，也不替代板级验证。

## 4. fdma_aurora_brg 接入 PCIe 工程的推荐设计方案

推荐采用“保留现有 `TOP.v` 和 PCIe/XDMA 软件控制平面，在 `PCIe.v` 内新增 Aurora/FDMA 数据面适配层”的方案。

当前 `RTDS_test` 工程的真实集成结构应为：

```text
TOP.v
  | existing 66-bit stream and PCIe pins
  v
PCIe.v
  | start / addr / length / status / irq from INFO_EXCH
  | 66-bit {SOF,data,EOF} stream from/to DATA_CDC
  v
pcie_fdma_aurora_brg_adapter.v
  | FDMA read/write request, size, addr, valid, ready
  v
design_1_wrapper.v
  | CONV_DMA / INFO_EXCH / XDMA / BRAM
  v
XDMA BAR and payload window
```

这次真实工程改法不把 `fdma_aurora_pcie_conv_dma_wrapper.v` 设成 top，也不把它当作 `RTDS_test` 的系统集成层。原因是该 wrapper 并不知道 `TOP.v` 中的 `DATA_CDC`、`PCIe.v` 中的 `INFO_EXCH` 控制信号，也没有天然连接到 `design_1_wrapper` 的真实 BD 端口。

真实数据面如下：

```text
Aurora/debug 66-bit stream from DATA_CDC
  -> RX FIFO
  -> pcie_fdma_aurora_brg_adapter
  -> FDMA write through design_1_wrapper/CONV_DMA
  -> BRAM/DDR payload window
  -> CPU reads payload and clears/advances status

CPU writes payload window
  -> RD_START / CPU_FPGA_START_ADDR / CPU_FPGA_LEN from INFO_EXCH
  -> FDMA read through design_1_wrapper/CONV_DMA
  -> pcie_fdma_aurora_brg_adapter
  -> TX FIFO
  -> 66-bit stream to DATA_CDC/Aurora side
```

关键原则：

- CPU 通过 XDMA AXI-Lite 配置寄存器。
- CPU/FPGA payload 通过 XDMA 可访问的 BRAM/DDR 数据窗口交互。
- `pcie_fdma_aurora_brg_adapter.v` 负责 FDMA 周期级握手、地址推进、512B frame 到 64 beat 的 size 适配、帧计数、FIFO 状态和错误 sticky。
- 软件不直接参与 `rareq/wareq/valid/ready/busy` 这类周期级 FDMA 控制。
- `rx_dst_rdy` 固定保持 `1'b1`，因为 Aurora RX 输出侧不接受下游反压。
- RX 方向的风险控制放在 FIFO 容量、overflow sticky、远端发送策略和软件读取策略上。

## 5. 数据流与控制流

### 5.1 CPU -> Aurora

CPU 到 Aurora 的推荐流程：

1. CPU 通过 XDMA BRAM/DDR BAR 写 payload 数据。
2. CPU 通过 AXI-Lite 写 TX 起始地址、长度或帧数。
3. CPU 写 `CPU_WR_DONE` 或未来扩展的 `TX_START`。
4. FPGA 硬件接收 start 后，发起 FDMA read。
5. `CONV_DMA` 从 AXI RAM/BRAM/DDR 读出数据。
6. `pcie_fdma_aurora_brg_adapter.v` 将数据送入 TX FIFO，并按 66-bit `{SOF,data,EOF}` 边界输出到 `DATA_CDC/Aurora` 方向。
7. 硬件置位 TX done、计数器或中断。
8. CPU 读取状态，必要时清 done/irq/error。

这一方向的关键是：软件只描述“数据在哪里、长度多少、什么时候开始”，不控制每个 beat 的握手。

### 5.2 Aurora -> CPU

Aurora 到 CPU 的推荐流程：

1. `DATA_CDC` 向 `PCIe.v` 输出 66-bit `{SOF,data,EOF}` 数据，真实 Aurora 接入后仍要求 RX 方向不可反压。
2. adapter 将 RX 数据写入 RX FIFO。
3. 硬件按帧或 burst 发起 FDMA write。
4. `CONV_DMA` 将数据写入 AXI RAM/BRAM/DDR payload window。
5. 写完一个可交付单位后，硬件更新 RX frame count、写地址或长度。
6. 硬件置位 `INT_STATE` 或扩展 RX done/IRQ。
7. CPU 收中断或轮询状态后，读取 payload window。
8. CPU 写 `CPU_REC_STATE` 或扩展 release/clear 寄存器，通知 FPGA 本段数据已处理。

这一方向的关键风险是 Aurora 不能被下游反压。如果 CPU 读得慢或 FDMA/AXI 写侧堵住，必须依靠 FIFO 深度和 sticky 状态把风险暴露出来。

## 6. 与 CPU-FPGA PCIe 交互方案的对应关系

原 CPU-FPGA PCIe 交互方案已经定义了 32-bit、小端序寄存器，以及 FPGA->CPU、CPU->FPGA 两个方向的数据交换协议。后续集成时应保持这些寄存器语义兼容。

### 6.1 原方案保留寄存器

| 偏移 | 名称 | 属性 | 原用途 | 集成 fdma_aurora_brg 后的建议 |
| --- | --- | --- | --- | --- |
| `0x0000` | `VERSION` | R | FPGA 程序版本号 | 保留，用于软件识别 bitstream 版本 |
| `0x0004` | `PROG_TIME` | R | FPGA 程序时间 | 保留，用于 bring-up 和版本追踪 |
| `0x0008` | `BUF_LEN_MAX` | R | 每通道最大 buffer 长度 | 保留；若采用 32KB 或更大窗口，应反映真实最大长度 |
| `0x000C` | `FPGA_TEMP` | R | FPGA 温度 | 保留，不与 Aurora/FDMA 状态混用 |
| `0x0010` | `INT_STATE` | RC | FPGA->CPU 写数据完成中断状态 | 可继续作为 RX done/FPGA 写完通知，也可由扩展 IRQ 汇总驱动 |
| `0x0014` | `CPU_REC_STATE` | W/R | CPU 已读取 FPGA 写入数据 | 可作为 RX buffer release 或读完成确认 |
| `0x0018` | `FPGA_CPU_START_ADDR` | R | FPGA->CPU 数据起始地址 | 建议由 RX 写入窗口基地址或当前可读块地址驱动 |
| `0x001C` | `FPGA_CPU_LEN` | R | FPGA->CPU 数据长度 | 建议由 RX 完成长度或 frame count 换算得到 |
| `0x0020` | `CPU_WR_DONE` | W/R | CPU->FPGA 写数据完成 | 可继续作为 TX start 触发源 |
| `0x0024` | `CPU_FPGA_START_ADDR` | W/R | CPU->FPGA 数据起始地址 | 作为 TX FDMA read base address |
| `0x0028` | `CPU_FPGA_LEN` | W/R | CPU->FPGA 数据长度 | 作为 TX FDMA read length 或 frame count 换算依据 |

### 6.2 兼容原则

扩展 Aurora/FDMA 寄存器时，不建议覆盖 `0x0000` 到 `0x0028`。这些地址已经属于原软件协议，后续软件、驱动或调试脚本可能依赖这些偏移。

新增寄存器建议从空闲偏移开始，例如 `0x0030` 以后放通用状态，`0x0100` 以后放 TX 控制，`0x0200` 以后放 RX 控制，`0x0300` 以后放硬件自测。

## 7. 寄存器表建议

### 7.1 属性约定

| 属性 | 含义 |
| --- | --- |
| R | CPU 只读 |
| W | CPU 只写 |
| W/R | CPU 可读写 |
| RC | CPU 读后自动清除 |
| W1C | CPU 写 1 清除对应 sticky/status 位 |

所有寄存器建议为 32-bit、小端序，和原交互方案保持一致。

### 7.2 通用状态与中断扩展寄存器

| 偏移 | 名称 | 属性 | 默认值 | 位定义 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `0x0030` | `AURORA_STATUS` | R | `0x0` | bit0 `channel_up`；bit1 `lane_up`；bit2 `link_down_sticky` | Aurora 链路状态。`link_down_sticky` 用于捕获曾经掉链 |
| `0x0034` | `FDMA_STATUS` | R | `0x0` | bit0 `tx_busy`；bit1 `rx_busy`；bit2 `fdma_rbusy`；bit3 `fdma_wbusy`；bit4 `fdma_timeout_sticky` | FDMA 数据面运行状态 |
| `0x0038` | `FIFO_STATUS` | R | `0x0` | bit0 `rx_almost_full`；bit1 `rx_full`；bit2 `rx_overflow_sticky`；bit3 `tx_underflow_sticky` | RX/TX FIFO 风险状态 |
| `0x003C` | `IRQ_ENABLE` | W/R | `0x0` | bit0 TX done；bit1 RX done；bit2 error；bit3 link down | 中断使能 |
| `0x0040` | `IRQ_STATUS` | W1C/R | `0x0` | bit0 TX done；bit1 RX done；bit2 error；bit3 link down | 中断状态，写 1 清除 |
| `0x0044` | `ERROR_CLEAR` | W1C | `0x0` | bit0 clear FIFO sticky；bit1 clear FDMA timeout；bit2 clear link sticky；bit3 clear counters | 错误和计数器清除入口 |

### 7.3 TX 方向扩展寄存器

| 偏移 | 名称 | 属性 | 默认值 | 位定义 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `0x0100` | `TX_CTRL` | W/R | `0x0` | bit0 `tx_start`；bit1 `tx_abort`；bit2 `loopback_enable`；bit3 `test_mode` | TX 控制。`tx_start` 可设计成写 1 触发后硬件自清 |
| `0x0104` | `TX_FRAME_BYTES` | W/R | `512` | bits[15:0] frame bytes | 默认 512B；接 `CONV_DMA` 时硬件换算为 64 beat |
| `0x0108` | `TX_FRAME_COUNT` | W/R | `0x0` | bits[31:0] frame count | CPU 请求发送的帧数；为 0 时可定义为不启动 |
| `0x010C` | `TX_FRAME_SENT` | R | `0x0` | bits[31:0] sent count | 硬件已发送帧计数 |
| `0x0110` | `TX_BASE_ADDR_L` | W/R | `0x0` | bits[31:0] low address | TX 从 CPU->FPGA payload window 读数据的低 32 位地址 |
| `0x0114` | `TX_BASE_ADDR_H` | W/R | `0x0` | bits[31:0] high address | 如果当前工程只用 32-bit 地址，可固定为 0 |
| `0x0118` | `TX_WINDOW_BYTES` | W/R | `0x8000` | bits[31:0] window bytes | TX 地址窗口长度，需和软件 buffer 一致 |

### 7.4 RX 方向扩展寄存器

| 偏移 | 名称 | 属性 | 默认值 | 位定义 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `0x0200` | `RX_CTRL` | W/R | `0x0` | bit0 `rx_arm`；bit1 `rx_clear_fifo`；bit2 `rx_drop_enable` | RX 控制。默认只 arm，不建议随意 drop |
| `0x0204` | `RX_FRAME_BYTES` | W/R | `512` | bits[15:0] frame bytes | RX 每帧字节数，默认 512B |
| `0x0208` | `RX_FRAME_COUNT` | R | `0x0` | bits[31:0] received count | 已写入 payload window 的 RX 帧数 |
| `0x020C` | `RX_WRITE_PTR` | R | `0x0` | bits[31:0] write pointer or offset | 当前 RX 写指针或窗口内偏移 |
| `0x0210` | `RX_BASE_ADDR_L` | W/R | `0x0` | bits[31:0] low address | RX 写入 FPGA->CPU payload window 的低 32 位地址 |
| `0x0214` | `RX_BASE_ADDR_H` | W/R | `0x0` | bits[31:0] high address | 当前 32-bit 地址工程可固定为 0 |
| `0x0218` | `RX_WINDOW_BYTES` | W/R | `0x8000` | bits[31:0] window bytes | RX 地址窗口长度，建议不小于软件最大读取块 |
| `0x021C` | `RX_RELEASE` | W | `0x0` | bit0 release current block | CPU 读完当前 RX buffer 后写 1 释放或推进 |

### 7.5 硬件自测扩展寄存器

| 偏移 | 名称 | 属性 | 默认值 | 位定义 | 说明 |
| --- | --- | --- | --- | --- | --- |
| `0x0300` | `HW_TEST_CTRL` | W/R | `0x0` | bit0 start；bit1 stop；bit2 clear；bit3 loopback | 可选硬件自测控制 |
| `0x0304` | `HW_TEST_PATTERN` | W/R | `0x0` | bits[3:0] pattern select | 递增、固定、伪随机等 pattern |
| `0x0308` | `HW_TEST_FRAME_COUNT` | W/R | `0x0` | bits[31:0] frame count | 自测帧数 |
| `0x030C` | `HW_TEST_ERROR_COUNT` | R | `0x0` | bits[31:0] error count | 自测比对错误数 |

硬件自测寄存器不是必须项，但强烈建议在上板早期保留一种可综合 pattern/check 路径。它能把问题分成两类：Aurora/bridge/CONV_DMA 硬件路径问题，或者软件写读 buffer/中断流程问题。

## 8. 如果添加这些寄存器，RTL 工程应如何改

### 8.1 推荐代码组织

如果后续真的把上述寄存器加入工程，建议新增或拆分以下可综合文件：

| 建议文件 | 是否必须 | 职责 |
| --- | --- | --- |
| `fdma_aurora_ctrl_regs.v` | 必须 | AXI-Lite 寄存器读写、默认值、W1C/RC 语义、start/clear/irq enable 输出 |
| `fdma_aurora_status_sync.v` | 推荐 | 将 Aurora、FDMA、FIFO 状态同步到 AXI-Lite 时钟域 |
| `fdma_aurora_irq.v` | 可选 | 汇总 TX done、RX done、error、link down 到 XDMA 用户中断；也可并入寄存器模块 |
| `fdma_aurora_hw_test_engine.v` | 可选 | 上板自测 pattern 生成和比对 |
| `pcie_fdma_aurora_brg_adapter.v` 修改 | 必须 | 增加寄存器控制端口和状态返回端口，并保持在 `PCIe.v` 内连接 `design_1_wrapper` 的 FDMA 口 |

不建议把软件寄存器直接散落写进 `fdma_aurora_brg_tx.v` 或 `fdma_aurora_brg_rx.v`。TX/RX FSM 应继续专注数据面，控制寄存器应集中在 AXI-Lite 控制模块，避免后续软件协议和数据握手互相缠绕。

### 8.2 AXI-Lite 寄存器模块放在哪里

优先方案是在现有 PCIe 顶层或 `INFO_EXCH` 附近增加一个 AXI-Lite 寄存器模块：

```text
XDMA m_axil
  -> AXI interconnect
  -> existing INFO_EXCH
  -> optional fdma_aurora_ctrl_regs
```

有两种实现方式：

1. 扩展现有 `INFO_EXCH.v`
   优点是地址空间和软件入口集中；缺点是原模块会变大，容易影响既有协议。

2. 新增独立 `fdma_aurora_ctrl_regs.v`
   优点是边界清楚，Aurora/FDMA 控制和原 PCIe 基础寄存器解耦；缺点是 Vivado block design 或 AXI interconnect 地址分配要新增一个 slave。

建议优先采用第二种。如果工程时间很紧，且 AXI-Lite 地址空间不方便新增 slave，可以先在 `INFO_EXCH.v` 内扩展，但要保持原 `0x0000-0x0028` 偏移不变。

### 8.3 寄存器模块应输出哪些控制信号

`fdma_aurora_ctrl_regs.v` 建议输出到 `pcie_fdma_aurora_brg_adapter.v` 或同级控制适配层的控制信号包括：

```verilog
tx_start_pulse
tx_abort_pulse
tx_base_addr
tx_window_bytes
tx_frame_bytes
tx_frame_count

rx_arm
rx_clear_fifo_pulse
rx_base_addr
rx_window_bytes
rx_frame_bytes
rx_release_pulse

status_clear_pulse
hw_test_enable
hw_test_start_pulse
hw_test_pattern
```

其中 `*_start_pulse`、`*_clear_pulse`、`*_release_pulse` 建议设计为 AXI-Lite 时钟域下的单周期脉冲，再通过 CDC 逻辑同步到目标时钟域。不要把软件写入的寄存器 bit 长时间直接当成跨时钟 start 使用。

### 8.4 adapter 应返回哪些状态

`pcie_fdma_aurora_brg_adapter.v` 或更高层应返回到寄存器模块的状态包括：

```verilog
channel_up
lane_up
tx_busy
rx_busy
fdma_rbusy
fdma_wbusy
tx_done_pulse
rx_done_pulse
rx_fifo_almost_full
rx_fifo_full
rx_fifo_overflow
tx_underflow
fdma_timeout
link_down
tx_frame_sent_count
rx_frame_count
rx_write_ptr
hw_test_error_count
```

状态返回后应在 AXI-Lite 时钟域进行同步、锁存和清除处理。尤其是 `overflow`、`underflow`、`timeout`、`link_down` 这类事件，不应只做瞬时状态，因为软件轮询可能错过。

### 8.5 跨时钟域处理原则

Aurora、FDMA、AXI-Lite 可能处在不同或派生时钟域。建议遵守以下原则：

- 单 bit 电平状态，例如 `channel_up`、`lane_up`，用两级同步器同步到 AXI-Lite 时钟域。
- 单周期事件，例如 `tx_done`、`rx_done`、`overflow`，用 toggle 或脉冲同步方式跨域。
- 多 bit 计数器，例如 `rx_frame_count`、`rx_write_ptr`，优先在源时钟域稳定采样，或用握手快照，不建议直接逐 bit 同步。
- sticky 位建议在 AXI-Lite 时钟域锁存，并用 W1C 或 clear pulse 清除。
- FIFO 水位如果来自 XPM FIFO，应优先使用 FIFO IP 自身提供的跨域安全状态或在对应读写时钟域转换成 sticky。

### 8.6 `rx_dst_rdy` 不应做成寄存器可控

Aurora RX 输出侧不能接受下游反压，因此：

```verilog
assign rx_dst_rdy = 1'b1;
```

这个设计原则应继续保持。不要新增寄存器 bit 去控制 `rx_dst_rdy`，也不要把 `rx_fifo_full` 直接反接到 `rx_dst_rdy`。

RX 溢出的处理应依赖：

- 足够的 RX FIFO 深度。
- `rx_almost_full` 和 `rx_full` 预警。
- `rx_overflow_sticky` 锁存。
- 上层协议或远端限速。
- 软件及时释放/推进 RX buffer。

### 8.7 建议实施顺序

后续真正改 RTL 时，不建议一次性把所有寄存器、IRQ、自测和数据路径都接上。推荐顺序如下：

1. 只新增 `fdma_aurora_ctrl_regs.v`，先做 AXI-Lite 读写仿真，确认寄存器默认值、W/R、RC、W1C 语义正确。
2. 将 `TX_CTRL/TX_FRAME_*` 接到 TX 地址、长度和帧控制，先验证 CPU -> Aurora 单帧。
3. 将 `RX_CTRL/RX_FRAME_*` 接到 RX 写地址窗口和计数，验证 Aurora -> CPU 单帧。
4. 接入 `AURORA_STATUS/FIFO_STATUS/ERROR_STICKY`，确认 link、FIFO、overflow、underflow 可读可清。
5. 接入 `IRQ_ENABLE/IRQ_STATUS`，验证 done/error/link down 中断。
6. 最后接入可选 `fdma_aurora_hw_test_engine.v`，用于板级自测和长时间稳定性测试。

### 8.8 不建议采用的做法

不建议先改完整 PCIe/XDMA 数据通路。PCIe/XDMA 本身变量很多，先把 Aurora/FDMA/control register 小闭环跑通更容易定位问题。

不建议让 CPU 直接控制 FDMA 单 beat 握手。软件应控制 buffer、长度、start、clear、irq，不应控制 `valid/ready/busy`。

不建议用寄存器控制 `rx_dst_rdy`。该信号必须固定为 1。

不建议把扩展寄存器覆盖原 `0x0000-0x0028` 地址。保持软件兼容比节省几个地址更重要。

不建议把 sticky 状态只接 ILA 不接寄存器。ILA 适合 bring-up，但软件联调和长期运行必须能读到错误状态。

## 9. 软件联调建议

软件端职责应保持清晰：

- 通过 XDMA AXI-Lite 访问控制/status 寄存器。
- 通过 XDMA BRAM/DDR BAR 读写 payload buffer。
- CPU -> Aurora 时，软件写 payload，配置 TX 地址和长度，触发 start，等待 done/IRQ，读取 error，最后清状态。
- Aurora -> CPU 时，软件配置或确认 RX buffer，等待 RX done/IRQ 或轮询 frame count，读取 payload，写 release/clear。
- 软件不参与 FDMA 周期级握手。

建议软件 bring-up 顺序：

1. 读 `VERSION/PROG_TIME/BUF_LEN_MAX`，确认 AXI-Lite 通。
2. 写读 scratch 或扩展控制寄存器，确认 W/R 通。
3. 读 `AURORA_STATUS`，确认 `channel_up/lane_up`。
4. 写 payload buffer，触发 TX 单帧，等待 TX done。
5. 用 Aurora 环回或对端回发，等待 RX done。
6. CPU 读 RX buffer，比对数据。
7. 连续多帧，检查 frame count、FIFO status、error sticky。
8. 人为制造 link down、CPU 慢读、RX 高速输入等异常，确认 sticky 和 clear 机制有效。

## 10. 后续验证建议

后续如果实现寄存器 RTL，建议补充以下验证：

| 验证层级 | 目标 | 重点检查 |
| --- | --- | --- |
| AXI-Lite 寄存器 TB | 证明寄存器可读写且语义正确 | 默认值、W/R、RC、W1C、start pulse、clear pulse |
| Bridge 单元回归 | 确认原 `fdma_aurora_brg` 未被改坏 | 原 `loop_validate` testcase 继续 PASS |
| 最小集成仿真 | 证明 adapter 或早期 wrapper 接 `CONV_DMA/AXI RAM` 语义正确 | 512B/64 beat、地址递增、stall、TX/RX、8KB wrap |
| 控制面 + 数据面仿真 | 证明寄存器能驱动 TX/RX | 软件写寄存器后触发 FDMA，done/irq/status 正确 |
| 板级 bring-up | 证明真实 GT、PCIe、时钟复位和软件环境工作 | PCIe 枚举、BAR 访问、Aurora link、单帧、连续帧、异常 sticky |

### 10.1 stall 检查的含义

`stall` 是 RTL 设计和仿真验证中非常常见的术语，通常表示某一级接口因为暂时不能接收或不能提供数据，导致握手暂停。它不是错误本身，而是正常数字系统里必须支持的流控场景。

在 AXI 或 FDMA 这类 ready/valid 接口中，典型 stall 表现为：

```text
valid = 1
ready = 0
```

这表示发送端已经准备好数据，但接收端暂时不能接收。正确的 RTL 行为是：

- 当前数据必须保持稳定，不能提前跳到下一拍。
- 地址、计数器、FIFO 读使能不能因为 `valid=1` 就推进。
- 只有在 `valid && ready` 同时成立的真实握手周期，数据、地址和计数才允许前进。
- stall 解除后，传输应从原位置继续，不能丢字、重复字或破坏帧边界。

本文里的“写 stall 检查”指的是在 RX 写入方向人为制造 AXI/FDMA 写侧停顿，验证如下通路在写侧不能连续接收时仍然正确：

```text
Aurora LocalLink RX
  -> RX FIFO
  -> fdma_aurora_pcie_conv_dma_wrapper
  -> CONV_DMA write channel
  -> AXI RAM model
```

检查重点不是让系统跑得最快，而是确认写侧 `ready` 间歇拉低时：

- RX 数据不会丢失。
- 同一个 beat 不会被写两次。
- AXI RAM 中的数据顺序正确。
- 写地址只随真实写握手推进。
- 一帧 512B 的边界仍然正确。

### 10.2 `write_stall_enable` 的含义

`write_stall_enable` 是本次 integration testbench 中 `axi_ram_model.sv` 的仿真控制开关，不是最终硬件必须暴露给软件的寄存器，也不是上板必须保留的控制信号。

它的作用是在 AXI RAM model 写通道上模拟“下游暂时不 ready”的情况。也就是说，testbench 打开 `write_stall_enable` 后，AXI RAM model 会有意让写地址或写数据通道产生间歇性等待，从而逼 DUT 经历写侧 stall。

可以把它理解成验证环境里的故障/压力注入开关：

```text
write_stall_enable = 0:
  AXI RAM model 尽量正常接收写事务。

write_stall_enable = 1:
  AXI RAM model 周期性或间歇性拉低 ready，制造写侧停顿。
```

这个开关的意义是证明 DUT 的 RTL 不依赖“下游永远 ready”的理想条件。真实板级系统中，AXI interconnect、BRAM controller、DDR controller 或 `CONV_DMA` 都可能因为仲裁、刷新、等待响应等原因造成短暂停顿，所以仿真必须覆盖这类情况。

需要区分的是：

- `write_stall_enable`：仿真模型开关，用来制造短暂停顿，最终产品 RTL 一般不需要。
- `write_block_enable`：仿真模型开关，用来长时间阻塞写侧，制造 RX FIFO 压力和 overflow 场景。
- `fdma_wready` 或 AXI `WREADY`：真实接口上的 ready 信号，是 RTL 必须正确处理的握手信号。

### 10.3 sticky 的含义

`sticky` 也是 RTL 和寄存器设计中常见的术语，一般指“事件一旦发生就锁存为 1，直到软件或硬件 clear”。中文可以理解为“粘滞位”“锁存状态位”或“保持型错误状态”。

普通状态位只反映当前瞬时状态，例如：

```text
rx_fifo_full = 1:
  当前这一刻 RX FIFO 是满的。

rx_fifo_full = 0:
  当前这一刻 RX FIFO 不是满的。
```

sticky 状态位反映“曾经发生过”，例如：

```text
rx_overflow_sticky = 1:
  自上次清除以来，RX FIFO 曾经发生过 overflow。
  即使当前 FIFO 已经不满，该位仍保持为 1。
```

sticky 位适合捕获软件轮询或 ILA 观察时可能错过的短脉冲事件，例如：

- `rx_overflow_sticky`：RX FIFO 曾经溢出。
- `tx_underflow_sticky`：TX 方向曾经欠读或无数据可发。
- `fdma_timeout_sticky`：FDMA 请求曾经超时。
- `link_down_sticky`：Aurora 链路曾经掉线。

后续接 AXI-Lite 寄存器时，sticky 位通常配合 W1C 语义使用：

```text
CPU 读 ERROR/STATUS 寄存器:
  看到 sticky 位是否置 1。

CPU 写 1 到对应 bit:
  清除该 sticky 位。

CPU 写 0 到对应 bit:
  不影响该 sticky 位。
```

因此可以确认：`stall` 和 `sticky` 都是 RTL/FPGA 设计与验证领域常用术语。`stall` 更偏向接口握手和流水线流控；`sticky` 更偏向状态寄存器、错误锁存和软件可观测性。

早期 `fdma_aurora_pcie_conv_dma_wrapper.v` 最小集成仿真已经覆盖：

- 一帧 512B 对 `CONV_DMA` 输出 64 beat。
- RX 写入 AXI RAM 的数据顺序和地址。
- TX 从 AXI RAM 读出后的 LocalLink 帧边界。
- AXI 写 stall、AXI 读 stall、TX `dst_rdy` stall。
- 8KB 地址窗口回绕。
- RX FIFO almost_full/full/overflow sticky。
- link down sticky 和状态清除。

但是完整上板前仍需要：

- 综合、实现、时序通过。
- GT/refclk/lane/SFP/PCIe 约束正确。
- PCIe XDMA 可枚举，BAR 可访问。
- ILA/VIO 或状态寄存器能观测 `channel_up/lane_up`、FDMA 握手、FIFO 水位、overflow/underflow、地址和帧计数。
- 软件能完成一次 TX、一次 RX、一次环回读回，并正确处理 done/irq/clear/error。

## 11. 结论

本次新增文件的核心价值，是把 `fdma_aurora_brg` 从单独 bridge 验证推进到 PCIe/`CONV_DMA` 最小集成验证。它证明了 512B Aurora frame、64-bit FDMA beat、`CONV_DMA` AXI burst、地址窗口和 FIFO 风险状态之间的关键关系。

后续真正集成到现有 PCIe 工程时，应保留原 CPU-FPGA PCIe 交互方案的软件控制面，以扩展寄存器和 `pcie_fdma_aurora_brg_adapter.v` 适配层接入 Aurora/FDMA 数据面。寄存器 RTL 应集中实现，跨时钟状态应同步和 sticky 锁存，`rx_dst_rdy` 应继续固定为 1。这样既能复用当前验证成果，也能保持软件协议稳定，降低上板 bring-up 风险。
