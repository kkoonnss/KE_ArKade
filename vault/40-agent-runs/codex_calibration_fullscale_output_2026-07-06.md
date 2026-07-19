---
run_id: codex_calibration_fullscale_output_2026-07-06
agent: codex
session_start: 2026-07-06T14:30:00-07:00
session_end: 2026-07-06T14:48:00-07:00
task_id: TASK-calibration-fullscale-output
lane: hub
lock_held: hub-calibration-fullscale
status: pending_kons_verify
pre_edit_commit: none_dirty_tree
close_commit: none_dirty_tree
backup_status: backup_pending
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

## Summary

Changed calibration from a small preview-style canvas to a full-viewport output
mapping surface. The controls are now a translucent overlay that can be hidden,
so the projected mapping can match the game frame one-to-one. Also added a hub
output-screen selector that is passed to launched games as `--screen N`.

## Changes

- `app/hub/calibrate_screen.gd`: mapping rect now covers the full viewport.
- `app/hub/calibrate_screen.gd`: controls are a floating overlay with a Hide
  Controls toggle.
- `app/hub/calibrate_screen.gd`: added selectable level reference backgrounds
  by scanning `reference_image`, `background.png`, and `semantic_map.png`.
- Follow-up fix: reference images now preserve aspect ratio and are centered
  with letterboxing instead of stretching to the calibration rect.
- Follow-up fix: selected reference images now render through the calibration
  mesh, so dragging pins warps the photo/test alignment live instead of leaving
  the photo as a passive backdrop.
- Follow-up fix: Calibrate now has its own Full Screen and Output Screen
  controls, plus `F11` and `H` shortcuts for fullscreen and hide/show controls.
- `app/hub/main.gd`: stores an output screen index in hub window state.
- `app/hub/main.gd`: Settings gets an Output Screen button.
- `app/hub/main.gd`: game launch args include `--screen N` when selected.
- Follow-up fix: Calibrate is now mounted as a root-level overlay instead of
  inside `UI/Content/MainPanel`, so the mapping surface covers the entire game
  window rather than only the hub content area.
- Follow-up fix: Calibrate is now scene-first. It has a Physical Scene picker,
  reference options no longer list every level variant, and calibration still
  saves to the selected scene's `calibration/current.yaml`.
- Follow-up fix: Calibrate background is fully opaque black, and the controls
  panel is collapsible and draggable by its header.
- Follow-up fix: added one canonical scene calibration reference per scene:
  `content/scenes/<scene_id>/calibration/reference.png`.
- Follow-up fix: Calibrate now defaults to the scene calibration reference
  instead of Test Pattern Only when a reference exists.
- Follow-up fix: added an Input Mask edit mode. The reference image is mapped
  through a draggable/scalable source quadrilateral first, then transformed by
  the output mesh pins. Saves under `input.mode = source_quad`.
- Follow-up fix: replaced the above `source_quad` model with a proper
  input/output split:
  - Input view shows the untouched reference image, aspect-fit and locked.
  - Input pins are now source-image crop points in image pixel space.
  - Input crop defaults to the source image corners: `(0,0)`, `(w,0)`,
    `(w,h)`, `(0,h)`.
  - Output view stretches the selected input crop over the full stage and then
    applies the output mesh pins.
  - Saves now use `input.mode = source_crop` and `input.space = image_pixels`.
- Follow-up fix: simplified the calibration panel:
  - Input and Output buttons now visibly highlight the active edit view.
  - Removed the input nudge buttons, input scale buttons, visible reference
    selector, and Hide Controls button.
  - Reference loading remains automatic and defaults to the scene calibration
    reference.
  - `H` now toggles the same Collapse behavior instead of hiding the panel with
    no visible tab.
- Follow-up fix: replaced fixed 2x2/3x3/4x4 mesh buttons with procedural
  subdivision plus/minus. Current states are 2x2, 4x4, and 8x8. Increasing or
  decreasing subdivisions samples the current warp so previous pin work is
  preserved where possible.
- Follow-up fix: replaced the above all-axis subdivision controls with
  independent H/V tab controls. Each axis now has levels 1-4, where the point
  counts are 2, 3, 5, and 9. Pressing `+` inserts midpoint layers into existing
  spans, and pressing `-` removes midpoint layers while keeping the remaining
  coarser points aligned.
- Follow-up fix: Input and Output now act like real tabs. Output shows H/V
  subdivisions plus Match Input, Match Source, and Match Screen. Input shows
  Match Source, Match Output, and Match Screen. Save and Close remain in the
  common bottom area.
- Follow-up fix: removed the visible Output Screen control from the calibrator
  panel for now.
- Follow-up fix on 2026-07-08: Match Source now fits the source image against
  the same true 1920x1080 canonical stage rect on output. Match Input converts
  the current input crop pins from source-image pixels into stage targets for
  the whole output mesh, and Match Output converts the current output corner
  targets back into source-image crop pixels.
