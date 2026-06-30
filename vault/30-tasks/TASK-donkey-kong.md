---
task_id: TASK-barrel-jumper
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/donkey_kong]
locks_required: [donkey_kong]
acceptance:
  - Donkey Kong fully playable platforming logic implemented (player jumps over rolling barrels, climbs ladders)
  - Barrels spawn at top, roll down inclined girders, and fall off ladders randomly
  - Safe spawns, dynamic score updates, levels/wave transitions, and neon graphical representation
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing ladders, platforms, and barrels
---

# Objective
Flesh out the `donkey_kong` cartridge stub into a fully playable Donkey Kong-like platformer conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/donkey_kong`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
