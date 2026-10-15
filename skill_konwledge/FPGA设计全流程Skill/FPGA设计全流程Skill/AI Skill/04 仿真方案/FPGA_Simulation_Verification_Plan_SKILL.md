---
name: fpga-simulation-verification-plan
version: "0.3"
language: zh-CN
stage: "04-仿真验证方案设计阶段"
description: >-
  根据 FPGA 模块设计方案、Reviewed/Stable RTL、RTL Code Review 结果、
  Needs Simulation、IP 配置、接口协议、寄存器表及用户提供的通用 FPGA 仿真报告 Word 模板，
  采用 P0/P1/P2 三阶段验证方法生成正式仿真验证计划。
  P0 为最小主链路/Smoke，P1 为定向功能/异常/边界，P2 为随机回归，
  且固定分为 MODE=0 正常随机、MODE=1 长时间稳定、MODE=2 错误恢复随机。
  本阶段只输出一份按照指定 Word 仿真报告模板填写好的“待补充仿真结果”报告，
  不编写 Testbench，不执行仿真，不提前填写 PASS/FAIL、实际结果、波形、日志、Coverage 或 Seed。
---

# FPGA Simulation Verification Plan SKILL

# 0. Skill 目标

本 Skill 用于 FPGA 前端开发流程中的第 04 阶段：

```text
01 方案设计
   ↓
XX模块设计方案

02 RTL开发
   ↓
XX模块RTL
IP配置清单

03 RTL Review
   ↓
RTL Review Report
RTL Issue List
Needs Simulation
RTL Stable

04 仿真验证方案设计
   ↓
本 Skill
   ↓
XX模块_仿真报告_待补充结果.docx

05 TB开发与仿真执行
   ↓
按照P0/P1/P2编写TB并执行
   ↓
回填同一份Word
   ↓
XX模块_仿真报告.docx
```

本 Skill 的核心职责：

> 根据 Design + Stable RTL + RTL Review，定义“需要验证什么、怎么激励、期望是什么”，并直接填写到正式仿真报告 Word 模板中。

本 Skill 不负责：

```text
Testbench代码
Driver代码
Monitor代码
Scoreboard代码
Reference Model代码
仿真脚本
真实仿真执行
真实Coverage采集
真实Regression执行
RTL修改
综合
Implementation
Bitstream
上板
```

---

# 1. 唯一正式输出

本阶段默认只输出：

```text
XX模块_仿真报告_待补充结果.docx
```

不再默认生成：

```text
Simulation_Verification_Plan.md
Simulation_Test_Case_List.md
Verification_Traceability_Matrix.md
Coverage_Plan.md
Regression_Plan.md
Verification_Open_Issues.md
```

原因：

仿真方案、测试项、结果记录、Coverage、Regression 和问题分析统一维护在同一份正式仿真报告中。

---

# 2. 仿真报告模板是强制输入

必须使用用户提供的：

```text
通用FPGA仿真报告模板.docx
```

作为母版。

原则：

```text
复制模板
→
保持模板版式
→
替换项目/模块信息
→
根据Design和RTL填写仿真方案
→
根据Design和RTL生成P0/P1/P2测试项
→
保留实际结果区域
→
输出待补充仿真结果Word
```

不得为了方便重新创建另一套 Word 结构。

---

# 3. 模板章节结构

正式输出应保持模板总体章节结构：

```text
Revision Record 修订记录

1 引言
  1.1 编写目的
  1.2 仿真目的

2 仿真环境

3 仿真方案

4 仿真关键接口

5 仿真项目及结果
  5.1 P0 基本主链路
  5.2 P1 定向功能/异常/边界
      5.2.x 根据实际设计/RTL动态生成
  5.3 P2 随机回归
      5.3.1 正常随机
      5.3.2 长时间稳定
      5.3.3 错误恢复随机
```

模板中的：

```text
标题样式
表格样式
页面布局
目录层级
章节编号
页眉页脚
```

应尽量保留。

---

# 4. 输入资料

## 4.1 必须输入

至少：

```text
1. XX模块设计方案
2. XX模块RTL稳定版
3. 通用FPGA仿真报告模板.docx
```

---

## 4.2 强烈推荐输入

