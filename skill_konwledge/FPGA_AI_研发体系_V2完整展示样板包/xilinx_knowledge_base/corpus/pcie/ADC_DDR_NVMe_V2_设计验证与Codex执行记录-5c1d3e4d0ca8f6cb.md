# ADC_DDR_NVMe_V2_设计验证与Codex执行记录

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md`
- SHA-256: `5c1d3e4d0ca8f6cba8bc80853ba25dbcb67a0537ff2c167c8d8c12865fba5a2e`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md

# ADC–DDR–NVMe V2 设计、验证与 Codex 执行记录

更新日期：2026-07-26
工作区：`E:\NVME_PRO\nvme_adc_axi_pipeline`
目标器件：`XCKU040-FFVA1156-2-I`
工具：Vivado 2020.2

## 1. 本文件的用途

这是一份可持续更新的工程记录，集中保存：

- 当前数据通路为什么这样设计；
- 已经实现和仍待集成的边界；
- 仿真用例、PASS 条件和日志位置；
- Codex 实际执行过的命令；
- 失败现象、定位过程、根因和修正；
- 下周供应商黑盒测试及后续购买交付准备。

V1.0 DOCX 保留为历史基线。当前自研RTL实现以V2.0为基线；最新供应商接口、
板级集成和现场验证结论以V2.1文档、README、本记录及
`ADC_DDR_NVMe_V2.1_修改要点与代码验证说明.md`为准。

## 2. 当前设计结论

### 2.1 三种运行模式

同一 bitstream 支持：

| 模式 | 存储格式 | 250 MSPS 数据率 |
|---|---|---:|
| 单通道 CH0 | 紧凑 16 bit/sample | 500 MB/s |
| 单通道 CH1 | 紧凑 16 bit/sample | 500 MB/s |
| 双通道 | `{CH1[15:0], CH0[15:0]}` | 1 GB/s |

`cfg_two_channel`、`cfg_single_channel_select` 和 `cfg_capture_id` 在
`capture_start && capture_ready` 时锁存。采集中修改不改变当前格式，并置位
`config_change_sticky`。

`sample_count` 始终表示采样时刻数量。双通道的一个采样时刻含两路数据，单通道含一路。

### 2.2 数据通路

```text
ADC并行样本 / 内部数据发生器
        ↓
adc_channel_packer（ADC时钟域）
  双通道：8个采样时刻 → 256 bit
  单通道：16个样本     → 256 bit
        ↓
263 bit异步FIFO
  data[255:0] + valid_bytes[5:0] + end_of_capture
        ↓
adc_ddr_segment_writer
        ↓ AXI4 Burst
SmartConnect → MIG → DDR
        ↓ READY描述符
segment_buffer_manager
        ↓
nvme_request_scheduler
        ↓
仿真Stub / MicroBlaze Mailbox / 第三方NVMe Host IP
        ↓
PCIe Root Complex → NVMe SSD
```

### 2.3 为什么 ADC 域先打包

旧思路是 32 bit 先跨时钟，再在系统域打包。系统域若为 125 MHz：

```text
32 bit × 125 MHz = 500 MB/s
```

这只有双通道输入 1 GB/s 的一半。V2 改成 ADC 域先扩宽为 256 bit：

```text
双通道：250 MHz ÷ 8 = 31.25 Mword/s
单通道：250 MHz ÷ 16 = 15.625 Mword/s
```

125 MHz 系统域有足够周期读取这些 256 bit 字。

### 2.4 异步 FIFO 的作用和深度

默认 FIFO 为约 `1024 × 263 bit`。

```text
双通道缓存时间 = 1024 × 32 Byte ÷ 1 GB/s ≈ 32.8 µs
单通道缓存时间 = 1024 × 32 Byte ÷ 0.5 GB/s ≈ 65.5 µs
```

FIFO 只吸收 CDC 相位差、复位释放、MIG 刷新和 DDR 短仲裁。它不负责吸收
SSD 的毫秒级停顿；后者由外部 DDR Segment 承担。

物理 ADC 不能被 `ready` 反压。如果 CDC FIFO 真的满，系统只能置位 overflow
并记录丢样。因此正常测试应保证 DDR 平均服务能力足够，同时测量 FIFO 最大水位。

### 2.5 DDR Segment

Segment 是同一块 DDR 的逻辑地址分段，不是多颗 DDR。

```text
FREE → FILLING → READY → INFLIGHT → FREE
                    └─错误/超时→ ERROR_HOLD
