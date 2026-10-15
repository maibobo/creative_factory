# build_v23_docs

- Category: `pcie`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\docs\build_v23_docs.py`
- SHA-256: `f66603a8b38d148c68f8adce32e0ab936f68fa50d07469f1d1f8668af6afab36`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

```python
"""生成V2.3 Vitis源码实证与现有RTL修复版DOCX。

正文直接读取本目录的V2.3详细设计方案和现有软件使用指南，保证Markdown与
DOCX共用同一组当前事实。按工作区规则，本脚本不调用LibreOffice，不生成
PDF、PNG或页面截图；输出只由check_v23_docx_structure.py做OOXML结构检查。
"""

from __future__ import annotations

import re
from pathlib import Path

from build_design_doc import add_bullet, add_callout, add_code, add_number, add_table
from build_v2_docs import add_masthead, configure_doc


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
DESIGN_SOURCE = DOCS / "NoPHAE_Vitis源码实证与现有RTL修复方案_V2.3.md"
GUIDE_SOURCE = DOCS / "NoPHAE_Vitis现有软件使用与验证指南_V1.0.md"
OUT = DOCS / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版.docx"


def set_core_properties(doc) -> None:
    """写入可由结构检查脚本读取的版本和用途元数据。"""

    core = doc.core_properties
    core.title = "NVMe_ADC_DDR_FPGA基础通路设计方案 V2.3"
    core.subject = "Vitis源码实证、现有RTL修复、NoPHAE寄存器契约和软件使用验证"
    core.author = "项目组"
    core.keywords = (
        "ADC, DDR, NVMe, NoPHAE, Vitis Classic, AXI4-Lite, XCKU040, "
        "XSim, V2.3"
    )


def clean_inline(text: str) -> str:
    """去除Markdown行内标记，保留路径、公式、寄存器名和原始语义。"""

    text = text.strip()
    text = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", text)
    text = text.replace("`", "").replace("**", "").replace("__", "")
    return text.replace(r"\|", "|")


def table_cells(line: str) -> list[str]:
    """解析不包含跨单元格竖线的工程Markdown表格。"""

    return [clean_inline(cell) for cell in line.strip().strip("|").split("|")]


def is_table_separator(line: str) -> bool:
    cells = table_cells(line)
    return bool(cells) and all(re.fullmatch(r":?-{3,}:?", cell) for cell in cells)


def table_widths(column_count: int) -> list[float]:
    """按正文可用宽度6.5英寸给出稳定的固定列宽。"""

    if column_count == 2:
        return [1.75, 4.75]
    if column_count == 3:
        return [1.35, 2.25, 2.90]
    if column_count == 4:
        return [1.15, 1.75, 1.65, 1.95]
    width = 6.5 / column_count
    return [width] * column_count


def append_markdown(doc, source: Path, *, skip_title: bool = True) -> None:
    """把当前工程Markdown的标题、列表、代码块和表格写入DOCX。"""

    lines = source.read_text(encoding="utf-8").splitlines()
    paragraph_lines: list[str] = []
    in_code = False
    code_lines: list[str] = []
    index = 0

    def flush_paragraph() -> None:
        if paragraph_lines:
            doc.add_paragraph(" ".join(clean_inline(item) for item in paragraph_lines))
            paragraph_lines.clear()

    while index < len(lines):
        raw = lines[index]
        stripped = raw.strip()

        if stripped.startswith("```"):
            flush_paragraph()
            if in_code:
                add_code(doc, "\n".join(code_lines))
                code_lines.clear()
                in_code = False
            else:
                in_code = True
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
            add_table(doc, headers, rows, table_widths(len(headers)))
            continue

        heading = re.match(r"^(#{1,6})\s+(.+)$", stripped)
        if heading:
            flush_paragraph()
            markdown_level = len(heading.group(1))
            if skip_title and markdown_level == 1:
                index += 1
                continue
            # 源文件从##开始编号；在合并文档中映射为一级章节。
            level = max(1, min(3, markdown_level - 1))
            doc.add_heading(clean_inline(heading.group(2)), level=level)
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

        if not stripped:
            flush_paragraph()
        else:
            paragraph_lines.append(stripped)
        index += 1

    flush_paragraph()
    if in_code:
        add_code(doc, "\n".join(code_lines))


def build_v23() -> Path:
    """生成同时包含详细设计和完整软件使用指导的V2.3文档。"""

    for source in (DESIGN_SOURCE, GUIDE_SOURCE):
        if not source.is_file():
            raise RuntimeError(f"Missing Markdown source: {source}")

    doc = configure_doc("ADC · DDR · NVMe V2.3源码实证与RTL修复")
    add_masthead(
        doc,
        "内部设计与使用说明",
        "NVMe–DDR–ADC FPGA\n基础通路设计方案",
        "Vitis源码实证｜现有RTL/SV修复｜NoPHAE软件ABI兼容｜无综合验证",
        "V2.3｜Vitis源码实证与现有RTL修复版｜2026-07-31",
        [
            (
                "事实基线",
                r"E:\NVME_PRO\vitis_classic\nvme\src、现有ELF/bit/XSA及XSim证据",
            ),
            (
                "本版动作",
                "不重建Vitis软件；修改现有RTL/SV、兼容寄存器、测试和相关文档",
            ),
            (
                "验证边界",
                "只做静态检查、RTL编译和行为仿真；不运行综合，不宣称真实SSD通过",
            ),
        ],
    )
    add_callout(
        doc,
        "V2.3核心结论",
        "当前XSA没有0x90000000外设，而现有ELF固定访问该地址。V2.3已按"
        "软件ABI补齐FDMA兼容寄存器，并把调度器请求转换为NoPHAE "
        "0x10000000寄存器序列。现有Vitis工程保持不重建；只有兼容RTL并入"
        "实际Vivado工程并产生新硬件后，FDMA菜单才可在板上使用。",
    )
    doc.add_page_break()

    doc.add_heading("第一部分：详细设计、源码证据和RTL修复", level=1)
    append_markdown(doc, DESIGN_SOURCE)

    doc.add_page_break()
    doc.add_heading("第二部分：现有Vitis软件完整使用与验证指导", level=1)
    append_markdown(doc, GUIDE_SOURCE)

    doc.add_heading("文档验证声明", level=1)
    add_callout(
        doc,
        "结构检查范围",
        "本文只进行DOCX ZIP、OOXML必需部件、核心属性、正文锚点、表格和"
        "内容规模检查。按照工作区要求未渲染PDF/PNG，因此不把结构检查写成"
        "页面视觉验收。",
        fill="FFF4E5",
    )

    set_core_properties(doc)
    doc.save(OUT)
    print(f"DOCX_GENERATED: {OUT} | {OUT.stat().st_size} bytes")
    return OUT


if __name__ == "__main__":
    build_v23()
```
