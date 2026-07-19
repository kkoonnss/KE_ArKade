@echo off
setlocal EnableExtensions
cd /d "%~dp0..\..\.."

set "LOCKFILE=.git\index.lock"
set "HIST=.git\_History"

if not exist "%LOCKFILE%" (
  echo No index.lock present. Nothing to do.
  goto :done
)

echo Found %LOCKFILE%.
echo Checking for a live git process before touching it...

tasklist /FI "IMAGENAME eq git.exe" 2>nul | find /I "git.exe" >nul
if %ERRORLEVEL%==0 (
  echo A git.exe process IS currently running.
  echo Refusing to move the lock automatically - this may be a real in-progress commit.
  echo If you are certain no git operation is active, delete or move the lock manually.
  goto :done
)

if not exist "%HIST%" mkdir "%HIST%"

for /f %%T in ('powershell -NoProfile -Command "Get-Date -Format yyyyMMdd_HHmmss"') do set "TS=%%T"
move /Y "%LOCKFILE%" "%HIST%\index.lock.moved_%TS%" >nul

if exist "%LOCKFILE%" (
  echo WARNING: move did not succeed, lock file still present.
) else (
  echo Moved stale lock to %HIST%\index.lock.moved_%TS%
)

:done
echo.
echo === git status ===
git status
pause
