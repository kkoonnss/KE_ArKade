---
task_id: TASK-neon-tapper
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/tapper]
locks_required: [tapper]
acceptance:
  - Tapper fully playable serving arcade logic implemented (player pours drinks, slides them down counters to customers, collects empty mugs)
  - Multiple bar counters, advancing customer queues, tip collecting, and glass breaking penalties
  - Dynamic difficulty, wave transitions, score updates, and spawn safety
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing bar counters, mugs, and customer silhouettes
---

# Objective
Flesh out the `tapper` cartridge stub into a fully playable Tapper-like soda serving game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/tapper`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
