@echo off
setlocal EnableDelayedExpansion
title Smart SQL Rollback

echo ==================================================
echo SQL Rollback Execution
echo ==================================================

set "SERVER=DESKTOP-5ESJKMQ"
echo Server: %SERVER%

REM ==================================================
REM 1. Database Input
REM ==================================================
set "DATABASE="
set /p "DATABASE=Enter Database Name to ROLLBACK: "

REM هنا كان الخطأ: تم التعديل لـ ==
if "%DATABASE%"=="" (
    echo [ERROR] No database name entered! Cancelled.
    pause
    exit /b 1
)

REM ==================================================
REM 2. Select Rollback File using Windows GUI
REM ==================================================
echo.
echo Please select the ROLLBACK SQL file...
set "SQLFILE="
for /f "delims=" %%I in ('powershell.exe -NoProfile -STA -Command "Add-Type -AssemblyName System.Windows.Forms; $d = New-Object System.Windows.Forms.OpenFileDialog; $d.Title = 'Select ROLLBACK SQL Script'; $d.Filter = 'SQL Files (*.sql)|*.sql|All Files (*.*)|*.*'; $d.Multiselect = $false; if ($d.ShowDialog() -eq 'OK') { Write-Output $d.FileName }"') do set "SQLFILE=%%I"

if not defined SQLFILE (
    echo [ERROR] No file selected. Cancelled.
    pause
    exit /b 1
)

REM ==================================================
REM 3. Extract Version from Filename
REM ==================================================
for %%I in ("%SQLFILE%") do set "FULL_FILENAME=%%~nI"

set "VERSION="
for /f "tokens=1* delims=_" %%A in ("%FULL_FILENAME%") do (
    set "VERSION=%%A"
)

set "LOG=%~dp0sql-rollback-%VERSION%.log"

echo.
echo ==================================================
echo [ROLLBACK SUMMARY]
echo Server:   %SERVER%
echo Database: %DATABASE%
echo Version:  %VERSION% (Will be checked and removed)
echo File:     %SQLFILE%
echo ==================================================
echo.

REM ==================================================
REM 4. Check if Database & Version Exist
REM ==================================================
set "VER_CHECK_FILE=%TEMP%\ver-check-%RANDOM%.txt"
set "SQL_CHECK=SET NOCOUNT ON; IF OBJECT_ID('dbo.migration_version', 'U') IS NOT NULL BEGIN IF EXISTS (SELECT 1 FROM dbo.migration_version WHERE version = '%VERSION%') PRINT 'VER_EXISTS' ELSE PRINT 'VER_NOT_FOUND' END ELSE PRINT 'TABLE_NOT_EXISTS';"

sqlcmd -S "%SERVER%" -E -C -d "%DATABASE%" -h -1 -W -Q "!SQL_CHECK!" > "%VER_CHECK_FILE%" 2>&1

set "VER_STATE="
for /f "usebackq delims=" %%I in ("%VER_CHECK_FILE%") do set "VER_STATE=%%I"
set "VER_STATE=!VER_STATE: =!"
del "%VER_CHECK_FILE%" >nul 2>&1

if not "!VER_STATE!"=="VER_EXISTS" (
    echo ==============================================
    echo [ABORTED] Version '%VERSION%' DOES NOT EXIST in database %DATABASE%!
    echo You cannot rollback a version that was never applied.
    echo ==============================================
    pause
    exit /b 1
)

echo [INFO] Version '%VERSION%' found in %DATABASE%. Proceeding with Rollback...

REM ==================================================
REM 5. Confirm Execution
REM ==================================================
set "CONFIRM="
echo.
set /p "CONFIRM=Type Y to execute ROLLBACK script on [%DATABASE%]: "
if /I not "%CONFIRM%"=="Y" (
    echo Cancelled by user.
    pause
    exit /b 1
)

REM ==================================================
REM 6. Execute Rollback SQL Script
REM ==================================================
echo.
echo [RUNNING] Applying %SQLFILE%...
sqlcmd -S "%SERVER%" -E -C -b -d "%DATABASE%" -i "%SQLFILE%" > "%LOG%" 2>&1

set "RESULT=!ERRORLEVEL!"
if not "!RESULT!"=="0" (
    echo ==============================================
    echo [FAILED] Rollback Execution Error:
    echo ==============================================
    type "%LOG%"
    pause
    exit /b !RESULT!
)

REM ==================================================
REM 7. Remove Version from History Table
REM ==================================================
echo [SUCCESS] Rollback script applied. Removing version '%VERSION%' from database %DATABASE%...

set "SQL_DELETE=USE [%DATABASE%]; DELETE FROM dbo.migration_version WHERE version = '%VERSION%';"
sqlcmd -S "%SERVER%" -E -C -b -d master -Q "!SQL_DELETE!" >> "%LOG%" 2>&1

if not "!ERRORLEVEL!"=="0" (
    echo [ERROR] Failed to remove version from migration_version table. Check logs.
    type "%LOG%"
    pause
    exit /b 1
)

echo ==============================================
echo [COMPLETED] Rollback and version removal successful!
echo ==============================================
pause
exit /b 0