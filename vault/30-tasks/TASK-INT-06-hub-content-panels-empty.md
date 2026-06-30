---
task_id: TASK-INT-06-hub-content-panels-empty
stage: 6
wave: 0
priority: P0
lane: hub
archetype: n/a
status: done
owner_agent: "Antigravity"
touches: [app/hub]
locks_required: [hub-design]
depends_on: []
acceptance:
  - Scenes panel lists the scenes (scene_classic_pack, scene_demo_wall) on launch AND on clicking Scenes
  - Games panel lists the cartridges; Levels panel lists levels for a chosen scene
  - Verified by a real screenshot of the running hub with populated panels (not just code)
---

## Objective
The hub launches (v01.01.00) but every content panel renders EMPTY — Scenes/Games/Levels show nothing (screenshot from Kons 2026-06-26). Content is present and the repo-root resolution exists, so this is a scan-path or render/visibility bug. Find and fix the real cause; verify by screenshot.

## Confirmed by orchestrator (don't re-derive)
- Content exists: `content/scenes/` has 2 scenes WITH `scene.yaml` (scene_classic_pack, scene_demo_wall); `content/cartridges/` has 33 `manifest.yaml`.
- `_ready()` already calls `display_scenes()` (main.gd ~line 159) and the nav buttons are wired.

## Two leads — check both
1. **Scan path.** `display_scenes()` (main.gd ~728) uses
   `ProjectSettings.globalize_path("res://").path_join("../../content/scenes")` then `DirAccess.open`.
   - Add/inspect the existing `print("Failed to open scenes dir: ", base_dir)` (line ~745). If it fires, the `../../` isn't resolving for how the hub is actually launched (editor vs exported build — globalize_path differs; an exported build won't have `../../content` beside it).
   - Note `path_join` does NOT collapse `..`; it relies on the OS. Prefer `.simplify_path()` and confirm the resolved absolute path actually points at the real `content/scenes`. Mirror the SAME repo-root resolution the cartridges now use (`app/shared/shared_loader.gd` `repo_root()`), so the hub and cartridges agree on where the repo root is.
2. **Render/visibility.** `_ready()` (~lines 97-108) reparents `scenes_grid` into a new `scroll_vbox` → `scroll_container`. Confirm `scenes_grid` ends up a VISIBLE descendant of `$UI/Content/MainPanel` and that `_prepare_scroll_view()` shows it. Buttons may be getting added to a detached/hidden node → empty panel even when the scan works.

Apply the same fix pattern to `display_games()` (~467) and the Levels view. Likely a regression from the Design-screen work (TASK-INT-03/04) — diff app/hub if helpful.

## Notes
- Own ONLY `app/hub/**`. Lock `hub-design`. Verify by launching the hub and screenshotting populated panels — code-only is not done.
