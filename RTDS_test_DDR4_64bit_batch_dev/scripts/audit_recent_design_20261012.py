from pathlib import Path
import json,hashlib,datetime
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'reports/core_annotation_20261012'
dirs=[ROOT/'rtl',ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new',ROOT/'RTDS_test_DDR4_64bit.srcs/constrs_1']
rows=[]
for d in dirs:
    if not d.exists():continue
    for p in d.rglob('*'):
        if p.is_file() and p.suffix.lower() in ('.v','.sv','.xdc'):
            stamp=datetime.datetime.fromtimestamp(p.stat().st_mtime)
            if stamp>=datetime.datetime(2026,10,10):
                comments=[l.strip() for l in p.read_text('utf-8-sig',errors='replace').splitlines() if '2026-10-1' in l and ('//' in l or l.startswith('#'))]
                rows.append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'last_write':stamp.isoformat(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'dated_comments':comments[:6]})
(OUT/'recent_design_before.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(rows,ensure_ascii=False))
