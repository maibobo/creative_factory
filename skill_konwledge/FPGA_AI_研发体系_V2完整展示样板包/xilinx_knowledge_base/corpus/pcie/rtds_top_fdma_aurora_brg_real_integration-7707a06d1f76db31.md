# rtds_top_fdma_aurora_brg_real_integration

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\rtds_top_fdma_aurora_brg_real_integration.md`
- SHA-256: `7707a06d1f76db310df95c46af8418859950691c071c36ab43f92acf2d9e873b`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test 以 TOP.v 为顶层集成 fdma_aurora_brg 的真实方案与验证计划

## 1. 文档目的

本文记录本次把 `fdma_aurora_brg` 嵌入 `RTDS_test` 工程的真实设计方案、RTL 修改、Vivado 工程添加方式、实际执行命令、当前验证结果，以及工程完成后应如何继续做仿真验证和上板验证。

核心修正点是：板级顶层保持 `TOP.v`，不把早上新增的 `fdma_aurora_pcie_conv_dma_wrapper.v` 当成系统 top 或真实集成层。真实嵌入点在：

```text
TOP.v -> PCIe.v -> pcie_fdma_aurora_brg_adapter.v -> design_1_wrapper/CONV_DMA
```

早上的 wrapper 和 integration testbench 仍有价值，但它们属于局部接口语义验证，不等于已经和原 `RTDS_test` PCIe 工程完成系统集成。

## 2. 真实工程层级

本次集成后的目标层级为：

```text
TOP.v
  ├─ DATA_CDC.v
  │   ├─ Aurora/debug -> PCIe 66-bit stream
  │   └─ PCIe -> Aurora/debug 66-bit stream
  ├─ PCIe.v
  │   ├─ pcie_fdma_aurora_brg_adapter.v
  │   │   ├─ fdma_aurora_brg_tx.v
  │   │   └─ fdma_aurora_brg_rx.v
  │   ├─ ila_FDMA
  │   └─ design_1_wrapper.v
  │       ├─ CONV_DMA
  │       ├─ INFO_EXCH
  │       └─ XDMA/PCIe/BRAM
  ├─ CLK_GEN
  ├─ TEMP_RD
  └─ LED
