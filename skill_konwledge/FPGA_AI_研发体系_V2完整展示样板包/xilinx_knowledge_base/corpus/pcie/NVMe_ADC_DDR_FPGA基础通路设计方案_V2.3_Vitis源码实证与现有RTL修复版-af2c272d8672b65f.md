# NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版.docx`
- SHA-256: `af2c272d8672b65f585d909cc4e2584b3a5891828789c4fcca99cf66472fb5a1`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版.docx

内部设计与使用说明

NVMe–DDR–ADC FPGA
基础通路设计方案

Vitis源码实证｜现有RTL/SV修复｜NoPHAE软件ABI兼容｜无综合验证

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V2.3｜Vitis源码实证与现有RTL修复版｜2026-07-31 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 事实基线 | E:\NVME_PRO\vitis_classic\nvme\src、现有ELF/bit/XSA及XSim证据 |

| 本版动作 | 不重建Vitis软件；修改现有RTL/SV、兼容寄存器、测试和相关文档 |

| 验证边界 | 只做静态检查、RTL编译和行为仿真；不运行综合，不宣称真实SSD通过 |


| V2.3核心结论 当前XSA没有0x90000000外设，而现有ELF固定访问该地址。V2.3已按软件ABI补齐FDMA兼容寄存器，并把调度器请求转换为NoPHAE 0x10000000寄存器序列。现有Vitis工程保持不重建；只有兼容RTL并入实际Vivado工程并产生新硬件后，FDMA菜单才可在板上使用。 |


# 第一部分：详细设计、源码证据和RTL修复

更新日期：2026-07-31 适用目录：E:\NVME_PRO\vitis_classic、E:\NVME_PRO\nvme_adc_axi_pipeline 验证边界：只做源码静态核对、RTL 编译和 XSim 行为仿真，不运行综合，不重建 Vitis 软件，不声称板卡、PCIe、DDR 或 SSD 已实测通过。

# 1. 当前结论

这次取得的 Vitis 工程把此前不确定的 NoPHAE 软件契约变成了可核对的源码事实。现有软件不是待重建样例，而是已经生成 ELF、bitstream 和 XSA 的工程。当前工作的正确方向是：

保留现有 Vitis 软件的寄存器地址、队列创建和轮询顺序；

根据软件实际访问补齐当前自研 RTL 中缺失的 0x90000000 FDMA 兼容寄存器；

把自研调度器的抽象请求转换成 NoPHAE 0x10000000 控制寄存器序列；

修正 ADC、CDC、DDR 分段、完成关联和错误冻结中的现有问题；

用行为 Stub 证明软件 ABI、地址换算、长度单位及 Payload/Flush/Commit/Flush 顺序；

等真实 NoPHAE RTL/SV 和完整 Vivado 工程到手后，只做实例接线、参数复核和板级验证，不提前猜测加密 IP 内部实现。

本轮没有改变 Vitis 程序的非注释 C token，也没有重新生成 nvme.elf。软件源码只增加中文语义注释；RTL 修改位于 nvme_adc_axi_pipeline。

# 2. 证据和版本基线

## 2.1 已有制品

| 制品 | 路径 | SHA256 | 结论 |

| MicroBlaze ELF | vitis_classic\nvme\Debug\nvme.elf | A75ADA0EF77714EC6C14E4D90028690D47512BC86432EE24591BC4B1D2248BFA | 303,488 Byte，ELF32 little-endian，e_machine=0x00BD，即 MicroBlaze |

| 已有 bitstream | vitis_classic\nvme\_ide\bitstream\design_1_wrapper.bit | 5CD336000563775E97C85C871C0B5C43E62AC3AB0998919DFF3DDE0E9556E0FA | 历史 Vitis Launch 使用的器件配置文件 |

| 硬件平台 XSA | vitis_classic\wrapper1\hw\design_1_wrapper.xsa | C0807F333FB7429BC3733B2D4BD6B2125E3D283133D04DB98FD976104FEAAD5E | Vivado 2024.2、XCKU040 硬件导出 |


静态复核命令：

& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1

该脚本只读检查 SHA256、ELF 类型、XSA/HWH 地址事实和源码注释清单，不连接板卡、不构建软件。

## 2.2 Vitis 源码注释等价性

注释范围：

vitis_classic\nvme\src\func.c

vitis_classic\nvme\src\func.h

vitis_classic\nvme\src\helloworld.c

vitis_classic\nvme\src\type_define.h

规则：

重要语句的中文说明写在同一源码行，源码后固定四个空格再写 //；

函数或连续代码段的概括可以独立成段；

Xil_Out32、寄存器读取、轮询、单位换算、危险操作和每个 case/default 必须有业务语义；

不使用原行号标记，不保留“结束作用域”一类无语义注释；

type_define.h 的寄存器宏只说明业务含义，不复述宏名、宏值或“地址表达式为……”；

每个文件的重要语句覆盖率必须大于 50%；

注释前后的非注释 C token 指纹必须相同。

当前校验结果：

| 文件 | 已注释重要语句/重要语句 | 覆盖率 | case/default |

| func.c | 408/505 | 80.79% | 20/20 |

| func.h | 29/30 | 96.67% | 0/0 |

| helloworld.c | 239/400 | 59.75% | 26/26 |

| type_define.h | 82/84 | 97.62% | 0/0 |


清单位于 vitis_classic\nvme\source_annotation_manifest.json。重新生成或验证时使用：

& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  E:\NVME_PRO\vitis_classic\annotate_core_sources.py --restyle

& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' `
  E:\NVME_PRO\vitis_classic\annotate_core_sources.py --verify

# 3. XSA 给出的真实硬件边界

design_1.hwh 可以确认以下事实：

| 项目 | 当前 XSA 实例值 |

| 器件 | xcku040-ffva1156-2-i |

| 工具 | Vivado 2024.2 |

| NoPHAE 实例 | nophae_top_0 |

| NoPHAE VLNV | xilinx.com:user:nophae_top:2.0 |

| NoPHAE s_axi_ctrl | AXI4-Lite，32 bit 数据，40 bit 地址，125 MHz |

| NoPHAE 控制地址 | 0x10000000，4 KiB |

| NoPHAE m_axi | AXI4-Full，256 bit 数据，32 bit 地址，10 bit ID，125 MHz |

| NoPHAE最大 Burst | 256 beat |

| NoPHAE Outstanding | 2 |

| MicroBlaze DDR 窗口 | 0x80000000～0xFFFFFFFF，2 GiB |

| MIG S_AXI | 512 bit 数据、32 bit 地址、ID width 1、RD_PRI_REG |

| UART | 0x40600000，软件配置为 115200 bit/s |


当前 XSA 中的控制连接是：

MicroBlaze
  └─ SmartConnect_1
       ├─ NoPHAE s_axi_ctrl @ 0x10000000
       └─ MIG DDR @ 0x80000000..0xFFFFFFFF

NoPHAE m_axi
  └─ SmartConnect_0
       └─ MIG DDR

XSA/HWH 中没有 0x90000000 外设。软件却固定访问该地址，因此当前导出的 bitstream 与软件 FDMA 菜单之间存在明确缺口。新 RTL 已实现这个 ABI，但尚未进入供应商原 bitstream；没有完整 Vivado 工程时不能伪造“已并入当前 bit”结论。

# 4. Vitis 源码形成的寄存器契约

## 4.1 NoPHAE 0x10000000

软件实际使用的主要偏移如下：

| 偏移 | 名称/作用 | 软件行为 |

| 0x00 | PCIe 初始化启动 | 写 1 后轮询状态 |

| 0x04 | NVMe 初始化启动 | 写 1 后轮询状态 |

| 0x08 | Debug/命令路径锁 | 选择调试、原生命令或指定 CID 路径 |

| 0x0C | 调试请求操作/完成 | PCIe Memory/Configuration 读写 |

| 0x10 | 调试请求地址 | 写入目标地址 |

| 0x14 | 调试写数据 | 写入 32 bit 数据 |

| 0x18 | 调试读数据 | 读取 32 bit 数据 |

| 0x1C | NoPHAE 状态 | 初始化轮询 |

| 0x44 | 高层 DMA 类型/启动 | 写方向为 1，读方向为 0 |

| 0x48 | 高层 DMA 长度 | 单位为 512 B LBA 数 |

| 0x4C | DMA 源 | Write 时为 DDR Offset，Read 时为 SLBA |

| 0x50 | DMA 目的 | Write 时为 SLBA，Read 时为 DDR Offset |

| 0x54 | DMA Ready | 等于 1 后才能提交 |

| 0x60 | 原生命令编码 | Opcode、Queue/NSID 组合 |

| 0x6C、0x74 | PRP1/PRP2 低 32 bit | 当前软件按 DDR 相对地址使用 |

| 0x78～0x84 | CDW10～13 | 原生命令参数 |

| 0x8C | CMD_WR | 写 1 提交原生命令 |

| 0x90、0x94 | I/O Queue 创建 | 软件创建队列后再启动 FDMA |

| 0xA8 | SQ Full | 队列流控 |

| 0xAC | CQ 无错误 | 错误入口 |

| 0xC0 | 完成命令计数 | Flush 通过计数变化判断完成 |

| 0xC8 | 高层 DMA Done | 软件永久轮询到 1 |

| 0xCC | MDTZ | 控制内部每命令传输规模 |

| 0xD8 | MPS | 软件按 4 KiB 假设配置 |

| 0xDC | 版本文本 | 菜单启动时输出 |

| 0x144 以后 | 成功 CQ 信息 | 指定 CID 和调试用途 |


## 4.2 软件固定使用的 FDMA 0x90000000

原 ELF 访问的兼容区为 0x90000000～0x9000003C：

| 偏移 | 软件含义 |

| 0x00 | 总任务启动/停止 |

| 0x04 | Burst 长度，单位为 32 bit beat |

| 0x08、0x0C | 写/读耗时计数 |

| 0x10 | Pattern 起点 |

| 0x14 | 环形内存大小 |

| 0x18 | FDMA 数据位宽 |

| 0x1C、0x20 | 总字节数低/高 32 bit |

| 0x24 | 本地数据产生/采集完成 |

| 0x28、0x2C | 总耗时低/高 32 bit |

| 0x30 | SSD 起始 LBA |

| 0x34 | FIFO 满状态 |

| 0x38 | NVMe 取数/任务完成 |

| 0x3C | 起始 LBA 使能 |


# 5. V2.3 实现架构

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

集成顶层为：

rtl/nvme_adc_vitis_compat_top.sv

它提供三个需要接入真实 Block Design 的总线边界：

ADC Writer 的 DDR AXI4 写主口；

MicroBlaze 到 0x90000000 的 AXI4-Lite Slave；

后端到 NoPHAE s_axi_ctrl 的 AXI4-Lite Master。

