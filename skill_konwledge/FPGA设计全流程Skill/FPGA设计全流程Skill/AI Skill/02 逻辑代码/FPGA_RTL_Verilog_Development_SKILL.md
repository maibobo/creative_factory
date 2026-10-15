---
name: fpga-rtl-verilog-development
description: >
  通用 FPGA RTL 逻辑代码开发 Skill。根据 FPGA 详细设计方案、接口定义、时钟复位、
  数据格式、状态机、FIFO/Buffer、寄存器表、官方 IP 配置、已有 RTL、约束文件和项目模板，
  使用 Verilog-2001 编写结构清晰、可综合、可仿真、可维护、便于 Review 的 FPGA RTL。
  默认面向 AMD/Xilinx FPGA 与 Vivado 工具链，同时保留通用 FPGA RTL 设计原则。
version: 0.1
language: zh-CN
rtl_language: Verilog-2001
---

# FPGA RTL Verilog 逻辑代码开发 SKILL

## 0. Skill 定位

本 Skill 用于将已经确认的 FPGA 设计方案转换为可综合的 Verilog RTL 代码。

本 Skill 的职责是：

- 读取 FPGA 设计方案；
- 读取接口定义；
- 读取时钟与复位定义；
- 读取数据格式；
- 读取 FSM 设计；
- 读取 FIFO / Buffer 设计；
- 读取寄存器定义；
- 读取已有 RTL；
- 读取官方 IP / 自研 IP / 第三方 IP；
- 读取 XCI / XDC / TCL 等工程附件；
- 读取已有 RTL 模板与目录规范；
- 根据设计方案进行 Verilog RTL 实现；
- 对 RTL 做结构、位宽、时钟、复位、CDC、FIFO、FSM、流水线等自检；
- 输出模块化、可综合、可仿真、可维护的 Verilog RTL；
- 输出 RTL 与设计方案之间的差异、假设、风险和 TBD。

本 Skill **不负责重新定义系统需求或擅自改变设计架构**。

若设计方案存在明显矛盾、缺失或不可实现问题，应先记录：

- DESIGN ISSUE
- ASSUMPTION
- TBD
- BLOCKING ISSUE

不得通过擅自修改接口、时序、数据格式、状态机或协议行为来绕过问题。

---

# 1. 与 FPGA 设计方案 Skill 的关系

推荐开发链如下：

```text
原始需求
   ↓
FPGA设计方案开发 Skill
   ↓
FPGA详细设计方案
   ↓
FPGA RTL Verilog开发 Skill
   ↓
Verilog RTL
   ↓
Compile / Lint / CDC / Review
   ↓
仿真验证
   ↓
RTL问题闭环
   ↓
设计方案反标
```

设计方案解决：

```text
做什么
+
怎么设计
```

RTL 开发解决：

```text
如何按照设计方案正确实现
```

原则：

> 设计方案决定 RTL 行为，RTL 不得反向擅自改变需求。

---

# 2. 适用范围

适用于：

- DMA；
- AXI / AXI-Lite / AXI-Stream；
- 数据采集；
- 数据发送；
- 数据缓存；
- 数据重排；
- 位宽转换；
- 协议转换；
- 控制状态机；
- 寄存器接口；
- SPI；
- I2C；
- UART；
- GPIO；
- 自定义流接口；
- DDR 前后级控制；
- PCIe 数据通路外围逻辑；
- Aurora / Ethernet 外围控制；
- ADC / DAC 数据处理；
- 算法前后处理；
- 数据打包；
- 数据解包；
- CRC / Checksum；
- 多通道数据处理；
- 跨时钟域数据传输；
- FPGA 内部通用 IP / 模块。

---

# 3. 默认技术基线

除非项目明确指定其他要求，默认采用：

```text
RTL语言：
Verilog-2001

文件扩展名：
.v

目标工具：
AMD/Xilinx Vivado

目标器件：
由设计方案指定

代码目标：
可综合
可仿真
可维护
可Review
```

默认不使用 SystemVerilog 专用语法，包括但不限于：

```text
logic
always_ff
always_comb
always_latch
interface
modport
typedef enum
package
struct
union
class
assert property
```

如项目明确允许 SystemVerilog，应使用其他对应 Skill，不应在本 Skill 中混用。

---

# 4. 输入资料

## 4.1 必须优先读取

如果存在以下资料，必须优先读取：

1. FPGA 详细设计方案；
2. FPGA 型号；
3. Vivado 版本；
4. RTL 语言规范；
5. 模块接口定义；
6. Clock 定义；
7. Reset 定义；
8. 数据格式；
9. FSM 定义；
10. FIFO / Buffer 定义；
11. 性能指标；
12. 已有 RTL。

## 4.2 推荐输入附件

用户可上传：

```text
*.md
*.docx
*.pdf
*.v
*.vh
*.xci
*.xdc
*.sdc
*.tcl
*.csv
*.xlsx
*.txt
```

典型资料：

- 设计方案；
- 接口协议；
- 芯片手册；
- 寄存器表；
- 数据格式；
- RTL；
- Xilinx 官方 IP 配置；
- 自研 IP；
- 第三方 IP；
- XDC；
- Vivado 工程脚本；
- 历史版本；
- RTL 模板；
- 公司编码规范。

---

# 5. 输入资料优先级

如果不同资料之间存在冲突，原则上按照以下优先级处理：

```text
用户当前明确指令
    ↓
正式设计方案
    ↓
正式接口协议 / 寄存器表
    ↓
已确认 RTL 接口
    ↓
官方 IP 配置
    ↓
已有代码实现
    ↓
历史设计资料
    ↓
经验推断
```

如果冲突会影响功能行为，不允许自动选择其中一个而不说明。

必须输出：

```text
CONFLICT:
资料A：
资料B：

影响：
建议：
当前处理：
```

---

# 6. RTL 开发前必须确认的信息

## 6.1 模块功能

必须能够回答：

- 模块负责什么？
- 模块不负责什么？
- 启动条件是什么？
- 运行条件是什么？
- 完成条件是什么？
- 失败条件是什么？
- 是否允许暂停？
- 是否允许并发？
- 是否允许重新启动？

## 6.2 接口

至少确认：

- 信号名称；
- 方向；
- 位宽；
- 有效电平；
- 所属 Clock；
- Reset 行为；
- 握手机制；
- 数据有效条件；
- 帧边界；
- 错误条件。

## 6.3 Clock

必须确认：

- Clock 名称；
- Clock 来源；
- Clock 频率；
- Clock Domain；
- Clock 之间关系；
- 是否同步；
- 是否异步；
- 是否由 MMCM / PLL / Clocking Wizard 产生。