```

`TOP.v` 仍是 Vivado synthesis top。`PCIe.v` 保持原模块名和原端口，因此 `TOP.v` 中的 `PCIe_inst` 不需要改接口。新增 adapter 放在 `PCIe.v` 内部，真正接入原工程已有的 66-bit stream、`INFO_EXCH` 控制信号和 `design_1_wrapper` 的 FDMA 端口。

## 3. 为什么不能直接使用早上的 wrapper

`fdma_aurora_pcie_conv_dma_wrapper.v` 的作用是验证下面这条局部链路：

```text
LocalLink BFM <-> fdma_aurora_brg <-> CONV_DMA <-> AXI RAM model
```

它并不知道 `RTDS_test` 的真实工程边界：

- `TOP.v` 中通过 `DATA_CDC` 使用的是 66-bit `{SOF,data[63:0],EOF}` stream，不是直接暴露 LocalLink 端口。
- `PCIe.v` 中已有 `INFO_EXCH` 输出的 `RD_START`、`CPU_FPGA_START_ADDR`、`CPU_FPGA_LEN`、`INT_STATE`、`CPU_REC_STATE` 等控制和状态语义。
- `CONV_DMA` 位于 `design_1_wrapper` block design 内，FDMA 端口已经由 BD wrapper 暴露出来。
- 原软件协议依赖 XDMA BAR、`INFO_EXCH` 寄存器和中断流程，不能绕开。

因此真实工程需要一个理解原 PCIe 工程语义的中间层，即本次新增的 `pcie_fdma_aurora_brg_adapter.v`。

## 4. 本次 RTL 修改

### 4.1 新增 `pcie_fdma_aurora_brg_adapter.v`

路径：

```text
E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\pcie_fdma_aurora_brg_adapter.v
```

主要职责：

| 功能 | 实现含义 |
| --- | --- |
| 66-bit RX 转 bridge RX | `SOF=bit65`，`data=bit64:1`，`EOF=bit0`，输入到 `fdma_aurora_brg_rx` |
| bridge TX 转 66-bit TX | 将 TX 输出重新打包为 `{SOF,data,EOF}`，送回 `DATA_CDC` 方向 |
| TX 软件控制 | 接收 `RD_START`、`CPU_FPGA_START_ADDR`、`CPU_FPGA_LEN`，检查 512B 对齐，启动 FDMA read |
| RX 写入通知 | 每完成一个 RX 512B frame，更新 `FPGA_CPU_START_ADDR`、`FPGA_CPU_LEN`，置 `INT_STATE_W` 和 `FPGA_CPU_irq_req` |
| FDMA size 适配 | 对 `CONV_DMA` 输出 `fdma_rsize=64`、`fdma_wsize=64`，含义是 64 个 64-bit beat，即 512B |
| 地址扩展 | 将 32-bit base/offset 显式扩展成 64-bit FDMA 地址 `{32'd0, addr}` |
| 错误 sticky | 锁存 `rx_overflow_sticky`、`tx_underflow_sticky`、`fdma_timeout_sticky`、`length_error_sticky` |

RX 方向仍遵守原风险判断：Aurora 输出侧不能接受反压，`rx_dst_rdy` 在 bridge 内保持等效固定为 1。FIFO 满或压力过大时不向 Aurora 反压，而是通过 full/almost_full/overflow sticky 暴露风险。

### 4.2 修改 `PCIe.v`

路径：

```text
E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\PCIe.v
```

修改要点：

- 保留 `PCIe` 模块名和端口，`TOP.v` 不需要把顶层切到其它模块。
- 保留 `design_1_wrapper` 例化，继续使用 BD 内的 XDMA、`CONV_DMA`、`INFO_EXCH`。
- 新增 `FRAME_BYTES=512`、`MEM_WINDOW_BYTES=32*1024`。
- FDMA 地址线改成显式 64-bit，避免隐式位宽扩展。
- 例化 `pcie_fdma_aurora_brg_adapter.v`。
- 将 `i_wr_data_valid/i_wr_data[65:0]` 接入 adapter RX。
- 将 adapter TX 输出接到 `o_rd_data_valid/o_rd_data[65:0]`。
- 将 `INFO_EXCH` 相关控制信号接入 adapter。
- 将 adapter FDMA 口接到 `design_1_wrapper` 的 `fdma_*_0`。
- 保留 `ila_FDMA`，并把部分 probe 改为 adapter 状态和 FDMA 状态。

当前 `link_enable` 暂接 `user_lnk_up_int`。这是因为当前 `TOP/DATA_CDC` 侧还没有真实 Aurora `channel_up` 信号进入 `PCIe.v`。后续真实 Aurora 接入时，应把 `channel_up/lane_up` 同步后作为 adapter 的有效链路状态。

### 4.3 本次未做的 RTL 项

本次没有把扩展状态寄存器真正加入 AXI-Lite 地址空间。原因是当前 `INFO_EXCH` 位于 block design 里，若直接新增端口或新增 AXI-Lite slave，需要同步修改 BD、地址分配、wrapper 端口和软件地址表。

当前 sticky/status 先在 adapter 和 ILA 级别可观察。后续若要软件可读，推荐新增或扩展：

```text
fdma_aurora_ctrl_regs.v
fdma_aurora_status_sync.v
fdma_aurora_irq.v
fdma_aurora_hw_test_engine.v
```

## 5. 数据流和控制流

### 5.1 CPU -> Aurora/debug TX

```text
CPU writes XDMA payload buffer
  -> CPU writes CPU_FPGA_START_ADDR / CPU_FPGA_LEN
  -> CPU writes CPU_WR_DONE
  -> INFO_EXCH emits RD_START
  -> pcie_fdma_aurora_brg_adapter starts TX
  -> fdma_raddr = {32'd0, CPU_FPGA_START_ADDR + offset}
  -> fdma_rsize = 64
  -> CONV_DMA reads 512B frame
  -> fdma_aurora_brg_tx emits frame
  -> adapter outputs 66-bit {SOF,data,EOF}
  -> DATA_CDC/Aurora direction
  -> adapter sets CPU_WR_DONE_resp
```

约束：

- `CPU_FPGA_LEN` 必须 512B 对齐。
- 不对齐时 adapter 不启动 TX，并置 `length_error_sticky`。
- 软件只控制地址、长度、start/clear，不参与 FDMA 单拍握手。

### 5.2 Aurora/debug RX -> CPU

```text
DATA_CDC/Aurora direction emits 66-bit {SOF,data,EOF}
  -> PCIe.v forwards stream to adapter
  -> adapter feeds fdma_aurora_brg_rx
  -> RX FIFO accumulates data
  -> adapter/bridge issues fdma_wareq
  -> fdma_wsize = 64
  -> CONV_DMA writes 512B frame into payload buffer
  -> adapter updates FPGA_CPU_START_ADDR / FPGA_CPU_LEN
  -> adapter sets INT_STATE_W and FPGA_CPU_irq_req
  -> CPU reads payload buffer and clears/advances state
```

RX 重点风险：

- 下游不能用 `rx_dst_rdy` 反压 Aurora。
- 如果 CPU 读取太慢、FDMA 写侧 stall 太久或远端持续高速输入，RX FIFO 可能满。
- 这种情况应通过 `rx_fifo_almost_full/rx_fifo_full/rx_overflow_sticky` 让 ILA 或后续寄存器捕获。

## 6. Vivado 工程添加方式

### 6.1 Tcl 脚本

脚本路径：

```text
E:\PCIE-CPU\RTDS_test\regression\add_fdma_aurora_brg_to_rtds_project.tcl
```

如果工程路径变化，通常只需要修改前三个路径变量：

```tcl
set project_path {E:/PCIE-CPU/RTDS_test/RTDS_test.xpr}
set rtds_root    {E:/PCIE-CPU/RTDS_test/RTDS_test.srcs/sources_1/new}
set brg_root     {E:/PCIE-CPU/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new}
```

脚本加入的 Design Sources：

```text
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\cdc_sync.v
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_tx.v
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_rx.v
E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_top.v
E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\pcie_fdma_aurora_brg_adapter.v
```

脚本还设置：

```tcl
set_property top TOP [get_filesets sources_1]
set_property xpm_libraries {XPM_CDC XPM_FIFO} [current_project]
update_compile_order -fileset sources_1
```

说明：脚本最终没有保留 `save_project`。Vivado 2020.2 对该工程执行 `save_project` 时曾出现 project name/path 相关异常；当前添加动作已经写入 `.xpr`，后续在 GUI 中打开工程再保存也可以。`.xpr` 中已经确认新增文件和 XPM 库存在。

### 6.2 GUI 手动检查/添加步骤

如果不用 Tcl，也可以在 GUI 中按以下步骤检查：

1. 打开 `E:\PCIE-CPU\RTDS_test\RTDS_test.xpr`。
2. 在 Sources 视图中确认 Design Sources top 是 `TOP`。
3. 确认层级中存在 `TOP -> PCIe -> pcie_fdma_aurora_brg_adapter`。
4. 如果缺文件，选择 Add Sources -> Add or Create Design Sources，加入 6.1 中列出的 5 个设计文件。
5. Project Settings 中确认 XPM 仿真库/工程属性包含 `XPM_CDC` 和 `XPM_FIFO`。
6. 不要把 `fdma_aurora_pcie_conv_dma_wrapper.v` 设成 top，也不要把它当成 `RTDS_test` 的真实系统集成层。

## 7. 实际执行命令记录

### 7.1 Vivado 工程添加命令

```powershell
& "D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat" `
  -mode batch `
  -source "E:\PCIE-CPU\RTDS_test\regression\add_fdma_aurora_brg_to_rtds_project.tcl"
```

结果：

- `RTDS_test.xpr` 已收录 `pcie_fdma_aurora_brg_adapter.v`、`fdma_aurora_brg_tx.v`、`fdma_aurora_brg_rx.v`、`fdma_aurora_brg_top.v`。
- `TOP` 仍是 `sources_1` 的 top module。
- 工程属性包含 `XPM_CDC` 和 `XPM_FIFO`。
- Vivado 报出若干 2020.1 -> 2020.2 IP locked/catalog revision 警告，这是原工程 IP 版本状态，不是 adapter 语法错误。

### 7.2 XSim adapter smoke 命令

跳过工程更新，只做 XSim 编译/展开 smoke：

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File "E:\PCIE-CPU\RTDS_test\regression\run_top_bridge_xsim.ps1" `
  -SkipProjectUpdate
```

完整路径，先更新 Vivado 工程，再编译/展开 adapter：

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File "E:\PCIE-CPU\RTDS_test\regression\run_top_bridge_xsim.ps1"
```

脚本会调用：

```text
xvlog.bat
xelab.bat
xsim.bat
```

工作目录：

```text
E:\PCIE-CPU\RTDS_test\xsim_top_bridge_work
```

当前结果：

- `xvlog` 通过。
- `xelab` 成功生成 `pcie_fdma_aurora_brg_adapter_elab`。
- `xsim` 运行 1 ns smoke 通过。
- 该结果只证明 adapter 及其依赖的 `fdma_aurora_brg_tx/rx`、XPM FIFO/CDC 可以被 XSim 编译和展开，不等同于功能仿真全部通过。

### 7.3 工程收录检查命令

```powershell
Select-String `
  -Path "E:\PCIE-CPU\RTDS_test\RTDS_test.xpr" `
  -Pattern "pcie_fdma_aurora_brg_adapter|fdma_aurora_brg_tx|fdma_aurora_brg_rx|fdma_aurora_brg_top|XPM_CDC|XPM_FIFO|TOP"
```

检查结果显示：

- `.xpr` 中存在 `pcie_fdma_aurora_brg_adapter.v`。
- `.xpr` 中存在 `fdma_aurora_brg_tx.v`、`fdma_aurora_brg_rx.v`、`fdma_aurora_brg_top.v`。
- `.xpr` 中存在 `XPM_CDC` 和 `XPM_FIFO`。
- `sources_1` 的 `TopModule` 为 `TOP`。

### 7.4 根目录清理检查命令

```powershell
Get-ChildItem -LiteralPath "E:\PCIE-CPU" -Force |
  Where-Object { $_.Name -like "RTDS_test*" } |
  Select-Object Name,FullName,LastWriteTime,PSIsContainer
```

检查结果显示，当前 `E:\PCIE-CPU` 根目录下只保留真实工程目录：

```text
E:\PCIE-CPU\RTDS_test
```

### 7.5 `PCIe.v` 语法级编译检查命令

为了确认真实嵌入点本身没有 Verilog 语法问题，又避免完整展开 BD/IP，执行过一条 `xvlog` 语法级检查。该检查编译 XPM、bridge、adapter、`design_1_wrapper.v` 和 `PCIe.v`，但不 `xelab TOP`，因此不要求展开 `design_1` 内部 XDMA/IP。

```powershell
$vivadoBin='D:\Xilinx_2020_2\Vivado\2020.2\bin'
$vivadoRoot=(Resolve-Path (Join-Path $vivadoBin '..')).Path
$work='E:\PCIE-CPU\RTDS_test\xsim_pcie_syntax_work'
if(Test-Path $work){Remove-Item -LiteralPath $work -Recurse -Force}
New-Item -ItemType Directory -Path $work | Out-Null
Push-Location $work
try {
  & (Join-Path $vivadoBin 'xvlog.bat') -sv -work xpm `
    (Join-Path $vivadoRoot 'data\ip\xpm\xpm_cdc\hdl\xpm_cdc.sv') `
    (Join-Path $vivadoRoot 'data\ip\xpm\xpm_fifo\hdl\xpm_fifo.sv')

  & (Join-Path $vivadoBin 'xvlog.bat') -sv -L xpm -work work `
    'E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\cdc_sync.v' `
    'E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_tx.v' `
    'E:\PCIE-CPU\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_rx.v' `
    'E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\pcie_fdma_aurora_brg_adapter.v' `
    'E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\bd\design_1\hdl\design_1_wrapper.v' `
    'E:\PCIE-CPU\RTDS_test\RTDS_test.srcs\sources_1\new\PCIe.v'
} finally {
  Pop-Location
}
```

结果：

- `xvlog` 成功分析 `pcie_fdma_aurora_brg_adapter`、`design_1_wrapper` 和 `PCIe`。
- 已核对 `design_1_wrapper` 中 `fdma_raddr_0/fdma_waddr_0` 为 64-bit，`fdma_rsize_0/fdma_wsize_0` 为 16-bit，和 `PCIe.v` 当前连线一致。
- 这仍不是完整 TOP elaboration，不替代后续工程综合和 BD/IP 检查。

## 8. 当前验证结论

当前已经完成：

| 项目 | 结果 |
| --- | --- |
| `TOP` 保持为 synthesis top | 已确认 |
| adapter 加入 `PCIe.v` | 已完成 |
| adapter 源文件加入 Vivado 工程 | 已确认 |
| 米联社 bridge 依赖文件加入 Vivado 工程 | 已确认 |
| XPM 库设置 | 已确认 |
| adapter XSim 编译/展开 smoke | 通过 |
| `PCIe.v` 语法级 `xvlog` 检查 | 通过 |

当前尚未完成：

| 项目 | 说明 |
| --- | --- |
| 完整功能仿真 | 还需要 adapter 级或 `PCIe.v` 级 testbench 检查真实 TX/RX 数据 |
| `INFO_EXCH` 扩展寄存器 | 当前没有新增 AXI-Lite 可读 sticky/status 寄存器 |
| 完整综合/实现/时序 | 还未运行，且需要先处理 Vivado 2020.1 IP 在 2020.2 下的 locked 状态 |
| 真实 Aurora 接入 | 当前仍沿用 `TOP/DATA_CDC` 的 66-bit stream 边界，真实 `channel_up/lane_up` 后续再接 |
| 上板验证 | 还未做，需要按分阶段 bring-up 执行 |

## 9. 工程做完后的仿真验证计划

仿真要分层做，不能只依赖上板现象。推荐顺序如下。

### 9.1 Bridge 单元回归

目标：确认米联社公开 bridge 源码和本次参数改动没有破坏原始 TX/RX 行为。

检查内容：

- 原 `loop_validate` testcase 继续 PASS。
- TX 方向 FDMA read 到 LocalLink/66-bit frame 的 SOF/EOF/data 正确。
- RX 方向 LocalLink/66-bit frame 到 FDMA write 的数据顺序正确。
- `rx_dst_rdy` 等效固定为 1。
- RX FIFO full/almost_full/overflow sticky 能触发。

### 9.2 Adapter 最小功能 TB

目标：证明真实 `pcie_fdma_aurora_brg_adapter.v` 的控制语义和 FDMA 语义正确。

DUT 建议为：

```text
pcie_fdma_aurora_brg_adapter
  <-> FDMA/CONV_DMA BFM or CONV_DMA + AXI RAM model
```

必测用例：

| 用例 | 预期 |
| --- | --- |
| CPU->TX 单帧 | `RD_START` 后发起 `fdma_rareq`，`fdma_rsize=64`，输出 66-bit frame |
| CPU->TX 多帧 | 地址每帧递增 512B，帧数符合 `CPU_FPGA_LEN/512` |
| 长度不对齐 | `CPU_FPGA_LEN` 非 512B 对齐时不启动，置 `length_error_sticky` |
| RX 单帧写入 | 输入一帧 66-bit stream 后发起 `fdma_wareq`，`fdma_wsize=64`，置 IRQ/INT |
| RX 多帧写入 | RX 地址窗口按 512B 递增，达到窗口末尾后回绕 |
| FDMA read stall | `fdma_rvalid` 间歇停顿时 TX 不丢字、不重复 |
| FDMA write stall | `fdma_wready` 间歇停顿时 RX 写入顺序和地址正确 |
| RX 压力 | FIFO almost_full/full/overflow sticky 能被观察 |

这里的 “stall 检查” 是 RTL 验证术语，表示 ready/valid 握手被人为暂停。正确行为是地址、计数器和 FIFO 读写只在真实握手周期推进。`sticky` 也是 RTL/寄存器术语，表示事件发生后锁存，直到软件或 clear 逻辑清除。

### 9.3 `PCIe.v` 级仿真

目标：证明真实嵌入点和 `INFO_EXCH` 语义对得上。

建议先不跑完整 PCIe Root Complex，也不跑真实 XDMA。可以 mock `design_1_wrapper` 或用简化模型代替其 FDMA/INFO_EXCH 行为：

```text
TB
  -> PCIe.v
     -> pcie_fdma_aurora_brg_adapter
     -> mocked design_1_wrapper FDMA/INFO_EXCH
```

必测内容：

- `CPU_WR_DONE/RD_START -> TX -> CPU_WR_DONE_resp`。
- RX frame 输入后，`FPGA_CPU_START_ADDR/FPGA_CPU_LEN/INT_STATE_W/FPGA_CPU_irq_req` 正确。
- `CLEAR_INTER_R` 或 `INT_STATE_R` 清除后，IRQ/status 行为正确。
- `fdma_raddr/fdma_waddr` 是 64-bit 显式地址。
- ILA probe 不影响功能。

### 9.4 工程级仿真和综合前检查

目标：在跑综合前发现明显工程问题。

检查项：

- Vivado hierarchy 中 `TOP -> PCIe -> pcie_fdma_aurora_brg_adapter` 存在。
- `design_1_wrapper` 端口宽度与 `PCIe.v` 一致。
- XPM 库已启用。
- 不存在把 `fdma_aurora_pcie_conv_dma_wrapper.v` 误设 top 的情况。
- Vivado `report_ip_status` 中 locked IP 已有处理策略。

## 10. 工程做完后的上板验证计划

上板验证不能直接从“仿真 PASS”跳到“长时间跑满速”。推荐分阶段 bring-up。

### 10.1 上板前置条件

必须先完成：

- Vivado synthesis 通过。
- Implementation 通过。
- Timing 通过。
- PCIe XDMA、BRAM、`CONV_DMA`、`INFO_EXCH` 相关 IP 状态正常。
- GT/refclk/lane/SFP/PCIe 管脚约束正确。
- ILA probe 能观察 FDMA、adapter 状态、FIFO 水位、sticky、TX/RX 计数。
- 软件端能访问 XDMA BAR。

特别注意：当前用 Vivado 2020.2 打开工程时存在 2020.1 定制 IP locked 警告。上板前必须决定是继续用原 Vivado 版本打开，还是升级/重新生成相关 IP，并重新跑综合实现。

### 10.2 阶段 1：PCIe 和寄存器生命体征

目标：确认板子和软件通路活着。

步骤：

1. 下载 bitstream。
2. 主机确认 PCIe XDMA 可枚举。
3. 软件读写 BAR，确认基础寄存器可访问。
4. 读取 `VERSION/PROG_TIME/BUF_LEN_MAX/FPGA_TEMP` 等原有寄存器。
5. 确认 `user_lnk_up_int`、复位和主时钟状态。

通过标准：

- XDMA 设备存在。
- BAR 读写不超时。
- 原有寄存器读值合理。

### 10.3 阶段 2：BRAM/payload 窗口读写

目标：确认 CPU 和 FPGA 的共享数据窗口正常。

步骤：

1. CPU 通过 XDMA 写一段固定 pattern 到 payload buffer。
2. CPU 读回并比较。
3. 换不同地址、不同长度重复。

通过标准：

- BRAM/DDR 数据一致。
- 地址偏移没有错位。

### 10.4 阶段 3：CPU -> Aurora/debug TX 单帧

目标：验证 TX 数据面第一帧能从 CPU buffer 被 FDMA 读出，并输出到 66-bit stream。

步骤：

1. CPU 写 512B pattern 到 `CPU_FPGA_START_ADDR`。
2. CPU 写 `CPU_FPGA_LEN=512`。
3. CPU 置 `CPU_WR_DONE`。
4. ILA 观察 `fdma_rareq/fdma_raddr/fdma_rsize/fdma_rvalid/fdma_rready`。
5. ILA 观察 `o_rd_data_valid/o_rd_data[65:0]`。
6. 软件等待或轮询 `CPU_WR_DONE_resp`。

通过标准：

- `fdma_rsize=64`。
- 地址与软件配置一致。
- 66-bit 输出首拍 SOF、末拍 EOF 正确。
- 数据 pattern 顺序正确。

### 10.5 阶段 4：Aurora/debug RX -> CPU 单帧

目标：验证 RX 输入能写回 CPU 可读 buffer 并触发中断/状态。

步骤：

1. 使用当前 `DATA_CDC` debug generator 或后续 Aurora 对端输入一帧 512B。
2. ILA 观察 RX FIFO、`fdma_wareq/fdma_waddr/fdma_wsize/fdma_wvalid/fdma_wready`。
3. 软件等待 `FPGA_CPU_irq_req/INT_STATE`。
4. CPU 根据 `FPGA_CPU_START_ADDR/FPGA_CPU_LEN` 读 payload buffer。
5. CPU 比较 pattern，并写 `CPU_REC_STATE` 或清中断。

通过标准：

- `fdma_wsize=64`。
- CPU 读回数据顺序正确。
- `INT_STATE/IRQ` 只在写完后置位。
- 清中断后状态可恢复。

### 10.6 阶段 5：连续帧和异常

目标：把单帧路径扩展为稳定运行。

连续帧测试：

- 16 帧、64 帧、长时间循环。
- 检查地址递增和回绕。
- 检查 TX/RX frame count。
- 检查无非法 overflow/underflow。

异常测试：

- CPU 慢读 RX buffer。
- 故意配置非 512B 对齐长度，检查 `length_error_sticky`。
- PCIe reset 后恢复。
- Aurora link down/up 后恢复。
- FDMA 写侧或读侧长时间忙，检查 timeout sticky。

通过标准：

- 正常压力下不丢帧、不重复帧。
- 异常场景 sticky 能置位。
- clear 后状态能恢复。
- 软件能根据状态判断继续、重试或报警。

## 11. 后续建议

短期建议优先补两个验证件：

1. `pcie_fdma_aurora_brg_adapter` 功能 TB，覆盖 TX/RX、stall、sticky、长度不对齐。
2. `PCIe.v` 级 mock `design_1_wrapper` TB，覆盖 `INFO_EXCH` 控制语义。

随后再补 AXI-Lite 可读状态寄存器。当前 sticky 只在硬件内部/ILA 层面可见，不利于软件长期联调。推荐从 `0x0030` 之后新增 Aurora/FDMA 扩展状态，保留原 `0x0000-0x0028` 软件协议。

最后再做真实 Aurora 接入，把当前 adapter 的 `link_enable` 从 `user_lnk_up_int` 替换为同步后的 `channel_up/lane_up`，并确认 `rx_dst_rdy` 仍不被寄存器或 FIFO full 反控。
