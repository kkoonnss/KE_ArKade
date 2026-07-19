@echo off
cd /d "C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade"

echo Clearing any stale lock/partial stage from the sandbox session...
if exist ".git\index.lock" del /F ".git\index.lock"
git reset >nul 2>nul

echo Staging full working tree as-is (no code review, preservation only)...
git add -A

echo Committing snapshot...
git commit -m "snapshot: full working-tree backup before continuing six-favorites testing pass" -m "Includes in-progress tetris/joypad debugging session, hub design/main/tab_menu edits, cartridge main.gd changes, level adjustments, and vault notes as-is. No code reviewed or changed by this commit - preservation only."

echo.
echo === Pushing to origin ===
call "_Briefs\governance\scripts\push_backup.cmd" manual

echo.
echo === Final status ===
git status
git log --oneline -3

pause
