@echo off
REM ============================================================
REM KE_ArKade — Backup + GitHub audit (2026-07-01)
REM
REM Runs the full backup hygiene sweep:
REM   1. Commits current working tree (with governance-shaped message)
REM   2. Tags today's daily
REM   3. Tags this week's weekly
REM   4. Reports remote status
REM   5. If a remote is configured, pushes everything
REM
REM Safe to re-run.
REM ============================================================

setlocal enabledelayedexpansion
set REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade
cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

echo.
echo === KE_ArKade backup + GitHub audit ===
echo Repo: %REPO%
echo.

REM ----- Step 1: Show what's uncommitted -----
echo Step 1: Current uncommitted work
git status -s | find /c /v ""
echo files above
echo.

REM ----- Step 2: Commit the current working tree -----
echo Step 2: Committing working tree
git add -A
git commit -m "governance: snapshot working tree 2026-07-01" -m "Captures in-flight work across hub, shared, cartridges (SharedLoader dynamic-load fix and downstream adapter changes) before further edits. Standard daily hygiene commit per _Briefs/governance/07_GIT_GOVERNANCE.md §2.2."
if errorlevel 1 (
  echo   nothing to commit ^(clean tree^) — OK
) else (
  echo   commit landed
)
echo.

REM ----- Step 3: Tag today's daily -----
echo Step 3: Daily snapshot tag
git tag -l "daily/2026-07-01" >nul
if errorlevel 1 (
  git tag daily/2026-07-01
  echo   tagged: daily/2026-07-01
) else (
  echo   already tagged: daily/2026-07-01
)
echo.

REM ----- Step 4: Tag this week's weekly (ISO week) -----
echo Step 4: Weekly snapshot tag
REM ISO week for 2026-07-01 is 2026-W27
git tag -l "week/2026-W27" >nul
if errorlevel 1 (
  git tag week/2026-W27
  echo   tagged: week/2026-W27
) else (
  echo   already tagged: week/2026-W27
)
echo.

REM ----- Step 5: Remote status -----
echo Step 5: GitHub remote status
git remote -v
echo.
git remote | findstr "origin" >nul
if errorlevel 1 (
  echo   NO REMOTE CONFIGURED.
  echo   To set one up:
  echo     1^) Create empty repo on GitHub ^(private^): github.com/new
  echo     2^) Run: git remote add origin git@github.com:^<username^>/KE_ArKade.git
  echo     3^) Run: git push -u origin master --tags
  echo   Or hand this to Codex as a ticket per 07_GIT_GOVERNANCE.md §7.
) else (
  echo   remote is set — pushing master + all tags
  git push origin master
  git push origin --tags
)
echo.

REM ----- Step 6: Health summary -----
echo Step 6: Backup health summary
echo   Total commits:
git rev-list --count master
echo   Total tags:
git tag -l | find /c /v ""
echo   Most recent commit:
git log -1 --format="  %%h %%s (%%ar)"
echo   Most recent daily tag:
git tag -l "daily/*" | sort /r
echo.

echo === Done. ===

endlocal
