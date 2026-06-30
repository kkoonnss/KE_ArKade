---
agent: KE_ArKade_260626_132556
task_id: TASK-INT-00-compile-all-derived
status: done
date: 2026-06-26
---

# TASK-INT-00 compile-all-derived

Implemented a reusable headless compiler entry point:
`app/tools/arena_compiler/compile_level.py`.

Added batch runner:
`app/tools/arena_compiler/batch_compile_levels.py`.

Integrated the current authoring backend:
`app/tools/level_authoring/author_backend.py` now calls `compile_level(...)`
after writing a semantic map.

Notes:
- Full derived set is regenerated in one call:
  `navgraph.json`, `container.json`, `grid.json`, `occupancy.png`,
  `platform_edges.json`, `track_centerline.json`, `authoring_profile.json`.
- Existing levels without `semantic_map.png` are handled via deterministic
  legacy occupancy fallback and record `source_kind: legacy_occupancy` in
  `authoring_profile.json`.
- `navgraph.py` no longer depends on `skimage` or `networkx`; the compiler path
  is OpenCV/numpy/PyYAML only.
- The task file was already marked `done` by another recorded owner when this
  close-out ran, and `vault/35-locks/tools-compiler.md` was already absent.

Run log:
- Installed `app/tools/requirements.txt` into the available Codex runtime Python
  so real OpenCV tests could execute.
- `python -m unittest app.tools.tests.test_compiler` -> OK, 5 tests.
- `python -m py_compile` on compiler, batch, derive, authoring backend, tests
  -> OK.
- `python -m app.tools.arena_compiler.batch_compile_levels` -> compiled 39
  level dirs, `incomplete: []`.
- Explicit derived completeness scan -> `LevelCount: 39`, `MissingCount: 0`.

Frozen schemas were read only and not edited.
