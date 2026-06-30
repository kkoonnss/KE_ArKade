---
task_id: TASK-drill-dug
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/dig_dug]
locks_required: [dig_dug]
acceptance:
  - Dig Dug fully playable digging and inflation logic implemented (player digs tunnels, pumps enemies until they pop)
  - Enemies roam tunnels, can turn into ghosts to pass through walls, and drop rocks to crush them
  - Dynamic score updates, levels/wave transitions, and spawn safety checks
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing dirt, tunnels, rocks, and pumps
---

# Objective
Flesh out the `dig_dug` cartridge stub into a fully playable Dig Dug-like digging action game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/dig_dug`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
