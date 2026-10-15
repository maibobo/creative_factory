---
name: fpga-verilog-tb-development
version: "0.2"
language: zh-CN
stage: "05-Testbench代码编写阶段"
tb_language: "Verilog-2001"
description: >-
  根据“XX模块_仿真报告_待补充结果.docx”中已经定义好的 P0/P1/P2 仿真测试项
  以及 XX模块 RTL 稳定版，使用纯 Verilog-2001 编写 FPGA Testbench。
  本 Skill 采用“一个测试项对应一个独立、自包含的 TB 文件”的开发方式：
  每个 TB 文件内部独立包含 Clock、Reset、DUT 例化、激励、Driver Task、
  Monitor/Checker、Reference/Expected、Error Injection、Timeout、PASS/FAIL
  和完整 Test Procedure，不拆分公共 driver/monitor/scoreboard/ref_model/common 文件。
  本阶段默认只输出 XX模块TB代码目录和 TB说明文档.md，不强制生成 Tcl 或其他仿真脚本，
  不擅自修改 Stable RTL，不重新定义测试项，不虚构仿真结果。
---

# FPGA Verilog TB Development SKILL

# 0. Skill 定位

本 Skill 对应 FPGA 前端开发流程中的：

```text
05 Testbench代码编写阶段
```

推荐完整流程：

```text
01 方案设计阶段
   ↓
XX模块设计方案

02 RTL逻辑代码编写阶段
   ↓
XX模块RTL代码
IP配置清单

03 RTL代码审查与稳定阶段
   ↓
RTL Review
RTL Stable

04 仿真验证方案设计阶段
   ↓
XX模块_仿真报告_待补充结果.docx

05 Testbench代码编写阶段
   ↓
本 Skill
   ↓
XX模块TB代码/
TB说明文档.md
```

本 Skill 的核心职责是：

> 将第 04 阶段仿真报告中已经明确的每一个测试项，
> 转换成一个独立、自包含、可直接用于 Vivado/XSim 等仿真器的 Verilog-2001 Testbench 文件。

---

# 1. 核心开发模式

本 Skill 强制采用：

```text
一个 Test ID
=
一个独立 TB 文件
```

例如：

```text
P0-BSC-001
↓
tb_P0_BSC_001_reset.v

P0-BSC-002
↓
tb_P0_BSC_002_basic_transfer.v

P1-FIFO-001
↓
tb_P1_FIFO_001_full.v

P1-ERR-001
↓
tb_P1_ERR_001_timeout.v

P2-M0-001
↓
tb_P2_M0_001_random_legal.v
```

Test ID 必须保持与仿真报告一致。

---

# 2. 自包含 TB 原则

每一个 TB 文件必须能够单独阅读、单独编译、单独运行。

每个 TB 文件内部按需包含：

```text
Test Information
Parameter
Clock
Reset
DUT Interface Signal
DUT Instance
Clock Generator
Reset Procedure
Driver Task
Stimulus Task
Monitor Logic
Reference / Expected Logic
Checker
Error Injection
Timeout
PASS / FAIL
Test Procedure
Simulation Finish
```

---

# 3. 禁止默认拆分公共 TB 文件

本 Skill 默认不生成：

```text
tb_common.vh
tb_driver.v
tb_monitor.v
tb_scoreboard.v
tb_ref_model.v
tb_error_inject.v
```

也不建立：

```text
common/
```

目录。

---

# 4. 允许代码重复

不同 Testbench 文件之间允许重复：

```text
Clock Generator
Reset Task
Driver Task
Monitor
Checker
辅助Function
日志逻辑
```

这是本 Skill 的设计选择。

原因：

```text
每个Test独立
↓
打开一个TB即可看完整验证逻辑
↓
无需跨文件跳转
↓
Bug定位更直接
↓
Test Case与代码一一对应
```

不要为了减少重复代码，擅自抽取公共模块。

---

# 5. 第 05 阶段输入

## 5.1 必须输入

```text
1. XX模块_仿真报告_待补充结果.docx
2. XX模块RTL稳定版.v
```

如果 RTL 由多个文件组成：

```text
XX模块RTL稳定版/
```

全部作为输入。

---

## 5.2 推荐输入

如有：

```text
IP配置清单
XCI
接口协议
寄存器表
数据格式说明
Golden Vector
Reference Model说明
第三方IP仿真模型
历史TB
```

应一并读取。

---

# 6. 输入资料优先级

如资料冲突：

```text
用户当前明确确认
    ↓
XX模块_仿真报告_待补充结果.docx
    ↓
正式设计方案
    ↓
正式接口/寄存器协议
    ↓
已批准Design Deviation
    ↓
RTL Stable
```

注意：

仿真报告中的：

```text
测试项
激励/条件
期望结果
```

已经是第 05 阶段的验证输入。

本 Skill 不重新设计这些内容。

---

# 7. RTL 不是 Expected 的来源

