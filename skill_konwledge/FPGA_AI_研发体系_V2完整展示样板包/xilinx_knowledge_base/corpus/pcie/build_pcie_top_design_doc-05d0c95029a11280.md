# build_pcie_top_design_doc

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\build_pcie_top_design_doc.py`
- SHA-256: `05d0c95029a112800f4f20407210cc91a04eb3b9de478f5bd5ec5385e596c5c3`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

```python
from pathlib import Path

from docx import Document
from docx.enum.section import WD_SECTION_START
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor
from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "docs" / "generated"
DOCX_PATH = OUT_DIR / "RTDS_test_PCIe_top_design.docx"
TOP_DIAGRAM = OUT_DIR / "pcie_top_block.png"
FLOW_DIAGRAM = OUT_DIR / "pcie_data_flow.png"


FONT_BODY = "Microsoft YaHei"
FONT_CODE = "Consolas"
BLUE = "2E74B5"
DARK_BLUE = "1F4D78"
LIGHT_BLUE = "E8EEF5"
LIGHT_GRAY = "F2F4F7"
BORDER = "9AA8B5"


def font(size=22, bold=False):
    candidates = [
        "C:/Windows/Fonts/msyhbd.ttc" if bold else "C:/Windows/Fonts/msyh.ttc",
        "C:/Windows/Fonts/simhei.ttf",
        "C:/Windows/Fonts/arial.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            return ImageFont.truetype(candidate, size)
    return ImageFont.load_default()


def ensure_output_dir():
    OUT_DIR.mkdir(parents=True, exist_ok=True)


def arrow(draw, start, end, color="#3B4A5A", width=4):
    draw.line([start, end], fill=color, width=width)
    x1, y1 = start
    x2, y2 = end
    if abs(x2 - x1) >= abs(y2 - y1):
        direction = 1 if x2 >= x1 else -1
        pts = [(x2, y2), (x2 - 14 * direction, y2 - 8), (x2 - 14 * direction, y2 + 8)]
    else:
        direction = 1 if y2 >= y1 else -1
        pts = [(x2, y2), (x2 - 8, y2 - 14 * direction), (x2 + 8, y2 - 14 * direction)]
    draw.polygon(pts, fill=color)


def box(draw, xy, title, lines=None, fill="#FFFFFF", outline="#7F8C99"):
    if not fill.startswith("#"):
        fill = "#" + fill
    if not outline.startswith("#"):
        outline = "#" + outline
    x1, y1, x2, y2 = xy
    draw.rounded_rectangle(xy, radius=14, fill=fill, outline=outline, width=3)
    draw.text((x1 + 18, y1 + 14), title, font=font(24, True), fill="#0B2545")
    if lines:
        y = y1 + 48
        for line in lines:
            draw.text((x1 + 18, y), line, font=font(18), fill="#263747")
            y += 25


def draw_top_diagram():
    img = Image.new("RGB", (1600, 900), "white")
    d = ImageDraw.Draw(img)
    d.text((40, 30), "PCIe.v subsystem block diagram", font=font(34, True), fill="#0B2545")
    d.text((40, 72), "Scope: hand-written PCIe wrapper + Vivado BD instance inside RTDS_test", font=font(22), fill="#536170")

    box(d, (60, 150, 330, 315), "DATA_CDC", ["100 MHz -> 250 MHz", "66-bit frame stream"], LIGHT_GRAY)
    box(d, (430, 125, 725, 345), "PCIe.v", ["SOF/EOF strip", "dual FIFO ping-pong", "FDMA read/write FSM", "IRQ / register handshake"], "#F7FBFF", "#2E74B5")
    box(d, (830, 105, 1190, 365), "design_1_wrapper", ["Vivado block design", "XDMA + AXI interconnect", "CONV_DMA / INFO_EXCH", "BRAM data window"], "#F4F8FC", "#1F4D78")
    box(d, (1285, 145, 1535, 325), "CPU / Host", ["PCIe link", "XDMA BAR / AXI", "IRQ + status"], LIGHT_GRAY)

    arrow(d, (330, 230), (430, 230))
    arrow(d, (725, 230), (830, 230))
    arrow(d, (1190, 230), (1285, 230))
    arrow(d, (1285, 285), (1190, 285))
    arrow(d, (830, 315), (725, 315))
    arrow(d, (430, 315), (330, 315))

    box(d, (430, 455, 725, 650), "PCIe.v hand logic", ["fdma_wareq / fdma_rareq", "fdma_wdata / fdma_rdata", "FPGA_CPU_irq_req", "INT_STATE / CLEAR_INTER"], "#FFFDF7", "#B0882E")
    box(d, (830, 455, 1190, 650), "BD internal IP", ["CONV_DMA: FDMA <-> AXI4", "INFO_EXCH: AXI-Lite regs", "XDMA: PCIe endpoint", "BRAM: 32 KB buffer"], "#FFFDF7", "#B0882E")
    arrow(d, (725, 555), (830, 555), color="#B0882E")

    d.text((60, 760), "Why the BD is drawn under PCIe.v:", font=font(24, True), fill="#0B2545")
    d.text((60, 795), "TOP.v is the FPGA project top; design_1_wrapper is only the PCIe communication subsystem used by PCIe.v.", font=font(21), fill="#263747")
    d.text((60, 825), "Putting the BD under PCIe.v keeps the diagram aligned with ownership and avoids hiding the hand-written wrapper FSMs.", font=font(21), fill="#263747")
    img.save(TOP_DIAGRAM)


def draw_flow_diagram():
    img = Image.new("RGB", (1600, 1000), "white")
    d = ImageDraw.Draw(img)
    d.text((40, 30), "PCIe data flow", font=font(34, True), fill="#0B2545")

    y1 = 145
    box(d, (65, y1, 320, y1 + 140), "Aurora/debug", ["Aurora_frame_gen", "66-bit {SOF,data,EOF}"], LIGHT_GRAY)
    box(d, (400, y1, 670, y1 + 140), "CDC FIFO", ["Aurora_PCIe_cdc", "100 MHz -> 250 MHz"], "#F7FBFF")
    box(d, (750, y1, 1030, y1 + 140), "PCIe.v write path", ["SOF/EOF removed", "64-bit payload", "ping-pong FIFO"], "#F7FBFF")
    box(d, (1110, y1, 1390, y1 + 140), "Host memory window", ["CONV_DMA -> AXI4", "XDMA/BRAM/PCIe"], LIGHT_GRAY)
    arrow(d, (320, y1 + 70), (400, y1 + 70))
    arrow(d, (670, y1 + 70), (750, y1 + 70))
    arrow(d, (1030, y1 + 70), (1110, y1 + 70))
    d.text((65, 310), "FPGA -> CPU direction: after one frame ends, PCIe.v starts 16-beat FDMA bursts over a 32 KB buffer, then raises FPGA_CPU_irq_req.", font=font(21), fill="#263747")

    y2 = 480
    box(d, (1110, y2, 1390, y2 + 140), "CPU write done", ["INFO_EXCH 0x0020", "r_RD_START pulse"], LIGHT_GRAY)
    box(d, (750, y2, 1030, y2 + 140), "PCIe.v read path", ["FDMA read FSM", "64-bit data", "add SOF/EOF"], "#F7FBFF")
    box(d, (400, y2, 670, y2 + 140), "CDC FIFO", ["PCIe_Aurora_cdc", "250 MHz -> 100 MHz"], "#F7FBFF")
    box(d, (65, y2, 320, y2 + 140), "Aurora side", ["current output unused", "ready for Aurora TX"], LIGHT_GRAY)
    arrow(d, (1110, y2 + 70), (1030, y2 + 70))
    arrow(d, (750, y2 + 70), (670, y2 + 70))
    arrow(d, (400, y2 + 70), (320, y2 + 70))
    d.text((65, 645), "CPU -> FPGA direction: host writes buffer/config, toggles CPU_WR_DONE; PCIe.v reads buffer and re-wraps data as 66-bit frame stream.", font=font(21), fill="#263747")

    box(d, (160, 765, 480, 910), "Control/status regs", ["INFO_EXCH AXI-Lite", "temperature, lengths", "interrupt clear, CPU state"], "#FFFDF7", "#B0882E")
    box(d, (650, 765, 960, 910), "Important caveat", ["DATA_CDC uses debug generator", "real Aurora RX input is commented", "PCIe->Aurora output is unconnected"], "#FFFDF7", "#B0882E")
    box(d, (1120, 765, 1420, 910), "Clock domains", ["100 MHz Aurora/debug", "250 MHz PCIe/FDMA", "PCIe ref clock in BD"], "#FFFDF7", "#B0882E")
    img.save(FLOW_DIAGRAM)


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = OxmlElement("w:shd")
    shd.set(qn("w:fill"), fill)
    tc_pr.append(shd)


def set_cell_border(cell, color=BORDER, size="4"):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right"):
        tag = "w:" + edge
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), "single")
        element.set(qn("w:sz"), size)
        element.set(qn("w:space"), "0")
        element.set(qn("w:color"), color)


