# build_v24_docs

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\build_v24_docs.py`
- SHA-256: `2c103e2d38e5ab5c574db2abf4e1c16a028cec691a351a3b06ebb4700cfb17d1`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_v24_docs.py

```python
"""由V2.4 Markdown生成代码级详细设计DOCX。

版式采用documents skill的compact_reference_guide和memo_masthead。
按工作区规则，本脚本不调用LibreOffice，不生成PDF、PNG或页面截图。
"""

from __future__ import annotations

import argparse
import re
from collections import Counter
from pathlib import Path

from docx.enum.text import WD_ALIGN_PARAGRAPH
from docx.enum.table import WD_TABLE_ALIGNMENT
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Inches, Pt, RGBColor

from build_design_doc import (
    add_bullet,
    add_code,
    add_number,
    add_table,
    set_cell_shading,
)
from build_v2_docs import add_masthead, configure_doc
from v24_visual_catalog import (
    FORMAL_MODULES,
    MODULE_VISUALS,
    OVERALL_ARCHITECTURE_EXPLANATION,
    OVERALL_ARCHITECTURE_ROWS,
    OVERALL_DATA_FLOW,
    OVERALL_DATA_FLOW_EXPLANATION,
)


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
RTL = ROOT / "rtl"
FIGURES = DOCS / "figures_v24"
SOURCE = DOCS / "ADC_DDR_NVMe_V2.4_代码级详细设计方案.md"
OUT = DOCS / "NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解.docx"

DESIGN_PRESET = "compact_reference_guide"
HEADER_TEMPLATE = "memo_masthead"
TABLE_WIDTH_DXA = 9360
TABLE_INDENT_DXA = 120
BLUE = "1F4E78"
LIGHT_BLUE = "D9EAF7"
PALE_BLUE = "EAF3F8"
LIGHT_GRAY = "F2F2F2"

PORT_PATTERN = re.compile(
    r"^\s*(input|output|inout)\s+"
    r"(?:(?:wire|reg|logic)\s+)?"
    r"(?:(\[[^\]]+\])\s+)?"
    r"([A-Za-z_][A-Za-z0-9_$]*)\s*,?\s*$"
)

SECTION_CODES = {
    "nvme_adc_vitis_compat_top": "3-3",
    "adc_channel_packer": "5-1",
    "adc_capture_limit_controller": "6-1",
    "axis_async_fifo": "7-1",
    "adc_ddr_segment_writer": "8-1",
    "sync_fifo": "8-2",
    "segment_buffer_manager": "9-1",
    "nvme_request_scheduler": "11-1",
    "nophae_dma_backend": "11-2",
    "nvme_adc_pipeline_top": "11-3",
    "fdma_vitis_compat_regs": "13-1",
}


def set_core_properties(doc) -> None:
    core = doc.core_properties
    core.title = "NVMe_ADC_DDR_FPGA详细设计方案 V2.4"
    core.subject = "正式Vitis兼容RTL的代码级信号、电路/Visio架构图、数据流与高低电平时序设计"
    core.author = "项目组"
    core.keywords = (
        "ADC, DDR, NVMe, NoPHAE, Capture, Segment, Manager, alloc, "
        "Commit, circuit diagram, Visio, data flow, I/O, waveform, ready/valid, stall, sticky, V2.4"
    )


def clean_inline(value: str) -> str:
    value = value.strip()
    value = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", value)
    value = value.replace(chr(96), "").replace("**", "").replace("__", "")
    return value.replace(r"\|", "|")


def table_cells(line: str) -> list[str]:
    return [clean_inline(cell) for cell in line.strip().strip("|").split("|")]


def is_table_separator(line: str) -> bool:
    cells = table_cells(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells)


def table_widths(column_count: int) -> list[float]:
    if column_count == 2:
        return [1.75, 4.75]
    if column_count == 3:
        return [1.35, 2.25, 2.90]
    if column_count == 4:
        return [1.05, 1.65, 1.85, 1.95]
    if column_count == 5:
        return [1.05, 1.25, 1.05, 1.25, 1.90]
    if column_count == 6:
        return [0.55, 0.80, 0.95, 0.65, 1.25, 2.30]
    width = 6.5 / column_count
    return [width] * column_count


