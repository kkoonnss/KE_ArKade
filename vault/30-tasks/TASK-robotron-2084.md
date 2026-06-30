---
task_id: TASK-robo-swarm
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/robotron_2084]
locks_required: [robotron_2084]
acceptance:
  - Robotron: 2084 fully playable twin-stick shooter logic (movement + shooting in any direction)
  - Swarms of enemies chasing player; human targets to rescue for bonus points
  - Reads level derived navgraph or empty cells for safe spawn zones for player and entities
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Saturated neon design with particle-rich explosions and clean grid backgrounds
---

# Objective
Flesh out the `robotron_2084` cartridge stub into a twin-stick shooter inspired by Robotron: 2084, utilizing the level map boundaries for spawn placements and entity constraints.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
