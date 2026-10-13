from pathlib import Path
import subprocess,json,re,datetime,sys
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
R=ROOT/'verification_20261012/post_timing_quick_20261012'
name='backend_edge_recovery';seed=1417633351;slug=name+'_seed_'+str(seed)
C=R/(slug+'.capture');C.mkdir(exist_ok=True)
S=R/(slug+'.diagnostic.tcl')
S.write_text('\n'.join(['set scope /tb_backend_edge_recovery','log_wave -r ${scope}/*','set objs [get_objects -r ${scope}/*]',
'set f [open {'+str(C/'recorded_signals.txt').replace('\\','/')+'} w]','foreach obj $objs {puts $f $obj}','close $f','create_wave_config',
'foreach obj $objs {if {[regexp {(^/tb_backend_edge_recovery/clk$)|(^/tb_backend_edge_recovery/B/[^/]+$)|(/U_DDR/(storage_ready|sim_ready_pipe|recovery_read_pending|recovery_read_abort|recovery_read_left|recovery_rload|recovery_rvalid|recovery_rdata|recovery_rresp|recovery_rlast|recovery_write_abort|recovery_write_left|mem_wvalid)$)} $obj]} {catch {add_wave $obj}}}',
'save_wave_config {'+str(C/'recommended.wcfg').replace('\\','/')+'}','open_vcd {'+str(C/'trace.vcd').replace('\\','/')+'}','log_vcd $objs','run all','close_vcd','quit','']),encoding='ascii')
O=R/(slug+'.diagnostic.options')
O.write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(S).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--wdb '+slug+'.wdb\n--log '+slug+'.diagnostic.simulate.log\n','ascii')
with (R/(slug+'.diagnostic.console.log')).open('w',encoding='utf-8') as f:
    rc=subprocess.run(subprocess.list2cmdline(['C:/Xilinx/Vivado/2020.2/bin/xsim.bat',name,'-f',str(O)]),shell=True,cwd=R,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=300).returncode
log=(R/(slug+'.diagnostic.simulate.log')).read_text('utf-8',errors='replace')
assert 'Fatal: EDGE/R' in log and (C/'trace.vcd').stat().st_size>0
(R/'failed_edge_capture.json').write_text(json.dumps({'case':name,'seed':seed,'exit_code':rc,'status':'EXPECTED_REPRODUCTION_OF_UNCLOSED_FAILURE','failure_lines':[l for l in log.splitlines() if 'Fatal:' in l or l.startswith('Time:')],'captured':datetime.datetime.now().isoformat()},indent=2),'utf-8')
print('UNCLOSED_EDGE_FAILURE_CAPTURED')
