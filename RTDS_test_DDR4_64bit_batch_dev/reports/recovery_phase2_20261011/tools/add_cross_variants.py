from pathlib import Path
R=Path('F:/RTDS_test_DDR4_64bit_batch_dev');N=R/'regression/recovery_phase2_20261011'
s=(N/'tb_recovery_isolation.sv').read_text('utf-8')
s=s.replace('tb_recovery_isolation','tb_recovery_cross_variants')
s=s.replace('kind=n%3;stage=n%6;', 'kind=(n/6)%4;stage=n%6;')
s=s.replace('2:H.ddr_reset_n=0;endcase','2:H.ddr_reset_n=0;3:H.lane_up=0;endcase')
s=s.replace('2:H.ddr_reset_n=1;endcase','2:H.ddr_reset_n=1;3:H.lane_up=1;endcase')
s=s.replace('TC-F15，随机中断位置', 'TC-F15补充：四种就绪失效×六处边界全组合，随机中断位置')
(N/'tb_recovery_cross_variants.sv').write_bytes(s.replace('\n','\r\n').encode('utf-8'))
print('cross variants: 4 readiness kinds x 6 boundary positions, 100 iterations per seed')
