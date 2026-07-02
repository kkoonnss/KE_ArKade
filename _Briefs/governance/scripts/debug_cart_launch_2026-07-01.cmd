@echo off
REM ============================================================
REM KE_ArKade — Cart launch diagnostic (2026-07-01)
REM
REM Runs pacman with the exact command line the hub SHOULD be running,
REM captures stdout + stderr, and shows you what Godot actually does.
REM
REM If pacman launches to a playable window from THIS script but not
REM from the hub, the hub is generating a different command than we think
REM (likely relative-exe-path failing).
REM
REM If pacman ALSO shows grey from this script, the args or cart-side is
REM the real bug and the hub is innocent.
REM ============================================================

setlocal enabledelayedexpansion

set REPO=C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade
cd /d "%REPO%" || (echo Could not cd to repo. & exit /b 1)

echo.
echo === Cart launch diagnostic ===
echo cwd: %CD%
echo.

REM ----- Sanity check the exe -----
if not exist "Godot_v4.3-stable_win64.exe" (
  echo FAIL: Godot_v4.3-stable_win64.exe not at repo root. This is likely
  echo       the root cause of the grey window — hub uses a relative exe
  echo       name and cannot find it.
  exit /b 1
)
echo OK: Godot_v4.3-stable_win64.exe present at repo root.
echo.

REM ----- Sanity check cart + scene paths -----
if not exist "content\cartridges\pacman\project.godot" (
  echo FAIL: pacman project.godot missing.
  exit /b 1
)
if not exist "content\scenes\scene_classic_pack\scene.yaml" (
  echo FAIL: classic pack scene.yaml missing.
  exit /b 1
)
if not exist "content\scenes\scene_classic_pack\levels\classic_pacman" (
  echo FAIL: classic_pacman level dir missing.
  exit /b 1
)
echo OK: pacman + scene_classic_pack + classic_pacman level all present.
echo.

REM ----- The actual launch (matches hub's args_template) -----
echo Running:
echo   Godot_v4.3-stable_win64.exe --path "content\cartridges\pacman" -- --scene "content\scenes\scene_classic_pack" --level "content\scenes\scene_classic_pack\levels\classic_pacman" --ipc 50000
echo.
echo Godot output will be captured to cart_debug_out.txt (redirected).
echo Any window pop-up is the actual behavior.
echo Close it when you're done watching.
echo.

Godot_v4.3-stable_win64.exe --path "content\cartridges\pacman" -- --scene "content\scenes\scene_classic_pack" --level "content\scenes\scene_classic_pack\levels\classic_pacman" --ipc 50000 > cart_debug_out.txt 2>&1

echo.
echo === Godot output (cart_debug_out.txt) ===
type cart_debug_out.txt
echo === End of output ===
echo.
echo cart_debug_out.txt saved at repo root — paste back to me if not clear.

endlocal
