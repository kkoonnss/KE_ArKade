# KE_ArKade — Integration Contract

**Audience:** all three agent fleets + the orchestrator (Opus).
**Purpose:** the seams. Read this before touching anything. If a change would
violate this contract, STOP and escalate to the orchestrator.

This document is how three independent agent swarms build one system without
overwriting each other. Markdown lock-files are advisory; the real safety is
**disjoint folder ownership + git + a frozen schema only the orchestrator edits.**

---

## 1. Work-packages & ownership (disjoint folders — do not cross)

**Agents are interchangeable.** The names below are *default* assignments by
current capacity and suitability — NOT fixed identities. Any capable agent (or
sub-agent) may execute any package; if one fleet is idle and others are low on
capacity/credits, that fleet takes the whole build. What is NOT negotiable is the
**folder ownership while a package is being worked**: whoever executes a package
owns those folders for the duration, and **no two concurrent agents write the same
tree.** A single fleet running the whole MVP MUST still partition its own
sub-agents along these exact boundaries so they don't collide.

| Work-package | Owns (writes here) | Default fleet |
|---|---|---|
| Compiler, CV, level-authoring tool | `app/tools/**` | Codex |
| Godot hub + launcher + the 2 cartridges | `app/hub/**`, `content/cartridges/**` | Antigravity |
| Schemas codegen, validators, QA, seed scenes | `vault/**`, `app/shared/**`, `content/scenes/**` | Sonnet |

Cartridges are separate-process games that READ a scene+level (seed + compiler
output) and the shared palette — they never write outside their own dir.

Rule: **no agent writes outside the tree of the package it currently holds.**
Cross-tree needs go through `app/shared/` (the contract surface) and the orchestrator.

## 2. The data contract (the only thing all fleets share)

The frozen schemas in `vault/50-schemas/` are the universal interface:
`semantic-palette-v1`, `scene-schema-v1`, `level-schema-v1`,
`cartridge-schema-v1`. **Only the orchestrator edits these.** A fleet that
needs a schema change opens a task note in `vault/30-tasks/` and waits; it does
not edit the schema to unblock itself. Schema changes are additive (v1.x) until
a hard break is unavoidable (v2).

`app/shared/` mirrors the schema as code-level constants/types (e.g. the palette
class IDs + colors as a generated header / GDScript const / Python module) so
both the hub and the compiler compile against the same numbers. The orchestrator
regenerates `app/shared/` from the YAML; fleets import it read-only.

## 3. The IPC contract (hub ↔ cartridge)

Transport: **localhost socket, newline-delimited JSON (NDJSON), v1.**

- hub → game: `load`, `pause`, `resume`, `quit`, `blank`
- game → hub: `ready`, `score`, `player_joined`, `error`, `heartbeat`
- Game emits `heartbeat` every 1000 ms. Hub force-kills after 3 missed beats
  and restores last-known-good. Game must exit cleanly on `quit`.
- Launch args the hub guarantees: `--scene <dir> --level <dir> --ipc <socket>`.

Antigravity implements the hub side; each cartridge implements the game side
against this exact contract. Neither invents new message types without a schema
bump from the orchestrator.

## 4. The filesystem contract (runtime data layout)

```
content/
  scenes/<scene_id>/
    scene.yaml
    calibration/current.yaml
    levels/<level_id>/
      level.yaml  semantic_map.png  derived/  overlays/  thumb.png
  cartridges/<cartridge_id>/
    manifest.yaml  + game binary/pck
```

The compiler WRITES `levels/<id>/semantic_map.png` + `derived/**`. The hub READS
scenes/levels/cartridges and LAUNCHES cartridges. A cartridge READS its
scene+level and WRITES only its own save dir. Nobody else touches `derived/**`.

## 5. Build & integration flow

1. Orchestrator freezes/updates `vault/50-schemas/**` and regenerates `app/shared/**`.
2. Fleets build inside their owned trees against `app/shared/`.
3. Integration happens on a shared git branch; the orchestrator merges. Conflicts
   are prevented by ownership, not resolved after the fact.
4. Every task ends with a QA note (`vault/70-qa/`) + an agent-run log
   (`vault/40-agent-runs/`).

## 6. Definition of "MVP done" (the honest test)

One verified **wall** scene + one painted level (authored via slider OR
paint-over-photo) + **two structurally different cartridges** that read the
**same untouched `semantic_map.png`**:
- **Lumen Maze** (Pac-Man-like) reads `path` as a nav graph.
- **Neon Stack** (Tetris-like) reads `solid` as the well/container boundary.

Both launched from the hub as separate processes, keyboard playable first then
Xbox + SNES-clone, Panic Black working, all on Profile L (laptop, wall
projection). Two games — not one — because one game proves nothing about arena
abstraction. Awkward map interpretations are acceptable and expected.

## 7. Escalation

Anything that would (a) edit a frozen schema, (b) write outside your tree,
(c) add an IPC message, or (d) change the MVP definition → STOP, write a task
note, ping the orchestrator. Forward momentum inside your lane; escalate at the seams.
