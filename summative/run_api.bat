@echo off
setlocal
cd /d "%~dp0"
uv run uvicorn API.prediction:app --reload
