---
doc_id: governance-04-agent-handoff-template
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: template
last_revised: 2026-06-30
---

# 04 — Agent Handoff Template

**Every session, every agent, every lane, ends with this file written.** No
exceptions for "I didn't do much" or "it broke before I finished" — those
sessions need a handoff *more*, not less. The previous holder of the lock is
the next holder's only context.

Naming collision is impossible by construction because every filename includes
the agent id and date. Six parallel cart agents on the same day produce six
distinct files.

---

## 1. Where the handoff lives

For a ticket-scoped session:

```
vault/40-agent-runs/<agent>_<topic>_<YYYY-MM-DD>.md
```

For a recovery session:

```
vault/40-agent-runs/recovery_<topic>_<YYYY-MM-DD>.md
```

For a QA/visual session:

```
vault/70-qa/<agent>_<topic>_<YYYY-MM-DD>.md
```

`<agent>` is the fleet name + optional disambiguator: `codex`, `codex_2`,
`antigravity`, `antigravity_3`, `claude_opus`, `claude_sonnet_4`. `<topic>` is
the ticket id or a short slug. Dates are ISO `YYYY-MM-DD`.

## 2. Required frontmatter

```yaml
---
run_id: <agent>_<topic>_<YYYY-MM-DD>
agent: <fleet-name-with-id>
session_start: <ISO timestamp>
session_end: <ISO timestamp>
task_id: <TASK-INT-...>             # the ticket worked, if any
lane: <tools|hub|shared|cartridge|vault|schemas|governance>
lock_held: <lock-name or "none">
status: <done|pending_kons_verify|blocked|abandoned>
pre_edit_commit: <git short hash>   # mandatory for any edit > §1.2 threshold
close_commit: <git short hash>      # mandatory if any edit was made
escalations: []                      # list of OPEN_QUESTIONS entries added
---
```

`status: abandoned` is a real, honest status. If the session ran out of time,
context, or capacity before close, mark it abandoned and explain. The next
agent (or the orchestrator) picks it up cleanly.

## 3. Required body sections

### Summary

Two to four sentences. What was attempted, what landed, what didn't.

### Changes

Bullet list of concrete edits with file paths. Skip "minor formatting" —
this is the durable record.

```
- Added <feature> to app/hub/main.gd lines 412-431 (new function _load_thumbnail_for_skin).
- Updated content/cartridges/pacman/main.gd: SharedLoader integration; removed local class_name reach.
```

### Verification (the gate evidence)

Per the lane's gate in `02_VERIFICATION_GATES.md`. Paste real output. Path to
screenshots if visual.

```
Cartridge gate (pacman):
- grep -E "SharedLoader" content/cartridges/pacman/ → 4 hits (main.gd, level_adjustments.gd, ...)
- grep -E "Adapter\.new\(\)|TabMenu\.new\(\)" content/cartridges/pacman/ → empty
- ls content/cartridges/pacman/adapter_base.gd → not found
- Launch log: vault/70-qa/pacman_launch_2026-06-30.log
- Screenshot: vault/70-qa/pacman_classic_2026-06-30.png
- Kons launch confirmation: PENDING (status: pending_kons_verify)
```

### Open questions

Anything the orchestrator needs to decide. Cross-link to the entry the agent
appended to `vault/40-agent-runs/OPEN_QUESTIONS.md`.

### Next holder briefing

One short paragraph for whoever picks this up next. "If you take this ticket
next, here's the trap." Not optional. Not "see the receipt above."

## 4. If the session ended badly

`status: blocked` or `status: abandoned` is normal and expected. The handoff
still gets written. Required additional fields:

- **What broke or stopped me:** specific error, missing dependency, scope
  ambiguity, time/credit limit.
- **What I left in a known-good state:** explicit list of files/commits.
- **What is in flight and risky:** any uncommitted edits, half-applied
  patches, locks I held.
- **What the next agent should do first:** "run X command to confirm Y" or
  "read Z file before touching W."

## 5. Lock release

Whoever closes the handoff also deletes the lock note at
`vault/35-locks/<lock-name>.md`. The deletion is part of the close commit
named in the frontmatter.

If the agent cannot delete the lock (no write access, environment failure),
they note it in **Next holder briefing** and the orchestrator clears it on
the next sweep.

## 6. The orchestrator's read pattern

When the orchestrator picks up the chair (or sweeps mid-day), it reads every
new handoff under `vault/40-agent-runs/` since its last sweep, in
chronological order. The handoff is the agent's voice; the orchestrator
treats it as the only authoritative source for what happened.

If a handoff is missing for a session that clearly happened (git commits
exist, tickets flipped, locks appeared), the orchestrator opens a `lane:
vault` ticket to reconstruct it from git + transcripts and pings the agent
fleet on `AGENT_SYNC.md`. **Missing handoffs are a tracked failure mode,
not a silent shrug.**

## 7. Example: a minimal but complete handoff

```markdown
---
run_id: antigravity_2_cart_snake_2026-07-01
agent: antigravity_2
session_start: 2026-07-01T09:14:00Z
session_end: 2026-07-01T10:42:00Z
task_id: TASK-INT-cart-snake
lane: cartridge
lock_held: cart-snake
status: pending_kons_verify
pre_edit_commit: a4f9c2b
close_commit: 7d1e8f0
escalations: []
---

## Summary

Brought content/cartridges/snake/ onto the shared MAZE adapter via
SharedLoader. Added the shared Tab menu with maze knobs (grid_scale,
wall_width, density, invert, reference). Parses, launches headless. Needs
Kons visual confirmation.

## Changes

- content/cartridges/snake/main.gd: removed bespoke map-read logic;
  added SharedLoader.load_adapter_script("maze") at _ready.
- content/cartridges/snake/main.gd: added SharedLoader.load_tab_menu_script()
  invocation; wired the 5 maze knobs.
- content/cartridges/snake/manifest.yaml: archetype = maze (was unset).
- Removed: content/cartridges/snake/adapter_base.gd (was a local copy).

## Verification

Cartridge gate (snake):
- grep -E "SharedLoader" content/cartridges/snake/ → 3 hits
- grep -E "Adapter\.new\(\)|TabMenu\.new\(\)" content/cartridges/snake/ → empty
- ls content/cartridges/snake/adapter_base.gd → not found
- Headless launch log: vault/70-qa/snake_headless_2026-07-01.log (parses,
  Tab menu opens, exits clean)
- Kons launch confirmation: PENDING

## Open questions

None new. Knob defaults match pacman's; may need per-game tuning in Wave 3.

## Next holder briefing

If Kons reports a regression on classic snake, the most likely culprit is
the density knob (defaults to 0.4, may be too sparse for the classic 32x32
grid). Try 0.6. Do not touch the wall_width default — it tracks the maze
adapter contract and changing it here would diverge from pacman.
```

---

*Authority: this document. Companions: [[01_LANES]] (where the work
happened), [[02_VERIFICATION_GATES]] (what evidence the receipt must
contain), [[03_RECOVERY_PROTOCOL]] (recovery-specific variant),
[[06_VAULT_HYGIENE]] (sweep cadence). Index: [[00_README]].*
