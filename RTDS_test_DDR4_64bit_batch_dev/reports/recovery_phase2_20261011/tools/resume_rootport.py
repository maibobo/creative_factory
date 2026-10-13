from pathlib import Path
import subprocess,json,time,datetime,re,hashlib,ctypes
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');V=R/'verification_20261011';BASE=V/'rootport_current_o0';O=V/'rootport_resume_20261012';O.mkdir(exist_ok=True)
B=Path('D:/Xilinx_2020_2/Vivado/2020.2/bin');seeds=[1417633351,750318462,360207181]
summary={'current_sources':True,'backend':'DDR4_SIM_RAM','real_xdma_root_port':True,'snapshot_directory':'rootport_current_o0','period_cycles':25000,'runs':[]}
def save():(O/'summary_current.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2),encoding='utf-8')
def tool(name,args,log,timeout=1200):
    with (O/log).open('w',encoding='utf-8') as f:
        p=subprocess.Popen(subprocess.list2cmdline([str(B/(name+'.bat')),*map(str,args)]),shell=True,cwd=BASE,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (O/'running_tool.json').write_text(json.dumps({'pid':p.pid,'tool':name,'args':list(map(str,args)),'log':log,'start':datetime.datetime.now().isoformat()}),encoding='utf-8')
        try:return p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);f.write('\nWALLCLOCK_TIMEOUT\n');return -999
paths=[]
for p in ['vlog.prj','vhdl.prj']:
    for q in re.findall(r'"([^"]+)"',(BASE/p).read_text('utf-8')):
        path=Path(q)
        if path.is_file():paths.append(path)
(O/'source_hashes.json').write_text(json.dumps([{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in dict.fromkeys(paths)],ensure_ascii=False,indent=2),encoding='utf-8')
ctypes.windll.kernel32.SetThreadExecutionState(0x80000001)
try:
    rc=tool('xvlog',['--relax','-L','xdma_v4_1_8','-i',B/'../data/xilinx_vip/include','-i',R/'regression/sim_xdma_rootport/tb','-i',R/'regression/sim_xdma_rootport/vendor/xdma_rp_2020_2','-d','DDR4_SIM_RAM','-d','XILINX_SIMULATOR','-prj','vlog.prj'],'compile_vlog.log')
    if rc:summary.update(status='COMPILE_FAIL',exit_code=rc);save();raise SystemExit(1)
    rc=tool('xvhdl',['--relax','-prj','vhdl.prj'],'compile_vhdl.log')
    if rc:summary.update(status='COMPILE_FAIL',exit_code=rc);save();raise SystemExit(1)
    opts=(R/'regression/sim_xdma_rootport/work/export/xsim/elab.opt').read_text('utf-8').strip().split()
    for k,x in enumerate(opts):
        if x=='--mt':opts[k+1]='off'
        if x=='--snapshot':opts[k+1]='board_phase2'
        if x=='-log':opts[k+1]=str(O/'elaborate.log')
    opts+=['-O0']
    rc=tool('xelab',opts,'elaborate.console.log',timeout=7200)
    if rc:summary.update(status='ELABORATE_FAIL',exit_code=rc);save();raise SystemExit(1)
    (O/'run.tcl').write_text('run all\nquit\n',encoding='ascii')
    for seed in seeds:
        slug='rootport_seed_'+str(seed);start=time.monotonic();log=O/(slug+'.simulate.log')
        (O/(slug+'.options')).write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(O/'run.tcl').replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--log "'+str(log).replace('\\','/')+'"\n',encoding='ascii')
        rc=tool('xsim',['board_phase2','-f',O/(slug+'.options')],slug+'.console.log',timeout=1800)
        text=log.read_text('utf-8',errors='replace') if log.exists() else ''
        markers=re.findall(r'RTDS_\w+(?:PASS|RESULT)[^\n]*',text)
        passed=rc==0 and bool(re.search(r'(?m)^RTDS_ROOTPORT_PASS\s*$',text)) and bool(re.search(r'RTDS_ROOTPORT_RESULT[^\n]*errors=0',text)) and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)',text)
        summary['runs'].append({'seed':seed,'status':'PASS' if passed else 'FAIL','exit_code':rc,'log':log.name,'wall_seconds':round(time.monotonic()-start,2),'finished':datetime.datetime.now().isoformat(),'markers':markers});save();print(slug,'PASS' if passed else 'FAIL',flush=True)
    summary['status']='PASS' if all(x['status']=='PASS' for x in summary['runs']) else 'FAIL';save()
finally:ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)
