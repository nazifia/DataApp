@echo off
echo ============================================
echo  TopUpNaija — Phone Test Launcher
echo ============================================

set ROOT=%~dp0
set VENV=%ROOT%venv\Scripts
set BACKEND=%ROOT%backend
set PORT=8000
set SUBDOMAIN=topupnaija-adp
set TUNNEL_URL=https://%SUBDOMAIN%.loca.lt

:: ── Step 1: Kill anything on port 8000 ──
echo [1/3] Clearing port %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr ":%PORT% " ^| findstr "LISTENING" 2^>nul') do (
    taskkill /PID %%a /F >nul 2>&1
)

:: ── Step 2: Start backend bound to all interfaces ──
echo [2/3] Starting backend...
start "TopUpNaija Backend" /min cmd /c "cd /d %BACKEND% && %VENV%\uvicorn main:app --host 0.0.0.0 --port %PORT% --reload"

:: Wait for backend to be ready
:WAIT_BACKEND
timeout /t 1 /nobreak >nul
curl -s http://localhost:%PORT%/health >nul 2>&1
if errorlevel 1 goto WAIT_BACKEND
echo       Backend is up at http://localhost:%PORT%

:: ── Step 3: Start localtunnel ──
echo [3/3] Starting public tunnel...
echo.
echo ============================================
echo  Phone Test URL:
echo  %TUNNEL_URL%
echo.
echo  App is already configured to use this URL.
echo  Just make sure backend + this window are
echo  running when you test on your phone.
echo ============================================
echo.
echo  Press Ctrl+C to stop the tunnel.
echo.
lt --port %PORT% --subdomain %SUBDOMAIN%
