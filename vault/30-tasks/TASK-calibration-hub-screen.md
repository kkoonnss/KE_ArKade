---
task_id: TASK-calibration-hub-screen
stage: output-mapping
status: pending_kons_verify
owner_agent: codex
lane: hub
locks_required: [hub-calibration-screen]
touches: [app/hub/main.gd, app/hub/calibrate_screen.gd, app/hub/calibrate_screen.tscn]
---

# Calibration Hub Screen

## Objective

Replace the visible Calibrate placeholder with the first usable output-mapping
screen.

## Acceptance

- Calibrate nav opens a full-screen calibration tool, not a coming-soon modal.
- Tool shows a projection test grid and draggable mesh pins.
- Mesh can switch between `2x2`, `3x3`, and `4x4`.
- Save writes the active scene's `calibration/current.yaml`.
- Hub and calibration scene parse/load in Godot.

## Status

Implemented and parser-checked. Needs Kons visual confirmation in-window.
