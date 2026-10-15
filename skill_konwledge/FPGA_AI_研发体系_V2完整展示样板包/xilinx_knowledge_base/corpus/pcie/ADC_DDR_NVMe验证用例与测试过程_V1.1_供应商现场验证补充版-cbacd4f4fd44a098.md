# ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版.docx`
- SHA-256: `cbacd4f4fd44a0980553b30395d116988578cc5d238d18800ed80e46bf3bc5f0`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版.docx

内部测试说明

ADC–DDR–NVMe
验证用例与测试过程

供应商现场黑盒验证补充｜证据留存｜交付后集成分级

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V1.1｜供应商现场验证补充版｜2026-07-28 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 现场限制 | 暂不交付源码、网表/DCP或可修改的完整工程 |

| 本次目标 | 验证黑盒功能、外部DDR数据一致性、性能、Flush和恢复 |

| 不包含 | 我方MIG/SmartConnect/ADC Writer与供应商IP的真实工程集成 |


| 测试底线 时间有限时优先完成四项：可修改DDR地址/长度/SLBA；我方Pattern写后读回一致；连续写至少10分钟并记录最低1秒带宽；Write→Flush→Readback及一次完整恢复演示。 |


# 1. 验证等级和结论口径

| 等级 | 条件 | 允许结论 |

| A：固定Demo | 只能运行供应商原程序 | 供应商基线复现 |

| B：参数化黑盒 | 可改地址、长度、SLBA、Opcode和Flush | 黑盒功能/性能验证 |

| C：我方Pattern | DDR A写SSD后读回DDR B一致 | 外部DDR数据接口预演 |

| D：交付后集成 | 取得工程并接我方MIG/ADC | 我方工程集成验证 |


没有源码或可复现工程不等于完全不能测试，但通常只能在供应商电脑、板卡和Demo环境中进行黑盒验证。能否在我方电脑运行、能否拷贝文件和能否修改程序必须在测试前逐项确认。

# 2. 测试前登记

| 类别 | 必须记录 |

| 环境 | 日期、地点、人员、测试电脑归属、板卡归属 |

| FPGA/工程 | 器件、板卡版本、Vivado/Vitis版本、IP/工程/bitstream/ELF版本 |

| SSD | 型号、容量、固件、Namespace、LBA Size、MDTS |

| PCIe | 实际Gen、Lane、Link状态、Refclk和PERST# |

| DDR | 颗粒/容量、MIG宽度/时钟、校准状态、测试地址窗口 |

| 缓存/命令 | SSD Cache、I/O大小、Queue、Depth、Flush设置 |


# 3. 文件和证据权限

| 对象 | 现场要确认 |

| Vivado工程 | 可查看、可修改、可保存或只能现场运行 |

| MicroBlaze源码/BSP | 是否可查看、修改、带走 |

| bitstream/ELF | 是否允许复制；若不允许，记录版本和Hash |

| 测试脚本 | 是否可保存现场修改版本 |

| 日志/结果 | 串口、性能表、寄存器、ILA截图是否可保存 |

| 接口资料 | 寄存器/API/状态码说明是否可获取 |


| 无法拷贝时 要求供应商允许留存签字记录、参数截图、结果截图、版本号和日志摘要。只有口头说明、没有可追溯证据的项目应标记为未确认。 |


# 4. 现场必须澄清的四类接口

## 4.1 DDR地址Absolute或Offset

记录API输入地址或Offset。

记录供应商DDR_BASE/OFFSET参数。

记录最终MIG AXI地址。

解释当前32 bit MIG地址宽度与此前2 TB口径。

## 4.2 4 KiB边界

解释`0x400 + 4 KiB`如何满足单个AXI Burst不跨4 KiB。

若IP内部拆分，记录各子Burst地址和长度。

确认高层大DMA任务允许跨多个4 KiB页面。

## 4.3 大任务Completion

确认全部内部SQE完成后才返回整笔大任务Completion。

确认任一内部SQE失败时整笔任务如何失败。

确认Flush与此前拆分SQE的排序。

## 4.4 重新下载程序

明确重新配置bitstream、下载MicroBlaze ELF或两者都需要。

明确是否还需SSD PERST#或断电。

明确旧Context和INFLIGHT Buffer何时安全释放。

# 5. 测试1：供应商基线

确认PCIe Link Up、Gen和Lane宽度。

完成SSD枚举、Identify和I/O Queue创建。

复现供应商顺序Write/Read性能。

确认数据源确实位于外部DDR，不是BRAM或IP内部Pattern。

记录Cache、Flush、I/O大小、Queue和Depth。

# 6. 测试2：参数化Read/Write

| 长度 | 目的 | 检查 |

| 4 KiB | 项目最小对齐任务 | 地址/长度/SLBA可修改，写后读回 |

| 512 KiB | 接近当前报告MDTS拆分粒度 | 跨页、Completion、数据一致 |

