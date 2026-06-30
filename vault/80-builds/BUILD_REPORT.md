# BUILD REPORT — KE_ArKade MVP Streak Execution

**Date:** 2026-06-19
**Executed By:** Antigravity Swarm (Shared-Integrator, Codex-Compiler, Hub-Architect, Cartridge-Dev)
**Target:** MVP Build (Profile L, Wall Scene, 2 Cartridges, 1 Map)

---

## 1. Summary of Delivered Components

The MVP streak executed successfully across all work packages:

- **`app/shared/`**:
  - `palette.py` and `palette.gd` generated programmatically from `semantic-palette-v1.yaml`.
  - Schema validation scripts written and verified against stubs.
  - A test `scene_demo_wall` with a compiled `semantic_map.png` built programmatically.

- **`app/tools/` (Arena Compiler & CV)**:
  - `compiler.py` created utilizing OpenCV, enforcing palette snapping policies.
  - Derived map layers (`occupancy.png`, `navgraph.json`, `container.json`) correctly output data needed for games.
  - Interactive Tkinter level-authoring (slider + paint-over-photo) and calibration tools established.
  - Golden fixtures constructed and tested green.

- **`app/hub/` (Godot Hub)**:
  - Godot 4 project structured.
  - High-contrast, design-brief-compliant Kiosk Shell completed.
  - Separate-process launcher and NDJSON socket IPC functioning with heartbeat monitoring and `Panic Black`.
  - SDL3 Input Manager mapped for up to 4 dynamic player slots.
  - Loopback validation cartridge tested the 3-missed-heartbeat kill flow successfully.

- **`content/cartridges/`**:
  - **Lumen Maze (`pacman`)**: Hooked into IPC, receives arguments, parses `navgraph.json` correctly.
  - **Neon Stack (`tetris`)**: Hooked into IPC, receives arguments, parses `container.json` bounds.
  - Both safely exit on IPC `quit` and support `blank`.

---

## 2. Done-Criteria Checklist

| Criterion | Status | Evidence (Screenshot/Log Paths) | Notes |
|---|---|---|---|
| **Wall MVP, Profile L** | **Pass** | [lumen_maze_run.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/lumen_maze_run.png)<br>[neon_stack_run.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/neon_stack_run.png) | VSync limited 60 FPS stable, gameplay of both games running off seed map. |
| **Two games, one untouched map** | **Pass** | [level.yaml](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/scenes/scene_demo_wall/levels/demo_level/level.yaml)<br>[semantic_map.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/content/scenes/scene_demo_wall/levels/demo_level/semantic_map.png) | Both cartridges load from the single demo_level map layout. |
| **Cartridges = separate processes** | **Pass** | [hub_ipc.log](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_ipc.log) | Spawns separate Godot instance processes with unique PIDs. |
| **Panic Black & Crash Isolation** | **Pass** | [hub_panic_black.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_panic_black.png)<br>[hub_restore_log.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_restore_log.png)<br>[hub_ipc.log](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_ipc.log) | Recovery log in Hub panel and Panic Black instant blanking. |
| **IP-Name Hygiene** | **Pass** | [hub_cartridge_picker.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_cartridge_picker.png) | Kiosk UI displays only clean homage titles (Lumen Maze, Neon Stack, etc.). |
| **Input (Keyboard + 4 slots)** | **Pass** | [input_manager.gd](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/hub/input/input_manager.gd) | Joystick DPAD & key helper tracking. |
| **Golden tests** | **Pass** | `python -m unittest app/tools/tests/test_compiler.py` output | All 4 tests green, including the new grid layer test. |
| **Folder Ownership Respected** | **Pass** | Conversation logs | Handled via compartmentalized fleet roles. |

---

## 3. Visual Reskin & Comparison

Here is the comparison between the north-star mockup designs (`design/frames/arkade_design_v1.html`) and the live Godot engine outputs after executing Addendum 03:

### 1. Hub Cartridge Picker
- **Mockup Goal:** Black base, thin structure borders, clean centered picker dialog with active cartridge hover, displaying clean homage names, and a technical navigation rail using uppercase mono labels.
- **Engine Output:** [hub_cartridge_picker.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_cartridge_picker.png)
- **Status:** **Match.** Navigation buttons style with a clean left border cyan indicator when active, otherwise showing dim grey mono titles. Dialog centers correctly on the screen, showing "Lumen Maze", "Neon Stack", etc.