原则：

> Stable RTL 是 DUT，不是 Golden Model。

如果发现：

```text
仿真报告期望结果
与
RTL当前行为
```

明显矛盾，

不能直接修改 Expected 来迎合 RTL。

应输出：

```text
VERIFICATION IMPLEMENTATION CONFLICT
```

并说明：

```text
Test ID
Report Expected
RTL Observed/Static Behavior
Conflict
Need Confirmation
```

---

# 8. Testbench 语言

默认：

```text
Verilog-2001
```

扩展名：

```text
.v
```

---

# 9. 禁止默认使用 SystemVerilog

除非用户明确要求，否则禁止：

```text
logic
always_ff
always_comb
typedef
enum
interface
class
mailbox
queue
covergroup
assert property
randomize
$urandom
$urandom_range
UVM
```

---

# 10. Testbench 可以使用非综合语句

Testbench 不属于可综合 RTL。

因此允许：

```verilog
initial
always
#delay
task
function
$display
$write
$fopen
$fclose
$fdisplay
$readmemh
$readmemb
$random
$finish
$stop
```

按实际需要使用。

---

# 11. 第 05 阶段正式输出

默认只输出：

```text
XX模块_TB/
    ├── tb_xxx.v
    ├── tb_xxx.v
    └── ...

XX模块_TB说明文档.md
```

---

# 12. 不强制输出仿真脚本

本 Skill 默认不输出：

```text
.tcl
.do
.sh
.bat
Makefile
```

用户如果后续明确需要：

```text
自动批量仿真
Regression自动执行
Vivado Tcl
```

再单独生成。

---

# 13. 推荐目录

推荐简单结构：

```text
XX模块_TB/
│
├── P0/
│   ├── tb_P0_BSC_001_xxx.v
│   ├── tb_P0_BSC_002_xxx.v
│   └── ...
│
├── P1/
│   ├── tb_P1_xxx_001_xxx.v
│   ├── tb_P1_xxx_002_xxx.v
│   └── ...
│
└── P2/
    ├── tb_P2_M0_001_xxx.v
    ├── tb_P2_M1_001_xxx.v
    ├── tb_P2_M2_001_xxx.v
    └── ...

XX模块_TB说明文档.md
```

如果测试项数量不多，也可以：

```text
XX模块_TB/
├── tb_P0_BSC_001_xxx.v
├── tb_P0_BSC_002_xxx.v
├── tb_P1_xxx_001_xxx.v
├── tb_P2_M0_001_xxx.v
└── ...
```

不强制分 P0/P1/P2 子目录。

---

# 14. 文件名规则

推荐：

```text
tb_<Test_ID>_<简短测试名称>.v
```

将 `-` 转换为 `_`。

例如：

```text
P0-BSC-001
→
tb_P0_BSC_001_reset_idle.v

P1-FIFO-003
→
tb_P1_FIFO_003_full_backpressure.v

P2-M2-002
→
tb_P2_M2_002_error_recovery.v
```

---

# 15. Module Name

Testbench module 名建议与文件名一致：

```verilog
module tb_P1_FIFO_003_full_backpressure;
```

便于 Vivado GUI：

```text
Set as Top
```

---

# 16. 每个 TB 文件头

每个文件必须至少写：

```verilog
// ============================================================
// Project     :
// DUT         :
// Test ID     :
// Test Name   :
// Stage       : P0 / P1 / P2
// Source      : XX模块_仿真报告_待补充结果.docx
// Purpose     :
// Stimulus    :
// Expected    :
// RTL Version :
// Notes       :
// ============================================================
```

未知信息不要虚构。

---

# 17. Test ID 不得改变

仿真报告中的：

```text
P0-BSC-001
```

TB 中仍必须保留：

```text
P0-BSC-001
```

不能重新编号成：

```text
TC-001
```

---

# 18. Test ID → TB 一一对应

必须满足：

```text
仿真报告 Test ID
↓
唯一 TB File
```

一个 Test ID 不应默认分散在多个 TB 文件中。

---

# 19. 一个 TB 不承载多个独立 Test ID

默认禁止：

```text
tb_all_tests.v
```

内部通过：

```text
TEST_ID
case
plusarg
```

跑几十个独立测试。

原则：

```text
一个测试项
=
一个入口
=
一个TB
```

---

# 20. 例外

只有用户明确要求：

```text
合并测试
公共Regression TB
统一随机框架
```

时才允许多个 Test ID 共享一个 TB。

默认不这样做。

---

# 21. 每个 TB 的推荐结构

```verilog
`timescale 1ns/1ps

module tb_xxx;

// ============================================================
// 1. Test Information
// ============================================================

// ============================================================
// 2. Parameters
// ============================================================

// ============================================================
// 3. Clock / Reset
// ============================================================

// ============================================================
// 4. DUT Interface
// ============================================================

