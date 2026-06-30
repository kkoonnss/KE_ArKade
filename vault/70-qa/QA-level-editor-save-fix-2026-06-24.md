# QA - Level Editor Save Fix - 2026-06-24

## Result
Pass for static Python parser validation.

## Covered Report
- Level Authoring Tool save failed with `Error deriving layers: list index out of range`.

## Validation Commands
- `python -m py_compile app/tools/arena_compiler/derive/navgraph.py app/tools/level_authoring/author.py app/shared/validate/validate_level.py`

## Notes
The likely crash was in `navgraph` short-spur pruning, where a queued leaf could lose all neighbors after another leaf was removed. The code now checks the current neighbor count before indexing.

Full runtime derivation was not replayed from Codex because the available bundled Python does not include `cv2` or `yaml`.
