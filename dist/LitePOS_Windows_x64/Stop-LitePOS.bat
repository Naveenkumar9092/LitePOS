@echo off
echo ========================================================
echo          Stopping LitePOS Services
echo ========================================================
echo.

echo [*] Terminating BillingPOS.Api process...
taskkill /F /IM BillingPOS.Api.exe >nul 2>&1

echo [*] Terminating Flutter Terminal processes...
taskkill /F /IM billing_pos_app.exe >nul 2>&1

echo.
echo [OK] All LitePOS services cleanly stopped.
echo ========================================================
pause