// ============================================================
// 5. DUT Instance
// ============================================================

// ============================================================
// 6. Clock Generator
// ============================================================

// ============================================================
// 7. Reset Procedure
// ============================================================

// ============================================================
// 8. Driver / Stimulus Tasks
// ============================================================

// ============================================================
// 9. Monitor / Reference / Checker
// ============================================================

// ============================================================
// 10. Timeout
// ============================================================

// ============================================================
// 11. Test Procedure
// ============================================================

// ============================================================
// 12. PASS / FAIL Summary
// ============================================================

endmodule
```

---

# 22. Test Information

必须将 Word 中：

```text
测试项
激励/条件
期望结果
```

以注释形式写进 TB。

这样打开 TB 就能直接知道：

```text
为什么测
怎么测
什么算正确
```

---

# 23. Parameter

TB 内定义：

```text
Clock Period
Timeout
Data Width
Test Length
Seed
Loop Count
```

等测试相关参数。

---

# 24. DUT Parameter

Stable RTL 的 Parameter 必须使用真实名称。

例如：

```verilog
dut #(
    .DATA_WIDTH(DATA_WIDTH)
) u_dut (
    ...
);
```

禁止猜 Parameter。

---

# 25. DUT Interface

从 Stable RTL 读取：

```text
Port Name
Direction
Width
```

TB 中声明：

```verilog
reg
wire
```

与真实接口一致。

---

# 26. DUT 输入信号

DUT input：

通常在 TB 中声明：

```verilog
reg
```

---

# 27. DUT 输出信号

DUT output：

通常在 TB 中声明：

```verilog
wire
```

---

# 28. Clock Generator

典型：

```verilog
initial begin
    clk = 1'b0;
    forever #(CLK_PERIOD/2) clk = ~clk;
end
```

CLK_PERIOD 来自：

```text
设计
仿真报告
```

---

# 29. 多时钟

如果 DUT 有：

```text
clk_a
clk_b
```

每个 TB 内分别生成。

每个 TB 都自包含，不依赖公共 Clock 文件。

---

# 30. Clock Ratio

涉及 CDC/FIFO 测试时：

对应 TB 自己定义：

```verilog
parameter CLK_A_PERIOD = ...;
parameter CLK_B_PERIOD = ...;
```

---

# 31. Reset

必须根据真实设计：

```text
Reset名称
极性
同步/异步
保持时间
释放要求
```

编写。

禁止默认全部使用：

```text
rst_n
```

---

# 32. Reset Procedure

推荐使用 TB 内部 Task：

```verilog
task apply_reset;
begin
    ...
end
endtask
```

---

# 33. 每个 TB 自己有 Reset Task

即使 50 个 TB 的 Reset Task 完全相同：

仍允许每个 TB 自己写一份。

不抽：

```text
common_reset.v
```

---

# 34. Clock / Reset Race

TB 驱动应避免和 DUT 在同一个边沿产生竞态。

如果 DUT：

```text
posedge clk
```

普通输入激励可优先考虑：

```text
negedge clk
```

更新。

具体根据协议确定。

---

# 35. Driver

本 Skill 中的 “Driver” 不是独立文件。

Driver 是：

```text
写在当前tb_xxx.v内部的一组task/过程
```

---

# 36. Driver Task

例如：

```verilog
task send_word;
input [31:0] data;
begin
    ...
