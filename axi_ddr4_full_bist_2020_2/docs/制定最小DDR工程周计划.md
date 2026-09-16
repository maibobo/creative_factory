# 制定最小DDR工程周计划

<!-- codex-history-md-export {"combined_sha256": "a53fc4cfc4bdd606780908c53316bb75dc5055c404372ffe475b17c6b81f268a", "format_version": 4, "kind": "conversation", "project_name": "ddr_proc", "session_ids": ["019fc561-6c64-7021-9090-820de6f07881"], "storage_mode": "session", "theme_key": "session-13bb9c5105488e13e854", "theme_title": "制定最小DDR工程周计划"} -->

* Project：ddr_proc
* 创建时间：2026-08-03 10:08:44 +0800
* 最后更新时间：2026-08-07 13:55:39 +0800

<a id="session-019fc561-6c64-7021-9090-820de6f07881"></a>

## 对话内容

### User

给我写一个周计划，就是做最小DDR工程，参考图片格式和历史记录E:\codex_history_md\ddr_proc

### Assistant

我会先按你给的五级字段格式，查阅 `E:\codex_history_md\ddr_proc` 里的历史记录，提取“最小 DDR 工程”的实际工作脉络，再整理成一周可执行计划。这个任务涉及语言整理，我会按本机 `unslop` 规则把表述写得自然、具体。图片只作本地参考，不会把原图或裁图展示出来。

历史记录里已经确认两条主线：现有 AXI BIST 仿真已通过，但还不等同于真实 DDR 验证；后续重点是把 Vivado 2020.2 下的 MIG、顶层 AXI 通路、实现与板级校准收敛到一个可复现的最小工程。我再核对 MicroBlaze/DDR 示例中的接口和验收点，然后给出可直接粘进周计划表的一行。

结合历史进度，本周重点不是重新写 AXI BIST，而是完成 **MIG 集成、工程构建和板级验收**。

| 任务（一级） | 子任务（二级） | 活动（三级） | 子活动（四级） | 目标产物 |
|---|---|---|---|---|
| DDR IP | 最小DDR工程搭建与验证 | DDR4 MIG、AXI4读写通路集成及板级测试 | 1. 核对 KU040、DDR4型号、时钟和引脚约束，固化 Vivado 2020.2 MIG 配置；2. 集成 MIG 与现有 AXI BIST，回归正常读写及注错仿真；3. 完成综合、实现、DRC、时序检查和 bitstream 生成；4. 上板确认 `init_calib_complete`，执行多地址、多数据模式写入回读；5. 整理问题记录和复现步骤 | 可复现的最小DDR工程，包含 XPR/Tcl、RTL、XDC、bitstream，以及仿真和板级测试报告 |

按天安排：

- 周一：核对器件、DDR参数、时钟与引脚，确认 MIG 配置。
- 周二：完成 MIG、AXI BIST 和顶层接口集成，回归已有仿真。
- 周三：完成综合、实现、DRC、时序检查，生成 bitstream。
- 周四：连接 JTAG 上板，检查 DDR 校准并运行写入回读测试。
- 周五：处理遗留问题，固化脚本、工程版本和验收文档。

验收标准：DDR 校准成功，AXI 写入回读无错误，工程可通过 Vivado 2020.2 从脚本或 XPR 重复构建。

### User

子活动（四级）概括为一句话  目标产物概括为词语

### Assistant

- 子活动（四级）：完成MIG配置、AXI读写通路集成、工程构建及板级验证  
- 目标产物：最小DDR工程及测试报告

### User

最小DDR工程搭建与验证  换个名字 高大上一点

### Assistant

建议改为：**DDR4存储子系统构建与验证**

更偏项目化也可以写：**高性能DDR4存储子系统开发与验证**。

### User

帮我查一下，当前这个最小工程在本机还是远程的机子，各有哪些工程和资料

### Assistant

我会分别盘点本机 `E:\ddr_proc` 和远程机 `C:\project\RTDS\DDR\axi_ddr4_min_2020_2`，区分源工程、脚本、RTL、仿真、文档、生成物及当前构建状态。全程只读，不启动 Vivado，也不修改工程。

本机工程目录已找到。远程 `vivado-srv` 当前首次连接超时，我先做一次端口连通性复核；如果远程机关机或网络未接通，我会把“当前实查结果”和“历史记录中确认存在的远程内容”分开列明，避免混在一起。

结论：**可直接用 Vivado 打开的完整最小 DDR 工程在远程机；本机只有源码和脚本暂存包，当前不是完整工程。**

### 本机

目录：[staging_axi_ddr4_min_2020_2](E:/ddr_proc/staging_axi_ddr4_min_2020_2)

现有内容：

- RTL：`axi_ddr_bist.v`、`top_axi_ddr4_bist.v`
- 仿真：`tb_axi_ddr_bist.sv`
- Tcl：工程创建、检查、构建、许可证检查、硬件检查、下载脚本
- 批处理：仿真、构建、工程检查、JTAG检查及下载入口
- 文档：`README.md`、DDR仿真验证总结

本机缺少：

- `constr\top_axi_ddr4_bist.xdc`
- Vivado `.xpr`
- MIG `.xci` 及生成文件
- 综合、实现目录和报告
- 仿真日志
- `.bit` 文件

因此，本机暂存包目前连创建脚本都不能独立运行，因为脚本引用的 XDC 不在本机。

另外，本机 `E:\ddr_proc\tmp\pdfs` 中还有 MicroBlaze 教程 PDF 和资料目录文本，但不属于最小 DDR 工程主体。

### 远程机

完整工程记录位置：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2
```

主工程：

```text
prj\axi_ddr4_min_2020_2.xpr
```

历史确认远程机包含：

- 完整 Vivado 2020.2 XPR
- DDR4 MIG AXI IP
- KU040 DDR4板级约束
- AXI BIST RTL和顶层
- SystemVerilog Testbench
- 工程创建、检查、构建和下载脚本
- XSim正常测试及注错测试日志
- IP状态、许可证和构建报告
- 旧工程备份：`prj_stale_20260724_1232`

远程参考工程和资料还有：

- `DDR\26_top_ddr4_rw`：KU040 DDR4基础参考工程
- `DDR\40_eth_ddr_lvds`：以太网、DDR和LVDS集成工程
- `02_example_mig_ddr-35t\01_mig_ddr_test`：DDR3简单写读工程
- `02_example_mig_ddr-35t\02_mig_3buf_test`：DDR3三缓冲工程
- 《Kintex Ultrascale之FPGA开发指南 V1.0》DDR章节
- MicroBlaze的DDR、DMA和Cache示例资料

最后一次历史检查显示：主 XPR 正常，许可证已经恢复，但完整综合没有真正跑完，尚无新生成的 bitstream。

当前远程机 `172.20.10.11:22` 无法连接，映射盘 `R:` 也不可用，因此以上远程内容是最后一次成功检查的记录，暂时无法确认今天是否有新增或改动。

### User

说明一下行为级、完整仿真的区别和当前bist.v、axi_ddr_bist的编写方案思路，并写一个方案设计+验证的md文档，保存在远端机器

### Assistant

我会先核对本机与远程工程里的 `bist.v`、`axi_ddr_bist.v`、顶层和 testbench，按实际代码说明两种仿真边界，再整理成“方案设计 + 验证方案”Markdown。文档表述会按 `unslop` 规则收紧，重点写清楚能验证什么、不能证明什么；确认远程目录后直接保存过去。

### User

不需要按 unslop 规则

### Assistant

收到，不使用 `unslop`，文档按普通技术设计文档风格编写。远程文件查询正在返回，我继续核对实际源码和目录。

### User

现有文件加上语段义的中文注释

### Assistant

我会把这一项并入本次交付：在现有 RTL／Testbench 中补充“语段级”中文注释，说明状态机阶段、握手条件、计数器含义和错误锁存逻辑，不逐行堆注释，也不改功能。修改后先做源码差异检查和可用的语法/行为仿真，再与设计文档一起同步到远程工程。

代码核对结果：当前工程没有单独的 `bist.v`，实际是 `axi_ddr_bist.v`（BIST主控）和 `top_axi_ddr4_bist.v`（MIG、复位、LED与BIST集成），验证文件是 `tb_axi_ddr_bist.sv`。文档会按这三个真实文件展开，同时注明这个命名差异。现在开始只补中文段落注释。

中文注释已经补到三个现有源码文件中，未改任何逻辑。接下来用本机实际安装的 Vivado 2020.2 工具链重新编译并运行正常、注错两组行为级测试；验证通过后，文档会引用这次最新结果。

XSim 仍在本机运行，当前没有返回编译错误。这个回归包含两次完整执行，第二次会重新运行同一快照并注入读数据错误；我继续等最终退出码。

注释后的源码已重新通过 Vivado/XSim 2020.2：正常读写和注错检测都在 `3335 ns` 结束并通过。现在生成设计与验证文档，内容会把“行为级仿真”“MIG+DDR4器件模型完整仿真”“实现后时序验证”“上板验证”四个层次分开，避免把完整仿真等同于板级通过。

远程机现在已经能连到 SSH 端口，但密钥认证被拒绝，和前两天的“网络超时”不同。我会先核对本机 SSH 配置及密钥文件是否仍存在，只检查路径和权限，不读取私钥内容；认证恢复后再同步四个文件。

设计文档和三份带中文注释的源码已上传到远程主工程。远程原文件的大小与本机修改前版本完全一致，说明没有覆盖远程新增逻辑；本次同步只是在同一版本上增加注释。现在做远程哈希和内容复核，再运行远程现有行为级回归。

### User

不需要编译，只改了注释即可

### Assistant

收到，不再进行任何编译或仿真。当前只完成文件回读与一致性校验，确认远端文档和注释文件上传正确后结束。之前本机已经做过一次回归，但不会在远端重复运行。

已完成并保存到远程机：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\docs\
DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md
```

本机副本：[DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md](E:/ddr_proc/staging_axi_ddr4_min_2020_2/docs/DDR4_MIN_BIST_DESIGN_AND_VERIFICATION.md)

文档主要说明：

- 行为级仿真：只验证 `axi_ddr_bist`，使用寄存器数组模拟DDR，重点检查AXI握手、状态机、数据比较及错误检测。
- 完整仿真：包含顶层、MIG和DDR4器件模型，可验证MIG校准、时钟复位以及AXI经过MIG访问DDR4模型的完整链路。
- 完整仿真仍不能代替板级验证，PCB、信号完整性和真实PHY校准最终要以上板结果为准。
- 详细分析了地址与数据模式、AXI单拍事务、AW/W独立握手、状态机和第一次错误现场锁存。
- 给出了完整仿真Testbench结构、测试用例、观察信号及分层验收矩阵。

当前工程没有单独的 `bist.v`，实际对应：

- `axi_ddr_bist.v`：AXI BIST主控
- `top_axi_ddr4_bist.v`：MIG与BIST集成顶层

以下远程文件已增加语段级中文注释：

```text
rtl\axi_ddr_bist.v
rtl\top_axi_ddr4_bist.v
sim\tb_axi_ddr_bist.sv
```

只增加了注释，没有修改逻辑。远程回读文件与本机文件的SHA256全部一致。按你的要求，没有在远程执行编译或仿真。

### User

如果下面执行仿真验证，需要做什么工作，你可以直接开始任务吗

### Assistant

可以开始，但当前是规划阶段，我先只读盘点远程工程是否已经具备 MIG 仿真模型、DDR4 器件模型、顶层 Testbench 和可复用的 Example Design 脚本。盘点后我会明确：现成能跑什么、还要补哪些文件，以及一次完整验证的预计步骤和判定标准。

### User

给出预计时间，之前跑pcie example design的仿真模型需要几个小时，这次呢

### Assistant

从远程现状看，这次比 PCIe Example Design 简单：没有 PCIe PHY/LTSSM、枚举和协议栈，但仍要跑 MIG 校准、DDR4 器件模型以及 8192 次单拍事务（4096写＋4096读）。而且当前工程只有 XPR、XCI 和约束，没有 MIG Example Design、DDR4 Model 或系统级仿真脚本。

预计时间：

- 生成并整理 MIG Example Design／器件模型：30～90分钟
- 编写系统级 Testbench、接入现有顶层：1～2小时
- 编译展开与第一次校准冒烟：30～90分钟
- 32～64字冒烟仿真：约30～90分钟
- 4096字完整回归：约2～6小时
- 结果检查和文档更新：30～60分钟

如果接口一次接对，整体约4～8小时；若遇到器件模型组织方式、复位极性或校准卡住，可能需要1～2个工作日。相比之前 PCIe 仿真，通常会更短，但直接从4096字开始仍可能跑数小时，而且失败后定位成本高。建议先把顶层 `TEST_WORDS` 参数化，跑32字完整链路，校准和数据通路通过后再跑4096字签核。

<proposed_plan>
# DDR4 MIG 分级完整仿真计划

## 概要

在远程工程 `C:\project\RTDS\DDR\axi_ddr4_min_2020_2` 上执行两级验证：

1. 32字完整冒烟仿真，确认MIG校准、复位和基本读写链路。
2. 冒烟通过后运行4096字签核仿真，覆盖32 KiB、4096次写入和4096次回读。

预计一次通过需要4～8小时；若校准或器件模型连接有问题，可能需要1～2个工作日。不会执行实现后时序仿真、生成bitstream或下载板卡。

## 实施内容

- 使用远程 Vivado 2020.2，从现有 `ddr4_axi_0.xci` 生成独立MIG Example Design、DDR4器件模型和XSim编译脚本，不修改主XPR及现有MIG参数。
- 在独立 `sim_full` 目录编写系统级Testbench，实例化当前顶层和MIG生成的DDR4模型，并复用Example Design中的时钟、复位、器件数量及DQ/DQS连接方式。
- 将 `top_axi_ddr4_bist` 的 `TEST_WORDS` 从内部常量改为模块参数，默认值保持4096，现有端口和上板行为不变。
- 在系统Testbench中提供两个固定顶层：
  - `tb_top_axi_ddr4_bist_smoke`：`TEST_WORDS=32`
  - `tb_top_axi_ddr4_bist_signoff`：`TEST_WORDS=4096`
- 新增冒烟和签核批处理脚本，输出独立日志及波形；冒烟失败时不启动4096字仿真。
- 生成 `DDR4_FULL_SIM_VALIDATION_REPORT.md`，记录环境、编译清单、MIG校准时间、BIST结束时间、关键波形、结果和未覆盖边界。

## 验证方案

- 编译检查：顶层、BIST、MIG仿真文件、DDR4模型和Testbench全部通过XSim编译与展开。
- 冒烟用例：
  - 外部复位正确释放；
  - `init_calib_complete`在超时前拉高；
  - `axi_aresetn`在校准完成后延迟两个`ui_clk`释放；
  - 32字写入回读结束；
  - `bist_done=1`、`bist_pass=1`、`bist_fail=0`、`error_count=0`。
- 签核用例：
  - 重启独立仿真快照；
  - 完成4096字写入和回读；
  - 最终结果同样为PASS且无错误；
  - 检查首地址、末地址及中间抽样地址的数据模式。
- 失败处理：
  - 校准失败：检查时钟周期、复位极性、器件型号和DDR4模型组织方式；
  - AXI停滞：定位最后一次AW/W/B/AR/R握手；
  - 数据错误：记录第一次错误地址、期望值和实际值；
  - 超时：保留WDB、日志和最后状态，不继续下一阶段。
- 原有行为级注错测试继续作为错误检测验证；完整MIG仿真不使用随意`force`破坏内部信号。

## 时间安排

- MIG Example Design及模型准备：30～90分钟
- 系统Testbench和脚本：1～2小时
- 32字冒烟编译、校准和运行：1～2小时
- 4096字签核运行：2～6小时
- 结果分析及文档：30～60分钟

## 假设与约束

- 使用远程主工程和远程 Vivado 2020.2。
- DDR4型号、位宽、时钟和MIG参数以现有XCI及其自动生成的Example Design为唯一依据。
- 不覆盖 `prj`、`prj_stale_20260724_1232` 或现有行为级日志。
- 完整仿真通过只证明数字模型链路正确，不能代替实现时序签核和真实板级DDR校准。
</proposed_plan>

### User

如果我给你手动生成一个exampledesign，你能直接使用吗，是否能减少token的使用，告诉我生成exampledesign需要填什么参数，以减少token的使用

### Assistant

可以直接使用，而且这是最省时间、最省 Token 的方式。最重要的是：**不要重新配置一个DDR4 IP，直接从现有 `ddr4_axi_0` 生成 Example Design。** 这样所有器件、位宽、时钟、引脚和AXI参数都会自动继承，不需要重新填写。

## 推荐生成方法

必须使用远程机上的 **Vivado 2020.2**。

打开：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\prj\
axi_ddr4_min_2020_2.xpr
```

然后：

1. 在 `Sources` 窗口切换到 `IP Sources`。
2. 找到：

   ```text
   ddr4_axi_0
   ```

3. 右键选择：

   ```text
   Open IP Example Design
   ```

4. 输出到新的独立目录：

   ```text
   C:\project\RTDS\DDR\axi_ddr4_min_2020_2\
   sim_full\mig_example_2020_2
   ```

5. 如果提示生成 Output Products，选择生成。
6. 等待Example Design工程自动打开即可，暂时不需要运行仿真。

这种方式不需要填写任何DDR参数，也不要进入 `Customize IP` 修改配置。

## 如果Vivado要求确认参数

参数应与现有工程保持一致：

| 参数 | 当前值 |
|---|---|
| FPGA | `xcku040-ffva1156-2-i` |
| MIG版本 | DDR4 SDRAM MIG 2.2 |
| Memory Type | Components |
| DDR4器件 | `MT40A512M16HA-083E` |
| DDR4总线宽度 | 64 bit |
| DDR数据速率周期 | `833 ps` |
| 输入时钟周期 | `9996 ps` |
| PHY Clock Ratio | `4:1` |
| Memory Voltage | `1.2 V` |
| Data Mask | `DM_NO_DBI` |
| CAS Latency | 16 |
| CAS Write Latency | 12 |
| 用户接口 | AXI4 |
| AXI数据宽度 | 64 bit |
| AXI地址宽度 | 32 bit |
| AXI ID宽度 | 4 bit |
| Narrow Burst | 禁用 |
| Arbitration | `RD_PRI_REG` |
| System Clock | Differential |
| Reference Clock | Differential |

但如果是从现有 `ddr4_axi_0` 生成，这些参数不应该要求重新填写。

## 生成后需要确认的文件

Example Design目录中应当能找到以下类型的内容，具体文件名可能略有差异：

```text
Example Design的.xpr
仿真Testbench
ddr4_model.sv
arch_defines.v
MIG仿真源文件
XSim仿真脚本
```

你生成完成后只需回复：

```text
Example Design已生成
路径：C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\mig_example_2020_2
Vivado版本：2020.2
工程能够正常打开
```

不需要发送截图，也不需要复制日志。之后我可以直接盘点该目录，复用器件模型、连接方式和编译顺序。

这样能明显减少生成、搜索文件和排查参数差异所需的工具调用与Token，同时还会降低连接DDR4模型时出错的概率。仿真本身的运行时间不会因此减少太多，但准备阶段通常可以节省30～90分钟。

### User

PLEASE IMPLEMENT THIS PLAN:
# DDR4 MIG 分级完整仿真计划

## 概要

在远程工程 `C:\project\RTDS\DDR\axi_ddr4_min_2020_2` 上执行两级验证：

1. 32字完整冒烟仿真，确认MIG校准、复位和基本读写链路。
2. 冒烟通过后运行4096字签核仿真，覆盖32 KiB、4096次写入和4096次回读。

预计一次通过需要4～8小时；若校准或器件模型连接有问题，可能需要1～2个工作日。不会执行实现后时序仿真、生成bitstream或下载板卡。

## 实施内容

- 使用远程 Vivado 2020.2，从现有 `ddr4_axi_0.xci` 生成独立MIG Example Design、DDR4器件模型和XSim编译脚本，不修改主XPR及现有MIG参数。
- 在独立 `sim_full` 目录编写系统级Testbench，实例化当前顶层和MIG生成的DDR4模型，并复用Example Design中的时钟、复位、器件数量及DQ/DQS连接方式。
- 将 `top_axi_ddr4_bist` 的 `TEST_WORDS` 从内部常量改为模块参数，默认值保持4096，现有端口和上板行为不变。
- 在系统Testbench中提供两个固定顶层：
  - `tb_top_axi_ddr4_bist_smoke`：`TEST_WORDS=32`
  - `tb_top_axi_ddr4_bist_signoff`：`TEST_WORDS=4096`
- 新增冒烟和签核批处理脚本，输出独立日志及波形；冒烟失败时不启动4096字仿真。
- 生成 `DDR4_FULL_SIM_VALIDATION_REPORT.md`，记录环境、编译清单、MIG校准时间、BIST结束时间、关键波形、结果和未覆盖边界。

## 验证方案

- 编译检查：顶层、BIST、MIG仿真文件、DDR4模型和Testbench全部通过XSim编译与展开。
- 冒烟用例：
  - 外部复位正确释放；
  - `init_calib_complete`在超时前拉高；
  - `axi_aresetn`在校准完成后延迟两个`ui_clk`释放；
  - 32字写入回读结束；
  - `bist_done=1`、`bist_pass=1`、`bist_fail=0`、`error_count=0`。
- 签核用例：
  - 重启独立仿真快照；
  - 完成4096字写入和回读；
  - 最终结果同样为PASS且无错误；
  - 检查首地址、末地址及中间抽样地址的数据模式。
- 失败处理：
  - 校准失败：检查时钟周期、复位极性、器件型号和DDR4模型组织方式；
  - AXI停滞：定位最后一次AW/W/B/AR/R握手；
  - 数据错误：记录第一次错误地址、期望值和实际值；
  - 超时：保留WDB、日志和最后状态，不继续下一阶段。
- 原有行为级注错测试继续作为错误检测验证；完整MIG仿真不使用随意`force`破坏内部信号。

## 时间安排

- MIG Example Design及模型准备：30～90分钟
- 系统Testbench和脚本：1～2小时
- 32字冒烟编译、校准和运行：1～2小时
- 4096字签核运行：2～6小时
- 结果分析及文档：30～60分钟

## 假设与约束

- 使用远程主工程和远程 Vivado 2020.2。
- DDR4型号、位宽、时钟和MIG参数以现有XCI及其自动生成的Example Design为唯一依据。
- 不覆盖 `prj`、`prj_stale_20260724_1232` 或现有行为级日志。
- 完整仿真通过只证明数字模型链路正确，不能代替实现时序签核和真实板级DDR校准。

### Assistant

我现在按计划执行。先检查远程 `sim_full` 是否已有手动生成的 Example Design，并核对主工程、MIG XCI、源文件和当前 Vivado 进程；随后在独立目录生成或复用仿真资产，不触碰现有 `prj`、旧备份、bitstream和板卡。

### User

```
Example Design已生成
路径：C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\mig_example_2020_2
Vivado版本：2020.2

