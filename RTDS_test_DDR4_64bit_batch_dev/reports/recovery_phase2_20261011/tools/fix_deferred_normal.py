from pathlib import Path
import re,shutil
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');rel='RTDS_test_DDR4_64bit.srcs/sources_1/new/pcie_fdma_aurora_brg_adapter.v'
p=R/rel;s=p.read_text('utf-8');backup=R/'backups/recovery_phase2_20261011/before_normal_defer'/rel
backup.parent.mkdir(parents=True,exist_ok=True);assert not backup.exists();shutil.copy2(p,backup)
def ann(block):
    out=[]
    for l in block.strip('\n').splitlines():
        if l.strip() and not l.lstrip().startswith('//'):
            a,_,b=l.partition('//');l=a.rstrip()+'   // 2026-10-11：'+(b.strip() or '正常收尾期间锁存下一条合法命令，清理完成后自动启动')
        out.append(l)
    return '\n'.join(out)
anchor='    wire tx_start_valid;'
i=s.index('\n',s.index(anchor))+1
s=s[:i]+ann('''
    // 修改记录 2026-10-11：随机快速回归发现正常连续提交被清理间隔拒绝。
    // 正常末帧完成后的清理可锁存一条下一命令；异常中断清理仍拒绝新提交。
    reg tx_recovery_aborted; // 区分异常中断清理与正常任务收尾
    reg tx_restart_pending; // 已接受但等待两域桥清理的下一条命令
    reg [31:0] tx_deferred_base; // 等待命令的地址快照
    reg [15:0] tx_deferred_frames; // 等待命令的帧数快照
    wire tx_defer_accept; // 正常收尾时锁存合法下一命令的接受事件
''')+'\n'+s[i:]
old="    assign cpu_wr_done_event = (rd_start && !tx_start_valid) ||    // TX 完成事件：末帧完成/链路断/非法命令\n        (tx_active && (!link_up_fdma || (tx_frame_done_fdma &&\n        (tx_completed_frames + 16'd1 >= tx_target_frames))));"
new=ann('''
    assign cpu_wr_done_event = (rd_start && !tx_start_valid && !tx_defer_accept) || // 已锁存的下一命令保持0x20忙，不按拒绝结束
        (tx_restart_pending && !link_up_fdma) || // 等待启动期间失去就绪，结束等待命令
        (tx_active && (!link_up_fdma || (tx_frame_done_fdma &&
        (tx_completed_frames + 16'd1 >= tx_target_frames))));
''')
assert old in s;s=s.replace(old,new,1)
s,n=re.subn(r'^    assign tx_start_valid =.*$',ann('''
    assign tx_start_valid = !tx_active && !tx_recovering && !fdma_rbusy && link_up_fdma &&
        ((rd_start && tx_config_valid) || tx_restart_pending); // 新脉冲或已锁存命令均等待同一安全启动条件
    assign tx_defer_accept = rd_start && !tx_active && tx_recovering && !tx_recovery_aborted &&
        !tx_restart_pending && link_up_fdma && tx_config_valid; // 仅正常收尾清理允许锁存一条下一命令
'''),s,flags=re.M);assert n==1
s,n=re.subn(r'^    assign tx_config_error_event =.*$',ann('''
    assign tx_config_error_event = rd_start && (!tx_config_valid || tx_active || tx_restart_pending ||
        (tx_recovering && tx_recovery_aborted) || (!tx_recovering && fdma_rbusy)); // 正常收尾的合法等待命令不记配置错误
'''),s,flags=re.M);assert n==1
anchor='    wire tx_active_user;'
block=ann('''
    // 修改记录 2026-10-11：等待命令的数据整体锁存；就绪失效时取消，避免自动重发旧批。
    always @(posedge fdma_clk or negedge fdma_rstn) begin
        if (!fdma_rstn) begin
            tx_recovery_aborted <= 1'b1;
            tx_restart_pending <= 1'b0;
            tx_deferred_base <= TX_BASE_ADDR_LO;
            tx_deferred_frames <= 16'd0;
        end else begin
            if (!link_up_fdma) begin
                tx_recovery_aborted <= 1'b1; // 异常清理不接受下一任务
                tx_restart_pending <= 1'b0; // 等待命令就绪失效即取消
            end else begin
                if (tx_active && tx_frame_done_fdma && (tx_completed_frames + 16'd1 >= tx_target_frames))
                    tx_recovery_aborted <= 1'b0; // 正常最后帧接受后，允许锁存下一合法任务
                if (tx_defer_accept) begin
                    tx_restart_pending <= 1'b1;
                    tx_deferred_base <= cpu_fpga_start_addr;
                    tx_deferred_frames <= requested_frames_32[15:0];
                end else if (tx_start_valid) begin
                    tx_restart_pending <= 1'b0; // 安全启动时一次取走等待命令
                end
            end
        end
    end
''')+'\n\n'
assert s.count(anchor)==1;s=s.replace(anchor,block+anchor)
a="                tx_target_frames <= requested_frames_32 [ 15 : 0 ] ;"
assert s.count(a)==1;s=s.replace(a,ann('                tx_target_frames <= tx_restart_pending ? tx_deferred_frames : requested_frames_32[15:0]; // 实际启动时采用等待命令的帧数快照'))
a='                tx_base_addr_lo <= cpu_fpga_start_addr ;'
assert s.count(a)==1;s=s.replace(a,ann('                tx_base_addr_lo <= tx_restart_pending ? tx_deferred_base : cpu_fpga_start_addr; // 实际启动时采用等待命令的地址快照'))
p.write_bytes(s.replace('\n','\r\n').encode('utf-8'))
print('normal completion defer implemented; abnormal recovery still rejects')
