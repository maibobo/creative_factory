# 1g：1G 配置跨时钟和周期发送

配置字节、译码/锁存、CDC 请求确认、链路复位、发送握手/帧标记/数据、周期和跳过计数；用于连接“首次合法配置→目的域参数→两拍发送”，并定位反压与掉线恢复。

当前本机重跑日志：195 个 WCFG 对象，195 个 VCD 声明；结束时间 283920000 × 1ps。

```text
TEST PASS tb_rtds_1g completed_frames=60
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|
| `/tb_rtds_1g/src_clk` | 1 | 141960 | 2000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/user_clk` | 1 | 17745 | 16000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/expected_duty` | 32 | 10 | 784000 | 256240000 | 0 | 8000 |
| `/tb_rtds_1g/expected_voltage` | 32 | 3 | 784000 | 199472000 | 0 | 24 |
| `/tb_rtds_1g/check_cadence` | 1 | 19 | 12240000 | 267696000 | 0 | 1 |
| `/tb_rtds_1g/last_sof_time` | 64 | 80 | 8176000 | 283888000 | 0 | 283792 |
| `/tb_rtds_1g/completed_frames` | 32 | 60 | 8208000 | 283824000 | 0 | 60 |
| `/tb_rtds_1g/partial_frame` | 1 | 120 | 8176000 | 283824000 | 0 | 1 |
| `/tb_rtds_1g/previous_stall` | 1 | 40 | 14224000 | 277392000 | 0 | 1 |
| `/tb_rtds_1g/held_payload` | 36 | 191 | 16000 | 283856000 | 12884901888 | 50734759936 |
| `/tb_rtds_1g/first_word` | 32 | 10 | 8176000 | 263632000 | 1075773440 | 3490119680 |
| `/tb_rtds_1g/observed_payload` | 48 | 10 | 8208000 | 263664000 | 343597386680 | 1649267449664 |
| `/tb_rtds_1g/expected_payload` | 48 | 10 | 8208000 | 263664000 | 343597386680 | 1649267449664 |
| `/tb_rtds_1g/bus/src_clk` | 1 | 141960 | 2000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/bus/user_clk` | 1 | 17745 | 16000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/bus/rst_n` | 1 | 19 | 786000 | 256242000 | 0 | 1 |
| `/tb_rtds_1g/bus/cfg_byte` | 8 | 38 | 826000 | 261394000 | 0 | 11 |
| `/tb_rtds_1g/bus/cfg_byte_valid` | 1 | 80 | 818000 | 265686000 | 0 | 1 |
| `/tb_rtds_1g/bus/user_reset` | 1 | 19 | 816000 | 256272000 | 0 | 1 |
| `/tb_rtds_1g/bus/channel_up` | 1 | 40 | 816000 | 283856000 | 0 | 1 |
| `/tb_rtds_1g/bus/tx_ready` | 1 | 59 | 816000 | 277360000 | 0 | 1 |
| `/tb_rtds_1g/bus/tx_data` | 32 | 139 | 6128000 | 283792000 | 0 | 3490119680 |
| `/tb_rtds_1g/bus/tx_rem` | 2 | 120 | 8176000 | 283824000 | 1 | 3 |
| `/tb_rtds_1g/bus/tx_sof` | 1 | 120 | 8144000 | 283792000 | 0 | 1 |
| `/tb_rtds_1g/bus/tx_eof` | 1 | 120 | 8176000 | 283824000 | 0 | 1 |
| `/tb_rtds_1g/bus/tx_valid` | 1 | 120 | 8144000 | 283824000 | 0 | 1 |
| `/tb_rtds_1g/bus/configured` | 1 | 19 | 6178000 | 261634000 | 0 | 1 |
| `/tb_rtds_1g/bus/configured_id` | 8 | 19 | 5942000 | 261398000 | 0 | 10 |
| `/tb_rtds_1g/bus/skipped_periods` | 32 | 39 | 16208000 | 275696000 | 0 | 3 |
| `/tb_rtds_1g/U_DUT/clk_250m` | 1 | 141960 | 2000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/rst_n` | 1 | 19 | 786000 | 256242000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_byte` | 8 | 38 | 826000 | 261394000 | 0 | 11 |
| `/tb_rtds_1g/U_DUT/cfg_byte_valid` | 1 | 80 | 818000 | 265686000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/user_clk` | 1 | 17745 | 16000 | 283920000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/user_reset` | 1 | 19 | 816000 | 256272000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/channel_up` | 1 | 40 | 816000 | 283856000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/tx_ready` | 1 | 59 | 816000 | 277360000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/tx_data` | 32 | 139 | 6128000 | 283792000 | 0 | 3490119680 |
| `/tb_rtds_1g/U_DUT/tx_rem` | 2 | 120 | 8176000 | 283824000 | 1 | 3 |
| `/tb_rtds_1g/U_DUT/tx_sof` | 1 | 120 | 8144000 | 283792000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/tx_eof` | 1 | 120 | 8176000 | 283824000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/tx_valid` | 1 | 120 | 8144000 | 283824000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/configured` | 1 | 19 | 6178000 | 261634000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/configured_id` | 8 | 19 | 5942000 | 261398000 | 0 | 10 |
| `/tb_rtds_1g/U_DUT/skipped_periods` | 32 | 39 | 16208000 | 275696000 | 0 | 3 |
| `/tb_rtds_1g/U_DUT/src_rst_n` | 1 | 20 | 100000 | 256258000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/user_rst_n` | 1 | 20 | 100000 | 256368000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_hold` | 48 | 19 | 5942000 | 261398000 | 0 | 1649267449664 |
| `/tb_rtds_1g/U_DUT/cfg_req` | 1 | 19 | 5942000 | 261398000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_ack` | 1 | 19 | 6128000 | 261584000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/req_sync` | 1 | 20 | 6096000 | 261776000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_cdc_data` | 48 | 10 | 6096000 | 261552000 | 0 | 1649267449664 |
| `/tb_rtds_1g/U_DUT/cfg_send` | 1 | 20 | 5942000 | 261634000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_dest_ack` | 1 | 20 | 6160000 | 261808000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/ack_sync` | 1 | 20 | 6174000 | 261822000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/cfg_user` | 48 | 19 | 6128000 | 261584000 | 0 | 1649267449664 |
| `/tb_rtds_1g/U_DUT/period_count` | 32 | 6962 | 6160000 | 283920000 | 0 | 62 |
| `/tb_rtds_1g/U_DUT/period_tick` | 1 | 220 | 8112000 | 283760000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/arm_count` | 3 | 100 | 6160000 | 283888000 | 0 | 4 |
| `/tb_rtds_1g/U_DUT/tx_curr_st` | 2 | 180 | 8144000 | 283824000 | 0 | 2 |
| `/tb_rtds_1g/U_DUT/decoded_duty` | 16 | 26 | 5938000 | 261394000 | 0 | 8000 |
| `/tb_rtds_1g/U_DUT/decoded_vin` | 32 | 26 | 5938000 | 261394000 | 0 | 25165824 |
| `/tb_rtds_1g/U_DUT/decode_valid` | 1 | 19 | 5938000 | 261394000 | 0 | 1 |
| `/tb_rtds_1g/U_DUT/tx_next_st` | 2 | 180 | 8112000 | 283792000 | 0 | 2 |
| `/tb_rtds_1g/U_DUT/PERIOD_CYCLES` | 0 | 0 | None | None | 63 | 63 |
| `/tb_rtds_1g/U_DUT/IDLE` | 2 | 0 | None | None | 0 | 0 |
| `/tb_rtds_1g/U_DUT/FIRST` | 2 | 0 | None | None | 1 | 1 |
| `/tb_rtds_1g/U_DUT/LAST` | 2 | 0 | None | None | 2 | 2 |
| `/tb_rtds_1g/stimulus/previous_frames` | 32 | 19 | 25168000 | 280624000 | 0 | 58 |

## 仿真源码文件列表（编译顺序）

- [rtds_1g_periodic_tx.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_1g_periodic_tx.v)
- [rtds_fpga_cfg_cdc.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_fpga_cfg_cdc.v)
- [rtds_fpga_reset_sync.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_fpga_reset_sync.v)
- [rtds_1g_test_if.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/rtds_1g_test_if.sv)
- [tb_rtds_1g.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/tb_rtds_1g.sv)
- [glbl.v](F:/RTDS_test_DDR4_64bit_batch_dev/evidence/local_wave_sessions/1g/project/wave_1g.sim/sim_1/behav/xsim/glbl.v)
- [xpm_cdc.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv)