```

- 分配给 Writer 时立即离开 FREE；
- DDR 最后一个 B 响应成功后才进入 READY；
- 提交 NVMe 请求后进入 INFLIGHT；
- 收到匹配 Tag 的成功 Completion 后才能返回 FREE；
- 错误、超时、Tag 不符时不能覆盖原数据。

参数建议：

| 阶段 | Segment 配置 |
|---|---|
| 行为仿真 | 4 KiB 小分段 |
| DDR 初联 | 1 MiB × 8 |
| 产品候选 | DDR 容量确认后 4 MiB × 16 |

### 2.6 尾段和 Commit

- 不足 256 bit 的最后一拍高位补零；
- `valid_bytes` 记录该拍真实字节；
- DDR/NVMe DMA 长度向上补齐到 4 KiB；
- `payload_bytes` 记录补零前长度；
- CRC32C 只覆盖真实 Payload；
- Payload 排空后写 4 KiB Commit 页。

Capture 完成顺序：

```text
停止采集
→ 排空Payload WRITE
→ Flush #1
→ Commit Metadata WRITE
→ Flush #2
→ capture_done
```

### 2.7 NVMe 可替换边界

项目不再依赖假定的供应商 AXI-Lite 寄存器表。统一请求：

```text
opcode, ddr_addr, byte_len, slba, user_tag
```

统一完成：

```text
user_tag, status
```

Opcode 支持 WRITE、READ、FLUSH。当前项目层只有一个大请求在途；第三方 IP
内部仍可按 MDTS 拆为多条 SQE。

Tag 使用 `{generation, segment_id}`，防止 Segment 复用后迟到 Completion
误释放新数据。项目 Tag 不等于第三方 IP 内部每条 SQE 的 CID。

MicroBlaze 只提交描述符和处理完成，不复制 ADC Payload。

### 2.8 模型通过后，接真实 IP 是否就基本打通

可以把当前模型看成完整通路的自研逻辑骨架。若真实接口和当前抽象一致，后续
不需要推翻架构，主要是板级连接、地址映射、性能和异常调试。

```text
当前模型通过
→ 真实MIG校准和DDR写后读回CRC
→ SmartConnect下ADC写与NVMe读并发
→ 供应商PCIe/NVMe初始化
→ 已知DDR数据写SSD并读回
→ 接真实ADC
→ 完整链路打通
```

仍有三个硬门槛：

1. MIG 校准、DDR 引脚和并发带宽必须真实通过；
2. 供应商 IP 必须能直接访问项目 DDR 地址，且对齐、AXI 和地址映射一致；
3. PCIe Link Up 之后还必须完成 NVMe Identify、Write、Read、Flush 和数据一致性。

所以“模型通过 + 接上几个 IP”是正确的大方向，但不能省略真实 DDR 读回和
SSD 写后读回这两次数据一致性闭环。

## 3. 当前工程状态

### 已实现

- ADC 单 CH0、单 CH1、双通道；
- 12→16 bit 符号扩展或零扩展；
- ADC 域 256 bit 打包；
- 263 bit XPM 异步 FIFO；
- `capture_ready/start/stop` 与短采尾拍；
- 64 bit 样本、字节、Sequence 和 Capture ID；
- AXI4 DDR Burst Writer；
- 4 KiB 补零、CRC32C 和 Commit 页；
- Segment Manager 和 generation Tag；
- WRITE/READ/FLUSH 通用 NVMe 接口；
- NVMe Stub 和 MicroBlaze Mailbox 后端；
- Command Timeout、Link Down、ECQE 和 fatal freeze；
- Vivado 自动化仿真和 OOC 综合脚本。

### 仿真桩

`axi_ddr_mem_stub.sv`：

- 接收 AW/W/B；
- 保存字节数组；
- 可随机撤销 AWREADY/WREADY、延迟 BVALID、注入 BRESP 错误；
- 不模拟真实 MIG、DDR 颗粒、刷新和读性能。

`nvme_req_cpl_stub.sv`：

- 接收通用请求；
- 固定延迟返回完成；
- 可注入失败、超时和错误 Tag；
- 不读取 DDR、不运行 PCIe、不生成 SQE/PRP、不访问 SSD。

### 待真实集成

- DDR 颗粒参数、MIG、SmartConnect 和 XDC；
- DDR AXI Reader 和真实写后读回 CRC；
- ADC LVDS PHY、DCO、IDELAY 和解串；
- AMD PCIe Root Port 独立 Bring-up；
- 第三方 NVMe Host IP；
- 真实 SSD Write/Read/Flush 闭环。

## 4. 验证体系

必须区分四级状态：

| 等级 | 含义 |
|---|---|
| 仿真通过 | 测试平台、桩模型和断言覆盖的数字逻辑通过 |
| 真实 DDR 通过 | MIG 校准、Pattern 读回、500 MB/s/1 GB/s CRC 和 ILA 通过 |
| 供应商 IP 通过 | 黑盒或交付后 Write/Read/Flush、长稳和错误状态通过 |
| 完整 SSD 闭环通过 | 真实 ADC→DDR→NVMe SSD→DDR 读回，全链路 CRC 一致 |

### 4.1 `tb_adc_channel_packer`

覆盖：

- 双通道、单 CH0、单 CH1；
- 0、1、7、8、9、15、16、17 个采样时刻；
- 10 µs、50 µs、100 µs、1 ms；
- `0x000、0x7FF、0x800、0xFFF`；
- 单/双通道字节顺序；
- EOC、`valid_bytes` 和尾部补零；
- Capture 内配置锁存；
- `valid&&!ready`期间 Payload 稳定；
- 有上限的 ADC 侧短握手停顿。

### 4.2 `tb_nvme_adc_pipeline`

配置：

- ADC 250 MHz；
- SYS 125 MHz；
- 4 × 4096 Byte Segment；
- 假 DDR 随机 AW/W 背压和 BVALID 延迟。

Capture：

1. 双通道 1024 个采样时刻；
2. 单 CH0 17 个采样；
3. 单 CH1 9 个采样。

检查：

- DDR 逐字节一致；
- accepted 正确、dropped 为 0；
- Segment 状态合法并最终全部 FREE；
- DDR/NVMe 地址和 DMA 长度按 4 KiB 对齐；
- 每个 Capture 请求顺序为 Payload WRITE、Flush、Commit WRITE、Flush；
- Commit magic 正确；
- AXI/NVMe 在等待 ready 时 Payload 稳定。

### 4.3 `tb_nvme_scheduler_errors`

分别注入：

- Completion status 错误；
- Completion Tag 错误；
- Command Timeout；
- PCIe Link Down；
- Flush 失败；
- ECQE 错误。

期望为 sticky 错误和 `fatal_error`，不得把失败 Segment 释放回 FREE。

## 5. Codex/Vivado 实际命令

### 5.1 主端到端仿真

```powershell
cd E:\NVME_PRO\nvme_adc_axi_pipeline

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_sim.tcl
```

### 5.2 指定测试平台

```powershell
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch `
  -source .\scripts\run_vivado_test.tcl `
  -tclargs tb_adc_channel_packer

& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch `
  -source .\scripts\run_vivado_test.tcl `
  -tclargs tb_nvme_scheduler_errors