# 6. 各 RTL 模块的当前修复

## 6.1 nvme_adc_pipeline_top.sv

默认 DDR 地址宽度改为 XSA 一致的 32 bit；

默认采集区改为 0xC0000000，避开软件在 0x80000000 附近使用的队列和测试缓冲；

增加每任务 session_start/session_base_slba；

CDC FIFO 载荷由 263 bit 改为 329 bit，把 EOC、有效字节数、通道模式、Capture ID 和数据放入同一表项；

删除模式/Capture ID 分离跨域造成的首字上下文竞态；

把 ADC 完整性、数据格式、DDR、Segment 和调度器错误统一汇入致命状态；

把 FIFO Full/Programmable Full 同步到 sys_clk 后供软件状态寄存器读取。

329 bit 位域：

[328]     end_of_capture
[327:322] valid_bytes
[321]     two_channel
[320]     single_channel_select
[319:256] capture_id
[255:0]   payload

## 6.2 adc_capture_limit_controller.sv

把软件写入的 64 bit 目标字节数换算为采样时刻数量；

双通道按 4 Byte/采样时刻，单通道按 2 Byte/采样时刻；

启动、停止、完成使用 Toggle CDC；

多位配置在同步后再多等一拍锁存；

自动停止采用组合阈值，使 Packer 在达到目标后的下一个采样沿先看到 STOP，避免多采 1 点；

START 尚未真正进入 Packer 时收到 STOP，返回明确取消完成，避免旧软件永久轮询。

## 6.3 adc_ddr_segment_writer.sv

检查中间字必须为 32 Byte、尾字为 0～32 Byte；

检查有效字节数符合单/双通道样本粒度；

检查 Burst、FIFO 容量和 4 KiB 边界条件；

Commit 信息携带错误状态，禁止把格式错误伪装成正常采集；

保持 256 bit Writer，不因 MIG 为 512 bit 重写数据格式；位宽转换由 SmartConnect 处理。

## 6.4 segment_buffer_manager.sv

完成 Tag 未命中任何 INFLIGHT Segment 时置状态错误；

Fill 错误进入 ERROR_HOLD，不再错误释放为 FREE；

保留 {generation, segment_id}，防止迟到 Completion 释放新一代数据。

## 6.5 nvme_request_scheduler.sv

每任务装载软件给定的 Raw LBA 起点；

明确 ST_HALT，Fatal 后停止所有新请求；

外部完整性错误、Link Down、ECQE 和超时具有高于正常 Completion 的优先级；

修复 Completion 与 Timeout 同拍的边界竞态；

检查 Payload、Commit 地址和长度的 4 KiB 对齐；

只有 Payload Write → Flush1 → Commit Write → Flush2 全部成功才产生 capture_done。

## 6.6 nophae_dma_backend.sv

该模块不是猜测 NoPHAE 内部 RTL，而是严格复现当前 Vitis 源码的外部寄存器行为。

Write：

poll 0x54 == 1
0x4C = physical_ddr_addr - 0x80000000
0x50 = slba
0x48 = byte_len / 512
0x44 = 1
poll 0xC8 == 1

Read：

poll 0x54 == 1
0x4C = slba
0x50 = physical_ddr_addr - 0x80000000
0x48 = byte_len / 512
0x44 = 0
poll 0xC8 == 1

Flush：

read 0xC0
0x08 = 2
写入cmd_code/PRP/CDW
0x8C = 1
0x08 = 0
poll 0xC0，直到计数变化

模块一次只保存一个项目 Tag，NoPHAE 完成后再把该 Tag 回送调度器，符合现有软件“一条高层 DMA 在途”的用法。

## 6.7 fdma_vitis_compat_regs.sv

该模块实现原 ELF 的 0x90000000 ABI，并在 0x40 以后增加不破坏旧软件的诊断寄存器：

| 偏移 | 扩展功能 |

| 0x40 | bit0：双通道；bit1：单通道时选择 CH1 |

| 0x44、0x48 | Capture ID 计数种子低/高 32 bit |

| 0x4C | 任务状态位 |

| 0x50、0x54 | 已接受采样时刻数低/高 32 bit |

| 0x58、0x5C | 丢失采样时刻数低/高 32 bit |

| 0x60 | FDMA 层最后错误 |

| 0x64 | NoPHAE 后端最后状态 |


0x4C 状态位：

| 位 | 含义 |

| 0 | transfer_active |

| 1 | 本地采集完成 |

| 2 | NVMe 全任务完成 |

| 3 | 本地阶段完成 |

| 4 | ADC FIFO Full |

| 5 | ADC FIFO Programmable Full |

| 6 | Pipeline Fatal |

| 7 | last_error != 0 |


默认 MIN_START_SLBA=1,048,576，即保护前 512 MiB。现有软件上电写入 LBA0；未先改为安全 LBA 时，START 返回错误终态，不向 NoPHAE 提交命令。

# 7. 地址、长度和盘上布局

必须区分三个地址域：

| 地址域 | 示例 | 使用者 |

| MicroBlaze/AXI 绝对地址 | 0xC0000000 | ADC Writer、MIG、软件直接 AXI 访问 |

| NoPHAE DDR Offset | 0x40000000 | dma_srcaddr/dma_dstaddr 中的 DDR 一侧 |

| SSD LBA | 0x00100000 | dma_srcaddr/dma_dstaddr 中的 SSD 一侧 |


换算公式：