def set_table_width(table, widths):
    table.alignment = WD_TABLE_ALIGNMENT.CENTER
    table.autofit = False
    for row in table.rows:
        for idx, width in enumerate(widths):
            row.cells[idx].width = Inches(width)
            row.cells[idx].vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_border(row.cells[idx])


def set_run_font(run, name=FONT_BODY, size=None, bold=None, color=None):
    run.font.name = name
    run._element.rPr.rFonts.set(qn("w:ascii"), name)
    run._element.rPr.rFonts.set(qn("w:hAnsi"), name)
    run._element.rPr.rFonts.set(qn("w:eastAsia"), name)
    if size:
        run.font.size = Pt(size)
    if bold is not None:
        run.bold = bold
    if color:
        run.font.color.rgb = RGBColor.from_string(color)


def set_paragraph_font(paragraph, name=FONT_BODY, size=11, color="000000"):
    for run in paragraph.runs:
        set_run_font(run, name=name, size=size, color=color)


def add_paragraph(doc, text="", style=None, bold_prefix=None):
    p = doc.add_paragraph(style=style)
    if bold_prefix and text.startswith(bold_prefix):
        r1 = p.add_run(bold_prefix)
        set_run_font(r1, bold=True)
        r2 = p.add_run(text[len(bold_prefix):])
        set_run_font(r2)
    else:
        r = p.add_run(text)
        set_run_font(r)
    return p


