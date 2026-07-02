---
run_id: antigravity_hub-absolute-launch-simplify_2026-07-01
agent: antigravity
session_start: 2026-07-01T01:26:36Z
session_end: 2026-07-01T01:30:00Z
task_id: TASK-INT-hub-wiring-launch-and-nav
lane: hub
lock_held: hub-design
status: pending_kons_verify
pre_edit_commit: 887b5cd
close_commit: 455f1b3
escalations: []
---

## Summary

Added `.simplify_path()` to the `base_dir` in `_launch_game()` so Godot's Windows `OS.create_process` can properly resolve the path without choking on `../..` relative segments. Also added three debug IPC logs immediately prior to process creation to dump the exact `exe`, `args`, and `CWD` strings for diagnostics.

## Changes

- `app/hub/main.gd`: Appended `.simplify_path()` to `base_dir` assignment.
- `app/hub/launcher/launcher.gd`: Emitted three `ipc_log` signals (DEBUG EXE, DEBUG ARGS, DEBUG CWD) right before `active_pid = OS.create_process(exe, args)`.

## Verification

Hub gate:
- `godot --headless --check app/hub/main.gd` -> OK (no parse errors).
- `godot --headless --check app/hub/launcher/launcher.gd` -> OK (no parse errors).
- Launch confirmation: PENDING (awaiting Kons test run + log check)

## Open questions

None new. 

## Next holder briefing

If Kons reports the hub still boots a grey window, check the new "DEBUG" outputs in the IPC Log (click the Log nav button). They will display the exact command signature the hub passed to the OS, which will isolate the issue.
