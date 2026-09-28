@echo off
setlocal
cd /d C:\project\RTDS\DDR\RTDS_test_DDR4_64bit
set XVLOG=C:\Xilinx\Vivado\2020.2\bin\xvlog.bat
set XELAB=C:\Xilinx\Vivado\2020.2\bin\xelab.bat
call "%XVLOG%" --incr --relax --sv -d DDR4_SIM_RAM --work top_compile_work_64bit ^
  "sim\top_compile\design_1_boundary_stub.v" ^
  "sim\top_compile\aurora_64b66b_top_boundary_stub.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\ip\clk_wiz_0\clk_wiz_0_clk_wiz.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\ip\clk_wiz_0\clk_wiz_0.v" ^
  "RTDS_test_DDR4_64bit.ip_user_files\ip\ila_FDMA\ila_FDMA_stub.v" ^
  "RTDS_test_DDR4_64bit.ip_user_files\ip\sys_mon\sys_mon_stub.v" ^
  "RTDS_test_DDR4_64bit.ip_user_files\ip\ila_temp\ila_temp_stub.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\bd\design_1\hdl\design_1_wrapper.v" ^
  "external_snapshot\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_rx.v" ^
  "external_snapshot\fdma_aurora_brg\fdma_aurora_brg.srcs\sources_1 - loop_validate\new\fdma_aurora_brg_tx.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\pcie_fdma_aurora_brg_adapter.v" ^
  "rtl\ddr4\rtds_axi_ram_model.sv" ^
  "rtl\ddr4\rtds_ddr4_backend.sv" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\CLK_GEN.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\LED.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\TEMP_RD.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\PCIe.v" ^
  "RTDS_test_DDR4_64bit.srcs\sources_1\new\TOP.v" ^
  "C:\Xilinx\Vivado\2020.2\data\verilog\src\glbl.v" ^
  > reports\compile\top_xvlog.log 2>&1
if errorlevel 1 exit /b 1
call "%XELAB%" --relax --debug typical --mt 2 ^
  -L unisims_ver -L unimacro_ver -L secureip -L xpm ^
  --snapshot RTDS_TOP_SIM_ELAB ^
  top_compile_work_64bit.TOP top_compile_work_64bit.glbl ^
  > reports\compile\top_xelab.log 2>&1
if errorlevel 1 exit /b 1
echo RTDS_TOP_COMPILE_ELABORATE_PASS
