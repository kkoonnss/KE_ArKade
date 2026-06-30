# TASK-INT-05 Shared Loader Standard

Agent: KE_ArKade_260626_132556
Date: 2026-06-26

## Summary

Added `app/shared/shared_loader.gd` as the canonical loader for separate-process cartridges. It resolves the KE_ArKade repo root by walking up from cartridge `res://`, loads shared scripts by absolute path, strips cross-project `class_name` reliance, and injects AdapterBase helper constants/functions into adapter scripts so cartridges do not need local `adapter_base.gd` copies.

Retrofitted `content/cartridges/gta/main.gd` as the reference consumer:
- Loads shared Tab menu through `SharedLoader.load_tab_menu_script()`.
- Loads shared Region adapter through `SharedLoader.load_adapter_script("region")`.
- Parses hub/user args correctly with `OS.get_cmdline_user_args()`.
- Adds deterministic OpenGL screenshot capture for QA.

Updated `app/shared/README.md` with the separate-project root cause, integration gate, and a 3-5 line copyable loader snippet.

## Verification

Headless parser/startup:
- `Godot_v4.3-stable_win64_console.exe --disable-crash-handler --headless --path content/cartridges/gta --quit-after 5`

Level-backed launches:
- `classic_gta`: `[GTA] SharedLoader RegionAdapter ... grid=40x23 cell_px=32 fallback=false`
- `demo_level`: `[GTA] SharedLoader RegionAdapter ... grid=21x31 cell_px=32 fallback=false`

OpenGL screenshots:
- `vault/70-qa/gta_classic_shared_loader_2026-06-26.png` saved with `err=0`
- `vault/70-qa/gta_demo_wall_shared_loader_2026-06-26.png` saved with `err=0`

Image audit:
- Both screenshots are 1920x1080.
- Both are nonblank with full RGB range.
- Visual inspection confirmed the shared Tab menu is open over live GTA content.

## Notes

GTA has no local `adapter_base.gd`; the shared adapter base behavior is supplied by `SharedLoader`. Existing Galaga/Frogger/On Track local bridge cleanup remains a later cleanup pass as noted in the ticket.