def widths_to_dxa(widths: list[float]) -> list[int]:
    values = [round(width * 1440) for width in widths]
    values[-1] += TABLE_WIDTH_DXA - sum(values)
    return values


def set_or_create(parent, tag: str) -> OxmlElement:
    node = parent.find(qn(tag))
    if node is None:
        node = OxmlElement(tag)
        parent.append(node)
    return node


def normalize_table_geometry(table, widths: list[float]) -> None:
    """把表格总宽、缩进、网格列和每格宽度固定为DXA。"""

    dxa = widths_to_dxa(widths)
    table.autofit = False
    table.alignment = WD_TABLE_ALIGNMENT.LEFT
    tbl_pr = table._tbl.tblPr

    tbl_w = set_or_create(tbl_pr, "w:tblW")
    tbl_w.set(qn("w:type"), "dxa")
    tbl_w.set(qn("w:w"), str(TABLE_WIDTH_DXA))

    tbl_ind = set_or_create(tbl_pr, "w:tblInd")
    tbl_ind.set(qn("w:type"), "dxa")
    tbl_ind.set(qn("w:w"), str(TABLE_INDENT_DXA))

    layout = set_or_create(tbl_pr, "w:tblLayout")
    layout.set(qn("w:type"), "fixed")

    grid = table._tbl.tblGrid
    for child in list(grid):
        grid.remove(child)
    for width in dxa:
        col = OxmlElement("w:gridCol")
        col.set(qn("w:w"), str(width))
        grid.append(col)

    for row in table.rows:
        if len(row.cells) != len(dxa):
            raise RuntimeError("Merged or irregular table is not supported")
        for index, cell in enumerate(row.cells):
            tc_w = set_or_create(cell._tc.get_or_add_tcPr(), "w:tcW")
            tc_w.set(qn("w:type"), "dxa")
            tc_w.set(qn("w:w"), str(dxa[index]))


def add_v24_table(doc, headers: list[str], rows: list[list[str]]):
    widths = table_widths(len(headers))
    table = add_table(doc, headers, rows, widths)
    normalize_table_geometry(table, widths)
    return table


def add_caption(doc, text: str):
    paragraph = doc.add_paragraph(style="Caption")
    paragraph.paragraph_format.keep_with_next = True
    paragraph.paragraph_format.space_before = Pt(6)
    paragraph.paragraph_format.space_after = Pt(4)
    run = paragraph.add_run(text)
    run.bold = True
    return paragraph


def style_diagram_table(table) -> None:
    """把普通固定表格改成可编辑的三泳道架构图。"""

    for row_index, row in enumerate(table.rows):
        for col_index, cell in enumerate(row.cells):
            fill = LIGHT_BLUE if row_index == 0 else (
                PALE_BLUE if col_index == 1 else LIGHT_GRAY
            )
            set_cell_shading(cell, fill)
            for paragraph in cell.paragraphs:
                paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.paragraph_format.space_after = Pt(0)
                for run in paragraph.runs:
                    run.font.size = Pt(8.5 if row_index == 0 else 8.2)
                    if row_index == 0 or col_index == 1:
                        run.bold = True


def add_architecture_diagram(doc, rows: list[list[str]]):
    table = add_table(
        doc,
        ["I / 上游 →", "模块内部结构", "→ O / 下游"],
        rows,
        [1.90, 2.70, 1.90],
    )
    normalize_table_geometry(table, [1.90, 2.70, 1.90])
    style_diagram_table(table)
    return table


def parse_module_ports(module_name: str) -> list[dict[str, str]]:
    """按模块头顺序提取端口；语义直接使用端口行中文注释。"""

    source = RTL / f"{module_name}.sv"
    if not source.is_file():
        raise RuntimeError(f"Missing formal RTL module: {source}")

    ports: list[dict[str, str]] = []
    collecting = False
    for raw in source.read_text(encoding="utf-8").splitlines():
        code, _, comment = raw.partition("//")
        match = PORT_PATTERN.match(code)
        if match:
            collecting = True
            direction, width, name = match.groups()
            ports.append(
                {
                    "direction": direction,
                    "width": width[1:-1] if width else "1",
                    "name": name,
                    "meaning": comment.strip() or "模块端口；以相邻状态机和赋值处说明为准",
                }
            )
            continue
        if collecting and raw.strip() == ");":
            break

    if not ports:
        raise RuntimeError(f"No module-header ports parsed from {source}")
    return ports


