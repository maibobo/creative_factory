# RTDS DDR4 集成运行关键点与问题记录

> 维护范围：本聊天中对远程机 `RTDS_test_DDR4_64bit` 的全部关键决策、执行结果、问题、处理办法和阶段结论。  
> 维护规则：每完成一个关键设计修改、验证步骤或问题定位后同步更新。  
> 最近更新：2026-08-20（编译、Elaborate、基本冒烟及文档/清单收尾完成）

## 1. 当前阶段结论

- 当前要求已收敛为：只在远程机新目录工作；本阶段不运行综合、实现、DRC、时序和 bitstream。
- 已完成基本冒烟、生产 TOP 的定向编译与 Elaborate、`DDR4_REAL` 后端结构编译与 Elaborate。
- 新工程已具备进入后续综合阶段的源文件、BD、MIG、Clock Converter、约束和两种构建模式基础。
- 由于用户明确要求暂不综合，当前不能声称“bitstream 已验证可生成”。能否最终生成 bitstream 仍需下一阶段运行综合、实现、约束检查和时序收敛后确认。
- 当前尚未连接目标板，未执行 DDR 校准、PCIe/Aurora 实板闭环和 ILA 观察，不记录或伪造硬件 PASS。

## 2. 工程范围与同板卡关系

- 远程新工程：`C:\project\RTDS\DDR\RTDS_test_DDR4_64bit`
- 生产基线：`E:\PCIE-CPU\RTDS_test-1ch`
- 远程旧工程参考：`C:\project\PCIE-CPU\RTDS_test`
- DDR golden：`C:\project\RTDS\DDR\axi_ddr4_min_2020_2`
- 远程 Vivado：`C:\Xilinx\Vivado\2020.2\bin\vivado.bat`
- 器件：`xcku040-ffva1156-2-i`

**同板卡说明：** PCIE-CPU 的 RTDS 工程和 `axi_ddr4_min_2020_2` DDR golden 工程均面向同一块 KU040 物理板卡。前者承担 PCIe/Aurora 业务数据通路，后者承担该板卡 DDR4 独立验证和参数/引脚参考。Golden 只读，未直接修改。

## 3. 需求与方案演变

1. 最初目标是将 DDR 工程接入 PCIE-CPU 工程，并新建独立目录。
2. 明确只在远程机操作，远程连接配置由 `agent.md` 提供。
3. DDR 参考对象最终固定为 `C:\project\RTDS\DDR\axi_ddr4_min_2020_2`，不导入 256-bit NVMe/ADC 数据骨干。
4. 生产方案固定为 64-bit AXI DDR4 替换 BRAM，保留现有 XDMA、CONV_DMA、Adapter 和 Aurora 64-bit 接口。
5. AXI ID 在生产集成中使用 5 位，禁止截断；golden 独立工程继续保持原 4 位配置。
6. 地址只使用 DDR 低 64 KiB：Aurora→CPU 为 `0x0000–0x7FFF`，CPU→Aurora 为 `0x8000–0xFFFF`。
7. 共用同一块板卡上的 AK17/AK16 100 MHz 差分时钟。TOP 只保留一个 IBUFDS，单端输出同时送系统 Clock Wizard 和配置为 `No_Buffer` 的 MIG。
8. DDR 外部低有效复位使用 AC34。
9. 构建模式分为 `DDR4_SIM_RAM`（快速回归，默认）和 `DDR4_REAL`（生产 MIG/Clock Converter 边界）。
10. 用户随后明确本阶段只做编译、Elaborate 和基本冒烟，不做综合。

## 4. 已实施的设计改动

### 4.1 Block Design 与内存后端

- 从 `design_1` 移除 `axi_bram_ctrl + blk_mem_gen`。
- 保留 XDMA/CONV_DMA 两主机及现有仲裁。
- 导出统一 `M_AXI_MEM`，数据宽度 64 bit，ID 宽度 5 bit。
- 新增 `rtl\ddr4\rtds_ddr4_backend.sv` 和 `rtl\ddr4\rtds_axi_ram_model.sv`。
- 后端包含跨时钟 Clock Converter、DDR 校准/复位就绪控制、响应错误 sticky 和进度超时 sticky。
- MIG 在新目录重新生成，没有复制 golden 的生成目录。

