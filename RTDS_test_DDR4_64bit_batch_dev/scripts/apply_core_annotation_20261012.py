from pathlib import Path
import json,hashlib,zipfile,subprocess,sys,datetime,shutil,re,ast
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
REPORT=ROOT/'reports/core_annotation_20261012'
PACKAGE=REPORT/'core_annotations_after.zip'
STAGE=REPORT/'prepared';STAGE.mkdir(exist_ok=True)
with zipfile.ZipFile(PACKAGE) as z:
    for name in z.namelist():
        if not (STAGE/name).resolve().is_relative_to(STAGE.resolve()):raise ValueError(name)
    z.extractall(STAGE)
checks=json.loads((STAGE/'annotation_checks.json').read_text('utf-8'))
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Load only lexical comparison helpers, never the formatting script's top-level edits.
source=(REPORT/'annotate_source.py').read_text('utf-8');tree=ast.parse(source)
pieces=[ast.get_source_segment(source,n) for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ('strip','top_split','expand_declarations','tokens')]
ns={'re':re};exec('\n\n'.join(pieces),ns)
pending=[]
previous_file=REPORT/'delivery_checks.json'
previous=json.loads(previous_file.read_text('utf-8')) if previous_file.exists() else {}
previous_hash={x['path']:x['after_sha256'] for x in previous.get('files',[])}
for c in checks:
    p=ROOT/c['path'];q=STAGE/c['path']
    assert H(q)==c['after_sha256'],q
    if H(p)==c['after_sha256']:continue
    if H(p) not in (c['before_sha256'],previous_hash.get(c['path'])):raise RuntimeError('File changed concurrently: '+str(p))
    assert ns['tokens'](p.read_text('utf-8-sig'))==ns['tokens'](q.read_text('utf-8-sig')),p
    pending.append({**c,'current_sha256':H(p)})
# Compile syntax in both preprocessor configurations before overwriting source files.
BIN=Path('C:/Xilinx/Vivado/2020.2/bin')
for mode in ('DDR4_REAL','DDR4_SIM_RAM'):
    wd=REPORT/('syntax_'+mode);wd.mkdir(exist_ok=True)
    flat=wd/'src';flat.mkdir(exist_ok=True)
    compile_files=[]
    for c in checks:
        q=flat/Path(c['path']).name;shutil.copy2(STAGE/c['path'],q);compile_files.append(str(q))
    args=[str(BIN/'xvlog.bat'),'-sv','-d',mode]+compile_files
    log=wd/'syntax.log'
    with log.open('w',encoding='utf-8') as f:
        p=subprocess.run(subprocess.list2cmdline(args),shell=True,cwd=wd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=120)
    if p.returncode:raise RuntimeError('Syntax check failed: '+str(log))
BACKUP=ROOT/'backups/core_annotation_20261012'
for c in pending:
    p=ROOT/c['path'];q=STAGE/c['path'];back=BACKUP/c['path']
    if H(p)!=c['current_sha256']:raise RuntimeError('Changed after syntax check: '+str(p))
    back.parent.mkdir(parents=True,exist_ok=True)
    if not back.exists():shutil.copy2(p,back)
    elif H(back)!=c['before_sha256']:raise RuntimeError('Different backup already exists: '+str(back))
    shutil.copy2(q,p)
    assert H(p)==c['after_sha256']
result={'date':'2026-10-12','files':checks,'applied':len(pending),'syntax_modes':['DDR4_REAL','DDR4_SIM_RAM'],'logic_token_equivalence':True,'backup':str(BACKUP),'simulation_rerun':False}
(REPORT/'delivery_checks.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps({'applied':len(pending),'total_files':len(checks),'syntax':'PASS both modes','tokens':'equal','backup':str(BACKUP)},ensure_ascii=False))
