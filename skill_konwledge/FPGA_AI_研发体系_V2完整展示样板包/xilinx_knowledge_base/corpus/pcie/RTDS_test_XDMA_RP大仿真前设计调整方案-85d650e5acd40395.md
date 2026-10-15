# RTDS_test_XDMA_RP大仿真前设计调整方案

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_XDMA_RP大仿真前设计调整方案.md`
- SHA-256: `85d650e5acd40395e2bac016bd811e54fb511bd0bcc46c0a3af264d37dd15929`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test XDMA + FDMA2AURORA 大仿真前设计调整方案

版本：V1.0
日期：2026-07-09
目标：在原 `fdmatx -> locallinktx -> aurora -> locallinkrx -> fdmarx` 环路已经完成 UT、IT 和上板调试的基础上，最小化修改当前 RTDS_test 工程，使其适合做 **XDMA + Root Port Model 通路 try-through 大仿真**。

---

## 1. 结论先行

当前阶段不建议再重做原始 FDMA/Aurora 数据桥的完整单元验证。更合适的策略是：

```text
原桥已有 UT/IT/上板验证
        ↓
当前只做必要 RTL 整理
        ↓
adapter 用代码检视 + 少量仿真断言兜底
        ↓
直接上 XDMA + Root Port Model 大仿真 try-through
```

这里的大仿真目标不是证明 Xilinx XDMA IP 正确，也不是重新证明 FDMA2AURORA 桥正确，而是证明：

```text
Root Port / Host 激励
  -> XDMA
  -> design_1_wrapper
  -> CONV_DMA / INFO_EXCH / payload window
  -> PCIe.v
  -> pcie_fdma_aurora_brg_adapter
  -> FDMA2AURORA 完整异步桥
  -> Aurora loopback 或 Aurora RX 注入
  -> FDMA write
  -> XDMA C2H 读回
```

能从“软件入口”到“硬件数据面”和“中断/status”跑通。

---

## 2. 当前工程事实与设计边界

根据已有工程文档，当前 RTDS_test 的真实集成点是：

```text
TOP.v -> PCIe.v -> pcie_fdma_aurora_brg_adapter.v -> design_1_wrapper/CONV_DMA
```

`TOP.v` 保持板级顶层；`PCIe.v` 保持原模块名和原端口；`design_1_wrapper` 内部保留 XDMA、CONV_DMA、INFO_EXCH 和 BRAM/payload window。

当前文档也已经明确：完整 FDMA2AURORA 异步桥已经包含 Aurora 与 FIFO CDC，因此最终主路径不应继续经过旧的 `DATA_CDC`。旧 `DATA_CDC` 只能作为遗留 debug/占位路径，不应作为产品主链路或大仿真的主链路。

---

## 3. 是否还需要 DATA_CDC

### 3.1 最终主路径：不要 DATA_CDC

如果当前 `fdma2ll` / `FDMA2AURORA` 转换桥已经包含：

```text
FDMA read/write
LocalLink TX/RX
Aurora IP/GT
Aurora RX FIFO
Aurora TX FIFO
跨时钟 FIFO CDC
channel_up / lane_up 状态
```

那么大仿真的主路径应改成：

```text
XDMA / CONV_DMA / INFO_EXCH
        |
      PCIe.v
        |
pcie_fdma_aurora_brg_adapter
        |
FDMA2AURORA 完整异步桥
        |
Aurora loopback / Aurora peer model / Aurora RX BFM
```

不再是：

```text
PCIe.v
  -> adapter 66-bit stream
  -> DATA_CDC
  -> Aurora_frame_gen / debug stream
```

### 3.2 DATA_CDC 的保留方式

建议保留文件，但从主链路退出：

```verilog
`ifdef LEGACY_DEBUG_STREAM
    // 保留旧 DATA_CDC / Aurora_frame_gen debug 路径
`else
    // 默认产品/大仿真路径：adapter 直连 FDMA2AURORA 完整桥
`endif
```

这样做的好处是：

1. 不破坏历史 debug bring-up 手段。
2. 大仿真主路径不会重复跨域。
3. 不会出现两套 Aurora/CDC 边界互相混淆。
4. 后续上板也可以按 `LEGACY_DEBUG_STREAM` 开关临时回退观察。