- Follow-up fix on 2026-07-08: source-stage matching now uses the actual
  visible reference-image fit from the Input view before converting back to
  canonical output-stage coordinates, removing the small width drift caused by
  fitting against a different abstract frame. Input and Output line segments
  now hover, select, drag, and nudge with arrow keys; selected lines move both
  endpoint pins together.
- Follow-up fix on 2026-07-08: the calibrator preview/mapping rect now
  aspect-fits the fixed 1920x1080 stage inside the current window rather than
  taking on the window's raw proportions. Resizing the window now produces
  black bars outside the locked stage instead of stretching the output map.
- Follow-up fix on 2026-07-08: trimmed the visible calibration panel into a
  minimal remote-style layout: scene selector at top, Input/Output actions in
  the center, and Save/Close at bottom. Removed visible header, status, grid,
  view, and fullscreen text; keyboard shortcuts still handle fullscreen and
  collapse behavior.
- Source choices:
  - `scene_classic_pack`: used pack thumbnail; no higher-res physical original
    was found.
  - `scene_demo_car`: used `Source/Car-CRV_v01.jpg`.
  - `scene_demo_gallery`: used `Source/gallery wall.jpeg`.
  - `scene_demo_wall`: used `Source/rock_clibming_v01.png`.
  - `scene_patriotic_pack`: used existing `levels/american_flag/reference.png`.
  - `scene_wallart`: used high-res `Source/wall art_260703_230000.jpg`,
    resized to 810x1080 to preserve aspect within 1920x1080.

## Verification

- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after the root-overlay follow-up.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after the aspect-fit and live-warp follow-ups.
- The same direct Calibrate scene load passed after the scene-first reference
  picker and collapsible/draggable panel follow-up.
- The same direct Calibrate scene load passed after adding scene calibration
  references and Input Mask edit mode.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after adding scene calibration references and Input Mask edit mode.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after replacing Input Mask with image-space source crop and separate
  Input/Output views.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after replacing Input Mask with image-space source crop and separate
  Input/Output views.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after panel cleanup and procedural subdivision controls.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after panel cleanup and procedural subdivision controls.
- `git diff --check -- app/hub/calibrate_screen.gd` passed after panel cleanup
  and procedural subdivision controls.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after H/V subdivisions and tab-specific control bodies.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after H/V subdivisions and tab-specific control bodies.
- `git diff --check -- app/hub/calibrate_screen.gd` passed after H/V
  subdivisions and tab-specific control bodies.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after the Match Input/Match Output geometry transfer fix.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after the Match Input/Match Output geometry transfer fix.
- `git diff --check -- app/hub/calibrate_screen.gd` did not report issues, but
  `calibrate_screen.gd` is currently untracked in this dirty worktree, so the
  useful verification signal is the Godot parser/scene checks above.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after the line hover/drag and visible-fit matching fix.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after the line hover/drag and visible-fit matching fix.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after locking the calibration surface to the 1920x1080 stage aspect.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after locking the calibration surface to the 1920x1080 stage aspect.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub res://calibrate_screen.tscn --quit-after 2`
  passed after the calibration panel UI trim.
- `.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --check --quit`
  passed after the calibration panel UI trim.
- Generated reference dimensions:
  `scene_classic_pack` 1024x1024, `scene_demo_car` 1280x960,
  `scene_demo_gallery` 387x516, `scene_demo_wall` 667x981,
  `scene_patriotic_pack` 1920x1080, `scene_wallart` 810x1080.
- `git diff --check -- app/hub/main.gd app/hub/calibrate_screen.gd` passed
  except the repo's known LF/CRLF warning.
- `git diff --check -- app/hub/calibrate_screen.gd` passed after the Input
  Mask follow-up.
- Godot commands required escalation because sandboxed runs cannot write the
  normal `user://logs` directory.

## Backup Status

- No git commit was made because the repo already has a large unrelated dirty
  working tree. Backup remains pending.

## Open Questions

- True dual-monitor operator/projector mode still needs a larger architecture
  pass, probably a separate projector process/window that renders the full
  calibration/game output while the hub stays on the operator monitor.
- The intended dual-screen workflow is now clearer: the projector/output window
  should always show final mapped output, while the operator monitor can switch
  between Input crop editing and Output mapping editing, with a toggle for
  showing/hiding pins on the final output.
- Launched games do not yet apply `calibration/current.yaml`. The next runtime
  pass should add a shared output warp/mapping layer so Pac-Man and the rest of
  the cartridges render through the saved scene profile.

## Next Holder Briefing

Kons should test Calibrate in fullscreen first. In Input view, confirm the
reference image stays unwarped and the crop pins sit on source-image corners.
In Output view, confirm that crop fills the stage and output pins warp it to
the screen edges. Test the subdivision flow by moving the four base corners,
raising H or V from level 1 to level 2, and confirming the old points remain
while only midpoint layers are inserted. The next implementation pass should
wire the saved profile into cartridge rendering so games actually use the
mapping.
