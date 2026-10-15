# build_v21_docs

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\build_v21_docs.py`
- SHA-256: `984fe59006387ffe3902b62e68114bec9563ec256c06af2ab2483a9136f94370`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_v21_docs.py

```python
"""生成V2.1设计契约和V1.1供应商现场验证DOCX。

本脚本只复用V2.0文档的版式函数，不修改旧生成器，也不覆盖V2.0/V1.0历史
DOCX。用户明确要求不渲染，因此脚本只写Word文件，不调用LibreOffice，不生成
PDF、PNG或页面截图。生成后的完整性由check_v21_docx_structure.py检查。
"""

from pathlib import Path

from docx.shared import RGBColor

from build_design_doc import (
    add_bullet,
    add_callout,
    add_code,
    add_number,
    add_table,
)
from build_v2_docs import configure_doc, add_masthead


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"

DESIGN_OUT = (
    DOCS
    / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.1_供应商补充答疑收敛版.docx"
)
TEST_OUT = (
    DOCS
    / "ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版.docx"
)

# 版式契约：两份新文档继续使用V2.0的紧凑工程参考手册样式和memo_masthead。
# 这样版本差异只来自技术内容，读者不需要重新适应标题、表格和页眉体系。
DESIGN_PRESET = "compact_reference_guide"
HEADER_TEMPLATE = "memo_masthead"


def set_core_properties(doc, title, subject, keywords):
    """统一写入Word核心属性，结构检查据此识别文档版本和用途。"""

    core = doc.core_properties
    core.title = title
    core.subject = subject
    core.author = "项目组"
    core.keywords = keywords


