# RTDS_test_DDR_MIG替换BRAM上板实施评估

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\RTDS_test_DDR_MIG替换BRAM上板实施评估.md`
- SHA-256: `277340bb3435eb31c5cb487443fb33e1ed5cecad5138b2b34d88944adf34519e`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

# RTDS_test DDR MIG 替换 BRAM：上板实施评估

日期：2026-07-17
范围：`E:\PCIE-CPU\RTDS_test-1ch` 及其引用的 `fdma_aurora_brg` 数据桥
目标：不是只完成 BD 连线，而是最终在实板上跑通 `Host/XDMA <-> DDR <-> CONV_DMA <-> Aurora` 双向数据与中断闭环。

## 1. 结论

方案可行，且不需要重写 adapter 或软件协议。推荐保留现有两个 AXI 主设备和寄存器控制面，仅替换共享 payload memory 的下游实现：

```text
现状：
CONV_DMA/M_AXI --+
                 +--> AXI Interconnect --> AXI BRAM Ctrl --> 64 KiB BRAM
XDMA/M_AXI -------+

目标：
CONV_DMA/M_AXI --+
                 +--> AXI Interconnect/SmartConnect
XDMA/M_AXI -------+          --> clock/width conversion --> DDR MIG S_AXI --> DDR
```

首版 DDR 工程继续只使用原来的 64 KiB 逻辑窗口：

- Aurora -> CPU：`0x0000_0000–0x0000_7FFF`，32 KiB；
- CPU -> Aurora：`0x0000_8000–0x0000_FFFF`，32 KiB；
- INFO_EXCH：`0x4000_0000/4 KiB`，保持不变。

这样可以先完成“存储介质替换”，不同时引入软件地址、缓冲管理和环形队列重构。DDR 容量扩展放到第二阶段。

以一名熟悉 Vivado/PCIe/DDR 的工程师估算：

| 前提 | 人日 | 日历时间 |
| --- | ---: | ---: |
| 有板厂/原工程的 Vivado 2020.2 可用 MIG 配置、引脚和已校准证据 | 15–22 人日 | 3–5 周 |
| 只有原理图、DDR 颗粒与布线拓扑，需要重建 MIG | 20–30 人日 | 4–6 周 |
| DDR 颗粒、位宽、Bank、时钟、管脚或板级 SI 信息不全 | 无法承诺 | 6–8 周以上，且可能被板级资料阻塞 |

当前工程不宜直接进入 MIG 替换。必须先关闭 BRAM 基线上的 P0 问题，否则 DDR 调试时无法区分“原链路故障”和“DDR 故障”。

## 2. 已核对的工程事实

### 2.1 主工程与器件

- 主工程：`RTDS_test-1ch/RTDS_test.xpr`；
- 顶层：`TOP`；
- 器件：`xcku040-ffva1156-2-i`；
- Vivado：2020.2；
- 工程未绑定 Board Part；
- 仓库内未找到 DDR3/DDR4/MIG XCI、MIG `.prj`、DDR 管脚约束或内存颗粒配置。

对该 UltraScale 器件，应按板载内存类型选用 Vivado 2020.2 的 DDR3/DDR4 memory interface IP；不能把 7-series `mig_7series` 配置直接套入。

### 2.2 当前 payload memory 拓扑

Vivado 2020.2 实际打开并校验 `design_1.bd` 后确认：

- `CONV_DMA_0/M_AXI -> axi_interconnect_0/S00_AXI`；
- `xdma_0/M_AXI -> axi_interconnect_0/S01_AXI`；
- `axi_interconnect_0/M00_AXI -> axi_bram_ctrl_0/S_AXI`；
- `axi_bram_ctrl_0 -> blk_mem_gen_0`；
- `CONV_DMA` 为 64-bit AXI4、250 MHz；
- XDMA 用户 AXI 为 64-bit、250 MHz；
- XDMA 时钟域到共享 memory fabric 已由 interconnect 内部 clock converter 处理；
- 两个 AXI master 均映射同一个 64 KiB 段，基地址为 0。

这说明 MIG 替换点非常明确：只需替换 `axi_interconnect_0/M00_AXI` 后面的共享从设备。

### 2.3 当前地址与帧契约

- adapter 固定 512 B frame，即 64 个 64-bit beat；
- RX/TX 各使用 32 KiB；
- FDMA 地址已是显式 64-bit，高 32 位当前固定为 0；
- INFO_EXCH 默认 `CPU_FPGA_START_ADDR=32 KiB`、`CPU_FPGA_LEN=32 KiB`；
- `CONV_DMA` 当前一次 512 B 事务生成 64-beat INCR burst，且地址按 512 B 对齐，不跨 4 KiB 边界。

因此 DDR 首版可以完整保持现有地址/帧契约。

### 2.4 当前验证状态不是“可直接换 DDR”的绿灯

- `sim_xdma_trythrough` 的直接 behavioral backend 有 `RTDS_TRYTHROUGH_PASS`；
- 完整 XDMA + Root Port 最新 `rtds_minimum` 已完成 Gen3 x2、MSI 和 INFO_EXCH 部分访问，但最终报 `TEST FAIL: TIMEOUT ERROR ... Completion data never received`；
- 当前 `TOP.bit` 和实现报告生成于 2026-06-26，早于 7 月的 Aurora/adapter/BD 修改，不能代表现源代码；
- 旧实现报告 WNS 为 `+0.287 ns`、BRAM 使用 131 tile，只能说明旧版本有资源余量，不能作为 DDR 版本时序结论。

结论：当前“轻量直接模型通过、真实 XDMA 大仿真未闭环、当前源未重新出 bit”。DDR 迁移前必须先建立可重复的 BRAM golden baseline。

## 3. DDR 前必须关闭的 P0 问题

### 3.1 FDMA 写通道命名与当前集成连接不一致

`fdma_aurora_brg_rx` 采用标准语义：

- bridge 输出 `fdma_wdata/fdma_wvalid`；
- memory backend 输出 `fdma_wready`。

但现有 `CONV_DMA.v` 的端口名沿用了相反语义：

- 它把输入 `fdma_wready` 当作 source valid；
- 它把输出 `fdma_wvalid` 当作 AXI 接收确认。

已有 bridge + CONV_DMA 集成 TB 明确采用交叉连接：

```verilog
.fdma_wvalid(fdma_wready),
.fdma_wready(fdma_wvalid),
```

当前 `PCIe.v` 却按同名连接 adapter 和 BD wrapper。按端口方向分析，这会造成：

- adapter 和 BD wrapper 同时驱动 `fdma_wvalid`；
- 两边都把 `fdma_wready` 当输入。

这是 Aurora -> memory 写方向的上板阻断项。推荐按以下顺序处理：

1. 为尽快闭环，先用两个语义明确的独立 net 在 `PCIe.v` 做交叉连接，复用已经通过的集成 TB 关系；
2. BRAM 基线和上板链路稳定后，再把 `CONV_DMA` 端口重构为标准 valid/ready 方向，避免长期维护误接。

### 3.2 `CONV_DMA` 不上报 AXI 错误响应

当前 `CONV_DMA` 没有把 `BRESP/RRESP` 错误转成状态。BRAM 常常永远返回 OKAY，DDR/地址转换/复位期间则更可能暴露 SLVERR/DECERR。

DDR 版至少应增加：

- `axi_bresp_error_sticky`；
- `axi_rresp_error_sticky`；
- 可选的首错地址和读写方向；
- INFO_EXCH 可读状态与 ILA probe。

### 3.3 现有完整 XDMA 大仿真必须先得到 BRAM PASS

在不改 memory backend 的前提下，至少通过：

```text
Host/RP -> XDMA H2C -> BRAM -> CONV_DMA -> Aurora loop
        -> CONV_DMA -> BRAM -> XDMA C2H -> Host
