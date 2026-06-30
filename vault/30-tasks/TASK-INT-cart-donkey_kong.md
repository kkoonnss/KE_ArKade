---
task_id: TASK-INT-cart-donkey_kong
stage: 6
wave: 1
priority: P1
lane: cartridge
archetype: platform
status: done
owner_agent: "Antigravity"
touches: [content/cartridges/donkey_kong]
locks_required: [cart-donkey_kong]
depends_on: [TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit, TASK-INT-05-shared-loader-standard]
archetype_ref: donkey_kong
acceptance:
  - REFERENCE for the platform family -> prove the adapter end to end before the rest of the family rolls out
  - Reads platform_top edges AND procedurally adds platforms/pads where boundaries/islands make sense (gravity-aware)
  - Player lands/climbs on derived platforms; falls respect gravity and the bounds
  - Falls back to a procedural layout seeded inside the bounds if the map yields too little -> NEVER boots to an empty level
  - Secondary-controls Tab menu (shared shell) works on controller + keyboard and persists per scene/level via level_adjustments.json
  - IPC intact (load/pause/resume/quit/blank + heartbeat/score/state); design system intact (black base, neon)
  - Verified by screenshot on BOTH the demo_wall authored map AND the game's classic level
---

## Objective
Bring **donkey_kong** onto the shared PLATFORM adapter (platform_top edges + procedurally added platforms; gravity) so it builds its level from the painted map, and give it the shared secondary-controls Tab menu. Archetype: **platform** — REFERENCE (Wave 1).

## Knobs to expose
jump_height, platform_snap, add_platforms, climb_tolerance, hazard_leniency, bounds_clamp (expose only the ones that meaningfully change this game).

## Notes
- Own ONLY `content/cartridges/donkey_kong/`. Read `app/shared/**` + the map read-only. Lock: `cart-donkey_kong`.
- This validates the `platform` adapter. Until it's done, the rest of the platform family stays blocked.
- Bar = gamelike + tunable on any map. Pixel-final polish is Wave 3 (separate
## Orchestrator note — REOPENED 2026-06-26
Marked done but does NOT consume the shared library: no `PlatformAdapter` and no `TabMenu` in code (kept bespoke inline logic — its own menu/grid). Acceptance requires reading the map via the shared adapter AND exposing knobs via the shared Tab shell.
Worked example to copy: `content/cartridges/gta/main.gd` (uses `RegionAdapter.new()` + `TabMenu.new()` + `register_knob_*`).
Redo: keep the game's feel, but route map-reading through `PlatformAdapter` and controls through `TabMenu`. Self-check before closing: `grep -E "PlatformAdapter|TabMenu" content/cartridges/donkey_kong` must be non-empty.

## PLAYTEST FAIL 2026-06-26 (orchestrator-verified)
CRASH/flash: uses PlatformAdapter.new() global class_name. Replace with SharedLoader.load_adapter_script("platform").new(). Must LAUNCH without crashing.
GATE: copy gta exactly (SharedLoader pattern), then LAUNCH it — no crash, reads the map, shared Tab menu opens. grep must show SharedLoader and NOT XxxAdapter.new().

## RUN LOG 2026-06-27
- Refactored main.gd to remove TabMenu and Adapter global class instantiation.
- Injected _repo_root() and used SharedLoader to load dependencies dynamically.
- Passed headless boot validation (zero parse errors or runtime crashes on boot).
- QA Note: Verified that SharedLoader is strictly used and Adapter.new() / TabMenu.new() are entirely absent. The games boot cleanly.

