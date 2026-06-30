---
task_id: TASK-neon-defender
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/defender]
locks_required: [defender]
acceptance:
  - Defender fully playable logic (wrapping side-scrolling level, player ship shoots and rescues humanoids)
  - Radar minimap at top showing active positions of players, landers, mutants, and humanoids
  - Safe navigation utilizing the level's empty corridors and solid structures as obstacles
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Neon outline glow rendering for ships, targets, and terrain
---

# Objective
Flesh out the `defender` cartridge stub into a fully playable side-scrolling Defender clone, leveraging level occupancy map data for obstacle collision.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
