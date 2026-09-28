# ring：上行拼接与八块队列

输入 frame、half/pair/tail、FDMA 全部写事务、状态机和响应、used_bytes、seal/push/pop、读写块指针、head/queued/irq/cpu_ack、丢失计数；用于确认“成功响应之后发布”、低32bit紧凑拼接和队列保护。

当前本机重跑日志：116 个 WCFG 对象，114 个 VCD 声明；结束时间 28902000 × 1ps。

```text
TEST PASS tb_rtds_ring V2.01
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|
| `/tb_rtds_ring/clk` | 1 | 14451 | 2000 | 28902000 | 0 | 1 |
| `/tb_rtds_ring/response_delay` | 32 | 2 | 25866000 | 27138000 | 3 | 300 |
| `/tb_rtds_ring/inject_error` | 1 | 2 | 27138000 | 28114000 | 0 | 1 |
| `/tb_rtds_ring/bus/clk` | 1 | 14451 | 2000 | 28902000 | 0 | 1 |
| `/tb_rtds_ring/bus/rst_n` | 1 | 1 | 34000 | 34000 | 0 | 1 |
| `/tb_rtds_ring/bus/enable` | 1 | 1 | 34000 | 34000 | 0 | 1 |
| `/tb_rtds_ring/bus/frame_valid` | 1 | 150 | 38000 | 28122000 | 0 | 1 |
| `/tb_rtds_ring/bus/cpu_ack` | 1 | 68 | 846000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/bus/irq_clear` | 1 | 68 | 846000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/bus/frame_data` | 64 | 75 | 38000 | 28118000 | 0 | 13619109058144370688 |
| `/tb_rtds_ring/bus/frame_ready` | 1 | 122 | 50000 | 28882000 | 0 | 1 |
| `/tb_rtds_ring/bus/head_addr` | 32 | 61 | 838000 | 28894000 | 0 | 2883584 |
| `/tb_rtds_ring/bus/head_len` | 32 | 54 | 838000 | 28894000 | 0 | 12 |
| `/tb_rtds_ring/bus/head_seq` | 32 | 59 | 1682000 | 28894000 | 0 | 33 |
| `/tb_rtds_ring/bus/ready_blocks` | 32 | 68 | 838000 | 28894000 | 0 | 8 |
| `/tb_rtds_ring/bus/dropped_frames` | 32 | 3 | 25694000 | 27194000 | 0 | 4 |
| `/tb_rtds_ring/bus/irq` | 1 | 54 | 838000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_waddr` | 64 | 80 | 90000 | 28882000 | 1048576 | 2883596 |
| `/tb_rtds_ring/bus/fdma_wdata` | 64 | 47 | 50000 | 28838000 | 0 | 12889196858296 |
| `/tb_rtds_ring/bus/fdma_wstrb` | 8 | 26 | 50000 | 28838000 | 0 | 255 |
| `/tb_rtds_ring/bus/fdma_wsize` | 16 | 0 | None | None | 1 | 1 |
| `/tb_rtds_ring/bus/fdma_wareq` | 1 | 94 | 50000 | 28846000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_wvalid` | 1 | 94 | 58000 | 28862000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_wbusy` | 1 | 94 | 54000 | 28874000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_waccept` | 1 | 94 | 70000 | 28862000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_wdone` | 1 | 94 | 86000 | 28878000 | 0 | 1 |
| `/tb_rtds_ring/bus/fdma_werror` | 1 | 2 | 27190000 | 28874000 | 0 | 1 |
| `/tb_rtds_ring/bus/dbg_state` | 4 | 188 | 50000 | 28878000 | 0 | 3 |
| `/tb_rtds_ring/U_DUT/clk` | 1 | 14451 | 2000 | 28902000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/rst_n` | 1 | 1 | 34000 | 34000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/enable` | 1 | 1 | 34000 | 34000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/frame_data` | 64 | 75 | 38000 | 28118000 | 0 | 13619109058144370688 |
| `/tb_rtds_ring/U_DUT/frame_valid` | 1 | 150 | 38000 | 28122000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/frame_ready` | 1 | 122 | 50000 | 28882000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/cpu_ack` | 1 | 68 | 846000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/irq_clear` | 1 | 68 | 846000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/head_addr` | 32 | 61 | 838000 | 28894000 | 0 | 2883584 |
| `/tb_rtds_ring/U_DUT/head_len` | 32 | 54 | 838000 | 28894000 | 0 | 12 |
| `/tb_rtds_ring/U_DUT/head_seq` | 32 | 59 | 1682000 | 28894000 | 0 | 33 |
| `/tb_rtds_ring/U_DUT/ready_blocks` | 32 | 68 | 838000 | 28894000 | 0 | 8 |
| `/tb_rtds_ring/U_DUT/dropped_frames` | 32 | 3 | 25694000 | 27194000 | 0 | 4 |
| `/tb_rtds_ring/U_DUT/irq` | 1 | 54 | 838000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_wstrb` | 8 | 26 | 50000 | 28838000 | 0 | 255 |
| `/tb_rtds_ring/U_DUT/fdma_waddr` | 64 | 80 | 90000 | 28882000 | 1048576 | 2883596 |
| `/tb_rtds_ring/U_DUT/fdma_wsize` | 16 | 0 | None | None | 1 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_wareq` | 1 | 94 | 50000 | 28846000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_wbusy` | 1 | 94 | 54000 | 28874000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_wdata` | 64 | 47 | 50000 | 28838000 | 0 | 12889196858296 |
| `/tb_rtds_ring/U_DUT/fdma_wvalid` | 1 | 94 | 58000 | 28862000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_waccept` | 1 | 94 | 70000 | 28862000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_wdone` | 1 | 94 | 86000 | 28878000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/fdma_werror` | 1 | 2 | 27190000 | 28874000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/dbg_state` | 4 | 188 | 50000 | 28878000 | 0 | 3 |
| `/tb_rtds_ring/U_DUT/write_curr_st` | 3 | 188 | 50000 | 28878000 | 0 | 3 |
| `/tb_rtds_ring/U_DUT/write_next_st` | 3 | 188 | 46000 | 28874000 | 0 | 3 |
| `/tb_rtds_ring/U_DUT/write_block` | 3 | 34 | 838000 | 28882000 | 0 | 7 |
| `/tb_rtds_ring/U_DUT/read_block` | 3 | 34 | 850000 | 28894000 | 0 | 7 |
| `/tb_rtds_ring/U_DUT/queued` | 4 | 68 | 838000 | 28894000 | 0 | 8 |
| `/tb_rtds_ring/U_DUT/block_len` |  |  |  |  |  |  |
| `/tb_rtds_ring/U_DUT/block_seq` |  |  |  |  |  |  |
| `/tb_rtds_ring/U_DUT/used_bytes` | 32 | 80 | 90000 | 28882000 | 0 | 12 |
| `/tb_rtds_ring/U_DUT/time_count` | 32 | 7217 | 38000 | 28902000 | 0 | 199 |
| `/tb_rtds_ring/U_DUT/publish_seq` | 32 | 34 | 838000 | 28882000 | 0 | 34 |
| `/tb_rtds_ring/U_DUT/seal_pending` | 1 | 72 | 834000 | 28882000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/half_valid` | 1 | 94 | 42000 | 28838000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/half_data` | 32 | 46 | 870000 | 28122000 | 0 | 4000 |
| `/tb_rtds_ring/U_DUT/active_transfer` | 76 | 47 | 50000 | 28838000 | 0 | 42482851614642294229944 |
| `/tb_rtds_ring/U_DUT/tick` | 1 | 72 | 830000 | 28834000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/take_word` | 1 | 150 | 38000 | 28122000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/reject_word` | 1 | 4 | 25690000 | 25702000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/pair_start` | 1 | 52 | 46000 | 27154000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/tail_start` | 1 | 42 | 1634000 | 28838000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/start_write` | 1 | 94 | 46000 | 28838000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/seal_done` | 1 | 72 | 834000 | 28882000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/push_block` | 1 | 68 | 834000 | 28882000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/pop_block` | 1 | 68 | 846000 | 28894000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/write_success` | 1 | 92 | 86000 | 28878000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/write_failure` | 1 | 2 | 27190000 | 27194000 | 0 | 1 |
| `/tb_rtds_ring/U_DUT/drop_sum` | 33 | 3 | 25690000 | 27190000 | 0 | 4 |
| `/tb_rtds_ring/U_DUT/len_index` | 32 | 0 | None | None | 8 | 8 |
| `/tb_rtds_ring/U_DUT/seq_index` | 32 | 0 | None | None | 8 | 8 |
| `/tb_rtds_ring/U_DUT/BLOCK_COUNT` | 0 | 0 | None | None | 8 | 8 |
| `/tb_rtds_ring/U_DUT/BLOCK_BYTES` | 0 | 0 | None | None | 262144 | 262144 |
| `/tb_rtds_ring/U_DUT/PERIOD_CYCLES` | 0 | 0 | None | None | 200 | 200 |
| `/tb_rtds_ring/U_DUT/BASE_ADDR` | 32 | 0 | None | None | 1048576 | 1048576 |
| `/tb_rtds_ring/U_DUT/INDEX_BITS` | 0 | 0 | None | None | 3 | 3 |
| `/tb_rtds_ring/U_DUT/IDLE` | 3 | 0 | None | None | 0 | 0 |
| `/tb_rtds_ring/U_DUT/REQ` | 3 | 0 | None | None | 1 | 1 |
| `/tb_rtds_ring/U_DUT/DATA` | 3 | 0 | None | None | 2 | 2 |
| `/tb_rtds_ring/U_DUT/RESPONSE` | 3 | 0 | None | None | 3 | 3 |
| `/tb_rtds_ring/responder/address` | 64 | 46 | 54000 | 27158000 | 1048576 | 2883592 |
| `/tb_rtds_ring/responder/data` | 64 | 47 | 62000 | 28850000 | 18 | 12889196858296 |
| `/tb_rtds_ring/responder/strb` | 8 | 26 | 62000 | 28850000 | 15 | 255 |

## 仿真源码文件列表（编译顺序）

- [rtds_rx_block_writer.v](F:/RTDS_test_DDR4_64bit_batch_dev/rtl/rtds_rx_block_writer.v)
- [rtds_ring_test_if.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/rtds_ring_test_if.sv)
- [tb_rtds_ring.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/tb_rtds_ring.sv)
- [glbl.v](F:/RTDS_test_DDR4_64bit_batch_dev/evidence/local_wave_sessions/ring/project/wave_ring.sim/sim_1/behav/xsim/glbl.v)
