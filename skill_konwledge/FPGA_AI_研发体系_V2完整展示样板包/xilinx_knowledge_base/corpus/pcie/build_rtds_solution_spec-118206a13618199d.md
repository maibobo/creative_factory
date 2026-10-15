# build_rtds_solution_spec

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\build_rtds_solution_spec.py`
- SHA-256: `118206a13618199df4c1a9eea0162c0433467e742d30157fb281a0ca1b7dea83`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

```python
from pathlib import Path
import sys
import math

# 文档构建依赖隔离在 docs/_pydeps，不修改系统或 Vivado Python 环境。
sys.path.insert(0, str(Path(__file__).resolve().parent / "_pydeps"))
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib.font_manager import FontProperties

from docx import Document
from docx.shared import Inches, Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT, WD_CELL_VERTICAL_ALIGNMENT
from docx.enum.section import WD_SECTION
from docx.enum.style import WD_STYLE_TYPE
from docx.oxml import OxmlElement
from docx.oxml.ns import qn


ROOT = Path(r"E:\PCIE-CPU")
OUT = ROOT / "docs" / "RTDS_test-1ch_XDMA_Aurora设计与验证方案规格书.docx"
ASSET_DIR = ROOT / "docs" / "_rtds_solution_spec_assets"
ASSET_DIR.mkdir(parents=True, exist_ok=True)

BLUE = "1F4E79"
DARK_BLUE = "17365D"
MID_BLUE = "5B9BD5"
LIGHT_BLUE = "D9EAF7"
PALE_BLUE = "EEF5FB"
GRAY = "666666"
LIGHT_GRAY = "F2F4F7"
DARK = "222222"
GREEN = "2F6B3C"
RED = "A61B1B"
GOLD = "8A6D1D"
WHITE = "FFFFFF"
TABLE_WIDTH_DXA = 9360
TABLE_INDENT_DXA = 120

font_path = Path(r"C:\Windows\Fonts\msyh.ttc")
CJK = FontProperties(fname=str(font_path)) if font_path.exists() else None


def style_run(run, size=10.5, bold=False, color=DARK, italic=False, ascii_font="Calibri"):
    run.font.name = ascii_font
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), ascii_font)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), ascii_font)
    run._element.get_or_add_rPr().rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


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
    for m, v in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{m}"))
        if node is None:
            node = OxmlElement(f"w:{m}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(v))
        node.set(qn("w:type"), "dxa")


def set_table_geometry(table, widths, indent=TABLE_INDENT_DXA):
    assert sum(widths) == TABLE_WIDTH_DXA, (widths, sum(widths))
    table.autofit = False
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl_pr = table._tbl.tblPr
    tbl_w = tbl_pr.find(qn("w:tblW"))
    if tbl_w is None:
        tbl_w = OxmlElement("w:tblW")
        tbl_pr.append(tbl_w)
    tbl_w.set(qn("w:w"), str(TABLE_WIDTH_DXA))
    tbl_w.set(qn("w:type"), "dxa")
    tbl_ind = tbl_pr.find(qn("w:tblInd"))
    if tbl_ind is None:
        tbl_ind = OxmlElement("w:tblInd")
        tbl_pr.append(tbl_ind)
    tbl_ind.set(qn("w:w"), str(indent))
    tbl_ind.set(qn("w:type"), "dxa")
    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in widths:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)
    for row in table.rows:
        for i, cell in enumerate(row.cells):
            tc_pr = cell._tc.get_or_add_tcPr()
            tc_w = tc_pr.find(qn("w:tcW"))
            if tc_w is None:
                tc_w = OxmlElement("w:tcW")
                tc_pr.append(tc_w)
            tc_w.set(qn("w:w"), str(widths[i]))
            tc_w.set(qn("w:type"), "dxa")
            cell.width = Inches(widths[i] / 1440)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            set_cell_margins(cell)


def repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_repeat_together(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    keep_next = OxmlElement("w:keepNext")
    p_pr.append(keep_next)


def set_repeat_lines(paragraph):
    p_pr = paragraph._p.get_or_add_pPr()
    keep_lines = OxmlElement("w:keepLines")
    p_pr.append(keep_lines)


def add_table(doc, headers, rows, widths, header_fill=LIGHT_BLUE, font_size=8.5):
    table = doc.add_table(rows=1, cols=len(headers))
    table.style = "Table Grid"
    table.rows[0].cells
    for i, header in enumerate(headers):
        cell = table.rows[0].cells[i]
        set_cell_shading(cell, header_fill)
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        p.paragraph_format.space_before = Pt(0)
        p.paragraph_format.space_after = Pt(0)
        r = p.add_run(header)
        style_run(r, size=font_size, bold=True, color=DARK_BLUE)
    repeat_table_header(table.rows[0])
    for row_data in rows:
        cells = table.add_row().cells
        for i, value in enumerate(row_data):
            p = cells[i].paragraphs[0]
            p.paragraph_format.space_before = Pt(0)
            p.paragraph_format.space_after = Pt(0)
            p.paragraph_format.line_spacing = 1.08
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i == 0 else WD_ALIGN_PARAGRAPH.LEFT
            r = p.add_run(str(value))
            style_run(r, size=font_size, color=DARK)
    set_table_geometry(table, widths)
    after = doc.add_paragraph()
    after.paragraph_format.space_after = Pt(2)
    return table


def add_caption(doc, text):
    p = doc.add_paragraph()
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_before = Pt(3)
    p.paragraph_format.space_after = Pt(7)
    r = p.add_run(text)
    style_run(r, size=9, italic=True, color=GRAY)


def add_picture_with_alt(doc, path, width, title, description):
    """插入图片并写入 Word 可访问性替代文本。"""
    shape = doc.add_picture(str(path), width=width)
    doc_pr = shape._inline.docPr
    doc_pr.set("title", title)
    doc_pr.set("descr", description)
    return shape


def add_callout(doc, title, body, fill=PALE_BLUE, title_color=BLUE):
    table = doc.add_table(rows=1, cols=1)
    cell = table.cell(0, 0)
    set_cell_shading(cell, fill)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(2)
    r = p.add_run(title + "  ")
    style_run(r, size=10, bold=True, color=title_color)
    r = p.add_run(body)
    style_run(r, size=9.5, color=DARK)
    # 单行说明框以标题开头；标记其语义入口，便于屏幕阅读器识别。
    repeat_table_header(table.rows[0])
    set_table_geometry(table, [TABLE_WIDTH_DXA])
    doc.add_paragraph().paragraph_format.space_after = Pt(2)


def add_body(doc, text, bold_prefix=None):
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(0)
    p.paragraph_format.space_after = Pt(6)
    p.paragraph_format.line_spacing = 1.18
    set_repeat_lines(p)
    if bold_prefix and text.startswith(bold_prefix):
        r = p.add_run(bold_prefix)
        style_run(r, bold=True)
        r = p.add_run(text[len(bold_prefix):])
        style_run(r)
    else:
        r = p.add_run(text)
        style_run(r)
    return p


def add_bullet(doc, text, num_id):
    p = doc.add_paragraph()
    p_pr = p._p.get_or_add_pPr()
    num_pr = OxmlElement("w:numPr")
    ilvl = OxmlElement("w:ilvl")
    ilvl.set(qn("w:val"), "0")
    num_id_node = OxmlElement("w:numId")
    num_id_node.set(qn("w:val"), str(num_id))
    num_pr.append(ilvl)
    num_pr.append(num_id_node)
    p_pr.append(num_pr)
    p.paragraph_format.space_after = Pt(4)
    p.paragraph_format.line_spacing = 1.15
    r = p.add_run(text)
    style_run(r)
    return p


def add_numbering(doc):
    numbering = doc.part.numbering_part.element
    existing_abs = [
        int(x.get(qn("w:abstractNumId")))
        for x in numbering.findall(qn("w:abstractNum"))
    ]
    existing_num = [
        int(x.get(qn("w:numId")))
        for x in numbering.findall(qn("w:num"))
    ]
    abstract_id = max(existing_abs + [0]) + 1
    num_id = max(existing_num + [0]) + 1
    abstract = OxmlElement("w:abstractNum")
    abstract.set(qn("w:abstractNumId"), str(abstract_id))
    nsid = OxmlElement("w:nsid")
    nsid.set(qn("w:val"), "4A3B2C1D")
    abstract.append(nsid)
    multi = OxmlElement("w:multiLevelType")
    multi.set(qn("w:val"), "singleLevel")
    abstract.append(multi)
    lvl = OxmlElement("w:lvl")
    lvl.set(qn("w:ilvl"), "0")
    start = OxmlElement("w:start")
    start.set(qn("w:val"), "1")
    num_fmt = OxmlElement("w:numFmt")
    num_fmt.set(qn("w:val"), "bullet")
    lvl_text = OxmlElement("w:lvlText")
    lvl_text.set(qn("w:val"), "•")
    lvl_jc = OxmlElement("w:lvlJc")
    lvl_jc.set(qn("w:val"), "left")
    p_pr = OxmlElement("w:pPr")
    tabs = OxmlElement("w:tabs")
    tab = OxmlElement("w:tab")
    tab.set(qn("w:val"), "num")
    tab.set(qn("w:pos"), "540")
    tabs.append(tab)
    ind = OxmlElement("w:ind")
    ind.set(qn("w:left"), "540")
    ind.set(qn("w:hanging"), "270")
    p_pr.append(tabs)
    p_pr.append(ind)
    r_pr = OxmlElement("w:rPr")
    fonts = OxmlElement("w:rFonts")
    fonts.set(qn("w:ascii"), "Calibri")
    fonts.set(qn("w:hAnsi"), "Calibri")
    r_pr.append(fonts)
    for node in (start, num_fmt, lvl_text, lvl_jc, p_pr, r_pr):
        lvl.append(node)
    abstract.append(lvl)
    numbering.append(abstract)
    num = OxmlElement("w:num")
    num.set(qn("w:numId"), str(num_id))
    abs_id = OxmlElement("w:abstractNumId")
    abs_id.set(qn("w:val"), str(abstract_id))
    num.append(abs_id)
    numbering.append(num)
    return num_id


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("第 ")
    style_run(run, size=8.5, color=GRAY)
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr = OxmlElement("w:instrText")
    instr.set(qn("xml:space"), "preserve")
    instr.text = "PAGE"
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.append(fld_char1)
    run._r.append(instr)
    run._r.append(fld_char2)
    r2 = paragraph.add_run(" 页")
    style_run(r2, size=8.5, color=GRAY)


def configure_styles(doc):
    styles = doc.styles
    normal = styles["Normal"]
    normal.font.name = "Calibri"
    normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
    normal.font.size = Pt(10.5)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.18
    for name, size, color, before, after in (
        ("Title", 24, DARK_BLUE, 0, 6),
        ("Subtitle", 13, GRAY, 0, 12),
        ("Heading 1", 16, BLUE, 18, 10),
        ("Heading 2", 13, BLUE, 14, 7),
        ("Heading 3", 11.5, DARK_BLUE, 10, 5),
    ):
        st = styles[name]
        st.font.name = "Calibri"
        st._element.rPr.rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
        st.font.size = Pt(size)
        st.font.color.rgb = RGBColor.from_string(color)
        st.font.bold = name != "Subtitle"
        st.paragraph_format.space_before = Pt(before)
        st.paragraph_format.space_after = Pt(after)
        st.paragraph_format.keep_with_next = True
    if "Figure Caption" not in [s.name for s in styles]:
        st = styles.add_style("Figure Caption", WD_STYLE_TYPE.PARAGRAPH)
        st.font.name = "Calibri"
        st._element.rPr.rFonts.set(qn("w:eastAsia"), "Microsoft YaHei")
        st.font.size = Pt(9)
        st.font.italic = True
        st.font.color.rgb = RGBColor.from_string(GRAY)


def draw_box(ax, xy, width, height, title, lines=(), fill="#EEF5FB", edge="#1F4E79"):
    x, y = xy
    box = FancyBboxPatch(
        (x, y), width, height, boxstyle="round,pad=0.015,rounding_size=0.015",
        linewidth=1.4, edgecolor=edge, facecolor=fill
    )
    ax.add_patch(box)
    ax.text(x + width / 2, y + height - 0.06, title, ha="center", va="top",
            fontsize=10.5, fontweight="bold", color="#17365D", fontproperties=CJK)
    if lines:
        ax.text(x + 0.02, y + height - 0.16, "\n".join(lines), ha="left", va="top",
                fontsize=8.2, color="#222222", linespacing=1.35, fontproperties=CJK)
    return box


def arrow(ax, start, end, text="", color="#1F4E79", rad=0.0):
    a = FancyArrowPatch(start, end, arrowstyle="-|>", mutation_scale=12,
                        linewidth=1.5, color=color,
                        connectionstyle=f"arc3,rad={rad}")
    ax.add_patch(a)
    if text:
        mx, my = (start[0] + end[0]) / 2, (start[1] + end[1]) / 2
        ax.text(mx, my + 0.025, text, ha="center", va="bottom", fontsize=8,
                color=color, fontproperties=CJK,
                bbox=dict(facecolor="white", edgecolor="none", pad=1))


def save_architecture():
    fig, ax = plt.subplots(figsize=(10.8, 6.2))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    draw_box(ax, (0.02, 0.30), 0.16, 0.38, "Host / CPU", ["驱动与应用", "PCIe Root Complex", "Host Memory"], "#F2F4F7", "#666666")
    draw_box(ax, (0.25, 0.18), 0.18, 0.62, "XDMA / design_1", ["Gen3 x2", "H2C/C2H：1 ch", "AXI 64 bit @ 250 MHz", "User BAR + Control BAR"], "#E8F1F8")
    draw_box(ax, (0.50, 0.18), 0.19, 0.62, "PCIe.v 集成层", ["INFO_EXCH", "CONV_DMA", "BRAM/AXI Interconnect", "IRQ / MSI 接口", "ILA 探针源"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.75, 0.18), 0.22, 0.62, "Adapter + Aurora", ["pcie_fdma_aurora_brg_adapter", "FDMA TX/RX bridge", "CDC + FIFO", "LocalLink 64 bit", "Aurora 64B/66B + GT"], "#FFF4DD", "#8A6D1D")
    arrow(ax, (0.18, 0.57), (0.25, 0.57), "PCIe TLP")
    arrow(ax, (0.25, 0.40), (0.18, 0.40), "MSI / C2H")
    arrow(ax, (0.43, 0.60), (0.50, 0.60), "AXI-MM")
    arrow(ax, (0.50, 0.39), (0.43, 0.39), "AXI-Lite")
    arrow(ax, (0.69, 0.60), (0.75, 0.60), "FDMA read")
    arrow(ax, (0.75, 0.39), (0.69, 0.39), "FDMA write / IRQ")
    ax.text(0.5, 0.93, "RTDS_test-1ch 生产设计总体架构", ha="center", va="center",
            fontsize=15, fontweight="bold", color="#17365D", fontproperties=CJK)
    ax.text(0.5, 0.07, "注：大仿真顶层直接实例化 PCIe，不实例化 TOP 中的官方 Aurora 64B/66B/GT。",
            ha="center", fontsize=9, color="#666666", fontproperties=CJK)
    path = ASSET_DIR / "architecture.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_sim_architecture():
    fig, ax = plt.subplots(figsize=(10.8, 6.2))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    draw_box(ax, (0.03, 0.28), 0.23, 0.48, "官方 Root Port / TPI", ["xilinx_pcie3_uscale_rp", "pci_exp_usrapp_tx/rx/cfg", "枚举、BAR、配置空间", "Host DATA_STORE（读数据源）"], "#E8F1F8")
    draw_box(ax, (0.37, 0.26), 0.26, 0.52, "真实 RTDS Endpoint", ["rtds_pcie_ep_sim_wrapper", "PCIe / design_1 / xdma_0", "CONV_DMA + INFO_EXCH", "Adapter + 生产 RTL"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.74, 0.53), 0.22, 0.25, "Aurora LL Peer BFM", ["消费 FPGA→Aurora", "注入 Aurora→FPGA", "RX 不支持 FPGA 反压"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.74, 0.20), 0.22, 0.24, "Monitor / Scoreboard", ["CQ Host-memory sink", "AXI activity monitor", "IRQ bind monitor", "Assertions + compare_logs"], "#FDECEC", "#A61B1B")
    arrow(ax, (0.26, 0.61), (0.37, 0.61), "PCIe x2 serial")
    arrow(ax, (0.37, 0.43), (0.26, 0.43), "C2H Memory Write")
    arrow(ax, (0.63, 0.62), (0.74, 0.65), "LocalLink")
    arrow(ax, (0.74, 0.57), (0.63, 0.52), "LocalLink")
    arrow(ax, (0.63, 0.36), (0.74, 0.32), "内部观测")
    arrow(ax, (0.26, 0.33), (0.74, 0.28), "m_axis_cq payload", color="#A61B1B", rad=-0.10)
    ax.text(0.5, 0.92, "XDMA Root Port 大仿真验证环境", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    path = ASSET_DIR / "simulation_architecture.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_data_flow():
    fig, axes = plt.subplots(2, 1, figsize=(10.8, 7.2))
    for ax in axes:
        ax.set_xlim(0, 1)
        ax.set_ylim(0, 1)
        ax.axis("off")
    ax = axes[0]
    ax.text(0.01, 0.92, "A. CPU → Aurora", fontsize=12, fontweight="bold", color="#17365D", fontproperties=CJK)
    labels = [("Host Memory", "0x400"), ("XDMA H2C", "1 ch"), ("Card Buffer", "0x8000"), ("FDMA Read", "64×64 bit"), ("Aurora TX", "SOF…EOF")]
    xs = [0.02, 0.22, 0.42, 0.62, 0.82]
    for x, (t, s) in zip(xs, labels):
        draw_box(ax, (x, 0.35), 0.15, 0.34, t, [s], "#EEF5FB")
    for i in range(len(xs) - 1):
        arrow(ax, (xs[i] + 0.15, 0.52), (xs[i + 1], 0.52))
    ax.text(0.5, 0.18, "INFO_EXCH：0x24=0x8000，0x28=512，0x20 执行 0→1→0；完成后 CPU_WR_DONE_resp 回落。",
            ha="center", fontsize=8.6, color="#555555", fontproperties=CJK)
    ax = axes[1]
    ax.text(0.01, 0.92, "B. Aurora → CPU", fontsize=12, fontweight="bold", color="#17365D", fontproperties=CJK)
    labels = [("Aurora RX", "512 B 连续源"), ("FDMA Write", "64×64 bit"), ("Card Buffer", "0x0000"), ("XDMA C2H", "1 ch"), ("Host Memory", "0x800")]
    for x, (t, s) in zip(xs, labels):
        draw_box(ax, (x, 0.35), 0.15, 0.34, t, [s], "#FFF4DD", "#8A6D1D")
    for i in range(len(xs) - 1):
        arrow(ax, (xs[i] + 0.15, 0.52), (xs[i + 1], 0.52), color="#8A6D1D")
    ax.text(0.5, 0.18, "接收完成：0x18=0，0x1C=512，usr_irq_req→MSI→usr_irq_ack；读 0x10 清中断，0x14 执行 1→0 重新武装。",
            ha="center", fontsize=8.6, color="#555555", fontproperties=CJK)
    path = ASSET_DIR / "data_flow.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_timing():
    fig, axes = plt.subplots(2, 1, figsize=(11, 7.5))
    sequences = [
        (
            "CPU → Aurora 关键时序",
            ["BAR write 0x24/0x28", "CPU_WR_DONE", "fdma_rareq / rbusy", "fdma_rvalid & rready", "LL src_rdy / dst_rdy", "SOF / EOF", "CPU_WR_DONE_resp"],
            [
                [(0.05, 0), (0.12, 1), (0.20, 0)],
                [(0.18, 0), (0.24, 1), (0.30, 0)],
                [(0.28, 0), (0.34, 1), (0.42, 0)],
                [(0.39, 0), (0.46, 1), (0.68, 1), (0.72, 0)],
                [(0.48, 0), (0.52, 1), (0.79, 1), (0.83, 0)],
                [(0.52, 0), (0.54, 1), (0.56, 0), (0.78, 0), (0.80, 1), (0.82, 0)],
                [(0.24, 0), (0.28, 1), (0.81, 1), (0.86, 0)],
            ],
            "#1F4E79",
        ),
        (
            "Aurora → CPU / MSI 关键时序",
            ["RX src_rdy（不可反压）", "fdma_wareq / wbusy", "fdma_w_source_valid", "fdma_w_accept", "FPGA_CPU_irq_req", "usr_irq_ack", "读 INFO 0x10", "CPU_REC_STATE 1→0"],
            [
                [(0.05, 0), (0.10, 1), (0.36, 1), (0.40, 0)],
                [(0.30, 0), (0.36, 1), (0.44, 0)],
                [(0.34, 0), (0.38, 1), (0.58, 1), (0.62, 0)],
                [(0.38, 0), (0.42, 1), (0.60, 1), (0.64, 0)],
                [(0.61, 0), (0.66, 1), (0.84, 1), (0.88, 0)],
                [(0.69, 0), (0.72, 1), (0.75, 0)],
                [(0.78, 0), (0.82, 1), (0.85, 0)],
                [(0.87, 0), (0.90, 1), (0.94, 0)],
            ],
            "#8A6D1D",
        ),
    ]
    for ax, (title, names, waves, color) in zip(axes, sequences):
        ax.set_xlim(0, 1)
        ax.set_ylim(-0.5, len(names) + 0.8)
        ax.axis("off")
        ax.text(0.0, len(names) + 0.42, title, fontsize=12, fontweight="bold", color="#17365D", fontproperties=CJK)
        for idx, (name, pts) in enumerate(zip(names, waves)):
            y = len(names) - idx - 1
            ax.text(0.0, y + 0.25, name, ha="left", va="center", fontsize=8.3, fontproperties=CJK)
            xoff = 0.24
            scale = 0.72
            xs, ys = [], []
            for x, v in pts:
                xs.append(xoff + scale * x)
                ys.append(y + 0.12 + 0.28 * v)
            ax.step(xs, ys, where="post", color=color, linewidth=1.5)
            ax.hlines(y + 0.12, xoff, xoff + scale, color="#DDDDDD", linewidth=0.5)
        ax.text(0.24, -0.25, "时间 →", fontsize=8.5, color="#666666", fontproperties=CJK)
    path = ASSET_DIR / "timing.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_pcie_internal_architecture():
    fig, ax = plt.subplots(figsize=(11.2, 7.0))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.95, "PCIe.v 内部子模块与语义边界", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.03, 0.60), 0.20, 0.25, "板级 PCIe 边界",
             ["MGT RX/TX x2", "100 MHz refclk", "PERST# / user_lnk_up"], "#E8F1F8")
    draw_box(ax, (0.03, 0.18), 0.20, 0.25, "Aurora LocalLink 边界",
             ["64-bit TX/RX", "SOF / EOF / REM", "src_rdy / dst_rdy"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.34, 0.54), 0.28, 0.34, "design_1_wrapper",
             ["XDMA Endpoint", "INFO_EXCH 寄存器", "CONV_DMA + BRAM/AXI", "user IRQ / MSI"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.34, 0.10), 0.28, 0.33, "pcie_fdma_aurora_brg_adapter",
             ["命令/窗口校验", "FDMA read/write", "双时钟 bridge + CDC", "IRQ / ownership / sticky"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.73, 0.54), 0.23, 0.25, "ila_FDMA",
             ["fdma_clk 采样", "地址/请求/数据/size", "RX/TX 状态码"], "#FDECEC", "#A61B1B")
    arrow(ax, (0.23, 0.72), (0.34, 0.72), "PCIe PHY / link")
    arrow(ax, (0.34, 0.64), (0.23, 0.64), "user_lnk_up")
    arrow(ax, (0.48, 0.54), (0.48, 0.43), "INFO + FDMA")
    arrow(ax, (0.43, 0.43), (0.43, 0.54), "IRQ / status", color="#8A6D1D")
    arrow(ax, (0.34, 0.27), (0.23, 0.27), "LL TX")
    arrow(ax, (0.23, 0.20), (0.34, 0.20), "LL RX", color="#8A6D1D")
    arrow(ax, (0.62, 0.68), (0.73, 0.68), "probe0..13", color="#A61B1B")
    ax.text(0.50, 0.025,
            "边界原则：PCIe.v 只做参数固化、语义改名和子模块连线；跨域、帧控制、所有权与错误锁存全部在 adapter 内完成。",
            ha="center", fontsize=8.8, color="#555555", fontproperties=CJK)
    path = ASSET_DIR / "pcie_internal_architecture.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_fdma_write_semantic_wiring():
    fig, ax = plt.subplots(figsize=(11.2, 4.6))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.92, "FDMA write 历史端口名与真实握手语义", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.05, 0.28), 0.27, 0.42, "Adapter / RX bridge",
             ["fdma_wdata[63:0]", "fdma_wvalid", "fdma_wready", "标准 valid/ready 语义"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.68, 0.28), 0.27, 0.42, "design_1 / CONV_DMA",
             ["fdma_wdata_0", "fdma_wready_0（输入）", "fdma_wvalid_0（输出）", "历史命名不可按字面理解"], "#E6F3EA", "#2F6B3C")
    arrow(ax, (0.32, 0.61), (0.68, 0.61), "fdma_wdata → fdma_wdata_0")
    arrow(ax, (0.32, 0.49), (0.68, 0.49), "fdma_wvalid → fdma_wready_0\n= fdma_w_source_valid", color="#8A6D1D")
    arrow(ax, (0.68, 0.35), (0.32, 0.35), "fdma_wvalid_0 → fdma_wready\n= fdma_w_accept", color="#2F6B3C")
    ax.text(0.5, 0.13, "数据提交条件始终是：fdma_w_source_valid && fdma_w_accept",
            ha="center", fontsize=10, fontweight="bold", color="#A61B1B", fontproperties=CJK)
    ax.text(0.5, 0.055, "PCIe.v 用语义名隔离历史端口名；禁止把同名 valid/ready 直接相连。",
            ha="center", fontsize=8.8, color="#555555", fontproperties=CJK)
    path = ASSET_DIR / "fdma_write_semantic_wiring.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_adapter_internal_architecture():
    fig, ax = plt.subplots(figsize=(11.4, 7.3))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.96, "pcie_fdma_aurora_brg_adapter 功能电路分层", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    ax.add_patch(FancyBboxPatch((0.02, 0.08), 0.46, 0.80, boxstyle="round,pad=0.01",
                                facecolor="#EEF5FB", edgecolor="#1F4E79", linewidth=1.2))
    ax.add_patch(FancyBboxPatch((0.52, 0.08), 0.46, 0.80, boxstyle="round,pad=0.01",
                                facecolor="#FFF8E8", edgecolor="#8A6D1D", linewidth=1.2))
    ax.text(0.25, 0.86, "fdma_clk 域（控制、FDMA、IRQ）", ha="center", fontsize=11,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    ax.text(0.75, 0.86, "aurora_user_clk 域（LocalLink、帧检查）", ha="center", fontsize=11,
            fontweight="bold", color="#8A6D1D", fontproperties=CJK)
    draw_box(ax, (0.05, 0.64), 0.18, 0.14, "TX 命令校验", ["对齐/窗口/链路", "tx_active 所有权"], "#FFFFFF")
    draw_box(ax, (0.27, 0.64), 0.18, 0.14, "TX 事务寄存器", ["base / target", "completed / resp"], "#FFFFFF")
    draw_box(ax, (0.05, 0.40), 0.40, 0.16, "fdma_aurora_brg_tx：FDMA read 侧", ["rareq/rbusy", "rvalid/rready", "异步 FIFO 写侧"], "#FFFFFF")
    draw_box(ax, (0.55, 0.40), 0.40, 0.16, "fdma_aurora_brg_tx：LocalLink TX 侧", ["异步 FIFO 读侧", "SOF/EOF/REM", "dst_rdy 背压保持"], "#FFFFFF", "#8A6D1D")
    draw_box(ax, (0.55, 0.64), 0.18, 0.14, "RX 帧检查", ["64 beat", "SOF/EOF/rem"], "#FFFFFF", "#8A6D1D")
    draw_box(ax, (0.77, 0.64), 0.18, 0.14, "User-domain sticky", ["overflow", "underflow/length"], "#FFFFFF", "#8A6D1D")
    draw_box(ax, (0.55, 0.18), 0.40, 0.15, "fdma_aurora_brg_rx：LocalLink RX 侧", ["src_rdy/dst_rdy", "异步 FIFO 写侧", "水位/overflow"], "#FFFFFF", "#8A6D1D")
    draw_box(ax, (0.05, 0.18), 0.18, 0.15, "FDMA write 侧", ["wareq/wbusy", "wvalid/wready"], "#FFFFFF")
    draw_box(ax, (0.27, 0.18), 0.18, 0.15, "RX 所有权/IRQ", ["rx_pending", "addr/len/INT"], "#FFFFFF")
    draw_box(ax, (0.05, 0.02), 0.40, 0.10, "Sticky + progress-aware timeout", ["clear hold / link_down / wait_count"], "#FDECEC", "#A61B1B")
    arrow(ax, (0.23, 0.71), (0.27, 0.71), "start")
    arrow(ax, (0.36, 0.64), (0.28, 0.56), "base/limit")
    arrow(ax, (0.45, 0.48), (0.55, 0.48), "64-bit async FIFO")
    arrow(ax, (0.55, 0.255), (0.45, 0.255), "64-bit async FIFO", color="#8A6D1D")
    arrow(ax, (0.23, 0.255), (0.27, 0.255), "burst_done")
    arrow(ax, (0.64, 0.40), (0.64, 0.33), "RX stream", color="#8A6D1D")
    arrow(ax, (0.73, 0.71), (0.77, 0.71), "errors", color="#A61B1B")
    path = ASSET_DIR / "adapter_internal_architecture.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_adapter_cdc_architecture():
    fig, ax = plt.subplots(figsize=(11.3, 6.5))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.95, "Adapter 跨时钟域结构与同步模式", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.04, 0.12), 0.27, 0.72, "fdma_clk 域",
             ["pcie_link_up", "rd_start / INFO", "FDMA read/write", "IRQ / sticky", "250 MHz"], "#EEF5FB")
    draw_box(ax, (0.69, 0.12), 0.27, 0.72, "aurora_user_clk 域",
             ["channel_up / lane_up", "LocalLink TX/RX", "frame checker", "user sticky", "156.25 MHz"], "#FFF4DD", "#8A6D1D")
    crossings = [
        (0.77, "pcie_link_up → user", "xpm_cdc_single / level", "#1F4E79"),
        (0.66, "channel_up, lane_up → fdma", "xpm_cdc_single / level", "#8A6D1D"),
        (0.55, "tx_active → user", "xpm_cdc_single / level", "#1F4E79"),
        (0.44, "tx_frame_done → fdma", "toggle → sync → XOR pulse", "#8A6D1D"),
        (0.33, "clear_inter → user", "toggle → sync → XOR pulse", "#1F4E79"),
        (0.22, "waterline/error sticky → fdma", "xpm_cdc_single / level", "#8A6D1D"),
    ]
    for y, name, method, color in crossings:
        ax.hlines(y, 0.31, 0.69, color=color, linewidth=1.7)
        ax.plot([0.31 if "→ user" in name else 0.69], [y], marker=">" if "→ user" in name else "<",
                markersize=7, color=color)
        ax.text(0.50, y + 0.018, name, ha="center", va="bottom", fontsize=8.7,
                color=color, fontproperties=CJK, bbox=dict(facecolor="white", edgecolor="none", pad=1))
        ax.text(0.50, y - 0.018, method, ha="center", va="top", fontsize=7.7,
                color="#555555", fontproperties=CJK)
    ax.text(0.5, 0.055, "多比特 payload 不走单比特同步器，只通过 TX/RX XPM async FIFO 跨域。",
            ha="center", fontsize=9.5, fontweight="bold", color="#A61B1B", fontproperties=CJK)
    path = ASSET_DIR / "adapter_cdc_architecture.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_tx_validation_flow():
    fig, ax = plt.subplots(figsize=(11.0, 6.2))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.95, "TX 软件命令接管与事务控制逻辑", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.05, 0.68), 0.18, 0.15, "rd_start=1", ["地址/长度已稳定"], "#EEF5FB")
    draw_box(ax, (0.31, 0.64), 0.31, 0.23, "组合合法性检查",
             ["len != 0", "addr/len 按 512B 对齐", "len <= 32KiB", "start >= 0x8000", "33-bit end <= window_end"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.70, 0.68), 0.25, 0.15, "放行条件", ["!tx_active", "link_up_fdma", "tx_config_valid"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.70, 0.39), 0.25, 0.18, "接管命令", ["锁存 base/target", "tx_active=1", "resp=1", "释放 TX bridge reset"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.31, 0.36), 0.31, 0.22, "活动事务", ["FDMA read 逐帧", "仅 LL EOF 真握手计完成", "completed+1 >= target 时结束"], "#EEF5FB")
    draw_box(ax, (0.05, 0.40), 0.18, 0.15, "拒绝/告警", ["配置/忙：length_error", "链路：link_down"], "#FDECEC", "#A61B1B")
    draw_box(ax, (0.31, 0.10), 0.31, 0.15, "正常完成", ["tx_active=0", "target/completed=0", "resp=0"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.70, 0.10), 0.25, 0.15, "活动期掉链", ["立即终止", "清事务寄存器", "link_down_sticky=1"], "#FDECEC", "#A61B1B")
    arrow(ax, (0.23, 0.75), (0.31, 0.75))
    arrow(ax, (0.62, 0.75), (0.70, 0.75), "valid")
    arrow(ax, (0.82, 0.68), (0.82, 0.57), "accept")
    arrow(ax, (0.70, 0.48), (0.62, 0.48))
    arrow(ax, (0.47, 0.36), (0.47, 0.25), "最后一帧")
    arrow(ax, (0.62, 0.42), (0.70, 0.20), "link down", color="#A61B1B")
    arrow(ax, (0.31, 0.68), (0.23, 0.50), "invalid/busy", color="#A61B1B")
    path = ASSET_DIR / "tx_validation_flow.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_rx_ownership_logic():
    fig, ax = plt.subplots(figsize=(11.1, 5.8))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.94, "RX 缓冲区所有权、通知与中断电路", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.04, 0.55), 0.20, 0.20, "rx_burst_done_fdma", ["完整 512B 已落盘", "不是 Aurora EOF"], "#EEF5FB")
    draw_box(ax, (0.33, 0.51), 0.25, 0.28, "所有权判定", ["!rx_pending_r", "或同拍 cpu_rec_ack", "才允许发布新通知"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.68, 0.58), 0.27, 0.24, "发布给 CPU", ["start=RX_BASE+raw", "len=512", "irq_req/int_state=1", "rx_pending=1"], "#E6F3EA", "#2F6B3C")
    draw_box(ax, (0.68, 0.27), 0.27, 0.18, "前帧未释放", ["保持旧地址/长度/IRQ语义", "rx_overrun_sticky=1"], "#FDECEC", "#A61B1B")
    draw_box(ax, (0.33, 0.15), 0.25, 0.20, "CPU_REC_STATE 上升沿", ["cpu_rec_ack=R & !R_d", "清 pending/overrun"], "#EEF5FB")
    draw_box(ax, (0.04, 0.15), 0.20, 0.20, "INT clear", ["int_state_clear", "或 clear_inter", "只清 IRQ/INT"], "#EEF5FB")
    arrow(ax, (0.24, 0.65), (0.33, 0.65))
    arrow(ax, (0.58, 0.67), (0.68, 0.69), "可发布")
    arrow(ax, (0.58, 0.55), (0.68, 0.36), "pending", color="#A61B1B")
    arrow(ax, (0.45, 0.35), (0.45, 0.51), "释放所有权")
    arrow(ax, (0.24, 0.25), (0.68, 0.58), "清中断，不清 pending", color="#1F4E79", rad=0.18)
    ax.text(0.5, 0.055, "中断应答与缓冲区归还是两个独立动作：先清 IRQ，再完成 C2H，最后归还 ownership。",
            ha="center", fontsize=9.2, fontweight="bold", color="#A61B1B", fontproperties=CJK)
    path = ASSET_DIR / "rx_ownership_logic.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_error_aggregation_logic():
    fig, ax = plt.subplots(figsize=(11.2, 6.3))
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    ax.text(0.5, 0.95, "错误状态汇聚、清除抑制与 FDMA 超时", ha="center", fontsize=15,
            fontweight="bold", color="#17365D", fontproperties=CJK)
    draw_box(ax, (0.03, 0.62), 0.22, 0.23, "Aurora 域错误源", ["RX overflow/not-ready", "TX underflow", "RX frame length/SOF/EOF/rem"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.03, 0.25), 0.22, 0.23, "FDMA 域错误源", ["TX config/busy", "start/down link", "active link drop", "waiting without progress"], "#EEF5FB")
    draw_box(ax, (0.34, 0.62), 0.24, 0.23, "源域 sticky + CDC", ["clear toggle 到 user", "level sync 回 fdma", "旧高电平可能滞后"], "#FFF4DD", "#8A6D1D")
    draw_box(ax, (0.34, 0.25), 0.24, 0.23, "等待/进展判定", ["waiting：req 或等数据", "progress：accept/beat/done", "progress 或 idle 清计数"], "#EEF5FB")
    draw_box(ax, (0.68, 0.55), 0.28, 0.30, "FDMA 域最终 sticky", ["rx_overflow", "tx_underflow", "length_error", "fdma_timeout", "link_down"], "#FDECEC", "#A61B1B")
    draw_box(ax, (0.68, 0.20), 0.28, 0.22, "clear_inter 行为", ["清最终 sticky/wait_count", "user_status_clear_hold=1", "源域全回 0 后重新吸收"], "#E6F3EA", "#2F6B3C")
    arrow(ax, (0.25, 0.73), (0.34, 0.73), "源域锁存")
    arrow(ax, (0.58, 0.73), (0.68, 0.70), "sync level")
    arrow(ax, (0.25, 0.36), (0.34, 0.36))
    arrow(ax, (0.58, 0.36), (0.68, 0.61), "timeout/config/link", color="#A61B1B")
    arrow(ax, (0.82, 0.42), (0.82, 0.55), "清零 + hold", color="#2F6B3C")
    arrow(ax, (0.68, 0.29), (0.58, 0.65), "toggle 清源域", color="#2F6B3C", rad=0.12)
    path = ASSET_DIR / "error_aggregation_logic.png"
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_waveform_detail(title, names, waves, filename, notes, color="#1F4E79"):
    fig, ax = plt.subplots(figsize=(11.3, 5.4))
    ax.set_xlim(0, 1)
    ax.set_ylim(-0.75, len(names) + 0.8)
    ax.axis("off")
    ax.text(0.0, len(names) + 0.42, title, fontsize=13.5, fontweight="bold",
            color="#17365D", fontproperties=CJK)
    xoff = 0.28
    scale = 0.68
    for idx, (name, pts) in enumerate(zip(names, waves)):
        y = len(names) - idx - 1
        ax.text(0.0, y + 0.24, name, ha="left", va="center", fontsize=8.2, fontproperties=CJK)
        xs = [xoff + scale * x for x, _ in pts]
        ys = [y + 0.12 + 0.30 * v for _, v in pts]
        ax.step(xs, ys, where="post", color=color, linewidth=1.55)
        ax.hlines(y + 0.12, xoff, xoff + scale, color="#DDDDDD", linewidth=0.55)
    for x, label in notes:
        xpos = xoff + scale * x
        ax.axvline(xpos, ymin=0.04, ymax=0.93, color="#A61B1B", linewidth=0.8, linestyle="--")
        ax.text(xpos, -0.42, label, ha="center", va="top", fontsize=7.7,
                color="#A61B1B", fontproperties=CJK)
    ax.text(xoff, -0.64, "时间 →（跨时钟域图仅表达先后关系，不按实际频率比例）",
            fontsize=8.2, color="#666666", fontproperties=CJK)
    path = ASSET_DIR / filename
    fig.tight_layout()
    fig.savefig(path, dpi=180, bbox_inches="tight")
    plt.close(fig)
    return path