def port_domain(module_name: str, signal: str) -> str:
    if signal in {"adc_clk", "s_clk"}:
        return "adc_clk/写侧"
    if signal in {"sys_clk", "m_clk"}:
        return "sys_clk/读侧"
    if signal == "clk":
        return "clk"
    if signal.endswith("rst_n"):
        if signal.startswith(("adc_", "s_")):
            return "adc_clk/写侧"
        if signal.startswith("m_"):
            return "sys_clk/读侧"
        return "clk对应域"
    if module_name == "adc_capture_limit_controller":
        if signal.endswith("_sys") or "_sys" in signal or signal.startswith("controller_busy"):
            return "sys_clk"
        return "adc_clk"
    if module_name == "axis_async_fifo":
        if signal.startswith("s_") or signal in {"full", "prog_full", "wr_used_count"}:
            return "s_clk"
        return "m_clk"
    if module_name == "adc_channel_packer":
        return "adc_clk"
    if module_name in {
        "adc_ddr_segment_writer",
        "sync_fifo",
        "segment_buffer_manager",
        "nvme_request_scheduler",
        "nophae_dma_backend",
        "fdma_vitis_compat_regs",
    }:
        return "clk"
    if module_name == "nvme_adc_pipeline_top":
        if signal.startswith("adc_") or signal.startswith("capture_") or signal.startswith("cfg_"):
            return "adc_clk/跨域"
        return "sys_clk"
    if module_name == "nvme_adc_vitis_compat_top":
        if signal.startswith("adc_") or signal in {"capture_active", "capture_ready"}:
            return "adc_clk/跨域"
        return "sys_clk"
    return "见模块时钟"


def port_group(signal: str) -> str:
    rules = (
        (("s_axi_fdma_", "s_axi_"), "软件AXI-Lite"),
        (("m_axi_ddr_",), "DDR AXI写"),
        (("m_axi_nophae_",), "NoPHAE AXI-Lite"),
        (("m_axi_",), "AXI主接口"),
        (("s_axis_",), "输入流"),
        (("m_axis_",), "输出流"),
        (("alloc_",), "alloc握手"),
        (("fill_",), "fill描述符"),
        (("ready_",), "ready描述符"),
        (("completion_", "manager_completion_"), "Completion"),
        (("commit_",), "Commit"),
        (("nvme_req_",), "NVMe请求"),
        (("nvme_cpl_", "cpl_"), "NVMe完成"),
        (("cfg_", "active_"), "Capture配置"),
        (("capture_", "session_"), "Capture控制"),
        (("adc_",), "ADC数据/诊断"),
        (("ecqe_", "pcie_", "nvme_init_", "ddr_init_"), "运行状态"),
        (("clk", "rst_n", "sys_", "enable"), "时钟/复位/使能"),
    )
    for prefixes, group in rules:
        if signal.startswith(prefixes):
            return group
    return "状态/诊断"


def interface_rows(module_name: str) -> list[list[str]]:
    direction_names = {"input": "I", "output": "O", "inout": "I/O"}
    rows = []
    for port in parse_module_ports(module_name):
        rows.append(
            [
                port_group(port["name"]),
                port["name"],
                direction_names[port["direction"]],
                port["width"],
                port_domain(module_name, port["name"]),
                port["meaning"],
            ]
        )
    return rows


def add_interface_table(doc, module_name: str):
    widths = [0.78, 1.48, 0.42, 0.77, 0.83, 2.22]
    table = add_table(
        doc,
        ["接口组", "信号", "I/O", "位宽", "时钟域", "语义"],
        interface_rows(module_name),
        widths,
    )
    normalize_table_geometry(table, widths)
    for row_index, row in enumerate(table.rows):
        for col_index, cell in enumerate(row.cells):
            for paragraph in cell.paragraphs:
                paragraph.paragraph_format.line_spacing = 1.0
                paragraph.paragraph_format.space_after = Pt(0)
                if col_index in {0, 2, 3, 4}:
                    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
                for run in paragraph.runs:
                    run.font.size = Pt(7.6 if row_index else 8.1)
                    if row_index and col_index == 1:
                        run.font.name = "Courier New"
                        run._element.rPr.rFonts.set(qn("w:eastAsia"), "微软雅黑")
    return table


