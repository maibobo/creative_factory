from pathlib import Path
import subprocess,json,hashlib,time,datetime,sys,os
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev');SRC=ROOT/'regression/recovery_phase2_20261011'
out_name='post_timing_quick_20261012'
only=None
if '--out-name' in sys.argv:out_name=sys.argv[sys.argv.index('--out-name')+1]
if '--only' in sys.argv:only=set(sys.argv[sys.argv.index('--only')+1].split(','))
OUT=ROOT/'verification_20261012'/out_name;OUT.mkdir(parents=True,exist_ok=True)
BIN=Path('C:/Xilinx/Vivado/2020.2/bin');STAGE=Path(__file__).parent
SEEDS=[1417633351,750318462,360207181]
CAPTURE={'ready_recovery','recovery_cross_variants','sync','1g','byte1_1g','backend_read','backend_write','ring'}
import shutil,re
sys.stdout.reconfigure(encoding='utf-8')
NOW=lambda:datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()
def tool(name,args,log,timeout=900):
    cmd=subprocess.list2cmdline([str(BIN/(name+'.bat')),*map(str,args)])
    with open(OUT/log,'w',encoding='utf-8') as f:
        p=subprocess.Popen(cmd,shell=True,cwd=OUT,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (OUT/'running_tool.json').write_text(json.dumps({'pid':p.pid,'tool':name,'args':list(map(str,args)),'log':log,'started':NOW()},ensure_ascii=False),encoding='utf-8')
        try:return p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True)
            f.write('\nWALLCLOCK_TIMEOUT\n');return -999
def record(obj):
    RESULTS.append(obj);(OUT/'summary.json').write_text(json.dumps(RESULTS,ensure_ascii=False,indent=2),encoding='utf-8')
RESULTS=[]
files=list((ROOT/'rtl').glob('*.v'))
new=ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new'
files += [new/x for x in ['INFO_EXCH.v','CONV_DMA.v','pcie_fdma_aurora_brg_adapter.v']]
files += [ROOT/'rtl/ddr4/rtds_ddr4_backend.sv',ROOT/'rtl/ddr4/rtds_axi_ram_model.sv',ROOT/'external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v']
files += list((ROOT/'regression/batch_1g').glob('*_test_if.sv'))
files += list((ROOT/'regression/new_cases_20261010').glob('*.sv'))
files += list((ROOT/'regression/batch_1g').glob('tb_*.sv'))
files += [SRC/'rtds_backend_test_if.sv',SRC/'backend_recovery_runner.sv',SRC/'tb_recovery_isolation.sv',SRC/'tb_writer_error_recovery.sv']
files += [SRC/'tb_recovery_cross_variants.sv',SRC/'tb_backend_edge_recovery.sv']
fast=ROOT/'regression/sim_xdma_trythrough'
files += [fast/x for x in ['rtds_test_pkg.sv','xdma_rp_backend.sv','aurora_ll_peer_bfm.sv','rtds_scoreboard.sv','rtds_assertions.sv','tb_xdma_rtds_trythrough.sv']]
files += [ROOT/'regression/board_cdc_smoke_20260921/tb_board_cdc_smoke.sv']
assert all(p.exists() for p in files)
# 修改记录 2026-10-12：从冻结源码副本编译全部快速用例，防止记录波形后源文件变化。
hashfiles=files+[SRC/'rtds_random.svh',fast/'rp_api.svh']
context=[ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new/TOP.v',ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new/PCIe.v',ROOT/'RTDS_test_DDR4_64bit.xpr',ROOT/'RTDS_test_DDR4_64bit.srcs/constrs_1/new/DDR4_PIN.xdc',ROOT/'rtl/aurora1g_board.xdc']
SNAP=OUT/'sources';SNAP.mkdir(exist_ok=True)
manifest=[]
for p in dict.fromkeys(hashfiles+context):
    q=SNAP/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
    manifest.append({'path':str(p.relative_to(ROOT)).replace('\\','/'),'sha256':hashlib.sha256(q.read_bytes()).hexdigest(),'compiled':p in hashfiles})
