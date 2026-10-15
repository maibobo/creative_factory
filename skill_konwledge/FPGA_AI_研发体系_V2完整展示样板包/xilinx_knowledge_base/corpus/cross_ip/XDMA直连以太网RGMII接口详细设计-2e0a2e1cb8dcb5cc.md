# XDMA直连以太网RGMII接口详细设计

- Category: `cross_ip`
- Source: `R:\fdma_aurora_brg_aurora_loop-validate\docs\XDMA直连以太网RGMII接口详细设计.md`
- SHA-256: `2e0a2e1cb8dcb5cc92d98801286ea8f228c860734e98abed7c0319275f54e0cc`
- Extractor: `text`
- Tags: `ethernet, rgmii, xdma`
- Duplicate sources:
  - none

# XDMA 直连以太网 RGMII 接口详细设计方案

## 1 概述

### 1.1 设计目标

将 XDMA（PCIe DMA 引擎）的 AXI4-Master 接口直接对接以太网 MAC 的 RGMII 接口，实现 CPU 通过 PCIe 访问远端以太网设备的数据通路，仅验证通路完整性。

### 1.2 与 Aurora 方案的对比

| 对比项 | Aurora 方案 | 以太网 RGMII 方案 |
|--------|------------|-------------------|
| 物理层 | GT 串行收发器 (10.3125 Gbps) | RGMII (1 Gbps) |
| 协议栈 | Aurora 64B/66B (轻量级) | 以太网 MAC + PHY (标准) |
| 数据宽度 | 64 bit | 8 bit (MAC内部) / 4 bit (RGMII DDR) |
| 帧格式 | 自定义 (AXI4-Stream) | 标准以太网帧 (前导码+SFD+MAC+数据+FCS) |
| 流控 | AXIS tready 反压 | IEEE 802.3x PAUSE 帧 + IPG |
| 延迟 | 低 (~100 ns) | 中 (~1~10 μs, 含MAC帧缓冲) |
| 带宽 | ~9.7 Gbps | ~1 Gbps (有效~950 Mbps) |
| 适用距离 | 板间/机架间 (<10m) | 局域网 (100m Cat5e) |

### 1.3 架构总览

```
┌──────────────────────────────────────────────────────────────────────────┐
│                              FPGA                                         │
│                                                                           │
│  ┌──────────┐    ┌────────────────────────────┐    ┌──────────────────┐ │
│  │          │    │  xdma_eth_rgmii_top         │    │                  │ │
│  │  XDMA    │    │                              │    │  Ethernet MAC    │ │
│  │          │    │  ┌────────────────────┐      │    │  (1G)            │ │
│  │ AXI4-M   │───→│  │ eth_tx            │      │    │                  │ │
│  │ M_AXI    │    │  │ AXI4→AXIS         │──┐   │    │  TX AXI4-S  ────┼─┼──→ RGMII TX
│  │          │    │  │ +以太网帧封装     │  │   │    │  (tx_axis)       │ │    (4 DDR pins)
│  │          │    │  │ +FIFO             │  └──→│───→│                  │ │
│  │          │    │  └────────────────────┘      │    │                  │ │
│  │          │    │                               │    │  RX AXI4-S  ←───│ │
│  │ AXI4-M   │←───│  ┌────────────────────┐      │    │  (rx_axis)       │ │
│  │ M_AXI    │    │  │ eth_rx            │  ┌──←│───←│                  │ │
│  │          │    │  │ AXIS→AXI4         │←─┘   │    │                  │ │
│  │          │    │  │ +以太网帧解封装   │      │    │  RX AXI4-S  ←───┼─┼──← RGMII RX
│  │          │    │  │ +FIFO             │      │    │                  │ │    (4 DDR pins)
│  └──────────┘    │  └────────────────────┘      │    └──────────────────┘ │
│                  └────────────────────────────┘                          │
│                                                                           │
│  ┌──────────┐                                                             │
│  │  CPU     │←── PCIe ──→ XDMA                                           │
│  └──────────┘                                                             │
└───────────────────────────────────────────────────────────────────────────┘
```

---

## 2 以太网帧格式与 RGMII 接口

### 2.1 标准以太网帧结构