def add_explanation(doc, title: str, paragraphs: list[str]) -> None:
    heading = doc.add_heading(title, level=3)
    heading.paragraph_format.keep_with_next = True
    for item in paragraphs:
        add_bullet(doc, item)


def add_inline_circuit_figure(doc, image_name: str, description: str) -> None:
    path = FIGURES / image_name
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"Missing circuit/Visio figure: {path}")
    paragraph = doc.add_paragraph()
    paragraph.alignment = WD_ALIGN_PARAGRAPH.CENTER
    paragraph.paragraph_format.keep_with_next = True
    paragraph.paragraph_format.space_after = Pt(4)
    shape = paragraph.add_run().add_picture(str(path), width=Inches(6.28))
    doc_pr = shape._inline.docPr
    doc_pr.set("title", description)
    doc_pr.set("descr", description)


def add_visual_overview(doc) -> None:
    doc.add_heading("图形化阅读导引", level=1)
    doc.add_paragraph(
        "本节先从工程外部边界说明总体架构和数据流。原Word表格式图完整保留，"
        "并在其后增加电路框图/Visio风格重绘图。重绘图采用模块边界、I/O端口、"
        "正交连接器和方向箭头；箭头只表示数据、控制或完成事件的因果方向，不把"
        "项目自定义接口误写成AXI、NVMe或NoPHAE标准协议。"
    )

    add_caption(doc, "图 1A  正式Vitis兼容通路总体顶层架构图（接口关系表）")
    table = add_table(
        doc,
        ["软件控制/所有权通道", "ADC采集与DDR缓存通道", "NoPHAE/SSD持久化通道"],
        OVERALL_ARCHITECTURE_ROWS,
        [2.08, 2.34, 2.08],
    )
    normalize_table_geometry(table, [2.08, 2.34, 2.08])
    style_diagram_table(table)
    add_caption(doc, "图 1B  正式Vitis兼容通路总体顶层架构图（系统框图）")
    add_inline_circuit_figure(
        doc,
        "overall_architecture_visio_circuit.png",
        "正式Vitis兼容通路总体顶层架构电路框图",
    )
    add_explanation(doc, "图 1A/1B 详细文字说明", OVERALL_ARCHITECTURE_EXPLANATION)

    add_caption(doc, "图 2A  一次Capture的端到端数据流图（阶段表）")
    table = add_table(
        doc,
        ["顺序", "数据所在阶段", "本阶段内容与流向"],
        OVERALL_DATA_FLOW,
        [0.45, 1.55, 4.50],
    )
    normalize_table_geometry(table, [0.45, 1.55, 4.50])
    add_caption(doc, "图 2B  一次Capture的端到端数据流图（数据流框图）")
    add_inline_circuit_figure(
        doc,
        "overall_data_flow_visio_circuit.png",
        "一次Capture端到端数据流Visio风格图",
    )
    add_explanation(doc, "图 2A/2B 详细文字说明", OVERALL_DATA_FLOW_EXPLANATION)

    add_caption(doc, "表 1  正式顶层接口信号分组导航")
    add_v24_table(
        doc,
        ["接口组", "顶层前缀/代表信号", "连接对象与用途"],
        [
            ["ADC输入", "adc_clk、adc_valid、adc_ch0/1", "连接ADC接收逻辑；样点源不可反压"],
            ["FDMA AXI-Lite", "s_axi_fdma_*", "连接MicroBlaze现有Vitis软件寄存器访问"],
            ["DDR AXI写", "m_axi_ddr_aw*/w*/b*", "Writer写Payload及Commit页到DDR"],
            ["NoPHAE AXI-Lite", "m_axi_nophae_*", "Backend编程NoPHAE控制寄存器"],
            ["运行前提", "ddr_init_done、nvme_init_done、pcie_link_up", "阻止未初始化链路启动数据搬运"],
            ["完成/错误", "local_capture_done、capture_done、fatal_error", "区分ADC本地排空、SSD最终持久化和失败"],
            ["计数/诊断", "accepted/dropped、submitted/completed", "软件定位丢样、请求停顿和完成缺口"],
        ],
    )
    doc.add_paragraph(
        "表1只用于先按接口族定位；第3节中就地展开的nvme_adc_vitis_compat_top"
        "接口信号列表按RTL模块头逐项列出每个实际端口、I/O、位宽、时钟域和中文语义。"
    )