### 4.2 MIG 固定参数

- DDR4 IP v2.2，器件 `xcku040-ffva1156-2-i`，存储器 `MT40A512M16HA-083E`。
- 物理 64 bit；AXI 为 64-bit data / 32-bit address / 5-bit ID。
- DDR 周期 833 ps，输入时钟周期 9996 ps，PHY 4:1，ECC 关闭，系统时钟缓冲为 `No_Buffer`。

### 4.3 时钟、复位和业务门控

- `init_calib_complete=1` 且 `ui_clk_sync_rst=0` 后，延迟两个 `ui_clk` 周期释放 DDR AXI 复位。
- `ddr_ready` 同步回 250 MHz 域；`ddr_ready=0` 时禁止 FDMA 启动和 Aurora 业务接收。
- XDMA 侧要求软件先轮询 `DDR_STATUS.ddr_ready` 再提交描述符。
- Aurora RX FIFO 保留原 8192×64 bit，容量 64 KiB。
- Aurora RX 完成/INFO/IRQ 的设计意图是等待最后一个 DDR 写 BRESP 返回后再产生。

### 4.4 TOP/PCIe/状态

- `TOP.v`、`PCIe.v` 已加入 DDR4 物理接口、复位和状态连接。
- `CLK_GEN.v` 改为接收共享 IBUFDS 后的单端时钟。
- `INFO_EXCH.v` 在 INFO 基址内加入只读 `DDR_STATUS`，偏移 `0x2C`。
- Adapter 增加 `ddr_ready` 门控。
- DDR 约束文件：`RTDS_test_DDR4_64bit.srcs\constrs_1\new\DDR4_PIN.xdc`。
- 约束只引入 golden 的 DDR 物理引脚/IO 标准，排除 golden 的 LED 和系统差分时钟重复约束。

## 5. 当前寄存器清单

INFO BD 基址：`0x40000000`。

| 偏移 | 名称 | 访问 | 当前说明 |
|---:|---|---|---|
| 0x00 | VERSION | RO | `0x00001001` |
| 0x04 | PROG_TIME | RO | `0x20260506` |
| 0x08 | BUF_LEN_MAX / CH_BUF_LEN | RO | `0x00008000`，32 KiB |
| 0x0C | FPGA_TEMP | RO | FPGA 温度 |
| 0x10 | INT_STATE | RC | 读取保持 read-to-clear；会清 IRQ/相关 sticky |
| 0x14 | CPU_REC_STATE | RW/握手 | C2H 完成后以 0→1 上升沿确认释放接收缓冲 |
| 0x18 | FPGA_CPU_START_ADDR | RO | Aurora→CPU 数据起始地址 |
| 0x1C | FPGA_CPU_LEN | RO | Aurora→CPU 数据长度 |
| 0x20 | CPU_WR_DONE | RW/握手 | 读为硬件响应；写 0→1 边沿启动 CPU→Aurora |
| 0x24 | CPU_FPGA_START_ADDR | RW | CPU→Aurora 数据起始地址 |
| 0x28 | CPU_FPGA_LEN | RW | CPU→Aurora 数据长度 |
| 0x2C | DDR_STATUS | RO | 新增 DDR/AXI/Aurora 状态 |

`DDR_STATUS` 位定义：

| 位 | 名称 | 说明 |
|---:|---|---|
| 0 | ddr_ready | DDR AXI 可接受业务 |
| 1 | init_calib_complete | MIG 校准完成 |
| 2 | ddr_axi_response_error_sticky | BRESP/RRESP 非 OKAY |
| 3 | aurora_rx_fifo_overflow_sticky | Aurora RX FIFO 溢出 |
| 4 | ddr_axi_timeout_sticky | DDR/AXI 或 FDMA 进度超时 |
| 31:5 | Reserved | 固定 0 |

