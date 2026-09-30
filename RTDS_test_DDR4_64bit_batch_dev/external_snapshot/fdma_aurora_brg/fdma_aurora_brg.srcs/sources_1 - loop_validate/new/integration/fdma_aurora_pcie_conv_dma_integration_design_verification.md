# fdma_aurora_brg 接入 CONV_DMA 的最小集成设计与验证说明

## 1. 背景

现有 `fdma_aurora_brg` 工程原本重点验证的是 Aurora LocalLink 与 FDMA 风格接口之间的桥接关系：

```text
FDMA read -> TX async FIFO -> Aurora LocalLink TX
Aurora LocalLink RX -> RX async FIFO -> FDMA write
```

现有 PCIe 工程的数据面则使用米联社公开资源 `CONV_DMA` 把 FDMA 风格接口转换到 AXI，再接 XDMA/AXI BRAM。此次最小集成验证的目标不是仿真完整 PCIe Root Complex，也不是跑完整 XDMA，而是证明 bridge 接上 `CONV_DMA` 后，关键语义仍然正确：

```text
LocalLink BFM <-> fdma_aurora_pcie_conv_dma_wrapper <-> CONV_DMA <-> AXI RAM model
```

这个仿真层位于原 bridge 单元回归与板级 bring-up 之间。原 `loop_validate` testcase 继续用于确认 bridge 内部未被改坏；新增 integration TB 用于确认 bridge 接入 `CONV_DMA/AXI RAM` 后，`size/address/data/handshake/FIFO status` 语义正确。

## 2. 关键约束

### 2.1 `CONV_DMA` 的 size 语义

`CONV_DMA.v` 中 `fdma_wsize/fdma_rsize` 被当作 64-bit beat 数使用：

- 512B frame = 64 个 64-bit beat。
- 因此接 `CONV_DMA` 时应传 `fdma_*size = 64`。
- 原 bridge 内部 RX 侧 `fdma_wsize = 512` 是 byte-size 风格，适合原自测/调试语义，但不能直接作为 `CONV_DMA` 的 size。

本次新增 wrapper 做了 size 适配：

```text
bridge raw fdma_wsize = 512 bytes
wrapper fdma_wsize    = 64 beats
wrapper fdma_rsize    = 64 beats
```

### 2.2 Aurora RX 不接受反压

Aurora RX 输出侧不能被下游反压，因此 `rx_dst_rdy` 必须保持 `1'b1`。本次没有把 `rx_dst_rdy` 改成 FIFO full 相关信号。

风险处理方式改为：

- RX FIFO 足够大。
- 暴露 `almost_full/full/overflow` 状态。
- wrapper 中锁存 sticky 状态，供 ILA/寄存器/软件读取。
- 压力验证中确认 `rx_dst_rdy` 始终为 1，同时 FIFO 压力会被 sticky status 捕获。

## 3. 设计修改

### 3.1 `fdma_aurora_brg_tx.v`

新增参数：

```verilog
parameter integer MEM_WINDOW_BYTES = 4096
```

作用：

- 原默认行为保持 4KB 地址窗口，不影响已有 bridge 单元回归。
- integration wrapper 可配置为 8KB 窗口，用于验证 16 帧 x 512B 后地址从 `0x1E00` 回绕到 `0x0000`。

### 3.2 `fdma_aurora_brg_rx.v`

新增参数：

```verilog
parameter integer MEM_WINDOW_BYTES = 4096
```

新增可综合状态输出：

```verilog
output rx_fifo_almost_full
output rx_fifo_full
output rx_fifo_overflow
```

作用：

- 默认地址窗口仍为 4KB。
- RX FIFO 真实水位状态不再只靠 debug bus 计数反推。
- wrapper 可直接使用 XPM FIFO 的 `almost_full/full/overflow` 状态生成 sticky。
- `rx_dst_rdy` 保持 `1'b1`，没有加入下游反压。

### 3.3 `fdma_aurora_brg_top.v`

新增参数透传：

```verilog
parameter integer MEM_WINDOW_BYTES = 4096
```

新增 RX FIFO 状态透传：

```verilog
output rx_fifo_almost_full
output rx_fifo_full
output rx_fifo_overflow
```

作用：

- 让 TX/RX 的地址窗口在 wrapper 中统一配置。
- 让上层可综合逻辑可以直接观测 RX FIFO 风险状态。

### 3.4 `fdma_aurora_pcie_conv_dma_wrapper.v`

新增文件。它是面向 PCIe/`CONV_DMA` 集成的桥接适配层。

主要功能：

