# Shared Adapter Cartridge Pass - Galaga, Frogger, On Track

Agent: KE_ArKade_260626_132556
Date: 2026-06-26

## Summary

Adapted:
- `content/cartridges/galaga` to the shared arena adapter and shared Tab menu.
- `content/cartridges/frogger` to the shared lane adapter and shared Tab menu.
- `content/cartridges/on_track` to the shared track adapter and shared Tab menu.

Each cartridge now loads the relevant shared adapter source from `app/shared/adapters/**` through a cartridge-local `adapter_base.gd` bridge, so standalone cartridge projects can resolve the adapter base class without editing `app/shared/**`.

## Verification

Parser/startup checks passed:
- `Godot_v4.3-stable_win64_console.exe --disable-crash-handler --headless --path content/cartridges/galaga --quit-after 5`
- `Godot_v4.3-stable_win64_console.exe --disable-crash-handler --headless --path content/cartridges/frogger --quit-after 5`
- `Godot_v4.3-stable_win64_console.exe --disable-crash-handler --headless --path content/cartridges/on_track --quit-after 5`

OpenGL screenshot checks passed with `err=0`:
- Galaga demo wall: `vault/70-qa/galaga_demo_wall_shared_arena_2026-06-26.png`
- Galaga classic: `vault/70-qa/galaga_classic_shared_arena_2026-06-26.png`
- Frogger demo wall: `vault/70-qa/frogger_demo_wall_shared_lane_2026-06-26.png`
- Frogger classic: `vault/70-qa/frogger_classic_shared_lane_2026-06-26.png`
- On Track demo wall: `vault/70-qa/on_track_demo_wall_shared_track_2026-06-26.png`
- On Track classic: `vault/70-qa/on_track_classic_shared_track_2026-06-26.png`

Image audit:
- All six screenshots are 1920x1080.
- All six contain nonblack rendered content and full RGB range.
- Frogger logs confirmed: `[Frogger] Derived lane playfield from shared adapter`.

## Notes

Headless screenshots are not supported by Godot's dummy renderer because `get_viewport().get_texture()` is null. Screenshot evidence was captured through the Windows/OpenGL render path with `--disable-crash-handler`.
