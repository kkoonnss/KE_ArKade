# DISPATCH — Stage 6 kickoff prompts (Codex + Antigravity)

Claude/Opus stays the orchestrator (manages the Base, flips ticket status, merges,
generates Wave-3 tickets). Codex + Antigravity execute. Copy a block into a fresh
agent instance. Each block is self-contained.

## Who does what

| Instance | Fleet | Lane / tree (writes here only) | Tickets |
|---|---|---|---|
| Codex #1 | Codex (Python/OpenCV) | `app/tools/**` | TASK-INT-00 |
| Antigravity #1 | Antigravity (Godot) | `app/shared/**` | TASK-INT-01 → TASK-INT-02 |
| Antigravity #2 | Antigravity (Godot) | `app/hub/**` | TASK-INT-03 → TASK-INT-04 |
| (after foundations) Codex #2..n + Antigravity #3..n | either | one `content/cartridges/<game>/` each | TASK-INT-cart-* |

Three disjoint trees in Wave 0 → run all three at once, zero collisions. The 32
cartridge tickets unlock after the foundations and split across as many Codex +
Antigravity instances as you want (one game per instance).

Repo root (all prompts assume this):
```
C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade
```

---

## Codex #1 — Compiler / tools (start now)

```
You are an autonomous build agent on the KE_ArKade project.
Repo root: C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade

Read these first, in order:
1. _Briefs/PLAN_interpretation-and-editor.md   (Stage 6 directive + strategy)
2. _Briefs/INTEGRATION_CONTRACT.md             (folder ownership — the collision rule)
3. vault/30-tasks/TASK-INT-00-compile-all-derived.md   (your ticket: objective + acceptance)
Skim: vault/20-architecture/arena-pipeline.md and vault/50-schemas/semantic-palette-v1.yaml (FROZEN — never edit).

Your job: TASK-INT-00 — build ONE headless, golden-tested "compile-all-derived"
entry point that regenerates the full derived set (navgraph, container, grid,
occupancy, platform_edges, track_centerline, authoring_profile) for a level in a
single call, then batch-run it across every level in content/scenes/** so they
all have a complete derived/ set (today ~26 levels lack grid/container and
classic_gta has none). Extract the derive-orchestration currently inlined in
app/tools/level_authoring/author.py into this reusable callable. Keep it plain
OpenCV/numpy so the hub can shell out to it later (incl. on a Raspberry Pi).

Rules:
- Write ONLY inside app/tools/**. Everything else is read-only. Never edit frozen schemas.
- Claim it: in the ticket frontmatter set owner_agent + status: in_progress; drop a
  note in vault/35-locks/tools-compiler.md.
- Verify by REAL output: run it, confirm every level gets a full derived/ set,
  golden tests green from a clean checkout. "Code written" is not done.
- Close: status: done, write a run log in vault/40-agent-runs/ + a QA note in
  vault/70-qa/, release the lock.
- If blocked or a frozen contract is in the way, log it in
  vault/40-agent-runs/OPEN_QUESTIONS.md and stop — don't guess.
```

---

## Antigravity #1 — Shared adapter library + controls toolkit (start now)

```
You are an autonomous build agent on the KE_ArKade project (Godot 4 / GDScript).
Repo root: C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade

Read these first, in order:
1. _Briefs/PLAN_interpretation-and-editor.md   (Stage 6 directive — esp. §3 archetypes, §4 controls)
2. _Briefs/INTEGRATION_CONTRACT.md             (folder ownership — the collision rule)
3. vault/30-tasks/TASK-INT-01-adapter-library.md   (your FIRST ticket)
4. vault/30-tasks/TASK-INT-02-controls-toolkit.md  (your SECOND ticket — after #1)
Reference the working pattern: content/cartridges/pacman/main.gd (the proven map→game loop).
Skim: vault/50-schemas/semantic-palette-v1.yaml (FROZEN — never edit).

Your job: build the shared interpretation library in app/shared/ — 7 archetype
adapters (maze, well_fill, arena, lane, track, platform, region), extracting the
MAZE adapter from pacman's grid→graph logic. Each adapter takes the level +
derived layers + knobs and returns a normalized play layout, and EACH must have a
procedural fallback so a game never boots to an empty level. THEN (TASK-INT-02)
build the shared map-fit ops (fill/invert, block_region, bounds_clamp, grid_scale,
wall_width, density, smooth, reference_opacity) and one controller-navigable Tab
menu shell every cartridge can dress with its own knobs, persisting via the
existing level_adjustments pattern. Do INT-01 first, freeze it, then INT-02.

Rules:
- Write ONLY inside app/shared/**. Everything else read-only. Never edit frozen schemas.
- Claim each ticket: set owner_agent + status: in_progress; lock note in
  vault/35-locks/shared-adapters.md.
- This is the critical path — 32 cartridges depend on it. After both close, treat
  the adapter contracts as frozen (changes route through Opus).
- Verify by REAL output: a headless harness runs each adapter on the demo_wall map
  AND a classic level and prints a non-empty layout for all 7; pacman re-pointed at
  the shared shell reproduces its current controls.
- Close each: status: done, run log in vault/40-agent-runs/ + QA note in
  vault/70-qa/, release the lock. Log any blockers in
  vault/40-agent-runs/OPEN_QUESTIONS.md and stop rather than guess.
```

