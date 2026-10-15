---
name: fpga-rtl-verilog-code-review
description: >
  通用 FPGA Verilog RTL 代码独立审查与静态检查 Skill。
  以 FPGA 模块设计方案作为 Golden Design Reference，结合 Verilog-2001 RTL、
  IP 配置清单、接口协议、寄存器表、XCI/XDC/TCL、已有 Review/Lint/CDC/Compile 报告，
  对 RTL 的设计一致性、编码质量、Clock/Reset、CDC/RDC、FSM、FIFO/Memory、
  位宽与算术、协议握手、Pipeline/Latency、IP 使用、综合可行性、
  Timing/Resource 风险及可维护性进行独立审查。
  默认只输出审查结论、问题清单和整改建议，不直接修改 RTL；
  只有用户明确要求整改时才允许生成修改后的 RTL。
version: 0.1
language: zh-CN
rtl_language: Verilog-2001
review_role: independent-reviewer
---

# FPGA RTL Verilog Code Review SKILL

## 0. Skill 定位

本 Skill 用于 FPGA RTL 开发完成后的独立代码审查。

本 Skill 的核心问题是：

> 这份 RTL 是否真实、完整、正确地实现了已确认的 FPGA 设计方案，并达到进入仿真验证阶段的基本质量要求？

本 Skill 默认定位为：

```text
Independent Reviewer
```

而不是：

```text
RTL Author
```

默认行为：

```text
读取设计方案
+
读取RTL
+
读取IP/接口/寄存器等资料
        ↓
独立Review
        ↓
发现问题
        ↓
问题分级
        ↓
输出Review Report
        ↓
输出整改建议
```

默认**不直接修改 RTL**。

只有当用户明确要求：

```text
修复
整改
修改RTL
生成整改版本
```

时，才允许在 Review 结论基础上生成修改后的 RTL。

---

# 1. 在 FPGA 开发流程中的位置

推荐流程：

```text
01 方案设计阶段
   ↓
XX模块设计方案
   ↓
02 RTL逻辑代码编写阶段
   ↓
XX模块RTL代码
IP配置清单
   ↓
03 RTL代码审查与稳定阶段
   ↓
本 Skill
   ↓
RTL代码审查报告
RTL问题整改清单
   ↓
RTL作者整改
   ↓
重新Review
   ↓
RTL Stable
   ↓
04 仿真验证方案设计阶段
```

本 Skill 是：

```text
设计
→
实现
→
独立检查
→
验证
```

之间的质量门。

---

# 2. 与 RTL Development Skill 的职责边界

RTL Development Skill 负责：

```text
如何按照设计方案实现 RTL
```

本 Review Skill 负责：

```text
判断 RTL 是否正确实现设计方案
```

两者必须分离。

Review 时不能因为：

```text
“这是我之前生成的代码”
```

而降低审查标准。

Review 必须重新从设计要求出发。

---

# 3. Golden Reference 原则

Review 的最高设计依据称为：

```text
Golden Design Reference
```

通常为：

```text
XX模块设计方案
```

如果存在更正式的项目资料，可包括：

- 正式接口协议；
- 正式寄存器表；
- 正式数据格式；
- 正式时钟复位定义；
- 正式 IP 配置；
- 正式设计变更记录。

Review 的核心关系：

```text
Golden Design Reference
           ↓
        Compare
           ↓
          RTL
```

---

# 4. 输入资料

## 4.1 必须输入

至少应提供：

```text
1. XX模块设计方案
2. XX模块RTL代码
```

---

## 4.2 推荐输入

推荐同时提供：

```text
IP配置清单.md
接口协议
寄存器表
数据格式说明
XCI
XDC
TCL
已有RTL_README
CDC清单
Design Deviation
Open Issues
Change Log
```

---

## 4.3 工具报告

如有，应读取：

```text
Vivado Compile Log
Vivado Synthesis Report
Lint Report
CDC Report
RDC Report
DRC Report
Timing Report
Utilization Report
```

但是：

本 Skill 当前阶段主要针对 RTL 前端 Review。

如果用户尚未进入综合实现阶段：

```text
Synthesis
Implementation
Timing Closure
```

不是 Review 通过的前置条件。

---

# 5. 输入资料优先级

如果资料冲突，优先级原则：

```text
用户当前明确指令
    ↓
正式设计方案
    ↓
正式接口协议 / 寄存器表
    ↓
已批准设计变更
    ↓
已确认IP配置
    ↓
RTL实现
    ↓
历史文档
```

不能把：

```text
RTL当前实现
```

自动视为正确设计。

---

# 6. 冲突处理

发现文档与 RTL 冲突时，不要自行替用户选择。

输出：

```text
CONFLICT ID:
资料A:
资料B:
RTL行为:
影响:
建议:
当前Review结论:
```

如果冲突会导致无法判断正确行为：

```text
REVIEW BLOCKED
```

---

# 7. 缺失资料分类

## 7.1 Blocking

缺失后无法判断 RTL 正确性。

例如：

```text
接口定义缺失
Clock关系未知
Reset极性冲突
TLAST定义未知
寄存器语义未知
FIFO深度来源未知
Latency要求未知但RTL依赖固定时延
```

处理：

```text
BLOCKING ISSUE
```

---

## 7.2 Non-Blocking

缺失后仍可完成主要 Review。

例如：

```text
作者
修改日期
部分注释
非关键命名规则
```

可继续 Review，但记录：

```text
INFORMATION GAP
```

---

# 8. Review 证据等级

所有结论必须区分证据来源。

## 8.1 STATIC

表示：

```text
仅通过代码和文档静态审查得出
```

---

## 8.2 TOOL-VERIFIED

表示：

```text
由真实工具报告验证
```

例如：

```text
Vivado Compile
Lint Tool
CDC Tool
Synthesis
```

---

## 8.3 NEEDS-SIMULATION

表示：

```text
仅靠静态代码无法可靠证明
需要仿真验证
```

---

## 8.4 NEEDS-IMPLEMENTATION

表示：

```text
需要综合 / Implementation / STA 后才能确认
```

---

# 9. 禁止虚构 Tool PASS

如果没有真实运行：

```text
Vivado Compile
Lint
CDC
Synthesis
Implementation
```

不得写：

```text
Compile PASS
Lint PASS
CDC PASS
Timing PASS
```

只能写：

