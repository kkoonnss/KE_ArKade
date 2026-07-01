---
doc_id: governance-03-recovery-protocol
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: contract
last_revised: 2026-06-30
origin_incident: Jun 28-30 2026 hub main.gd corruption + 3-day silent recovery
---

# 03 — Recovery Protocol

**This document exists because of a real incident.** On 2026-06-28 an agent
ran `multi_replace_file_content` on `app/hub/main.gd` with a mismatched
`EndLine` and silently deleted lines 51–1780. The hub greyed. Two agents
coordinated a 13-script recovery over three days. The vault has **zero
receipts** for any of it — the recovery happened entirely outside the
discipline system.

The corruption was preventable. The silent recovery was the second, larger
failure.

This document is how we prevent both.

---

## 1. Pre-edit invariants (every edit, every lane)

Before any edit to any file > 200 lines or any file an agent did not create
in this session:

1. **Read the file end-to-end in this session.** The "I read this last session"
   memory does not count — tools lie about line numbers across sessions.
2. **Commit the pre-edit state to git** under a tag like
   `pre-edit/<lane>/<topic>/<short-hash>`. One command (see §5). If git is
   not yet set up in the agent's workspace, the agent escalates rather than
   proceeds.
3. **Prefer single-target replacement** (`old_string` → `new_string`) with
   enough surrounding context to be unique. Range-based and multi-replace
   tools require a sanity check (see §1.1).
4. **Edit one logical change per commit.** If the agent's task requires N
   changes, that is N commits, not one.

### 1.1 Sanity check for range-based / multi-replace tools

Tools like `multi_replace_file_content` (the Jun 28 culprit) take line ranges.
Before any such call, the agent MUST:

```
# Log the bounds the agent BELIEVES it is editing
echo "start_line=$START content='$(sed -n "${START}p" $FILE)'"
echo "end_line=$END content='$(sed -n "${END}p" $FILE)'"
echo "span=$((END - START + 1)) lines"
```

If `start_line` or `end_line` content does not match what the agent expects
to be replacing, **abort the call.** Re-read the file. Recompute the bounds.

If `span` is larger than the agent intended (the Jun 28 trap: agent thought
it was editing 10 lines, the call deleted 1730), **abort the call** and
escalate.

## 2. Snapshot cadence (the cheap insurance)

### 2.1 Per-edit snapshot (mandatory)

Every edit to a file > 200 lines is preceded by a git commit of the
pre-edit state. The closing receipt names the pre-edit commit hash.

This is the gate (`02_VERIFICATION_GATES.md` §3.5) for hub edits because the
hub was the corruption site. Apply the same rule to any file the agent did
not author in this session.

### 2.2 Per-ticket snapshot (mandatory)

Every ticket claim begins with `git commit` of the working tree state (even
if nothing changed yet). Every ticket close ends with a `git commit` of the
final state. The receipt names both hashes.

### 2.3 Per-session snapshot (recommended)

At the start and end of every agent session (even a multi-ticket session),
commit. This bounds the blast radius if anything goes sideways mid-session.

### 2.4 Per-day backup snapshot (orchestrator)

The orchestrator (or a scheduled task) tags `daily/<YYYY-MM-DD>` once per
day, regardless of session activity. Cheap, durable, never wrong to have.

### 2.5 Per-week backup snapshot (orchestrator)

The orchestrator tags `week/<YYYY-Www>` (ISO week) once per week. This is
the "larger increment" backup — the coarse marker Kons's small-vs-large
versioning concern maps to. When the GitHub remote lands, weekly tags are
the minimum push cadence.

## 3. The forbidden patterns (already in `01_LANES.md` §2)

- `multi_replace_file_content` without the §1.1 sanity check.
- Global `class_name` reach across separate Godot projects.
- Editing frozen schemas.
- Writing outside your tree.
- **Silent recovery** (see §4).

## 4. The receipt-during-firefight rule

When a build session pivots into firefighting (file corruption, broken build,
agent collision, unexpected state), the receipt **is still required, and is
written as the firefight proceeds, not after.**

The Jun 28-30 corruption is the negative example. The right shape:

1. Agent detects breakage. **First action:** create
   `vault/40-agent-runs/recovery_<topic>_<date>.md` with frontmatter
   `kind: recovery`, `severity: <P0|P1|P2>`, `started_at: <ISO>`.
