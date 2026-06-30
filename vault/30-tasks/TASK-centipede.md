---
task_id: TASK-cyber-centipede
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/centipede]
locks_required: [centipede]
acceptance:
  - Centipede fully playable logic implemented (player moves left/right/up/down in lower area, shoots up)
  - Centipede spawns and moves down the screen winding through destructible mushroom barriers (using the level grid)
  - Destruction of mushroom segments and centipede segments, score tracking
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Styled with high-contrast neon colors and glows matching the design system
---

# Objective
Flesh out the `centipede` cartridge stub into a fully playable Centipede clone utilizing the level grid for mushroom layout, supporting 1-4 players, and integrating with the hub IPC.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
