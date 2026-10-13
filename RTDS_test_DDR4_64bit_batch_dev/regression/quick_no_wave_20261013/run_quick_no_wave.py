"""2026-10-13: current-source quick regression, one seed, no waveform recording."""
from pathlib import Path
import subprocess,json,hashlib,time,datetime,sys,shutil,re,traceback
sys.stdout.reconfigure(encoding='utf-8')
ROOT=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev')
BIN=Path('C:/Xilinx/Vivado/2020.2/bin')
OUT=ROOT/'verification_20261013/quick_no_wave_20261013'
if (OUT/'baseline.json').exists():raise RuntimeError('Refusing to overwrite existing regression')
OUT.mkdir(parents=True,exist_ok=True)
NOW=lambda:datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat()
SEED=1417633351
RESULTS=[]
CASES=[
('vio_stim_handshake','tb_vio_stim_handshake',[],None),
('rx_vio_smoke','tb_rx_vio_smoke',[],None),
('vio_disabled_smoke','tb_vio_disabled_smoke',[],None),
('ready_recovery','tb_ready_recovery',['TC-F11'],None),
('backend_read','tb_backend_read',['TC-F13'],None),
('backend_write','tb_backend_write',['TC-F14'],None),
('backend_edge_early','tb_backend_edge_recovery',['TC-F13','TC-F14'],-1),
('backend_edge_same','tb_backend_edge_recovery',['TC-F13','TC-F14'],0),
('backend_edge_late','tb_backend_edge_recovery',['TC-F13','TC-F14'],1),
('writer_error_recovery','tb_writer_error_recovery',['TC-F14'],None),
('recovery_isolation','tb_recovery_isolation',['TC-F15'],None),
('recovery_cross_variants','tb_recovery_cross_variants',['TC-F15'],None),
('fast_base','tb_xdma_rtds_trythrough',['TC-F01','TC-F02','TC-F03','TC-F04','TC-F05','TC-F06','TC-F07','TC-F08'],None),
('axi','tb_rtds_axi',['TC-M03'],None),('axi_tail','tb_rtds_axi_tail',['TC-M04'],None),
('ring','tb_rtds_ring',['TC-M02'],None),('regs','tb_rtds_regs',['TC-M05'],None),
('rx_fifo','tb_rtds_rx_fifo',['TC-M06'],None),('tx','tb_rtds_tx',['TC-M07'],None),
('sync','tb_rtds_sync',['TC-M08'],None),('1g','tb_rtds_1g',['TC-M01'],None),
('byte1_1g','tb_byte1_1g',['TC-F09'],None),('tx_boundaries','tb_tx_boundaries',['TC-F10'],None),
('regs_multiblock','tb_regs_multiblock',['TC-F12'],None),('board_cdc','tb_board_cdc_smoke',[],None),
('ddr4_backend_smoke','tb_rtds_ddr4_backend_smoke',[],None)]

def tool(name,args,log,timeout=600):
    started=NOW();cmd=subprocess.list2cmdline([str(BIN/(name+'.bat')),*map(str,args)])
    with (OUT/log).open('w',encoding='utf-8') as f:
        p=subprocess.Popen(cmd,shell=True,cwd=OUT,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (OUT/'progress.json').write_text(json.dumps({'stage':name,'pid':p.pid,'log':log,'started':started,'completed':len(RESULTS),'planned':len(CASES)},indent=2),encoding='utf-8')
        try:return p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True)
            f.write('\nWALLCLOCK_TIMEOUT\n');return -999

def record(obj):
    RESULTS.append(obj)
    (OUT/'summary.json').write_text(json.dumps(RESULTS,ensure_ascii=False,indent=2),encoding='utf-8')
    print(obj['case'],obj['status'],'completed',len(RESULTS),'/',len(CASES),flush=True)

