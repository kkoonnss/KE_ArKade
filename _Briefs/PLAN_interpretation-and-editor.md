# PLAN — Universal Level Interpretation + Editor Overhaul

**Stage 6 charter. Authoritative directive for this arc.** Extends
`ROADMAP_autonomous_buildout.md`; same self-orchestration loop, same
`INTEGRATION_CONTRACT.md` ownership rules. Opus authored; fleets execute.

**One line:** Every cartridge already runs as a real game — now make every
cartridge *read the painted map and build its level from it*, give each a
per-game tuning menu, and rebuild the level editor as a controller-driven
Design screen inside the hub. Do it once in shared code, then fan out across
all games in parallel with zero collisions.

---

## 0. Read order (before claiming a ticket)

1. This file (the strategy + the law for Stage 6).
2. `INTEGRATION_CONTRACT.md` §1 (folder ownership — the collision rule).
3. `vault/20-architecture/arena-pipeline.md` + `level-authoring.md` (the pipeline).
4. `vault/50-schemas/semantic-palette-v1.yaml` (FROZEN class vocabulary).
5. The Base: open `vault/60-bases/interpretation.base` → **Ready now** view →
   claim a ticket whose lane nobody else holds.

---

## 1. What the audit found (the real starting line)

The vision is **already proven** — in exactly one game.

- **Palette v1 is frozen and clean** (10 classes: empty/solid/path/platform_top/
  hazard/spawn/goal/pickup/tracking/ui_safe). Solid foundation; do not touch.
- **The pipeline exists** but is uneven. The arena compiler snaps a source image
  to the palette; the authoring tool runs the derived-layer generators
  (`navgraph`, `container`, `grid`, `occupancy`, `platform_edges`,
  `track_centerline`) on save. **But only ~6 of 33 levels actually have
  `grid.json`/`container.json` baked** — most have only `navgraph`. `classic_gta`
  has *no* derived layers at all. The universal substrate is not universally
  present.
- **All 33 cartridges are full, playable games** (1,400–1,800 lines each). What's
  thin is **map-interpretation depth**: most read the map only for the outer
  boundary, then play a generic, self-seeded version (e.g. Galaga reads
  `grid.json` for bounds but spawns waves procedurally).
- **Pac-Man is the finished proof of the entire thesis.** It reads `grid.json` →
  builds a node graph from walkable cells → seeds spawns/pickups by class →
  falls back to `navgraph` → and exposes a **per-game Tab menu** with reference
  opacity, **grid scale**, **wall width**, and **invert solid**. That is the
  whole product, working, in one cartridge.
- **The per-game settings backend is built and shared** (`level_adjustments.gd`:
  load/save keyed by `scene_id/level_id`, never mutating the map). Three stubs
  (frogger, bomberman, on_track) already carry their own copy.

**Conclusion:** this stage is not 33 build-from-scratch jobs. It is **one
generalization job** — lift Pac-Man's pattern into shared code — followed by a
**wide, mechanical fan-out**. That is the path of least resistance, and it is
naturally collision-free because each cartridge lives in its own folder.

---

## 2. The core strategy (build once, fan out)

Do **not** hand-author 33 bespoke map interpreters (easy-early, expensive-late).
Invest once in three shared foundations, then every game becomes a thin config:

1. **Universal compile-all-derived step.** Every level gets the *full* derived
   set baked (so any game can read any layer on any map). One headless,
   golden-tested entry point; batch-run across all existing levels.
2. **A shared interpretation library (the archetypes).** The 33 games cluster
   into **7 ways of reading a map**. Build 7 shared adapters; each game picks
   one. This is the linchpin.
3. **A shared secondary-controls toolkit + Tab shell.** Generalize Pac-Man's
   invert/scale/wall-width into a reusable set of in-memory **map-fit ops**
   (fill, invert, block, scale, wall, density, bounds, smooth) plus one shared
   controller-driven settings menu every cartridge dresses with its own knobs.

Then the editor overhaul (Design screen in the hub) consumes the *same*
adapters for a live preview — so what the designer sees while painting is
literally what the games will do.

### The success bar (and the safety net)

> **Every game must produce something that reads as that game in any space.**
> Perfect fit is a bonus, not the bar. The novelty — nostalgic hits re-skinned
> onto a real wall, four controllers out, people gathering — is the minimum win.

Guarantee it with a **procedural fallback in every adapter**: if a map yields
too little for an archetype (e.g. no walkable cells for a maze), the adapter
seeds a sensible default *inside the bounds* so the game always boots to
something playable. Pac-Man already does this (grid → navgraph → generic). Every
adapter inherits the same contract: **never boot to an empty level.**

---

## 3. The archetype taxonomy (how the 7 adapters read a map)

Each adapter is a shared module. Each game declares its archetype + the knobs it
exposes. The first game in each family is the **reference** that validates the
adapter before the rest of the family rolls out.

