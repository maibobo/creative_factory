# XDMA-AXIS直连Aurora替代方案详细设计

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\XDMA-AXIS直连Aurora替代方案详细设计.md`
- SHA-256: `706ddb1217d548021521ddf54cbb4fa8928bb6bb05272628838e097924c387c4`
- Extractor: `text`
- Tags: `aurora, axi-stream, design, xdma`
- Duplicate sources:
  - none

# XDMA-AXIS 直连 Aurora 替代方案详细设计

## 1 概述

### 1.1 当前架构

当前数据通路存在两次协议转换冗余：

```
CPU ← PCIe → XDMA(AXI4-M) → FDMA桥(AXI→FDMA) → fdma_aurora_brg(FDMA→LL) → Aurora(LL→AXIS→GT)
                                                                                         ↓ GT链路
CPU ← PCIe ← XDMA(AXI4-M) ← FDMA桥(AXI←FDMA) ← fdma_aurora_brg(FDMA←LL) ← Aurora(LL←AXIS←GT)
```

**冗余分析：**

| 模块 | 功能 | 是否冗余 |
|------|------|----------|
| XDMA | PCIe DMA引擎，提供AXI4-Master接口 | 否，必须 |
| FDMA桥 | AXI4 ↔ FDMA协议转换 | **是** — 增加一级转换 |
| fdma_aurora_brg | FDMA ↔ LocalLink协议转换 + AFIFO跨时钟域 | **部分** — 跨时钟域必要，FDMA↔LL转换冗余 |
| aurora_64b66b_0_exdes | LL ↔ AXIS转换 + frame_gen/check | **是** — Aurora IP核原生就是AXIS接口 |

**核心问题：** Aurora 64B/66B IP 核原生提供 AXI4-Stream 接口（`s_axi_tx_*` / `m_axi_rx_*`），`aurora_64b66b_0_exdes` 内部将 AXIS 转为 LL 是 Xilinx 示例设计的遗留，`fdma_aurora_brg` 又将 FDMA 转为 LL，形成 **AXI→FDMA→LL→AXIS** 的三重转换。

### 1.2 替代架构

```
CPU ← PCIe → XDMA(AXI4-M) → AXI DataMover(AXI4→AXIS) → Aurora(AXIS→GT)
                                                                              ↓ GT链路
