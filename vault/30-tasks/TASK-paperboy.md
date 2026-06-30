---
task_id: TASK-cyber-paperboy
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/paperboy]
locks_required: [paperboy]
acceptance:
  - Paperboy fully playable logic (auto-scrolling isometric/perspective neighborhood, throwing papers)
  - Subscribing houses marked as safe targets; non-subscribers and obstacles as hazards
  - Reads level derived navgraph and semantic paths to layout the road, sidewalks, and houses
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Saturated neon graphics, glowing indicators, paper trajectories physics
---

# Objective
Flesh out the `paperboy` cartridge stub into a fully playable Paperboy clone, utilizing the level map layers to extract roads, curbs, houses, and subscriber targets.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