```text
RTL Code Review Report
RTL Issue List
Needs Simulation
IP配置清单
接口协议
寄存器表
数据格式说明
CDC清单
Design Deviation
历史Bug
Golden Data说明
参考模型说明
```

---

# 5. 输入资料优先级

如果资料存在冲突：

```text
用户当前明确确认
    ↓
正式设计方案
    ↓
正式接口协议 / 寄存器表
    ↓
已批准Design Deviation
    ↓
正式IP配置
    ↓
Reviewed / Stable RTL
    ↓
历史资料
```

禁止：

```text
RTL当前怎么实现
=
Expected Result就怎么写
```

原则：

> RTL 是 DUT，设计方案是 Golden Reference。

---

# 6. 缺失信息处理

如果缺失信息导致无法确定 Expected Result：

必须标记：

```text
【待设计确认】
```

必要时增加：

```text
待确认项：
影响测试项：
需要确认内容：
```

不得猜测：

```text
TLAST定义
Reset行为
寄存器语义
Error行为
Latency
Endian
Padding
FIFO边界行为
```

---

# 7. 未知执行环境处理

如果以下信息尚未确定：

```text
TB Top
仿真脚本
Vivado实际运行版本
日志目录
波形目录
Coverage数据库路径
```

写：

```text
【待第05阶段补充】
```

不要虚构。

---

# 8. 三阶段验证总体方法

验证统一采用：

```text
P0 最小主链路
      ↓
P1 定向功能 / 异常 / 边界
      ↓
P2 随机回归
   ├── MODE=0 正常随机
   ├── MODE=1 长时间稳定
   └── MODE=2 错误恢复随机
```

验证思想：

```text
P0：先证明“能跑”
P1：再证明“各功能、异常和边界正确”
P2：最后证明“随机组合和长期运行仍稳定”
```

---

# 9. P0 定义

P0 是：

```text
最小主链路
Smoke
最小可运行基线
```

目标：

```text
DUT能够完成Reset
DUT能够进入正常工作状态
至少一个典型合法事务能够完成
关键输出可观察
主要握手可工作
无明显非预期Error
```

P0 不追求全面覆盖。

---

# 10. P0 测试项生成原则

P0 应：

```text
简单
稳定
可重复
使用典型合法配置
尽量无随机
不主动注入异常
尽量保持上下游Ready
```

---

# 11. P0 默认分析维度

按 DUT 实际情况选择：

```text
复位与空闲状态
单事务基本功能
典型数据/格式
基本握手
连续合法事务
基本状态/统计
```

---

# 12. P0 推荐 Test ID

可使用：

```text
P0-BSC-001
P0-BSC-002
P0-BSC-003
...
```

模板提供的通用 P0 项可以保留、删除、修改或新增。

不得为了保持模板而保留不适用测试。

---

# 13. P0 示例

```text
P0-BSC-001 复位与空闲状态
P0-BSC-002 单事务基本功能
P0-BSC-003 典型数据/格式检查
P0-BSC-004 基本握手与时序
P0-BSC-005 连续合法事务
P0-BSC-006 基本状态与统计
```

正式项目必须将：

```text
事务
数据格式
握手
状态
```

替换成 DUT 实际定义。

---

# 14. P0 准入/退出原则

第 3 章可以写明：

```text
P0通过后才进入P1。
```

但本阶段不得写：

```text
P0 PASS
```

因为尚未执行真实仿真。

---

# 15. P1 定义

P1 是：

```text
定向功能
+
异常
+
边界
```

P1 是整个 Verification Plan 的核心阶段。

P1 必须：

> 根据当前 Design 和实际 Stable RTL 动态分析后生成，不能机械复制模板示例。

---

# 16. P1 生成前必须分析 Design

从设计方案提取：

```text
模块职责
接口
数据流
事务流程
Clock
Reset
FSM
FIFO
Buffer
Memory
Data Format
Parameter
IP
Register
Error
Recovery
Performance
```

---

# 17. P1 生成前必须分析 RTL

从 RTL 提取：

```text
Top
Module Hierarchy
Port
Parameter
localparam
generate
FSM
if/case关键分支
Counter
Pointer
FIFO
RAM
CDC
RDC
Reset
Pipeline
Latency
Backpressure
Error条件
Timeout
default保护
IP Wrapper
Register Logic
```

---

# 18. Design 与 RTL 双向覆盖

