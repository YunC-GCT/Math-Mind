@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title MindTrace OCR Service

cd /d "%~dp0"

echo ========================================
echo   MindTrace OCR Service v1.2
echo   Formula OCR + fallback text OCR
echo ========================================
echo.

echo [1/5] Checking Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Python was not found. Please install Python 3.10 or later.
    pause
    exit /b 1
)
for /f "tokens=*" %%v in ('python --version 2^>^&1') do set PYTHON_VERSION=%%v
echo       !PYTHON_VERSION!

echo.
echo [2/5] Checking port 8000...
set PORT_BUSY=
for /f "tokens=5" %%p in ('netstat -ano ^| findstr /R /C:":8000 .*LISTENING"') do (
    set PORT_BUSY=%%p
)
if defined PORT_BUSY (
    echo [ERROR] Port 8000 is already used by process !PORT_BUSY!.
    echo Close the old OCR service, or stop that process, then run this script again.
    pause
    exit /b 1
)
echo       Port 8000 is available.

echo.
echo [3/5] Checking fallback text OCR...
if not exist "C:\Program Files\Tesseract-OCR\tesseract.exe" (
    echo [WARN] Tesseract was not found in the default path.
    echo        Server fallback text OCR may be unavailable.
) else (
    echo       Tesseract is installed.
)

echo.
echo [4/5] Installing Python dependencies...
if not exist "requirements.txt" (
    echo [ERROR] requirements.txt was not found.
    pause
    exit /b 1
)
pip install -r requirements.txt -q
if errorlevel 1 (
    echo [ERROR] Dependency installation failed. Check network and Python environment.
    pause
    exit /b 1
)
echo       Dependencies are ready.

echo.
echo [5/5] Detecting LAN IPv4 address...
set LAN_IP=
for /f "usebackq tokens=*" %%i in (`powershell -NoProfile -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -notlike '127.*' -and $_.PrefixOrigin -ne 'WellKnown' } | Sort-Object InterfaceMetric | Select-Object -First 1 -ExpandProperty IPAddress"`) do (
    set LAN_IP=%%i
)
if not defined LAN_IP (
    set LAN_IP=YOUR_PC_LAN_IP
)

echo.
echo ========================================
echo   Service URL:     http://localhost:8000
echo   LAN URL:         http://!LAN_IP!:8000
echo.
echo   Enter this in the app OCR setting:
echo   !LAN_IP!
echo.
echo   App OCR Endpoint:
echo   http://!LAN_IP!:8000/api/v1/ocr/recognize
echo.
echo   API Docs:        http://localhost:8000/docs
echo   Health Check:    http://localhost:8000/api/v1/formula/health
echo   Stop:            Ctrl+C
echo ========================================
echo.

start "" /b powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Sleep -Seconds 8; try { $r = Invoke-WebRequest -UseBasicParsing 'http://localhost:8000/api/v1/formula/health' -TimeoutSec 5; if ($r.StatusCode -eq 200) { Write-Host '[Health] OCR service is available.'; } else { Write-Host ('[Health] HTTP ' + $r.StatusCode); } } catch { Write-Host ('[Health] Failed: ' + $_.Exception.Message); }"

python -c "from fastapi import FastAPI; import uvicorn; from formula_api import router, ocr_router; app=FastAPI(title='MindTrace OCR Service'); app.include_router(router, prefix='/api/v1'); app.include_router(ocr_router, prefix='/api/v1'); uvicorn.run(app, host='0.0.0.0', port=8000, log_level='info')"

echo.
echo OCR service stopped.
pause
