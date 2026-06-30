# EXECUTE — KE_ArKade MVP, full build in one streak

**You are the executing fleet for the entire KE_ArKade MVP.** (Assigned to
Antigravity right now because it has the capacity; the work itself is
agent-agnostic — see the contract.) Your job: **build the whole wall MVP in one
big session, fanning out as many parallel sub-agents as you can.** Don't stop for
check-ins between packages — run the full streak, then self-verify and write a
build report for Opus (the orchestrator) to review.

---

## Read first, in this order
1. `_Briefs/00_MASTER_PLAN.md` — what we're building and why.
2. `_Briefs/INTEGRATION_CONTRACT.md` — the seams + folder-ownership rules. **Honor these for your own sub-agents.**
3. `vault/50-schemas/*.yaml` — the FROZEN vocabulary (palette, scene, level, cartridge). Treat as law.
4. `vault/20-architecture/` — `design-brief.md`, `hub-architecture.md`, `arena-pipeline.md`, `input-and-players.md`, `level-authoring.md`.
5. The three work-package briefs (now your packages, not other agents'):
   `01_BRIEF_arena-compiler_CODEX.md`, `02_BRIEF_godot-hub_ANTIGRAVITY.md`, `03_BRIEF_contracts-qa_SONNET.md`.

## Non-negotiable golden rules
- **Wall MVP, Profile L (laptop).** No floor, no camera, no Pi, no body-tracking.
- **Two games, one untouched map.** Lumen Maze (reads `navgraph`) + Neon Stack
  (reads `container`) both run off the SAME `semantic_map.png`. This IS the test.
- **Cartridges = separate OS processes.** Hub is a launcher. A crashing game must
  never kill the hub. Each game gets its own log + can run standalone.
- **Follow `design-brief.md` for all visuals.** Black base, thin white lines,
  poppy neon semantic accents, festival-readable.
- **Schemas are frozen.** If you truly need a change, DON'T silently edit —
  record it in a `vault/30-tasks/` note + in the BUILD_REPORT for Opus to ratify.
- **Your sub-agents obey folder ownership.** No two concurrent sub-agents write
  the same tree. Partition exactly along the work-packages below.

## Work packages & dependency order (parallelize hard)
Spin sub-agents per package; within a package, split further where folders allow.

- **WP-A — shared + seed** (`app/shared/**`, `content/scenes/**`): codegen
  `palette.py` + `palette.gd` from the YAML; schema validators; one verified
  **wall** seed scene + one deliberately-imperfect shared level
  (`solid`+`path`+`spawn`+`pickup`+`goal`). _Start first — unblocks everyone._
- **WP-B — compiler + tools** (`app/tools/**`): arena compiler (paint→map);
  derived `navgraph` + `container` + `occupancy` (golden-tested); the
  level-authoring tool (slider + paint-over-photo + opacity toggle); manual
  4-point calibration. _Parallel with A and C._
- **WP-C — hub + launcher** (`app/hub/**`): kiosk shell (scenes gallery, level
  swiper, Panic Black, Last-Known-Good, test pattern, controller/display test);
  separate-process launcher + NDJSON IPC + heartbeat-kill; input layer
  (keyboard→Xbox→SNES, slots 1–4); compatibility gate; a loopback stub cartridge
  to prove IPC + kill. _Parallel; stub palette consts until WP-A lands._
- **WP-D — the two cartridges** (`content/cartridges/**`): `pacman`
  (Lumen Maze) and `tetris` (Neon Stack), separate-process Godot games on
  the IPC contract, designed for up to 4 players. _Depends on A (shared) +
  B (derived layers) + C (loopback IPC proven)._
- **WP-E — QA** (`vault/70-qa/**`): golden tests for `navgraph`/`container`;
  venue acceptance script; the full integration run (both games on one map).

## Definition of done (the honest test)
On one **wall** scene + one untouched `semantic_map.png`: **Lumen Maze AND Neon
Stack both launch from the hub as separate processes and play** — keyboard first,
then Xbox + SNES-clone (up to 4 slots); a simulated cartridge crash / heartbeat
timeout returns cleanly to the hub; Panic Black blanks instantly; stable 60 fps
on Profile L. Awkward map interpretations are acceptable.

## Self-verify before declaring done
- Run the golden tests (WP-E) — green.
- Launch both games off the seed map; capture a screenshot of each.
- Kill a running cartridge process mid-game; confirm the hub survives + restores.
- Hit Panic Black mid-game; confirm instant blank + recover.
- Note FPS on Profile L.

## Handoff for Opus review (do this at the end of the streak)
Write `vault/80-builds/BUILD_REPORT.md`: what built, what passed/failed each
done-criterion, screenshots/log locations, any deviations, and any schema-change
requests. Drop per-package run logs in `vault/40-agent-runs/` and QA results in
`vault/70-qa/`. Then stop and signal ready-for-review — Opus checks the work.
