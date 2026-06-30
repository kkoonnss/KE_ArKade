---
task_id: TASK-stage4-stubs
stage: 4
status: done
owner_agent: Antigravity-Orchestrator
touches: [content/cartridges/frogger, content/cartridges/on_track, content/cartridges/bomberman]
locks_required: [stubs]
acceptance:
  - Frogger playable (lanes/hazards, spawn->goal)
  - On Track playable (track centerline, laps, 1-4p)
  - Bomberman playable (grid bombs, destructibles, multiplayer)
  - All skinned to the locked design system
---

## Objective
Flesh out the three prototype stubs into playable cartridges that honor IPC and the design system.