P1 必须同时做到：

```text
Design有定义
→
必须有测试

RTL有真实实现的关键状态/分支
→
必须确认是否有测试
```

---

# 19. P1 子章节动态生成

模板中的：

```text
5.2.1 [功能/仲裁/资源管理模块]
5.2.2 [数据处理/格式处理模块]
5.2.3 [核心控制/协议模块]
```

只是占位。

正式输出必须替换为：

```text
实际模块名
或
实际功能域
```

---

# 20. P1 子章节示例

例如实际 RTL：

```text
xxx_top
├── input_ctrl
├── fifo_manage
├── data_pack
├── packet_ctrl
└── reg_if
```

则 P1 可以生成：

```text
5.2.1 input_ctrl模块测试
5.2.2 fifo_manage模块测试
5.2.3 data_pack模块测试
5.2.4 packet_ctrl模块测试
5.2.5 reg_if模块测试
5.2.6 错误与恢复测试
5.2.7 系统边界测试
```

---

# 21. P1 功能测试

每个关键模块至少检查：

```text
基本功能
所有主要模式
配置变化
连续事务
模块间交互
状态变化
```

---

# 22. P1 接口测试

按实际协议考虑：

```text
Valid/Ready
Req/Ack
AXI
AXI-Lite
AXI-Stream
Custom Interface
Memory Interface
```

覆盖：

```text
正常握手
等待
Backpressure
连续握手
间断握手
Last Beat
非法组合
```

---

# 23. P1 FSM 测试

应覆盖：

```text
Reset State
主要可达状态
关键Transition
正常完成
等待
Timeout
Abort
Error
Recovery
Reset
default/保护路径
```

---

# 24. P1 Parameter 测试

对实际 Parameter：

```text
最小
典型
最大
特殊值
```

进行规划。

如果 Parameter 为编译期配置：

在报告中说明：

```text
需要独立Build Configuration
```

---

# 25. P1 Generate 分支

如果 RTL 存在：

```verilog
generate
```

必须检查不同分支是否需要分别验证。

---

# 26. P1 FIFO / Buffer / Queue

按设计存在项覆盖：

```text
Empty
Almost Empty
Normal Write
Normal Read
Simultaneous Read/Write
Almost Full
Full
Overflow保护
Underflow保护
Pointer Wrap
Reset
```

---

# 27. P1 RAM / Memory

按实际设计考虑：

```text
最低地址
最高地址
边界地址
对齐
非对齐
读Latency
写模式
读写冲突
回绕
越界
```

---

# 28. P1 Pointer / Counter

重点：

```text
0
1
N-1
N
MAX-1
MAX
Wrap
Off-by-One
```

---

# 29. P1 数据格式

验证：

```text
Bit Field
Byte Mapping
Lane Mapping
Endian
Header
Payload
Metadata
SOP
EOP
TLAST
TKEEP
Padding
```

---

# 30. P1 位宽转换

例如：

```text
32 → 128
128 → 32
```

至少分析：

```text
完整聚合
最后不完整Beat
连续Packet
Backpressure
TLAST位置
Padding/Keep
```

---

# 31. P1 Arithmetic

如 DUT 有算术：

```text
0
1
MIN
MAX
正数
负数
Overflow
Underflow
Truncate
Round
Saturate
Signed
Unsigned
```

---

# 32. P1 Pipeline / Latency

检查：

```text
Data
Valid
Last
Keep
ID
User
Error
Metadata
```

是否对齐。

如果设计规定精确 Latency：

建立定向 Latency Test。

---

# 33. P1 Backpressure

按适用项：

```text
单拍Backpressure
连续多拍Backpressure
Last Beat Backpressure
随机位置Backpressure
资源接近满时Backpressure
解除后的恢复
```

---

# 34. P1 Reset

覆盖设计允许的：

```text
Power-on Reset
Idle Reset
运行中Reset
FSM关键状态Reset
FIFO非空Reset
Error状态Reset
Reset后下一事务
```

---

# 35. P1 CDC / RDC

仿真可验证：

```text
Clock Ratio下的逻辑行为
Pulse传递
Handshake
Async FIFO
跨域顺序
Reset交互
```

仿真不能证明：

```text
真实Metastability
MTBF
物理CDC布局
```

报告中不得写：

```text
CDC物理安全已由仿真证明
```