def build_design_contract():
    """生成V2.1设计文档。

    章节按“版本边界→供应商事实→歧义/未知→集成结构→地址/对齐→完成/恢复”
    排列。重点是阻止未知接口进入RTL，而不是把供应商答疑扩写成假端口说明。
    """

    # 首屏直接声明V2.0数据面保持、2020.2/2024.2隔离和不虚构接口三条红线。
    doc = configure_doc("ADC · DDR · NVMe V2.1供应商契约")
    add_masthead(
        doc,
        "内部设计说明",
        "NVMe–DDR–ADC FPGA\n基础通路设计方案",
        "供应商补充答疑收敛｜V2.0 RTL基线保持｜真实集成条件分级",
        "V2.1｜供应商补充答疑收敛版｜2026-07-28",
        [
            (
                "自研基线",
                "Vivado 2020.2；ADC打包、263 bit CDC、256 bit Writer和Segment结构保持不变",
            ),
            (
                "供应商工程",
                "当前使用Vivado 2024.2；正式交付后在独立工作区集成",
            ),
            (
                "本版边界",
                "不虚构NVMe M_AXI、正式API、地址换算和自动恢复流程",
            ),
        ],
    )
    add_callout(
        doc,
        "V2.1结论",
        "供应商补充回复没有推翻V2.0的数据面。当前应保留自研256 bit Writer，"
        "通过SmartConnect与供应商当前512 bit MIG配置衔接。截图只证明MIG配置，"
        "不能当作NVMe IP M_AXI参数。地址、聚合Completion和“重新下载程序”的"
        "实际含义仍须现场确认。",
    )
    doc.add_page_break()

    # 版本关系：先列出哪些RTL明确不改，避免读者把V2.1误解为数据面重构。
    doc.add_heading("1. 本版范围和版本关系", level=1)
    doc.add_paragraph(
        "V2.0是已经完成行为回归的自研RTL基线，继续保留原文件。V2.1只收敛"
        "供应商接口契约、真实集成结构、异常边界和现场验证要求。本版不修改"
        "ADC数据格式、CDC、DDR Writer、Segment状态机和项目级单请求结构。"
    )
    add_table(
        doc,
        ["项目", "V2.0基线", "V2.1处理"],
        [
            ("ADC单/双通道", "已实现并回归", "保持不变"),
            ("ADC域256 bit打包", "已实现并回归", "保持不变"),
            ("263 bit CDC", "已实现并回归", "保持不变"),
            ("256 bit DDR Writer", "已实现并回归", "保持不变"),
            ("Segment/Tag", "已实现并回归", "保持不变"),
            ("供应商接口", "抽象req/cpl", "补充三态契约，不猜测真实API"),
            ("工具版本", "Vivado 2020.2", "供应商2024.2独立集成"),
            ("验证", "三组行为回归", "新增AXI Burst 4 KiB边界断言"),
        ],
        [1.55, 2.35, 2.6],
    )
    add_callout(
        doc,
        "状态用语",
        "CONFIRMED表示供应商已明确；AMBIGUOUS表示有回复但口径仍冲突；"
        "UNKNOWN表示当前资料没有给出。AMBIGUOUS和UNKNOWN都不能写成RTL固定事实。",
        fill="FFF4E5",
    )

    # 供应商状态矩阵：CONFIRMED只收录书面回复/截图；MIG截图不得外推为NVMe M_AXI。
    doc.add_heading("2. 供应商补充回复：CONFIRMED", level=1)
    add_table(
        doc,
        ["对象", "已确认事实", "设计动作"],
        [
            (
                "MIG截图",
                "512 bit数据、32 bit地址、ID=1、RD_PRI_REG、833 ps",
                "只标记为MIG配置",
            ),
            (
                "共享DDR",
                "支持NVMe通路与ADC Writer共同访问MIG",
                "保留SmartConnect",
            ),
            (
                "上层请求",
                "一次只能提交一个大DMA任务",
                "保持单请求在途",
            ),
            (
                "内部并发",
                "16个Queue，Depth最大1024，按MDTS拆SQE",
                "不实现应用层多Outstanding",
            ),
            (
                "最小单位",
                "供应商答复为512 B",
                "项目仍按4 KiB对齐",
            ),
            (
                "异常",
                "当前建议为重新下载程序",
                "fatal后冻结并人工恢复",
            ),
            (
                "工程版本",
                "供应商当前使用Vivado 2024.2",
                "独立目录集成",
            ),
        ],
        [1.2, 3.2, 2.1],
    )

    # 歧义和未知分别列出所需证据，后续拿到API或现场日志后可以逐项关闭。
    doc.add_heading("3. 仍有歧义和未知的事项", level=1)
    doc.add_heading("3.1 AMBIGUOUS", level=2)
    add_table(
        doc,
        ["事项", "歧义", "需要的现场证据"],
        [
            (
                "NVMe M_AXI",
                "MIG截图不能证明NVMe端口也是512/32/ID1",
                "正式端口表或BD连接",
            ),
            (
                "DDR地址",
                "Absolute还是相对DDR Offset未说明",
                "API入参到MIG地址换算示例",
            ),
            (
                "2 TB口径",
                "与32 bit本地DDR地址不属于同一层",
                "明确SSD/LBA/PCIe/DDR哪一层",
            ),
            (
                "4 KiB示例",
                "0x400 + 4 KiB会跨0x1000",
                "展示内部Burst拆分或更正示例",
            ),
            (
                "聚合完成",
                "未说明是否等待全部内部SQE",
                "大任务Completion时序说明",
            ),
            (
                "重新下载",
                "bitstream还是MicroBlaze ELF未说明",
                "现场完整恢复演示",
            ),
            (
                "Flush",
                "接口、排序和持久化完成语义未给出",
                "Write→Flush调用及状态日志",
            ),
        ],
        [1.25, 2.9, 2.35],
    )

    doc.add_heading("3.2 UNKNOWN", level=2)
    add_table(
        doc,
        ["未知项", "当前缺失", "当前工程处理"],
        [
            (
                "NVMe DDR M_AXI",
                "位宽、时钟、复位、Outstanding、ID、Burst",
                "只定义SmartConnect接入要求",
            ),
            (
                "Read/Write/Flush API",
                "函数/寄存器、字段、参数单位",
                "不编写猜测性Adapter",
            ),
            (
                "请求/完成",
                "Ready/Busy、聚合Completion、Tag、状态码",
                "保留通用req/cpl和Mailbox上下文",
            ),
            (
                "ECQE",
                "字段、深度、清除、溢出、中断",
                "只保留抽象错误入口",
            ),
            (
                "DDR保留区",
                "SQ/CQ/PRP/Context是否占用外部DDR",
                "不分配最终地址图",
            ),
            (
                "现场文件权限",
                "工程、bitstream、ELF、脚本和日志能否留存",
                "现场前书面确认",
            ),
        ],
        [1.5, 2.75, 2.25],
    )

    # 板级结构：自研Writer仍为256 bit，位宽差异留给SmartConnect/Wrapper。
    doc.add_heading("4. V2.1正式集成结构", level=1)
    add_code(
        doc,
        "ADC Writer 256-bit M_AXI\n"
        "           │\n"
        "           ▼\n"
        "SmartConnect：仲裁 + 必要的256→512 bit宽度转换\n"
        "           │\n"
        "           ▼\n"
        "供应商当前MIG 512-bit S_AXI → DDR\n"
        "           ▲\n"
        "           │\n"
        "供应商NVMe DDR M_AXI（实际位宽、时钟和复位仍未知）",
    )
    add_bullet(doc, "不把ADC域打包器和DDR Writer直接改为512 bit。")
    add_bullet(
        doc,
        "256 bit×125 MHz理论载荷为4 GB/s，高于双通道1 GB/s输入，宽度不是当前瓶颈。",
    )
    add_bullet(
        doc,
        "SmartConnect需要处理仲裁；只有在实际端口不匹配时才启用宽度/时钟转换。",
    )
    add_bullet(
        doc,
        "MIG的RD_PRI_REG可能增加ADC写等待，必须用ILA测最长AW/W Stall和FIFO最大水位。",
    )
    add_callout(
        doc,
        "不能提前生成的对象",
        "当前没有真实DDR颗粒、MIG/XDC和供应商IP工程，不生成假MIG，不创建假"
        "Block Design，也不把供应商截图参数硬编码进自研顶层。",
        fill="FFF4E5",
    )

    # 地址契约：保留项目64 bit地址，但不在缺少API时猜Absolute/Offset换算。
    doc.add_heading("5. DDR地址契约", level=1)
    doc.add_paragraph(
        "项目内部继续使用64 bit DDR地址。未来供应商适配层只负责控制面的地址检查"
        "和换算，不复制ADC Payload。正式API未提供前只定义以下输入输出要求。"
    )
    add_code(
        doc,
        "项目请求：project_ddr_addr[63:0]\n"
        "          ↓ 范围/对齐检查\n"
        "          ↓ Absolute或Offset换算（规则待确认）\n"
        "供应商API：vendor_ddr_address_or_offset\n"
        "          ↓ 供应商内部地址参数\n"
        "最终MIG AXI地址",
    )
    add_table(
        doc,
        ["检查", "要求"],
        [
            ("范围", "地址和长度必须落在分配给Payload/Readback的DDR窗口内"),
            ("溢出", "64 bit到供应商地址位宽收窄前必须检查高位"),
            ("保留区", "不得与供应商SQ/CQ/PRP/Context区重叠"),
            ("所有权", "请求完成前Segment不得被ADC覆盖"),
            ("实现门槛", "必须先拿到正式API和一组地址换算示例"),
        ],
        [1.25, 5.25],
    )

    # 对齐拆层：项目Buffer策略、供应商最小单位和AXI Burst规则不能混为一谈。
    doc.add_heading("6. 三层对齐和4 KiB边界", level=1)
    add_table(
        doc,
        ["层次", "规则", "当前动作"],
        [
            (
                "项目策略",
                "Buffer起始地址和NVMe DMA长度按4 KiB对齐",
                "保持不变",
            ),
            (
                "供应商最小单位",
                "答复为512 B",
                "只记录，不放宽RTL",
            ),
            (
                "AXI4 Burst",
                "单个Burst不能跨4 KiB边界",
                "系统TB新增断言",
            ),
        ],
        [1.35, 3.45, 1.7],
    )
    add_code(
        doc,
        "当前Burst = 256 bit/beat × 16 beat = 512 Byte\n"
        "检查条件  = AWADDR[11:0] + ((AWLEN+1) << AWSIZE) <= 4096",
    )
    doc.add_paragraph(
        "4 KiB对齐Segment内包含8个512 B Burst，各Burst起点依次为0x000、0x200、"
        "0x400、0x600、0x800、0xA00、0xC00和0xE00，最后一个正好结束于下一"
        "4 KiB边界。供应商的0x400 + 4 KiB示例只有在内部拆分为多个Burst时才合法。"
    )

    # 请求/完成：项目保持单大任务，内部MDTS/SQE/Queue由供应商IP管理。
    doc.add_heading("7. 请求、内部并发和Completion", level=1)
    add_code(
        doc,
        "项目层：一次提交一个大DMA请求\n"
        "  request = opcode + ddr_addr + byte_len + slba + user_tag\n"
        "             ↓\n"
        "供应商IP：按MDTS拆分SQE，使用内部Queue/CID/PRP\n"
        "             ↓\n"
        "项目层：接收一条整笔任务Completion（完成语义待确认）",
    )
    add_bullet(doc, "项目Tag继续使用{generation, segment_id}，它不是内部NVMe CID。")
    add_bullet(doc, "不假定供应商API原样返回user_tag；Mailbox保存本地关联。")
    add_bullet(doc, "不实现应用层多Outstanding，也不自行拆MDTS、SQE或PRP。")
    add_bullet(doc, "只有全部内部SQE完成后的聚合Completion才能释放Segment。")

    # 错误语义：Timeout不证明SSD已停止读DDR，所以只能冻结，不能直接释放或重试。
    doc.add_heading("8. Fatal冻结与人工恢复", level=1)
    add_table(
        doc,
        ["触发", "V2.1动作"],
        [
            ("Command Timeout", "fatal；保持INFLIGHT数据"),
            ("Completion/Tag错误", "fatal；禁止误释放Segment"),
            ("PCIe Link Down", "fatal；停止新请求和新Capture"),
            ("ECQE", "fatal；保存错误状态"),
            ("Flush失败", "fatal；Capture不得标记完成"),
        ],
        [2.0, 4.5],
    )
    add_number(doc, "停止接受新的Capture。")
    add_number(doc, "停止提交新的NVMe请求。")
    add_number(doc, "保持INFLIGHT和ERROR_HOLD Segment，不覆盖原数据。")
    add_number(doc, "不自动重试，不根据Timeout猜测SSD已经停止访问DDR。")
    add_number(doc, "等待人工执行供应商定义的重新下载或系统级恢复。")
    add_callout(
        doc,
        "删除的旧假设",
        "V2.1不再写“MicroBlaze一定可以自动重新初始化恢复”。只有供应商现场"
        "演示并给出可执行流程后，才能把恢复路径写入产品状态机。",
        fill="FFF4E5",
    )

    # 工具隔离：2020.2是当前可执行基线；2024.2只能在正式交付后的独立目录验证。
    doc.add_heading("9. Vivado版本隔离", level=1)
    add_table(
        doc,
        ["工作区", "工具", "规则"],
        [
            ("自研RTL基线", "Vivado 2020.2", "继续运行三组行为回归，不覆盖历史工程"),
            ("供应商集成", "Vivado 2024.2", "到货后新建独立目录，按供应商工程版本接入"),
            ("共同RTL", "未来双版本检查", "先编译/仿真，再处理IP与BD版本差异"),
        ],
        [1.55, 1.45, 3.5],
    )
    doc.add_paragraph(
        "本机当前没有Vivado 2024.2，本轮不创建或运行2024.2脚本。不能用2024.2"
        "直接打开并保存唯一的2020.2工程，也不能把供应商2024.2工程强行降级。"
    )

    # 交付范围：明确区分“修改了验证代码”和“没有改正常数据面RTL”。
    doc.add_heading("10. 本轮实现和验证", level=1)
    add_table(
        doc,
        ["对象", "本轮动作"],
        [
            ("正常数据面RTL", "不修改"),
            ("系统testbench", "新增AXI AW Burst不跨4 KiB边界断言"),
            ("vendor_ip_contract.md", "改为CONFIRMED/AMBIGUOUS/UNKNOWN三态矩阵"),
            ("README", "改为V2.0 RTL基线 + V2.1集成契约"),
            ("现场清单", "新增文件权限、地址、Completion、Pattern、长稳和恢复记录"),
            ("自动回归", "继续使用Vivado 2020.2三组行为回归"),
            ("Word文档", "新建V2.1/V1.1，不覆盖旧版本，不做PDF/PNG渲染"),
        ],
        [2.0, 4.5],
    )

    doc.add_heading("11. 进入真实集成的门槛", level=1)
    add_number(doc, "项目组提供真实DDR颗粒、原理图引脚、时钟和XDC。")
    add_number(doc, "供应商交付可复现的Vivado 2024.2工程和正式端口/API说明。")
    add_number(doc, "确认DDR地址Absolute/Offset换算和供应商DDR保留区。")
    add_number(doc, "确认大任务Completion等待全部内部SQE。")
    add_number(doc, "确认Flush完成和异常恢复语义。")
    add_number(doc, "先完成MIG Example Design和DDR写后读回CRC。")
    add_number(doc, "再完成我方Pattern DDR→SSD→DDR闭环，最后接真实ADC PHY。")

    doc.add_heading("12. 当前准确结论", level=1)
    add_callout(
        doc,
        "可以确认",
        "自研ADC格式化、CDC、DDR写入骨架、Segment所有权和抽象NVMe控制顺序已"
        "具备真实集成基础。供应商补充回复使SmartConnect共享DDR、项目级单请求和"
        "内部多SQE方向进一步明确。",
    )
    add_callout(
        doc,
        "仍不能确认",
        "真实MIG、供应商NVMe M_AXI、地址映射、聚合Completion、Flush持久化、"
        "异常恢复和完整SSD写入尚未接入或验证，因此不能写“完整通路已打通”。",
        fill="FFF4E5",
    )

    set_core_properties(
        doc,
        "NVMe_ADC_DDR_FPGA基础通路设计方案 V2.1",
        "供应商补充答疑、MIG接口收敛、地址/完成/恢复边界",
        "ADC, DDR, NVMe, FPGA, MIG, SmartConnect, Vivado 2020.2, Vivado 2024.2",
    )
    DOCS.mkdir(parents=True, exist_ok=True)
    doc.save(DESIGN_OUT)


