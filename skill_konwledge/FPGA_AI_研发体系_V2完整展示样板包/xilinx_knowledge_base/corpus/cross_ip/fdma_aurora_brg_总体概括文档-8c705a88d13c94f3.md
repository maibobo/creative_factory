# fdma_aurora_brg_总体概括文档

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\fdma_aurora_brg_总体概括文档.md`
- SHA-256: `8c705a88d13c94f322159a7f0e357703749766cef8868a0da9f8e5871af65591`
- Extractor: `text`
- Tags: `aurora, fdma, overview, pcie`
- Duplicate sources:
  - none

# fdma_aurora_brg IP 总体概括文档

## 1. 文档范围

本文面向项目汇报、设计评审和验证交接场景，对 `fdma_aurora_brg` IP 的设计目标、模块架构、数据通路、验证平台和硬件调试模式进行概括说明。内容综合参考以下资料：

- `fdma_aurora_brg IP设计.docx`
- `fdma_aurora_brg IP  IT验证1.docx`
- `SV测试平台模式数据流详解.md`
- `SV测试平台文件类函数详解.md`
- `设计核心要素概览.md`
- `ChatGPT Image Jun 30, 2026` 四张架构/验证示意图

## 2. 一句话概括

`fdma_aurora_brg` 是一个双向桥接 IP，用于把 FPGA 内部 FDMA 读写接口与 Aurora 64B/66B LocalLink 数据接口连接起来。发送方向将 FDMA 读出的 64 bit 数据缓存、跨时钟、封装成 LocalLink 帧并送入 Aurora；接收方向从 Aurora/LocalLink 接收数据，经 RX 异步 FIFO 缓冲后，以 FDMA 写突发写回存储空间。

在验证场景中，该设计通过物理或仿真的 Aurora 自环回，把“FDMA 读出 -> Aurora 发送 -> Aurora 接收 -> FDMA 写回”构成一条闭环数据链路，并通过逐级监控和端到端比对确认数据顺序、地址推进、帧标记和握手机制正确。

## 3. 设计目标

本 IP 的核心目标包括：

1. 实现 FDMA 与 Aurora LocalLink 之间的双向协议转换。
2. 通过异步 FIFO 解决 FDMA 时钟域与 Aurora user 时钟域之间的跨时钟数据传输。
3. 支持 FDMA 侧 512 字节突发读写，地址按 512 字节步进并在 4 KB 测试空间内回绕。
4. 通过 ready/valid 类握手机制支持读写方向的流控。
5. 提供仿真验证和硬件调试两套互相对应的验证路径。

## 4. 总体架构

设计顶层以 `fdma_aurora_brg_aurora_loop` 为完整环路封装，内部主要包含三类功能块：

- `fdma_aurora_brg_top`：FDMA 与 LocalLink 的桥接核心，内部包括 TX 桥和 RX 桥。
- `aurora_64b66b_top`：Xilinx Aurora 64B/66B IP 封装，完成 LocalLink/AXI-Stream 转换、64B/66B 编解码和 GT 收发。
- `cdc_sync` 与 `ila_brg_loop`：分别用于 `channel_up` 跨域同步和 ILA 调试信号封装。

### 图 1 DUT 设计架构图

![图1 DUT 设计架构图](./ChatGPT%20Image%20Jun%2030%2C%202026%2C%2004_12_36%20PM%20%281%29.png)

图 1 展示了 DUT 的完整设计分层。左侧是 FDMA 读写接口所在的 `fdma_clk` 域，右侧大部分逻辑位于 Aurora `user_clk` 域。TX 路径以橙色标识，数据从 FDMA 读接口进入 `fdma_aurora_brg_tx`，经异步 TX FIFO 跨到 user 时钟域，再封装成 LocalLink TX 帧送入 Aurora。RX 路径以紫色标识，数据从 Aurora RX 返回后进入 `fdma_aurora_brg_rx`，写入异步 RX FIFO，再跨回 FDMA 时钟域并通过 FDMA 写接口输出。图中还标出了 `channel_up` 经 `cdc_sync` 同步后作为 FDMA 侧状态机启动条件，说明链路建立信号是数据启动的前置条件。

## 5. 发送方向数据流

发送方向完成 FDMA 到 LocalLink/Aurora 的转换，主要流程如下：

1. TX 读状态机在 `channel_up_fdma` 有效、TX FIFO 未达到 almost_full 条件时发起 FDMA 读请求。
2. FDMA 读从机响应 `rareq/rbusy` 后，通过 `rvalid/rready` 握手返回 64 bit 数据。
3. 每完成一次真实握手，TX 桥将数据写入异步 TX FIFO。
4. TX FIFO 写侧在 `fdma_clk` 域，读侧在 `user_clk` 域，完成跨时钟缓存。
5. LocalLink TX 状态机从 FIFO 读出数据，生成 `tx_sof/tx_eof/tx_rem/tx_src_rdy` 等帧控制信号。
6. Aurora IP 将 LocalLink/AXI-Stream 数据进一步编码，通过 GT TX 发出。

发送方向的关键控制点是 TX FIFO 水位。FDMA 侧原始吞吐高于 Aurora user 侧，因此 TX FIFO 需要通过 almost_full 提前反压 FDMA 读侧，使 `fdma_rready` 拉低，防止继续写入。

## 6. 接收方向数据流

接收方向完成 Aurora/LocalLink 到 FDMA 的转换，主要流程如下：

1. Aurora RX 解码后的数据经 AXI2LL 转换为 LocalLink RX 信号。
2. RX 桥在 `rx_src_rdy` 有效且 FIFO 可写时，将 64 bit 数据写入异步 RX FIFO。
3. RX FIFO 写侧在 `user_clk` 域，读侧在 `fdma_clk` 域。
4. FDMA 写状态机按 512 字节突发读取 FIFO 数据，并发起 FDMA 写请求。
5. 每完成 `wvalid && wready` 握手，写侧推进一个 64 bit 数据字，直到完成一个 burst。

## 7. 时钟、复位与跨域

设计中主要涉及三个时钟：

| 时钟 | 典型频率 | 作用 |
|---|---:|---|
| `fdma_clk` | 250 MHz | FDMA 读写接口、TX 读引擎、RX 写引擎 |
| `user_clk` | 156.25 MHz | LocalLink/Aurora 用户侧数据处理 |
| `clk_init` | 50 MHz | Aurora/GT 初始化相关逻辑 |

跨时钟处理主要由异步 FIFO 和同步器完成：

- TX FIFO：`fdma_clk` 写入，`user_clk` 读出。
- RX FIFO：`user_clk` 写入，`fdma_clk` 读出。
- `channel_up`：由 Aurora 用户侧产生，经 `cdc_sync` 两级同步到 FDMA 时钟域。

复位方面，FDMA 侧和 user 侧分别使用各自低有效复位信号。FIFO 复位忙信号需要参与读写门控，避免复位释放过程中的无效访问。

## 8. 关键模块分工

| 模块 | 位置 | 主要职责 |
|---|---|---|
| `fdma_aurora_brg_tx` | 桥接核心 TX 侧 | 发起 FDMA 读、写 TX FIFO、生成 LocalLink TX 帧 |
| `fdma_aurora_brg_rx` | 桥接核心 RX 侧 | 接收 LocalLink RX、写 RX FIFO、发起 FDMA 写 |
| `fdma_aurora_brg_top` | 桥接核心顶层 | 组合 TX/RX 两个方向的数据桥 |
| `aurora_64b66b_top` | Aurora 封装 | LocalLink/AXIS 转换、64B/66B 编解码、GT 收发 |
| `cdc_sync` | 跨域同步 | 将 `channel_up` 同步到 FDMA 时钟域 |
| `fdma_hw_test_engine` | 硬件调试模式 | 在板上生成/检查 FDMA 数据流 |
| `ila_brg_loop` | 调试观测 | 封装 ILA 探针，观察关键内部信号 |

## 9. 仿真验证平台

SV 仿真平台不采用 UVM，而是使用轻量级 SystemVerilog class、interface、BFM、monitor 和 scoreboard 组成。平台主要由以下部分构成：

- `tc_if.sv`：定义 FDMA 读接口、FDMA 写接口、LocalLink 监控接口、控制接口和观测接口。
- `tc_base.sv`：提供随机计划生成、读写 BFM、监控器、9 级队列记分板和公共运行流程。
- `aurora_loop_harness.sv`：完整 Aurora/GT 环回验证环境。
- `brg_harness.sv`：直接桥接验证环境，用于 FIFO 水线、ready 停顿和 RX 注入等定向测试。
- `tc_*` 测试用例：通过继承 `tc_base`，覆盖不同测试场景。

### 图 2 验证环境与数据流总图

![图2 验证环境与数据流总图](./ChatGPT%20Image%20Jun%2030%2C%202026%2C%2004_12_36%20PM%20%282%29.png)

图 2 把仿真验证环境和 DUT 数据通路放在同一张图中。左侧是 SV 测试平台，`tc_base/test` 负责 `configure -> build_plan -> initialize -> fork BFM/monitor -> wait_channel_up -> check_results` 的生命周期管理；组件区包含随机化引擎、读写 BFM、FDMA/LL 监控器和记分板。右侧是 DUT 的 TX/RX 桥和 Aurora 环路。图下半部分是数据比对链路：`expected_q`、FDMA 读握手队列、TX FIFO 队列、LL TX/RX 队列、RX FIFO 队列和 FDMA 写握手队列按顺序比较，同时读写地址队列单独进行回绕检查。这张图说明平台不仅做端到端比对，也能定位首个出错边界。

## 10. 测试用例组织

当前 IT 验证方案覆盖 7 个主要用例：

| 用例 | 验证环境 | 关注点 |
|---|---|---|
| `tc_aurora_loop_nobp` | `aurora_loop_harness` | 无反压端到端数据通路 |
| `tc_aurora_loop_bp` | `aurora_loop_harness` | 随机反压、空拍、响应延迟 |
| `tc_aurora_loop_addr_wrap` | `aurora_loop_harness` | 4 KB 地址空间 512 B 步进回绕 |
| `tc_brg_rd_ready_stall` | `brg_harness` | FDMA 读侧 `rready` 停顿 |
| `tc_brg_wr_ready_stall` | `brg_harness` | FDMA 写侧 `wready` 停顿与数据保持 |
| `tc_brg_tx_fifo_waterline` | `brg_harness` | TX FIFO almost_full 水线与反压 |
| `tc_brg_rx_fifo_overflow` | `brg_harness` | RX FIFO 满载边界观测 |

这些用例分为两类：完整环回用例验证桥接 IP 与 Aurora IP 组合后的端到端行为；直接桥用例跳过 Aurora，用更可控的环境覆盖 FIFO、ready 停顿和定向注入场景。

### 图 2-2 测试用例类封装与多态关系

![图2-2 测试用例类封装与多态关系](./ChatGPT%20Image%20Jun%2030%2C%202026%2C%2004_12_39%20PM%20%283%29.png)

图 2-2 展示了 SV 测试用例的类继承与多态组织方式。`tc_base` 是公共基类，封装随机化引擎、FDMA 读写 BFM、监控器、9 级队列记分板和固定 `run()` 主流程。不同子类只覆盖必要钩子，例如 `configure()` 设置帧数和是否启用反压，`pre_start()` 提前拉低 `tx_dst_rdy`，`after_channel_up()` 等待 FIFO 水线，或直接重写 `run()` 处理特殊注入场景。图中“框架固定，差异填空”概括了该平台的核心思想：公共流程稳定复用，测试差异通过少量虚函数注入。

## 11. 记分板与比对机制

仿真平台的核心是逐级队列记分板。平台在每个协议边界采集一份数据队列，仿真结束后按通路顺序逐级比较：

```text
expected_q
  -> fdma_rd_hs_q
  -> tx_fifo_wr_q
  -> tx_fifo_rd_q
  -> ll_tx_q
  -> ll_rx_q
  -> rx_fifo_wr_q
  -> rx_fifo_rd_q
  -> fdma_wr_hs_q
