# Codex Run Log - All Cartridge Functional QC

Date: 2026-06-22
Agent: Codex
Scope: all 30 playable cartridge directories under `content/cartridges/` excluding `loopback`

## Summary

Completed the follow-up build/QC pass after the final five prototype cartridges were made playable. The project now has 30 playable cartridges with loading, runtime, visual screenshot, and pixel-level art checks passing.

## Build Tightening

- Added post-splash `--screenshot` support to:
  - `content/cartridges/bomberman/main.gd`
  - `content/cartridges/on_track/main.gd`
  - `content/cartridges/frogger/main.gd`
- Updated `on_track` and `frogger` to append `OS.get_cmdline_user_args()` so arguments passed after Godot's `--` delimiter are honored.
- Fixed `tetris` screenshot timing so the capture waits until the splash layer has cleared.
- Re-encoded all real cartridge `splash.png` and `thumbnail.png` files as strict PNGs earlier in this pass to eliminate Godot image import warnings.

## Validation

- Parser checks passed for edited scripts:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --check-only --script res://main.gd`
- Required headless launch validation passed for all 30 cartridges:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit`
- Bounded runtime load with demo level passed for all 30 cartridges:
  `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cart> --quit-after 20 --log-file vault/70-qa/<cart>_full_qc_runtime.log -- --level <demo_level>`
- Runtime logs scanned for errors and warnings; no matches found for:
  `ERROR|SCRIPT ERROR|Invalid|Parse Error|Cannot|Failed|ERR_FILE|WARNING: Not a PNG`
- Gameplay screenshots captured for all 30 cartridges:
  `vault/70-qa/<cart>_full_qc_gameplay.png`
- Pixel audit passed:
  - `checked=30`
  - `warnings=0`
  - `failures=0`

## Evidence

- Runtime aggregate log: `vault/70-qa/ALL_CARTRIDGES_headless_quit_2026-06-22.log`
- Gameplay contact sheet: `vault/70-qa/all_cartridge_gameplay_contact_sheet_2026-06-22.png`
- Splash/cover contact sheet: `vault/70-qa/all_cartridge_splash_contact_sheet_2026-06-22.png`
- Pixel audit CSV: `vault/70-qa/all_cartridge_gameplay_pixel_audit_2026-06-22.csv`

## Result

Status: pass. All real cartridge folders are functional, load in Godot, render valid art, and produce nonblank post-splash gameplay screenshots.

## Addendum - 2026-06-25

- Clarified that `asteroids`, `donkey_kong`, and `breakout` are internal cartridge folder IDs; visible classic names are provided by `project.godot`, `manifest.yaml`, and runtime title maps (`Asteroids`, `Donkey Kong`, `Breakout`).
- Fixed `content/cartridges/rampage/main.gd` so IPC `ready` is emitted after the TCP socket reports connected, instead of being sent during startup before the hub can reliably receive it. Added `--arkade_screenshot` parsing support for future smoke captures.
- Fixed `content/cartridges/battlezone/main.gd` tank movement by replacing nearest-cell snap correction during tank motion with blocked/slide stepping. This prevents the player and enemy tanks from jittering backward and forward when the tank noses into blocked map cells.
- Validation passed:
  - `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit`
  - `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/battlezone --quit`