def build_onsite_verification_guide():
    """生成V1.1现场验证文档。

    章节按现场实际执行顺序排列：环境/文件权限→接口澄清→基线→参数化I/O→
    Pattern闭环→Flush→长稳→恢复。每一步都要求可保存证据，避免只记录口头结论。
    """

    # 首屏先限定黑盒测试等级，避免“供应商Demo通过”被写成“我方工程集成通过”。
    doc = configure_doc("ADC · DDR · NVMe V1.1现场验证")
    add_masthead(
        doc,
        "内部测试说明",
        "ADC–DDR–NVMe\n验证用例与测试过程",
        "供应商现场黑盒验证补充｜证据留存｜交付后集成分级",
        "V1.1｜供应商现场验证补充版｜2026-07-28",
        [
            (
                "现场限制",
                "暂不交付源码、网表/DCP或可修改的完整工程",
            ),
            (
                "本次目标",
                "验证黑盒功能、外部DDR数据一致性、性能、Flush和恢复",
            ),
            (
                "不包含",
                "我方MIG/SmartConnect/ADC Writer与供应商IP的真实工程集成",
            ),
        ],
    )
    add_callout(
        doc,
        "测试底线",
        "时间有限时优先完成四项：可修改DDR地址/长度/SLBA；我方Pattern写后"
        "读回一致；连续写至少10分钟并记录最低1秒带宽；Write→Flush→Readback"
        "及一次完整恢复演示。",
    )
    doc.add_page_break()

    # A/B/C/D四级结论与可获得的工程控制权一一对应。
    doc.add_heading("1. 验证等级和结论口径", level=1)
    add_table(
        doc,
        ["等级", "条件", "允许结论"],
        [
            ("A：固定Demo", "只能运行供应商原程序", "供应商基线复现"),
            ("B：参数化黑盒", "可改地址、长度、SLBA、Opcode和Flush", "黑盒功能/性能验证"),
            ("C：我方Pattern", "DDR A写SSD后读回DDR B一致", "外部DDR数据接口预演"),
            ("D：交付后集成", "取得工程并接我方MIG/ADC", "我方工程集成验证"),
        ],
        [1.2, 2.9, 2.4],
    )
    doc.add_paragraph(
        "没有源码或可复现工程不等于完全不能测试，但通常只能在供应商电脑、板卡和"
        "Demo环境中进行黑盒验证。能否在我方电脑运行、能否拷贝文件和能否修改程序"
        "必须在测试前逐项确认。"
    )

    # 先冻结环境版本，后续性能和兼容性结果才可复现。
    doc.add_heading("2. 测试前登记", level=1)
    add_table(
        doc,
        ["类别", "必须记录"],
        [
            ("环境", "日期、地点、人员、测试电脑归属、板卡归属"),
            ("FPGA/工程", "器件、板卡版本、Vivado/Vitis版本、IP/工程/bitstream/ELF版本"),
            ("SSD", "型号、容量、固件、Namespace、LBA Size、MDTS"),
            ("PCIe", "实际Gen、Lane、Link状态、Refclk和PERST#"),
            ("DDR", "颗粒/容量、MIG宽度/时钟、校准状态、测试地址窗口"),
            ("缓存/命令", "SSD Cache、I/O大小、Queue、Depth、Flush设置"),
        ],
        [1.3, 5.2],
    )

    # 没有源码不等于没有证据；逐项确认哪些文件、日志和截图允许留存。
    doc.add_heading("3. 文件和证据权限", level=1)
    add_table(
        doc,
        ["对象", "现场要确认"],
        [
            ("Vivado工程", "可查看、可修改、可保存或只能现场运行"),
            ("MicroBlaze源码/BSP", "是否可查看、修改、带走"),
            ("bitstream/ELF", "是否允许复制；若不允许，记录版本和Hash"),
            ("测试脚本", "是否可保存现场修改版本"),
            ("日志/结果", "串口、性能表、寄存器、ILA截图是否可保存"),
            ("接口资料", "寄存器/API/状态码说明是否可获取"),
        ],
        [1.55, 4.95],
    )
    add_callout(
        doc,
        "无法拷贝时",
        "要求供应商允许留存签字记录、参数截图、结果截图、版本号和日志摘要。"
        "只有口头说明、没有可追溯证据的项目应标记为未确认。",
        fill="FFF4E5",
    )

    # 四个阻塞项对应真实Adapter、Segment释放、4KiB Burst和系统恢复设计。
    doc.add_heading("4. 现场必须澄清的四类接口", level=1)
    doc.add_heading("4.1 DDR地址Absolute或Offset", level=2)
    add_number(doc, "记录API输入地址或Offset。")
    add_number(doc, "记录供应商DDR_BASE/OFFSET参数。")
    add_number(doc, "记录最终MIG AXI地址。")
    add_number(doc, "解释当前32 bit MIG地址宽度与此前2 TB口径。")

    doc.add_heading("4.2 4 KiB边界", level=2)
    add_number(doc, "解释`0x400 + 4 KiB`如何满足单个AXI Burst不跨4 KiB。")
    add_number(doc, "若IP内部拆分，记录各子Burst地址和长度。")
    add_number(doc, "确认高层大DMA任务允许跨多个4 KiB页面。")

    doc.add_heading("4.3 大任务Completion", level=2)
    add_number(doc, "确认全部内部SQE完成后才返回整笔大任务Completion。")
    add_number(doc, "确认任一内部SQE失败时整笔任务如何失败。")
    add_number(doc, "确认Flush与此前拆分SQE的排序。")

    doc.add_heading("4.4 重新下载程序", level=2)
    add_number(doc, "明确重新配置bitstream、下载MicroBlaze ELF或两者都需要。")
    add_number(doc, "明确是否还需SSD PERST#或断电。")
    add_number(doc, "明确旧Context和INFLIGHT Buffer何时安全释放。")

    # 基线先复现供应商原结果，随后所有参数化测试以同一环境作比较。
    doc.add_heading("5. 测试1：供应商基线", level=1)
    add_number(doc, "确认PCIe Link Up、Gen和Lane宽度。")
    add_number(doc, "完成SSD枚举、Identify和I/O Queue创建。")
    add_number(doc, "复现供应商顺序Write/Read性能。")
    add_number(doc, "确认数据源确实位于外部DDR，不是BRAM或IP内部Pattern。")
    add_number(doc, "记录Cache、Flush、I/O大小、Queue和Depth。")

    # 长度覆盖项目4KiB策略、报告中的MDTS粒度、候选Segment和大任务拆分。
    doc.add_heading("6. 测试2：参数化Read/Write", level=1)
    add_table(
        doc,
        ["长度", "目的", "检查"],
        [
            ("4 KiB", "项目最小对齐任务", "地址/长度/SLBA可修改，写后读回"),
            ("512 KiB", "接近当前报告MDTS拆分粒度", "跨页、Completion、数据一致"),
            ("4 MiB", "产品候选Segment", "大任务自动拆分、性能和完成"),
            ("1 GiB", "条件允许的大任务", "内部多SQE、长任务完成和地址范围"),
        ],
        [1.0, 2.4, 3.1],
    )
    doc.add_paragraph(
        "每个长度至少使用两个不同DDR地址和两个不重叠SLBA。Read目标区域先清零"
        "或填反码，避免误把旧内存内容当作读回成功。"
    )

    # 数据闭环必须比较真实Payload；只看到Completion成功不能证明数据正确。
    doc.add_heading("7. 测试3：我方Pattern闭环", level=1)
    add_code(
        doc,
        "DDR A写入递增Pattern或PRBS并计算CRC\n"
        "→ NVMe Write到指定SLBA\n"
        "→ DDR B清空\n"
        "→ NVMe Read同一SLBA到DDR B\n"
        "→ A/B逐字节比较或分别计算CRC",
    )
    add_bullet(doc, "递增Pattern和PRBS至少各执行一次。")
    add_bullet(doc, "必须覆盖跨多个4 KiB页面的数据。")
    add_bullet(doc, "必须比较真实Payload，不能只检查API返回成功。")
    add_bullet(doc, "记录源/目标DDR地址、SLBA、长度、状态、CRC和耗时。")

    # Flush用例验证项目的Payload/Commit双Flush顺序及其持久化边界。
    doc.add_heading("8. 测试4：Write、Flush和Readback", level=1)
    add_number(doc, "提交Write并等待整笔任务Completion。")
    add_number(doc, "提交Flush并等待Completion。")
    add_number(doc, "Read同一SLBA到另一DDR区域。")
    add_number(doc, "逐字节或CRC比较。")
    add_number(doc, "记录Flush完成状态、平均/本次最大延迟及供应商持久化说明。")
    add_callout(
        doc,
        "当前Capture顺序",
        "项目使用Payload Write完成→Flush→Commit Write完成→Flush。现场需要确认"
        "供应商接口支持这个顺序，且Flush等待此前大任务的全部内部SQE。",
    )

    # 长稳记录最低带宽和最长停顿，二者决定DDR Segment容量而非平均带宽。
    doc.add_heading("9. 测试5：连续写性能", level=1)
    add_table(
        doc,
        ["指标", "要求"],
        [
            ("时长", "至少10分钟；条件允许时1小时"),
            ("容量", "写入量应超过SSD SLC Cache"),
            ("平均带宽", "双通道采购建议不低于1.2 GB/s"),
            ("最低带宽", "记录最低1秒窗口，不能只报平均值"),
            ("最长停顿", "记录最长无Completion或无DMA进展时间"),
            ("Flush", "记录延迟及其对连续写的影响"),
            ("温度", "记录起始、最高、结束温度和热降速"),
            ("错误", "记录CQE/ECQE、Timeout和Link异常"),
        ],
        [1.35, 5.15],
    )
    doc.add_paragraph(
        "平均3.3 GiB/s不能单独证明1 GB/s ADC长期无丢样。DDR Segment容量取决于"
        "最低带宽和最长停顿，因此这两项是现场必测数据。"
    )

    # 恢复演示要证明下载对象、重初始化和恢复后读写，而不是只观察Link重新Up。
    doc.add_heading("10. 测试6：恢复演示", level=1)
    add_number(doc, "记录异常前的请求、DDR地址、SLBA和Buffer状态。")
    add_number(doc, "按供应商方法执行一次“重新下载程序”。")
    add_number(doc, "记录下载对象、所有人工步骤和恢复耗时。")
    add_number(doc, "重新完成PCIe/NVMe初始化。")
    add_number(doc, "执行4 KiB Write→Flush→Readback并比较。")
    add_number(doc, "说明异常前INFLIGHT Buffer的最终处理规则。")

    # 现场黑盒与自研XSim互补；这里记录V2.1唯一验证代码变化及固定Vivado路径。
    doc.add_heading("11. 当前自动回归的补充检查", level=1)
    doc.add_paragraph(
        "现场黑盒测试不能替代当前V2 RTL回归。本轮不改正常数据面，只在"
        "`tb_nvme_adc_pipeline`增加以下AXI4边界断言："
    )
    add_code(
        doc,
        "AWADDR[11:0] + ((AWLEN + 1) << AWSIZE) <= 4096",
    )
    add_table(
        doc,
        ["测试平台", "继续验证"],
        [
            ("tb_adc_channel_packer", "三模式、边界长度、字节序和配置锁存"),
            ("tb_nvme_adc_pipeline", "CDC、随机AXI背压、DDR内容、Segment、Flush/Commit及4 KiB Burst"),
            ("tb_nvme_scheduler_errors", "Completion/Tag/Timeout/Link/Flush/ECQE错误"),
        ],
        [1.8, 4.7],
    )
    doc.add_paragraph(
        "三组测试继续由`D:\\Xilinx_2020_2\\Vivado\\2020.2\\bin\\vivado.bat`"
        "运行。供应商2024.2工程未交付且本机未安装2024.2，本轮不创建2024.2脚本。"
    )

    doc.add_heading("12. 交付后真实集成验证", level=1)
    add_number(doc, "在供应商2024.2独立工作区重建并复现原Demo。")
    add_number(doc, "接入真实MIG并确认init_calib_complete。")
    add_number(doc, "使用SmartConnect连接256 bit ADC Writer和NVMe DDR Master。")
    add_number(doc, "内部500 MB/s/1 GB/s Pattern写DDR并读回CRC。")
    add_number(doc, "已知DDR数据经NVMe Write到SSD并Read回另一DDR区域。")
    add_number(doc, "并发压力下记录FIFO最大水位和ADC Writer最长Stall。")
    add_number(doc, "最后接真实ADC PHY并完成全链路CRC。")

    doc.add_heading("13. 现场报告模板", level=1)
    add_table(
        doc,
        ["字段", "填写内容"],
        [
            ("达到等级", "A / B / C；未取得工程前不能写D"),
            ("最大任务", "4 KiB / 512 KiB / 4 MiB / 1 GiB"),
            ("Pattern闭环", "递增/PRBS，全量或CRC结果"),
            ("性能", "时长、平均、最低1秒、最长停顿"),
            ("Flush", "调用顺序、完成状态和延迟"),
            ("温度/错误", "起始/最高/结束温度，CQE/ECQE/Link"),
            ("恢复", "下载对象、步骤、耗时和恢复后读写"),
            ("文件证据", "可带走的工程、bitstream、ELF、脚本、日志和截图"),
            ("未决问题", "地址、Completion、4 KiB拆分和接口字段"),
        ],
        [1.45, 5.05],
    )
    add_callout(
        doc,
        "报告禁用语",
        "在取得供应商可复现工程并接入我方MIG/SmartConnect/ADC之前，禁止写"
        "“完整ADC数据已保存到NVMe SSD”或“我方工程已集成通过”。",
        fill="FFF4E5",
    )

    set_core_properties(
        doc,
        "ADC_DDR_NVMe验证用例与测试过程 V1.1",
        "供应商现场黑盒测试、证据留存、性能、Flush和恢复",
        "verification, ADC, DDR, NVMe, supplier onsite test, Vivado",
    )
    DOCS.mkdir(parents=True, exist_ok=True)
    doc.save(TEST_OUT)


def main():
    # 两份文档使用独立输出名；执行顺序固定，任一保存失败都会使脚本返回非零。
    build_design_contract()
    build_onsite_verification_guide()
    print(DESIGN_OUT)
    print(TEST_OUT)


if __name__ == "__main__":
    main()
```
