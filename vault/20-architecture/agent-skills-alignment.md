---
title: Agent Skills Alignment — GitHub + Obsidian
type: architecture
status: active
project: KE_ArKade
tags: [governance, skills, github, obsidian, agent-alignment]
last_verified: 2026-07-03
---

# Agent Skills Alignment — GitHub + Obsidian

Cross-check of what each agent fleet actually uses to do GitHub-backup work and
Obsidian-vault work in this repo, so receipts from different fleets describe
the same underlying actions instead of drifting into fleet-specific jargon.
Triggered by a Kons request to confirm Claude/Sonnet threads are aligned with
Codex on this.

## GitHub / git backup work

**Codex's receipts** (e.g. `codex_backup_visibility_2026-07-03.md`) list
`skills_used: [project-github-backup, ...]`. There is no tool or skill named
`project-github-backup` on the Claude/Sonnet side — Codex appears to be naming
its own internal convention/prompt-pattern, not a portable skill id. Nothing to
fix here, just don't expect that name to mean anything outside a Codex receipt.

**What actually happens on both sides** is the same thing described in
`_Briefs/governance/07_GIT_GOVERNANCE.md`: plain `git` CLI commands (status,
add, commit, tag, push) run against the local repo, following the commit-message
format in §2.1 and the snapshot cadence in §2.2. Claude/Sonnet threads run these
via shell access; Codex runs them via its own shell. Same commands, same
governance doc, different execution environment — this is already aligned.

**One gap worth knowing about:** an `engineering:github` MCP connector is
available to Claude/Sonnet Cowork threads but was still connecting (not yet
authorized/loaded) as of this session. It would give API-backed GitHub
operations (PRs, issues, branch protection checks) instead of raw git CLI —
useful for the still-open branch-protection verification step in
`TASK-INFRA-github-remote-and-backup`. Not wired in yet; raw git CLI remains
the working path for both fleets today.

See also: [[github-backup-and-restore]], [[../80-builds/github-backup-runbook]].

## Obsidian vault work

**Codex's receipts** list `skills_used: [obsidian-markdown, obsidian-bases]`.
Claude/Sonnet has skills with those exact names available (`obsidian-markdown`,
`obsidian-bases`) — direct match, already aligned. Both fleets write vault notes
as plain YAML-frontmatter Markdown (`title`/`type`/`status`/`tags`) and use
`.base` files under `vault/60-bases/` for dashboard-style views (e.g.
`backups.base`).

**One thing NOT to reach for in this repo:** the `obsidian-tags` skill on the
Claude/Sonnet side is scoped specifically to the Million Dollar HQ vault's
frontmatter/tag conventions (`Documents\Claude\Million Dollar HQ`), not
KE_ArKade. This vault has its own lighter frontmatter convention already in
use throughout `vault/20-architecture/`, `vault/30-tasks/`, etc. — follow the
pattern in existing files (see this file's own frontmatter) rather than the
MDHQ tag taxonomy.

## Net assessment

GitHub and Obsidian conventions are already aligned across fleets in practice —
same commands, same skill names, same governance docs. The only drift is
label-level (`project-github-backup` isn't a real cross-fleet skill name), which
doesn't block anything. No action required beyond this note existing as a
reference for future receipts.
