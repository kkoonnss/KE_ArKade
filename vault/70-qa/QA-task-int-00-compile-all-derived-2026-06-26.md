---
task_id: TASK-INT-00-compile-all-derived
status: pass
date: 2026-06-26
agent: KE_ArKade_260626_132556
---

# QA - TASK-INT-00 compile-all-derived

Acceptance checks:
- Headless single-level compiler exists at
  `app/tools/arena_compiler/compile_level.py`.
- Batch compiler exists at
  `app/tools/arena_compiler/batch_compile_levels.py`.
- Golden tests cover the full derived set, including occupancy,
  platform edges, track centerline, and authoring profile.
- Batch run regenerated all existing `content/scenes/**/levels/*/derived/`
  outputs.
- Explicit completeness scan found 39 level directories and 0 missing required
  derived files.
- `classic_gta` now has a complete `derived/` set.
- No `skimage` or `networkx` references remain under `app/tools`.

Verification:
- `python -m unittest app.tools.tests.test_compiler` -> OK, 5 tests.
- `python -m py_compile ...` -> OK.
- `python -m app.tools.arena_compiler.batch_compile_levels` -> compiled 39,
  incomplete `[]`.

Result: PASS.