## 6.4 Reset

必须确认：

- Reset 名称；
- Reset 来源；
- Reset 极性，RTL复位信号默认采用高电平有效；
- 同步或异步；
- Reset 作用范围；
- Reset 释放策略；
- 是否有软复位；
- 是否存在局部 Reset。

## 6.5 性能

至少确认：

- 目标频率；
- 吞吐；
- 延迟；
- Burst；
- 最大数据规模；
- 最大并发；
- 是否允许气泡；
- 最大 Backpressure；
- FIFO 最大积压。

---

# 7. 缺失信息处理规则

不得为了完成代码而擅自猜测关键需求。

## 7.1 Blocking

缺失后无法确定正确 RTL 行为。

例如：

```text
接口位宽未知
Reset极性未知
TLAST定义未知
寄存器bit定义未知
Packet长度定义未知
Clock关系未知
```

处理：

```text
BLOCKING ISSUE
```

若任务要求必须继续，则只能：

- 建立显式假设；
- 在代码中标记；
- 在输出报告中列出；
- 不得将假设描述成已确认事实。

## 7.2 Non-Blocking

不会改变架构，仅影响代码细节。

例如：

```text
作者名
文件头日期
内部局部信号命名
```

可以采用项目默认值。

---

# 8. 设计方案一致性原则

RTL 必须与设计方案保持以下一致：

```text
模块边界
模块接口
Clock
Reset
数据宽度
数据格式
FIFO深度
状态机
异常处理
吞吐
Latency
寄存器
官方IP
跨时钟方案
```

如果实际实现需要调整，应记录：

```text
DESIGN DEVIATION
```

格式：

```text
设计项：
原设计：
RTL实际实现：
修改原因：
影响范围：
是否需要反标设计文档：
```

---

# 9. RTL 总体编码原则

所有 RTL 应满足：

```text
结构清晰
职责单一
显式设计
可综合
可验证
可维护
可移植
时序可控
资源可控
接口稳定
```

禁止依赖：

- 未定义行为；
- 仿真器特殊行为；
- 隐式位宽；
- 隐式有符号转换；
- 未声明 Net；
- 组合反馈；
- 多驱动；
- 错误的 CDC；
- 不可综合语句。

---

# 10. 推荐文件组织

```text
rtl/
│
├── top/
│   └── xxx_top.v
├── ctrl/
│   ├── xxx_ctrl.v
│   └── xxx_fsm.v
├── datapath/
│   ├── xxx_datapath.v
│   └── xxx_pipeline.v
├── interface/
│   ├── xxx_input_if.v
│   └── xxx_output_if.v
├── fifo/
│   └── xxx_fifo_wrapper.v
├── memory/
│   └── xxx_ram_wrapper.v
├── cdc/
│   └── xxx_cdc.v
├── common/
│   └── xxx_common.v
├── ip/
│   └── xxx_ip_wrapper.v
└── include/
    ├── xxx_define.vh
    └── xxx_parameter.vh
```

目录根据项目规模调整。小模块不需要为了形式过度拆分。

---

# 11. 模块划分原则

每个模块尽量只承担一个主要职责。

例如：

```text
dma_top
├── dma_reg
├── dma_ctrl
├── dma_reader
├── dma_writer
├── dma_fifo
├── dma_irq
└── dma_cdc
```

不推荐把寄存器、AXI、FIFO、CDC、FSM、中断、CRC、统计等全部堆在单个 top 模块中。

---

# 12. 顶层模块原则

Top 模块优先承担：

- 子模块例化；
- 接口连接；
- Clock / Reset 分发；
- 参数连接；
- IP Wrapper 连接。

Top 中避免大量复杂组合逻辑、大型 FSM、数据运算和多层嵌套控制。

---

# 13. Module 模板

```verilog
`timescale 1ns/1ps

module module_name #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,

    input  wire [DATA_WIDTH-1:0] data_i,
    input  wire                  valid_i,

    output wire [DATA_WIDTH-1:0] data_o,
    output wire                  valid_o
);

// ============================================================
// Local Parameters
// ============================================================

// ============================================================
// Internal Signals
// ============================================================

// ============================================================
// Combinational Logic
// ============================================================

// ============================================================
// Sequential Logic
// ============================================================

// ============================================================
// Submodule Instances
// ============================================================

endmodule
```

---

# 14. Module Header 规范

```verilog
// ============================================================================
// Module Name :
// File Name   :
// Description :
//
// Clock       :
// Reset       :
//
// Inputs      :
// Outputs     :
//
// FPGA        :
// Tool        :
// Version     :
//
// Change Log:
//   V0.1:
// ============================================================================
```

注释应说明设计意图，不应大量重复代码本身。

---

# 15. 命名规范

若项目已有命名规范，优先使用项目规范。

无项目规范时推荐：

```text
Clock:    clk / clk_sys / clk_axi / clk_data
Reset:    rst_n / rst_sys_n / rst_axi_n
Input:    xxx
Output:   xxx
Register: reg_xxx
Next:     xxx_next
Counter:  xxx_cnt
Enable:   xxx_en
Valid:    xxx_valid
Ready:    xxx_ready
State:    S_IDLE / S_CFG / S_RUN / S_DONE / S_ERR
```

---

# 16. 隐式 Net 禁止规则

推荐在所有 RTL 文件顶部使用：

```verilog
`default_nettype none
```

文件末尾根据项目规范恢复：

```verilog
`default_nettype wire
```

目的：防止信号名称拼写错误后被 Verilog 自动创建为隐式 wire。

如项目现有代码不允许使用该指令，应遵循项目规范。

---

# 17. 时序逻辑规范

时序逻辑使用：

```verilog
always @(posedge clk)
```

或带异步复位：

```verilog
always @(posedge clk or negedge rst)
```

时序逻辑统一使用：

```verilog
<=
```

禁止在时序逻辑中使用 Blocking Assignment 作为寄存器赋值方式。

---

# 18. 组合逻辑规范

组合逻辑使用：

```verilog
always @(*)
```

组合逻辑使用：

```verilog
=
```

必须确保所有输出在所有路径都有明确赋值。

示例：

```verilog
always @(*)
begin
    next_state = state;
    data_next  = data_reg;

    case (state)
        ST_IDLE:
        begin
            if (start_i)
                next_state = ST_RUN;
        end

        ST_RUN:
        begin
            if (done_i)
                next_state = ST_DONE;
        end

        ST_DONE:
        begin
            next_state = ST_IDLE;
        end

        default:
        begin
            next_state = ST_IDLE;
        end
    endcase
