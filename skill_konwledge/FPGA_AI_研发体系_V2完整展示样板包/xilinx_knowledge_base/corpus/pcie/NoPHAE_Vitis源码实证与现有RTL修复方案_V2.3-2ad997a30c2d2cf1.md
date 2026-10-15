# NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3.md`
- SHA-256: `2ad997a30c2d2cf110840122bac755304deabc6137e9afc93e5ad78b75d4c70d`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3.md

# NoPHAE Vitis 源码实证与现有 RTL 修复方案 V2.3

更新日期：2026-07-31
适用目录：`E:\NVME_PRO\vitis_classic`、`E:\NVME_PRO\nvme_adc_axi_pipeline`
验证边界：只做源码静态核对、RTL 编译和 XSim 行为仿真，不运行综合，不重建 Vitis 软件，不声称板卡、PCIe、DDR 或 SSD 已实测通过。

## 1. 当前结论

这次取得的 Vitis 工程把此前不确定的 NoPHAE 软件契约变成了可核对的源码事实。现有软件不是待重建样例，而是已经生成 ELF、bitstream 和 XSA 的工程。当前工作的正确方向是：

1. 保留现有 Vitis 软件的寄存器地址、队列创建和轮询顺序；
2. 根据软件实际访问补齐当前自研 RTL 中缺失的 `0x90000000` FDMA 兼容寄存器；
3. 把自研调度器的抽象请求转换成 NoPHAE `0x10000000` 控制寄存器序列；
4. 修正 ADC、CDC、DDR 分段、完成关联和错误冻结中的现有问题；
5. 用行为 Stub 证明软件 ABI、地址换算、长度单位及 Payload/Flush/Commit/Flush 顺序；
6. 等真实 NoPHAE RTL/SV 和完整 Vivado 工程到手后，只做实例接线、参数复核和板级验证，不提前猜测加密 IP 内部实现。

本轮没有改变 Vitis 程序的非注释 C token，也没有重新生成 `nvme.elf`。软件源码只增加中文语义注释；RTL 修改位于 `nvme_adc_axi_pipeline`。

## 2. 证据和版本基线

### 2.1 已有制品

| 制品 | 路径 | SHA256 | 结论 |
|---|---|---|---|
| MicroBlaze ELF | `vitis_classic\nvme\Debug\nvme.elf` | `A75ADA0EF77714EC6C14E4D90028690D47512BC86432EE24591BC4B1D2248BFA` | 303,488 Byte，ELF32 little-endian，`e_machine=0x00BD`，即 MicroBlaze |
| 已有 bitstream | `vitis_classic\nvme\_ide\bitstream\design_1_wrapper.bit` | `5CD336000563775E97C85C871C0B5C43E62AC3AB0998919DFF3DDE0E9556E0FA` | 历史 Vitis Launch 使用的器件配置文件 |
| 硬件平台 XSA | `vitis_classic\wrapper1\hw\design_1_wrapper.xsa` | `C0807F333FB7429BC3733B2D4BD6B2125E3D283133D04DB98FD976104FEAAD5E` | Vivado 2024.2、XCKU040 硬件导出 |

静态复核命令：

```powershell
& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1
```

该脚本只读检查 SHA256、ELF 类型、XSA/HWH 地址事实和源码注释清单，不连接板卡、不构建软件。

### 2.2 Vitis 源码注释等价性

注释范围：

- `vitis_classic\nvme\src\func.c`
- `vitis_classic\nvme\src\func.h`
- `vitis_classic\nvme\src\helloworld.c`
- `vitis_classic\nvme\src\type_define.h`

规则：

- 重要语句的中文说明写在同一源码行，源码后固定四个空格再写 `//`；
- 函数或连续代码段的概括可以独立成段；
- `Xil_Out32`、寄存器读取、轮询、单位换算、危险操作和每个 `case/default` 必须有业务语义；
- 不使用原行号标记，不保留“结束作用域”一类无语义注释；
- `type_define.h` 的寄存器宏只说明业务含义，不复述宏名、宏值或“地址表达式为……”；
- 每个文件的重要语句覆盖率必须大于 50%；
- 注释前后的非注释 C token 指纹必须相同。

当前校验结果：

