---
task_id: TASK-neon-snake
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/snake]
locks_required: [snake]
acceptance:
  - Snake fully playable grid-locked growth and movement logic implemented (snake eats food, grows longer, dies on self/wall collision)
  - Multiplayer support, power-ups, food spawning avoiding obstacles/snake body
  - Dynamic speed adjustments, score updates, and level/boundary checks
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing neon snake body and food particles
---

# Objective
Flesh out the `snake` cartridge stub into a fully playable Snake-like eating and growth game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/snake`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
