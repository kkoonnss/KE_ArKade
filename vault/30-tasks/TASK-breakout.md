---
task_id: TASK-brick-breaker
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/breakout]
locks_required: [breakout]
acceptance:
  - Breakout fully playable brick breaking logic implemented (player controls paddle at bottom, ball bounces and breaks bricks)
  - Different brick layers/types (e.g. multi-hit bricks, speed-up bricks, power-ups)
  - Dynamic score updates, levels/wave transitions, and ball spawn safety
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing bricks, paddle, and particles
---

# Objective
Flesh out the `breakout` cartridge stub into a fully playable Breakout-like brick breaking game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/breakout`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