软件读取顺序注意：读取 `INT_STATE(0x10)` 会清 IRQ/相关 sticky，因此应先快照 `DDR_STATUS(0x2C)`，再读 `INT_STATE`。

## 6. 验证结果

### 6.1 IP 生成

- 结果：PASS；标记：`DDR4_IP_GENERATION_PASS`。
- 日志：`reports\compile\generate_ddr4_ips.log`。
- IP 状态已检查，当前生成 IP 为 up-to-date。

### 6.2 DDR4_SIM_RAM 基本冒烟

- 结果：PASS。
- 日志：`reports\compile\ddr_backend_xvlog.log`、`ddr_backend_xelab.log`、`ddr_backend_smoke.log`。
- 通过标记：`DDR_READY_AFTER_TWO_CYCLES_PASS`、`W_FIRST_SINGLE_PASS`、`INCR16_8000_PASS`、`RTDS_DDR_BACKEND_SMOKE_PASS`。
- 覆盖两拍 ready、W 先于 AW 的独立握手、单拍读写和地址 `0x8000` 的 16-beat INCR。

### 6.3 生产 TOP 定向编译与 Elaborate

- 结果：PASS；标记：`RTDS_TOP_COMPILE_ELABORATE_PASS`。
- 日志：`reports\compile\top_xvlog.log`、`reports\compile\top_xelab.log`。
- 所有自定义集成 RTL 均参与编译；未改动的 Aurora 和 BD 内部 vendor 边界使用端口等价 stub，以隔离远程 Vivado 生成模型导出问题。这是结构/接口 Elaborate，不等价于完整 vendor IP 行为仿真。

### 6.4 DDR4_REAL 后端编译与 Elaborate

- 结果：PASS；标记：`RTDS_DDR4_REAL_BACKEND_COMPILE_ELABORATE_PASS`。
- 日志：`reports\compile\real_backend_xvlog.log`、`reports\compile\real_backend_xelab.log`。
- 使用从当前生成的 Clock Converter/MIG stub 提取的纯 Verilog 端口边界，验证 `rtds_ddr4_backend` 的生产实例名、端口名、方向和位宽可 Elaborate。生产 XCI 未修改。

## 7. 遇到的问题、原因与处理

### 7.1 `synth_design -rtl` 未纳入完整 IP 边界

- 现象：报告 `clk_wiz_0` 等模块缺失。
- 原因：`synth_design -rtl` 不自动纳入独立 IP DCP/完整生成模型。
- 处理：改用 XSim 的定向 `xvlog + xelab` 做结构编译与 Elaborate。
- 性质：验证方法选择问题，不是已确认的生产 RTL 端口错误。

### 7.2 远程 XSim 的 `util_ds_buf` 模型包含 Versal 专用原语端口

- 现象：KU040 目标编译 VHDL 模型时出现 `C_SIM_DEVICE=VERSAL_AI_CORE_ES1` 相关 VRFC 错误。
- 原因：生成/导出的仿真模型与目标器件族不一致。
- 处理：仅在 `sim\top_compile` 下建立编译/Elaborate 边界 stub；生产 XCI 不修改。

### 7.3 `ip_user_files` 内 BD 仿真导出陈旧

- 现象：旧 `ip_user_files\bd\design_1\sim\design_1.v` 缺少新增 `M_AXI_MEM/DDR_STATUS`，部分嵌套 IP 仍引用旧 AXI/XDMA 库版本。
- 原因：复制基线后，`ip_user_files` 仿真导出未与当前 BD 同步。
- 处理：结构检查使用当前 `RTDS_test_DDR4_64bit.srcs\sources_1\bd\design_1\sim\design_1.v` 和当前 wrapper；vendor 内部边界使用 stub。
- 后续：完整 Root Port/XDMA 仿真前应重新 export simulation 并编译匹配的 vendor simulation libraries。

### 7.4 远程 Vivado 的 IP Integrator 辅助 Tcl 缺失/异常