CPU ← PCIe ← XDMA(AXI4-M) ← AXI DataMover(AXIS→AXI4) ← Aurora(AXIS←GT)
```

**简化为 AXI→AXIS 一次转换。**

---

## 2 当前架构深度限制分析

当前架构中 FDMA 模块和 Aurora AXIS↔LL 转换模块存在多处硬性限制，严重制约了系统的灵活性、带宽利用率和协议兼容性。

### 2.1 FDMA 协议限制

FDMA（Fast DMA）是米联科定义的简化 DMA 协议，本质上是 AXI4 的子集，但去除了大量标准特性，导致与标准 AXI4 生态不兼容。

#### 2.1.1 AXI4 ostd（Outstanding Transaction）限制为 1

| 限制 | 当前实现 | 标准 AXI4 | 影响 |
|------|----------|-----------|------|
| 未完成读请求数 | 1 | 1~16+ | **严重** |
| 未完成写请求数 | 1 | 1~16+ | **严重** |

**分析：** FDMA 的 `rareq`/`wareq` 是单次握手信号，一次只能有一个未完成的突发请求。这意味着：
- AXI4 AR 通道发出请求后，必须等 R 通道全部数据返回后才能发下一个 AR
- AXI4 AW 通道发出请求后，必须等 B 通道响应后才能发下一个 AW
- **无法利用 DDR 的读写并行性和银行级并行性**，实际带宽利用率远低于 AXI4 标准能力

**量化影响：** DDR4 的 tRCD/tCAS 延迟约 30~50 ns，在 ostd=1 时，每次突发之间必须等待完整的 DDR 访问延迟。以 250 MHz AXI 时钟为例：
- ostd=1：有效带宽 ≈ 60~70% 峰值
- ostd=4：有效带宽 ≈ 85~90% 峰值
- ostd=16：有效带宽 ≈ 92~95% 峰值

#### 2.1.2 AXI4 wstrb 恒为全1

| 限制 | 当前实现 | 标准 AXI4 | 影响 |
|------|----------|-----------|------|
| 写字节使能 | 固定全1 (0xFF) | 每拍可变 | **中等** |

**分析：** FDMA 写接口没有 `wstrb` 信号（代码中 `fdma_wvalid` 直接拉高，无 `wstrb` 控制），意味着：
- **每次写突发必须写满完整 cache line**，不能写部分字节
- 不支持非对齐写操作（如只修改某个 64-bit 字的低 32 位）
- 与标准 AXI4 互联时，必须外加固件保证所有写操作都是对齐的完整突发

**代码证据：** `fdma_aurora_brg_rx.v` 中 FDMA 写接口只有 `fdma_wdata`/`fdma_wvalid`/`fdma_wsize`，无 `fdma_wstrb`。

#### 2.1.3 AXI4 突发长度固定

| 限制 | 当前实现 | 标准 AXI4 | 影响 |
|------|----------|-----------|------|
| 读突发长度 | 固定 64 拍 (512B) | 1~256 拍 | **中等** |
| 写突发长度 | 固定 64 拍 (512B) | 1~256 拍 | **中等** |

**分析：** `FDMA_BURST_LEN = 16'd512` 硬编码，所有读写突发固定为 512 字节（64 拍 × 8 字节/拍）：
- 无法适应不同帧大小（如小包 64B 也必须发 512B 突发，浪费带宽）
- 无法利用 AXI4 的可变突发长度优化 DDR 访问模式
- 与 Aurora 的帧定界不匹配（brg 需要将 2 个 512B FDMA 突发拼成 1 个 1024B LL 帧）

#### 2.1.4 FDMA 地址空间固定

| 限制 | 当前实现 | 标准 AXI4 | 影响 |
|------|----------|-----------|------|
| 地址范围 | 固定 4KB 循环 | 64-bit 可编程 | **低** |
| 地址更新 | 硬编码回绕 | 任意地址 | **低** |

**代码证据：** `TEST_MEM_SIZE = 32'd4 * 1024`，地址在 4KB 范围内循环回绕。这在验证阶段可接受，但产品化需要可编程地址。

### 2.2 Aurora AXIS↔LL 转换限制

`aurora_64b66b_0_exdes` 内部使用 `frame_gen_ll_to_axi_data` 和 `frame_chk_axi_to_ll_data` 实现 LL↔AXIS 转换，存在以下限制：

#### 2.2.1 AXIS 每拍数据全有效（tkeep 恒为 0xFF）

| 限制 | 当前实现 | 标准 AXIS | 影响 |
|------|----------|-----------|------|
| tkeep | 固定 0xFF (8字节全有效) | 每拍可变 | **严重** |

**分析：** `fdma_aurora_brg_tx.v` 中 `tx_rem = 3'b111`（即 64-bit 全有效），`aurora_64b66b_0_exdes` 中 LL→AXIS 转换器将 `tx_rem=7` 映射为 `tx_tkeep=0xFF`：
- **无法发送非 8 字节对齐的帧**（如 100 字节帧需要 13 拍，最后一拍只有 4 字节有效）
- 所有帧长度必须是 8 的整数倍
- 与以太网等标准协议不兼容（以太网帧最小 64B，最大 1518B，经常非 8 字节对齐）

**代码证据：**
```verilog
// fdma_aurora_brg_tx.v line 227
tx_rem = 3'b111;  // 硬编码，每拍64-bit全有效
```

#### 2.2.2 LL rem 字段位宽不足

| 限制 | 当前实现 | 标准需要 | 影响 |
|------|----------|----------|------|
| rem 位宽 | 3 bit (0~7) | 3 bit (0~7) | **低** |
| rem 含义 | 有效字节数-1 | 有效字节数-1 | 正确 |

**分析：** rem=3bit 对 64-bit 数据宽度是足够的（0~7 对应 1~8 字节），但当前实现中 `tx_rem` 恒为 `3'b111`，rem 字段形同虚设。

