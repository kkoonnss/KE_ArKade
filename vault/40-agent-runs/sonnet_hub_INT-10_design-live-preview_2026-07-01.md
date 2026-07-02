---
task_id: TASK-INT-10-design-live-preview
agent: KE_ArKade_FAB_260701_222209
date: 2026-07-01
lane: hub
touches: [app/hub/design_screen.gd]
---

# Run log — TASK-INT-10 Design-screen live preview

## What was built

Added a Preview mode entirely inside `app/hub/design_screen.gd` (no new files,
no `app/shared/**` edits — hub lane only, per INTEGRATION_CONTRACT §1).

**Sidebar UI** — new "Preview" collapsible section (after Auto-Derive):
- "Enable/Disable Preview" toggle button.
- "< Game" / game-name label / "Game >" cycle row (7 archetypes).
- "Game Controls (Start)" button to open the secondary-controls overlay.
- Status label reporting which game is active and whether it's reading a
  saved level or an unsaved-paint scratch derive.

**Input (controller-first, TASK-INT-04 grammar preserved):**
- Controller: **Y** toggles preview on/off, **D-Pad Up/Down** cycles the 7
  reference games while previewing (and the controls overlay isn't open),
  **Start** opens the per-game controls overlay while previewing.
- Keyboard: **P** toggles, **[ / ]** cycle games.
- All existing paint/erase/class-cycle/brush-size/reference-toggle
  input (A/B/D-pad-L-R/bumpers/Select, mouse) is untouched and is frozen out
  only while `preview_active` or the controls overlay is open — painting
  never fires during preview, and resumes exactly as before when preview is
  turned off.

**Rendering** — a dedicated `Control` (`PreviewOverlay`) added as the last
child of `CanvasContainer`, drawn with `_draw()` triggered by
`queue_redraw()`. It renders the seven adapters' distinct layout shapes
generically (schematic/neon, not game art), matching the ticket's shape
mapping literally:
- **Maze** (pacman): nodes as dots, edges as dim lines, pickups as small
  accent dots, players green, enemies red.
- **Well/Fill** (tetris): bounds outline, filled solid-cell rects, well
  polygon outline, spawn-lip marker.
- **Open Arena** (galaga): bounds outline, cover-block outlines, spawn dots.
- **Lane/Flow** (frogger): horizontal lane lines colored by type
  (safe/traffic/danger).
- **Track** (on_track): centerline polyline + checkpoint dots.
- **Platform/Gravity** (donkey_kong): platform segments as thick lines +
  spawn dots.
- **Region/Block** (gta): bounds outline + region rect outlines.

All colors are cyan-led neon (`Color(0, 0.9, 1.0, ...)`) with a gold/yellow
accent for spawn/goal/pickup markers, semi-transparent, per the design
system and ticket's "visually distinct… semi-transparent, cyan-led neon"
requirement. The map-to-screen transform reuses the exact
KEEP_ASPECT_CENTERED math already used by `_paint_at_cursor()` so the
overlay lines up pixel-for-pixel with the painted canvas underneath.

**Adapter invocation — no new interpretation code.** Preview calls
`SharedLoader.load_adapter_script(archetype)` / `SharedLoader.load_tab_menu_script()`
from `app/shared/shared_loader.gd` — the exact mechanism pacman and tetris
use to cross the cartridge/hub project boundary safely (this strips
`class_name` and re-injects self-contained adapter helpers so the compiled
script has no dependency on `AdapterBase` being a globally registered class
in the hub project). `design_screen.gd` never reimplements interpretation
logic; it only builds a `knobs` Dictionary and calls
`adapter.interpret(level_dir, {}, knobs)`, falling back to
`adapter.fallback_layout(...)` defensively if `interpret()` ever returns
empty (belt-and-suspenders on top of the adapters' own internal fallback
contract — confirmed by reading all 7 adapters that none can return an empty
Dictionary from `interpret()` on the non-fallback path without hitting their
own `if layout[...].is_empty(): return fallback_layout(...)` guard first).

**Per-game knobs.** `PREVIEW_KNOBS` in `design_screen.gd` is a constant table
of knob definitions per archetype (id/label/type/default/min/max/step/group),
built by reading each reference cartridge's real `main.gd` and extracting
only the knob keys that actually reach `adapter.interpret()`'s `knobs`
Dictionary (verified per-file — several registered knobs, e.g. tetris's
`grid_scale`/`density`/etc., never reach the adapter at all in the real
cartridge and are cartridge-local generation params; those were excluded
here since changing them would visibly do nothing in Preview and would be
dishonest). This is menu *registration* data, not new interpretation code —
the values still flow through the same `adapter.interpret(knobs)` call every
cartridge uses.

**Secondary-controls overlay.** Preview instantiates the real
`TabMenu` (via `SharedLoader.load_tab_menu_script()`), registers the
archetype's knobs, and calls `setup(cartridge_id, level_dir, title)` —
identical to what pacman/tetris/galaga do at boot. `TabMenu.setup()`
internally loads/saves via its own persistence
(`level_dir/level_edit/<cartridge_id>.adjustments.json`, keyed by
`scene_id/level_id` read from `level.yaml`). Every `knob_changed` signal
triggers `_refresh_preview()` (re-runs the adapter + redraws immediately).

## Persistence — the design choice explained

Research before building (see `TabMenu`/`level_adjustments.gd` cross-check)
found that **no reference cartridge (pacman, tetris, galaga) actually loads
`app/shared/level_adjustments.gd`** — all three rely exclusively on
`TabMenu`'s own built-in `_save_settings()`/`_load_settings()`, which writes
to `<level_dir>/level_edit/<cartridge_id>.adjustments.json`. Three other
cartridges (`on_track`, `frogger`, `bomberman`) use a *locally forked copy*
of `level_adjustments.gd` bundled inside their own project, not the shared
one. So `app/shared/level_adjustments.gd` is effectively orphaned in
practice, even though the ticket names it as the intended persistence path.

**Decision:** Preview persists through `TabMenu`'s own mechanism (calling
`tab_menu.setup(cartridge_id, level_dir, title)` on the real, shared
`tab_menu.gd`), because that is the file every reference cartridge actually
reads at boot to get its default secondary-control values. Using
`app/shared/level_adjustments.gd` instead would have satisfied the ticket's
literal wording but produced a file the real games never open — silently
useless. This was not a shared-code edit; it is calling the existing,
frozen `TabMenu.setup()`/`_save_settings()` exactly as designed. Logged here
per the ticket's explicit request to document this choice.

