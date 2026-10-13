from pathlib import Path
import json,re,hashlib
from lexical_compare import tokens,normalized_tokens
R=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
S=R/'evidence/local_wave_sessions/recovery_and_1g_20261012_post_timing_staging'
OLD=R/'evidence/local_wave_sessions/recovery_and_1g_20261012'
manifest=json.loads((S/'manifest.json').read_text('utf-8'));allcomparisons=[]
for item in manifest:
    name=item['case'];folder=S/name;comp=item['comparison']
    for row in comp.get('core_source_comparison',[]):
        a=(OLD/name/'sources'/row['path']).read_text('utf-8-sig');b=(folder/'sources'/row['path']).read_text('utf-8-sig')
        row['same_noncomment_tokens']=tokens(a)==tokens(b)
        row['same_after_declaration_normalization']=normalized_tokens(a)==normalized_tokens(b)
        row['normalization']='Expand ordinary grouped wire/reg/logic declarations into equivalent individual declarations; otherwise compare exact lexical tokens'
    (folder/'previous_capture_comparison.json').write_text(json.dumps(comp,ensure_ascii=False,indent=2),'utf-8')
    allcomparisons.append(comp)
    p=folder/'viewer.html';text=p.read_text('utf-8');match=re.search(r'(<script[^>]+type="application/json"[^>]*>)(.*?)(</script>)',text,re.S)
    if not match:match=re.search(r'(<script[^>]+id="data"[^>]*>)(.*?)(</script>)',text,re.S)
    assert match,p
    data=json.loads(match[2]);unsupported=[]
    for sig in data['signals']:
        if sig.get('type') in ('real','realtime','string'):
            unsupported.append(sig['path']);sig['code']=None
    encoded=json.dumps(data,ensure_ascii=False,separators=(',',':')).replace('<','\\u003c').replace('\u2028','\\u2028').replace('\u2029','\\u2029')
    p.write_text(text[:match.start(2)]+encoded+text[match.end(2):],'utf-8')
    (folder/'unsupported_html_objects.list').write_text('\n'.join(unsupported)+'\n','utf-8')
    item['unsupported_html_objects']=unsupported;item['files']['viewer.html']=hashlib.sha256(p.read_bytes()).hexdigest()
    (folder/'capture_manifest.json').write_text(json.dumps(item,ensure_ascii=False,indent=2),'utf-8')
    guide=folder/'README.md';guide.write_text(guide.read_text('utf-8')+'\n显示边界：wcfg_signals.list是Vivado默认完整列表；wcfg_not_in_vcd.list列出未进入VCD的默认对象。unsupported_html_objects.list列出的real/string对象保留在清单，HTML明确显示无波形记录，值请在WDB查看，不解释成二进制0。源码对照将合并声明展开为等价单独声明后再检查，区分注释/排版/声明整理和行为变化。\n','utf-8')
(S/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
(S/'previous_package_comparison.json').write_text(json.dumps(allcomparisons,ensure_ascii=False,indent=2),'utf-8')
print('Metadata clarified; real objects explicitly unavailable in HTML; declaration normalization recorded')