end
```

---

# 19. Latch 禁止规则

除非设计明确需要 Latch，否则禁止推断 Latch。

重点检查：

- if 无 else；
- case 不完整；
- output 未默认赋值；
- next value 未默认赋值；
- combinational process 存在保持路径。

目标：

```text
0 unintended latch
```

---

# 20. Blocking / Non-Blocking 规则

统一：

```text
组合逻辑：=
时序逻辑：<=
```

不要在同一个寄存器上混合 `=` 和 `<=`。

---

# 21. Reset 设计规范

Reset 必须与设计方案一致。

必须明确：

```text
Reset极性
Reset类型
Reset作用域
Reset释放方式
```

常见异步低有效 Reset：

```verilog
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
        state_reg <= ST_IDLE;
    else
        state_reg <= state_next;
end
```

---

# 22. Reset 使用原则

不要无条件 Reset 所有寄存器。

优先 Reset：

- FSM 状态；
- Control Flag；
- Valid；
- Ready 状态寄存器；
- Error；
- Interrupt；
- 指针；
- 关键 Counter；
- 对外可观察状态。

对于纯数据 Pipeline，如果功能允许，不一定需要 Reset。

原因包括：

```text
减少Reset Fanout
减轻Routing压力
改善Timing
利于SRL推断
利于RAM推断
```

是否 Reset 由功能决定，而不是形式决定。

---

# 23. Reset 释放规则

对于异步 Reset，推荐：

```text
Async Assert
Sync Deassert
```

不得让异步 Reset 在不同寄存器之间无控制释放导致状态不一致。

---

# 24. Clock 设计规范

普通业务 RTL 禁止通过组合逻辑直接生成 Clock。

错误：

```verilog
assign clk_new = clk & enable;
```

如果目标只是降低逻辑更新频率，优先使用 Clock Enable：

```verilog
always @(posedge clk)
begin
    if (clk_en)
        data_reg <= data_i;
end
```

---

# 25. Xilinx Clock Resource

如果必须产生或控制 Clock，优先使用器件专用资源：

```text
BUFG
BUFGCE
BUFGCTRL
MMCM
PLL
Clocking Wizard
```

具体使用必须符合 FPGA 型号、Vivado 版本、Clock 架构和设计约束。

---

# 26. CDC 总体规则

所有跨 Clock Domain 信号必须明确识别。

每个 CDC 至少记录：

```text
Source Clock
Destination Clock
Signal
Signal Type
CDC Method
```

禁止直接认为两个频率相同就一定属于同步时钟。

---

# 27. CDC 单 Bit Level 信号

单 bit 稳态控制信号通常使用 2FF 同步。

```verilog
reg sync_ff1;
reg sync_ff2;

always @(posedge dst_clk or negedge dst_rst_n)
begin
    if (!dst_rst_n)
    begin
        sync_ff1 <= 1'b0;
        sync_ff2 <= 1'b0;
    end
    else
    begin
        sync_ff1 <= async_i;
        sync_ff2 <= sync_ff1;
    end
end
```

2FF 同步只适合单 bit Level 信号，不能用于保证多 bit 数据一致性。

---

# 28. CDC Pulse 信号

短 Pulse 跨时钟域时不能默认直接使用 2FF。

可根据需求使用：

```text
Pulse Stretch
Toggle Synchronizer
Handshake
Event Counter
```

必须确认：

- Source Pulse 宽度；
- Source / Destination Clock 比例；
- Event 是否允许丢失；
- Event 是否可能连续发生。

---

# 29. CDC 多 Bit 数据

多 bit 数据禁止逐 bit 独立 2FF 后直接使用。

根据数据性质使用：

```text
Handshake
Stable Data + Control Synchronization
Gray Code
Async FIFO
```

---

# 30. CDC Streaming Data

连续数据流跨时钟域优先使用 Async FIFO。

在 AMD/Xilinx 项目中，可优先考虑：

```text
XPM FIFO
FIFO Generator
已有成熟 Async FIFO IP
```

优先级由项目规范决定。

---

# 31. RDC 规则

除 CDC 外，需要检查 Reset Domain Crossing。

关注：

- Reset 是否属于不同 Clock Domain；
- Reset 是否独立释放；
- 一个 Reset Domain 的状态信号是否进入另一个 Reset Domain；
- 一个模块 Reset 后另一个模块是否仍认为事务有效；
- Reset 是否会破坏握手状态。

---

# 32. FSM 编码规范

纯 Verilog 推荐使用 `localparam` 定义状态。

```verilog
localparam ST_IDLE = 3'd0;
localparam ST_CFG  = 3'd1;
localparam ST_RUN  = 3'd2;
localparam ST_DONE = 3'd3;
localparam ST_ERR  = 3'd4;

