# RTDS_test_XDMA_RootPort大仿真验证方案

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_XDMA_RootPort大仿真验证方案.md`
- SHA-256: `f7fda5a4ddbf140c8d62916283cf76b1787de72de0336ced8fe88c2ad154c140`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test XDMA + Root Port Model 大仿真验证方案

版本：V1.0
日期：2026-07-09
目标：针对“情况 B：payload 通过 XDMA H2C/C2H 搬运”的系统级 try-through 仿真，验证从仿真 Host 入口到 XDMA、INFO_EXCH、adapter、FDMA2AURORA 桥、Aurora RX FIFO/status、再到 XDMA C2H 读回的完整通路。

---

## 1. 验证目标

本方案不是重验 Xilinx XDMA IP 正确性，也不是重验已经完成 UT、IT 和上板调试的原始 FDMA/Aurora 大环路。

目标是证明：

```text
Root Port Model / Host TPI
  -> XDMA H2C
  -> payload window
  -> INFO_EXCH 寄存器启动
  -> adapter 控制与 FDMA read
  -> FDMA2AURORA TX
  -> Aurora loopback 或 Aurora RX 注入
  -> FDMA2AURORA RX FIFO
  -> FDMA write 回 payload window
  -> IRQ/status
  -> XDMA C2H
  -> Host memory compare
```

第一版只要求 try-through PASS：

```text
1 个 512B frame 能通过
多帧能通过
IRQ/status 能置位和清除
Host 端读回数据一致
压力场景能观察 Aurora RX FIFO 状态
```

不覆盖非 512B 对齐长度，不追求协议覆盖率。

---

## 2. 大仿真模型总结构

建议大仿真顶层：

```text
tb_xdma_rtds_trythrough.sv
  ├─ Root Port Model / TPI
  │   ├─ PCIe downstream TLP 产生
  │   ├─ PCIe upstream TLP 接收
  │   ├─ Host memory model
  │   ├─ H2C descriptor 配置 task
  │   ├─ C2H descriptor 配置 task
  │   └─ BAR/register read/write task
  │
  ├─ DUT wrapper
  │   ├─ PCIe.v
  │   │   ├─ design_1_wrapper
  │   │   │   ├─ XDMA
  │   │   │   ├─ CONV_DMA
  │   │   │   ├─ INFO_EXCH
  │   │   │   └─ payload window / BRAM
  │   │   │
  │   │   ├─ pcie_fdma_aurora_brg_adapter
  │   │   └─ FDMA2AURORA 完整异步桥
  │   │
  │   └─ 可选：Aurora sim wrapper / Aurora loopback
  │
  ├─ Aurora peer / loopback / RX BFM
  ├─ Scoreboard
  ├─ Assertion bind
  └─ Wave dump
```

如果 `TOP.v` 中包含太多板级无关逻辑，例如 LED、TEMP、CLK_GEN、DATA_CDC，可以不直接仿 `TOP.v`，而是建一个专用仿真 wrapper：

```text
tb_xdma_rtds_trythrough
  -> rtds_pcie_fdma_aurora_sim_wrapper
       -> PCIe.v
       -> FDMA2AURORA full bridge
