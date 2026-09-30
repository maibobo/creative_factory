from pathlib import Path
import json,re,xml.etree.ElementTree as ET
from summarize_local_wave_sessions import ROOT,OUT,CASES,norm

log=(ROOT/'logs/build_local_wave_sessions.log').read_text(encoding='utf-8',errors='replace')
unsupported=set(norm(s) for s in re.findall(r'WARNING: Simulation object (.*?) was not traceable',log))
report=[]
for case in CASES:
    folder=OUT/case
    loaded={norm(s) for s in (folder/'loaded_objects.txt').read_text(encoding='utf-8-sig').splitlines() if s}
    tree=ET.parse(folder/f'{case}.wcfg')
    listed={norm(s.get('fp_name')) for s in tree.findall('.//wvobject') if (s.get('fp_name') or '').startswith('/')}
    excluded=loaded-listed
    nonexistent=listed-loaded
    unexplained=excluded-unsupported
    assert not nonexistent,(case,nonexistent)
    assert not unexplained,(case,unexplained)
    (folder/'unsupported_objects.txt').write_text('XSim 2020.2 explicitly reports these objects as untraceable (automatic variables or dynamic types).\n'+'\n'.join(sorted(excluded))+'\n',encoding='utf-8-sig')
    report.append({'case':case,'loaded_objects':len(loaded),'listed_traceable_objects':len(listed),'explicitly_unsupported_objects':len(excluded),'unexplained_omissions':sorted(unexplained),'nonexistent_wcfg_objects':sorted(nonexistent)})
(OUT/'coverage_audit.json').write_text(json.dumps(report,indent=2),encoding='utf-8-sig')
print(json.dumps(report,indent=2))
