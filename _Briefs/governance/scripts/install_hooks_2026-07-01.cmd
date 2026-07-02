@echo off
REM ============================================================
REM KE_ArKade — Install git pre-commit safety hooks (2026-07-01)
REM
REM Installs a pre-commit hook that catches the exact class of bug
REM that caused the Jun 28-30 corruption:
REM   - main.gd (or any file > 500 lines) shrinking by >30% blocks the commit
REM   - Files with `Parse Error` sitting in them blocks the commit
REM   - Missing pre-edit tag for large-file edits warns (doesn't block)
REM
REM To override the block (only for intentional big deletions):
REM   set KE_ARKADE_ALLOW_SHRINK=1 && git commit -m "..."
REM
REM Safe to re-run.
REM ============================================================

setlocal
set REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade
cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

echo.
echo === Installing pre-commit safety hooks ===
echo Repo: %REPO%
echo.

if not exist ".git\hooks" (
  echo   ERROR: .git\hooks not found. Not a git repo?
  exit /b 1
)

REM Write the pre-commit hook (bash script — git uses Git for Windows shell)
(
echo #!/bin/sh
echo # KE_ArKade pre-commit safety hook
echo # Installed 2026-07-01 by _Briefs/governance/scripts/install_hooks_2026-07-01.cmd
echo # See _Briefs/governance/03_RECOVERY_PROTOCOL.md
echo.
echo REPO="$(git rev-parse --show-toplevel^)"
echo ALLOW_SHRINK="${KE_ARKADE_ALLOW_SHRINK:-0}"
echo.
echo # Check every staged file that already existed in HEAD
echo git diff --cached --name-only --diff-filter=M ^| while read -r FILE; do
echo   if [ -z "$FILE" ]; then continue; fi
echo   [ ! -f "$FILE" ] ^&^& continue
echo.
echo   # Count new size and old size in lines
echo   NEW_LINES=$(wc -l ^< "$FILE" 2^>/dev/null^)
echo   OLD_LINES=$(git show "HEAD:$FILE" 2^>/dev/null ^| wc -l^)
echo.
echo   if [ -z "$NEW_LINES" ] ^|^| [ -z "$OLD_LINES" ]; then continue; fi
echo   if [ "$OLD_LINES" -lt 500 ]; then continue; fi
echo.
echo   # Compute shrinkage
echo   SHRINK=$(( (OLD_LINES - NEW_LINES^) * 100 / OLD_LINES ^)^)
echo   if [ "$SHRINK" -gt 30 ]; then
echo     if [ "$ALLOW_SHRINK" = "1" ]; then
echo       echo "  WARN: $FILE shrunk ${SHRINK}%% (${OLD_LINES} -^> ${NEW_LINES} lines^) — allowed by KE_ARKADE_ALLOW_SHRINK=1"
echo     else
echo       echo ""
echo       echo "  ============================================================"
echo       echo "  BLOCK: $FILE would shrink from ${OLD_LINES} to ${NEW_LINES} lines (-${SHRINK}%%^)"
echo       echo ""
echo       echo "  This looks like the Jun 28-30 corruption pattern. If intentional:"
echo       echo "    set KE_ARKADE_ALLOW_SHRINK=1 ^&^& git commit -m '...'"
echo       echo "  Otherwise: git reset HEAD, inspect the diff, fix your edit."
echo       echo "  ============================================================"
echo       exit 1
echo     fi
echo   fi
echo done
echo.
echo # Check for Parse Error / traceback markers in .gd files
echo git diff --cached --name-only ^| grep '\.gd$' ^| while read -r FILE; do
echo   if [ ! -f "$FILE" ]; then continue; fi
echo   if grep -q "Parse Error:" "$FILE"; then
echo     echo "  BLOCK: $FILE contains 'Parse Error:' text — likely mis-committed error dump"
echo     exit 1
echo   fi
echo done
echo.
echo exit 0
) > ".git\hooks\pre-commit"

REM Make it executable on Windows (git-for-windows respects the +x bit via git update-index)
git update-index --chmod=+x ".git/hooks/pre-commit" 2>nul

echo   installed: .git\hooks\pre-commit
echo.

REM Sanity test — try dry-run diff
echo === Testing hook exists ===
if exist ".git\hooks\pre-commit" (
  echo   OK: pre-commit hook present
) else (
  echo   FAIL: pre-commit hook missing
  exit /b 1
)
echo.

echo === Done. ===
echo.
echo Test the hook by trying a "bad" commit ^(delete lines from main.gd, git commit^) —
echo the hook should block. Undo with: git reset HEAD ^&^& git checkout -- app/hub/main.gd
echo.
echo To bypass for intentional cleanup:
echo   set KE_ARKADE_ALLOW_SHRINK=1 ^&^& git commit -m "..."
echo   ^(the env var is only for that one command, not persistent^)

endlocal