nophae_ddr_offset = physical_ddr_addr - 0x80000000
dma_lba_count     = byte_len / 512
next_slba         = current_slba + dma_lba_count

项目仍要求 Payload 和 Commit DMA 地址、长度按 4 KiB 对齐。ADC 尾段不足 4 KiB 时补零，真实 Payload 字节数和补齐后的 DMA 字节数分别记录。

默认地址建议：

MicroBlaze DDR窗口：0x80000000 .. 0xFFFFFFFF
软件/队列/调试区： 保留0x80000000附近
ADC Segment区：    从0xC0000000开始
Commit页：         Segment区之后的独立4 KiB页

盘上顺序：

session_base_slba
  ├─ Payload Segment 0
  ├─ Payload Segment 1
  ├─ ...
  └─ Commit页

Commit 页只有在所有 Payload 和第一次 Flush 完成后才写入，并由第二次 Flush 建立持久化顺序。

# 8. 错误码和恢复策略

FDMA 层：

| 状态 | 含义 |

| D001 | 任务活动期间再次 START |

| D002 | 总字节数为 0 |

| D003 | 总字节数不符合当前通道样本粒度 |

| D004 | 起始 LBA 落入保护区 |

| D005 | Pipeline 已有 Fatal，不能开始新任务 |

| D006 | 尚未开始采集时被软件取消 |

| D100 | Pipeline Fatal |


NoPHAE 后端：

| 状态 | 含义 |

| E001 | 不支持的 Opcode |

| E002 | 长度为 0 或不是 LBA 整数倍 |

| E003 | DDR 绝对地址越界或 Offset 超过 32 bit |

| E004 | SLBA 超过当前 32 bit 软件寄存器能力 |

| E005 | AXI4-Lite 返回错误响应 |

| E006 | 单次 AXI4-Lite 事务超时 |

| E007 | 整笔 NoPHAE 命令超时 |

| E008 | 命令在途时 Backend 被禁止 |


致命错误策略：

停止新Capture
→ 停止新NVMe请求
→ INFLIGHT/ERROR_HOLD不释放
→ 软件读取0x60/0x64和状态位
→ 人工复位或按供应商流程恢复

旧软件没有 Timeout，因此 FDMA 在启动校验失败或未启动采集即取消时会同时置两个 Done，使旧轮询能够退出；是否成功必须读取扩展错误寄存器，不能只看 Done。

# 9. 无综合验证

## 9.1 五项行为回归

| Testbench | 覆盖内容 |

| tb_adc_channel_packer | 双通道、单 CH0、单 CH1、边界字节数、符号扩展、配置锁存 |

| tb_nvme_adc_pipeline | 329 bit CDC、随机 AXI 背压、DDR 内容、Segment、Flush、Commit |

| tb_nvme_scheduler_errors | 错误 Completion、错误 Tag、Timeout、Link Down、ECQE、Flush 失败 |

| tb_nophae_dma_backend | NoPHAE 寄存器顺序、Write/Read 地址换算、长度、AXI 错误和超时 |

| tb_nvme_adc_vitis_compat | 0x90000000 ABI 到 ADC/DDR/NoPHAE 的完整闭环、LBA0 保护和取消路径 |


执行：

Set-Location E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1

脚本固定调用：

D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat

只启动 Behavioral Simulation，不调用 synth_design、launch_runs synth_1 或实现流程。

2026-07-31 11:55～12:01 的完整回归结果：

tb_adc_channel_packer       PASS
tb_nvme_adc_pipeline        PASS
tb_nvme_scheduler_errors    PASS
tb_nophae_dma_backend       PASS
tb_nvme_adc_vitis_compat    PASS

5 PASS / 0 FAIL / FirstFatal=null

机器可读汇总位于 build\regression\summary.json。五项均重新经过 Vivado 2020.2 编译、展开和 XSim 运行，不是沿用旧日志。

## 9.2 Vitis ABI 完整闭环的已验证数据

集成仿真使用 64 Byte 双通道输入，结果为：

accepted samples = 16
dropped samples  = 0
NoPHAE DMA        = 2（Payload、Commit）
NoPHAE Flush      = 2
scheduler request = 4

同时验证：

0x80010000 物理地址转换为 0x00010000 NoPHAE DDR Offset；

4 KiB DMA 转换为 8 个 512 B LBA；

Commit 地址和 SLBA 紧跟 Payload；

每个 ADC 样本的 DDR 小端字节序正确；

Commit Magic 正确；

LBA0 不进入后端；

START 后在 Packer Ready 前 STOP 能形成 D006 终态；

正常路径无 Fatal、无丢样、无 Backend 错误。

# 10. 并入真实现有工程时的操作

这一步是修改硬件工程，不是重建 Vitis 软件：

在实际 Vivado Block Design 中加入 nvme_adc_vitis_compat_top.sv 及其依赖 RTL；

把 MicroBlaze 的 AXI 地址空间新增 0x90000000、4 KiB，从 SmartConnect 接到 s_axi_fdma_*；

把 m_axi_nophae_* 接到 NoPHAE s_axi_ctrl，地址仍为 0x10000000；

把 ADC Writer 的 m_axi_ddr_* 接到现有 MIG SmartConnect；

确认 ADC Segment 区和 Commit 页不与 SQ/CQ、PRP、软件测试区重叠；

连接 ddr_init_done、nvme_init_done、pcie_link_up 和 ECQE；

先跑 Behavioral Simulation，再做板级 DDR/NoPHAE 联调；

