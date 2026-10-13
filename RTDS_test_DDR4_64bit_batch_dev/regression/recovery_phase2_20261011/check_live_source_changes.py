from pathlib import Path
import json,hashlib,difflib,datetime
from lexical_compare import tokens,normalized_tokens
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
OUT=ROOT/'evidence/local_wave_sessions/recovery_and_1g_20261012'
R=ROOT/'verification_20261012/post_timing_quick_20261012/sources'
rows=[]
for row in json.loads((OUT/'source_hashes.json').read_text('utf-8')):
    now=ROOT/row['path'];old=R/row['path']
    h=hashlib.sha256(now.read_bytes()).hexdigest()
    if h==row['sha256']:continue
    a=old.read_text('utf-8-sig');b=now.read_text('utf-8-sig')
    same=normalized_tokens(a)==normalized_tokens(b)
    result={'path':row['path'],'compiled':row['compiled'],'recorded_sha256':row['sha256'],'latest_sha256':h,'same_lexical_tokens_without_comments':tokens(a)==tokens(b),'same_after_equivalent_declaration_normalization':same}
    if not same:result['first_token_difference']=list(difflib.unified_diff(normalized_tokens(a),normalized_tokens(b),n=5))[:70]
    rows.append(result)
result={'checked':datetime.datetime.now().isoformat(),'changed_files':rows,'all_changed_files_functional_tokens_equivalent':all(r['same_after_equivalent_declaration_normalization'] for r in rows),'note':'No live source was overwritten; compiled snapshots retained. Normalization expands ordinary wire/reg/logic/localparam grouped declarations without changing widths, names or initializer tokens.'}
(OUT/'live_source_changes_during_regression.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),'utf-8')
print(json.dumps(result,ensure_ascii=False))