- 现象：打开、重置或强制导出 BD 时出现 `utils.tcl`、`utils_timing.tcl`、`roe_framer auto_utils.tcl`、`quadsgmii bd.tcl` 等辅助文件错误。
- 原因：远程 Vivado IP catalog/安装内容不完整或环境污染。
- 处理：本阶段不强制重置生产 BD，不修改 Xilinx 安装目录；使用现有已生成生产源和定向边界验证完成当前门槛。
- 风险：可能影响后续完整 BD 重新生成或仿真导出，进入综合前应先做 `validate_bd_design`/IP catalog 环境复核。

### 7.5 生成的 SystemVerilog stub 触发 SystemC 链接错误

- 现象：`xvlog` 通过，但 `xelab` 链接时缺少 `rtds_axi_clock_converter.h`。
- 原因：Xilinx 生成的 XSim stub 带 `SC_MODULE_EXPORT`，XSim 将其当作 SystemC 模块。
- 处理：从生成 stub 的当前端口声明提取纯 Verilog 边界文件，仅用于结构 Elaborate。
- 结果：`DDR4_REAL` 后端 Elaborate PASS。

### 7.6 TOP 初次定向编译发现桩文件不同步

- 现象：旧 `clk_wiz_0_stub` 端口不匹配，并缺少 `ila_temp`。
- 处理：改为编译当前 Clock Wizard wrapper，并补齐只用于 Elaborate 的 `ila_temp` 边界。
- 结果：TOP 定向编译/Elaborate PASS。

## 8. 软件配合要点（供后续上板）

1. BAR/驱动完成后读取 `INFO_BASE + 0x2C`，等待 bit0=`ddr_ready` 且 bit1=`init_calib_complete`。
2. CPU→Aurora：
   - H2C 将数据写到 DDR `0x8000–0xFFFF`。
   - 长度非 0、512 B 对齐、最大 32 KiB，且地址+长度不超过 `0x10000`。
   - 写 `0x24` 起始地址、`0x28` 长度，对 `0x20` 产生 0→1 上升沿启动。
3. Aurora→CPU：
   - IRQ 到达后先读 `0x2C` 保存错误状态，再读 `0x10` 清 IRQ。
   - 读取 `0x18/0x1C`，通过 C2H 取数；C2H 完成后对 `0x14` 产生 0→1 上升沿确认释放缓冲。
4. 软件不得在 `ddr_ready=0` 时提交 XDMA 描述符。

## 9. 尚未执行与下一阶段

- 未运行生产综合、实现、DRC、时序和 bitstream。
- 未运行完整 MIG+DDR4 器件模型仿真和完整 Xilinx Root Port/XDMA 大回归。
- 未执行实板 DDR 校准、512 B/32 KiB 闭环和 ILA 观察。
- 若后续授权生成 bitstream，顺序建议为：复核 Vivado IP catalog/BD 环境 → `validate_bd_design`/IP 审计 → 综合 → 实现/DRC/时序 → bitstream → 软件配合上板。

## 10. 交付物维护状态

- 本运行纪要：已建立并持续维护。
- 设计方案与寄存器清单 Word：已生成，已通过 DOCX ZIP/XML、必需部件、表格和关键字段结构检查；按要求未渲染 PDF/PNG。
- 共享缓冲集成与验证记录 Markdown：以本运行纪要为内容基线，已固定正式交付副本。
- 最终 SHA-256 清单：本记录固定后生成到 manifest\final_sha256.txt，清单排除自身。

## 11. 收尾审计（2026-08-20）

- Word 已生成：docs\RTDS_test_DDR4设计方案与寄存器清单.docx；结构检查 PASS，明确记录两个工程属于同一块 KU040 板卡。
- Golden 快照补齐 create_project_2020_2.tcl；golden_snapshot_sha256.txt 记录 3 个只读参考文件。
- 已精确删除新工程内 10 个传输用 .b64 临时文件。
- 已移除新 XPR 从基线继承的 ../RTDS_test AutoIncrementalDir 元数据；生产源未发现新目录外绝对引用。
- 新 XPR 默认定义保持 DDR4_SIM_RAM；DDR4_REAL 使用独立运行脚本验证。
- 正式交付记录：docs\RTDS_test_DDR4共享缓冲集成与验证记录.md。
- 最终全目录 SHA-256 清单将在冗余清理决策和必要回归完成后生成，排除清单自身。
## 12. 工程目录冗余审计（2026-08-20）

