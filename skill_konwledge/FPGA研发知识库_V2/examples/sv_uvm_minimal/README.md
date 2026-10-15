> 原规范包示例的离线副本；本轮未重新执行 VCS。使用前按本机工具版本编译与仿真。

# 最小 SystemVerilog/UVM 验证工程

该工程验证一个单周期 `rsp_data = req_data + 1` 的握手 DUT，展示规范要求的最小闭环：

- driver/monitor 分离的 clocking block 与 modport；
- 强类型 config 和精确 config_db 路径；
- factory 创建、显式 sequence 启动及随机化结果检查；
- monitor 实际采样、analysis 广播、scoreboard 和 coverage；
- 命名 SVA、完成条件、check/report 和全局 watchdog；
- test 独占 objection，无 `default_sequence`、`uvm_do*`、class XMR 或 component `$finish`。

## 文件组织

`demo_if.sv` 必须在 `demo_pkg.sv` 前编译，因为 config class 使用带 modport 的 virtual interface 类型。各 class 的 `.svh` 只由 package 包含，不能再次单独加入 filelist。

## VCS Q-2020.03-SP2-7 / UVM 1.2

在本目录执行：

```text
vcs -full64 -sverilog +v2k -ntb_opts uvm-1.2 -timescale=1ns/1ps -f filelist.f -top demo_tb -o simv -l compile.log
./simv +UVM_TESTNAME=demo_test +ntb_random_seed=1 -l run.log
```

通过条件：日志出现 `TEST PASS`，UVM_ERROR/UVM_FATAL 为 0，且没有 watchdog 超时。改变 seed 后应继续通过；用相同工具、库、编译配置和 seed 可重放。

## 设计边界

`demo_dut.v` 是纯 Verilog DUT；其余文件是验证专用 SystemVerilog。示例中的绝对时间只用于顶层 watchdog，协议行为全部按接口时钟采样。
