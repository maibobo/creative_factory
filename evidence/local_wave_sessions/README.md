# 七组本机 GUI 波形会话

新版阅读说明：[WCFG 里是什么、覆盖是否足够、如何结合代码](WCFG_阅读与代码对照.md)。查看器现支持三栏拖动调宽、任选一栏/两栏、简名/全称切换和标准模块边界阅读；旧窗口请刷新后使用。

ring、axi、regs 的具体时间刻度与“波形 → RTL → 测试台检查”证据链见 [WCFG_ring_axi_regs_观察链与时间刻度.md](WCFG_ring_axi_regs_观察链与时间刻度.md)。

生成日期：2026-09-25。工程：`F:\RTDS_test_DDR4_64bit_batch_dev`。

七组均用本机 Vivado 2020.2 重新编译、展开和运行，日志均出现 `TEST PASS`。没有使用远程连接，没有修改功能 RTL、测试激励或原确认稿，也没有依赖旧截图。这里是模块级行为仿真，不代表真实 DDR 校准、Aurora 物理链路或整机 PCIe 已验证。

## 打开方式

双击下表的 `Open_*.cmd`，或者在 **Windows PowerShell 5** 中执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "F:\RTDS_test_DDR4_64bit_batch_dev\scripts\Open-LocalWave.ps1" -Case tx
```

`-Case` 可取 `1g`、`tx`、`rx_fifo`、`ring`、`axi`、`axi_tail`、`regs`。默认用本机 Edge 的独立应用窗口打开三栏离线查看器：信号、波形、代码三栏可分别拖动调整宽度，也可任选一栏或两栏。默认显示业务信号和纯简名，隐藏标准CDC/复位同步/XPM内部信号及采样别名；全部记录通过“全部信号”恢复。不需要安装额外程序，也不需要启动仿真器。若未找到 Edge，则使用默认浏览器。

在远程 Windows 的**已登录桌面**打开时，将命令中的 `-File` 路径改为 `C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev\scripts\Open-LocalWave.ps1`；各组 `Open_*.cmd` 仍可在各自目录双击。通过 SSH 启动 GUI 通常不显示在当前桌面，因此 SSH 只用于文件同步和校验。

七份 HTML 都是独立文件，已嵌入本次 VCD 的完整变化记录和对应源码快照，可以直接双击或单独复制后离线查看。生成时校验了源码 SHA-256；以后原工程源码发生变化，不会改变 HTML 中的对应代码。

需要 Vivado 原生 WDB 查看（包括 unpacked array 展开）时，在上面命令末尾加 `-Vivado`。此模式会校验当前磁盘源码 SHA-256，再打开独立仿真工程、WDB 和已填满信号的 WCFG；从 Simulation Sources 或信号右键菜单查看代码。当前源码与仿真时不一致会明确报出文件并停止。Vivado 使用固定位置 `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`，首次启动可能需要几分钟。

上述 `-Vivado` 入口按本机 F 盘源码路径与 D 盘 Vivado 安装生成，远端同步后未重建其独立仿真工程，因此远端直接使用的是自包含 HTML；若要在远端原生打开 WDB，需要先按远端 C 盘源码和 Vivado 安装重新生成/校验该入口。

| 三栏离线 GUI | 文件大小约 |
|---|---:|
| [1g_viewer.html](1g/1g_viewer.html) | 10.6 MB |
| [tx_viewer.html](tx/tx_viewer.html) | 6.0 MB |
| [rx_fifo_viewer.html](rx_fifo/rx_fifo_viewer.html) | 1.1 MB |
| [ring_viewer.html](ring/ring_viewer.html) | 1.4 MB |
| [axi_viewer.html](axi/axi_viewer.html) | 1.5 MB |
| [axi_tail_viewer.html](axi_tail/axi_tail_viewer.html) | 0.12 MB |
| [regs_viewer.html](regs/regs_viewer.html) | 0.09 MB |

| 用例 | 双击入口 | 波形数据库 | 波形信号配置 | 完整信号列表 | 编译源码列表 |
|---|---|---|---|---|---|
| 1g | [Open_1g.cmd](1g/Open_1g.cmd) | [1g.wdb](1g/1g.wdb) | [1g.wcfg](1g/1g.wcfg) | [signals.txt](1g/signals.txt) | [files.txt](1g/files.txt) |
| tx | [Open_tx.cmd](tx/Open_tx.cmd) | [tx.wdb](tx/tx.wdb) | [tx.wcfg](tx/tx.wcfg) | [signals.txt](tx/signals.txt) | [files.txt](tx/files.txt) |
| rx_fifo | [Open_rx_fifo.cmd](rx_fifo/Open_rx_fifo.cmd) | [rx_fifo.wdb](rx_fifo/rx_fifo.wdb) | [rx_fifo.wcfg](rx_fifo/rx_fifo.wcfg) | [signals.txt](rx_fifo/signals.txt) | [files.txt](rx_fifo/files.txt) |
| ring | [Open_ring.cmd](ring/Open_ring.cmd) | [ring.wdb](ring/ring.wdb) | [ring.wcfg](ring/ring.wcfg) | [signals.txt](ring/signals.txt) | [files.txt](ring/files.txt) |
| axi | [Open_axi.cmd](axi/Open_axi.cmd) | [axi.wdb](axi/axi.wdb) | [axi.wcfg](axi/axi.wcfg) | [signals.txt](axi/signals.txt) | [files.txt](axi/files.txt) |
| axi_tail | [Open_axi_tail.cmd](axi_tail/Open_axi_tail.cmd) | [axi_tail.wdb](axi_tail/axi_tail.wdb) | [axi_tail.wcfg](axi_tail/axi_tail.wcfg) | [signals.txt](axi_tail/signals.txt) | [files.txt](axi_tail/files.txt) |
| regs | [Open_regs.cmd](regs/Open_regs.cmd) | [regs.wdb](regs/regs.wdb) | [regs.wcfg](regs/regs.wcfg) | [signals.txt](regs/signals.txt) | [files.txt](regs/files.txt) |

以上路径均相对于本文件目录 `F:\RTDS_test_DDR4_64bit_batch_dev\evidence\local_wave_sessions`。每组另有同名 `.vcd`、`simulation.log`、`signals.csv`、`signal_sources.csv`、`signals_summary.md` 和 `source_hashes.json`。

不要只双击 WDB：WDB 保存变化数据，WCFG 保存信号显示列表与分组，XPR 提供当前源码文件集。启动器在 `-Vivado` 模式下把三者同时加载。VCD 用于后台分析和交换，不能替代包含数组对象的完整 WDB。

## 信号、波形和源码如何对应

WCFG 默认覆盖整个仿真时间范围，分四组：

- `01_TESTBENCH`：时钟、激励控制、监测计数和参考值。
- `02_INTERFACE`：`/tb_rtds_<case>/bus` 下的全部接口信号，把进出 DUT 的握手、地址、长度、数据、复位和状态放在一起。
- `03_DUT`：`/tb_rtds_<case>/U_DUT` 下的全部直接对象，包含全部端口及第一层内部状态、计数器和组合条件。
- `04_ALL_HIERARCHY`：整个测试顶层递归展开的可显示对象，包括子模块、CDC、XPM FIFO/存储对象、RAM 模型与 clocking block 别名。前三组中的部分信号在此重复，便于既按接口读，又按层次追踪。统计数量按完整路径去重，不重复计数。

离线 GUI 的核心层 862 个信号全部带源码行映射（包括测试顶层、接口、DUT 第一层和 AXI RAM 边界），点击即跳转。深层对象中能够识别实际模块/实例的也带映射；无法唯一定位的 clocking block 生成别名等会明确提示，保留完整文件列表与源码搜索，不伪造源代码行。每组 `signal_sources.csv` 提供 TB、bus、U_DUT 核心索引，HTML 还补充了可识别子模块的映射。

Vivado 模式下，在 Scopes 中选择 DUT/子模块可查看 Objects；从信号的右键菜单选择 **Go To Source Code** 可定位源码。详见 [AMD UG900 Objects Window](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Objects-Window)。

总线显示为十六进制，CSV 中的已知最小/最大值按无符号十进制统计。观察数据是否真正传输，要结合时钟与 `valid && ready`，不能仅凭数据线上有数值判断。离线 GUI 支持滚轮上下滚动、Ctrl+滚轮缩放、拖动平移、单击设光标、输入起止 ns 跳转；“全时段”恢复完整记录。“业务信号”为默认视图，可切换全部信号、测试台、接口 bus 或 DUT端口/状态。全部记录保留，不限于旧确认稿的局部截图。

## 完整性与覆盖范围

| 用例 | WCFG 唯一对象 | VCD 信号声明 | 仿真结束时间 | 源码/库文件数 |
|---|---:|---:|---:|---:|
| 1g | 195 | 195 | 283.920 µs | 7 |
| tx | 790 | 783 | 28.9056 µs | 7 |
| rx_fifo | 798 | 790 | 0.790 µs | 9 |
| ring | 116 | 114 | 28.902 µs | 4 |
| axi | 234 | 234 | 13.318 µs | 5 |
| axi_tail | 233 | 233 | 0.326 µs | 5 |
| regs | 114 | 114 | 0.422 µs | 4 |

总计 2480 个 WCFG 唯一对象、2463 个 VCD 声明；七组 VCD 声明与 WCFG 逐项对照，没有漏列。VCD 不支持的 17 个 unpacked array 仍保留在 WDB/WCFG，例如 `ring/U_DUT/block_len`、`block_seq`，以及 FIFO 内部数组。离线 GUI 也列出这 17 个对象，但明确标为“仅WDB数组”，不画伪造轨迹；需要看数组元素时用 `-Vivado` 打开原生波形。`files.txt` 按项目编译顺序列出用户源码，并追加实际使用的 `glbl.v` 和 XPM 预编译库对应源码。

“完整”指这些用例中可追踪的硬件信号和可显示对象。XSim 2020.2 不支持 task/function 自动局部变量、动态队列/关联数组的波形追踪，例如测试台自动任务参数、RX 参考队列及 ring 的软件记分板；这些不是遗漏的模块接口。仿真日志及构建日志保留了相关限制。没有为了显示它们而改动测试台行为。

本次实际校验结果：七个 WDB/WCFG 均重新打开成功；将 WDB 的 2533 个对象逐项与 WCFG 比较，2480 个可显示对象全部在列表中，其余 53 个全部有 XSim 明确的不可追踪警告，没有无法解释的遗漏，也没有配置中引用不存在信号的情况。见 [coverage_audit.json](coverage_audit.json)，每组排除对象见 `unsupported_objects.txt`。

七份离线 GUI 在本机无头 Edge 中完成加载、全信号列表、源码行引用、缩放、过滤、选中、光标、文件切换和帮助测试，均通过且无页面脚本错误。没有截图或上传。见 [viewer_test_results.json](viewer_test_results.json)。Windows PowerShell **5.1.19041.5737** 完成脚本语法、文件非空、WCFG XML 和源码哈希检查，见 `F:\RTDS_test_DDR4_64bit_batch_dev\logs\test_local_wave_ps5.log`。

新版可调布局另做了本机无头 Edge 交互复测：七组在 1440×900 与 1024×720 下的七种非空栏组合、分隔条拖动、信号/波形同步滚动、代码独立滚动、右侧滚动条拖动均通过；ring、axi、regs 本文使用的 ns 范围跳转也已点测。结果见 [resizable_viewer_test_results.json](resizable_viewer_test_results.json)。

## 选取理由与初步观察

### 1g

重点串联 `cfg_byte/cfg_byte_valid`、译码、`cfg_hold/cfg_req`、CDC 请求同步、`cfg_user/cfg_ack`、`configured/configured_id`，再看 `period_count/period_tick`、发送状态、`tx_data/tx_valid/tx_ready/tx_sof/tx_eof/tx_rem`、`channel_up` 和 `skipped_periods`。这些信号能区分配置错误、跨域未到达、正常等待和发送反压。

本次日志通过，`completed_frames=60`；VCD 中 `skipped_periods` 最大值为 3。现有检查器覆盖十组配置、非法/重复配置、无反压时 63×32ns 的发送周期、两拍字节序、反压保持和链路恢复。计数会随测试复位，所以变化次数不是漏帧总数。详见 [1g 核心信号统计](1g/signals_summary.md)。

### tx

选入 `raddr/rareq/rvalid/rready` 等 FDMA 读通路、`limit`、FIFO 写读水位及满空保护、读/发状态机、`tx_data/sof/eof/valid/ready` 和 `received/peak_words`。用于沿“DDR读取→异步FIFO→10G发送”逐级对照。

单帧与 300 帧均通过；水位峰值分别为 2、504，`fifo_overflow` 和 `fifo_underflow` 全程为 0。批量结束 `received=600`，计量是 64bit 拍，等于 300×2 拍。长平直段对应 ready 反压下保持；恢复后先补读再排空，不能将保持的数值误认为重复发送。详见 [tx 核心信号统计](tx/signals_summary.md)。

### rx_fifo

选入两个时钟域的复位/就绪、`rx_data/rx_valid/rx_ready/rx_sof/rx_eof/rx_rem`、内部 FIFO 写读与满空/复位忙、`frame_data/frame_valid/frame_ready`、源域丢失计数和 `dropped_frames/length_error`。这样既看线路输入，也看 DDR 侧实际消费与跨域状态延迟。

测试缩小 FIFO 深度构造拥塞；`received` 最终为 18，`dropped_frames` 达到 1，`length_error` 始终为 0，按序核对通过。满时额外有效拍被丢弃，读侧放行后恢复。详见 [rx_fifo 核心信号统计](rx_fifo/signals_summary.md)。

### ring

选入输入 frame、`half_data/half_valid`、pair/tail 条件、`fdma_w*` 全部事务、状态机、`used_bytes`、seal/push/pop、队列与块指针、`head_addr/head_len/head_seq`、`irq/cpu_ack/irq_clear` 和错误/丢失计数。它们能证明发布块之前已收到最终成功响应，并看清低 32bit 两字拼接及奇数尾字的 `WSTRB=0F`。

三轮八块地址复用、八块积压、延迟响应与错误恢复检查通过。`ready_blocks` 最大为 8，`head_seq` 最大为 33，`dropped_frames` 最终为 4（满队两个字，加错误响应两个字）；这是故意注入的测试结果。用例将采集周期缩为 200 拍，波形时间不能直接当作实际 100ms 配置。详见 [ring 核心信号统计](ring/signals_summary.md)。

### axi

同时保留 FDMA 读写接口、AXI AW/W/B/AR/R 全部通道、内部地址/拍数/状态、RAM 边界信号、`allow_aw/allow_w/allow_b` 和错误注入。不能只看 AW/W 而漏掉决定事务最终成功的 B 通道，也不能漏掉读回比对。

高地址、520 拍请求和独立通道停顿用例通过；从 `0x180FF8` 开始的拆分由测试检查器核对为 1/256/256/7 拍。波形记录 AWLEN 最大 255；需结合具体事务区间看完整地址/长度序列。错误注入属于预期场景，不能单凭 `fdma_werror` 曾置位判定回归失败。详见 [axi 核心信号统计](axi/signals_summary.md)。

### axi_tail

保留与 axi 同样的完整模块接口，重点对照 `fdma_wstrb/M_AXI_WSTRB`、写地址/数据和 `M_AXI_RDATA`。本次 `WSTRB=FF` 与 `0F` 均出现，测试通过“先全写，再只写低四字节，最后读回”确认高 32bit 保持。详见 [axi_tail 核心信号统计](axi_tail/signals_summary.md)。

### regs

选入 AXI-Lite 五通道、`CPU_WR_DONE` 及边沿检测、`start/done`、地址长度、`ack/WSTRB`、队头状态和读回数据。用它们区分软件写事务、内部锁存状态与一次性命令脉冲。

`starts=2`、`acks=2`，重复提交未额外启动，忙时地址/长度保持，完成事件清零后能再次提交，`WSTRB=E` 没有产生第三次 ACK。0x30/0x34/0x38 的读回由检查器核对为 1/7/9。详见 [regs 核心信号统计](regs/signals_summary.md)。

## 文件说明与复跑

`signals.csv` 列出所有添加对象的全名、位宽、VCD 可用性、初末值、变化次数、首末变化时刻、已知值范围及 X/Z 记录次数。初末值是 VCD 的二进制文本；初值不计入变化次数；X/Z 包括初始化，不直接判错。没有 VCD 对应的数组留空，不伪造统计。

重跑七组的命令如下。先关闭这些独立会话，重跑会更新本交付目录下的仿真工程和波形，不触碰主工程综合/实现产物。

```powershell
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' -mode batch -source 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\build_local_wave_sessions.tcl' -log 'F:\RTDS_test_DDR4_64bit_batch_dev\logs\build_local_wave_sessions.log'
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\summarize_local_wave_sessions.py'
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\build_offline_wave_viewers.py'
& 'D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat' -mode batch -source 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\verify_local_wave_sessions.tcl' -log 'F:\RTDS_test_DDR4_64bit_batch_dev\logs\verify_local_wave_sessions.log'
& 'C:\Users\MaiBo\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe' -X utf8 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\audit_local_wave_coverage.py'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File 'F:\RTDS_test_DDR4_64bit_batch_dev\scripts\Test-LocalWave.ps1'
```

日常打开不需要 Python。只有重建 CSV/Markdown 统计与 HTML 时需要上面的本地 Python；脚本仅用标准库，不联网、不上传波形。

证据位于每组 `simulation.log`、总表 `manifest.json`，以及工程 `logs` 下的 `build_local_wave_sessions.log`、`verify_local_wave_sessions.log`。原始参考文档为 `docs\RTDS_V2.01快速仿真波形确认稿.docx`；近五天历史用于确认七组用例范围和本地迁移背景，本次结论以新生成的波形、日志及源码为准。

## 可复用 Skill

已整理为 `C:\Users\MaiBo\.codex\skills\lightweight-wave-viewer\SKILL.md`，包含制作流程、标准模块连接边界、数据/源码一致性、布局交互、验证方法，以及 `assets/viewer.html` 模板和数据契约说明。以后可请求使用 `$lightweight-wave-viewer` 处理其他工程；需要按该工程重新提取数据和连接关系，不直接沿用本工程的层次名。

本次标准模块父连接清单位于各组 `standard_module_connections.csv`，记录父信号、实例、模块、端口、实际连接表达式和源码行。