---

# 36. P1 Error

必须先从 Design + RTL 枚举真实 Error Set。

例如：

```text
配置错误
长度错误
地址错误
协议错误
Timeout
资源错误
FIFO错误
Tag/ID错误
状态错误
外部响应错误
```

---

# 37. P1 Error Test

每种 Error 至少分析：

```text
Trigger
Detect
Record
Report
Cleanup
Recover
```

---

# 38. P1 不得臆造 Error

Design 未定义的异常：

不得自行写 Expected Result。

处理：

```text
不测试
或
【待设计确认】
```

---

# 39. P1 Recovery

不能只测试：

```text
Error能否检测
```

还应测试：

```text
错误后能否恢复
恢复后下一正常事务能否正确执行
```

---

# 40. P1 Register

如果有寄存器：

按适用项规划：

```text
Reset Value
RW
RO
W1C
Sticky
Pulse
Mask
Interrupt
Invalid Address
Reserved Bit
```

---

# 41. P1 W1C

至少覆盖：

```text
写0不清
写1清除
Hardware Set
Software Clear
同时发生
```

---

# 42. P1 Interrupt

按实际设计覆盖：

```text
Source
Enable
Mask
Status
Clear
Level/Pulse
多源同时发生
```

---

# 43. P1 系统边界 / E2E

从系统组合角度覆盖：

```text
最小事务
最大事务
连续事务
最大并发
多通道交错
资源共享
地址边界
长度边界
跨模块Backpressure
跨模块Error传播
跨模块Reset
外部IP交互
```

---

# 44. P1 Test ID

模块测试推荐：

```text
P1-[MOD]-001
P1-[MOD]-002
```

错误测试：

```text
P1-ERR-001
```

系统边界：

```text
P1-E2E-001
```

---

# 45. P1 测试项数量

不设固定数量。

由：

```text
模块数量
功能复杂度
FSM状态
接口数量
Parameter
边界
Error数量
Review风险
```

决定。

---

# 46. RTL Review → P1 映射

RTL Review 输出中的：

```text
NEEDS-SIMULATION
```

必须逐项消化。

通常优先映射为：

```text
P1 Directed Test
```

---

# 47. Review Warning → Test

如果 Review Warning 与功能相关：

建立针对性 Test。

例如：

```text
Review：
长Backpressure存在数据覆盖风险

↓

P1：
长Backpressure下数据保持与恢复测试
```

---

# 48. P2 定义

P2 是：

```text
随机回归
```

固定分成：

```text
MODE=0 正常随机
MODE=1 长时间稳定
MODE=2 错误恢复随机
```

---

# 49. P2 前提

执行原则：

```text
P0通过
+
P1关键测试通过
↓
进入P2
```

本阶段只写执行原则。

不得声称已经满足。

---

# 50. P2 可复现原则

所有 P2 运行必须可复现。

实际执行阶段需要记录：

```text
MODE
Seed
RTL Version
Design Version
配置
运行命令
运行轮次
运行时长
事务数量
Checker版本
Error配置
Log
Wave
Coverage
```

本阶段只预留字段。

---

# 51. MODE=0 正常随机

目标：

> 在全部合法工作空间内随机组合事务、数据、时序、流控和资源状态，发现 Directed Test 未覆盖的组合问题。

---

# 52. MODE=0 随机维度

根据实际 DUT 选择：

```text
Transaction Type
Data
Length
Count
Channel
Address
Config
Valid Gap
Ready
Response Delay
FIFO Occupancy
Resource State
Legal Boundary
```

---

# 53. MODE=0 禁止主动注入 Error

MODE=0 必须保持：

```text
合法输入空间
```

如果合法输入导致 Error：

应视为潜在 Bug。

---

# 54. MODE=0 推荐测试

按实际 DUT 调整：

```text
P2-M0-001 随机合法事务基础回归
P2-M0-002 随机竞争/多通道组合
P2-M0-003 随机断流与反压
P2-M0-004 随机资源压力
P2-M0-005 随机配置与边界组合
```

---

# 55. MODE=1 长时间稳定

目标：

> 验证 DUT 在长序列、持续压力和多次边界回绕后仍无死锁、状态漂移、资源泄漏、计数/指针累计误差。

---

# 56. MODE=1 重点随机内容