end
endtask
```

---

# 37. Packet Driver

可在当前 TB 内实现：

```text
send_packet
send_single_beat
send_multi_beat
```

---

# 38. Register Driver

可在当前 TB 内实现：

```text
reg_write
reg_read
```

---

# 39. Ready/Valid Driver

如果采用：

```text
valid/ready
```

TB 必须遵守真实握手。

传输事件：

```text
valid && ready
```

---

# 40. Backpressure 下保持

如果协议要求：

```text
valid=1 && ready=0
```

时：

```text
valid
data
last
keep
user
```

保持，

Driver 必须正确实现。

---

# 41. Illegal Protocol Test

只有当前 Test Case 明确就是：

```text
协议非法输入
```

时，

Driver 才能有意违反协议。

---

# 42. Monitor

Monitor 同样写在当前 TB 内。

可以使用：

```verilog
always @(posedge clk)
```

观察有效 Transaction。

---

# 43. Monitor 不是必须独立模块

简单 Test：

可以直接在：

```text
Test Procedure
```

中等待和检查输出。

不必为了形式写 Monitor block。

---

# 44. Checker

Checker 也写在当前 TB 内。

可以采用：

```text
if
case
task
function
always
```

进行自动检查。

---

# 45. Scoreboard

复杂数据流 Test 可以在当前 TB 文件内建立：

```text
Expected Memory
Actual Memory
Read Pointer
Write Pointer
Mismatch Counter
```

实现简单 Scoreboard。

不拆成：

```text
tb_scoreboard.v
```

---

# 46. Reference Model

Reference Model 也写在当前 TB 内。

简单模型：

```verilog
function
```

复杂模型：

```text
数组
Task
Golden Vector
```

---

# 47. Reference Model 独立性

Reference 应基于：

```text
Design Rule
公式
协议
Golden Vector
```

不能机械复制 DUT 内部 RTL。

---

# 48. Golden Vector

如果有：

```text
.hex
.mem
.txt
```

可以在单个 TB 内：

```verilog
$readmemh
$readmemb
```

加载。

---

# 49. Testbench 可以引用数据文件

“自包含 TB”指：

```text
验证代码逻辑不拆分
```

不代表不能读取：

```text
Golden Vector
Memory Initialization
```

等数据文件。

---

# 50. Error Injection

Error Injection 写在当前 Test 的 TB 内。

例如：

```text
错误响应
Timeout
非法参数
Response Delay
Backpressure
```

---

# 51. Force / Release

只有：

```text
设计定义的错误无法通过正式接口触发
且
该Test明确需要内部故障注入
```

才允许使用：

```verilog
force
release
```

---

# 52. 正常功能测试禁止依赖 Force

P0/P1 正常主路径：

优先通过真实接口产生状态。

---

# 53. Expected Result

每个 TB 必须根据 Word 中 Expected 实现 Checker。

不得只写：

```text
人工看波形
```

---

# 54. 自动 PASS / FAIL

每个 TB 必须尽量自动给出：

```text
PASS
FAIL
```

---

# 55. PASS 输出

例如：

```verilog
$display("========================================");
$display("[PASS] P1-FIFO-001");
$display("========================================");
```

---

# 56. FAIL 输出

例如：

```verilog
$display("========================================");
$display("[FAIL] P1-FIFO-001");
$display("Reason: ...");
$display("========================================");
```

---

# 57. Test Result 变量

推荐：

```verilog
integer error_count;
integer mismatch_count;
```

---

# 58. PASS 条件

根据具体 Test 定义。

一般可包含：

```text
No Timeout
Mismatch = 0
No Unexpected Error
Expected Count == Actual Count
```

---

# 59. Timeout

每一个 TB 必须有 Timeout。

---

# 60. 禁止无限 Wait

禁止只写：

```verilog
wait(done);
```

没有超时保护。

---

# 61. Global Timeout

推荐每个 TB 有：

```verilog
initial begin
    #(GLOBAL_TIMEOUT);
    $display("[FAIL] Timeout");
    $finish;
end
```

或基于 Cycle 的 watchdog。

---

# 62. Test Procedure

每个 TB 最核心的是：

```verilog
initial begin

    initialize();

    apply_reset();

    configure();

    drive_stimulus();

    wait_result();

    check_result();

    print_summary();

    $finish;
end
```

按 Test 实际需求调整。

---

# 63. P0 实现原则

P0：

```text
最小主链路
Smoke
```

每个 P0 测试项仍然：

```text
一个P0 Test ID
=
一个TB
```

---

# 64. P0 示例

```text
P0-BSC-001
↓
tb_P0_BSC_001_reset_idle.v

P0-BSC-002
↓
tb_P0_BSC_002_basic_transaction.v

P0-BSC-003
↓
tb_P0_BSC_003_data_format.v
```

---

# 65. P0 测试特点

P0 TB 应：

```text
逻辑简单
容易定位
少随机
无主动异常
快速运行
```

---

# 66. P1 实现原则

P1 是：

```text
定向功能
异常
边界
```

Word 中每一个 P1 Test ID 都生成独立 TB。

---

# 67. P1 模块测试

例如：

```text
P1-FIFO-001
P1-FIFO-002
P1-FIFO-003
```

生成：

```text
tb_P1_FIFO_001_xxx.v
tb_P1_FIFO_002_xxx.v
tb_P1_FIFO_003_xxx.v
```

---

# 68. P1 Boundary

每个边界 Test 独立。

例如：

```text
MIN
MAX
N-1/N/N+1
```

如果报告定义为多个独立 Test ID：

必须生成多个 TB。

---

# 69. P1 Error

每一种已定义 Error Test：

独立 TB。

例如：

```text
P1-ERR-001 Timeout
P1-ERR-002 Bad Response
P1-ERR-003 Invalid Length
```

---

# 70. P1 Recovery

如果报告将：

```text
错误检测
错误恢复
```

定义为一个 Test：

则一个 TB 内完成完整流程。

如果报告拆为两个 Test ID：

则生成两个 TB。

---

# 71. P1 Reset

运行中 Reset、Error 状态 Reset、FIFO 非空 Reset 等，

都按报告 Test ID 独立生成 TB。

---

# 72. P1 CDC

CDC 逻辑行为 Test：

每个 Test 独立设置自己的多时钟周期。

---

# 73. P2 实现原则

P2 仍然遵守：

```text
每个测试项
=
一个TB文件
```

---

# 74. P2 MODE

报告固定：

```text
MODE=0 正常随机
MODE=1 长时间稳定
MODE=2 错误恢复随机
```

---

# 75. MODE 不需要统一大 TB

本 Skill 不要求：

```text
一个tb_p2.v
+
MODE参数
```

而是更推荐：

```text
P2-M0-001
↓
tb_P2_M0_001_xxx.v

