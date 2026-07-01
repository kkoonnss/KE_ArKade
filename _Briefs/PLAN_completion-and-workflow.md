---
doc_id: plan-completion-and-workflow
audience: [kons, orchestrators, codex, antigravity, sonnet]
authority: directive
last_revised: 2026-06-30
author: opus_orchestrator
origin: Kons direction 2026-06-30 — "fix the hub, get the games solid and tested,
  the 6 favorites are the templated workflows, reuse them to build the rest.
  Opus sets direction + does final big QC; mid/low-tier agents run the work."
relation: sequences execution on top of PLAN_interpretation-and-editor.md (the WHAT).
  This doc is the ORDER, the OPERATING MODEL, and the OPUS-QC checkpoints.
---

# Completion Directive + Agent-Tier Workflow

**One line:** Fix the hub into a solid spine, make the 6 template games truly
gate-clean and tested, then clone each template across its family in parallel
with mid/low-tier agents — Opus only sets direction and runs the big QC gates.

This is the map for finishing KE_ArKade with the least Opus involvement.

---

## 1. The operating model (who does what)

The whole point: **Kons runs the build with mid/low-tier agents and comes back
to Opus rarely — only at the QC gates that decide whether to fan out.**

| Tier | Who | Job | Touch frequency |
|---|---|---|---|
| **Direction** | Opus 4.8 (this chair) | Set sequence, write the contracts/tickets, run the *big* QC gates, decide fan-out go/no-go, resolve escalations. Never writes game code. | Rare — at phase boundaries + the gates in §4 |
| **Build** | Antigravity (Godot), Codex (Python) | Fix the hub, solidify the templates, run the fan-out. Self-verify each ticket against its lane gate. | Continuous — the workhorses |
| **QC** | Sonnet 4.6 sub-agents | Cold grep-gate re-runs, cross-cart drift checks, receipt reconstruction. Spawned by the orchestrator, one per pass. | Every 3+ returns + weekly |
| **Grunt checks** | Haiku 4.5 | Dead-simple existence/count greps where no reasoning is needed. | As needed, cheap |

**The loop Kons runs without Opus:** dispatch a batch to Antigravity/Codex →
they build + self-verify + write receipts → Kons spot-launches → Sonnet QC
cold-checks the batch → only if QC finds drift, or a phase boundary is reached,
does it come back to Opus. Everything inside a phase is mid/low-tier.

**When Opus is invoked (the only times):**
1. A phase gate (§4) — go/no-go on advancing.
2. An escalation (frozen schema, contract change, MVP redefinition, new
   forbidden pattern).
3. Final pre-ship QC.

Everything else is delegated. If Opus finds itself doing line-edits, the
workflow has slipped.

---

## 2. The sequence (four phases, in Kons's stated order)

### Phase A — Fix the hub (the spine) — **do first**

The hub is the launcher every game runs through; it has to be solid before
anything fans out. Outstanding hub work, all `app/hub/**`, Antigravity lane,
one instance (shared `hub-design` lock, sequential):

- **INT-08** design-save → compile derived. Real bug: `_on_dir_selected()`
  prints success unconditionally even when the Python compile produces no
  `derived/`. Fix = check exit code + confirm `derived/grid.json` before
  claiming success; robust `python`/`py -3`/`python3` fallback.
- **INT-09** preset dropdown (Balanced Semantic / Open Flow / Vertical
  Surfaces), read from `author_backend.py` so it stays in sync. Depends on
  INT-08; same instance, same file.
- **scene-ordering** classic pack first, custom scenes after. ~5-line sort.
- **layout polish** (the minor thumbnails/favorites cosmetic Kons flagged) —
  fold in here or defer to Phase D; not blocking.

**Gate A (Opus + Kons):** Kons saves a level in Design → `derived/grid.json`
appears → launches a game on it and it reads the map. Hub boots clean, tabs
switch, classic-first ordering holds. → advance to Phase B.

### Phase B — Solidify the 6 templates (make each family's reference perfect)

The 6 templates get cloned ~22 times. A flaw in a template becomes 22 flaws.
So each template must be **truly gate-clean and Kons-tested before it seeds its
family.** Today several are NOT clean:

- pacman, tetris, donkey_kong — marked done but **predate SharedLoader**
  (INT-05); they read maps bespoke-style.
- galaga, frogger, on_track — carry a **local `adapter_base.gd` copy** instead
  of `SharedLoader`.
- gta — the SharedLoader canonical model; already clean.

**Phase B work = the SharedLoader retrofit + full test pass on the 6 templates
FIRST** (not deferred to Wave 3). Each template must pass the cartridge gate
(`02_VERIFICATION_GATES.md` §2): SharedLoader present, no `class_name` reach,
no local `adapter_base.gd`, launches clean, Kons-confirmed reading the map +
Tab menu working on both the demo-wall map and its classic level.

