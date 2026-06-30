---
tags: [project, active, installation, games, reference]
type: project
status: in-progress
connections: [KE_VibeApps, Home, MASTER_PROFILE, PRIORITY_MAP]
---

# KE_ArKade — Claude Context

**What:** Arena abstraction platform — turn any physical space into an interactive projected arena.
**Thesis:** Author the *meaning* of a space once; many games read it as interchangeable cartridges.
**Role split:** Opus orchestrates · Kons = creative · three agent fleets build (Codex / Antigravity / Sonnet).

---

## What You're Doing Here

Building the **arena abstraction layer first**, not projector-first. A painted
semantic map is the canonical model; games interpret it. Scene (physical) /
Level (semantic) / Cartridge (logic) are kept strictly separate. The platform —
not any one game — is the product. MVP is the honest test: **two dissimilar
games running off one untouched map.**

---

## Naming Rule

- Visible game names stay clean and alphabetical, e.g. `Frogger`, `Pac-Man`, `Rampage`.
- `classic` is a skin / compatibility concept, not part of the public title.
- Use `Classic <game>` only when a skin label or internal pairing needs to identify the original-reference look.
- The pack itself is still the classic arcade set, just remixed for projection mapping with brighter contrast and future reskins.
- Library/catalog entries may use a leading numeric index for stable ordering, e.g. `01 Frogger`, `02 Pac-Man`, `03 Rampage`.
- Keep the slug / cartridge IDs clean underneath the catalog label so scripts, manifests, and routes stay predictable.
- Leave spacing room in the numbering scheme so new cartridges can be inserted later without breaking the whole list.
- Apply the same numbering idea to classic scene/level entries when helpful, so the level pack and cartridge library stay aligned.

## Key Files

- `_Briefs/PLAN_interpretation-and-editor.md` — **CURRENT STAGE 6 directive** (universal map interpretation + controller-driven Design screen). Tickets in `vault/30-tasks/TASK-INT-*`; board at `vault/60-bases/interpretation.base`.
- `_Briefs/00_MASTER_PLAN.md` — the whole plan, decisions, roadmap. Start here.
- `_Briefs/INTEGRATION_CONTRACT.md` — fleet ownership + seams. Read before touching code.
- `_Briefs/01/02/03_BRIEF_*.md` — per-fleet send-off briefs (Codex / Antigravity / Sonnet).
- `vault/50-schemas/` — FROZEN v1 schemas (palette, scene, level, cartridge). Source of truth.
- `vault/20-architecture/` — hub, arena-pipeline, input-and-players.
- `Notes/ChatGPT/` — original source research (kept, not authoritative over schemas).

---

## How To Work Here

- **Fleets own disjoint folders:** Codex=`app/tools`, Antigravity=`app/hub`, Sonnet=`vault`+`app/shared`.
- **Only Opus edits frozen schemas.** Need a change? Write a task note, escalate.
- **Cartridges = separate process; hub = launcher.** Crash isolation is non-negotiable.
- **Do not:** build a projection-mapping editor instead of an arena OS; let the MVP slip to one game; tax the MVP with Pi 5 constraints (Pi is Phase 3).

---

## Current Focus (June 2026)

**Stage 6 — Universal Level Interpretation + Editor overhaul.** All 33 cartridges
are playable; Pac-Man already proves the full loop (reads the painted map →
builds its level → per-game Tab controls). Now: build the shared 7-archetype
adapter library + secondary-controls toolkit once, rebuild the level editor as a
controller-first **Design screen in the hub** (Pi-bound), then fan out across all
games in parallel (one cartridge = one folder = collision-free). Directive:
`_Briefs/PLAN_interpretation-and-editor.md`. Board: `vault/60-bases/interpretation.base`.

---

*→ Full context: [[00_MASTER_PLAN]] · [[MASTER_PROFILE]] · [[PRIORITY_MAP]]*