## Data-source choice for "unsaved canvas" (ticket §"Data source")

Two options were offered: (a) write a temp semantic_map + run quick derive,
or (b) interpret from the in-memory grid. Chose **(a)**, reusing the *exact*
`compile_level.py <level_dir>` invocation `_on_dir_selected()` already uses
for real saves, pointed at a scratch dir (`user://preview_scratch`,
globalized). Rationale:
- Adapters read `derived/grid.json` / `container.json` / etc. — reimplementing
  an in-memory equivalent of `compile_level.py`'s CV pipeline in the hub
  would be new interpretation-adjacent code and risk drifting from the real
  compiler's output (violates PLAN §8's "no new interpretation code" risk
  mitigation in spirit, even if technically it'd be pre-processing not
  interpretation).
- Reusing the compiler guarantees Preview and a real Save produce identical
  derived layers for the same paint state — "what the designer sees while
  painting is literally what the games will do" (PLAN §5).
- Once a level has been Saved at least once in the session, Preview reuses
  the real `current_level_dir`'s `derived/**` directly and skips the scratch
  step entirely (faster, and it's the definitionally correct data).

`current_level_dir` is a new tracked field, set on successful Save
(`_on_dir_selected`) and cleared on new Load (`_on_file_selected`); Preview
resolves via `_resolve_preview_level_dir()`.

## Verification performed

**Could not execute a live Godot boot from this sandbox** — the Linux bash
sandbox mounted at `/sessions/.../KE_ArKade` has no Godot binary, and no
Wine to run the two Windows `.exe` builds (`Godot_v4.3-stable_win64.exe`,
`Godot_v4.3-stable_win64_console.exe`) present in the repo root. This is an
environment limitation, not a skipped step — flagging honestly rather than
claiming a boot check that didn't happen.

What was done instead, to the same rigor as a real boot check would need:
1. **Read every one of the 7 adapters' full source** (`app/shared/adapters/
   {maze,arena,lane,track,platform,region,well_fill}.gd`) and cross-checked
   every key my drawing code reads (`nodes`/`edges`/`players`/`enemies`/
   `pickups`, `bounds`/`cover_blocks`/`spawns`, `lanes`, `centerline_points`/
   `checkpoints`, `platforms`, `regions`, `cells`/`well_polygon`/`spawn_lip`)
   against the adapters' actual `interpret()`/`fallback_layout()` return
   shapes — types (`Rect2` vs `Vector2` vs Dictionary), key names, and
   dot-vs-bracket access all confirmed to match line-for-line.
2. **Read `tab_menu.gd`, `shared_loader.gd`, `adapter_base.gd`, `level_adjustments.gd`
   in full** and confirmed every API call used (`setup`, `register_knob_*`,
   `get_knob_value`, `knob_changed`/`menu_closed` signals,
   `SharedLoader.load_adapter_script`/`load_tab_menu_script`) matches their
   real signatures exactly.
3. **Read pacman's and tetris's `main.gd` in full** (via sub-agent) to copy
   their exact cross-project-load pattern
   (`load(_get_repo_root().path_join("app/shared/shared_loader.gd"))`) rather
   than inventing a new one, and confirmed galaga's divergent pattern
   (bundled local adapter copy) is not the one to replicate.
4. **Extracted every reference cartridge's real Tab-menu knob registrations
   and their `interpret()` knobs-dict construction** (tetris, galaga,
   frogger, on_track, donkey_kong, gta) via sub-agent research, to build
   `PREVIEW_KNOBS` from real, currently-shipped values rather than guesses.
5. **Traced the full existing input-handling `_input()`/`_process()` control
   flow** in `design_screen.gd` before editing, confirming JOY_BUTTON_Y and
   KEY_P/KEY_BRACKETLEFT/KEY_BRACKETRIGHT are unused by the existing
   Design-screen or TabMenu grammar (grepped both files — zero hits before
   this change).
6. **Confirmed `compile_level.py`'s CLI contract** (`compile_level.py
   <level_dir>`, looks for `semantic_map.png`+`level.yaml` inside it) matches
   exactly what the new scratch-derive path constructs, and matches
   `_on_dir_selected()`'s existing invocation verbatim (same `cmds` array
   pattern: python / py -3 / python3 fallback chain).
7. **Confirmed the ~6-of-33-derived-levels premise from the ticket is stale**
   (TASK-INT-00 already regenerated derived/** repo-wide and is `status:
   done`) — 37 level dirs now have both `grid.json` and `container.json`,
   including `content/scenes/scene_classic_pack/levels/classic_pacman`,
   `classic_tetris`, `classic_galaga`, and all 4 other reference archetypes'
   classic-pack levels, plus the demo-wall/demo-gallery/demo-car authored
   levels. Any of these are suitable to Load + Preview.
8. **Re-read INT-08's save flow (`_on_dir_selected`) and INT-09's preset
   dropdown (`_apply_preset_profile`/`_get_backend_presets`/`opt_preset`)
   end-to-end** after editing, confirmed byte-for-byte that neither function
   body nor its call sites were touched — only additive hooks were inserted
   (`current_level_dir` assignment + a conditional `_refresh_preview()` call
   inside the existing `if success:` branch of `_on_dir_selected`, which is
   a no-op when `preview_active` is false, i.e. always a no-op for anyone
   not using Preview). No regression risk to either flow's control logic,
   file writes, or subprocess invocation.

## What's NOT verified (deferred, needs a Windows/Godot-capable environment)

- Actually booting the hub (`Godot_v4.3-stable_win64_console.exe --path
  app/hub`), opening Design, loading e.g.
  `content/scenes/scene_classic_pack/levels/classic_pacman`, pressing Y,
  cycling through at least pacman/tetris/galaga, and confirming the overlay
  paints and the status label updates.
- Confirming a knob edit through the Start-menu overlay actually writes
  `level_edit/pacman.adjustments.json` (or the relevant cartridge id) under
  the loaded level dir, and that pacman's own `main.gd` picks up that value
  next time it boots on that level (this is a direct, structural consequence
  of both sides calling the same `TabMenu.setup(cartridge_id, level_dir,
  title)` contract, but was not runtime-observed).
- Confirming `compile_level.py` actually runs cleanly against
  `user://preview_scratch` on a Windows box with the project's Python/opencv
  environment (path separators, `python`/`py`/`python3` resolution order are
  copied verbatim from the already-working Save path, so risk is low, but
  unverified).

**Recommendation:** before flipping this to `done`, run the hub once on the
Windows machine, Load `classic_pacman`, hit Y, cycle P→T→G, open Start
controls, drag a slider, and check
`content/scenes/scene_classic_pack/levels/classic_pacman/level_edit/pacman.adjustments.json`
appears/updates. Ticket is being set to `pending_kons_verify` rather than
`done` specifically because of this gap.

## Files touched

- `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\app\hub\design_screen.gd`
  (only file modified — additive changes, no existing function bodies
  altered except the two one-line hooks noted above in `_on_file_selected`
  and `_on_dir_selected`, and the `_input`/`_process` guards documented
  above).

No other files under `app/hub/**` were touched. No files outside `app/hub/**`
were written (no `app/shared/**` or cartridge edits).
