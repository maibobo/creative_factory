# check_v22_docx_structure

- Category: `pcie`
- Source: `E:\NVME_PRO\nvme_adc_axi_pipeline\docs\check_v22_docx_structure.py`
- SHA-256: `ba095dae949ed34a9fd92b5abd9bd20a803036014e8c27b795409550def41a78`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - none

```python
"""对V2.2 DOCX执行非渲染结构完整性检查。

用户和工作区规则明确禁止Word文档的PDF/PNG渲染，因此这里只检查DOCX ZIP
容器、WordprocessingML核心部件、版本属性、正文/表格语义锚点、内容规模和
占位符。检查通过只说明结构和关键内容完整，不代表做过页面视觉检查。
"""

from pathlib import Path
from zipfile import BadZipFile, ZipFile

from docx import Document


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
TARGET = DOCS / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.2_NoPHAE用户指南接口收敛版.docx"

# 核心部件缺失会导致Word无法正常解析文件。这里只检查文档自身，不依赖
# LibreOffice、PDF转换或图片渲染。
REQUIRED_ZIP_PARTS = {
    "[Content_Types].xml",
    "_rels/.rels",
    "docProps/core.xml",
    "word/document.xml",
    "word/styles.xml",
    "word/numbering.xml",
}

# 锚点覆盖版本、真实端口、DMA寄存器、KU040风险、Flush阻塞和供应商问题。
# 若生成器保存了旧正文、空文档或章节意外缺失，检查将返回非零。
REQUIRED_ANCHORS = [
    "V2.2",
    "s_axi_ctrl",
    "m_axi",
    "dma_srcaddr",
    "dma_dstaddr",
    "dma_ready",
    "dma_done",
    "512 B",
    "XCKU040",
    "UltraScale Gen3",
    "clr_queues",
    "sq_full",
    "Flush实现",
    "继续向供应商确认的8个关键问题",
    "取得用户指南不等于取得IP或完成集成",
]

# 生成文档不得带模板占位符或未决编辑标记。技术词UNKNOWN/AMBIGUOUS是正式
# 状态分类，因此不在占位符列表中。
FORBIDDEN_PLACEHOLDERS = [
    "TODO",
    "TBD",
    "FIXME",
    "{{",
    "}}",
    "[待填写]",
    "此处填写",
]


def collect_text(doc):
    """合并普通段落和表格单元格，使语义检查覆盖矩阵和问题清单。"""

    parts = [paragraph.text for paragraph in doc.paragraphs]
    parts.extend(
        cell.text
        for table in doc.tables
        for row in table.rows
        for cell in row.cells
    )
    return "\n".join(parts)


def main():
    if not TARGET.is_file() or TARGET.stat().st_size == 0:
        raise RuntimeError(f"Missing or empty DOCX: {TARGET}")

    # 先验证ZIP容器、必需OOXML部件和每个成员的CRC。
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

    # 再用python-docx解析正文，检查版本属性、语义锚点和最低内容规模。
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

    if doc.core_properties.title != "NVMe_ADC_DDR_FPGA基础通路设计方案 V2.2":
        raise RuntimeError(
            f"{TARGET.name}: unexpected core title {doc.core_properties.title!r}"
        )
    if len(doc.paragraphs) < 70 or len(doc.tables) < 10:
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
