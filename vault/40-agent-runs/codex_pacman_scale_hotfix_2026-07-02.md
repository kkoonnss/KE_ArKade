---
run_id: codex_pacman_scale_hotfix_2026-07-02
agent: codex
session_start: 2026-07-02T00:20:00-07:00
session_end: 2026-07-02T00:29:25.5441233-07:00
task_id: pacman-scale-render-hotfix
lane: cartridge
lock_held: cart-pacman
status: pending_kons_verify
pre_edit_commit: not-created-hotfix-under-existing-dirty-tree
close_commit: pending
escalations: []
---

## Summary

Investigated the Pac-Man screenshot where wall geometry rendered as huge rounded blue masses while characters stayed tiny. The likely cause was the renderer drawing inflated walkable-cell boundary geometry, while actors were sized from a different scale ratio. Patched Pac-Man to render maze lines from the graph edges that drive movement, and to size walls, pellets, Pac-Man, and ghosts from `grid_cell_size`.

## Changes

- `content/cartridges/pacman/main.gd`: `_draw_maze_skin()` now draws graph-edge maze strokes instead of merged walkable-cell boundaries.
- `content/cartridges/pacman/main.gd`: actor, ghost, pellet, and wall sizes now use grid-cell proportions.
- `content/cartridges/pacman/main.gd`: `original_pickups` is repopulated during `load_level()` so restart/reload paths do not inherit an empty pickup set and immediately hit win state.

## Verification

- `git diff --check -- content/cartridges/pacman/main.gd` passed.
- `rg -n "Parse Error:|<<<<<<<|>>>>>>>|=======" content/cartridges/pacman/main.gd` returned no matches.
- `rg -n "SharedLoader" content/cartridges/pacman` returned hits in `main.gd`.
- `rg -n "Adapter\.new\(\)|TabMenu\.new\(\)" content/cartridges/pacman` returned no matches.
- `Test-Path content/cartridges/pacman/adapter_base.gd` returned `False`.
- Godot runtime verification could not be completed: launching the Godot executable for a headless check produced a native Windows/Godot memory error dialog before a usable parse result.

## Open questions

None new.

## Next holder briefing

Kons should relaunch Pac-Man visually. Expected result: blue maze lines should be thin corridors again, actors should be readable at comparable scale, and the level should not immediately show `YOU WIN!` after a normal load or restart. If scale still feels off, tune the constants in `_draw_maze_skin()`, `_draw_pacman()`, and `_draw_ghost()` as grid-cell proportions rather than returning to walkable-boundary rendering.
