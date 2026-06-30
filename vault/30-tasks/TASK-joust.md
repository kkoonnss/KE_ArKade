---
task_id: TASK-neon-joust
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/joust]
locks_required: [joust]
acceptance:
  - Joust fully playable flap-and-collide platformer physics logic implemented (player flaps wings, collides from above to defeat enemies)
  - Defeated enemies spawn eggs that must be collected before they hatch into stronger enemies
  - Lava pool at bottom, pterodactyl hazard, wave transitions, and spawn safety
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Skinned in classic neon vector style with glowing platforms, lava, and flapping riders
---

# Objective
Flesh out the `joust` cartridge stub into a fully playable Joust-like flying ostriches action game conforming to the design brief and IPC requirements.

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/joust`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`.
