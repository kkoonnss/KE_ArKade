---
task_id: TASK-INT-hub-controller-ui-overhaul
stage: 6
wave: 2
priority: P0
lane: hub
status: in_progress
owner_agent: antigravity
touches: [app/hub/main.gd, app/hub/main.tscn]
locks_required: [hub-design]
depends_on: []
kind: feature
issued_by: kons_direct
issued_at: 2026-07-03
severity: high
acceptance:
  - Left panel (SideNav) treated as single navigation group; Help→up goes to Log
  - Left/right D-pad switches between SideNav and main content grid
  - Each side remembers its last focused item per menu
  - Main content always starts focus at first item on entry
  - A button on SideNav guides to right content area
  - B button in content goes up one level (levels→scenes, scenes→SideNav)
  - Right stick up/down scrolls like mouse wheel; selection snap keeps focused item visible
  - Game settings scroll tracking matches the same pattern
  - Skin selection uses X/Y controller buttons (prev/next) with single-line title
  - Classic games and custom game cards use same layout (4 columns, bigger)
  - Global scale slider in top-right, unified across all views
  - Classic Pack scene has a generated thumbnail image
  - All scenes/levels have thumbnails derived from reference images
  - demo_level removed if unused
  - Rockwall second-row layout issue fixed
---

## Objective

Complete controller-first UI overhaul of the hub. Kons provided detailed
feedback on 2026-07-03 covering navigation, scrolling, card layout, skin
switching, thumbnails, and scale. This ticket bundles all items into one
coordinated pass.

## Sub-tasks

### A — Navigation & Input (main.gd)
- [ ] A1: SideNav as single focus group — wire all nav buttons vertically (Help→up=Log, etc.)
- [ ] A2: Left/right D-pad switches between SideNav ↔ content grid
- [ ] A3: Remember last focused item per side per menu
- [ ] A4: Main content starts at first item on initial entry
- [ ] A5: A button on SideNav → guide to content; B in content → go up a level
- [ ] A6: Right stick up/down → scroll like mouse wheel
- [ ] A7: Selection movement always snaps scroll to keep focused item visible
- [ ] A8: Game settings (tab_menu) gets same scroll tracking

### B — Card Layout & Skin Switching (main.gd)
- [ ] B1: Redesign skin switching — X/Y buttons, single-line title with arrows
- [ ] B2: Unify classic games and custom cartridge card layouts
- [ ] B3: Change grid to 4 columns, increase card size
- [ ] B4: Global scale slider in top-right, unified parameter

### C — Content & Assets
- [ ] C1: Generate Classic Pack thumbnail image
- [ ] C2: Ensure all scenes/levels have thumbnails (reference image fallback)
- [ ] C3: Check and remove demo_level if unused
- [ ] C4: Fix Rockwall second-row layout issue
- [ ] C5: Document thumbnail/card image conventions

## Rules

- Write ONLY inside `app/hub/**` and `content/` for assets. Vault for docs.
- Lock: `hub-design` (already held).
- Pre-edit snapshot already committed (`02422b3`).
- Verify: Godot parse check + Kons click-through.
- Close with receipt in `vault/40-agent-runs/`.
