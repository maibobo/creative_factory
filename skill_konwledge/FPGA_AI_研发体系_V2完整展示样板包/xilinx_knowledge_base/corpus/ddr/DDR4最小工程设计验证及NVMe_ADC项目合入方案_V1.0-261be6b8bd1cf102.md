# DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0

- Category: `ddr`
- Source: `R:\DDR\axi_ddr4_min_2020_2\docs\DDR4最小工程设计验证及NVMe_ADC项目合入方案_V1.0.docx`
- SHA-256: `261be6b8bd1cf102b57433c3992482cbc4b69a61ffb69fe70f201e31fdb7537d`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr4, mig, validation`
- Duplicate sources:
  - none

内部设计与验证说明

DDR4 最小工程设计、验证
及 NVMe–ADC 项目合入方案

重点：主工程与MIG Example Design边界、三级顶层接口、完整仿真及后续集成

| 文档项 | 内容 |

| 版本 / 日期 | V1.0 / 2026-08-10（补充工程差异、三级顶层信号和架构图） |

| 最小工程 | C:\project\RTDS\DDR\axi_ddr4_min_2020_2 |

| 目标工程 | E:\NVME_PRO\nvme_adc_axi_pipeline |

| 工具基线 | 最小DDR：Vivado 2020.2；目标XSA：Vivado 2024.2 |

| 结论等级 | 条件式可合入：可作为DDR bring-up/诊断底座，不可原样替代目标共享DDR子系统 |


| 执行结论 当前最小DDR工程已经证明自研BIST经真实MIG数字模型完成校准后的基础写入和回读。但它的AXI用户口是64-bit、单拍、单主机；目标项目要求ADC Writer与NoPHAE两个256-bit主机经SmartConnect共享512-bit MIG。因此建议保留目标工程的256-bit业务RTL和512-bit MIG，把本工程的BIST、复位门控、监视器和受控波形脚本作为诊断能力移植过去。 |


# 1. 文档目的与适用边界

本文回答三个问题：第一，主工程prj与MIG Example Design分别承担什么职责；第二，最小DDR工程中除官方内容外新增了什么；第三，这些新增内容能否支撑后续ADC→DDR→NoPHAE NVMe工程合入。

设计范围：MIG校准后的AXI读写自检、复位门控、错误捕获、Example适配层和仿真自动化。

验证范围：Vivado 2020.2/XSim完整MIG与DDR4器件模型下的32字有效冒烟。

不在结论内：实现后时序、bitstream、板卡校准、ADC实时流、SmartConnect并发、PCIe/NVMe SSD闭环与长稳。

目标项目资料基线：V2.3设计说明、XSA/HWH实证、2026-08-05/06 NoPHAE与SSD最新报告。

# 2. 官方Example与自研新增内容的边界

| 对象 | 来源 | 本工程使用方式 | 是否属于自研新增 |

| MIG IP及XCI | Vivado生成 | 提供DDR4物理接口、校准、ui_clk和AXI Slave | 否 |

| MIG Example Design | Vivado生成 | 提供器件模型、时钟/复位范式、仿真工程骨架 | 否 |

| DDR4器件模型 | Vivado/模型库 | 连接DQ/DQS/DM及命令控制总线 | 否 |

| axi_ddr_bist.v | 本项目新增 | 生成读写事务、校验数据并捕获首错 | 是 |

| top_axi_ddr4_bist.v | 本项目新增 | MIG+BIST最小顶层、复位门控与LED状态 | 是 |

| example_top_bist_adapter.sv | 本项目新增 | 保持Example testbench端口，替换其流量发生器 | 是 |

| 完整仿真Tcl/批处理/守护脚本 | 本项目新增 | 单次运行、受控波形、容量/磁盘/墙钟保护 | 是 |

| 结果监视与报告 | 本项目新增 | 校准、复位、首/中/末样本、PASS/FAIL证据 | 是 |


| 关键原则 Example Design只作为可信仿真环境和DDR模型来源；功能目标、AXI事务、结果判定、保护脚本和合入方案均由项目侧定义。 |


## 2.1 主工程与MIG Example Design的区别

| 对比项 | 主工程 prj | 官方 ddr4_axi_0_ex | 工程结论 |

| 工程文件 | prj\axi_ddr4_min_2020_2.xpr | sim_full\mig_example_2020_2\ddr4_axi_0_ex\ddr4_axi_0_ex.xpr | 两个XPR相互独立 |

| 产生方式 | 项目侧建立并维护 | 由MIG的Open IP Example Design生成 | Example是生成快照，不是主工程的子运行 |

| 设计顶层 | top_axi_ddr4_bist | example_top | 上板和官方参考使用不同顶层 |

| 仿真顶层 | 主XPR未集成完整DDR模型TB | sim_tb_top | 完整MIG仿真以Example环境为底座 |

| AXI流量源 | 自研axi_ddr_bist | 官方AXI Traffic Generator | 最终冒烟验证使用自研流量与判定 |

| DDR4模型 | 主XPR内无外部器件模型 | 包含4片x16器件模型及封装 | 64-bit DQ由4片x16模型组成 |

| 约束 | top_axi_ddr4_bist.xdc，面向目标板卡 | example_design.xdc，官方参考约束 | 不能把Example约束直接当产品约束 |

| 综合/实现 | 用于自研RTL综合、实现和上板 | 可综合官方自测试顶层，也用于行为仿真 | 产品输出以prj为准 |

| 时序能力 | 可执行实现与静态时序分析；当前无完整器件模型TB | 可观察时钟、复位、校准和DDR模型时序检查 | 两者都未执行SDF回标的实现后时序仿真 |

| 当前目录快照 | 约261.4 MB，365个文件 | 约159.6 MB，535个文件 | 大小随日志、缓存和运行产物变化 |


两份ddr4_axi_0.xci的SHA-256不同，是因为XCI内部记录了不同的生成输出目录。逐行比较仅RUNTIME_PARAM.OUTPUTDIR不同，其余功能配置一致，所以两者仍代表同一个MIG参数基线，而不是两套独立的DDR配置。

图1  主工程、官方Example与正式仿真工作副本的关系

| prj/axi_ddr4_min_2020_2.xpr（自研产品工程） ├─ rtl/top_axi_ddr4_bist.v ──┬─ rtl/axi_ddr_bist.v │ └─ ddr4_axi_0（MIG）→ 板上DDR4 └─ ddr4_axi_0.xci │ Vivado: Open IP Example Design ▼ sim_full/mig_example_2020_2/ddr4_axi_0_ex（官方独立参考工程） ├─ example_top + 官方AXI Traffic Generator └─ sim_tb_top + 4×x16 DDR4器件模型 │ 复制为可修改的仿真工作副本 ▼ sim_full/bist_sim_work/ddr4_axi_0_ex.xpr（正式冒烟工程） ├─ sim_tb_top与DDR4模型保持官方接线 ├─ 官方example_top.sv设置USED_IN_SIMULATION=false └─ 加入example_top_bist_adapter + top_axi_ddr4_bist + axi_ddr_bist |


## 2.2 设计方案说明

本方案采用“产品工程、官方仿真基线、仿真工作副本”三层隔离。产品工程只保留上板所需的MIG、自研BIST和板级约束；官方Example保留为可重新生成、可追溯的参考；所有仿真适配只进入bist_sim_work，避免为了运行Testbench而污染产品XPR或修改MIG参数。

以主工程为设计真源：综合、实现、引脚约束和后续板卡调试都从prj进入，Example不能替代产品顶层。

以官方Example为模型真源：复用与当前XCI一致的时钟、复位、器件数量、DQ/DQS/DM及命令地址接线，避免手工猜测DDR4模型组织。

以同名适配层替换流量源：example_top_bist_adapter保持sim_tb_top期待的端口不变，内部改接自研top_axi_ddr4_bist，使官方环境验证的是项目自己的AXI Master和PASS/FAIL逻辑。

保持单一有效example_top：仿真工作工程必须关闭官方example_top.sv的USED_IN_SIMULATION属性，防止同名模块重复定义或误用官方Traffic Generator。

分开理解仿真与时序：当前完整冒烟是带MIG和DDR4器件模型的行为级仿真；prj的实现时序报告属于静态时序分析；两者都不等于实现后SDF时序仿真。

| 选择规则 综合、实现和上板打开prj；查看官方原始结构打开mig_example_2020_2下的ddr4_axi_0_ex；运行自研完整BIST仿真只使用bist_sim_work。 |


# 3. 自研最小DDR设计

## 3.1 上板架构

图2  自研最小DDR上板设计架构

| top_axi_ddr4_bist ┌───────────────────────────────────────────────────────────────────────┐ │ sys_clk_p/n ───────────────► ddr4_axi_0 MIG ──DDR4命令/数据──► 板上DDR4 │ │ sys_rst_n ──反相为sys_rst──► │ │ │ ├─ ui_clk / ui_clk_sync_rst │ │ ├─ init_calib_complete ──► LED0 │ │ └─ S_AXI 32/64/ID4 │ │ ▲ │ │ │ AXI五通道 │ │ axi_ddr_bist（AXI Master，单拍、单Outstanding） │ │ │ done/pass/fail/error_count │ │ └──────────────────────────────► LED1 │ │ init_calib_complete + ui_clk_sync_rst ─► 2拍复位门控 ─► axi_aresetn │ └───────────────────────────────────────────────────────────────────────┘ |


最小顶层不引入MicroBlaze、DMA、FIFO或业务数据路径，目的是把DDR问题压缩为“校准—复位—AXI—器件模型”四个可观察环节。

## 3.2 top_axi_ddr4_bist上板端口

| 信号 | 方向 | 位宽 | 有效极性/连接对象 | 设计含义 |

| sys_clk_p / sys_clk_n | 输入 | 各1 bit | 差分；连接MIG c0_sys_clk_p/n | 板级DDR参考时钟输入 |

| sys_rst_n | 输入 | 1 bit | 低有效；内部反相后接MIG sys_rst | 系统复位输入 |

| c0_ddr4_act_n | 输出 | 1 bit | 低有效；连接DDR4 ACT_n | 激活命令 |

| c0_ddr4_adr | 输出 | 17 bit | [16:0]；连接DDR4地址 | 行/列及模式寄存器地址 |

| c0_ddr4_ba | 输出 | 2 bit | [1:0]；连接DDR4 BA | Bank地址 |

| c0_ddr4_bg | 输出 | 1 bit | [0:0]；连接DDR4 BG | Bank Group地址 |

| c0_ddr4_cke | 输出 | 1 bit | [0:0]；高有效 | DDR4时钟使能 |

| c0_ddr4_odt | 输出 | 1 bit | [0:0]；高有效 | DDR4片上终端控制 |

| c0_ddr4_cs_n | 输出 | 1 bit | [0:0]；低有效 | DDR4片选 |

| c0_ddr4_ck_t / ck_c | 输出 | 各1 bit | [0:0]差分时钟 | DDR4存储器时钟 |

| c0_ddr4_reset_n | 输出 | 1 bit | 低有效 | DDR4器件复位 |

| c0_ddr4_dm_dbi_n | 双向 | 8 bit | [7:0]；每8-bit lane一位 | 数据掩码/DBI边界 |

| c0_ddr4_dq | 双向 | 64 bit | [63:0]；连接DDR4数据总线 | 写数据输出及读数据输入 |

| c0_ddr4_dqs_t / dqs_c | 双向 | 各8 bit | [7:0]差分数据选通 | 每个byte lane的读写选通 |

| led | 输出 | 2 bit | led[0]校准；led[1]测试结果 | 校准中闪烁/PASS常亮/FAIL快闪 |


| 端口边界 init_calib_complete、ui_clk、ui_clk_sync_rst、axi_aresetn以及BIST结果不是该上板顶层的外部端口，而是顶层内部观测信号；当前通过mark_debug和LED提供调试入口。 |


## 3.3 官方/适配层example_top端口

| 信号 | 方向 | 位宽 | 官方含义 | 适配层处理 |

| sys_rst | 输入 | 1 bit | 高有效系统复位 | 反相后连接top_axi_ddr4_bist.sys_rst_n |

| c0_sys_clk_p / n | 输入 | 各1 bit | 差分系统时钟 | 原样转接sys_clk_p/n |

| c0_init_calib_complete | 输出 | 1 bit | MIG校准完成 | 映射u_bist_top.init_calib_complete |

| c0_data_compare_error | 输出 | 1 bit | 官方Traffic Generator比较错误 | 改为映射u_bist_top.bist_fail |

| c0_ddr4_act_n | 输出 | 1 bit | DDR4 ACT_n | 原样连接自研顶层 |

| c0_ddr4_adr / ba / bg | 输出 | 17/2/1 bit | 地址、Bank、Bank Group | 原样连接自研顶层 |

| c0_ddr4_cke / odt / cs_n | 输出 | 各1 bit | CKE、ODT、片选 | 原样连接自研顶层 |

| c0_ddr4_ck_t / ck_c | 输出 | 各1 bit | 差分DDR4时钟 | 原样连接自研顶层 |

| c0_ddr4_reset_n | 输出 | 1 bit | DDR4低有效复位 | 原样连接自研顶层 |

| c0_ddr4_dm_dbi_n | 双向 | 8 bit | 数据掩码/DBI | 与器件模型直连 |

| c0_ddr4_dq | 双向 | 64 bit | DDR4数据 | 与器件模型直连 |

| c0_ddr4_dqs_t / dqs_c | 双向 | 各8 bit | 差分数据选通 | 与器件模型直连 |


官方example_top参数为nCK_PER_CLK=4、APP_DATA_WIDTH=512、APP_MASK_WIDTH=64、C_AXI_ID_WIDTH=4、C_AXI_ADDR_WIDTH=32、C_AXI_DATA_WIDTH=64、C_AXI_NBURST_SUPPORT=0。APP_DATA_WIDTH是MIG内部应用数据组织宽度，当前对外AXI数据宽度仍为64 bit。

## 3.4 sim_tb_top仿真边界

sim_tb_top是无外部端口的Testbench顶层。下面的信号均为仿真内部对象，用来驱动FPGA侧并连接DDR4器件模型。

| 内部信号/参数 | 类型/位宽 | 驱动或连接 | 作用 |

| sys_clk_i | reg / 1 bit | 产生c0_sys_clk_p/n | 周期约9.996 ns的系统参考时钟 |

| sys_rst | reg / 1 bit | 连接example_top.sys_rst | 0→1→0复位序列，高有效 |

| c0_sys_clk_p / n | wire / 各1 bit | 连接u_example_top | 差分时钟激励 |

| c0_init_calib_complete | wire / 1 bit | 来自u_example_top | 校准结束状态 |

| c0_data_compare_error | wire / 1 bit | 来自u_example_top | 官方比较错误或适配后的bist_fail |

| c0_ddr4_adr_sdram[1:0] | reg / 2×17 bit | 由c0_ddr4_adr重排 | Rank/CA镜像后的器件地址 |

| c0_ddr4_ba_sdram[1:0] | reg / 2×2 bit | 由c0_ddr4_ba重排 | Rank/CA镜像后的Bank地址 |

| c0_ddr4_bg_sdram[1:0] | reg / 2×1 bit | 由c0_ddr4_bg连接 | Rank/Bank Group模型连接 |

| ACT/CKE/ODT/CS/RESET | wire / 各1 bit | FPGA顶层到DDR模型 | DDR4命令与控制边界 |

| c0_ddr4_ck_t/c | wire / 各1 bit | FPGA顶层到DDR模型 | DDR4差分存储器时钟 |

| DQ/DQS_T/DQS_C/DM_DBI_N | wire / 64/8/8/8 bit | FPGA顶层与4×x16模型双向连接 | DDR4数据和选通边界 |

| en_model / model_enable | bit/tri / 1 bit | 器件模型使能 | 复位初期控制模型启用 |

| tCK / SYSCLK_PERIOD | 833 ps | DDR4模型参数 | DDR4接口时钟周期基线 |

| DQ_WIDTH / DRAM_WIDTH | 64 / 16 bit | NUM_PHYSICAL_PARTS=4 | 4片x16模型组成64-bit数据宽度 |


## 3.5 MIG用户侧AXI五通道与诊断信号

| 通道 | 信号 | 相对BIST方向 | 位宽 | 功能与当前取值 |

| AW | awid / awaddr | 输出 | 4 / 32 | 写ID固定0；写字节地址 |

| AW | awlen / awsize / awburst | 输出 | 8 / 3 / 2 | LEN=0单拍；SIZE=3即8 Byte；INCR |

| AW | awlock / awcache / awprot / awqos | 输出 | 1/4/3/4 | LOCK=0；CACHE=0011；PROT/QOS=0 |

| AW | awvalid / awready | 输出 / 输入 | 各1 | 写地址VALID/READY握手 |

| W | wdata / wstrb / wlast | 输出 | 64 / 8 / 1 | 写数据；全字节有效；单拍LAST=1 |

| W | wvalid / wready | 输出 / 输入 | 各1 | 写数据VALID/READY握手 |

| B | bid / bresp | 输入 | 4 / 2 | 写响应ID及OKAY/错误码 |

| B | bvalid / bready | 输入 / 输出 | 各1 | 写响应握手 |

| AR | arid / araddr | 输出 | 4 / 32 | 读ID固定0；读字节地址 |

| AR | arlen / arsize / arburst | 输出 | 8 / 3 / 2 | LEN=0单拍；SIZE=3；INCR |

| AR | arlock / arcache / arprot / arqos | 输出 | 1/4/3/4 | LOCK=0；CACHE=0011；PROT/QOS=0 |

| AR | arvalid / arready | 输出 / 输入 | 各1 | 读地址握手 |

| R | rid / rdata / rresp / rlast | 输入 | 4/64/2/1 | 返回ID、数据、响应及单拍结束 |

| R | rvalid / rready | 输入 / 输出 | 各1 | 读数据握手 |


| 控制/诊断信号 | 位宽 | 来源 | 用途与正常状态 |

| ui_clk | 1 bit | MIG | MIG用户时钟；BIST全部时序逻辑工作在此域 |

| ui_clk_sync_rst | 1 bit | MIG | 高有效用户域同步复位 |

| init_calib_complete | 1 bit | MIG | 校准完成后拉高，也是BIST启动条件 |

| axi_aresetn | 1 bit | 顶层两级复位管线 | 校准完成后延迟两个ui_clk释放 |

| state | 3 bit | axi_ddr_bist | 六状态BIST状态机 |

| write_index / read_index | 各32 bit | axi_ddr_bist | 当前写入/回读字序号 |

| aw_sent / w_sent | 各1 bit | axi_ddr_bist | 分别记忆AW和W是否已独立握手 |

| done / pass / fail | 各1 bit | axi_ddr_bist | 完成与最终结论；正常结束为1/1/0 |

| error_count | 32 bit | axi_ddr_bist | BRESP、RRESP、RLAST或数据错误累计 |

| first_error_addr | 32 bit | axi_ddr_bist | 第一次错误对应地址 |

| first_expected_data / actual_data | 各64 bit | axi_ddr_bist | 首错期望值与实际读回值 |


## 3.6 时钟、复位与启动

外部差分系统时钟和复位进入MIG。

MIG完成训练后拉高 init_calib_complete，并输出 ui_clk/ui_clk_sync_rst。

自研顶层在校准完成后再延迟两个ui_clk周期释放 axi_aresetn。

BIST的start由校准完成状态驱动；状态机完成后停在ST_DONE，只有复位才能重新执行。

该门控避免BIST在MIG用户接口尚未稳定时发出AW/W/AR请求，也让板上ILA能稳定观察最终结果。

## 3.7 AXI BIST行为

| 项目 | 当前实现 |

| 地址/数据/ID | 32-bit / 64-bit / 4-bit |

| 事务类型 | AXI4 INCR单拍；AWLEN/ARLEN=0；ID固定0 |

| 并发能力 | 一次只允许一个写或读事务在途 |

| 测试顺序 | 先写完TEST_WORDS，再从首地址逐字回读 |

| 地址步进 | BASE_ADDR + index × 8 Byte |

| 数据模式 | {~index, index}，例如index=1为FFFF_FFFE_0000_0001 |

| 错误检测 | BRESP、RRESP、RLAST、读数据比较 |

| 错误证据 | error_count及首错地址/期望值/实际值 |


AW与W通道允许在不同周期独立握手。aw_sent/w_sent分别记忆两个通道是否完成，只有两者都完成后才打开BREADY，因此不会错误假设AWREADY与WREADY同时出现。

## 3.8 六状态与真实业务逻辑的关系

| 状态 | BIST中的作用 | 真实业务是否照搬 |

| ST_IDLE | 等待校准后的start | 不照搬；业务模块使用自己的空闲/任务接收状态 |

| ST_WRITE_SEND | 等待AW和W两个独立通道完成握手 | 原则保留；由ADC Writer/DMA自己的发送状态实现 |

| ST_WRITE_RESP | 等待并检查BRESP | 原则保留；真实Writer必须处理写响应和错误 |

| ST_READ_ADDR | 发送单拍AR地址 | ADC写路径不需要；DDR Reader或NoPHAE内部需要 |

| ST_READ_DATA | 接收R通道并比较Pattern | 业务数据通常不做BIST比较；Reader/CRC模块按需求实现 |

| ST_DONE | 锁存自检PASS/FAIL | 不照搬；业务模块用任务完成、Segment状态或DMA Completion |


这六个状态属于测试流量发生器，不是MIG的固定要求。去掉BIST后仍要有AXI Master：ADC写DDR由adc_ddr_segment_writer实现，NoPHAE访问DDR由供应商IP的m_axi实现，MicroBlaze访问由处理器M_AXI实现；SmartConnect负责把这些主机接到MIG AXI Slave。

## 3.9 当前Pattern评价与升级方向

| 方案 | 优点 | 限制/用途 |

| {~index,index} | 可由地址直接推导，波形易读，首错容易定位 | 适合64-bit、32字基础冒烟；短范围内只有少量低位充分翻转 |

| 全0/全1 | 快速检查固定高、固定低和严重开短路 | 两轮测试，不能单独覆盖耦合故障 |

| AA55/55AA | 相邻位交替，适合检查数据线耦合 | 应至少正反各一轮 |

| Walking 1/0 | 逐位覆盖每个数据位和每个byte lane | 运行时间较长，适合扩展诊断 |

| 地址扰动Pattern | 每个32/64-bit lane混入地址和lane编号，可扩展到256/512-bit | 推荐作为目标MIG的默认可复现Pattern |

| PRBS/LFSR | 翻转密度高，适合长稳和大范围覆盖 | 写读两阶段必须使用相同seed和推进规则 |


当前Pattern不应删除，它仍是最容易读懂的冒烟模式；但不能直接把DATA_WIDTH改成256/512后继续使用，因为赋值会让高位lane缺少有效变化。目标项目应增加PATTERN_MODE和SEED参数，并至少组合地址扰动、AA55/55AA、Walking 1/0及PRBS。

# 4. 自研完整仿真与波形策略

## 4.1 Testbench适配与自检查

图3  完整MIG行为仿真架构与波形记录边界

| sim_tb_top（仿真顶层，无外部端口） ├─ 产生c0_sys_clk_p/n、sys_rst与model_enable ├─ u_example_top : example_top_bist_adapter │ ├─ 监视校准、AXI复位、首/中/末样本和PASS/FAIL │ └─ u_bist_top : top_axi_ddr4_bist │ ├─ u_axi_ddr_bist ──M_AXI五通道──► MIG S_AXI │ └─ u_ddr4_axi_0 ──DDR4命令/DQ/DQS/DM──┐ └─ DDR4器件模型：4×x16 ◄───────────────────────┘ WDB记录：适配层、top_axi_ddr4_bist、u_axi_ddr_bist直属信号 + DDR命令控制 + DQ/DQS/DM物理边界 WDB排除：MIG/PHY内部层次、DDR4器件模型内部层次 |


适配层沿用Example顶层端口名和DDR4物理接线，内部实例改为top_axi_ddr4_bist。

监视器等待复位释放、校准完成、AXI复位释放和BIST结束，任一步超时即失败。

首地址0x00000000、中间地址0x00000080和末地址0x000000F8打印写入/回读样本。

成功条件固定为done=1、pass=1、fail=0、error_count=0。

## 4.2 受控波形记录

| 层次/信号组 | 记录策略 | 用途 |

| example_top适配层直属对象 | 记录 | 观察适配层复位、结果和物理边界 |

| top_axi_ddr4_bist直属信号 | 全部记录 | AXI五通道、ui_clk、复位、校准、BIST结果 |

| u_axi_ddr_bist直属信号 | 全部记录 | 状态机、索引、握手、响应和首错 |

| DDR命令控制 | ADR/BA/BG/ACT/CS/CKE/ODT/RESET/CK | 确认校准和读写期间命令活动 |

| DDR数据边界 | DQ[63:0]、DQS_T/C[7:0]、DM/DBI[7:0] | 观察物理数据活动；不递归展开模型 |

| MIG/PHY和器件模型内部 | 不记录 | 避免内部训练信号造成WDB爆炸 |


仿真属性关闭log_all_signals；脚本在仿真开始前显式加入对象，随后只执行一次run all。40 GB WDB、60 GB磁盘余量和30分钟冒烟墙钟限制形成三层保护。

## 4.3 大波形故障修正

此前238 GB WDB并非DDR业务复杂度所致，而是全层次递归记录叠加重复运行：launch_simulation按runtime=all先完成一次PASS，脚本又执行run all，第二次没有新的$finish而持续运行。修正后runtime置空，只加载快照；波形改为边界和自研层直属对象；正式运行仅一次。

旧smoke.wdb停在约7.0488 µs且界面未显示done/pass终值，是另一个结束时刻问题：最后一次r_fire所在时钟沿通过非阻塞赋值更新done/pass，Testbench检测到PASS后在同一仿真时刻立即$finish，日志已看到新值，但WDB可能仍停在更新前的最后采样。修正后PASS判定完成再保留4个ui_clk周期，新WDB在7.062 µs结束，done/pass有稳定观察窗口。

## 4.4 关键信号语义

| BIST信号 | 语义 | 正常波形/异常判断 |

| state | 六状态主状态机 | 按写发送→写响应→读地址→读数据推进，最后停在ST_DONE |

| aw_sent | 本次写事务的AW地址已经握手并被记住 | AW先于W完成时保持1；下一事务开始清0 |

| w_sent | 本次写事务的W数据已经握手并被记住 | W先于AW完成时保持1；下一事务开始清0 |

| aw_fire/w_fire | VALID与READY同周期为1的单周期握手事件 | 至少各出现一次；二者可同拍也可不同拍 |

| b_fire | 写响应被主机接收 | 每个单拍写事务对应一次；长期不出现表示写响应停滞 |

| ar_fire/r_fire | 读地址/读数据握手 | 每个测试字各一次；r_fire后检查RRESP、RLAST和数据 |

| write_index/read_index | 当前写入/回读字序号 | 从0推进至TEST_WORDS-1，不能跳变或长时间不动 |

| read_error | RRESP、数据或RLAST任一异常的组合结果 | 正常始终为0；为1时锁存首错现场 |

| done/pass/fail | 最终完成及结论锁存 | ST_DONE中done/pass保持1，fail保持0 |


| 行为级TB信号 | 语义 | 与完整MIG波形的关系 |

| aw_pending | 行为AXI Slave已收AW、尚未同时收到W | 仅tb_axi_ddr_bist.sv存在，不在完整MIG smoke.wdb中 |

| w_pending | 行为AXI Slave已收W、尚未同时收到AW | 仅行为级TB存在 |

| awaddr_hold | AW先到时暂存写地址 | aw_pending=1期间保持不变 |

| wdata_hold | W先到时暂存写数据 | w_pending=1期间保持不变 |

| read_index_hold | AR握手后锁存存储数组索引 | read_delay期间保持，随后用于产生RDATA |

| read_delay | 人为插入的三周期读延迟 | 倒计数到1时拉高RVALID/RLAST |

| cycle_count | 产生周期性READY反压 | 用于覆盖AW/W/AR不同拍握手，不代表真实MIG内部状态 |


| 层次边界 aw_sent/w_sent属于被测BIST主机；aw_pending/w_pending和各类*_hold属于行为级AXI Slave模型。两组信号名字相近，但方向相反，不能混为同一状态。 |


## 4.5 工程选择与顶层展开验收

| 工作目的 | 应打开的工程 | 预期顶层/关键设置 | 验收标准 |

| 综合、实现、上板 | prj\axi_ddr4_min_2020_2.xpr | Design Top=top_axi_ddr4_bist | 源文件为自研BIST+MIG；约束为板级XDC |

| 查看官方参考 | sim_full\mig_example_2020_2\ddr4_axi_0_ex\ddr4_axi_0_ex.xpr | Design Top=example_top；Simulation Top=sim_tb_top | 官方Traffic Generator和DDR4模型完整 |

| 运行自研完整仿真 | sim_full\bist_sim_work\ddr4_axi_0_ex.xpr | Simulation Top=sim_tb_top；官方example_top禁用 | 仅适配层提供有效example_top定义 |


| 检查项 | 检查方法 | 通过判据 |

| XCI功能一致性 | 逐行比较主工程和Example的ddr4_axi_0.xci | 只有RUNTIME_PARAM.OUTPUTDIR不同 |

| 同名顶层唯一性 | 检查sim_1文件属性及编译顺序 | 官方example_top.sv为USED_IN_SIMULATION=false；适配层为唯一有效定义 |

| 仿真顶层 | 检查sim_1 top并展开快照 | top=sim_tb_top；可展开u_example_top/u_bist_top/u_axi_ddr_bist |

| 行为仿真 | 运行32字完整冒烟 | 校准、复位、32写/32读、done/pass全部满足既有证据 |

| 静态时序 | 在prj实现结果中执行时序汇总 | 属于独立上板验收；不以行为波形替代 |

| 实现后时序仿真 | SDF回标网表仿真 | 当前未执行，不纳入本次PASS结论 |


“有时间轴的行为波形”“DDR4模型的协议/时序检查”“实现后的静态时序分析”和“SDF回标时序仿真”是四类不同证据。当前smoke_done_visible.wdb属于前两类；prj的实现报告属于第三类；第四类尚未执行。

# 5. 32字完整冒烟结果

| 检查项 | 结果 | 证据 |

| MIG校准 | PASS | init_calib_complete = 1 @ 3.827 µs |

| AXI复位 | PASS | axi_aresetn = 1 @ 3.833 µs，较校准延迟两个ui_clk |

| 写入样本 | PASS | 0x0、0x80、0xF8数据符合{~index,index} |

| 回读样本 | PASS | 三处样本与写入值一致 |

| 最终状态 | PASS | done/pass=1，fail=0，error_count=0 @ 7.049 µs |

| 流水线 | PASS | SMOKE_PASS；PIPELINE_RESULT=PASS |

| 终值可见性 | PASS | PASS后保持4个ui_clk；WDB结束时间7.062 µs |

| 正式WDB | PASS | smoke_done_visible.wdb为2,862,197 Byte，记录66个对象 |


32字覆盖256 Byte，能证明一次完整的校准、写响应、读响应、数据比较和结束判定链路。它足以支持“最小DDR工程基础可用”的结论。

| 不能扩大的结论 32字冒烟没有验证长地址范围、连续Burst、多个Outstanding、多主机仲裁、带宽、温度、真实板级SI或SSD稳定性。 |


# 6. 与 nvme_adc_axi_pipeline 的兼容性分析

## 6.1 目标工程事实

| 接口/需求 | 目标项目当前事实 |

| 器件与工具 | XCKU040-FFVA1156-2-I；XSA由Vivado 2024.2导出 |

| ADC数据率 | 单通道500 MB/s；双通道1 GB/s |

| ADC Writer | AXI4 Write Master，256-bit数据、32-bit地址 |

| NoPHAE DDR Master | AXI4-Full，256-bit数据、32-bit地址、10-bit ID、125 MHz |

| MIG S_AXI | 512-bit数据、32-bit地址、ID width 1、RD_PRI_REG |

| DDR窗口 | 0x80000000～0xFFFFFFFF，2 GiB |

| ADC建议区 | 0xC0000000起；需避开MicroBlaze及SQ/CQ/PRP/Context保留区 |

| 当前验证 | 五项行为回归5 PASS；尚无新RTL并入真实bit及真实DDR/SSD闭环证据 |


## 6.2 是否支持合入

| 能力 | 当前支持度 | 判断与处理 |

| 同板DDR校准/物理连接复用 | 条件支持 | 只有现有MIG XCI、XDC、颗粒和板卡版本一致时才能复用 |

| 基础AXI读写诊断 | 支持 | BIST、复位门控、首错捕获和波形脚本可移植 |

| 接目标512-bit MIG | 需适配 | 当前顶层固定64-bit/ID4；改为512-bit/ID1或经SmartConnect转换 |

| 接ADC 256-bit Writer | 需集成 | 保留现有Writer，在SmartConnect执行256→512位宽转换 |

| 接NoPHAE 256-bit Master | 需集成 | 与ADC Writer共同作为SmartConnect主机，复核ID和时钟转换 |

| 目标地址图 | 不直接支持 | BIST BASE=0；业务区需映射到0x80000000窗口并保护0xC0000000等区域 |

| 并发/持续带宽 | 不支持 | 当前单主机、单拍、单Outstanding，不能证明1 GB/s并发无丢样 |

| NVMe/SSD长稳 | 不支持 | 约300 GiB连续写异常属于NoPHAE/PCIe/SSD链路，DDR冒烟不能覆盖 |


| 最终判断 可作为合入底座和诊断资产，但不是可直接替换的业务DDR子系统。合入的前提是使用目标工程真实512-bit MIG/板级约束，并完成总线宽度、地址、仲裁和并发验证。 |


# 7. 推荐合入架构

| ADC Writer 256-bit M_AXI ─────────┐ NoPHAE 256-bit M_AXI ─────────────┼─ SmartConnect ─ 512-bit MIG S_AXI ─ DDR4 DDR诊断BIST（仅维护模式）─────────┘ │ MicroBlaze AXI4-Lite ─ fdma_vitis_compat_regs ─ nophae_dma_backend ─ NoPHAE控制口 |


推荐以目标项目真实MIG和地址图为主，不把当前64-bit MIG工程整体搬进供应商2024.2工程。应移植的是BIST与验证设施，并保持BIST只在维护模式获得总线所有权。

## 7.1 必要设计改造

核对目标MIG XCI、DDR颗粒、引脚/XDC、系统参考时钟和ui_clk；形成参数差异表。

将BIST顶层的AXI_DATA_WIDTH和ID_WIDTH参数化到目标接口；512-bit模式下扩展数据Pattern，确保所有64-bit lane都有可检测数据，而不是仅低64位变化。

BIST BASE_ADDR改为可配置且落在专用诊断区；上电默认禁止，避免覆盖ADC、MicroBlaze及供应商保留区。

在SmartConnect接入ADC Writer、NoPHAE和可选BIST；记录256→512宽度转换、ID转换、时钟转换、Outstanding和仲裁策略。

业务模式禁用BIST；维护模式先停ADC/NoPHAE并确认所有在途事务完成，再切换BIST。禁止用组合MUX直接切AXI五通道。

保留init_calib_complete门控、同步复位、首错寄存器和ILA观察点。

## 7.2 不建议的做法

不建议用当前64-bit MIG顶层替换目标XSA中的512-bit MIG。

不建议把ADC Writer重写为512-bit来迎合MIG；现有256-bit Writer已完成尾拍、WSTRB和4 KiB规则回归，宽度转换交给互连。

不建议把Example Design流量发生器作为产品BIST；它不包含项目地址保护、首错上下文和业务模式互斥。

不建议在不确认供应商DDR保留区前使用0地址或0x80000000附近作为BIST范围。

## 7.3 真实项目最终顶层

top_axi_ddr4_bist只用于DDR独立验证，不能作为产品顶层。自研业务侧应使用top_nvme_adc_ddr_system作为稳定集成边界，其内部实例化nvme_adc_vitis_compat_top；最外层仍由供应商Vivado工程的design_1_wrapper（或等价BD wrapper）拥有MIG、SmartConnect、MicroBlaze、NoPHAE和物理引脚。

| 板级 design_1_wrapper / vendor BD ├─ MIG 512-bit S_AXI → DDR4物理引脚 ├─ SmartConnect │ ├─ top_nvme_adc_ddr_system.m_axi_ddr（ADC Writer 256-bit） │ ├─ NoPHAE m_axi（256-bit） │ └─ 可选诊断BIST（仅维护模式） ├─ MicroBlaze AXI4-Lite → s_axi_fdma └─ top_nvme_adc_ddr_system.m_axi_nophae → NoPHAE s_axi_ctrl |


该骨架不重复实现AXI Master：ADC Writer已在业务RTL中，NoPHAE和MicroBlaze主口由对应IP提供。顶层只负责接口汇总，SmartConnect负责仲裁和256→512位宽转换。新增骨架已使用Vivado 2020.2 xvlog完成语法编译。

# 8. 合入验证方案

| 阶段 | 输入与动作 | 验收标准 |

| A 参数审计 | 比较最小工程与目标MIG XCI/XDC、器件、时钟、AXI宽度/ID | 差异表完整；不允许用口头参数替代 |

| B 目标MIG独立 | 官方Example + 移植后的512-bit BIST | 校准、线性/PRBS/Walking 1/0、全lane读回PASS |

| C ADC单主机 | 内部500 MB/s和1 GB/s发生器→256-bit Writer→SmartConnect→MIG | 逐字节/CRC一致；BRESP正常；无丢样 |

| D 并发压力 | ADC持续写 + 独立Reader/NoPHAE持续读 | 记录最长AW/W Stall、FIFO最高水位；1 GB/s下不饥饿 |

| E NoPHAE闭环 | DDR A→SSD→DDR B，含Write/Flush/Readback | A/B逐字节或CRC一致；Completion对应整笔任务 |

| F ADC闭环 | 真实ADC→DDR→SSD→DDR Readback | 全链路CRC、错误计数和地址所有权正确 |

| G 长稳 | 无间隔跨300 GiB故障点及全盘/接近全盘测试 | 无Link/CQE/DMA/数据错误；再评估0.5 ms规避 |


## 8.1 重点波形与ILA

MIG：init_calib_complete、ui_clk_sync_rst、axi_aresetn。

ADC Writer：FIFO水位、AW/W/B握手、Burst地址/长度、WSTRB、格式/丢样错误。

NoPHAE：AR/R与AW/W/B握手、ID、Outstanding、DMA Ready/Done、Link和ECQE。

SmartConnect：每个入口的有效请求、仲裁结果、宽度转换边界和最长stall。

DDR物理侧：命令控制和必要的DQ/DQS/DM边界；仿真不递归记录PHY/器件内部。

## 8.2 地址与数据检查

形成ADC Payload、Readback、Commit、MicroBlaze、供应商保留区和BIST诊断区的正式地址表。

验证physical_ddr_addr - 0x80000000得到NoPHAE 32-bit DDR Offset，且范围检查先于寄存器提交。

每个自研AXI Burst不得跨4 KiB；Payload/Commit按项目规则对齐。

512-bit BIST对每个64-bit lane使用不同可预测Pattern，并对首/中/末地址及跨4 KiB边界位置抽样。

# 9. 最新资料对本方案的影响

2026-08-05/06最新NoPHAE与SSD文档表明：NoPHAE已具备DDR↔SSD DMA和常规数据一致性能力，短时性能可满足约1 GB/s ADC目标；但Starblaze SSD在无间隔连续写约300 GiB附近仍有PCIe链路异常，加入每1 GiB后0.5 ms暂停可规避。

这说明最小DDR工程解决的是更底层的MIG/DDR可用性，不会验证Doorbell竞争、PCIe Link、CQE、SSD温度或长时间调度问题。后续项目必须保留“DDR通过”和“NVMe长稳通过”两个独立验收门槛。

# 10. 交付物与可追溯路径

| 交付物 | 路径/说明 |

| 自研BIST | rtl\axi_ddr_bist.v |

| 自研最小顶层 | rtl\top_axi_ddr4_bist.v |

| Example适配与监视 | sim_full\example_top_bist_adapter.sv |

| 仿真控制 | sim_full\tcl\run_full_sim_case_2020_2.tcl |

| 守护与流水线 | sim_full\run_full_sim_case_guarded_2020_2.ps1；run_full_sim_pipeline_2020_2.bat |

| 有效波形 | sim_full\results\smoke_done_visible.wdb |

| 真实项目集成骨架 | E:\ddr_proc\integration\top_nvme_adc_ddr_system.sv |

| 目标项目入口 | E:\NVME_PRO\nvme_adc_axi_pipeline\rtl\nvme_adc_vitis_compat_top.sv |

| 目标集成说明 | E:\NVME_PRO\nvme_adc_axi_pipeline\board_integration\README.md |


# 11. 阶段结论

当前最小DDR工程已经完成它应承担的第一阶段任务：用自研流量与判定逻辑，在官方完整MIG/DDR4模型中证明校准后基础读写链路可工作，并形成体积受控、可复核的波形。

面向nvme_adc_axi_pipeline，它应被定位为DDR bring-up与维护诊断资产。真正合入仍需以目标512-bit MIG和现有256-bit ADC/NoPHAE接口为准，补齐SmartConnect、地址隔离、并发压力和真实板级闭环。完成阶段A～D后，才可以说DDR子系统支持1 GB/s ADC数据通路；完成阶段E～G后，才可以说ADC→DDR→NVMe工程达到系统级可用。