```

专用 sim wrapper 要保持 PCIe Endpoint 端口与 Root Port Model 可连接。

---

## 3. XDMA 仿真模型与 Root Port Model 的分工

### 3.1 XDMA 仿真模型

XDMA 仿真模型是 DUT 里 XDMA Endpoint 的仿真表示，来自 Vivado 生成的 IP/BD simulation target。它让仿真器能够展开和运行 `design_1_wrapper` 内部的 XDMA、PCIe hard block 相关模型、AXI/BRAM 等 IP。

它不是激励源。

### 3.2 Root Port Model

Root Port Model 是 testbench 侧的 Host/Root Complex BFM。它用于：

```text
1. 产生 downstream PCIe TLP
2. 接收 upstream PCIe TLP
3. 模拟 Host memory
4. 通过 TPI task 做 BAR 读写、H2C/C2H descriptor、polling、数据比较
```

完整仿真必须同时有：

```text
DUT 内部：XDMA/IP simulation model
TB 侧：Root Port Model / TPI / Host memory model
```

---

## 4. 情况 B 的软件激励如何给

情况 B 中，payload 不是简单 BAR 直写，而是通过 XDMA H2C/C2H 搬运。因此仿真软件流程应映射成 Root Port TPI task。

真实软件流程：

```text
1. CPU 准备 TX payload
2. CPU 通过 XDMA H2C 写 payload buffer
3. CPU 写 CPU_FPGA_START_ADDR
4. CPU 写 CPU_FPGA_LEN
5. CPU 写 CPU_WR_DONE
6. FPGA 通过 adapter/bridge 发 TX
7. Aurora RX 数据写回 payload window
8. FPGA 置 IRQ/status
9. CPU 通过 XDMA C2H 读回 payload
10. CPU 比较数据并清中断
```

Root Port TPI 仿真流程：

```text
1. host_mem_write(tx_src_addr, pattern, len)
2. xdma_h2c_transfer(
       host_src_addr = tx_src_addr,
       card_dst_addr = payload_base,
       len           = 512 * frame_num
   )
3. rp_bar_write(INFO_EXCH_START_ADDR_REG, payload_base)
4. rp_bar_write(INFO_EXCH_LEN_REG, 512 * frame_num)
5. rp_bar_write(INFO_EXCH_CPU_WR_DONE_REG, 1)
6. wait_tx_done_or_poll_status()
7. aurora_loopback_or_rx_bfm_inject()
8. wait_irq_or_poll_int_state()
9. xdma_c2h_transfer(
       card_src_addr = rx_payload_base,
       host_dst_addr = rx_dst_addr,
       len           = 512 * frame_num
   )
