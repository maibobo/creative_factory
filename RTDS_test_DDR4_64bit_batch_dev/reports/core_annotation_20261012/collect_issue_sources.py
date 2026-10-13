import json
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(r'C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev')
out = root / 'reports/core_annotation_20261012/historical_issue_sources.zip'
files = []
files += list((root / 'docs').glob('*.md'))
for dirname in ['impl_20260920', 'impl_20260920_fix', 'impl_after_mig_clock_fix_20260920', 'timing_fix_gui_20260921', 'board_audit_20260921', 'timing_fix_20261012', 'post_timing_quick_20261012']:
    p = root / 'reports' / dirname
    files += [f for f in p.rglob('*') if f.is_file() and f.suffix.lower() in ['.rpt', '.log', '.md', '.tcl', '.json'] and f.stat().st_size < 15_000_000]
for f in (root / 'RTDS_test_DDR4_64bit.runs/impl_1').glob('*'):
    if f.is_file() and f.suffix.lower() in ['.rpt', '.log', '.tcl']:
        files.append(f)
manifest = []
with ZipFile(out, 'w', ZIP_DEFLATED) as z:
    for f in sorted(set(files)):
        rel = f.relative_to(root).as_posix()
        z.write(f, rel)
        manifest.append({'path': rel, 'size': f.stat().st_size, 'mtime': f.stat().st_mtime})
    z.writestr('source_manifest.json', json.dumps(manifest, ensure_ascii=False, indent=2))
print(json.dumps({'files': len(files), 'zip_bytes': out.stat().st_size}))
