from pathlib import Path
import re
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');N=R/'regression/recovery_phase2_20261011'
for p in N.glob('*.sv'):
    lines=[]
    for l in p.read_text('utf-8').splitlines():
        if l.strip() and not l.lstrip().startswith('//') and '// 2026-10-11：' not in l:
            a,_,b=l.partition('//');l=a.rstrip()+'   // 2026-10-11：'+(b.strip() or '新增恢复验证：按真实握手检查长度、ID、数据与中断边界')
        lines.append(l)
    p.write_bytes(('\n'.join(lines)+'\n').replace('\n','\r\n').encode('utf-8'))
p=R/'regression/new_cases_20261010/tb_ready_recovery.sv';s=p.read_text('utf-8')
s=s.replace('task automatic interrupt_and_recover(input int kind,input int length);','task automatic interrupt_and_recover(input int kind,input int length);\n   bit cleanup=0;   // 2026-10-11：标记是否做过失败清理复位，避免误记无复位恢复')
s=s.replace('     H.reset();','     cleanup=1;H.reset();   // 2026-10-11：只在失败后复位以继续独立检查')
s=s.replace('   $display("RECOVERY_NO_RESET_CHECK kind=', '   if(cleanup) $display("CLEANUP_RESET_CHECK kind=%0d",kind);   // 2026-10-11：失败清理单独记录\n   else $display("RECOVERY_NO_RESET_CHECK kind=')
p.write_bytes(s.replace('\n','\r\n').encode('utf-8'))
print('new test benches annotated; failure cleanup label retained')