```text
持续合法事务
随机流控
高负载
高资源占用
多次FIFO回绕
多次Pointer回绕
Counter长时间累计
多Seed
```

---

# 57. MODE=1 推荐测试

```text
P2-M1-001 长时间合法持续运行
P2-M1-002 长序列资源/指针/计数稳定性
P2-M1-003 持续随机流控稳定性
P2-M1-004 高占用/高吞吐稳定性
P2-M1-005 多Seed长时间重复性
```

---

# 58. MODE=1 时长/事务数

若项目未给出：

不要擅自固定：

```text
10小时
100万事务
```

填写：

```text
【待第05阶段根据仿真性能和项目要求确定】
```

---

# 59. MODE=2 错误恢复随机

目标：

> 在随机正常业务中随机注入设计已经定义的错误，验证 Error Detect、失败事务处理、资源清理和后续持续恢复。

---

# 60. MODE=2 Error Set

只能来自：

```text
Design已定义
且
能够判定Expected Result
```

的 Error。

---

# 61. MODE=2 随机维度

可以随机：

```text
Error Type
Injection Point
Injection Time
Related Transaction
Error Gap
Traffic
Backpressure
Resource Occupancy
```

---

# 62. MODE=2 恢复检查

错误后继续发合法事务。

检查：

```text
错误事务未误提交
错误状态正确
错误计数正确
缓存清理正确
资源释放正确
上下文清理正确
后续事务恢复正常
```

---

# 63. MODE=2 推荐测试

```text
P2-M2-001 随机错误类型/注入点
P2-M2-002 错误后随机恢复
P2-M2-003 连续/间歇错误恢复
P2-M2-004 错误与流控/资源压力组合
P2-M2-005 错误统计与长期恢复一致性
```

---

# 64. Test Case 表格固定格式

正式 Word 报告第 5 章中，测试项优先使用模板格式：

| 用例 ID | 测试项 | 激励/条件 | 期望结果 | 结果 |
|---|---|---|---|---|

本 Skill 填写：

```text
用例ID
测试项
激励/条件
期望结果
```

不填写：

```text
结果
```

---

# 65. Test Case 激励要求

“激励/条件”必须尽量明确：

```text
Precondition
配置
输入
时序
Clock
Reset
Backpressure
Error Injection
边界值
```

禁止只写：

```text
测试FIFO
测试异常
测试接口
```

---

# 66. Expected Result 要求

Expected Result 必须：

```text
可判定
可自动检查
有明确状态/数据/行为
```

---

# 67. Expected Result 示例

好：

```text
ready=0期间valid/data/last保持不变；
ready恢复后该Beat仅传输一次；
后续数据顺序与输入一致。
```

不好：

```text
接口正常。
```

---

# 68. Checker 导向

虽然本阶段不编写 TB，

但 Expected Result 应能指导后续：

```text
Checker
Scoreboard
Reference Model
Counter
Protocol Check
```

实现。

---

# 69. 结果列硬性规则

所有：

```text
结果
```

字段保持：

```text
【仿真后填写】
```

禁止填：

```text
PASS
FAIL
通过
失败
预计通过
正常
```

---

# 70. 阶段结果总结硬性规则

以下区域均保留：

```text
P0仿真结果总结
各P1模块仿真结果总结
MODE=0仿真结果总结
MODE=1仿真结果总结
MODE=2仿真结果总结
P2总体仿真结果总结
```

内容保持：

```text
【仿真执行后填写】
```

---

# 71. 波形 / 日志区域

模板中的：

```text
波形
日志
覆盖率证据
截图区域
```

必须保留。

当前阶段写：

```text
【仿真执行后填写】
```

---

# 72. Coverage 处理

本阶段不单独输出 Coverage Plan。

在报告中只定义：

```text
需要关注哪些Coverage
```

例如：

```text
FSM State
FSM Transition
关键Branch
Error类型
边界值
P2模式
关键功能场景
```

---

# 73. Coverage 数字

没有真实仿真：

禁止填写：

```text
Statement Coverage
Branch Coverage
FSM Coverage
Toggle Coverage
```

实际百分比。

---

# 74. Regression 处理

本阶段不单独输出 Regression Plan。

在第 3 章和 P2 中说明：

```text
P0 Smoke
P1 Directed
P2 Random
Bug Fix Regression
```