| 文件 | 已注释重要语句/重要语句 | 覆盖率 | `case/default` |
|---|---:|---:|---:|
| `func.c` | 408/505 | 80.79% | 20/20 |
| `func.h` | 29/30 | 96.67% | 0/0 |
| `helloworld.c` | 239/400 | 59.75% | 26/26 |
| `type_define.h` | 82/84 | 97.62% | 0/0 |

清单位于 `vitis_classic\nvme\source_annotation_manifest.json`。重新生成或验证时使用：

```powershell
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  E:\NVME_PRO\vitis_classic\annotate_core_sources.py --restyle

& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  E:\NVME_PRO\vitis_classic\annotate_core_sources.py --verify
```

## 3. XSA 给出的真实硬件边界

`design_1.hwh` 可以确认以下事实：

| 项目 | 当前 XSA 实例值 |
|---|---|
| 器件 | `xcku040-ffva1156-2-i` |
| 工具 | Vivado 2024.2 |
| NoPHAE 实例 | `nophae_top_0` |
| NoPHAE VLNV | `xilinx.com:user:nophae_top:2.0` |
| NoPHAE `s_axi_ctrl` | AXI4-Lite，32 bit 数据，40 bit 地址，125 MHz |
| NoPHAE 控制地址 | `0x10000000`，4 KiB |
| NoPHAE `m_axi` | AXI4-Full，256 bit 数据，32 bit 地址，10 bit ID，125 MHz |
| NoPHAE最大 Burst | 256 beat |
| NoPHAE Outstanding | 2 |
| MicroBlaze DDR 窗口 | `0x80000000`～`0xFFFFFFFF`，2 GiB |
| MIG S_AXI | 512 bit 数据、32 bit 地址、ID width 1、`RD_PRI_REG` |
| UART | `0x40600000`，软件配置为 115200 bit/s |

当前 XSA 中的控制连接是：

```text
MicroBlaze
  └─ SmartConnect_1
       ├─ NoPHAE s_axi_ctrl @ 0x10000000
       └─ MIG DDR @ 0x80000000..0xFFFFFFFF

NoPHAE m_axi
  └─ SmartConnect_0
       └─ MIG DDR
```

XSA/HWH 中没有 `0x90000000` 外设。软件却固定访问该地址，因此当前导出的 bitstream 与软件 FDMA 菜单之间存在明确缺口。新 RTL 已实现这个 ABI，但尚未进入供应商原 bitstream；没有完整 Vivado 工程时不能伪造“已并入当前 bit”结论。

## 4. Vitis 源码形成的寄存器契约

### 4.1 NoPHAE `0x10000000`

软件实际使用的主要偏移如下：

| 偏移 | 名称/作用 | 软件行为 |
|---:|---|---|
| `0x00` | PCIe 初始化启动 | 写 1 后轮询状态 |
| `0x04` | NVMe 初始化启动 | 写 1 后轮询状态 |
| `0x08` | Debug/命令路径锁 | 选择调试、原生命令或指定 CID 路径 |
| `0x0C` | 调试请求操作/完成 | PCIe Memory/Configuration 读写 |
| `0x10` | 调试请求地址 | 写入目标地址 |
| `0x14` | 调试写数据 | 写入 32 bit 数据 |
| `0x18` | 调试读数据 | 读取 32 bit 数据 |
| `0x1C` | NoPHAE 状态 | 初始化轮询 |
| `0x44` | 高层 DMA 类型/启动 | 写方向为 1，读方向为 0 |
| `0x48` | 高层 DMA 长度 | 单位为 512 B LBA 数 |
| `0x4C` | DMA 源 | Write 时为 DDR Offset，Read 时为 SLBA |
| `0x50` | DMA 目的 | Write 时为 SLBA，Read 时为 DDR Offset |
| `0x54` | DMA Ready | 等于 1 后才能提交 |
| `0x60` | 原生命令编码 | Opcode、Queue/NSID 组合 |
| `0x6C`、`0x74` | PRP1/PRP2 低 32 bit | 当前软件按 DDR 相对地址使用 |
| `0x78`～`0x84` | CDW10～13 | 原生命令参数 |
| `0x8C` | CMD_WR | 写 1 提交原生命令 |
| `0x90`、`0x94` | I/O Queue 创建 | 软件创建队列后再启动 FDMA |
| `0xA8` | SQ Full | 队列流控 |
| `0xAC` | CQ 无错误 | 错误入口 |
| `0xC0` | 完成命令计数 | Flush 通过计数变化判断完成 |
| `0xC8` | 高层 DMA Done | 软件永久轮询到 1 |
| `0xCC` | MDTZ | 控制内部每命令传输规模 |
| `0xD8` | MPS | 软件按 4 KiB 假设配置 |
| `0xDC` | 版本文本 | 菜单启动时输出 |
| `0x144` 以后 | 成功 CQ 信息 | 指定 CID 和调试用途 |

