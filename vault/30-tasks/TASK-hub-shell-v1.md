---
task_id: TASK-hub-shell-v1
title: Godot hub shell + separate-process launcher + IPC
lane: antigravity
status: ready
priority: high
owner_agent: null
depends_on: [TASK-shared-codegen-v1]
touches: [app/hub]
locks_required: [app-hub]
acceptance:
  - boots to scenes gallery from content/scenes
  - launches a stub cartridge as a separate process; crash/heartbeat-timeout returns to UI cleanly
  - Panic Black + Last-Known-Good work; keyboard + Xbox + SNES-clone slot 1-4
  - stable 60 fps Profile L
---

## Context
Build the kiosk launcher per `_Briefs/02_BRIEF_godot-hub_ANTIGRAVITY.md`.
Read `vault/20-architecture/hub-architecture.md` + `input-and-players.md`.

## Out of scope
In-process cartridges (locked: separate process), CV, map authoring.