def add_bullets(doc, items):
    for item in items:
        p = doc.add_paragraph(style="List Bullet")
        run = p.add_run(item)
        set_run_font(run)


def add_table(doc, headers, rows, widths):
    table = doc.add_table(rows=1, cols=len(headers))
    set_table_width(table, widths)
    hdr = table.rows[0].cells
    for i, header in enumerate(headers):
        set_cell_shading(hdr[i], LIGHT_BLUE)
        p = hdr[i].paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        run = p.add_run(header)
        set_run_font(run, bold=True, color="0B2545")
    for row in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row):
            p = cells[i].paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.LEFT
            run = p.add_run(value)
            set_run_font(run, name=FONT_CODE if value.endswith(".v") or "/" in value else FONT_BODY, size=10.5)
    return table


def style_document(doc):
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(1)
    section.bottom_margin = Inches(1)
    section.left_margin = Inches(1)
    section.right_margin = Inches(1)
    section.header_distance = Inches(0.492)
    section.footer_distance = Inches(0.492)

    normal = doc.styles["Normal"]
    normal.font.name = FONT_BODY
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), FONT_BODY)
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    for style_name, size, color, before, after in [
        ("Heading 1", 16, BLUE, 18, 10),
        ("Heading 2", 13, BLUE, 14, 7),
        ("Heading 3", 12, DARK_BLUE, 10, 5),
    ]:
        style = doc.styles[style_name]
        style.font.name = FONT_BODY
        style._element.rPr.rFonts.set(qn("w:eastAsia"), FONT_BODY)
        style.font.size = Pt(size)
        style.font.color.rgb = RGBColor.from_string(color)
        style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)