```text
Static Review: PASS
Tool Verification: NOT RUN / NOT PROVIDED
```

---

# 10. Review 结论状态

每个检查项使用：

```text
PASS
FAIL
WARNING
TBD
N/A
NEEDS-SIMULATION
NEEDS-TOOL
BLOCKED
```

含义：

### PASS

有足够证据支持正确。

### FAIL

发现明确缺陷。

### WARNING

存在明显风险，但不一定构成功能错误。

### TBD

信息不足，待确认。

### N/A

本设计不适用。

### NEEDS-SIMULATION

静态 Review 无法闭环。

### NEEDS-TOOL

需要 Vivado / Lint / CDC 等工具。

### BLOCKED

关键资料冲突或缺失，无法继续判断。

---

# 11. 问题严重等级

统一分为：

```text
Critical
Major
Minor
Suggestion
```

---

# 12. Critical 定义

满足以下任一情况可判 Critical：

- 可能导致核心功能完全错误；
- 可能造成数据破坏；
- 可能造成系统死锁；
- 明确错误 CDC；
- Clock 架构错误；
- 关键 Reset 行为错误；
- 多驱动；
- 组合环；
- 严重协议违规；
- 数据宽度导致关键数据丢失；
- 可能导致存储越界；
- 设计要求与 RTL 核心行为完全不一致；
- 明显不可综合且阻塞交付。

Critical 必须：

```text
MUST FIX
```

---

# 13. Major 定义

例如：

- 边界条件错误；
- Error Handling 不完整；
- FIFO Overflow/Underflow 风险；
- FSM 异常恢复错误；
- Pipeline Metadata 对齐错误；
- Backpressure 处理不完整；
- 寄存器语义错误；
- IP 参数或 Latency 使用错误；
- 重要 Timing 风险；
- 重要资源风险。

Major 必须在进入正式仿真回归前关闭。

---

# 14. Minor 定义

例如：

- 非关键命名问题；
- 注释不完整；
- 局部结构可读性差；
- 非关键未使用信号；
- 参数化不理想；
- 非功能性警告。

---

# 15. Suggestion 定义

属于：

```text
优化建议
可维护性建议
代码风格建议
未来扩展建议
```

不应与 Bug 混为一谈。

---

# 16. Review Gate

建议进入下一阶段的最低门槛：

```text
Critical = 0
Major    = 0
```

同时：

```text
所有 Blocking Issue 已解决
关键 Design Deviation 已确认
关键 TBD 已关闭或明确进入仿真验证
```

Minor 和 Suggestion 可由项目决定是否延期处理。

---

# 17. Review 总体流程

```text
Step 1 读取全部资料
      ↓
Step 2 建立Design Baseline
      ↓
Step 3 建立RTL Module Map
      ↓
Step 4 建立Interface Map
      ↓
Step 5 建立Clock/Reset Map
      ↓
Step 6 建立CDC/RDC Map
      ↓
Step 7 建立Data/Control Flow
      ↓
Step 8 设计一致性Review
      ↓
Step 9 RTL编码Review
      ↓
Step10 功能结构Review
      ↓
Step11 Protocol/FIFO/FSM/Width Review
      ↓
Step12 Timing/Resource Risk Review
      ↓
Step13 问题分级
      ↓
Step14 输出Review Report
```

---

# 18. Review 前建立 Design Baseline

首先提取设计方案中的：

```text
Module
Function
Scope
Parameter
Clock
Reset
Input
Output
Protocol
Data Format
Data Flow
Control Flow
FSM
FIFO
Memory
CDC
RDC
Register
IP
Latency
Throughput
Error Handling
```

然后形成：

```text
Design Baseline
```

Review 不允许跳过这一步直接阅读 RTL 后凭经验判断。

---

# 19. RTL Module Map

列出：

| Module | File | Responsibility | Clock | Reset | Design Reference |
|---|---|---|---|---|---|
| | | | | | |

检查：

```text
设计方案中的模块是否都存在？
RTL是否出现设计中没有说明的大模块？
模块职责是否一致？
```

---

# 20. Top Module Review

检查 Top 是否主要承担：

```text
实例化
连接
Clock/Reset分发
Parameter传递
IP Wrapper连接
```

检查是否出现：

- 大型 FSM 直接堆在 Top；
- 多个独立业务逻辑混杂；
- Top 与设计架构图严重不一致。

---

# 21. Module Responsibility Review

每个模块检查：

```text
负责什么
不负责什么
输入来源
输出去向
核心状态
存储
错误行为
```

发现一个模块承担过多职责：

通常：

```text
WARNING / Maintainability
```

如果造成设计边界不清或功能耦合：

可升级为：

```text
Major
```

---

# 22. Parameter Review

检查：

- Parameter 名称；
- 默认值；
- 允许范围；
- 参数依赖；
- 是否与设计一致；
- 是否存在非法参数组合；
- 是否使用无理由 Magic Number。

参数属于内部固定常量时，优先：

```text
localparam
```

---

# 23. Top Interface Review

逐项比较：

```text
Design Port
vs
RTL Port
```

检查：

- Signal Name；
- Direction；
- Width；
- Clock Domain；
- Reset State；
- Active Level；
- Handshake；
- Encoding；
- Sideband；
- Optional Signal。

---

# 24. Interface Review 输出表

| Signal | Design | RTL | Width | Direction | Clock | Result |
|---|---|---|---:|---|---|---|
| | | | | | | |

---

# 25. Internal Interface Review

除了顶层，还要检查关键内部接口。

特别关注：

```text
Valid/Ready
Req/Ack
FIFO接口
Memory接口
Register接口
Packet接口
CDC边界
IP Wrapper接口
```

---

# 26. Clock Review

建立：

```text
Clock Domain Map
```

| Clock | Frequency | Source | Modules | Design | RTL | Result |
|---|---:|---|---|---|---|---|
| | | | | | | |

检查：

- RTL 使用了哪些 Clock；
- 是否全部来自设计；
- 是否有未说明新 Clock；
- 时钟域是否正确；
- 是否错误跨域；
- 是否用普通逻辑生成 Clock。

---

# 27. Logic Generated Clock

发现：

```verilog
assign clk_new = clk & en;
```

或类似普通逻辑直接形成业务 Clock：

默认：

```text
Critical / Major
```

根据用途判断。

建议：

```text
Clock Enable
或
FPGA专用Clock Resource
```