---

## 4. adapter 当前承担的功能与必要性

adapter 不是重做原始 FDMA/Aurora 环路，而是保留 RTDS_test 原软件协议的适配层。它的必要性主要在控制面和边界适配。

| adapter 功能 | 必要性 |
|---|---|
| 接收 `RD_START`、`CPU_FPGA_START_ADDR`、`CPU_FPGA_LEN` | 让原软件仍按 INFO_EXCH 寄存器启动传输 |
| 锁存地址和长度 | 防止软件寄存器在传输中途变化影响当前 frame |
| 512B 对齐检查 | 原桥按 64 个 64-bit beat，即 512B frame 传输 |
| 生成 FDMA read 请求 | 把软件启动转换成 `fdma_raddr/fdma_rareq/fdma_rsize` |
| 生成 FDMA write 完成状态 | 把 Aurora RX 完成转换成 CPU 可读地址、长度和 IRQ |
| 固定 `fdma_rsize/fdma_wsize=64` | 匹配原 bridge 的 512B frame 粒度 |
| 32-bit 软件地址扩展到 64-bit FDMA 地址 | 避免隐式位宽扩展和地址截断 |
| `CPU_WR_DONE_resp` | 保持原 INFO_EXCH/软件 done 语义 |
| `INT_STATE_W/FPGA_CPU_irq_req` | 保持原 CPU 中断/status 语义 |
| `CLEAR_INTER_R/INT_STATE_R` 清中断 | 保持原软件读状态/清中断流程 |
| sticky 状态 | 暴露 RX FIFO overflow、timeout、length error 等 bring-up 线索 |
| `link_enable` 门控 | 避免 PCIe up 但 Aurora 未 up 时误启动 |

因此，adapter 的本质是：

```text
INFO_EXCH/软件寄存器语义
        ↓
FDMA2AURORA 桥的 start/done/FDMA/frame 语义
```

---

## 5. 当前设计建议怎么调整

### 5.1 不改 XDMA IP，不改 CONV_DMA，不改 INFO_EXCH 主协议

保持：

```text
design_1_wrapper
  ├─ XDMA
  ├─ CONV_DMA
  ├─ INFO_EXCH
  └─ payload window / BRAM
```

原因：

1. 你当前只是做通路 try-through，不是重构 PCIe 子系统。
2. 原软件协议依赖 INFO_EXCH 寄存器语义。
3. 情况 B 下 payload 通过 XDMA H2C/C2H 搬运，不能绕开 XDMA。
4. 修改 BD 地址分配会牵动 wrapper、驱动、脚本和回归验证。

### 5.2 PCIe.v 内部连接调整

当前建议目标结构：

```text
PCIe.v
  ├─ design_1_wrapper
  │   ├─ XDMA
  │   ├─ CONV_DMA fdma_r*/fdma_w*
  │   └─ INFO_EXCH control/status
  │
  ├─ pcie_fdma_aurora_brg_adapter
  │   ├─ INFO_EXCH 控制输入
  │   ├─ IRQ/status 输出
  │   ├─ FDMA read/write 边界
  │   └─ bridge start/status 边界
  │
  └─ FDMA2AURORA 完整异步桥
      ├─ FDMA read/write
      ├─ 内部 FIFO CDC
      ├─ Aurora TX/RX
      └─ channel_up/lane_up/fifo_status
```

### 5.3 adapter 是否要改成“控制适配器”

如果完整 FDMA2AURORA 桥已经直接提供 FDMA 读写接口，那么 adapter 最干净的形式应是：

```text
adapter 只保留：
  INFO_EXCH 控制
  地址/长度锁存
  start/done
  IRQ/status
  link_enable
  sticky/error
  对 FDMA2AURORA top 的控制/status 连接
```

不再把 66-bit `{SOF,data,EOF}` stream 当主路径。

若当前 adapter 代码仍含旧 66-bit stream 输入输出，可采用两个阶段：

### 阶段 1：低风险兼容修改

保留旧 stream 端口，但默认不接主路径：

