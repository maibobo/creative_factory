from pathlib import Path
ROOT=Path(r"C:\project\RTDS\DDR\RTDS_test_DDR4_64bit")
SRC=ROOT/"RTDS_test.srcs"/"sources_1"/"new"
def rep(path,old,new):
 t=path.read_text(encoding="utf-8")
 if new in t: print("ALREADY",path.name); return
 if old not in t: raise RuntimeError(f"pattern not found in {path}: {old[:80]!r}")
 path.write_text(t.replace(old,new,1),encoding="utf-8",newline="\n"); print("PATCHED",path.name)
info=SRC/"INFO_EXCH.v"
rep(info,"\t\tinput\twire\t[0 : 0]\t\t\t\t\t\tCPU_WR_DONE_resp\t\t,\n\t\t\n\t\toutput","\t\tinput\twire\t[0 : 0]\t\t\t\t\t\tCPU_WR_DONE_resp\t\t,\n\t\tinput\twire\t[C_S_AXI_DATA_WIDTH-1 : 0]\tDDR_STATUS_W\t\t\t,\n\t\t\n\t\toutput")
rep(info,"\t\t\t16'h0028\t: reg_data_out\t<= CPU_FPGA_LEN\t\t\t;\n\t\t\t\t\t\n","\t\t\t16'h0028\t: reg_data_out\t<= CPU_FPGA_LEN\t\t\t;\n\t\t\t16'h002C\t: reg_data_out\t<= DDR_STATUS_W\t\t\t;\n\t\t\t\t\t\n")
ad=SRC/"pcie_fdma_aurora_brg_adapter.v"
rep(ad,"        input              pcie_link_up,\n        input              aurora_channel_up,","        input              pcie_link_up,\n        input              ddr_ready,\n        input              aurora_channel_up,")
rep(ad,"    wire pcie_link_up_user;\n    wire aurora_channel_up_fdma;\n    wire aurora_lane_up_fdma;\n    wire link_up_user = pcie_link_up_user && aurora_channel_up && aurora_lane_up;\n    wire link_up_fdma = pcie_link_up && aurora_channel_up_fdma && aurora_lane_up_fdma;\n\n    xpm_cdc_single #(","    wire pcie_link_up_user;\n    wire ddr_ready_user;\n    wire aurora_channel_up_fdma;\n    wire aurora_lane_up_fdma;\n    wire link_up_user = pcie_link_up_user && ddr_ready_user &&\n                        aurora_channel_up && aurora_lane_up;\n    wire link_up_fdma = pcie_link_up && ddr_ready &&\n                        aurora_channel_up_fdma && aurora_lane_up_fdma;\n\n    xpm_cdc_single #(\n        .DEST_SYNC_FF(2), .INIT_SYNC_FF(0), .SIM_ASSERT_CHK(0), .SRC_INPUT_REG(0)\n    ) u_cdc_ddr_ready_to_user (\n        .src_clk(fdma_clk), .src_in(ddr_ready),\n        .dest_clk(aurora_user_clk), .dest_out(ddr_ready_user)\n    );\n\n    xpm_cdc_single #(")
clk=SRC/"CLK_GEN.v"
rep(clk,"\tinput\t\t\tclk_p\t\t,\n\tinput\t\t\tclk_n\t\t,","\tinput\t\t\tclk_i\t\t,")
rep(clk,"    .clk_in1_p(clk_p),    // input clk_in1_p\n    .clk_in1_n(clk_n));    // input clk_in1_n\n    //.clk_in1(clk));      // input clk_in1","    .clk_in1(clk_i));      // shared single-ended 100 MHz after one IBUFDS")
print("PATCH_STAGE1_DONE")