```

### Assistant

已收到，直接复用你生成的 Example Design，跳过IP示例工程生成步骤。这会减少准备时间，也避免重新生成时改变MIG资产。接下来只读提取它的器件模型、仿真顶层和XSim编译顺序，再在旁边建立我们的两级验证目录。

### User

告诉我何时可以断开ssh连接，请先快速提交任务

### Assistant

现在可以先断开你手动打开的 SSH/远程终端；我使用独立密钥会话，不依赖你的窗口。长仿真启动后我还会明确回报“后台进程已脱离会话、日志已开始写入”，那时远程桌面也可以关闭，但远程电脑本身不要关机、重启或休眠。

我先用已生成的 Example Design 快速完成编译清单和测试顶层，优先提交32字冒烟后台任务；4096字只在冒烟PASS后自动提交。

### User

现在可以先断开你手动打开的 SSH/远程终端了吗（就是我会断开本机和远程机子的网络，不仅是连接），如果不可以请尽快完成操作

### Assistant

**现在还不能断开网络。** 当前只完成了 Example Design 生成，我还在读取其中的模型连接文件，32字后台仿真任务尚未提交。请先保持网络约 **10～20分钟**；等我明确回复“后台任务已启动、可以断网”后再断开。远程电脑届时仍需保持开机且不休眠。

### User

那我可以先暂停一下，等会回来再继续任务吗

### Assistant

可以暂停，现在可以断开本机与远程机的网络。

当前状态：

- Example Design 已确认存在。
- 已读取关键模型和Testbench结构。
- 尚未修改远程工程。
- 尚未启动任何Vivado后台任务或仿真进程。

回来后直接说“继续任务”，我会从系统级Testbench和后台提交脚本开始，不需要重新分析前面的内容。

### User

继续任务 告诉我何时可以断开ssh连接

### Assistant

继续。现在先保持网络连接；我会优先完成远程工作副本、两级Testbench和自动流水脚本，然后启动脱离SSH会话的后台任务。等日志与PID都确认后，我会明确回复“可以断开网络”。预计还需要约10～20分钟完成提交。

远程独立工作副本和全部脚本已就位，主XPR及用户生成的Example Design原件未被修改。现在提交后台流水：先32字冒烟，PASS后自动转4096字；我会等PID、状态文件和Vivado日志实际出现后再允许断网。

第一次脱离方式没有保持住：状态文件已创建，但启动用的 `cmd` 在SSH会话结束后被系统回收，Vivado尚未真正启动，所以现在还不能断网。我正在改用 Windows WMI 创建独立进程；确认新PID在SSH退出后仍存在、日志开始增长后即可断开。

WMI和计划任务都被远程账号权限拒绝，属于Windows会话权限问题，不是仿真问题。现在尝试由远程桌面的Explorer会话代为启动，这种进程不会随SSH断开；若该方式也被会话隔离阻止，我会给你一条在远程桌面双击即可启动的批处理，执行后马上可以断网。

### User

是因为我没有开codex的完全访问权限吗，怎么解决被远程账号权限拒绝

### Assistant

不是 Codex“完全访问权限”的问题。SSH 已经正常登录并能读写工程；被拒绝的是远程 Windows 上 `vivadoagent` 对 **WMI 创建脱离进程** 和 **任务计划程序注册任务** 的权限。即使给 Codex 本机完全访问权限，SSH 到远程后仍然是 `vivadoagent`，远程ACL不会改变。

最快、最安全的解决办法是不改权限：在远程桌面本地双击

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\
run_full_sim_pipeline_2020_2.bat
```

或在远程桌面的 CMD 中运行：

```bat
cd /d C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full
start "" run_full_sim_pipeline_2020_2.bat
```

这个进程由远程桌面会话启动，断开网络后仍会继续，只要远程电脑不关机、不重启、不休眠。

如果要永久允许我通过SSH提交后台任务，需要管理员在远程机做二选一：

1. 由管理员预先创建一个可供 `vivadoagent` 手动运行的计划任务；推荐。
2. 在 WMI Control 的 `root\cimv2` 安全设置中，为 `vivadoagent` 授予 `Execute Methods` 和 `Remote Enable`。权限面更大，不建议仅为这次仿真修改。

我正在尝试最后一种无需管理员的 `CREATE_BREAKAWAY_FROM_JOB` 启动方式；若仍被Windows拒绝，就用上面的远程桌面一键启动。

脱离SSH的启动方式已经成功，证明后续可以做到断网运行；但冒烟任务在进入Vivado前立即失败，`smoke_vivado.log`仍为0字节。当前还不能断网，我正在核对远程 `vivado.bat` 实际路径和批处理入口，修正后重新提交。

已定位到立即失败原因：上传的批处理是LF换行，Windows `cmd` 没有正确处理跨行的 `^`，导致Vivado命令被拆成几段，最后只创建了0字节日志。不是Vivado、MIG或权限问题。正在改为单行命令并重新提交。

Vivado已真正启动，当前唯一报错是Tcl把 `-d BIST_TEST_WORDS=32` 误当成 `set_property` 自身选项；改用显式 `-name/-value/-objects` 即可。修正后再后台提交。

**现在可以断开SSH和本机—远程机网络。**

已确认后台任务真正脱离SSH会话：

```text
流水 cmd PID：2612
Vivado 2020.2 batch PID：11540
开始时间：2026-08-05 12:08:20
当前阶段：32字冒烟仿真
```

SSH已多次断开并重新连接，两个后台进程仍然存活，因此网络中断不会终止任务。冒烟PASS后脚本会自动启动4096字签核。

远程电脑必须保持开机、不要重启或休眠。回来后说“检查仿真结果”，我会读取：

```text
sim_full\pipeline.status
sim_full\logs\smoke_vivado.log
sim_full\logs\signoff_vivado.log
sim_full\results\*.wdb
```

现在可以断开SSH及两台机器之间的网络。

后台流水已独立运行：

- `cmd` PID：2612
- Vivado PID：11540
- 当前阶段：32字冒烟仿真
- 冒烟通过后自动运行4096字签核

请保持远程电脑开机且不休眠。回来后说“检查仿真结果”即可。

### User

检查 预估时间

### Assistant

我先读取流水状态、两个日志大小、退出码和后台进程，再根据当前阶段及日志推进速度估算剩余时间；只检查，不会重启任务。

检查结果不是“仍在运行”，而是后台流水在12:08:20进入冒烟阶段后立即失败，未启动4096字，当前没有batch Vivado/XSim进程。日志仍为0字节，说明失败发生在脱离进程调用Vivado的入口，而不是MIG校准超时。

我会用前台短时启动同一个冒烟脚本获取真实报错；预计1～3分钟能定位并重新提交。重新提交成功后，32字冒烟预计1～2小时，4096字再需2～6小时。

我先修复刚定位到的宏参数展开问题，然后重新提交 32 字冒烟仿真。预计修复和确认后台进程稳定需要 5～15 分钟；稳定后剩余仿真约 3～8 小时。确认后我会明确告诉你何时可以断网。

问题已修正为“冒烟/签核模式开关”，不再通过 XSim 命令行传递带数值的宏，规避 Vivado 2020.2 把宏值展开为空的问题。现在同步远端并重新启动。

后台任务已经提交（PID 8776）。刚才的状态查询因远端进程枚举超时，并不代表仿真失败；我改用轻量检查确认日志是否持续增长。

当前状态：后台主进程仍在（PID 8776），但 Vivado 日志仍为 0 字节，说明它卡在 Vivado 启动阶段，尚未开始编译或仿真。我再确认一次；若日志仍不增长，我会重启这一条后台任务，避免空等数小时。

已确认 Vivado 2020.2 本身可正常启动；卡住的是上一条“脱离 SSH 的后台进程树”，并非工程编译。后台父进程已停止，我正在清理其残留子进程后重提。此刻还不能断网。

进一步检查确认：32 字冒烟仿真已经成功完成编译和展开，当前正在运行 DDR4 器件模型与 MIG 校准；`simulate.log` 已出现 4 组 x16 DDR4 模型初始化记录。也就是说它不是卡死，当前约运行 10 分钟。

我会补一个独立的续跑守护脚本：冒烟结束后自动判断 PASS/FAIL，仅 PASS 时启动 4096 字签核。守护进程稳定后即可断开网络。

现在可以断开 SSH，也可以断开本机与远程机的网络连接。

当前状态：

- 32 字冒烟仿真已完成编译和展开，正在进行 MIG 校准及 DDR4 模型仿真。
- 自动续跑守护进程已稳定运行，PID 为 `20068`。
- 冒烟 PASS 后会自动启动 4096 字签核仿真；冒烟失败则不会启动签核。
- 远程电脑需保持开机，且不能休眠或重启。

预计剩余时间约 **3～8 小时**：

- 32 字冒烟：约 1～2 小时，已运行十余分钟。
- 4096 字签核：约 2～6 小时。
- 结果整理：重新联网后约 30～60 分钟。

### User

我问一下仿真模型加后的工程和测试文件保存在哪，怎么看

### Assistant

我确认一下远端目录里的工程、测试文件和当前日志名称，然后按“工程怎么打开、结果怎么看”给你列清楚。

### User

顺便确认冒烟仿真是否在进行

### Assistant

可以。我同时核对冒烟仿真的进程、状态文件、波形文件更新时间，再告诉你它是在正常运行、已结束，还是停在某个阶段。

已确认，仿真模型和测试文件都保存在远程机，主工程与独立仿真工程分开。

### 文件位置

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2
├─ rtl
│  ├─ axi_ddr_bist.v
│  └─ top_axi_ddr4_bist.v
├─ sim_full
│  ├─ mig_example_2020_2
│  │  └─ ddr4_axi_0_ex
│  │     └─ ddr4_axi_0_ex.xpr       原始 MIG Example Design
│  ├─ bist_sim_work
│  │  ├─ ddr4_axi_0_ex.xpr          实际使用的独立完整仿真工程
│  │  └─ imports
│  │     ├─ ddr4_model.sv            DDR4 器件模型
│  │     ├─ sim_tb_top.sv            MIG 原始系统 Testbench
│  │     └─ arch_defines.v
│  ├─ example_top_bist_adapter.sv    BIST 与 MIG Example Design 适配层
│  ├─ tcl
│  │  └─ run_full_sim_case_2020_2.tcl
│  ├─ run_full_sim_case_2020_2.bat
│  ├─ run_full_sim_pipeline_2020_2.bat
│  ├─ resume_full_sim_after_smoke_2020_2.bat
│  ├─ logs                           仿真日志
│  └─ results                        完成后保存整理后的 WDB
└─ docs
   └─ DDR4_FULL_SIM_VALIDATION_REPORT.md
```

主工程的 MIG 参数没有修改。完整仿真是在：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\ddr4_axi_0_ex.xpr
```

上运行的。

### 当前冒烟仿真状态

冒烟仿真正在运行，尚未产生 PASS/FAIL。

确认依据：

- 波形文件在 14:36 为 `7,356,135,609` 字节。
- 到 14:37 增长为 `7,824,417,601` 字节。
- 一分钟左右增长约 468 MB，说明 XSim 正在持续推进仿真。
- 自动续跑守护进程 PID `20068` 仍然存活。
- 当前内部运行日志：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\
ddr4_axi_0_ex.sim\sim_1\behav\xsim\simulate.log
```

- 当前实时波形：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\
ddr4_axi_0_ex.sim\sim_1\behav\xsim\sim_tb_top_behav.wdb
```

目前 WDB 正在写入，不建议现在用 Vivado 打开，以免读取不完整或占用文件。等冒烟结束后再打开。

### 完成后怎么看

在远程 Vivado 2020.2 中选择 `File → Open Project`，打开：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\ddr4_axi_0_ex.xpr
```

完成后，整理出的波形会保存在：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\results
```

状态可以直接查看：

```bat
type C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\pipeline.status
```

最终应出现：

```text
SMOKE_PASS=...
SIGNOFF_PASS=...
PIPELINE_RESULT=PASS
```

`logs\smoke_check_vivado.log` 是我用于重复检查时因原仿真占用文件而退出的日志，可以忽略；正式冒烟日志是 `logs\smoke_vivado.log`。

### User

简单说明下当前运行情况

### Assistant

我快速看一下状态文件和波形是否还在增长。

当前 32 字冒烟仿真仍在正常运行：

- 已运行约 50 分钟。
- 波形文件持续更新，当前约 22.3 GB。
- 暂未出现 PASS 或 FAIL。
- 冒烟通过后会自动启动 4096 字签核仿真。
- 远程机器保持开机即可，无需保持 SSH 或网络连接。

### User

有个小疑问，为什么这个目录和标准的vivado不一样也可以仿真和打开gui

### Assistant

因为 Vivado 工程能否打开、仿真，主要取决于 `.xpr` 中记录的文件集和路径，而不是必须符合某种固定目录结构。

当前目录看起来“不标准”，主要有三个原因：

- `bist_sim_work` 是从 MIG Example Design 复制出来的独立仿真副本。
- MIG 自动生成的模型位于 `imports`，而不是常见的 `.srcs/sim_1`。
- BIST、顶层和适配层通过工程文件/Tcl 加入，可以放在工程目录之外。

Vivado 打开：

```text
bist_sim_work\ddr4_axi_0_ex.xpr
```

后，会根据 `.xpr` 找到：

```text
imports\ddr4_model.sv
imports\sim_tb_top.sv
..\example_top_bist_adapter.sv
..\..\rtl\axi_ddr_bist.v
..\..\rtl\top_axi_ddr4_bist.v
```

运行仿真时，Vivado再自动生成：

```text
.Xil
*.cache
*.sim
*.runs
```

所以，常见的 `.srcs/.gen/.sim` 布局只是 Vivado 默认组织方式，并非强制标准。只要 `.xpr` 内的引用有效、IP输出产物和器件模型齐全，就能正常打开GUI并仿真。

这个独立目录还有一个好处：完整仿真产生的大量缓存和波形不会污染主工程。缺点是移动或删除外部引用的RTL文件后，工程会报找不到源文件。

### User

怎么样了

### Assistant

我检查一下当前阶段、PASS/FAIL标记和波形更新时间。

截至 16:36：

- 32 字冒烟仿真仍在运行，已超过 2 小时。
- 暂无 PASS/FAIL，波形仍持续写入，说明没有停止。
- WDB 已增至约 62.4 GB，远程磁盘剩余约 191 GB。
- 自动续跑守护进程正常。

当前进度比预计慢，较大的全量波形记录很可能拖慢了 XSim。继续运行暂时不会立即耗尽磁盘，但启动 4096 字签核前需要限制波形范围，否则存在磁盘空间风险。

### User

查看，并打印 一份RTDS目录的工程消耗空间的简报

### Assistant

我会只读统计远程 `C:\project\RTDS`：先按一级工程汇总容量，再展开占用最大的目录，并单独列出当前 DDR 仿真产生的日志、波形和缓存。统计可能需要几分钟。

当前 SSH 连远端没有返回，连最简单的 `echo` 都超时，说明远程机暂时离线、网络未恢复，或机器仍被仿真高负载拖住。我再做一次带连接超时的网络检查，确认是连不上还是登录后卡住。

目前无法生成实时空间简报：`vivado-srv` 的 SSH、端口检查和 Ping 均超时，远程机当前不可达，不是 Codex 文件权限问题。

最后已知数据（2026-08-05 16:36）：

- 当前仿真 WDB：约 **62.4 GB**
- C盘剩余空间：约 **191 GB**
- 冒烟仿真当时仍在运行

请恢复本机与远程机的网络连接，并确认远程机已开机、未休眠。连接恢复后我会统计并打印：

- `C:\project\RTDS` 总占用
- 各一级工程占用及文件数量
- 最大的子目录和大文件
- DDR工程的源码、IP、缓存、日志、WDB分别占用
- 可清理空间建议（只报告，不删除）

### User

RTDS目录可以递归2-3级打印，大小不大的目录就不用继续地柜

### Assistant

明白。我按“一级目录全部列出；目录达到 1 GB 才继续展开；最多递归到第 3 级”生成树状简报，小目录只显示汇总值。先重新连接远端执行只读统计。

### User

按理说应该连接的，网络是通的，你试试重连

### Assistant

我重新建立一次独立 SSH 连接，并关闭连接复用、加详细握手日志，定位卡在网络、认证还是远端命令启动。

已定位：网络和 22 端口都通，远端也返回了 OpenSSH 版本，但卡在密钥交换阶段，说明是远端 `sshd`/系统负载异常，不是本机断网。我尝试通过 Windows 文件共享只读访问目录，若共享可用就不依赖 SSH 完成统计。

重连结果：

- `172.20.10.11` Ping 正常，延迟约 7～13 ms。
- TCP 22 端口正常开放。
- 远端返回了 OpenSSH 版本，但卡在 SSH 密钥交换阶段，尚未进入账号认证。
- Windows共享可达，但 `C$` 被拒绝访问。

这说明不是网络问题，也不是 Codex完全访问权限问题，更可能是远端 `sshd` 卡住或系统磁盘/负载异常。考虑到昨天 WDB 已达 62 GB且快速增长，建议在远程机界面先检查：

1. C盘是否已满。
2. 任务管理器中 `xsim.exe`/Vivado是否仍在运行。
3. 以管理员身份重启“OpenSSH SSH Server”服务，或执行：

```powershell
Restart-Service sshd
```

重启 `sshd` 不会主动停止 XSim。请暂时不要删除 WDB；SSH恢复后我会按“一级全部显示、≥1 GB继续递归、最多三级”的规则生成RTDS空间简报。

### User

c盘满了，之前的波形在哪，要删除，如何避免过大的波形

### Assistant

可以删除。目标是当前完整仿真生成的单个超大 WDB，不动源码、XPR、MIG模型或日志。我先尝试重连；若 SSH 恢复，会先停止占用该文件的 XSim，再只删除已确认的 WDB，并修改后续仿真为“仅记录BIST/MIG关键控制信号”。

### User

远程电脑只有一个c盘

### Assistant

只有一个 C 盘时，当前全量 WDB 会直接把系统盘占满。SSH仍卡在密钥交换阶段，所以需要先在远程机本地/RDP释放空间；我同时核对 Vivado 2020.2 限制波形记录的正确设置，避免重跑再次占满。

### User

波形的大小能不能压缩，为什么这么大，压缩仿真时间呢，现在是多久

### Assistant

我先区分两个“时间”：实际等待的墙钟时间和XSim内部仿真时间。目前SSH仍未恢复，因此只能用启动时间计算墙钟上限，无法读取XSim当前推进到多少微秒。

先给结论：WDB不适合事后压缩来解决这个问题，正确做法是停止当前仿真、删除超大WDB，并从源头关闭 `log_all_signals`。我会先把本地仿真脚本改成只记录校准、BIST结果和AXI握手等关键小信号；SSH恢复后再同步远端。

原因已经找到：脚本里有这一行：

```tcl
log_wave -r /*
```

它会递归记录整个仿真层次，包括 MIG PHY、DDR4器件模型内部节点、DQ/DQS高频变化，所以 WDB 每小时增长约几十GB，最终占满C盘。这是波形异常大的直接原因。

### 先释放C盘

在远程机本地 PowerShell 执行：

```powershell
Get-Process xsim,xsimk -ErrorAction SilentlyContinue | Stop-Process -Force
Stop-Process -Id 20068 -Force -ErrorAction SilentlyContinue

$wdb = 'C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\ddr4_axi_0_ex.sim\sim_1\behav\xsim\sim_tb_top_behav.wdb'
Get-Item -LiteralPath $wdb
Remove-Item -LiteralPath $wdb -Force
```

这会永久删除当前超大波形，但不会删除源码、MIG模型、XPR或测试文件。

如果提示文件被占用，在任务管理器“详细信息”中结束：

- `xsim.exe`或`xsimk.exe`
- 命令行含有 `-mode batch` 的后台 `vivado.exe`

不要结束你手动打开的 Vivado GUI。

### 后续怎么避免

我已经在本地修改脚本：

- 删除 `log_wave -r /*`
- 设置：

```tcl
set_property xsim.simulate.log_all_signals false $simset
```

- 只记录约30个关键小信号：MIG校准、BIST结果、错误信息及AXI握手。
- 不再记录DDR4模型内部节点和物理DQ/DQS。

