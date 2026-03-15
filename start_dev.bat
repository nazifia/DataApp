@echo off
echo ========================================
echo  ADP Nigeria — Dev Launcher
echo ========================================

:: ── Paths ──
set ROOT=%~dp0
set VENV=%ROOT%venv\Scripts
set BACKEND=%ROOT%backend
set FLUTTER_APP=%ROOT%airtime_data_app
set PORT=8001

:: ── Step 1: Ensure firewall allows emulator traffic on dev port ──
echo [1/4] Ensuring Windows Firewall allows port %PORT%...
netsh advfirewall firewall show rule name="ADP Dev Port %PORT%" >nul 2>&1
if errorlevel 1 (
    netsh advfirewall firewall add rule name="ADP Dev Port %PORT%" dir=in action=allow protocol=TCP localport=%PORT% >nul 2>&1
    if errorlevel 1 (
        echo       [WARN] Could not add firewall rule (run as Administrator to fix).
        echo       If the emulator cannot connect, open Windows Defender Firewall
        echo       and allow inbound TCP on port %PORT%.
    ) else (
        echo       Firewall rule added for port %PORT%.
    )
) else (
    echo       Firewall rule already exists.
)

:: ── Step 2: Kill any existing backend on the dev port ──
echo [2/4] Checking for existing backend on port %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% " ^| findstr "LISTENING" 2^>nul') do (
    echo       Stopping old process (PID %%a)...
    taskkill /PID %%a /F >nul 2>&1
)

:: ── Step 3: Start backend server ──
echo [3/4] Starting backend server on port %PORT%...
start "ADP Backend" /min cmd /c "cd /d %BACKEND% && %VENV%\uvicorn main:app --host 0.0.0.0 --port %PORT% --reload"

:: Wait for backend to be ready
echo       Waiting for backend to start...
:WAIT_LOOP
timeout /t 1 /nobreak >nul
curl -s http://localhost:%PORT%/health >nul 2>&1
if errorlevel 1 goto WAIT_LOOP
echo       Backend is up!

:: ── Step 4: Launch Flutter app ──
echo [4/4] Launching Flutter app...
cd /d %FLUTTER_APP%
flutter run

echo.
echo ========================================
echo  Flutter app closed. Backend still running.
echo  Close the "ADP Backend" window to stop it.
echo ========================================
pause
