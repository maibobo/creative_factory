from pathlib import Path
import subprocess,json,time,datetime,re,shutil
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');V=R/'verification_20261011';BASE=V/'random_regression';OUT=V/'random_period_retry';OUT.mkdir(exist_ok=True)
BIN=Path('D:/Xilinx_2020_2/Vivado/2020.2/bin');seed=750318462;slug='period_100ms_seed_'+str(seed)
shutil.copy2(BASE/'source_hashes.json',OUT/'source_hashes.json')
(OUT/(slug+'.tcl')).write_text('run all\nquit\n',encoding='ascii')
(OUT/(slug+'.options')).write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(OUT/(slug+'.tcl')).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--log "'+str(OUT/(slug+'.simulate.log')).replace('\\','/')+'"\n',encoding='ascii')
start=time.monotonic()
with (OUT/(slug+'.console.log')).open('w',encoding='utf-8') as f:
    cmd=subprocess.list2cmdline([str(BIN/'xsim.bat'),'period_100ms','-f',str(OUT/(slug+'.options'))])
    p=subprocess.Popen(cmd,shell=True,cwd=BASE,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    (OUT/'running_tool.json').write_text(json.dumps({'pid':p.pid,'tool':'xsim','seed':seed,'started':datetime.datetime.now().isoformat()}),encoding='utf-8')
    try:rc=p.wait(timeout=2400)
    except subprocess.TimeoutExpired:
        subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);rc=-999
log=(OUT/(slug+'.simulate.log')).read_text('utf-8',errors='replace') if (OUT/(slug+'.simulate.log')).exists() else ''
passed=rc==0 and 'TEST PASS tb_period_100ms' in log and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)',log)
result={'case':'period_100ms','ids':['TC-M09'],'seed':seed,'status':'PASS' if passed else 'FAIL','exit_code':rc,'log':slug+'.simulate.log','wall_seconds':round(time.monotonic()-start,2),'snapshot_directory':'random_regression','period_cycles':25000000,'clock_ns':4,'repeat_reason':'previous seed run had inconsistent process exit despite functional PASS marker'}
(OUT/'summary.json').write_text(json.dumps([result],ensure_ascii=False,indent=2),encoding='utf-8');print(json.dumps(result,ensure_ascii=False),flush=True)
