@echo off
setlocal EnableExtensions

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..") do set "REPO=%%~fI"
set "LOG_DIR=%SCRIPT_DIR%logs"
set "LOG_FILE=%LOG_DIR%\push_backup.log"
set "MODE=%~1"
if "%MODE%"=="" set "MODE=manual"

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>nul

call :log "=== push_backup start mode=%MODE% repo=%REPO% ==="

where git >nul 2>nul
if errorlevel 1 (
  call :log "ERROR: git is not on PATH."
  echo ERROR: git is not on PATH.
  exit /b 1
)

git -C "%REPO%" rev-parse --is-inside-work-tree >nul 2>nul
if errorlevel 1 (
  call :log "ERROR: %REPO% is not a git repo."
  echo ERROR: %REPO% is not a git repo.
  exit /b 1
)

git -C "%REPO%" remote get-url origin >nul 2>nul
if errorlevel 1 (
  call :log "WARN: origin is not configured yet. Nothing to push."
  if /I "%MODE%"=="manual" echo WARN: origin is not configured yet. Nothing to push.
  exit /b 0
)

call :run_push "git push origin master"
if errorlevel 1 goto :push_failed

call :run_push "git push origin --tags"
if errorlevel 1 goto :push_failed

call :log "SUCCESS: pushed master and tags."
if /I "%MODE%"=="manual" echo Backup push succeeded.
exit /b 0

:push_failed
call :log "WARN: push failed. Local commits are intact; rerun push_backup.cmd after the network/remote issue is fixed."
if /I "%MODE%"=="manual" (
  echo WARN: push failed. Local commits are intact.
  echo Rerun _Briefs\governance\scripts\push_backup.cmd after the network or remote issue is fixed.
  exit /b 1
)
exit /b 0

:run_push
set "CMD=%~1"
call :log "RUN: %CMD%"
cmd /c "%CMD%" >> "%LOG_FILE%" 2>&1
set "RC=%ERRORLEVEL%"
call :log "RC=%RC% for %CMD%"
exit /b %RC%

:log
>> "%LOG_FILE%" echo [%DATE% %TIME%] %~1
exit /b 0
