# DDR4_MIN_BIST_DESIGN_AND_VERIFICATION

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\docs\DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md`
- SHA-256: `c8d5c69881c39692ee87a0a86f72e259b7198538b3c705c2105597eb621134ab`
- Extractor: `text`
- Tags: `ddr4, mig, validation`
- Duplicate sources:
  - E:\ddr_proc\staging_axi_ddr4_min_2020_2\docs\DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md

# DDR4 最小工程 BIST 方案设计与验证说明

## 1. 文档信息

| 项目 | 内容 |
|---|---|
| 工程名称 | `axi_ddr4_min_2020_2` |
| FPGA | Xilinx Kintex UltraScale `xcku040-ffva1156-2-i` |
| DDR4 数据宽度 | 64 bit |
| MIG 用户接口 | AXI4 Slave，64-bit Data、32-bit Address、4-bit ID |
| 工具版本 | Vivado / XSim 2020.2 |
| 文档日期 | 2026-08-05 |

本文说明当前最小 DDR4 工程的设计目的、`axi_ddr_bist.v` 与顶层文件的实现思路、现有行为级验证方案，以及下一阶段 MIG+DDR4 器件模型完整仿真的实施方法。

当前工程中没有名为 `bist.v` 的独立文件。与 BIST 相关的实际文件为：

| 文件 | 作用 |
|---|---|
| `rtl/axi_ddr_bist.v` | AXI4 BIST 主控，负责测试数据写入、回读、比较和错误记录 |
| `rtl/top_axi_ddr4_bist.v` | 工程顶层，实例化 MIG 和 BIST，处理复位、启动、LED及调试信号 |
| `sim/tb_axi_ddr_bist.sv` | 行为级 AXI Memory Slave 和自检查测试流程 |

如果口头描述中的 `bist.v` 指 BIST 顶层，本文对应分析对象为 `top_axi_ddr4_bist.v`。

## 2. 最小工程目标与范围

工程只验证以下基本链路：

```text
板上差分参考时钟与复位
            │
            ▼
       DDR4 MIG
  物理校准 + AXI4 Slave
            │
            ▼
     axi_ddr_bist
  写入 → 回读 → 比较
            │
            ▼
  done/pass/fail/错误现场
            │
            ▼
         LED / ILA
```

为了缩小问题范围，当前工程不加入 MicroBlaze、DMA、FIFO、视频三缓冲和业务数据源。测试失败时，故障范围主要落在时钟、复位、MIG配置、DDR4引脚、AXI握手或BIST逻辑内。

## 3. 行为级仿真与完整仿真的区别

### 3.1 当前行为级仿真

当前脚本只编译：

```text
rtl/axi_ddr_bist.v
sim/tb_axi_ddr_bist.sv
```

Testbench 使用一个 `reg [63:0] memory[]` 数组模拟存储器，并在 AXI 接口上直接产生 `AWREADY/WREADY/BVALID/ARREADY/RVALID`。它没有实例化 `top_axi_ddr4_bist.v`、DDR4 MIG 或 DDR4 器件模型。

行为级仿真主要回答以下问题：

- BIST 状态机是否按预期完成“先写后读”；
- AW 与 W 在不同周期握手时，主控是否会丢地址或丢数据；
- READY 插入等待、读数据延迟返回时，主控是否保持 VALID 和控制信息；
- `BRESP`、`RRESP`、`RLAST` 和数据比较逻辑是否正确；
- 注入一个错误后，`fail`、`error_count` 和第一次错误现场是否能正确锁存。

它不能验证 MIG 初始化、DDR4 DQ/DQS、校准、板级引脚、PHY时序或PCB信号质量。

### 3.2 MIG+DDR4 器件模型完整仿真

本文中的“完整仿真”是指把工程顶层、MIG 仿真模型和 DDR4 Memory Model 放入同一个仿真环境：

```text
tb_top_axi_ddr4_bist
    ├─ 差分系统时钟、复位
    ├─ top_axi_ddr4_bist
    │    ├─ ddr4_axi_0（MIG）
    │    └─ axi_ddr_bist
    └─ DDR4 Memory Model
         └─ DQ/DQS/地址/命令/时钟物理端口连接
