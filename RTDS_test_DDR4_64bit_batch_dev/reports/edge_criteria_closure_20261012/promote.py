from pathlib import Path
import json,shutil,hashlib,datetime,html,sys
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
BACK=ROOT/'backups/edge_criteria_before_20261012'
UPLOAD=ROOT/'reports/edge_criteria_closure_20261012'
NOW=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
lp=lambda p:Path('\\\\?\\'+str(p.resolve()))
BACK.mkdir(exist_ok=True)
edge=OUT/'backend_edge_recovery';old_edge=BACK/'evidence_backend_edge_recovery'
# Verify both absolute paths before moving the existing evidence directory on Windows.
assert edge.resolve().is_relative_to(ROOT.resolve()) and old_edge.resolve().is_relative_to(ROOT.resolve())
assert edge.name=='backend_edge_recovery' and old_edge!=edge and OUT.is_dir()
if not old_edge.exists():shutil.move(str(edge),str(old_edge))
else:assert edge.is_dir(),'Expected a partial first copy to resume'
changed=set();parts=[];phase_manifests={}
for mode,suffix,phase in [('main','',0),('early','_early',-1),('late','_late',1)]:
 stage=ROOT/('evidence/local_wave_sessions/edge_criteria_closure_staging_20261012'+suffix)
 target=edge if mode=='main' else edge/('phase_'+mode)
 shutil.copytree(lp(stage/'backend_edge_recovery'),lp(target),dirs_exist_ok=True)
 for p in lp(target).rglob('*'):
  if p.is_file():changed.add(Path(str(p)[4:]).relative_to(OUT).as_posix())
 entry=json.loads((target/'capture_manifest.json').read_text('utf-8'))
 entry['folder']=str(target);entry['edge_phase']=phase
 (target/'capture_manifest.json').write_text(json.dumps(entry,ensure_ascii=False,indent=2),'utf-8')
 phase_manifests[mode]=entry
 text=(stage/'create_and_check_projects.tcl').read_text('utf-8')
 lines=text.splitlines()[1:]
 lines=[x for x in lines if not x.startswith('puts "ALL_SAVED_WAVES_OPENED=') and x!='exit']
 if mode!='main':lines=[x.replace('set here [file join $package backend_edge_recovery]','set here [file join $package backend_edge_recovery phase_'+mode+']') for x in lines]
 lines=[x.replace('POST_TIMING_WAVE_OPEN_OK=backend_edge_recovery','EDGE_WAVE_OPEN_OK='+mode) for x in lines]
 parts+=lines
 # Keep the matched frozen sources/objects; relocate projects only when this Tcl runs at final paths.
 (target/'README.md').write_text((target/'README.md').read_text('utf-8')+'\n最新边界核准说明：EDGE_PHASE='+str(phase)+'，本组代表记录完整通过。所有RTL及约束本轮未改；原失败波形在backups/edge_criteria_before_20261012/evidence_backend_edge_recovery。相邻位置入口见phase_early与phase_late。\n','utf-8')
 changed.add((target/'README.md').relative_to(OUT).as_posix())
for name in ['manifest.json','summary.json','README.md','index.html','delivery_checks.json','delivery_manifest.json','replacement_record.json']:
 if (OUT/name).exists():shutil.copy2(OUT/name,BACK/('package_'+name))
manifest=json.loads((OUT/'manifest.json').read_text('utf-8'))
for i,entry in enumerate(manifest):
 if entry['case']=='backend_edge_recovery':
  manifest[i]=phase_manifests['main'];manifest[i]['phase_variants']={m:{'folder':str(edge/('phase_'+m)),'edge_phase':phase_manifests[m]['edge_phase'],'status':phase_manifests[m]['status']} for m in ['early','late']}
