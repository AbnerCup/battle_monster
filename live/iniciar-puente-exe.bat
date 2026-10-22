@echo off
REM Puente TikFinity -> modo torneo de Game.exe (puerto 8081). Abre TikFinity antes.
cd /d "%~dp0"
if not exist node_modules ( call npm install || (pause & exit /b 1) )
call npm run bridge
pause
