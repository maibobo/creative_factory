from pathlib import Path
import subprocess,json,re,time,sys
root=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
seed=1417633351;name='backend_edge_recovery';records=[]
for suffix,phase in [('',0),('_early',-1),('_late',1)]:
 run=root/('verification_20261012/edge_criteria_closure_20261012'+suffix)
 slug=name+'_seed_'+str(seed);script=run/(slug+'.tcl');opts=run/(slug+'.record.options')
 opts.write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--testplusarg "EDGE_PHASE='+str(phase)+'"\n--tclbatch "'+script.as_posix()+'"\n--onerror quit\n--onfinish stop\n--wdb '+slug+'.wdb\n--log '+slug+'.record.simulate.log\n','ascii')
 with (run/(slug+'.record.console.log')).open('w',encoding='utf-8') as f:
  rc=subprocess.run(subprocess.list2cmdline(['C:/Xilinx/Vivado/2020.2/bin/xsim.bat',name,'-f',str(opts)]),shell=True,cwd=run,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=300).returncode
 log=(run/(slug+'.record.simulate.log')).read_text('utf-8',errors='replace')
 assert rc==0 and 'TEST PASS tb_backend_edge_recovery' in log and not re.search('Fatal:|TEST FAIL|CHECK FAIL',log)
 assert (run/(slug+'.wdb')).stat().st_size>0
 records.append({'case':name,'seed':seed,'phase':phase,'status':'PASS','purpose':'Representative waveform recording, excluded from 27 functional runs','log':str(run/(slug+'.record.simulate.log'))})
 print('RECORDED_PHASE='+str(phase),flush=True)
(root/'verification_20261012/edge_criteria_closure_20261012/representative_recording_summary.json').write_text(json.dumps(records,indent=2),'utf-8')
