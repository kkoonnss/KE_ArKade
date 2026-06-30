---
task_id: TASK-INT-00-compile-all-derived
stage: 6
wave: 0
priority: P0
lane: tools
archetype: n/a
status: done
owner_agent: "KE_ArKade_I#1_260626_132732_"
touches: [app/tools/arena_compiler, app/tools/tests]
locks_required: [tools-compiler]
depends_on: []
acceptance:
  - One headless entry point (e.g. app/tools/arena_compiler/compile_level.py) takes a level dir (or semantic_map.png) and regenerates the FULL derived set in one call -> navgraph.json, container.json, grid.json, occupancy.png, platform_edges.json, track_centerline.json, authoring_profile.json
  - Pure function -> same map in, same bytes out; wired into golden tests for every layer
  - Batch script regenerates derived/** for ALL existing levels in content/scenes/** (fixes the ~26 levels missing grid/container and the empty classic_gta)
  - Verified -> every level under content/scenes/** has a complete derived/ set after running it; golden tests green from a clean checkout
  - Extracts the derive-orchestration currently inlined in app/tools/level_authoring/author.py into this reusable callable (author + hub Design screen both call it)
---

## Objective
Make the universal substrate truly universal. Today derived layers are baked ad hoc by the authoring tool, so only ~6 of 33 levels have `grid.json`/`container.json` and `classic_gta` has none. Every archetype adapter in Wave 1+ assumes the full derived set exists on every level. Build one headless, golden-tested compile-all-derived entry point and batch-run it across all existing levels.

## Notes
- Do NOT change the frozen palette or schemas. Read-only against `app/shared/palette`.
- This is the gate for the whole stage's cartridge work — highest priority in the `tools` lane.
- Keep it Pi-friendly (plain OpenCV/numpy, no exotic deps) so the hub Design screen can shell out to it later, including on a Pi.