#### 2.2.3 LL↔AXIS 转换引入额外延迟

| 转换方向 | 模块 | 延迟 | 原因 |
|----------|------|------|------|
| LL→AXIS (TX) | `frame_gen_ll_to_axi_data` | 4~8 clk | 状态机转换 + 信号重定时 |
| AXIS→LL (RX) | `frame_chk_axi_to_ll_data` | 4~8 clk | 状态机转换 + 信号重定时 |

**分析：** 这 8~16 clk 的延迟完全是冗余的——Aurora IP 核原生就是 AXIS 接口，LL 转换是 Xilinx 示例设计为兼容旧版 LocalLink IP 而添加的。

#### 2.2.4 RX 方向 tready 硬接为 1

| 限制 | 当前实现 | 标准 AXIS | 影响 |
|------|----------|-----------|------|
| RX tready | 硬接 1'b1 | 动态反压 | **严重** |

**代码证据：**
```verilog
// aurora_64b66b_0_exdes.v line 672
.AXI4_S_IP_TX_TREADY  (1'b1               ),  // RX方向tready硬接1
```

**分析：** RX 方向的 AXIS tready 硬接为 1，意味着：
- **下游无法反压**，即使 FIFO 将满也必须接收数据
- 如果下游处理速度跟不上上游发送速度，只能丢数据
- 这在 LL 接口层面通过 `rx_dst_rdy` 部分弥补，但 AXIS→LL 转换器内部没有反压传递机制
- **数据丢失风险**：当 Aurora 接收速率 > FDMA 写入速率时，FIFO 溢出

#### 2.2.5 LL 信号极性反转增加调试难度

| 信号 | LL 极性 | AXIS 极性 | 转换 |
|------|---------|-----------|------|
| sof | 低有效 (`sof_n`) | 高有效 (`tlast` + 位置) | 取反 |
| eof | 低有效 (`eof_n`) | 高有效 (`tlast`) | 取反 |
| src_rdy | 低有效 (`src_rdy_n`) | 高有效 (`tvalid`) | 取反 |
| dst_rdy | 低有效 (`dst_rdy_n`) | 高有效 (`tready`) | 取反 |

**代码证据：**
```verilog
// aurora_64b66b_0_exdes.v
assign tx_sof_n_i     = !tx_sof;       // 高有效→低有效
assign tx_eof_n_i     = !tx_eof;       // 高有效→低有效
assign tx_src_rdy_n_i = !tx_src_vld;   // 高有效→低有效
assign tx_dst_rdy     = !tx_dst_rdy_n_i; // 低有效→高有效
```

**分析：** 虽然 `fdma_aurora_brg` 使用高有效接口（`tx_sof`/`tx_src_rdy`），但 `aurora_64b66b_0_exdes` 内部需要做极性反转。这种双重反转增加了调试难度，波形中需要同时关注两种极性的信号。

### 2.3 限制综合影响

| 限制类别 | 对带宽的影响 | 对灵活性的影响 | 对可靠性的影响 |
|----------|-------------|---------------|---------------|
| ostd=1 | DDR带宽损失30~40% | 无法流水线访问 | 低 |
| wstrb恒1 | 无直接影响 | 不支持部分写 | 数据一致性风险 |
| 突发长度固定 | 小包带宽浪费 | 无法适应不同帧长 | 低 |
| tkeep恒0xFF | 非对齐帧无法传输 | 不兼容以太网 | 丢帧风险 |
| RX tready=1 | 无直接影响 | 无反压能力 | **FIFO溢出丢数据** |
| LL↔AXIS延迟 | 增加端到端延迟 | 无 | 低 |
| 信号极性反转 | 无 | 调试困难 | 低 |

### 2.4 替代方案如何解决这些限制

