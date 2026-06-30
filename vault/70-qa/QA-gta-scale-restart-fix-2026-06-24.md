# QA - GTA Scale + Restart Fix - 2026-06-24

## Result
Pass for targeted Godot headless startup/parser validation.

## Covered Reports
- GTA is smaller screen size: added viewport-fit scaling and centered draw transform.
- GTA keeps restarting: fixed socket polling/ready timing and ignored redundant load resets for the same level.

## Validation Commands
Passed:
- `gta` standalone
- `gta` with `classic_gta` level args

## Remaining Risk
Headless validation does not simulate the full hub IPC lifecycle. Manual hub playtest should confirm there are no repeated relaunches and the map fills the projection area.