| Archetype | Reads | Reference | Family (all games) |
|---|---|---|---|
| **Maze / Graph** | `grid` walkable cells → node graph, corridors, pickups | **pacman** ✅ | pacman, snake, tron, gauntlet, dig_dug, marble_madness, qbert |
| **Well / Fill** | `solid` region + `container` boundary → fill the shape with objects | **tetris** | tetris, breakout, bomberman, centipede, pong |
| **Open Arena** | `container` boundary = playfield edge; `solid` blocks = cover; waves spawn inside | **galaga** | galaga, asteroids, space_invaders, robotron_2084, smash_tv, defender, missile_command, battlezone, joust, tempest |
| **Lane / Flow** | `grid` rows/bands → traffic/water/safe lanes; spawn→goal crossing | **frogger** | frogger, paperboy, tapper |
| **Track** | `track_centerline` → lap + checkpoints | **on_track** | on_track |
| **Platform / Gravity** | `platform_top` edges + **procedurally add platforms** where boundaries/islands suggest; gravity | **donkey_kong** | donkey_kong, lunar_lander, burger_time, bubble_bobble |
| **Region / Block** | `solid` contours → city blocks / buildings / extruded shapes | **gta** | gta, rampage |

`loopback` is the IPC test cartridge, not a game — excluded.

This mirrors your own five concept frames exactly: Pac-Man = Maze, the space
shooter = Arena, Frogger = Lane, Bomberman & Breakout = Well/Fill. **Lunar
Lander is the Platform example you described** — read the terrain's top edges and
*add landing pads where the shape makes sense*. **GTA is the Region example** —
city blocks from the contours of the source image.

---

## 4. The secondary per-game controls (your explicit ask)

A shared, controller-navigable **Tab menu** every cartridge opens, backed by the
existing `level_adjustments.json` persistence (per-game, per-level, never
mutates `semantic_map.png`). The controls call a shared library of **map-fit
ops** that run *in memory* at game start:

| Op | What it does | Your words |
|---|---|---|
| **Fill / Invert** | swap solid↔open; fill enclosed shapes or leave them blank | "blocking and inversion… fill shapes or leave them blank" |
| **Block region** | mask off / block an area of the map | "some blocking… options" |
| **Bounds clamp** | keep all gameplay inside the projection boundary | "define the bounds so projection stays in the given area" |
| **Grid scale** | coarser/finer cells (Pac-Man has it) | per-game level fit |
| **Wall width** | thicken/thin solids — dilate/erode (Pac-Man has it) | per-game level fit |
| **Density** | how many pickups/enemies/bricks seed from the map | per-game level fit |
| **Smooth / close** | clean rough auto-derived maps (fill pinholes) | "final adjustments" |
| **Reference opacity** | show/hide the photo underlay (Pac-Man has it) | authoring aid |

A cartridge exposes only the ops that matter to it (a racer shows grip/speed/
checkpoints; a platformer shows jump/platform-snap). Some ops stay sliders;
others get baked to constrained ranges once a game feels right. **This is the
"deeper manipulation of the color map per game" you described — implemented as
reusable ops, not 33 one-off hacks.**

---

## 5. The editor overhaul — Design screen in the hub (decided)

The level editor moves **into the Godot hub as a "Design" screen** (its planned
Phase-2 destination), styled to the design system (black base, thin white
structure, cyan-led neon).

**Input model — controller-first, Pi-bound (your constraint):**
- Built on the hub's existing action-based input layer (SDL3, device-agnostic,
  1–4 players) — so it speaks the same language as the games.
- **Full controller navigation:** joystick/D-pad moves a paint cursor; **A** =
  paint, **B** = erase, bumpers/triggers = brush size, **D-pad** = cycle
  semantic class/brush, **Start** = open the tool menu, **Select** = toggle
  reference photo. Mirrors the console-paint grammar (think Mario Maker on a
  pad) and reuses Pac-Man's existing controller-menu interaction code.