2. Every recovery action gets a one-line entry as it happens: command run,
   output observed, hypothesis. Not after — as it happens.
3. If a second agent gets pulled in (the Jun 28 pattern), they read the
   recovery note before touching anything, append their own actions to it,
   and use `AGENT_SYNC.md` for real-time chat (see `01_LANES.md` §5).
4. On resolution, the recovery note closes with `resolved_at`, root cause,
   prevention rule, and links to any new tickets opened.
5. Throwaway recovery scripts (`recover_*.py`, `stitch_*.py`, etc.) live in
   `scratch/recovery-<date>/`. They do NOT live in repo root. They are
   `.gitignore`-d (see `07_GIT_GOVERNANCE.md`).

## 5. Restoration playbook (when corruption has already happened)

Triage in this order:

### Step 1 — Stop all edits

The agent that detected the breakage announces in `AGENT_SYNC.md` and on its
own working channel. **No further edits to the affected tree** until step 4.

### Step 2 — Open the recovery note

`vault/40-agent-runs/recovery_<topic>_<date>.md`. Severity: P0 if the hub
or schemas are broken, P1 if a cart or tool, P2 if local-only.

### Step 3 — Restore from snapshot

In order of preference:

1. **Git pre-edit tag** (`pre-edit/<lane>/<topic>/<hash>`) — if §1.2 was
   followed, this is one `git checkout` away.
2. **Most recent ticket-close commit** for the affected lane.
3. **Daily snapshot tag** (`daily/<YYYY-MM-DD>`).
4. **Stitching** from transcripts / partial files — the Jun 28 fallback.
   This is the worst case and is what we are designing to prevent.

### Step 4 — Verify the restoration

The lane's verification gate (`02_VERIFICATION_GATES.md` §2–7) runs against
the restored state. If it doesn't pass, the restore is not complete —
continue the recovery, don't claim done.

### Step 5 — Close the recovery note

Root cause. Prevention rule (does it warrant a new entry in `01_LANES.md`
§2?). Links to follow-on tickets.

### Step 6 — Orchestrator review

The orchestrator (this Opus thread or another Claude thread holding the
chair) reads the recovery note and decides whether any contract changes are
needed. If a new forbidden pattern is identified, it gets added to
`01_LANES.md` §2 with the cost cited (date and damage).

## 6. The AGENT_SYNC.md channel — when to use it

`AGENT_SYNC.md` at repo root is for **real-time agent-to-agent coordination
inside the same lane.** It is not the receipt — the receipt is the vault note.

Use it when:
- Two agents discover they are about to edit the same tree.
- A recovery is in flight and a second agent is being pulled in.
- An agent needs to flag a discovery the orchestrator should see *now*, not
  on the next sweep.

Format:
```
## From Agent (<short-id>) - <HH:MM>
<message>
```

Append-only. Each block prefixed with the agent's short id (first 8 chars of
session id or any stable identifier the agent uses). The orchestrator clears
`AGENT_SYNC.md` after every sweep, archiving the cleared content into
`vault/40-agent-runs/sync_archive_<date>.md`.

## 7. Tooling forbidden in recovery

In a recovery session, do NOT use:

- `multi_replace_file_content` or any range-based bulk-edit tool until §1.1
  is satisfied for the specific file.
- Any tool that writes to a file the agent has not just read end-to-end.
- Any tool that operates on multiple files in one call without explicit
  per-file confirmation.

Use:

- `git checkout` from a known-good tag.
- Single-target `Edit` calls after a full `Read`.
- `Write` only for files the recovery agent itself created.

## 8. Post-incident review (orchestrator obligation)

Within 24h of any P0 or P1 recovery, the orchestrator:

1. Reads the recovery note.
2. Updates `01_LANES.md` §2 with any new forbidden pattern.
3. Updates `_Briefs/HANDOFF.md` so the next thread sees the lesson.
4. Verifies the gate (`02_VERIFICATION_GATES.md`) for the affected lane is
   still adequate, and tightens it if not.

This is non-negotiable. The cost of not doing it is a repeat incident.

---

*Authority: this document. Origin: 2026-06-28 hub corruption.
Companions: [[01_LANES]] (forbidden patterns), [[02_VERIFICATION_GATES]]
(restore-verified gate), [[04_AGENT_HANDOFF_TEMPLATE]] (receipt format),
[[07_GIT_GOVERNANCE]] (snapshot commands). Index: [[00_README]].*
