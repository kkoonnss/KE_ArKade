@echo off
REM ============================================================
REM KE_ArKade - Install git safety + backup hooks (2026-07-01)
REM
REM Installs:
REM   - a pre-commit hook that catches the exact class of bug
REM     that caused the Jun 28-30 corruption
REM   - a post-commit hook that starts push_backup.cmd in the background
REM     so ticket-close commits auto-push when origin is configured
REM
REM Safe to re-run.
REM ============================================================

setlocal
set "REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade"
set "SCRIPT_DIR=%~dp0"
set "PRE_TEMPLATE=%SCRIPT_DIR%pre-commit.template"
set "POST_TEMPLATE=%SCRIPT_DIR%post-commit.template"

cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

echo.
echo === Installing git safety + backup hooks ===
echo Repo: %REPO%
echo.

if not exist ".git\hooks" (
  echo   ERROR: .git\hooks not found. Not a git repo?
  exit /b 1
)

if not exist "%PRE_TEMPLATE%" (
  echo   ERROR: missing template %PRE_TEMPLATE%
  exit /b 1
)

if not exist "%POST_TEMPLATE%" (
  echo   ERROR: missing template %POST_TEMPLATE%
  exit /b 1
)

copy /y "%PRE_TEMPLATE%" ".git\hooks\pre-commit" >nul || exit /b 1
echo   installed: .git\hooks\pre-commit

copy /y "%POST_TEMPLATE%" ".git\hooks\post-commit" >nul || exit /b 1
echo   installed: .git\hooks\post-commit
echo.

echo === Testing hook exists ===
if exist ".git\hooks\pre-commit" (
  echo   OK: pre-commit hook present
) else (
  echo   FAIL: pre-commit hook missing
  exit /b 1
)

if exist ".git\hooks\post-commit" (
  echo   OK: post-commit hook present
) else (
  echo   FAIL: post-commit hook missing
  exit /b 1
)

echo.
echo === Done. ===
echo Test the hook by trying a bad commit deletion from a large file.
echo Use push_backup.cmd manually if you want to force an immediate backup push.

endlocal