- 独立报告：docs\RTDS_test_DDR4工程目录冗余审计.md。
- 发现旧名 RTDS_test.xpr/srcs/runs/ip_user_files/cache/hw/sim 约 470.78 MiB；新 XPR 的实际 File Path 不依赖这些目录，属于强清理候选。
- 发现 RTDS_test_DDR4_64bit.runs 约 171.60 MiB，其 TOP.bit、TOP_routed.dcp、TOP.dcp 与旧 RTDS_test.runs 对应文件 SHA-256 完全一致，属于基线遗留，不能当作本次 DDR4 bitstream。
- 上述强清理候选合计约 642.38 MiB。本次仅检查，尚未删除，等待用户授权。
- Aurora 的 sources_1 - loop_validate 下多个 example/exdes 文件被当前 XPR 直接引用，不能按名称删除。
- 未被当前 XPR 直接引用的 fdma_aurora_brg.gen 为 27.17 MiB，其中 example_design 仅约 0.159 MiB，可作为后续可选清理项。
- 新名 ip_user_files 约 54.26 MiB，虽然存在陈旧仿真导出，但远程 IP Integrator 环境当前异常，建议暂留到成功重新导出后再清理。
- 清理后必须重跑基本冒烟、TOP 定向编译/Elaborate、DDR4_REAL 后端编译/Elaborate，再生成最终 SHA-256 清单。
## 13. 本机轻量可打开备份（2026-08-20）

- 本机备份目录：E:\PCIE-CPU\RTDS_test_DDR4_64bit_本机备份_20260820。
- 标准 archive_project -exclude_run_results 两次失败：第一次受长临时路径影响发生 Vivado EXCEPTION_ACCESS_VIOLATION；第二次使用短临时目录后，明确报告 Aurora 深层源路径超过 Windows 248-Byte 上限。原远程生产工程未被修改。
- 改用精确目录备份：包含新 XPR、新 .srcs、当前 XPR 直接引用的 Aurora external_snapshot、rtl/tcl/scripts、sim/regression、docs/reports/logs/manifest/golden_snapshot 和定向验证脚本。
- 明确排除旧 RTDS_test.* 工程族、两套 .runs、旧 TOP.bit/DCP、新旧 cache/hw/ip_user_files/sim 工作目录和根 XSim 缓存。
- 本机备份最终体积约 464.26 MiB；BACKUP_SHA256.txt 覆盖除自身外 1446 个文件。
- 使用本机 D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat 以 batch 模式执行 open_project。
- 打开结果：工程名 RTDS_test_DDR4_64bit，器件 xcku040-ffva1156-2-i，工程文件 864 个，实际 File Path 缺失 0，标记 RTDS_LOCAL_BACKUP_OPEN_PASS。
- 未带 .runs 的 GeneratedRun 警告和未带 ip_user_files 的目录警告符合轻量备份预期；两者均为可再生成产物，不影响 XPR 打开。打开验证自动生成的本机 .Xil/.cache/.hw 已清理，打开证明保存在 reports\backup_validation。
- 本机 E: 已核实为本地 NTFS 固定磁盘（DriveType 3），不是 SMB 映射盘；远程机当前不存在 E:\PCIE-CPU。因此本机备份和远程 C:\project 工程是两份独立副本，不会自动同步。

## 14. Word 关键图纸重制（2026-08-23）

