---
title: GitHub Backup and Restore
type: architecture
status: active
project: KE_ArKade
tags: [backup, github, git, restore, governance]
last_verified: 2026-07-03
backup_status: remote-configured-unpushed
repo_url: https://github.com/kkoonnss/KE_ArKade.git
local_path: C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade
---

# GitHub Backup and Restore

KE_ArKade has a GitHub remote configured at `https://github.com/kkoonnss/KE_ArKade.git`, but the project is not fully backed up until local commits and reviewed working-tree changes are pushed.

See the project-local runbook: [[../../BACKUP|BACKUP]]

## Current status

- Git repo: valid
- Remote: `origin`
- Branch: `master`
- Tracking: `master` tracks `origin/master`
- Current audit result: `remote-configured-unpushed`
- Local commits: `master` is ahead of `origin/master` by 5 commits
- Working tree: dirty; review before commit/push
- Restore test: not yet run after current push state

## Obsidian tracking

- Active infra task: [[../30-tasks/TASK-INFRA-github-remote-and-backup]]
- Backup dashboard: [[../60-bases/backups.base]]
- Latest Codex visibility receipt: [[../40-agent-runs/codex_backup_visibility_2026-07-03]]

## Agent rules

- Do not push without Kons approval.
- Do not force-push or rewrite history unless Kons explicitly confirms.
- Do not describe the project as fully backed up while `git status --short --branch` shows `ahead`, modified files, or untracked files that should be saved.
- Keep the project-local `BACKUP.md` readable for a human who is not using an agent.
- Treat ignored Godot binaries as local install dependencies, not backed-up source.

## Health check

```powershell
git rev-parse --show-toplevel
git remote -v
git status --short --branch
git branch -vv
```

Healthy target:

- `origin` points to the expected GitHub URL.
- `master` tracks `origin/master`.
- No unreviewed dirty or untracked work remains.
- No unpushed local commits remain.
- A fresh clone restore test has passed.