10. compare_host_memory(tx_expected_or_rx_expected, rx_dst_addr)
11. rp_bar_read_or_write_clear_interrupt()
```

---

## 5. Test 规划

### 5.1 Test 0：仿真环境 bring-up

目的：只确认模型能编译、elaborate、PCIe link 能起来。

步骤：

```text
1. 编译 XDMA/BD/IP 仿真模型
2. 编译 Root Port Model
3. 编译 DUT wrapper
4. 连接 PCIe RX/TX 差分端口
5. 释放 reset
6. 等待 user_lnk_up
7. 读一个只读寄存器或固定状态寄存器
```

PASS 标准：

```text
PCIe link up
Root Port 能完成基本配置
BAR read/write 不超时
仿真无 fatal/error
```

### 5.2 Test 1：XDMA H2C payload 写入

目的：确认 Host memory 到 Card payload window 的 H2C 搬运正常。

步骤：

```text
1. Host memory 写入 512B pattern
2. Root Port 配置 H2C descriptor
3. 等待 H2C completed
4. 可选：通过 BAR/调试口或内部 monitor 检查 payload window 内容
```

PASS 标准：

```text
H2C descriptor completed
payload window 内部数据与 Host pattern 一致
```

### 5.3 Test 2：INFO_EXCH 启动 TX

目的：确认软件寄存器流程能触发 adapter 和 FDMA read。

步骤：

```text
1. rp_bar_write(CPU_FPGA_START_ADDR, payload_base)
2. rp_bar_write(CPU_FPGA_LEN, 512)
3. rp_bar_write(CPU_WR_DONE, 1)
4. 观察 INFO_EXCH RD_START
5. 观察 adapter fdma_rareq
6. 观察 fdma_rsize=64
7. 观察 fdma_raddr={32'd0,payload_base}
```

PASS 标准：

```text
RD_START 产生
adapter 发出 fdma_rareq
fdma_rsize=64
TX frame 输出 SOF/EOF 正确
CPU_WR_DONE_resp 正确返回
```

### 5.4 Test 3：TX 到 RX loopback 单帧

目的：确认 TX 输出能回到 RX，完成 FDMA write 和 IRQ。

两种方式：

```text
方式 A：Aurora 内部 loopback
  FDMA2AURORA TX -> Aurora loopback -> FDMA2AURORA RX

方式 B：Aurora RX BFM 注入
  不依赖真实 Aurora TX，直接由 BFM 按协议输入一帧 RX 数据
```

第一版建议用方式 A。如果 Aurora IP/GT 仿真太重，可先用方式 B。

PASS 标准：

```text
RX FIFO 收到一帧
fdma_wareq 产生
fdma_wsize=64
写完后 FPGA_CPU_irq_req 置位
INT_STATE_W 置位
FPGA_CPU_START_ADDR/FPGA_CPU_LEN 更新
```

### 5.5 Test 4：XDMA C2H 读回与 Host compare

目的：确认 RX 写回后的 payload 能被 Host 通过 C2H 读回。

步骤：

```text
1. 等待 RX done/IRQ/status
2. Root Port 配置 C2H descriptor
3. card_src_addr = FPGA_CPU_START_ADDR 对应 payload 地址
4. host_dst_addr = rx_host_buffer
5. len = FPGA_CPU_LEN
6. 等 C2H completed
7. Host memory compare
```

PASS 标准：

```text
C2H completed
Host rx buffer 与预期 pattern 一致
```

### 5.6 Test 5：多帧 try-through

目的：确认连续帧基本通路可用，不追求极限压力。

推荐帧数：

```text
2 frames
16 frames
64 frames
```

检查：

```text
fdma_raddr 每帧递增 512B
fdma_waddr 每帧递增 512B 或按窗口策略回绕
rx_frame_cnt 正确
tx_frame_cnt 正确
无非预期 overflow
Host compare 全部通过
```

### 5.7 Test 6：RX FIFO 压力观测

目的：只观察压力下 Aurora RX FIFO 状态，不一定要求永不 overflow。

推荐两种压力源：

#### 压力源 A：RX BFM 高速注入

```text
Aurora RX BFM 连续注入 N 帧
帧间隔设为 0 或很短
Host 延迟 C2H 读取
观察 rx_fifo_level/almost_full/full/overflow_sticky
```

#### 压力源 B：降低 sim FIFO 深度

如果 FIFO 深度参数可改，可以在仿真中用较小 FIFO：

```text
SIM_RX_FIFO_DEPTH = 4 frames 或 8 frames
```

更容易触发 almost_full/full。

PASS/观察标准：

```text
rx_fifo_level 能上升
rx_fifo_almost_full 能出现
rx_fifo_full 能出现或可解释地不出现
rx_overflow_sticky 若出现，仿真报告记录发生时间和输入速率
无未知 X 传播
无死锁
系统能在停止注入后 drain FIFO 或进入可解释状态
```

注意：压力测试中 overflow 不一定判 FAIL，除非设计目标声明“该输入速率下必须无丢帧”。

### 5.8 Test 7：清中断

目的：确认软件能清除 RX 中断/status。

步骤：

```text
1. 等待 FPGA_CPU_irq_req=1
2. rp_bar_read(INT_STATE) 或写 clear
3. 观察 CLEAR_INTER_R / INT_STATE_R
4. 观察 FPGA_CPU_irq_req 清零
5. 观察 INT_STATE_W 清零
```

PASS 标准：

```text
中断可清
清除后可再次触发下一帧中断
```

---

## 6. 关键 monitor 与 waveform

必须记录以下信号：

```text
PCIe/XDMA:
  user_lnk_up
  h2c descriptor start/done
  c2h descriptor start/done
  BAR write/read task log

INFO_EXCH:
  CPU_FPGA_START_ADDR
  CPU_FPGA_LEN
  CPU_WR_DONE
  RD_START
  CPU_WR_DONE_resp
  INT_STATE_R
  CLEAR_INTER_R

adapter:
  link_enable
  tx_active
  rx_active
  fdma_rareq
  fdma_raddr
  fdma_rsize
  fdma_rvalid
  fdma_rready
  fdma_wareq
  fdma_waddr
  fdma_wsize
  fdma_wvalid
  fdma_wready
  FPGA_CPU_START_ADDR
  FPGA_CPU_LEN
  INT_STATE_W
  FPGA_CPU_irq_req

FDMA2AURORA:
  tx_frame_cnt
  rx_frame_cnt
  tx_sof/tx_eof
  rx_sof/rx_eof
  rx_fifo_level
  rx_fifo_almost_full
  rx_fifo_full
  rx_overflow_sticky
  fdma_w_stall_cnt

Aurora:
  channel_up
  lane_up
  hard_err/soft_err
```

---

## 7. Scoreboard 设计

### 7.1 Host memory scoreboard

维护两块 Host memory：

```text
host_tx_buffer：H2C 输入 pattern
host_rx_buffer：C2H 读回数据
```

比较逻辑：

```text
for i in 0 .. len-1:
    if host_rx_buffer[i] != expected[i]:
        error_count++
```

### 7.2 Frame scoreboard

记录：

```text
TX frame id
TX payload checksum
RX frame id
RX payload checksum
C2H readback checksum
```

第一版不需要复杂乱序支持，因为 try-through 只跑顺序帧。

---

## 8. Assertion 方案

断言文件放在仿真目录中，通过 bind 加入，不放入正式 RTL 主体。

推荐文件：

```text
sim/assert/pcie_fdma_aurora_brg_adapter_sva.sv
sim/assert/fdma2aurora_fifo_sva.sv
sim/xdma_trythrough/xdma_trythrough_bind.sv
```

最小断言集：

```systemverilog
// 1. FDMA read request size
assert property (@(posedge clk) disable iff (rst)
    fdma_rareq |-> (fdma_rsize == 16'd64));

// 2. FDMA write request size
assert property (@(posedge clk) disable iff (rst)
    fdma_wareq |-> (fdma_wsize == 16'd64));

// 3. link down 不启动 TX
assert property (@(posedge clk) disable iff (rst)
    (!link_enable) |-> !bridge_tx_start);

// 4. valid 且 ready=0 时数据稳定
assert property (@(posedge clk) disable iff (rst)
    (fdma_wvalid && !fdma_wready) |=> $stable(fdma_wdata));

// 5. 普通 try-through 测试中不应 overflow
assert property (@(posedge clk) disable iff (rst)
    normal_trythrough_mode |-> !rx_overflow_sticky);
```

压力测试中第 5 条要关闭或改成 cover：

```systemverilog
cover property (@(posedge clk) disable iff (rst)
    rx_fifo_almost_full);

cover property (@(posedge clk) disable iff (rst)
    rx_fifo_full);
```

---

## 9. Root Port TPI task 建议

建立 `rp_tpi_rtds_tasks.svh`，封装和软件动作等价的任务。

```systemverilog
task rtds_h2c_write_payload(
    input longint unsigned host_src,
    input longint unsigned card_dst,
    input int unsigned     len
);
    // 1. 写 XDMA H2C descriptor
    // 2. 启动 H2C
    // 3. poll completed
endtask

task rtds_write_info_exch_start(
    input int unsigned card_payload_addr,
    input int unsigned len
);
    rp_bar_write(CPU_FPGA_START_ADDR_OFFSET, card_payload_addr);
    rp_bar_write(CPU_FPGA_LEN_OFFSET,        len);
    rp_bar_write(CPU_WR_DONE_OFFSET,         32'h1);
endtask

task rtds_wait_irq_or_status();
    // 轮询 INT_STATE 或等待 user irq
endtask

task rtds_c2h_read_payload(
    input longint unsigned card_src,
    input longint unsigned host_dst,
    input int unsigned     len
);
    // 1. 写 XDMA C2H descriptor
    // 2. 启动 C2H
    // 3. poll completed
endtask

task rtds_clear_irq();
    // 读 INT_STATE 或写 clear，按 INFO_EXCH 实际协议
endtask
```

---

## 10. Vivado / XSim 执行方式

### 10.1 推荐准备方式

1. 在 Vivado 中对当前 `design_1` 生成 simulation target：

```tcl
generate_target simulation [get_files design_1.bd]
```

2. 导出仿真脚本：

```tcl
export_simulation -simulator xsim -directory ./sim_export_xsim -force
```

3. 对相同 XDMA 配置生成 XDMA example design，提取 Root Port Model/TPI 相关 testbench 文件。

4. 将 example design 中 endpoint 实例替换为当前 `rtds_pcie_fdma_aurora_sim_wrapper`。

5. 保证 Root Port Model 参数与当前 XDMA endpoint 配置一致：

```text
link width
link speed
AXI-MM / AXI-Lite / DMA 配置
BAR size/address map
descriptor mode
interrupt mode
```

### 10.2 目录建议

```text
RTDS_test/
  regression/
    sim_xdma_trythrough/
      run_xdma_trythrough_xsim.ps1
      run_xdma_trythrough.tcl
      filelist_xdma_trythrough.f
      logs/
      waves/
      reports/
```

### 10.3 运行命令示意

```powershell
powershell.exe -ExecutionPolicy Bypass `
  -File "E:\PCIE-CPU\RTDS_test\regression\sim_xdma_trythrough\run_xdma_trythrough_xsim.ps1"
```

脚本内部建议分步：

```text
xvlog XPM/IP/BD simulation files
xvlog Root Port Model files
xvlog DUT wrapper and RTDS RTL
xvlog SVA bind files
xelab tb_xdma_rtds_trythrough
xsim tb_xdma_rtds_trythrough -runall
```

---

## 11. PASS/FAIL 标准

### 第一版 try-through PASS

必须满足：

```text
PCIe link up
XDMA H2C completed
INFO_EXCH RD_START 出现
adapter fdma_rareq 出现
fdma_rsize=64
TX frame 输出正确
RX frame 写回 payload
IRQ/status 置位
XDMA C2H completed
Host memory compare pass
中断可清除
无 fatal assertion
```

### 压力测试 PASS/OBSERVE

必须满足：

```text
仿真不死锁
FIFO 状态可观测
almost_full/full/overflow 行为可解释
停止输入后系统可恢复或保持在可解释错误状态
无 X 传播
报告记录最大 FIFO level、overflow 次数、丢帧次数
```

---

## 12. 风险与规避

| 风险 | 表现 | 规避 |
|---|---|---|
| Root Port Model 与 XDMA 配置不匹配 | link 不起或 BAR 访问失败 | 从相同 XDMA 配置生成 example design |
| IP 仿真库缺失 | xelab 失败 | 用 Vivado export_simulation 生成脚本 |
| DATA_CDC 仍在主路径 | 重复 CDC、路径混乱 | 大仿真默认禁用 legacy stream |
| Aurora GT 仿真太慢 | 仿真时间极长 | 第一版用 Aurora loopback/RX BFM |
| 压力测试误判 | overflow 被当成失败 | normal 与 pressure mode 分开判定 |
| 失败难定位 | 只看到 Host compare fail | 增加 adapter/FDMA/FIFO/status waveform 和 SVA |

---

## 13. 建议交付物

```text
1. sim_xdma_trythrough 目录
2. tb_xdma_rtds_trythrough.sv
3. rtds_pcie_fdma_aurora_sim_wrapper.v/sv
4. rp_tpi_rtds_tasks.svh
5. aurora_loopback_or_rx_bfm.sv
6. host memory scoreboard
7. SVA bind 文件
8. run_xdma_trythrough_xsim.ps1
9. 仿真报告：
   - link up 时间
   - H2C/C2H completed 时间
   - frame 数
   - compare 结果
   - RX FIFO 最大水位
   - overflow/sticky 状态
```

---

## 14. 最终建议

当前阶段按以下顺序执行：

```text
1. 整理 RTL 主路径：禁用 DATA_CDC，adapter 直连完整 FDMA2AURORA
2. 生成/确认 XDMA simulation model
3. 从 XDMA example design 取 Root Port Model/TPI
4. 写 RTDS 软件动作等价的 TPI task
5. 先跑 1 frame try-through
6. 再跑 16/64 frame
7. 最后跑 RX FIFO 压力观测
```

第一版只要通路能跑通，基本就可以进入后续上板前综合/实现/ILA bring-up。
