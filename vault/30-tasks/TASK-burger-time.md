---
task_id: TASK-cyber-burger
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/burger_time]
locks_required: [burger_time]
acceptance:
  - BurgerTime fully playable logic (player walks over burger ingredients to drop them down)
  - Enemies chasing player (hot dogs, pickles, eggs) that can be crushed by dropping ingredients
  - Reads level derived grid/navgraph to construct platforms and ladders dynamically
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Bright neon style matching the design system
---

# Objective
Flesh out the `burger_time` cartridge stub into a fully playable BurgerTime clone, parsing the level layout to extract platforms, walkways, and vertical ladders dynamically.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
