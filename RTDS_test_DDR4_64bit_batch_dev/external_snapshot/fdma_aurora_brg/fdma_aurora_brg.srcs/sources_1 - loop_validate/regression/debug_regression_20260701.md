# Regression Debug Notes 2026-07-01

## Run

命令：

```powershell
powershell -ExecutionPolicy Bypass -File .\run_regression.ps1 `
  -RegressList .\regress_list_nowave_once `
  -LogVerbosity 0 `
  -Vivado D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat
```

运行目录：

```text
regression/logs/20260701_091319
```

## Result

```text
OVERALL TOTAL=7 PASS=6 FAIL=1
```

逐项结果：

```text
PASS tc_aurora_loop_nobp      seed=317102 elapsed=662.861s wave=0
PASS tc_aurora_loop_bp        seed=268196 elapsed=526.301s wave=0
PASS tc_aurora_loop_addr_wrap seed=980693 elapsed=495.468s wave=0
PASS tc_brg_rd_ready_stall    seed=836765 elapsed=77.901s  wave=0
PASS tc_brg_wr_ready_stall    seed=088240 elapsed=77.018s  wave=0
PASS tc_brg_tx_fifo_waterline seed=478284 elapsed=86.154s  wave=0
FAIL tc_brg_rx_fifo_overflow  seed=677927 elapsed=88.186s  wave=0
```

## Runtime Notes

- 第一条 `tc_aurora_loop_nobp` 用时 `662.861s`，主要慢在 Vivado 打开工程、Aurora IP 编译和 full-loop `xelab`。
- 第二条 `tc_aurora_loop_bp` 用时 `526.301s`，比第一条少约 `136.560s`，说明后续用例复用了部分增量编译/缓存产物。
- 第三条 `tc_aurora_loop_addr_wrap` 用时 `495.468s`，继续受益于增量编译。
- bridge 直连类用例无需 Aurora IP full-loop elaboration，用时约 `77s` 到 `88s`。
- 这类 batch 命令比 GUI 慢，主要因为每个 testcase 都重新通过 batch Vivado 打开工程、设置 sim top、update compile order、launch/close simulation；GUI 中同一工程和 snapshot 往往已经热启动，且用户手工只跑当前 top。

## Failure: tc_brg_rx_fifo_overflow

日志：

```text
regression/logs/20260701_091319/tc_brg_rx_fifo_overflow_677927_simulate.log
```

seed：

```text
677927
```

首个错误：

```text
Error: [227000] [tc_brg_rx_fifo_overflow] RX accepted but did not store word=0 data=0b62cb9ccf5a5ef1 count=0 full=0
```

后续检查：

```text
[CHECK][RX_FIFO] accepted=2075 stored=2049 peak=1024 almost_full_seen=1 full_seen=1
TEST_FAIL: tc_brg_rx_fifo_overflow seed=677927 errors=1
```

初步定位：

- 错误发生在 `word=0`，此时 `count=0 full=0 wr_en=0 ready=1`。
- 这不是 FIFO 满边界的数据丢失，而是直连 RX 注入首拍采样/驱动竞态。
- testcase 在同一轮循环里给 `ctrl_vif.rx_drive_*` 赋值后立刻 `@(obs_vif.user_cb)` 采样 `rx_dst_rdy` 与 `rx_fifo_wr_en`。
- `rx_dst_rdy` 在 RTL 中恒为 1，因此 testbench 将该拍算作 accepted；但首个 drive word/src_rdy 还未在 DUT 采样边界稳定生效，`rx_fifo_wr_en` 为 0，于是误报 accepted-but-not-stored。
- 需要继续确认并修复 `tc_brg_rx_fifo_overflow` 的注入时序，类似 `wready` 反压竞态：驱动 RX word/src_rdy 后先等待一个 `ll_vif.mon_cb` 或 `obs_vif.user_cb` 生效周期，再开始统计 accepted/stored。

后续建议：

- 不应先按设计 FIFO 满处理这个 seed；首个失败点是 testbench 首拍竞态。
- 修复 testbench 注入生效等待后，重新单跑 `tc_brg_rx_fifo_overflow`。
- 若修复首拍竞态后仍在 FIFO 满边界失败，再判断是否需要 RTL 将 `rx_dst_rdy` 与 `!fifo_full` 或 almost-full 策略联动。

## Fix Attempt 1: Limit Drop Check To Full Window

修改文件：

```text
new/tc/tc_brg_rx_fifo_overflow.sv
```

修改点：

```systemverilog
if (full_seen &&
    (ll_vif.mon_cb.rx_dst_rdy === 1'b1) &&
    (obs_vif.user_cb.rx_fifo_wr_en !== 1'b1) && !drop_reported) begin
```

原因：

- 本 testcase 的设计意图是验证 RX FIFO 满后，RTL 仍保持 `rx_dst_rdy=1` 时会出现 accepted-but-not-stored。
- 旧逻辑从 word0 就检查 `ready=1 && wr_en=0`，首个注入 word 尚未稳定进入 DUT/FIFO 采样边界，因此把启动首拍误报成满 FIFO 丢数。
- 当前先将 accepted-but-not-stored 检查限制到 `full_seen` 之后，避免启动首拍竞态污染结果。

待验证：

- 语法检查 `tc_brg_rx_fifo_overflow.sv`。
- 单跑 `tc_brg_rx_fifo_overflow`，无波形。
- 若仍失败，继续看首个错误是否移动到 FIFO 满边界。

验证结果：

- `regression/logs/20260701_095627/tc_brg_rx_fifo_overflow_299313_simulate.log`
- seed：`299313`
- 结果：FAIL

新的首个错误：

```text
Error: [13379000] [tc_brg_rx_fifo_overflow] RX accepted but did not store word=2055 data=c20a842c63dce5c1 count=1024 full=1
[CHECK][RX_FIFO] accepted=2077 stored=2049 peak=1024 almost_full_seen=1 full_seen=1
```

结论：

- 首拍误报已消失。
- 错误移动到真正的 FIFO full 边界：`full=1` 时 `rx_dst_rdy` 仍为 1，但 `rx_fifo_wr_en=0`。
- 这是设计问题：`fdma_aurora_brg_rx.v` 中 `rx_dst_rdy` 恒为 1，FIFO 满后没有向 LocalLink RX 源侧反压，导致 accepted-but-not-stored。

## Fix Attempt 2: RX Backpressure At FIFO Full

计划修改：

- RTL：
  - `fdma_aurora_brg_rx.v` 中 `rx_dst_rdy` 改为 `!fifo_full && !wr_rst_busy`。
  - `fifo_wr_en` 改为 `rx_src_rdy && rx_dst_rdy`，保证 LocalLink accepted 与 FIFO write enable 一致。
- testcase：
  - `tc_brg_rx_fifo_overflow.sv` 不再要求观察到数据丢失。
  - 若出现 `rx_dst_rdy=1 && rx_fifo_wr_en=0`，仍判定失败。
  - 结束时检查 `almost_full_seen/full_seen`，并确认没有 accepted-but-not-stored。

实际修改：

```systemverilog
// fdma_aurora_brg_rx.v
assign rx_dst_rdy = (!fifo_full) && (!wr_rst_busy);
assign fifo_wr_en = rx_src_rdy && rx_dst_rdy;
```

```systemverilog
// tc_brg_rx_fifo_overflow.sv
// 删除结束处的:
// if (!drop_reported) record_error("RX full-handshake data-loss condition was not observed");
```

说明：

- 修复后 testcase 不再把“观察到丢数”当成通过条件。
- `drop_reported` 仍保留为错误标志；只要出现 `ready=1 && wr_en=0`，仍立即报错。

验证：

- `regression/logs/20260701_100309/tc_brg_rx_fifo_overflow_439899_simulate.log`
- seed：`439899`
- 结果：PASS

关键输出：

```text
[CHECK][RX_FIFO] accepted=2049 stored=2049 peak=1024 almost_full_seen=1 full_seen=1
TEST_PASS: tc_brg_rx_fifo_overflow seed=439899
```

最终结论：

- `tc_brg_rx_fifo_overflow` 原始失败包含两层问题：
  - testcase 启动首拍误报：word0 时 drive 尚未稳定，却按 `rx_dst_rdy=1` 统计 accepted。
  - RTL 真实设计问题：FIFO full 后 `rx_dst_rdy` 仍为 1，导致 accepted-but-not-stored。
- 当前修复后，FIFO full 后 `rx_dst_rdy` 拉低，accepted 与 stored 对齐，单测通过。

## Correction: Aurora RX Cannot Be Backpressured

用户补充设计约束：

```text
rx_dst_rdy 必须恒为 1，因为 Aurora SERDES 的发送数据侧不允许下游反压；
RX 方向依靠较深 FIFO 吸收数据，而不是向 Aurora RX 源侧施加反压。
```

因此 `Fix Attempt 2` 中“FIFO full 后拉低 `rx_dst_rdy`”的 RTL 修改不符合设计约束，已撤回。

最终修正方向改为：

- RTL：
  - `fdma_aurora_brg_rx.v` 保持 `assign rx_dst_rdy = 1'b1;`
  - `fifo_wr_en = rx_src_rdy && !fifo_full;`
  - FIFO 满后继续保持 ready，但不写 FIFO，从而避免 XPM overflow。
- testcase：
  - `tc_brg_rx_fifo_overflow.sv` 将 full 后 `ready=1 && wr_en=0` 视为预期的 saturated drop 覆盖点。
  - 启动首拍的 `ready=1 && wr_en=0` 不计入 drop，仍通过 `full_seen` 限定到满 FIFO 后。
  - `rx_fifo_overflow` 仍为错误。
  - 结束时要求观察到 `almost_full_seen`、`full_seen` 和 `drop_reported`。

实际修改：

```systemverilog
// fdma_aurora_brg_rx.v
assign rx_dst_rdy = 1'b1;
assign fifo_wr_en = rx_src_rdy && !fifo_full;
```

```systemverilog
// tc_brg_rx_fifo_overflow.sv
if (full_seen &&
    (ll_vif.mon_cb.rx_dst_rdy === 1'b1) &&
    (obs_vif.user_cb.rx_fifo_wr_en !== 1'b1) && !drop_reported) begin
    $display("[CHECK][RX_FIFO] saturated drop ...");
    drop_reported = 1'b1;
end

if (!drop_reported) record_error("RX saturated-drop condition was not observed");
```

验证：

- `regression/logs/20260701_100915/tc_brg_rx_fifo_overflow_641547_simulate.log`
- seed：`641547`
- 结果：PASS

关键输出：

```text
[CHECK][RX_FIFO] saturated drop word=2055 data=a4cbcfbe50563d1b count=1024 full=1
[CHECK][RX_FIFO] accepted=2095 stored=2049 peak=1024 almost_full_seen=1 full_seen=1
TEST_PASS: tc_brg_rx_fifo_overflow seed=641547
```

最终结论更新：

- `rx_dst_rdy` 恒 1 是设计要求，不能作为 overflow 修复点。
- RX FIFO 满后不写入新数据是预期饱和保护；用例应验证该保护被触发，并确认 XPM `overflow` 不触发。
