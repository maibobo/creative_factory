# ADC_DDR_NVMe验证用例与测试过程_V1.0

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe验证用例与测试过程_V1.0.docx`
- SHA-256: `1c199d4a321a6a2d3a729543abf45cf1fe614e8209d8a4dad4c369e091e1e05f`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe验证用例与测试过程_V1.0.docx

内部测试说明

ADC–DDR–NVMe
验证用例与测试过程

测试对象、测试桩、PASS条件、日志位置与真实硬件分级

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V1.0｜2026-07-26 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 当前自动化 | 3个Vivado行为仿真测试平台 + 1个KU040 OOC综合脚本 |

| 当前真实硬件 | 未接MIG/XDC、ADC PHY和第三方NVMe IP |


| 本手册的目的 让读者知道每个PASS究竟证明了什么。假DDR保存数组、假NVMe返回完成，并不等于真实DDR或SSD已经工作。测试报告必须使用“仿真通过、真实DDR通过、供应商IP通过、完整SSD闭环通过”四种不同表述。 |


# 1. 验证环境

| 项目 | 配置 |

| FPGA目标 | XCKU040-FFVA1156-2-I |

| 工具 | D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat |

| 语言 | SystemVerilog + Xilinx XPM FIFO |

| ADC时钟 | 250 MHz |

| 系统时钟 | 主端到端用例为125 MHz；可扩展到200/250 MHz |

| DDR模型 | axi_ddr_mem_stub，字节数组，只实现AXI写响应 |

| NVMe模型 | nvme_req_cpl_stub，固定延迟完成，可注入错误 |

| 板级约束 | 无MIG、无XDC；OOC报告不能作为最终时序 |


# 2. 两个仿真桩做了什么

## 2.1 假DDR：axi_ddr_mem_stub

接收AXI AW、W和B通道，把有效字节写入仿真数组。

可随机撤销AWREADY/WREADY、随机延迟BVALID。

可在下一条Burst注入BRESP错误。

不模拟MIG校准、刷新、Bank/Row、真实带宽和读通路。

## 2.2 假NVMe：nvme_req_cpl_stub

接收opcode、DDR地址、长度、SLBA和user_tag。

等待固定周期后返回完成状态。

可注入完成失败、永久不完成和错误Tag。

不读取DDR、不生成SQE/PRP、不运行PCIe、不访问SSD。

# 3. 历史V1基线用例

下面内容用于解释V1.0文档中“端到端仿真通过”的原始口径。V2.0已替换部分结构和用例，但保留该记录，避免把历史测试和当前回归混在一起。

Vivado脚本创建XCKU040-FFVA1156-2-I临时工程。

ADC和系统时钟都设为250 MHz，系统时钟错开1 ns相位。

使用4个4096 Byte分段，共产生4096个采样时刻。

CH0=sample_index[11:0]；CH1=(sample_index+0x155)&0xFFF。

RTL执行12→16 bit符号扩展、32→256 bit打包和AXI Burst写入。

假DDR保存数据，测试平台按32 bit样本对逐项比较。

假NVMe等待固定周期后返回成功；它没有读取DDR或运行PCIe/NVMe。

| 检查项 | 历史期望 |

| 样本 | 接收4096个采样时刻，丢样0 |

| Segment | 4个分段全部提交、完成并回到FREE |

| DDR | 逐个32 bit样本对一致 |

| 命令 | SLBA/NLB/DDR地址符合历史模型 |

| CRC | 最后一个Segment CRC32C一致 |

| 综合 | 只检查语法/资源；无XDC，不代表板级时序 |


# 4. V2当前自动化回归

| 测试平台 | 主要覆盖 | PASS标记 |

| tb_adc_channel_packer | 三模式、边界长度、字节序、符号边界、配置锁存 | TEST_PASS |

| tb_nvme_adc_pipeline | CDC、随机AXI背压、DDR内容、Segment、Flush、Commit | TEST_PASS |

| tb_nvme_scheduler_errors | 完成/Tag/超时/链路/Flush/ECQE错误 | TEST_PASS |


# 5. 用例A：ADC打包边界

| 覆盖项 | 测试内容 |

| 运行模式 | 双通道、单CH0、单CH1 |

| 短边界 | 0、1、7、8、9、15、16、17个采样时刻 |

| 时间长度 | 10 µs、50 µs、100 µs、1 ms |

| 原始码 | 0x000、0x7FF、0x800、0xFFF循环 |

| 背压 | 输出ready按LFSR随机短停顿，连续停顿上限4个ADC周期 |

| 配置锁存 | 采集中修改模式，数据格式保持且错误标志置位 |


每个输出字都按字节检查。单通道必须连续保存16 bit；双通道每个采样时刻按CH0低/高字节、CH1低/高字节排列。最后一个输出检查EOC、valid_bytes和补零。

| 采样数 | 为什么要测 |

| 0 | 验证空Capture用零字节EOC结束 |

| 7/8/9 | 双通道256 bit边界前、正好、边界后 |

| 15/16/17 | 单通道256 bit边界前、正好、边界后 |

| 10～100 µs | 覆盖实际短采尾段 |

| 1 ms | 验证较长连续打包和计数 |


# 6. 用例B：端到端数字逻辑骨架

| 参数 | 当前值 |

| ADC / SYS时钟 | 250 MHz / 125 MHz，异步相位 |

| Segment | 4 × 4096 Byte |

| DDR背压 | AWREADY/WREADY随机撤销，BVALID随机延迟 |

| Capture 1 | 双通道1024个采样时刻，正好填满1个4 KiB Segment |

| Capture 2 | 单CH0，17个采样，尾段补零到4 KiB |

| Capture 3 | 单CH1，9个采样，尾段补零到4 KiB |

| 每个Capture请求 | Payload WRITE、Flush#1、Commit WRITE、Flush#2 |


等待`capture_ready`后开始，防止CDC FIFO仍处于复位忙状态。

ADC每个时钟给出一组样本，不能用ready反压真实ADC。

打包数据经263 bit异步FIFO进入125 MHz系统域。

DDR Writer在随机AXI背压下写入假DDR并补齐4 KiB。

测试平台逐字节读取假DDR数组，比较三种模式。

检查所有Segment最终回到FREE，错误和丢样计数为0。

检查Commit magic、请求总数和WRITE/FLUSH opcode计数。

| 这个用例没有做的事 假NVMe没有读取DDR。因而该用例证明的是：ADC格式、CDC、DDR写握手、分段所有权和NVMe控制顺序在数字逻辑模型内一致；它不证明SSD能从DDR搬走这些数据。 |


# 7. 用例C：NVMe异常路径

| 注入事件 | 期望结果 |

| Completion status非0 | fatal_error，错误状态上传 |

| Completion Tag错误 | 状态FFFF，禁止误释放Segment |

| 永久不返回Completion | 达到32周期测试超时，timeout_sticky |

| PCIe Link Down | link_down_sticky和fatal_error |

| 第一次Flush失败 | Capture不完成并进入fatal |

| ECQE错误通知 | 记录状态并进入fatal |


异常测试每个场景前独立复位，避免上一个sticky状态影响下一项。真实系统的超时阈值需要按系统时钟和供应商最大延迟重新设定。

# 8. 断言和在线检查

`valid && !ready`期间ADC打包Payload必须稳定。

AXI AW和W通道在等待ready时地址、数据和控制字段必须稳定。

NVMe请求在等待ready时opcode、地址、长度、SLBA和Tag必须稳定。

WRITE/READ的DDR地址、DMA长度必须4 KiB对齐且长度非0。

Segment只允许FREE→FILLING→READY→INFLIGHT→FREE或进入ERROR_HOLD。

正常用例accepted_sample_times等于输入，dropped_sample_times必须为0。

采集中配置不能改变有效模式。

# 9. 如何运行

cd E:\NVME_PRO\nvme_adc_axi_pipeline
& .\scripts\run_vivado_regression.ps1

脚本固定调用 `D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`。每个测试平台单独创建临时Vivado工程，搜索`TEST_PASS`；全部通过后生成JSON汇总。

| 输出 | 位置/说明 |

| simulate.log | build/regression/<test>/.../xsim/simulate.log |

| WDB | 同一xsim目录；失败时用于展开关键信号 |

| 回归汇总 | build/regression/summary.json |

| OOC资源 | build/vivado_synth/utilization_ooc.rpt |

| OOC时序 | build/vivado_synth/timing_ooc.rpt；无XDC，不作最终结论 |


# 10. 失败定位顺序

先读simulate.log中的第一条Fatal，不要从最后一个错误倒推。

确认测试输入、模式和sample_count是否一致。

若字节错位，先看packer的valid_bytes/EOC，再看CDC FIFO握手。

若DDR错位，检查AW地址、Burst长度、W握手和WLAST。

若Segment未释放，检查Tag、Completion状态和状态跳转。

若Capture不完成，检查Payload是否排空、两次Flush和Commit完成。

# 11. 真实DDR测试过程

| 阶段 | 测试对象 | 通过条件 |

| DDR-1 | 官方MIG Example Design | init_calib_complete稳定，Pattern无错 |

| DDR-2 | 内部500 MB/s数据发生器 | 写后读回CRC一致，FIFO不溢出 |

| DDR-3 | 内部1 GB/s数据发生器 | 持续运行无丢样，记录最大Stall |

| DDR-4 | 读写混合 | ADC Writer和Reader并发，吞吐/仲裁满足要求 |

| DDR-5 | 真实ADC PHY | 测试Pattern、通道顺序、位序、符号和CRC正确 |


在没有DDR颗粒和XDC前，不执行这些上板步骤。需要先完成根目录`board_bringup_inputs.md`。

# 12. PCIe独立Bring-up

使用AMD官方UltraScale PCIe Gen3 Root Port/Configurator Example。

确认100 MHz Refclk、PERST#、GT Lane和供电。

记录Link Up、Gen速率、Lane宽度、配置空间和BAR访问。

必要时使用ILA/协议分析仪观察基础Configuration/Memory TLP。

该工程独立保留，不把它当作NVMe Host，也不在供应商IP到手前并入主工程。

# 13. 供应商黑盒测试过程

| 级别 | 允许条件 | 可写结论 |

| 固定Demo | 不能改参数/数据 | 供应商基线复现 |

| 参数可调 | 可改地址、长度、读写和Flush | 供应商IP黑盒验收 |

| 我方DDR数据 | 可提交我方Pattern并写后读回 | 我方数据接口预演 |

| 交付后集成 | 拿到可复现IP工程 | 我方工程集成验证 |


记录版本、SSD、PCIe Gen/Lane、DDR数据源、I/O大小、Cache和Flush。

用递增Pattern和PRBS做全量读回，不只看API返回成功。

连续写至少10分钟；条件允许时1小时，并覆盖SSD SLC Cache。

记录平均带宽、最低1秒带宽、最长停顿、Flush延迟和SSD温度。

测试Reset后重初始化和ECQE错误读出。

# 14. 四级通过定义

| 等级 | 必须具备的证据 |

| 仿真通过 | 自动化用例PASS、日志/WDB、断言无失败 |

| 真实DDR通过 | MIG校准、Pattern读回、500MB/s/1GB/s CRC和ILA记录 |

| 供应商IP通过 | 黑盒或交付后测试，写后读回、Flush、长稳和错误状态 |

| 完整SSD闭环通过 | 真实ADC→DDR→PCIe/NVMe→SSD→DDR读回，全链路CRC一致 |


| 报告用语 测试报告标题和结论必须带上等级。例如“V2 RTL行为回归通过”是准确的；在当前阶段写“ADC数据成功保存到NVMe SSD”是不准确的。 |


# 附录A：当前自动化覆盖与待补项

| 项目 | 状态 |

| 三模式/边界/10µs/50µs/100µs/1ms | 自动化 |

| 250MHz ADC→125MHz SYS | 自动化 |

| AXI随机背压和B延迟 | 自动化 |

| DDR BRESP错误 | Stub支持；真实端到端专项仍应增加 |

| NVMe状态/Tag/超时/Link/Flush/ECQE | 自动化 |

| 200/250MHz SYS组合 | 接口支持；建议在真实MIG时按UI时钟验证 |

| Segment耗尽长稳 | 待真实DDR容量和SSD停顿模型 |

| 真实MIG/ADC/PCIe/NVMe/SSD | 待板级资料和供应商交付 |