---

# 28. Clock Enable Review

检查：

- Enable 是否来自正确 Clock Domain；
- Enable 是否产生意外漏拍；
- Enable 是否与 Pipeline 控制一致；
- 是否误把 Clock Enable 当跨时钟同步手段。

---

# 29. Reset Review

建立：

| Reset | Polarity | Sync/Async | Clock Domain | Scope | Release | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

检查：

```text
Reset来源
极性
同步/异步
作用域
Assert
Deassert
Reset值
局部软复位
外部IP复位
```

---

# 30. Reset 极性冲突

如果：

```text
设计方案 = Active High
RTL      = Active Low
```

属于：

```text
Critical / Major
```

不得用“项目通常使用低有效”解释。

Review 永远以当前设计依据为准。

---

# 31. Reset Release Review

若为异步 Reset：

检查是否存在：

```text
Async Assert
Sync Deassert
```

或设计方案指定的其他安全策略。

如果多个寄存器直接异步释放导致状态一致性风险：

```text
Major / Critical
```

---

# 32. Reset Coverage Review

检查需要 Reset 的状态是否正确初始化：

- FSM；
- Valid；
- Busy；
- Done；
- Error；
- Pointer；
- Counter；
- Interrupt；
- Sticky Status。

同时检查是否对大量数据 Pipeline 无理由 Reset。

---

# 33. RDC Review

检查：

```text
不同Reset Domain之间的控制交互
局部Reset后握手另一端状态
FIFO两侧Reset关系
IP Reset关系
软Reset时事务清理
```

如果无法静态确认：

```text
NEEDS-SIMULATION
或
NEEDS-CDC/RDC TOOL
```

---

# 34. CDC Inventory

所有跨时钟信号必须建立清单。

| ID | Source Clock | Destination Clock | Signal/Data | Type | Method | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 35. CDC 单 bit Level Review

检查：

```text
是否使用2FF/官方CDC结构
同步器是否在Destination Clock
同步级数是否合理
是否有ASYNC_REG等项目要求属性
```

2FF 只证明：

```text
单bit Level
```

不能证明：

```text
Pulse
Multi-bit Data
Bus
```

---

# 36. CDC Pulse Review

检查：

- Pulse 宽度；
- Source/Destination Clock 比例；
- 是否可能连续事件；
- 是否允许事件丢失；
- 使用 Pulse Stretch / Toggle / Handshake 是否正确。

普通 2FF 可能丢 Pulse。

---

# 37. CDC Multi-bit Review

禁止：

```text
每一bit单独2FF后直接组合使用
```

检查是否采用：

```text
Handshake
Stable Data
Gray Code
Async FIFO
```

等正确方法。

---

# 38. CDC Streaming Review

连续 Data Stream 跨时钟：

优先检查是否使用：

```text
Async FIFO
```

或设计明确的等价可靠方案。

---

# 39. Gray Code Review

若使用 Gray Pointer：

检查：

- Binary → Gray；
- Gray 同步；
- Full/Empty 判断；
- Pointer Width；
- Wrap Bit；
- Reset；
- 同步级数。

自研 Async FIFO 属于高风险 Review 项。

---

# 40. CDC 工具边界

仅通过人工代码 Review：

不得写：

```text
CDC CLEAN
```

可以写：

```text
Manual CDC Review completed
CDC Tool Verification: NOT PROVIDED
```

---

# 41. FSM Review

建立：

| State | Design Function | RTL Encoding | Entry | Exit | Error Path | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 42. FSM 重点检查

检查：

```text
Reset State
正常流程
边界流程
异常流程
非法状态
Timeout
Abort
恢复路径
Done路径
返回安全状态
```

---

# 43. FSM Deadlock Review

重点寻找：

```text
等待永远不会发生的信号
握手双方互相等待
只进入不退出状态
Error后无法恢复
Busy永久保持
```

明确死锁：

```text
Critical
```

潜在永久等待但需求允许：

需记录设计依据。

---

# 44. FSM Default Review

有组合 `case` 时：

检查 default 是否：

```text
安全
符合设计
不会破坏正在进行事务
```

不能机械认为：

```text
default → IDLE
```

永远正确。

---

# 45. FSM Output Review

检查 Moore / Mealy 输出：

- 是否与设计一致；
- 是否可能 Glitch；
- 是否跨 Clock；
- 是否需要寄存；
- 是否与 State Transition 同拍关系正确。

---

# 46. Verilog-2001 Language Review

项目要求 Verilog 时，检查是否出现 SystemVerilog 专用语法：

```text
logic
always_ff
always_comb
typedef
enum
interface
struct
package
```

若出现：

```text
FAIL
```

除非项目明确允许。

---

# 47. Implicit Net Review

检查拼写错误导致的隐式 wire。

推荐：