```

### 5.3 完整回归

```powershell
& .\scripts\run_vivado_regression.ps1
```

输出：

```text
build/regression/<test>/.../xsim/simulate.log
build/regression/<test>/.../xsim/*.wdb
build/regression/summary.json
```

### 5.4 KU040 OOC 综合

```powershell
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' `
  -mode batch -source .\scripts\run_vivado_synth.tcl
```

当前综合结果：

```text
0 error
0 critical warning
CLB LUT       2259
CLB Register  2377
RAMB36E2      11
RAMB18E2      1
DSP           0
```

没有板级 XDC，因此 OOC 时钟告警是预期的，不能作为最终频率结论。

### 5.5 生成 DOCX

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\docs\build_v2_docs.py
```

本轮按用户最新要求只生成 DOCX，不继续做 PDF 渲染。

## 6. 问题定位记录

### 问题 1：第一轮端到端仿真从第 16 个样本附近跳号

现象：

```text
Dual-channel mismatch at 15/16
期望样本 0x0F/0x10，实际跳到 0x1C
```

定位：

1. SystemVerilog 编译和 XSim 展开成功，排除语法问题；
2. 增加 ADC 打包输出观察；
3. 发现第一、第二个 256 bit 字正确，第三个字从样本 28 开始；
4. 根因是输出寄存器被背压时，第二个打包字只保存了前 7 个样本；
5. ready 恢复时，新样本替换了本应位于末尾的样本，造成跳号。

修正：

- 增加 `pack_full_pending`；
- 输出寄存器和 `pack_data` 形成两级弹性缓存；
- ready 恢复时先发送完整 pending 字，同时把当前 ADC 样本放入新字；
- 增加 Payload 稳定断言。

### 问题 2：Capture 在 XPM FIFO 复位忙期间过早启动

现象：

- 测试刚释放复位就开始送 ADC；
- XPM FIFO 的 `wr_rst_busy` 尚未结束；
- 本地弹性缓存被耗尽并置位 overflow。

修正：

- 新增 `capture_ready`；
- 只有 `capture_start && capture_ready` 才锁存配置并进入 ACTIVE；
- 过早的 start 不再被静默接受；
- 测试平台和后续软件都必须先等待 `capture_ready`。

### 问题 3：完整 256 bit 结束时可能出现零字节 EOC

现象：

- Capture 长度正好是 256 bit 整数倍时，最后完整数据字可能已经发送；
- 随后需要一个 `valid_bytes=0` 的 EOC 标记；
- DDR Writer 原逻辑会把这个零字节标记也压入 Beat FIFO。

风险：

- 排队 Beat 数可能大于按真实 Payload 计算的 4 KiB 目标 Beat 数；
- Writer 可能等待错误的完成条件。

修正：

- `valid_bytes=0` 的 EOC 只触发 finalize；
- 不压入 DDR Beat FIFO；
- CRC、Payload 和样本计数不增加。

### 问题 4：1 ms 单元测试出现 2 个丢样

现象：

```text
samples=250000
accepted=249998
dropped=2
overflow=1
```

定位：

- 测试直接在 packer 输出端使用 LFSR 随机拉低 ready；
- 足够长的测试会出现超过本地两级弹性缓存容量的连续反压；
- 真实 ADC 不能停止，RTL 正确置位 overflow 并记录丢样；
- 完整系统中 packer 的直接下游是 1024 深度 CDC FIFO，ready 只会在复位或 FIFO 真满时失效。

处理：

- 正常 packer 回归把直接 ready 停顿限制为最多 4 个 ADC 周期；
- 长时 DDR/NVMe 停顿由完整系统中的 CDC FIFO 水位和 DDR Segment 用例验证；
- “FIFO 真的满”应作为负向 overflow 用例，不能要求在无限反压下仍然 0 丢样。

这不是把失败隐藏掉，而是把正常用例和故障用例的物理前提分开。

复测结果：

```text
250000个双通道采样时刻（1 ms）
accepted = 250000
dropped  = 0
TEST_PASS
```

### 问题 5：Vivado/LibreOffice 命令超时

Vivado：

- Codex 外层命令曾在 120/300 秒超时；
- 子 Vivado 进程仍继续运行；
- 通过 `vivado.log`、`elaborate.log`、`simulate.log` 和进程状态判断真实结果；
- OOC 综合实际完成，生成 DCP 和报告。

LibreOffice：

- 首次独立 Profile URL 写法不正确，进程没有产出 PDF；
- 修正为 `file:///E:/...` 后可转换；
- 用户随后明确“不用渲染，生成文档即可”，因此停止后续 PDF 检查。

## 7. 真实 DDR、PCIe 和供应商测试

### 7.1 不等待 NVMe IP 的真实通路

有必要先做：

1. 项目组补齐 DDR 颗粒、原理图、引脚、时钟、Rank、位宽和速率；
2. 生成真实 UltraScale Memory IP/MIG；
3. 跑官方 Example Design；
4. 运行线性、PRBS、Walking 1/0 写读；
5. 接内部 500 MB/s / 1 GB/s 数据发生器；
6. 用 AXI Reader 读回并计算 CRC；
7. ILA 记录 FIFO 水位、AXI Stall、BRESP；
8. 最后接真实 ADC PHY。

当前没有 DDR 参数和 XDC，不生成假 MIG。

### 7.2 Xilinx 官方 PCIe IP

可单独验证：

- PCIe Link Up；
- Gen 和 Lane 宽度；
- 配置空间、BAR 和基础 TLP；
- GT、Refclk、PERST# 和板级连接。

不能代替：

- NVMe SQ/CQ；
- PRP；
- Doorbell；
- Identify；
- NVMe Read/Write/Flush。

官方 PCIe Bring-up 工程在拿到第三方 IP 前独立保留，不并入主工程。

### 7.3 供应商现场测试限制（未交付IP阶段）

供应商不交付 IP 文件，完整购买还需一至两周。结论分级：

| 条件 | 允许结论 |
|---|---|
| 只能跑固定 Demo | 供应商基线复现 |
| 可修改地址/长度/命令 | 供应商 IP 黑盒验收 |
| 可提交我方 DDR Pattern 并读回 | 我方数据接口预演 |
| 交付后能从干净目录生成 | 我方工程集成验证 |

双通道目标为 1 GB/s，购买验收建议平均持续写不低于 1.2 GB/s，并记录
最低 1 秒带宽、最长停顿、Flush 延迟、SSD 温度和写后读回一致性。

## 8. 项目组输入

详细勾选表：

- `board_bringup_inputs.md`
- `vendor_ip_contract.md`
- `supplier_onsite_test_checklist.md`

关键项包括：

- FPGA 完整型号、封装、速度等级和板卡版本；
- DDR 完整颗粒、数量、组织、Rank、速率、引脚、CK/VREF/ODT；
- ADC 型号、码制、LVDS、DCO、单双沿、Lane 位序和极性；
- PCIe Lane/GT、100 MHz Refclk/SSC、PERST#、供电和散热；
- 最大采集时长、丢样策略、Raw LBA 范围、Flush/掉电、读回需求。

## 9. 交付文件

```text
README.md
vendor_ip_contract.md
board_bringup_inputs.md
board_integration/README.md

docs/
  NVMe_ADC_DDR_FPGA基础通路设计方案_V2.0_单双通道与分阶段验证版.docx
  ADC_DDR_NVMe验证用例与测试过程_V1.0.docx
  ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md
  ADC_DDR_NVMe_V2.1_修改要点与代码验证说明.md

rtl/
  adc_channel_packer.sv
  axis_async_fifo.sv
  adc_ddr_segment_writer.sv
  segment_buffer_manager.sv
  nvme_request_scheduler.sv
  nvme_mailbox_backend.sv

sim/
  tb_adc_channel_packer.sv
  tb_nvme_adc_pipeline.sv
  tb_nvme_scheduler_errors.sv

scripts/
  run_vivado_sim.tcl
  run_vivado_test.tcl
  run_vivado_regression.ps1
  run_vivado_synth.tcl
```

## 10. 后续更新规则

每次真实集成或测试后，在本文件追加：

```text
日期
硬件/工具/IP/SSD版本
测试对象和输入
执行命令
PASS/FAIL
第一条失败
根因
修改文件
复测结果
仍未覆盖的风险
```

禁止用“平均带宽正常”“命令返回成功”代替完整的数据一致性、最低带宽和
最长停顿记录。

## 11. 供应商补充回复差异分析（V2.1，2026-07-28）

### 11.1 本轮保持不变的自研RTL

供应商补充回复没有推翻以下已经回归的结构：

- ADC单CH0、单CH1和双通道配置；
- ADC时钟域256 bit打包；
- `data[255:0] + valid_bytes[5:0] + EOC`的263 bit CDC；
- 256 bit DDR Writer；
- `FREE→FILLING→READY→INFLIGHT→FREE/ERROR_HOLD`；
- 项目层一个大NVMe请求在途；
- `{generation, segment_id}`项目Tag；
- Payload Write、Flush、Commit Write、Flush顺序。

本轮正常数据面RTL不修改，只在系统testbench增加AXI Burst不跨4 KiB断言。

### 11.2 MIG截图与正式集成结构

供应商截图明确显示的是其当前MIG配置：

```text
AXI Data Width = 512
AXI Address Width = 32
AXI ID Width = 1
Arbitration = RD_PRI_REG
Memory Device Interface Speed = 833 ps
```

这些参数不是NVMe IP M_AXI的正式端口表。当前集成思路为：

```text
ADC Writer 256 bit
→ SmartConnect仲裁及必要的256→512 bit宽度转换
→ MIG 512 bit
← 供应商NVMe DDR M_AXI（实际位宽、时钟、复位仍未知）
```

不把ADC Writer改成512 bit，避免重新引入打包、WSTRB、尾段和CRC风险。
`RD_PRI_REG`可能让NVMe读DDR期间偏向读请求，因此真实板级必须用ILA记录
ADC Writer最长AW/W Stall和FIFO最大水位。

### 11.3 地址和4 KiB口径

项目继续使用64 bit DDR地址，未来供应商Adapter负责范围检查和
Absolute/Offset换算。当前没有正式API，因此不实现猜测性Adapter。

对齐问题分三层：

| 层次 | 当前结论 |
|---|---|
| 项目策略 | DDR Buffer和NVMe DMA长度继续4 KiB对齐 |
| 供应商答复 | 最小传输单位512 B |
| AXI4规则 | 单个Burst不得跨越4 KiB边界 |

供应商示例`0x400 + 4 KiB`会跨过`0x1000`。合理推测是高层任务可跨页，
IP内部再拆成不跨4 KiB的AXI Burst，但在现场证明前只标记为歧义，不据此
放宽项目对齐。

当前Writer为：

```text
256 bit × 16 beat = 512 Byte/Burst
```

Segment从4 KiB边界开始并以512 B递增，正常路径天然不跨4 KiB。系统
testbench新增通用检查：

```text
AWADDR低12位 + ((AWLEN+1) << AWSIZE) <= 4096
```

### 11.4 单大任务与内部并发

供应商已经确认：

- 上层一次只能提交一个大DMA任务；
- 内部可创建16个队列；
- Queue Depth最大1024；
- 大任务按MDTS拆成多条SQE并分配到空闲队列。

因此项目层不增加多Outstanding，也不自行实现SQE、CID、PRP或4 KiB命令拆分。
仍待现场确认的是：上层大任务Completion是否只在全部内部SQE完成后返回。
只有该聚合完成成立，对应Segment才能安全释放。

### 11.5 异常恢复

供应商当前只回复“重新下载程序”，未明确是重新配置FPGA bitstream还是
重新下载MicroBlaze ELF。V2.1采用保守策略：

```text
Timeout / Completion错误 / Link Down / ECQE / Flush失败
→ fatal_error
→ 禁止新Capture和新NVMe请求
→ INFLIGHT/ERROR_HOLD数据保持
→ 不自动重试、不自动释放
→ 等待人工恢复
```

删除“MicroBlaze一定可以自动重新初始化恢复”的确定性表述。

### 11.6 Vivado版本隔离

自研RTL和现有自动化继续以Vivado 2020.2为有效基线。供应商当前工程为
Vivado 2024.2，交付后必须建立独立集成目录，不用2024.2打开并覆盖现有
2020.2工程，也不尝试把供应商工程强行降级。

本机当前未安装Vivado 2024.2，因此本轮不创建或运行2024.2脚本。待供应商
工程到手后，再对共同RTL执行双版本编译和行为回归。

### 11.7 V2.1文档与执行命令

新增文件：

```text
docs/NVMe_ADC_DDR_FPGA基础通路设计方案_V2.1_供应商补充答疑收敛版.docx
docs/ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版.docx
docs/build_v21_docs.py
docs/check_v21_docx_structure.py
docs/ADC_DDR_NVMe_V2.1_修改要点与代码验证说明.md
supplier_onsite_test_checklist.md
```

生成DOCX：

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\docs\build_v21_docs.py
```

结构检查：

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\docs\check_v21_docx_structure.py
```

按用户要求，本轮不调用LibreOffice，不生成PDF、PNG或页面截图。

Vivado 2020.2回归：

```powershell
& .\scripts\run_vivado_regression.ps1
```

回归结果和时间在本轮执行完成后以`build/regression/summary.json`和各
`simulate.log`为准。

### 11.8 本轮实际结果

执行时间：2026-07-28 10:05～10:08

| 测试平台 | 结果 | 证据 |
|---|---|---|
| `tb_adc_channel_packer` | PASS | `simulate.log`包含packer边界、模式、字节序和配置锁存PASS标记 |
| `tb_nvme_adc_pipeline` | PASS | 新增4 KiB Burst边界断言未触发；三模式、CDC、DDR、Segment、Flush/Commit通过 |
| `tb_nvme_scheduler_errors` | PASS | Completion、Tag、Timeout、Link、Flush和ECQE六类异常均通过 |

统一汇总：

```text
build/regression/summary.json
3 PASS / 0 FAIL / FirstFatal=null
```

DOCX结构检查：

```text
V2.1：46068 Byte，56个段落，16个表格
V1.1：44738 Byte，76个段落，12个表格
```

两份DOCX均通过ZIP/OOXML核心部件、核心属性和关键章节锚点检查。按用户要求
未执行PDF/PNG渲染和页面视觉检查。

## 12. NoPHAE用户指南差异分析（V2.2，2026-07-29）

### 12.1 本轮输入和范围

新增依据：

```text
E:\NVME_PRO\用户指南.docx
```

本轮只更新设计结论、供应商三态契约、现场问题和Word/Markdown说明，不修改
任何`rtl/`、`sim/`或`scripts/`下的Vivado代码，也不运行行为仿真或综合。
V2.0/V2.1 DOCX、V1.1验证文档及V2.1生成器保持历史原样。

### 12.2 从UNKNOWN升级为CONFIRMED

用户指南现在明确给出：

- NoPHAE是FPGA侧NVMe Host Controller，支持NVMe 1.3d和PCIe 3.0；
- 支持SoC和无CPU纯逻辑环境；
- `s_axi_ctrl`为32 bit AXI4-Lite，基址4 KiB对齐、地址空间4 KiB；
- `m_axi`为外部DDR AXI4-Full Master，DATA/ADDR/ID宽度为配置参数；
- PCIe/NVMe初始化寄存器及状态输出；
- `dma_type/dma_len/dma_srcaddr/dma_dstaddr/dma_ready/dma_done`；
- `dma_len`单位为512 B；
- 原生NVMe命令、Queue、错误CQE和命令计数寄存器；
- 初始化、队列、顺序读写、Identify和SMART等样例API。

因此NoPHAE控制Backend可以开始做寄存器行为模型和状态机接口设计。该结论
不表示真实IP已经交付，也不表示地址、完成或Flush语义已经完整。

### 12.3 保持不变的自研结构

```text
ADC单/双通道
→ ADC域256 bit打包
→ 263 bit CDC
→ 256 bit DDR Writer
→ Segment所有权
→ 单个抽象NVMe大请求在途
```

NoPHAE高层DMA寄存器没有用户Tag，因此项目`{generation, segment_id}`继续只
保存在Backend本地上下文。只有供应商确认`dma_done`代表整笔任务全部内部SQE
完成后，Backend才能把对应Tag返回并释放Segment。

### 12.4 新暴露的P0风险

1. 用户指南的`PCIEIP_VERSION`只列Virtex-7 Gen3和UltraScale+ Gen4，没有
   列XCKU040所需的UltraScale Gen3。
2. `dma_srcaddr/dma_dstaddr`没有说明DDR/LBA映射、地址单位和Absolute/Offset。
3. `dma_done`没有说明保持、清除、错误和聚合完成条件。
4. 高层DMA寄存器和API没有Flush入口。
5. `clr_queues`高有效与使用流程写0冲突。
6. `sq_full`只有`[16:0]`，流程却检查bit `[17]`。
7. `s_axi_ctrl`时钟域和NoPHAE交付实例`m_axi`参数未知。

### 12.5 推荐首轮控制面

```text
nvme_request_scheduler
→ nvme_mailbox_backend
→ MicroBlaze供应商API
→ NoPHAE s_axi_ctrl
```

MicroBlaze只搬运描述符和状态，不复制ADC Payload。先复用供应商样例验证
初始化、Queue、DMA和错误行为；确认全部语义后，再决定是否开发纯RTL
AXI-Lite Backend。

### 12.6 本轮文档和命令

新增：

```text
docs/NVMe_ADC_DDR_FPGA基础通路设计方案_V2.2_NoPHAE用户指南接口收敛版.docx
docs/NoPHAE用户指南深度分析_V2.1修订与供应商问题_2026-07-29.md
docs/build_v22_docs.py
docs/check_v22_docx_structure.py
```

更新：

```text
README.md
vendor_ip_contract.md
supplier_onsite_test_checklist.md
docs/ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md
```

生成命令：

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\docs\build_v22_docs.py
```

结构检查命令：

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  .\docs\check_v22_docx_structure.py
```

### 12.7 本轮实际结果

```text
V2.2 DOCX：48641 Byte
普通段落：89
表格：13
核心标题：NVMe_ADC_DDR_FPGA基础通路设计方案 V2.2
结构检查：PASS
```

结构检查覆盖：

- DOCX ZIP和内部CRC；
- `[Content_Types].xml`、关系、正文、样式、编号和核心属性；
- V2.2版本、NoPHAE端口、DMA寄存器、KU040风险和8个供应商问题；
- 未清理`TODO/TBD/FIXME`及模板占位符。

按用户和工作区要求，本轮没有调用LibreOffice，没有生成PDF、PNG或页面截图，
也没有执行Vivado回归。

## 13. Vitis源码实证与现有RTL修复（V2.3，2026-07-31）

### 13.1 本轮范围

本轮输入为已经写好的Vitis Classic工程，不重建Vitis软件。核心源码位于：

```text
E:\NVME_PRO\vitis_classic\nvme\src
```

工作内容为：

1. 由现有C源码、ELF、bitstream和XSA提取真实软件/硬件契约；
2. 给四个核心C/H文件增加中文语义注释，不改变非注释C token；
3. 依据软件实际访问修复现有RTL/SV，并补齐`0x90000000`兼容接口；
4. 新增NoPHAE寄存器Backend和完整Vitis ABI行为测试；
5. 同步更新设计、软件使用、板级输入、供应商现场和契约文档；
6. 只运行Vivado编译和XSim行为仿真，不运行综合或实现。

### 13.2 已有制品和XSA事实

| 对象 | 结果 |
|---|---|
| `nvme.elf` | 303488 Byte，ELF32 little-endian，MicroBlaze，SHA256=`A75ADA0EF77714EC6C14E4D90028690D47512BC86432EE24591BC4B1D2248BFA` |
| `design_1_wrapper.bit` | SHA256=`5CD336000563775E97C85C871C0B5C43E62AC3AB0998919DFF3DDE0E9556E0FA` |
| `design_1_wrapper.xsa` | SHA256=`C0807F333FB7429BC3733B2D4BD6B2125E3D283133D04DB98FD976104FEAAD5E` |
| NoPHAE | `xilinx.com:user:nophae_top:2.0`，XCKU040，Vivado 2024.2 |
| `s_axi_ctrl` | 32 bit数据、40 bit地址、125 MHz，`0x10000000`、4 KiB |
| NoPHAE `m_axi` | 256 bit数据、32 bit地址、10 bit ID、125 MHz，最大Burst 256、Outstanding 2 |
| MIG | 512 bit数据、32 bit地址、ID width 1、`RD_PRI_REG` |
| DDR/UART | `0x80000000`～`0xFFFFFFFF`共2 GiB；UART=`0x40600000` |

当前XSA/HWH没有`0x90000000`外设。原ELF却固定访问
`0x90000000`～`0x9000003C`，因此原bitstream不能被表述为已经支持FDMA
菜单13～17。V2.3 RTL补齐了ABI，但尚未并入供应商原bitstream。

### 13.3 Vitis源码注释结果

注释风格固定为：函数/连续流程概括可单独成段，其余重要语句在源码本行后
空4格写中文注释。`Xil_Out32`、关键寄存器读写、轮询、换算、危险操作和每个
`case/default`分支均给出业务含义。删除原行号标记、无语义结束说明及
`type_define.h`中“定义宏名、地址表达式为……”一类复述。

| 文件 | 覆盖率 | 分支注释 | C token指纹 |
|---|---:|---:|---|
| `func.c` | 408/505，80.79% | 20/20 | `01E6E079420B41B9D1401F5B43E59BB5395523CBB869FC6F9D29A64F4249A99F` |
| `func.h` | 29/30，96.67% | 0/0 | `09066FB879A5C607B4FE12B6B8C6A06421A4A20C5910ADF45E9F4C50C35C25D0` |
| `helloworld.c` | 239/400，59.75% | 26/26 | `2AD95647C9523BD6EE607E396F06206740989D843E4E0446EBC6948BE57271A5` |
| `type_define.h` | 82/84，97.62% | 0/0 | `984379EAD19F5E4B9E7227A1A571FEAA1DB26F3CE0A9A577E354A3149C560939` |

`annotate_core_sources.py --verify`现在同时检查：

- 非注释C token指纹；
- 每个文件重要语句覆盖率大于50%；
- 所有`case/default`都有同行注释；
- 同行注释前恰好4个空格；
- 禁止原行号和无语义结束注释；
- `type_define.h`禁止宏名/宏值/地址表达式复述。

### 13.4 RTL/SV修复

新增或重点修改：

```text
rtl/nvme_adc_vitis_compat_top.sv
rtl/fdma_vitis_compat_regs.sv
rtl/adc_capture_limit_controller.sv
rtl/nophae_dma_backend.sv
rtl/nvme_adc_pipeline_top.sv
rtl/adc_ddr_segment_writer.sv
rtl/segment_buffer_manager.sv
rtl/nvme_request_scheduler.sv
rtl/stubs/nophae_ctrl_reg_stub.sv
rtl/stubs/axi_ddr_mem_stub.sv
sim/tb_nophae_dma_backend.sv
sim/tb_nvme_adc_vitis_compat.sv
```

关键变化：

- CDC载荷从263 bit改为329 bit，使数据、EOC、有效字节数、通道模式和
  Capture ID原子跨域；
- 定长采集按单/双通道字节数换算，达到目标后不多采一个样本；
- START尚未进入Packer即STOP时返回`D006`，避免旧软件永久轮询；
- DDR Writer增加格式、样本粒度、Burst、FIFO和4 KiB检查；
- Segment未知Completion Tag和Fill错误进入致命状态；
- Scheduler增加会话LBA、显式HALT、Commit校验和Timeout同拍处理；
- `nophae_dma_backend`实现
  `physical_ddr_addr - 0x80000000`和`byte_len / 512`换算；
- Capture严格执行`Payload Write → Flush → Commit Write → Flush`；
- `fdma_vitis_compat_regs`实现旧ELF的`0x90000000` ABI和诊断扩展区；
- 默认`MIN_START_SLBA=1048576`，阻止软件默认LBA0覆盖SSD前512 MiB。

### 13.5 无综合回归结果

执行命令：

```powershell
Set-Location E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1
```

脚本固定调用：

```text
D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat
```

2026-07-31 11:55～12:01实际结果：

| 测试平台 | 结果 | FirstFatal |
|---|---|---|
| `tb_adc_channel_packer` | PASS | `null` |
| `tb_nvme_adc_pipeline` | PASS | `null` |
| `tb_nvme_scheduler_errors` | PASS | `null` |
| `tb_nophae_dma_backend` | PASS | `null` |
| `tb_nvme_adc_vitis_compat` | PASS | `null` |

统一结果：

```text
build/regression/summary.json
5 PASS / 0 FAIL / FirstFatal=null
```

完整ABI测试在7041 ns结束：

```text
TEST_PASS: Vitis FDMA ABI -> ADC/DDR -> NoPHAE full contract
TEST_STATS: samples=16 dma=2 flush=2 requests=4
```

该测试还验证LBA0被`D004`拦截、开始采集前取消返回`D006`、DDR物理地址转
NoPHAE Offset、4 KiB转8个LBA、Payload和Commit内容及两次Flush顺序。

### 13.6 文档交付和结构检查

新增当前版：

```text
docs/NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3.md
docs/NoPHAE_Vitis现有软件使用与验证指南_V1.0.md
docs/NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版.docx
docs/build_v23_docs.py
docs/check_v23_docx_structure.py
```

DOCX检查结果：

```text
62306 Byte
410个普通段落
22个表格
核心标题：NVMe_ADC_DDR_FPGA基础通路设计方案 V2.3
DOCX_STRUCTURE_PASS
```

检查覆盖ZIP/CRC、OOXML必需部件、核心属性、关键技术锚点、内容规模和占位符。
按工作区要求没有调用LibreOffice，没有渲染PDF/PNG，也没有做页面视觉验收。

### 13.7 仍未完成的真实硬件等级

当前没有板卡/JTAG/SSD连接，也没有真实NoPHAE RTL/SV和完整可修改Vivado
工程。本轮结论等级止于“静态制品/源码通过”和“XSim行为模型通过”，不能写成：

- 新RTL已经进入当前bitstream；
- PCIe/NVMe已在本机初始化通过；
- DDR→SSD→DDR真实回读一致；
- ADC→DDR→SSD长时间完整通路通过。

V2.3已经准备好实际工程的三个连接边界：MicroBlaze到`0x90000000`、
Backend到NoPHAE `0x10000000`以及ADC Writer到MIG。后续硬件工程到手时
继续使用现有`nvme.elf`，只修改并验证Vivado硬件工程。

## 14. V2.4 代码级详细设计与RTL注释（2026-08-10）

### 14.1 最新范围调整

本轮最初方案包含第六项定向回归，随后按最新要求收敛为：

1. 不再运行Vivado/XSim回归，不新增第六项测试；
2. 不运行综合、实现或bitstream生成；
3. 11个正式通路RTL只增加或修正中文注释；
4. 唯一允许的非注释文本变化是adc_channel_packer中的always_comb改为always @*；
5. DOCX生成、RTL静态检查和DOCX结构检查在远程主机vivado-srv执行；
6. V2.4文档和修改后的正式RTL同步到远程实际工程目录。

本轮没有修改Vitis C/H源码，没有重建ELF。

### 14.2 RTL注释覆盖

正式通路覆盖：

~~~text
rtl/nvme_adc_vitis_compat_top.sv
rtl/fdma_vitis_compat_regs.sv
rtl/adc_capture_limit_controller.sv
rtl/nvme_adc_pipeline_top.sv
rtl/adc_channel_packer.sv
rtl/axis_async_fifo.sv
rtl/adc_ddr_segment_writer.sv
rtl/sync_fifo.sv
rtl/segment_buffer_manager.sv
rtl/nvme_request_scheduler.sv
rtl/nophae_dma_backend.sv
~~~

注释重点：

- 参数、端口、状态、寄存器、计数器、CDC同步级和派生信号；
- Capture是一次完整任务，不是SV类型；
- Manager只管理DDR槽位所有权，不是AXI Master且不搬运数据；
- alloc是Writer到Manager的项目内ready/valid握手；
- stall是valid=1且ready=0时必须保持当前条目的反压停顿；
- sticky是瞬时错误置位后保持到代码规定的清除条件；
- Packer的DRAIN、pending缓存、配置锁存和accepted/dropped统计；
- Writer八状态、AXI四状态、ready门控、CRC、4 KiB补零和fill描述符；
- Manager generation、迟到Completion和ERROR_HOLD；
- Commit页字段、共享地址生命周期以及两次Flush；
- Scheduler的单请求在途、SLBA推进和Backend地址域换算。

正式RTL中错误的当前263 bit注释已经改为329 bit。current_ddr_addr、
job_is_commit和data_payload_bytes等保留对象已明确标注当前未读取或遗留保留。

### 14.3 非注释源码不变量

新增守门脚本：

~~~text
scripts/check_v24_rtl_comment_only.ps1
scripts/check_v24_markdown_links.ps1
~~~

脚本在修改前建立的11个去注释SHA-256基线基础上检查当前文件，并把
always_comb预先规范化为唯一允许的always @*形式。本地和远程结果均为：

~~~text
V24_RTL_COMMENT_ONLY_PASS: 11/11 comment-free hashes match
V24_COMBINATIONAL_STYLE_PASS: adc_channel_packer uses always @*
V24_COMMENT_COVERAGE_PASS: every declaration has inline or immediately preceding semantics
V24_REGRESSION_SKIPPED: per latest user instruction
V24_SYNTHESIS_SKIPPED: no synthesis or implementation invoked
~~~

这表示注释工作没有改变端口、常量、状态编码、赋值、时序或功能表达式。
Markdown链接脚本在本地和远端均得到
V24_MARKDOWN_LINKS_PASS: 21 local links resolved。

### 14.4 V2.4文档交付

新增：

~~~text
docs/ADC_DDR_NVMe_V2.4_代码级详细设计方案.md
docs/NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解.docx
docs/build_v24_docs.py
docs/check_v24_docx_structure.py
~~~

Markdown正文包含术语、全链路、默认参数推导、Packer、Capture Controller、
329 bit CDC、Writer、Manager、Commit页、Scheduler、NoPHAE Backend、
保护删除反证、软件指导以及11个模块的代码级字典。

DOCX使用compact_reference_guide和memo_masthead：

- US Letter纵向，四边1英寸；
- Calibri 11 pt，正文1.25倍行距；
- Heading 1/2/3为真实Word标题样式；
- 软件步骤使用真实List Number；
- 所有表格固定9360 DXA、缩进120 DXA，并逐列写入固定grid和tcW；
- 页眉、页脚和页码字段采用memo样式。

### 14.5 远程执行与同步

远程主机和目标：

~~~text
SSH别名：vivado-srv
主机：172.20.10.11
目标：C:\project\RTDS\nvme_adc_axi_pipeline
~~~

远端系统Python 3.12原先没有python-docx，因此在工程docs目录创建隔离环境
.venv_v24_docs，并只在该环境安装python-docx 1.2.0及其依赖，没有修改系统
Python。远程生成结果：

~~~text
DOCX_STRUCTURE_PASS
文件大小：72939 Byte
普通段落：199
表格：43
正文和表格文本：32839字符
核心标题：NVMe_ADC_DDR_FPGA详细设计方案 V2.4
DOCX_GEOMETRY_PASS
Letter / 1in margins / 9360DXA / 120DXA / fixed layout
DOCX_RENDER_SKIPPED
~~~

远端结构检查覆盖ZIP/CRC、OOXML必需部件、核心属性、标题层级、编号样式、
固定表格几何、页眉页脚字段、关键术语、内容规模和未清理占位符。按工作区
要求未调用LibreOffice，未生成PDF/PNG，也没有页面视觉验收。

### 14.6 本轮结论等级

本轮只证明：

- 注释后的正式RTL与修改前功能文本一致；
- Packer组合过程按要求写成always @*；
- V2.4代码级设计文档和DOCX结构完整；
- 本地与远程工程中的相关RTL和文档一致。

本轮没有执行新回归，因此不把V2.3的5 PASS写成V2.4结果，也不宣称
6 PASS / 0 FAIL。没有真实NoPHAE内部RTL、综合、时序、上板或SSD回读证据。

## 15. V2.4架构、数据流、接口与时序图册补充（2026-08-10）

### 15.1 用户要求与执行边界

在V2.4代码级信号详解文档中新增：

1. 正式Vitis兼容通路总体顶层架构图；
2. 一次Capture的端到端数据流图；
3. 顶层接口信号分组列表；
4. 11个正式模块各自的顶层架构图、逐端口接口信号列表和关键时序图；
5. 每张架构图、数据流图和时序图后的详细文字说明。

本轮只修改文档源、DOCX生成器、结构检查器、README和执行记录，没有修改
任何RTL/SV或Vitis源码；没有运行RTL回归、行为仿真、综合或实现。按照工作区
规则，只检查DOCX结构，不渲染PDF/PNG。

### 15.2 图册组织与事实源

新增图形目录：

~~~text
docs/v24_visual_catalog.py
~~~

该文件只保存总体/模块架构、代表性时序和详细读图说明。逐端口接口表不在图形
目录中手工复制，而是由`build_v24_docs.py`直接解析11个
`rtl/<module>.sv`的模块头，提取方向、参数化位宽、端口名和同行中文语义，再按
端口前缀补充分组和时钟域。

本次从RTL模块头提取429个正式端口：

| 模块 | 端口数 |
|---|---:|
| nvme_adc_vitis_compat_top | 80 |
| fdma_vitis_compat_regs | 40 |
| adc_capture_limit_controller | 21 |
| nvme_adc_pipeline_top | 64 |
| adc_channel_packer | 24 |
| axis_async_fifo | 15 |
| adc_ddr_segment_writer | 55 |
| sync_fifo | 9 |
| segment_buffer_manager | 41 |
| nvme_request_scheduler | 42 |
| nophae_dma_backend | 38 |

结构检查器会定位11张六列表格，并逐模块比较DOCX中的端口顺序与当前RTL模块头；
任一端口缺失、顺序变化或语义为空都会失败。图形检查还逐项确认总体两张图、
11张模块架构图、11张模块时序图、11张接口表及24组详细文字说明标题。

### 15.3 图形表达和详细文字说明

总体顶层图按“软件控制/所有权、ADC采集与DDR缓存、NoPHAE/SSD持久化”三条
职责通道组织，明确Manager不搬运数据、DDR同时是Writer写目标和NoPHAE DMA源、
本地排空完成不同于SSD最终完成。

数据流图从12 bit双路ADC开始，依次说明16 bit格式化、256 bit打包、329 bit原子
CDC、Segment分配、CRC与4 KiB补零、DDR、Manager READY、Scheduler四阶段顺序、
Backend和SSD Completion。说明同时覆盖stall保持、不可反压ADC的丢样边界、
Payload bytes与DMA bytes的区别和Commit页的持久化位置。

每个模块的架构图后至少有三段说明，分别解释数据/控制方向、内部职责和异常边界；
每个时序图后至少有三段说明，逐阶段解释握手、状态转换、stall保持及完成或错误
条件。图和时序均使用Word原生固定表格或等宽文本，没有嵌入本地截图或位图。

### 15.4 本地与远程结构检查

本地先执行Python语法检查、DOCX生成、DOCX结构检查和Markdown链接检查。随后把
Markdown、生成器、检查器、图形目录、DOCX和README同步到远程：

~~~text
SSH别名：vivado-srv
远程目录：C:\project\RTDS\nvme_adc_axi_pipeline
远程Python：docs\.venv_v24_docs\Scripts\python.exe
~~~

远程使用隔离Python环境重新生成DOCX，并执行同一结构检查。结果为：

~~~text
DOCX_GENERATED: 127116 bytes
DOCX_STRUCTURE_PASS
普通段落：454
表格：69
正文和表格文本：81243字符
DOCX_GEOMETRY_PASS: Letter / 1in / 9360DXA / 120DXA / fixed
DOCX_RENDER_SKIPPED
V24_MARKDOWN_LINKS_PASS: 21 local links resolved
~~~

远程系统执行策略默认禁止直接运行PS1；Markdown只读检查使用单次
`powershell.exe -NoProfile -ExecutionPolicy Bypass -File`执行，没有修改系统执行策略。
远程生成的DOCX回传本地作为最终件，本地和远程SHA-256相同：

~~~text
C108CE518DEA8E3088E5DDC2231EC5E595F873D4F63798CDB9369112CED23424
~~~

### 15.5 交付文件

~~~text
README.md
docs/ADC_DDR_NVMe_V2.4_代码级详细设计方案.md
docs/NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解.docx
docs/build_v24_docs.py
docs/check_v24_docx_structure.py
docs/v24_visual_catalog.py
docs/ADC_DDR_NVMe_V2_设计验证与Codex执行记录.md
~~~

本节记录的通过项只证明图册内容、RTL端口映射、OOXML部件、标题/编号样式、固定
表格几何、关键术语和内容规模满足检查条件；没有PDF/PNG视觉渲染证据，也不代表
RTL功能、综合、时序或板级行为已经在本轮重新验证。

## 16. V2.4正文融合、电路图和高低电平时序修订（2026-08-10）

### 16.1 内容重组

按最新要求删除DOCX中的独立“附录D”。11个正式模块的架构图、接口信号列表、
关键时序图和详细文字说明通过Markdown隐藏插入标记，分别放入对应正文：

| 正文章节 | 就地展开模块 |
|---|---|
| 第3节 | nvme_adc_vitis_compat_top |
| 第5节 | adc_channel_packer |
| 第6节 | adc_capture_limit_controller |
| 第7节 | axis_async_fifo |
| 第8节 | sync_fifo、adc_ddr_segment_writer |
| 第9节 | segment_buffer_manager |
| 第11节 | nophae_dma_backend、nvme_request_scheduler、nvme_adc_pipeline_top |
| 第13节 | fdma_vitis_compat_regs |

结构检查明确禁止DOCX正文出现“附录D”“图D-”或“表D-”，并逐项确认11个模块的
Heading 3、架构图、接口表、时序图和说明标题都存在。

### 16.2 原图保留与电路/Visio风格重绘

原有Word固定表格式总体图和11张模块架构图均保留，并在每张原图后增加一张重绘图。
重绘图使用：

- 外层模块边界和内部功能块；
- 左侧I端口、右侧O端口；
- 端口圆点、总线汇聚点和方向箭头；
- 水平/垂直正交连接器；
- 与正文一致的控制、数据、描述符和Completion语义。

总体架构和Capture数据流也分别增加Visio泳道/正交连接器重绘图。共生成13张
高分辨率PNG，仅作为DOCX行内图使用：

~~~text
docs/build_v24_circuit_diagrams.py
docs/figures_v24/*.png
图数：13
图源总大小：1479337 Byte
~~~

DOCX图片审计结果为13个`wp:inline`、0个浮动`wp:anchor`。图片源和中间图没有在
前台显示。每张新旧架构图、总体数据流图和时序图仍紧跟详细文字说明。

### 16.3 I/O接口和高低电平时序

接口表方向列由“输入/输出/双向”统一改为：

| 标记 | 含义 |
|---|---|
| I | 进入模块的输入端口 |
| O | 由模块驱动的输出端口 |
| I/O | 真正的双向端口；项目中的AXI双向传输仍由独立I和O端口构成 |

11张接口表仍由RTL模块头自动提取，共429个端口。结构检查逐项比较端口名称、顺序
和I/O方向，不允许文档方向与RTL的input/output/inout声明不一致。

原有以字符0、1和`1/0`表示电平的时序表不再写入DOCX。新的11张时序图按统一
时间列生成：低电平使用`▁`，高电平使用`▔`，边沿使用`╱/╲`，状态或总线阶段仍
使用文字。每个信号占一行、每个周期占固定DXA列，因此各信号边沿按时间列对齐。
检查器要求11张时序表全部存在、行列规则一致、至少包含高低电平波形字符，并禁止
单元格继续使用孤立的0、1、0/1或1/0表示逻辑电平。

### 16.4 生成和检查结果

本地及远程均使用更新后的`build_v24_docs.py`和
`check_v24_docx_structure.py`。最终远程生成结果：

~~~text
DOCX_GENERATED: 1497206 bytes
DOCX_STRUCTURE_PASS
普通段落：467
表格：80
正文和表格文本：81447字符
行内电路/Visio图：13
浮动图：0
DOCX_GEOMETRY_PASS: Letter / 1in / 9360DXA / 120DXA / fixed
DOCX_RENDER_SKIPPED
V24_MARKDOWN_LINKS_PASS: 21 local links resolved
~~~

远程原文件当时被Word占用，SCP和生成器均得到Permission denied。未强制关闭远程
Word，也未删除或改名被占用文件；在同一目录生成并检查以下新文件：

~~~text
C:\project\RTDS\nvme_adc_axi_pipeline\docs\
NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解_正文融合电路图版.docx
~~~

远程生成件已回传覆盖本地标准交付文件。本地标准文件与远程“正文融合电路图版”
SHA-256一致：

~~~text
366B0A5F0E2E4EA944E968331D4BB6C5D9A93DAE3ED25CF94262A988DC7620AE
~~~

### 16.5 验证边界

本轮没有修改任何RTL/SV或Vitis源码，没有运行RTL回归、XSim、综合或实现。按照
工作区Word规则只进行ZIP/CRC、OOXML部件、图片锚定、标题层级、固定表格几何、
接口端口映射、图文锚点和波形结构检查，没有渲染PDF/PNG页面，不声明完成页面级
视觉验收。

## 17. V2.4框图字号、连续边沿和章节开篇调整（2026-08-10）

### 17.1 新增框图字号

新增框图在2400 pixel宽图源中统一提高字体：Title 46→58、Lane 29→42、
Node 27→39、Body 23→35、Pin 25→38 pixel。图片在DOCX中固定缩放为6.28英寸，
对应字号增量约2.3～2.5 pt，落在要求的2～3 pt范围内。为避免放大后文字拥挤，
同步提高模块框图、总体架构图和数据流图的画布高度、功能块高度和内部留白。

### 17.2 图标题简化

Caption中删除“电路/Visio风格重绘”“重绘”“高/低电平对齐”等实现性描述。
标题只保留图的用途和区分项：

| 图类型 | 当前标题后缀 |
|---|---|
| 原Word架构图 | 接口关系表 |
| 新增架构图 | 系统框图或模块框图 |
| 原数据流表 | 阶段表 |
| 新数据流图 | 数据流框图 |
| 模块时序图 | 关键时序图，无波形实现后缀 |

结构检查遍历全部49个Caption，出现`重绘`、`高/低电平对齐`或`电路/Visio`
任一字样即失败。

### 17.3 连续时序波形

11张时序图从Word周期单元格波形改为连续高分辨率图。每个信号共用一条连续
时间轴：

- A0～A5、C0～C4等周期在同一横向坐标系中连续排列；
- 周期边界只画灰色垂直虚线，不切断水平电平线；
- 电平在相邻周期发生变化时，只在公共边界画一条蓝色垂直转换沿；
- 同一下降沿或上升沿不会在前后两个周期中各画一次；
- 状态/总线值合并相邻同值周期，二值信号使用连续水平高/低电平。

生成器中的转换沿只由当前周期向下一周期比较后绘制一次，并保留源内不变量注释
`每个周期边界只画一次垂直转换边沿`。结构检查要求11个
`*_timing_waveform.png`全部存在，且24个总图源集合、PNG签名和最低分辨率均正确。

### 17.4 模块图表移动到章节最开头

11个模块的“架构、接口与时序”整体移动到相关章节标题之后、首个状态机或行为
小节之前：

| 章节 | 首先出现的模块图表 |
|---|---|
| 第3节 | nvme_adc_vitis_compat_top |
| 第5节 | adc_channel_packer |
| 第6节 | adc_capture_limit_controller |
| 第7节 | axis_async_fifo |
| 第8节 | adc_ddr_segment_writer、sync_fifo |
| 第9节 | segment_buffer_manager |
| 第11节 | nvme_request_scheduler、nophae_dma_backend、nvme_adc_pipeline_top |
| 第13节 | fdma_vitis_compat_regs |

检查器比较主章节标题、模块Heading 3和第一个正文小节的段落序号，要求每个模块
满足`section_index < module_index < first_body_index`。

### 17.5 本地与远程结果

本地和远程检查结果：

~~~text
DOCX_GENERATED: 3143849 bytes
DOCX_STRUCTURE_PASS
普通段落：467
表格：69
正文和表格文本：77565字符
行内图片：24
浮动图片：0
Caption：49
V24_MARKDOWN_LINKS_PASS: 21 local links resolved
DOCX_RENDER_SKIPPED
~~~

远程最终文件：

~~~text
C:\project\RTDS\nvme_adc_axi_pipeline\docs\
NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解_正文开篇连续波形版.docx
~~~

远程生成件已回传为本地标准交付文件。两者SHA-256一致：

~~~text
617CD525FDBADF1645312F69385D5C6A0F1C9E453C06801F95707DFE304C71CA
~~~

本轮仍未修改RTL/SV或Vitis源码，未运行RTL回归、XSim、综合或实现；按工作区规则
没有渲染DOCX页面到PDF/PNG。
