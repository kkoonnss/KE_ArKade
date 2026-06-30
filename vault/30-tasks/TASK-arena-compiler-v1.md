---
task_id: TASK-arena-compiler-v1
title: Arena compiler + derived layers (navgraph, occupancy)
lane: codex
status: ready
priority: high
owner_agent: null
depends_on: []
touches: [app/tools]
locks_required: [app-tools]
acceptance:
  - compile produces palette-valid semantic_map.png from a painted source
  - navgraph.json + container.json + occupancy.png are byte-stable vs committed goldens
  - level-authoring tool: slider mode + paint-over-photo (opacity toggle) produce a valid map
  - unit tests + 3 golden fixtures under app/tools/tests
---

## Context
Build the translation layer per `_Briefs/01_BRIEF_arena-compiler_CODEX.md`.
Read `vault/50-schemas/semantic-palette-v1.yaml` and `vault/20-architecture/arena-pipeline.md`.

## Out of scope
ChArUco (Phase 2), hub UI, game logic.
