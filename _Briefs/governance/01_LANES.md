---
doc_id: governance-01-lanes
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: contract
last_revised: 2026-06-30
supersedes: parts of INTEGRATION_CONTRACT.md §1 (kept as legacy reference)
---

# 01 — Lanes, Restrictions, Escalation

**The contract every agent reads before its first edit.** Hardens
`INTEGRATION_CONTRACT.md` with the lessons from the Jun 28-30 corruption event.

If a change would violate this document, **STOP** and escalate. Do not "fix
forward." Do not work around a frozen contract.

---

## 1. Folder ownership (disjoint trees — never cross)

| Lane | Owns (writes here only) | Default fleet | Can read |
|---|---|---|---|
| `tools` | `app/tools/**` | Codex | repo-wide, read-only |
| `hub` | `app/hub/**` | Antigravity | repo-wide, read-only |
| `shared` | `app/shared/**` | Antigravity or Sonnet | repo-wide, read-only |
| `cartridge` | `content/cartridges/<game>/**` (one game per agent) | any | repo-wide, read-only |
| `vault` | `vault/30-tasks/**`, `vault/35-locks/**`, `vault/40-agent-runs/**`, `vault/70-qa/**` | the agent doing the work | repo-wide |
| `schemas` | `vault/50-schemas/**` | **Orchestrator only** | repo-wide |
| `governance` | `_Briefs/governance/**`, `_Briefs/HANDOFF.md`, `_Briefs/PLAN_*.md` | **Orchestrator only** | repo-wide |

**Agents are interchangeable.** The default fleet column is *suitability*, not
identity. Any capable agent may execute any lane; folder ownership while the
package is being worked is what's non-negotiable. **No two concurrent agents
write the same tree.**

A single fleet running multiple packages MUST partition its sub-agents along
these exact boundaries.

## 2. Forbidden patterns (the traps we've already hit)

These are not "best practice" suggestions. Violating any of them caused a real
incident in this repo.

### 2.1 The `multi_replace_file_content` trap (cost: Jun 28 hub corruption)

Multi-range string-replacement tools with an `EndLine` parameter MUST NOT be
used on a file the agent has not just read end-to-end in this session.
Mismatched `EndLine` values silently delete the range between them. This wiped
lines 51–1780 of `app/hub/main.gd` and required a 13-script recovery campaign.

**Rule:** before any range-based edit:

1. Read the entire file (or the full target span) in this session.
2. Prefer single-target replacements (`old_string` → `new_string`) with enough
   surrounding context to be unique.
3. If the tool requires line ranges, write a sanity check: log start-line
   content + end-line content + line count before the call. Refuse the call if
   any of them disagree with the read.

### 2.2 `class_name` reach across separate Godot projects

Every cartridge and the hub are **separate Godot projects**. `res://` resolves
to that project's own folder; `app/shared` is OUTSIDE it. **NEVER** use global
`class_name` (e.g. `RegionAdapter.new()`, `TabMenu.new()`) or `res://`-relative
preloads from a cartridge or hub to reach shared code — it won't resolve.

**Rule:** use `app/shared/shared_loader.gd`:
`SharedLoader.load_adapter_script("<arch>")`, `load_tab_menu_script()`.
Canonical model: `content/cartridges/gta/main.gd`. Gate (see 02): `grep
"SharedLoader"` must hit, `grep "Adapter\.new\(\)|TabMenu\.new\(\)"` must be
empty, no local `adapter_base.gd`.

### 2.3 Editing frozen schemas

`vault/50-schemas/**` is frozen. Any fleet that needs a schema change opens a
task note in `vault/30-tasks/` and waits. **The fleet does not edit the schema
to unblock itself.** Schema changes are additive (v1.x) until a hard break is
unavoidable (v2).

### 2.4 Writing outside your tree

Cross-tree needs go through `app/shared/` (the contract surface) and the
orchestrator. A `tools` agent must not edit `app/hub/`. A `cartridge` agent
must not edit `app/shared/`. A `hub` agent must not edit a cartridge folder.

### 2.5 Silent recovery (the second Jun 28-30 failure)

If a build session pivots into firefighting, **the receipt is still required**.
Every recovery action goes into `vault/40-agent-runs/recovery_<topic>_<date>.md`
as it happens, not after. The corruption event was not the failure; the
*invisible* recovery was. See `03_RECOVERY_PROTOCOL.md`.

## 2b. Parallel work pattern (6+ agents at once is the design target)

Kons routinely runs **up to 6 simultaneous agents** across cartridges for
build, debug, and test passes. This is the system's natural mode, not the
exception. The lane grid above is collision-free for parallel cart agents by
construction:

- **One cartridge = one folder = one lock = one writer.** Six agents on six
  different cartridges write into six disjoint trees. No coordination needed
  beyond the lock note.
- **Cartridges run as separate processes** and **separate Godot projects**.
  They never share runtime state or files at write time. The IPC contract
  (hub ↔ cart, NDJSON, §3 of `INTEGRATION_CONTRACT.md`) is the only seam.
