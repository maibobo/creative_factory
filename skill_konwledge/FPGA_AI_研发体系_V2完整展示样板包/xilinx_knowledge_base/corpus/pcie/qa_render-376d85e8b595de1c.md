# qa_render

- Category: `pcie`
- Source: `R:\nvme_adc_axi_pipeline\docs\qa_render.py`
- SHA-256: `376d85e8b595de1c020bd728dc5815c1b0a050f0625ffae17880a1a1095b81c6`
- Extractor: `text`
- Tags: `ddr, integration, nvme, pcie`
- Duplicate sources:
  - E:\NVME_PRO\nvme_adc_axi_pipeline\docs\qa_render.py

```python
from pathlib import Path
import json
import pypdfium2 as pdfium
from PIL import ImageChops, Image
from pypdf import PdfReader


ROOT = Path(__file__).resolve().parents[1]
PDF = ROOT / "docs" / "rendered_v1_checked" / "NVMe_ADC_DDR_FPGA基础通路设计方案_V1.0_接口与时序补充版.pdf"
PAGE_DIR = ROOT / "docs" / "rendered_v1_checked" / "pages"
PAGE_DIR.mkdir(parents=True, exist_ok=True)

pdf = pdfium.PdfDocument(str(PDF))
reader = PdfReader(str(PDF))
results = []

for index, page in enumerate(pdf):
    bitmap = page.render(scale=1.5)
    image = bitmap.to_pil().convert("RGB")
    page_path = PAGE_DIR / f"page-{index + 1:02d}.png"
    image.save(page_path)

    white = Image.new("RGB", image.size, "white")
    diff = ImageChops.difference(image, white)
    bbox = diff.getbbox()
    text = reader.pages[index].extract_text() or ""

    edge = 12
    edge_pixels = 0
    width, height = image.size
    gray = image.convert("L")
    for crop in (
        gray.crop((0, 0, width, edge)),
        gray.crop((0, height - edge, width, height)),
        gray.crop((0, 0, edge, height)),
        gray.crop((width - edge, 0, width, height)),
    ):
        edge_pixels += sum(1 for px in crop.getdata() if px < 245)

    results.append(
        {
            "page": index + 1,
            "size": [width, height],
            "content_bbox": list(bbox) if bbox else None,
            "text_chars": len(text.strip()),
            "edge_dark_pixels": edge_pixels,
        }
    )

summary = {
    "page_count": len(pdf),
    "blank_pages": [r["page"] for r in results if r["text_chars"] < 20],
    "edge_contact_pages": [r["page"] for r in results if r["edge_dark_pixels"] > 0],
    "pages": results,
}
print(json.dumps(summary, ensure_ascii=False, indent=2))
```