继续使用现有 nvme.elf，除非以后明确要修复软件功能缺陷。

本轮不综合，因此没有生成新 bitstream，也没有改写当前 XSA。

# 11. 已知限制

当前没有真实 NoPHAE RTL/SV、完整 Vivado BD、MIG/XDC 和板卡连接；

当前机器没有可用 JTAG/SSD 实物证据，不能完成 UART 菜单和真实介质写入验证；

NoPHAE Stub 只模拟寄存器完成，不模拟 PCIe、NVMe 队列、SSD 延迟和掉电持久化；

当前 NoPHAE 高层 DMA 寄存器只有 32 bit DDR Offset 和 32 bit SLBA；

软件大量轮询无 Timeout，硬件异常时仍可能停住；

当前 ELF 的菜单提示含旧基址文本，菜单 7 应以本文地址图为准；

当前软件默认从 LBA0 开始，必须使用隔离测试盘并先设置安全起始 LBA；

真 RTL 到手后的内部模块审查清单不在本版展开，届时以实际交付层次和加密边界为准。

# 12. 交付文件

核心 RTL：

rtl/nvme_adc_vitis_compat_top.sv

rtl/fdma_vitis_compat_regs.sv

rtl/adc_capture_limit_controller.sv

rtl/nophae_dma_backend.sv

rtl/nvme_adc_pipeline_top.sv

rtl/adc_ddr_segment_writer.sv

rtl/segment_buffer_manager.sv

rtl/nvme_request_scheduler.sv

行为模型和测试：

rtl/stubs/nophae_ctrl_reg_stub.sv

rtl/stubs/axi_ddr_mem_stub.sv

sim/tb_nophae_dma_backend.sv

sim/tb_nvme_adc_vitis_compat.sv

scripts/run_vivado_regression.ps1

scripts/collect_regression_summary.ps1

Vitis 保持项和工具：

vitis_classic\nvme\Debug\nvme.elf

vitis_classic\run_existing_elf.tcl

vitis_classic\verify_existing_artifacts.ps1

vitis_classic\annotate_core_sources.py

vitis_classic\nvme\source_annotation_manifest.json

# 第二部分：现有Vitis软件完整使用与验证指导

更新日期：2026-07-31 软件工程：E:\NVME_PRO\vitis_classic 原则：使用现有 bitstream、XSA 和 ELF，不重新创建工程，不重新编译 Vitis 软件。源码中文注释不会改变当前 ELF。

# 1. 使用前先看结论

当前软件是 MicroBlaze 裸机 UART 菜单程序。它负责：

PCIe 和 NVMe 初始化；

Identify Controller/Namespace；

I/O Queue 创建和删除；

NoPHAE 高层 DMA；

原生 NVMe 命令；

日志页、Feature、IOPS、顺序读写和数据校验；

固定地址 0x90000000 的 FDMA 控制。

当前已有 XSA/bitstream 中没有 0x90000000 外设。也就是说：

NoPHAE 0x10000000 相关菜单属于已有硬件基线；

菜单 13～17 和 FDMA 相关功能，只有把 V2.3 兼容 RTL 并入实际 Vivado 工程并生成新硬件后才能使用；

V2.3 RTL 不要求重建 Vitis 软件，寄存器 ABI 就是为当前 ELF 保持兼容；

当前没有板卡/JTAG/SSD 连接，本轮只完成了制品静态检查和 XSim 行为验证。

所有写盘测试都必须使用可完全清空的隔离测试 SSD。不要连接保存有项目资料、系统或个人数据的 SSD。

# 2. 当前已有文件

| 文件 | 路径 | SHA256 |

| ELF | E:\NVME_PRO\vitis_classic\nvme\Debug\nvme.elf | A75ADA0EF77714EC6C14E4D90028690D47512BC86432EE24591BC4B1D2248BFA |

| bitstream | E:\NVME_PRO\vitis_classic\nvme\_ide\bitstream\design_1_wrapper.bit | 5CD336000563775E97C85C871C0B5C43E62AC3AB0998919DFF3DDE0E9556E0FA |

| XSA | E:\NVME_PRO\vitis_classic\wrapper1\hw\design_1_wrapper.xsa | C0807F333FB7429BC3733B2D4BD6B2125E3D283133D04DB98FD976104FEAAD5E |

| Vitis Launch | E:\NVME_PRO\vitis_classic\nvme\_ide\launch\Debugger_nvme-Default.launch | 现有 Standalone Debug 配置 |

| 免重建下载脚本 | E:\NVME_PRO\vitis_classic\run_existing_elf.tcl | 使用现有 bit/ELF |


运行前静态核验：

& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1

看到以下结尾才表示文件与本指南一致：

ARTIFACT_VERIFY_PASS: existing ELF/bit/XSA/source contract

# 3. 硬件和工具准备

## 3.1 必需硬件

对应 XCKU040 板卡；

原工程使用的 Digilent JTAG 线缆；

独立 UART；

只用于破坏性测试的 NVMe SSD；

符合板卡电源和 PCIe 参考时钟要求的连接。

历史 Launch 记录中的线缆为：

Digilent JTAG-HS1 210512180081

该序列号只是历史配置。更换线缆后应在 Vitis Target Connection 中选择实际线缆，不能照抄旧序列号。

## 3.2 工具

原工程 Launch 版本为 Vitis 2024.2；

hw_server 和 XSCT 应来自与该工程兼容的 Vitis 安装；