| 4 MiB | 产品候选Segment | 大任务自动拆分、性能和完成 |

| 1 GiB | 条件允许的大任务 | 内部多SQE、长任务完成和地址范围 |


每个长度至少使用两个不同DDR地址和两个不重叠SLBA。Read目标区域先清零或填反码，避免误把旧内存内容当作读回成功。

# 7. 测试3：我方Pattern闭环

DDR A写入递增Pattern或PRBS并计算CRC
→ NVMe Write到指定SLBA
→ DDR B清空
→ NVMe Read同一SLBA到DDR B
→ A/B逐字节比较或分别计算CRC

递增Pattern和PRBS至少各执行一次。

必须覆盖跨多个4 KiB页面的数据。

必须比较真实Payload，不能只检查API返回成功。

记录源/目标DDR地址、SLBA、长度、状态、CRC和耗时。

# 8. 测试4：Write、Flush和Readback

提交Write并等待整笔任务Completion。

提交Flush并等待Completion。

Read同一SLBA到另一DDR区域。

逐字节或CRC比较。

记录Flush完成状态、平均/本次最大延迟及供应商持久化说明。

| 当前Capture顺序 项目使用Payload Write完成→Flush→Commit Write完成→Flush。现场需要确认供应商接口支持这个顺序，且Flush等待此前大任务的全部内部SQE。 |


# 9. 测试5：连续写性能

| 指标 | 要求 |

| 时长 | 至少10分钟；条件允许时1小时 |

| 容量 | 写入量应超过SSD SLC Cache |

| 平均带宽 | 双通道采购建议不低于1.2 GB/s |

| 最低带宽 | 记录最低1秒窗口，不能只报平均值 |

| 最长停顿 | 记录最长无Completion或无DMA进展时间 |

| Flush | 记录延迟及其对连续写的影响 |

| 温度 | 记录起始、最高、结束温度和热降速 |

| 错误 | 记录CQE/ECQE、Timeout和Link异常 |


平均3.3 GiB/s不能单独证明1 GB/s ADC长期无丢样。DDR Segment容量取决于最低带宽和最长停顿，因此这两项是现场必测数据。

# 10. 测试6：恢复演示

记录异常前的请求、DDR地址、SLBA和Buffer状态。

按供应商方法执行一次“重新下载程序”。

记录下载对象、所有人工步骤和恢复耗时。

重新完成PCIe/NVMe初始化。

执行4 KiB Write→Flush→Readback并比较。

说明异常前INFLIGHT Buffer的最终处理规则。

# 11. 当前自动回归的补充检查

现场黑盒测试不能替代当前V2 RTL回归。本轮不改正常数据面，只在`tb_nvme_adc_pipeline`增加以下AXI4边界断言：

AWADDR[11:0] + ((AWLEN + 1) << AWSIZE) <= 4096

| 测试平台 | 继续验证 |

| tb_adc_channel_packer | 三模式、边界长度、字节序和配置锁存 |

| tb_nvme_adc_pipeline | CDC、随机AXI背压、DDR内容、Segment、Flush/Commit及4 KiB Burst |

| tb_nvme_scheduler_errors | Completion/Tag/Timeout/Link/Flush/ECQE错误 |


三组测试继续由`D:\Xilinx_2020_2\Vivado\2020.2\bin\vivado.bat`运行。供应商2024.2工程未交付且本机未安装2024.2，本轮不创建2024.2脚本。

# 12. 交付后真实集成验证

在供应商2024.2独立工作区重建并复现原Demo。

接入真实MIG并确认init_calib_complete。

使用SmartConnect连接256 bit ADC Writer和NVMe DDR Master。

内部500 MB/s/1 GB/s Pattern写DDR并读回CRC。

已知DDR数据经NVMe Write到SSD并Read回另一DDR区域。

并发压力下记录FIFO最大水位和ADC Writer最长Stall。

最后接真实ADC PHY并完成全链路CRC。

# 13. 现场报告模板

| 字段 | 填写内容 |

| 达到等级 | A / B / C；未取得工程前不能写D |

| 最大任务 | 4 KiB / 512 KiB / 4 MiB / 1 GiB |

| Pattern闭环 | 递增/PRBS，全量或CRC结果 |

| 性能 | 时长、平均、最低1秒、最长停顿 |

| Flush | 调用顺序、完成状态和延迟 |

| 温度/错误 | 起始/最高/结束温度，CQE/ECQE/Link |

| 恢复 | 下载对象、步骤、耗时和恢复后读写 |

| 文件证据 | 可带走的工程、bitstream、ELF、脚本、日志和截图 |

| 未决问题 | 地址、Completion、4 KiB拆分和接口字段 |


| 报告禁用语 在取得供应商可复现工程并接入我方MIG/SmartConnect/ADC之前，禁止写“完整ADC数据已保存到NVMe SSD”或“我方工程已集成通过”。 |