- **Shared code is read-only at runtime.** `app/shared/**` is consumed via
  `SharedLoader` (see 2.2); cart agents never write there.

**What's safe in parallel:**
- N agents, each owning one `content/cartridges/<game>/` folder.
- N agents launching their own cart binary in their own process for debug.
- N agents reading the same `app/shared/**`, `vault/50-schemas/**`,
  `content/scenes/**`.
- N agents appending to `vault/40-agent-runs/` and `vault/70-qa/` (file names
  include the agent id and date — see `04_AGENT_HANDOFF_TEMPLATE.md`).

**What is NOT safe in parallel and must serialize on a shared lock:**
- Two agents editing `app/hub/**` → serialize on `hub-<purpose>` lock.
- Two agents editing `app/shared/**` → serialize on `shared-<purpose>` lock.
- Two agents editing `app/tools/**` → serialize on `tools-<purpose>` lock.
- Two agents editing the same cartridge → serialize on `cart-<game>` lock.
- Any edit to `vault/50-schemas/**` → orchestrator-only, single-threaded.
- Any edit to `_Briefs/governance/**` or `_Briefs/HANDOFF.md` →
  orchestrator-only, single-threaded.

**Append-safe vault files** (multiple agents can write the same day without
colliding because each writes its own file):

- `vault/40-agent-runs/<agent>_<topic>_<date>.md`
- `vault/70-qa/<agent>_<topic>_<date>.md`
- `vault/35-locks/<lock-name>.md`

**Append-coordinated vault files** (single file, multi-agent append — use
file-level append, not whole-file rewrite):

- `vault/40-agent-runs/OPEN_QUESTIONS.md` — always append a new bullet under
  the relevant section header. Never rewrite the file wholesale.
- `_Briefs/HANDOFF.md` — orchestrator-only writes; agents read.
- `AGENT_SYNC.md` (repo root) — append-only real-time chat; each agent
  prefixes its block with `## From Agent (<short-id>) - <HH:MM>`.

**Six-agent debug/test pattern (the Kons workflow):**
1. Open one cart per agent — six cartridges, six locks, six folders.
2. Each agent reads its ticket + the four mandatory docs (§6 below).
3. Each agent launches its own cart binary headless or with the Godot console
   for debug; logs go to its own working file under the cartridge folder or
   the agent's scratch space, NEVER to repo root.
4. Each agent writes its receipt at session end (one file per agent — naming
   collision impossible by construction).
5. Orchestrator sweeps locks + reconciles statuses after.

## 3. Locks (advisory but enforced socially)

Before claiming a ticket, write a lock note at
`vault/35-locks/<lock-name>.md` containing your agent id, the ticket id, and
the time. The `locks_required` field on the ticket lists the lock-name(s).

**One lock = one concurrent writer.** `hub-design` and `shared-adapters` are
serialized locks: even if multiple sub-agents from the same fleet are working,
they share the lock and sequence inside it.

**Releasing the lock is part of closing the ticket.** A lock left behind
after `status: done` is a hygiene violation; the next orchestrator sweep
deletes it (see `06_VAULT_HYGIENE.md`).

## 4. Escalation paths

Anything that would (a) edit a frozen schema, (b) write outside your tree,
(c) add an IPC message, (d) change the MVP definition, (e) break a contract in
`app/shared/**`, or (f) require a tool the lane doesn't normally use →

1. **STOP.** Do not work around it.
2. Open a ticket note in `vault/30-tasks/`, `kind: escalation`,
   `escalated_to: orchestrator`.
3. Log the block in `vault/40-agent-runs/OPEN_QUESTIONS.md`.
4. Release your current lock.
5. Pull the next ticket from your lane that doesn't depend on the blocked one.
   Never wait idle.

The orchestrator (this Opus thread or another Claude thread holding the chair)
resolves the escalation and re-issues the ticket.

## 5. Inter-agent communication

`AGENT_SYNC.md` (repo root) is the **real-time** channel when two agents are
forced to coordinate inside the same lane (e.g. a recovery). It is not a
substitute for receipts. Anything significant said in `AGENT_SYNC.md` must
also be summarized in the relevant `vault/40-agent-runs/` note.

`vault/40-agent-runs/OPEN_QUESTIONS.md` is the **async** channel — parked
decisions waiting on the orchestrator.

## 6. What gets read on cold-start (mandatory)

Every agent, every fleet, on session start, reads in this order:

1. `_Briefs/governance/00_README.md` (this pack's index)
2. `_Briefs/governance/01_LANES.md` (this file)
3. `_Briefs/governance/02_VERIFICATION_GATES.md`
4. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
5. The ticket the agent is claiming
6. Any `vault/40-agent-runs/` note from the previous holder of the same lock

The orchestrator, additionally, reads `05_ORCHESTRATOR_RUNBOOK.md` and the
current state of `_Briefs/HANDOFF.md`.

---

*Authority: this document. Legacy reference: [[INTEGRATION_CONTRACT]].
Index: [[00_README]].*
