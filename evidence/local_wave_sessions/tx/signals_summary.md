# tx：16Byte 下行与异步 FIFO

FDMA 地址/请求/数据握手、批量上限、FIFO 水位和满空保护、读/发状态机、10G 数据与 SOF/EOF/REM/ready；用于区分预取、反压保持、补读和排空。

当前本机重跑日志：790 个 WCFG 对象，783 个 VCD 声明；结束时间 28905600 × 1ps。

```text
TX CASE PASS frames=1 peak=2
TX CASE PASS frames=300 peak=504
TEST PASS tb_rtds_tx single/batch/near_full/backpressure
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|
| `/tb_rtds_tx/fdma_clk` | 1 | 14452 | 2000 | 28904000 | 0 | 1 |
| `/tb_rtds_tx/user_clk` | 1 | 9033 | 3200 | 28905600 | 0 | 1 |
| `/tb_rtds_tx/received` | 32 | 603 | 329600 | 28777600 | 0 | 600 |
| `/tb_rtds_tx/peak_words` | 32 | 507 | 274000 | 6722000 | 0 | 504 |
| `/tb_rtds_tx/monitor_enable` | 1 | 3 | 162000 | 626000 | 0 | 1 |
| `/tb_rtds_tx/held_payload` | 70 | 904 | 163200 | 28784000 | 7 | 382221626412279810799 |
| `/tb_rtds_tx/was_stalled` | 1 | 402 | 316800 | 28758400 | 0 | 1 |
| `/tb_rtds_tx/bus/fdma_clk` | 1 | 14452 | 2000 | 28904000 | 0 | 1 |
| `/tb_rtds_tx/bus/user_clk` | 1 | 9033 | 3200 | 28905600 | 0 | 1 |
| `/tb_rtds_tx/bus/rst_n` | 1 | 3 | 82000 | 546000 | 0 | 1 |
| `/tb_rtds_tx/bus/channel_up` | 1 | 3 | 162000 | 626000 | 0 | 1 |
| `/tb_rtds_tx/bus/limit` | 16 | 2 | 2000 | 466000 | 0 | 300 |
| `/tb_rtds_tx/bus/raddr` | 32 | 302 | 274000 | 21294000 | 0 | 4800 |
| `/tb_rtds_tx/bus/rareq` | 1 | 602 | 258000 | 21286000 | 0 | 1 |
| `/tb_rtds_tx/bus/rready` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/bus/rbusy` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/bus/rvalid` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/bus/rdata` | 64 | 602 | 262000 | 21286000 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/bus/tx_data` | 64 | 903 | 310400 | 28777600 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/bus/sof` | 1 | 602 | 310400 | 28771200 | 0 | 1 |
| `/tb_rtds_tx/bus/eof` | 1 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/bus/valid` | 1 | 602 | 310400 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/bus/done` | 1 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/bus/rem` | 3 | 0 | None | None | 7 | 7 |
| `/tb_rtds_tx/bus/ready` | 1 | 406 | 233600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/bus/dbg_fdma` | 38 | 2058 | 2000 | 28798000 | 0 | 239914496000 |
| `/tb_rtds_tx/bus/dbg_user` | 39 | 1597 | 3200 | 28784000 | 0 | 342523641870 |
| `/tb_rtds_tx/U_DUT/fdma_clk` | 1 | 14452 | 2000 | 28904000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fdma_rstn` | 1 | 3 | 82000 | 546000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/user_clk` | 1 | 9033 | 3200 | 28905600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/user_rstn` | 1 | 3 | 82000 | 546000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/channel_up` | 1 | 3 | 162000 | 626000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/channel_up_fdma` | 1 | 3 | 162000 | 626000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/cfg_tx_burst_limit` | 16 | 2 | 2000 | 466000 | 0 | 300 |
| `/tb_rtds_tx/U_DUT/fdma_raddr` | 32 | 302 | 274000 | 21294000 | 0 | 4800 |
| `/tb_rtds_tx/U_DUT/fdma_rareq` | 1 | 602 | 258000 | 21286000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fdma_rbusy` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fdma_rdata` | 64 | 602 | 262000 | 21286000 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/U_DUT/fdma_rvalid` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fdma_rready` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_d` | 64 | 903 | 310400 | 28777600 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/U_DUT/tx_sof` | 1 | 602 | 310400 | 28771200 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_eof` | 1 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_rem` | 3 | 0 | None | None | 7 | 7 |
| `/tb_rtds_tx/U_DUT/tx_src_rdy` | 1 | 602 | 310400 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_dst_rdy` | 1 | 406 | 233600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/dbg_fdma_bus` | 38 | 2058 | 2000 | 28798000 | 0 | 239914496000 |
| `/tb_rtds_tx/U_DUT/dbg_user_bus` | 39 | 1597 | 3200 | 28784000 | 0 | 342523641870 |
| `/tb_rtds_tx/U_DUT/tx_frame_done` | 1 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_state` | 2 | 1204 | 254000 | 21294000 | 0 | 3 |
| `/tb_rtds_tx/U_DUT/rd_state_nxt` | 2 | 1204 | 250000 | 21290000 | 0 | 3 |
| `/tb_rtds_tx/U_DUT/rd_addr` | 32 | 302 | 274000 | 21294000 | 0 | 4800 |
| `/tb_rtds_tx/U_DUT/rd_word_cnt` | 7 | 602 | 266000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_burst_done` | 1 | 602 | 266000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_state` | 2 | 903 | 310400 | 28777600 | 0 | 2 |
| `/tb_rtds_tx/U_DUT/tx_state_nxt` | 2 | 903 | 304000 | 28771200 | 0 | 2 |
| `/tb_rtds_tx/U_DUT/tx_word_cnt` | 8 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/wr_burst_done` | 1 | 602 | 329600 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/frame_cnt` | 16 | 302 | 336000 | 28777600 | 0 | 300 |
| `/tb_rtds_tx/U_DUT/burst_cnt` | 16 | 302 | 270000 | 21290000 | 0 | 300 |
| `/tb_rtds_tx/U_DUT/fifo_wr_en` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_rd_en` | 1 | 802 | 323200 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/wr_en` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_en` | 1 | 802 | 323200 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_rst` | 1 | 3 | 82000 | 546000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_full` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_tx/U_DUT/fifo_empty` | 1 | 4 | 304000 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_wdata` | 64 | 602 | 262000 | 21286000 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/U_DUT/fifo_rdata` | 64 | 603 | 304000 | 28771200 | 0 | 11944425825383744087 |
| `/tb_rtds_tx/U_DUT/fifo_overflow` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_tx/U_DUT/fifo_underflow` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_tx/U_DUT/fifo_wr_cnt` | 10 | 1197 | 2000 | 28798000 | 0 | 504 |
| `/tb_rtds_tx/U_DUT/fifo_rd_cnt` | 10 | 1009 | 3200 | 28784000 | 0 | 504 |
| `/tb_rtds_tx/U_DUT/fifo_almost_full` | 1 | 66 | 6718000 | 21302000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_almost_empty` | 1 | 4 | 304000 | 28771200 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/wr_rst_busy` | 1 | 4 | 2000 | 670000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_rst_busy` | 1 | 8 | 118400 | 649600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/wr_clk` | 1 | 14452 | 2000 | 28904000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_clk` | 1 | 9033 | 3200 | 28905600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_burst_allowed` | 1 | 3 | 270000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_data_phase` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/fifo_write_ready` | 1 | 70 | 2000 | 21302000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/rd_data_hs` | 1 | 602 | 262000 | 21290000 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/tx_hs` | 1 | 802 | 323200 | 28777600 | 0 | 1 |
| `/tb_rtds_tx/U_DUT/FRAME_BYTES` | 0 | 0 | None | None | 16 | 16 |
| `/tb_rtds_tx/U_DUT/MEM_WINDOW_BYTES` | 0 | 0 | None | None | 32768 | 32768 |
| `/tb_rtds_tx/U_DUT/TEST_MEM_SIZE` | 32 | 0 | None | None | 32768 | 32768 |
| `/tb_rtds_tx/U_DUT/FDMA_BURST_LEN` | 32 | 0 | None | None | 16 | 16 |
| `/tb_rtds_tx/U_DUT/BURST_WORDS` | 32 | 0 | None | None | 2 | 2 |
| `/tb_rtds_tx/U_DUT/FRAME_WORDS` | 32 | 0 | None | None | 2 | 2 |
| `/tb_rtds_tx/U_DUT/TX_FIFO_RESERVE_WORDS` | 32 | 0 | None | None | 8 | 8 |
| `/tb_rtds_tx/U_DUT/TX_PROG_FULL_THRESH` | 32 | 0 | None | None | 504 | 504 |
| `/tb_rtds_tx/U_DUT/RD_IDLE` | 2 | 0 | None | None | 0 | 0 |
| `/tb_rtds_tx/U_DUT/RD_REQ` | 2 | 0 | None | None | 1 | 1 |
| `/tb_rtds_tx/U_DUT/RD_DATA` | 2 | 0 | None | None | 2 | 2 |
| `/tb_rtds_tx/U_DUT/RD_WAIT` | 2 | 0 | None | None | 3 | 3 |
| `/tb_rtds_tx/U_DUT/TX_IDLE` | 2 | 0 | None | None | 0 | 0 |
| `/tb_rtds_tx/U_DUT/TX_SOF` | 2 | 0 | None | None | 1 | 1 |
| `/tb_rtds_tx/U_DUT/TX_DATA` | 2 | 0 | None | None | 2 | 2 |

## 仿真源码文件列表（编译顺序）

- [fdma_aurora_brg_tx.v](F:/RTDS_test_DDR4_64bit_batch_dev/external_snapshot/fdma_aurora_brg/fdma_aurora_brg.srcs/sources_1 - loop_validate/new/fdma_aurora_brg_tx.v)
- [rtds_tx_test_if.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/rtds_tx_test_if.sv)
- [tb_rtds_tx.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/tb_rtds_tx.sv)
- [glbl.v](F:/RTDS_test_DDR4_64bit_batch_dev/evidence/local_wave_sessions/tx/project/wave_tx.sim/sim_1/behav/xsim/glbl.v)
- [xpm_cdc.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv)
- [xpm_fifo.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv)
- [xpm_memory.sv](D:/Xilinx_2020_2/Vivado/2020.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv)
