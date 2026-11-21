@echo off
cd /d "%~dp0"
echo === Running Kovra VPN on the connected phone / emulator ===
echo (first build takes a few minutes)  Keys: r = reload, R = restart, q = quit
call flutter run
pause