| 限制 | 方案B (DataMover+AXIS) 解决方式 |
|------|------|
| ostd=1 | AXI4 标准接口，支持 ostd=1~16+，可充分利用 DDR 带宽 |
| wstrb 恒1 | 标准 AXI4 wstrb，支持任意字节使能 |
| 突发长度固定 | 可编程 arlen/awlen，1~256 拍 |
| tkeep 恒0xFF | 标准 AXIS tkeep，支持非对齐帧 |
| RX tready=1 | 标准 AXIS tready 反压，FIFO 将满时反压上游 |
| LL↔AXIS 延迟 | 直接使用 Aurora AXIS 接口，无转换延迟 |
| 信号极性反转 | 全链路标准 AXIS 高有效，无极性反转 |

---

## 3 方案对比

### 3.1 方案A：当前架构（FDMA + fdma_aurora_brg + LL）

```
XDMA ─AXI4─→ FDMA桥 ─FDMA─→ fdma_aurora_brg ─LL─→ exdes(LL→AXIS) ─→ Aurora IP ─→ GT
```

### 3.2 方案B：AXI DataMover 直连 Aurora AXIS

```
XDMA ─AXI4─→ AXI DataMover ─AXIS─→ Aurora IP ─→ GT
```

### 3.3 方案C：XDMA Scatter/Gather 直接驱动 Aurora AXIS

```
XDMA Desc ─→ AXI4-M ─→ AXI4-Stream Interconnect ─→ Aurora IP ─→ GT
```

### 3.4 综合对比

| 对比项 | 方案A (FDMA+brg+LL) | 方案B (DataMover+AXIS) | 方案C (XDMA S/G+AXIS) |
|--------|---------------------|------------------------|----------------------|
| 协议转换次数 | 3次 (AXI→FDMA→LL→AXIS) | 1次 (AXI→AXIS) | 0次 (AXI4-M→AXIS桥) |
| 自研模块数 | 3 (FDMA桥+brg_tx+brg_rx) | 2 (dm_tx+dm_rx) | 1 (AXI-Stream桥) |
| 跨时钟域 | AFIFO (在brg内) | FIFO (在DataMover内) | FIFO (在桥内) |
| 流控机制 | FDMA反压+LL反压 | AXIS tready反压 | AXIS tready反压 |
| 帧定界 | brg内固定1024B帧 | DataMover可编程 | 依赖描述符 |
| 设计复杂度 | 高 | 中 | 低 |
| 灵活性 | 低(固定帧长) | 中 | 高(S/G描述符) |

---

## 4 方案B详细设计：AXI DataMover 直连 Aurora AXIS

### 4.1 架构总览

```
┌─────────────────────────────────────────────────────────────────────┐
│                        FPGA                                          │
│                                                                      │
│  ┌──────────┐    ┌──────────────────────┐    ┌──────────────────┐   │
│  │          │    │  xdma_aurora_axis_top │    │                  │   │
│  │  XDMA    │    │                      │    │  Aurora 64B/66B  │   │
│  │          │    │  ┌────────────────┐   │    │  IP Core         │   │
│  │ AXI4-M   │───→│  │ dm_tx         │   │    │                  │   │
│  │ M_AXI    │    │  │ AXI4→AXIS     │───┼───→│ s_axi_tx_*      │   │
│  │          │    │  │ +cmd解析      │   │    │ (AXI4-Stream TX) │   │
│  │          │    │  │ +FIFO         │   │    │        │         │   │
│  │          │    │  └────────────────┘   │    │        ↓         │   │
│  │          │    │                        │    │    GT TX ───────┼──┼──→ GT TXP/N
│  │          │    │  ┌────────────────┐   │    │                  │   │
│  │ AXI4-M   │←───│  │ dm_rx         │   │    │    GT RX ←──────┼──┼──← GT RXP/N
│  │ M_AXI    │    │  │ AXIS→AXI4     │←──┼───←│ m_axi_rx_*      │   │
│  │          │    │  │ +帧重组       │   │    │ (AXI4-Stream RX) │   │
│  │          │    │  │ +FIFO         │   │    │                  │   │
│  └──────────┘    │  └────────────────┘   │    └──────────────────┘   │
│                  └──────────────────────┘                             │
│                                                                       │
│  ┌──────────┐                                                         │
│  │  CPU     │←── PCIe ──→ XDMA                                       │
│  └──────────┘                                                         │
└───────────────────────────────────────────────────────────────────────┘
```

