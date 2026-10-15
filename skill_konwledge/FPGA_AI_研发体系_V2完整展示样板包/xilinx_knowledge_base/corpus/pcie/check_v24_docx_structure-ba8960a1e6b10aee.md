# check_v24_docx_structure

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\check_v24_docx_structure.py`
- SHA-256: `ba8960a1e6b10aeefbaadf356780eba85e271787352e01407a12126900b43613`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\check_v24_docx_structure.py

```python
"""对V2.4 DOCX执行非渲染结构、版式和内容完整性检查。"""

from __future__ import annotations

import argparse
from pathlib import Path
from zipfile import BadZipFile, ZipFile

from docx import Document
from docx.oxml.ns import qn
from docx.shared import Inches, Pt

from build_v24_docs import SECTION_CODES, parse_module_ports
from v24_visual_catalog import (
    FORMAL_MODULES,
    MODULE_VISUALS,
    OVERALL_ARCHITECTURE_EXPLANATION,
    OVERALL_DATA_FLOW_EXPLANATION,
    WAVEFORMS,
)


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
TARGET = DOCS / "NVMe_ADC_DDR_FPGA详细设计方案_V2.4_代码级信号与状态机详解.docx"

TABLE_WIDTH_DXA = 9360
TABLE_INDENT_DXA = 120

REQUIRED_ZIP_PARTS = {
    "[Content_Types].xml",
    "_rels/.rels",
    "docProps/core.xml",
    "word/document.xml",
    "word/styles.xml",
    "word/numbering.xml",
    "word/header1.xml",
    "word/footer1.xml",
}

REQUIRED_ANCHORS = [
    "V2.4",
    "Capture",
    "Segment",
    "Manager",
    "alloc",
    "ready/valid",
    "stall",
    "sticky",
    "ADCCOMM1",
    "329 bit",
    "ST_DRAIN",
    "pack_full_pending",
    "ST_CONTEXT",
    "WR_COMMIT_DESC",
    "SEG_ERROR_HOLD",
    "generation",
    "s_axis_tready",
    "Payload Write",
    "Flush1",
    "Commit Write",
    "Flush2",
    "0xC0800000",
    "current_ddr_addr",
    "job_is_commit",
    "data_payload_bytes",
    "adc_channel_packer",
    "adc_capture_limit_controller",
    "axis_async_fifo",
    "sync_fifo",
    "adc_ddr_segment_writer",
    "segment_buffer_manager",
    "nvme_request_scheduler",
    "nophae_dma_backend",
    "fdma_vitis_compat_regs",
    "nvme_adc_pipeline_top",
    "nvme_adc_vitis_compat_top",
    "图形化阅读导引",
    "总体顶层架构图",
    "端到端数据流图",
    "顶层接口信号分组导航",
    "模块边界",
    "I表示进入模块的输入端口",
    "模块框图",
    "接口信号列表",
    "关键时序图",
    "详细文字说明",
    "不运行 RTL 回归",
    "不综合",
]

FORBIDDEN_ANCHORS = [
    "附录 D：11个正式模块的架构、接口与时序图册",
    "图 D-",
    "表 D-",
]

FORBIDDEN_PLACEHOLDERS = [
    "TODO",
    "TBD",
    "FIXME",
    "{{",
    "}}",
    "[待填写]",
    "此处填写",
]


def collect_text(doc) -> str:
    parts = [paragraph.text for paragraph in doc.paragraphs]
    parts.extend(
        cell.text
        for table in doc.tables
        for row in table.rows
        for cell in row.cells
    )
    return "\n".join(parts)


def attr_int(element, name: str) -> int:
    value = element.get(qn(name))
    if value is None:
        raise RuntimeError(f"Missing OOXML attribute {name}")
    return int(value)