```

如果 BRAM 版本不通过，不进入 MIG 主工程集成。

## 4. 推荐实现策略

### 4.1 不做运行时 BRAM/DDR 双选，保留可回退工程版本

推荐保留：

- `design_1_bram`：golden baseline；
- `design_1_ddr`：DDR 集成版本；
- Tcl 脚本记录 IP 创建、连接、地址分配和 wrapper 生成。

不建议为首版加入运行时 BRAM/DDR mux。运行时双选会增加 AXI 地址、复位、仲裁和验证组合，对“尽快上板”没有收益。

### 4.2 MIG 先在独立最小工程校准

在主工程之外先生成与实板一致的 DDR3/DDR4 IP：

1. 器件、DDR part、位宽、rank、bank group、地址映射与板级走线完全按原理图；
2. 使用真实 system/reference clock 和 reset 极性；
3. 生成 example design/traffic generator；
4. 上板确认 `init_calib_complete`；
5. 完成地址线、数据线、byte lane、walking 1/0、伪随机和长时间读写；
6. 保存 XCI/配置 Tcl/生成日志/ILA 或校准报告。

MIG-only 工程不过，不改主 BD。这样可以把 DDR 物理层、管脚、时钟和 PCB 问题独立出来。

### 4.3 主 BD 的推荐结构

保留 `axi_interconnect_0` 的两个 slave-side master 输入，替换其 M00 下游：

```text
CONV_DMA 64b @ 250 MHz ---- S00
                                  AXI Interconnect/SmartConnect
