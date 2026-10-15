# build_design_doc

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\build_design_doc.py`
- SHA-256: `8a093d64d2c8cd80f77cdbc1a37589c30bbff914e7eb431f7c59daf92ee1800f`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_design_doc.py

```python
from pathlib import Path
from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "NVMe_ADC_DDR_FPGA基础通路设计方案_V1.0_接口与时序补充版.docx"

BLUE = "1F4E79"
DARK = "243447"
LIGHT_BLUE = "E8EEF5"
LIGHT_GRAY = "F3F5F7"
MID_GRAY = "667085"
WHITE = "FFFFFF"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=80, start=120, bottom=80, end=120):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for margin, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{margin}"))
        if node is None:
            node = OxmlElement(f"w:{margin}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def prevent_row_split(row):
    tr_pr = row._tr.get_or_add_trPr()
    cant_split = OxmlElement("w:cantSplit")
    tr_pr.append(cant_split)


def set_table_fixed(table):
    table.autofit = False
    tbl_pr = table._tbl.tblPr
    layout = tbl_pr.find(qn("w:tblLayout"))
    if layout is None:
        layout = OxmlElement("w:tblLayout")
        tbl_pr.append(layout)
    layout.set(qn("w:type"), "fixed")
    table.alignment = WD_TABLE_ALIGNMENT.CENTER


def set_column_widths(table, widths):
    for row in table.rows:
        for index, width in enumerate(widths):
            row.cells[index].width = Inches(width)


def set_east_asia(run, font_name):
    run.font.name = font_name
    run._element.rPr.rFonts.set(qn("w:eastAsia"), font_name)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("第 ")
    set_east_asia(run, "Calibri")
    begin = OxmlElement("w:fldChar")
    begin.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = " PAGE "
    separate = OxmlElement("w:fldChar")
    separate.set(qn("w:fldCharType"), "separate")
    text = OxmlElement("w:t")
    text.text = "1"
    end = OxmlElement("w:fldChar")
    end.set(qn("w:fldCharType"), "end")
    run._r.extend([begin, instr, separate, text, end])
    tail = paragraph.add_run(" 页")
    set_east_asia(tail, "Calibri")


def add_table(doc, headers, rows, widths):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    set_table_fixed(table)
    header = table.rows[0]
    set_repeat_table_header(header)
    prevent_row_split(header)
    for i, value in enumerate(headers):
        cell = header.cells[i]
        set_cell_shading(cell, LIGHT_BLUE)
        set_cell_margins(cell)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        p = cell.paragraphs[0]
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(value)
        r.bold = True
        r.font.color.rgb = RGBColor.from_string(DARK)
        set_east_asia(r, "Calibri")
    for row_data in rows:
        row = table.add_row()
        prevent_row_split(row)
        for i, value in enumerate(row_data):
            cell = row.cells[i]
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            p = cell.paragraphs[0]
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(str(value))
            set_east_asia(r, "Calibri")
    set_column_widths(table, widths)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


def add_bullet(doc, text, level=0):
    p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
    p.add_run(text)
    return p


def add_number(doc, text):
    p = doc.add_paragraph(style="List Number")
    p.add_run(text)
    return p


def add_callout(doc, title, text, fill=LIGHT_BLUE):
    table = doc.add_table(rows=1, cols=1)
    set_table_fixed(table)
    set_column_widths(table, [6.5])
    cell = table.cell(0, 0)
    prevent_row_split(table.rows[0])
    set_cell_shading(cell, fill)
    set_cell_margins(cell, top=120, start=160, bottom=120, end=160)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run(title)
    r.bold = True
    r.font.color.rgb = RGBColor.from_string(BLUE)
    set_east_asia(r, "Calibri")
    p2 = cell.add_paragraph(text)
    p2.paragraph_format.space_after = Pt(0)
    return table


def add_code(doc, text):
    p = doc.add_paragraph(style="Code Block")
    p.add_run(text)
    return p


def add_signal_table(doc, rows):
    table = add_table(
        doc,
        ["信号", "方向", "宽度", "时钟域", "含义"],
        rows,
        [1.85, 0.42, 0.58, 0.75, 2.90],
    )
    for row_index, row in enumerate(table.rows):
        for col_index, cell in enumerate(row.cells):
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.paragraph_format.space_after = Pt(0)
                if col_index in (1, 2, 3):
                    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in paragraph.runs:
                    run.font.size = Pt(8.2 if row_index else 8.5)
                    if col_index == 0 and row_index:
                        run.font.name = "Courier New"
                        run._element.rPr.rFonts.set(qn("w:eastAsia"), "微软雅黑")
    return table


def add_timing_diagram(doc, title, rows, explanation):
    doc.add_heading(title, level=3)
    table = add_table(
        doc,
        ["信号/阶段", "时间从左向右 →"],
        rows,
        [1.35, 5.15],
    )
    for row_index, row in enumerate(table.rows):
        for cell in row.cells:
            set_cell_margins(cell, top=60, start=90, bottom=60, end=90)
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.paragraph_format.space_after = Pt(0)
                for run in paragraph.runs:
                    run.font.size = Pt(8.0 if row_index else 8.5)
                    if row_index:
                        run.font.name = "Courier New"
                        run._element.rPr.rFonts.set(qn("w:eastAsia"), "微软雅黑")
    for item in explanation:
        add_bullet(doc, item)
    return table


def configure_styles(doc):
    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal.font.size = Pt(11)
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "等线")
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    for name, size, before, after, color in (
        ("Title", 24, 0, 12, BLUE),
        ("Subtitle", 12, 0, 8, MID_GRAY),
        ("Heading 1", 16, 18, 10, BLUE),
        ("Heading 2", 13, 14, 7, BLUE),
        ("Heading 3", 12, 10, 5, DARK),
    ):
        style = styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "等线")
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True
        if name.startswith("Heading") or name == "Title":
            style.font.bold = True

    for list_name in ("List Bullet", "List Bullet 2", "List Number"):
        style = styles[list_name]
        style.font.name = "Calibri"
        style.font.size = Pt(10.5)
        style._element.rPr.rFonts.set(qn("w:eastAsia"), "等线")
        style.paragraph_format.space_after = Pt(3)

    if "Code Block" not in styles:
        code = styles.add_style("Code Block", WD_STYLE_TYPE.PARAGRAPH)
    else:
        code = styles["Code Block"]
    code.font.name = "Courier New"
    code.font.size = Pt(8.5)
    code._element.rPr.rFonts.set(qn("w:eastAsia"), "微软雅黑")
    code.paragraph_format.left_indent = Inches(0.18)
    code.paragraph_format.right_indent = Inches(0.18)
    code.paragraph_format.space_before = Pt(3)
    code.paragraph_format.space_after = Pt(6)
    code.paragraph_format.line_spacing = 1.0
    p_pr = code.element.get_or_add_pPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), LIGHT_GRAY)
    p_pr.append(shd)


def configure_sections(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1.0)
    section.bottom_margin = Inches(1.0)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    header = section.header
    p = header.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = p.add_run("NVMe · DDR · ADC  FPGA 基础通路")
    r.font.size = Pt(8.5)
    r.font.color.rgb = RGBColor.from_string(MID_GRAY)
    set_east_asia(r, "Calibri")
    add_page_number(section.footer.paragraphs[0])