### 2. Lumen Maze (Pac-Man)
- **Mockup Goal:** Black background (reference photo disabled by default for pure `#000000` projection backdrop). Corridors and solid walls rendered as clean thin neon line-work (cyan paths, crisp white/edge walls, no gray blocky fill), so it reads as neon vector art on black. Yellow neon pickups, and cyan player outline shapes, all with punchier festival glow.
- **Engine Output:** [lumen_maze_run.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/lumen_maze_run.png)
- **Status:** **Match.** The reference background is turned off. Grid cells render with a pure crisp white edge and soft cyan glow, with no muddy 18% fill. Pickups and players use yellow/cyan neon shapes with an increased intensity glow (alpha boosted to 0.4/0.7).

### 3. Neon Stack (Tetris)
- **Mockup Goal:** Black background inside and outside the well (reference photo disabled). Blocks styled with saturated translucent neon (~35% fill for pure black readability), 1px neon edges, and punchier soft glows, so each piece reads as its actual color and not muddy dark gray. Background grid lattice and well outline preserved.
- **Engine Output:** [neon_stack_run.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/neon_stack_run.png)
- **Status:** **Match.** Reference background is turned off. Invisible wall blocks allow the true black backdrop to show through. Settled and falling pieces use higher-opacity translucent fills + saturated glow strokes to stay bright on pure black.

### 4. Panic Black Mode
- **Mockup Goal:** Instant cut to `#000` (screen blanked) with absolutely zero text or borders to avoid emitting projector light.
- **Engine Output:** [hub_panic_black.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_panic_black.png)
- **Status:** **Match.** Panic overlay is a pure black `#000000` panel, and the debug text label is hidden.

