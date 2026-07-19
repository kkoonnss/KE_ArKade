---
task_id: TASK-calibration-fullscale-output
stage: output-mapping
status: pending_kons_verify
owner_agent: codex
lane: hub
locks_required: [hub-calibration-fullscale]
touches: [app/hub/main.gd, app/hub/calibrate_screen.gd]
---

# Calibration Full-Scale Output

## Objective

Make calibration match game output one-to-one by using the full viewport as the
mapping surface, with controls floating above it instead of shrinking the
calibration canvas.

## Acceptance

- Calibrate draws the grid/reference over the whole viewport.
- Controls can be hidden so only output mapping remains visible.
- Scene/level reference backgrounds can be selected for alignment.
- Hub settings expose an output screen selector.
- Game launches pass the selected output screen to Godot with `--screen N`.
- Every scene has a canonical `calibration/reference.png` capped to 1920x1080.
- Calibrate distinguishes input/source mask adjustment from output warp pins.
- Input adjustment is image-space cropping: pins live in source image pixels,
  default to the reference image corners, and are edited in a separate Input
  view.
- Output adjustment is stage-space projection mapping: the selected input crop
  fills the full stage and is then warped by output mesh pins.
- Input/Output controls visibly highlight the active edit view.
- Calibration panel removes nudge/scale buttons, visible reference selection,
  and Hide Controls in favor of direct pin editing and Collapse.
- Output subdivisions are now independent H/V tab controls with levels 1-4.
  The actual point counts are 2, 3, 5, and 9, so each plus inserts midpoints
  and each minus removes midpoint layers while preserving remaining points.
- Input and Output now have separate tab bodies. Output shows H/V subdivisions,
  Match Input, Match Source, and Match Screen. Input shows Match Source,
  Match Output, and Match Screen. Save and Close remain common controls below
  the tab-specific sections.
- Match Source now uses the same true 1920x1080 canonical stage fit for both
  sides. Match Input and Match Output now transfer literal corner geometry
  through the source-image-to-stage mapping instead of only matching averaged
  aspect ratios.
- Follow-up: source-stage matching now derives from the same visible fitted
  reference image rect used by the Input view, then converts that rect back
  into output stage coordinates. Input and Output line segments now hover,
  select, drag, and nudge with arrow keys just like individual pins.
- Follow-up: the calibrator mapping surface now aspect-fits the 1920x1080
  stage inside the current window instead of reshaping to the raw window size.
  Window resizing creates black bars outside the locked stage, matching the
  hub/game canvas behavior.
- Follow-up: trimmed the calibration panel into three sparse zones: scene
  selector at the top, Input/Output actions centered, and Save/Close pinned at
  the bottom. Removed visible header/status/grid/view/fullscreen text; F11 and
  H shortcuts remain available.

## Status

Implemented and parser-checked. Needs in-window/projector confirmation and a
follow-up runtime pass to apply saved calibration profiles inside launched
games. Later two-screen mode should keep final output visible on the projector
while the operator monitor switches between Input and Output editing views.

Runtime follow-up started in `TASK-calibration-runtime-scene-warp`: the shared
post-process warp now loads scene-level `calibration/current.yaml`, with
Pac-Man as the first cartridge proof.
