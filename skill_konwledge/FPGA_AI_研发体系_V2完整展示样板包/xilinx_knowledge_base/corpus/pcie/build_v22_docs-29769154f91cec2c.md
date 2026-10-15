# build_v22_docs

- Category: `pcie`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_v22_docs.py`
- SHA-256: `29769154f91cec2c732f6c6ca9e9cb1d3bc059c7bd0882b5cf2ddca514a0b8c9`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

```python
"""生成V2.2 NoPHAE用户指南接口收敛版DOCX。

本脚本保留V2.0/V2.1历史文件和生成器，只复用既有版式函数。正文事实来自
2026-07-29更新的《用户指南》以及此前供应商答疑；每一项严格区分已确认、
合理推断和仍需供应商确认。按用户要求，本脚本不调用LibreOffice，不生成
PDF、PNG或页面截图，结构完整性由check_v22_docx_structure.py检查。
"""

from pathlib import Path

from build_design_doc import add_bullet, add_callout, add_code, add_number, add_table
from build_v2_docs import add_masthead, configure_doc


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
OUT = DOCS / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.2_NoPHAE用户指南接口收敛版.docx"

# V2.2继续采用V2系列的紧凑工程参考手册样式，使版本差异集中在技术内容，
# 而不是重新设计标题、表格和页眉体系。
DESIGN_PRESET = "compact_reference_guide"
HEADER_TEMPLATE = "memo_masthead"


def set_core_properties(doc):
    """写入可由结构检查脚本读取的版本和用途元数据。"""

    core = doc.core_properties
    core.title = "NVMe_ADC_DDR_FPGA基础通路设计方案 V2.2"
    core.subject = "NoPHAE用户指南接口、DMA寄存器、KU040风险和供应商问题收敛"
    core.author = "项目组"
    core.keywords = (
        "ADC, DDR, NVMe, NoPHAE, AXI4-Lite, DMA, XCKU040, Vivado, V2.2"
    )


def add_status_legend(doc):
    """统一三态词义，避免把存在寄存器误写成寄存器语义已经完全确认。"""

    add_table(
        doc,
        ["状态", "本文中的准确含义"],
        [
            ("CONFIRMED", "用户指南或供应商书面回复已明确给出，可进入接口设计"),
            (
                "INFERENCE",
                "根据现有资料形成的合理解释，只用于理解，不能硬编码为供应商事实",
            ),
            (
                "AMBIGUOUS",
                "资料有描述但对象、单位、有效值或示例存在冲突，必须继续确认",
            ),
            (
                "UNKNOWN",
                "当前资料没有给出；真实IP到手前不得在Adapter中假定",
            ),
        ],
        [1.25, 5.25],
    )


