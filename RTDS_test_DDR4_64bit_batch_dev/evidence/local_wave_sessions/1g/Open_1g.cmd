@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\..\scripts\Open-LocalWave.ps1" -Case 1g
if errorlevel 1 pause