```
┌──────────┬─────┬──────────────┬──────────────┬─────────┬──────────┬─────┐
│ 前导码    │ SFD │ 目的MAC地址   │ 源MAC地址     │ 类型/长度│ 数据     │ FCS │
│ 7B       │ 1B  │ 6B           │ 6B           │ 2B      │ 46~1500B │ 4B  │
└──────────┴─────┴──────────────┴──────────────┴─────────┴──────────┴─────┘
                                                    ↑
                                               有效载荷 (Payload)
                                               由 eth_tx 封装
                                               由 eth_rx 提取
```

**关键参数：**

| 参数 | 值 | 说明 |
|------|-----|------|
| 最小帧长 | 64 B | 含前导码和FCS |
| 最大帧长 | 1518 B | 标准帧，Jumbo帧可达9000B |
| 最小有效载荷 | 46 B | 不足时需填充 |
| 最大有效载荷 | 1500 B | 标准MTU |
| 帧间隙 (IPG) | 12 B | 帧间最小间隔 |
| 前导码 | 7 B (0x55) | 时钟同步 |
| SFD | 1 B (0xD5) | 帧起始定界符 |
| FCS | 4 B (CRC32) | 帧校验序列 |

### 2.2 RGMII 接口信号

| 信号名 | 方向 | 宽度 | 描述 |
|--------|------|------|------|
| `rgmii_tx_clk` | output | 1 | TX 时钟 125 MHz (DDR) |
| `rgmii_tx_ctl` | output | 1 | TX 控制 (TX_EN XOR TX_ERR) |
| `rgmii_txd` | output | 4 | TX 数据 (DDR, 上升沿+下降沿各4bit=8bit/cycle) |
| `rgmii_rx_clk` | input | 1 | RX 时钟 125 MHz (DDR) |
| `rgmii_rx_ctl` | input | 1 | RX 控制 |
| `rgmii_rxd` | input | 4 | RX 数据 (DDR) |
| `rgmii_mdc` | output | 1 | MDIO 时钟 |
| `rgmii_mdio` | inout | 1 | MDIO 数据 (PHY配置) |
| `phy_rst_n` | output | 1 | PHY 复位 |

**RGMII DDR 时序：**
- 时钟频率：125 MHz (1 Gbps)
- 每个时钟周期传输 8 bit 数据（上升沿 4 bit + 下降沿 4 bit）
- 有效带宽：125 MHz × 8 bit = 1 Gbps

### 2.3 MAC 层 AXI4-Stream 接口

Xilinx 1G/2.5G Ethernet MAC IP 核提供 AXI4-Stream 用户接口：

**TX AXIS (CPU→MAC)：**
| 信号 | 宽度 | 描述 |
|------|------|------|
| `tx_axis_tdata` | 8 | TX 数据 |
| `tx_axis_tvalid` | 1 | 数据有效 |
| `tx_axis_tready` | 1 | MAC 准备接收 |
| `tx_axis_tlast` | 1 | 帧结束 |
| `tx_axis_tuser` | 1 | 错误指示 |

**RX AXIS (MAC→CPU)：**
| 信号 | 宽度 | 描述 |
|------|------|------|
| `rx_axis_tdata` | 8 | RX 数据 |
| `rx_axis_tvalid` | 1 | 数据有效 |
| `rx_axis_tlast` | 1 | 帧结束 |
| `rx_axis_tuser` | 1 | 错误指示 (FCS错误等) |

**关键差异（与Aurora对比）：**

| 特性 | Aurora AXIS | Ethernet MAC AXIS |
|------|-------------|-------------------|
| 数据宽度 | 64 bit | 8 bit |
| tkeep | 有 | 无 (8bit宽度不需要) |
| 帧定界 | tlast | tlast |
| 帧大小限制 | 无 | 64~1518 B (标准) |
| FCS | 无 (Aurora内部CRC) | MAC自动添加/校验 |
| 前导码/SFD | 无 | MAC自动添加/剥离 |
| 流控 | tready | PAUSE帧 + IPG |

---

## 3 模块详细设计

### 3.1 xdma_eth_rgmii_top（顶层）

