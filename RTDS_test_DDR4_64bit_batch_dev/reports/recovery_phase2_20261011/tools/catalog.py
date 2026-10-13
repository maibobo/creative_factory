from pathlib import Path
import json,re,hashlib
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');O=Path(__file__).parent
j=json.loads((R/'docs/RTDS_functional_20261011/content_and_evidence.json').read_text('utf-8'))
catalog=[]
for c in j['cases']:
    files=re.findall(r'\b[\w]+\.(?:sv|svh)\b',str(c[3]))
    catalog.append({'id':c[0],'name':c[1],'level':c[2],'files':list(dict.fromkeys(files))[:4],'result':c[7]})
(O/'case_catalog.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(catalog,ensure_ascii=False,indent=2))
history=[]
for p in sorted(Path('E:/codex_history_md/PCIE-CPU').glob('*.md')):
    text=p.read_text('utf-8-sig');lines=text.splitlines()
    hits=[]
    for i,line in enumerate(lines):
        if re.search(r'遗留|待补|待确认|待验证|尚未|未通过|未收敛|未验证|未重跑|失败|缺陷|Warning|UCIO|WNS|阻塞|错误',line,re.I):
            hits.append({'line':i+1,'text':line[:1000]})
    history.append({'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lines':len(lines),'findings':hits})
(O/'history_candidates.json').write_text(json.dumps(history,ensure_ascii=False,indent=2),encoding='utf-8')
print('history_read_files',len(history),'candidate_lines',sum(len(x['findings']) for x in history))
