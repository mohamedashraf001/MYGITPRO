@echo off
setlocal EnableDelayedExpansion
title Smart SQL Deployment (Strict Versioning)

echo ==================================================
echo SQL Deployment (Strict Version Checking)
echo ==================================================

set "SERVER=DESKTOP-5ESJKMQ"
echo Server: %SERVER%

REM ==================================================
REM 1. Require Database Name (No Defaults)
REM ==================================================
set "DATABASE="
set /p "DATABASE=Enter Database Name: "

if "%DATABASE%"=="" (
    echo [ERROR] No database name entered! Cancelled.
    pause
    exit /b 1
)

REM ==================================================
REM Select File using Windows GUI
REM ==================================================
echo.
echo Please select the SQL file...
set "SQLFILE="
for /f "delims=" %%I in ('powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select SQL Script'; $d.Filter = 'SQL Files (*.sql)|*.sql|All Files (*.*)|*.*'; $d.Multiselect = $false; if ($d.ShowDialog() -eq 'OK') { Write-Output $d.FileName }"') do set "SQLFILE=%%I"

if not defined SQLFILE (
    echo [ERROR] No file selected. Cancelled.
    pause
    exit /b 1
)

REM ==================================================
REM Extract Version and Script Name securely
REM ==================================================
for %%I in ("%SQLFILE%") do set "FULL_FILENAME=%%~nI"

set "VERSION="
set "SCRIPT_NAME=No_Description"

REM Split the filename by the FIRST underscore "_"
for /f "tokens=1* delims=_" %%A in ("%FULL_FILENAME%") do (
    set "VERSION=%%A"
    if not "%%B"=="" set "SCRIPT_NAME=%%B"
)

set "LOG=%~dp0sql-deploy-%VERSION%.log"

echo.
echo ==================================================
echo [SUMMARY]
echo Server:      %SERVER%
echo Database:    %DATABASE%
echo Version:     %VERSION%      (Used for Duplicate Check)
echo Script Name: %SCRIPT_NAME%  (Saved for Info Only)
echo File:        %SQLFILE%
echo ==================================================
echo.

REM ==================================================
REM Check Database Existence & Target Routing
REM ==================================================
set "DB_CHECK_FILE=%TEMP%\db-check-%RANDOM%.txt"
sqlcmd -S "%SERVER%" -E -C -d master -h -1 -W -Q "SET NOCOUNT ON; IF EXISTS (SELECT 1 FROM sys.databases WHERE name = '%DATABASE%') PRINT 'DB_EXISTS' ELSE PRINT 'DB_NOT_EXISTS';" > "%DB_CHECK_FILE%" 2>&1

set "DB_STATE="
for /f "usebackq delims=" %%I in ("%DB_CHECK_FILE%") do set "DB_STATE=%%I"
set "DB_STATE=!DB_STATE: =!"
del "%DB_CHECK_FILE%" >nul 2>&1

set "TARGET_DB=%DATABASE%"

if /I "!DB_STATE!"=="DB_NOT_EXISTS" (
    echo [INFO] Database '%DATABASE%' is NEW. Script will run against 'master'.
    set "TARGET_DB=master"
) else (
    echo [INFO] Database '%DATABASE%' EXISTS. Checking version history...
    
    REM Check migration_version Table & strict VERSION
    set "VER_CHECK_FILE=%TEMP%\ver-check-%RANDOM%.txt"
    set "SQL_CHECK=SET NOCOUNT ON; IF OBJECT_ID('dbo.migration_version', 'U') IS NOT NULL BEGIN IF EXISTS (SELECT 1 FROM dbo.migration_version WHERE version = '%VERSION%') PRINT 'VER_EXISTS' ELSE PRINT 'VER_NEW' END ELSE PRINT 'TABLE_NOT_EXISTS';"
    
    sqlcmd -S "%SERVER%" -E -C -d "%DATABASE%" -h -1 -W -Q "!SQL_CHECK!" > "!VER_CHECK_FILE!" 2>&1
    
    set "VER_STATE="
    for /f "usebackq delims=" %%I in ("!VER_CHECK_FILE!") do set "VER_STATE=%%I"
    set "VER_STATE=!VER_STATE: =!"
    del "!VER_CHECK_FILE!" >nul 2>&1

    if /I "!VER_STATE!"=="VER_EXISTS" (
        echo ==============================================
        echo [ABORTED] Version '%VERSION%' ALREADY EXISTS in %DATABASE%!
        echo No changes applied to prevent duplication.
        echo ==============================================
        pause
        exit /b 1
    )
    echo [INFO] Version '%VERSION%' is new. Proceeding...
)

REM ==================================================
REM Confirm execution
REM ==================================================
set "CONFIRM="
echo.
set /p "CONFIRM=Type Y to execute the script on [!TARGET_DB!]: "
if /I not "%CONFIRM%"=="Y" (
    echo Cancelled by user.
    pause
    exit /b 1
)

REM ==================================================
REM Execute Developer's SQL Script
REM ==================================================
echo.
echo [RUNNING] Applying %SQLFILE%...
sqlcmd -S "%SERVER%" -E -C -b -d "!TARGET_DB!" -i "%SQLFILE%" > "%LOG%" 2>&1

set "RESULT=!ERRORLEVEL!"
if not "!RESULT!"=="0" (
    echo ==============================================
    echo [FAILED] SQL Execution Error:
    echo ==============================================
    type "%LOG%"
    pause
    exit /b !RESULT!
)

REM ==================================================
REM Register Version (Fixed: Split Schema & Data)
REM ==================================================
echo [SUCCESS] SQL script applied. Registering version '%VERSION%' in database %DATABASE%...

REM الخطوة الأولى: التجهيز (إنشاء الجدول أو إضافة العمود لو مش موجودين)
set "SQL_SCHEMA=USE [%DATABASE%]; IF OBJECT_ID('dbo.migration_version', 'U') IS NULL BEGIN CREATE TABLE dbo.migration_version (version NVARCHAR(50) PRIMARY KEY, script_name NVARCHAR(255), applied_at DATETIME DEFAULT GETDATE()); END ELSE BEGIN IF COL_LENGTH('dbo.migration_version', 'script_name') IS NULL ALTER TABLE dbo.migration_version ADD script_name NVARCHAR(255); END;"
sqlcmd -S "%SERVER%" -E -C -b -d master -Q "!SQL_SCHEMA!" >> "%LOG%" 2>&1

REM الخطوة الثانية: الإضافة الفعالة (تسجيل البيانات)
set "SQL_INSERT=USE [%DATABASE%]; INSERT INTO dbo.migration_version (version, script_name) VALUES ('%VERSION%', '%SCRIPT_NAME%');"
sqlcmd -S "%SERVER%" -E -C -b -d master -Q "!SQL_INSERT!" >> "%LOG%" 2>&1

if not "!ERRORLEVEL!"=="0" (
    echo [ERROR] Failed to register version in migration_version table. Check logs.
    type "%LOG%"
    pause
    exit /b 1
)

echo ==============================================
echo [COMPLETED] Deployment and version registration successful!
echo ==============================================
pause
exit /b 0