```verilog
module xdma_eth_rgmii_top (
    // XDMA AXI4-Master 接口 (TX方向)
    input         m_axi_tx_aclk,
    input         m_axi_tx_aresetn,
    output [63:0] m_axi_tx_araddr,
    output [7:0]  m_axi_tx_arlen,
    output        m_axi_tx_arvalid,
    input         m_axi_tx_arready,
    input  [63:0] m_axi_tx_rdata,
    input         m_axi_tx_rlast,
    input         m_axi_tx_rvalid,
    output        m_axi_tx_rready,

    // XDMA AXI4-Master 接口 (RX方向)
    input         m_axi_rx_aclk,
    input         m_axi_rx_aresetn,
    output [63:0] m_axi_rx_awaddr,
    output [7:0]  m_axi_rx_awlen,
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

    // RGMII 接口
    output        rgmii_tx_clk,
    output        rgmii_tx_ctl,
    output [3:0]  rgmii_txd,
    input         rgmii_rx_clk,
    input         rgmii_rx_ctl,
    input  [3:0]  rgmii_rxd,

    // PHY 管理
    output        rgmii_mdc,
    inout         rgmii_mdio,
    output        phy_rst_n,

    // 状态
    output        link_up,
    output        link_speed
);
```

### 3.2 eth_tx（AXI4 读 → 以太网帧发送）

#### 3.2.1 功能描述

1. 从 DDR 读取有效载荷数据（通过 AXI4 AR 通道）
2. 将 64-bit AXI4 数据拆分为 8-bit AXIS 数据
3. 添加以太网帧头（目的MAC + 源MAC + 类型）
4. 通过 MAC IP 核的 TX AXIS 接口发送
5. MAC 自动添加前导码、SFD、FCS

#### 3.2.2 模块接口

```verilog
module eth_tx (
    // AXI4 读主接口
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

    // AXI4-Stream 主接口 (连MAC TX)
    input         axis_clk,        // MAC TX 时钟 (125 MHz)
    input         axis_rstn,
    output [7:0]  m_axis_tdata,
    output        m_axis_tvalid,
    input         m_axis_tready,
    output        m_axis_tlast,
    output        m_axis_tuser,    // 0=正常, 1=错误

    // 控制
    input         link_up,
    input  [47:0] dst_mac,        // 目的MAC地址
    input  [47:0] src_mac,        // 源MAC地址
    input  [15:0] eth_type,        // 以太网类型 (0x0800=IPv4)
    input  [31:0] base_addr,       // DDR读取基地址
    input  [15:0] frame_size,      // 有效载荷大小 (46~1500B)
    input         start
);
```

#### 3.2.3 帧封装状态机

```
                    ┌──────────┐
                    │  IDLE    │
                    └────┬─────┘
                         │ start & link_up
                    ┌────▼─────┐
                    │  HDR_DST │ ── 发送6B目的MAC
                    └────┬─────┘
                    ┌────▼─────┐
                    │  HDR_SRC │ ── 发送6B源MAC
                    └────┬─────┘
                    ┌────▼─────┐
                    │  HDR_TYPE│ ── 发送2B类型
                    └────┬─────┘
                    ┌────▼─────┐
                    │  PAYLOAD │ ── 发送有效载荷(从FIFO读)
                    └────┬─────┘
                         │ 计数到frame_size
                    ┌────▼─────┐
                    │  PAD     │ ── 填充到46B(如需要)
                    └────┬─────┘
                    ┌────▼─────┐
                    │  DONE    │ ── tlast=1, 返回IDLE
                    └──────────┘
```

#### 3.2.4 数据宽度转换

```
AXI4 R通道 (64-bit) ──→ 异步FIFO (64→8 bit) ──→ AXIS (8-bit)
    axi_clk                    axis_clk
```

**宽度转换策略：**
- AXI4 每拍 64-bit = 8 字节，写入 FIFO 时按 8 字节打包
- FIFO 读出时按 8-bit 输出，每 64-bit 字拆为 8 次 AXIS 传输
- 使用 XPM_FIFO_ASYNC 配置 WRITE_DATA_WIDTH=64, READ_DATA_WIDTH=8

#### 3.2.5 帧大小约束

| 条件 | 处理 |
|------|------|
| 有效载荷 < 46 B | 自动填充 0x00 到 46 B |
| 有效载荷 > 1500 B | 拒绝启动，报错 |
| 有效载荷 46~1500 B | 正常发送 |
| 有效载荷非整数字节 | 最后一拍 tkeep 标记（但8-bit宽度无需tkeep） |

