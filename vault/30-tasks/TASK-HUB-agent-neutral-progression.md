---
task_id: TASK-HUB-agent-neutral-progression
title: Hub agent-neutral progression and takeover ledger
stage: 6
wave: coordination
priority: P0
lane: vault
related_lane: hub
status: active
owner_agent: any
touches: [vault/30-tasks, vault/40-agent-runs, vault/60-bases]
locks_required: [vault-hub-coordination]
depends_on: []
kind: coordination
issued_by: kons_direct
issued_at: 2026-07-04
last_swept: 2026-07-04T00:46:40-07:00
---

# Hub Agent-Neutral Progression

This is the current short map for hub work. It exists so any capable agent can
take over without needing the original fleet identity. `owner_agent` means
"current or last holder", not permanent ownership.

## Transfer Rule

An incoming agent may take over a hub task when all of these are true:

- The task is not `done`.
- No active lock conflicts with the write set.
- The agent reads the latest receipt named by `closing_receipt` or the newest
  `vault/40-agent-runs/*hub*` note for the same scope.
- For `app/hub/main.gd` or other large hub files, the agent creates a fresh
  pre-edit commit and `pre-edit/hub/...` tag before editing.
- If a task is `pending_kons_verify`, the next action is verification first,
  not new implementation, unless Kons reports a failing behavior.

## Current Hub Sequence

| Order | Task | Status | Next action | Takeover posture |
|---:|---|---|---|---|
| 1 | `TASK-INT-hub-wiring-launch-and-nav` | `pending_kons_verify` | Kons visual: launch Pac-Man and GTA, confirm no gray window, confirm Log/Calibrate/Help/Test Pattern respond. | Verification-safe for any agent; code edit only if verification fails. |
| 2 | `TASK-INT-hub-classic-routing-data-driven` | `pending_kons_verify` | Kons visual: launch snake, breakout, qbert, dig_dug from hub and confirm classic levels route. | Verification-safe for any agent; code edit only if routing fails. |
| 3 | `TASK-INT-hub-scene-ordering-classic-first` | `pending_kons_verify` | Kons visual: Scenes tab shows Classic Pack first and remains stable after restart. | Verification-safe for any agent. |
| 4 | `TASK-INT-08-design-save-compile-derived` | `pending_kons_verify` | In Design, author/save a level, confirm `derived/grid.json`, then launch a game on it. | Verification-safe for any agent. |
| 5 | `TASK-INT-09-design-preset-selector` | `pending_kons_verify` | In Design, switch derive presets and confirm output changes. | Verification-safe for any agent. |
| 6 | `TASK-INT-10-design-live-preview` | `pending_kons_verify` | In Design, preview at least Pac-Man/Tetris/Galaga and confirm knob persistence. Include Codex derive-cancel smoke behavior. | Verification-safe for any agent. |
| 7 | `TASK-INT-hub-controller-ui-overhaul` | `in_progress` | Reconcile local untracked AG/Claude notes, then either finish or split into smaller child tickets. | Implementation requires `hub-design` lock and a fresh pre-edit snapshot. |
| 8 | `TASK-hub-shell-v1` | `ready` | Treat as legacy umbrella only; do not start before Stage 6 hub verification sweep. | Superseded-by-practice unless a missing shell feature is found. |

## Dirty Tree Boundary

Do not treat the entire dirty tree as one hub task. As of this sweep:

- Hub-specific modified files visible in status: `app/hub/design_screen.tscn`,
  `app/hub/main.tscn`, `app/hub/project.godot`.
- Hub coordination notes visible as local untracked files include
  `TASK-INT-hub-controller-ui-overhaul.md`,
  `antigravity_hub_controller_ui_overhaul_2026-07-03.md`,
  `claude_hub_classic_routing_continuation_2026-07-03.md`, and
  `claude_hub_ui_nav_and_buttons_2026-07-03.md`.
- Repo-wide dirty noise, cartridge files, shared files, and scratch scripts are
  not hub takeover work. Route those through a separate orchestrator
  housekeeping pass because they cross lanes.

## Clean Takeover Pattern

For a hub implementation task:

1. Claim `vault/35-locks/hub-design.md` or a narrower `hub-<purpose>` lock.
2. Read this note, the target task, and the newest matching receipt.
3. Run `git status --short -- app/hub vault/30-tasks vault/40-agent-runs`.
4. Make a pre-edit snapshot and tag before touching large hub files.
5. Stage only the files in the task write set.
6. Verify with Godot output plus any required Kons visual check.
7. Write a receipt, release the lock, and let the backup hook push.

For a verification-only hub task:

1. Do not edit code first.
2. Run the requested click-through or headless smoke.
3. If it passes, flip only the task status and receipt metadata.
4. If it fails, open or update a focused child task with the failing behavior.

## Major-Change Notification Rule

Agents should note Kons in their final response and in the receipt when they:

- Split a broad hub task into child tickets.
- Convert a `pending_kons_verify` ticket back to `in_progress`.
- Change the hub navigation model, launch contract, scene/level routing, or
  Design-screen authoring workflow.
- Decide to stage or discard any pre-existing untracked hub note or scene file.

Routine lock handoffs, receipts, and verification-only passes do not need a
special plan-change ping beyond the normal final summary.

## Immediate Recommendation

Next best hub move: run one hub verification pass covering orders 1 through 6.
If all pass, close those `pending_kons_verify` tickets together. Then split the
broad controller-overhaul ticket into smaller child tickets before further code
work, because it currently mixes navigation, card layout, thumbnails, scale,
and content cleanup in one large lock.
