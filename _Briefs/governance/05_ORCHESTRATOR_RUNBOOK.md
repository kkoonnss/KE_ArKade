---
doc_id: governance-05-orchestrator-runbook
audience: [orchestrators, claude_threads]
authority: runbook
last_revised: 2026-06-30
---

# 05 — Orchestrator Runbook

**For whichever Claude thread (or human) is holding the orchestrator chair.**
Picks-up protocol from a cold start, sweep cadence, dispatch shape,
verification cadence, hand-off shape when the chair changes hands.

This is the "what does Opus actually do all day" doc.

---

## 0. The orchestrator's job in one sentence

Hold the contract. Verify reality against tickets. Dispatch work into the
right lanes. Never write code yourself unless the lane explicitly delegates
to the orchestrator (schemas, governance).

## 1. Cold-start protocol (a fresh Claude thread inherits the chair)

In this exact order:

1. Read `_Briefs/HANDOFF.md` — the last orchestrator's parting note.
2. Read `_Briefs/governance/00_README.md` — this pack's index.
3. Read `_Briefs/governance/01_LANES.md`, `02_VERIFICATION_GATES.md`,
   `03_RECOVERY_PROTOCOL.md`, `06_VAULT_HYGIENE.md`, `07_GIT_GOVERNANCE.md`.
4. List active locks: `ls vault/35-locks/`. Each lock represents a claim by
   an agent. Note any whose ticket is already `done` — those are stale and
   get swept (§3).
5. List recent handoffs: `ls -lt vault/40-agent-runs/` for the last 7 days.
   Read every one whose ticket the previous orchestrator did not already
   confirm closed.
6. List ticket statuses: grep `status:` across `vault/30-tasks/*.md`. Cross
   reference against handoffs. Any disagreement = reconcile (§4).
7. Check `vault/40-agent-runs/OPEN_QUESTIONS.md` and
   `_Briefs/HANDOFF.md` for parked decisions waiting on you.
8. Check `AGENT_SYNC.md` (repo root) for any unresolved real-time threads.
9. Run `git log -10 --oneline` and `git status -s` to ground in actual repo
   state versus what the tickets claim.
10. Read the current `_Briefs/PLAN_*.md` directive to understand which
    Stage/Wave is active.

You are now warmed up. **Do not dispatch new work or flip any status until
you've finished steps 1–10.**

## 2. Daily/per-session sweep

Run at least once per orchestrator session, more often during active build
days.

### 2a. Lock sweep

```
ls vault/35-locks/*.md
```

For each lock file:
- Find the ticket(s) with `locks_required:` containing this lock-name.
- If all of those tickets are `status: done` → the lock is stale → delete it.
- If a ticket is `status: in_progress` and the corresponding handoff exists
  and is dated > 24h ago → ping the agent on `AGENT_SYNC.md`; if no
  response by next sweep, treat as abandoned and release the lock.
- If a ticket is `status: in_progress` and no handoff exists → escalate to
  the agent via `AGENT_SYNC.md` requesting a status; lock is presumed live.

### 2b. Status reconciliation

```
for f in vault/30-tasks/TASK-*.md; do
  grep -E "^(task_id|status|closed_at|closing_receipt):" "$f"
done
```

For each ticket marked `done`:
- Confirm `closing_receipt` exists at the named path.
- Confirm the receipt's gate evidence (per `02_VERIFICATION_GATES.md` §2-7).
- If gate evidence is missing → flip to `pending_kons_verify`, log the gap
  in OPEN_QUESTIONS.

For each ticket marked `pending_kons_verify`:
- Check `_Briefs/HANDOFF.md` and recent chat for Kons confirmation.
- If confirmed → flip to `done`, append to handoff log.
- If not confirmed in > 48h → re-surface in the next Kons ping.

### 2c. Handoff completeness

Every commit in the last 24h should have a corresponding handoff under
`vault/40-agent-runs/`. If a commit exists without a handoff:
- Open a `lane: vault` ticket to reconstruct from git + transcripts.
- Ping the agent fleet on `AGENT_SYNC.md`.
- Record as a tracked hygiene failure in OPEN_QUESTIONS.

### 2d. AGENT_SYNC.md archive

After resolving every thread in `AGENT_SYNC.md`, move its content into
`vault/40-agent-runs/sync_archive_<YYYY-MM-DD>.md` and reset the file to
its template header. This keeps the live channel from accreting noise.

### 2e. Repo root cruft check

```
ls *.py *.txt *.gd *.log *.png 2>/dev/null | wc -l
```

