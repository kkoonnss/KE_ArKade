# QA - Playtest Fix Batch 3 - 2026-06-24

## Result
Pass for targeted Godot headless startup/parser validation.

## Covered Reports
- Battlezone bullets not killing enemies: fixed with bullet-tick enemy collision.
- Breakout powerups too subtle: added timed WIDE/SLOW/LASER/SHIELD states with HUD and visible effects.
- Bubble Bobble bubbles ineffective: bubble hits now trap enemies directly.
- Bubble Bobble player stuck bottom: bottom floor now marks the player grounded.
- Burger Time start/help/menu confusion: Burger Time now waits at a start/help overlay until Enter/Space.
- Centipede not getting harder: wave scaling increased.
- Defender not getting harder: wave scaling increased.
- Dig Dug should be mostly ground: playfield now starts as mostly dirt with dug tunnels.
- Donkey Kong barrels should descend ladders: barrels now sometimes roll down ladders.
- Frogger title bar says Frogger: Godot project title now says Frogger.

## Validation Commands
All affected cartridges passed `--headless --quit`:
- `battlezone`
- `breakout`
- `bubble_bobble`
- `burger_time`
- `centipede`
- `defender`
- `dig_dug`
- `donkey_kong`
- `frogger`

## Remaining Risk
Headless validation does not simulate input timing or gameplay feel. Manual playtest should verify Battlezone hit feel, Breakout laser/shield readability, Bubble Bobble capture timing, Burger Time start overlay flow, and Dig Dug tunnel/enemy path balance.
