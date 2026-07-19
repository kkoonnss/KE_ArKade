---
run_id: codex_calibration_output_mapping_presets_2026-07-05
agent: codex
session_start: 2026-07-05T01:12:00-07:00
session_end: 2026-07-05T01:28:00-07:00
task_id: TASK-calibration-output-mapping-presets
lane: tools
lock_held: tools-calibration-presets
status: pending_next_slice
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Started the Calibrate rebuild by defining calibration as reusable output-mapping
profiles. The chosen workflow is preset-first: tune a physical projector/wall
setup, save it as a named profile, then assign/export it to the scene's active
`calibration/current.yaml`. This keeps projector warp separate from level and
cartridge tuning.

## Changes

- Added `app/tools/calibration/profile.py` for creating and validating
  calibration profiles.
- Added `app/tools/tests/test_calibration_profile.py` covering default 2x2
  corner pinning, denser refinement meshes, YAML/JSON round-trip, and validation
  failure.
- Updated `app/tools/README.md` with the recommended calibration preset
  workflow and CLI usage.
- Added `vault/30-tasks/TASK-calibration-output-mapping-presets.md` to track
  the broader build slices.
- Created smoke artifact
  `vault/70-qa/calibration_profile_smoke_2026-07-05.yaml`.

## Verification

- `python` and `py` were not available on PATH.
- Used bundled runtime:
  `C:\Users\Kons\.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe`
- `-m py_compile app\tools\calibration\profile.py app\tools\tests\test_calibration_profile.py` passed.
- `-m unittest app.tools.tests.test_calibration_profile` passed: 4 tests.
- CLI smoke:
  `app\tools\calibration\profile.py new vault\70-qa\calibration_profile_smoke_2026-07-05.yaml --profile-id studio_wall --label "Studio Wall" --mesh 3x3 --scene-id scene_demo_wall`
  wrote the file successfully.
- CLI validate:
  `app\tools\calibration\profile.py validate vault\70-qa\calibration_profile_smoke_2026-07-05.yaml`
  reported valid.

## Backup Status

- No git commit was made because the repo already had a large unrelated dirty
  working tree across hub/shared/cartridges/content. A pre-edit snapshot commit
  would have captured unrelated work.
- Backup remains pending until an orchestrator/housekeeping pass snapshots the
  existing tree cleanly.

## Open Questions

- None new. The next architectural choice is implementation strategy for the
  Godot runtime wrapper: shared boot scene versus per-cartridge integration.

## Next Holder Briefing

Next slice should be hub/shared, not tools: build the Calibrate screen that can
create/select profiles, project a test pattern, edit pins, and save/apply the
profile to the active scene. Keep the runtime target as final-frame output
warping; do not put projector warp logic inside individual cartridge gameplay.