### 4.2 软件固定使用的 FDMA `0x90000000`

原 ELF 访问的兼容区为 `0x90000000`～`0x9000003C`：

| 偏移 | 软件含义 |
|---:|---|
| `0x00` | 总任务启动/停止 |
| `0x04` | Burst 长度，单位为 32 bit beat |
| `0x08`、`0x0C` | 写/读耗时计数 |
| `0x10` | Pattern 起点 |
| `0x14` | 环形内存大小 |
| `0x18` | FDMA 数据位宽 |
| `0x1C`、`0x20` | 总字节数低/高 32 bit |
| `0x24` | 本地数据产生/采集完成 |
| `0x28`、`0x2C` | 总耗时低/高 32 bit |
| `0x30` | SSD 起始 LBA |
| `0x34` | FIFO 满状态 |
| `0x38` | NVMe 取数/任务完成 |
| `0x3C` | 起始 LBA 使能 |

## 5. V2.3 实现架构

```text
MicroBlaze现有ELF
       │ AXI4-Lite @ 0x90000000
       ▼
fdma_vitis_compat_regs
       │ start/stop/size/mode/capture_id
       ▼
adc_capture_limit_controller
       │ Toggle CDC + 稳定多位上下文
       ▼
adc_channel_packer
       │ 329 bit 原子CDC载荷
       ▼
axis_async_fifo
       ▼
adc_ddr_segment_writer ──AXI4 Write──► SmartConnect/MIG/DDR
       │ job/commit
       ▼
segment_buffer_manager
       ▼
nvme_request_scheduler
       │ 抽象req/cpl
       ▼
nophae_dma_backend
       │ AXI4-Lite @ 0x10000000
       ▼
NoPHAE s_axi_ctrl ──NoPHAE m_axi──► SmartConnect/MIG/DDR
                                      │
                                      ▼
                                  PCIe RC / SSD
```

集成顶层为：

```text
rtl/nvme_adc_vitis_compat_top.sv
```

它提供三个需要接入真实 Block Design 的总线边界：

1. ADC Writer 的 DDR AXI4 写主口；
2. MicroBlaze 到 `0x90000000` 的 AXI4-Lite Slave；
3. 后端到 NoPHAE `s_axi_ctrl` 的 AXI4-Lite Master。

## 6. 各 RTL 模块的当前修复

### 6.1 `nvme_adc_pipeline_top.sv`

- 默认 DDR 地址宽度改为 XSA 一致的 32 bit；
- 默认采集区改为 `0xC0000000`，避开软件在 `0x80000000` 附近使用的队列和测试缓冲；
- 增加每任务 `session_start/session_base_slba`；
- CDC FIFO 载荷由 263 bit 改为 329 bit，把 EOC、有效字节数、通道模式、Capture ID 和数据放入同一表项；
- 删除模式/Capture ID 分离跨域造成的首字上下文竞态；
- 把 ADC 完整性、数据格式、DDR、Segment 和调度器错误统一汇入致命状态；
- 把 FIFO Full/Programmable Full 同步到 `sys_clk` 后供软件状态寄存器读取。

329 bit 位域：

```text
[328]     end_of_capture
[327:322] valid_bytes
[321]     two_channel
[320]     single_channel_select
[319:256] capture_id
[255:0]   payload
```

### 6.2 `adc_capture_limit_controller.sv`