P2-M1-001
↓
tb_P2_M1_001_xxx.v

P2-M2-001
↓
tb_P2_M2_001_xxx.v
```

---

# 76. P2 Test 文件头

P2 TB 必须记录：

```text
MODE
Test ID
Seed
Loop / Duration Config
```

---

# 77. Seed

纯 Verilog 默认使用：

```verilog
$random
```

---

# 78. Seed 可复现

每个 P2 TB 必须具备：

```text
固定默认Seed
+
允许修改Seed
```

---

# 79. Seed 变量

例如：

```verilog
integer seed;
```

---

# 80. 默认 Seed

可以使用：

```verilog
seed = 1;
```

作为默认。

但必须在文件头/说明中写明：

```text
可修改
```

---

# 81. Seed 输出

P2 启动时必须打印：

```text
Test ID
MODE
Seed
```

---

# 82. Random Signed 问题

`$random` 可能产生 signed 值。

不能简单：

```verilog
value = $random % N;
```

而完全忽略负数。

---

# 83. Random Helper

可以在当前 TB 内写：

```verilog
function integer rand_range;
...
endfunction
```

用于范围化。

---

# 84. P2 MODE=0

正常随机 TB：

只能随机：

```text
设计允许的合法输入空间
```

不主动注入 Error。

---

# 85. MODE=0 每个 Test 独立

例如：

```text
P2-M0-001 随机合法事务
P2-M0-002 随机Backpressure
```

则分别生成两个 TB。

---

# 86. P2 MODE=1

长时间稳定测试：

每个报告测试项独立 TB。

---

# 87. MODE=1 Loop

TB 内：

```verilog
integer loop_count;
```

应可以修改。

---

# 88. MODE=1 时长

如果报告仍写：

```text
【待第05阶段确定】
```

本 Skill 根据用户项目要求决定。

若仍没有依据：

保留 Parameter，例如：

```verilog
parameter TEST_LOOPS = 1000;
```

并明确：

```text
默认调试值
正式回归值待项目确认
```

不得声称该值是正式要求。

---

# 89. MODE=1 Checker

除正常数据外，

按 Test 需求检查：

```text
Deadlock
Transaction Progress
Pointer Wrap
Counter Drift
Resource Leak
```

---

# 90. P2 MODE=2

错误恢复随机：

每个 Test 独立 TB。

---

# 91. MODE=2 Error Set

只能使用仿真报告已经定义的 Error。

禁止新造：

```text
非法Error类型
```

---

# 92. MODE=2 Recovery

错误后必须按报告继续：

```text
合法事务
```

检查恢复。

---

# 93. MODE=2 统计

当前 TB 内可统计：

```text
Injected Error
Detected Error
Recovery Count
Unexpected Error
```

---

# 94. Testbench 与 Vivado GUI

由于本 Skill 不强制 Tcl，

TB 应设计为方便 Vivado GUI 直接运行。

---

# 95. Vivado GUI 基本方式

TB说明中可以写：

```text
1. Add Sources
2. Add Simulation Sources
3. 将对应tb_xxx.v加入Simulation Sources
4. Set as Top
5. Run Behavioral Simulation
6. 查看Console PASS/FAIL
7. 需要Debug时查看Waveform
```

---

# 96. 每次只运行目标 TB

由于一个 Test 一个 TB：

运行某 Test 时：

```text
Set该TB为Simulation Top
```

即可。

---

# 97. TB 与其他 TB 不应互相依赖

`tb_P1_FIFO_001.v` 不应例化：

```text
tb_P0_BSC_001
```

等另一个 Testbench。

---

# 98. Testbench 独立运行

理论上：

```text
只添加Stable RTL
+
当前TB
+
必要IP模型
```

即可运行。

---

# 99. IP 模型

如果 DUT 使用 Xilinx/第三方 IP：

Testbench 可以依赖：

```text
正式IP仿真模型
```

这不违反自包含原则。

---

# 100. 不得随意 Mock 正式 IP

如果验证需要真实 IP 行为：

不能为了简单随意写假模型。

---

# 101. Behavioral Model

只有报告/设计允许：

```text
Behavioral Stub
```

时才可使用。

---

# 102. File IO

如果当前 Test 需要 Golden Vector：

文件路径尽量使用：

```text
相对路径
```

---

# 103. 文件打开失败

应直接：

```text
FAIL
```

不能继续默默仿真。

---

# 104. Data Compare

数据 Test 至少输出：

```text
Expected
Actual
Index
Cycle/Time
```

用于定位。

---

# 105. Unexpected Output

没有 Expected 事务却输出：

通常：

```text
FAIL
```

具体按设计。

---

# 106. Missing Output

Expected 未在 Timeout 内返回：

```text
FAIL
```

---

# 107. Duplicate Output

如设计不允许：

```text
FAIL
```

---

# 108. Reorder

如果要求 In Order：

乱序：

```text
FAIL
```

---

# 109. Valid Window

Checker 只在：

```text
有效事务
```

时比较 Data。

---

# 110. X/Z Check

关键有效输出出现：

```text
X
Z
```

应视为：

```text
FAIL
```

除非设计明确允许。

---

# 111. 未Reset的数据路径

若：

```text
valid=0
```

且 data 为 X，

设计允许：

不要误报。

---

# 112. Latency

固定 Latency Test：

当前 TB 内记录：

```text
Start Cycle
End Cycle
```

比较 N cycles。

---

# 113. 可变 Latency

如果设计只规定范围：

Checker 使用：

```text
Min / Max
```

而不是固定拍数。

---

# 114. Throughput

如果当前 Test 是性能仿真：

可以在 TB 内统计：

```text
Accepted Beat
Cycle
Bubble
```

---

# 115. 功能仿真不能证明 Fmax

禁止从：

```text
100MHz仿真运行正常
```

得出：

```text
Timing Closure PASS
```

---

# 116. CDC 仿真边界

Testbench 可以验证：

```text
逻辑传递
事件不丢
Async FIFO顺序
Reset交互
```

不能证明：

```text
MTBF
Metastability概率
物理布局
```

---

# 117. TB 静态自检

生成每个 TB 后至少检查：

```text
Module Name
DUT Name
Port
Width
Parameter
Clock
Reset
Task Declaration
Function Declaration
Undefined Signal
Syntax
SystemVerilog语法混入
Timeout
PASS/FAIL
```

---

# 118. Testbench Race Review

重点检查：

```text
TB输入更新时间
DUT采样边沿
Monitor采样时机
```

---

# 119. Blocking Assignment

TB 激励通常可使用：

```verilog
=
```

因为 Testbench 不受 RTL 时序编码规范限制。

但要避免 race。

---

# 120. Nonblocking Assignment

需要模拟寄存器时序行为时也可使用：

```verilog
<=
```

根据仿真语义决定。

---

# 121. `timescale`

每个 TB 文件独立写：

```verilog
`timescale 1ns/1ps
```

