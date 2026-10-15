# SV测试平台文件类函数详解

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\SV测试平台文件类函数详解.md`
- SHA-256: `98af2b7cad63e93bb28ed6af1054111560f248c887acca8cc4f746956b85f971`
- Extractor: `text`
- Tags: `aurora, fdma, pcie, verification`
- Duplicate sources:
  - none

# SV 测试平台文件/类/函数逐个详解

> 本文档逐文件、逐类、逐函数解释 `sources_1 - loop_validate/new` 目录下 SV 测试平台的全部源码，覆盖接口定义、harness、基类、测试用例与单元测试。

> **代码定位约定**：本文所有行号引用均基于 `sources_1 - loop_validate-6-24-afternoon/sources_1 - loop_validate/new/` 目录下最新代码，格式为 `[文件名#L起-L止]`，可点击跳转。语义描述与代码注释句子一一对应。

---

## 目录结构总览

```
new/
├── tc/
│   ├── tc_if.sv                       # 接口定义层（5 个 interface）
│   ├── tc_base.sv                     # 验证核心包（tc_base 类 + 工具函数）
│   ├── tc_aurora_loop_nobp.sv         # 完整环回无反压测试
│   ├── tc_aurora_loop_bp.sv           # 完整环回带反压测试
│   ├── tc_aurora_loop_addr_wrap.sv    # 地址回绕覆盖测试
│   ├── tc_brg_rd_ready_stall.sv       # 读侧 rready 拉低定向测试
│   ├── tc_brg_wr_ready_stall.sv       # 写侧 wready 拉低定向测试
│   ├── tc_brg_tx_fifo_waterline.sv    # TX FIFO 几乎满水位测试
│   ├── tc_brg_rx_fifo_overflow.sv     # RX FIFO 溢出测试
│   └── tc_list                        # 回归测试列表（7 个测试名）
├── harness/
│   ├── brg_harness.sv                 # 直接桥测试平台（无 Aurora 核）
│   └── aurora_loop_harness.sv         # 完整环回测试平台（含 Aurora + GT 自环）
├── tb_fdma_hw_test_engine.sv          # fdma_hw_test_engine 单元测试
└── （DUT 与硬件调试文件略）
```

---

## 一、tc/tc_if.sv — 接口定义层

本文件定义 5 个 `interface`，是 harness、DUT、BFM、监控器之间的信号束契约。全文 [tc_if.sv#L1-L132](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L1-L132)。

### 1.1 `fdma_read_if`

**作用**：FDMA 读侧信号束，BFM 驱动 `rbusy/rdata/rvalid`，DUT 驱动 `raddr/rareq/rready`。定义于 [tc_if.sv#L4-L29](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L4-L29)。

| 成员 | 类型 | 说明 |
|------|------|------|
| `raddr[31:0]` | logic | DUT 选择的 512B burst 字节地址 |
| `rareq` | logic | DUT 请求，保持至从机拉高 `rbusy` |
| `rbusy` | logic | BFM 响应：1=事务进行中 |
| `rdata[63:0]` | logic | BFM 提供的读数据 |
| `rvalid` | logic | BFM 声明 `rdata` 有效 |
| `rready` | logic | DUT 声明可接收 `rdata` |

**`clocking cb`**：`@(posedge clk)` + `default #1step`，在时钟沿前后立即采样/驱动，消除 SV 与 DUT 时序竞争。`input raddr/rareq/rready`（DUT 输出），`output rbusy/rdata/rvalid`（BFM 输出）。

**`modport dut`**：声明 DUT 侧方向约束（`output raddr/rareq/rready, input rbusy/rdata/rvalid`）。

### 1.2 `fdma_write_if`

**作用**：FDMA 写侧信号束，BFM 驱动 `wbusy/wready`，DUT 驱动 `waddr/wareq/wdata/wvalid/wsize`。定义于 [tc_if.sv#L32-L57](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L32-L57)。

| 成员 | 类型 | 说明 |
|------|------|------|
| `waddr[31:0]` | logic | DUT 写 burst 字节地址 |
| `wareq` | logic | DUT 写请求 |
| `wbusy` | logic | BFM 响应 |
| `wdata[63:0]` | logic | DUT 写数据 |
| `wvalid` | logic | DUT 声明 `wdata` 有效 |
| `wsize[15:0]` | logic | 请求字节数（期望 512） |
| `wready` | logic | BFM 声明可接收 |

`clocking cb` 与 `modport dut` 同读接口模式。

### 1.3 `ll_link_if`

**作用**：LocalLink 信号束，观察桥与 Aurora 边界的 TX/RX 信号。定义于 [tc_if.sv#L60-L84](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L60-L84)。

| 成员 | 说明 |
|------|------|
| `tx_d/tx_sof/tx_eof/tx_rem/tx_src_rdy/tx_dst_rdy` | 桥→Aurora TX 侧 |
| `rx_d/rx_sof/rx_eof/rx_rem/rx_src_rdy/rx_dst_rdy` | Aurora→桥 RX 侧 |

**`clocking mon_cb`**：仅 `input #1step`，监控专用（不驱动），用于 LL 帧标记检查与数据采集。

### 1.4 `brg_ctrl_if`

**作用**：验证专用控制信号束，仅 `brg_harness` 实现，用于定向故障注入。定义于 [tc_if.sv#L87-L98](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L87-L98)。

| 成员 | 说明 |
|------|------|
| `force_tx_almost_full` | 强制 TX FIFO `almost_full` 为 1（`tc_brg_rd_ready_stall` 用） |
| `can_drive_tx_dst_rdy` | 1=`brg_harness` 可驱动 `tx_dst_rdy`；0=Aurora 核拥有 |
| `rx_loopback_enable` | 1=TX→RX 正常环回；0=直接 RX 注入 |
| `rx_drive_d/sof/eof/rem/src_rdy` | 直接 RX 注入的载荷与控制 |

### 1.5 `brg_obs_if`

**作用**：只读 DUT 内部探针，供监控器/检查器采样状态机、FIFO 计数、溢出标志。定义于 [tc_if.sv#L101-L132](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_if.sv#L101-L132)。

| 分组 | 成员 |
|------|------|
| 状态 | `is_full_loop/channel_up/lane_up/user_rstn` |
| TX 桥 | `tx_rd_state/tx_state/tx_rd_word_cnt/tx_word_cnt` |
| TX FIFO | `tx_fifo_wr_en/rd_en/wdata/rdata/wr_cnt/rd_cnt/overflow/underflow/almost_full/almost_empty/full/empty` |
| RX 桥 | `rx_wr_state/rx_wr_word_cnt/rx_wdata_hold_valid` |
| RX FIFO | `rx_fifo_wr_en/rd_en/wdata/rdata/wr_cnt/rd_cnt/overflow/underflow/almost_full/full/empty` |

**`clocking user_cb`**：`@(posedge user_clk)`，用于 RX FIFO 边界测试避免 NBA 竞争。

---

## 二、harness/brg_harness.sv — 直接桥测试平台

**作用**：例化 `fdma_aurora_brg_top`（仅桥，无 Aurora 核），提供可控 LL 环回/注入，用于 FIFO 边界与反压定向测试。全文 [brg_harness.sv#L1-L144](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/harness/brg_harness.sv#L1-L144)。

### 关键成员/逻辑

| 成员/段 | 行号 | 作用 |
|---------|------|------|
| `fdma_clk`/`user_clk` | L17-L22 | 独立时钟（250MHz/156.25MHz），exercise 异步 FIFO |
| `fdma_rstn`/`user_rstn` | L25-L33 | 复位序列：20 个 fdma_clk 后释放 |
| `channel_up` | L41-L51 | 合成就绪标志，4 拍同步后拉高 |
| `rd_if/wr_if/ll_if/ctrl_if/obs_if` | L35-L39 | 5 个接口实例 |
| `ll_if.tx_dst_rdy=1` | L48 | 默认接受 TX |
| `ctrl_if.rx_loopback_enable=1` | L49 | 默认 TX→RX 环回 |
| `assign ll_if.rx_*` | L87-L93 | 环回选择：`rx_loopback_enable` 为 1 时 `rx=tx`，否则 `rx=rx_drive_*` |
| `force dut.u_..._tx.fifo_almost_full` | L96-L101 | `force_tx_almost_full` 触发时强制 DUT 内部信号 |
| `assign obs_if.*` | L104-L143 | 层次化引用 DUT 内部信号到观察接口 |

---

## 三、harness/aurora_loop_harness.sv — 完整环回测试平台

**作用**：例化 `fdma_aurora_brg_aurora_loop`（桥 + Aurora IP + GT 物理自环），用于端到端功能验证。全文 [aurora_loop_harness.sv#L1-L153](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/harness/aurora_loop_harness.sv#L1-L153)。

### 关键成员/逻辑

| 成员/段 | 行号 | 作用 |
|---------|------|------|
| `fdma_clk/init_clk/gt_ref_clk_n` | L20-L27 | 3 个时钟（250M/50M/156.25M） |
| `gt_ref_clk_p = ~gt_ref_clk_n` | L25 | 差分参考时钟正端 |
| `rxp=txp, rxn=txn` | L30-L37 | GT 物理自环回（SFP 短接） |
| `sys_rst` 复位序列 | L30-L37 | 160 个 init_clk 后释放，满足 Aurora 仿真复位时间 |
| `fdma_rstn` | L45-L55 | `sys_rst` 释放后 60ns 释放桥复位 |
| `dut.SIMULATION=1` | L62 | 加速 Aurora 初始化（硅片模式为 0） |
| `assign ll_if.*` | L94-L105 | 通过 `dut.ll_tx_*` 层次引用观察 LL 边界 |
| `assign obs_if.*` | L108-L152 | 通过 `dut.u_fdma_aurora_brg_top.u_..._tx/rx.*` 引用内部信号 |
| `ctrl_if.can_drive_tx_dst_rdy=0` | L52 | Aurora 核拥有 `tx_dst_rdy`，测试平台不可驱动 |

---

## 四、tc/tc_base.sv — 验证核心包

**作用**：定义 `package fdma_aurora_brg_tb_pkg`，包含协议常量、工具函数、`tc_base` 基类（BFM/监控器/记分板/生命周期）。全文 [tc_base.sv#L1-L741](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L1-L741)。

### 4.1 包级常量

定义于 [tc_base.sv#L9-L15](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L9-L15)。

| 常量 | 值 | 说明 |
|------|----|------|
| `WORD_BYTES` | 8 | 一个 word 8 字节 |
| `FRAME_WORDS` | 64 | 一帧 64 word |
| `BURST_WORDS` | 64 | 一个 burst 64 word |
| `FDMA_BURST_BYTES` | 512 | burst 字节数 |
| `TEST_MEM_SIZE_BYTES` | 4096 | 地址回绕边界 |
| `DEFAULT_SEED` | 260622 | GUI 默认种子 |

### 4.2 类型定义

定义于 [tc_base.sv#L17-L18](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L17-L18)。

| 类型 | 说明 |
|------|------|
| `data_queue_t` | `logic[63:0][$]`，有序数据队列 |
| `addr_queue_t` | `logic[31:0][$]`，地址队列 |

### 4.3 包级函数

#### `resolve_seed(output string seed_source) → int unsigned`
[tc_base.sv#L21-L33](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L21-L33)。解析 `+SEED=` plusarg；无则用 `$urandom_range(1,999999)` 自动生成 6 位十进制种子。`seed_source` 返回 `"PLUSARG"` 或 `"AUTO"`，用于日志复现。

#### `resolve_verbose() → int unsigned`
[tc_base.sv#L35-L42](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L35-L42)。解析 `+VERBOSE=` plusarg，默认 1；>2 则 `$fatal`。0=摘要，1=帧/burst 级，2=每次握手。

### 4.4 `tc_base` 类

类声明 [tc_base.sv#L44](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L44)。

#### 4.4.1 可配置随机延迟参数（`cfg_*`）

[tc_base.sv#L49-L62](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L49-L62)。

| 参数 | 默认 | 说明 |
|------|------|------|
| `cfg_rd_accept_delay_min/max/prob` | 1/8/30 | rareq→rbusy 响应延迟 |
| `cfg_wr_accept_delay_min/max/prob` | 1/8/30 | wareq→wbusy 响应延迟 |
| `cfg_rd_inter_burst_gap_min/max/prob` | 1/8/30 | 读 burst 间间隔 |
| `cfg_wr_inter_burst_gap_min/max/prob` | 1/8/30 | 写 burst 间间隔 |
| `cfg_rd_valid_gap_min/max/prob` | 1/4/20 | rvalid 低电平间隔 |
| `cfg_wr_ready_stall_min/max/prob` | 1/4/20 | wready 低电平持续 |

#### 4.4.2 成员变量

[tc_base.sv#L64-L107](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L64-L107)。

| 分组 | 成员 |
|------|------|
| 标识 | `test_name/seed/rng_state/verbose` |
| 规模 | `num_frames/total_words` |
| 开关 | `enable_backpressure/stop_requested` |
| 标志 | `fdma_x_reported/ll_x_reported` |
| 计数 | `error_count` |
| 接口句柄 | `rd_vif/wr_vif/ll_vif/ctrl_vif/obs_vif` |
| 数据队列 | `expected_q/fdma_rd_hs_q/tx_fifo_wr_q/tx_fifo_rd_q/ll_tx_q/ll_rx_q/rx_fifo_wr_q/rx_fifo_rd_q/fdma_wr_hs_q` |
| 地址队列 | `fdma_rd_addr_q/fdma_wr_addr_q` |
| 延迟数组 | `rd_accept_delay[]/wr_accept_delay[]/rd_inter_burst_gap[]/wr_inter_burst_gap[]/rd_valid_gap[]/wr_ready_stall[]` |
| 帧计数 | `tx_frame_word_count/rx_frame_word_count/tx_frame_count/rx_frame_count` |
| FIFO 峰值 | `tx_fifo_peak/rx_fifo_peak` |

#### 4.4.3 方法详解

##### `new(name, seed_i, verbose_i, rd/wr/ll/ctrl/obs_vif_i)`
[tc_base.sv#L109-L128](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L109-L128)。构造函数：保存名字、种子（0 用 DEFAULT_SEED）、verbose、绑定 5 个 virtual interface，初始化 `enable_backpressure=0/stop_requested=0/error_count=0`。

##### `next_rand() → int unsigned`
[tc_base.sv#L131-L134](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L131-L134)。LCG 随机数：`rng_state = rng_state*1664525 + 1013904223`（Numerical Recipes），返回新状态。同一种子产生同一序列。

##### `rand_range(low, high) → int unsigned`
[tc_base.sv#L136-L140](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L136-L140)。返回 `[low, high]` 闭区间随机数。

##### `choose_delay(prob, min, max) → int unsigned`
[tc_base.sv#L143-L153](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L143-L153)。
- `enable_backpressure=0` 或 `prob=0` 返回 0；
- 否则以 `prob%` 概率返回 `[min,max]` 随机延迟。

##### `configure()` [virtual]
[tc_base.sv#L155-L158](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L155-L158)。派生类覆盖：设置 `num_frames` 与 `enable_backpressure`。基类默认 1-3 帧无反压。

##### `pre_start()` [virtual task]
[tc_base.sv#L161-L164](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L161-L164)。生命周期钩子：BFM 启动前执行（如 `tc_brg_tx_fifo_waterline` 在此拉低 `tx_dst_rdy`）。

##### `after_channel_up()` [virtual task]
[tc_base.sv#L165-L168](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L165-L168)。`channel_up` 后执行（如 `tc_brg_tx_fifo_waterline` 在此等待 `almost_full`）。

##### `apply_directed_plan()` [virtual function]
[tc_base.sv#L169-L170](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L169-L170)。`build_random_plan` 末尾调用，派生类覆盖以修改随机计划（如 `tc_brg_wr_ready_stall` 注入 3 个 stall 点）。

##### `on_read_word_presented(global_word_index)` [virtual task]
[tc_base.sv#L171-L172](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L171-L172)。每个读 word 呈现时回调（如 `tc_brg_rd_ready_stall` 在选定 word 注入 `force_tx_almost_full`）。

##### `build_random_plan()`
[tc_base.sv#L175-L218](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L175-L218)。
- 计算 `total_words = num_frames * FRAME_WORDS`；
- 清空 `expected_q`，分配 6 个延迟数组；
- 生成 `total_words` 个随机 64bit 数据入 `expected_q`；
- 为每帧选 4 种 burst 级延迟，每 word 选 2 种 word 级延迟；
- 末尾调 `apply_directed_plan()`。

##### `record_error(message)`
[tc_base.sv#L220-L223](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L220-L223)。`error_count++` 并 `$error` 打印时间戳/测试名/消息。

##### `initialize_drivers()`
[tc_base.sv#L226-L242](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L226-L242)。驱动所有 TB 信号到 idle：`rbusy=0/rdata=0/rvalid=0/wbusy=0/wready=0`，清 ctrl 信号，`tx_dst_rdy=1`。

##### `wait_for_channel_up()`
[tc_base.sv#L244-L256](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L244-L256)。循环等待 `obs_vif.channel_up`，超时 500000 周期记错。

##### `fdma_read_slave()` [task]
[tc_base.sv#L259-L318](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L259-L318)。读 BFM 主循环：
1. 等待 `rareq && !rbusy`，捕获地址入 `fdma_rd_addr_q`；
2. 插入 `rd_accept_delay` 后拉高 `rbusy`；
3. 循环 64 word：插入 `rd_valid_gap`，驱动 `rdata/rvalid`，等握手，调 `on_read_word_presented`；
4. 插入 `rd_inter_burst_gap` 后释放 `rbusy`，进入下一 burst；
5. 完成所有帧后 `while(!stop_requested)` 挂起。

##### `check_write_data_stable(stall_cycles)` [task]
[tc_base.sv#L320-L336](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L320-L336)。`wready` 拉低期间检查 `wvalid` 不掉、`wdata` 不变，验证 AXI 稳定性协议。

##### `fdma_write_slave()` [task]
[tc_base.sv#L339-L389](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L339-L389)。写 BFM 主循环：
1. 等待 `wareq && !wbusy`，捕获地址，检查 `wsize==512`；
2. 插入 `wr_accept_delay` 后拉高 `wbusy`；
3. 循环 64 word：查 `wr_ready_stall`，为 0 直接 `wready=1`，否则 `wready=0` + `check_write_data_stable` + `wready=1`，等握手；
4. 插入 `wr_inter_burst_gap` 后释放 `wbusy/wready`。

##### `monitor_fdma_and_fifos()` [task]
[tc_base.sv#L392-L445](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L392-L445)。fdma_clk 域监控（forever）：
- X/Z 检测（FDMA 控制信号/数据）；
- 读握手采集入 `fdma_rd_hs_q`，TX FIFO 写采集入 `tx_fifo_wr_q`；
- RX FIFO 读采集入 `rx_fifo_rd_q`，写握手采集入 `fdma_wr_hs_q`；
- 更新 `tx_fifo_peak/rx_fifo_peak`；
- 检测 FIFO overflow/underflow。

##### `check_frame_markers(direction, word_in_frame, sof, eof, rem)` [task]
[tc_base.sv#L447-L461](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L447-L461)。检查 LL SOF/EOF 出现位置是否正确（word 0 必须 SOF，word 63 必须 EOF，EOF 时 rem 必须为 111）。

##### `monitor_ll_and_rx_fifo()` [task]
[tc_base.sv#L464-L523](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L464-L523)。user_clk 域监控（forever）：
- X/Z 检测（LL 控制信号）；
- TX 握手采集入 `ll_tx_q` + 帧标记检查 + `tx_frame_word_count/tx_frame_count` 更新；
- TX FIFO 读采集入 `tx_fifo_rd_q`；
- RX 握手采集入 `ll_rx_q` + 帧标记检查 + `rx_frame_word_count/rx_frame_count` 更新；
- RX FIFO 写采集入 `rx_fifo_wr_q` + `rx_fifo_peak` 更新。

##### `wait_for_completion()` [task]
[tc_base.sv#L525-L540](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L525-L540)。等待 `fdma_wr_hs_q.size() >= total_words`，超时 500000（完整环回）或 100000（直接桥）周期记错；完成后额外等 100 个 LL 周期。

##### `compare_data_queues(lhs_name, lhs, rhs_name, rhs)` [task]
[tc_base.sv#L542-L573](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L542-L573)。
- 长度不等记错；
- 逐 word 比对，首个不匹配记错（仅报一次）；
- 打印 PASS/FAIL 摘要。

##### `check_addresses()` [task]
[tc_base.sv#L575-L605](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L575-L605)。
- 检查读/写地址队列长度等于 `num_frames`；
- 期望地址从 0 开始，每次 +512，到 4096 回绕到 0；
- 逐个比对实际地址。

##### `check_results()` [task]
[tc_base.sv#L608-L627](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L608-L627)。端到端记分板：9 级队列比对
```
expected_q → fdma_rd_hs_q → tx_fifo_wr_q → tx_fifo_rd_q
→ ll_tx_q → ll_rx_q → rx_fifo_wr_q → rx_fifo_rd_q → fdma_wr_hs_q
```
外加 `expected_q → fdma_wr_hs_q` 端到端比对、`check_addresses`、帧计数检查。

##### `print_configuration()` [task]
[tc_base.sv#L629-L677](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L629-L677)。打印测试配置：种子、帧数、word 数、各延迟参数、每帧延迟、有延迟的 word。

##### `run()` [virtual task]
[tc_base.sv#L680-L706](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L680-L706)。生命周期主流程：
1. `configure()` → `build_random_plan()` → `initialize_drivers()` → `print_configuration()` → `pre_start()`；
2. `fork` 启动 4 个并发任务（读 BFM/写 BFM/2 个监控器）`join_none`；
3. `wait_for_channel_up()` → `after_channel_up()`；
4. `error_count==0` 时 `wait_for_completion()`；
5. `stop_requested=1`，等 4 拍，`disable fork`；
6. `check_results()` + 打印 FIFO 峰值/帧计数/PASS/FAIL。

---

## 五、测试用例文件

### 5.1 tc_aurora_loop_nobp.sv

**`package tc_aurora_loop_nobp_pkg`**：命名空间隔离。

**`class tc_aurora_loop_nobp extends tc_base`**：
- `new()`：调 `super.new("tc_aurora_loop_nobp", ...)` 绑定接口。
- `configure()`：`num_frames=rand_range(1,3)`，`enable_backpressure=0`（无反压冒烟测试）。

**`module tc_aurora_loop_nobp_top`**：
- 例化 `aurora_loop_harness h()`；
- `initial`：`resolve_seed/verbose`，构造类，`test.run()`，失败 `$fatal`。

### 5.2 tc_aurora_loop_bp.sv

**`class tc_aurora_loop_bp extends tc_base`**：
- `configure()`：`num_frames=rand_range(1,3)`，`enable_backpressure=1`（启用所有 `cfg_*` 随机延迟）。

其余结构与 `tc_aurora_loop_nobp` 相同。

### 5.3 tc_aurora_loop_addr_wrap.sv

**`class tc_aurora_loop_addr_wrap extends tc_base`**：
- `configure()`：`num_frames=rand_range(9,12)`（至少跨过一次 0xE00→0 地址回绕，因 4096/512=8 个 burst 后回绕）。

### 5.4 tc_brg_rd_ready_stall.sv

**`class tc_brg_rd_ready_stall extends tc_base`**：
- 成员：`stall_word/stall_cycles`。
- `apply_directed_plan()`：随机选 `stall_word=rand_range(8,total_words-8)`，`stall_cycles=rand_range(2,5)`。
- `on_read_word_presented(global_word_index)`：当选定 word 呈现时，`force_tx_almost_full=1` 强制 DUT `rready=0`，循环 `stall_cycles` 拍检查：`rready` 必须为 0、TX FIFO 不写、`rd_word_cnt` 不推进；之后释放。
- 使用 `brg_harness`（直接桥，可控 `force`）。

### 5.5 tc_brg_wr_ready_stall.sv

**`class tc_brg_wr_ready_stall extends tc_base`**：
- `apply_directed_plan()`：选 3 个 word（`early_word=rand_range(0,7)`/`middle_word=rand_range(8,total_words-9)`/`late_word=total_words-1-rand_range(0,7)`），分别注入 2-5/2-8/2-5 拍 `wready` 拉低。
- 复用基类 `fdma_write_slave` 的 `wr_ready_stall[]` 数组机制。

### 5.6 tc_brg_tx_fifo_waterline.sv

**`class tc_brg_tx_fifo_waterline extends tc_base`**：
- `configure()`：`num_frames=8`（8*64=512 word 可填满 512 深 FIFO），`enable_backpressure=0`。
- `pre_start()`：`ll_vif.tx_dst_rdy=0` 阻塞 FIFO 读端。
- `after_channel_up()`：等待 `tx_fifo_almost_full=1`（阈值 448），检查：`almost_full` 已置、`wr_cnt>=448`、`rready=0`（反压生效）、无 overflow；然后 `tx_dst_rdy=1` 释放排空。

### 5.7 tc_brg_rx_fifo_overflow.sv

**`class tc_brg_rx_fifo_overflow extends tc_base`**：
- 覆盖 `run()`：完全自定义 RX-only 流程。
- `injection_words=2048+rand_range(1,64)`（超过 RX FIFO 2048 深度）。
- 循环注入：通过 `ctrl_if.rx_drive_*` 直接驱动 RX（`rx_loopback_enable=0`），每 word 随机数据 + 正确 SOF/EOF。
- 检查：`rx_dst_rdy=1` 但 `rx_fifo_wr_en=0` 即"接受但未存储"记错（首次）；`overflow` 置位记错；覆盖 `almost_full/full` 标志。

---

## 六、tb_fdma_hw_test_engine.sv — 单元测试

**作用**：独立验证 `fdma_hw_test_engine` 模块本身（非 DUT 桥），确保硬件调试从机逻辑正确。

### 6.1 信号与例化

- 250MHz 时钟（`always #2`）；
- 例化 `fdma_hw_test_engine`，`FRAME_BYTES/BURST_BYTES=512`；
- 从 `dbg_bus` 解包出各计数/错误信号。

### 6.2 `check(condition, message)` [task]
断言失败则 `failures++` + `$error`。

### 6.3 `run_read_burst(frame_number, insert_stall)` [task]
- 设置 `raddr=frame*512`，拉高 `rareq`，等 `rbusy`；
- 循环 64 word：等握手，检查 `rdata=={frame,word}`；
- `insert_stall=1` 时在第 8 个 word 后拉低 `rready` 4 拍，检查 `rdata` 保持不变（稳定性）。

### 6.4 `run_write_burst(frame_number, error_mode)` [task]
- 设置 `waddr/wsize=512`，拉高 `wareq`，等 `wbusy`；
- 循环 64 word：`value={frame,word}`，`error_mode=1` 时第 5 word 翻转 bit0，`error_mode=2` 时第 0/1 word 翻转；
- 负边沿驱动避免竞争。

### 6.5 主 `initial` 流程
1. 复位释放；
2. 两次读 burst（第 2 次含 stall），检查 `hw_rd_word_total=128/burst_count=2`；
3. 正确写 burst，检查无错误；
4. 单错误写 burst（word 5），检查 `error_count=1/sticky=1/first_error` 锁存正确；
5. 强制 `hw_error_count=0xFFFFFFFE`，双错误写 burst，检查饱和到 `0xFFFFFFFF` 且 `first_error` 不被覆盖；
6. `fork` 并行读+写，检查独立性；
7. `failures==0` 打印 `TB_PASS`，否则 `$fatal`。

### 6.6 超时 `initial`
`#200000` 后 `$fatal("TB_TIMEOUT")`。

---

## 七、tc/tc_list — 回归列表

7 个测试名，每行一个，供 `run_regression.tcl` 逐行读取并启动独立 XSim 仿真。

---

## 八、文件间关联图

```
tc_if.sv (接口)
   ↑
   ├── brg_harness.sv ──── 例化 fdma_aurora_brg_top + 5 接口
   │       ↑
   │       └── tc_brg_*_top (4 个直接桥测试)
   │
   ├── aurora_loop_harness.sv ── 例化 fdma_aurora_brg_aurora_loop + 5 接口
   │       ↑
   │       └── tc_aurora_loop_*_top (3 个完整环回测试)
   │
   └── tc_base.sv (tc_base 类 + 工具函数)
           ↑
           └── 所有 tc_* 类 extends tc_base
                   ↑
                   └── tc_*_top.initial: 构造 + run()

tb_fdma_hw_test_engine.sv ── 独立单元测试（不依赖 tc_base/harness）
```

**数据流关联**：harness 例化 DUT 与接口 → tc_top 构造 tc 类并绑定 virtual interface → tc.run() 启动 BFM/监控器 → 监控器通过 obs_if 采样 DUT 内部 → 记分板比对 9 级队列 → PASS/FAIL。

---

## 九、SV 测试点矩阵（精炼）

> 每个测试点均映射到具体测试用例与检查代码段，"不求多，求准确"。

| # | 测试点 | 覆盖用例 | 关键检查代码 | 期望 |
|---|--------|----------|-------------|------|
| TP-S1 | 端到端数据完整性（无反压） | `tc_aurora_loop_nobp` | `check_results()` 9 级队列比对 [tc_base.sv#L608-L627](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L608-L627) | `expected_q == fdma_wr_hs_q`，error_count=0 |
| TP-S2 | 端到端 + 随机反压 | `tc_aurora_loop_bp` | `cfg_*` 全部启用 [tc_base.sv#L49-L62](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L49-L62) | 数据完整，协议合规 |
| TP-S3 | 地址回绕（0xE00→0） | `tc_aurora_loop_addr_wrap` | `check_addresses()` [tc_base.sv#L575-L605](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L575-L605) | ≥9 帧跨 4096 边界，地址序列 0,512,...,3584,0 |
| TP-S4 | TX FIFO 水位线反压 | `tc_brg_tx_fifo_waterline` | `after_channel_up()` 等 `almost_full` | wr_cnt≥448 时 rready=0，无 overflow |
| TP-S5 | TX FIFO 溢出保护 | `tc_brg_rx_fifo_overflow` | 注入 2048+ word [tc_brg_rx_fifo_overflow.sv](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_brg_rx_fifo_overflow.sv) | overflow 置位，`rx_dst_rdy=1` 但 `rx_fifo_wr_en=0` |
| TP-S6 | 读侧 rready stall（force 反压） | `tc_brg_rd_ready_stall` | `on_read_word_presented()` [tc_base.sv#L171-L172](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L171-L172) | rready=0 期间 rd_word_cnt 不推进 |
| TP-S7 | 写侧 wready stall + AXI 稳定性 | `tc_brg_wr_ready_stall` | `check_write_data_stable()` [tc_base.sv#L320-L336](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L320-L336) | wready=0 时 wvalid 不掉、wdata 不变 |
| TP-S8 | LL 帧标记（SOF/EOF/rem） | 所有 loop 用例 | `check_frame_markers()` [tc_base.sv#L447-L461](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L447-L461) | word0=SOF, word63=EOF, rem=7 |
| TP-S9 | X/Z 竞争检测 | 所有用例 | `monitor_*` 内 `^x`/`^z` 检查 [tc_base.sv#L392-L445](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L392-L445) | FDMA/LL 信号无 X/Z |
| TP-S10 | 硬件从机单元测试 | `tb_fdma_hw_test_engine` | `run_read/write_burst` + error 饱和 [tb#L197-L256](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tb_fdma_hw_test_engine.sv#L197-L256) | rd/wr 计数正确，error_count 饱和到 0xFFFFFFFF，first_error 不被覆盖 |
| TP-S11 | 可复现性 | 所有用例 | `resolve_seed()` + LCG [tc_base.sv#L21-L33](file:///C:/project/RTDS/fdma_aurora_brg_aurora_loop-validate/docs/sources_1%20-%20loop_validate-6-24-afternoon/sources_1%20-%20loop_validate/new/tc/tc_base.sv#L21-L33) | 同 `+SEED=` 完全复现 |

**回归执行**：`tc_list`（7 项）逐行启动独立 XSim，`+SEED=` 驱动随机化，`TEST_PASS/TEST_FAIL` 串行判定。
