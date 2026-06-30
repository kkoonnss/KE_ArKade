# Debug Doctor Report

Date: 2026-06-25 12:38:39
Cartridge: `pacman`
Symptom: `launch`
Scene: `scene_demo_wall`
Level: `demo_level`

## Metadata

- Project name: `Pac-Man`
- Manifest game name: `Pac-Man`
- Godot executable: `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\Godot_v4.3-stable_win64_console.exe`

## Checks

- `headless_launch`: TIMEOUT
  cmd: `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\Godot_v4.3-stable_win64_console.exe --headless --path C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\cartridges\pacman --quit`
  output:
```text
ERROR: Failed to open user://logs/godot2026-06-25T12.38.13.log
   at: (core/io/dir_access.cpp:351)

================================================================
CrashHandlerException: Program crashed with signal 11
Engine version: Godot Engine v4.3.stable.official (77dcf97d82cbfe4e4615475fa52ca03da645dbd8)
Dumping the backtrace. Please include this when reporting the bug to the project developer.
[1] error(-1): no debug info in PE/COFF executable
[2] error(-1): no debug info in PE/COFF executable
[3] error(-1): no debug info in PE/COFF executable
[4] error(-1): no debug info in PE/COFF executable
[5] error(-1): no debug info in PE/COFF executable
[6] error(-1): no debug info in PE/COFF executable
[7] error(-1): no debug info in PE/COFF executable
[8] error(-1): no debug info in PE/COFF executable
[9] error(-1): no debug info in PE/COFF executable
[10] error(-1): no debug info in PE/COFF executable
[11] error(-1): no debug info in PE/COFF executable
[12] error(-1): no debug info in PE/COFF executable
[13] error(-1): no debug info in PE/COFF executable
[14] error(-1): no debug info in PE/COFF executable
-- END OF BACKTRACE --
======================================================
```
- `level_smoke`: TIMEOUT
  cmd: `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\Godot_v4.3-stable_win64_console.exe --headless --path C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\cartridges\pacman --quit-after 8 -- --scene C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall --level C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall\levels\demo_level --ipc 0`
  output:
```text
ERROR: Failed to open user://logs/godot2026-06-25T12.38.17.log
   at: (core/io/dir_access.cpp:351)

================================================================
CrashHandlerException: Program crashed with signal 11
Engine version: Godot Engine v4.3.stable.official (77dcf97d82cbfe4e4615475fa52ca03da645dbd8)
Dumping the backtrace. Please include this when reporting the bug to the project developer.
[1] error(-1): no debug info in PE/COFF executable
[2] error(-1): no debug info in PE/COFF executable
[3] error(-1): no debug info in PE/COFF executable
[4] error(-1): no debug info in PE/COFF executable
[5] error(-1): no debug info in PE/COFF executable
[6] error(-1): no debug info in PE/COFF executable
[7] error(-1): no debug info in PE/COFF executable
[8] error(-1): no debug info in PE/COFF executable
[9] error(-1): no debug info in PE/COFF executable
[10] error(-1): no debug info in PE/COFF executable
[11] error(-1): no debug info in PE/COFF executable
[12] error(-1): no debug info in PE/COFF executable
[13] error(-1): no debug info in PE/COFF executable
[14] error(-1): no debug info in PE/COFF executable
-- END OF BACKTRACE --
======================================================
```
- `screenshot_smoke`: FAIL
  cmd: `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\Godot_v4.3-stable_win64_console.exe --headless --path C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\cartridges\pacman --quit-after 10 -- --scene C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall --level C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\content\scenes\scene_demo_wall\levels\demo_level --ipc 0 --screenshot C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\scratch\debug_doctor_pacman_demo_level.png`
  output:
```text
ERROR: Failed to open user://logs/godot2026-06-25T12.38.29.log
   at: (core/io/dir_access.cpp:351)

================================================================
CrashHandlerException: Program crashed with signal 11
Engine version: Godot Engine v4.3.stable.official (77dcf97d82cbfe4e4615475fa52ca03da645dbd8)
Dumping the backtrace. Please include this when reporting the bug to the project developer.
[1] error(-1): no debug info in PE/COFF executable
[2] error(-1): no debug info in PE/COFF executable
[3] error(-1): no debug info in PE/COFF executable
[4] error(-1): no debug info in PE/COFF executable
[5] error(-1): no debug info in PE/COFF executable
[6] error(-1): no debug info in PE/COFF executable
[7] error(-1): no debug info in PE/COFF executable
[8] error(-1): no debug info in PE/COFF executable
[9] error(-1): no debug info in PE/COFF executable
[10] error(-1): no debug info in PE/COFF executable
[11] error(-1): no debug info in PE/COFF executable
[12] error(-1): no debug info in PE/COFF executable
[13] error(-1): no debug info in PE/COFF executable
[14] error(-1): no debug info in PE/COFF executable
-- END OF BACKTRACE --
======================================================
```

## Findings

- Headless cartridge boot failed, so the problem is below hub/UI level.
- Cartridge booted headless but failed when scene/level args were applied.
- Gameplay screenshot smoke did not complete, which usually means startup flow or post-splash timing is unhealthy.

## Next Technical Questions

- Does `pacman` fail only from the hub, or also when launched directly with `scene_demo_wall/demo_level`?
- Does it reach splash and then die, or never paint a frame at all?
- If it restarts, is there a game-over/reset loop in `_process` or `_handle_ipc(load)`?