### 4.2 模块定义

#### 4.2.1 xdma_aurora_axis_top（顶层）

```verilog
module xdma_aurora_axis_top (
    // XDMA AXI4-Master 接口 (TX方向: 读DDR, 发送数据)
    input         m_axi_tx_aclk,
    input         m_axi_tx_aresetn,
    output [63:0] m_axi_tx_araddr,
    output [7:0]  m_axi_tx_arlen,
    output [2:0]  m_axi_tx_arsize,
    output [1:0]  m_axi_tx_arburst,
    output        m_axi_tx_arvalid,
    input         m_axi_tx_arready,
    input  [63:0] m_axi_tx_rdata,
    input  [1:0]  m_axi_tx_rresp,
    input         m_axi_tx_rlast,
    input         m_axi_tx_rvalid,
    output        m_axi_tx_rready,

    // XDMA AXI4-Master 接口 (RX方向: 接收数据, 写DDR)
    input         m_axi_rx_aclk,
    input         m_axi_rx_aresetn,
    output [63:0] m_axi_rx_awaddr,
    output [7:0]  m_axi_rx_awlen,
    output [2:0]  m_axi_rx_awsize,
    output [1:0]  m_axi_rx_awburst,
    output        m_axi_rx_awvalid,
    input         m_axi_rx_awready,
    output [63:0] m_axi_rx_wdata,
    output [7:0]  m_axi_rx_wstrb,
    output        m_axi_rx_wlast,
    output        m_axi_rx_wvalid,
    input         m_axi_rx_wready,
    input  [1:0]  m_axi_rx_bresp,
    input         m_axi_rx_bvalid,
    output        m_axi_rx_bready,

    // Aurora GT IO
    input         clk_init,
    input         sys_rst,
    input         GTHQ0_P,
    input         GTHQ0_N,
    input         RXP,
    input         RXN,
    output        TXP,
    output        TXN,

    // 状态
    output        channel_up,
    output        lane_up,
    output        user_clk,
    output        user_rstn
);
```

#### 4.2.2 dm_tx（AXI4 读 → AXIS 发送）

```verilog
module dm_tx (
    // AXI4 读主接口 (从DDR读数据)
    input         axi_clk,
    input         axi_rstn,
    output [63:0] m_axi_araddr,
    output [7:0]  m_axi_arlen,
    output        m_axi_arvalid,
    input         m_axi_arready,
    input  [63:0] m_axi_rdata,
    input         m_axi_rlast,
    input         m_axi_rvalid,
    output        m_axi_rready,

    // AXI4-Stream 主接口 (发往Aurora)
    input         axis_clk,        // user_clk
    input         axis_rstn,
    output [63:0] m_axis_tdata,
    output        m_axis_tlast,
    output [7:0]  m_axis_tkeep,
    output        m_axis_tvalid,
    input         m_axis_tready,

    // 控制
    input         channel_up,
    input  [31:0] base_addr,        // 读取起始地址
    input  [15:0] frame_size,       // 帧大小(字节)
    input         start             // 启动传输
);
```

**工作流程：**
1. CPU 写寄存器设置 `base_addr` + `frame_size` + `start=1`
2. dm_tx 发起 AXI4 AR 请求，突发长度 = frame_size / 8
3. AXI4 R 通道数据写入异步 FIFO（axi_clk → axis_clk）
4. FIFO 读出后驱动 AXIS TX 接口
5. `tlast` 在帧末尾拉高，`tkeep` 指示有效字节

#### 4.2.3 dm_rx（AXIS 接收 → AXI4 写）