Anything in repo root that isn't:
- `Create Shortcuts.vbs`, `icon.ico`, `icon.png`, `Godot_v4.3-stable_*.exe`,
  `add_multiplayer.py` (if still load-bearing — confirm), or another known
  fixture

should either be in `.gitignore` (one-off recovery script) or moved into
the appropriate folder. The repo root is not scratch.

## 3. Dispatch shape (issuing work)

When dispatching to a fleet:

1. Confirm the lane is unblocked (no in-flight ticket in the same tree).
2. Confirm the agent will read the four mandatory docs (`01_LANES`,
   `02_VERIFICATION_GATES`, `03_RECOVERY_PROTOCOL`, plus the ticket).
3. Write the dispatch prompt in this shape (the existing `DISPATCH.md`
   template still applies):

```
You are an autonomous build agent on the KE_ArKade project.
Repo root: C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade

Read in order:
1. _Briefs/governance/01_LANES.md
2. _Briefs/governance/02_VERIFICATION_GATES.md
3. _Briefs/governance/03_RECOVERY_PROTOCOL.md
4. _Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md
5. vault/30-tasks/<TASK-...>.md (your ticket)

[Lane-specific brief]

Rules:
- Write ONLY inside <lane tree>. Everything else read-only.
- Claim: set owner_agent + status: in_progress; lock note at
  vault/35-locks/<lock-name>.md.
- Pre-edit commit before any edit to a file > 200 lines.
- Verify via the lane gate in 02_VERIFICATION_GATES.md before close.
- Close with a handoff per 04_AGENT_HANDOFF_TEMPLATE.md. Release the lock.
- Blockers → vault/40-agent-runs/OPEN_QUESTIONS.md and stop. Do not guess.
```

4. Pass the prompt to Kons to paste, or invoke the agent directly via the
   Agent tool if the fleet supports it (Claude sub-agents).

### 3a. Parallel dispatch (6+ agents)

When dispatching multiple cart tickets in parallel:

1. Confirm the lock for each cart is free.
2. Issue one prompt per cart with explicit `<GAME>` substitution.
3. Note in the orchestrator's own working log which agents got which carts.
4. After the batch returns, run the cartridge gate (§2c above + the gate
   document) on each before flipping any to `done`.
5. Bundle the Kons launch confirmation requests — one message listing N
   games to spot-check, not N messages.

## 4. The verification cadence

Per `02_VERIFICATION_GATES.md` §9 — after every batch returns:

1. Grep the gate for every claimed-done ticket.
2. Confirm the lock release + receipt exist.
3. Single Kons ping with the launch list.
4. Flip to `done` only after Kons confirms.

## 5. Escalation handling

When an agent escalates (per `01_LANES.md` §4):

1. Read the escalation ticket in `vault/30-tasks/` and the corresponding
   OPEN_QUESTIONS entry.
2. Decide. Schema changes, contract changes, MVP redefinition, new
   forbidden patterns — these are yours.
3. Apply the decision: edit the relevant governance doc, schema, or
   contract. Update `_Briefs/HANDOFF.md`.
4. Re-issue the ticket (or open a follow-on) to the appropriate fleet.

## 6. Chair handoff (when you, the orchestrator, end your session)

You write `_Briefs/HANDOFF.md` with:

1. Current Stage/Wave and what's actively in flight.
2. What you just landed in this session (new docs, decisions, dispatches).
3. What's parked in OPEN_QUESTIONS that's blocking forward motion.
4. What the next orchestrator should sweep first.
5. Any Kons-specific asks that are still open.

The HANDOFF.md is the next orchestrator's cold-start input (step 1 of §1).

## 7. The orchestrator's forbidden patterns

You, too, have lane discipline.

- **Do not write code in `app/**` or `content/**`.** That's the fleets'
  work. If you find yourself drafting GDScript or Python, you've crossed.
  Open a ticket and dispatch.
- **Do not skip the cold-start protocol** to "save time." Every skipped
  step is a stale assumption that will cost more later.
- **Do not flip a ticket to `done` without gate evidence.** Even if Kons
  says "we're done" in chat — get the receipt first.
- **Do not delete a recovery note**, even if it's resolved. It's the
  durable record of how we learned.

## 8. Tools the orchestrator uses

- `Read` / `Grep` / `Glob` on the host path for fresh state.
- `mcp__workspace__bash` for grep batches, git inspection, lock listings.
  Cache lag caveat: prefer `Read` on the host for files just edited by
  another agent.
