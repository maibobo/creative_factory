from pathlib import Path
import subprocess,json,hashlib,datetime,re,sys
sys.stdout.reconfigure(encoding='utf-8')
R=Path('C:/project/RTDS/DDR/RTDS_test_DDR4_64bit_batch_dev');O=R/'verification_20261013/vio_smoke';O.mkdir(parents=True,exist_ok=True)
B=Path('C:/Xilinx/Vivado/2020.2/bin');S=R/'regression/vio_smoke_20261013';I=R/'regression/recovery_phase2_20261011'
results=[]
def tool(name,args,log):
    with (O/log).open('w',encoding='utf-8') as f:
        p=subprocess.run(subprocess.list2cmdline([str(B/(name+'.bat')),*map(str,args)]),shell=True,cwd=O,stdout=f,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
    if p.returncode:raise RuntimeError(name+' failed; '+log)
def compile():
    files=list((R/'rtl').glob('*.v'))
    files+=[R/'RTDS_test_DDR4_64bit.srcs/sources_1/new'/n for n in ['INFO_EXCH.v','CONV_DMA.v','pcie_fdma_aurora_brg_adapter.v']]
    files+=[R/'rtl/ddr4/rtds_ddr4_backend.sv',R/'rtl/ddr4/rtds_axi_ram_model.sv',R/'external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v']
    files+=list((R/'regression/batch_1g').glob('*_test_if.sv'))+list(S.glob('*.sv'))
    files+=[R/'regression/new_cases_20261010/rtds_real_harness.sv',R/'regression/new_cases_20261010/tb_regs_multiblock.sv']
    (O/'smoke_source_hashes.json').write_text(json.dumps([{'path':str(p.relative_to(R)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in files],indent=2),encoding='utf-8')
    tool('xvlog',['-sv','-work','xpm',B/'../data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv',B/'../data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv'],'compile_xpm.log')
    tool('xvlog',['-work','work',B/'../data/verilog/src/glbl.v'],'compile_glbl.log')
    tool('xvlog',['-sv','-L','xpm','-d','DDR4_SIM_RAM','-i',I,'-work','work',*files],'compile_smoke.log')
compile()
for top in ['tb_vio_stim_handshake','tb_rx_vio_smoke','tb_vio_disabled_smoke','tb_regs_multiblock']:
    tool('xelab',['-debug','typical','-mt','off','-L','xpm','-L','unisims_ver','work.'+top,'work.glbl','-s',top],top+'.elaborate.log')
    tcl=O/(top+'.tcl');tcl.write_text('run all\nquit\n',encoding='ascii')
    options=O/(top+'.options')
    options.write_text('--testplusarg "SEED=1417633351"\n--tclbatch "'+str(tcl).replace('\\','/')+'"\n--onerror quit\n--onfinish stop\n--log '+top+'.simulate.log\n',encoding='ascii')
    tool('xsim',[top,'-f',options],top+'.console.log')
    txt=(O/(top+'.simulate.log')).read_text(encoding='utf-8',errors='replace')
    ok=('TEST PASS '+top) in txt and not re.search(r'Fatal:|Error:|TEST FAIL',txt)
    result={'case':top,'status':'PASS' if ok else 'FAIL','model':'real RTL + DDR4_SIM_RAM; simulated VIO start; no board/XDMA/MIG proof','date':datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=8))).isoformat(),'log':top+'.simulate.log'}
    results.append(result);(O/'smoke_summary.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(top,result['status'],flush=True)
    if not ok:raise RuntimeError('Functional failure '+top)
print('VIO_QUICK_SMOKE_PASS',flush=True)
