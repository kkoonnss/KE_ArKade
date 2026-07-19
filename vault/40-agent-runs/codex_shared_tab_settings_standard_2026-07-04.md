---
run_id: codex_shared_tab_settings_standard_2026-07-04
agent: codex
session_start: 2026-07-04T14:20:00-07:00
session_end: 2026-07-04T14:56:33-07:00
task_id: TASK-shared-tab-settings-standard
lane: shared
lock_held: shared-tab-settings-standard
status: pending_kons_verify
pre_edit_commit: c1864ce
close_commit: pending
backup_status: backup_pending_usage_limit
backup_remote: origin
escalations:
  - Godot headless smoke/checks required unsandboxed access because Godot writes logs/config outside the workspace.
  - Git commit/push was blocked by Codex usage limit; retry after 2026-07-06T22:20:00-07:00 or from another approved local Git session.
---

# Codex Shared Tab Settings Standard

## Summary

Implemented the shared Tab Settings Panel Standardization Plan in the common
`TabMenu` shell and updated the existing secondary-level UI guide. The shared
menu now renders a projection-mapping-first group order, aliases `Map` and
`Level` into `Secondary`, defaults groups collapsed, and persists group layout
state per cartridge/level.

## Changes

- `app/shared/controls/tab_menu.gd`
  - Added canonical group ordering:
    `Preview`, `Secondary`, `Collision`, `Gameplay`, `Actions`, then
    `General`.
  - Normalized `Map` and `Level` groups to `Secondary`.
  - Moved built-in settings buttons into the `Actions` group.
  - Defaulted all groups to collapsed on first open.
  - Added `ui_state.version = tab_menu_layout_v1` and
    `ui_state.collapsed_groups` persistence beside existing `settings`.
  - Preserved existing settings values and unknown adjustment JSON fields.
  - Adjusted the scene/level subtitle so resolution renders on its own
    `RES: <value>` line instead of wrapping `RES:` away from the value.
- `app/shared/SECONDARY_LEVEL_UI_STANDARD.md`
  - Updated the guide to match the code-enforced order and aliases.
  - Added projection-mapping-first rationale, UI-state persistence rules,
    current audit notes, and agent rules for future settings panels.
- `vault/30-tasks/TASK-shared-tab-settings-standard.md`
  - Added task tracking and verification notes.

## Verification

- `git diff --check -- app/shared/controls/tab_menu.gd app/shared/SECONDARY_LEVEL_UI_STANDARD.md vault/30-tasks/TASK-shared-tab-settings-standard.md vault/35-locks/shared-tab-settings-standard.md`
  - Passed.
- Synthetic Godot smoke:
  - Loaded `TabMenu` through `SharedLoader`.
  - Registered groups out of order.
  - Verified rendered order:
    `PREVIEW`, `SECONDARY`, `COLLISION`, `GAMEPLAY`, `ACTIONS`, `GENERAL`.
  - Verified `Map` and `Level` persisted/rendered as `Secondary`.
  - Verified first open defaults every group collapsed.
  - Verified legacy `settings` loaded and unknown JSON field was preserved.
  - Verified toggling `Secondary` persisted immediately and reloaded.
  - Result: `TabMenu standard smoke OK`.
- Cartridge headless checks:
  - Rampage passed.
  - Pac-Man passed.
  - Tetris passed.
  - GTA passed as the General-heavy shared TabMenu check.
  - Galaga was attempted first for the General-heavy check but failed on an
    unrelated pre-existing parse error: mixed tab indentation at
    `content/cartridges/galaga/main.gd:682`.
- Shared contract grep:
  - `rg "SharedLoader" app content/cartridges -g "*.gd"` returned broad
    consumer coverage.
  - `rg "load_tab_menu_script\\(" app content/cartridges -g "*.gd"` found
    the shared TabMenu consumers.
  - `rg "Adapter\\.new\\(\\)|TabMenu\\.new\\(" content/cartridges app -g "*.gd"`
    found only `app/shared/qa_harness.gd` adapter constructors, not cartridge
    `TabMenu.new()` usage.
- Follow-up UI text patch:
  - `git diff --check -- app/shared/controls/tab_menu.gd vault/40-agent-runs/codex_shared_tab_settings_standard_2026-07-04.md`
  - Passed.

## Backup status

- Pre-edit tag created at `pre-edit/shared/tab-settings-standard/c1864ce`.
- Close commit and push are pending because the git commit action was blocked
  by the Codex usage-limit guard:
  `try again at Jul 6th, 2026 10:20 PM`.
- Next command once git actions are available:
  `git add -- app/shared/controls/tab_menu.gd app/shared/SECONDARY_LEVEL_UI_STANDARD.md vault/30-tasks/TASK-shared-tab-settings-standard.md vault/35-locks/shared-tab-settings-standard.md vault/40-agent-runs/codex_shared_tab_settings_standard_2026-07-04.md`
  then `git commit -m "shared: standardize tab settings panels"` and
  `git push origin master --tags`.

## Open questions

- None new.

## Next holder briefing

Visually confirm a few live settings panels after launch. Best check set:
Tetris or Asteroids for the full `Preview/Secondary/Collision/Gameplay`
stack, Rampage or Pac-Man for alias normalization, and GTA for `General`
falling last. Do not treat the Galaga parse failure as part of this shared
change; it is a cartridge-file indentation issue already present in the dirty
tree.