- `Edit` / `Write` for governance docs, ticket frontmatter, lock files,
  `.gitignore`, `_Briefs/HANDOFF.md`.
- `Agent` tool to spawn Claude sub-agents for parallel dispatch when the
  fleet is Claude-side. For Codex / Antigravity, the prompt goes to Kons
  to paste.
- `mcp__workspace__bash` git commands for snapshots, log inspection,
  history. Direct `git` execution is allowed for the orchestrator's
  sweep/snapshot duties even though it's "writes."

## 9a. QC cadence (Sonnet sub-agent pattern)

The orchestrator does not verify every gate personally. It spawns Sonnet
4.6 sub-agents (via the Agent tool) for cold, narrow validation passes.
This is the "belt AND suspenders" layer that makes Kons's "efficiency =
me not finding bugs" possible.

**QC pass triggers (spawn a Sonnet sub-agent when any of these fire):**

1. **Batch of 3+ cartridge returns.** After 3 or more agents claim
   `status: done` on cart tickets in the same window, spawn one Sonnet
   sub-agent to cold-re-run the cartridge gate
   (`02_VERIFICATION_GATES.md` §2) on ALL of them. If the sub-agent
   disagrees with any claim, that claim is downgraded to
   `pending_kons_verify`.
2. **Hub commit without an accompanying receipt.** Spawn a Sonnet
   sub-agent to reconstruct the receipt from the commit + `AGENT_SYNC.md`.
   Same pattern as the Jun 28-30 corruption reconstruction — automate it.
3. **Weekly hygiene sweep.** Spawn a Sonnet sub-agent to run every check
   in `06_VAULT_HYGIENE.md` §7 (lock sweep, status reconciliation,
   handoff completeness, repo-root cruft) and file a hygiene report at
   `vault/40-agent-runs/hygiene_sweep_<YYYY-MM-DD>.md`.
4. **Pre-cascade validation.** Before dispatching a large parallel batch
   (6+ agents), spawn a Sonnet sub-agent to grep-verify that every
   ticket the batch depends on is actually `done` with valid receipt.
5. **Cross-cartridge consistency.** Every N ticket closes (N=5 default),
   spawn a Sonnet sub-agent to grep for pattern drift across the cart
   family (e.g. "all maze carts use SharedLoader the same way"). Drift
   opens a Wave-3 ticket.

**Sub-agent briefing shape:**

Every sub-agent gets: the four mandatory reads (`01_LANES`, `02_VERIFICATION_GATES`,
`03_RECOVERY_PROTOCOL`, `04_AGENT_HANDOFF_TEMPLATE`), plus its specific
scope. It writes a receipt like any other agent. It closes.

**Model routing:**

- Orchestrator chair: **Opus 4.8, extended thinking**. Judgment lane.
- QC sub-agents (grep, gate re-runs, receipt reconstruction): **Sonnet 4.6**.
- Fast pattern checks (dead-simple existence/count): **Haiku 4.5** where
  the task truly does not need reasoning.

The point: the orchestrator is expensive-but-rare, the QC is cheap-and-often.
Both are needed. Neither can be skipped without regressing to Jun 28-30.

## 9b. Sub-agent budget guidance

Kons rations Claude credits. To make the QC pattern affordable:

- Prefer **one sub-agent per QC pass**, not one per artifact. A Sonnet
  sub-agent can grep 22 cartridges in a single session.
- Bundle QC triggers. If the weekly sweep and a batch-of-3-return
  validation both fire on the same day, one sub-agent handles both.
- Use Haiku where the check is grep-count-shaped and Sonnet only when
  interpretation is needed.

## 10. When to ask Kons vs. decide

Ask Kons when:
- A schema change or contract change has a creative impact (game feel,
  archetype reassignment, visual design system change).
- Verification requires a Godot launch (you cannot launch).
- Resource allocation (which fleet, how many agents) is unclear.
- A decision changes the MVP definition.

Decide yourself when:
- Stale lock release, status reconciliation, handoff reconstruction.
- Dispatch routing within an already-approved plan.
- Forbidden-pattern addition after an incident.
- Governance doc edits, ticket frontmatter, .gitignore.

Default to **forward momentum**. If a decision is reversible and inside
your lane, decide. If it's load-bearing or creative, ask.

---

*Authority: this document. Companions: [[01_LANES]], [[02_VERIFICATION_GATES]],
[[03_RECOVERY_PROTOCOL]], [[04_AGENT_HANDOFF_TEMPLATE]], [[06_VAULT_HYGIENE]],
[[07_GIT_GOVERNANCE]]. Index: [[00_README]].*
