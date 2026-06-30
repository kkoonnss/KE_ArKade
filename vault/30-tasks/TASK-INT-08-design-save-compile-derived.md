---
task_id: TASK-INT-08-design-save-compile-derived
stage: 6
wave: 0
priority: P0
lane: hub
archetype: n/a
status: in_progress
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: []
acceptance:
  - Saving a level in the Design tab reliably produces a full derived/ set (grid, container, navgraph, occupancy, platform_edges, track_centerline, authoring_profile) in the new level folder
  - If the compile step fails, the UI shows a clear error -> it must NOT print/claim success when nothing was generated
  - level.yaml: level_id is the LEVEL folder name (not the scene_id); level saved under content/scenes/<scene>/levels/<level>/
  - Verified by authoring a fresh level in the hub, saving, and confirming derived/grid.json exists, THEN launching a game (e.g. gta) on it and seeing it read the map
---

## Objective
Design-tab "Save Level" writes semantic_map.png + level.yaml but the level ends up with NO derived/ folder, so games can't read custom levels. Make save reliably compile and surface failures.

## Root cause (confirmed by orchestrator)
`_on_dir_selected()` in app/hub/design_screen.gd (~:377-381) calls
`OS.execute("python", [compile_level.py, dir_path], output, true)` then UNCONDITIONALLY
prints "Derived layers generated" without checking the exit code. On Kons's machine that
call produces nothing (no derived/), so the false-success hid a failed compile. The
arena compiler itself works (running it manually generated the full derived set for the
custom level + all 15 levels now have derived/).

## Fix
1. Capture the OS.execute return code AND output; treat a non-zero exit OR a missing
   derived/grid.json afterward as FAILURE and show it in the UI (error label/toast),
   not a success message.
2. Make the Python invocation robust on Windows: try `python`, then `py -3`, then
   `python3`; log which worked. If none, tell the user the editor needs Python with
   opencv-python + numpy (also relevant for the Raspberry Pi target).
3. After a successful compile, confirm derived/grid.json exists before declaring done.
4. Metadata: set level_id to the level folder name (currently it can end up as the
   scene_id); ensure the level is written under <scene>/levels/<level>/. Don't write a
   stray scene.yaml into the level folder.

## Notes
- Own ONLY app/hub/**. Lock hub-design. VERIFY by actually authoring + saving + launching a game on the new level — not code-only.
- Orchestrator already back-filled derived/ for all existing levels, so testing is unblocked meanwhile.
