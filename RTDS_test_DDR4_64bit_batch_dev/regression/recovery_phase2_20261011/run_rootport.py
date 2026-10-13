from pathlib import Path
import subprocess,json,time,datetime,re,shutil,hashlib,sys
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');O=R/'verification_20261011/rootport_current'
B=Path('D:/Xilinx_2020_2/Vivado/2020.2/bin');S=Path(__file__).parent
if '--out-name' in sys.argv:
    base=O;O=R/'verification_20261011'/sys.argv[sys.argv.index('--out-name')+1];O.mkdir(parents=True,exist_ok=True)
    for name in ['vlog.prj','vhdl.prj','xsim.ini','source_paths.json']:shutil.copy2(base/name,O/name)
seeds=json.loads((S/'seeds.json').read_text('utf-8'))['seeds']
p=R/'regression/sim_xdma_rootport/tb/rtds_rootport_pkg.sv';backup=R/'backups/recovery_phase2_20261011'/p.relative_to(R)
if not backup.exists():
    backup.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,backup)
    src=p.read_text('utf-8').replace('        pattern_byte = seed + (index * 8\'d37) + (index >> 3);', '''        integer command_seed;   // 2026-10-11：真实RootPort回归种子从命令行取得
        logic[31:0] mix;   // 2026-10-11：不同种子产生不同实际DMA字节
        if(!$value$plusargs("SEED=%d",command_seed)) command_seed=20261011;   // 2026-10-11：记录的默认种子可复现
        mix=32'(command_seed)^(32'(index)*32'h9e3779b9);   // 2026-10-11：按字节序号混合种子
        mix=mix^(mix<<13);mix=mix^(mix>>17);mix=mix^(mix<<5);   // 2026-10-11：独立xorshift32数据变换
        pattern_byte = seed + (index * 8'd37) + (index >> 3) + mix[7:0];   // 2026-10-11：实际载荷与参考数据共同使用随机字节''')
    p.write_bytes(src.replace('\n','\r\n').encode('utf-8'))
def tool(name,args,log,timeout=1800):
    with (O/log).open('w',encoding='utf-8') as f:
        cmd=subprocess.list2cmdline([str(B/(name+'.bat')),*map(str,args)])
        q=subprocess.Popen(cmd,shell=True,cwd=O,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (O/'running_tool.json').write_text(json.dumps({'pid':q.pid,'name':name,'log':log,'start':datetime.datetime.now().isoformat()}),encoding='utf-8')
        try:return q.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(q.pid),'/T','/F'],capture_output=True);f.write('\nWALLCLOCK_TIMEOUT\n');return -999
summary={'current_sources':True,'backend':'DDR4_SIM_RAM','real_xdma_root_port':True,'runs':[]}
def save():(O/'summary_current.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
missing=json.loads((O/'source_paths.json').read_text('utf-8'))['missing']
if missing:summary['status']='SOURCE_MISSING';save();sys.exit(1)
rc=tool('xvlog',['--relax','-L','xdma_v4_1_8','-i',B/'../data/xilinx_vip/include','-i',R/'regression/sim_xdma_rootport/tb','-i',R/'regression/sim_xdma_rootport/vendor/xdma_rp_2020_2','-d','DDR4_SIM_RAM','-d','XILINX_SIMULATOR','-prj','vlog.prj'],'compile_vlog.log')
if rc:summary.update(status='COMPILE_FAIL',exit_code=rc);save();sys.exit(1)
rc=tool('xvhdl',['--relax','-prj','vhdl.prj'],'compile_vhdl.log')
if rc:summary.update(status='COMPILE_FAIL',exit_code=rc);save();sys.exit(1)
opts=(R/'regression/sim_xdma_rootport/work/export/xsim/elab.opt').read_text('utf-8').strip().split()
opts=[('-O3' if x=='--mt' else x) for x in opts] if False else opts
for k,x in enumerate(opts):
    if x=='--mt':opts[k+1]='off'
if '--optimize' in sys.argv:opts+=['-O'+sys.argv[sys.argv.index('--optimize')+1]]
rc=tool('xelab',opts,'elaborate.console.log',timeout=3600)
if rc:summary.update(status='ELABORATE_FAIL',exit_code=rc);save();sys.exit(1)
(O/'run_seed.tcl').write_text('run all\nquit\n',encoding='ascii')
for seed in seeds:
    slug='rootport_seed_'+str(seed);start=time.monotonic()
    (O/(slug+'.options')).write_text('--testplusarg "SEED='+str(seed)+'"\n--tclbatch run_seed.tcl\n--onerror quit\n--onfinish stop\n--log '+slug+'.simulate.log\n',encoding='ascii')
    rc=tool('xsim',['board','-f',slug+'.options'],slug+'.console.log',timeout=1800)
    log=(O/(slug+'.simulate.log')).read_text('utf-8',errors='replace') if (O/(slug+'.simulate.log')).exists() else ''
    markers=re.findall(r'RTDS_\w+(?:PASS|RESULT)[^\n]*',log)
    passed=rc==0 and bool(re.search(r'(?m)^RTDS_ROOTPORT_PASS\s*$',log)) and bool(re.search(r'RTDS_ROOTPORT_RESULT[^\n]*errors=0',log)) and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)',log)
    summary['runs'].append({'seed':seed,'status':'PASS' if passed else 'FAIL','exit_code':rc,'log':slug+'.simulate.log','wall_seconds':round(time.monotonic()-start,2),'markers':markers})
    save();print(slug,'PASS' if passed else 'FAIL',flush=True)
summary['status']='PASS' if all(x['status']=='PASS' for x in summary['runs']) else 'FAIL';save()
