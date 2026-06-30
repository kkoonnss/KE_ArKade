---
task_id: TASK-mvp-cartridges
title: Two MVP cartridges — Pac-Man + Tetris (Godot, separate-process)
lane: antigravity
status: ready
priority: high
owner_agent: null
depends_on: [TASK-hub-shell-v1, TASK-arena-compiler-v1, TASK-shared-codegen-v1]
touches: [content/cartridges]
locks_required: [content-cartridges]
acceptance:
  - both run as separate processes honoring the IPC + cartridge schema
  - both read the SAME untouched semantic_map.png on a wall scene
  - Pac-Man consumes navgraph; Tetris consumes container (wall-down)
  - keyboard playable first, then Xbox + SNES-clone; Tetris designed for up to 4p
---

## Context
Build after the loopback cartridge proves IPC. See
`_Briefs/02_BRIEF_godot-hub_ANTIGRAVITY.md` (Work package 2). Original names,
homage mechanics — NOT trademarked IP. Awkward map fits are acceptable/fun.

## Out of scope
Racing ("Trace") = Phase 2. Floor/tracker modes = later, per-game.
