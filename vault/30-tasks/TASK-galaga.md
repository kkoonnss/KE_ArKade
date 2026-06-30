---
task_id: TASK-star-fighter
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/galaga]
locks_required: [galaga]
acceptance:
  - Galaga fully playable logic implemented (player shoots from bottom, enemies swoop down in formations)
  - Capturing of player ship by boss alien and dual-ship functionality when rescued
  - Dynamic score updates, wave transitions, and sound effects/particle feedback
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing stars and bullets
---

# Objective
Flesh out the `galaga` cartridge stub into a fully playable Galaga-like space shooter conforming to the design brief and IPC requirements.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
