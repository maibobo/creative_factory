# regs：CPU AXI-Lite 寄存器交互

完整 AXI-Lite 五通道、CPU_WR_DONE 及边沿检测、start/done、ACK/WSTRB、地址长度锁存和队头状态输入/读回；用于检查一次提交一次启动、忙时保持、硬件清零与 ACK 字节过滤。

当前本机重跑日志：114 个 WCFG 对象，114 个 VCD 声明；结束时间 422000 × 1ps。

```text
TEST PASS tb_rtds_regs V2.01
```

## 核心层信号与变化概要

以下逐项列出测试顶层、接口与 DUT 第一层信号。深层 CDC/XPM、clocking block 别名和存储对象见 signals.csv / signals.txt；WCFG 同时包含完整层次。变化次数不包含初值，不等于成功握手次数；已知值范围按无符号二进制解释，X/Z 次数包含初始化阶段，不单独判错。时间单位见上文。

| 信号全名 | 位宽 | 变化次数 | 首次变化 | 最后变化 | 已知最小值 | 已知最大值 |
|---|---:|---:|---:|---:|---:|---:|
| `/tb_rtds_regs/clk` | 1 | 211 | 2000 | 422000 | 0 | 1 |
| `/tb_rtds_regs/starts` | 32 | 2 | 174000 | 310000 | 0 | 2 |
| `/tb_rtds_regs/acks` | 32 | 2 | 342000 | 374000 | 0 | 2 |
| `/tb_rtds_regs/bus/clk` | 1 | 211 | 2000 | 422000 | 0 | 1 |
| `/tb_rtds_regs/bus/rst_n` | 1 | 1 | 30000 | 30000 | 0 | 1 |
| `/tb_rtds_regs/bus/done` | 1 | 2 | 274000 | 278000 | 0 | 1 |
| `/tb_rtds_regs/bus/awaddr` | 32 | 7 | 130000 | 330000 | 0 | 40 |
| `/tb_rtds_regs/bus/wdata` | 32 | 6 | 130000 | 298000 | 0 | 36864 |
| `/tb_rtds_regs/bus/araddr` | 32 | 10 | 50000 | 346000 | 0 | 56 |
| `/tb_rtds_regs/bus/awvalid` | 1 | 20 | 130000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/bus/wvalid` | 1 | 20 | 130000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/bus/arvalid` | 1 | 28 | 34000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/bus/bready` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_regs/bus/rready` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_regs/bus/wstrb` | 4 | 1 | 394000 | 394000 | 14 | 15 |
| `/tb_rtds_regs/bus/awready` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/bus/wready` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/bus/bvalid` | 1 | 21 | 2000 | 406000 | 0 | 1 |
| `/tb_rtds_regs/bus/arready` | 1 | 29 | 2000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/bus/rvalid` | 1 | 28 | 2000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/bus/rdata` | 32 | 13 | 2000 | 354000 | 0 | 539363604 |
| `/tb_rtds_regs/bus/command_addr` | 32 | 1 | 2000 | 2000 | 32768 | 32768 |
| `/tb_rtds_regs/bus/command_len` | 32 | 2 | 2000 | 154000 | 16 | 32768 |
| `/tb_rtds_regs/bus/bresp` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/bus/rresp` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/bus/start` | 1 | 5 | 2000 | 310000 | 0 | 1 |
| `/tb_rtds_regs/bus/ack` | 1 | 5 | 2000 | 374000 | 0 | 1 |
| `/tb_rtds_regs/bus/clear_irq` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/bus/clear_inter` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/CPU_WR_DONE_EVENT` | 1 | 2 | 274000 | 278000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/FPGA_TEMP_W` | 32 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/INT_STATE_W` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/CPU_REC_STATE_W` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/FPGA_CPU_START_ADDR` | 32 | 0 | None | None | 1048576 | 1048576 |
| `/tb_rtds_regs/U_DUT/FPGA_CPU_LEN` | 32 | 0 | None | None | 12 | 12 |
| `/tb_rtds_regs/U_DUT/CPU_WR_DONE_resp` | 1 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/DDR_STATUS_W` | 32 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/RX_READY_BLOCKS` | 32 | 0 | None | None | 1 | 1 |
| `/tb_rtds_regs/U_DUT/RX_HEAD_SEQ` | 32 | 0 | None | None | 7 | 7 |
| `/tb_rtds_regs/U_DUT/RX_DROPPED_FRAMES` | 32 | 0 | None | None | 9 | 9 |
| `/tb_rtds_regs/U_DUT/r_INT_STATE` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/r_CLEAR_INTER` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/r_CPU_REC_STATE` | 1 | 5 | 2000 | 374000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/r_RD_START` | 1 | 5 | 2000 | 310000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/r_CPU_FPGA_START_ADDR` | 32 | 1 | 2000 | 2000 | 32768 | 32768 |
| `/tb_rtds_regs/U_DUT/r_CPU_FPGA_LEN` | 32 | 2 | 2000 | 154000 | 16 | 32768 |
| `/tb_rtds_regs/U_DUT/S_AXI_ACLK` | 1 | 211 | 2000 | 422000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_ARESETN` | 1 | 1 | 30000 | 30000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_AWADDR` | 32 | 7 | 130000 | 330000 | 0 | 40 |
| `/tb_rtds_regs/U_DUT/S_AXI_AWPROT` | 3 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/S_AXI_AWVALID` | 1 | 20 | 130000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_AWREADY` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_WDATA` | 32 | 6 | 130000 | 298000 | 0 | 36864 |
| `/tb_rtds_regs/U_DUT/S_AXI_WSTRB` | 4 | 1 | 394000 | 394000 | 14 | 15 |
| `/tb_rtds_regs/U_DUT/S_AXI_WVALID` | 1 | 20 | 130000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_WREADY` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_BRESP` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/S_AXI_BVALID` | 1 | 21 | 2000 | 406000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_BREADY` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_ARADDR` | 32 | 10 | 50000 | 346000 | 0 | 56 |
| `/tb_rtds_regs/U_DUT/S_AXI_ARPROT` | 3 | 0 | None | None | 0 | 0 |
| `/tb_rtds_regs/U_DUT/S_AXI_ARVALID` | 1 | 28 | 34000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_ARREADY` | 1 | 29 | 2000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_RDATA` | 32 | 13 | 2000 | 354000 | 0 | 539363604 |
| `/tb_rtds_regs/U_DUT/S_AXI_RRESP` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/S_AXI_RVALID` | 1 | 29 | 2000 | 422000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/S_AXI_RREADY` | 1 | 0 | None | None | 1 | 1 |
| `/tb_rtds_regs/U_DUT/axi_awaddr` | 32 | 8 | 2000 | 334000 | 0 | 40 |
| `/tb_rtds_regs/U_DUT/axi_awready` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/axi_wready` | 1 | 21 | 2000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/axi_bresp` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/axi_bvalid` | 1 | 21 | 2000 | 406000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/axi_araddr` | 32 | 11 | 2000 | 350000 | 0 | 56 |
| `/tb_rtds_regs/U_DUT/axi_arready` | 1 | 29 | 2000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/axi_rdata` | 32 | 13 | 2000 | 354000 | 0 | 539363604 |
| `/tb_rtds_regs/U_DUT/axi_rresp` | 2 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/axi_rvalid` | 1 | 29 | 2000 | 422000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/INT_STATE_R` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/CLEAR_INTER_R` | 1 | 1 | 2000 | 2000 | 0 | 0 |
| `/tb_rtds_regs/U_DUT/CPU_WR_DONE` | 32 | 4 | 2000 | 306000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/CPU_REC_STATE` | 32 | 5 | 2000 | 374000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/CPU_FPGA_START_ADDR` | 32 | 1 | 2000 | 2000 | 32768 | 32768 |
| `/tb_rtds_regs/U_DUT/CPU_FPGA_LEN` | 32 | 2 | 2000 | 154000 | 16 | 32768 |
| `/tb_rtds_regs/U_DUT/slv_reg_rden` | 1 | 28 | 38000 | 418000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/slv_reg_wren` | 1 | 20 | 134000 | 402000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/reg_data_out` | 32 | 14 | 2000 | 374000 | 0 | 539363604 |
| `/tb_rtds_regs/U_DUT/byte_index` | 32 | 0 | None | None | None | None |
| `/tb_rtds_regs/U_DUT/aw_en` | 1 | 21 | 2000 | 406000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/byte_index_CPU_FPGA_START_ADDR` | 32 | 1 | 138000 | 138000 | 4 | 4 |
| `/tb_rtds_regs/U_DUT/byte_index_CPU_FPGA_LEN` | 32 | 1 | 154000 | 154000 | 4 | 4 |
| `/tb_rtds_regs/U_DUT/CPU_WR_DONE_d` | 1 | 4 | 2000 | 310000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/CPU_WR_DONE_pos` | 1 | 5 | 2000 | 310000 | 0 | 1 |
| `/tb_rtds_regs/U_DUT/VERSION` | 0 | 0 | None | None | 8193 | 8193 |
| `/tb_rtds_regs/U_DUT/PROG_TIME` | 0 | 0 | None | None | 539363604 | 539363604 |
| `/tb_rtds_regs/U_DUT/CH_BUF_LEN` | 0 | 0 | None | None | 262144 | 262144 |
| `/tb_rtds_regs/U_DUT/C_S_AXI_DATA_WIDTH` | 0 | 0 | None | None | 32 | 32 |
| `/tb_rtds_regs/U_DUT/C_S_AXI_ADDR_WIDTH` | 0 | 0 | None | None | 32 | 32 |
| `/tb_rtds_regs/U_DUT/ADDR_LSB` | 0 | 0 | None | None | 2 | 2 |
| `/tb_rtds_regs/U_DUT/OPT_MEM_ADDR_BITS` | 0 | 0 | None | None | 14 | 14 |

## 仿真源码文件列表（编译顺序）

- [INFO_EXCH.v](F:/RTDS_test_DDR4_64bit_batch_dev/RTDS_test_DDR4_64bit.srcs/sources_1/new/INFO_EXCH.v)
- [rtds_regs_test_if.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/rtds_regs_test_if.sv)
- [tb_rtds_regs.sv](F:/RTDS_test_DDR4_64bit_batch_dev/regression/batch_1g/tb_rtds_regs.sv)
- [glbl.v](F:/RTDS_test_DDR4_64bit_batch_dev/evidence/local_wave_sessions/regs/project/wave_regs.sim/sim_1/behav/xsim/glbl.v)