即可。

---

# 75. Traceability 处理

本阶段不单独输出 Traceability Matrix。

追踪关系通过：

```text
章节
模块
Test ID
测试项
激励
Expected Result
```

体现。

必要时可在 Test 描述中加入：

```text
设计章节/Review Issue ID
```

---

# 76. Open Issue 处理

不单独输出 Open Issue 文件。

设计不明确时：

```text
【待设计确认】
```

Review遗留时：

可在对应测试项或结果分析区域引用：

```text
RTL-REV-xxx
```

---

# 77. 章节 1：引言填写规则

填写：

```text
项目名称
模块名称
仿真目的
验证范围
P0/P1/P2方法
```

不列具体 Test Case。

---

# 78. 章节 2：仿真环境填写规则

已知则填写：

```text
项目/模块
RTL基线
设计方案版本
仿真工具
FPGA器件
Clock
Reset
IP
```

尚未有 TB：

```text
【待第05阶段TB开发后补充】
```

---

# 79. 仿真工具版本

如果输入资料明确：

填写真实值。

否则：

```text
【待确认】
```

---

# 80. RTL Baseline

如果 Stable RTL 已正式冻结：

填写版本。

否则：

```text
【待RTL冻结后补充】
```

---

# 81. 章节 3：仿真方案

必须明确：

```text
P0
P1
P2
```

三阶段策略。

推荐描述：

```text
分层验证
定向优先
随机回归收敛
```

---

# 82. 第 3 章 TB 能力需求

只描述：

```text
Driver
Monitor
Reference Model
Scoreboard
Protocol Checker
Memory Model
Register Model
Error Injection
Logging
Coverage
```

所需能力。

不写具体 TB 代码。

---

# 83. 章节 4：仿真关键接口

必须从真实 Design / RTL 提取。

按实际 DUT 分类：

```text
Clock / Reset
Config / Control
Input Data
Output Data
Memory / Bus
Status / IRQ / Statistics
Debug
```

---

# 84. 第 4 章禁止占位不替换

正式输出不能保留：

```text
clk_x
cfg_*
data
[模块名]
```

这种无意义通用占位。

如果确实未知：

```text
【待确认】
```

---

# 85. 第 5 章唯一承载具体测试项

所有具体：

```text
P0 Test
P1 Test
P2 Test
```

只放第 5 章。

前面章节不重复列测试清单。

---

# 86. P1 模板占位处理

正式 Word 不得保留：

```text
[功能/仲裁/资源管理模块]
[数据处理/格式处理模块]
[核心控制/协议模块]
```

必须替换成当前 DUT 实际模块/功能。

---

# 87. P1 章节增删

允许：

```text
复制
删除
新增
重命名
```

以匹配真实 RTL 层级。

---

# 88. P2 固定结构

必须保留：

```text
5.3.1 正常随机
5.3.2 长时间稳定
5.3.3 错误恢复随机
```

---

# 89. P2 MODE 固定定义

统一：

```text
MODE=0 正常随机
MODE=1 长时间稳定
MODE=2 错误恢复随机
```

如果第 05 阶段 TB 最终使用其他变量名：

可以后续更新参数名，

但三种验证语义保持不变。

---

# 90. Revision Record

初版建议填写：

```text
Version:
V0.1

Change:
完成P0/P1/P2仿真方案及测试项设计，仿真结果待执行后补充。
```

不得虚构：

```text
审核人
批准人
实际发布日期
```

---

# 91. 文件命名

默认：

```text
XX模块_仿真报告_待补充结果.docx
```

执行完成后：

```text
XX模块_仿真报告.docx
```

---

# 92. Word 编辑原则

必须：

```text
基于模板副本编辑
```

而不是从零重新创建。

---

# 93. Word 排版检查

输出前必须检查：

```text
页面结构
标题层级
表格边界
文字换行
页眉页脚
目录
表格分页
截图占位
章节编号
```

不得出现：

```text
文字重叠
表格截断
标题编号错乱
测试项跨表异常
```

---

# 94. 自动目录

如可可靠刷新：

更新目录。

如无法刷新：

至少确保：

```text
Heading层级
章节编号
```

正确，便于 Word 后续更新目录。

---

# 95. 第 04 阶段禁止填写真实结果