### 3.3 eth_rx（以太网帧接收 → AXI4 写）

#### 3.3.1 功能描述

1. 从 MAC RX AXIS 接口接收以太网帧
2. 校验 FCS（MAC 自动完成，通过 tuser 指示）
3. 剥离以太网帧头（14B MAC头）
4. 将 8-bit AXIS 数据组装为 64-bit AXI4 数据
5. 通过 AXI4 AW/W 通道写入 DDR

#### 3.3.2 模块接口

```verilog
module eth_rx (
    // AXI4-Stream 从接口 (来自MAC RX)
    input         axis_clk,        // MAC RX 时钟
    input         axis_rstn,
    input  [7:0]  s_axis_tdata,
    input         s_axis_tvalid,
    output        s_axis_tready,
    input         s_axis_tlast,
    input         s_axis_tuser,    // 0=正常, 1=FCS错误

    // AXI4 写主接口
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
    input         link_up,
    input  [31:0] base_addr,       // DDR写入基地址
    output [15:0] rx_frame_size,   // 接收到的有效载荷大小
    output        frame_done,      // 帧接收完成
    output        frame_error      // FCS错误
);
```

#### 3.3.3 帧解封装状态机

```
                    ┌──────────┐
                    │  IDLE    │
                    └────┬─────┘
                         │ tvalid & ~tlast
                    ┌────▼─────┐
                    │  SKIP_DST│ ── 跳过6B目的MAC
                    └────┬─────┘
                    ┌────▼─────┐
                    │  SKIP_SRC│ ── 跳过6B源MAC
                    └────┬─────┘
                    ┌────▼─────┐
                    │  SKIP_TYPE│ ── 跳过2B类型
                    └────┬─────┘
                    ┌────▼─────┐
                    │  PAYLOAD │ ── 有效载荷写入FIFO
                    └────┬─────┘
                         │ tlast
                    ┌────▼─────┐
                    │  CHECK   │ ── 检查tuser(FCS), 通知CPU
                    └──────────┘
```

#### 3.3.4 数据宽度转换

```
AXIS (8-bit) ──→ 异步FIFO (8→64 bit) ──→ AXI4 W通道 (64-bit)
  axis_clk                axi_clk
```

**宽度转换策略：**
- AXIS 每拍 8-bit，写入 FIFO 时按 8 字节组装
- FIFO 积累 8 字节后一次性读出 64-bit
- 帧末尾不足 8 字节时，用 `wstrb` 标记有效字节
- 使用 XPM_FIFO_ASYNC 配置 WRITE_DATA_WIDTH=8, READ_DATA_WIDTH=64

### 3.4 MAC IP 核配置

使用 Xilinx 1G/2.5G Ethernet MAC (temac) IP 核：

| 配置项 | 值 | 说明 |
|--------|-----|------|
| 速率 | 1 Gbps | RGMII 1G |
| 接口 | RGMII | Reduced Gigabit MII |
| TX AXI4-Stream | 使能 | 用户数据接口 |
| RX AXI4-Stream | 使能 | 用户数据接口 |
| 数据宽度 | 8 bit | 标准配置 |
| MDIO | 使能 | PHY 管理 |
| FCS 校验 | 使能 | TX自动添加, RX自动校验 |
| 帧过滤 | 禁用 | 接收所有帧(验证用) |
| Flow Control | 可选 | IEEE 802.3x PAUSE |

### 3.5 PHY 配置

通过 MDIO 接口配置外部 PHY 芯片（如 RTL8211F、DP83867）：

| 寄存器 | 地址 | 配置 | 说明 |
|--------|------|------|------|
| BMCR | 0x00 | 0x1140 | 使能自协商, 重启自协商 |
| ANAR | 0x04 | 0x0DE1 | 广播1000M全双工 |
| PHYID1 | 0x02 | 读 | 确认PHY型号 |
| LPA | 0x05 | 读 | 链路伙伴能力 |
| BMSR | 0x01 | 读 | 链路状态 |

**PHY 初始化流程：**
1. `phy_rst_n` 拉低 10 ms，释放
2. 等待 100 ms (PHY 复位完成)
3. 通过 MDIO 读取 PHY ID 确认通信正常
4. 配置自协商参数
5. 轮询 BMSR 寄存器等待链路建立

