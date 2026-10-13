from pathlib import Path
import hashlib,json
root=Path(__file__).resolve().parent.parent
items=json.loads((root/'manifest/source_manifest.json').read_text())
for item in items:
    path=root/item['package']
    assert path.is_file(), str(path)
    if 'sha256' in item: assert hashlib.sha256(path.read_bytes()).hexdigest()==item['sha256'], str(path)
for line in (root/'full.f').read_text().splitlines(): assert (root/line).is_file(), line
print('STATIC_PACKAGE_FILES_PASS',len(items))
