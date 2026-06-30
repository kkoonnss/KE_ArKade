# BRIEF — Godot Hub, Launcher & MVP Cartridges  →  ANTIGRAVITY fleet

**You own:** `app/hub/**` AND `content/cartridges/**` (Godot is one domain — the
hub and the two MVP games are all Godot). Engine: Godot 4.5+ (SDL3 input). Use
your live-preview verification to check the UI as you build. Read-only inputs:
`vault/**`, `app/shared/**`. Do not write outside your two trees.

**Read first, in order:** `_Briefs/00_MASTER_PLAN.md` →
`_Briefs/INTEGRATION_CONTRACT.md` → `vault/20-architecture/hub-architecture.md`,
`input-and-players.md`, `design-brief.md` →
`vault/50-schemas/cartridge-schema-v1.yaml`.

**MVP target:** **wall** scene, Profile L (laptop). Follow `design-brief.md` for
ALL visuals: black base, thin white lines on high contrast, poppy neon semantic
accents, large geometry, built to survive a night festival. The two games read
ONE untouched map two ways: Lumen Maze uses `navgraph`, Neon Stack uses
`container` (both produced by Codex's compiler).

---

## Core principle
The hub is a **launcher, not a host.** Cartridges run as **separate OS
processes**. You launch a game, hand it `--scene <dir> --level <dir> --ipc
<socket>`, monitor heartbeats, and kill it on crash / 3 missed beats / Panic
Black. Bonus: separate processes give each game its own log and let any game run
standalone for debugging — keep it that way; it's a feature, not overhead.

## Work package 1 — Hub & runtime (`app/hub/`)

### A. Kiosk shell
Navigation: `Scenes · Levels · Play · Calibrate · Devices · Service`. Hero object
= the **Arena View** (per design-brief). Saved-scenes gallery (scan
`content/scenes/`), level swiper, **Panic Black** (always reachable) +
**Last-Known-Good Restore**, Test Pattern (corner grid), Controller Test,
Display Test.

### B. Launcher + IPC — `app/hub/launcher/`
Start/stop cartridge processes; pass the launch-args contract. IPC: localhost
socket, NDJSON. hub→game `load/pause/resume/quit/blank`; game→hub
`ready/score/player_joined/error/heartbeat`. Kill + restore on 3 missed 1000 ms
heartbeats.

### C. Compatibility gate
Before offering a cartridge on a level, check cartridge `requires` (orientation
+ semantic_classes + derived_layers + players) vs. what the level provides.
Never show an unlaunchable combo. (MVP scene is `wall`; Neon Stack requires
`wall`, Lumen Maze accepts `wall`.)

### D. Input layer — `app/hub/input/`
Normalize via SDL3; map by **action**, not device. Sources: keyboard (first),
Xbox pad, SNES-clone pad. Assign devices to **player slots 1–4**. Live
controller-test screen.

### E. Content scanning + override
Scan `content/scenes/` and `content/cartridges/` on boot; support `override.cfg`.

## Work package 2 — the two MVP cartridges (`content/cartridges/`)

Build **after** the loopback cartridge proves IPC + kill paths. Both are
separate-process Godot games honoring the IPC + cartridge schema. Original
names, homage mechanics — NOT trademarked IP.

- **`pacman` — "Lumen Maze"** (Pac-Man-like): read `navgraph` from the level;
  spawn from `spawn`, scatter `pickup`s, win on `goal`. Gravity-agnostic.
- **`tetris` — "Neon Stack"** (Tetris-like): read `container` from the
  level as the well boundary (may be non-rectangular); pieces fall toward
  wall-down. Design the input/board for up to 4 players (MVP can demo 1–2; the
  standout target is 4-player on one mapped canvas).

Both must run off the **same untouched `semantic_map.png`**. Awkward fits are OK.
Each may expose its own visibility options (zone tints / grid on or off).

## Acceptance criteria
- Hub boots to a scenes gallery from `content/scenes/`; design-brief look honored.
- Launching a level + cartridge starts a **separate process**; a simulated crash
  / heartbeat timeout returns cleanly to the UI; Panic Black blanks instantly.
- Keyboard playable first; Xbox + SNES-clone enumerated and slot-assigned (1–4).
- **Lumen Maze AND Neon Stack both launch and play off one untouched wall map.**
- Stable 60 fps on Profile L.

## Do NOT
- Do not run cartridges in-process — separate process is locked.
- Do not run computer vision or author maps (that's Codex).
- Do not invent new IPC messages — request a schema bump via a task note.
- Do not edit schemas or `app/shared/`; do not write outside your two trees.

## Deliverables
`app/hub/` Godot project (shell, launcher, IPC, input, compatibility gate) + a
loopback stub cartridge; then `content/cartridges/pacman` +
`content/cartridges/tetris`. QA note in `vault/70-qa/`, run log in
`vault/40-agent-runs/`.
