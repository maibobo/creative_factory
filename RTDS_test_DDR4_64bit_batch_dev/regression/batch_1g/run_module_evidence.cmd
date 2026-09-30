@echo off
setlocal
set "CASE_NAME=%~1"
set "CASE_VALID="
for %%C in (1g ring axi axi_tail rx_fifo regs tx) do if /I "%CASE_NAME%"=="%%C" set "CASE_VALID=1"
if not defined CASE_VALID (
    echo Usage: run_module_evidence.cmd 1g^|ring^|axi^|axi_tail^|rx_fifo^|regs^|tx
    exit /b 2
)

for %%D in ("%~dp0..\..") do set "ROOT=%%~fD"
set "ROOT_FWD=%ROOT:\=/%"
set "RUN_DIR=%ROOT%\regression\v201_runs\%CASE_NAME%\project\module_test.sim\sim_1\behav\xsim"
set "SNAPSHOT=tb_rtds_%CASE_NAME%_behav"
set "EVIDENCE=%ROOT%\evidence\v201_quick_wave_draft\raw\%CASE_NAME%"
set "EVIDENCE_FWD=%ROOT_FWD%/evidence/v201_quick_wave_draft/raw/%CASE_NAME%"
set "RTDS_WAVE_TOP=tb_rtds_%CASE_NAME%"
set "RTDS_VCD_PATH=%EVIDENCE_FWD%/%CASE_NAME%_full.vcd"
set "RTDS_WCFG_PATH=%EVIDENCE_FWD%/%CASE_NAME%_all_signals.wcfg"

if not exist "%RUN_DIR%\xsim.dir\%SNAPSHOT%" (
    echo ERROR: snapshot not found: %RUN_DIR%\xsim.dir\%SNAPSHOT%
    exit /b 3
)
if not exist "%EVIDENCE%" mkdir "%EVIDENCE%"

cd /d "%RUN_DIR%"
call C:\Xilinx\Vivado\2020.2\bin\xsim.bat "%SNAPSHOT%" ^
  -wdb "%EVIDENCE%\%CASE_NAME%_full.wdb" ^
  -log "%EVIDENCE%\xsim_%CASE_NAME%.log" ^
  -tclbatch "%ROOT_FWD%/regression/batch_1g/record_module_evidence.tcl"
set "RC=%ERRORLEVEL%"
echo RTDS_EVIDENCE_CASE=%CASE_NAME% EXIT=%RC%
exit /b %RC%