def add_integrated_module_visual(doc, module_name: str) -> None:
    if module_name not in SECTION_CODES:
        raise RuntimeError(f"No body-section placement for {module_name}")
    spec = MODULE_VISUALS[module_name]
    code = SECTION_CODES[module_name]
    ports = parse_module_ports(module_name)

    doc.add_heading(f"{module_name} 架构、接口与时序", level=3)
    doc.add_paragraph(
        f"源码：rtl/{module_name}.sv。模块定位：{spec['role']}本模块图表就地放在"
        "相关正文设计章节，不再集中放入独立附录。"
    )

    add_caption(doc, f"图 {code}A  {module_name} 顶层架构图（接口关系表）")
    add_architecture_diagram(doc, spec["architecture"])
    add_caption(doc, f"图 {code}B  {module_name} 顶层架构图（模块框图）")
    add_inline_circuit_figure(
        doc,
        f"{module_name}_visio_circuit.png",
        f"{module_name}顶层架构电路框图",
    )
    add_explanation(
        doc,
        f"图 {code}A/{code}B 详细文字说明",
        spec["architecture_explanation"],
    )

    add_caption(doc, f"表 {code}  {module_name} 接口信号列表（{len(ports)}项）")
    add_interface_table(doc, module_name)
    groups = Counter(port_group(port["name"]) for port in ports)
    group_summary = "、".join(f"{name}{count}项" for name, count in groups.items())
    doc.add_paragraph(
        f"接口表读法：按RTL模块头顺序列出，共{len(ports)}项；接口分组为{group_summary}。"
        "I表示进入模块的输入端口，O表示由模块驱动的输出端口，I/O只用于真正的双向"
        "端口。位宽保留参数表达式；时钟域标为“跨域”时必须继续检查同步器或异步FIFO。"
    )
    doc.add_paragraph(
        "握手类接口均按valid与ready同时处于高电平才转移；stall期间发送端要保持数据"
        "及伴随Tag、长度、EOC或状态字段。输出诊断若标为sticky，则瞬时错误置位后保持。"
    )

    add_caption(doc, f"图 {code}C  {module_name} 关键时序图")
    add_inline_circuit_figure(
        doc,
        f"{module_name}_timing_waveform.png",
        f"{module_name}关键时序图",
    )
    add_explanation(
        doc,
        f"图 {code}C 详细文字说明",
        spec["timing_explanation"],
    )


def configure_compact_styles(doc) -> None:
    normal = doc.styles["Normal"]
    normal.font.name = "Calibri"
    normal.font.size = Pt(11)
    normal.paragraph_format.space_after = Pt(6)
    normal.paragraph_format.line_spacing = 1.25

    for name, size, before, after in (
        ("Heading 1", 16, 18, 10),
        ("Heading 2", 13, 14, 7),
        ("Heading 3", 12, 10, 5),
    ):
        style = doc.styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(size)
        style.font.bold = True
        style.paragraph_format.space_before = Pt(before)
        style.paragraph_format.space_after = Pt(after)
        style.paragraph_format.keep_with_next = True

    for name in ("List Bullet", "List Bullet 2", "List Number"):
        style = doc.styles[name]
        style.font.name = "Calibri"
        style.font.size = Pt(11)
        style.paragraph_format.left_indent = Inches(0.375)
        style.paragraph_format.first_line_indent = Inches(-0.188)
        style.paragraph_format.space_after = Pt(4)
        style.paragraph_format.line_spacing = 1.25

    caption = doc.styles["Caption"]
    caption.font.name = "Calibri"
    caption.font.size = Pt(9.5)
    caption.font.bold = True
    caption.font.color.rgb = RGBColor.from_string(BLUE)
    caption.paragraph_format.keep_with_next = True
    caption.paragraph_format.space_before = Pt(6)
    caption.paragraph_format.space_after = Pt(4)


