---
task_id: TASK-calibration-output-mapping-presets
stage: output-mapping
status: in_progress
owner_agent: codex
lane: tools
locks_required: [tools-calibration-presets]
touches: [app/tools/calibration, app/tools/tests, app/tools/README.md]
---

# Calibration Output Mapping Presets

## Objective

Turn Calibrate into the output-mapping layer for KE_ArKade. Calibration should
apply to the final rendered frame for a physical projector/location, not to a
single game or level.

## Recommended Workflow

1. Pick or create a calibration preset for the physical setup.
2. Project a full-screen test pattern.
3. Drag the four outer corner pins to fit the wall or projection surface.
4. Save as a named preset and assign it to the active scene.
5. If the wall/projector needs local correction, increase the mesh from `2x2`
   to `3x3` or `4x4` and nudge interior pins.
6. Keep per-game/per-level adjustment knobs separate from output calibration.

## Data Ownership

- Presets are reusable output profiles.
- `content/scenes/<scene_id>/calibration/current.yaml` is the active calibration
  selected for a scene.
- Levels and cartridges read the same semantic map and should not own projector
  warp state.

## Build Slices

1. Tools contract: create/validate calibration profile YAML.
2. Hub Calibrate screen: list presets, create preset, project test pattern,
   edit pins, save/apply.
3. Runtime output wrapper: render cartridge output to a normal frame, then apply
   profile warp to the final projector window.
4. Second-monitor operator mode: unwarped control view on monitor A, warped
   projector output on monitor B.

## Acceptance

- `2x2` profile supports normal global corner pinning.
- Denser profiles preserve the same format and add refinement pins.
- A profile validates before being used as scene `current.yaml`.
- Hub no longer treats Calibrate as a generic coming-soon placeholder.
