@echo off
echo ========================================================
echo          LITEPOS - High-Performance Billing POS
echo ========================================================
echo.

echo [*] Starting SQL Server LocalDB...
sqllocaldb start MSSQLLocalDB >nul 2>&1

echo [*] Launching LitePOS Backend Server on http://localhost:5270...
cd /d "%~dp0backend"
start "LitePOS Backend Service" /B BillingPOS.Api.exe --urls "http://localhost:5270"

echo [*] Waiting for server initialization...
timeout /t 3 /nobreak >nul

echo [*] Starting LitePOS Terminal Frontend...
cd /d "%~dp0..\..\billing_pos_app"
flutter run -d windows

echo.
echo [*] LitePOS session terminated.
echo ========================================================

