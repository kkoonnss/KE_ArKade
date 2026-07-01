@echo off
REM ============================================================
REM KE_ArKade — Governance cleanup ADDENDUM (2026-06-30, second pass)
REM
REM Catches cruft that the AG hub-fix session left behind AFTER the
REM first cleanup ran. Also removes the orchestrator's stray
REM sandbox test file.
REM
REM Safe to re-run.
REM ============================================================

setlocal enabledelayedexpansion
set REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade

echo.
echo === KE_ArKade cleanup addendum ===
echo Repo: %REPO%
echo.

cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

REM ----- Step 1: Move new repo-root throwaway scripts to scratch -----
echo Step 1: Moving new throwaway scripts to scratch\recovery-2026-06-28\
for %%P in (rewrite_*.py safe_rewrite*.py tweak_*.py) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 2: Move hub-lane scratch to scratch -----
echo Step 2: Moving hub-lane scratch to scratch\recovery-2026-06-28\
for %%P in (app\hub\main_backup.gd app\hub\main_dump.txt app\hub\main_dump2.txt app\hub\test_hub.gd) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 3: Remove orchestrator's stray sandbox test file -----
echo Step 3: Removing orchestrator sandbox artifact
if exist "vault\35-locks\_test_write.tmp" (
  del /q "vault\35-locks\_test_write.tmp" && echo   deleted: vault\35-locks\_test_write.tmp
)
echo.

REM ----- Step 4: Show git status -----
echo Step 4: git status
git status -s
echo.

REM ----- Step 5: Commit -----
echo Step 5: Staging + commit
git add -A
git commit -m "governance: cleanup addendum + new hub scene-ordering ticket" -m "- Moved rewrite_hub.py, safe_rewrite.py, tweak_ui2.py to scratch/recovery-2026-06-28/" -m "- Moved app/hub/main_backup.gd, main_dump*.txt, test_hub.gd to scratch/recovery-2026-06-28/" -m "- Removed orchestrator sandbox artifact vault/35-locks/_test_write.tmp" -m "- Added .gitignore patterns for rewrite_*.py, safe_rewrite*.py, tweak_*.py" -m "- Reconstructed AG hub-thumbnails/favorites receipt in vault/40-agent-runs/" -m "- Issued TASK-INT-hub-scene-ordering-classic-first"
echo.

echo === Done. ===
echo.

endlocal