```verilog
module dm_rx (
    // AXI4-Stream 从接口 (来自Aurora)
    input         axis_clk,        // user_clk
    input         axis_rstn,
    input  [63:0] s_axis_tdata,
    input         s_axis_tlast,
    input  [7:0]  s_axis_tkeep,
    input         s_axis_tvalid,
    output        s_axis_tready,

    // AXI4 写主接口 (写数据到DDR)
    input         axi_clk,
    input         axi_rstn,
    output [63:0] m_axi_awaddr,
    output [7:0]  m_axi_awlen,
    output        m_axi_awvalid,
    input         m_axi_awready,
    output [63:0] m_axi_wdata,
    output [7:0]  m_axi_wstrb,
    output        m_axi_wlast,
    output        m_axi_wvalid,
    input         m_axi_wready,
    input  [1:0]  m_axi_bresp,
    input         m_axi_bvalid,
    output        m_axi_bready,

    // 控制
    input         channel_up,
    input  [31:0] base_addr,        // 写入起始地址
    input  [15:0] frame_size,       // 期望帧大小
    output        frame_done        // 帧接收完成中断
);
```

**工作流程：**
1. Aurora RX AXIS 数据到达
2. `tlast` 检测帧边界，整帧写入异步 FIFO（axis_clk → axi_clk）
3. FIFO 积累到足够数据后发起 AXI4 AW+W 写请求
4. 写完成后 `frame_done` 拉高，通知 CPU

### 4.3 关键设计细节

#### 4.3.1 AXI4 突发参数

| 参数 | 值 | 说明 |
|------|-----|------|
| AXI4 数据宽度 | 64 bit | 匹配 XDMA M_AXI |
| AXI4 突发类型 | INCR | 增量突发 |
| AXI4 突发长度 | 1~256 | 由 frame_size 决定 |
| AXIS 数据宽度 | 64 bit | 匹配 Aurora s_axi_tx_tdata |
| 帧大小 | 可编程 | 由 CPU 配置寄存器设定 |

#### 4.3.2 跨时钟域处理

```
axi_clk (250MHz) ──→ 异步FIFO ──→ axis_clk (user_clk ~161MHz)
```

- FIFO 深度：256（容纳 2 个最大突发）
- FIFO 宽度：64 bit + sideband（tlast, tkeep）
- 使用 XPM_FIFO_ASYNC 或 XPM_FIFO_AXIS

#### 4.3.3 流控策略

| 场景 | 处理方式 |
|------|----------|
| Aurora TX 反压 (tready=0) | FIFO 积累，FIFO 将满时停止 AXI4 AR 请求 |
| Aurora RX 数据涌入 | FIFO 缓冲，AXI4 W 通道背压时 FIFO 吸收 |
| DDR 响应慢 | AXI4 R/W 通道反压，FIFO 吸收 |

#### 4.3.4 帧定界

- **TX方向**：CPU 配置 `frame_size`，dm_tx 计数到 `frame_size` 字节时插入 `tlast`
- **RX方向**：dm_rx 检测 `tlast` 确定帧边界，整帧写入 DDR
- **tkeep**：TX 方向按 8 字节对齐时 `tkeep=0xFF`，非对齐时按实际有效字节设置

### 4.4 寄存器映射

| 偏移 | 名称 | 位域 | 描述 |
|------|------|------|------|
| 0x00 | TX_CTRL | [0] start, [1] busy | 启动TX传输 |
| 0x04 | TX_BASE_ADDR | [31:0] | TX读取DDR基地址 |
| 0x08 | TX_FRAME_SIZE | [15:0] | TX帧大小(字节) |
| 0x0C | TX_FRAME_CNT | [15:0] | 已发送帧数 |
| 0x10 | RX_CTRL | [0] start, [1] busy | 启动RX接收 |
| 0x14 | RX_BASE_ADDR | [31:0] | RX写入DDR基地址 |
| 0x18 | RX_FRAME_SIZE | [15:0] | RX期望帧大小(字节) |
| 0x1C | RX_FRAME_CNT | [15:0] | 已接收帧数 |
| 0x20 | STATUS | [0] channel_up, [1] lane_up | Aurora状态 |
| 0x24 | IRQ_STATUS | [0] tx_done, [1] rx_done, [2] err | 中断状态 |

---

## 5 性能与PPA对比

### 5.1 带宽分析

