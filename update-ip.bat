@echo off
echo Getting current IP address...
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr "IPv4" ^| findstr "192.168"') do (
    set IP=%%i
    set IP=!IP: =!
    goto :found
)
:found
echo Current IP: %IP%

echo Updating app configuration...
powershell -Command "(Get-Content 'lib\config\app_config.dart') -replace 'http://192\.168\.\d+\.\d+:8080', 'http://%IP%:8080' | Set-Content 'lib\config\app_config.dart'"

echo IP updated to %IP%
echo Restarting backend...
cd backend
call auto-start.bat