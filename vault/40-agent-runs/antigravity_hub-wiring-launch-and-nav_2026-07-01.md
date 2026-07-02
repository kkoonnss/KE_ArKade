---
run_id: antigravity_hub-wiring-launch-and-nav_2026-07-01
agent: antigravity
session_start: 2026-07-01T00:57:02Z
session_end: 2026-07-01T01:00:00Z
task_id: TASK-INT-hub-wiring-launch-and-nav
lane: hub
lock_held: hub-design
status: pending_kons_verify
pre_edit_commit: c81a3c0
close_commit: 8838809
escalations: []
---

## Summary

Added `--ipc <socket>` to the launch arguments in the hub so cartridges can successfully initialize IPC instead of timing out and exiting. Also hooked up the four inactive nav buttons (Log, Calibrate, Help, Test Pattern) to show placeholder modals, providing feedback on clicks.

## Changes

- `app/hub/main.gd`: Updated `args_template` in `_launch_game()` to include `-- --scene "<dir>" --level "<dir>" --ipc <socket>`.
- `app/hub/main.gd`: Connected `launcher.ipc_log` signal and stored last 50 lines in an array.
- `app/hub/main.gd`: Implemented `_show_placeholder_overlay` to spawn a dimming background + modal panel for the unused buttons.
- `app/hub/main.gd`: Wired `ServiceBtn`, `HelpBtn`, `CalibrateBtn`, and `TestPatternBtn` to show their respective modals using the overlay helper.

## Verification

Hub gate:
- `godot --headless --check app/hub/main.gd` -> OK (no parse errors).
- Launch confirmation: PENDING
- Nav buttons confirmation: PENDING

## Open questions

None new. 

## Next holder briefing

The Log/Help overlays are just dynamically spawned Node hierarchies appended directly to `$UI` rather than loaded from separate tscn files, just to keep it minimal and contained within `main.gd` for now. If you're building out full menus, consider replacing `_show_placeholder_overlay` with instancing dedicated packed scenes.