(OUT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8');changed.add('manifest.json')
closure=json.loads((UPLOAD/'closure_summary.json').read_text('utf-8'))
shutil.copy2(UPLOAD/'closure_summary.json',OUT/'edge_criteria_closure_summary.json');changed.add('edge_criteria_closure_summary.json')
for name in ['rtl_unchanged_audit.json','viewer_validation.json','document_structure_checks.json']:
 source=UPLOAD/name
 if source.exists():shutil.copy2(source,OUT/('edge_criteria_'+name));changed.add('edge_criteria_'+name)
old=json.loads((OUT/'summary.json').read_text('utf-8'))
old_runs=old['runs'];current=[]
by={(r['case'],r['seed']):r for r in closure['runs'] if r.get('edge_phase') in (None,0)}
for row in old_runs:
 k=(row['case'],row['seed']);current.append({**by.get(k,row),'evidence_reused_from_original_run':k not in by})
assert len(current)==60 and all(x['status']=='PASS' for x in current)
summary={'date':'2026-10-12','phase':'Latest validated result per testbench/seed after test-only criterion correction; not a single fresh 60-run regression','runs':current,'reused_original_runs':39,'new_related_runs':21,'additional_phase_runs':6,'new_functional_runs_total':27,'representative_recordings':3,'historical_summary':str(BACK/'package_summary.json'),'scope':closure['scope'],'wave_seed':1417633351}
(OUT/'summary.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),'utf-8');changed.add('summary.json')
logs=OUT/'edge_criteria_closure_logs'
for mode,suffix in [('main',''),('early','_early'),('late','_late')]:
 run=ROOT/('verification_20261012/edge_criteria_closure_20261012'+suffix)
 target=logs/mode;target.mkdir(parents=True,exist_ok=True)
 for p in run.iterdir():
  if p.is_file() and p.suffix in ('.log','.json','.options','.tcl'):
   shutil.copy2(p,target/p.name);changed.add((target/p.name).relative_to(OUT).as_posix())
doc_changes=[]
for p in sorted((UPLOAD/'documents').iterdir()):
 if p.suffix not in ('.docx','.md'):continue
 dest=ROOT/'docs'/p.name
 if dest.exists():
  old=BACK/'docs'/p.name;old.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(dest,old)
 try:shutil.copy2(p,dest)
 except PermissionError:
  dest=dest.with_name(dest.stem+'_边界判据核准更新'+dest.suffix);shutil.copy2(p,dest)
 doc_changes.append({'source':str(p),'destination':str(dest),'sha256':sha(dest)})
 if 'DDR恢复边界' in p.name or '时序修复后_快速回归' in p.name:
  if (OUT/p.name).exists():shutil.copy2(OUT/p.name,BACK/('package_'+p.name))
  shutil.copy2(p,OUT/p.name);changed.add(p.name)
note='2026-10-12晚间边界判据核准：仅修改测试台，RTL、模型和约束未改；相关21次＋相邻边界6次，共27/27通过。当前每个快速测试/种子的最新有效结果均为PASS，其中39次复用原回归证据，不表示本轮重新跑了全部60次。原失败和原文档保留在backups/edge_criteria_before_20261012。根目录compiled_sources和quick_regression_logs仍是12:45回归历史快照；新边界使用backend_edge_recovery及其phase_early/phase_late各自匹配sources，最新日志在edge_criteria_closure_logs。详情见RTDS_DDR恢复边界_测试判据核准与验证_20261012.docx。'
(OUT/'README.md').write_text('# 最新边界判据核准结果\n\n'+note+'\n\n'+(OUT/'README.md').read_text('utf-8'),'utf-8');changed.add('README.md')
links=''.join('<li>'+html.escape(x['case']+' '+x['title']+' '+x['status'])+' <a href="'+x['case']+'/viewer.html">波形</a> <a href="'+x['case']+'/README.md">说明</a></li>' for x in manifest)
links+='<li>DDR前一拍 <a href="backend_edge_recovery/phase_early/viewer.html">波形</a></li><li>DDR后一拍 <a href="backend_edge_recovery/phase_late/viewer.html">波形</a></li>'
(OUT/'index.html').write_text('<!doctype html><meta charset="utf-8"><title>RTDS 当前设计仿真证据</title><h1>RTDS 典型波形</h1><p>'+html.escape(note)+'</p><ul>'+links+'</ul>','utf-8');changed.add('index.html')
checks={'checked':NOW,'new_functional_runs':27,'pass':27,'edge_modes_and_seeds':9,'case_deleted':False,'rtl_and_constraints_unchanged':closure['rtl_audit'],'viewer_checks':json.loads((UPLOAD/'viewer_validation.json').read_text('utf-8')),'documents':doc_changes,'native_wave_check':'Pending saved WDB/WCFG check at final paths','historical_checks':str(BACK/'package_delivery_checks.json'),'latest_matrix_pass':60,'latest_matrix_reused_runs':39,'scope':closure['scope']}
(OUT/'delivery_checks.json').write_text(json.dumps(checks,ensure_ascii=False,indent=2),'utf-8');changed.add('delivery_checks.json')
check_tcl=['set package [file dirname [file normalize [info script]]]',*parts,'puts "ALL_EDGE_WAVES_OPENED=3"','exit']
(OUT/'create_and_check_edge_projects.tcl').write_text('\n'.join(check_tcl)+'\n','utf-8');changed.add('create_and_check_edge_projects.tcl')
record={'completed':NOW,'replaced_case':'backend_edge_recovery','old_evidence':str(old_edge),'phase_variants':phase_manifests,'documents':doc_changes,'rtl_modified':False,'functional_runs':27}
(OUT/'edge_criteria_replacement_record.json').write_text(json.dumps(record,ensure_ascii=False,indent=2),'utf-8');changed.add('edge_criteria_replacement_record.json')
# Incremental manifest refresh: retain unchanged large waveform hashes, hash only changed/new files.
old_manifest=json.loads((OUT/'delivery_manifest.json').read_text('utf-8'))
files={x['path']:x for x in old_manifest['files'] if not x['path'].startswith('backend_edge_recovery/')}
for rel in sorted(changed):
 f=lp(OUT/rel)
 if f.is_file():files[rel]={'path':rel,'bytes':f.stat().st_size,'sha256':sha(f)}
old_manifest['created']=NOW;old_manifest['files']=list(files.values());old_manifest['edge_criteria_update']=str(OUT/'edge_criteria_replacement_record.json')
(OUT/'delivery_manifest.json').write_text(json.dumps(old_manifest,ensure_ascii=False,indent=2),'utf-8')
print('EDGE_EVIDENCE_AND_DOCUMENTS_PROMOTED')
