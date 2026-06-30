# Input & Players

Decision (locked 2026-06-19): **controllers are the main interaction model.**
Keyboard is the test/dev path and ships day 1. Body/positional tracking is a
**Phase 2 noted idea** only — designed-for, not built now.

## Design target: up to 4 local players

The input layer is abstracted so the game logic never asks "keyboard or pad?"
It asks "what did Player N do this frame?" Sources are pluggable:

```
[ keyboard ] [ xbox pad ] [ snes-clone pad ] ...future: [ body tracker ]
        \         |             /                        /
         \        |            /                        /
            Input Layer  (normalizes -> Player 1..4 action streams)
                         |
                    Cartridge reads PlayerInput[N]
```

- Normalize at the engine level via Godot 4.5+ **SDL3**. Avoid controller-
  specific gameplay assumptions; map by action, not by device.
- Hardware on hand: Xbox controller, SNES-clone controller. Both XInput/SDL.
- Player slots 1–4. A cartridge declares `requires.players: {min, max}`; the
  hub assigns connected devices to slots and shows a live controller-test screen.

## MVP vs. ambition

- **MVP:** 1–2 players is fine for demoing. Keyboard first, then get Xbox +
  SNES-clone working fast.
- **Standout twist (post-MVP):** **4-player Tetris on one mapped canvas** — the
  kind of "wait, four people on one projected arena?" moment that makes the
  platform memorable. The input layer is built for this from day 1 so it's a
  content problem later, not an architecture problem.

## Future: positional / body tracking (Phase 2, noted only)

When it arrives, a body tracker becomes just another input source feeding the
same `PlayerInput[N]` slots — except its "action" is a position in arena space.
That requires closing the physical→camera→arena loop (the `tracking` palette
class, ID 8, is already reserved for exactly this). Nothing in the MVP design
blocks it; nothing in the MVP build implements it.