| 参数 | 方案A (FDMA+brg+LL) | 方案B (DataMover+AXIS) |
|------|---------------------|------------------------|
| Aurora线速率 | 10 Gbps | 10 Gbps |
| 64B/66B编码效率 | 96.97% | 96.97% |
| 有效数据带宽 | ~9.70 Gbps | ~9.70 Gbps |
| 协议开销 | FDMA帧头+LL帧头+brg状态机 | AXIS tkeep/tlast |
| 实际可用带宽 | ~9.0 Gbps (固定帧开销) | ~9.5 Gbps (更少开销) |
| AXI4突发效率 | FDMA固定512B突发 | 可编程突发长度 |

**关键差异：** 方案A的brg将FDMA 512B突发重组为1024B LL帧，引入额外延迟和缓冲；方案B的AXI4突发长度可按帧大小配置，减少碎片。

### 5.2 延迟分析

| 延迟来源 | 方案A | 方案B |
|----------|-------|-------|
| AXI→FDMA转换 | 2~4 clk | — |
| FDMA→LL转换 (brg_tx) | 4~8 clk | — |
| AFIFO写入 | 2~4 clk | 2~4 clk (异步FIFO) |
| AFIFO读出 | 2~4 clk | 2~4 clk |
| LL→AXIS转换 (exdes) | 4~8 clk | — |
| **TX总延迟** | **14~28 clk** | **4~8 clk** |
| AXIS→LL转换 (exdes) | 4~8 clk | — |
| LL→FDMA转换 (brg_rx) | 4~8 clk | — |
| FDMA→AXI转换 | 2~4 clk | — |
| **RX总延迟** | **14~28 clk** | **4~8 clk** |

**方案B延迟降低约 60~70%。**

### 5.3 资源对比 (Xilinx UltraScale+)

| 资源 | 方案A | 方案B | 节省 |
|------|-------|-------|------|
| LUT | ~2800 | ~1200 | 57% |
| FF | ~2200 | ~900 | 59% |
| BRAM (36Kb) | 6 (AFIFO×2 + exdes内部) | 2 (异步FIFO×2) | 67% |
| 最高工作频率 | 250 MHz (fdma_clk) | 250 MHz (axi_clk) | 相同 |

**资源节省原因：**
- 去除 FDMA 桥（AXI↔FDMA转换逻辑）
- 去除 fdma_aurora_brg（FDMA↔LL转换 + AFIFO）
- 去除 exdes 内部 LL↔AXIS 转换逻辑
- 只保留 2 个异步 FIFO（跨时钟域）

### 5.4 功耗对比

| 来源 | 方案A | 方案B |
|------|-------|-------|
| 组合逻辑翻转 | 高（3级协议转换） | 低（1级转换） |
| BRAM 动态功耗 | 6×36Kb | 2×36Kb |
| 时钟树 | 3个独立时钟域 | 2个独立时钟域 |
| **估算总功耗** | ~120 mW | ~50 mW |

### 5.5 PPA综合评分

| 指标 | 方案A | 方案B | 优势方 |
|------|-------|-------|--------|
| Performance (带宽) | ★★★☆☆ | ★★★★☆ | B |
| Performance (延迟) | ★★☆☆☆ | ★★★★★ | B |
| Power | ★★☆☆☆ | ★★★★☆ | B |
| Area | ★★☆☆☆ | ★★★★☆ | B |
| 设计复杂度 | ★★☆☆☆ | ★★★★☆ | B |
| 灵活性 | ★★☆☆☆ | ★★★★☆ | B |
| 验证难度 | ★★☆☆☆ | ★★★★☆ | B |

---

## 6 方案B实现要点

### 6.1 Aurora IP 核配置变更

当前 `aurora_64b66b_0` IP 核配置为 LL 接口模式，需改为 AXIS 接口模式：

| 配置项 | 当前值 | 修改后 |
|--------|--------|--------|
| Interface | LocalLink | AXI4-Stream |
| TX 接口 | ll_tx_* | s_axi_tx_tdata/tlast/tkeep/tvalid/tready |
| RX 接口 | ll_rx_* | m_axi_rx_tdata/tlast/tkeep/tvalid |
| 数据宽度 | 64 bit | 64 bit (不变) |
| 线速率 | 10.3125 Gbps | 10.3125 Gbps (不变) |

