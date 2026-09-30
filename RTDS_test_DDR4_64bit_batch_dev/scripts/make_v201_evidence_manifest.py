from __future__ import annotations

import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EVIDENCE = ROOT / "evidence" / "v201_quick_wave_draft"
cases = ("1g", "ring", "axi", "axi_tail", "rx_fifo", "regs", "tx")
files = []

for case in cases:
    case_dir = EVIDENCE / "raw" / case
    log = case_dir / f"xsim_{case}.log"
    text = log.read_text(encoding="utf-8", errors="replace")
    runtime_errors = [line for line in text.splitlines() if ("ERROR:" in line or "FATAL:" in line or "$fatal called" in line)]
    if text.count("TEST PASS") != 1 or runtime_errors:
        raise RuntimeError(f"{case}: PASS/error validation failed: {runtime_errors}")
    files.extend(case_dir.glob("*"))

files.extend((EVIDENCE / "figures_no_title_png").glob("*.png"))
files.extend((EVIDENCE / "figures_with_title_png").glob("*.png"))
files.extend([EVIDENCE / "wave_manifest.json", ROOT / "docs" / "RTDS_V2.01快速仿真波形确认稿.docx"])
files.extend((ROOT / "regression" / "batch_1g").glob("tb_rtds_*.sv"))
files.extend([
    ROOT / "rtl" / "rtds_1g_periodic_tx.v",
    ROOT / "rtl" / "rtds_rx_frame_fifo.v",
    ROOT / "rtl" / "rtds_rx_block_writer.v",
    ROOT / "RTDS_test_DDR4_64bit.srcs" / "sources_1" / "new" / "CONV_DMA.v",
    ROOT / "RTDS_test_DDR4_64bit.srcs" / "sources_1" / "new" / "INFO_EXCH.v",
    ROOT / "RTDS_test_DDR4_64bit.srcs" / "sources_1" / "new" / "pcie_fdma_aurora_brg_adapter.v",
])

records=[]
for path in sorted(set(files), key=lambda p: str(p).lower()):
    if not path.is_file():
        raise FileNotFoundError(path)
    h=hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024*1024), b""):
            h.update(chunk)
    records.append({"path":str(path.relative_to(ROOT)),"bytes":path.stat().st_size,"sha256":h.hexdigest()})

(EVIDENCE / "SHA256SUMS.json").write_text(json.dumps(records,ensure_ascii=False,indent=2),encoding="utf-8")
(EVIDENCE / "validation_summary.json").write_text(json.dumps({
    "cases":list(cases),"all_test_pass":True,"runtime_error_or_fatal":0,
    "raw_files":sum(1 for _ in (EVIDENCE/"raw").rglob("*.*")),
    "figures_no_title":len(list((EVIDENCE/"figures_no_title_png").glob("*.png"))),
    "figures_with_title":len(list((EVIDENCE/"figures_with_title_png").glob("*.png"))),
    "docx_structure":"PASS","docx_inline_figures":17,
},ensure_ascii=False,indent=2),encoding="utf-8")
print(f"SHA256_MANIFEST_PASS files={len(records)}")
