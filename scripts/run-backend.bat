@echo off
setlocal
cd /d "%~dp0..\backend\fastapi-project"
.venv\Scripts\python.exe -m fastapi dev main.py --port 8000