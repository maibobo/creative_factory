vlib questa_lib/work
vlib questa_lib/msim

vlib questa_lib/msim/xpm
vlib questa_lib/msim/fifo_generator_v13_2_5
vlib questa_lib/msim/xil_defaultlib

vmap xpm questa_lib/msim/xpm
vmap fifo_generator_v13_2_5 questa_lib/msim/fifo_generator_v13_2_5
vmap xil_defaultlib questa_lib/msim/xil_defaultlib

vlog -work xpm  -sv \
"E:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"E:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
"E:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm  -93 \
"E:/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work fifo_generator_v13_2_5  \
"../../../ipstatic/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_5  -93 \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_5  \
"../../../ipstatic/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work xil_defaultlib  \
"../../../../RTDS_test.srcs/sources_1/ip/fifo_cdc_pcie/sim/fifo_cdc_pcie.v" \

vlog -work xil_defaultlib \
"glbl.v"