- 实例化 `fdma_aurora_brg_top`。
- 将 bridge 的 512B frame 转成 `CONV_DMA` 需要的 64-beat size。
- 输出 `fdma_rsize/fdma_wsize = FRAME_BYTES/8`。
- 保留 `bridge_fdma_wsize_raw`，便于确认原 bridge RX raw size 仍为 512。
- 默认把 `MEM_WINDOW_BYTES` 设为 8192。
- 保留 Aurora LocalLink TX/RX 接口。
- 保留 FDMA read/write 接口。
- 增加 sticky 状态：
  - `rx_almost_full_sticky`
  - `rx_full_sticky`
  - `rx_overflow_sticky`
  - `tx_underflow_sticky`
  - `link_down_sticky`
  - `fdma_timeout_sticky`

这些 sticky 适合后续接 AXI-Lite 状态寄存器或 ILA。

## 4. 最小集成仿真结构

### 4.1 AXI RAM model

新增文件：

```text
new/integration/axi_ram_model.sv
```

功能：

- 模拟 64-bit AXI RAM。
- 支持 AXI AW/W/B 和 AR/R 通道。
- 记录：
  - AW 接收次数
  - AR 接收次数
  - 写入 word 数
  - 读出 word 数
  - 最近一次 AW/AR 地址
- 支持插入 stall：
  - `write_stall_enable`
  - `read_stall_enable`
  - `write_block_enable`
  - `read_block_enable`

`write_block_enable` 用于 RX 压力场景：阻塞 AXI 写侧，让 RX FIFO 不能继续向 RAM 泄放，从而验证 FIFO sticky。

### 4.2 Integration testbench

新增文件：

```text
new/integration/tb_fdma_aurora_brg_conv_dma_integration.sv
```

DUT 结构：

```text
LocalLink RX driver
        |
        v
fdma_aurora_pcie_conv_dma_wrapper
        |
        v
CONV_DMA
        |
        v
axi_ram_model
```

TX 方向则由 AXI RAM 预置数据，经 `CONV_DMA -> wrapper -> LocalLink TX monitor` 读出。

## 5. 覆盖的验证点

### 5.1 Size 与 AXI burst

检查项：

- `fdma_rsize == 64`
- `fdma_wsize == 64`
- `bridge_fdma_wsize_raw == 512`
- AXI 写地址通道 `AWLEN == 63`
- AXI 读地址通道 `ARLEN == 63`
- `AWSIZE/ARSIZE == 3`，即每 beat 8 bytes。

验证意义：

一帧 512B 被正确转换为 64 个 64-bit AXI beat，没有把 byte size 错接到 `CONV_DMA`。

### 5.2 RX 写入路径

场景：

- LocalLink RX 注入 2 帧。
- 每帧 64 beat。
- AXI RAM 中检查 frame 0 写到 `0x000`，frame 1 写到 `0x200`。

检查项：

- 数据顺序不乱。
- 地址递增 0x200。
- 帧边界不吞、不重。

### 5.3 AXI 写 stall

场景：

- 打开 `write_stall_enable`。
- RX 注入 1 帧。
- 检查 RAM 中数据仍然完整有序。

验证意义：

`fdma_wready` 停顿时，RX 写数据保持寄存器不应丢字或重复。

### 5.4 TX 读出路径

场景：

- AXI RAM 预置 2 帧 pattern。
- 打开 `read_stall_enable`。
- LocalLink TX monitor 捕获 2 帧。
- TX `dst_rdy` 插入停顿。

检查项：

- `SOF` 只在首 beat。
- `EOF` 只在末 beat。
- `REM == 3'b111`。
- 数据与 AXI RAM 预置 pattern 一致。

验证意义：

AXI read 空拍和 TX 端反压不会导致 TX FIFO 读错、计数错或帧边界错。

### 5.5 8KB 地址窗口回绕

场景：

- wrapper 配置 `MEM_WINDOW_BYTES = 8192`。
- TX 方向请求 16 个 512B burst。

期望地址序列：

```text
0x0000
0x0200
0x0400
...
0x1E00
下一次回到 0x0000
```

验证意义：

证明 wrapper 用 8KB window 接入 PCIe buffer 语义时，bridge 地址推进不会仍卡在原 4KB 默认窗口。

### 5.6 RX FIFO 压力与 sticky

场景：

- `rx_dst_rdy` 保持 1。
- AXI 写侧被 `write_block_enable` 阻塞。
- 连续注入超过 RX FIFO 深度的数据。

检查项：

- `aurora_rx_dst_rdy` 仍为 1。
- `rx_almost_full_sticky` 置位。
- `rx_full_sticky` 置位。
- `rx_overflow_sticky` 置位。

验证意义：

这个场景不是要靠下游反压保护 Aurora RX，而是确认不可反压条件下的风险可被硬件状态捕获，后续可通过 ILA/寄存器/软件策略处理。

### 5.7 link down sticky

场景：

- `channel_up` 建立后拉低。

检查项：

