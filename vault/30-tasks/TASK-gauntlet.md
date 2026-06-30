---
task_id: TASK-dungeon-crawl
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/gauntlet]
locks_required: [gauntlet]
acceptance:
  - Gauntlet fully playable top-down hack & slash dungeon crawling logic implemented (player shoots projectiles, fights monster generators)
  - Monsters spawn continuously from spawners until destroyed; food/keys are collectable
  - Dynamic health decay, score updates, multiple levels/depths, and spawn safety checks
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing dungeon walls, generators, keys, and monsters
---

# Objective
Flesh out the `gauntlet` cartridge stub into a fully playable Gauntlet-like dungeon crawler conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/gauntlet`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