XDMA M_AXI 64b @ 250 MHz --- S01
                                           |
                              width + clock conversion
                                           |
                               MIG S_AXI @ ui_clk
                                           |
                                          DDR
```

实现要点：

- `M00_ACLK` 使用 MIG `ui_clk`；
- M00 reset 使用同步到 `ui_clk`、且受 `init_calib_complete` 控制的 `ddr_axi_aresetn`；
- 让 BD 自动插入或显式加入 AXI Clock Converter/Data Width Converter；
- 不改变 `CONV_DMA` 和 XDMA 各自的 64-bit/250 MHz 接口；
- 两个 master 映射同一个 MIG memory segment；
- 首版软件仍只访问最低 64 KiB；
- INFO_EXCH/AXI-Lite 控制面继续工作在 PCIe/250 MHz 域，不依赖 DDR 校准。

若现有 AXI Interconnect 在 DDR 宽度/时钟组合下自动转换不稳定，再将 payload fabric 换成 SmartConnect；不需要为了“看起来更新”预先重构。

### 4.4 复位与校准门控

不要用 `init_calib_complete` 去复位整个 PCIe/Aurora 系统，否则 DDR 校准异常会导致 PCIe 无法枚举，失去调试入口。

推荐：

- PCIe、INFO_EXCH、Aurora 各自保持原复位；
- DDR AXI 从设备和 M00 clock-conversion 域由 MIG UI reset 管理；
- adapter 增加同步后的 `memory_ready`；
- `memory_ready=0` 时拒绝新的 FDMA read/write request，并置可读状态，不让事务进入半完成状态；
- 软件先轮询 DDR ready，再发 H2C/C2H 或 `RD_START`。

INFO_EXCH 建议新增 `0x002C MEMORY_STATUS`：

| Bit | 含义 |
| ---: | --- |
| 0 | `init_calib_complete` |
| 1 | DDR AXI reset 已释放 |
| 2 | memory BIST pass |
| 3 | memory BIST fail sticky |
| 4 | AXI BRESP error sticky |
| 5 | AXI RRESP error sticky |

### 4.5 DDR 延迟与 backpressure

DDR 刷新、仲裁、clock conversion 和 width conversion 会比 BRAM 引入更多停顿。当前 RX async FIFO 深度为 2048 x 64-bit，即 16 KiB；不能仅凭容量判断安全，必须按 Aurora 连续输入速率和 DDR 最坏服务间隔做压力测试。

需覆盖：

- AXI AW/W/AR/R 随机 backpressure；
- DDR refresh 期间的连续帧；
- XDMA 和 CONV_DMA 同时争用 DDR；
- RX FIFO almost-full/full/overflow；
- adapter `FDMA_TIMEOUT_CYCLES` 是否需放宽；
- 512 B、4 KiB 边界和 32 KiB 窗口回绕。

## 5. 验证与上板路线

### G0：BRAM golden baseline

验收：

- 修正写通道连接；
- behavioral try-through PASS；
- 完整 XDMA + Root Port minimum case PASS；
- 当前源重新综合、实现、出 bit；
- DRC 0 error、所有约束时钟 WNS >= 0、无关键 unconstrained path；
- BRAM 实板 H2C/C2H + Aurora loop + IRQ 闭环通过。

### G1：MIG-only 校准与 BIST

验收：

- 连续 20 次冷启动均进入 `init_calib_complete`；
- 全目标测试范围进行 walking 1/0、address、checkerboard、伪随机读写；
- 至少 30 分钟连续读写 0 error；
- 记录校准耗时、失败状态和温度。

### G2：DDR 接入主 BD，不接 Aurora 数据闭环

验收：

- PCIe 可独立枚举；
- 软件可读 MEMORY_STATUS；
- XDMA H2C 写 DDR、C2H 读回，覆盖 512 B、4 KiB、32 KiB 和随机长度/地址；
- 两个逻辑窗口不串扰；
- AXI response error 为 0。

### G3：CONV_DMA + Aurora 单向验证

先 CPU -> Aurora，再 Aurora -> CPU。每次只开一个方向，ILA 同时观察：

- FDMA request/busy/size/address；
- AXI AW/W/B 或 AR/R；
- MIG ready/calib；
- RX/TX FIFO 水位；
- frame SOF/EOF 和数据计数。

### G4：完整双向闭环和中断

验收链路：

```text
Host H2C -> DDR TX window -> CONV_DMA -> Aurora loop/peer
         -> CONV_DMA -> DDR RX window -> MSI/状态 -> Host C2H compare
