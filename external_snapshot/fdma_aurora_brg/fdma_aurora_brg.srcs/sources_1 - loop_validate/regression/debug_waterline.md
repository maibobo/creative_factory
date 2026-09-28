# tc_brg_tx_fifo_waterline Debug Notes

日期：2026-06-30

## 范围

当前只定位 `tc_brg_tx_fifo_waterline`，不继续跑其它回归或 full Aurora loop。仿真要求：不带波形，单用例验证。

## 已知失败现象

最近可复现失败日志：

- `regression/logs/20260630_160714/tc_brg_tx_fifo_waterline_023196_simulate.log`
- testcase：`tc_brg_tx_fifo_waterline`
- seed：`023196`
- frames：8
- total words：512

关键输出：

```text
[CHECK][TX_FIFO] count=448 almost_full=1 full=0 overflow=0 rready=0
Error: completion timeout: got 478/512 FDMA write words
Error: fdma_rd_hs/tx_fifo_wr length mismatch: 512/478
Error: fdma_rd_hs/tx_fifo_wr first mismatch at 0: 3e3c0a2e39c9b54b/0abb8482cb6fb7ef
Error: expected/fdma_wr_hs length mismatch: 512/478
Error: TX frame count 7, expected 8
Error: RX frame count 7, expected 8
Error: partial LL frame remained at end of test
[tc_brg_tx_fifo_waterline] FIFO peaks: TX=449 RX=5
[tc_brg_tx_fifo_waterline] LL frames: TX=7 RX=7 words_per_frame=64
```

## 已排除或已确认的点

- TX FIFO 水线本身已经能到 448：
  - `obs_vif.tx_fifo_wr_cnt == 448`
  - `obs_vif.tx_fifo_almost_full == 1`
  - `rd_vif.rready == 0`
- 因此当前失败不是原始的 almost_full 阈值错误，而是满水线后的恢复/收尾问题。
- 失败稳定停在 `478/512`：
  - 448 是 7 帧。
  - 478 = 448 + 30。
  - 说明第 8 个 64-word burst 在第 30 个 word 后没有完整收完，剩余 34 个 word 未进入端到端写回。

## RTL 已做修正

文件：`new/fdma_aurora_brg_tx.v`

1. 将 TX FIFO 水线从 XPM 默认 `almost_full` 改为 `prog_full`。
   - `PROG_FULL_THRESH = 512-64 = 448`
   - `prog_full` 接到内部 `fifo_almost_full`
   - XPM 默认 `almost_full` 不再用来表达 448-word 水线

2. TX LocalLink 发送侧已改为真实握手推进。
   - `tx_hs = tx_src_rdy && tx_dst_rdy`
   - `wr_burst_done` 基于 `tx_hs`
   - `tx_word_cnt`、SOF/EOF、FIFO read 只随真实握手推进

3. FDMA read 接收侧新增写端 ready 门控。
   - 新增 `fifo_write_ready = (~wr_rst_busy) && (~fifo_almost_full)`
   - `fdma_rready = rd_data_phase && fifo_write_ready`
   - `RD_IDLE -> RD_REQ` 也要求 `fifo_write_ready`

## 当前判断

`fdma_rd_hs_q` 由 testbench raw `rd_vif.rvalid && rd_vif.rready` 采样得到，而 `tx_fifo_wr_q` 由 DUT 内部 `wr_en` 采样得到。失败中前者 512、后者 478，说明仿真观测到 FDMA 读口完成了 512 次握手，但 FIFO 实际写入只有 478 次。

优先怀疑点：

- RTL 在 FIFO 写端尚未真正可写时允许了 FDMA read 握手，导致 `rd_word_cnt` 推进但 `wr_en` 未写入。
- 已针对 `wr_rst_busy` 增加门控，避免 reset-busy 期间产生假握手。
- 该修正尚需重新运行 `tc_brg_tx_fifo_waterline` 验证。

## 后续动作

