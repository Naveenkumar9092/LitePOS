@echo off
echo ===================================================
echo   LitePOS Database Setup & Verification
echo ===================================================
echo.

echo [*] Starting SQL Server LocalDB instance...
sqllocaldb start MSSQLLocalDB

echo [*] Verifying LocalDB instance state...
sqllocaldb info MSSQLLocalDB

echo.
echo [*] Checking database 'LitePOS_BillingDb_Dev'...
sqlcmd -S "(localdb)\MSSQLLocalDB" -Q "IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'LitePOS_BillingDb_Dev') CREATE DATABASE [LitePOS_BillingDb_Dev];"

echo.
echo [OK] Database is ready for LitePOS operation!
echo ===================================================
pause

