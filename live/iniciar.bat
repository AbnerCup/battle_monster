@echo off
REM Inicia el juego para TikTok LIVE en esta PC (doble clic).
REM 1) Instala dependencias la primera vez  2) Importa el contenido del juego
REM 3) Compila  4) Abre el servidor local en http://localhost:4173
cd /d "%~dp0"
where node >nul 2>nul || (echo Falta Node.js 20 o superior: https://nodejs.org & pause & exit /b 1)
if not exist node_modules (
  echo Instalando dependencias...
  call npm install || (pause & exit /b 1)
)
call npm run build || (pause & exit /b 1)
echo.
echo  Panel de pruebas:  http://localhost:4173/
echo  Para OBS:          http://localhost:4173/?obs=1   (1080 x 1920)
echo.
start "" http://localhost:4173/
call npm start