```

仿真必须从外部复位开始，等待 MIG 完成初始化和训练；`init_calib_complete` 拉高后，顶层释放 AXI 复位并启动 BIST。此时 BIST 的 AXI 请求会经过 MIG 控制器和PHY仿真逻辑，再转换成 DDR4 命令访问器件模型。

完整仿真可以验证：

- MIG 参数、顶层端口和 DDR4 器件模型是否匹配；
- 参考时钟、系统复位、`ui_clk` 和 `ui_clk_sync_rst` 的时序关系；
- MIG 是否能够在仿真中完成校准；
- AXI请求通过MIG后能否真正写入、读回器件模型；
- BIST是否在校准完成后启动，并最终给出正确的 `done/pass/fail`。

### 3.3 两者对比

| 对比项 | 行为级仿真 | MIG+DDR4完整仿真 |
|---|---|---|
| 被测范围 | `axi_ddr_bist` | 顶层 + BIST + MIG + DDR4模型 |
| 存储器 | Testbench寄存器数组 | DDR4厂商器件模型 |
| AXI响应方 | 自编行为模型 | MIG AXI Slave |
| DDR4校准 | 不涉及 | 涉及 |
| DDR4物理端口 | 不涉及 | 涉及逻辑/时序模型 |
| READY反压控制 | Testbench可定向构造 | 由MIG内部状态决定 |
| 错误注入 | 容易，可直接翻转数据 | 较复杂，通常保留在行为级测试中 |
| 运行速度 | 快，秒级 | 慢，校准和4096次访问可能耗时较长 |
| 主要用途 | 验证BIST RTL功能 | 验证系统集成和MIG数据通路 |

### 3.4 完整仿真仍不等于板级验证

MIG+DDR4器件模型仿真使用数字模型，不能真实反映PCB走线、阻抗、电源噪声、抖动、温度、电压和器件个体差异。完整仿真通过后，仍必须完成实现、时序签核和上板校准读写。

验证层次应按以下顺序理解：

```text
行为级仿真
    ↓
MIG+DDR4器件模型完整仿真
    ↓
综合/实现/DRC/静态时序分析
    ↓
bitstream下载与板级BIST
```

## 4. `axi_ddr_bist.v` 编写方案

### 4.1 参数化接口

模块保留以下参数：

```verilog
ADDR_WIDTH = 32
DATA_WIDTH = 64
ID_WIDTH   = 4
TEST_WORDS = 4096
BASE_ADDR  = 0
```

默认配置测试 4096 个 64-bit 字，总容量为：

```text
4096 × 8 Byte = 32768 Byte = 32 KiB
```

当前数据模式 `{~index, index}` 按 64 bit 设计，因此 `DATA_WIDTH` 虽然参数化，实际使用时应保持为64。若以后支持128 bit或256 bit，需要重新定义可扩展的数据生成函数。

### 4.2 地址与数据模式

第 `index` 个测试字地址为：

```text
address = BASE_ADDR + index × (DATA_WIDTH / 8)
```

64-bit数据模式为：

```text
expected_data = {~index[31:0], index[31:0]}
```

例如：

```text
index = 0 → FFFF_FFFF_0000_0000
index = 1 → FFFF_FFFE_0000_0001
index = 7 → FFFF_FFF8_0000_0007
```

这种模式的优点是生成逻辑简单、每个地址的数据不同，观察波形或第一次错误数据时也容易反推索引。

### 4.3 AXI事务策略

当前采用最小 AXI4 子集：

- 固定 `ID=0`；
- `AWLEN/ARLEN=0`，即单拍事务；
- `AWSIZE/ARSIZE=3`，每拍8字节；
- `AWBURST/ARBURST=INCR`；
- `WSTRB=8'hFF`，所有字节有效；
- 任意时刻最多只有一个未完成事务。

该方案吞吐率不高，但控制路径短，方便判断问题发生在地址、数据、响应还是读回比较阶段。最小工程优先保证可调试性，不以带宽为目标。

### 4.4 状态机流程

```text
ST_IDLE
   │ start
   ▼
ST_WRITE_SEND ──等待AW与W分别握手──► ST_WRITE_RESP
      ▲                                      │
      └────────────还有数据，准备下一字──────┘
                                             │ 最后一个写响应
                                             ▼
ST_READ_ADDR ──AR握手──► ST_READ_DATA
      ▲                         │
      └──还有数据，准备下一地址─┘
                                │ 最后一个读数据
                                ▼
                             ST_DONE
```

AXI4写地址通道与写数据通道互相独立。`aw_sent` 和 `w_sent` 分别记录两路握手状态，只有二者都完成后才拉高 `BREADY`。这避免了从设备在不同周期给出 `AWREADY`、`WREADY` 时产生误判。