```verilog
`default_nettype none
```

如果项目未使用该指令：

仍需检查：

```text
Undeclared Signal
```

---

# 48. Blocking / Non-Blocking Review

规则：

```text
组合逻辑 =
时序逻辑 <=
```

检查：

- 同一寄存器是否混用；
- 时序逻辑中 Blocking 是否改变预期顺序；
- 组合逻辑 Non-blocking 是否产生仿真语义问题。

---

# 49. Latch Review

寻找：

```text
if缺else
case不完整
组合输出未赋默认值
next-state未完整赋值
```

非预期 Latch：

```text
Major
```

若进入关键控制：

可为：

```text
Critical
```

---

# 50. Multiple Driver Review

同一 reg 多 always 驱动：

```text
Critical
```

同一 Net 多驱动但非明确 Tri-State：

```text
Critical
```

---

# 51. Combinational Loop Review

检查：

```text
Ready链
Grant
FSM Next
Mux
Control
```

是否形成：

```text
A → B → A
```

明确组合环：

```text
Critical
```

---

# 52. Undriven / Unused Review

检查：

```text
Undriven Signal
Unused Input
Unused Register
Constant Output
Unconnected Critical Port
```

不能因为信号未使用就自动删除。

先确认：

```text
设计是否要求
预留接口是否允许
```

---

# 53. Width Review

每个关键表达式检查：

```text
Input Width
Expression Width
Output Width
```

重点：

```text
加法
减法
乘法
比较
移位
拼接
索引
地址
Counter
Length
```

---

# 54. Truncation Review

如果从宽信号赋值到窄信号：

检查是否显式：

```verilog
assign data_o = result[7:0];
```

隐式截断：

至少：

```text
WARNING
```

如果会丢关键数据：

```text
Major / Critical
```

---

# 55. Extension Review

检查：

```text
Zero Extension
Sign Extension
```

是否正确。

特别是：

```text
地址
长度
有符号算术
比较
```

---

# 56. Signed / Unsigned Review

检查：

```text
signed声明
混合signed/unsigned
比较
乘法
右移
扩展
```

任何依赖 Verilog 隐式 signed 传播的关键算法都应重点 Review。

---

# 57. Overflow Review

对：

```text
Counter
Accumulator
Address
Length
Arithmetic
```

确认溢出策略：

```text
Wrap
Saturate
Error
Impossible by Constraint
```

---

# 58. Fixed Point Review

如果使用定点：

检查：

```text
Q格式
Signed
小数位
中间位宽
Round
Truncate
Saturate
Pipeline格式
```

如果设计方案未定义：

```text
BLOCKING / DESIGN ISSUE
```

视影响程度判断。

---

# 59. Arithmetic Review

重点：

```text
+
-
*
/
%
Variable Shift
```

检查：

```text
功能正确性
位宽
Signed
资源
Latency
Timing风险
```

---

# 60. Division Review

如果直接使用：

```verilog
/
%
```

检查：

- 除数是否常量；
- 是否 2 的幂；
- 是否组合除法；
- 是否符合目标频率；
- 是否应使用 Divider IP；
- 除零处理。

高频大位宽组合除法：

```text
HIGH TIMING/RESOURCE RISK
```

---

# 61. Shift Review

Variable Shift：

检查是否形成大 Barrel Shifter。

如果位宽大且目标 Fmax 高：

```text
Timing Risk
```

---

# 62. Counter Review

每个关键 Counter 检查：

```text
初值
宽度
最大值
+1条件
清零条件
溢出
比较值
Off-by-One
```

Off-by-One 属于高频 Bug 类型。

---

# 63. Address Arithmetic Review

检查：

```text
base + index * stride
地址宽度
对齐
越界
Wrap
Burst边界
4KB边界（如协议要求）
```

---

# 64. Pipeline Review

建立：

| Path | Signal | Design Latency | RTL Latency | Alignment | Result |
|---|---|---:|---:|---|---|
| | | | | | |

---

# 65. Data / Metadata Alignment

如果数据 Pipeline N 拍：

检查：

```text
Valid
SOP
EOP
TLAST
TKEEP
ID
USER
ERROR
CHANNEL
LENGTH
```

是否保持事务对应关系。

---

# 66. Pipeline Stall Review

如果支持 Backpressure：

检查 Stall 时：

```text
Data是否保持
Valid是否保持
Metadata是否保持
Pipeline后级是否覆盖前级
```

---

# 67. Latency Review

比较：

```text
Design Expected Latency
vs
RTL Actual Latency
```

如果不能仅静态确认：

```text
NEEDS-SIMULATION
```

不能猜。

---

# 68. Throughput Review

检查结构是否支持设计要求：

例如：

```text
1 beat / cycle
1 packet / N cycles
N channels
```

静态 Review 只能判断结构风险。

最终吞吐需要仿真或系统测试时：

标记：

```text
NEEDS-SIMULATION
```

---

# 69. Ready / Valid Review

如果采用 Ready/Valid：

传输条件：

```text
valid && ready
```

检查：

当：

```text
valid=1
ready=0
```

是否按协议保持：

```text
valid
data
sideband
```

---

# 70. Backpressure Review

检查：

```text
下游Ready=0时数据保存位置
上游停止条件
Pipeline缓存空间
FIFO满传播
是否丢数据
是否覆盖数据
```

---

# 71. Combinational Ready Path

如果 Ready 从下游一路组合反馈到上游：

检查：

```text
组合路径长度
层级
Fanout
Timing Risk
组合环风险
```

必要时建议：

```text
Skid Buffer
Register Slice
Elastic Buffer
```

但 Review Skill 不擅自修改。

---

# 72. AXI Review

如涉及 AXI：

必须依据正式 AXI 接口定义及项目设计。

检查相关通道：

```text
VALID/READY
ADDR
DATA
RESP
BURST
LEN
SIZE
LAST
STRB
KEEP
ID
USER
```

不得凭经验补充项目未定义信号。

---

# 73. AXI-Lite Review

重点检查：

```text
AWVALID/AWREADY
WVALID/WREADY
BVALID/BREADY
ARVALID/ARREADY
RVALID/RREADY
```

特别注意：

```text
AW
W
```

是独立通道。

如果 RTL 假设二者必须同拍：

通常为：

```text
Major
```

---

# 74. AXI-Stream Review

重点：

```text
TVALID
TREADY
TDATA
TLAST
TKEEP
TUSER
```

Backpressure 时必须满足协议稳定性。

---

# 75. Req/Ack Review

自定义 Request/Acknowledge：

确认：

```text
Req是Pulse还是Level
Ack是Pulse还是Level
是否允许连续Req
Busy时Req处理
Timeout
取消
```

---

# 76. Packet / Frame Review

检查：

```text
最小包
最大包
单Beat包
连续包
SOP
EOP
TLAST
Length
Padding
TKEEP
异常中止
Reset中止
```

---

# 77. FIFO Review

建立：

| FIFO | Type | Clock | Width | Depth | Full | Empty | Reset | Result |
|---|---|---|---:|---:|---|---|---|---|
| | | | | | | | | |

---

# 78. FIFO Depth Review

比较：

```text
设计深度
vs
RTL/IP配置深度
```

如果不同：

```text
Design Deviation / FAIL
```

不能因为 RTL 深度“看起来更大”就自动认为可接受。

---

# 79. FIFO Full Review

检查写使能：

```text
full时是否禁止写
Overflow如何处理
Almost Full是否使用正确
```

---

# 80. FIFO Empty Review

检查读使能：

```text
empty时是否禁止读
Underflow如何处理
FWFT模式是否正确理解
```

---

# 81. Async FIFO Review

重点：

```text
写Clock
读Clock
Reset
Pointer
Full/Empty
CDC
IP配置
Width Conversion
```

自研 Async FIFO 应提高 Review 优先级。

---

# 82. FIFO Reset Review

检查：

- 两侧 Reset 是否同时；
- 是否允许独立 Reset；
- Reset 后 Full/Empty 状态；
- Reset 期间读写是否屏蔽；
- Reset 后旧数据是否有效。

---

# 83. Memory Review

检查：

```text
RAM类型
Depth
Width
Port
Clock
Read Latency
Write Mode
Address
Collision
Reset
Initialization
```

---

# 84. BRAM/URAM Inference Review

若使用 RTL 推断：

检查代码结构是否明显匹配目标 Vivado 支持的推断方式。

如无实际综合报告：

不得声称：

```text
已成功推断BRAM
```

只能：

```text
Expected BRAM Inference
Needs Synthesis Verification
```

---

# 85. Memory Read Latency Review

设计认为：

```text
Read = combinational
```

RTL/IP 实际：

```text
1/2 cycle
```

会导致严重数据/状态错位。

重点检查。

---

# 86. IP Review

建立：

| IP | Version | Config | Design Use | RTL Wrapper | Latency | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 87. IP Version Review

检查：

```text
Vivado Version
IP Version
XCI
FPGA Family
```

如果无法确认：

```text
NEEDS-TOOL / TBD
```

不要猜。

---

# 88. IP Parameter Review

至少检查：

```text
Width
Depth
Clock
Reset
Mode
Latency
Handshake
Optional Port
```

是否与设计和 Wrapper 一致。

---

# 89. IP Wrapper Review

检查 Wrapper 是否：

```text
隔离官方IP端口
暴露稳定业务接口
参数清晰
Clock/Reset正确
无隐藏协议转换
```

---

# 90. Black Box Review

第三方 IP 无源码时：

Review 只允许依据：

```text
接口
协议
官方说明
参数
Latency
```

不得推断其内部行为。

---

# 91. Register Map Review

建立：

| Address | Field | Access | Reset | Design | RTL | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

检查：

```text
Address
Bit Field
Reset Value
Access Type
Side Effect
```

---

# 92. RW / RO Review

确保：

```text
RO不能被软件写改变
RW读回值正确
```

---

# 93. W1C Review

Write-1-to-Clear：

重点检查：

```text
Hardware Set
Software Clear
同时发生时优先级
```

优先级必须来自设计。

---

# 94. Sticky Status Review

Sticky Error 应：

```text
置位后保持
直到Reset或Clear
```

如果错误状态自动下一拍消失：

可能为：

```text
Major
```

---

# 95. Pulse Register Review

软件触发 Pulse：

检查：

```text
Pulse宽度
Clock Domain
CDC
重复触发
Busy期间行为
```

---

# 96. Interrupt Review

检查：

```text
Interrupt Source
Mask
Enable
Status
Clear
Pulse/Level
Priority
CDC
```

---

# 97. Error Handling Review

建立：

| Error | Detect | Record | Report | Recover | Reset Required | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 98. Timeout Review

检查：

```text
计时起点
停止条件
Counter
Timeout值
Off-by-One
Timeout动作
状态恢复
Error记录
```

---

# 99. Abort / Cancel Review

如果允许中止：

确认：

```text
正在处理的数据怎么办
FIFO怎么办
Outstanding事务怎么办
状态如何恢复
Done/Error如何返回
```

---

# 100. Data Format Review

比较：

```text
位域
Byte Order
Endian
Field Width
Reserved
Header
Payload
CRC
```

---

# 101. Width Conversion Review

例如：

```text
32 → 128
128 → 32
```

检查：

```text
低位/高位顺序
Beat计数
TLAST
Padding
Keep
不完整最后一拍
Backpressure
```

---

# 102. Arbitration Review

如果有多个请求源：

检查：

```text
Priority
Round Robin
Fairness
Starvation
Hold Grant
Release
```

与设计一致。

---

# 103. Concurrent Transaction Review

支持多个并发时：

检查：

```text
ID
Tag
Context
Ordering
Completion
Buffer
Resource Conflict
```

---

# 104. Ordering Review

明确：

```text
In Order
Out of Order
Per Channel Order
```

并检查 RTL。

---

# 105. Synthesis Feasibility Review

静态检查不可综合或高风险结构：

```text
#delay
wait
force
release
fork/join
仿真专用系统任务
不合适initial
动态行为
```

---

# 106. Simulation-only Code Review

若使用：

```verilog
`ifndef SYNTHESIS
```