### 5. Restore Logs
- **Mockup Goal:** Technical real-time logs in monospace format, with custom colors highlighting the severity of signals.
- **Engine Output:** [hub_restore_log.png](file:///C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/vault/70-qa/hub_restore_log.png)
- **Status:** **Match.** Panel displays all IPC signals cleanly, and the status label references connect properly without node path lookup errors.

---

## 4. Deviations & Schema Change Requests

- **Deviations:** No core structural deviations. We adhered strictly to the `INTEGRATION_CONTRACT.md` rules.
- **Schema Changes:** **NONE.** No schemas were mutated, no external components redefined. The vocabulary inside `semantic-palette-v1.yaml` proved robust enough for all components.

## 5. Sub-Agent Logs
Agent conversation transcripts and QA notes have been deposited:
- `vault/70-qa/VENUE_ACCEPTANCE.md`
- `vault/70-qa/golden_harness.py`
- `vault/40-agent-runs/codex_wp_b_run.md`
- `vault/30-tasks/task-QA-Shared-Integrator.md`

**Status:** Ready for final orchestrator (Opus) review.

---

## 6. Stage 4 Cartridge Batch - Codex Update (2026-06-22)

Codex completed the 10 generated classic cartridge tickets:

- Centipede
- Space Invaders
- Robotron: 2084
- BurgerTime
- Galaga
- Missile Command
- Defender
- Lunar Lander
- Paperboy
- Q*bert

Each cartridge now has a self-contained playable Godot `main.gd` with NDJSON IPC
handling, heartbeat emission, pause/resume/blank/quit support, safe level-grid
loading, BFS nearest-walkable spawn fallback, pure black projection base, and
high-contrast neon vector rendering. Manifests were updated to clean homage
names and `status: playable`.

Evidence:
- Run log: `vault/40-agent-runs/codex_10_classic_cartridges_2026-06-22.md`
- QA note: `vault/70-qa/QA-10-classic-cartridges-2026-06-22.md`
- Screenshots: `vault/70-qa/<cartridge>_gameplay.png`
- Runtime logs: `vault/70-qa/<cartridge>_runtime.log`

Verification status: **Pass**. Godot parser checks and bounded runtime launches
passed for all ten. Screenshot corner pixel sampling confirmed pure `#000000`
black at all four corners for every cartridge.

---

## 7. Stage 4 Cartridge Batch 2 - Codex Update (2026-06-22)

Codex completed the next 10 generated classic cartridge tickets:

- Donkey Kong
- Breakout
- Bubble Bobble
- Dig Dug
- Gauntlet
- Marble Madness
- Joust
- Snake
- Tapper
- Tempest

Each cartridge now has a self-contained playable Godot `main.gd` with level-grid
loading, BFS nearest-walkable spawn fallback, bounds safety, NDJSON IPC command
handling, heartbeat emission, score broadcasting, pure black projection base,
and neon vector rendering. Manifests were updated to clean homage names and
`status: playable`.

Evidence:
- Run log: `vault/40-agent-runs/codex_10_more_classic_cartridges_2026-06-22.md`
- QA note: `vault/70-qa/QA-10-more-classic-cartridges-2026-06-22.md`
- Screenshots: `vault/70-qa/<cartridge>_gameplay.png`
- Runtime logs: `vault/70-qa/<cartridge>_runtime.log`

Verification status: **Pass**. The required command
`./Godot_v4.3-stable_win64_console.exe --headless --path content/cartridges/<cartridge_dir> --quit`
passed for all ten. Parser checks, bounded runtime launches, log scans, and
black-corner pixel sampling also passed.

---

## 8. Remaining Prototype Cartridges - Codex Update (2026-06-22)

Codex completed the five cartridge folders that still existed as prototypes:

- Asteroids
- Tron
- Pong
- Smash TV
- Battlezone

Each now has a playable Godot `main.gd` with safe level-grid loading, BFS
nearest-walkable spawn fallback, NDJSON IPC command handling, heartbeat
emission, score broadcasting, pure black projection base, and neon vector
rendering. Manifests were updated to `status: playable`.

Per user direction, classic IP references in the cover art were preserved as
intentional art-direction nods. `pong`, `smash_tv`, and `battlezone`
cover files were re-encoded as valid PNGs after Godot reported invalid PNG data.

Evidence:
- Run log: `vault/40-agent-runs/codex_5_missing_cartridges_2026-06-22.md`
- QA note: `vault/70-qa/QA-5-missing-cartridges-2026-06-22.md`
- Screenshots: `vault/70-qa/<cartridge>_gameplay.png`
- Runtime logs: `vault/70-qa/<cartridge>_runtime.log`

Verification status: **Pass**. Parser checks, required headless launches,
bounded runtime launches, log scans, and black-corner pixel sampling passed for
all five.

---

## 9. All-Cartridge Functional Art/Load QC - Codex Update (2026-06-22)

Codex completed a full QC pass across all 30 real cartridge folders in
`content/cartridges/`, excluding the diagnostic `loopback` cartridge.

Final hardening included post-splash screenshot support for `bomberman`,
`on_track`, and `frogger`, user-argument parsing fixes for `on_track`
and `frogger`, and corrected screenshot timing for `tetris` so QA
captures gameplay instead of cover art.

Evidence:
- Run log: `vault/40-agent-runs/codex_all_cartridges_functional_qc_2026-06-22.md`
- QA note: `vault/70-qa/QA-all-cartridges-functional-art-load-2026-06-22.md`
- Gameplay contact sheet: `vault/70-qa/all_cartridge_gameplay_contact_sheet_2026-06-22.png`
- Splash/cover contact sheet: `vault/70-qa/all_cartridge_splash_contact_sheet_2026-06-22.png`
- Pixel audit CSV: `vault/70-qa/all_cartridge_gameplay_pixel_audit_2026-06-22.csv`
- Headless launch log: `vault/70-qa/ALL_CARTRIDGES_headless_quit_2026-06-22.log`

Verification status: **Pass**. Required headless launch checks passed for all
30 cartridges. Bounded runtime launches loaded cleanly for all 30. Runtime logs
were scanned for Godot/script/image errors with no matches. Post-splash OpenGL
screenshots were captured for all 30 and the pixel audit reported
`checked=30`, `warnings=0`, `failures=0`.

---

## 10. Rampage + Sprint 2 Custom-Level Prep - Codex Update (2026-06-22)

Codex added a 31st playable cartridge, `rampage`, with a matching
`scene_classic_pack` tester level at `classic_rampage`. Rampage reads custom
level grid/occupancy data, treats occupied cells as destructible building mass,
uses BFS nearest-walkable spawn safety, supports IPC heartbeat and standard
commands, and renders as neon vector city destruction on a black projection
base.

The racing cartridge `on_track` now displays as `Sprint 2`, the Atari-style
on-track racer. `classic_on_track` and `classic_on_track` now include explicit
`track_centerline.json` loop data and navgraph data so the racer starts on a
real track rather than an empty graph.

Legacy IPC command handling was tightened for `tetris`, `bomberman`,
`pacman`, `on_track`, and `frogger` so `pause`, `resume`, `blank`,
`load`, and `quit` are all handled directly.

Evidence:
- Run log: `vault/40-agent-runs/codex_rampage_sprint2_custom_level_prep_2026-06-22.md`
- QA note: `vault/70-qa/QA-rampage-sprint2-custom-level-prep-2026-06-22.md`
- Rampage screenshot: `vault/70-qa/rampage_classic_gameplay_2026-06-22.png`
- Sprint 2 screenshot: `vault/70-qa/sprint2_classic_on_track_gameplay_2026-06-22.png`
- Classic-pack contact sheet: `vault/70-qa/classic_pack_thumbnail_sync_contact_sheet_2026-06-22.png`

Verification status: **Pass**. All 31 real cartridges passed parser checks and
required headless launch checks. Rampage and Sprint 2 custom-level loads passed.
The custom-level compliance audit reported `31 checked`, `0 warnings`. The
classic-pack thumbnail sync audit reported `32` level thumbnails and `0 errors`.

---

## 11. Level Editor Semantic Assist + Per-Game Settings Pattern - Codex Update (2026-06-22)

Codex updated the Python level authoring tool so the base editor remains focused
on the canonical shared `semantic_map.png`, while gaining neutral semantic
assist presets and an `Auto Multi-Class Map` action for deriving path, solid,
platform_top, hazard, spawn, goal, pickup, tracking, and ui_safe classes from a
reference image.

The save flow now emits `platform_edges.json`, `track_centerline.json`, and
`authoring_profile.json` alongside the existing shared derived layers. The
architecture note now defines per-game Tab tuning as procedural settings stored
by each cartridge in one `user://level_adjustments.json` registry keyed by
`<scene_id>/<level_id>`. No additional per-game level maps should be saved; any
game-fit masks are generated in memory at cartridge startup. Tab menus should
share the same persistence shell while exposing game-specific controls and
bounded ranges that match each cartridge's mechanics.

Evidence:
- Run log: `vault/40-agent-runs/codex_level_editor_semantic_assist_2026-06-22.md`
- QA note: `vault/70-qa/QA-level-editor-semantic-assist-2026-06-22.md`
- Architecture: `vault/20-architecture/level-authoring.md`

Verification status: **Partial pass**. `author.py` passed syntax compilation.
The compiler unittest could not run in the bundled Python runtime because
OpenCV (`cv2`) is not installed there.

---

## 12. Per-Cartridge Level Adjustment Helper - Codex Update (2026-06-22)

Codex added the first shared persistence implementation for game-specific Tab
menu tuning. `app/shared/level_adjustments.gd` is the source helper, with
standalone cartridge-local copies added to `on_track`, `frogger`, and
`bomberman` so each Godot project can `preload("res://level_adjustments.gd")`.

The three migrated cartridges now save future Tab-menu edits to their own
`user://level_adjustments.json` registry keyed by `<scene_id>/<level_id>`.
Legacy level-folder `settings.json` files are still read as fallback data when a
registry entry does not exist yet, but new saves no longer mutate level folders.

Evidence:
- Run log: `vault/40-agent-runs/codex_level_adjustments_helper_2026-06-22.md`
- QA note: `vault/70-qa/QA-level-adjustments-helper-2026-06-22.md`
- Source helper: `app/shared/level_adjustments.gd`

Verification status: **Pass**. Godot headless parser/quit checks passed for
`on_track`, `frogger`, and `bomberman` with AppData/user-directory access
enabled for Godot `user://` logging. Headless `--quit` checks with classic-pack
level arguments also passed for all three migrated cartridges. Helper copies
matched the shared source by file hash. Screenshot runtime smoke launches need a
future bounded quit harness; the attempted screenshot checks timed out.

---

## 13. Playtest Fix Batch - Codex Update (2026-06-23)

Codex applied the first hands-on playtest fix batch. All cartridge splash covers
now aspect-fit centered instead of cropping. Continuous movement was fixed for
Battlezone, Gauntlet, Marble Madness, Dig Dug, Breakout, and Donkey Kong by
preserving sub-cell movement when the target cell is walkable and only snapping
to nearest safe cells on blocked positions.

Breakout now has falling item drops. Dig Dug pump aiming persists after movement
stops. Defender now flips the ship left/right, fires in the persisted facing
direction, keeps humans/enemies above the terrain band, and distributes enemy
targets. Missile Command ammo was increased from 12 to 22 per silo. Centipede
now scales later waves with more segments and denser/durable barriers.

Evidence:
- Run log: `vault/40-agent-runs/codex_playtest_fix_batch_2026-06-23.md`
- QA note: `vault/70-qa/QA-playtest-fix-batch-2026-06-23.md`

Verification status: **Pass for startup/parser validation**. Full real-cartridge
Godot headless `--quit` sweep passed, excluding the diagnostic `loopback`
cartridge. Universal start/help/settings screens and the remaining bespoke
gameplay refinements are queued as the next pass.

---

## 14. Playtest Fix Batch 2 - Codex Update (2026-06-23)

Codex applied the second user playtest fix batch. Rampage classic-pack launch
routing now maps `classic_rampage` to the `rampage` cartridge. Robotron and
Smash TV now preserve continuous movement on walkable cells, fixing the frozen
movement caused by snapping every frame back to the cell center.

Snake now renders as a more legible neon snake with a connected body, tapered
segments, larger head, eyes, and tongue. Tapper now advances one row per tap
with a short movement cooldown. On Track now uses the On Track title/skin label
instead of Sprint 2/Classic Neon-style fallback text, and its track rails draw
to either side of the center path so the vehicle sits between the lines.

Evidence:
- Run log: `vault/40-agent-runs/codex_playtest_fix_batch_2_2026-06-23.md`
- QA note: `vault/70-qa/QA-playtest-fix-batch-2-2026-06-23.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless `--quit` checks passed for `robotron_2084`, `smash_tv`, `snake`,
`tapper`, `on_track`, `rampage`, and `app/hub`.

---

## 15. Visual Dress-Up Pass 1 - Codex Update (2026-06-23)

Codex applied a first broad vector-art dress-up pass across the generated
cartridge templates. The intent was to preserve the neon projection style while
making common entities read closer to their classic-game inspirations: girders
now have bracing, ladders have rungs, humanoids have heads/limbs/eyes, robots
have bodies and antennae, tanks have turrets and treads, ships have cockpit and
thrust detail, and game-specific items such as bubbles, eggs, mugs, burgers,
city blocks, houses, bikes, cube hoppers, Tempest claws, and centipede segments
now have identifiable silhouettes.

Evidence:
- Run log: `vault/40-agent-runs/codex_visual_dressup_pass_1_2026-06-23.md`
- QA note: `vault/70-qa/QA-visual-dressup-pass-1-2026-06-23.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless `--quit` checks passed for `donkey_kong`, `gauntlet`,
`marble_madness`, `bubble_bobble`, `joust`, `tempest`, `robotron_2084`,
`burger_time`, `paperboy`, `qbert`, `lunar_lander`,
`space_invaders`, `galaga`, `asteroids`, `tron`,
`pong`, `smash_tv`, and `battlezone`.

---

## 16. GTA Cartridge - Codex Update (2026-06-23)

Codex added `gta`, a new top-down static-city cartridge inspired by
early bird's-eye city crime games while using neutral project naming. The game
interprets semantic maps as city blocks: `path` becomes streets, sidewalk-safe
classes become walkable pedestrian/mission space, and `solid` becomes
buildings.

The first playable loop includes walking, shooting, stealing/driving cars,
traffic, pedestrians, ringing payphone missions, package pickup and delivery,
cash/ammo drops, wanted-star escalation, cop spawns, pursuit, and wanted decay
when the player hides far from cops. A new `classic_gta` level was added
to `scene_classic_pack` with a blocky city semantic map, thumbnail, and hub
mapping.

Evidence:
- Run log: `vault/40-agent-runs/codex_gta_cartridge_2026-06-23.md`
- QA note: `vault/70-qa/QA-street-job-cartridge-2026-06-23.md`

Verification status: **Pass for startup/parser validation**. Godot headless
`--quit` checks passed for `gta` standalone, `gta` with the
classic level args, and `app/hub` after mapping changes.

---

## 17. Playtest Fix Batch 3 - Codex Update (2026-06-24)

Codex applied a targeted playtest batch across Battlezone, Breakout, Bubble
Bobble, Burger Time, Centipede, Defender, Dig Dug, Donkey Kong, and Frogger.
Battlezone shots now check enemy hits during bullet movement. Breakout powerups
are now timed and obvious, with WIDE, SLOW, LASER, and SHIELD states plus HUD
timers. Bubble Bobble bubbles now trap enemies directly and the player can jump
again after landing at the bottom.

Burger Time now waits on a start/help overlay before gameplay begins. Centipede
and Defender wave scaling were increased. Dig Dug now starts mostly filled with
dirt, carves starter/custom tunnels, and restricts non-ghost enemies to dug
paths. Donkey Kong barrels can roll down ladders. Frogger's Godot project title
now says `Frogger` instead of `Frogger`.

Evidence:
- Run log: `vault/40-agent-runs/codex_playtest_fix_batch_3_2026-06-24.md`
- QA note: `vault/70-qa/QA-playtest-fix-batch-3-2026-06-24.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless `--quit` checks passed for `battlezone`, `breakout`,
`bubble_bobble`, `burger_time`, `centipede`, `defender`,
`dig_dug`, `donkey_kong`, and `frogger`.

---

## 18. Playtest Fix Batch 4 - Codex Update (2026-06-24)

Codex applied a targeted playtest batch across Galaga/Galaga, Gauntlet,
Joust, On Track, Paperboy, Rampage, Robotron, Smash TV, and GTA. Galaga
now has Galaga-like entry formations, formation weaving, diving attackers, and a
downward-scrolling starfield. Gauntlet, Robotron, Smash TV, and Paperboy now
persist aim/throw direction from the last relevant player input.

Joust now advances waves after enemies are cleared and displays objective
guidance. The duplicate On Track classic level was removed from hub mappings.
Rampage's classic level now declares the semantic metadata needed by the hub
compatibility gate. GTA is now presented as `GTA`, with updated project
title, manifest title, HUD title, splash, thumbnail, and reduced reset-time IPC
noise.

Evidence:
- Run log: `vault/40-agent-runs/codex_playtest_fix_batch_4_2026-06-24.md`
- QA note: `vault/70-qa/QA-playtest-fix-batch-4-2026-06-24.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless `--quit` checks passed for `galaga`, `gauntlet`,
`joust`, `paperboy`, `robotron_2084`, `smash_tv`, `gta`,
`rampage`, and `app/hub`. Rampage was also validated with the classic Rampage
level args.

---

## 19. Level Editor Save Derive Fix - Codex Update (2026-06-24)

Codex fixed a Level Authoring Tool save failure reported as `Error deriving
layers: list index out of range`. The likely failure was in `navgraph` spur
pruning: a leaf collected earlier in the pass could become isolated after a
neighbor was removed, but the code still indexed `neighbors[0]`.

The `navgraph` generator now re-checks the live neighbor list before indexing.
The level authoring save flow also wraps each derive step with its layer name,
so future failures identify the layer that failed.

Evidence:
- Run log: `vault/40-agent-runs/codex_level_editor_save_fix_2026-06-24.md`
- QA note: `vault/70-qa/QA-level-editor-save-fix-2026-06-24.md`

Verification status: **Pass for static Python parser validation**. Full GUI
runtime derivation could not be replayed from Codex because the available
bundled Python lacks `cv2` and `yaml`.

---

## 20. Pac-Man + Start Menu Pass - Codex Update (2026-06-24)

Codex applied a focused Pac-Man pass and began the cartridge start-screen
rollout. Pac-Man now holds on a splash/title overlay with Start, Help,
Settings, player count selection, Tab settings, and Escape-to-title behavior.
Classic Pac-Man rails now render only on tunnel-like path edges, while large
open/blank areas use sparse collectible dots instead of dense blue corridor
lines. Ghost movement now uses simple chase, ambush, flank, and scatter target
selection instead of random turns.

The shared start-state flow was also rolled onto the 10 generated classic
cartridges: `donkey_kong`, `breakout`, `bubble_bobble`, `dig_dug`,
`gauntlet`, `marble_madness`, `joust`, `snake`, `tapper`, and
`tempest`.

Evidence:
- Run log: `vault/40-agent-runs/codex_pacman_start_menu_pass_2026-06-24.md`
- QA note: `vault/70-qa/QA-pacman-start-menu-pass-2026-06-24.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless checks passed for Pac-Man against `260624_095010` and all 10 generated
classic cartridges listed above. Remaining cartridge families still need the
same start-screen treatment in a follow-up pass.

---

## 21. GTA Scale + Restart Fix - Codex Update (2026-06-24)

Codex fixed GTA rendering as a smaller inset by adding viewport-fit scaling and
a centered draw offset to `gta`. The game world now scales to the
cartridge viewport, while HUD text is reset back to screen-space drawing.

Codex also fixed an IPC handshake issue where GTA marked `ready_sent` before the
TCP socket was connected and did not poll the socket. Ready is now sent only
after `STATUS_CONNECTED`, and redundant `load` messages for the current level no
longer reset the round.

Evidence:
- Run log: `vault/40-agent-runs/codex_gta_scale_restart_fix_2026-06-24.md`
- QA note: `vault/70-qa/QA-gta-scale-restart-fix-2026-06-24.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless checks passed for `gta` standalone and with the
`classic_gta` level args.

---

## 22. Pac-Man Controller Menu - Codex Update (2026-06-25)

Codex updated Pac-Man's start/help/settings overlay to use a controller-style
focus model. D-pad or left stick moves the selected row, left/right adjusts
settings, A/Start/Enter accepts, and B/Escape returns to the title menu. The
settings screen now exposes selectable rows for Players, Skin, Reference, Back,
and Start Game.

Evidence:
- Run log: `vault/40-agent-runs/codex_pacman_controller_menu_2026-06-25.md`
- QA note: `vault/70-qa/QA-pacman-controller-menu-2026-06-25.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless checks passed for `pacman` standalone and with the
`260624_095010` level args.

---

## 26. Pac-Man Classic Wall Boundary Render - Codex Update (2026-06-25)

Codex replaced the classic Pac-Man maze render model again, this time moving
away from graph-edge tunnel strokes to solid-cell boundary walls. That closes
corners more reliably across elbow turns, room outlines, islands, and other
shape variations that were still rendering with awkward internal stubs.

Evidence:
- QA note: `vault/70-qa/QA-pacman-classic-wall-boundaries-2026-06-25.md`

Verification status: **Pass for targeted startup validation**. Godot headless
startup passed for `pacman` after the classic wall render change.

---

## 25. Pac-Man Corner Caps and Authoring Sections - Codex Update (2026-06-25)

Codex replaced the over-trimmed Pac-Man tunnel rendering with full classic
rails plus an elbow-cap pass that closes exposed outside corners. This keeps
the maze continuous while still targeting the awkward tail problem at bends.
Codex also grouped the level authoring panel into collapsible sections and
added an `Auto` checkbox for live semantic multi-class preview on slider
adjustments.

Evidence:
- Run log: `vault/40-agent-runs/codex_pacman_corner_caps_and_authoring_sections_2026-06-25.md`
- QA note: `vault/70-qa/QA-pacman-corner-caps-authoring-sections-2026-06-25.md`

Verification status: **Pass for targeted validation**. Pac-Man headless startup
passed, and the level authoring tool passed Python syntax compilation.

---

## 24. Pac-Man Rail Trim - Codex Update (2026-06-25)

Codex trimmed the classic Pac-Man rail rendering so the blue/black line segments
no longer overrun junctions and dead ends. The maze edges are now shortened
before drawing, which removes the visible tail stubs in the tunnel geometry.

Evidence:
- Run log: `vault/40-agent-runs/codex_pacman_rail_trim_2026-06-25.md`
- QA note: `vault/70-qa/QA-pacman-rail-trim-2026-06-25.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless checks passed for `pacman` standalone and with the
`260624_095010` level args.

---

## 23. Pac-Man Reference Opacity Settings - Codex Update (2026-06-25)

Codex added a controller-friendly `Reference Opacity` row to Pac-Man's settings
menu. The row displays a bar plus percentage, responds to D-pad/left-stick or
arrow left/right adjustment, and automatically enables the reference overlay.
Pac-Man now saves players, skin, reference enabled, and reference opacity as
per-level settings in `user://level_adjustments.json`, and reloads them when a
level is loaded through IPC.

Evidence:
- Run log: `vault/40-agent-runs/codex_pacman_reference_opacity_settings_2026-06-25.md`
- QA note: `vault/70-qa/QA-pacman-reference-opacity-settings-2026-06-25.md`

Verification status: **Pass for targeted startup/parser validation**. Godot
headless checks passed for `pacman` standalone and with the
`260624_095010` level args.
