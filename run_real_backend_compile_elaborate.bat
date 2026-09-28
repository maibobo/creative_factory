@echo off
setlocal
cd /d C:\project\RTDS\DDR\RTDS_test_DDR4_64bit
set XVLOG=C:\Xilinx\Vivado\2020.2\bin\xvlog.bat
set XELAB=C:\Xilinx\Vivado\2020.2\bin\xelab.bat
call "%XVLOG%" --incr --relax --sv -d DDR4_REAL --work real_backend_work_64bit ^
  "sim\top_compile\rtds_axi_clock_converter_boundary_stub.v" ^
  "sim\top_compile\rtds_ddr4_mig_boundary_stub.v" ^
  "rtl\ddr4\rtds_ddr4_backend.sv" ^
  "C:\Xilinx\Vivado\2020.2\data\verilog\src\glbl.v" ^
  > reports\compile\real_backend_xvlog.log 2>&1
if errorlevel 1 exit /b 1
call "%XELAB%" --relax --debug typical --mt 2 ^
  -L unisims_ver -L unimacro_ver -L secureip -L xpm ^
  --snapshot RTDS_REAL_BACKEND_ELAB ^
  real_backend_work_64bit.rtds_ddr4_backend real_backend_work_64bit.glbl ^
  > reports\compile\real_backend_xelab.log 2>&1
if errorlevel 1 exit /b 1
echo RTDS_DDR4_REAL_BACKEND_COMPILE_ELABORATE_PASS
