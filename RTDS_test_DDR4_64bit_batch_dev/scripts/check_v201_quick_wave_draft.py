from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED
from lxml import etree
from docx import Document

ROOT = Path(__file__).resolve().parents[1]
DOCX = ROOT / "docs" / "RTDS_V2.01快速仿真波形确认稿.docx"
assert DOCX.is_file() and DOCX.stat().st_size > 100_000
with ZipFile(DOCX) as zf:
    bad = zf.testzip()
    assert bad is None, bad
    names = set(zf.namelist())
    for required in ("[Content_Types].xml", "word/document.xml", "word/_rels/document.xml.rels"):
        assert required in names
    doc_xml = etree.fromstring(zf.read("word/document.xml"))
    rel_xml = etree.fromstring(zf.read("word/_rels/document.xml.rels"))
    ns = {
        "w":"http://schemas.openxmlformats.org/wordprocessingml/2006/main",
        "a":"http://schemas.openxmlformats.org/drawingml/2006/main",
        "r":"http://schemas.openxmlformats.org/officeDocument/2006/relationships",
        "pr":"http://schemas.openxmlformats.org/package/2006/relationships",
    }
    blips = doc_xml.xpath(".//a:blip/@r:embed", namespaces=ns)
    assert len(blips) == 17, len(blips)
    image_rels = {x.get("Id"):x.get("Target") for x in rel_xml.xpath(".//pr:Relationship", namespaces=ns) if x.get("Type","").endswith("/image")}
    used = [image_rels[x] for x in blips]
    assert len(set(used)) == 17
    assert all(("word/" + target.replace("../", "")) in names or ("word/" + target) in names for target in used)
    headings = ["".join(x.xpath(".//w:t/text()", namespaces=ns)) for x in doc_xml.xpath(".//w:p", namespaces=ns)]
    assert any("RTDS V2.01 快速仿真波形确认稿" in x for x in headings)
    assert any("VCD波形重绘图" in x for x in headings)
    instr = " ".join(doc_xml.xpath(".//w:instrText/text()", namespaces=ns))
    assert "TOC" in instr
doc = Document(DOCX)
assert len(doc.inline_shapes) == 17
expected = int(17.2 / 2.54 * 914400)
for shape in doc.inline_shapes:
    assert abs(shape.width - expected) < 5000, shape.width
print(f"DOCX_STRUCTURE_PASS inline_shapes={len(doc.inline_shapes)} tables={len(doc.tables)} sections={len(doc.sections)}")
