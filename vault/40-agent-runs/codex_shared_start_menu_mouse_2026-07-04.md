---
run_id: codex_shared_start_menu_mouse_2026-07-04
agent: codex
session_start: 2026-07-04T05:00:00-07:00
session_end: 2026-07-04T05:20:00-07:00
task_id: TASK-shared-start-menu-mouse
lane: shared
lock_held: shared-start-menu-mouse
status: pending_kons_verify
pre_edit_commit: not_created_dirty_tree
close_commit: 5de443e
backup_status: pushed_to_origin_master
backup_remote: origin
escalations:
  - Godot headless smoke required unsandboxed access because Godot writes logs/config outside the workspace.
---

# Codex Shared Start Menu Mouse Takeover

## Summary

Made the shared `TabMenu` start/help labels mouse selectable and clickable,
matching the keyboard/controller behavior already used by the game start
overlay.

## Changes

- `app/shared/controls/tab_menu.gd`
  - Added mouse wiring for the reusable start/help labels.
  - Hovering a visible label updates `selected_menu_index` and refreshes the
    `>` highlight.
  - Left-clicking a visible label sets selection and calls the existing
    `_menu_accept()` path.
  - Blank labels and the settings view now use `MOUSE_FILTER_IGNORE`.
  - Updated the start/help hints to include clicking.
  - Added an ancestry guard before `settings_scroll.ensure_control_visible()`
    so entering Settings through the new mouse path does not log a scroll
    container warning for the reset button.

## Coordination

- Created `TASK-shared-start-menu-mouse` for this narrow shared UI takeover.
- Removed the stale `shared-slider-focus-style` lock after confirming the
  Claude Sonnet receipt already marked the slider-focus work complete and
  pending Kons verification.
- Left the broad Antigravity controller-overhaul checklist alone because this
  fix is narrower and fully captured here.

## Verification

- `Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/rampage --quit-after 2`
  - Passed.
- Disposable direct smoke script through Rampage project:
  - Loaded `app/shared/shared_loader.gd`.
  - Loaded `app/shared/controls/tab_menu.gd`.
  - Confirmed hover selects Settings and Help.
  - Confirmed click opens Settings and Help.
  - Confirmed click on Start Game emits the `start` action.
  - Passed with a clean console after the scroll-container ancestry guard.

## Notes

`app/shared/controls/tab_menu.gd` already had an uncommitted resolution-display
subtitle change before this takeover began. This Codex pass preserved that
change and added the mouse-start-menu fix beside it.
