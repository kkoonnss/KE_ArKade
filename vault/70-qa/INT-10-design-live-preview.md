---
task_id: TASK-INT-10-design-live-preview
qa_by: KE_ArKade_FAB_260701_222209
date: 2026-07-01
status: needs_windows_boot_check
---

# QA note — TASK-INT-10 Design-screen live preview

## Scope of this QA pass

Static/cross-reference verification only. This sandbox has no Godot binary
and no Wine, so the hub could not actually be launched. Everything below is
either (a) confirmed by reading the exact source of every dependency touched,
or (b) explicitly flagged as unverified and deferred to a Windows run.

## Confirmed by direct source cross-reference (high confidence)

- [x] `design_screen.gd` still parses as consistent GDScript — every new
      function referenced by a signal/button connection exists; every
      existing function signature is unchanged.
- [x] Preview toggle button, game cycle buttons, controls button, and status
      label are added to the sidebar without touching the File / Brush &
      Palette / Auto-Derive sections' existing nodes or connections.
- [x] `SharedLoader.load_adapter_script()` / `load_tab_menu_script()` calls
      use the exact same repo-root-resolution + cross-project-load pattern
      already proven by pacman/tetris's `main.gd` (same
      `load(_get_repo_root().path_join("app/shared/shared_loader.gd"))`
      bootstrap, same static method names).
- [x] Every layout-dict key drawn by the 7 `_draw_*_layout()` functions
      matches the real return shape of the corresponding adapter's
      `interpret()`/`fallback_layout()`, verified by reading all 7 adapter
      source files directly (`maze.gd`, `arena.gd`, `lane.gd`, `track.gd`,
      `platform.gd`, `region.gd`, `well_fill.gd`).
- [x] Every adapter's `fallback_layout()` returns a non-empty layout
      unconditionally (procedural fallback contract from PLAN §8/§2) —
      confirmed by reading each one; Preview additionally calls
      `fallback_layout()` itself as a second safety net if `interpret()`
      somehow returns empty, so "preview never renders empty" is satisfied
      at two layers.
- [x] `TabMenu.setup(cartridge_id, level_dir, title)` /
      `register_knob_float/int/bool/enum` / `get_knob_value` /
      `knob_changed` / `menu_closed` signal names and parameter orders match
      `app/shared/controls/tab_menu.gd` exactly.
- [x] Persistence path decision (TabMenu's own
      `level_edit/<cartridge_id>.adjustments.json`, not
      `app/shared/level_adjustments.gd`) matches what pacman/tetris/galaga
      actually read at boot — confirmed no reference cartridge loads the
      shared `level_adjustments.gd` file.
- [x] Scratch-derive path (`_derive_preview_scratch_dir`) invokes
      `compile_level.py <dir>` with the identical `python`/`py -3`/`python3`
      fallback-chain pattern as the existing, working `_on_dir_selected()`
      save flow — confirmed by reading `compile_level.py`'s argparse CLI
      contract (`input` = level dir containing `semantic_map.png` +
      `level.yaml`).
- [x] INT-04 controller grammar preserved: JOY_BUTTON_A/B/DPAD_LEFT/RIGHT/
      LEFT_SHOULDER/RIGHT_SHOULDER/BACK handling in `_input()` and the
      `Input.is_joy_button_pressed(0, JOY_BUTTON_A)` paint-hold in
      `_process()` are untouched; new Preview input
      (JOY_BUTTON_Y/DPAD_UP/DPAD_DOWN/START, KEY_P/BRACKETLEFT/BRACKETRIGHT)
      uses previously-unused bindings (grepped both `design_screen.gd` and
      `tab_menu.gd` for these constants before adding — zero prior hits).
- [x] INT-08 save-compile flow (`_on_dir_selected`) — diffed against the
      original: only 3 new lines added inside the existing `if success:`
      block (`current_level_dir = target_dir`, `preview_dirty_since_derive =
      true`, conditional `_refresh_preview()` call gated on
      `preview_active`). No existing line changed, removed, or reordered.
- [x] INT-09 preset dropdown (`_apply_preset_profile`, `_get_backend_presets`,
      `opt_preset` wiring in `_build_ui`) — zero lines touched.
- [x] 37 level directories confirmed to have both `derived/grid.json` and
      `derived/container.json` on disk right now (TASK-INT-00 already closed
      this gap repo-wide), including classic-pack levels for all 7
      reference archetypes — plenty of real data available for a boot check,
      contrary to the ticket's now-stale "~6 of 33" framing.

## NOT verified — requires a Windows/Godot boot (flagging honestly)

- [ ] Hub actually boots with the new code (no `_ready()` crash from the new
      `_build_preview_overlay()` call or the `@onready var canvas_container`
      lookup).
- [ ] Pressing Y (or clicking Enable Preview) with a loaded level actually
      shows a visible neon overlay that isn't obviously misaligned with the
      painted canvas.
- [ ] Cycling pacman → tetris → galaga produces 3 visually distinct overlay
      shapes (maze graph vs. filled well vs. arena bounds+cover) on the same
      map, per the ticket's explicit 3-archetype check.
- [ ] Opening the Start-menu controls overlay shows the archetype's knobs and
      that dragging one causes an immediate visible redraw.
- [ ] A knob edit actually creates/updates
      `<level_dir>/level_edit/<cartridge_id>.adjustments.json` on disk.
- [ ] That same cartridge, booted independently afterward on the same level,
      picks up the edited value as its default (end-to-end proof of the
      "becomes that game's default" acceptance criterion).
- [ ] Save (INT-08) and the preset dropdown (INT-09) still work when
      exercised interactively, not just read statically.
- [ ] `compile_level.py` actually succeeds against
      `user://preview_scratch` in the real Windows Python/opencv
      environment (unsaved-paint path).

## Recommendation

Do not close this ticket to `done` without the Windows boot check above.
Set to `pending_kons_verify` so a human (or a Windows-capable agent) can run
the hub once and confirm the unverified items. The code is structurally
sound against every dependency it calls, but "code written" is explicitly
not "done" per this project's own verification bar, and a live render/redraw
check is the one thing that cannot be faked from static review.
