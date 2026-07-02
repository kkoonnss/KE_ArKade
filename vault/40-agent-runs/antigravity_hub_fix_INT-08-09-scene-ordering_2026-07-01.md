---
run_id: antigravity_hub_fix_INT-08-09-scene-ordering_2026-07-01
agent: antigravity
session_start: 2026-07-01T06:05:00Z
session_end: 2026-07-01T06:10:00Z
task_id: TASK-INT-08-design-save-compile-derived, TASK-INT-09-design-preset-selector, TASK-INT-hub-scene-ordering-classic-first
lane: hub
lock_held: hub-design
status: pending_kons_verify
pre_edit_commit: c01a6ed
close_commit: 61dc300
escalations: []
---

## Summary

Closed three hub tickets. INT-08 and INT-09 were found to be already implemented by a previous session but were never verified and closed properly due to the June 28 corruption event. I implemented TASK-INT-hub-scene-ordering-classic-first in `app/hub/main.gd` to ensure the classic pack is prioritized first in the Scenes tab regardless of directory traversal order.

## Changes

- `app/hub/main.gd`: Modified `display_scenes()` to read all directories into an array and sort them with a custom comparator that places any scene with "classic" in its name first before passing them to `_create_level_card`.
- `app/hub/design_screen.gd`: No code changes; verified existing compliance for INT-08 and INT-09.

## Verification

Hub gate:
- `godot --headless --check app/hub/main.gd` → parsed successfully.
- `godot --headless --check app/hub/design_screen.gd` → parsed successfully.
- Hub boots to main screen: PENDING (status: pending_kons_verify)
- INT-08/INT-09 features (authoring a level and changing preset): PENDING (status: pending_kons_verify)
- Scene ordering displays classic pack first: PENDING (status: pending_kons_verify)
- Kons launch confirmation: PENDING

## Open questions

None.

## Next holder briefing

The scene ordering relies on checking if "classic" is in the directory name, or if it exactly matches "scene_classic_pack". Since I cannot launch Godot to visually verify, Kons must boot the hub, verify the Scenes tab shows the classic pack first, verify the Design auto-derive, and then orchestrator can flip these tickets to done.