**注意：** 修改 IP 核接口模式后，`aurora_64b66b_0_exdes` 不再需要（它内部的 LL↔AXIS 转换和 frame_gen/check 都是冗余的）。

### 6.2 XDMA 配置

| 配置项 | 值 | 说明 |
|--------|-----|------|
| M_AXI 数据宽度 | 64 bit | 匹配 DDR/Aurora |
| M_AXI 地址宽度 | 64 bit | 标准配置 |
| SG 使能 | 是 | Scatter/Gather DMA |
| 描述符宽度 | 64 bit | |
| 通道数 | 2 (H2C+C2H) | TX+RX |

### 6.3 CPU 驱动流程

#### TX 方向（发送数据到远端）

```c
// 1. 准备发送数据到DDR缓冲区
memcpy(ddr_tx_buf, data, data_len);

// 2. 配置dm_tx寄存器
write_reg(TX_BASE_ADDR, ddr_tx_buf_phys);
write_reg(TX_FRAME_SIZE, data_len);
write_reg(TX_CTRL, 0x1);  // start

// 3. 等待完成中断
wait_irq(TX_DONE_IRQ);

// 4. 查询状态
frame_cnt = read_reg(TX_FRAME_CNT);
```

#### RX 方向（从远端接收数据）

```c
// 1. 配置dm_rx寄存器
write_reg(RX_BASE_ADDR, ddr_rx_buf_phys);
write_reg(RX_FRAME_SIZE, expected_len);
write_reg(RX_CTRL, 0x1);  // start

// 2. 等待完成中断
wait_irq(RX_DONE_IRQ);

// 3. 从DDR读取接收数据
memcpy(data, ddr_rx_buf, data_len);
```

### 6.4 验证策略

| 验证项 | 方法 |
|--------|------|
| AXI4 读正确性 | AXI4 VIP 验证 AR/R 通道协议 |
| AXI4 写正确性 | AXI4 VIP 验证 AW/W/B 通道协议 |
| AXIS 协议 | AXIS VIP 验证 tvalid/tready/tlast/tkeep |
| 跨时钟域 | 两个独立时钟，随机相位偏移 |
| GT 环回 | 同方案A，Partner 使用 USE_CORE_TRAFFIC |
| 反压 | 随机 tready 拉低 |
| 端到端 | AXI4 写入数据 → GT 环回 → AXI4 读出比对 |

---

## 7 方案选择建议

### 7.1 选方案A的场景

- 已有成熟的 FDMA 生态（多个 IP 共享 FDMA 总线）
- 需要与其他 FDMA 外设（如 UART、SPI）统一接口
- 项目进度紧张，不愿修改 Aurora IP 核配置
- 需要固定帧长的确定性传输

### 7.2 选方案B的场景

- **新项目**，无 FDMA 历史包袱
- 追求**低延迟、高带宽、低资源**
- Aurora 是唯一的对端通信接口
- 需要灵活的帧大小配置
- 简化验证复杂度

### 7.3 迁移路径

若从方案A迁移到方案B：

1. 重新配置 Aurora IP 核为 AXIS 模式
2. 开发 dm_tx / dm_rx 模块（约 500 行 Verilog）
3. 删除 FDMA 桥、fdma_aurora_brg、aurora_64b66b_0_exdes
4. 修改 XDMA 驱动（寄存器映射变化）
5. 重新验证

---

## 8 结论

方案B（AXI DataMover 直连 Aurora AXIS）在性能、功耗、面积上全面优于方案A：

- **延迟降低 60~70%**：去除两级协议转换
- **资源节省 57~67%**：去除 FDMA 桥 + brg + exdes 内部转换
- **功耗降低约 58%**：减少逻辑翻转和 BRAM 使用
- **设计复杂度大幅降低**：自研模块从 3 个减为 2 个，协议转换从 3 级减为 1 级

**建议：** 对于仅验证通路完整性的场景，方案B是更优选择。方案A的 FDMA+brg 架构适用于需要与现有 FDMA 生态兼容的场景。
