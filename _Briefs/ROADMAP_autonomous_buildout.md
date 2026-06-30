# ROADMAP — Autonomous build-out (run while Opus is offline)

**You are the executing fleet AND your own orchestrator** (Antigravity by
capacity; agent-agnostic). Opus is offline. You grab your own tickets, sequence
your own work, and run the loop below until the backlog is done or everything
left is blocked. Don't wait for sign-off between stages. When something needs an
Opus/Kons decision, **don't block** — log it in
`vault/40-agent-runs/OPEN_QUESTIONS.md` and pull the next ticket.

This file is the single authoritative directive. Everything else it points to is
context.

## Source of truth — read before starting
- `_Briefs/00_MASTER_PLAN.md` — vision + locked decisions.
- `_Briefs/INTEGRATION_CONTRACT.md` — ownership, IPC contract, seams, work-packages.
- `vault/50-schemas/*.yaml` — FROZEN data contracts (palette, scene, level, cartridge).
- `vault/20-architecture/` — hub-architecture, arena-pipeline, input-and-players,
  level-authoring, design-brief, **design-system** (the visual law).
- `design/frames/arkade_design_v1.html` — visual north star.
- `vault/80-builds/BUILD_REPORT.md` + Addenda 01–04 — what's already done.

## How you run yourself (self-orchestration loop)
Ticket board = `vault/30-tasks/` (one `.md` per ticket; frontmatter: `task_id`,
`stage`, `status` [ready|in_progress|blocked|done], `owner_agent`, `touches`,
`locks_required`, `acceptance`). Decompose the stages below into tickets; create
more as needed.

Loop, continuously:
1. **Pick** the highest-priority `ready` ticket whose dependencies are met.
2. **Claim** it: set `owner_agent` + `status: in_progress`; for shared trees drop a
   lock note in `vault/35-locks/`.
3. **Build** only inside your owned tree (`INTEGRATION_CONTRACT` §1).
4. **Verify against acceptance by real output** — run the test, sample the
   screenshot, measure the FPS. "Code written" is NOT done.
5. **Close**: `status: done`, write a run log (`vault/40-agent-runs/`) + QA note
   (`vault/70-qa/`), release the lock. → next ticket.
   On fail/blocked: `status: blocked`, record why in `OPEN_QUESTIONS.md`, move on.

Parallelize across **disjoint trees** (never two agents in one tree). Respect
stage order for dependencies, but pull independent tickets forward to keep every
agent busy.

## Always-on guardrails
- **Schemas are frozen** (`vault/50-schemas/`). Need a change? Log it, don't edit.
- **Cartridges = separate processes**; hub is the launcher. Keep crash isolation.
- **Sub-agents respect folder ownership** (`INTEGRATION_CONTRACT.md`) — no two write the same tree.
- **Design system is law** (`vault/20-architecture/design-system.md`): black base,
  thin white structure, cool cyan-led neon, punchier festival glow, homage names only.
- **Verify by the actual pixels / running output, not by the code value.** Sample
  the screenshot before claiming a visual fix.
- **Out of scope (do NOT build):** floor/table orientation, body/camera tracking,
  Raspberry Pi/Profile P, ChArUco. Those are future phases.
- Keep `vault/80-builds/BUILD_REPORT.md` + `vault/40-agent-runs/` updated as you go.

---

## STAGE 0 — Finish the visual lock (do first)
- **Background is still GRAY in the latest captures, not black.** Put a
  full-viewport pure-`#000000` layer behind everything in BOTH games AND the hub
  (black clear color / full-rect ColorRect at the back). Confirm by sampling the
  corner pixels of a fresh screenshot ≈ #000. This is the #1 projection rule.
- Re-capture Lumen Maze + Neon Stack on true black; confirm they match
  `design/frames/arkade_design_v1.html`.

## STAGE 1 — Make the two MVP games actually playable
- **Lumen Maze:** enemies that move along the navgraph; pickup collection + score;
  win (all pickups) and lose (caught) states; lives; restart. Keyboard first, then
  Xbox + SNES. Emit score/state to the hub over IPC.
- **Neon Stack:** full falling-block rules (spawn, move, rotate, soft/hard drop,
  line clear, top-out game over) inside the non-rectangular well; scoring;
  **1–4 player slots sharing the one mapped well** (the standout). Controls + IPC.
- Both: honor IPC `pause/resume/quit/blank`; clean exit.

## STAGE 2 — Hub completeness
- Scenes gallery + level swiper fully working from the content scan.
- **Devices** screen: live controller test for keyboard / Xbox / SNES; slot
  assignment 1–4.
- **Calibrate** screen: wire the manual 4-point flow to the calibration tool;
  test pattern; save into the scene's calibration file.
- **Service** screen: last-known-good restore, blank, log view.
- `override.cfg` support; enforce the compatibility gate (only offer launchable
  cartridges per level).

## STAGE 3 — Content depth (prove the thesis again)
- Author a **second level** in `scene_demo_wall` with the level tool; confirm
  level-swap <10s with the SAME cartridges reading a different map.
- Level-authoring tool: both modes solid — slider (photo→zones) and paint-over-
  photo (opacity toggle) — emitting schema-conformant levels. Make it fun/simple.

## STAGE 4 — Bring the three stubs to playable + skinned (in this order)
Each reads the shared map + `grid.json`, is IPC-compliant, skinned to the design
system, homage-named:
1. **Frogger** (Frogger-like): lanes/hazards, spawn→goal, score.
2. **On Track** (racing): use `track_centerline.json`; laps + checkpoints; 1–4p.
3. **Boomer Man** (Bomberman-like): grid bombs, destructibles, multiplayer.

## STAGE 5 — Polish & QA
- Golden tests green from a clean checkout for ALL derived layers (navgraph,
  container, grid, occupancy, track_centerline).
- Confirm 60 fps on Profile L for the hub and each game; log any misses.
- Run the venue acceptance script end-to-end; log results.
- Add a **splash / game-start screen featuring the bold, edgy K** (the parked
  brand moment) — now is the time; keep it off the running gameplay UI.
- Regenerate all screenshots into `vault/70-qa/`; update the BUILD_REPORT
  comparison table beside the north-star mockup.

---

## Handoff for Opus review
In `vault/80-builds/BUILD_REPORT.md`, give a **stage-by-stage status**
(done / partial / blocked) with evidence (screenshots, test output, FPS). Put all
decisions you parked in `vault/40-agent-runs/OPEN_QUESTIONS.md`. Then stop and
signal ready-for-review. Build as far down this list as you can.