- 把软件写入的 64 bit 目标字节数换算为采样时刻数量；
- 双通道按 4 Byte/采样时刻，单通道按 2 Byte/采样时刻；
- 启动、停止、完成使用 Toggle CDC；
- 多位配置在同步后再多等一拍锁存；
- 自动停止采用组合阈值，使 Packer 在达到目标后的下一个采样沿先看到 STOP，避免多采 1 点；
- START 尚未真正进入 Packer 时收到 STOP，返回明确取消完成，避免旧软件永久轮询。

### 6.3 `adc_ddr_segment_writer.sv`

- 检查中间字必须为 32 Byte、尾字为 0～32 Byte；
- 检查有效字节数符合单/双通道样本粒度；
- 检查 Burst、FIFO 容量和 4 KiB 边界条件；
- Commit 信息携带错误状态，禁止把格式错误伪装成正常采集；
- 保持 256 bit Writer，不因 MIG 为 512 bit 重写数据格式；位宽转换由 SmartConnect 处理。

### 6.4 `segment_buffer_manager.sv`

- 完成 Tag 未命中任何 INFLIGHT Segment 时置状态错误；
- Fill 错误进入 `ERROR_HOLD`，不再错误释放为 FREE；
- 保留 `{generation, segment_id}`，防止迟到 Completion 释放新一代数据。

### 6.5 `nvme_request_scheduler.sv`

- 每任务装载软件给定的 Raw LBA 起点；
- 明确 `ST_HALT`，Fatal 后停止所有新请求；
- 外部完整性错误、Link Down、ECQE 和超时具有高于正常 Completion 的优先级；
- 修复 Completion 与 Timeout 同拍的边界竞态；
- 检查 Payload、Commit 地址和长度的 4 KiB 对齐；
- 只有 `Payload Write → Flush1 → Commit Write → Flush2` 全部成功才产生 `capture_done`。

### 6.6 `nophae_dma_backend.sv`

该模块不是猜测 NoPHAE 内部 RTL，而是严格复现当前 Vitis 源码的外部寄存器行为。

Write：

```text
poll 0x54 == 1
0x4C = physical_ddr_addr - 0x80000000
0x50 = slba
0x48 = byte_len / 512
0x44 = 1
poll 0xC8 == 1
```

Read：

```text
poll 0x54 == 1
0x4C = slba
0x50 = physical_ddr_addr - 0x80000000
0x48 = byte_len / 512
0x44 = 0
poll 0xC8 == 1
```

Flush：

```text
read 0xC0
0x08 = 2
写入cmd_code/PRP/CDW
0x8C = 1
0x08 = 0
poll 0xC0，直到计数变化
```

模块一次只保存一个项目 Tag，NoPHAE 完成后再把该 Tag 回送调度器，符合现有软件“一条高层 DMA 在途”的用法。

### 6.7 `fdma_vitis_compat_regs.sv`

该模块实现原 ELF 的 `0x90000000` ABI，并在 `0x40` 以后增加不破坏旧软件的诊断寄存器：

| 偏移 | 扩展功能 |
|---:|---|
| `0x40` | bit0：双通道；bit1：单通道时选择 CH1 |
| `0x44`、`0x48` | Capture ID 计数种子低/高 32 bit |
| `0x4C` | 任务状态位 |
| `0x50`、`0x54` | 已接受采样时刻数低/高 32 bit |
| `0x58`、`0x5C` | 丢失采样时刻数低/高 32 bit |
| `0x60` | FDMA 层最后错误 |
| `0x64` | NoPHAE 后端最后状态 |

`0x4C` 状态位：

| 位 | 含义 |
|---:|---|
| 0 | transfer_active |
| 1 | 本地采集完成 |
| 2 | NVMe 全任务完成 |
| 3 | 本地阶段完成 |
| 4 | ADC FIFO Full |
| 5 | ADC FIFO Programmable Full |
| 6 | Pipeline Fatal |
| 7 | `last_error != 0` |

默认 `MIN_START_SLBA=1,048,576`，即保护前 512 MiB。现有软件上电写入 LBA0；未先改为安全 LBA 时，START 返回错误终态，不向 NoPHAE 提交命令。

## 7. 地址、长度和盘上布局

必须区分三个地址域：

