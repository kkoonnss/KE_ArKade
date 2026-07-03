---
task_id: TASK-INFRA-github-remote-and-backup
stage: 6
wave: infra
priority: P0
lane: tools
status: in_progress
owner_agent: codex
touches: [".gitignore", "_Briefs/governance/07_GIT_GOVERNANCE.md", "_Briefs/governance/scripts/**"]
locks_required: [tools-github-integration]
depends_on: []
kind: infra
issued_by: opus_orchestrator
issued_at: 2026-07-01
severity: blocking
acceptance:
  - GitHub private repo created and linked as `origin` remote.
  - Full history (all commits + all tags including pre-edit/*, daily/*, week/*) pushed successfully.
  - Branch protection rules configured on `master`: linear history, no force-push, immutable tags.
  - A push-cadence script exists at `_Briefs/governance/scripts/push_backup.cmd` that Kons can run manually; also a git post-commit hook that pushes automatically after every ticket-close commit.
  - `_Briefs/governance/07_GIT_GOVERNANCE.md` §7 updated with the actual remote URL, push cadence, branch protection rules, and recovery instructions (clone fresh + check out daily/<date>).
  - README addition or install-step doc: how to clone the repo fresh and end up with a working checkout (given that the large Godot binaries at repo root are gitignored per 07_GIT_GOVERNANCE.md §5).
---

## Objective

**Prevent code loss.** The Jun 28-30 corruption event and every subsequent recovery have relied on local `.git` only. If Kons's disk fails, the machine gets wiped, or another agent runs a destructive delete before the pre-commit hook is in place, everything is gone.

Set up a GitHub remote as the offsite backup, wire the push cadence into the existing governance snapshot pattern, and document the recovery-from-remote story.

## Constraints and design

**Private repo.** This is Kons's personal build. Do NOT create it public.

**Kons's identity.** He'll create the empty repo on GitHub himself and give you the remote URL. Your job is to wire everything up on his machine and verify the push path works end-to-end.

**Godot binaries.** `Godot_v4.3-stable_win64.exe` (133 MB) and `godot.zip` (57 MB) are currently in the repo. GitHub's file limit is 100 MB per file, and repo-size warnings kick in at 1 GB. The `.gitignore` at `_Briefs/governance/07_GIT_GOVERNANCE.md` §5 already flags these but they haven't been removed from history yet.

Decision: use `git lfs` OR replace with a documented install step. Recommendation: install step. The install step becomes part of the README so `git clone` + one command gets a working checkout.

**Push cadence** (see `_Briefs/governance/03_RECOVERY_PROTOCOL.md` §2 + `07_GIT_GOVERNANCE.md` §2.2):

- After every ticket-close commit → push to origin.
- Daily tag → push tag.
- Weekly tag → push tag.

Post-commit git hook is the least-effort way to get this automatic.

## Deliverables

1. **`_Briefs/governance/scripts/push_backup.cmd`** — one-shot script that pushes master + all tags. Handles connection failures gracefully.

2. **`.git/hooks/post-commit`** shell script that runs `push_backup.cmd` in background so it doesn't block the commit. If the network is down, the local commit still succeeds; the next successful push catches up.

3. **`_Briefs/governance/07_GIT_GOVERNANCE.md` §7 rewrite** with:
   - Actual remote URL (Kons will provide).
   - Push cadence (documented above).
   - Branch protection rules (linear history on master, no force-push, tags immutable).
   - Recovery-from-remote runbook: `git clone <url>`, `git checkout daily/<last-good-date>`, run install step.

4. **`README.md` install step** (or a new `INSTALL.md`) documenting how a fresh clone becomes a working checkout on Windows. Should cover the Godot exe (via install step or lfs), and note that `Documents/_KE_VibeApps/KE_ArKade` is the expected local path.

5. **History-cleanup consideration** (optional, only if repo pushes fail on file size): `git lfs migrate import --include="*.exe,*.zip"` to retroactively move binaries into LFS. Kons's call — the alternative is accepting the current repo size.

## Rules

- Write ONLY inside `.gitignore`, `.git/hooks/`, `_Briefs/governance/**`, `README.md` (or new `INSTALL.md`). Do NOT edit anything in `app/`, `content/`, or `vault/50-schemas/`.
- Claim: set `owner_agent` + `status: in_progress`; lock note at `vault/35-locks/tools-github-integration.md`.
- **No pre-edit git commit required** for this ticket because no >200-line files are being touched. If you do end up touching one (e.g. `07_GIT_GOVERNANCE.md` grows), snapshot per `03_RECOVERY_PROTOCOL.md` §1.2.
- Verify:
  1. `git remote -v` shows `origin` with the correct URL.
  2. `git push origin master` succeeds.
  3. `git push origin --tags` succeeds.
  4. Both are visible on the GitHub web UI.
  5. Branch protection rules visible on GitHub Settings → Branches.
  6. A fresh clone into a scratch directory produces a working repo per the install step in the README.
- Close with a receipt per `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`. Release the lock.

## Cold-start reads (mandatory)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. `_Briefs/governance/07_GIT_GOVERNANCE.md` (existing conventions you're extending)
6. This ticket.