def save_detailed_timings():
    return {
        "tx_cmd": save_waveform_detail(
            "TX 命令接管与 FDMA read 请求时序",
            ["rd_start", "tx_config_valid", "tx_start_valid", "tx_active / resp", "fdma_rareq", "fdma_rbusy", "fdma_rvalid", "fdma_rready"],
            [[(0.03,0),(0.12,1),(0.20,0)],[(0.00,1),(0.96,1)],[(0.03,0),(0.12,1),(0.20,0)],
             [(0.03,0),(0.13,1),(0.92,1),(0.96,0)],[(0.18,0),(0.26,1),(0.40,1),(0.43,0)],
             [(0.20,0),(0.36,1),(0.86,1),(0.90,0)],[(0.38,0),(0.47,1),(0.83,1),(0.87,0)],
             [(0.38,0),(0.44,1),(0.83,1),(0.87,0)]],
            "timing_tx_command_fdma.png", [(0.13,"锁存命令"),(0.36,"请求接受"),(0.83,"第64 beat")]),
        "tx_backpressure": save_waveform_detail(
            "Aurora TX 背压、末拍完成与 toggle CDC",
            ["aurora_tx_src_rdy", "aurora_tx_dst_rdy", "TX data/SOF/EOF 稳定", "tx_frame_done_user", "tx_done_toggle_user", "tx_done_toggle_fdma", "tx_frame_done_fdma", "tx_completed_frames"],
            [[(0.05,0),(0.12,1),(0.76,1),(0.80,0)],[(0.00,1),(0.30,1),(0.30,0),(0.47,0),(0.47,1),(0.82,1)],
             [(0.05,0),(0.30,1),(0.47,1),(0.76,1),(0.80,0)],[(0.70,0),(0.76,1),(0.80,0)],
             [(0.00,0),(0.76,1),(0.98,1)],[(0.00,0),(0.82,1),(0.98,1)],[(0.00,0),(0.82,1),(0.86,0)],
             [(0.00,0),(0.83,1),(0.98,1)]],
            "timing_tx_backpressure_toggle.png", [(0.30,"dst_rdy=0"),(0.47,"恢复握手"),(0.76,"EOF握手"),(0.82,"FDMA域完成")], "#8A6D1D"),
        "rx_write": save_waveform_detail(
            "Aurora RX、FDMA write 与通知发布时序",
            ["RX src_rdy", "RX SOF", "RX EOF/rem=111", "fdma_wareq", "fdma_wbusy", "fdma_wvalid", "fdma_wready", "rx_burst_done_fdma", "IRQ / INT / pending"],
            [[(0.03,0),(0.09,1),(0.40,1),(0.43,0)],[(0.07,0),(0.09,1),(0.12,0)],[(0.36,0),(0.40,1),(0.43,0)],
             [(0.33,0),(0.42,1),(0.51,1),(0.54,0)],[(0.40,0),(0.49,1),(0.83,1),(0.86,0)],
             [(0.47,0),(0.55,1),(0.80,1),(0.84,0)],[(0.47,0),(0.58,1),(0.80,1),(0.84,0)],
             [(0.80,0),(0.84,1),(0.87,0)],[(0.80,0),(0.85,1),(0.98,1)]],
            "timing_rx_write_notify.png", [(0.09,"SOF"),(0.40,"EOF"),(0.49,"write接受"),(0.84,"完整落盘"),(0.85,"发布通知")], "#8A6D1D"),
        "irq_ownership": save_waveform_detail(
            "IRQ 清除与 RX buffer 所有权归还时序",
            ["rx_burst_done", "fpga_cpu_irq_req", "int_state_w", "int_state_clear / clear_inter", "rx_pending", "C2H 读取窗口", "cpu_rec_state_r", "cpu_rec_ack", "rx_overrun_sticky"],
            [[(0.04,0),(0.10,1),(0.14,0)],[(0.04,0),(0.11,1),(0.42,1),(0.46,0)],[(0.04,0),(0.11,1),(0.42,1),(0.46,0)],
             [(0.38,0),(0.42,1),(0.46,0)],[(0.04,0),(0.11,1),(0.82,1),(0.86,0)],[(0.50,0),(0.57,1),(0.72,1),(0.76,0)],
             [(0.76,0),(0.82,1),(0.90,1),(0.94,0)],[(0.76,0),(0.82,1),(0.86,0)],[(0.00,0),(0.98,0)]],
            "timing_irq_ownership.png", [(0.11,"ownership给CPU"),(0.42,"只清中断"),(0.57,"C2H"),(0.82,"归还buffer")]),
        "clear_hold": save_waveform_detail(
            "clear_inter 的 toggle CDC 与旧 sticky 高电平抑制",
            ["clear_inter", "status_clear_toggle_fdma", "status_clear_toggle_user", "status_clear_user", "user sticky source", "synced sticky in fdma", "user_status_clear_hold", "final sticky"],
            [[(0.04,0),(0.10,1),(0.16,0)],[(0.00,0),(0.10,1),(0.98,1)],[(0.00,0),(0.27,1),(0.98,1)],
             [(0.00,0),(0.27,1),(0.33,0)],[(0.00,1),(0.34,1),(0.38,0),(0.98,0)],[(0.00,1),(0.48,1),(0.53,0),(0.98,0)],
             [(0.00,0),(0.10,1),(0.54,1),(0.58,0)],[(0.00,1),(0.10,0),(0.98,0)]],
            "timing_clear_hold.png", [(0.10,"FDMA域先清"),(0.27,"user域收到clear"),(0.53,"旧高电平消失"),(0.58,"重新允许置位")], "#2F6B3C"),
        "timeout": save_waveform_detail(
            "FDMA progress-aware timeout 计数规则",
            ["fdma_waiting", "fdma_progress", "fdma_wait_count", "fdma_timeout_sticky", "clear_inter"],
            [[(0.02,0),(0.10,1),(0.43,1),(0.50,0),(0.58,1),(0.88,1),(0.92,0)],
             [(0.02,0),(0.30,1),(0.35,0),(0.58,0),(0.88,0),(0.92,0)],[(0.02,0),(0.10,1),(0.30,1),(0.31,0),(0.58,1),(0.82,1),(0.83,0)],
             [(0.02,0),(0.80,0),(0.82,1),(0.95,1)],[(0.88,0),(0.92,1),(0.96,0)]],
            "timing_fdma_timeout.png", [(0.10,"开始等待"),(0.30,"有progress→清零"),(0.58,"再次等待"),(0.82,"达到门槛"),(0.92,"clear")], "#A61B1B"),
    }


def add_heading(doc, text, level=1):
    p = doc.add_paragraph(text, style=f"Heading {level}")
    set_repeat_together(p)
    return p