---

## Antigravity #2 — Editor "Design screen" in the hub (start now)

```
You are an autonomous build agent on the KE_ArKade project (Godot 4 / GDScript).
Repo root: C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade

Read these first, in order:
1. _Briefs/PLAN_interpretation-and-editor.md   (Stage 6 directive — esp. §5 editor)
2. _Briefs/INTEGRATION_CONTRACT.md             (folder ownership + IPC contract)
3. vault/30-tasks/TASK-INT-03-editor-design-screen.md     (your FIRST ticket)
4. vault/30-tasks/TASK-INT-04-editor-controller-input.md  (your SECOND ticket — after #3)
Reference: vault/20-architecture/level-authoring.md, input-and-players.md;
the existing standalone tool app/tools/level_authoring/author.py (what to replace);
content/cartridges/pacman/main.gd (its controller-driven Tab menu = the interaction grammar to reuse).

Your job: rebuild the level editor as a "Design" screen INSIDE the hub
(app/hub/**), styled to the design system. Slider mode (photo→zones) + paint mode
(paint classes over a photo, opacity toggle) writing a clean semantic_map.png +
level.yaml; heavy photo→map auto-derive delegated to the Python backend (call
TASK-INT-00's compile step — do NOT reimplement CV in GDScript, keep it
Pi-portable); on save, trigger compile-all-derived. Add a LIVE PREVIEW that reuses
the shared archetype adapters (from app/shared, once TASK-INT-01 is frozen) to
show how each game fills the map. THEN (TASK-INT-04) make the whole screen fully
controller-operable (joystick cursor, A paint, B erase, bumpers brush size, D-pad
cycle class, Start tool menu, Select toggle photo) while keeping mouse+keyboard
fully in. Design for a Raspberry Pi later; do not optimize Pi perf now.

Rules:
- Write ONLY inside app/hub/**. Everything else read-only. Never edit frozen schemas.
- Claim each ticket: owner_agent + status: in_progress; lock note in
  vault/35-locks/hub-design.md. Do INT-03 then INT-04 (same tree, sequential).
- Verify by REAL output: author a fresh level end-to-end with ONLY a controller,
  then again with ONLY mouse/keyboard; launch two different cartridges on the new
  level unchanged. Sample the screenshot.
- Close each: status: done, run log + QA note, release lock. Log blockers in
  vault/40-agent-runs/OPEN_QUESTIONS.md and stop rather than guess.
```

---

## Cartridge wave (after the foundations close) — reusable template

When TASK-INT-01 + TASK-INT-02 are done, the 7 Wave-1 reference cartridges become
ready (pacman, tetris, galaga, frogger, on_track, donkey_kong, gta). Their family
members (Wave 2) unlock as each reference closes. Open
`vault/60-bases/interpretation.base` → **Ready now** view → hand each instance one
ticket whose `lane: cartridge` and folder nobody else holds. Paste this, filling
in <GAME>:

```
You are an autonomous build agent on the KE_ArKade project (Godot 4 / GDScript).
Repo root: C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade

Read in order:
1. _Briefs/PLAN_interpretation-and-editor.md   (Stage 6 — §3 archetypes, §4 controls, §6 loop)
2. _Briefs/INTEGRATION_CONTRACT.md
3. vault/30-tasks/TASK-INT-cart-<GAME>.md       (your ticket: archetype + acceptance + knobs)
4. app/shared/README.md                         (the adapter + controls contracts you consume)

Your job: bring content/cartridges/<GAME>/ onto its shared archetype adapter so it
builds its level from the painted map, and give it the shared secondary-controls
Tab menu with the knobs listed in the ticket. It must fall back to a procedural
layout inside the bounds if the map is sparse (never boot empty), keep IPC +
design system intact, and stay controller+keyboard playable.

Rules:
- Write ONLY inside content/cartridges/<GAME>/. Read app/shared/**, the map, and
  schemas read-only — never edit them.
- Claim it: owner_agent + status: in_progress; lock note vault/35-locks/cart-<GAME>.md.
- Verify by REAL output: screenshot the game on BOTH the demo_wall authored map AND
  its classic level; confirm it reads the map, the Tab menu works, it never boots empty.
- INTEGRATION GATE (MUST): instantiate the shared <ARCHETYPE> adapter + TabMenu — copy
  the POST-INT-05 gta as the worked model. Load the adapter + TabMenu via SharedLoader
  (NOT global class_name — cartridges are separate Godot projects), and keep NO local
  adapter_base.gd. Before closing, grep -E "SharedLoader|TabMenu" content/cartridges/<GAME>/
  must be non-empty (no bespoke map/menu logic, no copied shared files).
- Close: status: done, run log + QA note, release lock. Blockers →
  vault/40-agent-runs/OPEN_QUESTIONS.md, then pull the next ready cartridge ticket.
```

Split guidance: Antigravity is the stronger Godot fit, so give it the reference
games + the trickier archetypes (platform, region, well_fill). Codex can take the
more self-contained arena/maze/lane games in parallel. One game per instance.
```
