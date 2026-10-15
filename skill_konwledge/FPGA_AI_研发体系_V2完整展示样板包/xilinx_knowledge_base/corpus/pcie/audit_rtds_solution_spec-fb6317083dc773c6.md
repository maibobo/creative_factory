# audit_rtds_solution_spec

- Category: `pcie`
- Source: `E:\PCIE-CPU\docs\audit_rtds_solution_spec.py`
- SHA-256: `fb6317083dc773c604232bffcb96d91d1e4c4d206858e2422979def6f41dd760`
- Extractor: `text`
- Tags: `aurora, engineering, pcie, xdma`
- Duplicate sources:
  - none

```python
from pathlib import Path
import hashlib
import re
import sys
import zipfile
from xml.etree import ElementTree as ET


ROOT = Path(r"E:\PCIE-CPU")
DOCX = ROOT / "docs" / "RTDS_test-1ch_XDMA_Aurora设计与验证方案规格书.docx"
SOURCES = {
    "PCIe.v": (
        ROOT / "backups" / "RTDS_test-1ch_remote_20260819" / "annotated" / "PCIe.v",
        "632FF08DA51CE38544523297727FB6EEE8039F0941B0630B944528FC0F1A67C6",
    ),
    "pcie_fdma_aurora_brg_adapter.v": (
        ROOT / "backups" / "RTDS_test-1ch_remote_20260819" / "annotated" / "pcie_fdma_aurora_brg_adapter.v",
        "3E7CD3552F81EA69794F94D256A65357AB9F631A9619A319850F334BA9E634F5",
    ),
}


def declared_names(source_text):
    names = []
    pattern = re.compile(
        r"^\s*(?:input|output|wire|reg|localparam|parameter)\s+"
        r"(?:(?:reg|wire|integer|signed)\s+)?"
        r"(?:\[[^\]]+\]\s+)?([A-Za-z_][A-Za-z0-9_]*)"
    )
    for line in source_text.splitlines():
        line = line.split("//", 1)[0]
        match = pattern.match(line)
        if match:
            names.append(match.group(1))
    return sorted(set(names))


def docx_text_and_structure(path):
    ns = {"w": "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
    with zipfile.ZipFile(path) as archive:
        bad_member = archive.testzip()
        if bad_member:
            raise RuntimeError(f"corrupt zip member: {bad_member}")
        document = ET.fromstring(archive.read("word/document.xml"))
        text = "\n".join(node.text or "" for node in document.findall(".//w:t", ns))
        headings = []
        for paragraph in document.findall(".//w:p", ns):
            style = paragraph.find("./w:pPr/w:pStyle", ns)
            if style is not None and style.get(f"{{{ns['w']}}}val", "").startswith("Heading"):
                headings.append("".join(node.text or "" for node in paragraph.findall(".//w:t", ns)))
        tables = len(document.findall(".//w:tbl", ns))
        drawings = len(document.findall(".//w:drawing", ns))
        media = [name for name in archive.namelist() if name.startswith("word/media/")]
        doc_pr = document.findall(".//{http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing}docPr")
        missing_alt = [node.get("id") for node in doc_pr if not node.get("descr")]
    return text, headings, tables, drawings, media, missing_alt


def main():
    if not DOCX.exists():
        raise FileNotFoundError(DOCX)
    text, headings, tables, drawings, media, missing_alt = docx_text_and_structure(DOCX)
    if drawings != 17 or len(media) != 17:
        raise AssertionError(f"expected 17 figures, drawings={drawings}, media={len(media)}")
    if missing_alt:
        raise AssertionError(f"figures without alt text: {missing_alt}")
    required_headings = [
        "6.1 PCIe.v 集成模块",
        "6.2 pcie_fdma_aurora_brg_adapter",
        "附录 C：PCIe.v 完整信号词典",
        "附录 D：Adapter 完整信号词典",
        "附录 E：设计规则到 RTL 实现的约束映射",
    ]
    missing_headings = [heading for heading in required_headings if heading not in headings]
    if missing_headings:
        raise AssertionError(f"missing headings: {missing_headings}")

    coverage = {}
    for label, (source_path, expected_hash) in SOURCES.items():
        raw = source_path.read_bytes()
        actual_hash = hashlib.sha256(raw).hexdigest().upper()
        if actual_hash != expected_hash:
            raise AssertionError(f"{label} hash changed: {actual_hash}")
        source_text = raw.decode("utf-8")
        names = declared_names(source_text)
        missing = [name for name in names if name not in text]
        coverage[label] = (len(names), missing)
        if missing:
            raise AssertionError(f"{label} missing declarations in DOCX: {missing}")

    print(f"DOCX_OK size={DOCX.stat().st_size} headings={len(headings)} tables={tables} figures={drawings}")
    for label, (count, missing) in coverage.items():
        print(f"SIGNAL_COVERAGE {label}: declared={count} missing={len(missing)}")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"AUDIT_FAIL: {exc}", file=sys.stderr)
        raise
```
