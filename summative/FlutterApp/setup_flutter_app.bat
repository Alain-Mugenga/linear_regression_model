@echo off
setlocal
cd /d "%~dp0"

where flutter >nul 2>&1
if errorlevel 1 (
    echo Flutter was not found in PATH.
    echo Install Flutter, restart VS Code, and run this file again.
    exit /b 1
)

if not exist "web" (
    flutter create . --project-name african_football_predictor --platforms=android,web,windows
    if errorlevel 1 exit /b 1
)

flutter pub get
if errorlevel 1 exit /b 1

echo.
echo Setup complete.
echo Run: flutter run -d chrome
