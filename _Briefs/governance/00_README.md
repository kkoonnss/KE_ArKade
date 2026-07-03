---
doc_id: governance-00-readme
audience: [orchestrators, codex, antigravity, sonnet, claude_threads, kons]
authority: index
last_revised: 2026-06-30
---

# KE_ArKade Governance Pack — Index

**This pack is the contract every agent and orchestrator reads on cold-start.**

It exists because the Jun 28-30 2026 hub corruption + silent 3-day recovery
exposed a real gap: the discipline system held on the happy path, then broke
the moment things went sideways. The pack closes that gap. It is the rules
of the road for everyone working on this project — Kons, the Opus
orchestrator, any other Claude thread holding the chair, Codex, Antigravity,
Sonnet.

If you are reading this for the first time, read the pack in the order below.
If you are an orchestrator picking up the chair, also read
`_Briefs/HANDOFF.md` first.

---

## The pack

| # | Document | What it answers | Required for |
|---|---|---|---|
| 00 | [[00_README]] | "What is this pack? What do I read first?" | everyone, on cold start |
| 01 | [[01_LANES]] | "Where am I allowed to write? What are the forbidden patterns?" | every agent before first edit |
| 02 | [[02_VERIFICATION_GATES]] | "What does 'done' actually mean for my lane?" | every agent before close |
| 03 | [[03_RECOVERY_PROTOCOL]] | "How do I avoid corruption? What do I do if it happens anyway?" | every agent, every session |
| 04 | [[04_AGENT_HANDOFF_TEMPLATE]] | "How do I write the receipt the next holder needs?" | every agent at session end |
| 05 | [[05_ORCHESTRATOR_RUNBOOK]] | "How do I hold the orchestrator chair? Cold start, sweep, dispatch, handoff." | orchestrators |
| 06 | [[06_VAULT_HYGIENE]] | "What keeps the vault honest? What are the tracked hygiene failures?" | orchestrators (and all agents indirectly) |
| 07 | [[07_GIT_GOVERNANCE]] | "How is git used as backup + time machine? How do commits, GitHub pushes, LFS, and recovery work?" | every agent before close, orchestrators for tags/backups |
| 08 | [[08_NEW_SESSION_SEED]] | "How does Kons start a fresh Opus thread in one paste?" | Kons + incoming orchestrators |

---

## Read order by role

### A new Claude thread inheriting the orchestrator chair

1. `_Briefs/HANDOFF.md` (the previous orchestrator's parting note)
2. This file (`00_README.md`)
3. `01_LANES.md`
4. `02_VERIFICATION_GATES.md`
5. `03_RECOVERY_PROTOCOL.md`
6. `05_ORCHESTRATOR_RUNBOOK.md`
7. `06_VAULT_HYGIENE.md`
8. `07_GIT_GOVERNANCE.md`
9. Current `_Briefs/PLAN_*.md` directive

Then run cold-start protocol (`05_ORCHESTRATOR_RUNBOOK.md` §1).

### A build agent (Codex, Antigravity, Sonnet, any Claude sub-agent)

1. This file (`00_README.md`)
2. `01_LANES.md`
3. `02_VERIFICATION_GATES.md`
4. `03_RECOVERY_PROTOCOL.md`
5. `04_AGENT_HANDOFF_TEMPLATE.md`
6. `07_GIT_GOVERNANCE.md`
7. The ticket assigned to you in `vault/30-tasks/`
8. Any prior handoff for the same lock in `vault/40-agent-runs/`

### Kons (the human)

You don't need to memorize the pack. Use it as a reference when:

- You want to know what an agent *should* have done that it didn't.
- You want to onboard a new agent or fleet to the project.
- You want to verify the orchestrator is doing its job.
- You want to change a rule (open a ticket, escalate to the orchestrator,
  same as any contract change).

---

## The non-negotiables (one-page summary)

If you read nothing else in this pack, internalize these.

0. **GitHub backup is part of close.** Every closing receipt records whether
   `origin` push succeeded, failed, or is pending (`07_GIT_GOVERNANCE.md`).
1. **Lanes are disjoint.** One folder = one writer. Cross-lane work routes
   through the orchestrator.
2. **`vault/50-schemas/` is frozen.** Only the orchestrator edits.
3. **No `multi_replace_file_content`** without the sanity check
   (`03_RECOVERY_PROTOCOL.md` §1.1). This is the trap that cost us 3 days.
4. **No global `class_name` reach** across separate Godot projects. Use
   `SharedLoader`. Canonical model: `content/cartridges/gta/main.gd`.
5. **"Done" = real output.** Pass your lane's gate
   (`02_VERIFICATION_GATES.md`) before flipping the status.
6. **Every session writes a handoff** (`04_AGENT_HANDOFF_TEMPLATE.md`).
   Including — especially — recovery sessions.
7. **Pre-edit snapshot before any edit to a file > 200 lines**
   (`03_RECOVERY_PROTOCOL.md` §1.2). One `git commit`, one `git tag`. Cheap.
8. **Release your lock when you close** (`04_AGENT_HANDOFF_TEMPLATE.md` §5).
9. **Recovery scripts live in `scratch/recovery-<date>/`**, never repo root
   (`03_RECOVERY_PROTOCOL.md` §4.5).
10. **Six parallel cart agents is the design target**, not the exception
    (`01_LANES.md` §2b). The system is built for it.

---

## What's NOT in this pack (and where it lives)

- The Stage 6 directive (what we're actually building right now):
  `_Briefs/PLAN_interpretation-and-editor.md`.
- The current session pickup state: `_Briefs/HANDOFF.md`.
- Cartridge dispatch prompt template: `_Briefs/DISPATCH.md`.
- The board (live ticket view): `vault/60-bases/interpretation.base`.
- The architecture docs (durable design): `vault/20-architecture/`.
- Schemas (data contracts): `vault/50-schemas/`.

The governance pack is the **how**. Those are the **what**.

---

## Versioning

This pack is at v1, established 2026-06-30. Changes are tracked in
git + the `last_revised` frontmatter on each file. The orchestrator
maintains it; agents propose changes via tickets.

A major bump (v2) happens if a non-negotiable changes. Otherwise, edits
are additive within v1.x.

---

*Pack location: `_Briefs/governance/`. Maintained by the orchestrator.
Origin: 2026-06-28 hub corruption + the realization that the discipline
system needed to be the recovery protocol, not just the happy path.*
