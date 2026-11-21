@echo off
cd /d "%~dp0"
echo === Kovra VPN setup ===
where flutter >nul 2>nul
if errorlevel 1 (
  echo.
  echo Flutter SDK was not found on this PC.
  echo Install it from flutter.dev, add C:\flutter\bin to PATH, then double-click this file again.
  pause
  exit /b 1
)
echo Creating Android and iOS project files...
call flutter create --org com.yourstudio --project-name skylane_vpn --platforms android,ios .
call flutter pub get
echo Opening the project in Android Studio...
start "" "C:\Program Files\Android\Android Studio\bin\studio64.exe" "%~dp0."
echo Done. You can close this window.
pause