reg [2:0] state_reg;
reg [2:0] state_next;
```

推荐使用状态寄存器 + Next State 组合逻辑 + 输出逻辑。两段式或三段式均可，项目统一优先于个人偏好。

---

# 33. FSM 必须检查

至少检查：

```text
Reset State
所有正常状态
所有正常转移
异常状态
非法状态
错误恢复
返回安全状态路径
死锁风险
永久等待风险
```

不要强制所有 FSM 都必须命名为 IDLE，但必须有明确安全初始状态。

---

# 34. FSM default 规则

组合状态机必须提供合理的安全 default。

具体恢复状态根据设计方案确定。

不得默认所有非法状态都跳 IDLE，如果这样会破坏事务或产生危险行为。

---

# 35. Counter 设计规范

Counter 必须明确：

```text
计数范围
初值
最大值
清零条件
递增条件
溢出行为
```

避免无理由统一使用 32 bit Counter。

---

# 36. Counter 位宽

Verilog-2001 中可使用 function 计算位宽，或者由参数显式提供。

简单项目可以：

```verilog
parameter CNT_WIDTH = 10;
```

不应为了自动化写过度复杂、难维护的 constant function。

---

# 37. Magic Number 禁止规则

禁止大量直接写：

```verilog
if (cnt == 1023)
```

推荐：

```verilog
parameter DATA_NUM = 1024;
localparam DATA_LAST = DATA_NUM - 1;
```

---

# 38. Parameter 使用原则

适合参数化：

```text
DATA_WIDTH
ADDR_WIDTH
FIFO_DEPTH
CHANNEL_NUM
BURST_LEN
MAX_LENGTH
TIMEOUT
```

只有需要实例化时配置的参数才使用 parameter，内部固定常量使用 localparam。

---

# 39. 位宽设计原则

每个运算必须确认：

```text
Input Width
Expression Width
Output Width
Signed / Unsigned
Overflow
Truncation
Extension
```

重点关注：

```text
+
-
*
>>
<<
比较
拼接
常量
```

---

# 40. 隐式截断

如果需要截断，应显式表达设计意图。

推荐：

```verilog
assign data_o = result[7:0];
```

不推荐依赖隐式位宽截断。

---

# 41. 扩展规则

Unsigned 扩展：

```verilog
assign ext_data = {{8{1'b0}}, data_i};
```

Signed 扩展：

```verilog
assign ext_data = {{8{data_i[7]}}, data_i};
```

---

# 42. Signed / Unsigned

涉及 signed / unsigned 混合运算时，应显式检查表达式位宽与符号属性。

禁止默认认为位宽相同就等于符号行为正确。

---

# 43. 常量位宽规则

推荐显式位宽：

```verilog
8'd1
16'd1024
32'h0000_0001
```

不要为了形式产生过度复杂代码，但在会影响算术结果的位置必须明确位宽。

---

# 44. Arithmetic 设计规则

使用以下运算前必须考虑资源、Latency 和 Fmax：

```text
+
-
*
/
%
Variable Shift
```

---

# 45. 乘法

乘法要检查：

```text
输入位宽
输出位宽
Signed
DSP推断
流水级
```

对于高频、大位宽乘法，优先考虑 Pipeline、DSP48 或官方 Multiplier IP。

---

# 46. 除法与模运算

除法和 `%` 可能生成大规模逻辑。

必须确认：

- 除数是否常量；
- 是否为 2 的幂；
- 是否允许多周期；
- 是否应该使用 Divider Generator；
- 是否可以改成移位、乘倒数或迭代结构。

不得仅因为 Verilog 支持 `/` 就直接用于高性能数据通路。

---

# 47. Shift

固定移位通常成本较低。

Variable Shift 可能推断 Barrel Shifter，需要根据位宽和目标 Fmax 评估。

---

# 48. Pipeline 设计规范

Pipeline 必须保证 Data 与 Metadata 对齐。

如果数据延迟 N 拍，则与该事务绑定的：

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
```

必须保持一致的语义对齐。

---

# 49. Latency 一致性

如果设计方案规定 Input → Output = N cycles，RTL 应按设计实现。

如实际实现变更，必须记录 DESIGN DEVIATION，并提示设计方案反标。

---

# 50. Ready / Valid 总体规则

内部 Ready / Valid 或 AXI Stream 类接口的数据传输成立条件：

```text
valid && ready
```

---

# 51. Valid 保持规则

当：

```text
valid = 1
ready = 0
```

若协议要求标准 Ready / Valid 行为，必须保持：

```text
valid
数据
sideband
```

直到握手成功。

---

# 52. Backpressure

所有支持 Backpressure 的模块必须分析：

```text
下游Ready=0时
数据存在哪里
上游何时停止
Pipeline如何停
FIFO是否会满
已进入Pipeline的数据如何保存
```

不得默认 ready 永远为 1，除非设计方案明确如此。

---

# 53. Skid Buffer

对于高频 Ready / Valid 通路，如组合 Ready 路径过长，可根据设计需要使用：

```text
Skid Buffer
Elastic Buffer
Register Slice
```

是否使用必须考虑 Latency、Throughput、Timing 和协议行为。

---

# 54. Packet / Frame 处理

涉及 SOP / EOP / TLAST / Packet Length / Frame Length 时，至少分析：

```text
单Beat
最小长度
最大长度
连续Packet
Backpressure
Packet中途Reset
非法长度
早到EOP
缺失EOP
```

---

# 55. FIFO 设计规范

使用 FIFO 前明确：

```text
用途
同步/异步
Data Width
Depth
FWFT / Standard
Almost Full
Almost Empty
Data Count
Reset行为
Overflow行为
Underflow行为
```

---

# 56. FIFO 读写保护

原则：

```text
write = wr_req && !full
read  = rd_req && !empty
```

除非所使用 IP 本身支持其他合法模式。

---

# 57. FIFO 深度

FIFO 深度必须来自：

```text
流量分析
最大Backpressure
Burst
Clock Ratio
Latency
系统缓存策略
```

如果设计方案已给深度，RTL Skill 不擅自修改。

---

# 58. RAM / ROM 设计规则

根据容量、数据宽度、读写端口、Clock、Latency 和读写模式决定使用：

```text
Register
LUTRAM
BRAM
URAM
XPM Memory
Block Memory Generator
```

---

# 59. RAM 推断

使用 RTL 推断 RAM 时，代码结构应符合目标 Vivado 版本的 RAM inference 模板。

如用户提供公司 RAM 模板，应严格遵循模板。

---

# 60. 大容量数组

禁止在不了解综合结果的情况下用大量寄存器实现大容量存储。

必须确认：

- 是否正确推断 RAM；
- 是否符合读延迟；
- 是否符合端口类型；
- 是否满足目标器件资源。

---

# 61. 官方 IP 使用原则

如设计方案指定官方 IP，不得擅自改成自研 RTL。

如设计方案允许选择，可按项目优先级选择：

```text
已有成熟项目IP
    ↓
已有公司自研IP
    ↓
Xilinx XPM
    ↓
Xilinx官方IP
    ↓
通用RTL推断
    ↓
自研底层结构
```

具体优先级以项目要求为准。

---

# 62. Xilinx XPM

在 AMD/Xilinx 项目中，适合使用时可考虑：

```text
XPM_CDC
XPM_FIFO
XPM_MEMORY
```

是否使用必须结合 Vivado 版本、FPGA 型号、项目规范、仿真环境和可移植性要求。

---

# 63. 官方 IP Wrapper

推荐：

```text
Business Logic
      ↓
IP Wrapper
      ↓
Official IP
```

例如：

```text
xxx_fifo_wrapper.v
xxx_bram_wrapper.v
xxx_divider_wrapper.v
```

便于隔离 IP 版本、简化上层接口、替换与仿真。

---

# 64. IP 配置记录

使用官方 IP 时应记录：

```text
IP Name
IP Version
Vivado Version
FPGA Family
XCI
Key Parameters
Clock
Reset
Latency
Width
Depth
```

---

# 65. 已有 RTL 使用规则

用户上传已有 RTL 时，首先：

```text
理解
↓
分析
↓
确认接口
↓
识别Clock/Reset
↓
识别FSM
↓
识别数据路径
↓
识别依赖
↓
确定修改范围
```

然后再修改。

---

# 66. 已有 RTL 最小修改原则

对于成熟项目优先：

```text
Minimize Diff
```

不要为了“代码更漂亮”重写整个模块。

除非用户明确要求重构，或设计已经发生重大变化。

---

# 67. 已有 RTL 接口保护

除非设计方案或用户明确要求，禁止擅自修改：

```text
Module Name
Port Name
Port Width
Parameter Name
Clock
Reset
Protocol Behavior
Latency
```

---

# 68. Include 文件规则

`.vh` 适合放：

```text
宏定义
公共常量
全局编译开关
```

不要滥用全局宏替代 module parameter。

---

# 69. `define 使用原则

推荐只用于全局 Feature 开关、统一常量和编译条件。

如果参数属于模块实例配置，优先：

```verilog
parameter DATA_WIDTH = 256
```

而不是全局宏。

---

# 70. Generate 使用规则

Verilog generate 可用于参数化通道、重复实例和可选逻辑。

```verilog
genvar i;

generate
    for (i = 0; i < CHANNEL_NUM; i = i + 1)
    begin : GEN_CHANNEL
        // instance
    end
endgenerate
```

必须保证 Instance Name 清晰、参数合法、边界值可综合。

---

# 71. Function 使用规则

Verilog function 可用于：

```text
组合计算
位宽辅助
编码转换
重复组合逻辑
```

复杂业务逻辑不要为了减少行数而全部塞入 function。

---

# 72. Task 使用规则

Synthesizable RTL 中谨慎使用 task。

若项目编码规范不允许，禁止使用。

如果使用：

- 必须确认 Vivado 可综合；
- 不允许 timing control；
- 不允许仿真专用行为；
- 不应隐藏复杂状态逻辑。

---

# 73. Tri-State 规则

FPGA 内部逻辑不应依赖内部三态总线。

顶层 IO 如确实需要三态，应使用 FPGA 支持的 IO 结构，如 Xilinx IOBUF。

---

# 74. Initial 语句规则

普通可综合业务 RTL 默认禁止 `initial`。

例外：部分 FPGA RAM / ROM 初始化流程可能允许综合。

如确实使用，必须满足 Vivado 支持、目标器件支持、设计方案允许，并保证仿真与综合行为一致。

---

# 75. 不可综合代码禁止列表

普通 RTL 中禁止：

```verilog
#10
wait(...)
force
release
fork
join
```

以及其他仿真 timing control。

避免在可综合 RTL 中使用 `real`、`time`、`event` 等仿真型语义。

---

# 76. 多驱动禁止规则

同一 reg 不得由多个 always 块驱动。

同一 wire 不得由多个普通逻辑源产生冲突驱动。

发现 Multi Driver 必须视为 MUST FIX。

---

# 77. 组合环路禁止规则

禁止无意组合反馈，特别检查：

```text
ready链
grant链
mux反馈
next-state逻辑
```

---

# 78. Large MUX / Priority Logic

出现大 Case、多层 if-else、Priority Encoder、宽 Mux 时，必须考虑：

```text
组合深度
Fmax
资源
Fanout
```

如果目标频率较高，可考虑 Pipeline、分层编码、Tree Structure 或 Register Stage。

---

# 79. High Fanout

重点关注：

```text
Reset
Enable
Start
Mode
Clear
Global Valid
```

若驱动大量寄存器，可能导致 Routing Congestion 与 Timing Risk。

---

# 80. Timing 意识

RTL 编写时必须考虑：

```text
Critical Path
Combinational Depth
Fanout
Wide Compare
Wide Add
Large Mux
Priority Logic
Variable Shift
Division
```

不能只保证仿真功能正确。

---

# 81. Resource 意识

RTL 编写时应关注：

```text
LUT
FF
BRAM
URAM
DSP
BUFG
MMCM
PLL
GT
```

未综合前只能给资源风险、资源倾向或估算，不得虚构实际综合利用率。

---

# 82. Timing 结果禁止虚构

未实际运行 Vivado Implementation 时，不得声称：

```text
WNS >= 0
Timing Closed
Fmax = xxx MHz
```

只能说明设计目标、预计风险和建议检查项。

---

# 83. Resource 结果禁止虚构

未实际综合时不得声称：

```text
LUT = xxx
FF = xxx
BRAM = xxx
```

除非数字来自用户提供的综合报告。

---

# 84. AXI 规则

如涉及 AXI / AXI-Lite / AXI-Stream，必须以设计方案、接口协议和官方规范为准。

重点检查：

```text
VALID
READY
Address
Data
Response
Burst
LEN
SIZE
LAST
KEEP
STRB
ID
USER
```

不得仅凭“常见写法”自行猜测项目接口行为。

---

# 85. AXI-Lite

至少检查：

```text
AWVALID/AWREADY
WVALID/WREADY
BVALID/BREADY
ARVALID/ARREADY
RVALID/RREADY
```

AXI-Lite 写地址和写数据通道相互独立，不能默认 AWVALID 和 WVALID 一定同拍。

---

# 86. AXI-Stream

重点检查：

```text
TVALID
TREADY
TDATA
TLAST
TKEEP
TUSER
```

当 TVALID=1 且 TREADY=0 时，必须保持当前传输内容稳定，符合协议。

---

# 87. 寄存器逻辑

如果设计方案提供寄存器表，必须严格按照：

```text
Address
Bit Field
Reset Value
Access Type
Description
```

实现。

不得擅自改变 RO、RW、W1C、RC、Pulse、Sticky 等语义。

---

# 88. W1C

Write-1-to-Clear 字段需要明确处理同时发生 Hardware Set 与 Software Clear 的优先级。

优先级必须来自设计方案，不能擅自定义。

---

# 89. Sticky Error

错误状态如果要求 Sticky，一旦置位，应保持到 Reset 或明确 Clear，不得自动下一拍清零。

---

# 90. Pulse Register

软件写寄存器产生单拍 Pulse 时，必须明确：

```text
在哪个Clock域
Pulse宽度
是否跨Clock
是否允许重复触发
```

如果跨 Clock，需要 CDC。

---

# 91. Timeout

涉及 Timeout 必须明确：

```text
起始条件
停止条件
清零条件
Timeout值
Clock频率
Counter宽度
Timeout后的动作
```

---

# 92. Error Handling

常见异常：

```text
Overflow
Underflow
Protocol Error
Length Error
Timeout
Illegal State
Configuration Error
```

每种异常至少明确：

```text
Detect
Record
Report
Recover
Reset Required?
```

---

# 93. Debug 设计

如设计方案要求可观测性，可提供：

```text
Status
Error Code
FIFO Level
FSM State
Packet Count
Byte Count
Performance Count
Timeout Count
```

不要为了调试永久暴露大量内部信号到顶层。

---

# 94. ILA

如项目要求 ILA，业务 RTL 应保持关键内部信号命名清晰、层级合理。

是否添加 `mark_debug` 必须根据项目要求，不要默认给大量信号添加。

---

# 95. Synthesis Attribute

例如：

```verilog
(* keep = "true" *)
(* dont_touch = "true" *)
(* mark_debug = "true" *)
(* use_dsp = "yes" *)
```

不得滥用。只有明确知道原因、综合影响和维护影响时使用。

---

# 96. dont_touch 规则

`dont_touch` 会限制综合优化。

默认禁止把它作为“防止 Vivado 改代码”的通用手段。

---

# 97. generate / parameter 边界测试

参数化模块至少思考：

```text
MIN
MAX
1
2
Power of 2
Non-Power of 2
```

不能只验证默认参数。

---

# 98. 代码注释规范

注释重点解释：

```text
为什么
协议约束
时序原因
边界原因
异常策略
特殊综合考虑
```

避免无信息量注释。

---

# 99. TODO / FIXME 规则

RTL 交付版本禁止存在未说明的：

```text
TODO
FIXME
TEMP
HACK
```

如存在必须纳入 Open Issue List。

---

# 100. 版本管理

每次重要修改建议记录：

```text
Version
Date
Change
Reason
Affected Modules
Related Bug / Requirement
```

详细历史应由 Git 管理，文件头只保留必要版本信息。

---

# 101. Verilog 格式规范

建议：

```text
4空格缩进
begin/end对齐
一行一个主要语句
端口按功能分组
信号按功能分组
```

统一优先于个人风格。

---

# 102. Port 声明

Verilog-2001 推荐 ANSI 风格端口：

```verilog
module xxx (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [31:0] data_i,
    output wire [31:0] data_o
);
```

---

# 103. Reg / Wire 使用规则

组合 assign 输出使用 wire，always 块赋值使用 reg。

---

# 104. 同一信号单一所有者

每个寄存器应有明确的 Owner always block，每个控制信号应有明确 Source 和 Destination。

---

# 105. Combinational Output vs Registered Output

是否寄存输出必须根据接口协议、Latency、Timing 和 Glitch 要求确定。

不要默认所有输出都组合，也不要默认所有输出都寄存。

---

# 106. Glitch

对于 Reset、Clock Enable、Interrupt、External Control、IO Control 等，如果协议要求无毛刺，需要确保输出来自寄存器或专用资源。

---

# 107. Pulse Width

单周期 Pulse 必须说明基于哪个 Clock、持续几个周期、是否允许连续。

---

# 108. Start / Busy / Done

典型事务控制必须明确：

```text
Start接受条件
Busy期间Start如何处理
Done是Level还是Pulse
Error是否与Done同时有效
```

这些必须来自设计方案。

---

# 109. 并发事务

如果支持多个事务并行，必须明确：

```text
ID
Tag
Context
Ordering
Completion
Buffer
```

不得将单事务 FSM 简单修改成可并发而不重新设计状态管理。

---

# 110. Ordering

涉及多通道、多个 Outstanding、多个 FIFO 时，必须确认输出是否要求：

```text
In Order
Out of Order
Per Channel Order
```

---

# 111. 数据字节序

必须明确：

```text
Little Endian
Big Endian
Byte Lane
Bit Ordering
```

涉及位宽转换或数据重排时尤其重要。

---

# 112. 位宽转换

例如 32 → 128、128 → 32 时，必须明确：

```text
低位先/高位先
帧边界
不足一个完整输出字如何处理
Keep
Padding
```

---

# 113. 数据打包 / 解包

必须保持 Field 位置、Field 宽度、Byte 顺序、Reserved 位、CRC 位置、Header、Payload 与协议一致。

---

# 114. Saturation / Wrap

算术溢出必须明确：

```text
Wrap
Saturation
Error
Ignore
```

不能自行选择。

---

# 115. Fixed Point

若存在定点数，必须明确：

```text
Q Format
Integer Bits
Fraction Bits
Signed
Rounding
Truncation
Saturation
```

所有 Pipeline Stage 必须保持格式可追踪。

---

# 116. Rounding

若需要 Round，应明确具体规则，不得把简单截位当作 Round。

---

# 117. BRAM Read Latency

使用 Block RAM 时必须考虑实际 Read Latency。

不能设计成组合读，但实际 IP 为 1~2 cycle latency。

---

# 118. IP Latency

任何官方 IP 都必须确认：

```text
Input Handshake
Output Handshake
Fixed Latency
Variable Latency
Pipeline
Reset
Clock Enable
```

不能仅凭 IP 名称假设 Latency。

---

# 119. Black Box

如果第三方 IP 只有接口，没有内部 RTL，必须将其视为 Black Box，不得虚构内部实现。

---

# 120. 仿真宏

如果 RTL 中需要 simulation-only 代码，必须使用项目允许的编译宏隔离。

例如：

```verilog
`ifndef SYNTHESIS
// simulation only
`endif
```

但默认不应在生产 RTL 中加入大量仿真逻辑。

---

# 121. `$display` / `$finish`

生产 RTL 默认不应使用 `$display`、`$finish`、`$stop`。

如仅用于仿真调试，必须明确隔离，并确认综合不会受到影响。

---

# 122. Assertion 规则

本 Skill 为纯 Verilog-2001 Skill。

不在 RTL 中生成 SystemVerilog Assertion：

```text
assert property
property
sequence
```

如果需要协议 Assertion，应放入后续 SystemVerilog TB 或验证 Skill。

---

# 123. Compile 自检

生成 RTL 后至少检查：

```text
Syntax Error
Undefined Signal
Implicit Net
Port Mismatch
Parameter Mismatch
Multiple Driver
Width Mismatch
Signed Mismatch
Unconnected Critical Port
```

---

# 124. Lint 自检

至少检查：

```text
Unintended Latch
Multiple Driver
Incomplete Case
Width Truncation
Signed Conversion
Unused Critical Signal
Undriven Signal
Constant Signal
Combinational Loop
Reset Issue
FSM Issue
```

---

# 125. Warning 分类

Warning 不允许统一忽略。

```text
MUST FIX
需要修复

REVIEW
需要人工确认

KNOWN / ACCEPTED
确认可接受，必须说明原因
```

---

# 126. CDC 自检输出

| Source Clock | Destination Clock | Signal/Data | Type | CDC Method |
|---|---|---|---|---|
| | | | | |

---

# 127. Reset 自检输出

| Reset | Clock Domain | Polarity | Assert | Deassert | Scope |
|---|---|---|---|---|---|
| | | | | | |

---

# 128. FIFO 自检输出

| FIFO | Clock | Type | Width | Depth | Full Handling | Empty Handling |
|---|---|---|---|---|---|---|
| | | | | | | |

---

# 129. Latency 自检输出

| Path | Expected Latency | RTL Latency | Status |
|---|---:|---:|---|
| | | | |

若无法从静态代码可靠确定，标记：

```text
TBD / Needs Simulation
```

不要虚构。

---

# 130. Module Interface 自检

| Signal | Direction | Width | Clock | Reset | Description |
|---|---|---:|---|---|---|
| | | | | | |

---

# 131. RTL 生成工作流程

## Step 1：读取全部输入

读取：

```text
设计方案
接口
时钟
复位
数据格式
FSM
FIFO
IP
寄存器
性能
已有RTL
模板
```

## Step 2：建立设计摘要

```text
Module
Function
Clock
Reset
Input
Output
Data Flow
FSM
FIFO
CDC
IP
Performance
```

## Step 3：建立模块树

必须以设计方案为主。

## Step 4：建立 Clock / Reset Map

列出 Clock Domain、Reset Domain、CDC、RDC。

## Step 5：建立 Interface Map

列出 External Interfaces、Internal Interfaces、Ready/Valid、Packet Signals、Register Interface。

## Step 6：建立数据通路

明确 Input → Buffer → Transform → Process → Output。

## Step 7：建立 Control Flow

明确 Start → State → Process → Done/Error。

## Step 8：确定 Verilog 文件

在编码前确定文件名、模块名、职责、依赖。

## Step 9：先实现基础结构

优先 Port、Parameter、Localparam、Signal、Instance。

## Step 10：实现时序与组合逻辑

按照 Clock、Reset、FSM、Datapath、FIFO、Interface 逐项实现。

## Step 11：处理 CDC / IP

CDC 和官方 IP 不应最后临时添加，应作为架构组成部分实现。

## Step 12：静态自检

执行 Compile Review、Lint Review、CDC Review、Width Review、FSM Review、FIFO Review、Pipeline Review。

## Step 13：设计一致性检查

逐项比较 Design vs RTL。

## Step 14：输出

输出 RTL 文件、README、Module 说明、接口说明、Parameter 说明、CDC 清单、IP 清单、设计差异、TBD、Risk。

---

# 132. 现有模板处理规则

如果用户上传公司 RTL 模板，优先遵循：

```text
目录
文件头
命名
缩进
Module结构
参数格式
Reset写法
FSM风格
注释格式
```

除非模板存在明显综合错误。

若模板与本 Skill 默认规范冲突：用户模板优先，同时对潜在问题进行说明。

---

# 133. 已有工程处理

如果用户上传完整工程，不要重新建立完全不同的目录。

应尽量保持原目录、原 Top、原 IP、原 Constraint、原命名，仅增加必要模块。

---

# 134. Vivado 版本处理

所有与 Xilinx IP、XPM、Primitive、综合模板相关的建议必须结合用户提供的 Vivado Version。

如果版本未知，不能声称某具体 IP Version 必然可用。

---

# 135. FPGA 型号处理

所有以下内容需要结合器件：

```text
BRAM
URAM
DSP
GT
MMCM
PLL
IO
Clock Buffer
```

如果 FPGA 型号未知，只能使用通用 RTL 结构，不得虚构器件资源能力。

---

# 136. 不得擅自升级语言

若项目要求 Verilog，不得输出 SystemVerilog。

禁止：

```text
logic
always_ff
always_comb
typedef
enum
interface
```

输出文件必须使用 `.v` 而不是 `.sv`。

---

# 137. 不得擅自优化架构

未经设计依据，不得将：

```text
FSM → Pipeline
BRAM → Distributed RAM
Async FIFO → 2FF
Packet Buffer → Stream Through
```

---

# 138. 优化建议与正式实现分离

如果发现更优架构，可以输出：

```text
OPTIMIZATION SUGGESTION
```

但不要直接应用到正式 RTL，除非设计方案允许、用户明确要求、不改变外部行为且风险可控。

---

# 139. 安全修改原则

修改已有 RTL 时，优先保持：

```text
接口
行为
Clock
Reset
Latency
Parameter
```

除非任务明确要求改变。

---

# 140. Bug Fix 规则

修复 Bug 时必须说明：

```text
Bug现象
根因
修改点
影响模块
接口是否变化
Latency是否变化
资源风险
Regression范围
设计文档是否需要反标
```

---

# 141. 重构规则

重构与功能修改分开。

如果目标只是重构，不得改变 External Behavior、Cycle Behavior、Handshake、Latency、Reset，除非明确允许。

---

# 142. 输出目录推荐

```text
output/
│
├── rtl/
├── include/
├── ip/
├── doc/
│   ├── RTL_README.md
│   ├── RTL_INTERFACE.md
│   ├── RTL_CDC_LIST.md
│   ├── RTL_IP_LIST.md
│   ├── RTL_DESIGN_DEVIATION.md
│   └── RTL_OPEN_ISSUES.md
└── changelog/
    └── RTL_CHANGE_LOG.md
```

---

# 143. RTL_README 内容

至少包含：

```text
Project
Module
FPGA
Vivado
RTL Language
Top Module
Clock
Reset
Main Function
Directory
Dependencies
Build Notes
Known Issues
```

---

# 144. RTL_CHANGE_LOG

| Version | Module | Change | Reason | Impact |
|---|---|---|---|---|
| | | | | |

---

# 145. RTL_OPEN_ISSUES

| ID | Type | Description | Impact | Status |
|---|---|---|---|---|
| | TBD / Risk / Design Issue | | | |

---

# 146. RTL_DESIGN_DEVIATION

| ID | Design Requirement | RTL Implementation | Reason | Need Design Update |
|---|---|---|---|---|
| | | | | |

---

# 147. 输出代码要求

正式输出代码必须：

- 完整；
- 不省略关键模块；
- 不使用伪代码替代 RTL；
- 不使用 `...` 代替实现；
- 不虚构 IP 端口；
- 不虚构寄存器定义；
- 不虚构芯片资源；
- 不虚构时序结果。

---

# 148. 代码生成时的说明要求

每个主要模块输出时说明：

```text
模块职责
Clock
Reset
输入
输出
核心逻辑
状态机
Latency
CDC
IP依赖
```

---

# 149. 不应在 RTL Skill 内完成的工作

本 Skill 不替代：

```text
FPGA需求分析
详细架构设计
完整Testbench
UVM
功能Coverage
板级验证
完整STA
硬件调试
```

这些应由其他 Skill 完成。

---

# 150. 与仿真 Skill 的接口

RTL Skill 输出应足以让后续 TB Skill 获取：

```text
Top Module
Module Port
Clock
Reset
Parameter
Protocol
FSM
Expected Behavior
Error Behavior
Latency
TBD
```

---

# 151. 与 Review Skill 的接口

RTL Skill 应输出：

```text
RTL Source
Design Reference
CDC List
IP List
Open Issues
Design Deviations
```

供 Review Skill 检查功能、编码、CDC、Reset、Timing Risk、Resource Risk、Maintainability。

---

# 152. 设计反标接口

如果 RTL 实现导致设计方案需要更新，必须输出：

```text
DESIGN BACK-ANNOTATION REQUIRED
```

至少列出模块、接口、FSM、FIFO、Latency、Clock、Reset、IP、Parameter 中发生变化的项目。

---

# 153. RTL 开发完成 Checklist

## 153.1 设计一致性

```text
[ ] 模块职责与设计一致
[ ] 外部接口与设计一致
[ ] 数据格式与设计一致
[ ] 数据流与设计一致
[ ] FSM与设计一致
[ ] FIFO深度与设计一致
[ ] IP选择与设计一致
[ ] Latency与设计一致或已记录差异
```

## 153.2 Clock / Reset

```text
[ ] 每个模块Clock明确
[ ] 每个模块Reset明确
[ ] 无普通逻辑生成Clock
[ ] Reset极性正确
[ ] Reset行为正确
[ ] 异步Reset释放策略正确
[ ] 无明显RDC风险
```

## 153.3 CDC

```text
[ ] 所有Clock Domain已识别
[ ] 所有CDC已列出
[ ] 单bit CDC方法正确
[ ] Pulse CDC方法正确
[ ] Multi-bit CDC方法正确
[ ] Streaming CDC使用适当结构
[ ] 无直接多bit异步采样
```

## 153.4 Verilog 编码

```text
[ ] 使用Verilog-2001
[ ] 无SystemVerilog专用语法
[ ] 时序逻辑使用<=
[ ] 组合逻辑使用=
[ ] 无意外Latch
[ ] 无Multiple Driver
[ ] 无Implicit Net
[ ] 无组合环
[ ] case有合理default
[ ] 无不可综合Timing Control
```

## 153.5 位宽

```text
[ ] 输入位宽正确
[ ] 输出位宽正确
[ ] 加法位宽已检查
[ ] 乘法位宽已检查
[ ] Shift位宽已检查
[ ] Signed/Unsigned已检查
[ ] 截断为显式设计
[ ] 扩展为显式设计
[ ] Overflow策略明确
```

## 153.6 FSM

```text
[ ] Reset State明确
[ ] 正常路径完整
[ ] 异常路径完整
[ ] 无死锁
[ ] 非法状态有处理
[ ] 状态输出无意外毛刺
```

## 153.7 FIFO

```text
[ ] FIFO类型正确
[ ] FIFO深度正确
[ ] Full处理正确
[ ] Empty处理正确
[ ] Overflow处理正确
[ ] Underflow处理正确
[ ] Async FIFO CDC正确
[ ] Reset行为正确
```

## 153.8 Pipeline

```text
[ ] Data与Valid对齐
[ ] Data与Last对齐
[ ] Data与Metadata对齐
[ ] Backpressure处理正确
[ ] Latency可追踪
[ ] Pipeline无数据覆盖
```

## 153.9 IP

```text
[ ] IP名称正确
[ ] IP版本与Vivado匹配
[ ] IP参数已记录
[ ] IP Clock正确
[ ] IP Reset正确
[ ] IP Latency已确认
[ ] Wrapper接口稳定
```

## 153.10 可维护性

```text
[ ] Module职责单一
[ ] 命名一致
[ ] 参数合理
[ ] 无大量Magic Number
[ ] 注释解释设计意图
[ ] 无无意义重复代码
[ ] 无未说明TODO
[ ] Change Log完整
```

---

# 154. Definition of Done

RTL 只有同时满足以下条件，才认为达到本 Skill 的完成标准：

```text
[ ] 与设计方案一致
[ ] 使用纯Verilog-2001
[ ] 所有模块接口完整
[ ] Clock正确
[ ] Reset正确
[ ] CDC有明确处理
[ ] RDC无明显未处理风险
[ ] 无非预期Latch
[ ] 无Multiple Driver
[ ] 无Implicit Net
[ ] 无明显组合环
[ ] 无明显Width错误
[ ] Signed/Unsigned正确
[ ] FSM正常及异常路径完整
[ ] FIFO读写保护正确
[ ] Pipeline Data/Control对齐
[ ] Backpressure逻辑正确
[ ] 官方IP使用符合项目要求
[ ] 无不可综合代码
[ ] RTL结构清晰
[ ] 参数使用合理
[ ] 无未说明Magic Number
[ ] 编译级问题已检查
[ ] Lint风险已检查
[ ] CDC清单已输出
[ ] IP清单已输出
[ ] Design Deviation已输出
[ ] TBD/Open Issue已输出
[ ] 可进入后续仿真验证阶段
```

---

# 155. 推荐最终回复格式

完成 RTL 代码开发后，按以下格式汇报：

```text
# RTL开发结果

## 1. 开发范围
## 2. 输入依据
## 3. RTL文件
## 4. 模块层级
## 5. Clock / Reset
## 6. 接口
## 7. FSM
## 8. FIFO / Buffer
## 9. CDC / RDC
## 10. IP
## 11. Pipeline / Latency
## 12. 自检结果
## 13. Design Deviation
## 14. TBD / Open Issue
## 15. 后续建议
```

---

# 156. 核心原则总结

本 Skill 必须始终遵守：

> 设计方案优先。

> 不猜关键需求。

> 不擅自改变接口。

> 不擅自改变协议行为。

> 不擅自改变 Clock / Reset。

> 不擅自改变 Latency。

> 不擅自替换已指定 IP。

> 不使用 SystemVerilog 语法。

> 不生成不可综合 RTL。

> 不以仿真通过代替综合正确。

> 不以代码简短代替结构清晰。

> 不虚构综合、资源、Timing 结果。

> 已有 RTL 修改优先最小化 Diff。

> 代码变更必须能够追溯回设计方案。

> RTL 完成后必须为仿真、Review、综合和设计反标提供完整输入。

---

# 157. Skill 最终目标

最终目标不是“生成一段能运行的 Verilog”，而是生成：

```text
符合设计
+
接口稳定
+
Clock/Reset正确
+
CDC正确
+
位宽正确
+
状态机可靠
+
数据对齐
+
可综合
+
易验证
+
易维护
+
易Review
+
可追溯
```

的工程级 FPGA Verilog RTL。