def check_table_geometry(doc) -> None:
    for table_index, table in enumerate(doc.tables, start=1):
        tbl_pr = table._tbl.tblPr
        tbl_w = tbl_pr.find(qn("w:tblW"))
        tbl_ind = tbl_pr.find(qn("w:tblInd"))
        layout = tbl_pr.find(qn("w:tblLayout"))
        if tbl_w is None or tbl_w.get(qn("w:type")) != "dxa":
            raise RuntimeError(f"table {table_index}: tblW is not fixed DXA")
        if attr_int(tbl_w, "w:w") != TABLE_WIDTH_DXA:
            raise RuntimeError(f"table {table_index}: tblW is not 9360 DXA")
        if tbl_ind is None or tbl_ind.get(qn("w:type")) != "dxa":
            raise RuntimeError(f"table {table_index}: tblInd is not DXA")
        if attr_int(tbl_ind, "w:w") != TABLE_INDENT_DXA:
            raise RuntimeError(f"table {table_index}: tblInd is not 120 DXA")
        if layout is None or layout.get(qn("w:type")) != "fixed":
            raise RuntimeError(f"table {table_index}: table layout is not fixed")

        grid = table._tbl.tblGrid
        grid_widths = [
            attr_int(column, "w:w")
            for column in grid.findall(qn("w:gridCol"))
        ]
        if not grid_widths or sum(grid_widths) != TABLE_WIDTH_DXA:
            raise RuntimeError(
                f"table {table_index}: grid total is {sum(grid_widths)}"
            )

        for row_index, row in enumerate(table.rows, start=1):
            if len(row.cells) != len(grid_widths):
                raise RuntimeError(
                    f"table {table_index} row {row_index}: irregular grid"
                )
            for column_index, cell in enumerate(row.cells):
                tc_w = cell._tc.get_or_add_tcPr().find(qn("w:tcW"))
                if tc_w is None or tc_w.get(qn("w:type")) != "dxa":
                    raise RuntimeError(
                        f"table {table_index} row {row_index}: tcW is not DXA"
                    )
                if attr_int(tc_w, "w:w") != grid_widths[column_index]:
                    raise RuntimeError(
                        f"table {table_index} row {row_index}: tcW/grid mismatch"
                    )


def check_styles_and_sections(doc) -> None:
    normal = doc.styles["Normal"]
    if normal.font.name != "Calibri" or normal.font.size != Pt(11):
        raise RuntimeError("Normal style is not Calibri 11 pt")
    if normal.paragraph_format.line_spacing != 1.25:
        raise RuntimeError("Normal style line spacing is not 1.25")

    expected = {
        "Heading 1": (16, 18, 10),
        "Heading 2": (13, 14, 7),
        "Heading 3": (12, 10, 5),
    }
    for name, (size, before, after) in expected.items():
        style = doc.styles[name]
        if style.font.name != "Calibri" or style.font.size != Pt(size):
            raise RuntimeError(f"{name} font does not match preset")
        if style.paragraph_format.space_before != Pt(before):
            raise RuntimeError(f"{name} space_before does not match preset")
        if style.paragraph_format.space_after != Pt(after):
            raise RuntimeError(f"{name} space_after does not match preset")

    section = doc.sections[0]
    if section.page_width != Inches(8.5) or section.page_height != Inches(11):
        raise RuntimeError("Page size is not US Letter portrait")
    for value in (
        section.top_margin,
        section.bottom_margin,
        section.left_margin,
        section.right_margin,
    ):
        if value != Inches(1):
            raise RuntimeError("Page margins are not 1 inch")
    if abs(section.header_distance - Inches(0.492)) > 1000:
        raise RuntimeError("Header distance does not match memo preset")
    if abs(section.footer_distance - Inches(0.492)) > 1000:
        raise RuntimeError("Footer distance does not match memo preset")

    heading_counts = {
        name: sum(1 for paragraph in doc.paragraphs if paragraph.style.name == name)
        for name in expected
    }
    if heading_counts["Heading 1"] < 15:
        raise RuntimeError(f"Too few Heading 1 paragraphs: {heading_counts}")
    if heading_counts["Heading 2"] < 25:
        raise RuntimeError(f"Too few Heading 2 paragraphs: {heading_counts}")
    # 当前Markdown正文使用两级结构；Heading 3仍按预设完整定义，供后续扩展。

    numbered = sum(
        1 for paragraph in doc.paragraphs if paragraph.style.name == "List Number"
    )
    if numbered < 8:
        raise RuntimeError(f"Too few real numbered-list paragraphs: {numbered}")

    captioned = sum(
        1 for paragraph in doc.paragraphs if paragraph.style.name == "Caption"
    )
    if captioned < 49:
        raise RuntimeError(f"Too few real figure/table captions: {captioned}")

    explanations = sum(
        1
        for paragraph in doc.paragraphs
        if "详细文字说明" in paragraph.text
    )
    if explanations < 24:
        raise RuntimeError(
            f"Too few detailed diagram explanations: {explanations}"
        )


