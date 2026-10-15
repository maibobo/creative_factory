# check_v23_docx_structure

- Category: `pcie`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\docs\check_v23_docx_structure.py`
- SHA-256: `e2d17601497f842f78b92d4a676ad0c7c4e43ee50ca038235879cb7038a94681`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

```python
"""对V2.3 DOCX执行非渲染结构完整性检查。

工作区规则要求Word文档只做结构检查，因此本脚本不调用LibreOffice，也不
生成PDF、PNG或截图。通过只表示DOCX容器、核心部件和关键技术内容完整。
"""

from pathlib import Path
from zipfile import BadZipFile, ZipFile

from docx import Document


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
TARGET = DOCS / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.3_Vitis源码实证与现有RTL修复版.docx"

REQUIRED_ZIP_PARTS = {
    "[Content_Types].xml",
    "_rels/.rels",
    "docProps/core.xml",
    "word/document.xml",
    "word/styles.xml",
    "word/numbering.xml",
}

REQUIRED_ANCHORS = [
    "V2.3",
    "vitis_classic",
    "0x90000000",
    "0x10000000",
    "329 bit",
    "nophae_dma_backend",
    "fdma_vitis_compat_regs",
    "nvme_adc_vitis_compat_top",
    "physical_ddr_addr - 0x80000000",
    "byte_len / 512",
    "Payload Write",
    "Commit Write",
    "MIN_START_SLBA",
    "D004",
    "D006",
    "E007",
    "tb_nvme_adc_vitis_compat",
    "不重建Vitis软件",
    "不运行综合",
    "115200 8N1",
    "当前XSA没有0x90000000",
    "LBA0",
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
    """合并普通段落和表格单元格，使检查覆盖正文和矩阵内容。"""

    parts = [paragraph.text for paragraph in doc.paragraphs]
    parts.extend(
        cell.text
        for table in doc.tables
        for row in table.rows
        for cell in row.cells
    )
    return "\n".join(parts)


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
    except BadZipFile as exc:
        raise RuntimeError(f"{TARGET.name}: invalid DOCX ZIP") from exc

    doc = Document(TARGET)
    text = collect_text(doc)
    missing_anchors = [anchor for anchor in REQUIRED_ANCHORS if anchor not in text]
    if missing_anchors:
        raise RuntimeError(
            f"{TARGET.name}: missing required text anchors {missing_anchors}"
        )

    found_placeholders = [
        marker for marker in FORBIDDEN_PLACEHOLDERS if marker in text
    ]
    if found_placeholders:
        raise RuntimeError(
            f"{TARGET.name}: unresolved placeholders {found_placeholders}"
        )

    expected_title = "NVMe_ADC_DDR_FPGA基础通路设计方案 V2.3"
    if doc.core_properties.title != expected_title:
        raise RuntimeError(
            f"{TARGET.name}: unexpected core title {doc.core_properties.title!r}"
        )
    if len(doc.paragraphs) < 150 or len(doc.tables) < 20:
        raise RuntimeError(
            f"{TARGET.name}: suspiciously small document "
            f"({len(doc.paragraphs)} paragraphs, {len(doc.tables)} tables)"
        )

    print(
        "DOCX_STRUCTURE_PASS: "
        f"{TARGET} | {TARGET.stat().st_size} bytes | "
        f"{len(doc.paragraphs)} paragraphs | {len(doc.tables)} tables | "
        f"title={doc.core_properties.title}"
    )
    print("DOCX_RENDER_SKIPPED: per user and workspace instructions")


if __name__ == "__main__":
    main()
```
