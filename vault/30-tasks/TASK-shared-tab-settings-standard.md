---
task_id: TASK-shared-tab-settings-standard
lane: shared
status: pending_kons_verify
locks_required: [shared-tab-settings-standard]
opened_by: codex
opened_at: 2026-07-04
closing_receipt: vault/40-agent-runs/codex_shared_tab_settings_standard_2026-07-04.md
---

# Standardize shared TabMenu settings panels

## Goal

Implement the Tab Settings Panel Standardization Plan: make the shared
`TabMenu` render settings groups in a projection-mapping-first order, persist
collapsed group state per cartridge/level, and update the shared guide so new
cartridge settings panels follow the same UX.

## Scope

- Shared `TabMenu` grouping, aliases, default collapsed state, and `ui_state`
  persistence.
- `app/shared/SECONDARY_LEVEL_UI_STANDARD.md` guide update.
- No bespoke cartridge overlay migration in this pass.

## Acceptance

- Canonical group order is `Preview`, `Secondary`, `Collision`, `Gameplay`,
  `Actions`, then `General`.
- `Map` and `Level` render as `Secondary`.
- First open with no `ui_state` starts all groups collapsed.
- Toggling a group persists immediately in the adjustment JSON without
  dropping existing settings or unknown fields.
- Synthetic smoke covers ordering, legacy settings load, first-open collapsed
  state, and collapsed-state reload.

## Verification

- 2026-07-04 Codex: Synthetic TabMenu smoke passed.
- 2026-07-04 Codex: Rampage, Pac-Man, Tetris, and GTA headless cartridge
  checks passed.
- 2026-07-04 Codex: Galaga was attempted as a General-heavy check but failed
  on a pre-existing cartridge indentation parse error at `main.gd:682`; GTA
  was used as the General-heavy passing check instead.
- Visual confirmation in the live settings UI is still pending.
