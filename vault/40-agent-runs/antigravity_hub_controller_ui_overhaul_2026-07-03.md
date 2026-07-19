---
run_id: antigravity_hub_controller_ui_overhaul_2026-07-03
agent: antigravity
session_start: 2026-07-03T16:33:00-07:00
session_end: pending
task_id: TASK-INT-hub-controller-ui-overhaul
lane: hub
lock_held: hub-design
status: in_progress
pre_edit_commit: 02422b3
close_commit: pending
backup_status: backed_up (02422b3 pushed to origin)
backup_remote: https://github.com/kkoonnss/KE_ArKade.git
escalations: []
---

# Agent Run — Hub Controller UI Overhaul

## Context

Kons provided detailed feedback on 2026-07-03 covering:
1. SideNav navigation (treat as single group, Help→up=Log)
2. Left/right D-pad switching between SideNav ↔ content
3. Remember last focused item per side per menu
4. A button on SideNav guides to content; B in content goes up a level
5. Right stick scrolling + selection snap
6. Skin switching redesign (X/Y buttons, single line)
7. Unified card layout (4 columns, bigger, same for classic and custom)
8. Global scale slider
9. Classic Pack thumbnail generation
10. Scene/level thumbnails from reference images
11. demo_level cleanup
12. Rockwall layout fix
13. Thumbnail convention documentation

## Research Findings

### SideNav Structure (from main.tscn)
Order: ScenesBtn → LevelsBtn → GamesBtn → DesignBtn → CalibrateBtn →
DevicesBtn(hidden) → ServiceBtn("Log") → Spacer → HelpBtn → TestPatternBtn → RestoreBtn

### Key File Facts
- `main.gd`: 1536 lines. All card creation, navigation, and input handling.
- `main.tscn`: 206-line scene. SideNav has 11 children (7 buttons + spacer + 3 bottom buttons).
- Card types: game cards (PanelContainer 260×300, with skin switcher) and level cards (Button 256×284, simpler).
- Grids: 3 columns for display_games/display_scenes, 6 columns for games_lightbox overlay.
- Bomberman skin thumbnail: `thumbnail_boomer_man.png` exists.
- demo_level: Only adjustment JSONs, no images/maps. Likely an artifact.
- Favorites default: tetris, pacman, bomberman, frogger, asteroids (5 games, not 6 — Kons said 6).

## Sub-task Progress

### Group A — Navigation & Input
- [ ] A1: SideNav vertical focus chain
- [ ] A2: Left/right D-pad SideNav ↔ content switching
- [ ] A3: Remember last focused item per side
- [ ] A4: Content starts at first item on entry
- [ ] A5: A=accept on SideNav, B=cancel goes up levels
- [ ] A6: Right stick scrolling
- [ ] A7: Selection snap on focus change
- [ ] A8: Tab menu scroll tracking

### Group B — Card Layout & Skin Switching
- [ ] B1: X/Y skin switching, single-line title
- [ ] B2: Unify classic and custom card layouts
- [ ] B3: 4 columns, bigger cards
- [ ] B4: Global scale slider

### Group C — Content & Assets
- [ ] C1: Classic Pack thumbnail
- [ ] C2: Scene/level thumbnail coverage
- [ ] C3: demo_level cleanup
- [ ] C4: Rockwall layout fix
- [ ] C5: Thumbnail convention doc

## Execution Strategy

Groups A and C run in parallel (different files).
Group B runs after A (same file: main.gd).
All progress tracked here and in vault task ticket.
