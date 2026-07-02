---
task_id: TASK-INT-10-design-live-preview
stage: 6
wave: 0
priority: P1
lane: hub
archetype: n/a
status: pending_kons_verify
owner_agent: "KE_ArKade_FAB_260701_222209"
touches: [app/hub]
locks_required: [hub-design]
depends_on: [TASK-INT-03-editor-design-screen, TASK-INT-01-adapter-library, TASK-INT-02-controls-toolkit]
closing_receipt: vault/40-agent-runs/sonnet_hub_INT-10_design-live-preview_2026-07-01.md
acceptance:
  - Design screen gains a Preview mode (button in sidebar + controller shortcut, e.g. Y / keyboard P) that renders a game's interpreted layout as an overlay ON TOP of the current painted map canvas
  - A game selector cycles the 7 archetype reference games (pacman, tetris, galaga, frogger, on_track, donkey_kong, gta); switching re-runs that game's adapter live
  - While Preview is active, the shared secondary-controls overlay (tab_menu.gd pattern) opens over the editor with that game's knobs (grid scale, wall width, invert, density, etc.); changing a knob re-interprets and redraws the overlay immediately
  - Knob values are persisted via level_adjustments.gd keyed to the previewed cartridge_id + current level, so the values chosen in the editor become that game's DEFAULT secondary controls for this map when the cartridge later boots
  - Preview never renders empty — adapters' procedural fallback is honored; if the current canvas has no derived data yet, run/refresh derive first (same path as TASK-INT-08 save-compile step) or interpret from the in-memory grid
  - Overlay is visually distinct from the paint layer (semi-transparent, cyan-led neon per design system) and can be toggled off without losing paint state
  - Verified by real output — launch the hub, open Design, load a level, preview at least pacman + tetris + galaga, adjust a knob per game, confirm redraw + persisted adjustment file
---

## Objective

The "killer feature" from PLAN §5: live game preview inside the Design screen.
While painting a map, the designer flips through "how would Pac-Man / Tetris /
Frogger read this?" in place, with overlay controls. The secondary-control
values set during preview persist as that game's defaults for this level.

## Implementation notes (spec, not law — builder may improve)

- **Reuse, don't reinvent:** `app/shared/adapters/*.gd` (7 adapters,
  `interpret(level_dir, derived, knobs)`), `app/shared/controls/tab_menu.gd`
  (controller-navigable overlay menu + knob registry + persistence hooks),
  `app/shared/level_adjustments.gd` (per cartridge_id/level defaults). No new
  interpretation code in the hub — PLAN §8 risk table forbids it.
- **Rendering:** adapters return a normalized layout Dictionary. Add a single
  `preview_overlay` drawing node in design_screen.gd that renders layout
  primitives generically (nodes/edges for maze graphs, cells/bricks for
  well-fill, spawn/goal/lane markers, track centerline, platform edges, region
  contours). Keep it schematic — wireframe/neon, not the actual game art.
- **Data source:** preview interprets the CURRENT map. If the canvas has
  unsaved paint, either (a) write a temp semantic_map + run quick derive, or
  (b) prefer interpreting from in-memory grid where the adapter supports it.
  Choose the simpler path that stays honest; document the choice in the run log.
- **Knob defaults per game:** pull each reference cartridge's knob definitions
  (see pacman's Tab menu registration and the three stubs) rather than
  hardcoding; expose a sensible common subset where a game defines none.
- **Persistence key:** `level_adjustments.gd` keys by scene_id/level_id from
  level.yaml — make sure the Design screen passes the real level dir so the
  saved defaults land where the cartridge will read them at boot.
- **Input:** follow the existing Design-screen controller grammar
  (TASK-INT-04). Preview toggle + game-cycle must be controller-reachable;
  mouse/keyboard parallel path stays.
- **Same file caution:** design_screen.gd was last touched by INT-08/09
  (pending_kons_verify). Do not regress the save-compile flow or the preset
  selector; run their acceptance checks after changes.

## Verify by real output

Boot hub headless-or-windowed, open Design, load an existing level with baked
derived layers (pick one of the ~6 complete ones), screenshot preview overlay
for 3 archetypes, adjust a knob, confirm `user://level_adjustments.json` gains
the entry, and confirm the game (e.g. pacman) picks the value up as default.
Write `vault/40-agent-runs/` log + `vault/70-qa/` note, release lock.
