---
doc_id: governance-06-vault-hygiene
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: contract
last_revised: 2026-06-30
---

# 06 — Vault Hygiene

**The vault is the system's memory.** If it drifts from reality, every
downstream decision is wrong. This document is the discipline that keeps it
honest.

The Jun 28-30 corruption exposed the gap: the vault stopped getting updated
the moment things went sideways. Hygiene that only holds on the happy path
is not hygiene.

---

## 1. Vault folder map (what lives where)

```
vault/
  10-research/      research notes, kept indefinitely
  20-architecture/  durable architecture docs (arena pipeline, input, hub)
  30-tasks/         tickets (TASK-INT-*.md) — one file per ticket
  35-locks/         active locks (delete on close)
  40-agent-runs/    handoffs (one per session) + OPEN_QUESTIONS.md
  50-schemas/       FROZEN v1 schemas (orchestrator-only edits)
  60-bases/         Obsidian Bases (live queries over 30-tasks)
  70-qa/            QA notes + screenshots + launch logs
  80-builds/        build artifacts, version snapshots
```

## 2. The receipts contract (who writes where)

Every session that touches code produces:

1. **One handoff** in `vault/40-agent-runs/<agent>_<topic>_<date>.md` per
   `04_AGENT_HANDOFF_TEMPLATE.md`.
2. **At least one QA note** in `vault/70-qa/` for any visual or interactive
   change.
3. **Zero or more OPEN_QUESTIONS appends** for parked decisions.
4. **A lock release** (delete from `vault/35-locks/`) on close.
5. **A ticket status flip** with `closed_at` + `closing_receipt` in
   `vault/30-tasks/`.

A session that produced commits but no handoff is a hygiene failure (see §6).

## 3. File naming (so 6 parallel agents don't collide)

Every file an agent writes includes the agent id and date.

| Folder | Pattern |
|---|---|
| `vault/40-agent-runs/` | `<agent>_<topic>_<YYYY-MM-DD>.md` |
| `vault/40-agent-runs/` (recovery) | `recovery_<topic>_<YYYY-MM-DD>.md` |
| `vault/70-qa/` | `<agent>_<topic>_<YYYY-MM-DD>.{md,png,log}` |
| `vault/35-locks/` | `<lock-name>.md` (the lock-name is the coordination key, only one agent holds it at a time) |
| `vault/30-tasks/` | `TASK-INT-<slug>.md` (orchestrator-issued; agents only edit frontmatter) |
| `_Briefs/governance/` | `<NN>_<TOPIC>.md` (orchestrator-only) |

Agent ids stable: `codex`, `codex_2`, `antigravity`, `antigravity_3`,
`claude_opus`, `claude_sonnet_4`, etc. Add digit suffix when running multiple
of the same fleet in parallel.

## 4. Append-coordinated files (multi-agent same file)

Three files take multi-agent appends in the same day. They must be appended
to, never rewritten wholesale.

### `vault/40-agent-runs/OPEN_QUESTIONS.md`

Append a bullet under the correct section header. Format:

```
- [ ] **<short title>** — <decision needed>. Logged by <agent> on <date>.
  Context: <link to handoff>.
```

### `AGENT_SYNC.md` (repo root)

Append a block. Format:

```
## From Agent (<short-id>) - <HH:MM>
<message>
```

### `_Briefs/HANDOFF.md`

Orchestrator-only writes. Agents read.

## 5. Frozen-only folders

`vault/50-schemas/` is **frozen** at v1. Only the orchestrator edits. Any
fleet that needs a schema change opens a ticket and waits (see
`01_LANES.md` §2.3).

`_Briefs/governance/` is **orchestrator-only**.

`_Briefs/PLAN_*.md` and `_Briefs/HANDOFF.md` are **orchestrator-only**.

## 6. Tracked hygiene failures (and the cost of each)

These are real, named, fixable failure modes. They are tracked, not
hand-waved.

### 6.1 Missing handoff

A commit exists but no handoff under `vault/40-agent-runs/`.

- **Cost:** the next holder of the lane works blind. Estimated 15-60 min of
  lost time per missing handoff.
- **Fix:** orchestrator opens a `lane: vault` ticket to reconstruct from
  git + transcripts. Pings the offending agent on `AGENT_SYNC.md`.
- **Prevention:** the dispatch prompt template (`05_ORCHESTRATOR_RUNBOOK.md`
  §3) names the handoff as part of "done." Agents that consistently skip
  handoffs are flagged in OPEN_QUESTIONS for orchestrator review.

