from pathlib import Path
import json,hashlib,sys
root=Path(r"C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev")
paths=set((root/'rtl').rglob('*.v'))|set((root/'rtl').rglob('*.sv'))|set((root/'rtl').rglob('*.xdc'))
paths|=set((root/'RTDS_test_DDR4_64bit.srcs/sources_1/new').rglob('*.v'))|set((root/'RTDS_test_DDR4_64bit.srcs/sources_1/new').rglob('*.sv'))
old=json.loads((root/'verification_20261012/post_timing_quick_20261012/source_hashes.json').read_text('utf-8'))
paths|={root/x['path'] for x in old if not x['path'].startswith('regression/')}
obj={p.relative_to(root).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(paths) if p.is_file()}
out=root/'verification_20261012/edge_criteria_closure_20261012'
out.mkdir(exist_ok=True)
if sys.argv[1]=='before':
 (out/'rtl_before.json').write_text(json.dumps(obj,indent=2),'utf-8')
 print('RTL_BASELINE_FILES='+str(len(obj)))
else:
 before=json.loads((out/'rtl_before.json').read_text('utf-8'))
 changes=[p for p in sorted(set(obj)|set(before)) if obj.get(p)!=before.get(p)]
 result={'files':len(obj),'rtl_and_constraints_unchanged':not changes,'changed_paths':changes}
 (out/'rtl_unchanged_audit.json').write_text(json.dumps(result,indent=2),'utf-8')
 print(json.dumps(result))
 if changes:raise SystemExit(2)
