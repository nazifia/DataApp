@echo off
echo ========================================
echo  ADP Nigeria — Dev Launcher
echo ========================================

:: ── Paths ──
set ROOT=%~dp0
set VENV=%ROOT%venv\Scripts
set BACKEND=%ROOT%backend
set FLUTTER_APP=%ROOT%airtime_data_app

:: ── Step 1: Kill any existing backend on port 8000 ──
echo [1/3] Checking for existing backend on port 8000...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":8000 " ^| findstr "LISTENING" 2^>nul') do (
    echo       Stopping old process (PID %%a)...
    taskkill /PID %%a /F >nul 2>&1
)

:: ── Step 2: Start backend server ──
echo [2/3] Starting backend server...
start "ADP Backend" /min cmd /c "cd /d %BACKEND% && %VENV%\uvicorn main:app --host 0.0.0.0 --port 8000 --reload"

:: Wait for backend to be ready
echo       Waiting for backend to start...
:WAIT_LOOP
timeout /t 1 /nobreak >nul
curl -s http://localhost:8000/health >nul 2>&1
if errorlevel 1 goto WAIT_LOOP
echo       Backend is up!

:: ── Step 3: Launch Flutter app ──
echo [3/3] Launching Flutter app...
cd /d %FLUTTER_APP%
%VENV%\.. 2>nul
flutter run

echo.
echo ========================================
echo  Flutter app closed. Backend still running.
echo  Close the "ADP Backend" window to stop it.
echo ========================================
pause