串口参数为 115200 8N1，关闭硬件和软件流控；

本轮不需要执行 Build Project。

# 4. 启动方法

## 4.1 方法 A：Vitis Classic 已有 Launch

打开现有 E:\NVME_PRO\vitis_classic 工作区；

刷新工程，确认 nvme、wrapper1 和 nvme_system 可见；

打开 Run → Debug Configurations；

选择 Debugger_nvme-Default；

确认：

Application 为 Debug/nvme.elf；

bitstream 为 _ide/bitstream/design_1_wrapper.bit；

Processor 为 microblaze_0；

Program FPGA 打开；

Reset System 打开；

在 Target Connection 中选择当前实际 JTAG；

不点击 Build，直接 Debug/Run；

程序停在 main 时继续运行；

打开 UART，等待版本信息和菜单。

## 4.2 方法 B：XSCT 直接下载已有制品

先启动 hw_server，再执行：

& '<Vitis 2024.2安装目录>\bin\xsct.bat' `
  E:\NVME_PRO\vitis_classic\run_existing_elf.tcl

多线缆环境显式给出线缆名：

& '<Vitis 2024.2安装目录>\bin\xsct.bat' `
  E:\NVME_PRO\vitis_classic\run_existing_elf.tcl `
  'Digilent JTAG-HS1 210512180081'

该脚本执行：

connect
→ 选择FPGA
→ 下载已有bitstream
→ 载入已有XSA寄存器描述
→ 系统复位
→ 下载已有nvme.elf
→ 运行MicroBlaze

它不调用编译器，也不生成新的 ELF。

# 5. 正常启动时应看到什么

main() 的实际顺序是：

初始化平台；

关闭数据缓存；

调用 initial(1) 启动 PCIe/NVMe；

调用 identify()；

从版本寄存器输出 NoPHAE 版本文本；

写 FDMA 默认参数：

Burst Length=0x20000；

Pattern Start=0；

Memory Size=0x40000000；

Start LBA=0；

SLBA Enable=1；

进入永久 UART 菜单。

如果 PCIe/NVMe 未完成，initial() 和 identify() 中的无超时轮询会让程序停住。此时不要反复输入菜单，应先检查：

PCIe Link；

SSD 供电和插接；

NoPHAE 初始化状态；

UART 是否接对；

bitstream/ELF 是否为本指南列出的版本。

# 6. 菜单说明

| 菜单 | 功能 | 是否写介质 | 使用建议 |

| 1 | Identify Controller/Namespace | 否 | 首个只读检查；会刷新软件记录的容量 |

| 2 | 指定 GiB 的高层 DMA Read/Write | 取决于方向 | w 会覆盖 Raw LBA；r 也要求地址和队列正确 |

| 3 | 开关 Volatile Write Cache | 不直接写用户数据 | 修改控制器 Feature；完成检查不充分 |

| 4 | PCIe Memory Read/Write | 写分支危险 | 可改 Endpoint BAR0；只给熟悉寄存器的人使用 |

| 5 | Error Information / SMART Log | 否 | 推荐只读检查 |

| 6 | Get Volatile Write Cache Feature | 否 | 结果提示要求查看 CQ |

| 7 | 任意 AXI 地址 Read/Write | 写分支非常危险 | 菜单提示的旧基址不可信，以本指南地址图为准 |

| 8 | PCIe Configuration Read/Write | 写分支非常危险 | 错写可能导致链路或设备失效 |

| 9 | NVM Flush | 不写 Payload | 以全局命令计数变化判断完成 |

| 10 | 从任意地址输出 NUL 结尾文本 | 否 | 地址无效或无 NUL 时可越界读取 |

| 11 | 固定容量梯度顺序测速 | 是 | 大量覆盖写，只能用于空测试盘 |

| 12 | 读取 FDMA 计数器估算带宽 | 否 | 计时寄存器为 0 时会除零 |

| 13 | FDMA/ADC→DDR→NVMe 完整任务 | 是 | 需要 V2.3 硬件和有效 ADC 输入 |

| 14 | 停止 FDMA 任务 | 可能产生尾段 | V2.3 RTL 会做干净停止或返回取消错误 |

| 15 | 设置 FDMA Burst Length | 否 | 保持软件/硬件约定单位 |

| 16 | 设置 Pattern Start | 否 | V2.3 ADC 采集路径不把它当 ADC 数据源 |

| 17 | 设置 FDMA Memory Size | 否 | 兼容保留寄存器 |

| 18 | 命令/DMA/Fetch 数据校验 | 是 | 三个分支均可能覆盖 LBA0 |

| 20 | 指定 CID 的 4 KiB 命令 | 写分支是 | 固定 LBA0；非法方向字符会使 rw 未初始化 |

| 21 | Q1D2、Q8D8 IOPS BIST | 是 | 写/读 BIST，默认破坏性 |

| 22 | 逐 GiB 记录速度 | 写分支是 | 输入上限未检查，固定数组只有 4096 项 |

| 23 | 多种 MDTZ 测试矩阵 | 写分支是 | 数据量很大，只能用于专用测试盘 |


菜单 19 未实现。

# 7. 地址图

| 地址 | 含义 | 当前事实 |

| 0x10000000 | NoPHAE AXI4-Lite 控制 | XSA 已存在，4 KiB |

| 0x40600000 | AXI UARTLite | XSA 已存在 |

| 0x80000000～0xFFFFFFFF | MicroBlaze DDR | XSA 已存在，2 GiB |

| 0x90000000 | FDMA/Vitis 兼容寄存器 | 原 ELF 固定访问；当前原 XSA 不存在，V2.3 RTL 已补 |

| 0xC0000000 起 | V2.3 建议 ADC Segment 区 | 新硬件集成时分配 |


菜单 7 输出中的 0xA0000000 NoPHAE 基址和 0x5_00000000 DDR 基址是旧文本，与当前源码/XSA 不一致。

# 8. 最安全的首次上板流程

## 8.1 只读基线

连接专用测试 SSD；

下载现有 bit/ELF；

保存完整 UART 启动日志；

执行菜单 1，记录：

NVMe 版本；

Controller/Namespace Identify；

Namespace 容量；

执行菜单 5、LID 2，记录温度和 SMART；

执行菜单 6、SEL 0，读取当前写缓存 Feature；

用菜单 7 只读：

0x100000DC：NoPHAE 版本区域；

0x1000001C：NoPHAE 状态；

不执行任何写盘菜单。

## 8.2 V2.3 硬件是否真正并入

用菜单 7 读取：

0x90000018

V2.3 返回：

0x00000100

即 256 bit。再读取：

0x9000004C
0x90000060
0x90000064

空闲、无错误时应为 0。若读访问无响应、返回总线错误或值不可信，说明当前 bitstream 没有并入 V2.3 FDMA 兼容块，禁止执行菜单 13。

# 9. 安全配置菜单 13

## 9.1 为什么必须先改 LBA

软件上电执行：

Xil_Out32(START_LBA_ADDR, 0x0);
Xil_Out32(SLBA_ENABLE_ADDR, 0x1);

因此默认从 LBA0 写入，会破坏分区表、文件系统或已有 Raw 数据。V2.3 RTL 默认保护前 1,048,576 个 512 B LBA，即前 512 MiB；LBA0 START 会返回 D004，不会向 NoPHAE 提交。

保护区只避免最前面的误写，不代表后续区域安全。仍必须使用隔离测试 SSD，并根据 SSD 容量计算任务尾地址。

## 9.2 通过菜单 7 设置安全 LBA

以下输入均为十六进制。示例把起点设为 0x00100000：

菜单: 7
操作: w
地址: 90000030
数据: 00100000

确认 SLBA Enable：

菜单: 7
操作: w
地址: 9000003c
数据: 00000001

读取回查：

菜单: 7
操作: r
地址: 90000030

菜单: 7
操作: r
地址: 9000003c

## 9.3 选择 ADC 模式

V2.3 扩展寄存器 0x90000040：

| 值 | 模式 |

| 0x1 | 双通道，4 Byte/采样时刻 |

| 0x0 | 单通道 CH0，2 Byte/采样时刻 |

| 0x2 | 单通道 CH1，2 Byte/采样时刻 |


写双通道：

菜单: 7
操作: w
地址: 90000040
数据: 00000001

默认复位值已经是双通道。

## 9.4 容量边界计算

软件菜单 13 输入十进制 GiB，并执行：

transfer_bytes = input_GiB << 30

512 B LBA 数：

payload_lbas = transfer_bytes / 512

还要为 4 KiB Commit 页保留 8 个 LBA：

last_exclusive_lba = start_lba + payload_lbas + 8

必须满足：

last_exclusive_lba <= Identify得到的Namespace容量

示例：1 GiB 任务、起点 0x00100000：

payload_lbas       = 0x00200000
commit_lbas        = 0x00000008
last_exclusive_lba = 0x00300008

## 9.5 启动

确认 ADC 数据源有效且 DDR/PCIe/NVMe 已初始化后：

菜单: 13
数据大小: 1

软件会：

create_queues(2, 8)
→ 写0x9000001C/20总字节数
→ 写0x90000000=1
→ 等0x90000024=1
→ 等0x90000038=1
→ delete_queues(2)

如果 ADC 没有送 adc_valid，自动定长采集无法达到目标，菜单会一直等待本地完成。

# 10. 任务完成后必须检查

不能只看菜单返回。使用菜单 7 读取：

| 地址 | 正常值/判断 |

| 0x90000024 | 1，本地采集完成 |

| 0x90000038 | 1，Payload/Flush/Commit/Flush 全部完成 |

| 0x9000004C | 低 8 bit 正常终态通常为 0x0E |

| 0x90000050/54 | 已接受采样时刻数 |

| 0x90000058/5C | 丢样数，应为 0 |

| 0x90000060 | FDMA 错误，应为 0 |

| 0x90000064 | NoPHAE Backend 错误，应为 0 |


样本数期望：

双通道 accepted_sample_times = transfer_bytes / 4
单通道 accepted_sample_times = transfer_bytes / 2

只要 0x60 或 0x64 非 0，就不能把两个 Done 解释为成功。启动参数被拒绝时，硬件也会置 Done，目的是让旧软件的无超时轮询退出。

# 11. 停止任务

菜单 14 写 0x90000000=0。

V2.3 行为：

已经采集时：停止接收新样本，发送尾段 EOC，完成已接收数据的 DDR/NVMe/Commit/Flush；

尚未真正开始采集时：返回取消终态 D006，两个 Done 同时置位；

不会把未提交的数据静默当作正常完整 Capture。

停止后读取 0x90000060。D006 表示任务在 Packer 启动前被取消，不是 SSD 写入成功。

# 12. 错误码

## 12.1 0x90000060

| 低 16 bit | 含义 | 处理 |

| D001 | Active 期间再次 START | 等当前任务结束 |

| D002 | 总字节数为 0 | 重新设置 Size |

| D003 | Size 不符合通道样本粒度 | 双通道按 4 Byte、单通道按 2 Byte 对齐 |

| D004 | LBA 落入保护区 | 选择安全 LBA，并重新核算容量 |

| D005 | Pipeline 已 Fatal | 系统复位，先查根因 |

| D006 | 开始采集前被取消 | 属于取消结果 |

| D100 | Pipeline Fatal | 查看状态、DDR、Link、ECQE 和 Backend |


## 12.2 0x90000064

| 低 16 bit | 含义 |

| E001 | Opcode 非法 |

| E002 | DMA 长度非法 |

| E003 | DDR 地址或窗口非法 |

| E004 | SLBA 超出 32 bit |

| E005 | NoPHAE AXI4-Lite 错误响应 |

| E006 | NoPHAE AXI4-Lite 单事务超时 |

| E007 | 整笔命令超时 |

| E008 | 命令在途时 Backend 被禁止 |


出现 Fatal 后不要自动重试同一 Buffer。保存 UART、ILA 和寄存器快照，再按供应商定义的复位/重新下载流程恢复。

# 13. 软件源码中的已知风险

这些问题已在源码行尾注释中标出，但本轮没有修改功能：

多处硬件轮询没有 Timeout；

菜单 7 打印的 NoPHAE/DDR 基址是旧值；

菜单 20 输入非法方向后仍可能使用未初始化的 rw；

多数速度和数据测试默认从 LBA0 开始；

容量回卷判断晚一拍，Namespace 边界附近可能越界；

full_transfer_data() 的速度数组只有 4096 项，Size 过大会越界，Size=0 会除零；

test_data_cmd() 文本说 16 MB，实际只校验 8 KiB；

test_data_dma() 实际覆盖 256 MiB；

Fetch 校验不处理不足 4 MiB 的尾部；

start_transfer() 不先清残留 Done，也没有错误/Timeout 分支；

cmd() 提交后不等待 Ready 或匹配 Completion；

cmd_alloc_cid() 创建两条队列但原路径只删除一条；

test_seq() 的长度单位是 512 B LBA 数，不是 Byte；

Trim 描述符使用 0x10000000 控制空间，地址明显可疑；

Identify 假设 512 B LBA 和 4 KiB MPS；

Capability 链遍历没有空指针、环路和最大次数保护；

Flush 只看全局命令计数变化，没有匹配该命令 CQE；

txt_rd() 一直读取到 NUL，没有最大长度；

部分 scanf 格式与变量类型不匹配，已有构建警告；

头文件保留旧式非原型声明。

在修复这些软件功能前，不应把该程序当作无人值守生产工具。

# 14. 没有板卡时怎样验证

## 14.1 Vitis 制品静态验证

& E:\NVME_PRO\vitis_classic\verify_existing_artifacts.ps1

验证：

ELF/bit/XSA 哈希；

ELF32 MicroBlaze 类型；

XSA 中 NoPHAE、DDR、UART 地址；

XSA 中确实没有 0x90000000；

四个核心源码的 token 等价、注释覆盖率和分支覆盖。

## 14.2 RTL/XSim 验证

Set-Location E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1

五项回归全部出现 TEST_PASS 后，查看：

E:\NVME_PRO\nvme_adc_axi_pipeline\build\regression\summary.json

2026-07-31 的本轮结果为 5 PASS / 0 FAIL / FirstFatal=null；五项日志更新时间 为 11:55～12:01，均由 Vivado 2020.2 重新编译和运行，且未执行综合。

其中 tb_nvme_adc_vitis_compat 是最接近当前软件使用方式的一项：

写0x90000000兼容寄存器
→ 自动采16个双通道样本
→ DDR写入
→ NoPHAE Payload DMA
→ Flush
→ Commit DMA
→ Flush
→ 软件Done/Status

它证明 RTL 和软件 ABI 的行为一致，不证明真实 SSD 已写入。

# 15. 现场证据记录模板

每次上板至少记录：

日期/操作者：
板卡与序列号：
JTAG与序列号：
SSD厂商/型号/容量/固件：
Vitis/Vivado版本：
bit SHA256：
ELF SHA256：
XSA SHA256：
UART启动日志：
PCIe/NVMe初始化结果：
Identify容量：
SMART温度：
起始LBA：
传输字节数：
通道模式：
accepted/dropped：
FDMA status/error：
Backend status：
Write/Flush/Commit/Flush结果：
读回CRC或逐字节比较：
最长停顿/FIFO最高水位：
异常与恢复过程：
结论等级：

结论等级必须区分：

| 等级 | 可写结论 |

| 静态 | 制品、源码和 XSA 契约核对通过 |

| XSim | RTL/软件 ABI 行为模型通过 |

| 板级基础 | bit/ELF 可下载，UART、PCIe/NVMe 初始化通过 |

| 数据闭环 | DDR→SSD→DDR 回读一致 |

| ADC 闭环 | ADC→DDR→SSD→DDR 数据一致和长稳通过 |


没有达到相应等级时，不使用“完整通路已跑通”的表述。

# 文档验证声明

| 结构检查范围 本文只进行DOCX ZIP、OOXML必需部件、核心属性、正文锚点、表格和内容规模检查。按照工作区要求未渲染PDF/PNG，因此不把结构检查写成页面视觉验收。 |
