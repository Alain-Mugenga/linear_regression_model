@echo off
setlocal
cd /d "%~dp0"
flutter pub get
if errorlevel 1 exit /b 1
flutter run -d chrome
