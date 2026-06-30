---
task_id: TASK-bubble-dragons
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/bubble_bobble]
locks_required: [bubble_bobble]
acceptance:
  - Bubble Bobble fully playable platformer logic implemented (player blows bubbles to trap enemies, then pops them)
  - Trapped enemies float up, and pop when touched, spawning fruit or points
  - Dynamic score updates, wave transitions, enemy AI, and spawn safety checks
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing bubbles, platforms, and characters
---

# Objective
Flesh out the `bubble_bobble` cartridge stub into a fully playable Bubble Bobble-like bubble shooter platformer conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/bubble_bobble`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
