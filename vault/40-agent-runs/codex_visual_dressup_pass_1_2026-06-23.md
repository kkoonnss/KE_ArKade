# Codex Visual Dress-Up Pass 1 - 2026-06-23

## Scope
First broad code-native vector-art pass to move cartridge visuals away from raw circles/rectangles and toward recognizable classic-arcade silhouettes while preserving black backgrounds, translucent fills, glowing outlines, and projection-friendly contrast.

## Visual Upgrades
- Platform/action template:
  - Girder platforms now include lower rails and diagonal bracing.
  - Ladders now have side rails and rungs.
  - Player characters now have heads, bodies, arms, legs, and eyes.
  - Enemies now have faces/limbs instead of plain circles.
  - Bubbles, eggs, pickups, rocks, Dig Dug-style enemies, dungeon generators, warriors, marbles, bar counters, mugs, customers, bartender, Tempest claws, and Tempest ship all gained distinctive vector silhouettes.
- Robotron/multi-game template:
  - Robotron enemies now draw as robots with head/body/arms/antennae.
  - Humans now draw as tiny stick-silhouette rescues.
  - Player now draws as a twin-stick hero.
  - Centipede barriers/segments, aliens, burger layers, food enemies, chef, cities, houses, bicycle rider, cube hopper, and cube enemies gained more readable silhouettes.
- Arcade/action template:
  - Asteroids gained translucent fills and vertex highlights.
  - Tron vehicles now draw as bikes/cycles.
  - Pong paddles now have filled paddle bodies and glow cores.
  - Smash TV enemies now draw as robots and spawner cores.
  - Battlezone tanks now have larger hulls, turrets, and tread marks.
  - Player ships now have cockpit/highlight and thrust detail.

## Propagated Cartridges
- `donkey_kong`
- `gauntlet`
- `marble_madness`
- `bubble_bobble`
- `joust`
- `tempest`
- `robotron_2084`
- `burger_time`
- `paperboy`
- `qbert`
- `lunar_lander`
- `space_invaders`
- `galaga`
- `asteroids`
- `tron`
- `pong`
- `smash_tv`
- `battlezone`

## Validation
Headless `--quit` validation passed for the changed template representatives and propagated cartridges:
- `donkey_kong`
- `gauntlet`
- `marble_madness`
- `bubble_bobble`
- `joust`
- `tempest`
- `robotron_2084`
- `burger_time`
- `paperboy`
- `qbert`
- `lunar_lander`
- `space_invaders`
- `galaga`
- `asteroids`
- `tron`
- `pong`
- `smash_tv`
- `battlezone`

## Notes
This pass is intentionally modest fidelity: identifiable silhouettes and decorative detail without raster sprites or heavy illustration. Bespoke cartridges that already had custom art direction, such as `rampage`, `bomberman`, `pacman`, `tetris`, `frogger`, `on_track`, and the recently adjusted `snake`, were left for a focused second pass.
