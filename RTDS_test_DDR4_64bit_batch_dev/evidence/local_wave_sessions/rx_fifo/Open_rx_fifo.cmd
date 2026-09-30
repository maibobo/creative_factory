@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\scripts\Open-LocalWave.ps1" -Case rx_fifo
if errorlevel 1 pause
