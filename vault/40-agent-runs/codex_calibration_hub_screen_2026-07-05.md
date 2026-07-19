---
run_id: codex_calibration_hub_screen_2026-07-05
agent: codex
session_start: 2026-07-05T02:05:00-07:00
session_end: 2026-07-05T02:12:00-07:00
task_id: TASK-calibration-hub-screen
lane: hub
lock_held: hub-calibration-screen
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Replaced the Calibrate coming-soon path with a real hub calibration screen.
The screen is still an MVP, but it is now visible and interactive: test grid,
mesh pins, 2x2/3x3/4x4 selection, reset, full test-pattern toggle, and save to
the active scene calibration file.

## Changes

- Added `app/hub/calibrate_screen.tscn`.
- Added `app/hub/calibrate_screen.gd`.
- Updated `app/hub/main.gd` so `_on_launch_calibration_tool()` loads the new
  screen instead of showing the placeholder.
- Updated Help text from "Calibrate: Coming soon" to output mapping wording.
- Added `vault/30-tasks/TASK-calibration-hub-screen.md`.

## Verification

- First direct scene load caught a GDScript parse error in the mesh callback;
  fixed it.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after the fix.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed.
- Godot checks required escalation because sandboxed runs crashed when Godot
  could not write its `user://logs` directory.

## Backup Status

- No git commit was made because the repo already has a large unrelated dirty
  working tree. Capturing a snapshot here would include other agents' work.
- Backup remains pending.

## Open Questions

- None new.

## Next Holder Briefing

Next step is runtime application of the saved calibration profile. Best path is
a shared final-frame output wrapper so cartridges render normally and the warp
is applied once at the projector/window boundary, not separately inside every
game.