**Gate B (Opus — the big one):** Spawn a Sonnet QC sub-agent to cold-run the
cartridge gate on all 6 templates. Kons launch-confirms all 6. Opus reviews
the QC report and signs off. **This is the fan-out authorization gate — the
single most important checkpoint in the project.** Do not clone a template
that hasn't cleared it.

### Phase C — Fan-out (clone each template across its family, massively parallel)

Once a template clears Gate B, its family is unblocked. Each remaining game is
a thin clone of its template's workflow (same adapter, same Tab shell, per-game
knobs). One game = one folder = one lock = one agent; up to 6 in parallel.
Mid-tier agents (Antigravity + Codex) own this entirely.

**Gate C (Sonnet QC, not Opus):** after every batch of 3+ returns, one Sonnet
sub-agent cold-re-runs the cartridge gate across the batch + a drift check
against the template. Failures → `pending_kons_verify`. Only *drift from the
template pattern* escalates to Opus.

### Phase D — Polish + final QC (Wave 3)

Per-game tuning (density, wall width, knob defaults), venue-hit candidates
first (Pac-Man, Bomberman, 4p Tetris, Frogger). Then the final pre-ship Opus QC
gate across the whole roster.

---

## 3. The 6 templates and their families

Each template's workflow is the clone source for its family. Fan-out of a
family cannot start until its template clears **Gate B**.

| Template (archetype) | Reads | Family (fan-out targets) |
|---|---|---|
| **pacman** (Maze/Graph) | grid → node graph, corridors, pickups | snake, tron, gauntlet, dig_dug, marble_madness, qbert |
| **tetris** (Well/Fill) | solid + container → fill the shape | breakout, bomberman, centipede, pong |
| **galaga** (Open Arena) | container = playfield edge; solids = cover; waves inside | space_invaders, robotron_2084, smash_tv, defender, missile_command, battlezone, joust, tempest, tapper* |
| **frogger** (Lane/Flow) | grid rows → lanes; spawn→goal crossing | paperboy, tapper* |
| **donkey_kong** (Platform/Gravity) | platform_top + procedural platforms; gravity | lunar_lander, burger_time, bubble_bobble |
| **gta** (Region/Block) | solid contours → blocks/buildings | rampage |

*tapper's archetype is a Lane/Flow-vs-Arena judgment call (see
OPEN_QUESTIONS). Assign it to whichever template it clones most cleanly at
fan-out; not load-bearing.

**on_track** (Track archetype) stands alone — no family to seed — so it is not
a template. It just needs its own SharedLoader retrofit + test in Phase B/D.

Family membership above is the interpretation-PLAN taxonomy. If Kons's mental
"6 favorites" differ from pacman/tetris/galaga/frogger/donkey_kong/gta, that's
a one-line correction — the structure holds regardless of which 6.

---

## 4. The Opus-QC checkpoints (the only times Kons comes back to me)

1. **Gate A** — hub is solid. Quick sign-off.
2. **Gate B** — the 6 templates are all gate-clean + Kons-tested. **The big
   one.** Authorizes the entire fan-out. Sonnet QC report + Opus review.
3. **Gate C** — per fan-out batch, Sonnet QC handles it; Opus only sees
   template-drift escalations.
4. **Gate D / final** — whole-roster pre-ship QC before calling it done.

Between gates, Kons runs mid/low-tier agents freely. The gates are where
direction is re-set — nowhere else.

---

## 5. What's ready to fire right now

- **Phase A is the immediate front.** INT-08/09 + scene-ordering are written
  and `ready`. Antigravity, one instance, `hub-design` lock.
- **Phase B tickets** (SharedLoader retrofit for the 6 templates + on_track)
  are not yet written — Opus writes them next so they're queued behind the hub
  fix.
- **Phase C** (the 22-game fan-out) stays parked until Gate B clears. The
  earlier "fire all 22 now" instinct is explicitly deferred: cloning
  un-solidified templates would multiply defects.

---

## 6. Parked for Kons (one-line confirms, non-blocking)

- Confirm the 6 templates = pacman, tetris, galaga, frogger, donkey_kong, gta
  (on_track standalone). Correct if your "6 favorites" differ.
- Confirm Phase order: hub → templates → fan-out → polish. (Matches your
  2026-06-30 direction.)
- Layout polish: Phase A or Phase D?

---

*Sequences: PLAN_interpretation-and-editor.md (the WHAT) · Governance:
_Briefs/governance/ (the HOW) · Board: vault/60-bases/interpretation.base ·
This doc: the ORDER + the OPERATING MODEL.*