这是硬性规则。

禁止生成：

```text
PASS
FAIL
实际输出数据
真实波形
真实日志
真实Coverage
真实Seed
真实运行时长
真实事务数
真实Bug结论
真实Regression结论
```

除非用户明确提供了这些真实结果并要求回填。

---

# 96. 状态占位统一

三种状态统一：

## 尚未执行

```text
【仿真后填写】
```

## 第05阶段才能确定

```text
【待第05阶段补充】
```

## Design本身不清楚

```text
【待设计确认】
```

不得混用。

---

# 97. 第05阶段接口

第 05 阶段输入：

```text
XX模块_仿真报告_待补充结果.docx
+
Stable RTL
+
FPGA_Verilog_TB_Development_SKILL.md
```

第 05 阶段负责：

```text
编写TB
执行P0
执行P1
执行P2
回填Result
插入Wave
记录Log
记录Seed
记录Coverage
记录Bug
记录Regression
```

---

# 98. 同一份报告持续维护

原则：

```text
第04阶段生成计划版
↓
第05阶段直接回填
↓
最终形成正式仿真报告
```

不要另外创建：

```text
Test Plan
Test Result
Regression Report
```

多份重复文档。

---

# 99. Bug 闭环在报告中的位置

结果分析区域应能记录：

```text
问题现象
Bug ID
RTL修复版本
重测结果
Regression结论
```

当前阶段只保留位置。

---

# 100. 自动判定原则

重要 Test Case 必须尽量能在第 05 阶段实现：

```text
Automatic PASS/FAIL
```

优先依靠：

```text
Checker
Scoreboard
Reference Model
Protocol Check
Counter
```

---

# 101. 波形的定位

波形主要用于：

```text
Debug
证据
Review
```

不应成为：

```text
唯一Pass Criteria
```

---

# 102. P0/P1/P2 生成工作流程

## Step 1

读取所有输入：

```text
Design
Stable RTL
RTL Review
Needs Simulation
IP
Protocol
Register
Word Template
```

---

## Step 2

提取 DUT Baseline：

```text
Function
Module Hierarchy
Interface
Clock
Reset
FSM
FIFO
Memory
Parameter
Register
Error
IP
Latency
Performance
```

---

## Step 3

生成 P0：

确定：

```text
最小可运行主链路
```

并形成必要 Smoke Test。

---

## Step 4

生成 P1：

逐：

```text
模块
功能
接口
状态
分支
参数
边界
异常
恢复
```

分析。

---

## Step 5

检查 RTL Review：

所有：

```text
Needs Simulation
```

必须映射。

---

## Step 6

生成 P2：

确定当前 DUT 可随机化的：

```text
正常业务空间
长期压力空间
Error Set
```

---

## Step 7

复制 Word 模板。

---

## Step 8

填写：

```text
Revision
引言
环境
仿真方案
关键接口
P0
P1
P2
```

---

## Step 9

所有结果字段保持待补充。

---

## Step 10

删除模板无意义占位。

---

## Step 11

检查 P1 是否真正来自：

```text
当前 Design + 当前 RTL
```

不能只套模板。

---

## Step 12

检查 Word 排版。

---

## Step 13

唯一输出：

```text
XX模块_仿真报告_待补充结果.docx
```

---

# 103. P0 Checklist

```text
[ ] Reset
[ ] Idle State
[ ] 单事务
[ ] 典型数据
[ ] 基本握手
[ ] 连续事务按需
[ ] 基本状态/统计按需
[ ] Expected Result明确
```

---

# 104. P1 Checklist

```text
[ ] 每个关键模块
[ ] 每个核心功能
[ ] 每个关键接口
[ ] 每个FSM关键状态
[ ] 每个主要Transition
[ ] Parameter边界
[ ] Generate分支
[ ] FIFO/Buffer边界
[ ] Memory边界
[ ] Counter/Pointer边界
[ ] Data Format
[ ] Signed/Width/Arithmetic
[ ] Pipeline/Latency
[ ] Backpressure
[ ] Reset
[ ] CDC/RDC逻辑行为
[ ] 每类Error
[ ] 每类Recovery
[ ] Register
[ ] E2E系统边界
[ ] Needs Simulation无遗漏
```

---

# 105. P2 Checklist

