@echo off
setlocal
cd /d "%~dp0..\backend"
.venv\Scripts\python.exe -m fastapi dev main.py --port 8000