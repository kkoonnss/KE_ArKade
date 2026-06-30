# QA - Playtest Fix Batch 2 - 2026-06-23

## Result
Pass for targeted headless startup/parser validation.

## Covered Reports
- Rampage does not open: hub classic-level mapping now includes `classic_rampage -> rampage`; Rampage cartridge also passes standalone headless validation.
- Robotron does not move: fixed `robotron_2084` safe movement to avoid snapping every frame to the current cell center.
- Smash TV does not move: fixed `smash_tv` safe movement with the same continuous-position rule.
- Snake should look more like a snake: head/body rendering improved while keeping neon-vector style.
- On Track classic name: manifest `game_name` and first skin label now use `On Track`.
- Tapper moves too far on one press: lane changes are rate-limited to one row per tap/short repeat.
- On Track ship should be between lines: track rails now render offset around the checkpoint center path.

## Validation Commands
- `robotron_2084`: pass
- `smash_tv`: pass
- `snake`: pass
- `tapper`: pass
- `on_track`: pass
- `rampage`: pass
- `app/hub`: pass

## Remaining Risk
Headless validation confirms projects load and scripts parse. It does not simulate held-key/tap feel or visually inspect the hub card, so the next manual playtest should verify the exact row-step timing, On Track lane spacing, and Rampage launch from the classic-pack UI.
