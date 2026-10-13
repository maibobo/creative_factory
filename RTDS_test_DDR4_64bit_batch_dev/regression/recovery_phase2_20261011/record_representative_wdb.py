from pathlib import Path
import subprocess,json,re,time,datetime,sys
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
R=ROOT/'verification_20261012/post_timing_quick_20261012'
names=['ready_recovery','recovery_cross_variants','sync','1g','byte1_1g','backend_read','backend_write','ring']
seed=1417633351;results=[]
for name in names:
    slug=name+'_seed_'+str(seed);script=R/(slug+'.tcl')
    assert script.exists() and 'log_wave' in script.read_text('ascii')
    opts=R/(slug+'.record.options')
    opts.write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(script).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--wdb '+slug+'.wdb\n--log '+slug+'.record.simulate.log\n','ascii')
    start=time.monotonic()
    with (R/(slug+'.record.console.log')).open('w',encoding='utf-8') as f:
        rc=subprocess.run(subprocess.list2cmdline(['C:/Xilinx/Vivado/2020.2/bin/xsim.bat',name,'-f',str(opts)]),shell=True,cwd=R,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=600).returncode
    log=(R/(slug+'.record.simulate.log')).read_text('utf-8',errors='replace')
    ok=rc==0 and 'TEST PASS' in log and not re.search('Fatal:|TEST FAIL|CHECK FAIL',log)
    results.append({'case':name,'seed':seed,'status':'PASS' if ok else 'FAIL','exit_code':rc,'wall_seconds':round(time.monotonic()-start,2),'log':slug+'.record.simulate.log','purpose':'Explicit per-seed WDB recording; rerun from same frozen compiled snapshot'})
    (R/'representative_recording_summary.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),'utf-8')
    print(name,'RECORDED' if ok else 'RECORD_FAILED',flush=True)
assert all(r['status']=='PASS' for r in results)
print('REPRESENTATIVE_WDB_RECORDING_COMPLETE')
