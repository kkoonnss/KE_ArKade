# KE_ArKade — Master Plan

**One line:** Turn any physical space into an interactive arena. Build the
**arena abstraction layer** first; games are interchangeable cartridges that
read it. Orchestrated by Opus; built by three agent fleets.

**Status:** schema frozen, scaffold built, briefs ready to dispatch (2026-06-19).

---

## 1. The thesis (and why it's right)

Most people build projector-first: projector → keystone → game. That couples
every game to one room. KE_ArKade inverts it:

```
Physical space → Arena definition → Semantic layers → Game interpretation → Projection
```

Author the *meaning* of a space once (a painted/drawn semantic map), and any
game reads it. One calibration supports a library of games; one game runs in
any calibrated arena. The platform — not any single game — is the IP.

## 2. Decisions locked this session (the holes we closed first)

These were poked before any build started, so the swarm builds the right thing:

1. **MVP scope corrected + games chosen.** "One game reads a map" proves
   nothing. MVP = **two structurally different games off the same untouched
   map**: **Lumen Maze** (Pac-Man-like, reads `path` as a nav graph) and **Neon
   Stack** (Tetris-like, reads `solid` as a falling-block well). Racing
   (**Trace**, single-line vector track from a traced image) is Phase 2. Awkward
   auto-derived maps are acceptable and fun — level design is part of the play.
2. **Input model:** controllers main; keyboard for dev/test (ships day 1); input
   layer designed for **up to 4 local players**; body-tracking is Phase-2 noted-
   only (controllers prototype well in small spaces; trackers/large-space art-
   installation feel comes later). Standout post-MVP twist: **4-player Neon Stack
   on one mapped canvas.**
3. **Wall-first; orientation is first-class.** Start on the **wall** — easiest to
   test (vertical screens + a wall + a projector). Orientation = physical plane
   (wall/floor/table); gravity is a per-cartridge trait. Floor/tracker rules are
   a deliberate later, per-game concern and must NOT tax the MVP.
4. **Cartridges run as separate processes; hub is a launcher.** A crashing game
   can't kill the operator UI — required for unattended public installs.
5. **Palette reconciled & frozen.** The two source docs contradicted each other
   on classes 8/9 and colors; resolved into `semantic-palette-v1` (with split
   authoring-color vs. ui-color). See `vault/50-schemas/`.
6. **Pi 5 = Phase-2 hypothesis to kill early**, not a day-1 constraint. MVP is
   Profile L (laptop) only, so Pi budgets don't tax the proof.
7. **Git + disjoint folders are the real lock**, not advisory markdown locks.
   See `INTEGRATION_CONTRACT.md`.

## 3. Resources & fleet lanes ("lane by layer")

| Lane | Fleet | Owns | Deliverable |
|---|---|---|---|
| Compiler & CV | **Codex** (Python/OpenCV) | `app/tools/**` | arena compiler + derived layers + 4-point calibration, headless + tested |
| Hub & runtime | **Antigravity** (Godot, agent-IDE w/ live preview) | `app/hub/**` | kiosk UI, launcher, IPC, input layer, Panic Black |
| Contracts & glue | **Cowork/Sonnet** (under Opus) | `vault/**`, `app/shared/**`, `content/**` seeds | schemas, `app/shared` codegen, QA goldens, docs, integration |

Opus is the orchestrator: owns the frozen schemas, regenerates `app/shared/`,
merges integration, arbitrates the seams. Fleets move fast *inside* their lane
and escalate *at* the seams. Full rules: `INTEGRATION_CONTRACT.md`.

## 4. Folder structure (built)

```
KE_ArKade/
  CONTEXT.md                 # brain floor plan
  _Briefs/                   # this plan + per-lane briefs + integration contract
  app/
    hub/                     # Antigravity (Godot)
    tools/arena_compiler/    # Codex
    tools/calibration/       # Codex
    shared/                  # codegen from schemas (Opus); read-only to fleets
  content/
    scenes/                  # runtime venue data (compiler writes maps/derived)
    cartridges/              # game packages (separate-process)
  vault/                     # Obsidian orchestration (source of truth for planning)
    10-research 20-architecture 30-tasks 35-locks
    40-agent-runs 50-schemas 60-bases 70-qa 80-builds
  Notes/ChatGPT/             # original source research (kept)
```

## 5. Phased roadmap

**Phase 0 — Freeze (DONE).** Schemas, palette, orientation, IPC contract,
ownership map. Nothing else starts until this is frozen — and it is.

**Phase 1 — MVP (the honest test), wall + Profile L.** In parallel across lanes:
- Codex: arena compiler (paint→map), `navgraph` + `container` + `occupancy`
  generators, the **level-authoring tool** (slider + paint-over-photo modes),
  manual 4-point calibration. Headless core, golden-tested.
- Antigravity: hub shell (scenes gallery, level swiper, launch, Panic Black,
  controller test), separate-process launcher + IPC, keyboard→Xbox→SNES input,
  **plus the two MVP cartridges** Lumen Maze + Neon Stack (Godot).
- Sonnet/Opus: `app/shared` codegen, schema validators, golden-image QA, the
  **design brief** upkeep, one seed **wall** scene + one shared painted level.
- Integration target: **Lumen Maze + Neon Stack on one untouched map, on a wall.**

**Phase 2 — Make it fun + recall.** More cartridges, ChArUco camera
recalibration wizard, 4-player content (incl. the 4p-Tetris twist), level
authoring polish.

**Phase 3 — Portability & scale.** Kill-or-confirm Pi 5 (Profile P), multi-
projector R&D, structured-light calibration if justified.

## 6. Success criteria (MVP)

| Metric | Target |
|---|---|
| First-time venue setup | < 15 min |
| Returning to saved scene | < 2 min |
| Level swap (same scene) | < 10 s |
| Launch a cartridge | < 5 s after selection |
| Frame rate (Profile L) | stable 60 fps |
| **Abstraction proof** | **2 dissimilar games, 1 untouched map** |

## 7. Top risks & mitigations

| Risk | Mitigation |
|---|---|
| Building a projection-mapping editor instead of an arena OS | MVP is defined as 2 games on 1 map; the map/abstraction is the deliverable |
| Three swarms colliding | Disjoint folder ownership + git + schema-only-Opus; `INTEGRATION_CONTRACT.md` |
| Palette can't span genres | Orientation is first-class; adapters scoped to floor/wall/table |
| Cartridge crashes kill the show | Separate-process launcher + heartbeat + Panic Black + last-known-good |
| Pi constraints over-engineer the MVP | Pi deferred to Phase 3; MVP is Profile L only |
| IP exposure | Homage mechanics only; original names/art/branding (e.g. "Lumen Maze") |

## 8. Next action / live directive

The current authoritative directive is **`_Briefs/ROADMAP_autonomous_buildout.md`** —
a self-contained charter the executing fleet runs *and self-orchestrates* from
(grabs its own tickets via `vault/30-tasks/`, verifies by real output, parks
decisions in `OPEN_QUESTIONS.md`). It carries the full ordered backlog (Stage 0
visual lock → playable MVP games → hub completeness → content depth → the 3 stubs
→ QA/polish). Addenda 01–04 are done. Opus stays in orchestrator/verify mode and
reviews `BUILD_REPORT.md` on return. Earlier briefs (`EXECUTE_MVP`, `01/02/03`,
addenda) remain as detailed specs the roadmap references.