def main():
    phase=ROOT/'regression/recovery_phase2_20261011';fast=ROOT/'regression/sim_xdma_trythrough'
    files=sorted((ROOT/'rtl').glob('*.v'))
    files += [ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new'/n for n in ['INFO_EXCH.v','CONV_DMA.v','pcie_fdma_aurora_brg_adapter.v']]
    files += [ROOT/'rtl/ddr4/rtds_ddr4_backend.sv',ROOT/'rtl/ddr4/rtds_axi_ram_model.sv',ROOT/'external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v']
    files += sorted((ROOT/'regression/batch_1g').glob('*_test_if.sv'))
    files += sorted((ROOT/'regression/new_cases_20261010').glob('*.sv'))
    files += sorted((ROOT/'regression/batch_1g').glob('tb_*.sv'))
    files += [phase/n for n in ['rtds_backend_test_if.sv','backend_recovery_runner.sv','tb_recovery_isolation.sv','tb_writer_error_recovery.sv','tb_recovery_cross_variants.sv','tb_backend_edge_recovery.sv']]
    files += [fast/n for n in ['rtds_test_pkg.sv','xdma_rp_backend.sv','aurora_ll_peer_bfm.sv','rtds_scoreboard.sv','rtds_assertions.sv','tb_xdma_rtds_trythrough.sv']]
    files += [ROOT/'regression/board_cdc_smoke_20260921/tb_board_cdc_smoke.sv']
    files += sorted((ROOT/'regression/vio_smoke_20261013').glob('*.sv'))
    files += [ROOT/'sim/ddr4_backend/tb_rtds_ddr4_backend_smoke.sv']
    files=list(dict.fromkeys(files));assert all(p.exists() for p in files)
    context=[ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new/TOP.v',ROOT/'RTDS_test_DDR4_64bit.srcs/sources_1/new/PCIe.v',ROOT/'RTDS_test_DDR4_64bit.xpr',ROOT/'RTDS_test_DDR4_64bit.srcs/constrs_1/new/DDR4_PIN.xdc']
    manifest=[];snap=OUT/'sources'
    for p in dict.fromkeys(files+[phase/'rtds_random.svh',fast/'rp_api.svh']+context):
        q=snap/p.relative_to(ROOT);q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q)
        if p in files:assert not re.search(r'\$(dumpfile|dumpvars)\s*\(',q.read_text(encoding='utf-8',errors='replace')),str(p)
        manifest.append({'path':p.relative_to(ROOT).as_posix(),'sha256':hashlib.sha256(q.read_bytes()).hexdigest(),'compiled':p in files})
    (OUT/'source_hashes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (OUT/'baseline.json').write_text(json.dumps({'started':NOW(),'root':str(ROOT),'seed':SEED,'wave_recording':False,'unique_testbenches':len(set(c[1] for c in CASES)),'planned_runs':len(CASES),'cases':CASES,'excluded':['production 100ms long run TC-M09','real MIG/DDR model TC-F16','real Root Port TC-R01'],'model':'RTL functional; DDR4_SIM_RAM; behavioral host/peer; VIO start modeled; no synthesis/implementation/board operation','sources':len(manifest)},ensure_ascii=False,indent=2),encoding='utf-8')
    rc=tool('xvlog',['-sv','-work','xpm',BIN/'../data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv',BIN/'../data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv'],'compile_xpm.log')
    if rc:raise RuntimeError('XPM compile failed '+str(rc))
    rc=tool('xvlog',['-work','work',BIN/'../data/verilog/src/glbl.v'],'compile_glbl.log')
    if rc:raise RuntimeError('glbl compile failed '+str(rc))
    rc=tool('xvlog',['-sv','-L','xpm','-d','DDR4_SIM_RAM','-i',snap/'regression/recovery_phase2_20261011','-i',snap/'regression/sim_xdma_trythrough','-work','work',*[Path('sources')/p.relative_to(ROOT) for p in files]],'compile_tests.log')
    if rc:raise RuntimeError('Test compile failed '+str(rc))
    elaborated={}
    for name,top,ids,edge_phase in CASES:
        if top not in elaborated:
            snapshot='q_'+top
            rc=tool('xelab',['-debug','all','-O0','-mt','off','-L','xpm','-L','unisims_ver','work.'+top,'work.glbl','-s',snapshot],top+'.elaborate.log')
            elaborated[top]=(snapshot,rc)
        snapshot,rc=elaborated[top]
        if rc:
            record({'case':name,'top':top,'ids':ids,'status':'ELABORATE_FAIL','exit_code':rc,'log':top+'.elaborate.log','finished':NOW()});continue
        # No log_wave/log_vcd or signal enumeration. Close the automatic empty WDB before execution.
        tcl=OUT/(name+'.tcl');tcl.write_text('if {[llength [info commands close_wave_database]] != 0} {close_wave_database}\nrun all\nquit\n',encoding='ascii')
        args=['--sv_seed',str(SEED),'--testplusarg','SEED='+str(SEED),'--tclbatch',str(tcl),'--onerror','quit','--onfinish','stop','--log',name+'.simulate.log']
        if edge_phase is not None:args+=['--testplusarg','EDGE_PHASE='+str(edge_phase)]
        options=OUT/(name+'.options');options.write_text(subprocess.list2cmdline(args),encoding='ascii')
        started=NOW();wall=time.monotonic();rc=tool('xsim',[snapshot,'-f',options],name+'.console.log')
        log=(OUT/(name+'.simulate.log')).read_text(encoding='utf-8',errors='replace') if (OUT/(name+'.simulate.log')).exists() else ''
        expected='RTDS_TRYTHROUGH_PASS' if name=='fast_base' else ('BOARD_CDC.*PASS|TEST PASS' if name=='board_cdc' else 'TEST PASS '+top)
        errors=re.findall(r'(?m)^\s*(?:Fatal:|Error:|ERROR:).*|TEST FAIL.*|CHECK FAIL.*',log)
        passed=rc==0 and bool(re.search(expected,log)) and not errors
        record({'case':name,'top':top,'ids':ids,'seed':SEED,'edge_phase':edge_phase,'status':'PASS' if passed else ('FUNCTIONAL_FAIL' if errors else 'TOOL_FAIL'),'exit_code':rc,'started':started,'finished':NOW(),'wall_seconds':round(time.monotonic()-wall,2),'log':name+'.simulate.log','pass_lines':re.findall(r'(?m)^.*(?:TEST PASS|RTDS_TRYTHROUGH_PASS|BOARD_CDC.*PASS).*$',log),'errors':errors[:8]})
        # Only simulator-created empty containers in this fresh run directory; preserve all previous evidence.
        for p in OUT.glob('*.wdb'):
            assert p.parent.resolve()==OUT.resolve()
            p.unlink()
    changes=[]
    for entry in manifest:
        p=ROOT/entry['path'];digest=hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else None
        if digest!=entry['sha256']:changes.append({'path':entry['path'],'captured_sha256':entry['sha256'],'current_sha256':digest})
    waves=[p.relative_to(OUT).as_posix() for p in OUT.rglob('*') if p.is_file() and p.suffix.lower() in ('.wdb','.vcd','.wcfg')]
    failures=sum(r['status']!='PASS' for r in RESULTS)
    result={'completed':len(RESULTS)==len(CASES),'finished':NOW(),'runs':len(RESULTS),'unique_testbenches':len(set(c[1] for c in CASES)),'passed':len(RESULTS)-failures,'failures':failures,'wave_recording':False,'wave_files':waves,'live_source_changes':changes}
    (OUT/'completion.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
    print('QUICK_NO_WAVE_COMPLETE',json.dumps(result,ensure_ascii=False),flush=True)
    return 1 if failures or waves else 0

try:sys.exit(main())
except Exception as exc:
    (OUT/'runner_error.txt').write_text(traceback.format_exc(),encoding='utf-8')
    (OUT/'completion.json').write_text(json.dumps({'completed':False,'finished':NOW(),'runs':len(RESULTS),'error':str(exc)},ensure_ascii=False,indent=2),encoding='utf-8')
    traceback.print_exc();sys.exit(2)
