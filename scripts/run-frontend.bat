@echo off
setlocal
cd /d "%~dp0..\frontend"
flutter run -d web-server --web-port=8080