def build():
    doc = Document()
    configure_styles(doc)
    configure_sections(doc)

    # Title page / memo masthead.
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(4)
    r = p.add_run("内部设计说明")
    r.bold = True
    r.font.size = Pt(10)
    r.font.color.rgb = RGBColor.from_string(BLUE)
    set_east_asia(r, "Calibri")

    title = doc.add_paragraph(style="Title")
    title.add_run("NVMe–DDR–ADC FPGA\n基础通路设计方案")
    subtitle = doc.add_paragraph(style="Subtitle")
    subtitle.add_run("面向 UltraScale KU040｜Vivado 2020.2｜原始 LBA 连续采集")

    add_table(
        doc,
        ["项目项", "内容"],
        [
            ("目标数据源", "1 片 ADC、2 通道、250 MSPS、12 bit，按 16 bit/通道存储"),
            ("持续输入带宽", "1,000,000,000 Byte/s，约 953.7 MiB/s"),
            ("数据落盘方式", "原始 LBA＋512 B 采集元数据＋分块序号＋CRC32C；无文件系统"),
            ("目标器件/工具", "Xilinx UltraScale KU040，Vivado 2020.2"),
            ("文档版本", "V1.0 接口与时序补充版｜2026-07-24"),
        ],
        [1.45, 5.05],
    )

    add_callout(
        doc,
        "结论",
        "该架构可以作为 NVMe–DDR 数据流打通的基础工程。ADC→DDR 写通路、分段管理、"
        "NVMe 命令调度和 AXI-Lite 占位适配已经形成可仿真的纯 RTL 骨架。最终接板前，"
        "必须用厂商正式的数据面接口、寄存器表和初始化时序替换仿真桩；这一步不能由"
        "“AXI 接口”四个字推断。",
    )

    doc.add_page_break()

    doc.add_heading("1. 范围、假设与交付边界", level=1)
    doc.add_paragraph(
        "本方案解决连续 ADC 数据从采样时钟域进入 DDR，再由 NVMe Host Controller "
        "经 PCIe 写入 SSD 的基础数据通路。设计不包含 FAT、EXT4、NTFS 等文件系统，"
        "也不要求 MicroBlaze 参与实时采集。电脑端通过后续导出工具按固定 LBA 和元数据"
        "恢复文件。"
    )
    add_table(
        doc,
        ["范围内", "范围外/待接口确认"],
        [
            ("两路 12 bit ADC 样本的 16 bit 存储格式", "KU040 板级 ADC 引脚约束与 IDELAY 校准"),
            ("ADC 到系统时钟域的 XPM 异步 FIFO", "厂商 NVMe IP 的内部协议实现"),
            ("256 bit AXI4 DDR Burst 写入", "SSD 文件系统与操作系统块设备驱动"),
            ("DDR 多分段状态管理", "PC 导出工具的正式实现"),
            ("原始 LBA、分块序号和 CRC32C", "厂商真实寄存器地址、DMA 端口方向"),
            ("Vivado 2020.2 行为仿真和 KU040 OOC 检查", "板级 SI、PCIe Equalization 和 SSD 热降速"),
        ],
        [3.25, 3.25],
    )

    doc.add_heading("2. 输入数据与带宽预算", level=1)
    add_code(doc, "2 通道 × 250,000,000 sample/s × 16 bit ÷ 8 = 1,000,000,000 Byte/s")
    doc.add_paragraph(
        "每个 ADC 采样周期形成一个 32 bit 样本对。DDR 数据面采用 256 bit，即每个 AXI "
        "beat 容纳 8 个样本对。100 MHz 时理论单向带宽为 3.2 GB/s，200 MHz 时为 "
        "6.4 GB/s。由于 DDR 同时承担约 1 GB/s 的采集写入和约 1 GB/s 的 NVMe 读出，"
        "验收时应要求 DDR 有效双向总吞吐不低于 3 GB/s，并观察最差仲裁延迟。"
    )
    add_table(
        doc,
        ["项目", "数值", "设计含义"],
        [
            ("单样本对", "4 Byte", "ch0 16 bit＋ch1 16 bit"),
            ("持续输入", "1.0 GB/s", "不能依赖平均速率掩盖短时停顿"),
            ("256 bit AXI beat", "32 Byte", "8 个样本对"),
            ("推荐起始分块", "1 MiB", "约 1.049 ms 采集数据"),
            ("8 × 1 MiB 环形缓存", "8 MiB", "只提供约 8.39 ms 缓冲"),
            ("LBA 大小假设", "512 Byte", "最终须读取 Identify Namespace 核对"),
        ],
        [1.55, 1.35, 3.60],
    )
    add_callout(
        doc,
        "缓存判断",
        "DDR 只能吸收瞬时抖动，不能弥补 SSD 长期写速率低于 1 GB/s。若 SSD 实际持续写入"
        "只有 800 MB/s，缓存仍会以约 200 MB/s 的速度被吃满。连续采集时间必须和 SSD "
        "稳态写速率、温度降速以及可用 DDR 容量一起确定。",
        fill="FFF4E5",
    )

    doc.add_heading("3. 参考工程与 ADC 数据格式", level=1)
    doc.add_paragraph(
        "ADC 逻辑格式参考远端 RTDS/BUFR_RPT201-1，而不是照搬其器件原语。参考工程的 "
        "AD_LVDS.sv 使用 ADC DCO 的双沿采样产生 adc_cha[11:0] 和 adc_chb[11:0]；"
        "DATA_TRS.v 只把 A 路符号扩展为 16 bit，B 路没有进入最终数据流。本工程保留两路。"
    )
    add_code(
        doc,
        "ch0_16 = {{4{adc_ch0[11]}}, adc_ch0};\n"
        "ch1_16 = {{4{adc_ch1[11]}}, adc_ch1};\n"
        "sample_pair[31:0] = {ch1_16, ch0_16};"
    )
    add_table(
        doc,
        ["参考项", "采用方式", "说明"],
        [
            ("AD_LVDS.sv", "采用双沿后两路 12 bit 的逻辑含义", "新顶层输入从解串后的 adc_ch0/adc_ch1 开始"),
            ("DATA_TRS.v", "采用 12→16 bit 符号扩展", "改为 A/B 两路都保留"),
            ("IBUFDS/BUFR/IDELAYE2/IDDR", "不直接复制", "属于 7 系列原语，不适合 UltraScale"),
            ("KU040 ADC PHY", "板级适配器另建", "用 UltraScale 对应原语并按实际引脚、时钟校准"),
        ],
        [1.60, 2.25, 2.65],
    )

    doc.add_heading("4. 总体架构与数据流", level=1)
    add_code(
        doc,
        "ADC PHY → adc_pair_to_axis → XPM async FIFO → 32→256 bit packer\n"
        "        → AXI4 burst writer → DDR segment ring → NVMe DMA read\n"
        "        → PCIe Root Complex → NVMe SSD Endpoint\n\n"
        "segment descriptor → scheduler → vendor command adapter → NVMe Host IP"
    )
    add_number(doc, "ADC 物理层在 adc_clk 域输出两路 12 bit 样本和 adc_valid。")
    add_number(doc, "adc_pair_to_axis 对两路符号扩展，组成 32 bit AXI-Stream 数据。")
    add_number(doc, "XPM 异步 FIFO 完成 adc_clk 到 sys_clk 的跨时钟传输。")
    add_number(doc, "打包器把 8 个样本对组成一个 256 bit beat，并计算 CRC32C。")
    add_number(doc, "AXI4 Writer 以固定 INCR Burst 写入当前 DDR 分段。")
    add_number(doc, "分段完成且最后一个 B 响应返回后，生成地址、长度、序号和 CRC 描述符。")
    add_number(doc, "调度器分配 SLBA/NLB，并通过厂商适配层提交 NVMe 写命令。")
    add_number(doc, "NVMe IP 从 DDR 读取负载，经 PCIe RC 写入作为 EP 的 SSD。")
    add_number(doc, "收到 NVMe 完成状态后，对应 DDR 分段才重新标记为 FREE。")

    doc.add_heading("5. RTL 模块划分", level=1)
    add_table(
        doc,
        ["模块", "职责", "是否可直接保留"],
        [
            ("adc_pair_to_axis.sv", "两路符号扩展、32 bit 打包、丢样计数", "是"),
            ("axis_async_fifo.sv", "XPM BRAM 异步 FIFO，隔离 ADC/系统时钟", "是"),
            ("adc_ddr_segment_writer.sv", "256 bit 打包、CRC32C、AXI Burst、描述符", "是"),
            ("nvme_segment_scheduler.sv", "分段队列、FREE 掩码、LBA 分配、完成回收", "是"),
            ("nvme_axil_cmd_bridge.sv", "把内部命令映射到占位 AXI-Lite 寄存器", "需按厂商手册修改"),
            ("axi_ddr_mem_stub.sv", "行为级 DDR 写模型", "仅仿真"),
            ("nvme_axil_stub.sv", "行为级 NVMe 命令完成模型", "仅仿真"),
            ("nvme_adc_pipeline_top.sv", "连接数据面、控制面和状态输出", "接口调整后保留"),
        ],
        [2.05, 3.15, 1.30],
    )

    doc.add_heading("5.1 adc_pair_to_axis 顶层信号", level=2)
    doc.add_paragraph(
        "该模块位于 ADC 采样时钟域。它把两路 12 bit 二补码样本分别符号扩展到 "
        "16 bit，再按 {ch1_16, ch0_16} 组成一个 32 bit AXI-Stream 数据字。"
    )
    add_signal_table(doc, [
        ("adc_clk", "I", "1", "adc_clk", "ADC 数据处理时钟；所有输入样本在其上升沿采样。"),
        ("adc_rst_n", "I", "1", "adc_clk", "低有效异步复位，清除 valid、计数器和溢出标志。"),
        ("capture_enable", "I", "1", "adc_clk", "采集总使能；为 0 时忽略 adc_valid。"),
        ("adc_valid", "I", "1", "adc_clk", "本周期 adc_ch0/adc_ch1 有效。"),
        ("adc_ch0", "I", "12", "adc_clk", "ADC 第 0 路 12 bit 二补码样本。"),
        ("adc_ch1", "I", "12", "adc_clk", "ADC 第 1 路 12 bit 二补码样本。"),
        ("m_axis_tdata", "O", "32", "adc_clk", "打包后的样本对；[15:0] 为 ch0，[31:16] 为 ch1。"),
        ("m_axis_tvalid", "O", "1", "adc_clk", "输出数据有效；在 ready 拉低时保持数据和 valid。"),
        ("m_axis_tready", "I", "1", "adc_clk", "下游接收能力；valid&&ready 表示一次传输。"),
        ("overflow_sticky", "O", "1", "adc_clk", "发生过无法接收的新样本后置 1，复位前保持。"),
        ("accepted_sample_pairs", "O", "64", "adc_clk", "成功装入输出寄存器的样本对数量。"),
        ("dropped_sample_pairs", "O", "64", "adc_clk", "valid 被阻塞时到来的样本对数量。"),
    ])
    doc.add_paragraph(
        "SIGN_EXTEND 参数默认为 1。若 ADC 输出是无符号码，可以设为 0，此时高 4 bit 补零。"
        "由于真实 ADC 不能接受 ready 回压，overflow_sticky 或 dropped_sample_pairs 非零必须"
        "判定该次连续采集不完整。"
    )

    doc.add_heading("5.2 axis_async_fifo 顶层信号", level=2)
    doc.add_paragraph(
        "该模块封装 Vivado 2020.2 的 xpm_fifo_async，采用 BRAM 和 FWFT 模式。写端属于 "
        "adc_clk，读端属于 sys_clk；Gray 指针同步和复位忙时序由 XPM 内部完成。"
    )
    add_signal_table(doc, [
        ("s_clk", "I", "1", "写时钟", "AXI-Stream 写端时钟，工程中连接 adc_clk。"),
        ("s_rst_n", "I", "1", "写时钟", "写端低有效复位；与 m_rst_n 合成 XPM 总复位。"),
        ("s_axis_tdata", "I", "DATA_WIDTH", "写时钟", "待跨域的数据，当前为 32 bit 样本对。"),
        ("s_axis_tvalid", "I", "1", "写时钟", "写端数据有效。"),
        ("s_axis_tready", "O", "1", "写时钟", "FIFO 非满且 wr_rst_busy 结束后置 1。"),
        ("m_clk", "I", "1", "读时钟", "AXI-Stream 读端时钟，工程中连接 sys_clk。"),
        ("m_rst_n", "I", "1", "读时钟", "读端低有效复位。"),
        ("m_axis_tdata", "O", "DATA_WIDTH", "读时钟", "FWFT 输出数据；empty=0 后首字已在输出端。"),
        ("m_axis_tvalid", "O", "1", "读时钟", "FIFO 非空且 rd_rst_busy 结束后置 1。"),
        ("m_axis_tready", "I", "1", "读时钟", "下游接收能力；与 valid 同时为 1 时弹出一个字。"),
        ("full", "O", "1", "写时钟", "FIFO 已满，用于状态观察。"),
        ("empty", "O", "1", "读时钟", "FIFO 已空，用于状态观察。"),
    ])
    doc.add_paragraph(
        "ADDR_WIDTH 决定深度 2^ADDR_WIDTH。顶层默认 ADDR_WIDTH=10，即 1024 个 32 bit "
        "样本对。复位释放后不能立即开始采集，必须等 XPM 的 wr_rst_busy/rd_rst_busy 完成；"
        "本封装通过 ready/valid 自动屏蔽复位忙阶段。"
    )

    doc.add_heading("5.3 sync_fifo 顶层信号", level=2)
    doc.add_paragraph(
        "该模块封装 xpm_fifo_sync，作为 256 bit DDR beat 缓冲。它把较慢的 32→256 bit "
        "打包过程与 AXI Burst 发送状态机隔离。"
    )
    add_signal_table(doc, [
        ("clk", "I", "1", "sys_clk", "FIFO 读写公共时钟。"),
        ("rst_n", "I", "1", "sys_clk", "低有效复位。"),
        ("din", "I", "DATA_WIDTH", "sys_clk", "写入数据，当前为一个 256 bit AXI beat。"),
        ("wr_en", "I", "1", "sys_clk", "写请求；内部仅在 !full 时实际写入。"),
        ("rd_en", "I", "1", "sys_clk", "读请求；内部仅在 !empty 时实际弹出。"),
        ("dout", "O", "DATA_WIDTH", "sys_clk", "FWFT 当前队首数据。"),
        ("full", "O", "1", "sys_clk", "FIFO 满标志。"),
        ("empty", "O", "1", "sys_clk", "FIFO 空标志。"),
        ("used_count", "O", "ADDR_WIDTH+1", "sys_clk", "当前已用 beat 数，用来判断能否发起完整 Burst。"),
    ])

    doc.add_heading("5.4 adc_ddr_segment_writer 顶层信号", level=2)
    doc.add_paragraph(
        "该模块完成样本打包、CRC32C、DDR 地址生成和 AXI4 写事务。只有当前分段的全部 "
        "W beat 已发送且最后一个 B 响应返回后，才输出分段描述符。"
    )
    add_signal_table(doc, [
        ("clk", "I", "1", "sys_clk", "打包、CRC、AXI Writer 和描述符公共时钟。"),
        ("rst_n", "I", "1", "sys_clk", "低有效复位。"),
        ("s_axis_tdata", "I", "32", "sys_clk", "来自跨时钟 FIFO 的样本对。"),
        ("s_axis_tvalid", "I", "1", "sys_clk", "输入样本有效。"),
        ("s_axis_tready", "O", "1", "sys_clk", "当前有可写分段且 beat FIFO 可接收数据。"),
        ("segment_free", "I", "SEGMENT_COUNT", "sys_clk", "每 bit 对应一个可用 DDR 分段，1 表示 FREE。"),
        ("desc_valid", "O", "1", "sys_clk", "完整分段描述符有效。"),
        ("desc_ready", "I", "1", "sys_clk", "调度器可以接收描述符。"),
        ("desc_segment_id", "O", "clog2(N)", "sys_clk", "完成写入的 DDR 分段编号。"),
        ("desc_ddr_addr", "O", "AXI_ADDR_WIDTH", "sys_clk", "分段起始 DDR 地址。"),
        ("desc_byte_len", "O", "32", "sys_clk", "有效 payload 字节数，当前等于 SEGMENT_BYTES。"),
        ("desc_sequence", "O", "32", "sys_clk", "单调递增的分段序号。"),
        ("desc_crc32c", "O", "32", "sys_clk", "该分段 payload 的 CRC32C。"),
        ("m_axi_awaddr", "O", "AXI_ADDR_WIDTH", "sys_clk", "AXI4 写地址。"),
        ("m_axi_awlen", "O", "8", "sys_clk", "Burst beat 数减 1。"),
        ("m_axi_awsize", "O", "3", "sys_clk", "每 beat 字节数的 log2；256 bit 时为 5。"),
        ("m_axi_awburst", "O", "2", "sys_clk", "固定为 01，即 INCR Burst。"),
        ("m_axi_awvalid", "O", "1", "sys_clk", "写地址通道有效。"),
        ("m_axi_awready", "I", "1", "sys_clk", "DDR/SmartConnect 接受写地址。"),
        ("m_axi_wdata", "O", "AXI_DATA_WIDTH", "sys_clk", "AXI4 写数据。"),
        ("m_axi_wstrb", "O", "AXI_DATA_WIDTH/8", "sys_clk", "字节有效掩码，完整 beat 时全 1。"),
        ("m_axi_wlast", "O", "1", "sys_clk", "当前 Burst 最后一个 beat。"),
        ("m_axi_wvalid", "O", "1", "sys_clk", "写数据有效。"),
        ("m_axi_wready", "I", "1", "sys_clk", "DDR/SmartConnect 接受写数据。"),
        ("m_axi_bresp", "I", "2", "sys_clk", "写响应；00 为 OKAY，其余置错误标志。"),
        ("m_axi_bvalid", "I", "1", "sys_clk", "写响应有效。"),
        ("m_axi_bready", "O", "1", "sys_clk", "Writer 准备接收写响应。"),
        ("axi_error_sticky", "O", "1", "sys_clk", "检测到非 OKAY B 响应后保持为 1。"),
        ("accepted_sample_pairs", "O", "32", "sys_clk", "Writer 实际接收的样本对数量。"),
        ("active_segment_id", "O", "clog2(N)", "sys_clk", "当前 FILLING 分段编号，供调试。"),
    ])
    doc.add_paragraph(
        "地址计算为 DDR_BASE_ADDR + segment_id*SEGMENT_BYTES + burst_offset。"
        "SEGMENT_BYTES 必须同时对齐 AXI beat 和完整 Burst。当前状态机一次只发一个"
        " outstanding Burst，目的是先把接口打通；256 bit 总线每 8 个输入样本才产生一个 beat，"
        "在 1 GB/s 输入下仍有足够发送间隙。"
    )

    doc.add_heading("5.5 nvme_segment_scheduler 顶层信号", level=2)
    doc.add_paragraph(
        "调度器保存 READY 描述符，分配原始 LBA，并在 NVMe 成功完成后释放 DDR 分段。"
        "当前基线只允许一个 NVMe 命令在途，因此 Tag 可以直接使用 segment_id。"
    )
    add_signal_table(doc, [
        ("clk", "I", "1", "sys_clk", "调度器时钟。"),
        ("rst_n", "I", "1", "sys_clk", "低有效复位；复位后所有分段为 FREE。"),
        ("nvme_init_done", "I", "1", "sys_clk", "NVMe 控制器已初始化并可接收 I/O 命令。"),
        ("desc_valid", "I", "1", "sys_clk", "Writer 描述符有效。"),
        ("desc_ready", "O", "1", "sys_clk", "描述符队列未满且无 fatal_error。"),
        ("desc_segment_id", "I", "clog2(N)", "sys_clk", "READY 分段编号。"),
        ("desc_ddr_addr", "I", "AXI_ADDR_WIDTH", "sys_clk", "NVMe DMA 源地址。"),
        ("desc_byte_len", "I", "32", "sys_clk", "待写 SSD 的字节数。"),
        ("desc_sequence", "I", "32", "sys_clk", "分段序号。"),
        ("desc_crc32c", "I", "32", "sys_clk", "分段 CRC32C。"),
        ("segment_free", "O", "SEGMENT_COUNT", "sys_clk", "分段空闲位图，返回 Writer。"),
        ("cmd_valid", "O", "1", "sys_clk", "内部 NVMe 写命令有效。"),
        ("cmd_ready", "I", "1", "sys_clk", "厂商适配层接受命令。"),
        ("cmd_ddr_addr", "O", "AXI_ADDR_WIDTH", "sys_clk", "DMA 源 DDR 地址。"),
        ("cmd_slba", "O", "64", "sys_clk", "起始逻辑块地址。"),
        ("cmd_nlb", "O", "32", "sys_clk", "0-based LBA 数量，即 block_count-1。"),
        ("cmd_tag", "O", "16", "sys_clk", "命令标签，当前低位为 segment_id。"),
        ("cmd_sequence", "O", "32", "sys_clk", "分块序号，送元数据/调试接口。"),
        ("cmd_expected_crc", "O", "32", "sys_clk", "期望 payload CRC32C。"),
        ("cpl_valid", "I", "1", "sys_clk", "NVMe 完成信息有效。"),
        ("cpl_ready", "O", "1", "sys_clk", "存在在途命令时置 1。"),
        ("cpl_tag", "I", "16", "sys_clk", "完成命令标签。"),
        ("cpl_status", "I", "16", "sys_clk", "0 表示成功，其余为错误。"),
        ("fatal_error", "O", "1", "sys_clk", "Tag、长度或 NVMe 状态异常后锁存。"),
        ("submitted_segments", "O", "32", "sys_clk", "已提交 NVMe 的分段数。"),
        ("completed_segments", "O", "32", "sys_clk", "成功完成并释放的分段数。"),
    ])
    doc.add_paragraph(
        "cmd_slba 从 BASE_SLBA 开始；每次命令握手后增加 desc_byte_len/LBA_BYTES。"
        "若字节数为 0 或不能被 LBA_BYTES 整除，调度器置 fatal_error。错误完成不会释放"
        "对应 segment_free 位，避免坏数据被覆盖。"
    )

    doc.add_heading("5.6 nvme_axil_cmd_bridge 顶层信号", level=2)
    doc.add_paragraph(
        "该模块把项目内部的单条写命令转换为占位 AXI-Lite 寄存器访问：依次写参数和 start，"
        "轮询 status，写 completion ack，最后向调度器返回完成。寄存器地址必须按厂商文档替换。"
    )
    add_signal_table(doc, [
        ("clk", "I", "1", "sys_clk", "命令桥和 AXI-Lite 公共时钟。"),
        ("rst_n", "I", "1", "sys_clk", "低有效复位。"),
        ("cmd_valid", "I", "1", "sys_clk", "调度器命令有效。"),
        ("cmd_ready", "O", "1", "sys_clk", "桥处于 IDLE 时置 1。"),
        ("cmd_ddr_addr", "I", "DDR_ADDR_WIDTH", "sys_clk", "DMA 源地址。"),
        ("cmd_slba", "I", "64", "sys_clk", "SSD 起始 LBA。"),
        ("cmd_nlb", "I", "32", "sys_clk", "0-based LBA 数量。"),
        ("cmd_tag", "I", "16", "sys_clk", "命令标签。"),
        ("cmd_sequence", "I", "32", "sys_clk", "分块序号。"),
        ("cmd_expected_crc", "I", "32", "sys_clk", "期望 CRC32C。"),
        ("cpl_valid", "O", "1", "sys_clk", "完成结果有效。"),
        ("cpl_ready", "I", "1", "sys_clk", "调度器接受完成结果。"),
        ("cpl_tag", "O", "16", "sys_clk", "完成 Tag。"),
        ("cpl_status", "O", "16", "sys_clk", "0 成功；协议错误时输出 FFFF。"),
        ("m_axil_awaddr", "O", "AXI_ADDR_WIDTH", "sys_clk", "AXI-Lite 写地址。"),
        ("m_axil_awvalid", "O", "1", "sys_clk", "写地址有效。"),
        ("m_axil_awready", "I", "1", "sys_clk", "从设备接受写地址。"),
        ("m_axil_wdata", "O", "32", "sys_clk", "AXI-Lite 写数据。"),
        ("m_axil_wstrb", "O", "4", "sys_clk", "字节使能，固定为 F。"),
        ("m_axil_wvalid", "O", "1", "sys_clk", "写数据有效。"),
        ("m_axil_wready", "I", "1", "sys_clk", "从设备接受写数据。"),
        ("m_axil_bresp", "I", "2", "sys_clk", "写响应。"),
        ("m_axil_bvalid", "I", "1", "sys_clk", "写响应有效。"),
        ("m_axil_bready", "O", "1", "sys_clk", "桥接收写响应。"),
        ("m_axil_araddr", "O", "AXI_ADDR_WIDTH", "sys_clk", "状态寄存器读地址。"),
        ("m_axil_arvalid", "O", "1", "sys_clk", "读地址有效。"),
        ("m_axil_arready", "I", "1", "sys_clk", "从设备接受读地址。"),
        ("m_axil_rdata", "I", "32", "sys_clk", "状态寄存器读数据。"),
        ("m_axil_rresp", "I", "2", "sys_clk", "读响应。"),
        ("m_axil_rvalid", "I", "1", "sys_clk", "读数据有效。"),
        ("m_axil_rready", "O", "1", "sys_clk", "桥接收读数据。"),
        ("axil_error_sticky", "O", "1", "sys_clk", "任一 AXI-Lite BRESP/RRESP 非 OKAY 后锁存。"),
    ])
    doc.add_paragraph(
        "AXI-Lite 的 AW 和 W 通道可以独立握手，因此桥分别记录 aw_sent 和 w_sent，二者都完成"
        "后才等待 B 响应。轮询读同样遵循 AR/R 两阶段握手。该实现不是 CPU 软件，但做的事情"
        "与驱动写寄存器、敲 doorbell、读完成状态本质相同。"
    )

    doc.add_heading("5.7 nvme_adc_pipeline_top 顶层信号", level=2)
    doc.add_paragraph(
        "顶层连接 ADC 数据面、DDR AXI4 写口和 NVMe AXI-Lite 控制口。厂商 NVMe IP 的 DDR "
        "DMA Master 数据口不在该抽象顶层内，集成时应作为 SmartConnect 的另一主设备访问同一 "
        "DDR 地址空间。"
    )
    add_signal_table(doc, [
        ("adc_clk", "I", "1", "ADC", "ADC 解串后数据时钟。"),
        ("adc_rst_n", "I", "1", "ADC", "ADC 时钟域低有效复位。"),
        ("capture_enable", "I", "1", "ADC", "连续采集使能。"),
        ("adc_valid", "I", "1", "ADC", "两路 ADC 数据有效。"),
        ("adc_ch0", "I", "12", "ADC", "第 0 路 12 bit 样本。"),
        ("adc_ch1", "I", "12", "ADC", "第 1 路 12 bit 样本。"),
        ("sys_clk", "I", "1", "系统", "DDR Writer、调度器和命令桥时钟。"),
        ("sys_rst_n", "I", "1", "系统", "系统时钟域低有效复位。"),
        ("ddr_init_done", "I", "1", "系统", "DDR 校准完成；为 0 时禁止从 CDC FIFO 取数。"),
        ("nvme_init_done", "I", "1", "系统", "NVMe Host 已可接收写命令。"),
        ("m_axi_ddr_awaddr", "O", "AXI_ADDR_WIDTH", "系统", "DDR AXI4 写地址。"),
        ("m_axi_ddr_awlen", "O", "8", "系统", "DDR Burst 长度减 1。"),
        ("m_axi_ddr_awsize", "O", "3", "系统", "DDR 每 beat 字节数编码。"),
        ("m_axi_ddr_awburst", "O", "2", "系统", "DDR Burst 类型，固定 INCR。"),
        ("m_axi_ddr_awvalid", "O", "1", "系统", "DDR 写地址有效。"),
        ("m_axi_ddr_awready", "I", "1", "系统", "DDR 接受写地址。"),
        ("m_axi_ddr_wdata", "O", "AXI_DATA_WIDTH", "系统", "DDR 写数据。"),
        ("m_axi_ddr_wstrb", "O", "AXI_DATA_WIDTH/8", "系统", "DDR 写字节使能。"),
        ("m_axi_ddr_wlast", "O", "1", "系统", "DDR Burst 最后 beat。"),
        ("m_axi_ddr_wvalid", "O", "1", "系统", "DDR 写数据有效。"),
        ("m_axi_ddr_wready", "I", "1", "系统", "DDR 接受写数据。"),
        ("m_axi_ddr_bresp", "I", "2", "系统", "DDR 写响应。"),
        ("m_axi_ddr_bvalid", "I", "1", "系统", "DDR 写响应有效。"),
        ("m_axi_ddr_bready", "O", "1", "系统", "顶层接收 DDR 写响应。"),
        ("m_axil_nvme_awaddr", "O", "AXIL_ADDR_WIDTH", "系统", "NVMe 控制口写地址。"),
        ("m_axil_nvme_awvalid", "O", "1", "系统", "NVMe 控制口写地址有效。"),
        ("m_axil_nvme_awready", "I", "1", "系统", "NVMe 控制口接受写地址。"),
        ("m_axil_nvme_wdata", "O", "32", "系统", "NVMe 控制口写数据。"),
        ("m_axil_nvme_wstrb", "O", "4", "系统", "NVMe 控制口字节使能。"),
        ("m_axil_nvme_wvalid", "O", "1", "系统", "NVMe 控制口写数据有效。"),
        ("m_axil_nvme_wready", "I", "1", "系统", "NVMe 控制口接受写数据。"),
        ("m_axil_nvme_bresp", "I", "2", "系统", "NVMe 控制口写响应。"),
        ("m_axil_nvme_bvalid", "I", "1", "系统", "NVMe 控制口写响应有效。"),
        ("m_axil_nvme_bready", "O", "1", "系统", "顶层接收写响应。"),
        ("m_axil_nvme_araddr", "O", "AXIL_ADDR_WIDTH", "系统", "NVMe 状态读地址。"),
        ("m_axil_nvme_arvalid", "O", "1", "系统", "NVMe 状态读地址有效。"),
        ("m_axil_nvme_arready", "I", "1", "系统", "NVMe 接受读地址。"),
        ("m_axil_nvme_rdata", "I", "32", "系统", "NVMe 状态读数据。"),
        ("m_axil_nvme_rresp", "I", "2", "系统", "NVMe 状态读响应。"),
        ("m_axil_nvme_rvalid", "I", "1", "系统", "NVMe 状态读数据有效。"),
        ("m_axil_nvme_rready", "O", "1", "系统", "顶层接收状态读数据。"),
        ("adc_overflow_sticky", "O", "1", "ADC", "ADC 入口发生过丢样。"),
        ("ddr_axi_error_sticky", "O", "1", "系统", "DDR AXI 写响应错误。"),
        ("nvme_axil_error_sticky", "O", "1", "系统", "NVMe AXI-Lite 协议错误。"),
        ("fatal_error", "O", "1", "系统", "调度器检测到不可继续的命令/完成错误。"),
        ("adc_accepted_sample_pairs", "O", "64", "ADC", "ADC 入口接收样本对计数。"),
        ("adc_dropped_sample_pairs", "O", "64", "ADC", "ADC 入口丢弃样本对计数。"),
        ("submitted_segments", "O", "32", "系统", "已提交 NVMe 的分段数。"),
        ("completed_segments", "O", "32", "系统", "成功完成的分段数。"),
        ("segment_free", "O", "SEGMENT_COUNT", "系统", "DDR 分段空闲位图。"),
    ])
    doc.add_paragraph(
        "实际 MIG/SmartConnect 常带 AWID、AWCACHE、AWPROT、AWQOS 等完整 AXI4 信号。"
        "当前 Writer 使用的是最小写通道子集；集成封装应按 MIG 端口补齐 ID，并把未使用属性"
        "绑为厂商推荐常量。不能简单按同名线连接后就认为 AXI 已完整。"
    )

    doc.add_heading("5.8 仿真桩顶层信号", level=2)
    doc.add_heading("5.8.1 axi_ddr_mem_stub", level=3)
    add_signal_table(doc, [
        ("clk", "I", "1", "系统", "AXI 行为模型时钟。"),
        ("rst_n", "I", "1", "系统", "低有效复位。"),
        ("s_axi_awaddr", "I", "AXI_ADDR_WIDTH", "系统", "写地址。"),
        ("s_axi_awlen", "I", "8", "系统", "Burst 长度减 1。"),
        ("s_axi_awsize", "I", "3", "系统", "每 beat 字节数编码。"),
        ("s_axi_awburst", "I", "2", "系统", "Burst 类型。"),
        ("s_axi_awvalid", "I", "1", "系统", "写地址有效。"),
        ("s_axi_awready", "O", "1", "系统", "模型接受写地址。"),
        ("s_axi_wdata", "I", "AXI_DATA_WIDTH", "系统", "写数据。"),
        ("s_axi_wstrb", "I", "AXI_DATA_WIDTH/8", "系统", "写字节使能。"),
        ("s_axi_wlast", "I", "1", "系统", "最后 beat。"),
        ("s_axi_wvalid", "I", "1", "系统", "写数据有效。"),
        ("s_axi_wready", "O", "1", "系统", "模型接受写数据。"),
        ("s_axi_bresp", "O", "2", "系统", "协议和地址合法时返回 OKAY。"),
        ("s_axi_bvalid", "O", "1", "系统", "写响应有效。"),
        ("s_axi_bready", "I", "1", "系统", "主设备接受写响应。"),
    ])
    doc.add_paragraph(
        "该桩只实现单 outstanding 写 Burst 和字节数组存储，用于测试平台逐字节检查 DDR "
        "内容。它不是 MIG 性能模型，不模拟刷新、仲裁、读通道或真实 DDR 延迟。"
    )
    doc.add_heading("5.8.2 nvme_axil_stub", level=3)
    add_signal_table(doc, [
        ("clk/rst_n", "I", "1/1", "系统", "AXI-Lite 行为模型时钟和低有效复位。"),
        ("s_axil_awaddr", "I", "AXI_ADDR_WIDTH", "系统", "写寄存器地址。"),
        ("s_axil_awvalid/ready", "I/O", "1/1", "系统", "AXI-Lite AW 握手。"),
        ("s_axil_wdata/wstrb", "I", "32/4", "系统", "写数据和字节使能。"),
        ("s_axil_wvalid/ready", "I/O", "1/1", "系统", "AXI-Lite W 握手。"),
        ("s_axil_bresp/bvalid/bready", "O/O/I", "2/1/1", "系统", "AXI-Lite B 通道。"),
        ("s_axil_araddr", "I", "AXI_ADDR_WIDTH", "系统", "状态寄存器读地址。"),
        ("s_axil_arvalid/ready", "I/O", "1/1", "系统", "AXI-Lite AR 握手。"),
        ("s_axil_rdata/rresp", "O", "32/2", "系统", "状态读数据和响应。"),
        ("s_axil_rvalid/rready", "O/I", "1/1", "系统", "AXI-Lite R 握手。"),
        ("command_count", "O", "32", "系统", "收到 start 的命令数量。"),
        ("last_ddr_addr", "O", "64", "系统", "最近一次命令的 DDR 地址。"),
        ("last_slba", "O", "64", "系统", "最近一次命令的 SLBA。"),
        ("last_nlb", "O", "32", "系统", "最近一次命令的 NLB。"),
        ("last_tag", "O", "16", "系统", "最近一次命令 Tag。"),
        ("last_sequence", "O", "32", "系统", "最近一次分块序号。"),
        ("last_expected_crc", "O", "32", "系统", "最近一次期望 CRC32C。"),
    ])
    doc.add_paragraph(
        "该桩在 COMPLETE_LATENCY 个周期后把 busy 清零并置 done，不读取 DDR，也不运行真实 NVMe "
        "协议。它只证明命令字段、寄存器握手和分段回收逻辑正确。"
    )

    doc.add_heading("5.9 关键时序图与逐拍说明", level=2)
    add_timing_diagram(
        doc,
        "5.9.1 ADC 样本进入 AXI-Stream",
        [
            ("adc_clk", "_|-|_|-|_|-|_|-|_|-|_"),
            ("adc_valid", "___|-----------|_______"),
            ("adc_ch0/ch1", "---S0--S1--S2--S3------"),
            ("tready", "---------------|___|----"),
            ("tvalid", "____|-----------|-------"),
            ("tdata", "----D0--D1--D2--D3------"),
            ("transfer", ".....*...*...*.......*..."),
        ],
        [
            "在 adc_clk 上升沿，如果 capture_enable=1 且 adc_valid=1，模块把当前 Sx 扩展并打包为 Dx。",
            "tvalid 与 tready 同时为 1 的上升沿才算一次传输，图中用 * 标出。",
            "tready 拉低期间，输出寄存器必须保持 tvalid=1 且 tdata 不变；若 ADC 此时继续给新样本，新样本无法回压，会累加 dropped_sample_pairs。",
            "正式启动 capture_enable 前应确认 CDC FIFO 已离开 reset busy 且至少有一个 FREE 分段。",
        ],
    )
    add_timing_diagram(
        doc,
        "5.9.2 异步 FIFO 跨时钟传输",
        [
            ("s_clk", "_|-|_|-|_|-|_|-|_|-|_|-|_"),
            ("s_valid/ready", "____|=======|____________"),
            ("FIFO write", ".....W0..W1..W2..........."),
            ("m_clk", "__|--|__|--|__|--|__|--|__"),
            ("empty", "--------|-----0-------|1---"),
            ("m_valid/ready", "__________|=======|_______"),
            ("FIFO read", "...........R0...R1...R2...."),
        ],
        [
            "写指针在 s_clk 域推进，读指针在 m_clk 域推进；跨域只同步 Gray 指针，不直接同步多 bit 二进制计数。",
            "W0 写入后，empty 不会立刻在读域撤销，需要经过 CDC_SYNC_STAGES。这个延迟只影响启动，不会改变数据顺序。",
            "FWFT 模式下 empty 撤销后，队首数据已经出现在 m_axis_tdata；m_valid&&m_ready 时读指针推进。",
            "full、empty 只在各自时钟域使用。不要把它们当作无同步的全局状态信号跨域组合。",
        ],
    )
    add_timing_diagram(
        doc,
        "5.9.3 256 bit 打包与 DDR AXI4 Burst",
        [
            ("32b samples", "D0 D1 D2 D3 D4 D5 D6 D7 | D8 ..."),
            ("beat_fifo_wr", "_______________________|*|______"),
            ("AWVALID", "________________________|---|____"),
            ("AWREADY", "__________________________|-|____"),
            ("WVALID", "____________________________|===="),
            ("WREADY", "____________________________|===="),
            ("WLAST", "________________________________*"),
            ("BVALID", "__________________________________|*|"),
            ("desc_valid", "____________________________________|---"),
        ],
        [
            "每接收 8 个 32 bit 样本对，打包器向 beat FIFO 写入一个 256 bit beat；D0 位于 [31:0]，D7 位于 [255:224]。",
            "只有 beat_fifo_count 达到 BURST_BEATS，Writer 才拉高 AWVALID，避免发出地址后因数据不足而长时间断流。",
            "AWVALID 必须保持到 AWREADY；随后每个 WVALID&&WREADY 周期发送一个 beat，最后一个 beat 同时拉高 WLAST。",
            "最后一个 W beat 发送不等于 DDR 已完成写入。必须等待 BVALID&&BREADY，并检查 BRESP=OKAY。",
            "只有整个分段的最后一个 Burst 收到成功 B 响应后，desc_valid 才能置 1。这保证 NVMe 不会读到仍在 DDR 写入的数据。",
        ],
    )
    add_timing_diagram(
        doc,
        "5.9.4 分段描述符、NVMe 命令与回收",
        [
            ("segment state", "FILLING -> READY -> INFLIGHT -> FREE"),
            ("desc_valid", "__________|---|__________________"),
            ("desc_ready", "____________|--------------------"),
            ("cmd_valid", "_______________|---|_____________"),
            ("cmd_ready", "_________________|----------------"),
            ("cpl_valid", "___________________________|---|__"),
            ("cpl_status", "---------------------------OK------"),
            ("free_mask[id]", "1----0-------------------------1---"),
        ],
        [
            "Writer 接受 FREE 分段后进入 FILLING。描述符握手时调度器把对应 free_mask 位清零，分段变为不可覆盖。",
            "命令桥空闲且 nvme_init_done=1 时，cmd_valid/cmd_ready 完成提交，调度器记录 inflight_segment_id 和 Tag。",
            "NVMe 命令完成前，即使 Writer 需要新空间，也不能使用该分段。",
            "只有 cpl_tag 匹配且 cpl_status=0，free_mask 位才恢复为 1；错误完成置 fatal_error 并保留现场数据。",
        ],
    )
    add_timing_diagram(
        doc,
        "5.9.5 AXI-Lite 命令写入、轮询与完成",
        [
            ("cmd handshake", "|*|______________________________________"),
            ("AW/W writes", "DDR SLBA NLB TAG SEQ CRC START"),
            ("B responses", "__B___B___B___B___B___B___B___B___B___"),
            ("AR status", "________________________________|AR|_"),
            ("R busy", "___________________________________|R0|"),
            ("AR status", "______________________________________|AR|"),
            ("R done", "_________________________________________|R1|"),
            ("ACK write", "____________________________________________|ACK|"),
            ("cpl_valid", "________________________________________________|--"),
        ],
        [
            "cmd 握手后，桥先锁存全部字段，后续 AXI-Lite 等待不会改变命令内容。",
            "每个寄存器写操作都分别完成 AW、W 和 B 三个通道；AW 与 W 谁先 ready 都可以。",
            "写 START 后，桥反复读取 STATUS。R0 表示 busy/done=0，继续轮询；R1 表示 done=1。",
            "桥写 ACK 清除厂商状态，再输出 cpl_valid。若任一 BRESP/RRESP 非 OKAY，完成状态强制为 FFFF。",
            "接真实 IP 时，流程可能改为命令 FIFO、AXI-Stream 或直接 SQ doorbell，但内部 cmd/cpl 握手可以保持不变。",
        ],
    )

    doc.add_heading("6. 时钟、复位与流控", level=1)
    add_table(
        doc,
        ["时钟域", "主要逻辑", "复位/启动要求"],
        [
            ("adc_clk", "ADC 格式化、XPM FIFO 写端", "adc_rst_n 释放后等待 wr_rst_busy 清零"),
            ("sys_clk", "FIFO 读端、DDR Writer、调度器、NVMe 命令桥", "sys_rst_n 释放后等待 DDR/NVMe init_done"),
            ("PCIe/NVMe IP 内部", "LTSSM、Admin/I/O Queue、DMA", "以厂商 IP 时钟复位规范为准"),
        ],
        [1.25, 2.85, 2.40],
    )
    doc.add_paragraph(
        "ADC 本身不能接受 ready 回压，因此 m_axis_tready 变低时只能报警和计数，不能“暂停 ADC”。"
        "正式系统应只在 DDR 初始化完成、FIFO 复位忙结束、至少一个分段可用后拉高 capture_enable。"
        "采集中任何 dropped_sample_pairs 非零都应判定该次采集无效。"
    )

    doc.add_heading("7. DDR 分段与状态机", level=1)
    add_code(doc, "FREE → FILLING → READY → NVME_INFLIGHT → DONE → FREE")
    doc.add_paragraph(
        "实现中 FILLING 由 Writer 隐式持有；最后一个 AXI B 响应成功后生成 READY 描述符；"
        "调度器接收描述符时清除 free_mask，对应 NVMe 完成成功后重新置位。错误完成不会释放分段，"
        "避免坏数据被下一轮覆盖。当前基线一次只允许一个 NVMe 命令在途，便于先打通；获得厂商"
        "队列深度和 Tag 规则后可扩展为多 outstanding。"
    )
    add_table(
        doc,
        ["参数", "当前默认", "建议现场扫描"],
        [
            ("AXI_DATA_WIDTH", "256 bit", "与 MIG/SmartConnect 数据宽度一致"),
            ("BURST_BEATS", "16", "16/32/64；不超过 AXI4 256 beats"),
            ("SEGMENT_BYTES", "1 MiB", "64 KiB、256 KiB、1 MiB；受 MDTS 约束"),
            ("SEGMENT_COUNT", "8", "按 DDR 容量和最差 SSD 延迟增加"),
            ("BASE_SLBA", "2048", "避开盘头保护区；由测试盘布局决定"),
        ],
        [1.70, 1.35, 3.45],
    )

    doc.add_heading("8. 原始 LBA 与采集元数据格式", level=1)
    doc.add_paragraph(
        "建议每个采集块占用“1 个元数据 LBA＋若干数据 LBA”。电脑端扫描 magic 和 sequence，"
        "按 payload_bytes 读取负载并校验 payload_crc32c。这样既不依赖文件系统，也能在掉电、"
        "中途停止或坏块后重新定位有效数据。"
    )
    add_table(
        doc,
        ["偏移", "长度", "字段", "定义"],
        [
            ("0x000", "8", "magic", 'ASCII "ADCSTRM1"'),
            ("0x008", "2", "version", "格式版本，初始为 1"),
            ("0x00A", "2", "header_bytes", "固定 512"),
            ("0x00C", "4", "flags", "有效、截断、溢出等标志"),
            ("0x010", "8", "sequence", "单调递增分块序号"),
            ("0x018", "8", "sample_index_start", "本块第一个样本对序号"),
            ("0x020", "8", "timestamp_ns", "可为 0，接入时间源后启用"),
            ("0x028", "4", "sample_rate_hz", "250000000"),
            ("0x02C", "2", "channel_count", "2"),
            ("0x02E", "2", "stored_bits", "16"),
            ("0x030", "2", "valid_bits", "12"),
            ("0x032", "2", "sample_format", "1＝signed little-endian"),
            ("0x034", "4", "payload_bytes", "本块 ADC 数据字节数"),
            ("0x038", "4", "payload_crc32c", "对负载计算，初值全 1、最终取反"),
            ("0x03C", "4", "header_crc32c", "对头部指定范围计算"),
            ("0x040", "448", "reserved", "清零，供未来扩展"),
        ],
        [0.70, 0.55, 1.65, 3.60],
    )
    add_callout(
        doc,
        "当前代码状态",
        "现有 Writer 已计算 sequence 和 payload_crc32c，并随描述符送到 NVMe 命令桥；仿真也检查"
        "这两个值。为了保持第一版通路简单，512 B 元数据尚未作为 DDR 负载写入。接厂商 IP 时，"
        "增加一个 metadata composer，把元数据头与 payload 组成连续 DMA 区域，或先发 1 个头部"
        "命令再发 payload 命令。前者更便于一次命令落盘。",
        fill="FFF4E5",
    )

    doc.add_heading("9. NVMe、PCIe RC 与“无需软件”", level=1)
    doc.add_paragraph(
        "NVMe SSD 是 PCIe Endpoint。FPGA 上的 NVMe Host Controller 承担主机角色，因此 PCIe "
        "底层必须是 Root Complex；厂商只提供 RC 形式源码，方向上是正确的。若把 FPGA 配成 EP，"
        "它只能被另一台主机枚举，不能直接把同一块 SSD 当作下游设备管理。"
    )
    doc.add_paragraph(
        "“无需软件”不等于“不需要寄存器和 doorbell”。NVMe 仍然存在控制器初始化、Admin Queue、"
        "I/O Submission Queue、Completion Queue 和 SQ/CQ doorbell。差别只在于这些动作由厂商"
        "RTL 状态机/IP 内部完成，而不是 CPU 驱动完成。调试用软核可以读取状态、打印日志或下发"
        "测试参数，但不应位于 1 GB/s 实时数据面。"
    )

    doc.add_heading("10. 厂商 IP 接口替换清单", level=1)
    add_table(
        doc,
        ["必须确认", "为什么必须确认", "接入动作"],
        [
            ("NVMe 数据面 AXI 是 Master 还是 Slave", "决定谁从 DDR 发起读事务", "连接 SmartConnect 并做地址映射"),
            ("命令提交接口及寄存器表", "当前 AXI-Lite 地址只是占位", "重写 nvme_axil_cmd_bridge"),
            ("IP 是否内部初始化 Admin/I/O Queue", "决定是否真的不需要 CPU", "核对复位到 ready 的状态序列"),
            ("DMA 地址宽度和地址含义", "物理地址、窗口地址可能不同", "统一 DDR_BASE 和 Address Editor"),
            ("LBA 大小与 MDTS", "决定 NLB、分块上限", "Identify 后锁定参数"),
            ("完成状态、Tag 和最大 outstanding", "决定何时回收 DDR 分段", "扩展调度器队列"),
            ("PCIe 代际、lane 数和硬核配置", "决定链路吞吐上限", "至少验证 Gen3 x4 及实际 payload 吞吐"),
            ("缓存一致性要求", "纯 FPGA 一般无 CPU cache，但 IP 可能有窗口", "按厂商手册处理 barrier/flush"),
        ],
        [2.25, 2.30, 1.95],
    )

    doc.add_heading("11. 占位 AXI-Lite 寄存器协议", level=1)
    doc.add_paragraph(
        "下表仅用于本工程的 NVMe 仿真桩，不是厂商 IP 事实。它让调度器、命令握手和完成回收可以在"
        "没有正式 IP 时先行验证。接入时允许整体替换。"
    )
    add_table(
        doc,
        ["地址", "名称", "方向", "定义"],
        [
            ("0x004", "DDR_ADDR_LO", "W", "DMA 源地址低 32 bit"),
            ("0x008", "DDR_ADDR_HI", "W", "DMA 源地址高 32 bit"),
            ("0x00C", "SLBA_LO", "W", "起始 LBA 低 32 bit"),
            ("0x010", "SLBA_HI", "W", "起始 LBA 高 32 bit"),
            ("0x014", "NLB", "W", "NVMe 0-based block count"),
            ("0x018", "TAG", "W", "分段/命令标签"),
            ("0x01C", "SEQUENCE", "W", "分块序号"),
            ("0x020", "EXPECTED_CRC", "W", "负载 CRC32C"),
            ("0x024", "CTRL", "W", "bit0 start；bit1 completion ack"),
            ("0x028", "STATUS", "R", "ready/busy/done/error、状态码和 tag"),
        ],
        [0.75, 1.40, 0.55, 3.80],
    )

    doc.add_heading("12. 验证结果与验收计划", level=1)
    add_table(
        doc,
        ["检查项", "当前结果", "证据/判定"],
        [
            ("Vivado 2020.2 编译与展开", "通过", "KU040 目标器件；SystemVerilog＋XPM"),
            ("行为仿真", "通过", "4096 个样本对、4 个 4096 B 分段"),
            ("ADC 丢样", "0", "accepted=4096，dropped=0"),
            ("DDR 内容", "通过", "逐 32 bit 样本比对两路符号扩展数据"),
            ("NVMe 命令", "通过（仿真桩）", "4 次提交/完成，最后 SLBA=2072，NLB=7"),
            ("CRC32C", "通过", "最后分段的 RTL/测试平台计算一致"),
            ("KU040 OOC 综合", "通过", "0 errors/0 critical warnings；仅有未加板级 XDC 的时钟告警"),
        ],
        [2.05, 1.55, 2.90],
    )
    doc.add_paragraph(
        "OOC 综合资源结果：1125 个 CLB LUT、1274 个寄存器、5 个 RAMB36E2、0 个 DSP。"
        "该数字只覆盖本基础 RTL，不含 DDR MIG、PCIe/NVMe IP、UltraScale ADC PHY 和 ILA。"
        "由于当前没有板级 XDC，timing_ooc.rpt 的时钟/IO 未约束告警属于预期，不能用该报告"
        "判断最终时序收敛。"
    )
    doc.add_heading("12.1 板级递进验收", level=2)
    add_number(doc, "只接 DDR：固定模式写入、读回，比对地址边界和 Burst 响应。")
    add_number(doc, "只接 NVMe：沿用厂商自测流程，确认 RC 枚举、Identify 和原始 LBA 写读。")
    add_number(doc, "DDR→NVMe：预置递增数据，写入指定 LBA，电脑导出后逐字节比对。")
    add_number(doc, "ADC→DDR：以内部计数模式替代 ADC，确认 1 GB/s 等效流量下无 overflow。")
    add_number(doc, "ADC→DDR→NVMe：短时采集，检查 magic、sequence、CRC 和 LBA 连续性。")
    add_number(doc, "长稳测试：覆盖计划采集时长，记录 FIFO 水位、SSD 温度、PCIe 重训和错误计数。")

    doc.add_heading("12.2 最低通过条件", level=2)
    add_bullet(doc, "整个采集区间 dropped_sample_pairs 恒为 0，AXI B/R 响应无错误。")
    add_bullet(doc, "电脑导出的 sequence 连续，无重复、倒退或缺块。")
    add_bullet(doc, "每个 payload 的 CRC32C 一致；末块允许通过 flags 标记截断。")
    add_bullet(doc, "NVMe 完成状态全部成功后才释放 DDR 分段。")
    add_bullet(doc, "SSD 在目标温度和容量区间内的稳态写速率高于 1 GB/s，并保留工程裕量。")

    doc.add_heading("13. 工程目录与使用方法", level=1)
    add_code(
        doc,
        "nvme_adc_axi_pipeline/\n"
        "  rtl/                 # 可综合数据面和控制面\n"
        "  rtl/stubs/           # 仅行为仿真\n"
        "  sim/                 # 端到端自检测试平台\n"
        "  scripts/             # Vivado 2020.2 仿真/综合 Tcl\n"
        "  docs/                # 本设计方案"
    )
    add_code(
        doc,
        "& 'D:\\Xilinx_2020_2\\Vivado\\2020.2\\bin\\vivado.bat' `\n"
        "  -mode batch -source .\\scripts\\run_vivado_sim.tcl\n\n"
        "& 'D:\\Xilinx_2020_2\\Vivado\\2020.2\\bin\\vivado.bat' `\n"
        "  -mode batch -source .\\scripts\\run_vivado_synth.tcl"
    )

    doc.add_heading("14. 下一步实施顺序", level=1)
    add_number(doc, "向厂商索取接口手册、完整 example design、寄存器表、时钟复位要求和 MDTS 说明。")
    add_number(doc, "确定 KU040 板卡、PCIe lane/速率、DDR MIG 数据宽度和 Address Editor 地址图。")
    add_number(doc, "完成 UltraScale ADC PHY 适配，先以 ILA 验证两路 12 bit 样本顺序。")
    add_number(doc, "用真实 MIG 替换 DDR stub，完成 DDR 固定模式写读和并发带宽测试。")
    add_number(doc, "按厂商接口重写 NVMe adapter，先写固定 DDR 模式到测试盘原始 LBA。")
    add_number(doc, "增加 512 B metadata composer，再接通 ADC 短采、导出和 CRC 校验。")
    add_number(doc, "最后提高分块大小和 outstanding 数，做长稳、温度和异常断链测试。")

    doc.add_heading("附录 A：本次参考路径", level=1)
    add_bullet(doc, r"远端 ADC：C:\project\RTDS\BUFR_RPT201-1\idelay_2018\RPT201")
    add_bullet(doc, r"远端 DDR：C:\project\RTDS\DDR\26_top_ddr4_rw")
    add_bullet(doc, r"本地基础工程：E:\NVME_PRO\nvme_adc_axi_pipeline")
    add_bullet(doc, r"厂商自测材料：E:\NVME_PRO\NVMe_Host_Controller_自测报告.docx")
    add_bullet(doc, "按用户要求，不以《NVMe协议研究报告.docx》作为设计依据。")

    core = doc.core_properties
    core.title = "NVMe–DDR–ADC FPGA 基础通路设计方案"
    core.subject = "UltraScale KU040 上的原始 LBA 连续采集通路"
    core.author = "项目组 / Codex 协作整理"
    core.keywords = "NVMe, DDR, ADC, FPGA, AXI, PCIe RC, Raw LBA"

    OUT.parent.mkdir(parents=True, exist_ok=True)
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    build()
```
