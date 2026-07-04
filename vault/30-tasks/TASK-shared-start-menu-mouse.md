---
task_id: TASK-shared-start-menu-mouse
lane: shared
status: pending_kons_verify
locks_required: [shared-start-menu-mouse]
opened_by: codex
opened_at: 2026-07-04
---

# Make the shared TabMenu start/help entries mouse selectable

## Problem

The shared game start overlay in `app/shared/controls/tab_menu.gd` supports
keyboard and controller navigation, but its start/help entries are plain
`Label` nodes and do not respond to mouse hover or left-click. The settings
view already uses mouse-native controls, so the start overlay feels broken
by comparison.

## Scope

- Wire the start/help menu labels to mouse hover and left-click.
- Reuse the existing `_menu_accept()` activation path so mouse, keyboard,
  and controller behavior stay aligned.
- Do not change the settings controls or broader hub/controller-overhaul
  ticket.

## Acceptance

- Hovering a visible start/help menu entry moves the highlighted `>` marker.
- Left-clicking a visible start/help menu entry triggers the same action as
  pressing Enter/A/Start on that entry.
- Blank labels and the settings view do not intercept mouse events.

## Handoff

This is intentionally narrow and swappable. If another agent needs to take
over, claim `shared-start-menu-mouse`, inspect this note, and continue from
`app/shared/controls/tab_menu.gd`.

## Verification

- 2026-07-04 Codex: Rampage headless boot passed.
- 2026-07-04 Codex: Direct smoke script passed for hover-to-select and
  click-to-activate on Settings, Help, and Start Game.
