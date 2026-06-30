---
task_id: TASK-INT-07-design-screen-blank-calibrate
stage: 6
wave: 0
priority: P0
lane: hub
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: []
acceptance:
  - Design tab renders the FULL in-hub editor (sidebar tools + photo/semantic canvas + virtual cursor), not just the "Level Design" label
  - Slider mode + paint mode + reference-opacity work; controller AND mouse both operate it
  - Calibrate tab no longer offers the redundant external "Launch Level Editor" (editor now lives in the Design tab); keep "Launch 4-Point Calibration"
  - Verified by screenshots of both tabs working
---

## Objective
The Design tab is blank and the Calibrate tab still launches the legacy external editor. Fix both.

## Root cause (confirmed by orchestrator)
`app/hub/design_screen.tscn` line 3 declares its script as
`[ext_resource type="Script" path="res://app/hub/design_screen.gd" ...]`.
The hub project's `res://` **is** `app/hub/`, so that path resolves to
`app/hub/app/hub/design_screen.gd` (does not exist). The script never attaches,
so the instantiated DesignScreen renders only its static nodes (the "Level Design"
title + dark bg) with no behavior/canvas. **Fix: change it to `res://design_screen.gd`.**
(main.gd already preloads `res://design_screen.tscn` and instantiates it correctly in `_on_design_nav_pressed` ~:1391.)

## Also
- After the path fix, launch the Design tab and confirm the canvas + sidebar tools + virtual cursor actually appear and work (slider/paint/opacity, controller + mouse). If any sub-UI is still missing, finish it — this is the in-hub editor from TASK-INT-03/04.
- Calibrate screen (main.gd ~:1649 `author_btn "Launch Level Editor"`): remove that button (or repoint it to open the Design tab). The editor is the Design tab now; Calibrate keeps only 4-Point Calibration.

## Notes
- Own ONLY `app/hub/**`. Lock `hub-design`. Verify by real screenshots, not code.

## REOPENED 2026-06-26 — still blank: TWO compile errors in app/hub/design_screen.gd
The .tscn script path was fixed, but design_screen.gd does not COMPILE, so it never attaches (only the static "Level Design" title shows). The full editor UI is already coded in _build_ui(); it just never runs.
1. Line 27: `"invert_mask": False` -> GDScript needs lowercase `false`.
2. Line 3: `const Palette = preload("res://shared/palette.gd")` -> wrong path; palette lives in app/shared (OUTSIDE the hub's res://). Do NOT preload it. Load it at runtime like SharedLoader does (resolve repo root, then `load(root.path_join("app/shared/palette.gd"))`), and use that for the palette grid in _build_ui().
HARD GATE: actually LAUNCH the hub, click Design, and confirm the Load/Save buttons + sliders + palette grid render and a photo loads onto the canvas. A non-compiling script was marked done 3x — do not repeat.