1. 对 `fdma_aurora_brg_tx.v` 做轻量语法检查。
2. 只运行 `tc_brg_tx_fifo_waterline`，无波形。
3. 若仍失败：
   - 继续检查第 8 个 burst 中 `rready/prog_full/wr_en/rd_state/rd_word_cnt` 的恢复关系。
   - 重点确认 `prog_full` deassert 后 `fdma_rready` 是否恢复，以及恢复后 FIFO 写和 FDMA read monitor 是否逐字一致。

## 进展记录

### 2026-06-30 语法检查

命令：

```powershell
D:\Xilinx_2020_2\Vivado\2020.2\bin\xvlog.bat --sv --relax -L xpm new\fdma_aurora_brg_tx.v
```

结果：通过。

关键输出：

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../new/fdma_aurora_brg_tx.v" into library work
INFO: [VRFC 10-311] analyzing module fdma_aurora_brg_tx
```

### 2026-06-30 单测验证

命令：

```powershell
powershell -ExecutionPolicy Bypass -File regression\run_regression.ps1 `
  -RegressList regression\regress_list_tx_waterline_only `
  -LogVerbosity 0 `
  -Vivado D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat
```

结果：通过。

日志：

- `regression/logs/20260630_213955/tc_brg_tx_fifo_waterline_423006_simulate.log`
- seed：`423006`

关键输出：

```text
[CHECK][TX_FIFO] count=448 almost_full=1 full=0 overflow=0 rready=0
[STIM][TX_FIFO] tx_dst_rdy=1; draining FIFO
[tc_brg_tx_fifo_waterline] FIFO peaks: TX=448 RX=5
[tc_brg_tx_fifo_waterline] LL frames: TX=8 RX=8 words_per_frame=64
TEST_PASS: tc_brg_tx_fifo_waterline seed=423006 frames=8
```

说明：

- 修复后水线仍在 448 触发，且 `rready=0`，保留了 testcase 期望的反压行为。
- 收尾阶段 8 帧全部通过，原先 `478/512` 和 `partial LL frame` 问题消失。
- 之后尝试直接复用 snapshot 调 `xsim.exe` 跑旧 seed `023196`，命令未进入仿真，退出码 `-1073741515`。这是直接调用未完整 Vivado 运行环境的问题，不是 testcase 失败；有效验证以上面的 Vivado batch 单测为准。

## 其它失败用例跟踪

后续继续定位：

- `tc_brg_rd_ready_stall`
- `tc_brg_wr_ready_stall`

### tc_brg_rd_ready_stall

旧失败日志：

- `regression/logs/20260630_152316/tc_brg_rd_ready_stall_712359_simulate.log`
- seed：`712359`

旧失败关键输出：

```text
[STIM] rready stall word=101 cycles=2
Error: completion timeout: got 94/128 FDMA write words
Error: fdma_rd_hs/tx_fifo_wr length mismatch: 128/94
Error: TX frame count 1, expected 2
Error: RX frame count 1, expected 2
Error: partial LL frame remained at end of test
```

判断：

- 该失败和 waterline 的 `fdma_rd_hs/tx_fifo_wr` 数量不一致同类。
- 根因在 TX FDMA read 接收侧：`fdma_rready` 未覆盖 FIFO 写端 reset-busy/ready 状态时，会让 FDMA BFM 认为读数据握手已经完成，但 XPM FIFO 的实际 `wr_en` 被门控，导致数据字丢失。
- 修复点是 `fifo_write_ready = ~wr_rst_busy && ~fifo_almost_full`，并同时门控 `fdma_rready` 和 `RD_IDLE -> RD_REQ`。

当前验证：

- `regression/logs/20260630_214931/tc_brg_rd_ready_stall_392929_simulate.log`
- seed：`392929`
- 结果：PASS

关键输出：

```text
TEST_PASS: tc_brg_rd_ready_stall seed=392929 frames=2
```

### tc_brg_wr_ready_stall

旧失败日志：

- `regression/logs/20260630_152316/tc_brg_wr_ready_stall_049703_simulate.log`
- seed：`049703`

旧失败关键输出：

