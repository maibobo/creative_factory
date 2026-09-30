@echo off
setlocal
set "CASE_NAME=%~1"
set "CASE_VALID="
for %%C in (1g ring axi axi_tail rx_fifo regs tx) do if /I "%CASE_NAME%"=="%%C" set "CASE_VALID=1"
if not defined CASE_VALID (
    echo Usage: open_module_full_wave.cmd 1g^|ring^|axi^|axi_tail^|rx_fifo^|regs^|tx
    exit /b 2
)

for %%D in ("%~dp0..\..") do set "ROOT=%%~fD"
set "ROOT_FWD=%ROOT:\=/%"
set "RUN_DIR=%ROOT%\regression\v201_runs\%CASE_NAME%\project\module_test.sim\sim_1\behav\xsim"
set "SNAPSHOT=tb_rtds_%CASE_NAME%_behav"
set "RTDS_WAVE_TOP=tb_rtds_%CASE_NAME%"
set "FULL_WDB=%RUN_DIR%\%SNAPSHOT%_full.wdb"
set "WAVE_TCL=%ROOT_FWD%/regression/batch_1g/full_wave_gui.tcl"

if not exist "%RUN_DIR%\xsim.dir\%SNAPSHOT%" (
    echo ERROR: simulation snapshot not found: %RUN_DIR%\xsim.dir\%SNAPSHOT%
    echo Run the module regression once before opening the full waveform.
    exit /b 3
)

cd /d "%RUN_DIR%"
echo Opening %CASE_NAME% with all traceable signals. The small test will rerun once.
call C:\Xilinx\Vivado\2020.2\bin\xsim.bat "%SNAPSHOT%" -gui -wdb "%FULL_WDB%" -tclbatch "%WAVE_TCL%"
exit /b %ERRORLEVEL%