def check_module_interface_tables(doc) -> None:
    expected_header = ["接口组", "信号", "I/O", "位宽", "时钟域", "语义"]
    interface_tables = []
    for table in doc.tables:
        if not table.rows or len(table.rows[0].cells) != len(expected_header):
            continue
        header = [cell.text.strip() for cell in table.rows[0].cells]
        if header == expected_header:
            interface_tables.append(table)

    if len(interface_tables) != len(FORMAL_MODULES):
        raise RuntimeError(
            "Interface table count mismatch: "
            f"{len(interface_tables)} != {len(FORMAL_MODULES)}"
        )

    body_order = list(SECTION_CODES)
    if set(body_order) != set(FORMAL_MODULES):
        raise RuntimeError("Body placement does not cover all formal modules")

    direction_names = {"input": "I", "output": "O", "inout": "I/O"}
    for module_name, table in zip(body_order, interface_tables):
        expected_ports = [
            port["name"] for port in parse_module_ports(module_name)
        ]
        actual_ports = [
            row.cells[1].text.strip() for row in table.rows[1:]
        ]
        if actual_ports != expected_ports:
            raise RuntimeError(
                f"{module_name}: DOCX interface list differs from RTL header"
            )
        if any(not row.cells[5].text.strip() for row in table.rows[1:]):
            raise RuntimeError(
                f"{module_name}: blank interface semantic description"
            )
        expected_directions = [
            direction_names[port["direction"]]
            for port in parse_module_ports(module_name)
        ]
        actual_directions = [
            row.cells[2].text.strip() for row in table.rows[1:]
        ]
        if actual_directions != expected_directions:
            raise RuntimeError(
                f"{module_name}: I/O column differs from RTL directions"
            )


def check_caption_wording(doc) -> None:
    forbidden = ["重绘", "高/低电平对齐", "电路/Visio"]
    bad = [
        paragraph.text
        for paragraph in doc.paragraphs
        if paragraph.style.name == "Caption"
        and any(marker in paragraph.text for marker in forbidden)
    ]
    if bad:
        raise RuntimeError(f"Figure titles contain removed wording: {bad}")


def check_integrated_placement(doc) -> None:
    paragraphs = [paragraph.text.strip() for paragraph in doc.paragraphs]
    placements = {
        "nvme_adc_vitis_compat_top": ("3. 系统全链路", "一次正式 Vitis 兼容 Capture"),
        "adc_channel_packer": ("5. adc_channel_packer 详细设计", "5.1 三个状态"),
        "adc_capture_limit_controller": ("6. adc_capture_limit_controller 详细设计", "6.1 Toggle CDC 和多位上下文"),
        "axis_async_fifo": ("7. 329 bit CDC FIFO 与反压链", "7.1 位域"),
        "adc_ddr_segment_writer": ("8. adc_ddr_segment_writer 详细设计", "8.1 Writer 八状态"),
        "sync_fifo": ("8. adc_ddr_segment_writer 详细设计", "8.1 Writer 八状态"),
        "segment_buffer_manager": ("9. segment_buffer_manager 详细设计", "9.1 它管理什么，不管理什么"),
        "nvme_request_scheduler": ("11. Scheduler、NoPHAE Backend 与两个顶层", "11.1 Scheduler 的单请求在途约束"),
        "nophae_dma_backend": ("11. Scheduler、NoPHAE Backend 与两个顶层", "11.1 Scheduler 的单请求在途约束"),
        "nvme_adc_pipeline_top": ("11. Scheduler、NoPHAE Backend 与两个顶层", "11.1 Scheduler 的单请求在途约束"),
        "fdma_vitis_compat_regs": ("13. 软件使用指导", "13.1 不重建的软件边界"),
    }

    for module_name, (section_title, first_body_title) in placements.items():
        module_title = f"{module_name} 架构、接口与时序"
        try:
            section_index = paragraphs.index(section_title)
            module_index = paragraphs.index(module_title)
            body_index = next(
                index
                for index, text in enumerate(paragraphs)
                if index > section_index and text.startswith(first_body_title)
            )
        except (ValueError, StopIteration) as exc:
            raise RuntimeError(
                f"{module_name}: cannot locate section-start placement anchors"
            ) from exc
        if not section_index < module_index < body_index:
            raise RuntimeError(
                f"{module_name}: architecture/interface/timing is not at module start"
            )


