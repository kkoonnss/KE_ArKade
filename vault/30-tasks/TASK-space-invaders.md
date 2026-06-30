---
task_id: TASK-neon-invaders
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/space_invaders]
locks_required: [space_invaders]
acceptance:
  - Space Invaders fully playable logic implemented (player moves left/right at bottom, shoots up)
  - Grid of aliens moving horizontally, dropping down, shooting back at the player
  - Shields/barricades generated from the level's destructible semantic maps
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Saturated neon colors, glowing lasers, retro particle explosions
---

# Objective
Flesh out the `space_invaders` cartridge stub into a fully playable Space Invaders clone, utilizing the level map for protective shield locations and supporting 1-4 players.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