| 地址域 | 示例 | 使用者 |
|---|---|---|
| MicroBlaze/AXI 绝对地址 | `0xC0000000` | ADC Writer、MIG、软件直接 AXI 访问 |
| NoPHAE DDR Offset | `0x40000000` | `dma_srcaddr/dma_dstaddr` 中的 DDR 一侧 |
| SSD LBA | `0x00100000` | `dma_srcaddr/dma_dstaddr` 中的 SSD 一侧 |

换算公式：

```text
nophae_ddr_offset = physical_ddr_addr - 0x80000000
dma_lba_count     = byte_len / 512
next_slba         = current_slba + dma_lba_count
```

项目仍要求 Payload 和 Commit DMA 地址、长度按 4 KiB 对齐。ADC 尾段不足 4 KiB 时补零，真实 Payload 字节数和补齐后的 DMA 字节数分别记录。

默认地址建议：

```text
MicroBlaze DDR窗口：0x80000000 .. 0xFFFFFFFF
软件/队列/调试区： 保留0x80000000附近
ADC Segment区：    从0xC0000000开始
Commit页：         Segment区之后的独立4 KiB页
```

盘上顺序：

```text
session_base_slba
  ├─ Payload Segment 0
  ├─ Payload Segment 1
  ├─ ...
  └─ Commit页
```

Commit 页只有在所有 Payload 和第一次 Flush 完成后才写入，并由第二次 Flush 建立持久化顺序。

## 8. 错误码和恢复策略

FDMA 层：

| 状态 | 含义 |
|---|---|
| `D001` | 任务活动期间再次 START |
| `D002` | 总字节数为 0 |
| `D003` | 总字节数不符合当前通道样本粒度 |
| `D004` | 起始 LBA 落入保护区 |
| `D005` | Pipeline 已有 Fatal，不能开始新任务 |
| `D006` | 尚未开始采集时被软件取消 |
| `D100` | Pipeline Fatal |

NoPHAE 后端：

| 状态 | 含义 |
|---|---|
| `E001` | 不支持的 Opcode |
| `E002` | 长度为 0 或不是 LBA 整数倍 |
| `E003` | DDR 绝对地址越界或 Offset 超过 32 bit |
| `E004` | SLBA 超过当前 32 bit 软件寄存器能力 |
| `E005` | AXI4-Lite 返回错误响应 |
| `E006` | 单次 AXI4-Lite 事务超时 |
| `E007` | 整笔 NoPHAE 命令超时 |
| `E008` | 命令在途时 Backend 被禁止 |

致命错误策略：

```text
停止新Capture
→ 停止新NVMe请求
→ INFLIGHT/ERROR_HOLD不释放
→ 软件读取0x60/0x64和状态位
→ 人工复位或按供应商流程恢复
```

旧软件没有 Timeout，因此 FDMA 在启动校验失败或未启动采集即取消时会同时置两个 Done，使旧轮询能够退出；是否成功必须读取扩展错误寄存器，不能只看 Done。

## 9. 无综合验证

### 9.1 五项行为回归

| Testbench | 覆盖内容 |
|---|---|
| `tb_adc_channel_packer` | 双通道、单 CH0、单 CH1、边界字节数、符号扩展、配置锁存 |
| `tb_nvme_adc_pipeline` | 329 bit CDC、随机 AXI 背压、DDR 内容、Segment、Flush、Commit |
| `tb_nvme_scheduler_errors` | 错误 Completion、错误 Tag、Timeout、Link Down、ECQE、Flush 失败 |
| `tb_nophae_dma_backend` | NoPHAE 寄存器顺序、Write/Read 地址换算、长度、AXI 错误和超时 |
| `tb_nvme_adc_vitis_compat` | `0x90000000` ABI 到 ADC/DDR/NoPHAE 的完整闭环、LBA0 保护和取消路径 |

执行：

```powershell
Set-Location E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1
```

脚本固定调用：

```text
D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat
```

只启动 Behavioral Simulation，不调用 `synth_design`、`launch_runs synth_1` 或实现流程。

2026-07-31 11:55～12:01 的完整回归结果：

```text
tb_adc_channel_packer       PASS
tb_nvme_adc_pipeline        PASS
tb_nvme_scheduler_errors    PASS
tb_nophae_dma_backend       PASS
tb_nvme_adc_vitis_compat    PASS

5 PASS / 0 FAIL / FirstFatal=null
```