def check_diagram_assets() -> None:
    figures = DOCS / "figures_v24"
    expected = {
        "overall_architecture_visio_circuit.png",
        "overall_data_flow_visio_circuit.png",
        *(f"{module}_visio_circuit.png" for module in FORMAL_MODULES),
        *(f"{module}_timing_waveform.png" for module in FORMAL_MODULES),
    }
    actual = {path.name for path in figures.glob("*.png")}
    if actual != expected:
        raise RuntimeError(
            f"Diagram asset set mismatch: missing={expected-actual}, extra={actual-expected}"
        )
    for name in expected:
        data = (figures / name).read_bytes()
        if len(data) < 50000 or data[:8] != b"\x89PNG\r\n\x1a\n":
            raise RuntimeError(f"Invalid or suspiciously small diagram: {name}")
        width = int.from_bytes(data[16:20], "big")
        height = int.from_bytes(data[20:24], "big")
        if width < 2000 or height < 800:
            raise RuntimeError(f"Diagram resolution too small: {name} {width}x{height}")

    generator = (DOCS / "build_v24_circuit_diagrams.py").read_text(encoding="utf-8")
    if "每个周期边界只画一次垂直转换边沿" not in generator:
        raise RuntimeError("Continuous-edge waveform generator invariant is missing")
    if set(WAVEFORMS) != set(FORMAL_MODULES):
        raise RuntimeError("Waveform source does not cover all formal modules")


def check_visual_catalog(text: str) -> None:
    if len(OVERALL_ARCHITECTURE_EXPLANATION) < 3:
        raise RuntimeError("Overall architecture explanation is too short")
    if len(OVERALL_DATA_FLOW_EXPLANATION) < 3:
        raise RuntimeError("Overall data-flow explanation is too short")

    expected = [
        "图 1A  正式Vitis兼容通路总体顶层架构图（接口关系表）",
        "图 1B  正式Vitis兼容通路总体顶层架构图（系统框图）",
        "图 2A  一次Capture的端到端数据流图（阶段表）",
        "图 2B  一次Capture的端到端数据流图（数据流框图）",
        "图 1A/1B 详细文字说明",
        "图 2A/2B 详细文字说明",
    ]
    for module_name in FORMAL_MODULES:
        spec = MODULE_VISUALS[module_name]
        code = SECTION_CODES[module_name]
        if len(spec["architecture_explanation"]) < 3:
            raise RuntimeError(
                f"{module_name}: architecture explanation is too short"
            )
        if len(spec["timing_explanation"]) < 3:
            raise RuntimeError(
                f"{module_name}: timing explanation is too short"
            )
        expected.extend(
            [
                f"{module_name} 架构、接口与时序",
                f"图 {code}A  {module_name} 顶层架构图（接口关系表）",
                f"图 {code}B  {module_name} 顶层架构图（模块框图）",
                f"图 {code}A/{code}B 详细文字说明",
                f"表 {code}  {module_name} 接口信号列表",
                f"图 {code}C  {module_name} 关键时序图",
                f"图 {code}C 详细文字说明",
            ]
        )

    missing = [anchor for anchor in expected if anchor not in text]
    if missing:
        raise RuntimeError(f"Missing visual catalog anchors: {missing}")


