---
task_id: TASK-missile-defense
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/missile_command]
locks_required: [missile_command]
acceptance:
  - Missile Command fully playable logic (incoming ICBM paths targeting cities/silos, player shoots counter-missiles)
  - Mapped positions of cities/silos matching level spawn cells or landmarks
  - Screen-shake, expanding explosive circles, score tracking, ammo counts
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Beautiful neon vector layout with glowing missile trails and bright expanding explosions
---

# Objective
Flesh out the `missile_command` cartridge stub into a fully playable Missile Command clone, mapping base targets to level spawn points and enforcing bounds.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
