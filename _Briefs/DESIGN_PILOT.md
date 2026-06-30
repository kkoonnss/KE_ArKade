# DESIGN PILOT — Lock the visual language on 2 games + the hub

**Goal:** stop guessing the look. Push the visual direction hard on a small,
representative slice — the **hub shell** + the **two MVP games** (Lumen Maze,
Neon Stack) — and turn the result into a **locked design-system** that every
other game and screen inherits. Do this *now*, loosely, before the other three
games get skinned.

**Where to run it:** **Claude Design** (your separate credits — fast visual
iteration, Figma). This is the right tool: it's for static comps, style frames,
and a token system, not real-time engine work. The games themselves stay in
Godot; this pilot produces the *spec and reference frames* that Godot implements.

## Why these two games
Lumen Maze (paths/corridors) and Neon Stack (a bounded falling-block well) are
visually opposite — a line-and-node world vs. a filled-cell world. A system that
makes BOTH look intentional will generalize to Frogger/Trace/Bomberman with
little rework. They're also the most built-out, so the design lands on something real.

## Inputs (start from these)
- `vault/20-architecture/design-brief.md` — the written direction (black base,
  thin white lines, poppy neon, festival contrast, Nintendo × Blackmagic).
- The semantic palette `ui_color`s (cyan/orange/green/magenta/yellow/white/gray) —
  these are load-bearing: every game inherits them, so design *with* them.
- Projection reality: pure black = "off", boost contrast, saturated neon survives
  ambient festival LEDs, thin bright lines read; avoid mid-tones/gradients/small text.

## What to produce (the deliverables that come back into the repo)
1. **A locked design-system** → `vault/20-architecture/design-system.md`:
   color tokens (hex + role), type scale, line weights, spacing/grid, corner/edge
   language, motion language (how things appear/blank), and **how each semantic
   class renders** (incl. a tile/cell treatment for gridified games).
2. **Reference frames (PNG exports)** → a new `design/frames/` folder: the hub
   gallery, the arena view, a launch state, Panic Black; plus a look-frame for
   Lumen Maze and one for Neon Stack.
3. Any tightening of `design-brief.md` if the direction shifts during iteration.

## Suggested loop (in Claude Design)
Generate comps from the brief → critique + iterate (use the design-critique /
design-system passes) → when you like it, export tokens + frames → drop them in
the repo at the paths above.

## How it feeds the build (handoff to Antigravity)
Once `design-system.md` + frames land, Antigravity skins the Godot hub and the
two games to match. **Sequencing:** the hub can be skinned right away; the game
re-skin happens *after gridification* (Addendum 01), because gridified tiles/cells
are the unit the visual system styles — doing it before would mean redoing it.

## Scope guard
This is a *direction-locking* pilot, not a full UI build. Two games + the core
hub screens is enough to decide the language. Resist styling all five games here —
that's downstream, against the locked system.
