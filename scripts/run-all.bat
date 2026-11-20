@echo off
setlocal
start "MyMoneyUG Backend" cmd /k "%~dp0run-backend.bat"
start "MyMoneyUG Frontend" cmd /k "%~dp0run-frontend.bat"