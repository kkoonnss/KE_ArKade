---
task_id: TASK-calibration-runtime-scene-warp
stage: output-mapping
status: pending_kons_verify
owner_agent: codex
lane: shared+cartridge
locks_required: [shared-scene-calibration-runtime, cart-pacman-scene-calibration-runtime]
touches:
  - app/shared/shared_loader.gd
  - app/shared/calibration/final_output_warp.gd
  - content/cartridges/pacman/project.godot
  - content/cartridges/pacman/runtime_main.gd
  - content/cartridges/pacman/runtime_main.tscn
---

# Calibration Runtime Scene Warp

## Objective

Apply saved scene calibration profiles as a final visual output pass for
launched games. Gameplay, semantic maps, pathfinding, collision, and level
interpretation must remain in the normal flattened 1920x1080 stage.

## Decisions

- Calibration is scene-scoped: `content/scenes/<scene_id>/calibration/current.yaml`.
- Cartridges consume the scene profile passed by `--scene`; they do not own
  calibration data.
- Runtime mapping is a post-process warp of the final frame, not a gameplay
  coordinate transform.
- The first proof is Pac-Man because it is the current known-good full loop.
  The warp implementation itself lives in `app/shared`.

## Acceptance

- Shared code can load and parse `calibration/current.yaml`.
- Shared code draws a final viewport texture through the saved output mesh.
- Missing or invalid calibration falls back to an unwarped final frame.
- Pac-Man launches through a runtime wrapper that renders the existing game
  scene into a canonical 1920x1080 SubViewport.
- The wrapper draws the SubViewport as the final mapped output and aspect-fits
  the canonical stage with black bars on non-16:9 windows.
- Pac-Man still reads `--scene` and `--level` normally; gameplay remains
  canonical and flattened.

## Status

Shared runtime loading/drawing code exists and Pac-Man now launches through
`runtime_main.tscn`, which renders the existing flat `main.tscn` game into a
1920x1080 `SubViewport` before drawing that finished texture through the
scene calibration mesh.

The earlier Pac-Man visual-coordinate mapping experiment has been removed from
`main.gd`; gameplay and drawing are flat again inside the canonical stage.
This is pending Kons visual verification because the local environment refused
another Godot launch on usage limits during the final wrapper pass.