```verilog
parameter USE_LEGACY_STREAM = 1'b0;
```

`USE_LEGACY_STREAM=0` 时：

```text
adapter -> FDMA2AURORA full bridge control/FDMA boundary
```

`USE_LEGACY_STREAM=1` 时：

```text
adapter -> legacy 66-bit stream / DATA_CDC debug path
```

### 阶段 2：产品化清理

当大仿真和上板都通过后，再删除或彻底旁路旧 66-bit debug 主路径，只保留必要 debug hook。

---

## 6. link_enable 建议

当前 `link_enable` 如果只接 `user_lnk_up_int`，只能说明 PCIe 链路可用，不代表 Aurora 可发送。

建议最终改成：

```verilog
link_enable = pcie_link_up_sync && bridge_channel_up_sync && bridge_lane_up_sync;
```

其中 `bridge_channel_up/lane_up` 如果来自 Aurora 时钟域，需要同步到 adapter 所在时钟域。

在大仿真第一版中，如果暂时没有真实 Aurora link training，可先用：

```verilog
assign bridge_channel_up_sim = 1'b1;
assign bridge_lane_up_sim    = 1'b1;
```

但必须在仿真日志中标注：

```text
本次大仿真只验证 PCIe/XDMA/FDMA/control try-through，
不验证真实 Aurora GT link training。
```

---

## 7. RX FIFO 状态和压力测试观测点

你当前重点关注压力测试和 Aurora RX FIFO 状态，因此需要在 RTL 中明确导出以下状态：

```text
rx_fifo_level
rx_fifo_almost_full
rx_fifo_full
rx_overflow_sticky
rx_frame_cnt
rx_drop_cnt
fdma_w_stall_cnt
fdma_w_timeout_sticky
aurora_channel_up
aurora_lane_up
```

短期可以只进 ILA / 仿真 waveform，不一定马上加软件可读寄存器。

更稳的写法：

```verilog
output wire [15:0] dbg_rx_fifo_level,
output wire        dbg_rx_fifo_almost_full,
output wire        dbg_rx_fifo_full,
output wire        dbg_rx_overflow_sticky,
output wire [31:0] dbg_rx_frame_cnt,
output wire [31:0] dbg_fdma_w_stall_cnt
```

如果后续软件需要长期压力测试，建议从 `0x0030` 之后扩展 INFO_EXCH 或新增 AXI-Lite status slave，但这不是当前 try-through 的必要条件。

---

## 8. 少量 assert 应该加在哪里

### 8.1 推荐方式：放验证文件，用 bind 绑定到 DUT

不要直接把大量 SystemVerilog assertion 混进正式设计文件。推荐新增：

```text
sim/assert/pcie_fdma_aurora_brg_adapter_sva.sv
sim/assert/fdma2aurora_sva.sv
sim/assert/xdma_trythrough_bind.sv
```

通过 `bind` 方式挂到 DUT 内部：

```systemverilog
bind pcie_fdma_aurora_brg_adapter pcie_fdma_aurora_brg_adapter_sva u_adapter_sva (.*);
```

优点：

1. 不污染可综合 RTL。
2. 不影响 Vivado synthesis。
3. 大仿真、局部仿真都能复用。
4. 断言失败时定位直接。

### 8.2 备选方式：RTL 内加 `ifdef SIM_ASSERT`

如果工具或层级不方便 bind，可以在 RTL 内加：