- 应用户要求扩充 `docs\RTDS_test_DDR4设计方案与寄存器清单.docx`，新增附录A及4张关键图纸。
- 图 A-1 为64-bit DDR4共享缓冲总体数据通路；使用正交双向AXI总线箭头，明确标注250 MHz/MIG `ui_clk`时钟域、64-bit/32-bit/5-bit接口及低64 KiB地址窗口。
- 图 A-2 为AK17/AK16共享100 MHz差分时钟与AC34复位电路；使用IBUFDS、分支连接、反相器和结点，不以功能框代替复位极性关系。
- 图 A-3 为DDR AXI复位两拍释放与`ddr_ready`两级同步电路；使用逻辑门、D触发器、时钟线和清零线表达实际RTL关系。
- 图 A-4 为`DDR_STATUS` sticky错误位保持/清除电路；使用OR门、清零MUX、D触发器及Q反馈，映射bit2/bit3/bit4错误来源。
- 图中文字已统一放大：标题86 px，域标识66 px，主要器件/节点64 px，标签62 px，最小58 px；按17 cm插图宽度设计，避免沿用初稿的小字号。
- 连接线采用正交折线、圆角连接和端点箭头，避免斜穿器件、箭头悬空或无意义指向。
- DOCX结构检查PASS：ZIP成员无损坏，必需OOXML部件齐全，7个原有表格保留，4张2800×1500 PNG均以内联方式嵌入，无浮动`wp:anchor`，4项替代文本齐全。
- 按当前工作区规则仅执行DOCX结构与图片嵌入审计，未渲染PDF/PNG预览。
- 本机最终Word SHA-256：`8E5BE4E06CEB0B9A34E3241560F5FAD84A1ACE4061DB3AE893B2E8CCF4388F5F`。
- 远程同步状态：`vivado-srv`解析为`172.20.10.11`，2026-08-23同步时SSH 22端口超时且Ping不通；因此本次先完成本机备份，待远程机恢复连接后再同步到`C:\project\RTDS\DDR\RTDS_test_DDR4_64bit\docs`，未伪报远程更新完成。
- 用户确认远程机当前不通且本次不需要打开Vivado；因此未启动Vivado、未执行工程打开或编译，仅完成文档修改与离线结构校验。

## 15. 最新文档同步到远程机（2026-09-01）

