@echo off
echo =======================================================
echo 🚀 Launching SuperWomen Mobility Platform Ecosystem
echo =======================================================

echo 1. Starting Core Rapido Engine (Port 5000)...
start "SuperWomen Core Backend" cmd /k "cd backend && node src/app.js"

echo 2. Starting Web Simulator & REST API Server (Port 3000)...
start "SuperWomen Web Server" cmd /k "node server.js"

timeout /t 2 /nobreak >nul

echo 3. Opening Interactive Dual Simulator in Browser...
start "" "http://localhost:3000"

echo 4. Opening Admin Operations Dashboard...
start "" "http://localhost:3000/admin-panel/"

echo =======================================================
echo ✅ SuperWomen Services are Live!
echo - Core Backend API: http://localhost:5000
echo - Interactive Simulator: http://localhost:3000
echo - Admin Operations Console: http://localhost:3000/admin-panel/
echo - Captain Flutter Web: http://localhost:8081
echo - Rider Flutter Web: http://localhost:8082
echo - Android APKs: apks/CaptainSuperWomen.apk & apks/SuperWomenRider.apk
echo =======================================================
pause