---

## 4 寄存器映射

| 偏移 | 名称 | 位域 | 描述 |
|------|------|------|------|
| 0x00 | TX_CTRL | [0] start, [1] busy | 启动TX传输 |
| 0x04 | TX_BASE_ADDR | [31:0] | TX读取DDR基地址 |
| 0x08 | TX_FRAME_SIZE | [15:0] | TX有效载荷大小(46~1500B) |
| 0x0C | TX_DST_MAC | [47:0] | 目的MAC地址 |
| 0x10 | TX_SRC_MAC | [47:0] | 源MAC地址 |
| 0x14 | TX_ETH_TYPE | [15:0] | 以太网类型(默认0x0800) |
| 0x18 | TX_FRAME_CNT | [15:0] | 已发送帧数 |
| 0x20 | RX_CTRL | [0] start, [1] busy | 启动RX接收 |
| 0x24 | RX_BASE_ADDR | [31:0] | RX写入DDR基地址 |
| 0x28 | RX_FRAME_SIZE | [15:0] | 接收到的有效载荷大小 |
| 0x2C | RX_FRAME_CNT | [15:0] | 已接收帧数 |
| 0x30 | RX_ERR_CNT | [15:0] | FCS错误帧数 |
| 0x38 | STATUS | [0] link_up, [1] speed | 链路状态 |
| 0x3C | IRQ_STATUS | [0] tx_done, [1] rx_done, [2] rx_err | 中断状态 |
| 0x40 | PHY_CTRL | [0] mdio_req, [1] mdio_rw | MDIO控制 |
| 0x44 | PHY_ADDR | [4:0] PHY地址, [15:8] 寄存器地址 | MDIO目标 |
| 0x48 | PHY_DATA | [15:0] | MDIO读写数据 |

---

## 5 关键设计细节

### 5.1 数据宽度转换（64-bit ↔ 8-bit）

这是以太网方案与 Aurora 方案最大的架构差异。Aurora 使用 64-bit AXIS，而以太网 MAC 使用 8-bit AXIS。

**TX方向 (64→8)：**

```
AXI4 R通道 (64-bit/beat) ──→ 64→8 位宽转换 ──→ AXIS (8-bit/beat)
     │                         │                    │
     │ 1 beat = 8 bytes       │ 拆分为8次          │ 8 beats = 8 bytes
     │                         │ 传输               │
     ▼                         ▼                    ▼
  [D7 D6 D5 D4 D3 D2 D1 D0] → [D0]→[D1]→...→[D7] → MAC TX
```

**实现方式：**
- 方式1：使用 XPM_FIFO_ASYNC 的非对称位宽功能 (WRITE=64, READ=8)
- 方式2：自研位宽转换器 + 独立异步 FIFO

推荐方式1，XPM 内置位宽转换，资源更优。

**RX方向 (8→64)：**

```
MAC RX ──→ AXIS (8-bit/beat) ──→ 8→64 位宽转换 ──→ AXI4 W通道 (64-bit/beat)
              │                      │                    │
              │ 8 beats = 8 bytes   │ 组装为1次          │ 1 beat = 8 bytes
              │                      │ 传输               │
              ▼                      ▼                    ▼
           [D0]→[D1]→...→[D7]  →  [D7 D6 D5 D4 D3 D2 D1 D0]
```

**帧末尾处理：**
- 有效载荷可能不是 8 字节的整数倍
- 最后一拍 AXI4 W 数据可能只有部分有效
- 使用 `wstrb` 标记有效字节（如 100 字节有效载荷 = 12 拍完整 + 1 拍 4 字节，wstrb=0x0F）

### 5.2 跨时钟域

| 时钟域 | 频率 | 来源 | 用途 |
|--------|------|------|------|
| axi_clk | 250 MHz | XDMA M_AXI | DDR 访问 |
| axis_clk | 125 MHz | MAC TX/RX | 以太网帧处理 |
| rgmii_tx_clk | 125 MHz | FPGA ODDR 输出 | RGMII TX |
| rgmii_rx_clk | 125 MHz | 外部 PHY | RGMII RX |

