# check_v21_docx_structure

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\check_v21_docx_structure.py`
- SHA-256: `d5976161241ade7d62211e517dec807cabf75a7064eb8dc0f64e144c0e7f1834`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\check_v21_docx_structure.py

```python
"""对V2.1/V1.1 DOCX执行非渲染结构检查。

用户明确要求不生成PDF/PNG，因此本脚本只检查DOCX ZIP容器、WordprocessingML
核心部件、核心属性、章节锚点和最低内容规模。它不会调用LibreOffice，也不能
替代页面级视觉检查；检查通过只说明Word文件结构完整、关键内容已写入。
"""

from pathlib import Path
from zipfile import ZipFile, BadZipFile

from docx import Document


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"

# 每份文档使用不同的语义锚点。锚点覆盖版本、供应商三态、关键歧义、恢复和
# 验证路径，防止生成脚本意外保存了空文档或旧版本正文。
CHECKS = {
    DOCS
    / "NVMe_ADC_DDR_FPGA基础通路设计方案_V2.1_供应商补充答疑收敛版.docx": [
        "V2.1",
        "CONFIRMED",
        "AMBIGUOUS",
        "UNKNOWN",
        "SmartConnect",
        "0x400 + 4 KiB",
        "Vivado 2024.2",
        "Fatal冻结与人工恢复",
    ],
    DOCS
    / "ADC_DDR_NVMe验证用例与测试过程_V1.1_供应商现场验证补充版.docx": [
        "V1.1",
        "参数化黑盒",
        "我方Pattern闭环",
        "Write、Flush和Readback",
        "连续写性能",
        "重新下载程序",
        "AWADDR[11:0]",
        "交付后真实集成验证",
    ],
}

# DOCX最小核心部件：内容类型、包关系、正文和样式。缺少任一项，Word文件即使
# 扩展名正确也不能视为结构完整。
REQUIRED_ZIP_PARTS = {
    "[Content_Types].xml",
    "_rels/.rels",
    "word/document.xml",
    "word/styles.xml",
}


def check_one(path, anchors):
    """检查单个DOCX的容器、核心部件、文本锚点、属性和内容规模。"""

    # 先检查文件存在和ZIP内部CRC，捕获零字节、截断或损坏的DOCX。
    if not path.is_file() or path.stat().st_size == 0:
        raise RuntimeError(f"Missing or empty DOCX: {path}")

    try:
        with ZipFile(path) as package:
            names = set(package.namelist())
            missing = REQUIRED_ZIP_PARTS - names
            if missing:
                raise RuntimeError(f"{path.name}: missing package parts {sorted(missing)}")
            for member in REQUIRED_ZIP_PARTS:
                if not package.read(member):
                    raise RuntimeError(f"{path.name}: empty package part {member}")
            if package.testzip() is not None:
                raise RuntimeError(f"{path.name}: corrupt ZIP member")
    except BadZipFile as exc:
        raise RuntimeError(f"{path.name}: invalid DOCX ZIP") from exc

    # python-docx负责解析WordprocessingML；正文和表格都要计入锚点搜索，
    # 因为三态矩阵和现场用例主要位于表格单元格中。
    doc = Document(path)
    text = "\n".join(paragraph.text for paragraph in doc.paragraphs)
    text += "\n" + "\n".join(
        cell.text
        for table in doc.tables
        for row in table.rows
        for cell in row.cells
    )
    missing_anchors = [anchor for anchor in anchors if anchor not in text]
    if missing_anchors:
        raise RuntimeError(
            f"{path.name}: missing required text anchors {missing_anchors}"
        )
    # 核心标题用于版本识别；最低段落/表格数量用于发现生成流程提前退出。
    if not doc.core_properties.title:
        raise RuntimeError(f"{path.name}: missing core title")
    if len(doc.paragraphs) < 20 or len(doc.tables) < 3:
        raise RuntimeError(
            f"{path.name}: suspiciously small document "
            f"({len(doc.paragraphs)} paragraphs, {len(doc.tables)} tables)"
        )
    return {
        "path": str(path),
        "bytes": path.stat().st_size,
        "paragraphs": len(doc.paragraphs),
        "tables": len(doc.tables),
        "title": doc.core_properties.title,
    }


def main():
    # 任一文档失败立即抛出异常并返回非零；全部通过时逐份输出机器可读PASS行。
    for path, anchors in CHECKS.items():
        result = check_one(path, anchors)
        print(
            "DOCX_STRUCTURE_PASS: "
            f"{result['path']} | {result['bytes']} bytes | "
            f"{result['paragraphs']} paragraphs | {result['tables']} tables | "
            f"title={result['title']}"
        )


if __name__ == "__main__":
    main()
```
