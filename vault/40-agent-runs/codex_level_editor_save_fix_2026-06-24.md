# Codex Level Editor Save Fix - 2026-06-24

## Scope
Fixed a Level Authoring Tool save failure reported as:

`Error deriving layers: list index out of range`

The failure appeared while saving `scene_demo_wall/levels/260624_095010`, after the semantic map had been written but before derived files were completed.

## Root Cause
The derived `navgraph` generator prunes short skeleton spurs by collecting all current leaves, then removing qualifying leaves in that batch. On dense or fragmented semantic maps, removing one leaf can leave another queued leaf with no remaining neighbors. The old code still indexed `neighbors[0]`, causing `list index out of range`.

## Changes
- `app/tools/arena_compiler/derive/navgraph.py`
  - Re-checks each queued leaf's live neighbor list before indexing it.
  - Skips leaves that are no longer degree-1 after previous removals in the same prune pass.
- `app/tools/level_authoring/author.py`
  - Wraps each derived-layer step with its layer name.
  - Future save errors will identify the failing layer, such as `navgraph: ...`, instead of only reporting a generic exception.

## Validation
- Python syntax compilation passed for:
  - `app/tools/arena_compiler/derive/navgraph.py`
  - `app/tools/level_authoring/author.py`
  - `app/shared/validate/validate_level.py`

## Remaining Risk
The local Codex bundled Python lacks `cv2` and `yaml`, so full GUI/runtime derivation could not be replayed from this shell. The patch targets the exact `list index out of range` failure mode in `navgraph` and improves diagnostics if a different derive layer fails later.
