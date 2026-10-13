from pathlib import Path
import re,subprocess,json,time,hashlib,datetime,sys
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');S=Path(__file__).parent
N=R/'regression/recovery_phase2_20261011';O=R/'verification_20261011/real_mig_recovery';O.mkdir(parents=True,exist_ok=True)
B=Path('D:/Xilinx_2020_2/Vivado/2020.2/bin')
PROBE=R/'verification_20261011/mig_model_probe';EX=PROBE/'example/rtds_ddr4_mig_ex'
IPPRJ=EX/'rtds_ddr4_mig_ex.ip_user_files/sim_scripts/rtds_ddr4_mig/xsim'
TB=PROBE/'ip_copy/rtds_ddr4_mig/tb';MODEL=TB/'ddr4_model'
seeds=json.loads((S/'seeds.json').read_text('utf-8'))['seeds'];results={'model':'DDR4_REAL + actual AXI clock converter + 4 x x16 DDR4 model','ids':['TC-F16'],'runs':[]}
def save():(O/'summary.json').write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding='utf-8')
def tool(name,args,log,timeout=1200):
    with (O/log).open('w',encoding='utf-8') as f:
        cmd=subprocess.list2cmdline([str(B/(name+'.bat')),*map(str,args)])
        p=subprocess.Popen(cmd,shell=True,cwd=O,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        (O/'running_tool.json').write_text(json.dumps({'pid':p.pid,'tool':name,'args':list(map(str,args)),'log':log,'started':datetime.datetime.now().isoformat()}),encoding='utf-8')
        try:return p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            subprocess.run(['taskkill','/PID',str(p.pid),'/T','/F'],capture_output=True);f.write('\nWALLCLOCK_TIMEOUT\n');return -999
def rebase(text,base):
    return re.sub(r'"([^"\r\n]+)"',lambda m:'"'+str((base/m.group(1)).resolve()).replace('\\','/')+'"',text)
vlog=rebase((IPPRJ/'vlog.prj').read_text('utf-8'),IPPRJ)
vlog=re.sub(r'(?m)^verilog xil_defaultlib "[^"]*/glbl.v"\s*$', '',vlog).replace('nosort','')
rootprj=(R/'verification_20261011/rootport_current_o0/vlog.prj').read_text('utf-8')
libs=['generic_baseblocks_v2_1_0','axi_infrastructure_v1_1_0','axi_register_slice_v2_1_22','fifo_generator_v13_2_5','axi_data_fifo_v2_1_21','axi_clock_converter_v2_1_21']
for block in rootprj.split('\n\n'):
    if any(re.match(r'\s*verilog '+re.escape(lib)+r'\b',block) for lib in libs):vlog+='\n'+block+'\n'
vlog+='\nsv xpm "'+str(B/'../data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv').replace('\\','/')+'" "'+str(B/'../data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv').replace('\\','/')+'"\n'
models=[TB/'ddr4_sdram_model_wrapper.sv',MODEL/'arch_package.sv',MODEL/'proj_package.sv',MODEL/'interface.sv',MODEL/'ddr4_model.sv']
own=[R/'RTDS_test_DDR4_64bit.srcs/sources_1/ip/rtds_axi_clock_converter/sim/rtds_axi_clock_converter.v',R/'rtl/ddr4/rtds_ddr4_backend.sv',N/'rtds_ddr4_physical_peer.sv',N/'rtds_backend_real_env.sv',N/'tb_real_mig_recovery.sv']
vlog+='\nsv xil_defaultlib --include "'+str(MODEL).replace('\\','/')+'" --include "'+str(TB).replace('\\','/')+'" --include "'+str(N).replace('\\','/')+'" '+ ' '.join('"'+str(p).replace('\\','/')+'"' for p in models+own)+'\n'
vlog+='\nverilog xil_defaultlib "'+str(B/'../data/verilog/src/glbl.v').replace('\\','/')+'"\nnosort\n'
(O/'vlog.prj').write_text(vlog,encoding='utf-8');(O/'vhdl.prj').write_text(rebase((IPPRJ/'vhdl.prj').read_text('utf-8'),IPPRJ),encoding='utf-8')
paths=[]
for line in vlog.splitlines():
    if not line.lstrip().startswith(('verilog ','sv ')) or '--include' not in line:
        for q in re.findall(r'"([^"]+)"',line):
            p=Path(q)
            if p.is_file():paths.append(p)
paths+=models+own+[N/'rtds_random.svh']
(O/'source_hashes.json').write_text(json.dumps([{'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in dict.fromkeys(paths)],ensure_ascii=False,indent=2),encoding='utf-8')
rc=tool('xvlog',['--relax','-d','DDR4_REAL','-d','XILINX_SIMULATOR','-i',MODEL,'-i',TB,'-i',N,'-prj','vlog.prj'],'compile_vlog.log')
if rc:results.update(status='COMPILE_FAIL',exit_code=rc);save();sys.exit(1)
rc=tool('xvhdl',['--relax','-prj','vhdl.prj'],'compile_vhdl.log')
if rc:results.update(status='COMPILE_FAIL',exit_code=rc);save();sys.exit(1)
rc=tool('xelab',['--relax','-debug','typical','-O0','-mt','off','-L','xpm',*sum([['-L',lib] for lib in ['blk_mem_gen_v8_4_4',*libs]],[]),'-L','unisims_ver','-L','unimacro_ver','-L','secureip','xil_defaultlib.tb_real_mig_recovery','xil_defaultlib.glbl','-s','real_mig'],'elaborate.log',timeout=1800)
if rc:results.update(status='ELABORATE_FAIL',exit_code=rc);save();sys.exit(1)
(O/'run.tcl').write_text('run all\nquit\n',encoding='ascii')
for seed in seeds:
    slug='real_mig_seed_'+str(seed);start=time.monotonic()
    (O/(slug+'.options')).write_text('--sv_seed '+str(seed)+'\n--testplusarg "SEED='+str(seed)+'"\n--tclbatch run.tcl\n--onerror quit\n--onfinish stop\n--log '+slug+'.simulate.log\n',encoding='ascii')
    rc=tool('xsim',['real_mig','-f',slug+'.options'],slug+'.console.log',timeout=1800)
    log=(O/(slug+'.simulate.log')).read_text('utf-8',errors='replace') if (O/(slug+'.simulate.log')).exists() else ''
    passed=rc==0 and 'TEST PASS tb_real_mig_recovery' in log and not re.search(r'(?m)^\s*(Fatal:|Error:|ERROR:)|TEST FAIL|CHECK FAIL',log)
    results['runs'].append({'seed':seed,'status':'PASS' if passed else 'FAIL','exit_code':rc,'log':slug+'.simulate.log','wall_seconds':round(time.monotonic()-start,2)});save();print(slug,'PASS' if passed else 'FAIL',flush=True)
results['status']='PASS' if all(r['status']=='PASS' for r in results['runs']) else 'FAIL';save()