```

该机制有三个作用：

1. 验证最终写回数据与期望数据一致。
2. 判断数据错位、丢字、重复或损坏发生在哪一级边界。
3. 配合地址队列和帧计数，覆盖地址推进、SOF/EOF/rem 标记和半帧残留。

地址检查独立比较 FDMA 读地址队列和写地址队列，期望序列为 `0x000 -> 0x200 -> 0x400 -> ... -> 0xE00 -> 0x000`。

## 12. 随机化与可复现

测试平台使用 seed 驱动随机化。`resolve_seed()` 解析命令行 `+SEED=`，未提供时自动生成 seed 并打印；随机数由 LCG 生成，所有帧数据和延迟计划都由同一 seed 派生。

随机计划主要包含：

- 每帧读请求接受延迟。
- 每帧写请求接受延迟。
- 读 burst 间隔。
- 写 burst 间隔。
- 每个 word 的 `rvalid` 空拍。
- 每个 word 的 `wready` 停顿。

同一个 seed 可复现相同数据、相同空拍和相同反压分布，便于回归失败后的定位。

## 13. 硬件调试模式

硬件调试模式用可综合 RTL 替代 SV BFM，在真实 FPGA 上运行闭环测试。核心模块是 `fdma_hw_test_engine`，它在板上生成确定性数据 `{frame, word}`，同时接收写回数据并进行实时比较。

硬件模式的主要组成包括：

- 读 FSM：产生 FDMA 读侧数据源和 `rareq/rready` 交互。
- 写 FSM：接收 FDMA 写侧数据并做实时比对。
- 测试编排 FSM：管理 IDLE、RUNNING、DONE 等状态。
- 计数器与首错锁存：统计 word 数、错误数，并锁存首次错误的期望值、实际值和位置。
- VIO：提供 start、clear、auto、limit 等在线控制。
- ILA：采集 FDMA、LocalLink、FIFO 和状态机相关信号。

### 图 3 硬件调试模式数据流图

![图3 硬件调试模式数据流图](./ChatGPT%20Image%20Jun%2030%2C%202026%2C%2004_12_43%20PM%20%284%29.png)

图 3 展示了硬件调试模式如何与仿真模式对齐。左侧是可综合硬件调试环境，`fdma_hw_test_engine` 负责生成期望数据、驱动 FDMA 读、接收 FDMA 写并实时比对；VIO 通过 JTAG 下发启动、清除、自动运行和帧数限制控制，ILA 采集 `dbg_bus` 与 `status_bus`。右侧是与仿真一致的 DUT 数据通路，包括 TX 桥、Aurora 物理自环回、RX 桥和 ILA 观测封装。图底部用编号标出硬件数据流：期望数据经 FDMA 读握手进入 TX FIFO，经过 LL TX、GT 物理自环、LL RX 后，最终由 FDMA 写握手返回并实时比对。

## 14. SV 仿真与硬件调试的对应关系

| 验证维度 | SV 仿真模式 | 硬件调试模式 |
|---|---|---|
| 数据源 | LCG 随机 64 bit 数据 | `{frame, word}` 确定性数据 |
| 驱动方式 | BFM task 驱动 FDMA 读写接口 | 可综合 `fdma_hw_test_engine` |
| 比对方式 | 多级队列离线逐级比对 | 硬件实时比对与首错锁存 |
| 观测方式 | monitor 队列、日志、波形 | ILA、VIO、计数器 |
| 反压注入 | 随机延迟和定向 stall | 板上真实时序与可控帧数 |
| 运行环境 | Vivado XSim | FPGA 实板 |

这种双轨结构让仿真侧负责高可见性和高可控性，硬件侧负责真实链路、真实时钟和真实 GT 物理路径验证。

## 15. 主要参数速查

| 参数 | 值 | 说明 |
|---|---:|---|
| 数据位宽 | 64 bit | FDMA、LocalLink、AXI-Stream 用户数据统一宽度 |
| FDMA burst | 512 B | 64 个 64 bit word |
| 测试地址空间 | 4 KB | 地址按 512 B 步进并回绕 |
| TX FIFO 深度 | 512 word | FDMA 到 Aurora 方向跨域缓存 |
| TX almost_full 阈值 | 448 word | 用于提前反压 FDMA 读侧 |
| RX FIFO 深度 | 2048 word | Aurora 到 FDMA 方向跨域缓存 |
| RX almost_full 阈值 | 2032 word | 用于满载边界观测 |
| FDMA 时钟 | 250 MHz | FDMA 读写接口侧 |
| Aurora user 时钟 | 156.25 MHz | LocalLink/Aurora 用户侧 |
| GT 参考时钟 | 156.25 MHz | Aurora GT 参考 |

## 16. 资料对应关系

| 资料 | 在本文中的用途 |
|---|---|
| `fdma_aurora_brg IP设计.docx` | 设计背景、接口、TX/RX 子模块、FIFO、CDC、复位和参数 |
| `fdma_aurora_brg IP  IT验证1.docx` | IT 验证对象、平台、用例、通过标准和回归组织 |
| `SV测试平台模式数据流详解.md` | SV 平台生命周期、随机计划、BFM、monitor、9 级队列 |
| `SV测试平台文件类函数详解.md` | 文件组织、类封装、函数职责、测试点矩阵 |
| `设计核心要素概览.md` | 面向非 FPGA 专业人员的总体解释和关键术语 |
| 四张 `ChatGPT Image Jun 30` 图片 | 设计架构、仿真验证、用例多态和硬件调试模式图示 |
