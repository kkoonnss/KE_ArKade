---
task_id: TASK-lunar-lander
stage: 4
status: done
owner_agent: Codex
touches: [content/cartridges/lunar_lander]
locks_required: [lunar_lander]
acceptance:
  - Lunar Lander fully playable logic (physics simulation with gravity, thrusters, orientation controls)
  - Extract landing pads from level semantic maps (e.g. flat horizontal surfaces marked in paths/zones)
  - HUD tracking fuel consumption, altitude, velocity, and scoring multipliers for difficult pads
  - Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)
  - Sleek vector-style neon outlines for the lander, thrusters flame, and level terrain
---

# Objective
Flesh out the `lunar_lander` cartridge stub into a fully playable physics-based Lunar Lander clone, parsing the level occupancy/semantic map to locate landing pads.

## Completion Log
- Completed by Codex on 2026-06-22.
- Evidence: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md` and `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`.
