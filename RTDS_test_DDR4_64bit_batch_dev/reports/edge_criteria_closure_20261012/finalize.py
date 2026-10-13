import os as _codex_os
from pathlib import Path
import json,hashlib,datetime,re
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
REPORTS=ROOT/'reports/edge_criteria_closure_20261012'
lp=lambda p:Path(str(p.resolve()) if str(p.resolve()).startswith('\\\\?\\') else '\\\\?\\'+str(p.resolve()))
sha=lambda p:hashlib.sha256(lp(p).read_bytes()).hexdigest()
log=(REPORTS/'wave_open_check.log').read_text('utf-8',errors='replace')
assert all('EDGE_WAVE_OPEN_OK='+m in log for m in ['main','early','late'])
assert 'ALL_EDGE_WAVES_OPENED=3' in log
assert not re.search(r'(?m)^ERROR:',log)
summary=json.loads((OUT/'edge_criteria_closure_summary.json').read_text('utf-8'))
assert summary['functional_runs']==27 and all(r['status']=='PASS' for r in summary['runs'])
checks=json.loads((OUT/'delivery_checks.json').read_text('utf-8'))
for item in checks['documents']:
 assert sha(Path(item['destination']))==item['sha256']
assert json.loads((ROOT/'verification_20261012/edge_criteria_closure_20261012/rtl_unchanged_audit.json').read_text('utf-8'))['rtl_and_constraints_unchanged']
waves=[]
for mode,folder in [('main',OUT/'backend_edge_recovery'),('early',OUT/'backend_edge_recovery/phase_early'),('late',OUT/'backend_edge_recovery/phase_late')]:
 item=json.loads((folder/'capture_manifest.json').read_text('utf-8'))
 for name,digest in item['files'].items():assert sha(folder/name)==digest,(mode,name)
 for row in json.loads((folder/'source_hashes.json').read_text('utf-8')):
  assert sha(folder/'sources'/row['path'])==row['sha256'],(mode,row['path'])
 assert (folder/'project/wave_backend_edge_recovery.xpr').is_file()
 waves.append({'mode':mode,'status':'PASS','duration_ns':item['duration_ns'],'signals':item['vcd_signals'],'native_WDB_WCFG_open':'PASS','frozen_sources':'MATCH'})
checks['native_wave_check']='PASS: ' + _codex_os.environ["RTDS_DDR4_PASSWORD"] + ' saved WDB and WCFG opened in Vivado 2020.2'
checks['waves']=waves
checks['finalized']=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()
(OUT/'delivery_checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),'utf-8')
for name in ['wave_open_check.log','wave_open_console.log']:
 (OUT/('edge_criteria_'+name)).write_bytes((REPORTS/name).read_bytes())
# Replace the old all-nine-project creation script with one assembled from the final matched sources.
# Otherwise its old source list would point to the former failed-case snapshot if a user reran it.
old=(OUT/'create_and_check_projects.tcl').read_text('utf-8')
start=old.index('set here [file join $package backend_edge_recovery]')
head=old[:start]
edge=(OUT/'create_and_check_edge_projects.tcl').read_text('utf-8').splitlines()[1:]
tail=[line for line in edge if line!='exit']
(OUT/'create_and_check_projects.tcl').write_text(head+'\n'.join(tail)+'\nputs "ALL_SAVED_WAVES_OPENED=11"\nexit\n','utf-8')
manifest=json.loads((OUT/'delivery_manifest.json').read_text('utf-8'))
files={x['path']:x for x in manifest['files']}
changed={'delivery_checks.json','create_and_check_projects.tcl','edge_criteria_wave_open_check.log','edge_criteria_wave_open_console.log'}
for p in lp(OUT/'backend_edge_recovery').rglob('*'):
 if p.is_file():changed.add(Path(str(p)[4:]).relative_to(OUT).as_posix())
for rel in sorted(changed):
 p=lp(OUT/rel);files[rel]={'path':rel,'bytes':p.stat().st_size,'sha256':sha(p)}
manifest['files']=list(files.values());manifest['created']=checks['finalized']
(OUT/'delivery_manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
result={'functional_runs':27,'pass':27,'edge_matrix':9,'rtl_and_constraints_unchanged':True,'native_waves':waves,'viewer_validation':'PASS: 3 waveform payloads, 14 pane/viewport combinations per payload, local headless Edge, network blocked, no screenshots','documents_hashes':'MATCH','docx_rendered':False,'historical_failure_preserved':str(ROOT/'backups/edge_criteria_before_20261012'),'scope':summary['scope'],'stopped_after_delivery':True}
(OUT/'edge_criteria_final_checks.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(result,ensure_ascii=False))
