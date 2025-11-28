@echo off
setlocal enabledelayedexpansion
echo ========================================
echo    Smart Doorbell - Auto Startup
echo ========================================

echo [1/3] Getting current IP address...
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4" ^| findstr "192.168"') do (
    set IP=%%i
    set IP=!IP: =!
    goto :found
)
:found
echo Current IP: !IP!

echo [2/3] Updating app configuration...
powershell -Command "(Get-Content 'lib\config\app_config.dart') -replace 'http://192\.168\.\d+\.\d+:8080', 'http://!IP!:8080' | Set-Content 'lib\config\app_config.dart'"

echo [3/3] Starting backend server...
cd backend
start "Backend Server" cmd /k "auto-start.bat"
cd ..

echo ========================================
echo ✅ Setup Complete!
echo 📡 Backend: http://!IP!:8080
echo 📱 Now run: flutter run
echo ========================================
pause