---
task_id: TASK-marble-run
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/marble_madness]
locks_required: [marble_madness]
acceptance:
  - Marble Madness fully playable rolling marble physics logic implemented (player guides marble through a race course with hazards)
  - Hazards like enemies, slippery areas, and drop-offs that destroy the marble
  - Time limit, checkpoint bonuses, dynamic score updates, and spawn safety
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing grid tracks, height contours, and marble particles
---

# Objective
Flesh out the `marble_madness` cartridge stub into a fully playable Marble Madness-like isometric-styled rolling marble game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/marble_madness`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
