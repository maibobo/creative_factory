# NVMe_ADC_DDR_FPGA基础通路设计方案_V2.1_供应商补充答疑收敛版

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\NVMe_ADC_DDR_FPGA基础通路设计方案_V2.1_供应商补充答疑收敛版.docx`
- SHA-256: `c77e229621d8211743dfd3e6f143b56e787bef092d77d1d0d4dea9c0764a2cef`
- Extractor: `python-docx+zip-structure-check`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

内部设计说明

NVMe–DDR–ADC FPGA
基础通路设计方案

供应商补充答疑收敛｜V2.0 RTL基线保持｜真实集成条件分级

| 项目项 | 内容 |

| 目标器件/工具 | XCKU040-FFVA1156-2-I｜Vivado 2020.2 |

| 文档版本 | V2.1｜供应商补充答疑收敛版｜2026-07-28 |

| 设计预设 | compact_reference_guide｜memo_masthead |

| 自研基线 | Vivado 2020.2；ADC打包、263 bit CDC、256 bit Writer和Segment结构保持不变 |

| 供应商工程 | 当前使用Vivado 2024.2；正式交付后在独立工作区集成 |

| 本版边界 | 不虚构NVMe M_AXI、正式API、地址换算和自动恢复流程 |


| V2.1结论 供应商补充回复没有推翻V2.0的数据面。当前应保留自研256 bit Writer，通过SmartConnect与供应商当前512 bit MIG配置衔接。截图只证明MIG配置，不能当作NVMe IP M_AXI参数。地址、聚合Completion和“重新下载程序”的实际含义仍须现场确认。 |


# 1. 本版范围和版本关系

V2.0是已经完成行为回归的自研RTL基线，继续保留原文件。V2.1只收敛供应商接口契约、真实集成结构、异常边界和现场验证要求。本版不修改ADC数据格式、CDC、DDR Writer、Segment状态机和项目级单请求结构。

| 项目 | V2.0基线 | V2.1处理 |

| ADC单/双通道 | 已实现并回归 | 保持不变 |

| ADC域256 bit打包 | 已实现并回归 | 保持不变 |

| 263 bit CDC | 已实现并回归 | 保持不变 |

| 256 bit DDR Writer | 已实现并回归 | 保持不变 |

| Segment/Tag | 已实现并回归 | 保持不变 |

| 供应商接口 | 抽象req/cpl | 补充三态契约，不猜测真实API |

| 工具版本 | Vivado 2020.2 | 供应商2024.2独立集成 |

| 验证 | 三组行为回归 | 新增AXI Burst 4 KiB边界断言 |


| 状态用语 CONFIRMED表示供应商已明确；AMBIGUOUS表示有回复但口径仍冲突；UNKNOWN表示当前资料没有给出。AMBIGUOUS和UNKNOWN都不能写成RTL固定事实。 |


# 2. 供应商补充回复：CONFIRMED

| 对象 | 已确认事实 | 设计动作 |

| MIG截图 | 512 bit数据、32 bit地址、ID=1、RD_PRI_REG、833 ps | 只标记为MIG配置 |

| 共享DDR | 支持NVMe通路与ADC Writer共同访问MIG | 保留SmartConnect |

| 上层请求 | 一次只能提交一个大DMA任务 | 保持单请求在途 |

| 内部并发 | 16个Queue，Depth最大1024，按MDTS拆SQE | 不实现应用层多Outstanding |

| 最小单位 | 供应商答复为512 B | 项目仍按4 KiB对齐 |

| 异常 | 当前建议为重新下载程序 | fatal后冻结并人工恢复 |

| 工程版本 | 供应商当前使用Vivado 2024.2 | 独立目录集成 |


# 3. 仍有歧义和未知的事项

## 3.1 AMBIGUOUS

| 事项 | 歧义 | 需要的现场证据 |

| NVMe M_AXI | MIG截图不能证明NVMe端口也是512/32/ID1 | 正式端口表或BD连接 |

| DDR地址 | Absolute还是相对DDR Offset未说明 | API入参到MIG地址换算示例 |

| 2 TB口径 | 与32 bit本地DDR地址不属于同一层 | 明确SSD/LBA/PCIe/DDR哪一层 |

| 4 KiB示例 | 0x400 + 4 KiB会跨0x1000 | 展示内部Burst拆分或更正示例 |

| 聚合完成 | 未说明是否等待全部内部SQE | 大任务Completion时序说明 |

| 重新下载 | bitstream还是MicroBlaze ELF未说明 | 现场完整恢复演示 |

| Flush | 接口、排序和持久化完成语义未给出 | Write→Flush调用及状态日志 |


## 3.2 UNKNOWN

| 未知项 | 当前缺失 | 当前工程处理 |

| NVMe DDR M_AXI | 位宽、时钟、复位、Outstanding、ID、Burst | 只定义SmartConnect接入要求 |

| Read/Write/Flush API | 函数/寄存器、字段、参数单位 | 不编写猜测性Adapter |

| 请求/完成 | Ready/Busy、聚合Completion、Tag、状态码 | 保留通用req/cpl和Mailbox上下文 |

| ECQE | 字段、深度、清除、溢出、中断 | 只保留抽象错误入口 |

| DDR保留区 | SQ/CQ/PRP/Context是否占用外部DDR | 不分配最终地址图 |

| 现场文件权限 | 工程、bitstream、ELF、脚本和日志能否留存 | 现场前书面确认 |


# 4. V2.1正式集成结构

ADC Writer 256-bit M_AXI
           │
           ▼
SmartConnect：仲裁 + 必要的256→512 bit宽度转换
           │
           ▼
供应商当前MIG 512-bit S_AXI → DDR
           ▲
           │
供应商NVMe DDR M_AXI（实际位宽、时钟和复位仍未知）

不把ADC域打包器和DDR Writer直接改为512 bit。

256 bit×125 MHz理论载荷为4 GB/s，高于双通道1 GB/s输入，宽度不是当前瓶颈。

SmartConnect需要处理仲裁；只有在实际端口不匹配时才启用宽度/时钟转换。

MIG的RD_PRI_REG可能增加ADC写等待，必须用ILA测最长AW/W Stall和FIFO最大水位。

| 不能提前生成的对象 当前没有真实DDR颗粒、MIG/XDC和供应商IP工程，不生成假MIG，不创建假Block Design，也不把供应商截图参数硬编码进自研顶层。 |


# 5. DDR地址契约

项目内部继续使用64 bit DDR地址。未来供应商适配层只负责控制面的地址检查和换算，不复制ADC Payload。正式API未提供前只定义以下输入输出要求。

项目请求：project_ddr_addr[63:0]
          ↓ 范围/对齐检查
          ↓ Absolute或Offset换算（规则待确认）
供应商API：vendor_ddr_address_or_offset
          ↓ 供应商内部地址参数
最终MIG AXI地址

| 检查 | 要求 |

| 范围 | 地址和长度必须落在分配给Payload/Readback的DDR窗口内 |

| 溢出 | 64 bit到供应商地址位宽收窄前必须检查高位 |

| 保留区 | 不得与供应商SQ/CQ/PRP/Context区重叠 |

| 所有权 | 请求完成前Segment不得被ADC覆盖 |

| 实现门槛 | 必须先拿到正式API和一组地址换算示例 |


# 6. 三层对齐和4 KiB边界

| 层次 | 规则 | 当前动作 |

| 项目策略 | Buffer起始地址和NVMe DMA长度按4 KiB对齐 | 保持不变 |

| 供应商最小单位 | 答复为512 B | 只记录，不放宽RTL |

| AXI4 Burst | 单个Burst不能跨4 KiB边界 | 系统TB新增断言 |


当前Burst = 256 bit/beat × 16 beat = 512 Byte
检查条件  = AWADDR[11:0] + ((AWLEN+1) << AWSIZE) <= 4096

4 KiB对齐Segment内包含8个512 B Burst，各Burst起点依次为0x000、0x200、0x400、0x600、0x800、0xA00、0xC00和0xE00，最后一个正好结束于下一4 KiB边界。供应商的0x400 + 4 KiB示例只有在内部拆分为多个Burst时才合法。

# 7. 请求、内部并发和Completion

项目层：一次提交一个大DMA请求
  request = opcode + ddr_addr + byte_len + slba + user_tag
             ↓
供应商IP：按MDTS拆分SQE，使用内部Queue/CID/PRP
             ↓
项目层：接收一条整笔任务Completion（完成语义待确认）

项目Tag继续使用{generation, segment_id}，它不是内部NVMe CID。

不假定供应商API原样返回user_tag；Mailbox保存本地关联。

不实现应用层多Outstanding，也不自行拆MDTS、SQE或PRP。

只有全部内部SQE完成后的聚合Completion才能释放Segment。

# 8. Fatal冻结与人工恢复

| 触发 | V2.1动作 |

| Command Timeout | fatal；保持INFLIGHT数据 |

| Completion/Tag错误 | fatal；禁止误释放Segment |

| PCIe Link Down | fatal；停止新请求和新Capture |

| ECQE | fatal；保存错误状态 |

| Flush失败 | fatal；Capture不得标记完成 |


停止接受新的Capture。

停止提交新的NVMe请求。

保持INFLIGHT和ERROR_HOLD Segment，不覆盖原数据。

不自动重试，不根据Timeout猜测SSD已经停止访问DDR。

等待人工执行供应商定义的重新下载或系统级恢复。

| 删除的旧假设 V2.1不再写“MicroBlaze一定可以自动重新初始化恢复”。只有供应商现场演示并给出可执行流程后，才能把恢复路径写入产品状态机。 |


# 9. Vivado版本隔离

| 工作区 | 工具 | 规则 |

| 自研RTL基线 | Vivado 2020.2 | 继续运行三组行为回归，不覆盖历史工程 |

| 供应商集成 | Vivado 2024.2 | 到货后新建独立目录，按供应商工程版本接入 |

| 共同RTL | 未来双版本检查 | 先编译/仿真，再处理IP与BD版本差异 |


本机当前没有Vivado 2024.2，本轮不创建或运行2024.2脚本。不能用2024.2直接打开并保存唯一的2020.2工程，也不能把供应商2024.2工程强行降级。

# 10. 本轮实现和验证

| 对象 | 本轮动作 |

| 正常数据面RTL | 不修改 |

| 系统testbench | 新增AXI AW Burst不跨4 KiB边界断言 |

| vendor_ip_contract.md | 改为CONFIRMED/AMBIGUOUS/UNKNOWN三态矩阵 |

| README | 改为V2.0 RTL基线 + V2.1集成契约 |

| 现场清单 | 新增文件权限、地址、Completion、Pattern、长稳和恢复记录 |

| 自动回归 | 继续使用Vivado 2020.2三组行为回归 |

| Word文档 | 新建V2.1/V1.1，不覆盖旧版本，不做PDF/PNG渲染 |


# 11. 进入真实集成的门槛

项目组提供真实DDR颗粒、原理图引脚、时钟和XDC。

供应商交付可复现的Vivado 2024.2工程和正式端口/API说明。

确认DDR地址Absolute/Offset换算和供应商DDR保留区。

确认大任务Completion等待全部内部SQE。

确认Flush完成和异常恢复语义。

先完成MIG Example Design和DDR写后读回CRC。

再完成我方Pattern DDR→SSD→DDR闭环，最后接真实ADC PHY。

# 12. 当前准确结论

| 可以确认 自研ADC格式化、CDC、DDR写入骨架、Segment所有权和抽象NVMe控制顺序已具备真实集成基础。供应商补充回复使SmartConnect共享DDR、项目级单请求和内部多SQE方向进一步明确。 |


| 仍不能确认 真实MIG、供应商NVMe M_AXI、地址映射、聚合Completion、Flush持久化、异常恢复和完整SSD写入尚未接入或验证，因此不能写“完整通路已打通”。 |