机器可读汇总位于 `build\regression\summary.json`。五项均重新经过 Vivado
2020.2 编译、展开和 XSim 运行，不是沿用旧日志。

### 9.2 Vitis ABI 完整闭环的已验证数据

集成仿真使用 64 Byte 双通道输入，结果为：

```text
accepted samples = 16
dropped samples  = 0
NoPHAE DMA        = 2（Payload、Commit）
NoPHAE Flush      = 2
scheduler request = 4
```

同时验证：

- `0x80010000` 物理地址转换为 `0x00010000` NoPHAE DDR Offset；
- 4 KiB DMA 转换为 8 个 512 B LBA；
- Commit 地址和 SLBA 紧跟 Payload；
- 每个 ADC 样本的 DDR 小端字节序正确；
- Commit Magic 正确；
- LBA0 不进入后端；
- START 后在 Packer Ready 前 STOP 能形成 `D006` 终态；
- 正常路径无 Fatal、无丢样、无 Backend 错误。

## 10. 并入真实现有工程时的操作

这一步是修改硬件工程，不是重建 Vitis 软件：

1. 在实际 Vivado Block Design 中加入 `nvme_adc_vitis_compat_top.sv` 及其依赖 RTL；
2. 把 MicroBlaze 的 AXI 地址空间新增 `0x90000000`、4 KiB，从 SmartConnect 接到 `s_axi_fdma_*`；
3. 把 `m_axi_nophae_*` 接到 NoPHAE `s_axi_ctrl`，地址仍为 `0x10000000`；
4. 把 ADC Writer 的 `m_axi_ddr_*` 接到现有 MIG SmartConnect；
5. 确认 ADC Segment 区和 Commit 页不与 SQ/CQ、PRP、软件测试区重叠；
6. 连接 `ddr_init_done`、`nvme_init_done`、`pcie_link_up` 和 ECQE；
7. 先跑 Behavioral Simulation，再做板级 DDR/NoPHAE 联调；
8. 继续使用现有 `nvme.elf`，除非以后明确要修复软件功能缺陷。

本轮不综合，因此没有生成新 bitstream，也没有改写当前 XSA。

## 11. 已知限制

- 当前没有真实 NoPHAE RTL/SV、完整 Vivado BD、MIG/XDC 和板卡连接；
- 当前机器没有可用 JTAG/SSD 实物证据，不能完成 UART 菜单和真实介质写入验证；
- NoPHAE Stub 只模拟寄存器完成，不模拟 PCIe、NVMe 队列、SSD 延迟和掉电持久化；
- 当前 NoPHAE 高层 DMA 寄存器只有 32 bit DDR Offset 和 32 bit SLBA；
- 软件大量轮询无 Timeout，硬件异常时仍可能停住；
- 当前 ELF 的菜单提示含旧基址文本，菜单 7 应以本文地址图为准；
- 当前软件默认从 LBA0 开始，必须使用隔离测试盘并先设置安全起始 LBA；
- 真 RTL 到手后的内部模块审查清单不在本版展开，届时以实际交付层次和加密边界为准。

## 12. 交付文件

核心 RTL：

- `rtl/nvme_adc_vitis_compat_top.sv`
- `rtl/fdma_vitis_compat_regs.sv`
- `rtl/adc_capture_limit_controller.sv`
- `rtl/nophae_dma_backend.sv`
- `rtl/nvme_adc_pipeline_top.sv`
- `rtl/adc_ddr_segment_writer.sv`
- `rtl/segment_buffer_manager.sv`
- `rtl/nvme_request_scheduler.sv`

行为模型和测试：

- `rtl/stubs/nophae_ctrl_reg_stub.sv`
- `rtl/stubs/axi_ddr_mem_stub.sv`
- `sim/tb_nophae_dma_backend.sv`
- `sim/tb_nvme_adc_vitis_compat.sv`
- `scripts/run_vivado_regression.ps1`
- `scripts/collect_regression_summary.ps1`

Vitis 保持项和工具：

- `vitis_classic\nvme\Debug\nvme.elf`
- `vitis_classic\run_existing_elf.tcl`
- `vitis_classic\verify_existing_artifacts.ps1`
- `vitis_classic\annotate_core_sources.py`
- `vitis_classic\nvme\source_annotation_manifest.json`
