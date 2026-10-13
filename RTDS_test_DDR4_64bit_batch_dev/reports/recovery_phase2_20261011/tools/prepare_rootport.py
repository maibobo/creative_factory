from pathlib import Path
import re,json,hashlib,shutil
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');S=R/'regression/sim_xdma_rootport';OLD=S/'work/export/xsim'
OUT=R/'verification_20261011/rootport_current';OUT.mkdir(parents=True,exist_ok=True)
files=[*list((R/'RTDS_test_DDR4_64bit.srcs').rglob('*')),*list((R/'external_snapshot').rglob('*'))]
index={}
for p in files:
    if p.is_file():index.setdefault(p.name,[]).append(p)
missing=[];mapped=[]
def fix(m):
    original=m.group(1)
    v=re.sub(re.escape('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev'),lambda m:str(R).replace('\\','/'),original,flags=re.I)
    v=re.sub(re.escape('C:/Xilinx/Vivado/2020.2'),'D:/Xilinx_2020_2/Vivado/2020.2',v,flags=re.I)
    if not re.match(r'^[A-Za-z]:',v):v=str(OLD/v).replace('\\','/')
    p=Path(v)
    if not p.exists() and p.suffix in ['.v','.sv','.vhd','.vhdl']:
        hits=index.get(p.name,[])
        if len(hits)==1:v=str(hits[0]).replace('\\','/');p=hits[0]
        else:missing.append({'original':original,'mapped':v,'candidates':[str(h) for h in hits]})
    if p.is_file():mapped.append({'path':v,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
    return '"'+v+'"'
for name in ['vlog.prj','vhdl.prj']:
    s=(OLD/name).read_text('utf-8-sig')
    s=re.sub(r'"([^"]+)"',fix,s)
    (OUT/name).write_text(s,encoding='utf-8')
shutil.copy2(OLD/'xsim.ini',OUT/'xsim.ini')
(OUT/'source_paths.json').write_text(json.dumps({'missing':missing,'mapped':mapped},ensure_ascii=False,indent=2),encoding='utf-8')
print('mapped',len(mapped),'missing',len(missing))
print(json.dumps(missing[:5],ensure_ascii=False,indent=2))
# Preserve the pre-fix testing model exactly by reversing the only declaration-order edit.
model=R/'regression/sim_xdma_trythrough/xdma_rp_backend.sv';b=R/'backups/recovery_phase2_20261011'/model.relative_to(R)
if not b.exists():
    raw=model.read_bytes();newline=b'\r\n' if b'\r\n' in raw else b'\n'
    lines=raw.splitlines(keepends=True)
    lines=[l for l in lines if b'2026-10-11' not in l]
    old=b''.join(lines).replace(b'    reg [31:0] wr_word_index;'+newline,b'    reg [31:0] wr_word_index;'+newline+b'    reg [15:0] wr_words_left;'+newline)
    b.parent.mkdir(parents=True,exist_ok=True);b.write_bytes(old)
