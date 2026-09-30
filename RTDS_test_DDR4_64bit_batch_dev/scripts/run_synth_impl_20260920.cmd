@echo off
setlocal
cd /d C:\project\RTDS\DDR\RTDS_test_DDR4_64bit_batch_dev
echo [%date% %time%] RTDS_SYNTH_IMPL_LAUNCH
C:\Xilinx\Vivado\2020.2\bin\vivado.bat -mode batch -source scripts\run_synth_impl_20260920.tcl -log reports\impl_20260920\vivado.log -journal reports\impl_20260920\vivado.jou
set RC=%ERRORLEVEL%
echo [%date% %time%] RTDS_SYNTH_IMPL_EXIT=%RC%
exit /b %RC%
