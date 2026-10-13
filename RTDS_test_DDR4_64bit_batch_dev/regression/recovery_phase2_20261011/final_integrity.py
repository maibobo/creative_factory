from pathlib import Path
import json,hashlib,zipfile,xml.etree.ElementTree as ET,datetime,re
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
LONG=Path('\\\\?\\'+str(OUT))
hashfile=lambda p:hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
manifest=json.loads((OUT/'manifest.json').read_text('utf-8'))
summary=json.loads((OUT/'summary.json').read_text('utf-8'))
openlog=(OUT/'wave_open_check.log').read_text('utf-8',errors='replace')
assert len(manifest)==9 and len(summary['runs'])==60
assert sum(r['status']=='PASS' for r in summary['runs'])==57
assert {r['case'] for r in summary['runs'] if r['status']!='PASS'}=={'backend_edge_recovery'}
checks=[]
for item in manifest:
    folder=LONG/item['case']
    for name,h in item['files'].items():assert hashfile(folder/name)==h,(item['case'],name)
    assert 'POST_TIMING_WAVE_OPEN_OK='+item['case'] in openlog
    for row in json.loads((folder/'source_hashes.json').read_text('utf-8')):
        assert hashfile(folder/'sources'/row['path'])==row['sha256'],row['path']
    wcfg=ET.parse(folder/'recommended.wcfg')
    assert all(e.get('path')=='trace.wdb' for e in wcfg.getroot().iter('db_ref'))
    checks.append({'case':item['case'],'status':item['status'],'recorded_source_hashes':'MATCH','native_WDB_WCFG_open':'PASS','artifact_hashes':'MATCH'})
assert 'ALL_SAVED_WAVES_OPENED=9' in openlog
docs=json.loads((OUT/'document_structure_checks.json').read_text('utf-8'))
docchecks=[]
for row in docs:
    p=ROOT/'docs'/row['file']
    if hashfile(p)!=row['sha256']:
        p=p.with_name(p.stem+'_时序修复后回归更新'+p.suffix)
    assert hashfile(p)==row['sha256'],p
    with zipfile.ZipFile(p) as z:
        assert z.testzip() is None
        for name in z.namelist():
            if name.endswith('.xml'):ET.fromstring(z.read(name))
    docchecks.append({'file':str(p),'sha256':row['sha256'],'structure':'PASS','original_media_preserved':row['original_media_preserved']})
R=ROOT/'verification_20261012/post_timing_quick_20261012'
finished=json.loads((R/'completion.json').read_text('utf-8'))['finished']
running={'state':'completed','finished':finished,'runs':60,'remaining_running_tools':0}
(R/'running_tool.json').write_text(json.dumps(running,indent=2),'utf-8')
(OUT/'quick_regression_logs/running_tool.json').write_text(json.dumps(running,indent=2),'utf-8')
# Detect any active source changes after the frozen compilation, without changing source files.
live_changes=[]
for row in json.loads((OUT/'source_hashes.json').read_text('utf-8')):
    p=ROOT/row['path']
    if hashfile(p)!=row['sha256']:live_changes.append(row['path'])
result={'checked':datetime.datetime.now().isoformat(),'quick_runs':60,'pass':57,'fail':3,'failed_case':'backend_edge_recovery','cases':checks,'documents':docchecks,'active_source_changed_since_frozen_compilation':live_changes,'viewer_validation':'PASS 9 cases, 14 pane combinations each, blocked external network, no screenshots','implementation_timing':'11:39:31 WNS +0.077ns WHS +0.004ns all failing endpoints zero'}
audit=json.loads((OUT/'live_source_changes_during_regression.json').read_text('utf-8'))
assert audit['all_changed_files_functional_tokens_equivalent'],'Active RTL behavior changed; cannot describe it as annotation-only'
result['active_source_annotation_change_audit']=audit
(OUT/'delivery_checks.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),'utf-8')
replacement=json.loads((OUT/'replacement_record.json').read_text('utf-8'))
for row in replacement.get('document_destinations',[]):row['sha256']=hashfile(Path(row['saved']))
replacement['updated_related_documents']=docchecks
replacement['final_audit']=result['checked']
(OUT/'replacement_record.json').write_text(json.dumps(replacement,ensure_ascii=False,indent=2),'utf-8')
inventory=[]
for p in LONG.rglob('*'):
    if not p.is_file() or p.name=='delivery_manifest.json':continue
    if '.Xil' in p.parts or p.suffix in ('.jou',):continue
    inventory.append({'path':str(p.relative_to(LONG)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':hashfile(p)})
(OUT/'delivery_manifest.json').write_text(json.dumps({'created':result['checked'],'root':str(OUT),'files':inventory,'replacement':json.loads((OUT/'replacement_record.json').read_text('utf-8'))},ensure_ascii=False,indent=2),'utf-8')
print(json.dumps({'files':len(inventory),'bytes':sum(x['bytes'] for x in inventory),'native_wave_groups_opened':9,'source_changes_since_compile':live_changes,'docs':docchecks,'quick_pass':57,'quick_fail':3},ensure_ascii=False))