**CDC 方案：**
- TX方向：异步 FIFO（axi_clk → axis_clk）
- RX方向：异步 FIFO（axis_clk → axi_clk）
- FIFO 深度：512（容纳 1 个最大以太网帧 1518B + 开销）

### 5.3 流控策略

| 场景 | TX方向 | RX方向 |
|------|--------|--------|
| MAC 反压 | tready=0 → FIFO 积累 → FIFO 将满停止 AR | — |
| DDR 反压 | — | W 通道反压 → FIFO 积累 → FIFO 将满 → tready=0 |
| 帧间隙 | MAC 自动插入 IPG (12B) | MAC 自动处理 |
| PAUSE 帧 | MAC 自动处理 | MAC 自动处理 |

### 5.4 以太网帧封装细节

**TX 帧封装（eth_tx 自动完成）：**

```
用户有效载荷 (46~1500 B)
         │
         ▼
┌──────────────────────────────────────┐
│ 目的MAC (6B) │ 源MAC (6B) │ 类型 (2B) │ 有效载荷 (46~1500B) │ 填充 (0~B) │
└──────────────────────────────────────┘
         │
         ▼ MAC 自动添加
┌──────────────────────────────────────────────────────┐
│ 前导码 (7B) │ SFD (1B) │ MAC头+数据 │ FCS (4B) │ IPG (12B) │
└──────────────────────────────────────────────────────┘
```

**RX 帧解封装（eth_rx 自动完成）：**

```
接收到的完整以太网帧
┌──────────────────────────────────────────────────────┐
│ 前导码 (7B) │ SFD (1B) │ MAC头+数据 │ FCS (4B) │
└──────────────────────────────────────────────────────┘
         │ MAC 自动剥离前导码、SFD、FCS
         ▼
┌──────────────────────────────────────┐
│ 目的MAC (6B) │ 源MAC (6B) │ 类型 (2B) │ 有效载荷 │
└──────────────────────────────────────┘
         │ eth_rx 剥离 MAC 头 (14B)
         ▼
有效载荷 (46~1500 B) ──→ DDR
```

---

## 6 性能与PPA分析

### 6.1 带宽分析

| 参数 | 值 | 说明 |
|------|-----|------|
| RGMII 线速率 | 1 Gbps | DDR 125MHz × 4bit × 2边 |
| 编码效率 | 100% | 无 64B/66B 编码开销 |
| MAC 开销 | ~2.4% | 前导码+SFD+FCS+IPG = 38B/1518B |
| 有效载荷带宽 | ~950 Mbps | 1500B/1518B × 1Gbps |
| AXI4 突发效率 | ~90% | ostd=4, 64B 突发 |

**与 Aurora 方案对比：**

| 参数 | Aurora (10G) | Ethernet RGMII (1G) | 比值 |
|------|-------------|---------------------|------|
| 线速率 | 10.3125 Gbps | 1 Gbps | 10:1 |
| 有效带宽 | ~9.5 Gbps | ~0.95 Gbps | 10:1 |
| 帧开销 | ~3% (64B/66B) | ~2.4% (以太网) | 相当 |
| 延迟 | ~100 ns | ~1~10 μs | 10~100:1 |

### 6.2 延迟分析

| 延迟来源 | TX方向 | RX方向 |
|----------|--------|--------|
| AXI4 AR/W 请求 | 2~4 clk | 2~4 clk |
| 异步 FIFO | 2~4 clk | 2~4 clk |
| 位宽转换 (64↔8) | 8 clk (1个64-bit字拆8拍) | 8 clk (8拍组装1个64-bit字) |
| 帧封装/解封装 | 14 clk (MAC头) | 14 clk (跳过MAC头) |
| MAC 内部缓冲 | 4~8 clk | 4~8 clk |
| **FPGA 内部总延迟** | **30~38 clk** | **30~38 clk** |
| 线缆延迟 | — | 5 ns/m |
| PHY 延迟 | — | ~100 ns (收发各) |

### 6.3 资源估算 (Xilinx UltraScale+)

| 资源 | eth_tx | eth_rx | MAC IP | 合计 |
|------|--------|--------|--------|------|
| LUT | ~600 | ~700 | ~1500 | ~2800 |
| FF | ~400 | ~500 | ~1200 | ~2100 |
| BRAM (36Kb) | 2 (FIFO) | 2 (FIFO) | 0 | 4 |
| DSP | 0 | 0 | 0 | 0 |