def build_document():
    arch = save_architecture()
    sim_arch = save_sim_architecture()
    flow = save_data_flow()
    timing = save_timing()
    pcie_arch = save_pcie_internal_architecture()
    fdma_write_wiring = save_fdma_write_semantic_wiring()
    adapter_arch = save_adapter_internal_architecture()
    adapter_cdc = save_adapter_cdc_architecture()
    tx_validation = save_tx_validation_flow()
    rx_ownership = save_rx_ownership_logic()
    error_aggregation = save_error_aggregation_logic()
    detailed_timings = save_detailed_timings()

    doc = Document()
    section = doc.sections[0]
    section.page_width = Inches(8.5)
    section.page_height = Inches(11)
    section.top_margin = Inches(0.85)
    section.bottom_margin = Inches(0.8)
    section.left_margin = Inches(1.0)
    section.right_margin = Inches(1.0)
    section.header_distance = Inches(0.35)
    section.footer_distance = Inches(0.35)
    configure_styles(doc)
    bullet_num_id = add_numbering(doc)

    header = section.header
    hp = header.paragraphs[0]
    hp.alignment = WD_ALIGN_PARAGRAPH.LEFT
    hr = hp.add_run("RTDS_test-1ch · XDMA / Aurora 设计与验证规格")
    style_run(hr, size=8.5, color=GRAY)
    footer = section.footer
    add_page_number(footer.paragraphs[0])

    # Cover / memo masthead
    p = doc.add_paragraph()
    p.paragraph_format.space_before = Pt(22)
    p.paragraph_format.space_after = Pt(3)
    r = p.add_run("TECHNICAL DESIGN SPECIFICATION")
    style_run(r, size=9.5, bold=True, color=MID_BLUE)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(5)
    r = p.add_run("RTDS_test-1ch XDMA–Aurora")
    style_run(r, size=25, bold=True, color=DARK_BLUE)
    p = doc.add_paragraph()
    p.paragraph_format.space_after = Pt(18)
    r = p.add_run("设计架构、接口规格、数据流、关键时序与 Root Port 大仿真验证方案")
    style_run(r, size=13, color=GRAY)

    metadata = [
        ("项目", "RTDS_test-1ch / PCIE-CPU"),
        ("工具基线", "Vivado / XSim 2020.2"),
        ("PCIe", "XDMA Gen3 x2，H2C/C2H 各 1 通道"),
        ("数据面", "AXI4 64 bit @ 250 MHz；Aurora LocalLink 64 bit @ 156.25 MHz"),
        ("文档状态", "V1.1 详细设计规格；以远程机现行 PCIe.v/adapter RTL 为基线"),
        ("生成日期", "2026-08-20"),
    ]
    add_table(doc, ["字段", "内容"], metadata, [1800, 7560], header_fill=LIGHT_GRAY, font_size=9.5)
    add_callout(
        doc,
        "适用范围",
        "本文同时描述生产设计和仿真验证环境。生产硬件包含 Aurora 64B/66B 与 GT；Root Port 大仿真在 PCIe 模块的 LocalLink 边界使用轻量 BFM，不覆盖 Aurora 编码、GT、CDR 或真实串行误码。",
    )
    add_picture_with_alt(
        doc, arch, Inches(6.4), "RTDS_test-1ch 生产设计总体架构",
        "Host/CPU 经 PCIe TLP 连接 XDMA design_1，再经 PCIe 集成层、FDMA Adapter 与 Aurora 双向交换数据；MSI/C2H 为返回方向。",
    )
    add_caption(doc, "图 1  RTDS_test-1ch 生产设计总体架构")

    add_heading(doc, "文档控制", 1)
    add_table(
        doc,
        ["版本", "日期", "状态", "变更说明"],
        [
            ("V1.0", "2026-07-24", "基线", "汇总生产 RTL、1ch XDMA 配置、双向数据流、MSI/IRQ 语义及 Root Port 大仿真验证方案。"),
            ("V1.1", "2026-08-20", "详细设计", "补充远程机现行 PCIe.v 与 adapter 的子模块架构、电路级实现、完整信号词典及关键时序图。"),
        ],
        [1050, 1500, 1150, 5660],
    )
    add_heading(doc, "阅读导航", 2)
    for item in [
        "第 1～3 章：目标、约束与生产设计架构。",
        "第 4～8 章：顶层/子模块接口、寄存器、时钟复位和双向数据流。",
        "第 9～11 章：中断、关键时序、异常与恢复。",
        "第 12～15 章：验证环境、测试点矩阵、波形/日志门禁和覆盖边界。",
        "附录：完整信号词典、ILA 探针和复现入口。",
    ]:
        add_bullet(doc, item, bullet_num_id)

    add_heading(doc, "1. 目标与设计基线", 1)
    add_body(doc, "本设计在 FPGA 内部建立 CPU/PCIe 与 Aurora 串行链路之间的双向 512 B 数据通路。CPU 通过 XDMA H2C 将数据写入卡端地址窗口，Adapter 使用 FDMA 读取并发送至 Aurora；Aurora 接收数据后由 FDMA 写入卡端窗口，产生用户中断，再由 CPU 使用 XDMA C2H 读回。")
    add_table(
        doc,
        ["项目", "规格"],
        [
            ("器件工具", "Vivado 2020.2；仿真器 XSim 2020.2"),
            ("PCIe", "Gen3 x2；Vendor ID 0x10EE；Device ID 0x8032"),
            ("XDMA 通道", "H2C 1 ch；C2H 1 ch"),
            ("AXI 数据面", "64 bit，250 MHz"),
            ("Aurora LL", "64 bit，156.25 MHz；单帧 512 B / 64 beat"),
            ("卡端窗口", "RX base 0x0000；TX base 0x8000；活动窗口 32 KiB"),
            ("中断", "XDMA user interrupt，经 MSI；vector 0 / mask bit0"),
            ("最小验收", "Gen3 x2、枚举/BAR、基础 H2C/C2H、双向 Aurora 512 B、IRQ/clear、断言与 scoreboard 全通过"),
        ],
        [2050, 7310],
    )
    add_callout(doc, "核心约束", "Aurora→FPGA 方向不能依赖 FPGA 对线路施加反压。BFM 连续提供 RX 数据；若 FPGA 撤销接收能力，视为溢出/协议错误，而不是合法等待。", fill="FFF4DD", title_color=GOLD)

    add_heading(doc, "2. 生产设计架构", 1)
    add_body(doc, "生产顶层 TOP 完成板级时钟、复位、PCIe 引脚、Aurora GT/SFP 和状态 LED 的集成。TOP 内部的 PCIe 模块包含真实 design_1_wrapper/xdma_0、INFO_EXCH、CONV_DMA、BRAM/AXI Interconnect、用户中断和 FDMA–Aurora Adapter。")
    add_table(
        doc,
        ["层次", "模块", "职责"],
        [
            ("板级", "TOP", "板级引脚、CLK_GEN、Aurora 64B/66B、PCIe、LED。"),
            ("PCIe 集成", "PCIe", "连接 XDMA/BD、Adapter、ILA 和 INFO_EXCH 状态。"),
            ("XDMA/AXI", "design_1_wrapper", "PCIe Endpoint、H2C/C2H、AXI/AXI-Lite、BRAM 地址空间和用户 IRQ。"),
            ("协议适配", "pcie_fdma_aurora_brg_adapter", "命令校验、FDMA bridge、CDC、帧计数、IRQ 与 sticky status。"),
            ("内存访问", "CONV_DMA", "把自定义 FDMA 请求转换为 AXI4 burst。"),
            ("软件接口", "INFO_EXCH", "AXI-Lite 寄存器、命令触发、状态和 read-to-clear。"),
            ("串行链路", "aurora_64b66b_top", "生产环境的 Aurora 64B/66B、GT 和 LocalLink 接口。"),
        ],
        [1150, 2600, 5610],
    )

    add_heading(doc, "3. 数据路径与所有权", 1)
    add_picture_with_alt(
        doc, flow, Inches(6.45), "双向 512 B 数据流",
        "CPU 到 Aurora：Host Memory、XDMA H2C、卡端 0x8000、FDMA Read、Aurora TX；Aurora 到 CPU：Aurora RX、FDMA Write、卡端 0x0000、XDMA C2H、Host Memory。",
    )
    add_caption(doc, "图 2  双向 512 B 数据流")
    add_heading(doc, "3.1 CPU → Aurora", 2)
    for item in [
        "软件准备 Host 源数据和 H2C descriptor，通过 XDMA 写入卡端 TX 窗口 0x8000。",
        "软件写 INFO_EXCH 0x24/0x28，并对 0x20 执行 0→1→0；上升沿产生 RD_START。",
        "Adapter 校验地址、长度、链路状态与并发状态，发出 FDMA read。",
        "FDMA bridge 从 CONV_DMA/AXI 取得 64 个 64-bit beat，经 CDC/FIFO 进入 Aurora 用户时钟域。",
        "LocalLink TX 产生 SOF、连续 payload 和 EOF；完成后 CPU_WR_DONE_resp 回落。",
    ]:
        add_bullet(doc, item, bullet_num_id)
    add_heading(doc, "3.2 Aurora → CPU", 2)
    for item in [
        "Aurora RX 提供 512 B 连续 LocalLink 帧。FPGA 不得把 dst_rdy 当作对线路的长期反压机制。",
        "RX bridge 跨时钟缓存并发出 FDMA write，目标窗口基址 0x0000。",
        "写突发完成后 Adapter 锁存 start/len，置 rx_pending、INT_STATE 和 FPGA_CPU_irq_req。",
        "XDMA 在 MSI 已使能时接受 usr_irq_req 并返回 usr_irq_ack；主机读取 INFO_EXCH 0x10 清状态。",
        "软件提交 C2H descriptor，把卡端 0x0000 的 512 B 搬到 Host 目标区，再对 0x14 执行 1→0 重新武装。",
    ]:
        add_bullet(doc, item, bullet_num_id)

    add_heading(doc, "4. 时钟、复位与链路条件", 1)
    add_table(
        doc,
        ["时钟/复位", "频率/极性", "使用模块", "设计要求"],
        [
            ("pcie_diff_clk", "100 MHz 差分", "XDMA Endpoint", "PCIe 参考时钟。"),
            ("i_sys_clk / fdma_clk", "250 MHz", "Adapter FDMA 域、CONV_DMA、ILA", "FDMA、状态寄存及主要控制域。"),
            ("aurora_user_clk", "156.25 MHz", "Aurora LL、TX/RX bridge", "与 fdma_clk 异步，使用 XPM CDC/FIFO。"),
            ("pcie_rst_n", "低有效", "XDMA Endpoint", "大仿真保持低约 5 us 后释放。"),
            ("i_sys_rst", "高有效", "PCIe 集成逻辑", "传给 Adapter 时转换为 fdma_rstn=!i_sys_rst。"),
            ("aurora_user_rstn", "低有效", "Aurora 用户域", "BFM 稳定 16 个 LL 时钟后置 channel_up/lane_up。"),
        ],
        [1750, 1400, 2450, 3760],
        font_size=8.2,
    )
    add_body(doc, "Adapter 对 PCIe link、Aurora channel_up 和 lane_up 分别进行两级同步，并在目标域形成 link_up_user/link_up_fdma。TX 活动还参与子桥复位，使一个命令对应一个受控 burst 序列；RX 侧只要链路有效即保持可接收。")

    add_heading(doc, "5. 顶层接口规格", 1)
    add_heading(doc, "5.1 TOP 板级端口", 2)
    top_rows = [
        ("clk_p/n", "输入，1 bit", "板级差分系统时钟，供 CLK_GEN。"),
        ("pcie_mgt_rxp/n[1:0]", "输入", "PCIe Endpoint x2 串行接收。"),
        ("pcie_mgt_txp/n[1:0]", "输出", "PCIe Endpoint x2 串行发送。"),
        ("pcie_diff_clk_p/n[0]", "输入", "PCIe 100 MHz 差分参考时钟。"),
        ("pcie_rst_n", "输入，低有效", "PCIe PERST#。"),
        ("user_lnk_up", "输出", "XDMA 链路建立状态。"),
        ("GTHQ0_P/N", "输入", "Aurora GT 参考时钟。"),
        ("aurora_rxp/n", "输入", "Aurora 串行接收。"),
        ("aurora_txp/n", "输出", "Aurora 串行发送。"),
        ("sfp_tx_disable/rs0/rs1", "输出", "SFP 控制。"),
        ("led", "输出", "板级状态指示。"),
    ]
    add_table(doc, ["信号", "方向/宽度", "含义"], top_rows, [2500, 1900, 4960])
    add_heading(doc, "5.2 PCIe 模块 LocalLink 端口", 2)
    ll_rows = [
        ("aurora_tx_d[63:0]", "输出", "FPGA→Aurora payload。"),
        ("aurora_tx_sof/eof", "输出", "帧首/帧尾。"),
        ("aurora_tx_rem[2:0]", "输出", "尾拍有效字节编码；512 B 满拍为 3'b111。"),
        ("aurora_tx_src_rdy", "输出", "TX 数据有效。"),
        ("aurora_tx_dst_rdy", "输入", "Aurora Core 接收能力；TX 可按握手暂停。"),
        ("aurora_rx_d[63:0]", "输入", "Aurora→FPGA payload。"),
        ("aurora_rx_sof/eof", "输入", "RX 帧界。"),
        ("aurora_rx_rem[2:0]", "输入", "尾拍有效字节编码。"),
        ("aurora_rx_src_rdy", "输入", "RX 数据有效，真实链路侧连续推进。"),
        ("aurora_rx_dst_rdy", "输出", "内部接收能力指示；不能用于让远端 SerDes 回退已到达数据。"),
    ]
    add_table(doc, ["信号", "方向", "语义"], ll_rows, [2800, 1150, 5410])

    add_heading(doc, "6. 子模块详细设计规格", 1)
    add_callout(
        doc,
        "规范性说明",
        "本章是 PCIe.v 与 pcie_fdma_aurora_brg_adapter 的实现依据。RTL 应按本章定义的时钟域、复位极性、组合条件、寄存器生命周期、握手推进条件、地址/长度单位和异常清除规则编写；不得仅依据端口名称猜测 valid/ready 语义。",
        fill="EEF5FB",
        title_color=BLUE,
    )

    add_heading(doc, "6.1 PCIe.v 集成模块", 2)
    add_body(doc, "PCIe.v 是板级 TOP 与 design_1_wrapper/Adapter 之间的稳定集成边界。该层不实现 PCIe TLP、AXI burst、跨时钟 FIFO 或帧状态机，只负责固定系统参数、统一复位极性、建立语义正确的 FDMA/INFO_EXCH 连接、透传 LocalLink、汇集 ILA 探针，并保持原 XDMA Block Design 的端口和软件地址映射不变。")
    add_picture_with_alt(
        doc, pcie_arch, Inches(6.45), "PCIe.v 内部子模块与语义边界",
        "PCIe.v 内部包含 design_1_wrapper、pcie_fdma_aurora_brg_adapter 和 ila_FDMA；板级 PCIe 接 design_1，LocalLink 接 adapter，FDMA/INFO/IRQ 在二者之间交换。",
    )
    add_caption(doc, "图 3  PCIe.v 内部子模块、接口组与职责边界")
    add_heading(doc, "6.1.1 固定规格与不变量", 3)
    add_table(
        doc,
        ["常量", "值", "实现约束"],
        [
            ("FRAME_BYTES", "512 B", "一帧固定 64 个 64-bit beat；同时约束软件命令、FDMA burst 与 LocalLink 帧界。"),
            ("ACTIVE_WINDOW_BYTES", "32 KiB", "每个方向 64 帧；地址逻辑采用半开区间 [base, base+32 KiB)。"),
            ("RX_BASE_ADDR_LO", "0x0000_0000", "Aurora→CPU 的 FDMA write 窗口低地址。"),
            ("TX_BASE_ADDR_LO", "0x0000_8000", "CPU→Aurora 的 FDMA read 窗口低地址。"),
            ("CARD_ADDR_HI", "0x0000_0000", "与低 32-bit 地址拼成 64-bit card address；不得把软件地址当主机物理地址。"),
        ],
        [2200, 1700, 5460],
        font_size=8.1,
    )
    add_body(doc, "i_sys_rst 为高有效，而 Adapter 的 fdma_rstn 与 design_1_wrapper 的 sys_rst_n 为低有效，因此两处均使用 !i_sys_rst。user_lnk_up 直接等于 user_lnk_up_int，不额外打拍或门控，保证原 TOP/软件可见链路时序不变；Adapter 内部再把该状态与 Aurora channel_up/lane_up 同步后相与形成真实业务放行条件。")
    add_heading(doc, "6.1.2 三个子模块的连接职责", 3)
    add_table(
        doc,
        ["实例", "时钟/复位", "输入来源", "输出去向", "职责"],
        [
            ("u_pcie_fdma_aurora_brg_adapter", "i_sys_clk/!i_sys_rst；aurora_user_clk/aurora_user_rstn", "INFO、FDMA返回、PCIe/Aurora link、LL RX", "FDMA请求、LL TX、IRQ/status/sticky", "完成双向桥接、CDC、帧控制和所有权。"),
            ("ila_FDMA_inst", "i_sys_clk", "FDMA地址/请求/数据/size、bridge状态", "ILA capture", "只观测，不反馈控制；probe12=RX状态，probe13=TX状态。"),
            ("design_1_wrapper_inst", "i_sys_clk/!i_sys_rst；PCIe refclk/PERST#", "PCIe物理输入、Adapter FDMA/IRQ/status", "PCIe物理输出、INFO命令、FDMA返回、link", "保留 XDMA、CONV_DMA、INFO_EXCH、BRAM/AXI 和 MSI。"),
        ],
        [2100, 2100, 1780, 1780, 1600],
        font_size=7.1,
    )
    add_heading(doc, "6.1.3 FDMA write 语义改名电路", 3)
    add_picture_with_alt(
        doc, fdma_write_wiring, Inches(6.45), "FDMA write 历史端口名与真实握手语义",
        "Adapter 的标准 fdma_wvalid 接到 design_1 的 fdma_wready_0 输入并命名为 fdma_w_source_valid；design_1 的 fdma_wvalid_0 输出作为 fdma_w_accept 返回 Adapter fdma_wready。",
    )
    add_caption(doc, "图 4  CONV_DMA 历史端口名的语义隔离与正确连线")
    add_body(doc, "写数据每拍只有在 fdma_w_source_valid && fdma_w_accept 同时为 1 时提交。PCIe.v 通过 fdma_w_source_valid/fdma_w_accept 两个语义名阻断错误直觉：Adapter.fdma_wvalid 必须接 BD.fdma_wready_0；BD.fdma_wvalid_0 必须接 Adapter.fdma_wready。若按同名直连，数据源与接收确认方向会颠倒，可能造成丢字、重复或永久停顿。")
    add_heading(doc, "6.1.4 连接组与关键实现", 3)
    add_table(
        doc,
        ["连接组", "信号", "产生者 → 消费者", "实现规则"],
        [
            ("FDMA read 请求", "fdma_raddr/rareq/rsize", "Adapter → CONV_DMA", "请求被 rbusy 接受前地址和 size 保持；size=64 beat。"),
            ("FDMA read 数据", "fdma_rdata/rvalid/rready", "CONV_DMA ↔ Adapter", "只在 rvalid&&rready 时进入 TX FIFO。"),
            ("FDMA write 请求", "fdma_waddr/wareq/wsize", "Adapter → CONV_DMA", "请求被 wbusy 接受前地址和 size 保持。"),
            ("FDMA write 数据", "fdma_wdata/source_valid/accept", "Adapter ↔ CONV_DMA", "按真实 source-valid/data-accept 语义推进。"),
            ("TX 软件命令", "RD_START/CPU_FPGA_START_ADDR/LEN", "INFO_EXCH → Adapter", "地址/长度先稳定，RD_START 单周期触发。"),
            ("RX 软件通知", "FPGA_CPU_START_ADDR/LEN、INT_STATE_W、irq_req", "Adapter → INFO/XDMA", "仅完整 FDMA write burst 后发布。"),
            ("所有权/清除", "CPU_REC_STATE_R/W、INT_STATE_R、CLEAR_INTER_R", "INFO ↔ Adapter", "中断清除与 buffer 归还是两个独立动作。"),
            ("LocalLink", "aurora_tx_* / aurora_rx_*", "Adapter ↔ TOP/Aurora", "所有 payload/frame/ready 语义保持在 aurora_user_clk 域。"),
        ],
        [1500, 2550, 2250, 3060],
        font_size=7.3,
    )

    add_heading(doc, "6.2 pcie_fdma_aurora_brg_adapter", 2)
    add_body(doc, "Adapter 是软件命令、FDMA、Aurora LocalLink 和中断状态之间的语义边界。它复用 fdma_aurora_brg_tx/rx 作为双向数据子桥，在外层补充命令校验、地址窗口、跨域链路条件、帧完成事件、RX 所有权、IRQ、帧协议检查和 sticky/timeout 汇聚。多比特 payload 只通过异步 FIFO 跨域，控制电平和事件采用明确的 CDC 模式。")
    add_picture_with_alt(
        doc, adapter_arch, Inches(6.45), "Adapter 功能电路分层",
        "Adapter 分为 fdma_clk 与 aurora_user_clk 两个域，包含 TX 命令/事务、TX bridge、RX bridge、帧检查、RX 所有权/IRQ、sticky 与 timeout。",
    )
    add_caption(doc, "图 5  Adapter 双时钟域功能电路与子模块分解")
    add_heading(doc, "6.2.1 参数、单位与静态约束", 3)
    add_table(
        doc,
        ["参数/派生量", "当前值", "单位/用途", "约束"],
        [
            ("FRAME_BYTES", "512", "byte/帧", "当前计数器与尾拍规则只允许 512。"),
            ("ACTIVE_WINDOW_BYTES", "32768", "byte/方向窗口", "必须为正且为 FRAME_BYTES 整数倍。"),
            ("RX_BASE_ADDR_LO", "0x0000_0000", "RX低32位基址", "base+window 不得跨 4 GiB。"),
            ("TX_BASE_ADDR_LO", "0x0000_8000", "TX低32位基址", "base+window 不得跨 4 GiB。"),
            ("CARD_ADDR_HI", "0", "card address高32位", "与低地址拼接后参与 64-bit FDMA 地址。"),
            ("FDMA_TIMEOUT_CYCLES", "65535", "fdma_clk 周期", "仅 waiting 且无 progress 时累加。"),
            ("FRAME_WORDS", "64", "64-bit word/帧", "FRAME_BYTES/8。"),
            ("FRAME_BYTES_32", "512", "软件通知字节数", "固定写入 fpga_cpu_len。"),
            ("FRAME_WORDS_16", "64", "FDMA size beat数", "覆盖 RX bridge 的历史 byte-size 输出。"),
        ],
        [2300, 1400, 2400, 3260],
        font_size=7.6,
    )
    add_table(
        doc,
        ["子模块/资源", "数量", "接口角色", "设计说明"],
        [
            ("fdma_aurora_brg_tx", "1", "FDMA read ↔ async FIFO ↔ LL TX", "每个 burst/frame 固定 512 B；支持 TX dst_rdy 背压。"),
            ("fdma_aurora_brg_rx", "1", "LL RX ↔ async FIFO ↔ FDMA write", "连续接收；FIFO 满/撤 ready 作为系统错误。"),
            ("xpm_cdc_single level", "9", "link/active/waterline/error 电平", "两级目标域同步；同步结果只能在目标域使用。"),
            ("toggle CDC", "2", "tx_frame_done、clear_inter 脉冲", "源域翻转、目标域同步后异或恢复单周期事件。"),
            ("XPM async FIFO", "TX/RX 各1", "64-bit payload CDC", "TX 4 KiB，RX 16 KiB；多比特数据禁止逐位同步。"),
        ],
        [2300, 900, 2850, 3310],
        font_size=7.7,
    )
    add_heading(doc, "6.2.2 时钟域、链路门控与局部复位", 3)
    add_picture_with_alt(
        doc, adapter_cdc, Inches(6.45), "Adapter CDC 结构",
        "fdma_clk 与 aurora_user_clk 之间使用 level synchronizer、toggle pulse synchronizer 和双向 async FIFO；payload 仅经 FIFO 跨域。",
    )
    add_caption(doc, "图 6  Adapter 跨时钟域信号、方向与同步模式")
    add_table(
        doc,
        ["目标域", "放行条件", "局部复位", "行为"],
        [
            ("fdma_clk / TX", "pcie_link_up && sync(channel_up) && sync(lane_up) && tx_active", "tx_fdma_rstn", "无合法命令或掉链时清 TX FDMA 侧和 FIFO 写侧，防止残留数据进入下一命令。"),
            ("user_clk / TX", "sync(pcie_link_up) && channel_up && lane_up && sync(tx_active)", "tx_user_rstn", "仅活动命令允许 LocalLink TX；末字真握手才产生 frame_done。"),
            ("fdma_clk / RX", "pcie_link_up && sync(channel_up) && sync(lane_up)", "rx_fdma_rstn", "链路有效即允许把 FIFO 数据写入 card memory。"),
            ("user_clk / RX", "sync(pcie_link_up) && channel_up && lane_up", "rx_user_rstn", "链路有效即接收；与软件是否有 TX 命令无关。"),
        ],
        [1700, 2700, 1450, 3510],
        font_size=7.4,
    )
    add_heading(doc, "6.2.3 TX 命令校验与事务寄存器", 3)
    add_picture_with_alt(
        doc, tx_validation, Inches(6.45), "TX 命令接管与事务控制",
        "rd_start 经配置、忙状态和链路检查后锁存 base/target 并置 tx_active；最后一帧完成或活动期掉链时清事务。",
    )
    add_caption(doc, "图 7  TX 配置组合逻辑、命令接管与事务退出条件")
    add_body(doc, "tx_requested_end 和 tx_window_end 使用 33-bit 无符号加法。tx_config_valid 必须同时满足：cpu_fpga_len 非零；起始地址与长度按 512 B 对齐；长度不超过 32 KiB；起始地址不低于 TX_BASE_ADDR_LO；半开区间结束地址不超过 TX window end；加法最高位不产生回绕。tx_start_valid 还要求 !tx_active 与 link_up_fdma。")
    add_table(
        doc,
        ["事件", "寄存器更新", "可见结果"],
        [
            ("tx_start_valid", "tx_active=1；锁存 tx_base_addr_lo、tx_target_frames；completed=0", "cpu_wr_done_resp=1；TX 子桥解除局部复位。"),
            ("活动期 frame_done", "completed+1；若达到 target 则 active/target/completed 清零", "最后一帧完成后 resp=0。"),
            ("活动期 link_down", "active/target/completed 清零", "resp=0；link_down_sticky=1；事务需软件重发。"),
            ("配置非法或忙时 rd_start", "不接管新命令", "length_error_sticky=1；原活动事务不被新配置覆盖。"),
            ("down 时 rd_start", "不接管命令", "link_down_sticky=1。"),
        ],
        [2050, 4200, 3110],
        font_size=7.5,
    )
    add_heading(doc, "6.2.4 TX 数据路径、地址与完成事件", 3)
    add_body(doc, "TX 子桥内部 raw 地址从 0 开始按窗口递增/回绕，Adapter 输出 fdma_raddr={CARD_ADDR_HI,tx_base_addr_lo}+{32'd0,tx_fdma_raddr_raw}。fdma_rsize 恒为 FRAME_WORDS_16=64。FDMA read beat 只在 fdma_rvalid&&fdma_rready 时进入异步 FIFO；LocalLink beat 只在 aurora_tx_src_rdy&&aurora_tx_dst_rdy 时消费，背压期间 data/SOF/EOF/rem 必须稳定。")
    add_body(doc, "tx_frame_done_user 只在 LocalLink 第 64 beat 且 EOF 真握手时产生。该窄脉冲先翻转 tx_done_toggle_user，经两级同步得到 tx_done_toggle_fdma，再与 tx_done_toggle_fdma_d 异或恢复 tx_frame_done_fdma。完成计数以该事件为准；FDMA read 完成不等价于链路发送完成。")
    add_heading(doc, "6.2.5 RX 数据路径、帧检查和水位", 3)
    add_body(doc, "RX 子桥把 LocalLink 64-bit payload 写入异步 FIFO，在 fdma_clk 域发起 512 B FDMA write。fdma_waddr={CARD_ADDR_HI,RX_BASE_ADDR_LO}+{32'd0,rx_fdma_waddr_raw}；对外 fdma_wsize 固定覆盖为 64 beat，不能使用 rx_fdma_wsize_raw 的历史 byte 语义。rx_fifo_almost_full/full 经电平同步送到 fdma_clk 域用于观测；任一 FIFO overflow，或 aurora_rx_src_rdy=1 且 aurora_rx_dst_rdy=0，均锁存 RX overflow。")
    add_table(
        doc,
        ["帧检查上下文", "合法规则", "错误条件"],
        [
            ("帧起点", "首个 rx_hs 必须 aurora_rx_sof=1；word_count=1", "帧内重复 SOF；帧外无 SOF 数据。"),
            ("帧中", "每个 rx_hs 增加 word_count；无 EOF", "第64拍前提前 EOF；超过64拍仍无 EOF。"),
            ("帧终点", "此前计数=63，当前 EOF=1 且 rem=3'b111", "计数不等于63；rem不是全有效；SOF/EOF形成非法1-word帧。"),
            ("掉链", "清 rx_in_frame 和 word_count", "链路恢复后必须从新 SOF 建立上下文。"),
        ],
        [1800, 3900, 3660],
        font_size=7.6,
    )
    add_heading(doc, "6.2.6 RX 所有权、通知与 IRQ", 3)
    add_picture_with_alt(
        doc, rx_ownership, Inches(6.45), "RX 所有权和中断逻辑",
        "完整 FDMA burst 后在无 pending 时发布地址、长度和 IRQ；中断清除不归还 buffer，CPU_REC_STATE 上升沿才清 pending。",
    )
    add_caption(doc, "图 8  RX 完整落盘、CPU 所有权、中断清除与 overrun 判定")
    add_body(doc, "rx_burst_done_fdma 是发布通知的唯一数据完成条件。若 !rx_pending_r 或同拍 cpu_rec_ack，Adapter 发布 FPGA_CPU_START_ADDR=RX_BASE_ADDR_LO+rx_fdma_waddr_raw、FPGA_CPU_LEN=512，并置 fpga_cpu_irq_req、int_state_w_r、rx_pending_r。若前帧仍由 CPU 持有，则保持旧通知不变，仅置 rx_overrun_sticky_r，避免静默覆盖软件尚未读取的地址。")
    add_body(doc, "int_state_clear 或 clear_inter 只清 fpga_cpu_irq_req/int_state_w_r。cpu_rec_ack=cpu_rec_state_r&&!cpu_rec_state_d 检测 CPU_REC_STATE 上升沿，清 rx_pending_r 与 rx_overrun_sticky_r；cpu_rec_state_w 跟随 cpu_rec_state_r 作为回读/握手镜像。软件顺序应为：响应/清中断 → C2H 读完旧 buffer → CPU_REC_STATE 产生确认边沿。")
    add_heading(doc, "6.2.7 Sticky 状态、跨域清除与超时", 3)
    add_picture_with_alt(
        doc, error_aggregation, Inches(6.45), "错误状态汇聚与超时",
        "Aurora 域错误先源域锁存再同步回 FDMA 域；clear_inter 清最终状态并通过 toggle 清源域，hold 抑制同步链中的旧高电平；timeout 只在 waiting 且无 progress 时计数。",
    )
    add_caption(doc, "图 9  错误源、源域/目的域 sticky、clear hold 与 progress-aware timeout")
    add_table(
        doc,
        ["最终状态", "置位来源", "清除/保持规则"],
        [
            ("rx_overflow_sticky", "RX FIFO overflow；或 RX valid 且本地 not-ready", "clear_inter；源域清零返回前 user_status_clear_hold 阻止旧高电平反弹。"),
            ("tx_underflow_sticky", "tx_user_dbg_bus[0] 报告 TX FIFO/供数不足", "clear_inter，经 user 域 clear toggle 清源 sticky。"),
            ("length_error_sticky", "RX 帧界/长度/rem 错；TX 配置非法或忙时重启", "clear_inter。"),
            ("fdma_timeout_sticky", "fdma_waiting 持续且无 fdma_progress 达到门槛", "clear_inter；progress 或不再 waiting 时 wait_count 清零。"),
            ("link_down_sticky", "down 状态启动；活动期掉链；曾 up 后再次 down", "clear_inter；seen_link_up 避免上电训练阶段误报。"),
            ("rx_overrun_sticky", "pending 未释放时又完成新 RX burst", "cpu_rec_ack 清除，不由普通中断 clear 清除。"),
        ],
        [2200, 3500, 3660],
        font_size=7.4,
    )
    add_body(doc, "fdma_waiting 覆盖 rareq、wareq、rready&&!rvalid、wvalid&&!wready 四类等待；fdma_progress 覆盖请求被 busy 接受、读/写数据真握手和 rx_burst_done。只要有 progress 或协议不再等待，fdma_wait_count 就清零；因此正常长事务只要持续推进不会误报 timeout。")

    add_heading(doc, "6.3 CONV_DMA", 2)
    add_body(doc, "CONV_DMA 将自定义 FDMA request/data 接口转换为 AXI4 master 五通道。AXI 地址宽度 64 bit、数据宽度 64 bit、ID 宽度 1。FDMA size 以 64-bit word 数表示，512 B 对应 64 word。")
    add_callout(doc, "端口历史语义", "生产 PCIe.v 已建立语义网：fdma_w_source_valid 连接 CONV_DMA 的 fdma_wready_0 输入；fdma_w_accept 由 CONV_DMA 的 fdma_wvalid_0 输出返回。名称与常规 valid/ready 直觉相反，禁止按字面重新接线。", fill="FDECEC", title_color=RED)
    add_heading(doc, "6.4 INFO_EXCH", 2)
    add_body(doc, "INFO_EXCH 是 32-bit AXI-Lite 从设备。地址和数据按独立 AXI-Lite 握手接收，WSTRB 支持逐字节写。软件命令通过寄存器边沿转换为单周期控制脉冲；状态寄存器连接 Adapter。")
    add_callout(doc, "地址基准", "BD 中 INFO_EXCH AXI-Lite segment 的卡内基址为 0x4000_0000、范围 4 KiB。下表列的是模块内偏移；Root Port TPI 经过 XDMA BAR 地址转换后以用户 BAR 内偏移 0x00～0x28 访问。")
    reg_rows = [
        ("0x00", "VERSION", "RO", "0x00001001", "设计/协议版本。"),
        ("0x04", "PROG_TIME", "RO", "0x20260506", "构建日期标识。"),
        ("0x08", "CH_BUF_LEN", "RO", "0x00008000", "通道缓冲窗口标称长度。"),
        ("0x0C", "FPGA_TEMP_W", "RO", "运行值", "温度/遥测输入。"),
        ("0x10", "INT_STATE", "RO / read-clear", "0/1", "读取时产生 INT_STATE_R/CLEAR_INTER_R 单周期清除。"),
        ("0x14", "CPU_REC_STATE", "RW", "0", "CPU 接收完成/所有权释放；验证使用 1→0。"),
        ("0x18", "FPGA_CPU_START_ADDR", "RO", "0x00000000", "Aurora RX 完成后的卡端地址。"),
        ("0x1C", "FPGA_CPU_LEN", "RO", "512", "Aurora RX 完成长度。"),
        ("0x20", "CPU_WR_DONE", "RW / edge", "0", "bit0 上升沿生成 RD_START；软件执行 0→1→0。"),
        ("0x24", "CPU_FPGA_START_ADDR", "RW", "0x00008000", "CPU→Aurora 卡端起始地址。"),
        ("0x28", "CPU_FPGA_LEN", "RW", "512", "CPU→Aurora 发送长度。"),
    ]
    add_table(doc, ["偏移", "名称", "属性", "典型值", "语义"], reg_rows, [900, 2300, 1250, 1650, 3260], font_size=7.8)

    add_heading(doc, "6.5 XDMA / design_1", 2)
    add_table(
        doc,
        ["项目", "规格/用途"],
        [
            ("链路", "Gen3 x2，真实 Endpoint 与官方 RP 模型串行互连。"),
            ("通道", "H2C 1 ch；C2H 1 ch。"),
            ("M_AXI", "64 bit @ 250 MHz，访问 BRAM/CONV_DMA 数据空间。"),
            ("M_AXI-Lite", "访问 INFO_EXCH 用户寄存器。"),
            ("地址映射", "BRAM segment 基址 0x0000_0000、范围 64 KiB；INFO_EXCH 基址 0x4000_0000、范围 4 KiB。"),
            ("User IRQ", "usr_irq_req[0]；由 XDMA 在 MSI 已使能时接受并给出 usr_irq_ack[0]。"),
            ("软件可见完成", "descriptor count=1，status=0x6；每个事务独立判断，不要求跨事务单调递增。"),
        ],
        [2200, 7160],
    )
    add_heading(doc, "6.6 ILA", 2)
    ila_rows = [
        ("0", "fdma_raddr[31:0]", "FDMA read 地址"),
        ("1", "fdma_rareq", "读请求"),
        ("2", "fdma_rbusy", "读通道忙"),
        ("3", "fdma_rdata[63:0]", "读数据"),
        ("4", "fdma_rsize[15:0]", "读 word 数"),
        ("5", "fdma_rvalid", "读数据有效"),
        ("6", "fdma_waddr[31:0]", "FDMA write 地址"),
        ("7", "fdma_wareq", "写请求"),
        ("8", "fdma_wbusy", "写通道忙"),
        ("9", "fdma_wdata[63:0]", "写数据"),
        ("10", "fdma_wsize[15:0]", "写 word 数"),
        ("11", "fdma_w_source_valid", "Aurora RX 数据源有效"),
        ("12", "adapter_rx_state_dbg[3:0]", "RX bridge 状态"),
        ("13", "adapter_tx_state_dbg[3:0]", "TX bridge 状态"),
    ]
    add_table(doc, ["Probe", "信号", "用途"], ila_rows, [1000, 3500, 4860], font_size=8.2)
    add_body(doc, "大仿真不读取 ILA capture RAM，而是把探针源和相关握手信号直接写入 WDB。这样保留事务级可见性，同时避免 ILA 内部存储和触发逻辑增加仿真负担。")

    add_heading(doc, "7. 中断与 MSI 语义", 1)
    add_body(doc, "Adapter 产生 FPGA_CPU_irq_req，并通过 BD 连接到 XDMA usr_irq_req[0]。usr_irq_req 是应用层保持请求；msi_enable 是配置空间 MSI Enable 的运行时状态；usr_irq_ack 表示 XDMA 已接受该用户请求并生成相应中断消息。三者不是同一个阶段。")
    add_table(
        doc,
        ["信号/状态", "产生者", "含义", "清除/完成"],
        [
            ("FPGA_CPU_irq_req", "Adapter", "RX burst 完成且获得 buffer 所有权后置位。", "INFO 0x10 read-to-clear。"),
            ("usr_irq_req[0]", "RTDS→XDMA", "传给 XDMA 的用户中断请求，应保持至服务/清除。", "随 Adapter IRQ 清除。"),
            ("msi_enable", "XDMA", "Host 已在配置空间允许 MSI。", "由 PCIe 配置空间控制。"),
            ("usr_irq_ack[0]", "XDMA", "用户请求被接受并发送/排队为 MSI 的确认。", "脉冲/握手证据，不等于软件 ISR 完成。"),
            ("INT_STATE", "Adapter/INFO_EXCH", "软件可读 sticky 状态。", "读取 0x10 产生 clear。"),
        ],
        [1800, 1500, 3800, 2260],
        font_size=8.0,
    )
    add_callout(doc, "验证边界", "仿真已证明 MSI capability 配置、msi_enable、usr_irq_req/ack 和 read-to-clear 的硬件证据链；操作系统中断控制器、驱动 ISR 与真实 CPU 调度延迟仍需上板软件验证。")

    add_heading(doc, "8. 关键时序", 1)
    add_picture_with_alt(
        doc, timing, Inches(6.45), "CPU-Aurora 与 Aurora-CPU/MSI 关键时序",
        "上半图展示寄存器写、FDMA 读、LocalLink 帧和完成响应；下半图展示连续 Aurora RX、FDMA 写、IRQ 请求与应答、读清中断及重新武装。",
    )
    add_caption(doc, "图 10  CPU→Aurora 与 Aurora→CPU/MSI 总体关键时序（语义示意，非等比例）")
    add_heading(doc, "8.1 TX 命令接管与 FDMA read", 2)
    add_picture_with_alt(
        doc, detailed_timings["tx_cmd"], Inches(6.45), "TX 命令与 FDMA read 时序",
        "合法 rd_start 锁存命令并置 tx_active/resp；随后 FDMA read 请求由 rbusy 接受，数据按 rvalid/rready 传输。",
    )
    add_caption(doc, "图 11  TX 合法命令锁存、FDMA 请求接受与 64-beat 数据推进")
    add_body(doc, "rd_start 仅作为单周期请求。tx_start_valid 成立的同一 fdma_clk 边沿锁存地址和帧数；tx_active/cpu_wr_done_resp 从下一拍可见。fdma_rareq 由 TX bridge 发出并保持到 fdma_rbusy 接受；随后每个 beat 由 fdma_rvalid&&fdma_rready 推进。地址和 fdma_rsize 在请求接受前保持稳定。")
    add_heading(doc, "8.2 Aurora TX 背压与帧完成 CDC", 2)
    add_picture_with_alt(
        doc, detailed_timings["tx_backpressure"], Inches(6.45), "TX 背压与完成 toggle",
        "TX src_rdy 有效而 dst_rdy 拉低时数据和帧界保持；EOF 真握手产生 user 域 frame_done，经 toggle CDC 在 fdma 域恢复完成脉冲。",
    )
    add_caption(doc, "图 12  LocalLink TX stall 保持、EOF 真握手与跨域完成计数")
    add_body(doc, "aurora_tx_dst_rdy=0 的区间不消费数据，aurora_tx_d/sof/eof/rem/src_rdy 必须保持。只有 EOF 所在 beat 的 src_rdy&&dst_rdy 为真才翻转 tx_done_toggle_user。同步后的异或脉冲更新 tx_completed_frames；因此 CDC 延迟不会改变数据顺序，只推迟软件可见完成。")
    add_heading(doc, "8.3 Aurora RX、FDMA write 与通知", 2)
    add_picture_with_alt(
        doc, detailed_timings["rx_write"], Inches(6.45), "RX write 与通知时序",
        "RX 64-beat 帧进入 FIFO，FDMA write 请求被 wbusy 接受，数据按 source_valid/accept 提交，完整 burst done 后才置 IRQ/INT/pending。",
    )
    add_caption(doc, "图 13  RX 帧接收、FDMA write 握手与完整落盘后通知")
    add_body(doc, "Aurora EOF 仅表示一帧已进入 RX 路径，不表示 card memory 已写完。通知必须等待 rx_burst_done_fdma。PCIe.v 的 fdma_w_source_valid/fdma_w_accept 是本图中的真实有效/接受语义；CONV_DMA 端口名虽反向，推进条件仍为二者同时为 1。")
    add_heading(doc, "8.4 IRQ 清除与 RX 所有权归还", 2)
    add_picture_with_alt(
        doc, detailed_timings["irq_ownership"], Inches(6.45), "IRQ 与所有权时序",
        "RX 完成后 IRQ/INT/pending 同时置位；读清中断只清 IRQ/INT，C2H 后 CPU_REC_STATE 上升沿才清 pending。",
    )
    add_caption(doc, "图 14  中断应答、C2H 读取与 buffer ownership 的独立生命周期")
    add_body(doc, "中断生命周期和 buffer 生命周期不能合并。软件可先读 INFO 0x10 清 IRQ，rx_pending 仍保持，防止新帧覆盖旧通知；C2H 完成后再产生 CPU_REC_STATE 确认边沿归还所有权。若 pending 期间新 burst 完成，地址/长度保持旧值并置 rx_overrun_sticky。")
    add_heading(doc, "8.5 clear_inter 跨域与旧状态抑制", 2)
    add_picture_with_alt(
        doc, detailed_timings["clear_hold"], Inches(6.45), "clear toggle 与 hold 时序",
        "FDMA 域 clear_inter 先清最终 sticky 并翻转 toggle；用户域收到后清源 sticky；同步链旧高电平消失前 hold 保持，避免状态反弹。",
    )
    add_caption(doc, "图 15  Sticky clear 的双向 CDC 延迟与 user_status_clear_hold 窗口")
    add_body(doc, "clear_inter 到达时，FDMA 域最终 sticky 立即清零，同时 user_status_clear_hold=1。user 域在若干周期后收到 status_clear_user，清源域 sticky；这些 0 再同步回 fdma 域。只有 rx_overflow_fdma、tx_underflow_fdma、rx_length_error_fdma 全为 0，hold 才释放，之后的新错误才可重新置位。")
    add_heading(doc, "8.6 FDMA progress-aware timeout", 2)
    add_picture_with_alt(
        doc, detailed_timings["timeout"], Inches(6.45), "FDMA timeout 时序",
        "waiting 期间有任何 request accept、data handshake 或 burst done 都清等待计数；持续无进展达到门槛才置 timeout sticky。",
    )
    add_caption(doc, "图 16  FDMA 等待、有效进展、计数清零与 timeout sticky")
    add_body(doc, "fdma_wait_count 不是事务总时长计数器。只要 fdma_progress=1，或 fdma_waiting=0，计数立即清零；只有连续等待且完全无进展才递增。达到 FDMA_TIMEOUT_CYCLES-1 时置 fdma_timeout_sticky；clear_inter 清 sticky 和计数。")
    add_heading(doc, "8.7 LocalLink 规则", 2)
    for item in [
        "TX：src_rdy=1 且 dst_rdy=1 的拍才传输；背压期间 data/rem/SOF/EOF 必须稳定。",
        "RX：真实 Aurora SerDes 已经接收的数据不能由 FPGA 数据面推回线路。验证 BFM 连续发送，dst_rdy 低触发错误。",
        "512 B 满帧为 64 个 64-bit beat；最后一拍 rem=3'b111。",
        "SOF/EOF 与有效数据同拍；帧内不得出现无故中断、重复 SOF 或缺失 EOF。",
    ]:
        add_bullet(doc, item, bullet_num_id)
    add_heading(doc, "8.8 FDMA 规则", 2)
    for item in [
        "地址、长度在请求有效且 busy 接受前保持稳定。",
        "512 B 对应 size=64 word；地址必须在各自 32 KiB 活动窗口内并按 512 B 对齐。",
        "只有真实握手或 burst 完成算 progress；等待且无 progress 达到门槛才置 timeout sticky。",
        "任何 AXI BRESP/RRESP 非 OKAY 均使验证立即失败。",
    ]:
        add_bullet(doc, item, bullet_num_id)

    add_heading(doc, "9. 异常状态与恢复", 1)
    add_table(
        doc,
        ["状态", "置位条件", "清除", "软件建议"],
        [
            ("rx_overflow_sticky", "FIFO overflow 或 RX src_rdy 且 dst_rdy=0。", "读取 0x10 的 clear 流程。", "丢弃当前帧，检查吞吐/时钟。"),
            ("rx_overrun_sticky", "rx_pending 未释放时又完成新 burst。", "CPU_REC_STATE ack。", "先处理旧 buffer，再重新武装。"),
            ("tx_underflow_sticky", "TX bridge 数据供给不足。", "clear_inter 跨域 toggle。", "检查 FDMA read 和 AXI backpressure。"),
            ("fdma_timeout_sticky", "请求等待且长期无任何 progress。", "clear_inter。", "检查 busy/valid/ready 与 AXI response。"),
            ("length_error_sticky", "帧长/SOF/EOF/rem 或 TX 配置非法。", "clear_inter。", "校验 512 B 对齐和帧界。"),
            ("link_down_sticky", "命令时链路未起或活动期间链路掉线。", "clear_inter。", "重新训练链路后重发。"),
        ],
        [1900, 3300, 1900, 2260],
        font_size=7.8,
    )
    add_body(doc, "clear_inter 在 FDMA 域翻转 toggle，并同步至 Aurora 用户域。源域 sticky 清零再跨回需要若干周期，因此 user_status_clear_hold 会阻止旧的同步高电平把已清除状态重新置位。")

    add_heading(doc, "10. Root Port 大仿真架构", 1)
    add_picture_with_alt(
        doc, sim_arch, Inches(6.45), "XDMA Root Port 大仿真验证环境",
        "官方 Xilinx Root Port/TPI 通过 x2 串行链路连接真实 RTDS Endpoint；轻量 Aurora LocalLink BFM 和 CQ Host-memory sink、IRQ/AXI monitor、断言及 scoreboard 构成验证侧。",
    )
    add_caption(doc, "图 17  Xilinx Root Port + 真实 RTDS Endpoint 验证环境")
    add_table(
        doc,
        ["组件", "来源", "职责"],
        [
            ("board", "自定义 TB", "兼容官方 board.RP.tx_usrapp 层级；时钟、复位、互连和总控。"),
            ("RP", "XDMA example / 2020.2", "真实 Xilinx PCIe Root Port、TPI/USRAPP、枚举/BAR。"),
            ("EP", "真实 RTDS_test-1ch", "PCIe/design_1_wrapper/xdma_0 与生产 Adapter/INFO/CONV_DMA。"),
            ("LL_BFM", "自定义已验证 BFM", "TX 捕获和 RX 注入；RX 不支持随机反压。"),
            ("CQ_HOST", "自定义 monitor", "接收 RP m_axis_cq Memory Write 并形成 Host-memory sink。"),
            ("XDMA_AXI_MON", "自定义 monitor", "用本地 AXI 活动替代高频 descriptor count 轮询。"),
            ("IRQ bind monitor", "自定义 bind", "不改生产端口，观测 usr_irq_req/ack、msi_enable。"),
            ("Assertions/scoreboard", "自定义 TB", "协议、数据、顺序、超时与最终判定。"),
        ],
        [2000, 2400, 4960],
        font_size=8.0,
    )
    add_callout(doc, "CQ Host sink 的必要性", "官方 RP example 的 DATA_STORE 只是 Host 发起 H2C/descriptor read 时的数据源。Endpoint 的 C2H Memory Write 从 RP m_axis_cq 入站流到达，不会自动回写 DATA_STORE。CQ_HOST 按 TLP 地址、tkeep 和 payload 建立独立主机内存模型。")

    add_heading(doc, "11. rtds_minimum 验证流程", 1)
    steps = [
        ("1", "链路与枚举", "等待 link up；检查 Gen3 x2、Vendor/Device；完成 BAR 搜索。"),
        ("2", "MSI/IRQ 配置", "MSI capability=0x90，address=0xFEE00000，data=0x0045；使能 user IRQ bit0。"),
        ("3", "INFO_EXCH", "检查 0x00/0x04/0x08；0x24/0x28 写回。"),
        ("4", "基础 H2C", "Host 0x400 → card 0x8000，512 B；本地 AXI write 与 status 通过。"),
        ("5", "基础 C2H", "card 0x8000 → Host 0x800，512 B；CQ sink 逐字节通过。"),
        ("6", "CPU→Aurora", "写 INFO 命令；LL BFM 捕获 512 B；检查 resp 生命周期。"),
        ("7", "Aurora→CPU", "LL BFM 注入 512 B；检查 IRQ、INFO、MSI ack。"),
        ("8", "第二次 C2H", "card 0x0000 → Host 0x800；逐字节通过；CPU_REC_STATE 重新武装。"),
        ("9", "统一判定", "断言、scoreboard、AXI response、CQ protocol、warning/fatal 全为零。"),
    ]
    add_table(doc, ["序号", "阶段", "动作与判据"], steps, [800, 2100, 6460], font_size=8.3)

    add_heading(doc, "12. 测试点—验证用例矩阵", 1)
    matrix = [
        ("PCIe link", "Gen3 x2 / LTSSM", "rtds_minimum", "user_lnk_up、speed、width", "通过"),
        ("枚举/BAR", "Device/Vendor、BAR0/1", "rtds_minimum", "TPI readback", "通过"),
        ("MSI", "cap/address/data/enable", "rtds_minimum", "msi_enable、ack", "通过"),
        ("INFO", "固定值与 RW", "rtds_minimum", "BAR read/write", "通过"),
        ("H2C", "512 B 数据与 response", "rtds_minimum", "AXI monitor+数据", "通过"),
        ("C2H", "512 B posted write", "rtds_minimum", "CQ sink+scoreboard", "通过"),
        ("CPU→Aurora", "64 beat/帧界/resp", "rtds_minimum", "LL scoreboard+assertion", "通过"),
        ("Aurora→CPU", "连续 RX/FDMA write", "rtds_minimum", "FDMA+INFO+C2H", "通过"),
        ("IRQ clear", "req/ack/read-clear", "rtds_minimum", "bind monitor+INFO", "通过"),
        ("错误门禁", "X/Z、AXI error、timeout", "所有用例", "assertion/compare_logs", "通过"),
        ("压力", "1 KiB/32 KiB/连续帧", "后续 regression", "scoreboard+性能计数", "计划"),
        ("异常注入", "link drop/overflow/timeout", "后续专项", "sticky+恢复", "计划"),
    ]
    add_table(doc, ["功能", "测试点", "用例", "检查机制", "状态"], matrix, [1450, 2100, 1750, 3010, 1050], font_size=7.4)

    add_heading(doc, "13. 断言、scoreboard 与超时", 1)
    for item in [
        "LocalLink 背压稳定性：TX 在 valid=1、ready=0 时 data/rem/SOF/EOF 不变。",
        "Aurora RX 不反压：连续源期间 dst_rdy 低立即计为错误。",
        "FDMA：地址/长度合法、请求/忙/数据握手完整、完成响应顺序一致。",
        "AXI：BRESP/RRESP 必须 OKAY；无越界、无 X/Z、无未完成 burst。",
        "CQ Host：解析 Memory Write、地址递增、payload 字节数和 tkeep 一致。",
        "IRQ：RX 完成→INFO/IRQ→usr_irq_ack→read-clear→C2H 的顺序一致。",
        "超时：链路训练 500 us；单次 DMA/IRQ 200 us；总 HDL 2 ms；墙钟 120 min。",
    ]:
        add_bullet(doc, item, bullet_num_id)

    add_heading(doc, "14. 波形与日志验收", 1)
    wave_rows = [
        ("01_Reset_Link", "差分时钟、复位、user_lnk_up、LTSSM、速率/宽度"),
        ("02_RP_TLP", "RQ/RC/CQ/CC valid/ready/last/keep/data/tuser"),
        ("03_TPI / DMA", "testname、BAR、read data、descriptor/status、本地 AXI 计数"),
        ("03_CQ_Host", "write bytes、packet、address、protocol errors、包上下文"),
        ("04_Endpoint_AXI", "AW/W/B/AR/R 五通道及 AXI-Lite"),
        ("04_RTDS_FDMA", "read/write request、addr、size、busy、source_valid/accept、sticky"),
        ("05_Aurora_LL", "TX/RX data、SOF/EOF、rem、src/dst ready、channel/lane up"),
        ("06_XDMA_IRQ", "usr_irq_req/ack、msi_enable、INT/CLEAR/CPU_REC 状态"),
        ("07_Result", "各 milestone 与 test_error_count"),
    ]
    add_table(doc, ["分组", "关键对象"], wave_rows, [2200, 7160])
    add_body(doc, "日志只比较语义里程碑，不比较绝对时间戳、临时路径或许可证信息。成功必须同时出现 RTDS_ROOTPORT_RESULT ... errors=0、RTDS_ROOTPORT_PASS、RTDS_LOG_COMPARE_PASS，并且 unexpected_warnings=0、fatal_lines=0。")
    add_table(
        doc,
        ["仿真时间窗", "事件"],
        [
            ("0～228.49 us", "复位、链路训练、枚举与 BAR。"),
            ("228.49～245.73 us", "MSI、user IRQ、INFO_EXCH。"),
            ("245.73～261.94 us", "基础 H2C/C2H。"),
            ("261.94～263.30 us", "CPU→Aurora。"),
            ("263.30～273.99 us", "Aurora→CPU、IRQ、read-clear、第二次 C2H。"),
            ("274.094 us", "最终 PASS 与 $finish。"),
        ],
        [2200, 7160],
    )
    add_heading(doc, "14.1 最终清洁 WaveMode 回归结果", 2)
    add_table(
        doc,
        ["项目", "最终结果"],
        [
            ("开始/结束", "2026-07-24 12:12:54 ～ 12:35:42（UTC+8），墙钟约 22 分 48 秒"),
            ("XSim 终点", "274.094 us"),
            ("detached", "state=completed，exit_code=0，accepted=true"),
            ("功能/日志", "RTDS_ROOTPORT_PASS；RTDS_LOG_COMPARE_PASS"),
            ("错误门禁", "errors=0；unexpected_warnings=0；fatal_lines=0"),
            ("WDB", "24,521,538 B；SHA-256 2b4814207fafce67f89132bb08512bb4f6d7f3eacefe7eacfd8865c836df2440"),
            ("WCFG", "796 B；SHA-256 65f56e00e8d1babc5b6e71e3105df4a0f628cd115115b78187d9cacf87aeecee"),
            ("日志哈希", "simulate.log 83e32043…db403；summary.json b1272471…d6090"),
            ("归档", "logs/final_wave_20260724_123542"),
        ],
        [2200, 7160],
        font_size=8.1,
    )
    add_body(doc, "最终日志识别到 7 条 warning（simulate 6 条、prepare 1 条），全部命中逐条确认的精确 Xilinx 模型白名单；packed CQ tuser 位切片导致的 Simtcl 6-197/6-55 已通过仅记录完整向量消除，未加入白名单。")

    add_heading(doc, "15. 已知边界与后续回归", 1)
    for item in [
        "Root Port 大仿真使用 LocalLink BFM，不覆盖 Aurora 64B/66B 编码、GT、CDR、极性和真实链路误码。",
        "CQ Host-memory sink 不是操作系统/IOMMU/CPU cache 模型；posted write 的真实平台排序仍需上板。",
        "MSI 仿真覆盖硬件消息链，驱动 ISR 和 OS 中断路由需软件联调。",
        "最小门槛为单次 512 B；1 KiB、32 KiB、连续传输和压力回归作为后续扩展。",
        "Aurora→FPGA 方向不把随机 ready 撤销当作合法测试；该方向重点验证持续吞吐和溢出检测。",
        "descriptor count 按每次事务独立确认 count=1/status=0x6，不作为跨事务单调计数器使用。",
    ]:
        add_bullet(doc, item, bullet_num_id)

    add_heading(doc, "附录 A：关键文件与复现入口", 1)
    add_table(
        doc,
        ["类别", "路径/文件"],
        [
            ("生产顶层", "RTDS_test-1ch/RTDS_test.srcs/sources_1/new/TOP.v"),
            ("PCIe 集成", "RTDS_test-1ch/RTDS_test.srcs/sources_1/new/PCIe.v"),
            ("Adapter", "RTDS_test-1ch/RTDS_test.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v"),
            ("寄存器", "RTDS_test-1ch/RTDS_test.srcs/sources_1/new/INFO_EXCH.v"),
            ("验证环境", "RTDS_test-1ch/regression/sim_xdma_rootport"),
            ("运行", "run_xsim_detached.ps1 -RebuildSnapshot -WaveMode -WallClockTimeoutMinutes 120"),
            ("查看波形", "open_final_wdb.ps1（只读打开 final_wave_* 的 WDB/WCFG）"),
            ("问题台账", "docs/RTDS_test_XDMA_RootPort问题发现与处理台账.md"),
        ],
        [1800, 7560],
        font_size=8.2,
    )
    add_heading(doc, "附录 B：验证环境地址约定", 1)
    add_table(
        doc,
        ["用途", "地址", "长度"],
        [
            ("H2C descriptor", "Host 0x100", "descriptor"),
            ("C2H descriptor", "Host 0x300", "descriptor"),
            ("Host 源数据", "Host 0x400", "512 B"),
            ("Host 目标数据", "Host 0x800", "512 B"),
            ("CPU→Aurora 卡端窗口", "Card 0x8000", "512 B"),
            ("Aurora→CPU 卡端窗口", "Card 0x0000", "512 B"),
        ],
        [3600, 3000, 2760],
    )

    add_heading(doc, "附录 C：PCIe.v 完整信号词典", 1)
    add_body(doc, "本附录覆盖远程机现行 PCIe.v 中的端口、localparam 与内部 wire。纯物理差分对和同组直连信号允许合并说明，但每个源码标识符均显式列出。")
    add_heading(doc, "C.1 端口", 2)
    pcie_port_rows = [
        ("pcie_mgt_rxn / pcie_mgt_rxp", "输入，各[1:0]", "PCIe RX 两条差分 lane；直接进入 design_1_wrapper。", "物理差分输入，不参与用户逻辑组合。"),
        ("pcie_mgt_txn / pcie_mgt_txp", "输出，各[1:0]", "design_1_wrapper 的 PCIe TX 两条差分 lane。", "直接送 TOP 板级管脚。"),
        ("pcie_diff_clk_n / pcie_diff_clk_p", "输入，各[0:0]", "PCIe 100 MHz 差分参考时钟。", "只连接 XDMA Endpoint。"),
        ("pcie_rst_n", "输入，1 bit", "板级 PCIe PERST#，低有效。", "直接连接 design_1_wrapper.pcie_rst_n。"),
        ("user_lnk_up", "输出，1 bit", "assign user_lnk_up=user_lnk_up_int。", "保持原顶层可见链路状态；业务门控在 Adapter 内完成。"),
        ("FPGA_TEMP_W", "输入，[31:0]", "板级温度/遥测值。", "透传到 INFO_EXCH 路径，不改变寄存器语义。"),
        ("i_sys_clk", "输入，1 bit", "FDMA/CONV_DMA/INFO/ILA 主时钟。", "连接 fdma_clk、sys_clk 和 ILA clk。"),
        ("i_sys_rst", "输入，1 bit，高有效", "PCIe 集成逻辑系统复位。", "取反生成 fdma_rstn/sys_rst_n。"),
        ("aurora_user_clk", "输入，1 bit", "Aurora LocalLink 用户时钟。", "Adapter 用户域时钟。"),
        ("aurora_user_rstn", "输入，1 bit，低有效", "Aurora 用户域复位。", "Adapter 用户域及局部 TX/RX reset 的基础条件。"),
        ("aurora_channel_up / aurora_lane_up", "输入，各1 bit", "Aurora channel/lane 训练完成状态。", "Adapter 同步到 fdma 域并与 PCIe link 相与。"),
        ("aurora_tx_d", "输出，[63:0]", "Adapter TX bridge 的 LocalLink payload。", "仅 src_rdy&&dst_rdy 时消费。"),
        ("aurora_tx_sof / aurora_tx_eof", "输出，各1 bit", "TX 首拍/末拍标志。", "与对应 data/rem 一起在 stall 时保持。"),
        ("aurora_tx_rem", "输出，[2:0]", "TX 末拍有效字节编码。", "固定满 512 B 帧末拍为 3'b111。"),
        ("aurora_tx_src_rdy", "输出，1 bit", "TX 数据/帧界有效。", "与 aurora_tx_dst_rdy 共同形成 TX 握手。"),
        ("aurora_tx_dst_rdy", "输入，1 bit", "Aurora TX 接收能力。", "为0时 Adapter 保持当前 TX beat。"),
        ("aurora_rx_d", "输入，[63:0]", "Aurora→Adapter payload。", "在 RX 真握手时写入异步 FIFO。"),
        ("aurora_rx_sof / aurora_rx_eof", "输入，各1 bit", "RX 首拍/末拍标志。", "进入 Adapter 64-beat 帧检查器。"),
        ("aurora_rx_rem", "输入，[2:0]", "RX 末拍有效字节编码。", "完整帧 EOF 拍必须为 3'b111。"),
        ("aurora_rx_src_rdy", "输入，1 bit", "RX 数据有效。", "与 aurora_rx_dst_rdy 共同形成 rx_hs。"),
        ("aurora_rx_dst_rdy", "输出，1 bit", "RX FIFO 当拍接收能力。", "下降视为吞吐/容量异常，不能作为线路长期反压。"),
    ]
    add_table(doc, ["信号", "方向/宽度", "产生/连接", "设计语义"], pcie_port_rows, [2300, 1500, 2850, 2710], font_size=7.2)
    add_heading(doc, "C.2 固定参数与内部网络", 2)
    pcie_internal_rows = [
        ("FRAME_BYTES", "integer=512", "PCIe.v 固定参数", "传给 Adapter；帧字节数。"),
        ("ACTIVE_WINDOW_BYTES", "integer=32768", "PCIe.v 固定参数", "传给 Adapter；每方向活动窗口。"),
        ("RX_BASE_ADDR_LO", "[31:0]=0", "PCIe.v 固定参数", "Aurora→CPU 写窗口基址。"),
        ("TX_BASE_ADDR_LO", "[31:0]=0x8000", "PCIe.v 固定参数", "CPU→Aurora 读窗口基址。"),
        ("CARD_ADDR_HI", "[31:0]=0", "PCIe.v 固定参数", "64-bit card address 高位。"),
        ("fdma_raddr", "[63:0] / fdma", "Adapter 输出", "FDMA read 地址，送 CONV_DMA；ILA 只取低32位。"),
        ("fdma_rareq", "1 / fdma", "Adapter 输出", "FDMA read 请求；rbusy 接受前保持。"),
        ("fdma_rbusy", "1 / fdma", "CONV_DMA 输出", "read 请求接受/通道忙状态，返回 Adapter。"),
        ("fdma_rdata", "[63:0] / fdma", "CONV_DMA 输出", "共享内存 read payload，送 TX bridge。"),
        ("fdma_rsize", "[15:0] / fdma", "Adapter 输出", "read burst beat 数，512 B 时固定64。"),
        ("fdma_rvalid", "1 / fdma", "CONV_DMA 输出", "read data valid。"),
        ("fdma_rready", "1 / fdma", "Adapter 输出", "TX bridge/FIFO 接收能力；与 rvalid 真握手。"),
        ("fdma_waddr", "[63:0] / fdma", "Adapter 输出", "FDMA write 地址，送 CONV_DMA。"),
        ("fdma_wareq", "1 / fdma", "Adapter 输出", "FDMA write 请求；wbusy 接受前保持。"),
        ("fdma_wbusy", "1 / fdma", "CONV_DMA 输出", "write 请求接受/通道忙状态。"),
        ("fdma_wdata", "[63:0] / fdma", "Adapter 输出", "RX FIFO 读出的 write payload。"),
        ("fdma_wsize", "[15:0] / fdma", "Adapter 输出", "write burst beat 数，固定64。"),
        ("fdma_w_source_valid", "1 / fdma", "Adapter.fdma_wvalid", "真实写数据 source-valid；连接 BD.fdma_wready_0。"),
        ("fdma_w_accept", "1 / fdma", "BD.fdma_wvalid_0", "真实写数据 accept；连接 Adapter.fdma_wready。"),
        ("FPGA_CPU_START_ADDR", "[31:0] / fdma", "Adapter 输出", "完整 RX burst 的 card memory 起始地址，送 INFO_EXCH。"),
        ("FPGA_CPU_LEN", "[31:0] / fdma", "Adapter 输出", "RX 可读取长度，当前固定512字节。"),
        ("CPU_FPGA_START_ADDR", "[31:0] / fdma", "INFO_EXCH 输出", "软件下发 TX card memory 起始地址。"),
        ("CPU_FPGA_LEN", "[31:0] / fdma", "INFO_EXCH 输出", "软件下发 TX 字节长度。"),
        ("CLEAR_INTER_R", "1 / fdma", "INFO_EXCH 输出", "软件读清/清中断脉冲，送 Adapter.clear_inter。"),
        ("CPU_REC_STATE_R", "1 / fdma", "INFO_EXCH 输出", "软件 RX ownership 确认电平。"),
        ("CPU_REC_STATE_W", "1 / fdma", "Adapter 输出", "cpu_rec_state_r 的硬件镜像/回读状态。"),
        ("INT_STATE_W", "1 / fdma", "Adapter 输出", "RX 通知 sticky 状态，送 INFO_EXCH。"),
        ("INT_STATE_R", "1 / fdma", "INFO_EXCH 输出", "INT_STATE read-clear 事件，送 Adapter.int_state_clear。"),
        ("RD_START", "1 / fdma", "INFO_EXCH 输出", "CPU_WR_DONE 上升沿形成的 TX 启动脉冲。"),
        ("CPU_WR_DONE_resp", "1 / fdma", "Adapter 输出", "硬件持有 TX 命令的生命周期指示。"),
        ("FPGA_CPU_irq_req", "1 / fdma", "Adapter 输出", "RX 完成用户 IRQ 请求，送 XDMA。"),
        ("user_lnk_up_int", "1 / XDMA", "design_1_wrapper 输出", "XDMA 链路状态；透传 user_lnk_up 并输入 Adapter。"),
        ("rx_fifo_almost_full", "1 / fdma观测", "Adapter 输出", "RX FIFO almost-full 同步状态。"),
        ("rx_fifo_full", "1 / fdma观测", "Adapter 输出", "RX FIFO full 同步状态。"),
        ("rx_overflow_sticky", "1 / fdma", "Adapter 输出", "RX 容量/ready 异常锁存。"),
        ("rx_overrun_sticky", "1 / fdma", "Adapter 输出", "CPU 未归还 buffer 时新 burst 完成。"),
        ("tx_underflow_sticky", "1 / fdma", "Adapter 输出", "TX 供数不足锁存。"),
        ("fdma_timeout_sticky", "1 / fdma", "Adapter 输出", "FDMA 等待无进展超时锁存。"),
        ("length_error_sticky", "1 / fdma", "Adapter 输出", "TX 配置或 RX 帧规格错误锁存。"),
        ("link_down_sticky", "1 / fdma", "Adapter 输出", "命令时/活动期/曾up后掉链锁存。"),
        ("rx_pending", "1 / fdma", "Adapter 输出", "RX buffer 所有权已交给 CPU。"),
        ("adapter_tx_state_dbg", "[3:0] / fdma", "Adapter 输出", "TX bridge 状态码，ILA probe13。"),
        ("adapter_rx_state_dbg", "[3:0] / fdma", "Adapter 输出", "RX bridge 状态码，ILA probe12。"),
    ]
    add_table(doc, ["信号", "宽度/域", "产生者", "实现含义"], pcie_internal_rows, [2300, 1600, 2200, 3260], font_size=7.0)

    add_heading(doc, "附录 D：Adapter 完整信号词典", 1)
    add_body(doc, "本附录按端口与内部逻辑组解释远程机现行 pcie_fdma_aurora_brg_adapter.v 的全部非局部临时信号。调试总线按整体及被使用位说明；仅为边沿恢复而存在的一级延迟寄存器仍列入，避免代码实现时遗漏 CDC 配对关系。")
    add_heading(doc, "D.1 参数与端口", 2)
    adapter_port_rows = [
        ("FRAME_BYTES", "parameter integer", "512", "帧字节数；当前必须为512。"),
        ("ACTIVE_WINDOW_BYTES", "parameter integer", "32768", "每方向低地址窗口；必须是帧长整数倍。"),
        ("RX_BASE_ADDR_LO", "parameter [31:0]", "0x00000000", "RX FDMA write 基址。"),
        ("TX_BASE_ADDR_LO", "parameter [31:0]", "0x00008000", "TX FDMA read 最低合法基址。"),
        ("CARD_ADDR_HI", "parameter [31:0]", "0", "FDMA 64-bit 地址高32位。"),
        ("FDMA_TIMEOUT_CYCLES", "parameter integer", "65535", "无进展等待超时门槛。"),
        ("fdma_clk / fdma_rstn", "输入 / 低有效复位", "FDMA、INFO、IRQ主域", "所有控制寄存器和最终 sticky 所在域。"),
        ("aurora_user_clk / aurora_user_rstn", "输入 / 低有效复位", "Aurora LocalLink 用户域", "LL TX/RX、帧检查和源域 sticky 所在域。"),
        ("pcie_link_up", "输入 1", "XDMA link / fdma域", "同步到 user 域；两个域业务放行条件之一。"),
        ("aurora_channel_up", "输入 1", "Aurora / user域", "本域直接使用并同步到 fdma 域。"),
        ("aurora_lane_up", "输入 1", "Aurora / user域", "本域直接使用并同步到 fdma 域。"),
        ("aurora_tx_d", "输出 [63:0]", "TX bridge", "FPGA→Aurora payload。"),
        ("aurora_tx_sof / aurora_tx_eof", "输出各1", "TX bridge", "首/末拍标志，stall 时保持。"),
        ("aurora_tx_rem", "输出 [2:0]", "TX bridge", "末拍有效字节编码。"),
        ("aurora_tx_src_rdy / aurora_tx_dst_rdy", "输出/输入", "TX bridge ↔ Aurora", "二者同时为1才消费一个 TX beat。"),
        ("aurora_rx_d", "输入 [63:0]", "Aurora", "Aurora→FPGA payload。"),
        ("aurora_rx_sof / aurora_rx_eof", "输入各1", "Aurora", "RX 帧界，送 bridge 与帧检查器。"),
        ("aurora_rx_rem", "输入 [2:0]", "Aurora", "EOF 拍有效字节编码。"),
        ("aurora_rx_src_rdy / aurora_rx_dst_rdy", "输入/输出", "Aurora ↔ RX bridge", "二者同时为1形成 rx_hs；valid&&!ready 置 overflow。"),
        ("rd_start", "输入 1 / fdma", "INFO_EXCH", "TX 命令请求脉冲。"),
        ("cpu_fpga_start_addr", "输入 [31:0] / fdma", "INFO_EXCH", "TX card memory 起始低地址。"),
        ("cpu_fpga_len", "输入 [31:0] / fdma", "INFO_EXCH", "TX 字节长度。"),
        ("cpu_wr_done_resp", "输出 reg 1 / fdma", "TX 事务寄存器", "tx_active 生命周期指示。"),
        ("fpga_cpu_start_addr", "输出 reg [31:0] / fdma", "RX 通知逻辑", "新完整 RX burst 的 card address。"),
        ("fpga_cpu_len", "输出 reg [31:0] / fdma", "RX 通知逻辑", "新完整 RX burst 字节数，固定512。"),
        ("int_state_w", "输出 1 / fdma", "int_state_w_r", "软件可读 RX 中断状态。"),
        ("int_state_clear", "输入 1 / fdma", "INFO_EXCH", "只清 IRQ/INT，不清 pending。"),
        ("clear_inter", "输入 1 / fdma", "INFO_EXCH", "清 IRQ/INT/最终 sticky，并触发 user 域 clear。"),
        ("cpu_rec_state_r", "输入 1 / fdma", "INFO_EXCH", "上升沿归还 RX buffer ownership。"),
        ("cpu_rec_state_w", "输出 reg 1 / fdma", "RX 所有权逻辑", "cpu_rec_state_r 镜像。"),
        ("fpga_cpu_irq_req", "输出 reg 1 / fdma", "RX 通知逻辑", "XDMA user IRQ 请求，保持至 clear。"),
        ("fdma_raddr / fdma_rareq / fdma_rsize", "输出 64/1/16", "TX bridge+地址适配", "FDMA read 请求描述；size=64 beat。"),
        ("fdma_rbusy", "输入 1", "CONV_DMA", "read 请求接受/忙。"),
        ("fdma_rdata / fdma_rvalid / fdma_rready", "输入64/输入1/输出1", "CONV_DMA ↔ TX bridge", "rvalid&&rready 时一个 read beat 进入 FIFO。"),
        ("fdma_waddr / fdma_wareq / fdma_wsize", "输出 64/1/16", "RX bridge+地址适配", "FDMA write 请求描述；size=64 beat。"),
        ("fdma_wbusy", "输入 1", "CONV_DMA", "write 请求接受/忙。"),
        ("fdma_wdata / fdma_wvalid / fdma_wready", "输出64/输出1/输入1", "RX bridge ↔ CONV_DMA", "标准语义下 valid&&ready 提交一个 write beat。"),
        ("rx_fifo_almost_full / rx_fifo_full", "输出各1 / fdma观测", "user域水位同步", "瞬时 FIFO 水位；不属于 sticky。"),
        ("rx_overflow_sticky", "输出1 / fdma", "最终 sticky", "RX FIFO/ready 容量异常。"),
        ("rx_overrun_sticky", "输出1 / fdma", "所有权逻辑", "pending 期间新 burst 完成。"),
        ("tx_underflow_sticky", "输出1 / fdma", "最终 sticky", "TX bridge 供数不足。"),
        ("fdma_timeout_sticky", "输出1 / fdma", "最终 sticky", "FDMA 等待无进展。"),
        ("length_error_sticky", "输出1 / fdma", "最终 sticky", "TX 配置或 RX 帧规格错误。"),
        ("link_down_sticky", "输出1 / fdma", "最终 sticky", "业务链路异常。"),
        ("rx_pending", "输出1 / fdma", "rx_pending_r", "CPU 持有 RX buffer。"),
        ("dbg_tx_state / dbg_rx_state", "输出各[3:0]", "debug bus 位切片", "ILA 状态观测，不参与控制。"),
    ]
    add_table(doc, ["信号", "方向/宽度", "来源/当前值", "实现含义"], adapter_port_rows, [2600, 1750, 2350, 2660], font_size=6.9)
    add_heading(doc, "D.2 内部派生、状态与 CDC 信号", 2)
    adapter_internal_rows = [
        ("FRAME_WORDS", "integer=64", "FRAME_BYTES/8", "内部 64-bit word 数。"),
        ("FRAME_BYTES_32", "[31:0]=512", "FRAME_BYTES 宽度适配", "写入 fpga_cpu_len。"),
        ("FRAME_WORDS_16", "[15:0]=64", "FRAME_WORDS 宽度适配", "驱动 fdma_rsize/fdma_wsize。"),
        ("pcie_link_up_user", "1 / user", "pcie_link_up 经 xpm_cdc_single", "参与 link_up_user。"),
        ("aurora_channel_up_fdma", "1 / fdma", "aurora_channel_up 经 xpm_cdc_single", "参与 link_up_fdma。"),
        ("aurora_lane_up_fdma", "1 / fdma", "aurora_lane_up 经 xpm_cdc_single", "参与 link_up_fdma。"),
        ("link_up_user", "1 / user", "pcie_link_up_user&&channel_up&&lane_up", "用户域业务总放行。"),
        ("link_up_fdma", "1 / fdma", "pcie_link_up&&channel_up_fdma&&lane_up_fdma", "FDMA域业务总放行。"),
        ("tx_active", "reg 1 / fdma", "合法命令置位；完成/掉链清零", "当前 TX 命令硬件所有权。"),
        ("tx_target_frames", "reg [15:0] / fdma", "requested_frames_32[15:0]", "当前命令目标帧数。"),
        ("tx_completed_frames", "reg [15:0] / fdma", "每个 tx_frame_done_fdma 累加", "已完成 LL 帧数。"),
        ("tx_base_addr_lo", "reg [31:0] / fdma", "tx_start_valid 时锁存软件地址", "TX raw address 的外部基址。"),
        ("tx_requested_end", "wire [32:0] / fdma", "{0,start}+{0,len}", "33-bit 命令半开区间结束地址，检测回绕。"),
        ("tx_window_end", "wire [32:0] / fdma", "{0,TX_BASE}+window", "TX 合法窗口半开区间上界。"),
        ("tx_addr_aligned", "wire 1 / fdma", "start & (FRAME_BYTES-1)==0", "起始地址 512B 对齐条件。"),
        ("tx_len_aligned", "wire 1 / fdma", "len & (FRAME_BYTES-1)==0", "长度 512B 对齐条件。"),
        ("tx_config_valid", "wire 1 / fdma", "非零/对齐/长度/窗口/回绕合取", "软件 TX 配置总合法条件。"),
        ("tx_start_valid", "wire 1 / fdma", "rd_start&&!tx_active&&link_up_fdma&&config", "唯一接管命令事件。"),
        ("tx_config_error_event", "wire 1 / fdma", "rd_start&&(!config||tx_active)", "置 length_error_sticky。"),
        ("tx_start_link_error", "wire 1 / fdma", "rd_start&&!link_up_fdma", "置 link_down_sticky。"),
        ("requested_frames_32", "wire [31:0] / fdma", "cpu_fpga_len/FRAME_BYTES", "锁存目标帧数的完整计算结果。"),
        ("tx_active_user", "wire 1 / user", "tx_active 经 xpm_cdc_single", "用户域 TX 子桥使能。"),
        ("tx_fdma_rstn", "wire 1 / fdma", "fdma_rstn&&link_up_fdma&&tx_active", "TX bridge FDMA 侧局部复位。"),
        ("tx_user_rstn", "wire 1 / user", "aurora_user_rstn&&link_up_user&&tx_active_user", "TX bridge user 侧局部复位。"),
        ("tx_fdma_raddr_raw", "wire [31:0] / fdma", "TX bridge 输出", "窗口内相对 read 地址。"),
        ("tx_fdma_dbg_bus", "wire [37:0] / fdma", "TX bridge debug", "[37:36] 映射 dbg_tx_state。"),
        ("tx_user_dbg_bus", "wire [38:0] / user", "TX bridge debug", "[0] 提供 tx_underflow_user。"),
        ("tx_frame_done_user", "wire 1 / user", "TX bridge EOF 真握手", "驱动完成 toggle。"),
        ("tx_done_toggle_user", "reg 1 / user", "每帧完成翻转", "窄脉冲跨域源编码。"),
        ("tx_done_toggle_fdma", "wire 1 / fdma", "toggle 经 xpm_cdc_single", "目的域同步 toggle。"),
        ("tx_done_toggle_fdma_d", "reg 1 / fdma", "同步 toggle 延迟一拍", "与当前值异或恢复边沿。"),
        ("tx_frame_done_fdma", "wire 1 / fdma", "toggle_fdma ^ toggle_fdma_d", "单周期 TX 帧完成事件。"),
        ("rx_fdma_rstn", "wire 1 / fdma", "fdma_rstn&&link_up_fdma", "RX bridge FDMA 侧局部复位。"),
        ("rx_user_rstn", "wire 1 / user", "aurora_user_rstn&&link_up_user", "RX bridge user 侧局部复位。"),
        ("rx_fdma_waddr_raw", "wire [31:0] / fdma", "RX bridge 输出", "窗口内相对 write 地址；用于通知地址。"),
        ("rx_fdma_wsize_raw", "wire [15:0] / fdma", "RX bridge 历史输出", "byte 语义，仅保留连接；外部 size 被覆盖为64 beat。"),
        ("rx_fdma_dbg_bus", "wire [105:0] / fdma", "RX bridge debug", "[41:40] 映射 dbg_rx_state。"),
        ("rx_user_dbg_bus", "wire [28:0] / user", "RX bridge debug", "用户域诊断总线，仅观测。"),
        ("rx_fifo_almost_full_user", "wire 1 / user", "RX FIFO", "同步到 fdma 输出水位。"),
        ("rx_fifo_full_user", "wire 1 / user", "RX FIFO", "同步到 fdma 输出水位。"),
        ("rx_fifo_overflow_user", "wire 1 / user", "RX FIFO", "置 rx_overflow_user_sticky。"),
        ("rx_burst_done_fdma", "wire 1 / fdma", "RX bridge", "完整 FDMA write burst 完成；通知唯一完成条件。"),
        ("int_state_w_r", "reg 1 / fdma", "RX burst 完成置位；INT clear清零", "驱动 int_state_w。"),
        ("rx_pending_r", "reg 1 / fdma", "通知发布置位；cpu_rec_ack清零", "RX buffer ownership。"),
        ("rx_overrun_sticky_r", "reg 1 / fdma", "pending期间新burst置位", "驱动 rx_overrun_sticky；ack清除。"),
        ("cpu_rec_state_d", "reg 1 / fdma", "cpu_rec_state_r 延迟一拍", "上升沿检测历史值。"),
        ("cpu_rec_ack", "wire 1 / fdma", "cpu_rec_state_r&&!cpu_rec_state_d", "释放 RX ownership 的单周期事件。"),
        ("status_clear_toggle_fdma", "reg 1 / fdma", "clear_inter 时翻转", "clear 跨到 user 域的源编码。"),
        ("status_clear_toggle_user", "wire 1 / user", "clear toggle 经同步", "user 域同步 toggle。"),
        ("status_clear_toggle_user_d", "reg 1 / user", "同步 toggle 延迟一拍", "边沿恢复历史值。"),
        ("status_clear_user", "wire 1 / user", "toggle_user ^ toggle_user_d", "清 user 源域 sticky 的单周期脉冲。"),
        ("rx_in_frame", "reg 1 / user", "SOF建立、EOF/掉链清除", "RX 帧上下文状态。"),
        ("rx_frame_word_count", "reg [8:0] / user", "每个 rx_hs 计数", "验证固定64-beat帧长。"),
        ("rx_length_error_user_sticky", "reg 1 / user", "帧界/长度/rem检查", "源域长度错误锁存。"),
        ("rx_overflow_user_sticky", "reg 1 / user", "FIFO overflow或valid&&!ready", "源域溢出锁存。"),
        ("tx_underflow_user_sticky", "reg 1 / user", "tx_underflow_user", "源域TX下溢锁存。"),
        ("rx_hs", "wire 1 / user", "aurora_rx_src_rdy&&aurora_rx_dst_rdy", "帧计数唯一推进条件。"),
        ("tx_underflow_user", "wire 1 / user", "tx_user_dbg_bus[0]", "TX bridge 下溢事件。"),
        ("rx_length_error_fdma", "wire 1 / fdma", "user sticky 经同步", "最终 length_error 的源之一。"),
        ("rx_overflow_fdma", "wire 1 / fdma", "user sticky 经同步", "最终 rx_overflow 的源。"),
        ("tx_underflow_fdma", "wire 1 / fdma", "user sticky 经同步", "最终 tx_underflow 的源。"),
        ("rx_overflow_sticky_r", "reg 1 / fdma", "同步错误且非hold时置位", "驱动最终 rx_overflow_sticky。"),
        ("tx_underflow_sticky_r", "reg 1 / fdma", "同步错误且非hold时置位", "驱动最终 tx_underflow_sticky。"),
        ("fdma_timeout_sticky_r", "reg 1 / fdma", "wait_count达门槛置位", "驱动最终 fdma_timeout_sticky。"),
        ("length_error_sticky_r", "reg 1 / fdma", "RX错误或TX配置错误置位", "驱动最终 length_error_sticky。"),
        ("link_down_sticky_r", "reg 1 / fdma", "链路错误置位", "驱动最终 link_down_sticky。"),
        ("seen_link_up", "reg 1 / fdma", "首次 link_up_fdma 后保持", "抑制上电训练未完成的假掉链。"),
        ("fdma_wait_count", "reg [31:0] / fdma", "waiting无progress时累加", "超时计数；progress/idle/clear清零。"),
        ("user_status_clear_hold", "reg 1 / fdma", "clear置位；三同步错误源全0清除", "抑制跨域旧高电平反弹。"),
        ("fdma_waiting", "wire 1 / fdma", "req或等rvalid/wready", "标识协议正等待。"),
        ("fdma_progress", "wire 1 / fdma", "request accept/data handshake/RX done", "任何真实推进事件。"),
    ]
    add_table(doc, ["信号", "宽度/域", "产生逻辑", "消费/约束"], adapter_internal_rows, [2600, 1650, 2700, 2410], font_size=6.8)

    add_heading(doc, "附录 E：设计规则到 RTL 实现的约束映射", 1)
    implementation_rows = [
        ("链路放行", "link_up_user / link_up_fdma", "三个链路状态在各自目标域同步后相与", "禁止异步原始状态直接进入状态机。"),
        ("TX 命令接管", "tx_start_valid", "rd_start&&!active&&link&&config", "只有该事件可锁存软件地址/长度。"),
        ("地址越界检测", "tx_requested_end[32:0]", "33-bit 半开区间加法", "禁止32-bit回绕后被误判为窗口内。"),
        ("TX 数据推进", "fdma_rvalid&&fdma_rready；src_rdy&&dst_rdy", "分别推进 FIFO 写侧与 LL 读侧", "stall 时不得改变当前 beat。"),
        ("TX 完成", "tx_frame_done_user→toggle→tx_frame_done_fdma", "EOF 真握手后跨域", "不得用 FDMA read 完成替代链路发送完成。"),
        ("RX 数据推进", "rx_hs；fdma_wvalid&&fdma_wready", "分别推进 LL 接收与 FDMA 写", "valid&&!ready 必须记录 overflow。"),
        ("RX 通知", "rx_burst_done_fdma", "完整 write burst 后发布 addr/len/IRQ", "不得在 Aurora EOF 时提前通知。"),
        ("RX 所有权", "rx_pending_r / cpu_rec_ack", "通知置位，CPU_REC_STATE上升沿清除", "INT clear 不得清 pending。"),
        ("端口命名兼容", "fdma_w_source_valid / fdma_w_accept", "Adapter.valid→BD.ready；BD.valid→Adapter.ready", "以真实语义判定握手。"),
        ("跨域清除", "status_clear_toggle + user_status_clear_hold", "toggle清源域，hold等同步源回0", "防止清除后的旧高电平反弹。"),
        ("FDMA超时", "fdma_waiting / fdma_progress / wait_count", "仅连续等待且无进展时累加", "正常持续传输不得因总时长触发。"),
        ("调试状态", "dbg_tx_state / dbg_rx_state / ILA", "只读观测", "禁止调试信号反馈功能控制。"),
    ]
    add_table(doc, ["设计主题", "RTL对象", "规范实现", "禁止行为"], implementation_rows, [1800, 2400, 3000, 2160], font_size=7.2)
    add_callout(doc, "源码覆盖口径", "远程机现行 PCIe.v 与 pcie_fdma_aurora_brg_adapter.v 的端口、参数、localparam、reg、wire 和被使用的 debug bus 位均已在附录 C/D 中解释。允许省略的仅为明显的物理差分正/负端或同组直连信号的重复文字，不省略任何控制、状态、握手、地址、长度、CDC、所有权或异常语义。", fill="E6F3EA", title_color=GREEN)

    # Prevent split of captions and compact callouts where possible.
    for p in doc.paragraphs:
        if p.style.name.startswith("Heading"):
            p.paragraph_format.keep_with_next = True

    doc.core_properties.title = "RTDS_test-1ch XDMA–Aurora 设计与验证方案规格书"
    doc.core_properties.subject = "设计架构、接口、数据流、时序与 Root Port 大仿真验证"
    doc.core_properties.author = "PCIE-CPU Project"
    doc.core_properties.keywords = "RTDS, XDMA, PCIe, Aurora, FDMA, Root Port, XSim"
    doc.save(OUT)
    print(OUT)


if __name__ == "__main__":
    build_document()
```
