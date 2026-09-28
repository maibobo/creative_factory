# rx_fifo：10G 接收跨时钟 FIFO

接收数据/有效/帧标记、用户域与存储域时钟复位、FIFO 写读使能/满空/忙、frame 握手、源域丢失计数及目的域同步计数；用于检查按序透传和满时丢失。

当前本机重跑日志：798 个 WCFG 对象，790 个 VCD 声明；结束时间 790000 × 1ps。

```text
TEST PASS tb_rtds_rx_fifo V2.01
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|
| `/tb_rtds_rx_fifo/user_clk` | 1 | 246 | 3200 | 787200 | 0 | 1 |
| `/tb_rtds_rx_fifo/mem_clk` | 1 | 395 | 2000 | 790000 | 0 | 1 |
| `/tb_rtds_rx_fifo/received` | 32 | 18 | 682000 | 790000 | 0 | 18 |
| `/tb_rtds_rx_fifo/bus/user_clk` | 1 | 246 | 3200 | 787200 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/mem_clk` | 1 | 395 | 2000 | 790000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/rst_n` | 1 | 1 | 99200 | 99200 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/user_ready` | 1 | 1 | 99200 | 99200 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/rx_valid` | 1 | 38 | 297600 | 758400 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/rx_sof` | 1 | 13 | 297600 | 752000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/rx_eof` | 1 | 10 | 297600 | 752000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/rx_data` | 64 | 19 | 297600 | 752000 | 0 | 12580584273754456064 |
| `/tb_rtds_rx_fifo/bus/rx_rem` | 3 | 0 | None | None | 7 | 7 |
| `/tb_rtds_rx_fifo/bus/rx_ready` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_rx_fifo/bus/frame_valid` | 1 | 3 | 334000 | 786000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/fifo_full` | 1 | 3 | 6000 | 714000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/fifo_almost_full` | 1 | 3 | 6000 | 746000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/length_error` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/bus/frame_data` | 64 | 18 | 334000 | 786000 | 0 | 12580584273754456064 |
| `/tb_rtds_rx_fifo/bus/frame_ready` | 1 | 1 | 678000 | 678000 | 0 | 1 |
| `/tb_rtds_rx_fifo/bus/dropped_frames` | 32 | 1 | 614000 | 614000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rst_n` | 1 | 1 | 99200 | 99200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/user_clk` | 1 | 246 | 3200 | 787200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/user_ready` | 1 | 1 | 99200 | 99200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rx_data` | 64 | 19 | 297600 | 752000 | 0 | 12580584273754456064 |
| `/tb_rtds_rx_fifo/U_DUT/rx_sof` | 1 | 13 | 297600 | 752000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rx_eof` | 1 | 10 | 297600 | 752000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rx_rem` | 3 | 0 | None | None | 7 | 7 |
| `/tb_rtds_rx_fifo/U_DUT/rx_valid` | 1 | 38 | 297600 | 758400 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rx_ready` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/mem_clk` | 1 | 395 | 2000 | 790000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/frame_data` | 64 | 18 | 334000 | 786000 | 0 | 12580584273754456064 |
| `/tb_rtds_rx_fifo/U_DUT/frame_valid` | 1 | 3 | 334000 | 786000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/frame_ready` | 1 | 1 | 678000 | 678000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_full` | 1 | 3 | 6000 | 714000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_almost_full` | 1 | 3 | 6000 | 746000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/dropped_frames` | 32 | 1 | 614000 | 614000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/length_error` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/user_rst_n` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/drop_bin` | 32 | 1 | 598400 | 598400 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/full_user` | 1 | 2 | 508800 | 707200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/almost_full_user` | 1 | 2 | 438400 | 739200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/empty_mem` | 1 | 4 | 334000 | 790000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/wr_busy` | 1 | 2 | 3200 | 259200 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/rd_busy` | 1 | 4 | 110000 | 222000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_reset` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_read` | 1 | 3 | 678000 | 786000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_write` | 1 | 36 | 297600 | 758400 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/fifo_input` | 64 | 19 | 297600 | 752000 | 0 | 12580584273754456064 |
| `/tb_rtds_rx_fifo/U_DUT/almost_empty_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/almost_full_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/data_valid_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/dbiterr_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/overflow_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/prog_empty_nc` | 1 | 2 | 394000 | 730000 | 0 | 1 |
| `/tb_rtds_rx_fifo/U_DUT/sbiterr_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/underflow_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/wr_ack_nc` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_rx_fifo/U_DUT/rd_data_count_nc` | 5 | 36 | 2000 | 786000 | 0 | 17 |
| `/tb_rtds_rx_fifo/U_DUT/wr_data_count_nc` | 5 | 28 | 3200 | 771200 | 0 | 17 |
| `/tb_rtds_rx_fifo/U_DUT/FIFO_DEPTH` | 0 | 0 | None | None | 16 | 16 |
| `/tb_rtds_rx_fifo/monitor/value` | 64 | 18 | 682000 | 790000 | 157005733550882820 | 12580584273754456064 |

## 仿真源码文件列表（编译顺序）

- [rtds_fpga_count_cdc.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_fpga_count_cdc.v)
- [rtds_fpga_reset_sync.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_fpga_reset_sync.v)
- [rtds_rx_frame_fifo.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_rx_frame_fifo.v)
- [rtds_rx_fifo_test_if.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/rtds_rx_fifo_test_if.sv)
- [tb_rtds_rx_fifo.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/tb_rtds_rx_fifo.sv)
- [glbl.v](F:/RTDS_test_DDR4_64bit_batch_dev/evidence/local_wave_sessions/rx_fifo/project/wave_rx_fifo.sim/sim_1/behav/xsim/glbl.v)
- [xpm_cdc.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv)
- [xpm_fifo.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv)
- [xpm_memory.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv)