或项目指定值。

---

# 122. 每个 TB 独立 Timeout

即使多个 Test Timeout 相同：

也写在每个 TB 内。

---

# 123. 每个 TB 独立 PASS/FAIL

不依赖外部公共 Scoreboard。

---

# 124. 每个 TB 独立仿真结束

每个 Test 完成后：

```verilog
$finish;
```

---

# 125. 不默认使用 `$stop`

自动运行优先：

```verilog
$finish
```

Debug 时才考虑 `$stop`。

---

# 126. TB说明文档

本阶段第二个正式输出：

```text
XX模块_TB说明文档.md
```

---

# 127. TB说明文档目的

该文档不是重复仿真报告。

它只说明：

```text
生成了哪些TB
每个TB对应哪个Test ID
TB文件如何运行
依赖哪些RTL/IP
Seed/Loop如何修改
有哪些已知限制
```

---

# 128. TB说明文档推荐结构

```markdown
# XX模块 Testbench说明

## 1. 文档目的

## 2. 输入依据

## 3. DUT信息

## 4. TB文件目录

## 5. Test ID与TB文件对应关系

## 6. P0 Testbench

## 7. P1 Testbench

## 8. P2 Testbench

## 9. Clock / Reset说明

## 10. Random Seed说明

## 11. Vivado运行方法

## 12. PASS / FAIL规则

## 13. 外部IP/数据文件依赖

## 14. 已知限制 / Blocked Test
```

---

# 129. Test ID 映射表

必须包含：

| Test ID | Test Name | TB File | Status |
|---|---|---|---|
| P0-BSC-001 | | tb_P0_BSC_001_xxx.v | IMPLEMENTED |
| | | | |

---

# 130. Status

统一：

```text
IMPLEMENTED
BLOCKED
N/A
```

---

# 131. IMPLEMENTED

表示：

```text
已生成可执行TB
```

不代表：

```text
仿真已经PASS
```

---

# 132. BLOCKED

例如：

```text
Expected不明确
接口资料冲突
缺少第三方IP模型
无法定义错误注入
```

---

# 133. N/A

只有已确认：

```text
该Test已取消/不适用
```

时使用。

---

# 134. 不得把未实现写成 PASS

TB 开发状态：

```text
IMPLEMENTED
```

和仿真结果：

```text
PASS
```

必须严格区分。

---

# 135. Vivado运行说明

由于不强制脚本，

TB说明中应写 GUI 运行方式。