```

通过条件：

- 单帧、连续帧、窗口回绕数据逐字节一致；
- IRQ 产生、ack、状态读取和清除完整；
- 无 FIFO overflow、timeout、link-down、AXI response error；
- 连续 10,000 帧 0 error。

### G5：稳定性

- 20 次整机掉电重启；
- PCIe warm reset/link retrain；
- Aurora 对端晚启动和中途断链；
- DDR ready 之前的软件误操作；
- 30–60 分钟双向压力；
- 保存 bit/ltx、软件版本、寄存器快照和 ILA 触发模板。

## 6. 工作量拆分

| 阶段 | 内容 | 人日 |
| --- | --- | ---: |
| 0 | 关闭写通道连接问题、BRAM 大仿真失败和当前 bit 基线 | 3–5 |
| 1 | 冻结 DDR 颗粒/引脚/时钟/复位/容量，获取或重建 MIG | 2–6 |
| 2 | MIG-only example design、校准和 BIST 上板 | 2–4 |
| 3 | BD 替换、地址/时钟/位宽/复位、wrapper 与状态寄存器 | 3–5 |
| 4 | 定向仿真、AXI backpressure、错误响应、回归 | 2–4 |
| 5 | 综合、实现、DDR pin/clock DRC、时序收敛、bit/ltx | 2–4 |
| 6 | PCIe-DDR、Aurora 单向、全闭环、中断、稳定性上板 | 4–7 |

阶段有部分可重叠，但 G0 和 MIG-only G1 是主工程合并前的硬门槛。

## 7. 开工前必须补齐的输入

1. 板卡原理图和 PCB/约束资料；
2. DDR3/DDR4 颗粒完整型号、数量、总线位宽、rank、地址/Bank/byte-lane 拓扑；
3. DDR system/reference clock 频率、管脚和 reset 极性；
4. 若存在，板厂或旧工程已上板通过的 MIG XCI/`.prj`/Tcl/XDC/example design；
5. 目标 DDR 容量、目标带宽和是否要求 ECC；
6. 实板、JTAG、PCIe 主机、Aurora 对端/回环条件；
7. XDMA 驱动和当前 H2C/C2H/寄存器测试程序。

其中 1–4 项当前仓库内均未发现，是工期最大的不确定源。

## 8. 最终建议

执行顺序固定为：

```text
修通当前 BRAM golden baseline
        -> MIG-only 校准/BIST
        -> 主 BD 替换 memory backend
        -> PCIe<->DDR
        -> CONV_DMA/Aurora 单向
        -> 全闭环/IRQ
        -> 压力与掉电回归
```

不要把“BD 中出现 MIG IP”当作完成。最终完成标准是当前源代码重新出 bit 后，实板完成 DDR 校准、PCIe 双向搬运、Aurora 双向闭环、中断和稳定性回归，并能用状态寄存器与 ILA 定位失败点。