### 4.5 错误检测和现场保留

写阶段检查：

```text
BRESP == OKAY
```

读阶段检查：

```text
RRESP == OKAY
RLAST  == 1
RDATA  == data_pattern(read_index)
```

发生错误后：

- `fail` 置位并保持；
- `error_count` 每次错误加一；
- 仅第一次错误写入 `first_error_addr`、`first_expected_data` 和 `first_actual_data`；
- 后续测试继续执行，以便统计总错误数；
- 最后一个读事务完成时，根据历史 `fail` 和当前 `read_error` 生成 `pass`。

`ST_DONE` 会保持结果，直到系统复位，方便LED或ILA稳定观察。

## 5. `top_axi_ddr4_bist.v` 编写方案

### 5.1 MIG与BIST直连

顶层将 BIST 的五个 AXI 通道直接连接到 `ddr4_axi_0` 的 AXI Slave，不经过 AXI Interconnect。当前只有一个主机，因此这种连接方式最短，也不需要地址译码和仲裁。

### 5.2 时钟和复位

MIG产生：

```text
ui_clk
ui_clk_sync_rst
init_calib_complete
```

BIST工作在 `ui_clk` 域。只有 `ui_clk_sync_rst=0` 且 `init_calib_complete=1` 后，`axi_reset_pipe` 才连续移入两个1，再释放 `axi_aresetn`。该两级延迟用于避免校准完成信号变化时立即启动AXI状态机。

当前 `start` 直接连接 `init_calib_complete`。由于 BIST 完成后停在 `ST_DONE`，即使 `start` 一直为1，也只执行一次；若要重新测试，必须重新复位系统。

### 5.3 LED与调试信号

| 信号 | 状态 | 含义 |
|---|---|---|
| LED0 | 闪烁 | MIG仍在校准 |
| LED0 | 常亮 | `init_calib_complete=1` |
| LED1 | 慢闪 | BIST未完成且未失败 |
| LED1 | 常亮 | BIST完成并通过 |
| LED1 | 快闪 | BIST检测到错误 |

`init_calib_complete`、`bist_done/pass/fail`、错误计数和第一次错误现场均添加 `mark_debug`，后续可通过ILA观察。

## 6. 当前行为级验证方案

### 6.1 AXI行为模型

`tb_axi_ddr_bist.sv` 将 `TEST_WORDS` 缩减为32，即测试256 Byte，以缩短回归时间。Testbench实现以下条件：

- 100 MHz AXI时钟；
- AWREADY与WREADY按不同节拍变化；
- 写地址和写数据允许独立握手；
- ARREADY周期性插入等待；
- 读地址握手后延迟3个时钟返回数据；
- 返回正常的 `BRESP/RRESP` 和单拍 `RLAST`；
- 设置 `+INJECT_ERROR` 时，翻转索引7读数据的最低位。

### 6.2 测试用例

| 用例 | 场景 | 预期结果 |
|---|---|---|
| TC-BEH-001 | 32个64-bit字正常写入、回读 | `done=1, pass=1, fail=0, error_count=0` |
| TC-BEH-002 | 索引7读数据最低位翻转 | `done=1, pass=0, fail=1, error_count>0` |

### 6.3 2026-08-05回归结果

使用本机 Vivado/XSim 2020.2 重新编译注释后的源码，结果为：

```text
PASS: AXI write/read BIST completed without errors
$finish called at time : 3335 ns

PASS: injected read error was detected
$finish called at time : 3335 ns
```

中文注释未改变RTL和Testbench功能。

## 7. 完整仿真设计方案

### 7.1 仿真顶层

新增 `sim/tb_top_axi_ddr4_bist.sv`，完成以下工作：

1. 实例化 `top_axi_ddr4_bist`；
2. 按 MIG 配置产生差分系统参考时钟；
3. 产生满足要求的外部复位时序；
4. 实例化与 `MT40A512M16HA-083E` 组织方式匹配的 DDR4 Memory Model；
5. 按MIG示例工程连接CK、地址/命令、DQ、DQS和DM；
6. 设置校准和BIST完成超时；
7. 自动检查 `init_calib_complete`、`bist_done`、`bist_pass` 和 `bist_fail`。

具体器件模型数量和位宽连接必须以 Vivado 2020.2 MIG 生成的 Example Design 为准，不应手工猜测。

