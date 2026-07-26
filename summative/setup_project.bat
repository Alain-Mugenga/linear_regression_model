@echo off
setlocal
cd /d "%~dp0"
uv lock --refresh --default-index https://pypi.org/simple
if errorlevel 1 exit /b 1
uv sync --locked --default-index https://pypi.org/simple
