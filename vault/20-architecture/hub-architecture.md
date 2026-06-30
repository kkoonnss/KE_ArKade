# Hub Architecture

The **Hub** is the operator-facing application: a kiosk, not a game-engine
editor. It is the one thing that is always running at a venue. Engine: Godot
4.5+ (SDL3 input). Owner lane: **Antigravity**.

## Core principle: the hub is a launcher, not a host

Games (cartridges) run as **separate OS processes**. The hub launches a game,
hands it `--scene <dir> --level <dir> --ipc <socket>`, monitors a heartbeat,
and can kill it instantly. A game that hangs, leaks, or crashes can never take
down the operator UI. This is the deliberate trade vs. in-process `.pck`
loading: a little more plumbing, far more reliability for unattended installs.

```
[ HUB process ]  --launch-->  [ Cartridge process ]
      |  <--heartbeat / score / error-- (localhost socket, NDJSON)
      |  --load / pause / quit / blank-->
      |
   kills child + restores last-known-good on: crash, 3 missed heartbeats,
   or operator pressing Panic Black.
```

## Operator surfaces (kiosk navigation)

`Scenes · Levels · Play · Calibrate · Devices · Service`

The hero object is the **Arena View** (CAD-meets-console), never the projector.
Visual language is defined in `design-brief.md` — follow it: black base, thin
white lines on high contrast, poppy neon semantic accents, large geometry, very
low clutter, built to survive a night festival full of competing LEDs. Per-
cartridge visibility options (zone tints/grid/overlays on or off) are owned by
each game, not forced by the hub.

Required affordances, in priority order:
1. **Panic Black** — instantly blanks all projection output. Always reachable.
2. **Last-Known-Good Restore** — one click back to a verified scene.
3. Saved-scenes gallery (thumbnails) · level swiper within a scene.
4. Test Pattern (corner-to-corner grid) · Controller Test · Display Test.
5. Recalibrate (launches the calibration wizard — see arena-pipeline).

## Runtime responsibilities

- Scan `content/scenes/` and `content/cartridges/` on boot; build the gallery.
- **Compatibility gate:** before offering a cartridge on a level, check the
  cartridge `requires` (orientation + semantic_classes + derived_layers +
  players) against what the level provides. Never show an unlaunchable combo.
- Own the input layer (see `input-and-players.md`): enumerate keyboard +
  controllers, assign player slots, expose a live controller-test screen.
- Persist settings/scene selection; site overrides via `override.cfg`.

## What the hub does NOT do

- It does not run computer vision (that's the compiler/calibration tool).
- It does not contain game logic (that's cartridges).
- It does not author semantic maps (that's the arena compiler).

## Separate-process = a debugging WIN, not a tax

Crash isolation also makes the backend easier to troubleshoot: each cartridge
gets its own log, and any cartridge can be launched standalone (outside the hub)
for isolated debugging. The hub staying live regardless of which game loads in/out
is the goal; the process boundary is what delivers it cheaply.

## MVP cut

Profile L (laptop) only, **wall** projection. One projector, one display output.
Keyboard input first, then Xbox + SNES-clone controllers. Scenes gallery + level
swiper + launch + Panic Black + manual 4-point calibrate. Two cartridges (Lumen
Maze, Neon Stack) on one map. No camera, no Pi, no floor/tracking.
