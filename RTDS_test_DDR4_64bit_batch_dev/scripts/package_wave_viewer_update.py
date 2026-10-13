"""Package only the changed lightweight viewers, illustrated note, and evidence."""
from pathlib import Path
import hashlib
import json
import sys
import zipfile


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "evidence" / "local_wave_sessions"
CASES = ("1g", "tx", "rx_fifo", "ring", "axi", "axi_tail", "regs")


def package(archive_path):
    paths = [
        ROOT / "scripts" / name for name in (
            "local_wave_viewer.html",
            "test_resizable_wave_viewers.cjs",
            "capture_ring_axi_regs_wave_figures.cjs",
            "build_ring_axi_regs_wave_docx.py",
            "wave_figure_notes.py",
            "apply_wave_viewer_update_remote.ps1",
            "package_wave_viewer_update.py",
        )
    ]
    paths += [OUT / case / (case + "_viewer.html") for case in CASES]
    paths += [
        OUT / "WCFG_ring_axi_regs_观察链与时间刻度.md",
        OUT / "WCFG_其余四组观察链与时间刻度.md",
        OUT / "WCFG_ring_axi_regs_观察链与时间刻度_配图_20260928.docx",
        OUT / "trace_probe.py",
        OUT / "resizable_viewer_test_results.json",
    ]
    paths += sorted((OUT / "word_wave_captures").glob("*.png"))
    paths.append(OUT / "word_wave_captures" / "manifest.json")
    entries = []
    for path in paths:
        if not path.is_file():
            raise FileNotFoundError(path)
        entries.append({
            "path": path.relative_to(ROOT).as_posix(),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bytes": path.stat().st_size,
        })
    manifest_path = OUT / "word_wave_captures" / "remote_sync_manifest.json"
    manifest_path.write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding="utf-8")
    paths.append(manifest_path)
    with zipfile.ZipFile(archive_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=5) as archive:
        for path in paths:
            archive.write(path, arcname=path.relative_to(ROOT).as_posix())
    print(json.dumps({"archive": str(archive_path), "files": len(paths),
                      "bytes": archive_path.stat().st_size}, ensure_ascii=False))


if __name__ == "__main__":
    package(Path(sys.argv[1]).resolve())
