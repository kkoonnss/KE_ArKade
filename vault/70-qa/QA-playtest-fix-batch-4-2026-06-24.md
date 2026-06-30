# QA - Playtest Fix Batch 4 - 2026-06-24

## Result
Pass for targeted Godot headless startup/parser validation.

## Covered Reports
- Galaga should have enemies flying in/out of battle and diving: Galaga now uses entry, formation, dive, and return states.
- Galaga should feel like flying forward: Galaga now has a downward moving starfield.
- Gauntlet aim should persist from movement: dungeon crawler aim now remembers last movement direction.
- Joust win condition unclear: Joust now starts the next wave when enemies are cleared and displays hit-from-above/collect-eggs guidance.
- Two On Track classic levels: duplicate `classic_on_track` hub mappings and level directory were removed.
- Paperboy throw direction should persist: throw direction now follows last horizontal movement.
- Rampage will not load: classic Rampage level now declares semantic/derived layer metadata required by the hub compatibility gate.
- Robotron aim should persist: firing direction now remembers last aim vector.
- Smash TV aim should persist: firing direction now remembers last aim vector.
- Street Gob title should be GTA and flicker/restart: `gta` is now presented as `GTA`, and duplicate ready broadcast on reset was removed.

## Validation Commands
All affected cartridges and the hub passed `--headless --quit`:
- `galaga`
- `gauntlet`
- `joust`
- `paperboy`
- `robotron_2084`
- `smash_tv`
- `gta`
- `rampage`
- `app/hub`

Rampage was also validated with the classic Rampage level args.

## Remaining Risk
Headless validation does not simulate full controller feel, wave balance, or live hub restart behavior. Manual playtest should confirm Galaga dive cadence, Joust collision readability, Rampage hub launch, and GTA hub flicker behavior.