### 6.2 Stale lock

A lock exists but the corresponding ticket is `done`.

- **Cost:** new agents avoid the lane, work serializes unnecessarily.
- **Fix:** orchestrator sweeps locks (per `05_ORCHESTRATOR_RUNBOOK.md` §2a)
  and deletes the stale ones.
- **Prevention:** lock deletion is part of the close commit
  (`04_AGENT_HANDOFF_TEMPLATE.md` §5).

### 6.3 Status drift

A ticket's `status:` disagrees with the receipts and git history.

- **Cost:** orchestrator dispatches against a wrong baseline; agents
  duplicate work or step on each other.
- **Fix:** orchestrator reconciles per `05_ORCHESTRATOR_RUNBOOK.md` §2b.
- **Prevention:** the gate (`02_VERIFICATION_GATES.md`) requires status flip
  + closing_receipt + closed_at in the same step.

### 6.4 Silent recovery

Code was repaired but no recovery note in `vault/40-agent-runs/`.

- **Cost:** the lesson is lost. The same trap can be re-stepped.
- **Fix:** orchestrator reconstructs (this happened for Jun 28-30; see
  `vault/40-agent-runs/recovery_hub_main_gd_2026-06-28.md`).
- **Prevention:** `03_RECOVERY_PROTOCOL.md` §4 — receipt is written *as*
  the firefight proceeds, not after.

### 6.5 Vault-outside writes

An agent wrote outside its lane (touched a folder it doesn't own).

- **Cost:** contract violated. Possible silent breakage of consumers.
- **Fix:** orchestrator reverts via git, opens a ticket for the original
  goal in the right lane, escalates the agent's behavior to OPEN_QUESTIONS.
- **Prevention:** `01_LANES.md` §1 + dispatch prompt restricts the agent
  to its tree.

### 6.6 Repo-root cruft

One-off scripts (`fix_*.py`, `recover_*.py`, etc.) accumulate at repo root.

- **Cost:** newcomers can't tell signal from noise; git history bloats.
- **Fix:** orchestrator moves to `scratch/recovery-<date>/` and updates
  `.gitignore`.
- **Prevention:** `03_RECOVERY_PROTOCOL.md` §4.5 — recovery scripts live
  in `scratch/recovery-<date>/`, never in repo root.

## 7. Sweep cadence (orchestrator)

| Sweep | Cadence | Scope |
|---|---|---|
| Lock sweep | Every orchestrator session | `vault/35-locks/` vs. ticket statuses |
| Status reconciliation | Every orchestrator session | `vault/30-tasks/` vs. handoffs + git |
| Handoff completeness | Every orchestrator session | new commits vs. `vault/40-agent-runs/` |
| AGENT_SYNC archive | After every resolved thread | archive into `sync_archive_<date>.md` |
| Repo-root cruft check | Weekly | repo root file count |
| Daily snapshot tag | Daily | `git tag daily/<YYYY-MM-DD>` |
| Schema audit | Per release | every consumer compiles against current `vault/50-schemas/` |

## 8. Obsidian-specific notes

Wiki-links (`[[doc_id]]`) are first-class. Link liberally — broken
wiki-links are tracked-failure mode 6.7 below (added if it becomes a
problem).

Frontmatter `tags:` and `connections:` on every governance doc keep the
graph view useful (per the `obsidian-tags` skill).

`vault/60-bases/interpretation.base` is a live Obsidian Base over the
tickets. The orchestrator uses it as the dispatch board (Ready/In Progress/
Blocked views). It is read-only at the agent level — the underlying tickets
are the source of truth.

## 9. The honest version of "vault is up to date"

The vault is up to date when:

1. Every lock in `vault/35-locks/` corresponds to a live `in_progress`
   ticket.
2. Every `done` ticket has a `closing_receipt` that exists and passes its
   gate.
3. Every commit in the last 7 days has a corresponding handoff.
4. `AGENT_SYNC.md` has been archived since the last orchestrator session.
5. `_Briefs/HANDOFF.md` reflects what's actually in flight.

If any of those fail → there is real work for the orchestrator to do
before any new dispatch.

---

*Authority: this document. Companions: [[01_LANES]] (where work lives),
[[04_AGENT_HANDOFF_TEMPLATE]] (the receipt shape), [[05_ORCHESTRATOR_RUNBOOK]]
(sweep mechanics), [[07_GIT_GOVERNANCE]] (snapshot cadence).
Index: [[00_README]].*