def build_v22():
    """按“新增事实→架构影响→未决问题→供应商问题”生成V2.2设计文档。"""

    doc = configure_doc("ADC · DDR · NVMe V2.2用户指南契约")
    add_masthead(
        doc,
        "内部设计说明",
        "NVMe–DDR–ADC FPGA\n基础通路设计方案",
        "NoPHAE用户指南接口收敛｜V2.0 RTL保持｜真实控制Backend边界",
        "V2.2｜NoPHAE用户指南接口收敛版｜2026-07-29",
        [
            (
                "历史关系",
                "V2.0为自研RTL基线；V2.1为2026-07-28供应商补充答疑历史契约",
            ),
            (
                "新增依据",
                r"E:\NVME_PRO\用户指南.docx；接口、寄存器、DMA和样例API",
            ),
            (
                "本版边界",
                "不修改RTL，不虚构KU040配置、DMA地址语义、Flush或自动恢复",
            ),
        ],
    )
    add_callout(
        doc,
        "V2.2结论",
        "用户指南已经公开NoPHAE的AXI4-Lite控制口、AXI4-Full DDR Master、"
        "初始化/DMA/原生命令寄存器和软件API，因此真实控制Backend可以进入"
        "接口设计与行为仿真阶段。ADC数据面无需重构；没有KU040交付工程、地址"
        "示例、dma_done聚合语义和Flush流程前，仍不能完成真实IP集成。",
    )
    doc.add_page_break()

    # 第一章固定历史文件关系，明确V2.2是接口认知升级而不是重新证明RTL。
    doc.add_heading("1. 本版范围和历史关系", level=1)
    doc.add_paragraph(
        "V2.0继续作为已经通过行为回归的自研RTL基线。V2.1继续保留，记录"
        "2026-07-28供应商补充答疑时的三态契约。V2.2根据更新的用户指南修正"
        "“真实控制接口整体未知”的旧判断，但不覆盖历史DOCX或生成器。"
    )
    add_table(
        doc,
        ["对象", "V2.1结论", "V2.2处理"],
        [
            ("ADC/CDC/Writer", "已经实现和回归", "保持不变"),
            ("Segment/Tag", "单大请求在途，本地Tag", "保持不变"),
            ("NoPHAE控制口", "整体UNKNOWN", "AXI4-Lite和寄存器表已确认"),
            ("NoPHAE DDR口", "端口参数UNKNOWN", "端口类型及参数可配置已确认；实例值未知"),
            ("DMA", "抽象req/cpl", "寄存器和512 B长度单位已确认；地址/完成语义未知"),
            ("Flush", "供应商声称支持", "高层DMA无入口；真实Backend仍阻塞"),
            ("KU040", "沿用供应商测试结论", "指南未列UltraScale Gen3，升级为P0风险"),
        ],
        [1.45, 2.25, 2.8],
    )
    add_status_legend(doc)

    # 第二章只收录用户指南可以直接读出的端口和能力，不外推实际实例配置。
    doc.add_heading("2. 用户指南新增的CONFIRMED事实", level=1)
    add_table(
        doc,
        ["类别", "指南明确内容", "当前设计动作"],
        [
            (
                "IP定位",
                "FPGA侧NVMe Host Controller；NVMe 1.3d、PCIe 3.0",
                "保持FPGA Host/Root、SSD Endpoint架构",
            ),
            (
                "CPU依赖",
                "兼容SoC和无CPU纯逻辑环境",
                "首联可用MicroBlaze，后续可换纯RTL控制",
            ),
            (
                "控制接口",
                "32 bit s_axi_ctrl AXI4-Lite；基址4 KiB对齐、空间4 KiB",
                "真实Backend通过AXI-Lite访问寄存器",
            ),
            (
                "DDR接口",
                "m_axi为AXI4-Full Master；DATA/ADDR/ID宽度可配置",
                "继续经SmartConnect访问MIG",
            ),
            (
                "队列",
                "最多16个I/O队列；单队列和总深度最大1024",
                "项目层仍保持单请求，不复制内部队列逻辑",
            ),
            (
                "DMA",
                "公开type/len/src/dst/ready/done；长度单位512 B",
                "可以建立NoPHAE寄存器行为模型",
            ),
            (
                "原生命令",
                "公开PRP、CDW10~13、cmd_wr、队列创建和命令计数",
                "证明低层命令入口存在，不等于Flush已落实",
            ),
            (
                "错误Completion",
                "公开cq_no_err、cq_ren和错误CQE DW3/DW2",
                "可以设计抽象错误入口，字段关联仍待确认",
            ),
            (
                "软件样例",
                "ZCU106裸机API含初始化、队列、顺序读写、Identify和SMART",
                "首联优先复用软件，但不把ZCU106当作KU040证明",
            ),
        ],
        [1.25, 3.15, 2.1],
    )

    doc.add_heading("3. NoPHAE顶层连接边界", level=1)
    add_table(
        doc,
        ["接口/信号", "方向", "作用", "仍需确认"],
        [
            ("pcie_clk", "输入", "PCIe参考时钟", "KU040 Refclk和GT约束"),
            ("sys_reset", "输入", "高有效系统复位", "与PCIe/PERST#的顺序"),
            ("axi_clk", "输入", "m_axi时钟", "交付实例实际频率"),
            ("axi_resetn", "输入", "m_axi低有效复位", "释放条件和同步关系"),
            ("user_clk/reset", "输出", "IP内部用户时钟和复位", "s_axi_ctrl是否属于该域"),
            ("s_axi_ctrl", "Slave", "32 bit AXI4-Lite寄存器口", "准确时钟和复位"),
            ("m_axi", "Master", "外部DDR数据搬运", "实例宽度、ID、Burst、Outstanding"),
            ("pci_exp", "PCIe", "连接NVMe SSD", "KU040 PCIe Wrapper和Lane约束"),
            ("状态输出", "输出", "Link/PCIe/NVMe/CQE状态", "跨域和去毛刺要求"),
        ],
        [1.45, 0.65, 2.15, 2.25],
    )
    add_callout(
        doc,
        "参数边界",
        "供应商此前512 bit、32 bit、ID=1、RD_PRI_REG、833 ps截图仍然只证明"
        "其MIG配置。用户指南说明NoPHAE m_axi宽度可配置，但没有给出KU040"
        "交付实例的实际参数，二者不能混写。",
        fill="FFF4E5",
    )

    # 数据面只增加NoPHAE Master的板级位置，不改已经回归的自研接口。
    doc.add_heading("4. 正式数据面保持不变", level=1)
    add_code(
        doc,
        "ADC → 256 bit打包 → 263 bit CDC\n"
        "    → 256 bit DDR Writer\n"
        "    → SmartConnect → MIG/DDR\n"
        "                         ▲\n"
        "                         │\n"
        "             NoPHAE m_axi（实例参数待确认）",
    )
    add_bullet(doc, "ADC格式、单/双通道、采样计数、FIFO和尾段逻辑不修改。")
    add_bullet(doc, "ADC Writer继续为256 bit，不因MIG截图直接改成512 bit。")
    add_bullet(doc, "SmartConnect负责多Master仲裁及实际需要的宽度/时钟转换。")
    add_bullet(doc, "NoPHAE只通过m_axi读写已分配DDR区域，不经过MicroBlaze复制Payload。")
    add_bullet(doc, "真实并发测试必须记录ADC Writer最长AW/W Stall和FIFO最大水位。")

    # 控制面分首联和产品候选两条路径，明确为何先软件后纯RTL。
    doc.add_heading("5. 真实控制面建议", level=1)
    doc.add_heading("5.1 首轮集成：Mailbox＋MicroBlaze", level=2)
    add_code(
        doc,
        "nvme_request_scheduler\n"
        "        ↓ req/cpl\n"
        "nvme_mailbox_backend\n"
        "        ↓ 描述符\n"
        "MicroBlaze供应商API\n"
        "        ↓ s_axi_ctrl\n"
        "NoPHAE",
    )
    add_bullet(doc, "复用供应商已经运行过的初始化、队列和DMA软件，优先降低接口解释风险。")
    add_bullet(doc, "MicroBlaze只处理DDR地址、长度、SLBA和状态，不执行Payload memcpy。")
    add_bullet(doc, "样例关闭Cache提示软件访问DDR时必须考虑一致性；项目Payload宜映射为不可缓存或完全不由CPU访问。")

    doc.add_heading("5.2 后续可选：纯RTL AXI-Lite Backend", level=2)
    add_code(
        doc,
        "nvme_request_scheduler\n"
        "        ↓ req/cpl\n"
        "NoPHAE RTL AXI-Lite Backend\n"
        "        ↓ s_axi_ctrl\n"
        "NoPHAE",
    )
    doc.add_paragraph(
        "指南确认无CPU控制可行，因此纯RTL不是架构障碍。但队列初始化、DMA地址、"
        "dma_done、Flush和恢复仍存在歧义；未取得更正后的寄存器说明和现场日志前，"
        "不应把这些语义固化进产品状态机。"
    )

    doc.add_heading("6. 初始化和DMA寄存器映射", level=1)
    add_table(
        doc,
        ["偏移", "寄存器", "已确认用途", "Backend当前处理"],
        [
            ("0x00", "pcie_init_start", "写1启动PCIe初始化", "可建立初始化FSM"),
            ("0x04", "nvme_init_start", "写1启动NVMe初始化", "可建立初始化FSM"),
            ("0x1C", "nophae_status", "Link/PCIe/NVMe完成位", "轮询并与状态输出交叉检查"),
            ("0x2C", "clr_queues", "清队列", "有效值冲突，暂不固化"),
            ("0x44", "dma_type", "1写、0读", "业务方向仍需用示例确认"),
            ("0x48", "dma_len", "长度单位512 B", "未来执行byte_len/512"),
            ("0x4C", "dma_srcaddr", "DMA源地址", "DDR/LBA和单位未知"),
            ("0x50", "dma_dstaddr", "DMA目的地址", "DDR/LBA和单位未知"),
            ("0x54", "dma_ready", "高时允许新DMA", "可映射req_ready粗粒度门槛"),
            ("0xAC", "cq_no_err", "低表示存在错误CQE", "可产生错误入口"),
            ("0xB0~B8", "cq_ren/rdata", "读错误CQE DW3/DW2", "读取/清除语义未知"),
            ("0xC8", "dma_done", "DMA完成", "聚合、保持和清除语义未知"),
            ("0xCC", "MDTS", "最大NVMe命令请求长度", "单位和写入方法未知"),
        ],
        [0.75, 1.45, 2.25, 2.05],
    )

    doc.add_heading("7. 抽象请求如何映射到NoPHAE", level=1)
    add_code(
        doc,
        "项目请求：opcode + ddr_addr[63:0] + byte_len + slba + user_tag\n"
        "          ↓\n"
        "Backend等待dma_ready\n"
        "          ↓\n"
        "检查范围、对齐和地址单位\n"
        "          ↓\n"
        "dma_len = byte_len / 512\n"
        "          ↓\n"
        "配置srcaddr/dstaddr/type（映射待供应商示例）\n"
        "          ↓\n"
        "等待dma_done或本地Timeout\n"
        "          ↓\n"
        "用本地保存的user_tag返回项目Completion",
    )
    add_bullet(doc, "NoPHAE高层DMA寄存器没有用户Tag，项目Tag不进入供应商IP。")
    add_bullet(doc, "单请求在途使Backend可以用一个上下文寄存器保存当前Tag。")
    add_bullet(doc, "只有确认dma_done等待全部内部SQE后，Segment才能从INFLIGHT释放。")
    add_bullet(doc, "项目继续4 KiB对齐；512 B只是供应商DMA长度单位和最小粒度。")

    doc.add_heading("8. 用户指南中的矛盾与阻塞项", level=1)
    add_table(
        doc,
        ["优先级", "事项", "当前问题", "禁止的错误处理"],
        [
            (
                "P0",
                "KU040 PCIe",
                "只列Virtex-7 Gen3和UltraScale+ Gen4，未列UltraScale Gen3",
                "把ZCU106样例当成KU040证明",
            ),
            (
                "P0",
                "DMA地址",
                "src/dst的DDR、SLBA、单位和Offset不明",
                "按寄存器名称猜测映射",
            ),
            (
                "P0",
                "dma_done",
                "保持/清除/错误/全部SQE完成未知",
                "一见done就无条件释放Segment",
            ),
            (
                "P0",
                "Flush",
                "高层DMA无入口，cmd路径无完整示例",
                "声称两次Flush已能映射真实IP",
            ),
            (
                "P1",
                "clr_queues",
                "表格称高有效，流程要求写0",
                "直接照流程固化状态机",
            ),
            (
                "P1",
                "sq_full",
                "寄存器为[16:0]，流程检查bit[17]",
                "访问不存在的位",
            ),
            (
                "P1",
                "MDTS",
                "4 bit WO，但单位、来源和时机未知",
                "猜测MDTS换算",
            ),
            (
                "P1",
                "DDR保留区",
                "SQ/CQ/PRP/Context位置未知",
                "提前确定最终Segment地址图",
            ),
        ],
        [0.65, 1.2, 2.85, 1.8],
    )

    doc.add_heading("9. Flush、错误和恢复边界", level=1)
    doc.add_paragraph(
        "V2调度器的持久化目标仍然是Payload完成→Flush→Commit完成→Flush。"
        "用户指南没有提供高层Flush寄存器或API，只能证明原生命令入口存在，"
        "因此真实Backend中的Flush继续标为阻塞项。"
    )
    add_table(
        doc,
        ["事件", "当前项目动作", "仍需供应商确认"],
        [
            ("Command Timeout", "fatal并保持INFLIGHT", "是否可Abort及旧DMA最终状态"),
            ("dma_done异常", "不释放Segment", "清除、错误和聚合完成条件"),
            ("cq_no_err=0", "读取并锁存错误入口", "cq_ren顺序、字段、清除和溢出"),
            ("PCIe Link Down", "停止新Capture和请求", "恢复是否需要PERST#/重新配置"),
            ("Flush失败", "Capture不得完成", "Flush错误状态和恢复"),
            ("重新下载程序", "等待人工恢复", "bitstream、ELF还是整机上电"),
        ],
        [1.35, 2.3, 2.85],
    )

    doc.add_heading("10. 当前可以开展的设计与验证", level=1)
    add_number(doc, "依据真实寄存器表建立NoPHAE AXI-Lite行为模型。")
    add_number(doc, "设计初始化、dma_ready、寄存器配置、dma_done和Timeout的Backend框架。")
    add_number(doc, "验证byte_len到512 B单位的换算和非法长度拒绝。")
    add_number(doc, "验证单请求上下文、项目Tag本地保存和完成回送。")
    add_number(doc, "验证cq_no_err错误入口及错误现场寄存器保存。")
    add_number(doc, "准备SmartConnect、NoPHAE m_axi和s_axi_ctrl的板级接口壳。")
    add_number(doc, "保持现有ADC/DDR RTL回归，不因用户指南修改正常数据面。")
    add_callout(
        doc,
        "验证边界",
        "上述工作只能证明控制Backend状态机和项目所有权逻辑，不能模拟真实PCIe、"
        "PRP、SQ/CQ、SSD固件或NAND行为，也不能替代供应商IP上板。",
        fill="FFF4E5",
    )

    doc.add_heading("11. 当前仍不能完成的事项", level=1)
    for text in [
        "确认用户指南所述版本可在XCKU040上综合和实现。",
        "实例化真实NoPHAE、PCIe Root和SSD链路。",
        "确定交付实例的m_axi参数和s_axi_ctrl时钟域。",
        "完成可靠的DDR地址、SLBA和32 bit DMA地址转换。",
        "实现经过确认的Queue创建、MDTS配置和Flush Backend。",
        "验证dma_done的整笔聚合完成语义。",
        "确定SQ/CQ/PRP的DDR保留地址。",
        "验证SmartConnect下ADC写与NoPHAE读DDR并发。",
        "证明真实SSD持续写不低于1 GB/s且采集零丢样。",
        "实现供应商认可的自动异常恢复。",
    ]:
        add_bullet(doc, text)

    # 供应商问题保持8项，便于对方在较短时间内按编号回答。
    doc.add_heading("12. 继续向供应商确认的8个关键问题", level=1)
    questions = [
        (
            "1. XCKU040兼容性",
            "用户指南的PCIEIP_VERSION只列Virtex-7 Gen3和UltraScale+ Gen4。"
            "请确认XCKU040采用哪个PCIe配置、NoPHAE Wrapper和Vivado IP版本，"
            "并提供KU040工程或配置截图；ZCU106样例是否与KU040使用同一套RTL？",
        ),
        (
            "2. 实际AXI接口",
            "请提供KU040交付版本NoPHAE m_axi的DATA/ADDR/ID宽度、时钟、复位、"
            "最大Burst和Outstanding，以及s_axi_ctrl使用的时钟和复位。",
        ),
        (
            "3. DMA地址含义",
            "请分别给出一组NVMe Write和Read寄存器示例，明确dma_srcaddr/"
            "dma_dstaddr中哪个填写DDR地址、哪个填写SLBA，地址单位是Byte、"
            "512 B还是其他单位，以及是绝对地址还是Offset。",
        ),
        (
            "4. DMA启动和完成",
            "请说明哪次寄存器写正式启动DMA；dma_done是脉冲还是保持、如何清除；"
            "DMA失败时状态如何变化；大任务是否等全部内部SQE完成才置位dma_done。",
        ),
        (
            "5. 队列和DDR保留区",
            "请确认clr_queues写0还是1、sq_full检查哪个bit，并说明SQ/CQ、PRP List"
            "和Command Context是否使用外部DDR及其保留范围。",
        ),
        (
            "6. Flush实现",
            "请提供Flush寄存器或cmd()调用示例、完成判断和错误状态，并确认"
            "Write完成→Flush完成的排序及非易失持久化含义。",
        ),
        (
            "7. 错误与恢复",
            "请说明cq_no_err/cq_ren/cq_rdata的读取和清除顺序，以及“重新下载程序”"
            "具体指bitstream、MicroBlaze ELF、SSD PERST#还是整机重新上电。",
        ),
        (
            "8. 交付环境",
            "请确认是否交付KU040可重建工程、PCIe配置、NoPHAE RTL/DCP、"
            "MicroBlaze源码、XDC、API头文件和测试脚本，以及有效Vivado版本。",
        ),
    ]
    for title, body in questions:
        doc.add_heading(title, level=2)
        doc.add_paragraph(body)

    doc.add_heading("13. 进入真实集成的门槛", level=1)
    add_number(doc, "取得XCKU040对应的NoPHAE/PCIe工程并在供应商指定Vivado版本重建。")
    add_number(doc, "取得交付实例的m_axi和s_axi_ctrl完整时钟、复位及参数表。")
    add_number(doc, "关闭DMA地址、启动、dma_done、Queue和Flush五类接口歧义。")
    add_number(doc, "项目组补齐真实DDR颗粒、原理图引脚、时钟和XDC。")
    add_number(doc, "先完成MIG Example Design和内部Pattern写后读回CRC。")
    add_number(doc, "再接NoPHAE，执行DDR Pattern→SSD→另一DDR区域闭环。")
    add_number(doc, "记录并发压力下的FIFO最大水位、最长Stall和SSD最低带宽。")
    add_number(doc, "最后接真实ADC PHY，完成单/双通道全链路验证。")

    doc.add_heading("14. 当前准确结论", level=1)
    add_table(
        doc,
        ["层次", "状态"],
        [
            ("ADC单/双通道格式和计数", "已实现并仿真"),
            ("263 bit CDC", "已实现并仿真"),
            ("DDR Writer和Segment所有权", "已实现并仿真"),
            ("抽象NVMe调度和错误冻结", "已实现并仿真"),
            ("NoPHAE端口和寄存器表", "用户指南已公开"),
            ("NoPHAE控制Backend", "可以开始接口设计和行为建模"),
            ("NoPHAE真实IP实例", "尚未交付"),
            ("KU040 PCIe兼容性", "指南存在冲突，P0确认项"),
            ("真实MIG/PCIe/SSD", "尚未接入和验证"),
        ],
        [2.6, 3.9],
    )
    add_callout(
        doc,
        "最终判断",
        "当前自研数据通路仍然有效；用户指南已经足够支撑控制Backend的接口设计"
        "和仿真，但还不足以支撑真实NoPHAE实例化、地址转换、Flush持久化和"
        "XCKU040板级打通。取得用户指南不等于取得IP或完成集成。",
    )

    set_core_properties(doc)
    DOCS.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    return OUT


def main():
    # 生成器只创建V2.2一个新文件，V2.0/V2.1及其生成器保持原样。
    output = build_v22()
    print(output)


if __name__ == "__main__":
    main()
```