**与 Aurora 方案对比：**

| 资源 | Aurora DataMover方案 | Ethernet RGMII方案 | 差异 |
|------|----------------------|-------------------|------|
| LUT | ~1200 | ~2800 | +133% |
| FF | ~900 | ~2100 | +133% |
| BRAM | 2 | 4 | +100% |

**资源增加原因：**
- 64↔8 位宽转换逻辑（拆分/组装状态机）
- 以太网帧封装/解封装（MAC头处理、填充）
- MAC IP 核本身（~1500 LUT）
- 更深的 FIFO（以太网帧最大1518B vs Aurora帧1024B）

### 6.4 功耗估算

| 来源 | 功耗 |
|------|------|
| 组合逻辑 | ~80 mW |
| BRAM 动态 | ~30 mW |
| MAC IP | ~40 mW |
| I/O (RGMII DDR) | ~20 mW |
| **总计** | **~170 mW** |

### 6.5 PPA 综合评分

| 指标 | Aurora DataMover | Ethernet RGMII | 优势方 |
|------|------------------|-----------------|--------|
| 带宽 | ★★★★★ (9.5G) | ★★☆☆☆ (0.95G) | Aurora |
| 延迟 | ★★★★★ | ★★★☆☆ | Aurora |
| 面积 | ★★★★☆ | ★★★☆☆ | Aurora |
| 功耗 | ★★★★☆ | ★★★☆☆ | Aurora |
| 标准兼容性 | ★★☆☆☆ (Aurora私有) | ★★★★★ (IEEE 802.3) | Ethernet |
| 互操作性 | ★★☆☆☆ (需对端FPGA) | ★★★★★ (任何以太网设备) | Ethernet |
| 距离 | ★★☆☆☆ (<10m) | ★★★★★ (100m) | Ethernet |
| 设计复杂度 | ★★★★☆ (简单) | ★★★☆☆ (中等) | Aurora |

---

## 7 验证方案

### 7.1 验证环境

```
┌─────────────────────────────────────────────────────────┐
│                    Testbench                              │
│                                                           │
│  ┌──────────┐    ┌──────────────────┐    ┌───────────┐ │
│  │ AXI4 VIP │───→│  xdma_eth_rgmii  │───→│ MAC VIP   │ │
│  │ (Master)  │←───│  _top            │←───│ (RX Gen)  │ │
│  └──────────┘    └──────────────────┘    └───────────┘ │
│       │                                       │          │
│       │         ┌──────────┐                   │          │
│       └────────→│ DDR Model│←──────────────────┘          │
│                 └──────────┘                               │
│                                                           │
│  ┌──────────────────────────────────────────────┐        │
│  │ 比对：AXI4写入数据 vs MAC RX接收数据           │        │
│  └──────────────────────────────────────────────┘        │
└─────────────────────────────────────────────────────────┘
```

### 7.2 测试用例

| 编号 | 测试项 | 方法 | 通过标准 |
|------|--------|------|----------|
| T01 | 链路建立 | PHY MDIO配置 + 等待link_up | link_up=1 |
| T02 | 最小帧发送 | 发送64B有效载荷 | 对端收到完整帧 |
| T03 | 最大帧发送 | 发送1500B有效载荷 | 对端收到完整帧 |
| T04 | 非对齐帧 | 发送100B有效载荷 | 对端收到完整帧 |
| T05 | 填充帧 | 发送20B有效载荷(需填充到46B) | 对端收到46B+14B头 |
| T06 | 连续帧 | 连续发送100帧 | 帧间IPG正确 |
| T07 | TX反压 | MAC tready随机拉低 | 无数据丢失 |
| T08 | RX反压 | DDR W通道随机反压 | 无数据丢失 |
| T09 | FCS错误 | 注入错误帧 | frame_error=1, 丢弃 |
| T10 | 端到端 | AXI4写→MAC TX→MAC RX→AXI4读 | 数据一致 |

### 7.3 环回验证

**板内环回（无外部设备）：**
- 将 RGMII TX 输出通过内部逻辑环回到 RX 输入
- 验证 FPGA 内部数据通路完整性

