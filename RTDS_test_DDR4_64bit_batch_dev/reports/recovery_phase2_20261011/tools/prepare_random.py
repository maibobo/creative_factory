from pathlib import Path
import re,difflib,shutil,json,secrets,hashlib
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');O=Path(__file__).parent
B=R/'backups/recovery_phase2_20261011';N=R/'regression/recovery_phase2_20261011';N.mkdir(parents=True,exist_ok=True)
def ann(text,note='随机种子回归：改变激励时序或数据，保留原检查判据'):
    out=[]
    for l in text.splitlines():
        if l.strip() and not l.lstrip().startswith('//'):
            a,_,b=l.partition('//');l=a.rstrip()+'   // 2026-10-11：'+(b.strip() or note)
        out.append(l)
    return '\n'.join(out)
helper='''// 修改记录 2026-10-11：独立xorshift32随机流，SEED显式输入并记录抽样值和末状态。
integer phase2_seed;
integer unsigned phase2_rng=0;
integer phase2_draws=0;
bit phase2_rng_ready=0;
function automatic integer phase2_pick(input integer lo,input integer hi);
    integer unsigned v;
    if(!phase2_rng_ready) begin
        if(!$value$plusargs("SEED=%d",phase2_seed)) phase2_seed=20261011;
        phase2_rng=32'(phase2_seed)^32'h6d2b79f5;
        if(phase2_rng==0) phase2_rng=1;
        phase2_rng_ready=1;
        $display("RNG_INIT scope=%m seed=%0d algorithm=xorshift32",phase2_seed);
    end
    phase2_rng=phase2_rng^(phase2_rng<<13);
    phase2_rng=phase2_rng^(phase2_rng>>17);
    phase2_rng=phase2_rng^(phase2_rng<<5);
    v=phase2_rng;
    phase2_pick=lo+integer'(v%unsigned'(hi-lo+1));
    phase2_draws++;
    if(phase2_draws<=8) $display("RNG_DRAW scope=%m n=%0d value=%0d lo=%0d hi=%0d",phase2_draws,phase2_pick,lo,hi);
endfunction
final $display("RNG_SUMMARY scope=%m seed=%0d draws=%0d state=%h",phase2_seed,phase2_draws,phase2_rng);
'''
(N/'rtds_random.svh').write_text(ann(helper)+'\n',encoding='utf-8')
manifest=[]
def edit(rel,func):
    p=R/rel;old=p.read_text('utf-8-sig');s=func(old)
    if s==old:return
    assert not (B/rel).exists(),rel
    (B/rel).parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,B/rel)
    lines=s.splitlines();sm=difflib.SequenceMatcher(a=old.splitlines(),b=lines,autojunk=False)
    for op,a0,a1,b0,b1 in reversed(sm.get_opcodes()):
        if op in ('insert','replace'):lines[b0:b1]=ann('\n'.join(lines[b0:b1])).splitlines()
    p.write_bytes(('\n'.join(lines)+'\n').replace('\n','\r\n').encode('utf-8'))
    manifest.append({'path':rel,'before_sha256':hashlib.sha256((B/rel).read_bytes()).hexdigest(),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
def inc(s):
    return re.sub(r'(module\s+\w+\s*;)',r'\1\n // 修改记录 2026-10-11：加入随机种子激励。\n `include "rtds_random.svh"',s,count=1)
h='regression/new_cases_20261010/rtds_real_harness.sv'
def harness(s):
    s=inc(s).replace('.rst_n(rst_n),.tick_toggle_2us(tick_2us),.cfg_byte(cfg_byte)', '.rst_n(rst_n),.cfg_byte(cfg_byte)')
    s=s.replace('logic clk=0,uclk=0,gclk=0; always #2 clk=~clk; always #3.2 uclk=~uclk; always #16 gclk=~gclk;', '''logic clk=0,uclk=0,gclk=0;
 bit user_clock_enable=1;
 real user_half_period=3.2;
 bit random_tx_ready=1;
 always #2 clk=~clk;
 initial begin
   #(0.1*phase2_pick(0,31));
   forever begin #(user_half_period); if(user_clock_enable) uclk=~uclk; end
 end
 always #16 gclk=~gclk;
 always @(negedge uclk) if(rst_n && random_tx_ready) tx_ready<=phase2_pick(0,9)<7;
''')
    s=s.replace('expected_seed=seed;expected_byte1=id;', 'expected_seed=seed^phase2_pick(1,1048575);expected_byte1=id;')
    s=s.replace('task automatic wr(input int address,input int value,input logic[3:0] strobe=4\'hf);','task automatic wr(input int address,input int value,input logic[3:0] strobe=4\'hf);\n   repeat(phase2_pick(0,3)) @(regbus.driver_cb);')
    s=s.replace('task automatic rd(input int address,output logic[31:0] value);','task automatic rd(input int address,output logic[31:0] value);\n   repeat(phase2_pick(0,3)) @(regbus.driver_cb);')
    s=s.replace('task automatic send_rx(input int value);','task automatic send_rx(input int value);\n   repeat(phase2_pick(0,3)) @(negedge uclk);')
    return s
edit(h,harness)
for rel in ['regression/batch_1g/tb_rtds_'+x+'.sv' for x in ['1g','tx','ring','axi','axi_tail','regs','rx_fifo','sync']]+['regression/new_cases_20261010/tb_'+x+'.sv' for x in ['byte1_1g','tx_boundaries','ready_recovery','regs_multiblock','period_100ms']]:
    def change(s,rel=rel):
        s=inc(s)
        if rel.endswith('tb_rtds_tx.sv'):
            s=s.replace('int received=0,peak_words=0;', 'logic[31:0] phase2_data=phase2_pick(1,2147483647);\n    int received=0,peak_words=0;')
            s=s.replace("return {32'hA5C32001,32'(word_index)};", "return {phase2_data,32'(word_index)^phase2_data};")
            s=s.replace('for(int beat=0;beat<2;beat++) begin','for(int beat=0;beat<2;beat++) begin\n                repeat(phase2_pick(0,3)) @(bus.fdma_cb);')
            s=s.replace('bus.tx_cb.ready<=((cycle%7)<4);','bus.tx_cb.ready<=phase2_pick(0,9)<7;')
        elif rel.endswith(('tb_rtds_axi.sv','tb_rtds_axi_tail.sv')):
            s=s.replace('int cycle_count=0;', '''bit phase2_aw=0,phase2_w=0,phase2_b=0;
    always @(negedge M_AXI_ACLK) begin
      phase2_aw=phase2_pick(0,9)<6;
      phase2_w=phase2_pick(0,9)<7;
      phase2_b=phase2_pick(0,9)<3;
    end
    int cycle_count=0;''')
            s=s.replace('assign allow_aw=(cycle_count%11)>7;','assign allow_aw=phase2_aw;')
            s=s.replace('assign allow_w=(cycle_count%5)>1 && (!bus.M_AXI_WLAST || (cycle_count%17)>13);','assign allow_w=phase2_w && (!bus.M_AXI_WLAST || (cycle_count%17)>13);')
            s=s.replace('assign allow_b=(cycle_count%31)==0;','assign allow_b=phase2_b;')
            if rel.endswith('tb_rtds_axi_tail.sv'):
                s=s.replace('int cycle_count=0;', 'integer phase2_base=phase2_pick(1,2147483647);\n    int cycle_count=0;').replace("'h12345678",'phase2_base')
        elif rel.endswith('tb_rtds_ring.sv'):
            s=s.replace('int response_delay=3;', 'int response_delay=phase2_pick(3,9);')
            s=s.replace('repeat(2) @(bus.fdma_cb);','repeat(phase2_pick(2,9)) @(bus.fdma_cb);')
            s=s.replace('{$urandom,32\'(value)}', "{32'(phase2_pick(0,2147483647)),32'(value)}")
            s=s.replace('task automatic send_word(input int value);','task automatic send_word(input int value);\n        repeat(phase2_pick(0,3)) @(bus.host_cb);')
        elif rel.endswith('tb_rtds_rx_fifo.sv'):
            s=s.replace('value={$urandom,32\'(n)};',"value={32'(phase2_pick(0,2147483647)),32'(n)};")
            s=s.replace('int received=0;', 'bit phase2_read_enable=0;\n    always @(bus.mem_drv_cb) if(phase2_read_enable) bus.mem_drv_cb.frame_ready<=phase2_pick(0,9)<7;\n    int received=0;')
            s=s.replace('bus.mem_drv_cb.frame_ready<=1;', 'phase2_read_enable=1;')
        elif rel.endswith('tb_rtds_regs.sv'):
            s=s.replace('task automatic wr(input int address,input int value,input logic[3:0] strobe=4\'hf);','task automatic wr(input int address,input int value,input logic[3:0] strobe=4\'hf);\n        repeat(phase2_pick(0,7)) @(bus.driver_cb);')
            s=s.replace('task automatic check(input int address,input int value);','task automatic check(input int address,input int value);\n        repeat(phase2_pick(0,7)) @(bus.driver_cb);')
        elif rel.endswith('tb_rtds_sync.sv'):
            s=s.replace('repeat (5) @(negedge clk_250m);','repeat (phase2_pick(5,20)) @(negedge clk_250m);')
        elif rel.endswith('tb_rtds_1g.sv'):
            # TC-M01 target remains four full words; current legacy DUT is intentionally allowed to fail.
            a=s.index('                if (!partial_frame) begin');b=s.index('\n            end\n        end\n    end',a)
            s=s[:a]+'''                case (phase2_beat)
                  0: phase2_expected={expected_payload[7:0],expected_payload[15:8],expected_payload[23:16],expected_payload[31:24]};
                  1: phase2_expected={expected_payload[39:32],expected_payload[47:40],8'hf0,8'h00};
                  default: phase2_expected=0;
                endcase
                if(bus.tx_mon_cb.tx_sof!=(phase2_beat==0) || bus.tx_mon_cb.tx_eof!=(phase2_beat==3) || bus.tx_mon_cb.tx_rem!=3 || bus.tx_mon_cb.tx_data!==phase2_expected)
                    $fatal(1,"ONE_G/FOUR_BEAT_TARGET beat=%0d data=%h expected=%h eof=%b rem=%d",phase2_beat,bus.tx_mon_cb.tx_data,phase2_expected,bus.tx_mon_cb.tx_eof,bus.tx_mon_cb.tx_rem);
                if(phase2_beat==0) begin
                    if(check_cadence && last_sof_time!=0 && $time-last_sof_time!=1984 && $time-last_sof_time!=2016) $fatal(1,"ONE_G/CADENCE");
                    last_sof_time=$time;
                end
                if(phase2_beat==3) begin phase2_beat=0;partial_frame=0;completed_frames++;end
                else begin phase2_beat++;partial_frame=1;end'''+s[b:]
            s=s.replace('int expected_duty;', 'integer phase2_beat=0;\n    logic[31:0] phase2_expected;\n    int expected_duty;')
            s=s.replace('partial_frame = 0;\n            previous_stall', 'partial_frame = 0; phase2_beat=0;\n            previous_stall')
            s=s.replace('submit(8\'(id));', "expected_payload=(48'(expected_voltage*1048576)<<16)|48'(expected_duty);\n            submit(8'(id));")
            s=s.replace('repeat (210)', 'repeat (210+phase2_pick(0,50))').replace('repeat (90)', 'repeat (90+phase2_pick(0,30))')
        elif rel.endswith('tb_ready_recovery.sv'):
            s=s.replace('repeat(200) @(negedge H.clk);H.check_reg', 'repeat(200+phase2_pick(0,80)) @(negedge H.clk);H.check_reg')
            s=s.replace('     H.reset();', '     H.reset();\n     $display("RECOVERY_FAILURE_CLEANUP kind=%0d reset=1",kind);')
            s=s.replace('$display("CLEANUP_RESET_CHECK kind=', '$display("RECOVERY_NO_RESET_CHECK kind=')
            s=s.replace('else $display("TEST FAIL tb_ready_recovery failed_checks=%0d not_ready=checked R_error=checked B_error=checked timeout=checked overflow=checked clear=checked",failed_checks);', 'else $fatal(1,"TEST FAIL tb_ready_recovery failed_checks=%0d",failed_checks);')
        elif rel.endswith('tb_tx_boundaries.sv'):
            s=s.replace('   $display("TEST PASS', '''   for(int n=0;n<8;n++) begin
     int len,addr;len=16*phase2_pick(1,128);addr='h8000+16*phase2_pick(0,2048-len/16);
     H.valid_tx(addr,len,phase2_pick(1,1048575),8'(phase2_pick(1,10)));
   end
   $display("TEST PASS''')
        elif rel.endswith('tb_regs_multiblock.sv'):
            s=s.replace('logic[31:0] value;', 'integer phase2_base=phase2_pick(1,1048575);\n logic[31:0] value;')
            s=s.replace("'h1000+n*16+w",'phase2_base+n*16+w')
        elif rel.endswith('tb_period_100ms.sv'):
            s=s.replace('logic clk=0;', 'logic[31:0] phase2_words[0:4];\n  initial for(int k=0;k<5;k++) phase2_words[k]=32\'(phase2_pick(1,2147483647));\n  logic clk=0;')
            s=s.replace("64'h2222222211111111",'{phase2_words[1],phase2_words[0]}').replace("64'h4444444433333333",'{phase2_words[3],phase2_words[2]}').replace("64'h0000000055555555",'{32\'d0,phase2_words[4]}')
            for k,v in enumerate(['11111111','22222222','33333333','44444444','55555555']):s=s.replace("send_word('h"+v+')','send_word(phase2_words['+str(k)+'])')
            s=s.replace('repeat(3) @(bus.fdma_cb);','repeat(phase2_pick(3,12)) @(bus.fdma_cb);')
        return s
    edit(rel,change)
pkg='regression/sim_xdma_trythrough/rtds_test_pkg.sv'
def package(s):
    s=s.replace('    function automatic logic [63:0] make_pattern(','''    function automatic logic [63:0] phase2_mask;
        integer seed_value;
        logic[31:0] a,b;
        if(!$value$plusargs("SEED=%d",seed_value)) seed_value=20261011;
        a=32'(seed_value)^32'h6d2b79f5;a=a^(a<<13);a=a^(a>>17);a=a^(a<<5);
        b=a*32'h9e3779b9;
        return {a,b}&64'hffffffffffff0000;
    endfunction
    function automatic logic [63:0] make_pattern(''')
    return s.replace("beat_index[15:0], 16'h5AA5};", "beat_index[15:0], 16'h5AA5} ^ phase2_mask();")
edit(pkg,package)
edit('regression/sim_xdma_trythrough/tb_xdma_rtds_trythrough.sv',lambda s:inc(s).replace('        .pcie_link_up(pcie_link_up),','        .pcie_link_up(pcie_link_up),\n        .ddr_ready(1\'b1),') if '.ddr_ready(' not in s else inc(s))
seeds=[secrets.randbelow(2147483646)+1 for _ in range(3)]
(O/'seeds.json').write_text(json.dumps({'seeds':seeds,'generation':'Python secrets.SystemRandom，记录后可复现','runs_per_case':3},ensure_ascii=False,indent=2),encoding='utf-8')
(O/'test_changes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print('SEEDS',seeds,'modified_tests',len(manifest))