```text
[ ] MODE=0已规划
[ ] MODE=1已规划
[ ] MODE=2已规划
[ ] MODE=0只在合法空间随机
[ ] MODE=1包含长期/高压力
[ ] MODE=2只注入Design定义Error
[ ] Seed字段已预留
[ ] 运行时长字段已预留
[ ] 事务数字段已预留
[ ] Log/Wave/Coverage字段已预留
```

---

# 106. Test Case Checklist

```text
[ ] 每个Test有唯一ID
[ ] 每个Test名称明确
[ ] 激励/条件可执行
[ ] Expected Result可判定
[ ] Expected来自Design
[ ] Result保持【仿真后填写】
```

---

# 107. Word Checklist

```text
[ ] 使用指定模板
[ ] 保持主要章节
[ ] P1按实际结构调整
[ ] P2固定三模式
[ ] 模块名已替换
[ ] 无无意义占位
[ ] 未知项正确标注
[ ] 表格完整
[ ] 结果区保留
[ ] 波形区保留
[ ] 日志区保留
[ ] Coverage区保留
[ ] 结果分析区保留
[ ] 无提前PASS/FAIL
```

---

# 108. Definition of Done

本 Skill 完成必须满足：

```text
[ ] 已读取Design
[ ] 已读取Stable RTL
[ ] 已读取RTL Review
[ ] 已读取Needs Simulation
[ ] 已读取Word模板

[ ] 已形成P0最小主链路测试
[ ] 已形成P1定向功能测试
[ ] 已形成P1异常测试
[ ] 已形成P1边界测试
[ ] 已形成P2 MODE=0
[ ] 已形成P2 MODE=1
[ ] 已形成P2 MODE=2

[ ] P1依据Design+RTL动态生成
[ ] Review风险已映射
[ ] 每个Test有激励
[ ] 每个Test有Expected
[ ] Expected可自动判定

[ ] 所有实际Result未填写
[ ] 所有Wave/Log未填写
[ ] 所有Coverage数字未填写
[ ] 所有Seed未填写
[ ] 未编写TB
[ ] 未执行仿真

[ ] 已基于指定Word模板生成
[ ] Word排版已检查
[ ] 最终仅输出一个Word文件
```

---

# 109. 最终输出格式

本 Skill 执行完成后只需返回：

```text
已生成：

XX模块_仿真报告_待补充结果.docx

报告已完成：
- 仿真目标
- 仿真环境规划
- P0最小主链路
- P1定向功能/异常/边界
- P2正常随机/长时间稳定/错误恢复随机
- 各测试项激励/条件
- 各测试项期望结果

以下内容保留至第05阶段真实仿真后填写：
- Result
- PASS/FAIL
- 实际行为
- Wave
- Log
- Coverage
- Seed
- 运行时长/事务数
- Bug
- Regression结论
```

---

# 110. 核心原则

> P0 证明最小主链路能工作。

> P1 证明功能、状态、异常和边界正确。

> P2 证明随机组合、长时间运行和错误恢复稳定。

> P1 不能照抄模板，必须依据实际 Design + RTL 生成。

> P2 固定采用 MODE=0 正常随机、MODE=1 长时间稳定、MODE=2 错误恢复随机。

> RTL 是 DUT，Design 是 Expected Result 的依据。

> Review 中 Needs Simulation 必须落实到测试项。

> 不确定需求不能猜。

> 第04阶段不写TB。

> 第04阶段不跑仿真。

> 第04阶段不填写任何真实结果。

> 所有真实结果必须来自第05阶段实际执行。

> 第04阶段只输出一份按指定模板生成的 Word 仿真报告。

> 同一份 Word 在第05阶段继续回填，最终成为正式仿真报告。

---

# 111. 最终目标

将：

```text
XX模块设计方案
+
RTL Stable
+
RTL Review
+
Needs Simulation
+
通用FPGA仿真报告模板
```

转换为：

```text
XX模块_仿真报告_待补充结果.docx
```

该 Word 在第04阶段已经完成：

```text
仿真目标
仿真环境规划
关键接口
P0测试设计
P1测试设计
P2随机回归设计
Test ID
测试项
激励/条件
Expected Result
```

并保留：

```text
Result
Wave
Log
Coverage
Seed
Bug
Regression
Final Conclusion
```

供第05阶段实际仿真后回填。
