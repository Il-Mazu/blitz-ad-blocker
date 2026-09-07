@echo off
setlocal
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-Blitz-AdBlock.ps1"
if errorlevel 1 pause