检查：

- 是否只用于仿真；
- 是否会导致综合/仿真行为不一致；
- 是否污染生产 RTL。

---

# 107. Initial Review

普通业务 RTL：

默认不应依赖 `initial`。

如果用于 FPGA RAM/ROM 初始化：

必须：

```text
设计允许
Vivado支持
器件支持
综合行为明确
```

否则：

```text
WARNING / FAIL
```

---

# 108. Timing Risk Review

本阶段只做：

```text
RTL-level Timing Risk
```

不是 STA。

检查：

```text
Large Mux
Priority Encoder
Wide Compare
Wide Adder
Variable Shift
Division
High Fanout
Long Ready Chain
Deep Combinational Logic
```

---

# 109. Timing Risk 等级

建议：

```text
LOW
MEDIUM
HIGH
CRITICAL
```

注意：

`HIGH TIMING RISK`

不等于：

`Timing FAIL`

因为还没有真实 STA。

---

# 110. Resource Risk Review

静态关注：

```text
超大Register Array
大乘法
除法
多通道复制
大FIFO
宽Mux
大量Counter
大量Reset
```

未综合前：

不得给出实际：

```text
LUT
FF
BRAM
DSP
```

数量。

---

# 111. High Fanout Review

检查：

```text
Reset
Enable
Start
Mode
Clear
Valid
```

是否驱动大量逻辑。

只输出：

```text
High Fanout Risk
```

除非有真实工具数据。

---

# 112. Attribute Review

检查：

```text
keep
dont_touch
mark_debug
use_dsp
ram_style
ASYNC_REG
```

是否：

- 有明确目的；
- 使用位置正确；
- 没有滥用；
- 不会妨碍综合优化。

---

# 113. dont_touch Review

大量 `dont_touch`：

默认：

```text
WARNING
```

如果导致架构或 Timing 难以优化：

可提高等级。

---

# 114. Maintainability Review

检查：

```text
模块职责
命名
代码层级
Parameter
Magic Number
注释
重复代码
Wrapper
Include依赖
```

---

