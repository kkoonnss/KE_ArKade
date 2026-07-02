---
task_id: TASK-INT-09-design-preset-selector
stage: 6
wave: 0
priority: P2
lane: hub
archetype: n/a
status: pending_kons_verify
closed_at: 2026-07-01
closing_receipt: vault/40-agent-runs/antigravity_hub_fix_INT-08-09-scene-ordering_2026-07-01.md
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: [TASK-INT-08-design-save-compile-derived]
acceptance:
  - Design auto-derive sidebar has an OptionButton listing the presets the backend supports ("Balanced Semantic", "Open Flow", "Vertical Surfaces"), read from app/tools/level_authoring/author_backend.py so it stays in sync
  - Changing the preset sets cv_params["preset"] and re-runs the derive (same path as the sliders); default "Balanced Semantic"; existing CV sliders kept
  - Verified by launching Design, switching presets, and seeing the auto-derived map change
---

## Objective
Restore the auto-derive preset selector lost in the Design-screen redesign. The presets already exist + work in the Python backend (author_backend.py: Balanced Semantic / Open Flow / Vertical Surfaces); design_screen.gd just hardcodes one with no chooser. Add the dropdown.

## Notes
- Same hub-design lock + same file (design_screen.gd) as TASK-INT-08 — same Antigravity instance, sequential. Don't run a second hub agent concurrently.
- If the pre-redesign editor had MORE presets than these three, restoring those definitions is a Codex/app-tools follow-on (author_backend.py); this dropdown auto-picks them up if it reads the backend list.

## RUN LOG 2026-06-27
- Added preset key to cv_params with default " Balanced Semantic\.