def build_doc():
    ensure_output_dir()
    draw_top_diagram()
    draw_flow_diagram()

    doc = Document()
    style_document(doc)

    title = doc.add_paragraph()
    title.alignment = WD_ALIGN_PARAGRAPH.LEFT
    run = title.add_run("RTDS_test 联调工程 PCIe.v 顶层设计说明")
    set_run_font(run, size=22, bold=True, color="0B2545")
    add_paragraph(doc, "适用工程：E:\\PCIE-CPU\\RTDS_test；Vivado 实际综合顶层为 TOP.v，PCIe 子系统入口为 PCIe.v。")
    add_paragraph(doc, "结论：该工程不是纯 IP 集成。Vivado Block Design 负责 XDMA、AXI 互连、BRAM 和部分 AXI-Lite/AXI4 适配；PCIe.v、DATA_CDC、CONV_DMA、INFO_EXCH 等文件中仍有少量但关键的手写控制逻辑。")

    doc.add_heading("1. 顶层关系", level=1)
    add_paragraph(doc, "RTDS_test.xpr 中 TopModule 配置为 TOP。TOP.v 承担板级顶层职责：接收板级时钟和 PCIe 管脚，生成 250 MHz/100 MHz 时钟，实例化数据 CDC、PCIe 子系统、LED 和温度采集。")
    add_table(
        doc,
        ["层级", "模块/文件", "主要职责", "性质"],
        [
            ("工程顶层", "TOP.v", "板级 I/O、时钟复位、DATA_CDC、PCIe、LED、TEMP_RD 汇总。", "手写 RTL"),
            ("PCIe 子系统顶层", "PCIe.v", "帧处理、双 FIFO、FDMA 读写状态机、中断/握手、实例化 design_1_wrapper。", "手写 RTL + BD wrapper"),
            ("Vivado BD", "design_1.bd / design_1_wrapper.v", "XDMA、AXI interconnect、AXI BRAM 控制器、BRAM、util_ds_buf、CONV_DMA、INFO_EXCH。", "IP 集成 + HDL reference"),
            ("数据跨时钟", "DATA_CDC.v / *_cdc.v", "100 MHz 与 250 MHz 之间的 66-bit 异步 FIFO 转接。", "手写封装 + FIFO IP"),
            ("调试/辅助", "Aurora_frame_gen.v / LED.v / TEMP_RD.v", "当前联调数据源、板载 LED、FPGA 温度读取。", "手写逻辑 + IP"),
        ],
        [0.95, 1.45, 3.25, 0.85],
    )

    doc.add_heading("2. PCIe.v 顶层框图", level=1)
    add_paragraph(doc, "下面的框图按 PCIe.v 的实际职责划分。它没有把 TOP.v 里的 LED、温度读取、时钟生成全部展开，因为这些不属于 PCIe 数据搬运主路径。")
    doc.add_picture(str(TOP_DIAGRAM), width=Inches(6.5))

    doc.add_heading("3. 数据流", level=1)
    add_paragraph(doc, "PCIe 数据通路分成 FPGA -> CPU 和 CPU -> FPGA 两个方向。当前工程里 Aurora 真实输入仍被注释，DATA_CDC 使用 Aurora_frame_gen 作为 100 MHz 调试数据源；PCIe -> Aurora 的 CDC 输出也尚未接到真实 Aurora TX。")
    doc.add_picture(str(FLOW_DIAGRAM), width=Inches(6.5))

    doc.add_heading("4. PCIe.v 内部手写逻辑", level=1)
    add_table(
        doc,
        ["逻辑块", "所在位置", "作用", "说明"],
        [
            ("帧剥离", "PCIe.v", "把 66-bit {SOF, data[63:0], EOF} 转成 64-bit payload。", "SOF=i_wr_data[65]，EOF=i_wr_data[0]。"),
            ("双 FIFO ping-pong", "PCIe.v + fifo_AURORA_DATA64 IP", "按帧在 U1/U2 两个 FIFO 间切换，避免写入和 FDMA 读取互相踩踏。", "fifo_sel 在帧结束后翻转。"),
            ("FDMA 写状态机", "PCIe.v", "产生 fdma_wareq、fdma_waddr、fdma_wdata，将 FPGA 侧数据写入 host 可读缓冲区。", "FDMA_BURST_LEN=16，默认 FPGA_CPU_LEN=32 KB。"),
            ("中断握手", "PCIe.v + INFO_EXCH", "写完后置位 FPGA_CPU_irq_req；CPU 读取 INT_STATE 后通过 CLEAR_INTER_R 清中断。", "INT_STATE_W/R 是跨 AXI-Lite 寄存器的握手。"),
            ("FDMA 读状态机", "PCIe.v", "CPU 写完后由 INFO_EXCH 的 r_RD_START 触发，从 CPU_FPGA 区域读回数据。", "输出重新拼为 66-bit 帧。"),
            ("调试探针", "PCIe.v / *_cdc.v", "ILA 观测 FDMA 和 CDC 两侧信号。", "不改变主功能，但属于联调工程代码层级。"),
        ],
        [1.2, 1.45, 2.65, 1.2],
    )

    doc.add_heading("5. Block Design 内部", level=1)
    add_paragraph(doc, "design_1.bd 是 PCIe 子系统内部的 IP Integrator 设计，不是整个 FPGA 顶层。BD 中出现的 CONV_DMA 和 INFO_EXCH 是 HDL reference，被 Vivado 包装成 design_1_CONV_DMA_0_0 和 design_1_INFO_EXCH_0_0 后放入 BD。")
    add_table(
        doc,
        ["BD 单元", "来源/类型", "职责"],
        [
            ("xdma_0", "Xilinx XDMA IP", "PCIe endpoint，提供 AXI master/slave 通道和 user_lnk_up。"),
            ("axi_interconnect_0", "Xilinx AXI interconnect", "连接 CONV_DMA 的 AXI master 到 AXI BRAM 控制器。"),
            ("axi_bram_ctrl_0 + blk_mem_gen_0", "Xilinx IP", "提供 host/FPGA 数据交换缓冲区。"),
            ("axi_interconnect_1", "Xilinx AXI-Lite path", "连接 XDMA 到 INFO_EXCH 寄存器。"),
            ("CONV_DMA_0", "HDL reference", "把简单 fdma_* 请求转换成 AXI4 burst 读写。"),
            ("INFO_EXCH_0", "HDL reference", "AXI-Lite 寄存器、状态读取、控制写入和握手脉冲。"),
            ("util_ds_buf", "Xilinx util_ds_buf", "PCIe 差分参考时钟缓冲。"),
        ],
        [1.75, 1.8, 2.95],
    )

    doc.add_heading("6. INFO_EXCH 寄存器视图", level=1)
    add_table(
        doc,
        ["地址", "方向", "名称", "用途"],
        [
            ("0x0000", "R", "VERSION", "版本号，默认 0x00001001。"),
            ("0x0004", "R", "PROG_TIME", "程序时间，默认 0x20260506。"),
            ("0x0008", "R", "CH_BUF_LEN", "通道缓冲长度，默认 0x8000。"),
            ("0x000C", "R", "FPGA_TEMP_W", "FPGA 温度/状态字。"),
            ("0x0010", "R", "INT_STATE_W", "CPU 读取该地址会产生 INT_STATE_R 和 CLEAR_INTER_R 脉冲，用于清 FPGA_CPU_irq_req。"),
            ("0x0014", "R/W", "CPU_REC_STATE", "CPU 接收状态反馈。"),
            ("0x0018", "R", "FPGA_CPU_START_ADDR", "FPGA -> CPU 缓冲起始地址，当前固定 0。"),
            ("0x001C", "R", "FPGA_CPU_LEN", "FPGA -> CPU 长度，当前 32 KB。"),
            ("0x0020", "R/W", "CPU_WR_DONE", "CPU 写完成触发位；上升沿产生 r_RD_START。读侧返回 CPU_WR_DONE_resp。"),
            ("0x0024", "R/W", "CPU_FPGA_START_ADDR", "CPU -> FPGA 缓冲起始地址，复位默认 32 KB。"),
            ("0x0028", "R/W", "CPU_FPGA_LEN", "CPU -> FPGA 长度，复位默认 32 KB。"),
        ],
        [0.85, 0.55, 1.6, 3.5],
    )

    doc.add_heading("7. 是纯集成还是手写逻辑", level=1)
    add_paragraph(doc, "判断结果：不是纯集成。可以把工程理解为“BD 集成骨架 + 手写 PCIe/FDMA 胶水逻辑 + 联调调试逻辑”。")
    add_bullets(
        doc,
        [
            "纯集成部分：XDMA、AXI interconnect、AXI BRAM controller、BRAM、FIFO、ILA、clk_wiz、sys_mon 等标准 IP。",
            "手写但被放入 BD 的部分：CONV_DMA 和 INFO_EXCH。它们不是 Xilinx 原生 IP 的简单配置，而是本工程的 HDL reference。",
            "手写且在 BD 外部的部分：TOP、PCIe、DATA_CDC、PCIe_Aurora_cdc、Aurora_PCIe_cdc、Aurora_frame_gen、LED、TEMP_RD 中的控制和封装逻辑。",
            "最关键的业务逻辑在 PCIe.v：它决定何时写 host buffer、何时发中断、何时响应 CPU 写完成并读回数据。BD 只是承载 PCIe/AXI 基础设施。",
        ],
    )

    doc.add_heading("8. 为什么 block diagram 放在 PCIe.v 下面", level=1)
    add_paragraph(doc, "原因有三点。第一，Vivado 的 block design 只覆盖 PCIe 通信子系统，并由 PCIe.v 实例化；它不是 TOP.v 的完整展开。第二，工程真实顶层 TOP.v 还包含时钟、DATA_CDC、LED、TEMP_RD 等外围逻辑，把 BD 画成整个顶层会误导读者以为所有逻辑都在 IP Integrator 内。第三，PCIe.v 正好是手写逻辑和 BD 的边界：往上接 66-bit 业务帧和板级 PCIe 管脚，往下接 design_1_wrapper 的 fdma_*、AXI-Lite 状态和 XDMA 链路。")
    add_paragraph(doc, "如果要画整个顶层，建议另画一张系统级图：TOP.v 作为根节点，展开 CLK_GEN、DATA_CDC、PCIe、LED、TEMP_RD；其中 PCIe 节点再引用本说明中的 PCIe.v 子系统图。这样层次最清楚。")

    doc.add_section(WD_SECTION_START.NEW_PAGE)
    doc.add_heading("附录：代码层次树", level=1)
    add_paragraph(doc, "TOP.v")
    add_bullets(
        doc,
        [
            "CLK_GEN -> clk_wiz_0 IP，输出 clk_250m / clk_100m / sys_rst。",
            "DATA_CDC -> PCIe_Aurora_cdc、Aurora_frame_gen、Aurora_PCIe_cdc。",
            "PCIe -> fifo_AURORA_DATA64 U1/U2、ila_FDMA、design_1_wrapper。",
            "design_1_wrapper -> design_1 -> XDMA、AXI interconnect、BRAM、CONV_DMA、INFO_EXCH、util_ds_buf。",
            "LED -> 板级心跳。",
            "TEMP_RD -> sys_mon IP + ila_temp。",
        ],
    )
    add_paragraph(doc, "需要后续补强的接口点：真实 Aurora RX 输入目前在 DATA_CDC 中被注释，当前使用 Aurora_frame_gen 产生测试帧；PCIe_Aurora_cdc 的输出没有继续接到真实 Aurora 发送逻辑。若后续要形成完整 RTDS 联调闭环，应优先把这两个接口从调试模式切回真实 Aurora 数据路径。")

    footer = doc.sections[0].footer.paragraphs[0]
    footer.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    r = footer.add_run("RTDS_test PCIe.v 顶层设计说明")
    set_run_font(r, size=9, color="555555")

    doc.save(DOCX_PATH)


if __name__ == "__main__":
    build_doc()
    print(DOCX_PATH)
```