# 115. Comment Review

好注释应解释：

```text
为什么
协议
边界
特殊时序
异常策略
```

不要求每一行代码都有注释。

---

# 116. TODO/FIXME Review

发现：

```text
TODO
FIXME
TEMP
HACK
```

必须列入：

```text
Open Issue
```

不能让未说明 TODO 随 Stable RTL 发布。

---

# 117. Existing RTL Minimize Diff Review

如果本次是修改已有 RTL：

检查是否符合：

```text
Minimize Diff
```

关注：

```text
无关重构
接口变化
命名大改
Latency变化
额外行为变化
```

---

# 118. Change Scope Review

对于 Bug Fix：

必须能回答：

```text
修改了什么
为什么修改
影响哪些模块
影响哪些接口
影响Latency吗
影响CDC吗
影响验证项吗
```

---

# 119. Design Deviation Review

读取已有：

```text
RTL_DESIGN_DEVIATION
```

逐项判断：

```text
已批准
待批准
不允许
需反标
```

---

# 120. 未记录 Design Deviation

如果 Review 发现：

```text
RTL和Design不同
```

但没有 Design Deviation：

新增 Review Issue：

```text
DESIGN DEVIATION NOT RECORDED
```

---

# 121. Design Back-Annotation

如果稳定 RTL 与原设计存在已批准差异：

输出：

```text
DESIGN BACK-ANNOTATION REQUIRED
```

列出：

```text
Module
Interface
Clock
Reset
FSM
FIFO
IP
Parameter
Latency
Error Handling
```

需要更新的内容。

---

# 122. 仿真前可静态关闭的问题

通常应在进入仿真前关闭：

```text
接口不一致
明显语法问题
Multiple Driver
Latch
组合环
错误CDC
Reset极性错误
FSM明显死锁
关键位宽错误
FIFO错误使用
协议明显违规
```

---

# 123. 必须留给仿真的问题

以下问题通常需要进入仿真验证：

```text
复杂时序交互
Backpressure随机组合
Reset运行中注入
Packet边界
并发竞争
长时间压力
Error Injection
Reference Model数据正确性
Latency动态行为
```

标记：

```text
NEEDS-SIMULATION
```

不要把它当 Review 未完成。

---

# 124. Review Issue 标准格式

每个问题必须使用统一结构：

```text
Review ID:
RTL-REV-001

Severity:
Critical / Major / Minor / Suggestion

Category:
CDC / Reset / FSM / Width / Protocol / ...

Evidence:
STATIC / TOOL-VERIFIED

File:
xxx.v

Module:
xxx

Line:
如可确定则填写

Design Reference:
设计方案章节/表/接口

Issue:
问题描述

Risk:
可能造成的影响

Recommendation:
建议整改方案

Verification:
整改后如何验证

Status:
OPEN / FIXED / VERIFIED / ACCEPTED / DEFERRED
```

---

# 125. Line Number 原则

如果能够准确确定源代码行号：

必须提供。

如果不能准确确定：

不要虚构。

可使用：

```text
Module + always block + signal
```

作为定位。

---

# 126. Review Issue ID

统一：

```text
RTL-REV-001
RTL-REV-002
RTL-REV-003
```

重新 Review 时保留原 ID。

不要每轮 Review 重新编号导致问题追踪断裂。

---

# 127. Issue 状态

建议：

```text
OPEN
FIXED
VERIFIED
ACCEPTED
DEFERRED
CLOSED
```

---

# 128. FIXED 与 VERIFIED 区别

```text
FIXED
```

表示：

```text
代码声称已修改
```

```text
VERIFIED
```

表示：

```text
Reviewer重新检查修改结果
```

只有 VERIFIED 才可关闭关键问题。

---

# 129. ACCEPTED Risk

如果用户明确接受某风险：

状态可：

```text
ACCEPTED
```

必须记录：

```text
接受原因
影响
责任/批准依据
```

Review Skill 不得自行接受 Critical Bug。

---

# 130. Review Report 输出

主输出：

```text
XX模块_RTL_Code_Review_Report.md
```

---

# 131. Review Report 标准章节

```markdown
# XX模块 RTL Code Review Report

## 1. Review信息

## 2. Review输入

## 3. Review范围

## 4. Review方法和证据等级

## 5. 总体结论

## 6. 问题统计

## 7. Design Compliance Review

## 8. Module / Interface Review

## 9. Clock / Reset Review

## 10. CDC / RDC Review

## 11. Verilog Coding Review

## 12. FSM Review

## 13. Width / Arithmetic Review

## 14. Protocol / Handshake Review

## 15. FIFO / Memory Review

## 16. Pipeline / Latency Review

## 17. Register / Error Handling Review

## 18. IP Review

## 19. Synthesis Feasibility Review

## 20. Timing / Resource Risk Review

## 21. Maintainability Review

## 22. Design Deviation

## 23. Needs Simulation / Needs Tool

## 24. Open Issues

## 25. Review Gate
```

---

# 132. 问题统计表

| Severity | Open | Fixed | Verified | Accepted |
|---|---:|---:|---:|---:|
| Critical | 0 | 0 | 0 | 0 |
| Major | 0 | 0 | 0 | 0 |
| Minor | 0 | 0 | 0 | 0 |
| Suggestion | 0 | 0 | 0 | 0 |

---

# 133. Review Summary

总体结论只允许：

```text
PASS
PASS WITH MINOR ISSUES
FAIL
BLOCKED
```

---

# 134. PASS 条件

建议：

```text
Critical = 0
Major = 0
Blocking = 0
```

并且：

```text
关键设计一致性已确认
关键CDC/RDC无明确未处理错误
关键接口无明确协议错误
```

---

# 135. PASS WITH MINOR ISSUES

只有：

```text
Minor
Suggestion
```

遗留时可使用。

不得存在未关闭的：

```text
Critical
Major
```

---

# 136. FAIL

存在：

```text
Critical
Major
```

问题时：

```text
FAIL
```

---

# 137. BLOCKED

关键设计输入缺失或冲突，无法判断正确 RTL 行为：

```text
BLOCKED
```

---

# 138. RTL问题整改清单

第二个输出：

```text
XX模块_RTL_Issue_List.md
```

格式：

| ID | Severity | Category | File/Module | Issue | Recommendation | Status |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 139. CDC Review 输出

附表：