### 7.2 编译对象

完整仿真需要包含：

- `rtl/axi_ddr_bist.v`；
- `rtl/top_axi_ddr4_bist.v`；
- `ddr4_axi_0` MIG生成的仿真文件；
- Vivado 2020.2对应的Xilinx仿真库；
- DDR4器件模型；
- 新增的系统级Testbench。

建议从 MIG 的 `export_simulation` 或 Example Design 仿真脚本生成编译顺序，再把当前顶层和 BIST 接入，避免遗漏加密IP库、宏定义或Include目录。

### 7.3 完整仿真用例

| 用例 | 检查内容 | 通过条件 |
|---|---|---|
| TC-FULL-001 | 上电、复位和MIG初始化 | 超时前 `init_calib_complete=1` |
| TC-FULL-002 | 校准后AXI复位释放 | `axi_aresetn`在校准后稳定拉高 |
| TC-FULL-003 | 4096字写入与回读 | `bist_done=1, bist_pass=1, bist_fail=0` |
| TC-FULL-004 | LED状态映射 | 校准中、运行中、PASS状态符合定义 |
| TC-FULL-005 | 外部复位后重测 | 结果寄存器清零并重新完成校准和BIST |

错误注入仍以行为级测试为主。若需要在完整仿真中验证错误路径，应通过器件模型或MIG支持的接口定向注错，不建议用 `force` 随意破坏内部信号，因为这容易制造非协议场景。

### 7.4 建议观察信号

```text
sys_rst_n
init_calib_complete
ui_clk_sync_rst
axi_aresetn
axi_awvalid/axi_awready/axi_awaddr
axi_wvalid/axi_wready/axi_wdata
axi_bvalid/axi_bready/axi_bresp
axi_arvalid/axi_arready/axi_araddr
axi_rvalid/axi_rready/axi_rdata/axi_rresp/axi_rlast
bist_done/bist_pass/bist_fail
bist_error_count
first_error_addr
first_expected_data
first_actual_data
```

## 8. 分层验证与验收矩阵

| 阶段 | 验证对象 | 当前状态 | 输出物 |
|---|---|---|---|
| V0 | RTL编译与展开 | 已通过 | `xvlog/xelab`日志 |
| V1 | 行为级正常读写 | 已通过 | 正常场景XSim日志 |
| V2 | 行为级注错检测 | 已通过 | 注错场景XSim日志 |
| V3 | MIG+DDR4完整仿真 | 待执行 | 校准、读写波形和自检查日志 |
| V4 | 综合、实现、DRC、时序 | 待完成 | DCP、DRC和Timing报告 |
| V5 | bitstream与板级BIST | 待完成 | `.bit`、ILA/LED验收记录 |

最终板级通过条件：

1. MIG OOC综合和顶层综合完成；
2. 实现完成且DRC无Error；
3. Setup/Hold时序均满足；
4. bitstream成功生成；
5. JTAG识别到KU040；
6. 下载后 `init_calib_complete=1`；
7. BIST结束且 `pass=1, fail=0, error_count=0`。

## 9. 当前方案的限制与后续扩展

当前方案适合作为最小通路验收，但不代表DDR带宽或长期稳定性验证已经完成。主要限制如下：

- 只使用单拍事务，没有验证AXI Burst；
- 不支持多 outstanding，也没有验证不同AXI ID；
- 只覆盖起始32 KiB地址，没有覆盖高地址、边界和不同Bank/Row组合；
- 数据模式只有 `{~index, index}`，没有全0、全1、Walking 1/0、地址模式和伪随机模式；
- 硬件内部没有超时计数器，若AXI响应永久缺失，状态机会停住；
- 只能通过复位重新运行；
- 当前 `DATA_WIDTH` 的通用参数形式与64-bit数据模式并不完全匹配。

建议保持第一版最小工程不变，先完成校准和基础读写上板验收。第二阶段再增加 Burst、多数据模式、地址分段、超时和循环压力测试，避免在基础链路尚未确认时扩大故障范围。

## 10. 本次源码注释更新

以下文件已增加语段级中文注释，未修改逻辑：

```text
rtl/axi_ddr_bist.v
rtl/top_axi_ddr4_bist.v
sim/tb_axi_ddr_bist.sv
```

注释覆盖模块用途、状态机阶段、AXI独立握手、错误锁存、MIG复位启动、LED状态和行为级Memory Slave模型。
