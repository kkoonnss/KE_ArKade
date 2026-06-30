# QA Note: TASK-INT-00-compile-all-derived

## Acceptance Criteria Check
- [x] **One headless entry point:** `app/tools/arena_compiler/compile_level.py:compile_level()` regenerates the full derived set.
- [x] **Pure function:** `test_compiler.py` runs byte-for-byte matching on golden tests for all derived outputs. JSONs are normalized (indent=2, sort_keys=True).
- [x] **Batch script:** `batch_compile_levels.py` regenerates derived layers across all levels in `content/scenes/**`.
- [x] **Verified output:** Tested that running `batch_compile_levels.py` populated the missing `grid.json` and `container.json` files for all maps, including `classic_gta`.
- [x] **Extracted logic:** `author.py` uses `compile_level(dir_path)` directly instead of performing inline OpenCV generation.

All criteria met. Safe for Wave 1 archetype adapters to assume the derived set is present on all levels.