def append_markdown(doc, source: Path) -> None:
    lines = source.read_text(encoding="utf-8").splitlines()
    paragraph_lines: list[str] = []
    code_lines: list[str] = []
    in_code = False
    fence = ""
    index = 0

    def flush_paragraph() -> None:
        if paragraph_lines:
            doc.add_paragraph(" ".join(clean_inline(item) for item in paragraph_lines))
            paragraph_lines.clear()

    while index < len(lines):
        raw = lines[index]
        stripped = raw.strip()

        visual_marker = re.fullmatch(
            r"<!--\s*MODULE_VISUAL:\s*([A-Za-z_][A-Za-z0-9_]*)\s*-->",
            stripped,
        )
        if visual_marker and not in_code:
            flush_paragraph()
            module_name = visual_marker.group(1)
            add_integrated_module_visual(doc, module_name)
            index += 1
            continue

        if stripped.startswith(chr(96) * 3) or stripped.startswith("~~~"):
            marker = stripped[:3]
            flush_paragraph()
            if in_code and marker == fence:
                add_code(doc, "\n".join(code_lines))
                code_lines.clear()
                in_code = False
                fence = ""
            elif not in_code:
                in_code = True
                fence = marker
            index += 1
            continue

        if in_code:
            code_lines.append(raw)
            index += 1
            continue

        if (
            stripped.startswith("|")
            and index + 1 < len(lines)
            and is_table_separator(lines[index + 1])
        ):
            flush_paragraph()
            headers = table_cells(raw)
            index += 2
            rows: list[list[str]] = []
            while index < len(lines) and lines[index].strip().startswith("|"):
                row = table_cells(lines[index])
                if len(row) == len(headers):
                    rows.append(row)
                index += 1
            add_v24_table(doc, headers, rows)
            continue

        heading = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if heading:
            flush_paragraph()
            markdown_level = len(heading.group(1))
            title = clean_inline(heading.group(2))
            if markdown_level == 1:
                index += 1
                continue
            if title.startswith("附录 A"):
                doc.add_page_break()
            level = max(1, min(3, markdown_level - 1))
            doc.add_heading(title, level=level)
            index += 1
            continue

        bullet = re.match(r"^[-*]\s+(.+)$", stripped)
        if bullet:
            flush_paragraph()
            add_bullet(doc, clean_inline(bullet.group(1)))
            index += 1
            continue

        numbered = re.match(r"^\d+\.\s+(.+)$", stripped)
        if numbered:
            flush_paragraph()
            add_number(doc, clean_inline(numbered.group(1)))
            index += 1
            continue

        if stripped.startswith(">"):
            flush_paragraph()
            paragraph = doc.add_paragraph(clean_inline(stripped.lstrip("> ")))
            paragraph.style = doc.styles["Subtitle"]
            index += 1
            continue

        if not stripped:
            flush_paragraph()
        else:
            paragraph_lines.append(stripped)
        index += 1

    flush_paragraph()
    if in_code:
        add_code(doc, "\n".join(code_lines))


def build_v24(output: Path = OUT) -> Path:
    if not SOURCE.is_file():
        raise RuntimeError(f"Missing Markdown source: {SOURCE}")

    doc = configure_doc("ADC · DDR · NVMe V2.4代码级详细设计")
    configure_compact_styles(doc)
    add_masthead(
        doc,
        "内部代码级设计说明",
        "NVMe–DDR–ADC FPGA\n详细设计方案",
        "正式Vitis兼容通路｜电路架构图、数据流、I/O接口、高低电平时序与状态机",
        "V2.4｜代码级信号与状态机详解｜2026-08-10",
        [
            ("事实源", "当前正式通路实际例化的11个RTL/SV模块"),
            ("本版动作", "只补充中文语义注释；Packer组合块改为always @*"),
            ("验证边界", "不重建Vitis、不回归、不综合；只做源码不变量和OOXML结构检查"),
        ],
    )
    normalize_table_geometry(doc.tables[0], [1.45, 5.05])
    doc.add_page_break()

    add_visual_overview(doc)
    doc.add_page_break()
    append_markdown(doc, SOURCE)

    doc.add_heading("文档结构验证声明", level=1)
    doc.add_paragraph(
        "本文只进行DOCX ZIP/CRC、OOXML必需部件、核心属性、真实标题与编号"
        "样式、固定DXA表格几何、关键术语和内容规模检查。按照工作区规则未"
        "渲染PDF/PNG，因此不把结构检查表述为页面视觉验收。"
    )

    set_core_properties(doc)
    output = Path(output)
    doc.save(output)
    print(f"DOCX_GENERATED: {output} | {output.stat().st_size} bytes")
    return output


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--out", type=Path, default=OUT)
    arguments = parser.parse_args()
    build_v24(arguments.out)
```
