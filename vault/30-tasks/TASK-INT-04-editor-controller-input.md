---
task_id: TASK-INT-04-editor-controller-input
stage: 6
wave: 0
priority: P1
lane: hub
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: [TASK-INT-03-editor-design-screen]
acceptance:
  - The Design screen is FULLY operable on a controller (SNES/Xbox/USB), no mouse required -> joystick/D-pad moves a paint cursor, A paints, B erases, bumpers/triggers change brush size, D-pad cycles semantic class/brush, Start opens the tool menu, Select toggles the reference photo
  - Built on the hub's existing action-based input layer (SDL3, device-agnostic) -> maps by action not device; reuses pacman's controller-menu interaction code where sensible
  - Mouse + keyboard remain a parallel, equally-capable path (desk authoring)
  - Tool palette / class picker / bounds editing / save-confirm are all reachable and legible from a pad at projector distance
  - Verified -> author a complete level end to end using ONLY a controller, then again with only mouse/keyboard; both produce a valid map
---

## Objective
Make the Design screen controller-first so it survives the move to a Raspberry Pi driven by emulator controllers, while keeping mouse/keyboard fully in. This is Kons's explicit constraint: D-pad/joystick + Start/A/B must drive every tool.

## Notes
- Same `app/hub` tree as TASK-INT-03 — depends_on it; never run both concurrently in the hub tree.
- Design the cursor + button grammar like a console paint tool (Mario-Maker-on-a-pad feel).
- Do not block on Pi hardware — validate with the Xbox + SNES-clone pads on hand.