例如：

```text
打开工程
→
Add Simulation Sources
→
加入目标TB
→
Set as Top
→
Run Behavioral Simulation
```

---

# 136. 独立仿真工程

如果用户习惯单独 Simulation Project：

TB说明可以写：

```text
加入RTL
加入IP
加入当前TB
设置TB Top
运行
```

---

# 137. 不绑定固定本机路径

TB 和说明文档中不要写：

```text
C:\Users\xxx\...
```

这类个人绝对路径。

---

# 138. RTL Stable 保护

本 Skill 默认：

```text
只读 Stable RTL
```

---

# 139. 发现 RTL Bug

TB 开发时如静态发现：

```text
RTL Issue
```

输出：

```text
RTL ISSUE FOUND DURING TB DEVELOPMENT
```

不要直接改 RTL。

---

# 140. 发现 Verification Plan 问题

如果 Test Case 无法实现：

输出：

```text
VERIFICATION PLAN ISSUE
```

例如：

```text
没有具体激励
Expected模糊
Error无法触发
```

---

# 141. 发现 Design 问题

如果必须回到设计确认：

输出：

```text
DESIGN CLARIFICATION REQUIRED
```

---

# 142. 不允许迎合 DUT

禁止：

```text
DUT输出A
↓
就把Expected改成A
```

---

# 143. 不允许删除失败 Checker

不能为了让 Test 运行：

```text
注释Mismatch
忽略Timeout
屏蔽Error
```

---

# 144. 不允许无限延长 Timeout

如果 DUT 未完成：

需要分析原因。

不能把 Timeout 改成：

```text
无限
```

---

# 145. 不虚构实际仿真结果

如果本阶段只生成 TB：

最终回复只能说：

```text
TB已生成
```

不能说：

```text
P0 PASS
P1 PASS
P2 PASS
```

---

# 146. Word 报告回填

当前 Skill 默认不回填：

```text
XX模块_仿真报告_待补充结果.docx
```

因为本阶段定义是：

```text
Testbench代码编写
```

实际执行仿真后再回填。

---

# 147. 如果用户同时要求运行仿真

只有真实执行后，

才允许把：

```text
Result
Wave
Log
Seed
Coverage
```

回填 Word。

---

# 148. P0/P1/P2 完整映射

最终必须做到：

```text
Word Test ID
     ↓
TB File
     ↓
Test Procedure
     ↓
Checker
```

---

# 149. 不再要求 Script 映射

因为当前流程不强制：

```text
.tcl
```

所以无需：

```text
Test ID → Tcl
```

映射。

---

# 150. Testbench代码风格

推荐：

```text
结构清晰
注释完整
Task适度
变量命名明确
Test流程顺序清楚
Checker集中
```

---

# 151. 避免过度工程化

不要为了一个简单 Test：

生成：

```text
Driver Module
Monitor Module
Scoreboard Module
Package
Common
Framework
```

---

# 152. 简单 Test 优先简单实现

例如 Reset Test：

一个 TB 可能只需要：

```text
Clock
Reset
DUT
Check
Timeout
```

即可。

---

# 153. 复杂 Test 仍保持单文件

即使某 Test 复杂，

可以在一个 `.v` 中包含多个：

```text
task
function
always
memory array
```

但不默认拆文件。

---

# 154. 文件长度不是拆分理由

一个复杂 Testbench 即使：

```text
几百行
上千行
```

也优先保持：

```text
Test Case自包含
```

除非用户明确要求重构。

---

# 155. P0 Testbench Checklist

```text
[ ] Test ID正确
[ ] 文件名正确
[ ] DUT正确
[ ] Clock正确
[ ] Reset正确
[ ] 激励来自报告
[ ] Expected来自报告
[ ] Checker存在
[ ] Timeout存在
[ ] PASS/FAIL存在
```

---

# 156. P1 Testbench Checklist

```text
[ ] Test ID正确
[ ] 定向场景正确
[ ] Boundary值正确
[ ] Error触发正确
[ ] Recovery按设计
[ ] Backpressure正确
[ ] Reset场景正确
[ ] Checker完整
[ ] Timeout存在
```

---

# 157. P2 Testbench Checklist

```text
[ ] MODE分类正确
[ ] Test ID正确
[ ] Seed存在
[ ] Seed可修改
[ ] 随机范围合法
[ ] Loop/Duration可配置
[ ] Checker存在
[ ] Timeout存在
[ ] Fail时打印Seed
```

---

# 158. 文件完整性 Checklist

每个 TB：

```text
[ ] 可独立阅读
[ ] 不依赖common TB源文件
[ ] 不依赖其他Testbench
[ ] 所有辅助Task在本文件
[ ] 所有辅助Function在本文件
[ ] PASS/FAIL在本文件
```

---

# 159. 输入完整性 Checklist

