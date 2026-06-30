---
task_id: TASK-shared-codegen-v1
title: app/shared codegen + validators + seed content
lane: sonnet
status: ready
priority: high
owner_agent: null
depends_on: []
touches: [app/shared, content, vault]
locks_required: [app-shared]
acceptance:
  - palette.py and palette.gd byte-derivable from YAML, agree on every class
  - validators reject broken scene/level/manifest, accept seed content
  - one WALL scene + shared painted level + two stub cartridge manifests (pacman, tetris) exist and validate
---

## Context
Build the shared truth + QA per `_Briefs/03_BRIEF_contracts-qa_SONNET.md`.
This unblocks the hub (imports palette.gd) and gives Codex a seed map to derive from.

## Out of scope
Game logic, hub UI, CV algorithms.
