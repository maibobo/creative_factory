from pathlib import Path
import xml.etree.ElementTree as ET,json,hashlib,zipfile
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'reports/core_annotation_20261012';OUT.mkdir(parents=True,exist_ok=True)
tree=ET.parse(ROOT/'RTDS_test_DDR4_64bit.xpr');files=[]
for fs in tree.findall('.//FileSet'):
    if fs.get('Name')!='sources_1':continue
    for f in fs.findall('File'):
        raw=f.get('Path','').replace('\\','/')
        if not raw.lower().endswith(('.v','.sv')):continue
        if any(a.get('Name')=='AutoDisabled' and a.get('Val')=='1' for a in f.findall('.//Attr')):continue
        raw=raw.replace('$PSRCDIR/',str(ROOT/'RTDS_test_DDR4_64bit.srcs')+'/').replace('$PPRDIR/',str(ROOT)+'/')
        p=Path(raw)
        if not p.exists():raise FileNotFoundError(p)
        rel=str(p.relative_to(ROOT)).replace('\\','/')
        if rel.startswith('rtl/') or rel.startswith('RTDS_test_DDR4_64bit.srcs/sources_1/new/') or p.name in ('fdma_aurora_brg_tx.v','aurora_64b66b_top.v'):
            files.append(p)
# The behavioral RAM is a companion module and belongs to the requested DDR pair.
ram=ROOT/'rtl/ddr4/rtds_axi_ram_model.sv'
if ram not in files:files.append(ram)
files=sorted(set(files));manifest=[];instructions=[]
for p in files:
    rel=str(p.relative_to(ROOT)).replace('\\','/')
    manifest.append({'path':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size})
    parent=p.parent
    while parent!=ROOT.parent:
        q=parent/'AGENTS.md'
        if q.exists() and q not in instructions:instructions.append(q)
        if parent==ROOT:break
        parent=parent.parent
(OUT/'source_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
with zipfile.ZipFile(OUT/'core_sources_before.zip','w',zipfile.ZIP_DEFLATED) as z:
    for p in files:z.write(p,str(p.relative_to(ROOT)).replace('\\','/'))
    for p in instructions:z.write(p,str(p.relative_to(ROOT)).replace('\\','/'))
    z.write(ROOT/'RTDS_test_DDR4_64bit.xpr','RTDS_test_DDR4_64bit.xpr')
    z.write(OUT/'source_manifest.json','source_manifest.json')
print(json.dumps({'files':len(files),'paths':[x['path'] for x in manifest],'instructions':[str(p) for p in instructions]},ensure_ascii=False))