def main() -> None:
    if not TARGET.is_file() or TARGET.stat().st_size == 0:
        raise RuntimeError(f"Missing or empty DOCX: {TARGET}")

    try:
        with ZipFile(TARGET) as package:
            names = set(package.namelist())
            missing_parts = REQUIRED_ZIP_PARTS - names
            if missing_parts:
                raise RuntimeError(
                    f"{TARGET.name}: missing package parts {sorted(missing_parts)}"
                )
            for member in REQUIRED_ZIP_PARTS:
                if not package.read(member):
                    raise RuntimeError(f"{TARGET.name}: empty package part {member}")
            corrupt_member = package.testzip()
            if corrupt_member is not None:
                raise RuntimeError(
                    f"{TARGET.name}: corrupt ZIP member {corrupt_member}"
                )
            document_xml = package.read("word/document.xml").decode("utf-8")
            footer_xml = package.read("word/footer1.xml").decode("utf-8")
            if "PAGE" not in footer_xml or "NUMPAGES" not in footer_xml:
                raise RuntimeError("Footer page fields are incomplete")
            if "<w:tblLayout w:type=\"fixed\"" not in document_xml:
                raise RuntimeError("Fixed table layout marker is missing")
            media = sorted(
                name for name in names if name.startswith("word/media/")
            )
            if len(media) != 24 or any(not name.lower().endswith(".png") for name in media):
                raise RuntimeError(f"Expected 24 inline PNG diagrams, found {media}")
            if any(not package.read(member) for member in media):
                raise RuntimeError("Empty embedded circuit figure")
            if document_xml.count("<wp:inline") < 24:
                raise RuntimeError("Too few inline architecture/timing figures")
            if "<wp:anchor" in document_xml:
                raise RuntimeError("Floating figure found; only inline figures are allowed")
    except BadZipFile as exc:
        raise RuntimeError(f"{TARGET.name}: invalid DOCX ZIP") from exc

    doc = Document(TARGET)
    text = collect_text(doc)
    missing_anchors = [anchor for anchor in REQUIRED_ANCHORS if anchor not in text]
    if missing_anchors:
        raise RuntimeError(
            f"{TARGET.name}: missing required text anchors {missing_anchors}"
        )

    forbidden_anchors = [anchor for anchor in FORBIDDEN_ANCHORS if anchor in text]
    if forbidden_anchors:
        raise RuntimeError(
            f"{TARGET.name}: removed appendix-D anchors remain {forbidden_anchors}"
        )

    found_placeholders = [
        marker for marker in FORBIDDEN_PLACEHOLDERS if marker in text
    ]
    if found_placeholders:
        raise RuntimeError(
            f"{TARGET.name}: unresolved placeholders {found_placeholders}"
        )

    expected_title = "NVMe_ADC_DDR_FPGA详细设计方案 V2.4"
    if doc.core_properties.title != expected_title:
        raise RuntimeError(
            f"{TARGET.name}: unexpected core title {doc.core_properties.title!r}"
        )
    if "V2.4" not in (doc.core_properties.keywords or ""):
        raise RuntimeError("Core keywords do not identify V2.4")

    check_styles_and_sections(doc)
    check_table_geometry(doc)
    check_module_interface_tables(doc)
    check_caption_wording(doc)
    check_integrated_placement(doc)
    check_diagram_assets()
    check_visual_catalog(text)

    if len(doc.paragraphs) < 340 or len(doc.tables) < 65 or len(text) < 50000:
        raise RuntimeError(
            f"{TARGET.name}: suspiciously small document "
            f"({len(doc.paragraphs)} paragraphs, {len(doc.tables)} tables, "
            f"{len(text)} text characters)"
        )

    print(
        "DOCX_STRUCTURE_PASS: "
        f"{TARGET} | {TARGET.stat().st_size} bytes | "
        f"{len(doc.paragraphs)} paragraphs | {len(doc.tables)} tables | "
        f"{len(text)} chars | title={doc.core_properties.title}"
    )
    print(
        "DOCX_GEOMETRY_PASS: Letter | margins=1in | "
        "tables=9360DXA | indent=120DXA | layout=fixed"
    )
    print("DOCX_RENDER_SKIPPED: per user and workspace instructions")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--target", type=Path, default=TARGET)
    arguments = parser.parse_args()
    TARGET = arguments.target
    main()
```