(OUT/'source_hashes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),'utf-8')
(OUT/'baseline.json').write_text(json.dumps({'root':str(ROOT),'captured':NOW(),'seeds':SEEDS,'mode':'RTL functional quick regression; DDR4_SIM_RAM','wave_seed':SEEDS[0],'excluded':['period_100ms production period','real MIG and DDR4 model','real Root Port'],'source_count':len(manifest)},ensure_ascii=False,indent=2),'utf-8')
files=[SNAP/p.relative_to(ROOT) for p in files]
SRC=SNAP/'regression/recovery_phase2_20261011';fast=SNAP/'regression/sim_xdma_trythrough'
rc=tool('xvlog',['-sv','-work','xpm',BIN/'../data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv',BIN/'../data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv'],'compile_xpm.log')
if rc:sys.exit(rc)
rc=tool('xvlog',['-work','work',BIN/'../data/verilog/src/glbl.v'],'compile_glbl.log')
if rc:sys.exit(rc)
rc=tool('xvlog',['-sv','-L','xpm','-d','DDR4_SIM_RAM','-i',SRC,'-i',fast,'-work','work',*files],'compile_tests.log')
if rc:sys.exit(rc)
cases=[
('ready_recovery','tb_ready_recovery',['TC-F11']),
('backend_read','tb_backend_read',['TC-F13']),
('backend_write','tb_backend_write',['TC-F14']),
('backend_edge_recovery','tb_backend_edge_recovery',['TC-F13','TC-F14']),
('writer_error_recovery','tb_writer_error_recovery',['TC-F14']),
('recovery_isolation','tb_recovery_isolation',['TC-F15']),
('recovery_cross_variants','tb_recovery_cross_variants',['TC-F15']),
('fast_base','tb_xdma_rtds_trythrough',['TC-F01','TC-F02','TC-F03','TC-F04','TC-F05','TC-F06','TC-F07','TC-F08']),
('axi','tb_rtds_axi',['TC-M03']),('axi_tail','tb_rtds_axi_tail',['TC-M04']),
('ring','tb_rtds_ring',['TC-M02']),('regs','tb_rtds_regs',['TC-M05']),
('rx_fifo','tb_rtds_rx_fifo',['TC-M06']),('tx','tb_rtds_tx',['TC-M07']),
('sync','tb_rtds_sync',['TC-M08']),('1g','tb_rtds_1g',['TC-M01']),
('byte1_1g','tb_byte1_1g',['TC-F09']),('tx_boundaries','tb_tx_boundaries',['TC-F10']),
('regs_multiblock','tb_regs_multiblock',['TC-F12']),('board_cdc','tb_board_cdc_smoke',[]),
]
for name,top,ids in cases:
    if only and name not in only:continue
    rc=tool('xelab',['-debug','all','-O0','-mt','off','-L','xpm','-L','unisims_ver','work.'+top,'work.glbl','-s',name],name+'.elaborate.log')
    if rc:
        record({'case':name,'ids':ids,'status':'ELABORATE_FAIL','exit_code':rc,'log':name+'.elaborate.log','date':NOW()});continue
    for seed in SEEDS:
        slug=name+'_seed_'+str(seed);tcl=OUT/(slug+'.tcl')
        if name in CAPTURE and seed==SEEDS[0]:
            capture=OUT/(slug+'.capture');capture.mkdir(exist_ok=True)
            scope='/'+top
            script='\n'.join(['set scope '+scope,'log_wave -r ${scope}/*','set objects [get_objects -r ${scope}/*]',
              'set fh [open {'+str(capture/'recorded_signals.txt').replace('\\','/')+'} w]',
              'foreach obj $objects {puts $fh $obj}','close $fh','create_wave_config',
              'foreach obj $objects {if {[regexp {(^/[^/]+/(clk|M_AXI_ACLK|fdma_clk|user_clk|src_clk|clk_250m|rst_n|frames|beat|tick_toggle_2us|cpu_sync_50us)$)|(/(bus|B)/[^/]+$)|(/H/[^/]+$)|(/U_ADAPTER/(tx_active|tx_recovering|tx_quiet_count|tx_user_quiet_fdma|tx_deliver_enable|link_up_fdma|tx_frame_done_fdma|tx_restart_pending)$)|(/U_DMA/(read_curr_st|M_AXI_RVALID|M_AXI_RREADY|M_AXI_RDATA)$)|(/U_DDR/(storage_ready|recovery_read_pending|recovery_read_abort|recovery_read_left|recovery_rvalid|recovery_rdata|recovery_rid|recovery_rresp|recovery_rlast|recovery_write_pending|recovery_write_abort|recovery_write_left|recovery_bvalid|recovery_bid|recovery_bresp)$)|(/U_DUT/(time_count|tick|state|half_valid|used_bytes|publish_seq)$)} $obj]} {catch {add_wave $obj}}}',
              'save_wave_config {'+str(capture/'recommended.wcfg').replace('\\','/')+'}',
              'open_vcd {'+str(capture/'trace.vcd').replace('\\','/')+'}','log_vcd $objects','run all','close_vcd','puts "CAPTURE_DONE='+slug+'"','quit',''])
            tcl.write_text(script,encoding='ascii')
        else:tcl.write_text('run all\nquit\n',encoding='ascii')
        started=NOW();wall=time.monotonic()
        options=OUT/(slug+'.options')
        options.write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch "'+str(tcl).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--log '+slug+'.simulate.log\n',encoding='ascii')
        rc=tool('xsim',[name,'-f',options],slug+'.console.log',timeout=1200 if name=='period_100ms' else 600)
        log=(OUT/(slug+'.simulate.log')).read_text('utf-8',errors='replace') if (OUT/(slug+'.simulate.log')).exists() else ''
        import re
        expected='RTDS_TRYTHROUGH_PASS' if name=='fast_base' else ('BOARD_CDC.*PASS|TEST PASS' if name=='board_cdc' else 'TEST PASS '+top)
        passed=rc==0 and bool(re.search(expected,log)) and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)|TEST FAIL|CHECK FAIL',log)
        draws=re.findall(r'RNG_(?:DRAW|SUMMARY).*',log)
        record({'case':name,'top':top,'ids':ids,'seed':seed,'status':'PASS' if passed else 'FUNCTIONAL_FAIL' if re.search(r'Fatal:|TEST FAIL|CHECK FAIL',log) else 'TOOL_FAIL','exit_code':rc,'started':started,'finished':NOW(),'wall_seconds':round(time.monotonic()-wall,2),'log':slug+'.simulate.log','random_samples':draws[:8],'random_summary':draws[-3:]})
        print(name,seed,'PASS' if passed else 'FAIL',flush=True)
(OUT/'completion.json').write_text(json.dumps({'completed':True,'finished':NOW(),'runs':len(RESULTS),'failures':sum(r['status']!='PASS' for r in RESULTS)},ensure_ascii=False,indent=2),encoding='utf-8')
print('QUICK_REGRESSION_COMPLETE',flush=True)
sys.exit(0)