- **Mouse + keyboard stay in** as a parallel path (precise authoring at a desk).
- **Designed to run on a Raspberry Pi later:** keep the UI controller-complete
  and the heavy photo→map auto-derive in a **swappable Python/OpenCV backend**
  the hub calls (OpenCV runs on Pi). *Pi performance tuning is deferred* — design
  for it now (cheap), optimize for it in Phase 3 (don't tax this build).

**Live preview (the killer feature):** the Design screen runs the *same* shared
adapters the games use, so as you paint/derive you can flip through "how would
Pac-Man / Tetris / Frogger fill this?" in place. This validates the whole
"every game off one map" thesis *at authoring time* and makes level-building the
fun ritual it's meant to be.

**Output contract is unchanged:** the editor still writes a clean
`semantic_map.png` + `level.yaml` and triggers the compile-all-derived step.
Games read the neutral map; per-game tweaks live in `level_adjustments.json`.

---

## 6. Parallel execution model (collision-free by construction)

The reason this fans out safely: **each cartridge is its own folder**, and the
shared foundations are built *first* and *frozen* before any cartridge agent
reads them. No two agents ever write the same tree.

### Lanes (from INTEGRATION_CONTRACT §1)

| Lane | Owns (writes) | Default fleet |
|---|---|---|
| `tools` | `app/tools/**` (compiler, derive, editor CV backend) | Codex |
| `hub` | `app/hub/**` (Design screen, input, live preview) | Antigravity |
| `shared` | `app/shared/**` + `vault/**` (adapters, controls toolkit, QA) | Sonnet/Opus |
| `cartridge` | `content/cartridges/<game>/**` — **one game per agent** | any |

### Waves (dependency order — the Base enforces this via `status`)

- **Wave 0 — Foundations (gate everything).** `tools`, `hub`, `shared` run in
  parallel (disjoint trees). `shared` is the critical path: the adapter library
  + controls toolkit must finish and freeze before any cartridge starts.
  - `TASK-INT-00` compile-all-derived (tools)
  - `TASK-INT-01` interpretation/adapter library (shared) ← critical path
  - `TASK-INT-02` controls toolkit + Tab shell (shared)
  - `TASK-INT-03` editor Design-screen scaffold + live preview (hub)
  - `TASK-INT-04` editor controller+mouse input model (hub)
- **Wave 1 — Archetype references (7, parallel).** One agent per reference game
  (pacman/tetris/galaga/frogger/on_track/donkey_kong/gta), each proving its
  adapter end-to-end. Disjoint folders → 7 agents at once.
- **Wave 2 — Wide rollout (~25, massively parallel).** One ticket per remaining
  cartridge, each depending on its archetype reference. As many agents as you
  have, each owning a single `content/cartridges/<game>/` folder.
- **Wave 3 — Per-game final tweak.** The polish pass you flagged for *after*
  breadth. Generated per game once its Wave-2 ticket closes (same script,
  `--wave 3`).

### The loop every agent runs (unchanged from the roadmap)

1. Open the Base → **Ready now** → pick the top ticket in a **lane nobody owns**.
2. Claim: set `owner_agent` + `status: in_progress`; drop a note in
   `vault/35-locks/` named for the `locks_required` value.
3. Build **only inside `touches`**. Read `app/shared/**` and the map read-only.
4. **Verify by real output** — screenshot the game on the demo-wall map *and* its
   classic level; confirm it reads the map + the Tab menu works + it never boots
   empty. "Code written" is not done.
5. Close: `status: done`, write a `vault/40-agent-runs/` log + `vault/70-qa/`
   note, release the lock. Flip newly-unblocked tickets to `ready`. → next.

On blocked/undecided: `status: blocked`, log it in
`vault/40-agent-runs/OPEN_QUESTIONS.md`, pull the next ticket. Never wait.

---

## 7. Sequencing rationale (breadth-first, fix-forward)

Your call stands: **get every game reading the designer + controls first, then
final-tweak.** So Wave 2 = breadth (all games to "gamelike + tunable"), Wave 3 =
depth. The fix-forward investment is Wave 0: spending real effort on the shared
library and the compile-all step *pays back 32 times* and is what makes the wide
rollout mechanical instead of heroic. Picking the easy path now (bespoke per
game) would be slower to a finished product, which is exactly the trap you named.

---

## 8. Risks & mitigations

| Risk | Mitigation |
|---|---|
| A game looks broken on a hostile map | Every adapter has a procedural fallback seeded by bounds — never boot empty |
| Two agents collide | One cartridge = one folder = one lock; foundations frozen before fan-out |
| Adapter library churns after games depend on it | Freeze `app/shared/**` adapters at end of Wave 0; changes go through Opus like schemas |
| Over-engineering for the Pi now | Design controller-complete + swappable CV backend (cheap); defer Pi perf to Phase 3 |
| "Universal grid" decision relitigated | Settled: **grid is the primary substrate, navgraph is fallback** (Pac-Man proves it; ratified in arena-pipeline v1.1) |
| Editor scope creep | Editor's job is unchanged: clean `semantic_map.png` + derived. Live preview reuses game adapters — no new interpretation code in the hub |

---

## 9. Parked for Kons/Opus (see OPEN_QUESTIONS.md)

- Confirm the 7-family archetype assignments (esp. marble_madness→Maze,
  pong→Well, joust/tempest→Arena, bubble_bobble→Platform).
- How deep should the editor live-preview go in Wave 0 (all 7 archetypes vs. the
  4 reference families first)?
- Wave 3 polish ordering — which games are likeliest to become "venue hits" and
  deserve first tweak?

---

*Tickets: `vault/30-tasks/TASK-INT-*.md` · Board: `vault/60-bases/interpretation.base`
· Loop & guardrails: `ROADMAP_autonomous_buildout.md` · Ownership: `INTEGRATION_CONTRACT.md`*