- `link_down_sticky` 置位。
- `status_clear` 可清 sticky。

验证意义：

上板 bring-up 时可定位 Aurora link down/up 异常。

## 6. 直接 XSim 运行

新增脚本：

```text
regression/run_integration_xsim.ps1
```

默认工具路径：

```text
D:\Xilinx_2020_2\Vivado\2020.2\bin
```

运行方式：

```powershell
powershell.exe -ExecutionPolicy Bypass -File "E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\run_integration_xsim.ps1"
```

脚本执行内容：

1. 编译 XPM：

```text
xpm_cdc.sv
xpm_fifo.sv
```

2. 编译设计与 TB：

```text
cdc_sync.v
fdma_aurora_brg_tx.v
fdma_aurora_brg_rx.v
fdma_aurora_brg_top.v
fdma_aurora_pcie_conv_dma_wrapper.v
glbl.v
CONV_DMA.v
axi_ram_model.sv
tb_fdma_aurora_brg_conv_dma_integration.sv
```

3. elaboration：

```text
xelab -debug typical -L xpm work.tb_fdma_aurora_brg_conv_dma_integration work.glbl
```

4. xsim batch：

```text
xsim tb_fdma_aurora_brg_conv_dma_integration_sim -tclbatch run_all.tcl
```

脚本最后会检查 `xsim.log`，必须出现：

```text
TEST PASS: fdma_aurora_brg CONV_DMA integration
```

如果没有 PASS，或者出现 `TEST FAIL/Error/Fatal`，脚本会返回失败。

## 7. 本次实跑结果

运行环境：

```text
Vivado/XSim 2020.2
工具路径：D:\Xilinx_2020_2\Vivado\2020.2\bin
工作目录：E:\PCIE-CPU\fdma_aurora_brg\xsim_integration_work
日期：2026-07-07
```

结果：

```text
TEST PASS: fdma_aurora_brg CONV_DMA integration
```

日志位置：

```text
E:\PCIE-CPU\fdma_aurora_brg\xsim_integration_work\xsim.log
```

补充回归：

除新增 integration TB 外，还用直接 XSim 脚本跑了两个原 bridge 回归用例：

```text
tc_brg_wr_ready_stall : PASS
tc_brg_rd_ready_stall : PASS
```

对应脚本：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\regression\run_bridge_tc_xsim.ps1
```

备注：

- XPM 编译期间有 Vivado 2020.2 自带 warning/info，例如 `XPM_MEMORY 20-1`，不影响仿真结果。
- 第一版 direct XSim 脚本遇到两个工具问题，已修复：
  - XPM CDC 需要编译并 elaboration `glbl.v`。
  - `-tclbatch` 路径不能包含空格，否则 XSim 2020.2 内部 `source` 会按空格拆路径；脚本已把工作目录移到无空格路径。
- 第一版 TB 暴露 RX BFM 驱动时序问题，已改为下降沿准备数据、上升沿由 DUT 采样，并等待 XPM FIFO reset-busy 释放。

## 8. 对板级集成的作用

这次最小集成仿真通过后，可以说明：

- wrapper 的 size 适配方向正确。
- `CONV_DMA` 看见的是 64 beat，而不是 512 byte。
- 512B frame 到 AXI burst 的映射正确。
- RX 写 RAM、TX 读 RAM的基本数据面能跑通。
- 8KB buffer window 的地址回绕可控。
- AXI stall/TX `dst_rdy` stall 不破坏数据顺序。
- RX 不可反压风险已经有可综合 sticky 观测点。

但它不等价于“可以跳过板级验证”。上板仍然需要检查：

- PCIe XDMA 枚举和 BAR 访问。
- Aurora GT/refclk/lane/SFP 管脚和时钟复位。
- `channel_up/lane_up` 稳定性。
- ILA/VIO 或 AXI-Lite 状态寄存器是否能看到 FIFO/sticky/FDMA 状态。
- 软件是否按 TX/RX start/done/irq/clear/error 流程推进 buffer。

## 9. 后续建议

板级最小闭环建议按下面顺序做：

1. 保留或接入 `fdma_aurora_pcie_conv_dma_wrapper`。
2. 将 sticky 状态接到 AXI-Lite 状态寄存器或 ILA。
3. 软件先只做 BRAM BAR pattern 写读。
4. 软件触发 TX，从 Aurora 环回或对端回发，再读 RX buffer 比对。
5. 连续多帧压力测试时重点看：
   - `rx_almost_full_sticky`
   - `rx_full_sticky`
   - `rx_overflow_sticky`
   - `tx_underflow_sticky`
   - `fdma_timeout_sticky`
   - `link_down_sticky`

只要这些状态能被软件读到并能清除，硬件 bring-up 会比直接盯 ILA 波形轻很多。
