---
task_id: TASK-INT-cart-pacman-map-render-and-win
stage: 6
wave: 2
priority: P0
lane: cartridge
status: pending_kons_verify
owner_agent: antigravity
closing_receipt: vault/40-agent-runs/antigravity_TASK-INT-cart-pacman-map-render-and-win_2026-07-01.md
touches: [content/cartridges/pacman/main.gd]
locks_required: [cart-pacman]
depends_on: []
kind: fix
issued_by: opus_orchestrator
issued_at: 2026-07-01
severity: blocking
acceptance:
  - Classic Pac-Man map renders as an actual maze with corridors and walls, NOT a big blue blob.
  - Pickup pellets are visible along the corridors.
  - Game does NOT instantly transition to "YOU WIN!" on first frame.
  - Kons visual confirmation via screenshot on the classic_pacman level.
---

## Objective

Pacman now launches successfully (commit `52a4081` unblocked the launch chain) but exhibits two rendering / logic bugs on the `classic_pacman` level:

1. **Maze renders as an amorphous blue blob** with rounded edges covering most of the play area, instead of proper Pac-Man corridors.
2. **"YOU WIN!" fires on frame 1** — game_state flips to "win" immediately.

Both bugs are cartridge-side in `content/cartridges/pacman/main.gd`. Player and ghost entities render correctly (visible on top of the blob), so the entity system + IPC + map file loading all work. The problem is downstream: how the layout is drawn and how pickups are seeded.

## Root cause hypotheses (rank-ordered)

### Blob (most likely)

Function `_draw_maze_skin()` around line 866, and `_draw_wall_segment()` at 951. Wall thickness is computed as:

```
outer_width = 7.0 * classic_wall_width_scale * resolution_ratio
```

where `resolution_ratio = grid_cell_size / grid_cell_size_base`. Then this is fed through `_scaled_width()` which applies ANOTHER scale multiplier. On the classic_pacman map, `grid.json` has `cell_px: 60` (large — most levels are 32). This causes wall thickness to compound and merge every wall into a single filled shape.

**Corner radius** on `_draw_wall_corner` uses `outer_width * 0.5` — which becomes cell-sized circles that fill and blob everything together.

### Instant WIN (most likely)

`_build_scaled_layout_from_grid()` seeds `layout["pickups"]` from cells where `cid in [2, 7]` — should produce hundreds. Then `_apply_tunnel_fill_mask(layout, ...)` runs and prunes based on `_build_tunnel_fill_keep`. On the dense classic_pacman map, the mask may be leaving only the pickups near pacman's spawn.

Then in `_process_player` at line 1086, the pickup collection loop uses `distance_to(pickup) < 15.0` — a 15px radius. Multiple co-located pickups near spawn all get collected in a single frame. `pickups.size() == 0` fires → `game_state = "win"` (line 1095).

## Approach — two phases in one session

### Phase 1 — instrument (before fixing)

Add `emit_signal`-style debug output via `send_ipc_message` (already imported) OR direct `print()` calls at these points, so we can see the actual data flow when Kons re-launches:

1. In `_load_grid_metadata` (line 392) after loading, print: grid_rows, grid_cols, grid_cell_size_base, cell_px from data.
2. At the end of `_build_scaled_layout_from_grid` (before returning), print:
   `layout.nodes.size()`, `layout.pickups.size()`, `layout.players.size()`, `grid_cell_size`.
3. Right after `_apply_tunnel_fill_mask` runs (called around line ~430), print pickups.size() again to see how many the mask kept.
4. In `_draw_maze_skin` on the first draw call only, print `outer_width` value, `scale_factor`, `resolution_ratio`, and `classic_wall_width_scale`.

Use a one-shot flag so debug prints only fire once per launch (they'd flood otherwise).

### Phase 2 — apply the fixes

**Fix A (blob):** In `_draw_maze_skin` line ~872, remove the `resolution_ratio` multiplication from `outer_width` since `_scaled_width` already scales:

```
BEFORE: outer_width = 7.0 * classic_wall_width_scale * resolution_ratio
AFTER:  outer_width = 7.0 * classic_wall_width_scale
```

**Also** cap the corner radius so it can't exceed a fraction of a cell:

```
_draw_wall_corner(corner, min(outer_width * 0.5, grid_cell_size * 0.15), ...)
```

**Fix B (instant WIN):** Verify via the Phase 1 logs what pickups.size() actually is after `_apply_tunnel_fill_mask`. If it's < 10, the mask is too aggressive on dense maps — investigate `_build_tunnel_fill_keep`. If it's normal (>50) but pacman spawns on top of them, the fix is to give the player a start-of-game grace period (skip pickup collection for the first 5 frames) OR ensure spawn point is not on a pickup cell.

**Also** the win-condition itself deserves a sanity check: `if pickups.size() == 0 AND game_time > 0.5: game_state = "win"` — never win on the first half-second. This is a defensive belt for future.

## Rules

- Write ONLY inside `content/cartridges/pacman/**`. Everything else read-only.
- Claim: set `owner_agent` + `status: in_progress`; lock note at
  `vault/35-locks/cart-pacman.md`.
- **Pre-edit git commit + tag** required (governance pack §1.2). pacman/main.gd is 1200+ lines.
- Verify:
  1. `godot --headless --check content/cartridges/pacman/main.gd` parses.
  2. Kons launches classic_pacman from the hub. Screenshot the actual maze (not a blob) to `vault/70-qa/<agent>_pacman_render_2026-07-01.png`.
  3. Confirm game does NOT immediately show "YOU WIN!".
  4. Paste the Phase 1 debug log output into the receipt so we have the actual numbers for future gate hardening.
- Close with a receipt per `04_AGENT_HANDOFF_TEMPLATE.md`. Release the lock.

## Cold-start reads (mandatory)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. This ticket.
6. `content/cartridges/pacman/main.gd` (the whole file — it's the target).
7. `content/scenes/scene_classic_pack/levels/classic_pacman/derived/grid.json` (understand the map shape).
