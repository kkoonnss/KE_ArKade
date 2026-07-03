---
task_id: TASK-INT-hub-classic-routing-data-driven
stage: 6
wave: 2
priority: P0
lane: hub
status: pending_kons_verify
owner_agent: claude_sonnet
touches: [app/hub/main.gd]
locks_required: [hub-design]
depends_on: []
kind: fix
issued_by: opus_orchestrator
issued_at: 2026-07-01
severity: blocking
closing_receipt: vault/40-agent-runs/claude_hub_classic_routing_continuation_2026-07-03.md
acceptance:
  - Clicking ANY cart in the hub routes to that cart's classic_<id> level if it exists in scene_classic_pack/levels/, regardless of the cart id.
  - No hardcoded classic-game list in main.gd — the routing is data-driven off the filesystem.
  - Fallback to scene_demo_wall/demo_level ONLY when no classic_<id> level exists.
  - Kons visual confirmation: launch 3-4 previously-broken carts (e.g. snake, breakout, qbert, dig_dug) and confirm they now load their classic level instead of demo_wall.
---

## Objective

Since the hub's post-corruption rebuild removed the level selection screen, clicking a game card in the hub jumps straight to launching a cart with a hub-decided level. The current routing hardcodes only 9 game IDs as classic-pack members:

```
if cart_id in ["tetris", "pacman", "bomberman", "frogger", "asteroids", "tron", "on_track", "rampage", "gta"]:
    current_scene = "scene_classic_pack"
    selected_level_name = "classic_" + cart_id
```

For any cart NOT in that list, the hub falls through to `scene_demo_wall / demo_level` — the wrong level for those games. Result: most carts (snake, gauntlet, dig_dug, qbert, breakout, centipede, pong, lunar_lander, burger_time, bubble_bobble, space_invaders, robotron_2084, smash_tv, defender, missile_command, battlezone, joust, tempest, tapper, marble_madness, paperboy, galaga, donkey_kong) load an incompatible level and behave broken (die instantly, wrong dimensions, missing spawns).

**Verified filesystem state:** `content/scenes/scene_classic_pack/levels/` contains `classic_<id>` directories for ALL 32 carts, not just 9. The hub's hardcoded list is a rebuild-era regression that lost the level-detection logic.

## Root cause

`_launch_game()` around line 330 of `app/hub/main.gd`. The check should be data-driven off the filesystem instead of a hardcoded list.

## Expected shape of the fix

Replace the hardcoded array check with a directory-exists check:

```gdscript
# BEFORE (line ~326-332):
if current_scene == "" or current_scene == "scene_classic_pack":
    if cart_id in ["tetris", "pacman", "bomberman", "frogger", "asteroids", "tron", "on_track", "rampage", "gta"]:
        current_scene = "scene_classic_pack"
        selected_level_name = "classic_" + cart_id

# AFTER:
if current_scene == "" or current_scene == "scene_classic_pack":
    var candidate_level = "classic_" + cart_id
    var candidate_path = base_dir.path_join("content/scenes/scene_classic_pack/levels").path_join(candidate_level)
    if DirAccess.dir_exists_absolute(candidate_path):
        current_scene = "scene_classic_pack"
        selected_level_name = candidate_level
```

Note: `base_dir` is already computed earlier in `_launch_game` — reuse it (or move it above this check).

The fall-through to `scene_demo_wall / demo_level` remains untouched — it fires only when no `classic_<cart_id>` level exists on disk.

## Related-but-separate work (do NOT fix in this ticket)

**Missing semantic_maps.** Of the 32 classic levels, only 7 have a `semantic_map.png` (bomberman, frogger, gta, on_track, pacman, rampage, tetris). The other 25 have derived files but no source image. This is a data problem — the derived files were likely stubbed during recovery. Even after this routing fix, those 25 carts will load levels with structurally empty derived files.

Track as a separate follow-on ticket: `TASK-INT-classic-levels-missing-semantic-maps` (P1, lane: content, needs the arena compiler to regenerate from either the reference photo or fresh source painting).

**Cart-side rendering bugs.** Pacman blobs. Tetris blacks out. Others may die instantly for cart-side reasons (map interpretation bugs, adapter mismatch, hardcoded starting conditions). These are per-cart tickets tracked separately — see `TASK-INT-cart-pacman-map-render-and-win` for the template.

## Rules

- Write ONLY inside `app/hub/**`. Everything else read-only.
- Claim: set `owner_agent` + `status: in_progress`; lock note at
  `vault/35-locks/hub-design.md`.
- **Pre-edit git commit + tag** required (governance pack §1.2). main.gd is 1000+ lines and was the corruption site.
- Verify:
  1. `godot --headless --check app/hub/main.gd` parses.
  2. Kons launches 3-4 previously-broken carts (snake, breakout, qbert, dig_dug). Screenshot each to `vault/70-qa/<agent>_routing_<cart>_2026-07-01.png`. Note: they may still have cart-side rendering bugs — the acceptance criterion is only that the CORRECT level loads, not that gameplay is perfect. The Log button's DEBUG output should show the correct scene_dir + level_dir now.
  3. Kons launches a cart NOT in the classic pack (there should be none currently — all 32 have a classic level — but if any exists, confirm it falls back to demo_wall correctly).
- Close with a receipt per `04_AGENT_HANDOFF_TEMPLATE.md`. Release the lock.

## Cold-start reads (mandatory)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. This ticket.