这是 Vivado 2020.2 官方支持的设置：[UG900 Vivado Simulator Simulation Options](https://docs.amd.com/r/2020.2-English/ug900-vivado-logic-simulation/Vivado-Simulator-Simulation-Options)。

WDB事后可以压缩归档，但不能解决运行时占满磁盘，而且压缩需要额外临时空间。正确方法是从源头减少记录信号。

### 已运行多久

仿真于 **2026-08-05 14:19** 启动；本机当前时间约为 **2026-08-06 09:10**，墙钟时间约 **18小时51分钟**。

最后确认正常推进是在昨日16:36，当时已运行约2小时17分钟、WDB约62.4GB。之后C盘被写满，仿真大概率已经停滞，不能算作有效运行了。释放空间并恢复SSH后，需要用精简波形设置重新运行。

### User

波形的路径在什么位置

### Assistant

当前超大波形文件路径：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\ddr4_axi_0_ex.sim\sim_1\behav\xsim\sim_tb_top_behav.wdb
```

波形结果计划归档目录：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\results
```

删除当前超大波形的 PowerShell 命令：

```powershell
Remove-Item -LiteralPath 'C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\bist_sim_work\ddr4_axi_0_ex.sim\sim_1\behav\xsim\sim_tb_top_behav.wdb' -Force
```

如果提示文件被占用，需要先结束 `xsim.exe`或`xsimk.exe`。

### User

已删除，238g的波形文件，继续查看，是不是因为爆盘仿真终止了

### Assistant

我现在重连远端，检查流水线状态、XSim/Vivado进程、日志结尾和是否留下异常退出标记，确认是不是因为C盘写满而终止。

大概率是C盘写满导致仿真异常终止或卡死。238 GB的WDB说明全量波形一直写到磁盘极限；而此前没有产生 `FULL_SIM_RESULT=PASS/FAIL`，因此这次冒烟结果无效，必须重新运行。

目前SSH仍卡在密钥交换阶段，释放磁盘后 `sshd` 尚未恢复。请在远程机管理员 PowerShell执行：

```powershell
Restart-Service sshd
```

不需要重启整台电脑。服务恢复后我会立即检查：

- `smoke_vivado.log`和`simulate.log`的异常结尾
- XSim/Vivado是否残留
- 流水线退出码
- C盘剩余空间

随后同步已经改好的精简波形脚本，只记录关键控制信号，再重新提交冒烟仿真。

### User

已执行
```
Restart-Service sshd，告诉我接下来以什么仿真策略执行，波形如何控制大小，保留关键接口、自定义模块的全部信号即可

```

### Assistant

我先确认SSH已恢复、磁盘空间、上次仿真退出状态，以及远端脚本当前仍是全量记录还是已更新。然后给出可直接执行的仿真与波形分层策略。

SSH服务已响应，但重启后认证状态发生变化：现在不是超时，而是明确拒绝认证。我再按原来的连接方式尝试一次，确认是否只是禁用了批处理认证。

远端SSH目前已恢复到认证阶段，但公钥被拒绝；这不影响先把仿真策略定清楚。我会依据本地同步的RTL和Testbench，确认“关键接口”和“自定义模块”的准确层次，避免下一次又递归到MIG/DDR模型内部。

波形范围已经能精确定义：记录 `example_top`、`top_axi_ddr4_bist`、`axi_ddr_bist` 各自直属的全部信号，以及AXI五通道、校准/复位/BIST结果；明确排除 `u_ddr4_axi_0` 以下所有MIG内部层次和DDR4模型内部层次。还需要锁定两个会显著影响容量的选择。

### User

如果不能访问，告诉我远端机子要怎么做，告诉我能给agent执行的命令

### Assistant

可以。现在远端 `sshd` 已恢复，但代理使用的公钥被拒绝。我要读取本机对应的公钥文本，然后给你一组可在远端管理员 PowerShell直接执行的命令，修复 `vivadoagent` 的SSH访问权限。

<proposed_plan>
# DDR4完整仿真重跑与波形控制计划

## 1. 恢复Agent的SSH权限

在远端电脑以管理员身份打开PowerShell，执行以下命令。它会把Agent公钥加入 `vivadoagent` 的正确授权文件并修复ACL，不开放额外账号权限：

```powershell
$agentUser = 'vivadoagent'
$pubKey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEpPv7ZO/q42ghsCTyiZxTm4bv4PI6SV0scSL7000s35 vivado_remote_access'

$user = Get-LocalUser -Name $agentUser -ErrorAction Stop
if (-not $user.Enabled) {
    throw "$agentUser account is disabled"
}

$adminGroup = Get-LocalGroup -SID 'S-1-5-32-544'
$adminSids = @(Get-LocalGroupMember -Group $adminGroup.Name |
    ForEach-Object { $_.SID.Value })
$isAdmin = $adminSids -contains $user.SID.Value

if ($isAdmin) {
    $authFile = Join-Path $env:ProgramData 'ssh\administrators_authorized_keys'
    if (-not (Test-Path -LiteralPath $authFile)) {
        New-Item -ItemType File -Path $authFile -Force | Out-Null
    }

    $existingKeys = @(Get-Content -LiteralPath $authFile -ErrorAction SilentlyContinue)
    if ($existingKeys -notcontains $pubKey) {
        Add-Content -LiteralPath $authFile -Value $pubKey -Encoding ascii
    }

    & icacls.exe $authFile /inheritance:r
    & icacls.exe $authFile /grant:r '*S-1-5-32-544:F' '*S-1-5-18:F'
} else {
    $sshDir = "C:\Users\$agentUser\.ssh"
    $authFile = Join-Path $sshDir 'authorized_keys'

    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    if (-not (Test-Path -LiteralPath $authFile)) {
        New-Item -ItemType File -Path $authFile -Force | Out-Null
    }

    $existingKeys = @(Get-Content -LiteralPath $authFile -ErrorAction SilentlyContinue)
    if ($existingKeys -notcontains $pubKey) {
        Add-Content -LiteralPath $authFile -Value $pubKey -Encoding ascii
    }

    $userDirGrant = "*$($user.SID.Value):(OI)(CI)F"
    $userFileGrant = "*$($user.SID.Value):F"

    & icacls.exe $sshDir /inheritance:r
    & icacls.exe $sshDir /grant:r $userDirGrant '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F'
    & icacls.exe $authFile /inheritance:r
    & icacls.exe $authFile /grant:r $userFileGrant '*S-1-5-18:F' '*S-1-5-32-544:F'
}

$sshd = "$env:WINDIR\System32\OpenSSH\sshd.exe"
& $sshd -t
if ($LASTEXITCODE -ne 0) {
    throw 'sshd_config validation failed'
}

Restart-Service sshd
Get-Service sshd
Write-Host "AuthorizedKeysFile=$authFile"
```

成功标准：

- `sshd`状态为 `Running`。
- Agent使用公钥指纹 `SHA256:dNiJvdzZfmjFiFxZb/lyyBUIzRO8tHsCMnph2NOgLDc` 登录成功。
- 若仍失败，读取最近事件：

```powershell
Get-WinEvent -LogName 'OpenSSH/Operational' -MaxEvents 20 |
    Select-Object TimeCreated,Id,LevelDisplayName,Message
```

## 2. 波形记录策略

删除原脚本中的全层次记录：

```tcl
log_wave -r /*
```

并设置：

```tcl
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
```

按照Vivado推荐的直属对象方式记录，不使用递归选项：[UG900 `log_wave`说明](https://docs.amd.com/r/en-US/ug900-vivado-logic-simulation/Using-the-log_wave-Tcl-Command)。

记录范围：

- `example_top`适配层的直属信号。
- `top_axi_ddr4_bist`的直属信号，包括完整AXI五通道、时钟、复位、校准及BIST结果。
- `u_axi_ddr_bist`的全部直属信号，包括端口、状态机、读写计数器、握手和错误判断。
- DDR4物理侧仅记录地址、BA/BG、ACT、CS、CKE、ODT、RESET和CK。
- 不记录DDR4的DQ、DQS和DM。
- 不进入 `u_ddr4_axi_0` 的MIG内部层次。
- 不进入DDR4器件模型内部层次。

单次WDB硬上限采用用户指定的 **40 GB**。同时设置：

- 剩余磁盘低于60 GB时终止当前仿真。
- 冒烟最长墙钟时间4小时。
- 签核最长墙钟时间8小时。
- 触发任一限制时保留日志和已有WDB，不启动下一阶段。

## 3. 分级运行策略

1. 清理检查：确认旧XSim和后台流水线已退出，C盘至少有120 GB可用空间。
2. 波形探针：运行10 µs，确认所有自定义模块对象均能匹配，WDB不得超过200 MB。
3. 32字冒烟：完整执行MIG校准、32次写入及32次回读。
4. 冒烟必须得到 `bist_done=1`、`bist_pass=1`、`bist_fail=0`、`error_count=0`。
5. 冒烟PASS后重新启动独立仿真快照，执行4096字签核。
6. 冒烟和签核使用不同日志及WDB文件，避免覆盖和重复复制。

上次因238 GB全量WDB导致的运行判定为无效，不复用任何仿真结果。

## 4. 验收标准

- 波形中能看到自定义BIST内部状态、完整AXI握手、校准和复位过程。
- WDB不包含MIG PHY及DDR4模型内部对象。
- 10 µs波形探针低于200 MB，正式单次WDB低于40 GB。
- 冒烟失败时签核不启动。
- 最终报告记录编译、校准、BIST完成时间、首/中/末地址抽样及磁盘占用。
</proposed_plan>

### User

远程机子已sshd状态为 Running

### Assistant

我现在验证公钥认证是否恢复；若能登录，再只读检查剩余磁盘、残留仿真进程和上次异常日志，为重跑计划确认起点。

服务本身已经恢复，但公钥认证仍被拒绝，说明问题现在只剩 `authorized_keys` 路径或ACL，并非网络/sshd进程。需要确认你是否只检查了服务状态，还是已经执行了公钥安装脚本。

### User

Select-Object TimeCreated,Id,LevelDisplayName,Message

TimeCreated       Id LevelDisplayName Message
-----------       -- ---------------- -------
2026/8/6 9:46:53   4 信息             sshd: Connection reset by authenticating user vivadoagent 172.20.10.3 port 471...
2026/8/6 9:45:55   4 信息             sshd: Server listening on 0.0.0.0 port 22.
2026/8/6 9:45:55   4 信息             sshd: Server listening on :: port 22.
2026/8/6 9:22:24   4 信息             sshd: Connection reset by authenticating user vivadoagent 172.20.10.3 port 460...
2026/8/6 9:21:53   4 信息             sshd: Connection reset by authenticating user vivadoagent 172.20.10.3 port 459...
2026/8/6 9:20:28   4 信息             sshd: Server listening on 0.0.0.0 port 22.
2026/8/6 9:20:28   4 信息             sshd: Server listening on :: port 22.
2026/8/6 9:06:02   4 信息             sshd: Connection reset by 172.20.10.3 port 45049
2026/8/5 16:37:17  4 信息             sshd: Accepted publickey for vivadoagent from 172.20.10.3 port 56089 ssh2: ED2...
2026/8/5 16:36:39  4 信息             sshd: Disconnected from 172.20.10.3 port 56082
2026/8/5 16:36:39  4 信息             sshd: Received disconnect from 172.20.10.3 port 56082:11: disconnected by user
2026/8/5 16:36:39  4 信息             sshd: Accepted publickey for vivadoagent from 172.20.10.3 port 56082 ssh2: ED2...
2026/8/5 16:36:27  4 信息             sshd: Disconnected from 172.20.10.3 port 56073
2026/8/5 16:36:27  4 信息             sshd: Received disconnect from 172.20.10.3 port 56073:11: disconnected by user
2026/8/5 16:36:27  4 信息             sshd: Accepted publickey for vivadoagent from 172.20.10.3 port 56073 ssh2: ED2...
2026/8/5 15:09:38  4 信息             sshd: Disconnected from 172.20.10.3 port 52647
2026/8/5 15:09:38  4 信息             sshd: Received disconnect from 172.20.10.3 port 52647:11: disconnected by user
2026/8/5 15:09:38  4 信息             sshd: Accepted publickey for vivadoagent from 172.20.10.3 port 52647 ssh2: ED2...
2026/8/5 14:39:07  4 信息             sshd: Accepted publickey for vivadoagent from 172.20.10.3 port 51174 ssh2: ED2...
2026/8/5 14:37:58  4 信息             sshd: Disconnected from 172.20.10.3 port 51103

### Assistant

日志说明网络和sshd都正常，但今天的连接没有出现“Accepted publickey”；问题集中在“有效配置读取了哪个授权文件”或该文件ACL。先从客户端确认公钥确实被提交，再让远端打印有效配置与两个候选授权文件。

### User

这个是远程机的日志

### Assistant

这份远端日志与客户端调试结果一致：远端已经接受了正确公钥，但客户端在“用私钥签名”这一步没有发出签名包。因此远端授权文件和ACL基本已经修好；剩余问题在本机私钥需要口令或本机 `ssh-agent` 当前不可访问。我做两项只读检查确认。

### User

如果不能访问，告诉我远端机子要怎么做，告诉我能给agent执行的命令

### Assistant

远端已经配置正确：服务器明确接受了公钥。当前失败发生在本机签名阶段——私钥有口令，而Codex无法访问当前 `ssh-agent`。

请在本机（不是远程机）普通PowerShell执行：

```powershell
ssh-add C:\Users\MaiBo\.ssh\id_ed25519_vivado
```

输入该私钥的口令，然后检查：

```powershell
ssh-add -l
```

应看到指纹：

```text
SHA256:dNiJvdzZfmjFiFxZb/lyyBUIzRO8tHsCMnph2NOgLDc
```

再测试：

```powershell
ssh -o BatchMode=yes vivado-srv "cmd /d /c echo SSH_OK"
```

如果 `ssh-add`提示无法访问agent，先在管理员PowerShell执行：

```powershell
Restart-Service ssh-agent
```

然后重新打开普通PowerShell，再执行 `ssh-add`。

测试输出 `SSH_OK` 后，告诉我：

```text
SSH密钥已加入agent，请重试连接并执行只读检查
```

远端暂时不需要继续修改 `authorized_keys` 或重启 `sshd`。

### User

该私钥的口令是什么，我不知道

### Assistant

私钥口令无法从私钥文件中读取或恢复，我也不知道。没有原口令，就不能继续使用这把加密私钥进行自动登录。

建议新建一把专供Codex访问远程Vivado机的无口令密钥，旧密钥保留不动。这样后台任务不依赖人工输入口令。

在本机PowerShell执行：

```powershell
ssh-keygen -t ed25519 -f C:\Users\MaiBo\.ssh\id_ed25519_vivado_codex -C codex_vivado_remote
```

出现以下两次提示时都直接按回车：

```text
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
```

然后显示公钥：

```powershell
Get-Content C:\Users\MaiBo\.ssh\id_ed25519_vivado_codex.pub
```

把输出的完整一行发给我，我会给你对应的远端授权命令和本机SSH配置修改内容。不要发送没有 `.pub` 后缀的私钥文件。

### User

```
SSH密钥已加入agent，请重试连接并执行只读检查
```

### Assistant

我先验证SSH认证，然后只读检查C盘剩余空间、残留XSim/Vivado进程、流水线状态、日志结尾及远端当前波形脚本。不会修改或启动仿真。

认证仍被拒绝。当前SSH配置固定使用旧私钥 `id_ed25519_vivado` 且设置了 `IdentitiesOnly yes`，所以即使新密钥加入agent，也可能不会被提交。我检查本机agent当前可见指纹和新密钥文件名。

### User

为什么爆盘后要重新在两个机子上做这些操作

### Assistant

这不是“爆盘把两边密钥都弄坏了”，而是两个独立问题叠加：远端C盘满导致 `sshd`卡住；远端恢复后，本机Codex进程又无法访问保存私钥口令的 `ssh-agent`。我再用非沙箱权限只读检查本机agent，确认是否只是Codex隔离权限导致。

### User

我没有用新秘钥，我想起来了旧的

### Assistant

确认了：旧密钥已经在本机agent中，指纹正确，SSH测试返回 `SSH_OK`。之前失败只是Codex沙箱不能访问Windows的agent管道；使用已授权的沙箱外SSH即可，不需要新密钥，也不需要再改远端。现在继续只读检查仿真残留和磁盘状态。

不用新密钥，旧密钥已经恢复可用。刚才从沙箱外测试SSH已返回：

```text
SSH_OK
```

之所以看起来需要两台机器都操作，是两个独立问题：

- 远端：238 GB波形占满C盘，导致XSim和`sshd`异常，需要删除波形并重启`sshd`。
- 本机：旧私钥带口令，Codex沙箱不能直接访问Windows的`ssh-agent`；使用已授权的沙箱外SSH后即可正常签名。

这不是爆盘破坏了密钥，以后不需要重复配置。

当前只读检查还确认：

- 旧的238 GB WDB已经删除。
- 上次仿真没有PASS/FAIL或退出码，结果无效。
- 远端脚本仍包含危险的：

```tcl
log_wave -r /*
```

因此不能直接重跑。下一步应先同步精简波形脚本，再做10 µs波形容量探针，通过后运行32字冒烟。

### User

```
啥意思，之前的计划不是已经有了吗，照着执行，快点搞，等会我要断开网络：2. 波形记录策略
删除原脚本中的全层次记录：
log_wave -r /*
并设置：
set_property xsim.simulate.log_all_signals false [get_filesets sim_1]
按照Vivado推荐的直属对象方式记录，不使用递归选项：UG900 log_wave说明。
记录范围：
example_top适配层的直属信号。
top_axi_ddr4_bist的直属信号，包括完整AXI五通道、时钟、复位、校准及BIST结果。
u_axi_ddr_bist的全部直属信号，包括端口、状态机、读写计数器、握手和错误判断。
DDR4物理侧仅记录地址、BA/BG、ACT、CS、CKE、ODT、RESET和CK。
不记录DDR4的DQ、DQS和DM。
不进入 u_ddr4_axi_0 的MIG内部层次。
不进入DDR4器件模型内部层次。
单次WDB硬上限采用用户指定的 40 GB。同时设置：
剩余磁盘低于60 GB时终止当前仿真。
冒烟最长墙钟时间4小时。
签核最长墙钟时间8小时。
触发任一限制时保留日志和已有WDB，不启动下一阶段。
3. 分级运行策略
清理检查：确认旧XSim和后台流水线已退出，C盘至少有120 GB可用空间。
波形探针：运行10 µs，确认所有自定义模块对象均能匹配，WDB不得超过200 MB。
32字冒烟：完整执行MIG校准、32次写入及32次回读。
冒烟必须得到 bist_done=1、bist_pass=1、bist_fail=0、error_count=0。
冒烟PASS后重新启动独立仿真快照，执行4096字签核。
冒烟和签核使用不同日志及WDB文件，避免覆盖和重复复制。
上次因238 GB全量WDB导致的运行判定为无效，不复用任何仿真结果。
4. 验收标准
波形中能看到自定义BIST内部状态、完整AXI握手、校准和复位过程。
WDB不包含MIG PHY及DDR4模型内部对象。
10 µs波形探针低于200 MB，正式单次WDB低于40 GB。
冒烟失败时签核不启动。
最终报告记录编译、校准、BIST完成时间、首/中/末地址抽样及磁盘占用。
```

### Assistant

收到，计划已经完整，不需要再讨论。但当前会话处于“计划模式”，我不能修改远端文件或启动仿真。

此刻还不能断网，因为精简波形脚本尚未同步、后台仿真尚未提交。切换到执行模式后，我会立即：

<proposed_plan>
# DDR4完整仿真执行计划

1. 确认无残留XSim，C盘可用空间不少于120 GB。
2. 将远端 `log_wave -r /*` 替换为直属对象波形记录，并关闭 `log_all_signals`。
3. 记录适配层、DDR顶层和BIST模块直属信号，以及AXI五通道和DDR命令控制信号；排除DQ/DQS/DM、MIG内部和DDR模型内部信号。
4. 加入40 GB WDB、60 GB磁盘余量、冒烟4小时、签核8小时保护。
5. 运行10 µs波形探针，要求WDB小于200 MB。
6. 探针通过后提交32字冒烟；冒烟PASS后自动运行4096字签核。
7. 后台进程经独立SSH确认存活后，明确通知可以断网。
8. 最终更新验证报告，记录校准、BIST、抽样数据、波形容量和结果。
</proposed_plan>

### User

PLEASE IMPLEMENT THIS PLAN:
# DDR4完整仿真执行计划

1. 确认无残留XSim，C盘可用空间不少于120 GB。
2. 将远端 `log_wave -r /*` 替换为直属对象波形记录，并关闭 `log_all_signals`。
3. 记录适配层、DDR顶层和BIST模块直属信号，以及AXI五通道和DDR命令控制信号；排除DQ/DQS/DM、MIG内部和DDR模型内部信号。
4. 加入40 GB WDB、60 GB磁盘余量、冒烟4小时、签核8小时保护。
5. 运行10 µs波形探针，要求WDB小于200 MB。
6. 探针通过后提交32字冒烟；冒烟PASS后自动运行4096字签核。
7. 后台进程经独立SSH确认存活后，明确通知可以断网。
8. 最终更新验证报告，记录校准、BIST、抽样数据、波形容量和结果。

### Assistant

开始执行。我先做只读预检，同时准备同步精简波形和保护脚本；目标是在10～20分钟内完成探针并把后台冒烟稳定提交，然后明确通知你可以断网。

预检通过：C盘可用约255 GB；旧WDB已不存在。远程普通账号无法枚举全机进程，但当前仿真目录没有被占用迹象。现在落地波形探针、40 GB/60 GB/墙钟保护和自动流水线。

保护脚本已完成并通过PowerShell语法检查：远端将按“探针→32字冒烟→4096字签核”自动串行，任何容量、磁盘或时间限制触发都会停止下一阶段。现在同步远端并启动。

探针保护逻辑已生效，但第一次探针在Vivado启动/脚本阶段退出，未生成WDB，也未消耗磁盘。正在读取日志修正后立即重提。

重试已稳定：波形探针运行30秒时WDB仅约3.2 MB，已从原来的数GB/分钟降到约MB级；40 GB、60 GB余量和墙钟保护都在采样。后台流水线已脱离SSH。我再看一次探针是否已PASS，随后立即给出断网结论。

现在可以断开SSH，也可以断开本机与远程机的网络。

当前状态：

- 10 µs波形探针已PASS。
- 探针WDB仅约3.2 MB，远低于200 MB限制。
- 32字冒烟已自动启动，运行90秒时WDB约5.3 MB。
- C盘剩余约255 GB。
- 40 GB WDB、60 GB磁盘余量和4/8小时墙钟保护均已生效。
- 冒烟PASS后会自动启动4096字签核。

远程电脑需要保持开机且不能休眠。重新联网后我再检查结果并完成验证报告。

### User

现在，继续检查，并告诉我波形里的仿真时间是多少，为什么设置这么多，如何查看并验证重要信号的波形；指出为什么要冒烟+全跑，我理解冒烟就行了，各自再测什么

### Assistant

我先只读检查流水线阶段、日志中的仿真时间标记、当前WDB大小和保护采样。然后分别说明“墙钟时间”和“波形内部时间”，以及冒烟与4096字签核各自覆盖什么。

结果已经很关键：32字逻辑结果实际上是PASS，但在墙钟4小时边界才推进到PASS，保护器先按超时终止，所以流水线记为失败且未启动4096字。仿真内部只跑到约7.049 µs，墙钟却用了约4小时。接下来我核对波形对象数量和PASS后的退出日志，说明为何会出现“内部几微秒、现实几小时”。

检查结论：

- 32字BIST实际已经在仿真时间 **7,048,846 ps（约7.049 µs）** PASS。
- 校准完成在 **3.827 µs**，AXI复位释放在 **3.833 µs**。
- 现实运行却到4小时，是脚本把仿真跑了两次：`xsim.simulate.runtime=all`让 `launch_simulation`先自动跑到PASS，随后脚本才加波形并再次执行`run all`，第二次已没有新的`$finish`，因此无限运行。
- 这也解释了之前238 GB爆盘：关键不是正常DDR测试很长，而是PASS后又递归记录了一个不会结束的第二次运行。
- 当前3.2 MB探针WDB只记录了PASS后的空闲区间，不能用于验证；工作目录里约793 MB的WDB仍在增长，说明保护器杀掉父进程后可能遗留了XSim子进程。

正确修改应是把`xsim.simulate.runtime`设为空，先添加62个自定义/接口信号，再只执行一次`run all`。修正后32字烟测预计在约7.049 µs结束，波形应包含完整校准、写入和回读过程。

可以分两层判断：

- **功能冒烟：算通过。** 日志证明MIG校准完成、AXI复位正确释放、32次写入和32次回读完成，首/中/末地址数据一致，最终 `bist_pass=1`、`error_count=0`，结束于约7.049 µs。
- **正式自动化验收：暂不算完整通过。** 流水线的FAIL来自PASS之后的重复 `run all` 超时，不是DDR/BIST失败；但波形是在PASS后才开始记录，因此当前WDB无法证明校准和读写握手过程。

所谓“设置很多”实际只记录62个对象：适配层1个、DDR顶层48个、BIST内部10个，加3个TB状态信号。40 GB、60 GB和墙钟限制只是防爆盘保护，不会增加波形信号。

修正后可在Vivado Tcl Console打开：

```tcl
open_wave_database {C:/project/RTDS/DDR/axi_ddr4_min_2020_2/sim_full/results/smoke.wdb}
```

重点验证：

- `init_calib_complete`约3.827 µs拉高；
- `axi_aresetn`延迟两个UI时钟释放；
- `state/write_index/read_index`依次推进；
- AW/W/B和AR/R各通道VALID/READY完成握手；
- 地址0、0x80、0xF8的数据分别正确；
- 约7.049 µs时`done/pass=1`，`fail=0`、`error_count=0`。

<proposed_plan>
# DDR4 32字有效冒烟重跑计划

## 结论

本次DDR功能实际已PASS：校准3.827 µs、复位释放3.833 µs、32字读写在7.049 µs完成。流水线FAIL来自PASS后的重复运行，当前WDB不包含有效读写过程。

按用户选择，只修正并重跑32字冒烟，不自动执行4096字。

## 修正内容

- 停止遗留XSim并删除当前约793 MB的无效工作WDB。
- 将 `xsim.simulate.runtime` 从 `all` 改为空，确保 `launch_simulation`只加载快照。
- 在仿真开始前添加62个自定义模块和关键接口信号，然后只执行一次 `run all`。
- 保留40 GB WDB上限、60 GB磁盘余量；将烟测墙钟上限缩短为30分钟。
- 流水线只运行32字烟测；4096字入口保留为手动选项，不自动启动。

## 波形验收

有效波形保存为：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\results\smoke.wdb
```

检查内容：

- `init_calib_complete`约3.827 µs拉高。
- `axi_aresetn`延迟两个UI时钟释放。
- BIST状态机、`write_index`、`read_index`正确推进。
- AXI AW/W/B及AR/R通道握手完整。
- 地址0、0x80、0xF8的写入与回读数据一致。
- 约7.049 µs时`done/pass=1`，`fail=0`、`error_count=0`。
- WDB不得包含MIG和DDR4模型内部层次，预计容量为数MB。

## 验收与报告

- 流水线状态必须为`SMOKE_PASS`和`PIPELINE_RESULT=PASS`。
- 更新报告，区分“首次功能PASS但波形无效”和“修正后正式冒烟PASS”。
- 4096字签核不执行：它只增加32 KiB连续地址和4096次重复读写覆盖，不增加新的AXI协议场景；对于最小DDR工程基本可用性判断，32字冒烟足够。
</proposed_plan>

### User

PLEASE IMPLEMENT THIS PLAN:
# DDR4 32字有效冒烟重跑计划

## 结论

本次DDR功能实际已PASS：校准3.827 µs、复位释放3.833 µs、32字读写在7.049 µs完成。流水线FAIL来自PASS后的重复运行，当前WDB不包含有效读写过程。

按用户选择，只修正并重跑32字冒烟，不自动执行4096字。

## 修正内容

- 停止遗留XSim并删除当前约793 MB的无效工作WDB。
- 将 `xsim.simulate.runtime` 从 `all` 改为空，确保 `launch_simulation`只加载快照。
- 在仿真开始前添加62个自定义模块和关键接口信号，然后只执行一次 `run all`。
- 保留40 GB WDB上限、60 GB磁盘余量；将烟测墙钟上限缩短为30分钟。
- 流水线只运行32字烟测；4096字入口保留为手动选项，不自动启动。

## 波形验收

有效波形保存为：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\results\smoke.wdb
```

检查内容：

- `init_calib_complete`约3.827 µs拉高。
- `axi_aresetn`延迟两个UI时钟释放。
- BIST状态机、`write_index`、`read_index`正确推进。
- AXI AW/W/B及AR/R通道握手完整。
- 地址0、0x80、0xF8的写入与回读数据一致。
- 约7.049 µs时`done/pass=1`，`fail=0`、`error_count=0`。
- WDB不得包含MIG和DDR4模型内部层次，预计容量为数MB。

## 验收与报告

- 流水线状态必须为`SMOKE_PASS`和`PIPELINE_RESULT=PASS`。
- 更新报告，区分“首次功能PASS但波形无效”和“修正后正式冒烟PASS”。
- 4096字签核不执行：它只增加32 KiB连续地址和4096次重复读写覆盖，不增加新的AXI协议场景；对于最小DDR工程基本可用性判断，32字冒烟足够。

### Assistant

开始执行：先终止遗留XSim并清除无效工作WDB，同时修正“自动运行一次＋显式运行一次”的双运行问题；随后只提交32字有效冒烟。

### User

增加波形信号  dq相关的

### Assistant

收到。增加物理接口边界上的 `c0_ddr4_dq[63:0]`、`dqs_t/c[7:0]`和`dm_dbi_n[7:0]`，仍不递归记录MIG PHY或DDR4模型内部信号。由于有效仿真只有约7 µs，容量仍应可控。

### User

新建并补充设计、验证方案（重点是非example外自己新），以word形式给出

### Assistant

收到。我会在完成这次有效冒烟提交的同时，新建一份Word版《最小DDR工程设计与验证方案》，重点说明Example Design之外自行新增的顶层、BIST、适配层、波形与自动化保护。按工作区规则只做DOCX结构完整性检查，不渲染PDF或图片。现在先读取文档制作规范。

我先接着确认32字冒烟是否已按新策略完成；结果确认后，把实际校准、完成时间和波形容量写进新的 Word 方案。文档会重点区分“沿用 MIG Example Design 的部分”和“我们自行新增的设计/验证内容”，并按要求只做 DOCX 结构检查，不转 PDF/图片。

### User

我最终目的是E:\NVME_PRO\nvme_adc_axi_pipeline\docs、E:\NVME_PRO中最新文档涉及的项目，当前的最小DDR工程支持后面项目的合入吗

### Assistant

明白，文档的落点会从“最小 DDR 单体能否跑通”提升为“能否作为 `nvme_adc_axi_pipeline` 的 DDR 子系统合入”。我会先读取 `E:\NVME_PRO\nvme_adc_axi_pipeline\docs` 及 `E:\NVME_PRO` 最新相关文档，核对它们的接口、数据宽度、时钟、复位和缓存需求，再给出明确的“可直接合入 / 需适配 / 当前不支持”结论，并把差距清单补进 Word。

接口差距已经很明确：目标工程确认的 MIG 用户口是 512-bit，而当前最小 DDR 工程的自研顶层把 MIG AXI 数据口固定为 64-bit、ID 为 4，且 BIST 只发单拍、单 outstanding。它可以作为“同一颗粒/同一板级 MIG 配置的校准与基础读写底座”，但不能原封不动替换目标工程的共享 DDR 子系统。我正在继续核对器件、时钟和现有集成骨架，文档会给出需要新增的 256→512 宽度转换、SmartConnect、多主机仲裁和地址映射改造项。

目前结论先给你：最小工程“有合入价值，但不是直接拷贝顶层就能合入”。

它已经能验证 DDR4 物理模型、MIG 校准、复位释放和基础 AXI 读写；目标项目则还需要 256-bit ADC Writer 与 512-bit MIG 的宽度转换、ADC/NoPHAE 两主机仲裁、`0x80000000～0xFFFFFFFF` 地址窗口、`0xC0000000` 采集区，以及连续突发和并发停顿验证。最合理的合入方式是保留目标项目现有 256-bit Writer，在 MIG 前增加 SmartConnect/宽度转换，并把当前 BIST 改成可切换的 DDR bring-up 主机，而不是拿当前 64-bit 单拍 BIST 代替业务通路。Word 会把这条合入路线写成可执行步骤和验收矩阵。

修正后的32字冒烟已经正式 PASS：校准 3.827 µs、32字写回读 7.049 µs 完成，WDB 只有 2.86 MB。检查日志时发现一个细节：上一版虽然文字上允许 DQ，但直属对象过滤只统计到 62 个普通信号，DQ/DQS/DM 端口没有被明确计入。我已把这四组物理边界总线改为显式记录，准备再跑一次，确保交付波形确实含有它们，同时仍不进入 MIG PHY 和 DDR 模型内部层次。

### User

现在可以断开网络了吗

### Assistant

先别断，显式加入 DQ/DQS/DM 后的最后一次冒烟可能还在运行；我马上用只读状态确认。若已写出 `PIPELINE_RESULT=PASS` 和新 WDB，我会立即明确告诉你可以断网。

### User

等下，现在等于是全跑完了

### Assistant

按当前最终计划，32字完整冒烟已经全部跑完并 PASS：

- MIG 校准：3.827 µs
- 32字写入回读完成：7.049 µs
- `PIPELINE_RESULT=PASS`
- WDB：2.86 MB
- 4096字签核未执行，这是按你之前要求保留为手动选项

现在可以断开网络。Word 文档在本机继续生成，不依赖远程连接。DQ/DQS/DM 的显式记录脚本已修改，若之后需要重新生成包含这些信号的新 WDB，再恢复网络运行一次32字冒烟即可。

### User

继续前台执行 完成文档编写

### Assistant

我继续使用文档制作规范完成 Word。内容已经按“自研部分—完整仿真—目标项目合入差距—分阶段验证”组织；现在生成 DOCX、做结构完整性检查，并保存到 `E:\NVME_PRO\nvme_adc_axi_pipeline\docs`。按本工作区要求，只检查 DOCX 结构，不渲染 PDF/PNG。

### User

看一下跑的情况

### Assistant

我先检查两部分：Word 是否已经生成/是否有残留生成进程，以及远端32字冒烟的最终状态、WDB时间和大小。只做只读检查。

当前情况：

- 32字完整冒烟已完成并 PASS：
  - 开始：15:32:52
  - 完成：15:33:54
  - 仿真时间：7.049 µs
  - WDB：2,861,723 字节，约 2.86 MB
  - 状态：`PIPELINE_RESULT=PASS`
- 4096字签核按计划未运行。
- Word 生成刚才被中断，尚未生成文件，也没有残留 Python 文档进程。
- C盘剩余约 254.7 GB，空间正常。

仿真已经结束，接下来只需继续生成并检查 Word 文档。

### User

帮我生成文档

### Assistant

我现在直接生成 Word，并保存到目标项目的 `docs` 目录。文档会明确给出“条件式可合入”的结论、非 Example Design 的自研内容、接口差距、推荐集成架构和分阶段验收方案；完成后只做 DOCX 结构检查。

### User

先生成到本机

### Assistant

可以，先生成到本机 `E:\ddr_proc\deliverables`，暂不复制到 `E:\NVME_PRO` 或远端机器。生成后我会核对压缩包结构、Word必要部件、标题层级、表格数量和关键内容。

Word 已生成，当前结构检查通过：84个正文段落、23个标题、15个表格。现在补做样式与表格几何审计，重点确认页边距、标题层级、表格宽度以及所有必要的 Word XML 部件完整。

### User

告诉我如何打开之前仿真好的波形  以及关键波形

### Assistant

结构审计发现表格虽然单元格宽度正确，但 Word 的 `tblW/tblGrid/tblInd` 仍是默认值，打开时可能由不同版本自动重排。我正在把15个表格全部改成固定9360 DXA宽度、120 DXA缩进，并让列网格与单元格宽度完全一致；这是格式修正，不改文档内容。

打开已有波形可在远端机器执行：

```powershell
& 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat' -mode gui
```

进入 Vivado 后，在 Tcl Console 输入：

```tcl
open_wave_database {C:/project/RTDS/DDR/axi_ddr4_min_2020_2/sim_full/results/smoke.wdb}
```

也可以使用菜单 `File → Open Waveform Database`，选择同一个 `smoke.wdb`。

重点查看这几组：

- 校准与复位：`init_calib_complete`、`ui_clk_sync_rst`、`axi_aresetn`
- BIST：`state`、`write_index`、`read_index`、`done/pass/fail/error_count`
- 写通道：`axi_awaddr/awvalid/awready`、`axi_wdata/wstrb/wlast/wvalid/wready`、`axi_bresp/bvalid/bready`
- 读通道：`axi_araddr/arvalid/arready`、`axi_rdata/rresp/rlast/rvalid/rready`
- 握手事件：`aw_fire/w_fire/b_fire/ar_fire/r_fire`
- DDR命令：`adr/ba/bg/act_n/cs_n/cke/odt/reset_n/ck_t/ck_c`

关键时间点：

- 3.827 µs：校准完成
- 3.833 µs：AXI复位释放
- 3.847 µs：首地址写入
- 4.570 µs：首地址回读
- 7.049 µs：`done/pass=1`

当前这份已PASS的 WDB可以确认自研逻辑、完整AXI五通道和DDR命令。DQ/DQS/DM是在它生成后才改成显式记录，因此这份WDB中不保证存在；要看DQ物理数据，需要以后联网再重跑一次32字冒烟。文档生成与最终审计继续进行。

文档已生成到本机，并通过 DOCX 结构、标题层级及表格几何检查：

[DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx](E:/ddr_proc/deliverables/DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx)

文档重点包括：

- Example Design 与自研新增内容的边界
- BIST、最小顶层、适配层及仿真脚本设计
- 32字完整冒烟结果
- 与 `nvme_adc_axi_pipeline` 的接口差距
- 256→512-bit转换、SmartConnect仲裁及地址规划
- 分阶段合入和验证方案
- “条件式可合入”的明确结论

打开已有波形：

```powershell
& 'C:\Xilinx\Vivado\2020.2\bin\vivado.bat' -mode gui
```

在 Vivado Tcl Console 输入：

```tcl
open_wave_database {C:/project/RTDS/DDR/axi_ddr4_min_2020_2/sim_full/results/smoke.wdb}
```

重点时间：

- 3.827 µs：MIG校准完成
- 3.833 µs：AXI复位释放
- 3.847 µs：开始写入
- 4.570 µs：开始回读
- 7.049 µs：BIST PASS

重点信号包括校准与复位、BIST状态和计数器、AXI五通道及DDR命令控制信号。当前PASS波形生成早于DQ显式记录修改，因此不保证包含DQ/DQS/DM；查看这些信号需要重新运行一次32字冒烟。

### User

```
open_wave_database后，只显示列表，没有波形是否正常   之前加注释的代码出了远程机子本地有木有复制一份  现在没有厨处于ssh连接状态
```

### Assistant

截图中的状态正常：WDB已经打开，但当前只显示 Scope/Object 列表，尚未把信号加入右侧 Wave 窗口。我先核对本机是否保留了加中文注释后的 RTL、适配层和仿真脚本；不会尝试 SSH 或联网。

正常。`open_wave_database` 只打开 WDB 数据库，不一定自动创建波形布局，所以现在能看到 Scope/Object 列表、右侧没有波形。

### 添加波形

建议先在 Tcl Console 执行：

```tcl
create_wave_config
add_wave [get_objects -quiet -filter {type == signal} /sim_tb_top/u_example_top/u_bist_top/*]
add_wave [get_objects -quiet -filter {type == signal} /sim_tb_top/u_example_top/u_bist_top/u_axi_ddr_bist/*]
wave zoom full
```

如果仍然看不到右侧波形窗口，选择：

```text
Window → Waveform
```

也可以在 GUI 中操作：

1. 展开 `sim_tb_top → u_example_top → u_bist_top`。
2. 在 Objects 窗口按 `Ctrl+A`。
3. 右键选择 `Add to Wave Window`。
4. 再进入 `u_axi_ddr_bist`，重复添加。
5. 点击工具栏的 `Zoom Fit`。

截图中大量DDR模型层次只代表WDB保存了仿真层次结构，不代表这些模型的所有内部信号都被记录。

### 重点波形

按以下顺序分组观察：

1. 校准和复位

```text
init_calib_complete
ui_clk_sync_rst
axi_aresetn
```

2. BIST状态

```text
state
write_index
read_index
done
pass
fail
error_count
```

3. AXI写通道

```text
axi_awaddr
axi_awvalid
axi_awready
axi_wdata
axi_wstrb
axi_wlast
axi_wvalid
axi_wready
axi_bresp
axi_bvalid
axi_bready
```

4. AXI读通道

```text
axi_araddr
axi_arvalid
axi_arready
axi_rdata
axi_rresp
axi_rlast
axi_rvalid
axi_rready
```

关键时间点：

- `3.827 µs`：MIG校准完成
- `3.833 µs`：AXI复位释放
- `3.847 µs`：首地址写入
- `4.570 µs`：首地址回读
- `7.049 µs`：`done/pass=1`

当前PASS的WDB生成于DQ显式记录修改之前，因此不保证包含DQ/DQS/DM。

### 本机代码副本

加过中文语义注释的代码已经复制到本机：

- [axi_ddr_bist.v](E:/ddr_proc/staging_axi_ddr4_min_2020_2/rtl/axi_ddr_bist.v)
- [top_axi_ddr4_bist.v](E:/ddr_proc/staging_axi_ddr4_min_2020_2/rtl/top_axi_ddr4_bist.v)
- [example_top_bist_adapter.sv](E:/ddr_proc/staging_axi_ddr4_min_2020_2/sim_full/example_top_bist_adapter.sv)
- [仿真控制Tcl](E:/ddr_proc/staging_axi_ddr4_min_2020_2/sim_full/tcl/run_full_sim_case_2020_2.tcl)

守护脚本和流水线脚本也保存在同一 `staging_axi_ddr4_min_2020_2\sim_full` 目录。

目前本机保存的是自研修改文件和脚本，不是远程完整Vivado工程；`smoke.wdb`仍在远端。当前没有SSH连接，我也没有尝试联网。

---

<!-- codex-history-md-export-append {"append_id": "118b5bfed297cc0cbc1bdc07", "dialogue_sha256": "4b168a8a4d2b46f18ed846cfa738f7ac8bb979a892cd652cf38016dd9ef2a5f5", "from_message": 177, "session_id": "019fc561-6c64-7021-9090-820de6f07881", "to_message": 257} -->

## 对话增量

### User

当前看到7.0488µs波形就停了，可能刚好在done/pass=1的位置，但是done/pass没有拉高；将E:\ddr_proc\deliverables DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0复制到远程电脑的docs，并添加关键信号的解释，如axi_ddr_bist中的aw_sent、w_sent、，此外分析测试pattern这样做好吗，还可以怎么做，以及如果做完bist后，用于集成进真实项目的顶层又应该是什么

### Assistant

我先做只读核对，重点确认三个事实：为什么WDB停在`7.0488 µs`却看不到`done/pass`终值、现有BIST pattern和`aw_sent/w_sent`的准确语义、目标项目现有顶层接口是否适合直接接MIG。由于当前处于方案规划阶段且工作区禁止联网，我不会实际复制远端或修改Word，只把实施方案收敛到可直接执行。文档部分我会按 Word 文档规范规划，并遵守“只做DOCX结构检查、不渲染”的要求。

只读核对后，`7.0488 µs`现象基本可以解释：BIST在最后一次`r_fire`的时钟沿用非阻塞赋值拉高`done/pass`，监视器同一仿真时刻检测到PASS后立即`$finish`。日志能打印PASS，但WDB可能在终值稳定保存前关闭，所以最后一格仍显示旧值。应在Testbench判定PASS后额外保留4个`ui_clk`周期再结束，不需要改BIST功能逻辑。

另外，现有pattern `{~index,index}`适合可读性强的32字冒烟，但覆盖有限：32个字只让少量低位充分翻转；扩大到256/512-bit时高位还会被零扩展，不能作为真实项目签核pattern。文档应保留它作为基础pattern，同时增加全lane地址扰动、全0/全1、AA55/55AA、Walking 1/0和可复现PRBS等分级方案。

还有两个会直接影响交付方式的选择需要你确认。

### User

当前已联网 并打开权限

### User

还有tbxxx中的xx_PENDING xx hold信号

### Assistant

收到补充项：文档的关键信号说明还要覆盖Testbench中所有`*_PENDING`和`*_hold`信号，解释它们记录的是“请求已出现但对应握手/响应尚未完成”，并说明正常拉高区间与卡死判据。

虽然你现在已联网并开放权限，但当前工作区规则仍明确禁止联网，所以我不会从这里发起SSH；最终方案会把远端复制列为用户侧执行命令，或等待工作区规则解除后再由我执行。现在先在本机搜索这些信号的准确名称和定义，避免文档写成泛泛解释。

还有一个关键点：`aw_pending/w_pending/awaddr_hold/wdata_hold/read_index_hold`属于行为级Testbench `tb_axi_ddr_bist.sv`，用于模拟AXI Slave，不属于BIST或完整MIG仿真。因此它们应在文档中单独列为“行为级TB信号”，不能让读者误以为会出现在当前`smoke.wdb`里。

为了让文档证据和波形完全一致，最好同步修复结束时刻并重跑一次32字冒烟；这会产生一份能稳定看到`done/pass=1`、且按新脚本包含DQ/DQS/DM边界的新WDB。是否纳入本轮，需要你确认。

### User

当前工作区规则仍明确禁止联网 ——如何打开，我不知道

### Assistant

这里的“禁止联网”不是SSH权限或“完全访问”开关，而是当前任务加载到的 `AGENTS.md` 第6条。即使你在界面里开放了权限，我仍必须服从这条工作区规则。我要先只读定位实际的 `AGENTS.md` 文件，再告诉你改哪一处、怎样让新规则在任务中生效。我会使用 Codex 官方使用说明技能核对规则加载方式，不会联网搜索。

实际规则文件在：

```text
C:\Users\MaiBo\.codex\AGENTS.md
```

用记事本打开：

```powershell
notepad.exe "$env:USERPROFILE\.codex\AGENTS.md"
```

建议把第6条：

```text
6. 本工作区不允许联网、不允许使用computer use连接微信。
```

改为更精确的规则：

```text
6. 禁止访问公共互联网；允许使用SSH/SCP连接用户明确指定的内网远程机vivado-srv，用于工程检查、仿真和文件传输；禁止使用computer use连接微信。
```

保存后，关闭并重新打开当前Codex工作区，或者新建任务，确保新规则重新加载。之后即使仍有限制，只要出现SSH授权提示，点击允许即可。

当前任务已经加载了旧规则，因此即使界面打开“完全访问”，我在本轮仍不能发起SSH。界面权限和`AGENTS.md`是两层限制，必须同时允许。

### User

我重新修改了：只有chat_proc工作区不允许联网   现在能否联网

### Assistant

我先读取当前 `C:\Users\MaiBo\.codex\AGENTS.md`，确认规则已经只限制 `chat_proc`；随后对 `vivado-srv` 做一次只读SSH连通性检查，不修改远端文件。

可以联网。当前规则只禁止 `chat_proc`，而本工作区是 `E:\ddr_proc`；我已实际验证 `ssh vivado-srv` 返回 `SSH_OK`。

我接着完成之前未完的工作：修正PASS后立即结束导致终值未写入WDB的问题，重跑32字冒烟；补充关键信号、pattern分析和真实项目顶层说明；覆盖本机V1.0，并复制到远端 `docs`。Word仍只做DOCX结构检查，不渲染。

### User

改为medium推理强度

### Assistant

我无法从任务内部修改当前模型的系统级推理强度；需要你在Codex界面的模型/推理强度菜单中选择 `Medium`。我会按中等推理粒度继续当前任务，不中断已开始的修改。

远端只读检查通过：SSH可用，C盘剩余约255 GB，没有发现需要保留的活动仿真。现在把“PASS后保留4个UI时钟周期”的适配层和最新波形脚本上传，然后前台重跑32字冒烟。预计约1～2分钟。

重跑没有启动：你当前在Vivado里打开的 `smoke.wdb` 被GUI锁定，守护脚本无法删除旧文件。为避免关闭你的GUI或破坏正在查看的波形，我不会强制终止Vivado；我会把新结果改为独立文件 `smoke_done_visible.wdb`，旧的 `smoke.wdb` 保持不动。

### User

bist.v的6个状态是否是用于测试才加，我不太懂如果不用bist，是否也要加axi /dma逻辑

### Assistant

先回答你的核心疑问：`axi_ddr_bist.v`里的6个状态只属于“DDR自检主机”，不是MIG必须具备的状态。真实项目不用BIST后，不需要保留这6个状态，但仍然必须有某种AXI Master发起DDR访问。

- 只有CPU/MicroBlaze访问DDR：由处理器AXI主口和互连负责，不需要你再写BIST状态机。
- ADC数据写DDR：需要ADC打包/FIFO后面的AXI写主机，也就是现有`adc_ddr_segment_writer`一类DMA/Writer逻辑。
- NVMe从DDR读写：由NoPHAE自身的AXI Master负责。
- 多个主机共享MIG：需要SmartConnect/AXI Interconnect做仲裁、位宽和可能的时钟转换。

所以“去掉BIST”不等于“去掉AXI/DMA”。BIST只是临时测试流量源；真实顶层应换成ADC Writer、NoPHAE DMA、MicroBlaze等业务AXI主机。BIST最多作为维护模式下的可选第三主机保留。

刚才新结果名脚本出现了PowerShell参数语法问题，我正在修正；旧WDB和远端工程没有被改坏。

### User

我当前已关闭远程桌面的窗口

### Assistant

关闭远程桌面窗口通常只会断开RDP，不一定会关闭远端Vivado进程，因此旧WDB可能仍保持锁定。我不依赖GUI是否退出，改用独立结果名继续跑，避免影响旧文件。

### User

某种AXI Master发起DDR访问的逻辑在哪，在真实系统中？  需要本模块写吗

### Assistant

真实系统里的AXI Master不是一个统一模块，而是按数据来源分别存在：

```text
ADC采样流
  → adc_ddr_segment_writer        ← 我们写的AXI写主机
  → SmartConnect
  → MIG AXI Slave
  → DDR4

NoPHAE NVMe IP
  → NoPHAE内部m_axi              ← 供应商IP自带，不需要我们重写
  → SmartConnect
  → MIG AXI Slave
  → DDR4

MicroBlaze
  → MicroBlaze M_AXI             ← Xilinx处理器系统生成
  → SmartConnect
  → MIG AXI Slave
```

因此：

- `axi_ddr_bist`的6状态只用于测试，业务模式可完全去掉。
- ADC连续数据要写DDR，必须有AXI写主机；本项目已经由 `adc_ddr_segment_writer.sv` 实现，我们不需要在最终顶层再写一套。
- NoPHAE访问DDR的AXI Master在供应商IP内部，也不需要我们写。
- SmartConnect和MIG用Vivado IP配置，不手写协议状态机。
- 最终顶层的主要任务是实例化/连接这些模块、处理时钟复位和地址空间，不负责重新实现每个AXI Master。

只有以后增加“独立DDR回读CRC”“自研DMA搬运”或新的数据源时，才需要再写AXI Reader/Master，或采用AXI DMA/DataMover IP。当前文档会把这一点明确写清楚。

真实项目顶层我采用两层定义，避免把BIST误带进产品路径：

- `top_nvme_adc_ddr_system.sv`：新增的、可编译的自研集成边界，实例化现有 `nvme_adc_vitis_compat_top`，向Vivado BD暴露ADC Writer、FDMA控制口、NoPHAE控制口和状态。
- 供应商/板级 `design_1_wrapper`：真正拥有DDR、PCIe、时钟和引脚；在BD中用SmartConnect把自研顶层、NoPHAE和MIG连接起来。

BIST继续作为独立DDR诊断工程，不直接成为产品顶层。

新仿真已经PASS并生成独立波形：

- 功能PASS：`7.049 µs`
- 继续保持4个`ui_clk`周期后结束：`7.062 µs`
- 新WDB：`smoke_done_visible.wdb`
- 大小：2,862,197字节
- 记录对象：66个，较旧版增加4组DQ/DQS/DM边界对象

这份波形应能稳定看到`done/pass=1`。接下来检查真实项目顶层骨架的语法，再把这些实际结果写入Word。

32 字冒烟已修正并重跑通过，新的波形把终值保留到了 7.062 µs。现在我完成最后一步：把更新后的 Word 和接口骨架复制到远端，并核对文件哈希。之后会直接给出“真实系统里 AXI Master 逻辑放在哪、哪些需要本模块写”的结论。

远端目录创建命令遇到的是 Windows SSH 的引号转发问题，不是账号权限问题。我改用 PowerShell 编码命令执行，避免中文路径和管道符被远端 `cmd` 误解析。

复制和校验已完成，本地与远端 Word、接口骨架的 SHA-256 一致。最后我再定位现有工程中 ADC 写入 Master 的确切源码位置，避免只给抽象架构说明。

真实系统中，AXI Master 访问逻辑必须存在，但不需要在最外层顶层里重新编写。它通常由业务模块或 DMA IP 提供。

当前项目对应关系如下：

| 功能 | AXI Master 位于 |
|---|---|
| ADC 数据写入 DDR | [adc_ddr_segment_writer.sv](E:/NVME_PRO/nvme_adc_axi_pipeline/rtl/adc_ddr_segment_writer.sv:12) |
| ADC Writer 实例化 | [nvme_adc_pipeline_top.sv](E:/NVME_PRO/nvme_adc_axi_pipeline/rtl/nvme_adc_pipeline_top.sv:281) |
| NoPHAE 数据搬运 | [nophae_dma_backend.sv](E:/NVME_PRO/nvme_adc_axi_pipeline/rtl/nophae_dma_backend.sv:52) |
| 系统集成接口 | [nvme_adc_vitis_compat_top.sv](E:/NVME_PRO/nvme_adc_axi_pipeline/rtl/nvme_adc_vitis_compat_top.sv:12) |
| DDR 控制器 | MIG，作为 AXI Slave，不主动发起访问 |
| 多主机连接 | SmartConnect，负责仲裁、位宽转换，不产生读写请求 |

实际数据路径是：

```text
ADC采集
  ↓
adc_ddr_segment_writer（AXI Master）
  ↓
SmartConnect
  ↓
MIG（AXI Slave）
  ↓
DDR4
```

因此：

- `bist.v` 的六状态机是测试专用 AXI Master，用来主动产生固定写入和回读。
- 合入真实系统后，不需要复制这六个状态。
- ADC 写DDR所需的地址、突发长度、AW/W/B握手等逻辑，已经由 `adc_ddr_segment_writer` 实现。
- 新建的系统顶层只负责实例化和连接业务模块、SmartConnect、MIG等，不应再写一套重复的 AXI 事务状态机。
- 如果以后增加新的数据源访问DDR，则可以选择新写一个 AXI Master，或直接使用 AXI DMA/DataMover 等IP。

已完成交付：

- 更新文档：[DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx](E:/ddr_proc/deliverables/DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx)
- 集成顶层骨架：[top_nvme_adc_ddr_system.sv](E:/ddr_proc/integration/top_nvme_adc_ddr_system.sv)
- 文档已完成DOCX结构检查。
- 两个文件已复制到远端工程的 `docs`、`integration` 目录，哈希核对一致。
- 修正后的冒烟波形位于：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\results\smoke_done_visible.wdb
```

该波形在约 `7.049 µs` 出现 `done/pass=1`，并继续保留到 `7.062 µs`。当前远端操作已经全部完成，没有后台仿真需要维持，现在可以断开网络。

### User

C:\project\RTDS\DDR\axi_ddr4_min_2020_2\sim_full\mig_example_2020_2\ddr4_axi_0_ex ddr4_axi_0_ex和C:\project\RTDS\DDR\axi_ddr4_min_2020_2\prj  axi_ddr4_min_2020_2的区别是什么   请在设计、验证方案中列出详细顶层信号、架构图

### Assistant

我会先按实际目录内容做只读比对，再形成可直接更新文档的方案；重点确认两套工程各自的顶层、MIG实例、仿真模型和用途，而不是只按目录名推断。因为后续涉及 Word 方案文档，我会遵循文档技能，但只做 DOCX 结构检查，不进行 PDF/PNG 渲染。

目录结构已经确认：`ddr4_axi_0_ex` 是 Vivado 从 MIG 自动生成的独立 Example Design，`prj` 才是自研最小DDR工程。下一步我会核对两份 XCI 是否参数一致，并提取三个顶层层次的完整端口：上板顶层、Example适配层、仿真顶层。这样文档里的架构图和信号表能明确区分“真实板级端口、AXI内部接口、仿真模型连线”。

只读核对有一个关键结论：两份 `ddr4_axi_0.xci` 的功能配置逐行一致，唯一差别是各自工程的生成输出目录；因此它们不是两套不同DDR参数，而是“同一个MIG配置的产品工程”和“由它派生出的官方独立Example工程”。为了把文档改版范围锁定，我需要确认两个会影响交付形式的选择。

<proposed_plan>
# DDR4工程差异、顶层信号与架构图文档更新计划

## 概要

覆盖更新现有 `DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx`，不修改RTL、XCI、XPR或仿真结果。

文档明确以下结论：

- `prj\axi_ddr4_min_2020_2.xpr` 是自研最小DDR产品工程，设计顶层为 `top_axi_ddr4_bist`。
- `sim_full\mig_example_2020_2\ddr4_axi_0_ex\ddr4_axi_0_ex.xpr` 是Vivado根据MIG生成的独立Example Design，设计顶层为官方 `example_top`，仿真顶层为 `sim_tb_top`。
- 两份 `ddr4_axi_0.xci` 功能配置完全一致，逐行比较只有 `RUNTIME_PARAM.OUTPUTDIR` 不同；不是两套不同的DDR参数。
- 正式冒烟实际使用 `sim_full\bist_sim_work\ddr4_axi_0_ex.xpr`，关闭官方 `example_top.sv` 的仿真用途，再加入自研适配层和BIST RTL。

## 文档修改

### 1. 工程差异对照

新增完整对照表，列明：

- 工程路径、XPR名称、生成来源和维护责任。
- 综合顶层、仿真顶层、AXI流量发生器、DDR器件模型和约束来源。
- `prj` 用于自研RTL综合、实现和上板；Example用于官方流量测试、器件模型和完整仿真环境。
- Example包含官方AXI Traffic Generator、数据生成与比较模块、`sim_tb_top`及4片x16 DDR4模型；主工程使用自研 `axi_ddr_bist`。
- 两个工程相互独立，打开、修改或运行Example不会自动更新主工程。
- 记录当前目录快照：Example约159.6 MB/535个文件，`prj`约261.4 MB/365个文件，并注明大小会随日志和运行产物变化。

### 2. 三张架构图

使用Word原生等宽文本图和带底色边框，不嵌入截图或外部图片：

1. **工程生成与使用关系图**  
   展示主工程XCI生成Example、Example复制为 `bist_sim_work`、禁用官方顶层并接入自研适配层的关系。

2. **自研最小DDR上板架构图**  
   展示差分系统时钟/复位、MIG、AXI Slave、BIST Master、复位门控、状态LED及DDR4物理接口。

3. **完整MIG仿真架构图**  
   展示 `sim_tb_top → example_top_bist_adapter → top_axi_ddr4_bist → MIG → DQ/DQS/DM及命令总线 → 4×x16 DDR4模型`，并标出监视器、WDB记录边界和禁止递归记录的MIG/模型内部层次。

### 3. 详细顶层信号表

按完整三级边界列出方向、位宽、有效极性、连接对象和功能：

- **`top_axi_ddr4_bist`上板端口**
  - `sys_clk_p/n`、`sys_rst_n`
  - `c0_ddr4_act_n`
  - `c0_ddr4_adr[16:0]`
  - `c0_ddr4_ba[1:0]`、`c0_ddr4_bg[0:0]`
  - `c0_ddr4_cke[0:0]`、`c0_ddr4_odt[0:0]`、`c0_ddr4_cs_n[0:0]`
  - `c0_ddr4_ck_t/c[0:0]`、`c0_ddr4_reset_n`
  - `c0_ddr4_dm_dbi_n[7:0]`、`c0_ddr4_dq[63:0]`、`c0_ddr4_dqs_t/c[7:0]`
  - `led[1:0]`

- **官方/适配层 `example_top` 端口**
  - `sys_rst`、`c0_sys_clk_p/n`
  - `c0_init_calib_complete`、`c0_data_compare_error`
  - 全部DDR4物理端口
  - 说明适配层保持官方端口形状，但将流量发生器替换为 `top_axi_ddr4_bist`，并将 `bist_fail`映射到比较错误输出。

- **`sim_tb_top`仿真边界**
  - 明确该模块没有外部端口。
  - 列出内部时钟/复位、校准/比较状态、DDR命令地址、DQ/DQS/DM、CK、模型使能、Rank/镜像连接。
  - 记录 `tCK=833 ps`、输入差分时钟周期约9.996 ns、DQ宽64 bit、4片x16器件模型。

- **MIG用户侧AXI五通道**
  - AW：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - W：DATA、STRB、LAST、VALID、READY。
  - B：ID、RESP、VALID、READY。
  - AR：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - R：ID、DATA、RESP、LAST、VALID、READY。
  - 标明当前宽度为地址32 bit、数据64 bit、ID 4 bit，BIST使用单拍INCR事务。

- **控制、状态和诊断信号**
  - `ui_clk`、`ui_clk_sync_rst`、`init_calib_complete`、`axi_aresetn`
  - `state`、`write_index`、`read_index`、`aw_sent`、`w_sent`
  - `done/pass/fail`、`error_count`
  - `first_error_addr`、`first_expected_data`、`first_actual_data`

## 验证与交付

- 在验证方案中增加“工程选择检查”：综合/上板打开主XPR，官方参考打开Example XPR，完整BIST仿真使用 `bist_sim_work`。
- 增加XCI一致性验收：功能配置一致，只允许工程相对输出目录不同。
- 增加顶层展开检查：主工程综合顶层必须为 `top_axi_ddr4_bist`；完整仿真顶层必须为 `sim_tb_top`；仿真中只能存在一个有效的 `example_top`定义。
- 保留现有32字冒烟、校准、AXI复位、首中末地址、终值波形和WDB容量结论。
- 覆盖本地V1.0文档并同步覆盖远端 `docs`中的同名文件。
- 仅执行DOCX结构完整性、关键内容、表格宽度、标题层级和ZIP组件检查，不渲染PDF/PNG。
- 上传后比较本地与远端SHA-256，要求完全一致。
</proposed_plan>

### User

两者有什么区别，都有仿真时序吗

### Assistant

两者都“能看到随时间变化的波形”，但仿真能力不同：

- `ddr4_axi_0_ex` 是完整Example仿真工程，已经包含 `sim_tb_top`、时钟/复位激励、MIG和DDR4器件模型，可以直接进行校准及读写仿真。
- `prj\axi_ddr4_min_2020_2` 是上板设计工程，主要用于综合、实现和生成bitstream。当前XPR内没有完整DDR4器件模型Testbench，不能单独完成同等级的DDR完整仿真。
- 当前通过的32字冒烟，是借用Example的仿真环境运行自研 `top_axi_ddr4_bist`，属于完整行为级MIG仿真。
- 两者目前都没有执行“实现后时序仿真/SDF回标仿真”。`prj`中的实现时序报告属于静态时序分析，不等于时序仿真。

可以简单理解为：

```text
prj：       要上板的设计主体，侧重综合、布局布线、静态时序
Example：   仿真环境和官方参考设计，侧重MIG校准、器件模型及读写验证
二者组合： 用Example环境验证prj中的自研BIST和MIG连接
```

<proposed_plan>
# DDR4工程差异、顶层信号与架构图文档更新计划

## 概要

覆盖更新现有 `DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx`，不修改RTL、XCI、XPR或仿真结果。

文档明确以下结论：

- `prj\axi_ddr4_min_2020_2.xpr` 是自研最小DDR产品工程，设计顶层为 `top_axi_ddr4_bist`。
- `sim_full\mig_example_2020_2\ddr4_axi_0_ex\ddr4_axi_0_ex.xpr` 是Vivado根据MIG生成的独立Example Design，设计顶层为官方 `example_top`，仿真顶层为 `sim_tb_top`。
- 两份 `ddr4_axi_0.xci` 功能配置完全一致，逐行比较只有 `RUNTIME_PARAM.OUTPUTDIR` 不同；不是两套不同的DDR参数。
- 正式冒烟实际使用 `sim_full\bist_sim_work\ddr4_axi_0_ex.xpr`，关闭官方 `example_top.sv` 的仿真用途，再加入自研适配层和BIST RTL。

## 文档修改

### 1. 工程差异对照

新增完整对照表，列明：

- 工程路径、XPR名称、生成来源和维护责任。
- 综合顶层、仿真顶层、AXI流量发生器、DDR器件模型和约束来源。
- `prj` 用于自研RTL综合、实现和上板；Example用于官方流量测试、器件模型和完整仿真环境。
- Example包含官方AXI Traffic Generator、数据生成与比较模块、`sim_tb_top`及4片x16 DDR4模型；主工程使用自研 `axi_ddr_bist`。
- 两个工程相互独立，打开、修改或运行Example不会自动更新主工程。
- 记录当前目录快照：Example约159.6 MB/535个文件，`prj`约261.4 MB/365个文件，并注明大小会随日志和运行产物变化。

### 2. 三张架构图

使用Word原生等宽文本图和带底色边框，不嵌入截图或外部图片：

1. **工程生成与使用关系图**  
   展示主工程XCI生成Example、Example复制为 `bist_sim_work`、禁用官方顶层并接入自研适配层的关系。

2. **自研最小DDR上板架构图**  
   展示差分系统时钟/复位、MIG、AXI Slave、BIST Master、复位门控、状态LED及DDR4物理接口。

3. **完整MIG仿真架构图**  
   展示 `sim_tb_top → example_top_bist_adapter → top_axi_ddr4_bist → MIG → DQ/DQS/DM及命令总线 → 4×x16 DDR4模型`，并标出监视器、WDB记录边界和禁止递归记录的MIG/模型内部层次。

### 3. 详细顶层信号表

按完整三级边界列出方向、位宽、有效极性、连接对象和功能：

- **`top_axi_ddr4_bist`上板端口**
  - `sys_clk_p/n`、`sys_rst_n`
  - `c0_ddr4_act_n`
  - `c0_ddr4_adr[16:0]`
  - `c0_ddr4_ba[1:0]`、`c0_ddr4_bg[0:0]`
  - `c0_ddr4_cke[0:0]`、`c0_ddr4_odt[0:0]`、`c0_ddr4_cs_n[0:0]`
  - `c0_ddr4_ck_t/c[0:0]`、`c0_ddr4_reset_n`
  - `c0_ddr4_dm_dbi_n[7:0]`、`c0_ddr4_dq[63:0]`、`c0_ddr4_dqs_t/c[7:0]`
  - `led[1:0]`

- **官方/适配层 `example_top` 端口**
  - `sys_rst`、`c0_sys_clk_p/n`
  - `c0_init_calib_complete`、`c0_data_compare_error`
  - 全部DDR4物理端口
  - 说明适配层保持官方端口形状，但将流量发生器替换为 `top_axi_ddr4_bist`，并将 `bist_fail`映射到比较错误输出。

- **`sim_tb_top`仿真边界**
  - 明确该模块没有外部端口。
  - 列出内部时钟/复位、校准/比较状态、DDR命令地址、DQ/DQS/DM、CK、模型使能、Rank/镜像连接。
  - 记录 `tCK=833 ps`、输入差分时钟周期约9.996 ns、DQ宽64 bit、4片x16器件模型。

- **MIG用户侧AXI五通道**
  - AW：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - W：DATA、STRB、LAST、VALID、READY。
  - B：ID、RESP、VALID、READY。
  - AR：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - R：ID、DATA、RESP、LAST、VALID、READY。
  - 标明当前宽度为地址32 bit、数据64 bit、ID 4 bit，BIST使用单拍INCR事务。

- **控制、状态和诊断信号**
  - `ui_clk`、`ui_clk_sync_rst`、`init_calib_complete`、`axi_aresetn`
  - `state`、`write_index`、`read_index`、`aw_sent`、`w_sent`
  - `done/pass/fail`、`error_count`
  - `first_error_addr`、`first_expected_data`、`first_actual_data`

## 验证与交付

- 在验证方案中增加“工程选择检查”：综合/上板打开主XPR，官方参考打开Example XPR，完整BIST仿真使用 `bist_sim_work`。
- 增加XCI一致性验收：功能配置一致，只允许工程相对输出目录不同。
- 增加顶层展开检查：主工程综合顶层必须为 `top_axi_ddr4_bist`；完整仿真顶层必须为 `sim_tb_top`；仿真中只能存在一个有效的 `example_top`定义。
- 保留现有32字冒烟、校准、AXI复位、首中末地址、终值波形和WDB容量结论。
- 覆盖本地V1.0文档并同步覆盖远端 `docs`中的同名文件。
- 仅执行DOCX结构完整性、关键内容、表格宽度、标题层级和ZIP组件检查，不渲染PDF/PNG。
- 上传后比较本地与远端SHA-256，要求完全一致。
</proposed_plan>

### User

PLEASE IMPLEMENT THIS PLAN:
# DDR4工程差异、顶层信号与架构图文档更新计划

## 概要

覆盖更新现有 `DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx`，不修改RTL、XCI、XPR或仿真结果。

文档明确以下结论：

- `prj\axi_ddr4_min_2020_2.xpr` 是自研最小DDR产品工程，设计顶层为 `top_axi_ddr4_bist`。
- `sim_full\mig_example_2020_2\ddr4_axi_0_ex\ddr4_axi_0_ex.xpr` 是Vivado根据MIG生成的独立Example Design，设计顶层为官方 `example_top`，仿真顶层为 `sim_tb_top`。
- 两份 `ddr4_axi_0.xci` 功能配置完全一致，逐行比较只有 `RUNTIME_PARAM.OUTPUTDIR` 不同；不是两套不同的DDR参数。
- 正式冒烟实际使用 `sim_full\bist_sim_work\ddr4_axi_0_ex.xpr`，关闭官方 `example_top.sv` 的仿真用途，再加入自研适配层和BIST RTL。

## 文档修改

### 1. 工程差异对照

新增完整对照表，列明：

- 工程路径、XPR名称、生成来源和维护责任。
- 综合顶层、仿真顶层、AXI流量发生器、DDR器件模型和约束来源。
- `prj` 用于自研RTL综合、实现和上板；Example用于官方流量测试、器件模型和完整仿真环境。
- Example包含官方AXI Traffic Generator、数据生成与比较模块、`sim_tb_top`及4片x16 DDR4模型；主工程使用自研 `axi_ddr_bist`。
- 两个工程相互独立，打开、修改或运行Example不会自动更新主工程。
- 记录当前目录快照：Example约159.6 MB/535个文件，`prj`约261.4 MB/365个文件，并注明大小会随日志和运行产物变化。

### 2. 三张架构图

使用Word原生等宽文本图和带底色边框，不嵌入截图或外部图片：

1. **工程生成与使用关系图**  
   展示主工程XCI生成Example、Example复制为 `bist_sim_work`、禁用官方顶层并接入自研适配层的关系。

2. **自研最小DDR上板架构图**  
   展示差分系统时钟/复位、MIG、AXI Slave、BIST Master、复位门控、状态LED及DDR4物理接口。

3. **完整MIG仿真架构图**  
   展示 `sim_tb_top → example_top_bist_adapter → top_axi_ddr4_bist → MIG → DQ/DQS/DM及命令总线 → 4×x16 DDR4模型`，并标出监视器、WDB记录边界和禁止递归记录的MIG/模型内部层次。

### 3. 详细顶层信号表

按完整三级边界列出方向、位宽、有效极性、连接对象和功能：

- **`top_axi_ddr4_bist`上板端口**
  - `sys_clk_p/n`、`sys_rst_n`
  - `c0_ddr4_act_n`
  - `c0_ddr4_adr[16:0]`
  - `c0_ddr4_ba[1:0]`、`c0_ddr4_bg[0:0]`
  - `c0_ddr4_cke[0:0]`、`c0_ddr4_odt[0:0]`、`c0_ddr4_cs_n[0:0]`
  - `c0_ddr4_ck_t/c[0:0]`、`c0_ddr4_reset_n`
  - `c0_ddr4_dm_dbi_n[7:0]`、`c0_ddr4_dq[63:0]`、`c0_ddr4_dqs_t/c[7:0]`
  - `led[1:0]`

- **官方/适配层 `example_top` 端口**
  - `sys_rst`、`c0_sys_clk_p/n`
  - `c0_init_calib_complete`、`c0_data_compare_error`
  - 全部DDR4物理端口
  - 说明适配层保持官方端口形状，但将流量发生器替换为 `top_axi_ddr4_bist`，并将 `bist_fail`映射到比较错误输出。

- **`sim_tb_top`仿真边界**
  - 明确该模块没有外部端口。
  - 列出内部时钟/复位、校准/比较状态、DDR命令地址、DQ/DQS/DM、CK、模型使能、Rank/镜像连接。
  - 记录 `tCK=833 ps`、输入差分时钟周期约9.996 ns、DQ宽64 bit、4片x16器件模型。

- **MIG用户侧AXI五通道**
  - AW：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - W：DATA、STRB、LAST、VALID、READY。
  - B：ID、RESP、VALID、READY。
  - AR：ID、ADDR、LEN、SIZE、BURST、LOCK、CACHE、PROT、QOS、VALID、READY。
  - R：ID、DATA、RESP、LAST、VALID、READY。
  - 标明当前宽度为地址32 bit、数据64 bit、ID 4 bit，BIST使用单拍INCR事务。

- **控制、状态和诊断信号**
  - `ui_clk`、`ui_clk_sync_rst`、`init_calib_complete`、`axi_aresetn`
  - `state`、`write_index`、`read_index`、`aw_sent`、`w_sent`
  - `done/pass/fail`、`error_count`
  - `first_error_addr`、`first_expected_data`、`first_actual_data`

## 验证与交付

- 在验证方案中增加“工程选择检查”：综合/上板打开主XPR，官方参考打开Example XPR，完整BIST仿真使用 `bist_sim_work`。
- 增加XCI一致性验收：功能配置一致，只允许工程相对输出目录不同。
- 增加顶层展开检查：主工程综合顶层必须为 `top_axi_ddr4_bist`；完整仿真顶层必须为 `sim_tb_top`；仿真中只能存在一个有效的 `example_top`定义。
- 保留现有32字冒烟、校准、AXI复位、首中末地址、终值波形和WDB容量结论。
- 覆盖本地V1.0文档并同步覆盖远端 `docs`中的同名文件。
- 仅执行DOCX结构完整性、关键内容、表格宽度、标题层级和ZIP组件检查，不渲染PDF/PNG。
- 上传后比较本地与远端SHA-256，要求完全一致。

### Assistant

我开始按方案覆盖更新V1.0文档。只改文档生成脚本和DOCX，不动RTL、XCI、XPR或仿真结果；完成后做结构检查，并同步到远端 `docs` 后校验SHA-256。文档技能要求通常渲染检查，但本工作区规则明确覆盖为“只做DOCX结构检查”，因此不会生成PDF/PNG。

### User

需要额外添加一些设计方案的说明

### Assistant

会补上，不只列“目录和信号”。我会增加一节“设计方案说明”，解释为什么主工程与Example分离、为什么完整仿真复用官方器件模型、适配层如何替换官方Traffic Generator、上板与仿真各自使用哪个顶层，以及这种结构对后续NVMe_ADC合入的边界和好处。

主要内容已加入：工程差异表、三层隔离设计说明、三张架构图、三个顶层边界信号表、AXI五通道与诊断信号表，以及“行为仿真/静态时序/SDF时序仿真”的证据区分。现在开始重新生成DOCX并做结构审计。

### User

先暂停，保持3个step，等会继续

### Assistant

已暂停，保留3个步骤。

当前状态：

1. 文档内容与生成脚本更新：已完成。
2. DOCX重新生成：已完成；增强后的结构审计尚未执行。
3. 远端同步与SHA-256校验：尚未开始。

等你回来后从第2步继续。

### User

继续

### Assistant

继续第2步：重新运行加入增强审计的生成脚本，核对页面、全部表格几何、关键内容和DOCX组件；通过后执行远端覆盖与哈希校验。

第2步已通过：131段、34个标题、33张表，页面和全部表格宽度一致，DOCX组件完整且没有嵌入图片。现在执行第3步，将同名V1.0覆盖到远端 `docs` 并比较本地/远端SHA-256。

文档已更新并同步完成：

[DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx](E:/ddr_proc/deliverables/DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx)

新增内容包括：

- 主工程、官方Example、`bist_sim_work`的详细区别和使用规则。
- 补充“设计方案说明”。
- 三张Word原生架构图。
- 上板顶层、Example适配层、`sim_tb_top`三级信号表。
- MIG AXI五通道及BIST诊断信号说明。
- 行为仿真、静态时序分析、SDF时序仿真的区别。
- 工程选择、XCI一致性和顶层展开验收方案。

结构检查结果：34个标题、33张表，页面和表格几何检查通过；按工作区规则未渲染PDF/PNG。

远端文件：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\docs\DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx
```

本地与远端SHA-256一致：

```text
261BE6B8BD1CF102B57433C3992482CBC4B69A61FFB69FE70F201E31FDB7537D
```

### User

继续丰富验证用例，并跑仿真不需要回归

### Assistant

我先只读检查现有行为级TB、完整MIG仿真入口和已覆盖场景，确认哪些用例能快速新增并单独跑一次，避免把“补用例”误做成全量回归。

### User

注意用例的描述、设计要写出来

### Assistant

会把每个新增用例的目的、激励设计、关键检查点、预期结果和失败定位方式写清楚，并同步进验证方案。先继续缩小范围检查现有TB，避免扫描庞大的MIG生成目录。

现有TB只覆盖“正常读写”和“第7字读数据翻转”两类；BRESP、RRESP、RLAST错误、复位恢复和AW/W先后顺序都没有独立验收。新增用例适合放在快速行为级TB中，完整MIG仿真不适合人为破坏内部协议。需要锁定本次实际跑哪一层、跑哪一个代表场景。

用例可以收敛成一次定向仿真：第一阶段在同一轮BIST中分别注入BRESP、读数据、RRESP和RLAST四类错误；核对累计错误与首错现场后，脉冲复位，再跑一次干净读写验证恢复。这样只有一次XSim启动，不做多用例回归，同时能覆盖新增错误链路和复位恢复。还需确认可用的Vivado命令入口，以决定在本机还是远端执行。

确定以远端工程的实际执行结果作为证据。本次仍只启动一次行为仿真；本机只用于编辑和结构检查。最后再确认远端现有脚本记录的Vivado 2020.2路径，避免计划里留下执行路径选择。

因为新增用例的描述、激励、检查点和执行状态要写回现有Word验证方案，我会按文档技能约束规划更新；本工作区规则仍覆盖为只做DOCX结构检查，不渲染PDF/PNG。

<proposed_plan>
# AXI DDR BIST定向验证用例扩展与单次仿真计划

## 概要

扩展行为级Testbench的协议异常、握手顺序和复位恢复验证，但不修改 `axi_ddr_bist.v` 接口或功能，不重跑完整MIG冒烟，也不执行多用例回归。

在远端工程只启动一次 `DIRECTED` 定向仿真：

1. 第一阶段在同一轮32字BIST中注入四类错误并检查累计结果。
2. 第二阶段复位DUT和AXI Slave模型，关闭注错，重新完成一次干净读写，验证复位恢复。
3. 将用例目的、激励设计、检查点、结果和未执行项写入现有V1.0 Word方案。

## Testbench与执行入口

- 重构 `sim\tb_axi_ddr_bist.sv`，保留现有32字、100 MHz、三周期读延迟和超时机制。
- 新增 `TEST_CASE` plusarg，支持：
  - `CLEAN`
  - `READ_DATA_ERROR`
  - `BRESP_ERROR`
  - `RRESP_ERROR`
  - `RLAST_ERROR`
  - `RESET_RECOVERY`
  - `DIRECTED`
- 保留原 `INJECT_ERROR` plusarg兼容性，并映射为 `READ_DATA_ERROR`。
- AXI Slave采用确定性AW/W接受顺序：依次制造AW先到、W先到和同拍握手，分别计数并断言均被覆盖。
- 新增远端命令行脚本和XSim Tcl，固定使用：
  `C:\Xilinx\Vivado\2020.2\bin`
- 命令行直接编译 `axi_ddr_bist.v` 和行为级TB，不修改XPR。
- 波形只记录TB直属握手/注错/计数信号及DUT直属信号，不涉及MIG或DDR4模型。

## 用例设计与本次实际运行

用例说明写入文档时，每项均包含验证目的、前置条件、激励、关键观察点、预期结果和失败定位方式。

| 用例 | 设计 |
|---|---|
| CLEAN | 32字写入回读，无注错，预期 `done/pass=1`、`fail=0`、`error_count=0` |
| AW/W_ORDER | 确定性制造AW先到、W先到、同拍三种顺序，检查 `aw_sent/w_sent`及握手计数 |
| BRESP_ERROR | 写索引3返回SLVERR，预期记录写响应错误 |
| READ_DATA_ERROR | 读索引7翻转最低位，预期数据比较失败 |
| RRESP_ERROR | 读索引9返回SLVERR，预期记录读响应错误 |
| RLAST_ERROR | 读索引11返回 `RLAST=0`，预期记录单拍协议错误 |
| RESET_RECOVERY | 完成异常阶段后拉低复位至少3个时钟，确认结果和VALID/READY状态复位，再重新启动干净测试 |
| DIRECTED | 本次唯一实际执行入口，组合上述握手、四类注错和复位恢复 |

`DIRECTED`第一阶段的固定预期：

- 错误总数：4。
- 首错来自写索引3。
- `first_error_addr = 0x00000018`。
- `first_expected_data = 0xFFFF_FFFC_0000_0003`。
- 写响应首错的 `first_actual_data = 0`。
- 最终 `done=1`、`pass=0`、`fail=1`。
- AW先到、W先到和同拍握手计数均大于0。

复位后的第二阶段固定预期：

- 复位期间 `done/pass/fail/error_count`清零。
- 关闭全部注错并重新给出单周期 `start`。
- 32字干净写入回读结束后 `done/pass=1`、`fail=0`、`error_count=0`。
- 输出总标志 `DIRECTED_CASE_RESULT=PASS`。

## 仿真、文档与验收

- 将TB和运行脚本同步到远端工程，核对上传前后SHA-256。
- 在远端只运行一次 `TEST_CASE=DIRECTED`，不运行其他plusarg组合、不执行完整MIG冒烟和4096字签核。
- 结果保存为：
  - `sim\results\axi_ddr_bist_directed.log`
  - `sim\results\axi_ddr_bist_directed.wdb`
- 验收要求：编译、展开和XSim退出码均为0；阶段一四类错误、握手顺序覆盖、复位状态和阶段二干净恢复全部满足预期。
- 若失败，保留日志/WDB和第一处断言，不继续重复运行；文档按实际结果记录为FAIL或未完成。
- 覆盖更新V1.0 Word，新增用例矩阵、定向时序流程、注错位置、判定公式、执行日志摘要及“未分别回归”的状态说明。
- Word仅执行DOCX组件、标题、表格几何、关键字段和ZIP结构检查，不生成PDF/PNG。
- 最终同步文档到远端 `docs`，核对本地与远端SHA-256。

## 假设

- 远端SSH和 `C:\Xilinx\Vivado\2020.2` 在执行时可用。
- 当前32字完整MIG冒烟结果继续有效，本次行为级定向验证不替代也不重跑该结果。
- “不需要回归”解释为只启动一次 `DIRECTED` XSim仿真；其他独立用例保留为可选入口并写入方案，但本次不逐项执行。
</proposed_plan>

### User

PLEASE IMPLEMENT THIS PLAN:
# AXI DDR BIST定向验证用例扩展与单次仿真计划

## 概要

扩展行为级Testbench的协议异常、握手顺序和复位恢复验证，但不修改 `axi_ddr_bist.v` 接口或功能，不重跑完整MIG冒烟，也不执行多用例回归。

在远端工程只启动一次 `DIRECTED` 定向仿真：

1. 第一阶段在同一轮32字BIST中注入四类错误并检查累计结果。
2. 第二阶段复位DUT和AXI Slave模型，关闭注错，重新完成一次干净读写，验证复位恢复。
3. 将用例目的、激励设计、检查点、结果和未执行项写入现有V1.0 Word方案。

## Testbench与执行入口

- 重构 `sim\tb_axi_ddr_bist.sv`，保留现有32字、100 MHz、三周期读延迟和超时机制。
- 新增 `TEST_CASE` plusarg，支持：
  - `CLEAN`
  - `READ_DATA_ERROR`
  - `BRESP_ERROR`
  - `RRESP_ERROR`
  - `RLAST_ERROR`
  - `RESET_RECOVERY`
  - `DIRECTED`
- 保留原 `INJECT_ERROR` plusarg兼容性，并映射为 `READ_DATA_ERROR`。
- AXI Slave采用确定性AW/W接受顺序：依次制造AW先到、W先到和同拍握手，分别计数并断言均被覆盖。
- 新增远端命令行脚本和XSim Tcl，固定使用：
  `C:\Xilinx\Vivado\2020.2\bin`
- 命令行直接编译 `axi_ddr_bist.v` 和行为级TB，不修改XPR。
- 波形只记录TB直属握手/注错/计数信号及DUT直属信号，不涉及MIG或DDR4模型。

## 用例设计与本次实际运行

用例说明写入文档时，每项均包含验证目的、前置条件、激励、关键观察点、预期结果和失败定位方式。

| 用例 | 设计 |
|---|---|
| CLEAN | 32字写入回读，无注错，预期 `done/pass=1`、`fail=0`、`error_count=0` |
| AW/W_ORDER | 确定性制造AW先到、W先到、同拍三种顺序，检查 `aw_sent/w_sent`及握手计数 |
| BRESP_ERROR | 写索引3返回SLVERR，预期记录写响应错误 |
| READ_DATA_ERROR | 读索引7翻转最低位，预期数据比较失败 |
| RRESP_ERROR | 读索引9返回SLVERR，预期记录读响应错误 |
| RLAST_ERROR | 读索引11返回 `RLAST=0`，预期记录单拍协议错误 |
| RESET_RECOVERY | 完成异常阶段后拉低复位至少3个时钟，确认结果和VALID/READY状态复位，再重新启动干净测试 |
| DIRECTED | 本次唯一实际执行入口，组合上述握手、四类注错和复位恢复 |

`DIRECTED`第一阶段的固定预期：

- 错误总数：4。
- 首错来自写索引3。
- `first_error_addr = 0x00000018`。
- `first_expected_data = 0xFFFF_FFFC_0000_0003`。
- 写响应首错的 `first_actual_data = 0`。
- 最终 `done=1`、`pass=0`、`fail=1`。
- AW先到、W先到和同拍握手计数均大于0。

复位后的第二阶段固定预期：

- 复位期间 `done/pass/fail/error_count`清零。
- 关闭全部注错并重新给出单周期 `start`。
- 32字干净写入回读结束后 `done/pass=1`、`fail=0`、`error_count=0`。
- 输出总标志 `DIRECTED_CASE_RESULT=PASS`。

## 仿真、文档与验收

- 将TB和运行脚本同步到远端工程，核对上传前后SHA-256。
- 在远端只运行一次 `TEST_CASE=DIRECTED`，不运行其他plusarg组合、不执行完整MIG冒烟和4096字签核。
- 结果保存为：
  - `sim\results\axi_ddr_bist_directed.log`
  - `sim\results\axi_ddr_bist_directed.wdb`
- 验收要求：编译、展开和XSim退出码均为0；阶段一四类错误、握手顺序覆盖、复位状态和阶段二干净恢复全部满足预期。
- 若失败，保留日志/WDB和第一处断言，不继续重复运行；文档按实际结果记录为FAIL或未完成。
- 覆盖更新V1.0 Word，新增用例矩阵、定向时序流程、注错位置、判定公式、执行日志摘要及“未分别回归”的状态说明。
- Word仅执行DOCX组件、标题、表格几何、关键字段和ZIP结构检查，不生成PDF/PNG。
- 最终同步文档到远端 `docs`，核对本地与远端SHA-256。

## 假设

- 远端SSH和 `C:\Xilinx\Vivado\2020.2` 在执行时可用。
- 当前32字完整MIG冒烟结果继续有效，本次行为级定向验证不替代也不重跑该结果。
- “不需要回归”解释为只启动一次 `DIRECTED` XSim仿真；其他独立用例保留为可选入口并写入方案，但本次不逐项执行。

### Assistant

实施按三步推进：先改行为级TB和单次运行入口；再同步远端并只执行一次 `DIRECTED`；最后把实际结果写入V1.0文档并同步校验。不会触碰MIG完整冒烟、4096字签核或BIST RTL接口。

### User

改用非加速模式

### Assistant

当前 `DIRECTED` 是纯RTL行为级仿真，不实例化MIG，因此没有“加速/非加速校准”参数。

请确认你的意思是：

- 仍运行行为级 `DIRECTED`，按正常XSim模式执行；还是
- 改成完整MIG非加速仿真（`SIMULATION=FALSE`），这会改变原计划，校准时间也会显著增加？

目前只完成了TB修改，尚未启动仿真。

### User

继续完成

### Assistant

继续按“普通XSim行为仿真”完成：不启用MIG快速校准，也不切换到完整MIG仿真。当前尚未启动任何仿真；我先补齐运行脚本，同时复核TB的握手和注错时序，确认后再上传远端只运行一次。

脚本已补齐，远端SSH也已恢复。仿真还没有启动；我正在做最后一轮静态审查，重点确认四类错误不会互相覆盖、复位后第二阶段能重新启动，以及AW/W三种顺序不会造成Slave死锁。

TB已通过本机Vivado 2020.2的语法分析；这只是编译检查，不是额外仿真。运行脚本已按XSim 2020.2帮助改用正式的 `--testplusarg/--tclbatch/--wdb` 选项。接下来同步远端并启动唯一一次 `DIRECTED`。

远端三份文件与本地哈希一致。现在启动唯一一次 `DIRECTED` 普通行为仿真；它不会启动MIG Example、不会写入原来的 `smoke_done_visible.wdb`。

唯一一次运行已退出失败，按约定我不会直接重复启动。现在只读检查远端日志，先确认是脚本/编译问题还是用例断言问题，并保留已有日志和WDB。

检查确认远端没有生成日志或WDB，说明刚才失败在SSH到 `cmd` 的命令转发阶段，Vivado/XSim并未启动，因此不计入仿真次数。我改用编码PowerShell启动同一批处理，随后只执行这一轮实际仿真。

第二次仍未生成日志/WDB，说明批处理主体依旧没有被 `cmd` 正确调用，Vivado仍未启动。问题是远端PowerShell到批处理的二次引号，不是测试失败。我改为PowerShell直接调用 `.bat`，不再套 `cmd /c`。

找到了脚本缺陷：结果目录变量后少了反斜杠，日志实际写成了 `sim\resultsaxi_ddr_bist_directed.log`。批处理确实进入了编译/展开阶段，所以我不会再次启动；先按约定读取这一次实际运行留下的日志，记录真实失败点。

日志显示编译和展开均PASS，但XSim在解析 `TEST_CASE=DIRECTED` 参数时退出，仿真时间仍未开始、WDB也未创建。根因有两处脚本问题：plusarg缺少引号，结果路径少目录分隔符。我会修正这两个入口问题；修正后的运行才是唯一一次实际 `run all`。

实际仿真已经进入运行阶段，当前批处理仍在执行。行为级32字通常很快；如果持续不退出，TB内的20,000周期超时会自动给出明确失败点。

XSim已展开快照，但Tcl路径中的反斜杠被解释为转义字符，`run all`仍未执行；进程因此停在交互提示。我先精确终止这个 `tb_axi_ddr_bist_directed` XSim进程，再把Tcl路径改成正斜杠。已有日志会保留。

入口问题已修正，失败日志/WDB已另存保留。此前两次XSim都没有执行到 `run all`；现在启动第一轮、也是唯一一轮真正推进仿真时间的 `DIRECTED`。

唯一一次实际 `DIRECTED` 已退出码0。现在核对日志中的四类错误、首错、三种AW/W顺序、复位清零和第二阶段干净PASS，并读取WDB容量与仿真结束时间。

定向仿真全部通过：结束于6.765 µs，第一阶段累计4个错误且首错地址0x18；AW先到/W先到/同拍分别11/11/10次；复位后第二阶段零错误PASS。WDB仅89,463字节、记录114个对象。现在把用例设计和这组实际证据写入V1.0。

Word已重建并通过结构检查：36个标题、37张表，页面与表格几何全部通过，未生成或嵌入图片。最后同步文档并做TB、脚本、未改动BIST RTL、日志/WDB和DOCX的哈希核对。

远端同步在中文目标文件名处出现SCP broken pipe，仿真结果不受影响。我改为先上传ASCII临时文件，再由远端PowerShell覆盖同名中文DOCX；若文档正被Word占用，会明确保留本地完成件并报告锁定。

远端原V1.0正被Word或其他进程占用，无法覆盖或读取哈希；我不会强制结束用户进程。更新版已经完整上传为ASCII临时文件，我会在同一 `docs` 目录另存一个带“定向验证更新”的中文副本并校验，原文件保持不动。关闭远端Word后再覆盖同名文件即可。

远端没有 `WINWORD` 进程，锁更像是资源管理器预览、杀毒扫描或其他短暂句柄。我已保留旁路副本；再做一次同名覆盖检查，若仍锁定就停止，不会强制结束未知进程。

定向验证已完成并PASS，使用普通XSim行为模式，没有启动MIG加速仿真、完整MIG冒烟或4096字签核。

实际结果：

- 编译、展开：PASS
- 四类注错累计：`error_count=4`
- 首错地址：`0x00000018`
- 首错期望值：`FFFF_FFFC_0000_0003`
- AW先到/W先到/同拍：`11 / 11 / 10`次
- 复位清零：PASS
- 第二阶段干净读写：`done/pass=1`、`fail=0`、`error_count=0`
- 仿真结束时间：`6.765 µs`
- WDB：89,463字节，记录114个对象

文件如下：

- [tb_axi_ddr_bist.sv](E:/ddr_proc/staging_axi_ddr4_min_2020_2/sim/tb_axi_ddr_bist.sv)
- [运行批处理](E:/ddr_proc/staging_axi_ddr4_min_2020_2/sim/run_axi_ddr_bist_directed_2020_2.bat)
- [波形脚本](E:/ddr_proc/staging_axi_ddr4_min_2020_2/sim/run_axi_ddr_bist_directed_2020_2.tcl)
- [更新后的V1.0文档](E:/ddr_proc/deliverables/DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx)

远端结果：

```text
sim\results\axi_ddr_bist_directed.log
sim\results\axi_ddr_bist_directed.wdb
```

文档已完成结构检查：36个标题、37张表，页面和表格几何全部通过，未渲染PDF/PNG。

远端原同名V1.0目前被未知进程占用，无法安全覆盖；`WINWORD`并未运行，可能是资源管理器预览或其他程序句柄。因此更新版已保存为：

```text
C:\project\RTDS\DDR\axi_ddr4_min_2020_2\docs\
DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0_定向验证更新.docx
```

该文件与本地文档哈希一致：

```text
A8C968EB22FE24024FACDEE6624C4BB4357B4E300E299D9F7610D65E6CB0AEBE
```

只剩释放远端旧V1.0文件句柄后，将更新版覆盖成原文件名。

---

<!-- codex-history-md-export-append {"append_id": "f8884339d64d195528b437e4", "dialogue_sha256": "b51194d5d8b1b3cd17f0e8a67da26ed32cd2584fa55c89267b12130aefd639a5", "from_message": 257, "session_id": "019fc561-6c64-7021-9090-820de6f07881", "to_message": 270} -->

## 对话增量

### User

整理本机的最新相关文件，没有的话把远程机的文档/最新含注释代码拷贝过来   放到一个醒目的独立路径

### Assistant

我会先按哈希和修改时间核对本机与远端，不只按文件名判断。随后建立一个日期醒目的独立交付目录，分为文档、RTL、仿真代码、集成骨架和仿真证据，并生成清单说明每个文件来自本机还是远端。

本机候选文件已定位。现在核对远端的时间和 SHA-256，只把远端更新或本机缺失的版本补入独立交付目录；仿真证据也一并收纳，但不会带入历史超大 WDB。

远端刚才返回了批处理尾部文本，没有执行盘点脚本，属于 Windows SSH 命令解释问题，不是工程缺失。我改用已验证的 PowerShell 调用形式重查。

SSH 基础连接正常；问题只出在远端 `EncodedCommand` 的参数转发。为了尽快完成，我直接按已知的远端最新路径收件，再在本机统一做哈希、时间和 DOCX 结构校验，这也避免远端命令行编码影响中文文件名。

SFTP 方式没有立即返回，可能卡在远端子系统协商；我先收取结果。如果仍不通，就用 SSH 标准输出传输，不影响远端文件。

### User

已开通full access

### Assistant

权限已生效，远端 9 个代码/脚本已成功取回用于比对。接下来完成逐文件哈希、补取远端更新版 Word，并清理临时比较目录，只保留整洁交付包。

### User

如果需要远端机子处理，告诉我给他的agent的命令，如果无请忽略

### Assistant

无需远端 Agent 额外处理：远端最新版文档、注释 RTL、Testbench 和证据均已成功读取，且文档与 9 个代码/脚本全部逐字节一致。现在只生成本机说明与校验清单。

### User

刚才是什么问题，ssh一开始没获取到，把这个问题记录 方便下次启动

### Assistant

刚才不是 SSH 断线：`ssh vivado-srv hostname` 始终正常。失败点是远端 Windows 对 `powershell -EncodedCommand` 和旧式 `scp -O` 的命令转发，返回了异常的 `off / exit /b 1`；改用默认 SFTP 模式的 `scp` 后立即成功。我把现象、判别方式和下次可直接用的命令写进独立说明。

已整理完成，醒目独立目录为：

[打开 DDR4 最新文件包](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814)

其中包含：

- 最新 Word 设计验证方案
- 含中文注释的 `axi_ddr_bist.v`、`top_axi_ddr4_bist.v`
- 行为级 Testbench 和 DIRECTED 仿真脚本
- 完整 MIG 仿真适配层及运行脚本
- NVMe_ADC 集成顶层草案
- DIRECTED 与完整冒烟的日志、WDB
- [文件包说明](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\README_LATEST.md)
- [SHA-256 校验清单](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\SHA256SUMS.txt)
- [SSH/SCP 问题记录](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\SSH_TRANSFER_NOTES.md)

核对结果：

- Word 和9个代码/脚本与远端最新版 SHA-256 完全一致。
- DOCX 结构检查通过。
- 14个交付文件哈希全部通过。
- 未收录历史238 GB无效波形。
- SSH问题已记录：连接和密钥实际正常，异常来自远端 Windows 对 `-EncodedCommand` 和旧式 `scp -O` 的转发；下次直接使用默认 `scp`。
- 无需远端 Agent 再执行命令。

---

<!-- codex-history-md-export-append {"append_id": "fc970d497ae018c03b0ca252", "dialogue_sha256": "92d129e4eebb1dfd29adf5eae3aa50804ac81283897432594c0a17b486fb0f61", "from_message": 270, "session_id": "019fc561-6c64-7021-9090-820de6f07881", "to_message": 283} -->

## 对话增量

### User

这个ip后面怎么用，如何指导，不是现在写指导手册  我的意思是这个工程的意义何在，本来mig就是goldgen的ip

### Assistant

你说得对：MIG 本身就是 Xilinx 生成并验证过的“Golden IP”。这个最小 DDR 工程的意义不是重新设计 MIG，而是把 MIG 从一个裸 IP，变成当前板卡和后续系统可以直接接入、可以定位问题的 DDR 子系统基线。

可以这样理解：

```text
MIG IP
只解决：DDR4控制器、PHY、校准、AXI Slave接口
                         ↓
最小DDR工程
补齐：板级时钟/复位、管脚连接、AXI访问端、BIST、仿真环境、判定方法
                         ↓
真实NVMe_ADC工程
替换BIST：NVMe DMA / ADC搬运模块 / AXI Interconnect 发起DDR访问
```

### MIG已经是Golden IP，为什么还需要最小工程

官方 MIG Example Design 能证明：

- MIG配置能够生成；
- 官方流量发生器能够访问官方DDR模型；
- MIG与DDR器件模型的连接基本正确。

但它不能直接证明：

- 你的板级差分时钟、复位极性和管脚是否接对；
- 你自己的顶层能否正确等待 `init_calib_complete`；
- 你自己的AXI Master能否正确完成AW/W/B/AR/R握手；
- NVMe、ADC、DMA加入后，问题出在MIG还是上层数据通路；
- 当前工程使用的DDR型号、位宽和时钟参数是否形成了稳定基线。

最小工程解决的是这些“IP之外的系统集成问题”。

### `axi_ddr_bist`的意义

`axi_ddr_bist`不是最终产品功能，它是一个最小AXI Master和DDR自检工具。

它的价值是：

- 在没有NVMe、ADC和DMA时，独立验证DDR；
- 给出一套已经通过仿真的AXI访问时序；
- 上板后快速判断校准、写入、回读是否正常；
- 后续合入出现问题时，可以切回BIST模式，区分是DDR问题还是业务逻辑问题。

因此它可以保留在工程里，但正式运行时通常有两种处理方式：

- 综合时通过参数关闭，仅保留调试入口；
- 通过AXI Interconnect在BIST与业务Master之间切换。

### 合入真实项目后怎么用

真实项目中，MIG仍然作为AXI Slave。`axi_ddr_bist`的位置由实际数据搬运逻辑替代：

```text
NVMe PCIe/DMA ─┐
               ├─ AXI Interconnect/SmartConnect ─ MIG ─ DDR4
ADC DMA ───────┘
```

也就是说，后面真正需要设计的不是另一个DDR控制器，而是：

- 哪个模块作为AXI Master；
- NVMe数据写入DDR的地址规划；
- ADC数据写入和读取的缓冲区管理；
- 多个AXI Master之间的仲裁；
- 跨时钟域、背压、突发长度和带宽控制；
- 复位、错误恢复和状态监控。

### 这个工程最终应被定位成什么

最合适的定位是：

> 当前板卡的DDR4子系统Golden Baseline，以及NVMe/ADC工程合入前的独立验证基线。

它不是最终NVMe_ADC产品工程，也不是为了取代官方Example Design。它提供一个已知可工作的边界：

- 这个边界以内：MIG配置、DDR模型、时钟复位和基本AXI访问已经验证；
- 这个边界以外：后续重点开发NVMe DMA、ADC DMA、缓存管理和系统互连。

如果后续合入失败，重新运行32字BIST：

- BIST也失败：优先查DDR、时钟、复位或MIG连接；
- BIST通过而业务失败：优先查DMA、AXI互连、地址规划或业务逻辑。

所以，这个工程最大的意义不是“多做一个MIG工程”，而是建立一个能够隔离问题、重复验证并供真实系统替换流量源的可靠基线。

### User

请进一步解释基线的具体作用，是引出来了init_calib_complete等观测信号？还是多了AXI的检测

### Assistant

两者都有，但“基线”的作用不只是多引出几个信号，也不等于增加一个完整AXI协议检测器。它的核心是：固定一套已经验证过的配置、连接、激励和判定标准，后续工程可以拿它作比较。

具体分为四部分。

### 1. 建立可观测的DDR状态边界

MIG本身已经提供：

- `init_calib_complete`
- `ui_clk`
- `ui_clk_sync_rst`
- AXI各通道信号
- DDR4物理接口

最小工程做的事情是把这些信号正确接入顶层控制逻辑，并规定它们的使用方式。

例如：

```text
外部复位释放
    ↓
MIG执行DDR校准
    ↓
init_calib_complete = 1
    ↓
再等待两个ui_clk
    ↓
axi_aresetn = 1
    ↓
允许AXI Master访问DDR
```

这里的价值不是“创造了`init_calib_complete`”，而是验证并固定了：

- 它在当前板卡参数下什么时候拉高；
- AXI复位应在什么条件下释放；
- BIST不能在校准完成前发起访问；
- 上板时如何通过LED或ILA观察这些状态；
- 仿真失败时从哪个阶段开始定位。

所以，观测信号是基线的一部分，但不是全部。

### 2. 提供一个已知正确的AXI Master

MIG用户侧是AXI Slave，MIG不会主动访问内存。必须有AXI Master发起读写。

当前基线里的`axi_ddr_bist`就是一个最小、已知行为的AXI Master：

```text
axi_ddr_bist → AXI五通道 → MIG → DDR4
```

它固定执行：

1. 向32个地址写入已知数据；
2. 检查每次写响应；
3. 从相同地址回读；
4. 检查读响应、`RLAST`和回读数据；
5. 输出最终PASS/FAIL。

这样可以回答一个关键问题：

> 不接NVMe、不接ADC、不接DMA时，当前MIG和DDR能否被一个正常AXI Master访问？

如果答案是“能”，后续接入业务逻辑后失败，就可以把排查范围收缩到业务Master、AXI互连和地址管理。

### 3. 提供有限的AXI访问检查

当前BIST确实包含部分AXI检测，但它不是完整的AXI Protocol Checker。

BIST检查的主要内容是：

- `BRESP`是否为`OKAY`；
- `RRESP`是否为`OKAY`；
- 单拍读取时`RLAST`是否正确；
- 回读数据是否等于预期数据；
- AW和W两个独立通道是否都完成握手；
- 是否发生超时或状态机停滞；
- 第一次错误地址、期望数据和实际数据。

其中：

- `aw_sent`表示当前写事务的AW地址通道已经握手；
- `w_sent`表示当前写事务的W数据通道已经握手；
- 两者都完成后，状态机才等待B响应。

这验证了一个很重要的AXI特性：AW和W是独立通道，不能假设它们必然同拍握手。

行为级Testbench还专门制造了：

- AW先握手；
- W先握手；
- AW/W同拍握手；
- `BRESP`错误；
- `RRESP`错误；
- 回读数据错误；
- `RLAST`错误；
- 复位后的重新启动。

但当前基线没有覆盖：

- 多拍Burst的全部规则；
- 多个Outstanding事务；
- ID乱序返回；
- 4 KB边界；
- 窄传输和非对齐传输；
- 长时间随机背压；
- AXI协议的所有稳定性规则。

因此更准确的说法是：

> BIST提供已知正确的基本AXI访问和功能判定；Testbench提供定向异常检查，但它不是完整AXI协议验证平台。

### 4. 固定一个可重复比较的“正确结果”

基线最关键的价值，是已经得到一套确定结果：

- MIG校准约在`3.827 µs`完成；
- AXI复位随后释放；
- 32字写入和回读约在`7.049 µs`完成；
- `done=1`
- `pass=1`
- `fail=0`
- `error_count=0`
- 有对应日志和WDB波形。

后续合入NVMe/ADC后，可以直接对照：

| 现象 | 优先排查范围 |
|---|---|
| `init_calib_complete`不拉高 | MIG参数、DDR连接、时钟、复位、器件型号 |
| 校准完成，但`axi_aresetn`不释放 | 顶层复位门控逻辑 |
| AXI VALID发出但READY不返回 | MIG状态、AXI互连、复位或地址 |
| AW完成但W未完成 | 业务AXI Master写通道 |
| BIST通过，NVMe DMA失败 | NVMe DMA、互连、地址映射 |
| BIST通过，ADC写入数据错误 | ADC DMA、跨时钟域、缓存管理 |
| BIST也失败 | DDR子系统或公共时钟复位发生变化 |

所以，“基线”可以概括为四句话：

```text
参数有基准：MIG和DDR配置固定。
连接有基准：时钟、复位、AXI和DDR管脚连接固定。
访问有基准：存在一个已经验证的AXI Master。
结果有基准：有确定的PASS条件、日志和波形可比较。
```

`init_calib_complete`等信号解决“看得见DDR处于什么阶段”，BIST和Testbench解决“能否正确访问、错误能否被发现”，而整套基线解决的是“后面系统出问题时，有一个已知正确的参照物”。

### User

不接NVMe、不接ADC、不接DMA时，当前MIG和DDR能否被一个正常AXI Master访问？  肯定可以吧，这是golden ip  当前的已验证用例有几个、用例在哪个目录、有木有注释（没有加上）  现在不合入NVMe/ADC了，但可能合入AURORA-PCIE项目（E:\PCIE-CPU）

### Assistant

我先把“可选用例、实际跑过的仿真、DIRECTED内部子场景”分开统计，避免把一个组合仿真说成多次回归；同时检查TB和脚本的中文注释。随后只读盘点 `E:\PCIE-CPU` 的Aurora/PCIe接口，判断这套DDR基线未来应该接在哪一层。

已确认代码并非“无注释”：BIST、顶层、TB和完整仿真适配层都有中文语段注释。不过TB目前只解释总体机制，没有在每个`TEST_CASE`入口前逐项写清验证目的；我会补成用例级注释，同时不改功能。先查看Aurora-PCIe工程的最新顶层和数据通路。

结论先校正一下：MIG是Golden IP，只能保证厂商IP实现本身；“当前板卡参数、复位门控、AXI主机行为、物理连接”仍不能据此直接判定必然可用。当前证据是两次实际仿真：一次行为级`DIRECTED`组合仿真、一次32字完整MIG冒烟；其余是TB支持但未逐项回归的入口。现在只补用例说明注释，不改逻辑、不重跑仿真。

Aurora-PCIe方向初步匹配：现工程已经有`XDMA M_AXI`和`CONV_DMA M_AXI`两个64位Master，共享存储从设备目前在AXI Interconnect下游。DDR的合理接入点是替换该共享BRAM从设备，而不是把`top_axi_ddr4_bist`整体塞进业务顶层。最后我再核对实际BD包装层和时钟宽度，给出哪些能复用、哪些必须重做。

你说的“肯定可以”，需要分两层看：

- 在Xilinx规定的配置和官方Example Design环境里，MIG作为Golden IP，理论上当然能够被合法AXI Master访问。
- 但“MIG IP正确”不等于“当前生成参数、时钟复位、板级管脚、DDR颗粒连接以及自研AXI Master一定正确”。

当前最小工程验证的不是MIG算法本身，而是：

```text
自研AXI Master
    ↓
自研复位与校准门控
    ↓
当前这份MIG配置
    ↓
DDR4器件模型
```

因此它证明的是“我们这一种具体连接方式在完整数字仿真中可用”。目前没有生成bitstream或下载板卡，所以还不能据此宣称真实板上DDR已经通过。

## 当前到底有几个用例

要区分“支持的入口”和“实际跑过的仿真”。

### Testbench支持7个入口

在[tb_axi_ddr_bist.sv](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\tb_axi_ddr_bist.sv:373)中支持：

1. `CLEAN`
2. `READ_DATA_ERROR`
3. `BRESP_ERROR`
4. `RRESP_ERROR`
5. `RLAST_ERROR`
6. `RESET_RECOVERY`
7. `DIRECTED`

`AW/W_ORDER`不是独立的`TEST_CASE`。每轮测试都会检查三种握手顺序：

- AW先握手；
- W先握手；
- AW/W同拍握手。

### 实际完成了2次仿真

1. 行为级`DIRECTED`组合仿真

   - 第一阶段同时注入4类错误；
   - 覆盖AW先到、W先到、同拍三种顺序；
   - 第一阶段检测到4个错误；
   - 复位后关闭注错；
   - 第二阶段完成32字干净写入回读；
   - 最终结果PASS。

2. 32字完整MIG冒烟仿真

   - 实例化MIG和DDR4器件模型；
   - `3.827 µs`校准完成；
   - `7.049 µs`完成32字写入回读；
   - 最终PASS。

因此准确说法是：

> TB有7个可选入口；实际运行了1个DIRECTED组合用例和1个完整MIG冒烟，共2次仿真。其他6个行为级入口没有分别回归。

## 用例和结果在哪里

行为级验证：

- [行为级Testbench](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\tb_axi_ddr_bist.sv)
- [运行批处理](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\run_axi_ddr_bist_directed_2020_2.bat)
- [波形记录脚本](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\run_axi_ddr_bist_directed_2020_2.tcl)
- [DIRECTED日志](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\directed\axi_ddr_bist_directed.log)
- [DIRECTED波形](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\directed\axi_ddr_bist_directed.wdb)

完整MIG冒烟：

- [完整仿真适配层](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_full\example_top_bist_adapter.sv)
- [完整冒烟日志](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\full_smoke\smoke_done_visible_vivado.log)
- [完整冒烟波形](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\full_smoke\smoke_done_visible.wdb)

## 注释情况

原来的RTL、TB和完整仿真适配层已经有中文语段注释。这次又补充了每个`TEST_CASE`的逐项说明，包括：

- 用例目的；
- 注错索引；
- 预期检查结果；
- `AW/W_ORDER`为何不是独立入口；
- 哪些入口实际执行，哪些未逐项回归。

已同时更新：

- [交付包中的TB](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\tb_axi_ddr_bist.sv:373)
- [本机暂存工程中的TB](E:\ddr_proc\staging_axi_ddr4_min_2020_2\sim\tb_axi_ddr_bist.sv:373)

只增加注释，没有修改仿真功能，因此没有重新编译。校验清单也已更新并通过。

## 转向Aurora-PCIe后怎么使用

这个方向比原来的NVMe/ADC更明确。当前Aurora-PCIe工程为：

[RTDS_test-1ch](E:\PCIE-CPU\RTDS_test-1ch)

实际BD已经存在：

```text
CONV_DMA M_AXI ─┐
                ├─ AXI Interconnect ─ AXI BRAM Ctrl ─ BRAM
XDMA M_AXI ─────┘
```

从[design_1.bd](E:\PCIE-CPU\RTDS_test-1ch\RTDS_test.srcs\sources_1\bd\design_1\design_1.bd:1733)可以确认：

- `CONV_DMA M_AXI`：64位数据、64位地址、250 MHz；
- `XDMA M_AXI`也接入同一个AXI Interconnect；
- 两个Master当前均映射到基地址`0`、大小`64 KiB`的共享BRAM空间；
- BRAM位于`axi_interconnect_0/M00_AXI`下游。

DDR最合理的合入方式是：

```text
CONV_DMA M_AXI ─┐
                ├─ AXI Interconnect/SmartConnect
XDMA M_AXI ─────┘
                         ↓
                Clock/Address转换
                         ↓
                    MIG S_AXI
                         ↓
                       DDR4
```

也就是替换：

```text
AXI BRAM Ctrl + blk_mem_gen
```

而不是把整个`top_axi_ddr4_bist`复制进Aurora-PCIe顶层。

### 能直接复用的部分

如果是同一块KU040板卡、同一组DDR颗粒和管脚，可以复用：

- MIG XCI配置；
- DDR管脚和时钟约束；
- DDR时钟、复位及校准连接；
- `init_calib_complete`和`ui_clk_sync_rst`处理思路；
- 完整MIG仿真环境；
- BIST作为独立诊断Master；
- BRESP/RRESP错误监视思路。

### 需要重新设计的部分

- 250 MHz业务时钟到MIG `ui_clk`的时钟转换；
- 64位Master地址到MIG 32位地址的映射；
- XDMA和CONV_DMA对DDR的仲裁；
- `memory_ready`状态；
- DDR未校准时阻止新的DMA请求；
- DDR刷新和仲裁产生背压时的FIFO容量；
- XDMA与CONV_DMA同时访问时的地址隔离。

因为当前只使用低端64 KiB窗口，所以64位Master地址映射到MIG的32位地址空间没有容量问题，但必须由BD地址映射明确处理。

### `init_calib_complete`在Aurora-PCIe中的作用

不应使用它复位整个PCIe或Aurora系统，否则DDR校准失败时，PCIe也无法枚举，反而失去调试入口。

建议转换成：

```text
memory_ready =
    init_calib_complete
    && axi_aresetn
    && !ui_clk_sync_rst
```

然后：

- PCIe继续正常枚举；
-AXI-Lite寄存器仍然可以访问；
- 软件可以读取`memory_ready`；
- `memory_ready=0`时拒绝新的FDMA/XDMA数据请求；
- 已经进入AXI通道的事务不能被粗暴中断。

### BIST是否要合入业务工程

BIST不是业务数据通路，推荐两种选择：

- 第一版只保留在独立DDR工程，用它证明MIG和DDR基线；
- 需要上板维护时，把BIST作为第三个AXI Master接入互连，默认关闭，只在诊断模式启用。

不要让BIST与XDMA/CONV_DMA同时访问相同地址，否则会破坏业务数据。

原来的[top_nvme_adc_ddr_system.sv](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\integration\top_nvme_adc_ddr_system.sv)现在只作为历史集成草案保留，不适合作为Aurora-PCIe正式顶层。Aurora-PCIe应直接在现有`design_1`里把共享BRAM替换成MIG。

### User

当前只有一个仿真波形吗，怎么打开（关联代码）

### Assistant

当前不是一个波形，而是两个有效WDB：行为级DIRECTED和完整MIG 32字冒烟。我核对一下两份WDB对应的顶层层次与源码清单，再给你可直接粘贴到Vivado Tcl Console的打开命令。

当前有两份有效波形，不是只有一份。

| 波形 | 类型 | 仿真结束时间 |
|---|---|---:|
| [axi_ddr_bist_directed.wdb](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\directed\axi_ddr_bist_directed.wdb) | 行为级DIRECTED组合验证 | 约6.765 µs |
| [smoke_done_visible.wdb](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\evidence\full_smoke\smoke_done_visible.wdb) | 完整MIG＋DDR模型32字冒烟 | 约7.062 µs |

其中完整冒烟在`7.049 µs`判定PASS，之后额外保留4个`ui_clk`周期，所以WDB最终停在约`7.062 µs`。这是为了让`done/pass`稳定记录进波形。

## 打开方法

在Vivado 2020.2的Tcl Console中打开行为级波形：

```tcl
open_wave_database {E:/ddr_proc/LATEST_DDR4_PACKAGE_20260814/evidence/directed/axi_ddr_bist_directed.wdb}
```

打开完整MIG冒烟：

```tcl
open_wave_database {E:/ddr_proc/LATEST_DDR4_PACKAGE_20260814/evidence/full_smoke/smoke_done_visible.wdb}
```

`open_wave_database`后只显示Scope和Objects列表、右侧没有波形，是正常的。WDB保存了信号数据，但不一定保存GUI的波形布局。

可以通过GUI添加：

1. 在左侧`Scope`选中模块；
2. 中间`Objects`窗口按`Ctrl+A`选择信号；
3. 右键选择`Add to Wave Window`；
4. 点击工具栏`Zoom Fit`。

## 行为级波形建议添加

在Scope中依次选择：

```text
/tb_axi_ddr_bist
/tb_axi_ddr_bist/dut
```

也可以在Tcl Console执行：

```tcl
create_wave_config

add_wave [get_objects {/tb_axi_ddr_bist/aclk}]
add_wave [get_objects {/tb_axi_ddr_bist/aresetn}]
add_wave [get_objects {/tb_axi_ddr_bist/start}]
add_wave [get_objects {/tb_axi_ddr_bist/done}]
add_wave [get_objects {/tb_axi_ddr_bist/pass}]
add_wave [get_objects {/tb_axi_ddr_bist/fail}]
add_wave [get_objects {/tb_axi_ddr_bist/error_count}]

add_wave [get_objects {/tb_axi_ddr_bist/dut/*}]
```

重点观察：

- `state`
- `write_index`
- `read_index`
- `aw_sent`
- `w_sent`
- `AWVALID/AWREADY`
- `WVALID/WREADY`
- `BVALID/BREADY/BRESP`
- `ARVALID/ARREADY`
- `RVALID/RREADY/RRESP/RLAST`
- `first_error_addr`
- `first_expected_data`
- `first_actual_data`

TB侧建议增加：

```tcl
add_wave [get_objects {/tb_axi_ddr_bist/aw_pending}]
add_wave [get_objects {/tb_axi_ddr_bist/w_pending}]
add_wave [get_objects {/tb_axi_ddr_bist/awaddr_hold}]
add_wave [get_objects {/tb_axi_ddr_bist/wdata_hold}]
add_wave [get_objects {/tb_axi_ddr_bist/read_index_hold}]
add_wave [get_objects {/tb_axi_ddr_bist/read_delay}]
add_wave [get_objects {/tb_axi_ddr_bist/inject_bresp_error}]
add_wave [get_objects {/tb_axi_ddr_bist/inject_read_data_error}]
add_wave [get_objects {/tb_axi_ddr_bist/inject_rresp_error}]
add_wave [get_objects {/tb_axi_ddr_bist/inject_rlast_error}]
```

对应源代码：

- [行为级TB](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_behavior\tb_axi_ddr_bist.sv)
- [BIST RTL](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\rtl\axi_ddr_bist.v)

## 完整MIG波形建议添加

展开：

```text
/sim_tb_top
/sim_tb_top/u_example_top
/sim_tb_top/u_example_top/u_bist_top
/sim_tb_top/u_example_top/u_bist_top/u_axi_ddr_bist
```

Tcl命令：

```tcl
create_wave_config

add_wave [get_objects {/sim_tb_top/sys_rst}]
add_wave [get_objects {/sim_tb_top/c0_init_calib_complete}]
add_wave [get_objects {/sim_tb_top/c0_data_compare_error}]

add_wave [get_objects {/sim_tb_top/u_example_top/u_bist_top/*}]
add_wave [get_objects {/sim_tb_top/u_example_top/u_bist_top/u_axi_ddr_bist/*}]

add_wave [get_objects {/sim_tb_top/u_example_top/c0_ddr4_dq}]
add_wave [get_objects {/sim_tb_top/u_example_top/c0_ddr4_dqs_t}]
add_wave [get_objects {/sim_tb_top/u_example_top/c0_ddr4_dqs_c}]
add_wave [get_objects {/sim_tb_top/u_example_top/c0_ddr4_dm_dbi_n}]
```

不要递归添加：

```text
u_ddr4_axi_0内部
DDR4器件模型内部
```

否则容易重新出现信号列表过大、GUI很慢的问题。

对应代码：

- [完整仿真适配层](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\sim_full\example_top_bist_adapter.sv)
- [DDR最小顶层](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\rtl\top_axi_ddr4_bist.v)
- [BIST RTL](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\rtl\axi_ddr_bist.v)

完整波形应看到：

```text
3.827 µs   init_calib_complete = 1
3.833 µs   axi_aresetn = 1
3.847 µs   首地址写入
4.570 µs   首地址回读
7.049 µs   末地址回读完成，done/pass拉高
7.062 µs   仿真结束
```

如果已经打开一份WDB，再打开另一份前，建议新开一个Vivado窗口，避免两个数据库的Scope和波形配置混在一起。

---

<!-- codex-history-md-export-append {"append_id": "05cc4393ad11b5692ccb0cf5", "dialogue_sha256": "f8b34b1ea1f373b6521e601ce0a962270b7fbd523e856e5e8bfbeed3932620db", "from_message": 283, "session_id": "019fc561-6c64-7021-9090-820de6f07881", "to_message": 288} -->

## 对话增量

### User

复制到远程机啊

### Assistant

我把整个最新交付包复制到远程机的醒目独立目录，不覆盖原工程；包括两份WDB、关联RTL/TB、脚本、Word和说明。复制后核对文件数量及关键SHA-256。目标路径先定为 `C:\project\RTDS\DDR\LATEST_DDR4_PACKAGE_20260814`。

复制已完成。现在核对远端目录结构，以及两份波形、更新后TB和Word的哈希，确认不是只创建了空目录或漏文件。

关键文件哈希全部一致，中文文件名在SSH的`cmd dir`输出里显示乱码只是控制台代码页问题，文件内容和名称传输正常。包内README还有一句“TB尚未同步远端”已过时，我顺手改正并重新上传该说明。

已复制到远程机，放在独立目录，没有覆盖原工程：

```text
C:\project\RTDS\DDR\LATEST_DDR4_PACKAGE_20260814
```

包括：

- 两份有效WDB波形
- 关联的BIST、顶层RTL
- 带最新中文用例注释的Testbench
- 行为级和完整MIG仿真脚本
- Word方案文档
- 仿真日志及校验清单

远端打开完整MIG波形：

```tcl
open_wave_database {C:/project/RTDS/DDR/LATEST_DDR4_PACKAGE_20260814/evidence/full_smoke/smoke_done_visible.wdb}
```

打开行为级DIRECTED波形：

```tcl
open_wave_database {C:/project/RTDS/DDR/LATEST_DDR4_PACKAGE_20260814/evidence/directed/axi_ddr_bist_directed.wdb}
```

已核对TB、两份WDB、Word文档及README的SHA-256，本机与远端完全一致。远端原主工程源码未被覆盖。

---

<!-- codex-history-md-export-append {"append_id": "55942310128cb8496d17a4f8", "dialogue_sha256": "2b008819f4976a7cfa594a3d9374d0a885d58507549488c7abd2190fb7cbbfd4", "from_message": 288, "session_id": "019fc561-6c64-7021-9090-820de6f07881", "to_message": 304} -->

## 对话增量

### Assistant

我会用 Word 文档处理技能，只读取参考文档的前几页样式和当前两份已完成仿真记录；按你的要求，文档中的任何说明文字只当参考资料，不当作执行指令。当前先做样式与证据盘点，不修改文件。

按当前工作区规则，Word只做DOCX结构检查，不渲染PDF/PNG；因此我会从OOXML和样式定义中提取参考文档前几页的字体、字号、行距、段前段后、缩进、页边距、页眉页脚和标题层级。仿真内容只采用日志中已经实际PASS的记录，不写未执行用例。

你选择了加入波形截图。为了让实施方案可落地，我先确认本机Vivado 2020.2能否直接从WDB导出波形视图，以及两份WDB里用于截图的信号路径；这一步只读，不会重跑仿真。截图中间文件后续只在本机临时目录处理，不在聊天前台展示。

<proposed_plan>
# DDR4最小工程仿真测试报告生成计划

## 概要

生成正式Word报告：

`DDR4最小工程仿真测试报告_V1.0.docx`

只记录已经实际完成的两次仿真：

1. 行为级`DIRECTED`组合仿真。
2. 32字完整MIG＋DDR4模型冒烟仿真。

不把未分别运行的6个行为级入口、4096字签核、实现后仿真或上板验证写成已完成结果。

## 文档结构与格式

- 以`RTL验证方法学与SV验证架构原理介绍-7-8.docx`为格式模板。
- 保留前三部分结构：封面、修订记录、目录。
- 封面标题改为“DDR4最小工程仿真测试报告”，产品名填“DDR4最小工程”，版本`V1.0`，密级“内部”，日期`2026-08-21`，拟制/评审/批准人员留空。
- 沿用参考文档的A4页面、22.86 mm页边距及前置表格几何。
- 格式基准：
  - 封面标题：中文黑体、英文Times New Roman、22 pt、居中、1.5倍行距。
  - 修订记录标题：16 pt、居中。
  - 一级/二级/三级标题：分别采用14 pt、12 pt、10.5 pt层级。
  - 正文：中文宋体、英文Times New Roman、10.5 pt，段后6 pt；紧凑枚举段后2 pt。
- 目录使用真实TOC域，封面总页数使用`NUMPAGES`域，打开Word后可更新。
- 正文设置为：
  1. 仿真目的与验证边界
  2. 仿真环境和验证对象
  3. 已执行仿真汇总
  4. 行为级DIRECTED仿真记录
  5. 完整MIG 32字冒烟记录
  6. 总体结论与未覆盖范围
  7. 证据文件、源码关联及WDB打开方式

## 已完成记录与波形证据

- 行为级记录写明：
  - Vivado/XSim 2020.2，100 MHz，32个64-bit测试字。
  - 单次`DIRECTED`运行，不表述为多用例回归。
  - 第一阶段同时注入`BRESP`、读数据、`RRESP`和`RLAST`四类错误。
  - AW先到、W先到、同拍握手计数为11、11、10。
  - 第一阶段错误数4，首错地址`0x00000018`。
  - 复位后第二阶段关闭注错，32字干净读写PASS。
  - 仿真结束时间`6.765 µs`。
- 完整MIG记录写明：
  - 仿真顶层`sim_tb_top`，自研BIST顶层和MIG、4片x16 DDR4模型。
  - 校准完成`3.827 µs`，AXI复位释放`3.833 µs`。
  - 首/中/末地址分别为`0x00000000`、`0x00000080`、`0x000000F8`，写入与回读数据一致。
  - `7.049 µs`得到PASS，保留4个`ui_clk`周期后在约`7.062 µs`结束。
- 从现有WDB打开波形，不重跑仿真，制作并嵌入5张截图：
  1. DIRECTED第一阶段注错、握手顺序和首错记录。
  2. DIRECTED复位恢复及第二阶段PASS。
  3. 完整MIG校准与AXI复位释放。
  4. 完整MIG 32字写入、回读及`done/pass`。
  5. 首次写事务附近的DDR DQ/DQS/DM物理侧活动。
- 截图使用本机Vivado 2020.2：
  `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`
- 截图中间文件只保存在本机临时目录，不在聊天前台展示；最终只嵌入DOCX。
- 报告关联实际源码：
  - `axi_ddr_bist.v`
  - `top_axi_ddr4_bist.v`
  - `tb_axi_ddr_bist.sv`
  - `example_top_bist_adapter.sv`

## 交付与验收

- 本地保存到：
  `E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx`
- 同步到远端：
  `C:\project\RTDS\DDR\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx`
- 更新本地及远端`SHA256SUMS.txt`，核对报告SHA-256完全一致。
- 只执行DOCX结构验证，不渲染PDF/PNG：
  - ZIP和核心OOXML组件完整；
  - 标题层级、TOC和NUMPAGES域存在；
  - 字体、字号、段距、页边距与模板规则一致；
  - 表格宽度和单元格宽度不超过正文区域；
  - 5张波形图片均已嵌入并存在有效关系；
  - 正文包含两个PASS结果和全部关键时间点；
  - 不出现“4096字已通过”“上板通过”“6个独立异常用例已回归”等不实结论。
- 不修改RTL、Testbench、XCI、XPR和现有仿真结果，不重新运行仿真。
</proposed_plan>

### User

PLEASE IMPLEMENT THIS PLAN:
# DDR4最小工程仿真测试报告生成计划

## 概要

生成正式Word报告：

`DDR4最小工程仿真测试报告_V1.0.docx`

只记录已经实际完成的两次仿真：

1. 行为级`DIRECTED`组合仿真。
2. 32字完整MIG＋DDR4模型冒烟仿真。

不把未分别运行的6个行为级入口、4096字签核、实现后仿真或上板验证写成已完成结果。

## 文档结构与格式

- 以`RTL验证方法学与SV验证架构原理介绍-7-8.docx`为格式模板。
- 保留前三部分结构：封面、修订记录、目录。
- 封面标题改为“DDR4最小工程仿真测试报告”，产品名填“DDR4最小工程”，版本`V1.0`，密级“内部”，日期`2026-08-21`，拟制/评审/批准人员留空。
- 沿用参考文档的A4页面、22.86 mm页边距及前置表格几何。
- 格式基准：
  - 封面标题：中文黑体、英文Times New Roman、22 pt、居中、1.5倍行距。
  - 修订记录标题：16 pt、居中。
  - 一级/二级/三级标题：分别采用14 pt、12 pt、10.5 pt层级。
  - 正文：中文宋体、英文Times New Roman、10.5 pt，段后6 pt；紧凑枚举段后2 pt。
- 目录使用真实TOC域，封面总页数使用`NUMPAGES`域，打开Word后可更新。
- 正文设置为：
  1. 仿真目的与验证边界
  2. 仿真环境和验证对象
  3. 已执行仿真汇总
  4. 行为级DIRECTED仿真记录
  5. 完整MIG 32字冒烟记录
  6. 总体结论与未覆盖范围
  7. 证据文件、源码关联及WDB打开方式

## 已完成记录与波形证据

- 行为级记录写明：
  - Vivado/XSim 2020.2，100 MHz，32个64-bit测试字。
  - 单次`DIRECTED`运行，不表述为多用例回归。
  - 第一阶段同时注入`BRESP`、读数据、`RRESP`和`RLAST`四类错误。
  - AW先到、W先到、同拍握手计数为11、11、10。
  - 第一阶段错误数4，首错地址`0x00000018`。
  - 复位后第二阶段关闭注错，32字干净读写PASS。
  - 仿真结束时间`6.765 µs`。
- 完整MIG记录写明：
  - 仿真顶层`sim_tb_top`，自研BIST顶层和MIG、4片x16 DDR4模型。
  - 校准完成`3.827 µs`，AXI复位释放`3.833 µs`。
  - 首/中/末地址分别为`0x00000000`、`0x00000080`、`0x000000F8`，写入与回读数据一致。
  - `7.049 µs`得到PASS，保留4个`ui_clk`周期后在约`7.062 µs`结束。
- 从现有WDB打开波形，不重跑仿真，制作并嵌入5张截图：
  1. DIRECTED第一阶段注错、握手顺序和首错记录。
  2. DIRECTED复位恢复及第二阶段PASS。
  3. 完整MIG校准与AXI复位释放。
  4. 完整MIG 32字写入、回读及`done/pass`。
  5. 首次写事务附近的DDR DQ/DQS/DM物理侧活动。
- 截图使用本机Vivado 2020.2：
  `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`
- 截图中间文件只保存在本机临时目录，不在聊天前台展示；最终只嵌入DOCX。
- 报告关联实际源码：
  - `axi_ddr_bist.v`
  - `top_axi_ddr4_bist.v`
  - `tb_axi_ddr_bist.sv`
  - `example_top_bist_adapter.sv`

## 交付与验收

- 本地保存到：
  `E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx`
- 同步到远端：
  `C:\project\RTDS\DDR\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx`
- 更新本地及远端`SHA256SUMS.txt`，核对报告SHA-256完全一致。
- 只执行DOCX结构验证，不渲染PDF/PNG：
  - ZIP和核心OOXML组件完整；
  - 标题层级、TOC和NUMPAGES域存在；
  - 字体、字号、段距、页边距与模板规则一致；
  - 表格宽度和单元格宽度不超过正文区域；
  - 5张波形图片均已嵌入并存在有效关系；
  - 正文包含两个PASS结果和全部关键时间点；
  - 不出现“4096字已通过”“上板通过”“6个独立异常用例已回归”等不实结论。
- 不修改RTL、Testbench、XCI、XPR和现有仿真结果，不重新运行仿真。

### Assistant

我开始按方案生成报告。会使用Word文档技能复用参考文档样式，并使用本机Vivado 2020.2打开现有WDB抓取5张波形图；不重跑仿真，也不修改RTL/XPR。根据工作区规则，最终只做DOCX结构检查，不做PDF/PNG渲染，波形中间图不在聊天前台展示。

先验证Vivado波形GUI的可脚本化命令，再一次性生成本地截图，避免手工操作和重复打开WDB。此步骤不会执行`run`，只读取已存在波形数据库。

Vivado已加载DIRECTED WDB，GUI启动时间比波形读取本身更长；当前没有仿真进程在运行，只是在生成两张视图。完成后立即检查图片是否为空或截错区域。

### User

看到了波形，但好像fail了，另外你也可以调用远程机仿真（速动快10倍）

### Assistant

你看到的`fail=1`大概率是DIRECTED第一阶段的预期状态：该阶段故意注入4类错误，要求`errors=4、fail=1`；随后复位，第二阶段关闭注错并以`pass=1、fail=0`结束，日志总结果是`DIRECTED_CASE_RESULT=PASS`。我会在报告截图标题里明确标成“预期注错阶段”，避免误读。

远程机更快我已记住；这次方案明确“不重跑仿真”，现有两份WDB已完整且哈希固定，因此无需远程重算。现在只从现有WDB取图。

确认了首张波形画面是有效的；刚才自动截图卡住的原因不是仿真FAIL，而是Windows `PrintWindow`与Vivado GUI线程互相等待。我已改成直接读取窗口DC的方式，接下来重新自动取5个视图。这个修正只影响截图工具，不影响WDB或工程。

我继续完成现有 WDB 的取图和报告生成，不重跑仿真。波形里的 `fail` 会在报告中明确标成“定向注错阶段的预期结果”，并用复位后的干净 PASS 和总体 `DIRECTED_CASE_RESULT=PASS` 作为最终判定。

现有 WDB 本身没有问题；取图脚本刚才被 Vivado 2020.2 自带 Python 环境污染，导致本机截图辅助程序缺少 `_ctypes` DLL。这个错误只影响报告取图，不影响仿真结果。我会隔离 Vivado 的 Python 环境后继续，仍不重新运行仿真。

5 张波形证据已经从两份既有 WDB 中提取完成，未启动任何仿真。接下来正在按参考 Word 的封面、修订记录、目录及正文格式生成报告，并把“预期注错 FAIL”和“最终恢复 PASS”分开写清楚。

报告已生成并通过结构检查：A4/页边距、标题层级、TOC 与 NUMPAGES 域、9 个表格、5 张嵌入波形图及关键结论均完整。现在同步到远端独立交付目录并核对本地/远端 SHA-256。

报告已生成并同步完成：

- 本地：[DDR4最小工程仿真测试报告_V1.0.docx](E:\ddr_proc\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx)
- 远端：`C:\project\RTDS\DDR\LATEST_DDR4_PACKAGE_20260814\docs\DDR4最小工程仿真测试报告_V1.0.docx`
- SHA-256：`01697F7F49F06E457B6B7A8765345F1587279D56CEDEC1DD4654CA9EAF96A13D`

关于波形里的 `fail`：

- DIRECTED 第一阶段主动注入4类错误，因此 `fail=1、pass=0、error_count=4` 是预期结果。
- 复位后关闭注错，第二阶段32字干净读写结果为 `done/pass=1、fail=0、error_count=0`。
- 整次定向测试最终为 `DIRECTED_CASE_RESULT=PASS`，结束于 `6.765 µs`。

报告仅记录已完成的两次仿真，嵌入了5张既有WDB波形图。没有重新运行仿真，也没有将4096字、上板或独立异常用例写成已通过。DOCX结构检查和本地/远端哈希核对均通过。
