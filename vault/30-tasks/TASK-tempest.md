---
task_id: TASK-neon-tempest
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/tempest]
locks_required: [tempest]
acceptance:
  - Tempest fully playable tube shooter logic implemented (player moves along outer rim of 3D-like geometric tube, shooting down lanes)
  - Enemies crawl up lanes, can capture player if they reach the rim, superzapper utility
  - Dynamic level/tube configurations, score updates, wave transitions, and spawn safety
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing wireframe tubes and vector enemies
---

# Objective
Flesh out the `tempest` cartridge stub into a fully playable Tempest-like tube shooter conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/tempest`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