```systemverilog
`ifdef SIM_ASSERT
    always @(posedge clk) begin
        if (!rst) begin
            assert (fdma_rsize == 16'd64);
        end
    end
`endif
```

但要确保综合脚本不定义 `SIM_ASSERT`。

### 8.3 当前阶段建议的最小断言

只放和 try-through 强相关的断言：

```systemverilog
// FDMA read 请求时 size 必须是 64 beat
property p_fdma_rsize_64;
  @(posedge clk) disable iff (rst)
    fdma_rareq |-> (fdma_rsize == 16'd64);
endproperty
assert property (p_fdma_rsize_64);

// FDMA write 请求时 size 必须是 64 beat
property p_fdma_wsize_64;
  @(posedge clk) disable iff (rst)
    fdma_wareq |-> (fdma_wsize == 16'd64);
endproperty
assert property (p_fdma_wsize_64);

// TX 未 link_enable 时不应启动
property p_no_tx_when_link_down;
  @(posedge clk) disable iff (rst)
    (!link_enable) |-> !bridge_tx_start;
endproperty
assert property (p_no_tx_when_link_down);

// valid && !ready 时 data 保持稳定
property p_fdma_wdata_stable_when_stalled;
  @(posedge clk) disable iff (rst)
    (fdma_wvalid && !fdma_wready) |=> $stable(fdma_wdata);
endproperty
assert property (p_fdma_wdata_stable_when_stalled);
```

### 8.4 压力测试中不要把 overflow 永远当失败

如果你故意做 RX 压力，把输入速率推到超过 FDMA/CPU 读取能力，那么 `rx_overflow_sticky` 置位可能是预期结果。

因此建议：

```text
普通 try-through：
  assert no rx_overflow_sticky

压力测试：
  cover rx_fifo_almost_full
  cover rx_fifo_full
  observe rx_overflow_sticky
  不直接判失败，除非设计要求永不丢帧
```

---

## 9. 大仿真前设计检查清单

### RTL 检查

- [ ] `TOP.v` 仍为 synthesis top。
- [ ] 大仿真建议实例化 `PCIe.v` 或专用 sim wrapper，避免 TEMP/LED/板级无关逻辑干扰。
- [ ] `PCIe.v` 保留真实 `design_1_wrapper`。
- [ ] `DATA_CDC` 不在大仿真主路径中。
- [ ] `adapter` 直连完整 FDMA2AURORA 桥或通过 `USE_LEGACY_STREAM=0` 旁路旧 stream。
- [ ] `fdma_rsize/fdma_wsize=64`。
- [ ] `fdma_raddr/fdma_waddr` 为显式 64-bit。
- [ ] `link_enable` 最终由 PCIe up 与 Aurora up 相与。
- [ ] RX FIFO status/sticky 导出到 waveform/ILA。
- [ ] 旧 debug 66-bit stream 只作为 debug hook，不作为默认路径。

### 仿真检查

- [ ] XDMA / PCIe IP 仿真模型已加入。
- [ ] Root Port Model 与当前 XDMA 配置匹配。
- [ ] Root Port TPI 能发起 H2C/C2H descriptor。
- [ ] Host memory model 已初始化。
- [ ] INFO_EXCH 寄存器地址表已映射到 TPI task。
- [ ] payload window 地址与软件一致。
- [ ] 关键 SVA 通过 bind 加入。
- [ ] waveform 记录 adapter、FDMA、FIFO、IRQ、XDMA status。

---

## 10. 推荐最终文件组织

```text
RTDS_test/
  sim/
    xdma_trythrough/
      tb_xdma_rtds_trythrough.sv
      rp_tpi_rtds_tasks.svh
      host_mem_model.sv
      aurora_loopback_or_rx_bfm.sv
      xdma_rtds_scoreboard.sv
      xdma_trythrough_bind.sv
      run_xdma_trythrough_xsim.ps1
      run_xdma_trythrough.tcl

    assert/
      pcie_fdma_aurora_brg_adapter_sva.sv
      fdma2aurora_fifo_sva.sv

  rtl/
    或 sources_1/new/
      PCIe.v
      pcie_fdma_aurora_brg_adapter.v
      fdma_aurora_brg_top.v
```

---

## 11. 本文最终建议

当前设计不需要为了大仿真而重构全部工程。建议只做这几件事：

1. 从主链路移除或旁路 `DATA_CDC`。
2. 让 `adapter` 直接服务于完整 FDMA2AURORA 桥。
3. 保持 XDMA / CONV_DMA / INFO_EXCH / payload window 不变。
4. 把 `link_enable` 从纯 `user_lnk_up` 升级为 `pcie_link_up && aurora_channel_up && aurora_lane_up`。
5. 导出 RX FIFO 关键状态。
6. 少量断言放在仿真文件里，用 `bind` 挂上。
7. 直接做 XDMA + Root Port Model try-through。