**外部环回（需要网线+对端设备）：**
- 通过网线连接到另一台设备（PC/交换机）
- 使用 ping/iperf3 验证链路

---

## 8 CPU 驱动流程

### 8.1 初始化

```c
// 1. 复位PHY
write_reg(PHY_RST, 0);
usleep(10000);
write_reg(PHY_RST, 1);
usleep(100000);

// 2. 配置PHY (通过MDIO)
mdio_write(PHY_ADDR, 0x00, 0x1140);  // 自协商+重启

// 3. 等待链路建立
while (!(read_reg(STATUS) & 0x1))
    usleep(1000);

// 4. 配置MAC地址
write_reg(TX_DST_MAC, 0xFFFFFFFFFFFF);  // 广播
write_reg(TX_SRC_MAC, 0x000A35000102);    // 本地MAC
write_reg(TX_ETH_TYPE, 0x0800);          // IPv4
```

### 8.2 发送数据

```c
// 1. 准备发送数据到DDR
memcpy(ddr_tx_buf, data, data_len);

// 2. 配置TX寄存器
write_reg(TX_BASE_ADDR, ddr_tx_buf_phys);
write_reg(TX_FRAME_SIZE, data_len);
write_reg(TX_CTRL, 0x1);  // start

// 3. 等待完成
wait_irq(TX_DONE_IRQ);
```

### 8.3 接收数据

```c
// 1. 配置RX寄存器
write_reg(RX_BASE_ADDR, ddr_rx_buf_phys);
write_reg(RX_CTRL, 0x1);  // start

// 2. 等待接收完成
wait_irq(RX_DONE_IRQ);

// 3. 检查错误
if (read_reg(IRQ_STATUS) & 0x4)
    handle_error();

// 4. 读取接收数据
rx_len = read_reg(RX_FRAME_SIZE);
memcpy(data, ddr_rx_buf, rx_len);
```

---

## 9 与 Aurora 方案的架构差异总结

### 9.1 数据通路对比

```
Aurora方案:
XDMA ─AXI4─→ DataMover ─AXIS(64b)─→ Aurora IP ─GT─→ 光纤/背板

以太网方案:
XDMA ─AXI4─→ eth_tx ─AXIS(8b)─→ MAC IP ─RGMII─→ PHY ─网线─→ 交换机/PC
              │                    │
              │ 帧封装(14B头)       │ 前导码/FCS
              │ 64→8位宽转换        │ 8bit处理
              │                     │
```

### 9.2 关键差异

| 差异点 | Aurora | Ethernet RGMII |
|--------|--------|----------------|
| 数据宽度 | 64-bit | 8-bit (需位宽转换) |
| 帧封装 | 无 (裸数据) | 14B MAC头 + FCS |
| 帧大小限制 | 无 | 64~1518 B (标准) |
| 位宽转换 | 不需要 | 64↔8 (核心复杂度) |
| MAC IP | 不需要 | 必须 |
| PHY 管理 | 不需要 | MDIO 配置 |
| 线缆 | 光纤/背板 | Cat5e 网线 |
| 对端设备 | 另一个FPGA | 任何以太网设备 |

### 9.3 选型建议

| 场景 | 推荐方案 | 原因 |
|------|----------|------|
| 板间高速互联 (>1G) | Aurora | 带宽高、延迟低 |
| 标准网络通信 | Ethernet RGMII | 兼容性好、互操作性强 |
| CPU 远程访问 | Ethernet RGMII | 可通过 TCP/IP 协议栈 |
| 实时数据流 | Aurora | 确定性延迟 |
| 调试/监控 | Ethernet RGMII | 可用标准网络工具 |

---

## 10 结论

XDMA 直连以太网 RGMII 方案的核心挑战在于：

1. **64↔8 位宽转换**：AXI4 64-bit 与 MAC 8-bit 之间的数据宽度差异，需要异步 FIFO + 位宽转换逻辑
2. **以太网帧封装/解封装**：MAC 头处理、填充、FCS 校验等以太网协议开销
3. **PHY 管理**：MDIO 配置外部 PHY 芯片，增加初始化复杂度

相比 Aurora 方案，以太网方案带宽降低 10 倍（1G vs 10G），但具有标准兼容性和互操作性优势。适用于需要与标准以太网设备通信的场景，而非板间高速互联场景。
