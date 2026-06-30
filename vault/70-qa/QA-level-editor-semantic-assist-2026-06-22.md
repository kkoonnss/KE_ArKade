# QA - Level Editor Semantic Assist

Date: 2026-06-22
Agent: Codex

## Result

Partial pass.

The edited level-authoring tool compiles successfully. Full compiler unit tests were not executable in the available bundled Python because OpenCV (`cv2`) is missing from that runtime.

## Checks

- `app/tools/level_authoring/author.py` syntax compile: pass.
- Compiler unittest import: blocked by missing dependency `cv2`.

## Notes

The architecture now favors:

- one authored `semantic_map.png`;
- shared generated compiler layers in `derived/**`;
- one per-cartridge `user://level_adjustments.json` file keyed by `<scene_id>/<level_id>`;
- in-memory game-fit masks generated on cartridge start when a game needs them.
- shared Tab-menu persistence with game-specific controls, ranges, and baked defaults as each cartridge is refined.