```text
XX模块_RTL_CDC_Review.md
```

如果项目规模小，可直接放主 Review Report。

格式：

| ID | Src Clock | Dst Clock | Signal | Type | Method | Review | Tool |
|---|---|---|---|---|---|---|---|
| | | | | | | | |

---

# 140. Clock / Reset Review 输出

格式：

| Domain | Clock | Reset | Polarity | Reset Method | RTL Scope | Result |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 141. Design Compliance Matrix

格式：

| Design Item | Design Reference | RTL Reference | Result | Issue ID |
|---|---|---|---|---|
| Module | | | | |
| Interface | | | | |
| Clock | | | | |
| Reset | | | | |
| FSM | | | | |
| FIFO | | | | |
| IP | | | | |
| Latency | | | | |
| Error Handling | | | | |

---

# 142. Needs Simulation List

Review 后明确输出：

```text
XX模块_Needs_Simulation.md
```

或者放主报告中。

例如：

| ID | Verification Point | Reason | Related Design | Priority |
|---|---|---|---|---|
| SIM-001 | Backpressure随机测试 | 静态无法证明所有组合 | 2.3.3 | High |

该清单可以直接作为后续：

```text
FPGA_Simulation_Verification_Plan_SKILL
```

的输入。

---

# 143. Needs Tool List

列出：

```text
Compile
Lint
CDC
Synthesis
```

仍需要真实工具验证的内容。

例如：

| Check | Status | Required Tool | Reason |
|---|---|---|---|
| Compile | NOT RUN | Vivado | 需要确认语法和展开 |
| CDC | STATIC ONLY | CDC Tool | 需要结构化检查 |

---

# 144. Review 整改模式

默认：

```text
Review Only
```

如果用户明确要求整改：

进入：

```text
Review + Fix
```

---

# 145. Review + Fix 规则

整改前必须：

1. 保留原 Review Issue ID；
2. 只修改对应问题；
3. 遵循 Minimize Diff；
4. 不顺带大规模重构；
5. 不擅自改变接口；
6. 不擅自改变设计方案；
7. 不擅自改变 Latency；
8. 修改后重新 Review。

---

# 146. 整改版本输出

如果用户明确要求修复：

输出：

```text
XX模块_RTL_Fixed/
```

以及：

```text
XX模块_RTL_Fix_Log.md
```

---

# 147. Fix Log

格式：

| Review ID | File | Before | Fix | Impact | Re-review |
|---|---|---|---|---|---|
| | | | | | |

---

# 148. Stable RTL 定义

RTL Stable 不等于：

```text
仿真全部通过
```

本阶段 Stable 表示：

```text
设计一致性静态Review完成
Critical=0
Major=0
Blocking=0
关键问题已Verified
可进入正式仿真验证设计
```

---

# 149. Stable Version 输出原则

Review Skill 默认不主动“生成稳定版”。

稳定版应由：

```text
RTL作者整改
+
Reviewer重新验证
```

后形成。

如果用户要求由本 Skill 同时整改：

才可输出：

```text
XX模块_RTL_Stable/
```

---

# 150. Review 与仿真方案的接口

本 Skill 必须为下一阶段输出：

```text
Stable RTL Reference
Review Report
Open Issues
Needs Simulation List
Design Deviation
CDC Review
IP Review
```

---

# 151. 仿真方案重点继承内容

后续 Verification Plan 应优先继承：

```text
NEEDS-SIMULATION
WARNING
边界条件
CDC行为
Reset行为
Backpressure
FIFO
FSM异常路径
寄存器语义
Error Handling
Latency
```

---

# 152. Review Checklist：Design Compliance

```text
[ ] 模块边界与设计一致
[ ] 模块职责与设计一致
[ ] Top层级与架构一致
[ ] Parameter与设计一致
[ ] 外部接口与设计一致
[ ] 数据格式与设计一致
[ ] 数据流与设计一致
[ ] 控制流与设计一致
[ ] FSM与设计一致
[ ] FIFO与设计一致
[ ] Memory与设计一致
[ ] IP与设计一致
[ ] 寄存器与设计一致
[ ] Error Handling与设计一致
[ ] Latency一致或已记录Deviation
[ ] 所有Deviation均已记录
```

---

# 153. Review Checklist：Verilog

```text
[ ] 使用项目要求的Verilog版本
[ ] 无未允许SystemVerilog语法
[ ] 无Implicit Net
[ ] 无Multiple Driver
[ ] 无组合环
[ ] 无非预期Latch
[ ] Blocking/Non-blocking合理
[ ] case完整
[ ] 无关键Undriven
[ ] 无关键Unused
[ ] 无明显不可综合代码
[ ] 无未说明TODO/FIXME
```

---

# 154. Review Checklist：Clock/Reset

```text
[ ] Clock来源明确
[ ] Clock Domain明确
[ ] 无错误逻辑生成Clock
[ ] Clock Enable正确
[ ] Reset来源明确
[ ] Reset极性正确
[ ] Reset方式正确
[ ] Reset释放策略正确
[ ] Reset默认状态正确
[ ] RDC风险已检查
```

---

# 155. Review Checklist：CDC

```text
[ ] 所有CDC已识别
[ ] 单bit Level同步正确
[ ] Pulse跨域正确
[ ] Multi-bit跨域正确
[ ] Stream跨域正确
[ ] Async FIFO正确
[ ] 无逐bit同步后直接使用Bus
[ ] CDC Reset关系正确
[ ] 工具验证状态明确
```

---

# 156. Review Checklist：FSM

```text
[ ] Reset State正确
[ ] 正常流程完整
[ ] 异常流程完整
[ ] Abort/Timeout完整
[ ] 无明显死锁
[ ] 无永久等待Bug
[ ] 非法状态处理合理
[ ] 状态输出时序正确
```

---

# 157. Review Checklist：Width/Arithmetic

```text
[ ] 所有关键数据位宽正确
[ ] Counter位宽正确
[ ] Address位宽正确
[ ] Length位宽正确
[ ] Signed/Unsigned正确
[ ] Truncation显式
[ ] Extension正确
[ ] Overflow策略明确
[ ] Multiply宽度正确
[ ] Division风险已分析
[ ] Shift风险已分析
```

---

# 158. Review Checklist：Protocol

