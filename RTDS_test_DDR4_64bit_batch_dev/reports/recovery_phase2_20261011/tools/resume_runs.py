from pathlib import Path
import subprocess,json,time,datetime,re,shutil,hashlib,ctypes,sys
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');V=R/'verification_20261011';O=V/'random_resume_20261012';O.mkdir(exist_ok=True)
BIN=Path('D:/Xilinx_2020_2/Vivado/2020.2/bin');SEEDS=[1417633351,750318462,360207181];RESULTS=[]
now=lambda:datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()
def save():(O/'summary.json').write_text(json.dumps(RESULTS,ensure_ascii=False,indent=2),encoding='utf-8')
def run_tool(name,args,base,slug,timeout=1200):
    cmd=subprocess.list2cmdline([str(BIN/(name+'.bat')),*map(str,args)])
    with (O/(slug+'.console.log')).open('w',encoding='utf-8') as f:
        p=subprocess.Popen(cmd,shell=True,cwd=base,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (O/'running_tool.json').write_text(json.dumps({'pid':p.pid,'tool':name,'args':list(map(str,args)),'cwd':str(base),'log':slug+'.console.log','started':now()}),encoding='utf-8')
        try:return p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);f.write('\nWALLCLOCK_TIMEOUT\n');return -999
def simulate(group,top,ids,base,seed,snapshot=None):
    slug=group+'_seed_'+str(seed);tcl=O/(slug+'.tcl');opts=O/(slug+'.options')
    tcl.write_text('run all\nquit\n',encoding='ascii')
    log=O/(slug+'.simulate.log')
    opts.write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(tcl).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--log "'+str(log).replace('\\','/')+'"\n',encoding='ascii')
    start=time.monotonic();started=now();rc=run_tool('xsim',[snapshot or group,'-f',opts],base,slug,timeout=2400 if group=='period_100ms' else 1200)
    text=log.read_text('utf-8',errors='replace') if log.exists() else ''
    marker='BOARD_CDC_SMOKE_PASS' if group=='board_cdc' else 'TEST PASS '+top
    passed=rc==0 and marker in text and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)|TEST FAIL|CHECK FAIL',text)
    row={'case':group,'top':top,'ids':ids,'seed':seed,'status':'PASS' if passed else 'FAIL','exit_code':rc,'log':log.name,'started':started,'finished':now(),'wall_seconds':round(time.monotonic()-start,2),'snapshot_directory':str(base.relative_to(V)),'source_hashes':group+'.source_hashes.json','random_summary':re.findall(r'(?m)^RNG_SUMMARY.*',text),'markers':re.findall(r'(?m)^.*(?:TEST PASS|Fatal:|Error:|ERROR:).*$',text)[-8:]}
    RESULTS.append(row);save();print(group,seed,row['status'],'exit',rc,flush=True)
def preserve(group,base,seed):
    rows=json.loads((base/'summary.json').read_text('utf-8'))
    row=next((r for r in rows if r.get('case')==group and r.get('seed')==seed and r.get('status')=='PASS'),None)
    if not row:return False
    row=dict(row);dest=O/row['log'];shutil.copy2(base/row['log'],dest)
    row['preserved_pass_from']=str(base.relative_to(V));row['snapshot_directory']=str(base.relative_to(V));row['source_hashes']=group+'.source_hashes.json'
    RESULTS.append(row);save();return True
ctypes.windll.kernel32.SetThreadExecutionState(0x80000001)
try:
    backend=V/'random_backend_final'
    for group,top,ids in [('backend_read','tb_backend_read',['TC-F13']),('backend_write','tb_backend_write',['TC-F14']),('backend_edge_recovery','tb_backend_edge_recovery',['TC-F13','TC-F14'])]:
        shutil.copy2(backend/'source_hashes.json',O/(group+'.source_hashes.json'))
        if group!='backend_read':
            rc=run_tool('xelab',['-debug','typical','-O3','-mt','off','-L','xpm','-L','unisims_ver','work.'+top,'work.glbl','-s',group],backend,group+'.elaborate',timeout=1200)
            if rc:RESULTS.append({'case':group,'ids':ids,'status':'ELABORATE_FAIL','exit_code':rc,'log':group+'.elaborate.console.log','finished':now()});save();continue
        for seed in SEEDS:
            if not preserve(group,backend,seed):simulate(group,top,ids,backend,seed)
    final=V/'random_final';group='board_cdc'
    shutil.copy2(final/'source_hashes.json',O/(group+'.source_hashes.json'))
    for seed in SEEDS:
        if not preserve(group,final,seed):simulate(group,'tb_board_cdc_smoke',[],final,seed)
    mig=V/'real_mig_recovery';group='real_mig'
    shutil.copy2(mig/'source_hashes.json',O/(group+'.source_hashes.json'))
    for seed in SEEDS:
        data=json.loads((mig/'summary.json').read_text('utf-8'));row=next((x for x in data.get('runs',[]) if x['seed']==seed and x['status']=='PASS'),None)
        if row:
            shutil.copy2(mig/row['log'],O/row['log']);row=dict(row,case=group,ids=['TC-F16'],snapshot_directory='real_mig_recovery',source_hashes=group+'.source_hashes.json',preserved_pass_from='real_mig_recovery');RESULTS.append(row);save()
        else:simulate(group,'tb_real_mig_recovery',['TC-F16'],mig,seed)
    if '--quick-code' not in sys.argv:
        base=V/'random_regression';group='period_100ms'
        shutil.copy2(base/'source_hashes.json',O/(group+'.source_hashes.json'))
        for seed in SEEDS:
            if not preserve(group,base,seed):simulate(group,'tb_period_100ms',['TC-M09'],base,seed)
    (O/'completion.json').write_text(json.dumps({'completed':True,'finished':now(),'runs':len(RESULTS),'failures':sum(r['status']!='PASS' for r in RESULTS)}),encoding='utf-8')
finally:ctypes.windll.kernel32.SetThreadExecutionState(0x80000000)