- 远程主机 `DESKTOP-H0AB0MD` 已恢复SSH连接，目标目录为 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit\docs`。
- 已同步新版设计方案Word、4张关键图纸、本运行纪要及正式验证记录；未打开Vivado，也未改动RTL、IP、XPR或运行结果。
- 覆盖前的远程旧版三份主文档已备份到 `docs\archive\sync_before_20260901`，可用于回退。
- 传输压缩包和7个目标文件均完成SHA-256核对；远程临时压缩包和解包目录已删除。

## 16. 自研板卡资料与 XDC 复核（2026-09-08）

- `docs` 新增板卡资料：`RPT205-1-001.DSN`、`RPT205-1-001.brd`、`RPT205-1-001引脚定义.xlsx`、`RP205-1-001 （DDR4）.txt`。板卡是组内自研 `RPT205-1-001`，不是厂商开发板；板上 FPGA 器件仍为 `XCKU040-2-FFVA1156I`，与目标工程 `xcku040-ffva1156-2-i` 一致。
- 原理图应使用 OrCAD Capture/OrCAD X Capture CIS 打开 `.DSN`；PCB 应使用 Allegro PCB Editor/OrCAD X PCB Designer 打开 `.brd`。当前远程 Windows 仅确认安装 WPS Office 2019，可直接打开 `.xlsx/.docx`；未发现 Cadence、OrCAD、Allegro 或 LibreOffice。Windows 将 `.DSN` 错关联为 ODBC 数据源，不能直接双击，应在 OrCAD 内用 `File > Open > Design`。
- 当前 PCIe 工程活动约束只有 `RTDS_test.srcs\constrs_1\new\PIN.xdc`。旧实现报告确认 PCIe x2 数据通道位于 Bank 224：RX0 AP1/AP2、RX1 AM1/AM2、TX0 AN3/AN4、TX1 AM5/AM6；这与 9 月 8 日引脚表一致。
- 旧约束的 PCIe 参考时钟 Y5/Y6（Bank 225）和复位 K22 未出现在 9 月 8 日引脚表。自研板资料给出 Bank 224 直接参考时钟 AF5/AF6、缓冲参考时钟 AD5/AD6及 `SLOT_RST1=AK13`。必须结合 `.DSN` 确认实际装配链路后，在两组参考时钟中二选一，不能同时约束；不得因旧工程曾实现完成就继续沿用 Y5/Y6、K22。
- 系统 100 MHz 差分时钟确定为 AK17/AK16。现有 XDC 只显式写 AK17，应补齐 AK16并只建立一个 100 MHz 主时钟。单个 IBUFDS 输出供 Clock Wizard，并送入配置为 `No_Buffer` 的 MIG。
- DDR 引脚表与现有 `DDR4_PIN.xdc` 的 DQ、DM、DQS、地址、命令和 `DDR4-RESETN=AG16` 一致，因此物理 DDR 管脚可作为自研板约束基线；文件注释和来源必须改为 `RPT205-1-001`，不能再写旧 KU040 参考板。
- 板上 DDR 实际器件为 `MT40A1G16TB-062EIT`，当前生成脚本中的 `MT40A512M16HA-083E` 不匹配。必须按实物颗粒重新生成/配置 MIG；不能只修改 XDC。当前 `ddr_sys_rst_n=AC34` 也没有板卡资料依据，建议移除该外部端口并用内部 `!clk_wiz_locked` 驱动 MIG `sys_rst`，同时保留 AG16 作为 MIG 到 DRAM 的低有效复位输出。
- 单 LED 的旧约束 T23/LVCMOS18 与板卡表不一致。板卡测试灯 TEST1～TEST6 为 AP11、AP10、AM11、AN11、AE8、AH9，均标为 LVCMOS33；如只保留一个 `led`，应选择其中一个并从原理图确认亮灭极性。
- Aurora/10G 光口资料给出 Bank 226：参考时钟 V5/V6、RX Y1/Y2、TX AA3/AA4。旧示例的 T5/T6 以及 `sfp_tx_disable/sfp_rs0/sfp_rs1` 的 H26/G26/H27 不适用于本板；H26/G26 在板卡表中已有其他功能，控制信号必须从原理图核对后再绑定，不能猜测。
- 旧 routed DRC 只有 `CFGBVS-1` 与 `RTSTAT-10` 警告，没有 UCIO/NSTD，但该报告属于旧工程运行产物，不能证明 9 月 8 日新增板卡资料对应的约束已经闭合。后续应在修订 XDC/MIG 后重新执行 I/O 审计、Elaborate，再进入综合实现。

## 17. 2026-09-20 MIG实现失败复盘

实际实现验证补充了两个必须同时满足的条件：

1. `clk_p`和`clk_n`必须分别显式约束到AK17和AK16。只约束正端会在MIG Core Generation阶段触发`Mig 66-99`，不能依赖差分伴随管脚自动推断。
2. `System_Clock=No_Buffer`的MIG必须由共享IBUFDS输出直接驱动。不得改接系统Clock Wizard的`clk_100m`，否则形成用户MMCM/PLL级联MIG MMCM；GUI实现日志会报告级联结构在当前高速配置下不支持，并以`Opt 31-306`结束。

最终时钟结构：

```text
AK17/AK16差分100MHz
        |
     单个IBUFDS
        |------------------> MIG c0_sys_clk_i（No_Buffer，直接连接）
        +------------------> Clock Wizard --> 系统100/156.25/250MHz
```

对应源码约束为：

```text
PIN.xdc: clk_p=AK17，clk_n=AK16
TOP.v:   .ddr_sys_clk_i(clk_100m_ibuf)
MIG XCI: System_Clock=No_Buffer
```

任何修改这三项之一，都必须重新综合并实现到至少`opt_design`之后，不能用模块OOC综合通过代替MIG物理时钟检查。
- 本次只做只读检查和非工程 Vivado 器件管脚查询，未启动 Vivado GUI，未修改远程 RTL、IP、XPR 或 XDC。CentOS 虚拟机 SSH 当前不可达，未确认其软件状态；查看 OrCAD/Allegro 文件建议直接在远程 Windows 主机安装 OrCAD X Free Viewer。
