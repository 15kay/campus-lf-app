@echo off
echo Starting admin web server...
cd build/web
python -m http.server 8080
pause