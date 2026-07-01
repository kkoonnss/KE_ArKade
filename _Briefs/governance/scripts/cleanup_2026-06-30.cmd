@echo off
REM ============================================================
REM KE_ArKade — Governance cleanup script (2026-06-30)
REM
REM Run from any directory. Uses absolute paths.
REM
REM This script does what the bash sandbox can't:
REM   1) Hard-deletes 8 stale lock files (their tickets are done)
REM   2) Moves ~100 throwaway recovery scripts at repo root into
REM      scratch\recovery-2026-06-28\ (NOT into git — .gitignore catches it)
REM   3) Moves diagnostic dumps and recovery artifacts into the same scratch
REM   4) Stages a git commit for the cleanup
REM
REM Safe to re-run — every step checks existence first.
REM Nothing in app\, content\, vault\30-tasks\, vault\50-schemas\, or
REM _Briefs\governance\ is touched.
REM ============================================================

setlocal enabledelayedexpansion

set REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade

echo.
echo === KE_ArKade governance cleanup ===
echo Repo: %REPO%
echo.

cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

REM ----- Step 1: Delete 8 stale lock files -----
echo Step 1: Releasing stale locks ^(8 carts + shared-adapters^)
for %%L in (cart-asteroids cart-frogger cart-galaga cart-gta cart-on_track cart-paperboy cart-rampage shared-adapters) do (
  if exist "vault\35-locks\%%L.md" (
    del /q "vault\35-locks\%%L.md"
    echo   deleted: vault\35-locks\%%L.md
  ) else (
    echo   already gone: vault\35-locks\%%L.md
  )
)
echo.

REM ----- Step 2: Create scratch destination -----
echo Step 2: Preparing scratch\recovery-2026-06-28\
if not exist "scratch\recovery-2026-06-28" (
  mkdir "scratch\recovery-2026-06-28"
  echo   created: scratch\recovery-2026-06-28\
) else (
  echo   already exists: scratch\recovery-2026-06-28\
)
echo.

REM ----- Step 3: Move throwaway recovery scripts -----
echo Step 3: Moving throwaway scripts to scratch
for %%P in (fix_*.py patch_*.py recover*.py stitch*.py port_hub*.py rebuild_*.py refactor_*.py implement_*.py integrate_*.py tile_*.py clean_*.py smart_*.py visual_*.py add_multiplayer.py add_preview_menu.py gap_fill.py gen_seed.py find_main_gd_history.py debug_runner.py remove_duplicate.py) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 4: Move recovery artifacts -----
echo Step 4: Moving recovery artifacts to scratch
for %%P in (recovered_*.gd stitched_*.gd main_backup.gd main_dump*.txt extracted_funcs.txt recover_log.txt) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 5: Move diagnostic dumps -----
echo Step 5: Moving diagnostic dumps to scratch
for %%P in (*_err.txt *_out.txt *_err.log *_out.log godot_log.txt run_test.txt syntax_err*.txt syntax_out*.txt pg_err*.txt pg_out*.txt) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
REM Numbered err/out files (hub_err2.txt etc.)
for %%P in (*_err2.txt *_err3.txt *_err4.txt *_err5.txt *_err6.txt *_err7.txt *_err8.txt *_err9.txt *_err10.txt) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
for %%P in (*_out2.txt *_out3.txt *_out4.txt *_out5.txt *_out6.txt *_out7.txt *_out8.txt *_out9.txt *_out10.txt) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 6: Move test scaffolds at repo root -----
echo Step 6: Moving repo-root test scaffolds to scratch
for %%P in (test_crash.gd test_load.gd test_loader.gd test_repo_root.gd test_pacman_gal.gd test_dk_classic.gd) do (
  if exist "%%P" (
    move /y "%%P" "scratch\recovery-2026-06-28\" >nul && echo   moved: %%P
  )
)
echo.

REM ----- Step 7: Git status check -----
echo Step 7: Current git status ^(post-cleanup, before commit^)
git status -s
echo.

REM ----- Step 8: Stage + commit the cleanup -----
echo Step 8: Staging and committing the cleanup
git add .gitignore vault/35-locks/ vault/40-agent-runs/ _Briefs/governance/ 2>nul
git add -A 2>nul
git commit -m "governance: cleanup pass + governance pack landed" -m "- Released 8 stale lock files (their tickets are done)" -m "- Moved ~100 throwaway recovery scripts + dumps into scratch/recovery-2026-06-28/" -m "- Patched .gitignore to keep them out of git going forward" -m "- Wrote retrospective recovery receipt for Jun 28-30 hub corruption" -m "- Wrote _Briefs/governance/ pack (8 docs)" -m "" -m "See _Briefs/governance/00_README.md and vault/40-agent-runs/recovery_hub_main_gd_2026-06-28.md"
echo.

REM ----- Step 9: Tag today's daily snapshot -----
echo Step 9: Tagging daily snapshot
git tag daily/2026-06-30
echo   tagged: daily/2026-06-30
echo.

echo === Done. ===
echo.
echo Next steps:
echo   1) Run: git log --oneline -5    ^(verify the cleanup commit landed^)
echo   2) Run: git status -s            ^(should be empty^)
echo   3) Read: _Briefs\HANDOFF.md      ^(updated pickup state^)
echo.

endlocal
