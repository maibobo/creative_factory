from pathlib import Path
import shutil,json,datetime,hashlib,sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev').resolve()
TARGET=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
STAGE=TARGET.with_name(TARGET.name+'_post_timing_staging')
STAMP=datetime.datetime.now().strftime('%Y%m%d_%H%M%S')
BACKUP=ROOT/'backups'/('evidence_before_post_timing_'+STAMP)
DBAK=ROOT/'backups'/('documents_before_post_timing_'+STAMP)
for p in [TARGET,STAGE,BACKUP,DBAK]:
    assert p.resolve().is_relative_to(ROOT) and p.resolve()!=ROOT,p
assert STAGE.exists() and TARGET.exists() and not BACKUP.exists()
manifest=json.loads((STAGE/'manifest.json').read_text('utf-8'))
assert len(manifest)==9
for item in manifest:
    for f,digest in item['files'].items():assert hashlib.sha256((STAGE/item['case']/f).read_bytes()).hexdigest()==digest,(item['case'],f)
assert len(list(STAGE.glob('RTDS_时序修复后*.docx')))==1
DBAK.mkdir(parents=True)
document_destinations=[]
for p in list((STAGE/'documents_to_sync').iterdir()):
    old=ROOT/'docs'/p.name
    if old.exists():shutil.copy2(old,DBAK/p.name)
    destination=old
    try:shutil.copy2(p,old)
    except PermissionError:
        destination=old.with_name(old.stem+'_时序修复后回归更新'+old.suffix)
        shutil.copy2(p,destination)
    document_destinations.append({'requested':str(old),'saved':str(destination),'saved_separately_due_to_open_file':destination!=old,'sha256':hashlib.sha256(destination.read_bytes()).hexdigest()})
    p.unlink()
(STAGE/'documents_to_sync').rmdir()
TARGET.rename(BACKUP)
STAGE.rename(TARGET)
readme='''# RTDS 时序修复后快速回归与典型波形 · 2026-10-12

当前基线：远程已收敛时序的工程源码冻结副本。20个快速测试台、三个种子，共60次：57通过，3次是同一backend_edge_recovery历史未关闭判据失败。19个测试台全种子通过。1G已是四拍格式。

原五组波形与相关日志/源码/信号表已替换，增加DDR读/写恢复、上行块管理及同拍失败诊断，共9组。第一种子1417633351记录代表波形，其余种子结果见原日志。8次显式WDB录制加1次失败诊断与60次主回归分开记录。

详细说明：RTDS_时序修复后_快速回归与典型波形详解_20261012.docx（Markdown同名），从设计原因、输入变量、信号含义、实际边沿时间、接受拍数据到历史对照逐组说明。原三份设计/恢复/配图文档已同步更新到工程docs，配图文档41张历史图保持原媒体字节。

打开index.html可选离线查看器；组内Open_<组名>.cmd打开Vivado已记录WDB/WCFG，不重跑仿真。recording/source_hashes绑定冻结编译副本。HTML不支持的real/string对象及WCFG未进入VCD对象分别列出，不制造0值历史。

本轮未重跑100ms生产周期、真实MIG/Root Port、板级验证，也未进行带SDF的门级仿真；实现时序通过和RTL功能结果分别记录。当前完整TOP CDC未由这些局部用例签核。
'''
(TARGET/'README.md').write_text(readme+'\n上午波形备份：'+str(BACKUP)+'\n文档备份：'+str(DBAK)+'\n'+''.join('\n正在打开的文档另存新版：'+x['saved']+'\n' for x in document_destinations if x['saved_separately_due_to_open_file']),'utf-8')
entry=ROOT/'docs/仿真与设计资料入口_20261012.md'
if entry.exists():shutil.copy2(entry,DBAK/entry.name)
entry.write_text(readme+'\n当前波形目录：'+str(TARGET)+'\n详细报告：docs/RTDS_时序修复后_快速回归与典型波形详解_20261012.docx\n上午版本仅为备份：'+str(BACKUP)+'\n'+''.join('\n正在打开的文档另存新版：'+x['saved']+'\n' for x in document_destinations if x['saved_separately_due_to_open_file']),'utf-8')
delivery={'phase':'post_timing_fix','date':'2026-10-12','target':str(TARGET),'previous_package_backup':str(BACKUP),'previous_documents_backup':str(DBAK),'document_destinations':document_destinations,'other_document_backups':[str(x) for x in (ROOT/'backups').glob('documents_before_post_timing_*')],'cases':9,'quick_runs':60,'pass':57,'functional_fail':3,'failed_case':'backend_edge_recovery','no_RTL_or_test_criteria_modified':True,'replaced':datetime.datetime.now().isoformat()}
(TARGET/'replacement_record.json').write_text(json.dumps(delivery,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(delivery,ensure_ascii=False))