```text
[ ] Ready/Valid语义正确
[ ] Backpressure正确
[ ] Stall时数据保持
[ ] Packet边界正确
[ ] TLAST/SOP/EOP正确
[ ] TKEEP/Byte Enable正确
[ ] Req/Ack完整
[ ] AXI各通道独立性正确
[ ] Error/Abort协议正确
```

---

# 159. Review Checklist：FIFO/Memory

```text
[ ] FIFO类型正确
[ ] FIFO宽度正确
[ ] FIFO深度正确
[ ] Full处理正确
[ ] Empty处理正确
[ ] Overflow处理正确
[ ] Underflow处理正确
[ ] Reset处理正确
[ ] RAM端口正确
[ ] Read Latency正确
[ ] Collision行为明确
[ ] 推断结果未被虚构
```

---

# 160. Review Checklist：Pipeline

```text
[ ] Data/Valid对齐
[ ] Data/Last对齐
[ ] Data/Keep对齐
[ ] Data/User对齐
[ ] Data/Error对齐
[ ] Stall行为正确
[ ] Latency可追踪
[ ] 无Pipeline覆盖数据风险
```

---

# 161. Review Checklist：IP

```text
[ ] IP名称正确
[ ] IP用途正确
[ ] IP版本已记录
[ ] Vivado版本已考虑
[ ] XCI与清单一致
[ ] 参数与设计一致
[ ] Clock/Reset正确
[ ] Latency正确
[ ] Wrapper正确
[ ] 未虚构Black Box内部行为
```

---

# 162. Review Checklist：Register/Error

```text
[ ] Address正确
[ ] Bit Field正确
[ ] Reset Value正确
[ ] RW/RO正确
[ ] W1C正确
[ ] Sticky正确
[ ] Pulse正确
[ ] Interrupt正确
[ ] Error Detect正确
[ ] Error Record正确
[ ] Error Recover正确
[ ] Timeout正确
```

---

# 163. Review Checklist：Risk

```text
[ ] Large Mux已识别
[ ] Priority Logic已识别
[ ] Wide Compare已识别
[ ] Wide Arithmetic已识别
[ ] Division已识别
[ ] Variable Shift已识别
[ ] High Fanout已识别
[ ] Long Ready Chain已识别
[ ] 大Register Array已识别
[ ] Resource数字未虚构
[ ] Timing结果未虚构
```

---

# 164. Definition of Done

本 Review Skill 完成必须满足：

```text
[ ] 已读取设计方案
[ ] 已读取全部RTL
[ ] 已识别Top Module
[ ] 已建立Module Map
[ ] 已建立Interface Map
[ ] 已建立Clock/Reset Map
[ ] 已建立CDC/RDC清单
[ ] 已完成Design Compliance Review
[ ] 已完成Verilog Review
[ ] 已完成FSM Review
[ ] 已完成Width/Arithmetic Review
[ ] 已完成Protocol Review
[ ] 已完成FIFO/Memory Review
[ ] 已完成Pipeline/Latency Review
[ ] 已完成IP Review
[ ] 已完成Register/Error Review
[ ] 已完成Synthesis Feasibility Review
[ ] 已完成Timing/Resource Risk Review
[ ] 所有问题均有Severity
[ ] 所有问题均有Issue ID
[ ] 所有问题均有整改建议
[ ] 工具验证与静态检查已严格区分
[ ] 未虚构Compile/Lint/CDC/Synthesis结果
[ ] 已输出Needs Simulation清单
[ ] 已输出Review Gate结论
```

---

# 165. Review Gate 最终输出

最终必须给出：

```text
Review Gate:
PASS / PASS WITH MINOR ISSUES / FAIL / BLOCKED
```

并说明：

```text
Critical:
Major:
Minor:
Suggestion:
Blocking:
Needs Simulation:
Needs Tool:
```

---

# 166. 推荐最终输出结构

```text
review/
│
├── XX模块_RTL_Code_Review_Report.md
├── XX模块_RTL_Issue_List.md
├── XX模块_Needs_Simulation.md
├── XX模块_RTL_CDC_Review.md          # 按需
├── XX模块_RTL_Design_Compliance.md   # 按需
└── XX模块_RTL_Fix_Log.md             # 仅整改模式
```

---

# 167. 推荐最终回复格式

```markdown
# RTL Review Result

## 1. Review Scope

## 2. Input Files

## 3. Review Gate

## 4. Issue Summary

## 5. Critical / Major Issues

## 6. Design Compliance

## 7. Clock / Reset

## 8. CDC / RDC

## 9. FSM

## 10. Width / Arithmetic

## 11. Protocol

## 12. FIFO / Memory

## 13. Pipeline / Latency

## 14. IP

## 15. Timing / Resource Risk

## 16. Needs Simulation

## 17. Needs Tool Verification

## 18. Open Issues

## 19. Next Action
```

---

# 168. 核心 Review 原则

始终遵守：

> 设计方案是 Golden Reference，RTL 不是需求本身。

> Review 必须独立于 RTL 作者立场。

> 不因为代码能够编译就认为功能正确。

> 不因为仿真可能通过就忽略静态设计缺陷。

> 不因为常见写法就擅自替代项目正式定义。

> 不虚构 Vivado、Lint、CDC、Synthesis、Timing 结果。

> 不能静态证明的内容明确标记 NEEDS-SIMULATION。

> 需要工具证明的内容明确标记 NEEDS-TOOL。

> Critical 和 Major 默认必须关闭后才能进入正式验证阶段。

> Review 发现的 Design Deviation 必须形成可追踪记录。

> 默认只 Review，不直接修改 RTL。

> 用户明确要求整改后，修改必须 Minimize Diff，并重新 Review。

---

# 169. 最终目标

本 Skill 的目标不是：

```text
把代码挑得更漂亮
```

而是确保进入仿真验证阶段之前，RTL 已经达到：

```text
设计一致
+
接口一致
+
Clock/Reset正确
+
CDC/RDC可解释
+
FSM完整
+
位宽正确
+
协议正确
+
FIFO/Memory正确
+
Pipeline对齐
+
IP使用正确
+
可综合结构合理
+
风险透明
+
问题可追踪
```

最终形成：

```text
XX模块设计方案
      +
XX模块RTL
      ↓
Independent RTL Review
      ↓
Review Report
Issue List
Needs Simulation
      ↓
整改闭环
      ↓
RTL Stable
      ↓
进入仿真验证方案设计阶段
```
