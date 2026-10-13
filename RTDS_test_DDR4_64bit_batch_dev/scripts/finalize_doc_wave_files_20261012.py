from pathlib import Path
import json,hashlib,xml.etree.ElementTree as ET
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
P=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
M=json.loads((P/'manifest.json').read_text('utf-8'))
check=['set package [file dirname [file normalize [info script]]]']
for m in M:
    d=P/m['case'];tree=ET.parse(d/'recommended.wcfg');sig=[]
    for node in tree.getroot().iter():
        if node.tag=='db_ref':node.set('path','trace.wdb')
        if node.tag=='wvobject' and node.get('fp_name'):sig.append(node.get('fp_name'))
    assert sig,m['case']
    tree.write(d/'recommended.wcfg',encoding='utf-8',xml_declaration=True)
    (d/'recommended_signals.list').write_text('\n'.join(sig)+'\n','utf-8')
    m['recommended_signals']=sig;m['files']['recommended.wcfg']=hashlib.sha256((d/'recommended.wcfg').read_bytes()).hexdigest()
    (d/'capture_manifest.json').write_text(json.dumps(m,ensure_ascii=False,indent=2),'utf-8')
    check+=['set here [file join $package '+m['case']+']','open_project -read_only [file join $here project wave_'+m['case']+'.xpr]',
        'open_wave_database [file join $here trace.wdb]','open_wave_config [file join $here recommended.wcfg]',
        'puts "FINAL_WAVE_OPEN_OK='+m['case']+'"','close_sim','close_project']
(P/'manifest.json').write_text(json.dumps(M,ensure_ascii=False,indent=2),'utf-8')
(P/'verify_saved_wave_only.tcl').write_text('\n'.join(check)+'\n','utf-8')
print([(m['case'],len(m['recommended_signals'])) for m in M])