```text
[ ] 已读取仿真报告
[ ] 已读取Stable RTL
[ ] 已读取全部Test ID
[ ] 已读取激励
[ ] 已读取Expected
[ ] 已识别Top
[ ] 已识别接口
[ ] 已识别Clock
[ ] 已识别Reset
[ ] 已识别Parameter
[ ] 已识别IP
```

---

# 160. Test ID 完整性检查

仿真报告中的每个测试项：

必须在 TB说明中出现。

状态只能：

```text
IMPLEMENTED
BLOCKED
N/A
```

不能漏项。

---

# 161. P2 随机测试说明

TB说明文档中必须列：

```text
Test ID
MODE
Default Seed
修改Seed位置
Loop/Duration参数
```

---

# 162. External Dependency

如某 TB 依赖：

```text
XCI
IP Simulation Model
Golden Vector
Memory Init
```

必须在 TB说明中列出。

---

# 163. Definition of Done

本 Skill 完成标准：

```text
[ ] 已读取XX模块_仿真报告_待补充结果.docx
[ ] 已读取XX模块RTL稳定版
[ ] 已提取全部P0 Test ID
[ ] 已提取全部P1 Test ID
[ ] 已提取全部P2 Test ID

[ ] 每个适用Test ID对应一个独立TB文件
[ ] 每个TB使用Verilog-2001
[ ] 每个TB自包含
[ ] 每个TB包含Clock
[ ] 每个TB包含Reset
[ ] 每个TB包含DUT实例
[ ] 每个TB包含激励
[ ] 每个TB包含Expected/Checker
[ ] 每个TB包含Timeout
[ ] 每个TB包含PASS/FAIL
[ ] 每个TB包含完整Test Procedure

[ ] 未拆common
[ ] 未拆driver
[ ] 未拆monitor
[ ] 未拆scoreboard
[ ] 未拆ref_model
[ ] 未生成强制Tcl脚本

[ ] P0全部实现或明确BLOCKED
[ ] P1全部实现或明确BLOCKED
[ ] P2全部实现或明确BLOCKED
[ ] P2 Seed可复现
[ ] P2随机范围来自报告

[ ] 已生成TB说明文档.md
[ ] 已建立Test ID→TB文件映射
[ ] 已说明Vivado GUI运行方法
[ ] 已说明外部依赖
[ ] 已说明Blocked项

[ ] 未修改Stable RTL
[ ] 未擅自修改Expected
[ ] 未虚构仿真结果
```

---

# 164. 最终输出目录

推荐最终仅为：

```text
XX模块_TB/
│
├── P0/
│   ├── tb_P0_xxx.v
│   └── ...
│
├── P1/
│   ├── tb_P1_xxx.v
│   └── ...
│
└── P2/
    ├── tb_P2_M0_xxx.v
    ├── tb_P2_M1_xxx.v
    ├── tb_P2_M2_xxx.v
    └── ...

XX模块_TB说明文档.md
```

---

# 165. 第 05 阶段标准定义

最终阶段定义：

```text
05 Testbench代码编写阶段

输入：
XX模块_仿真报告_待补充结果.docx
XX模块RTL稳定版.v
FPGA_Verilog_TB_Development_SKILL.md

输出：
XX模块TB代码
TB说明文档.md
```

---

# 166. 核心原则总结

> 第04阶段定义“测试项、激励和期望”。

> 第05阶段把每一个测试项实现成一个独立 TB。

> 一个 Test ID 对应一个 TB 文件。

> 一个 TB 文件必须自包含。

> Clock、Reset、Driver、Monitor、Reference、Checker、Timeout、PASS/FAIL 全部按需写在当前 TB 文件中。

> 不建立 common/。

> 不默认拆 driver/monitor/scoreboard/ref_model。

> 不强制生成 Tcl。

> 允许不同 TB 之间存在重复代码。

> Test ID 必须与仿真报告保持一致。

> P0/P1/P2 结构必须与仿真报告一致。

> P2 保持 MODE=0 正常随机、MODE=1 长时间稳定、MODE=2 错误恢复随机。

> P2 Seed 必须可复现。

> Expected Result 来自仿真报告/Design，不根据 DUT 输出临时修改。

> Stable RTL 默认只读。

> 没有真实执行仿真时，不得声称 PASS/FAIL。

---

# 167. 最终目标

将：

```text
XX模块_仿真报告_待补充结果.docx
+
XX模块RTL稳定版
```

转换为：

```text
P0 Test ID
↓
独立P0 TB

P1 Test ID
↓
独立P1 TB

P2 Test ID
↓
独立P2 TB
```

每个 TB 文件自身完成：

```text
Clock
+
Reset
+
DUT
+
Stimulus
+
Expected
+
Checker
+
Timeout
+
PASS/FAIL
```

最终形成一套：

```text
测试项一一对应
独立可读
独立可运行
便于Debug
便于结果回填
```

的 FPGA Verilog Testbench 代码体系。