```text
[STIM] wready stall words=1/116/124 cycles=4/3/2
Error: wdata changed while wready was low
Error: completion timeout: got 94/128 FDMA write words
Error: fdma_rd_hs/tx_fifo_wr length mismatch: 128/94
Error: TX frame count 1, expected 2
Error: RX frame count 1, expected 2
Error: partial LL frame remained at end of test
```

判断：

- 后半段 `94/128` 与 TX read 假握手问题同根，已由 TX 修复覆盖。
- 前半段 `wdata changed while wready was low` 属于 RX FDMA write 数据保持问题，需用当前代码单测确认是否仍存在。

当前复现：

- `regression/logs/20260630_215331/tc_brg_wr_ready_stall_415439_simulate.log`
- seed：`415439`
- frames：1

关键输出：

```text
[STIM] wready stall words=1/28/60 cycles=4/6/2
Error: wdata changed while wready was low
[tc_brg_wr_ready_stall] FIFO peaks: TX=35 RX=6
[tc_brg_wr_ready_stall] LL frames: TX=1 RX=1 words_per_frame=64
TEST_FAIL: tc_brg_wr_ready_stall seed=415439 errors=12
```

新现象：

- TX 侧 `94/128`、partial frame、帧数不够已经消失。
- 失败只剩 RX FDMA write 数据保持。

定位：

- RX 写数据通路有保持寄存器 `wdata_hold`，但原逻辑允许在 `w_hs` 成立时同拍预取下一字：
  - `fifo_rd_en = ... (!wdata_hold_valid || (w_hs && !w_last_hs))`
- 在 `wready` 反压边界，输出寄存器会继续换成下一字；testbench 观测到 `wready=0` 后要求 `wdata` 保持，因此触发 `wdata changed while wready was low`。

修复：

- 曾尝试将 `new/fdma_aurora_brg_rx.v` 改成一字保持模式，但修后错误变成 `wvalid dropped while wready was low`。
- 该现象说明真正问题不在 RX 是否同拍预取，而在 testbench 反压注入边界：
  - `wr_vif.cb.wready <= 1'b0` 通过 clocking block 输出，存在 #1step 生效延迟。
  - testbench 原逻辑在拉低 `wready` 后立即进入 `check_write_data_stable()`。
  - DUT 在上一拍 `wready=1` 的合法握手后换字，却被 testbench 计入了 `wready=0` 期间。
- 因此已恢复 RX RTL 高吞吐预取逻辑，改修验证平台：
  - 文件：`new/tc/tc_base.sv`
  - 在 `wr_vif.cb.wready <= 1'b0;` 后增加 `@(wr_vif.cb);`
  - 等 clocking block 输出低电平真正生效后，再调用 `check_write_data_stable(stall_cycles)`。

语法检查：

```text
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../new/fdma_aurora_brg_rx.v" into library work
INFO: [VRFC 10-311] analyzing module fdma_aurora_brg_rx
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../new/tc/tc_if.sv" into library work
INFO: [VRFC 10-2263] Analyzing SystemVerilog file ".../new/tc/tc_base.sv" into library work
```

最终验证：

- `regression/logs/20260630_221823/tc_brg_wr_ready_stall_915083_simulate.log`
- seed：`915083`
- frames：3
- 结果：PASS

关键输出：

```text
[STIM] wready stall words=5/8/184 cycles=4/3/2
[tc_brg_wr_ready_stall] FIFO peaks: TX=76 RX=6
[tc_brg_wr_ready_stall] LL frames: TX=3 RX=3 words_per_frame=64
TEST_PASS: tc_brg_wr_ready_stall seed=915083 frames=3
```

## 本轮结论

- `tc_brg_tx_fifo_waterline`：PASS。设计修复点是 TX FIFO 水线使用 `prog_full`，并用 `fifo_write_ready` 门控 FDMA read 握手。
- `tc_brg_rd_ready_stall`：PASS。与 waterline 的 TX read 假握手/丢写同根，已被同一 TX 修复覆盖。
- `tc_brg_wr_ready_stall`：PASS。最终定位为验证平台 `wready` 反压注入竞态，修复点是拉低 `wready` 后等待一个 clocking block 事件再检查 `wvalid/wdata` 保持；RX RTL 保持原预取结构。
