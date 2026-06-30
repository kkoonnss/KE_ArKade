# HANDOFF — KE_ArKade Stage 6 (Universal Level Interpretation + Editor)

**For:** the incoming orchestrator (Opus). **As of:** 2026-06-27.
**Read these first:** this file → `PLAN_interpretation-and-editor.md` (strategy) →
`INTEGRATION_CONTRACT.md` (ownership) → `DISPATCH.md` (kickoff prompts + the recipe).
**Board:** `vault/60-bases/interpretation.base` (Obsidian Base over `vault/30-tasks/TASK-INT-*`).

---

## Your role & the fleet model
- **You = Opus orchestrator.** Kons keeps Claude credits for orchestration; do NOT spawn Claude sub-agents. You write tickets, route work, and VERIFY — the build is done by two external fleets Kons runs and reports back from:
  - **Codex** → Python / `app/tools/**` (compiler, CV/derive backend).
  - **Antigravity** → Godot / GDScript: `app/hub/**`, `app/shared/**`, and the cartridges.
- Kons pastes the prompts you write into agent instances and replies "done." **Keep the same agent on the same games** (his preference).
- Communicate with Kons in plain English, short. Technical detail goes in tickets, not chat.

## THE #1 RULE (learned the hard way this session)
**A ticket marked `done` is NOT proof.** Agents repeatedly marked things done without compiling or launching. Before you trust "done" or cascade dependent work, **verify by real output**:
- Code gate (you can run this via `mcp__workspace__bash` on the repo mount): `grep` that the actual integration exists.
- **You cannot launch Godot** — Kons is the visual check. Ask him to launch the specific screen/game and confirm.
- Caveat: the bash mount can lag; for fresh edits prefer Read/Grep on the host path.

## The load-bearing technical fact (do not relitigate)
Every cartridge AND the hub are **separate Godot projects** — `res://` = that project's own folder, so `app/shared` is OUTSIDE it. Therefore:
- **NEVER** use global `class_name` (e.g. `RegionAdapter.new()`, `TabMenu.new()`) or `res://`-relative preloads to reach shared code from a cartridge/hub — it won't resolve → crash/flash-loop.
- **ALWAYS** load shared scripts at runtime via repo-root resolution: `app/shared/shared_loader.gd` (`SharedLoader.load_adapter_script("<arch>")`, `load_tab_menu_script()`). The hub uses `_get_repo_root()` the same way.
- **Canonical copy-me model:** `content/cartridges/gta/main.gd`. The exact recipe is in `DISPATCH.md`.

## The cartridge gate (every game must pass before "done")
1. `grep -E "SharedLoader" content/cartridges/<game>/` → hits.
2. `grep -E "Adapter\.new\(\)|TabMenu\.new\(\)" content/cartridges/<game>/` → EMPTY.
3. No `content/cartridges/<game>/adapter_base.gd` (no copied shared files).
4. Kons launches it: no flashing, reads the map, Tab menu opens.

---

## Where we are

### Foundation — DONE (INT-00..INT-07) + two in flight
| Ticket | What | Status |
|---|---|---|
| INT-00 | compile-all-derived (`app/tools/arena_compiler/compile_level.py` + batch) | done |
| INT-01 | 7 archetype adapters in `app/shared/adapters/` | done |
| INT-02 | map-fit ops + shared `TabMenu` shell (`app/shared/controls/`) | done |
| INT-03 | Design screen in hub | done |
| INT-04 | Design screen controller+mouse input | done |
| INT-05 | **SharedLoader standard** + gta retrofit (the linchpin) | done |
| INT-06 | hub content panels (Scenes/Games/Levels) populate | done |
| INT-07 | Design screen blank fix + Calibrate cleanup | done |
| **INT-08** | Design "Save" must actually compile derived/ + verify (was lying about success) | **in_progress (Antigravity)** |
| **INT-09** | restore auto-derive preset dropdown in Design screen | **in_progress (Antigravity, same hub-design lock as INT-08, sequential)** |

INT-08 + INT-09 are the SAME Antigravity instance on `design_screen.gd` under the `hub-design` lock — must stay one hub instance, sequential. Verify INT-08 by: author a level in Design → save → confirm `derived/grid.json` exists → launch a game on it.

### Cartridges (32 games; `loopback` excluded)
- **DONE + gate-clean (SharedLoader):** gta (canonical), pacman, tetris, donkey_kong, rampage, asteroids, paperboy. *(pacman + asteroids passed the code gate but still need Kons's launch confirmation.)*
- **DONE but BESPOKE (work, need cleanup):** galaga, frogger, on_track — they read the map with their own code + carry a local `adapter_base.gd`. Small follow-on: convert to SharedLoader/adapters + delete local copy (logged in OPEN_QUESTIONS). rampage's earlier misalignment came from this same bespoke pattern, fixed by switching to the region adapter — apply the same lesson here.
- **READY — the cascade (22 games):** dispatched as two bundles (recipe + gate in `DISPATCH.md`):
  - **Antigravity (13):** maze → snake, tron, gauntlet, dig_dug, marble_madness, qbert · well_fill → breakout, bomberman, centipede, pong · platform → lunar_lander, burger_time, bubble_bobble
  - **Codex (9):** arena → space_invaders, robotron_2084, smash_tv, defender, missile_command, battlezone, joust, tempest · lane → tapper
  - One game per instance, fully parallel (each its own folder). Confirm with Kons whether these are already running; verify each via the gate as they return.

---

## Your immediate next moves
1. Confirm INT-08 actually produces `derived/` on save + INT-09 preset dropdown works (Kons launches Design).
2. Get Kons's launch confirmation on pacman + asteroids; if good, the SharedLoader pattern is fully proven.
3. Drive the 22-game cascade to completion, grep-gating each returned game.
4. Then **Wave 3 = per-game polish/tuning** (alignment, knob ranges) + the galaga/frogger/on_track cleanup. Generate Wave-3 tickets per game as Wave-2 closes.

## Open decisions (in `vault/40-agent-runs/OPEN_QUESTIONS.md`)
- Archetype assignments are sensible defaults — adjust if a game plays better as another type.
- Wave-3 polish ordering (likely "venue hit" games: Pac-Man, Bomberman, 4p Tetris, Frogger).
- Freeze `app/shared/**` adapter contracts (treat like schemas — changes route through you) now that 7+ games depend on them.
- Raspberry Pi: design is Pi-portable; **defer Pi perf tuning to Phase 3**, don't let it tax this stage.

## Gotchas / norms
- Schemas in `vault/50-schemas/` are FROZEN; only the orchestrator changes them.
- Cartridges run as separate processes; hub is the launcher (crash isolation is non-negotiable).
- One agent per folder/lock at a time; `app/hub` work shares the `hub-design` lock.
- Design system is law: black base, thin white structure, cyan-led neon; homage names only.
- The arena compiler runs fine headless (cv2+numpy). If Kons's in-hub save can't generate derived, it's usually a `python` PATH / opencv issue on his machine (that's part of INT-08).
