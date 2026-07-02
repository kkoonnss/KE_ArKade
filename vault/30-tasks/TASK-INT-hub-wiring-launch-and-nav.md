---
task_id: TASK-INT-hub-wiring-launch-and-nav
stage: 6
wave: 2
priority: P0
lane: hub
status: pending_kons_verify
owner_agent: antigravity
touches: [app/hub/main.gd]
locks_required: [hub-design]
depends_on: []
kind: fix
issued_by: opus_orchestrator
issued_at: 2026-07-01
severity: blocking
acceptance:
  - Clicking any game card launches its cart process AND the cart initializes past the gray Godot window (no 10s heartbeat-miss kill).
  - Log, Calibrate, Help, and Test Pattern buttons in the hub each do something (either the intended behavior or a clearly-labelled placeholder screen — no dead clicks).
  - IPC handshake completes end-to-end: cart connects to the hub's TCP port, hub receives the `ready` message, heartbeats flow.
  - Kons visual confirmation: launch pacman AND gta from the hub, both boot to actual gameplay, not gray.
---

## Objective

Two related hub bugs surfaced after the 2026-07-01 hub wiring pass:

1. **Every game launches to a gray window.** Cart process spawns but never
   initializes; hub eventually force-kills it after the 10s IPC-heartbeat
   timeout.
2. **Log, Calibrate, Help, and Test Pattern buttons do nothing.** Either
   unwired or wired to empty `pass` handlers.

Both live in `app/hub/main.gd`. Bundle into one hub-wiring pass.

## Root cause (verified 2026-07-01)

### Launch bug

`_launch_game` (main.gd ~line 225) builds args:

```
args_template = "--path \"" + cart_dir + "\" --scene \"" + scene_dir + "\" --level \"" + level_dir + "\""
```

**The `--ipc <socket>` arg is missing.** Every cartridge's launch-arg
parser expects `--ipc` and cannot initialize without it. Verified against
the canonical `content/cartridges/pacman/main.gd` (line 94) and
`content/cartridges/gta/main.gd` (line 151) — both scan for `--scene`,
`--level`, AND `--ipc`. Without `--ipc`, `ipc_port` stays 0, no socket is
opened, the hub never receives `ready`, and the launcher's 10s startup
timer kills the process.

Also: the IPC contract in `_Briefs/INTEGRATION_CONTRACT.md` §3 explicitly
lists `--scene <dir> --level <dir> --ipc <socket>` as the guaranteed
launch args. This ticket makes the hub actually honor that contract.

The launcher (`app/hub/launcher/launcher.gd`) already picks a free TCP
port at `_ready` (stored in `HubLauncher.port`) and exposes `launch()`
that takes an `args_template`. The template just needs to include an
`--ipc <socket>` placeholder that `HubLauncher.launch()` already knows
how to substitute (line 100: `.replace("<socket>", str(port))`).

### Nav-button dead clicks

Grep of `app/hub/main.gd`:
- Line 76: `CalibrateBtn.pressed.connect(_on_launch_calibration_tool)`
- Line 77: `TestPatternBtn.pressed.connect(_on_test_pattern_pressed)`
- Line 274: `func _on_launch_calibration_tool(): pass`
- Line 277: `func _on_test_pattern_pressed(): pass`

No handlers wired for `Log` or `Help` buttons — either they're not
present in the scene tree yet or the `.connect` calls are missing.

## Expected shape of the fix

### 1. Add `--ipc` to the args template

In `_launch_game`, append `--ipc <socket>` to `args_template`. Include a
leading `--` separator so Godot's engine doesn't try to consume our
app-level flags — carts already read both `get_cmdline_args()` AND
`get_cmdline_user_args()`, so either side of `--` works, but the
separator hardens against Godot's engine flag collisions in future
Godot versions.

Recommended template:

```
"--path \"" + cart_dir + "\" -- --scene \"" + scene_dir + "\" --level \"" + level_dir + "\" --ipc <socket>"
```

`HubLauncher.launch()` already replaces `<socket>` with the actual port.

### 2. Nav-button handlers

- `_on_launch_calibration_tool()` — either wire to the intended
  calibration screen OR pop a minimal "Coming soon" ColorRect overlay so
  the click has visible feedback.
- `_on_test_pattern_pressed()` — same treatment.
- `Log` button: check if `LogBtn` exists in `nav`; if yes, connect to
  a new `_on_log_pressed()` that shows the last N lines from the
  `ipc_log` signal (launcher already emits this — main.gd already has
  logic around it). Minimal viable: a modal ColorRect + Label showing
  the last log lines.
- `Help` button: check for `HelpBtn`; if yes, connect to a new
  `_on_help_pressed()` that shows a minimal help overlay (list of nav
  buttons + what each does). Not blocking on content depth — the point
  is the click DOES something.

If any of `LogBtn` / `HelpBtn` don't exist in `main.tscn`, that's a
scene-tree gap — add them or note it in the receipt as a follow-on
ticket, don't guess.

## Rules

- Write ONLY inside `app/hub/**`. Everything else read-only.
- Claim: set `owner_agent` + `status: in_progress`; lock note at
  `vault/35-locks/hub-design.md`.
- **Pre-edit git commit + tag** required (governance pack §1.2). main.gd
  is 1000+ lines and was the corruption site.
- Verify:
  1. `godot --headless --check app/hub/main.gd` parses.
  2. Launch hub, click a game card, screenshot the cart actually
     initializing past the gray window. Save to
     `vault/70-qa/<agent>_launch_gate_2026-07-01.png`.
  3. Click Log, Calibrate, Help, Test Pattern — each does something
     visible. Screenshot to
     `vault/70-qa/<agent>_nav_gate_2026-07-01.png`.
  4. Kons launch confirmation on both cases.
- Close with a receipt per `04_AGENT_HANDOFF_TEMPLATE.md`. Release lock.

## Cold-start reads (mandatory)

1. `_Briefs/governance/01_LANES.md`
2. `_Briefs/governance/02_VERIFICATION_GATES.md`
3. `_Briefs/governance/03_RECOVERY_PROTOCOL.md`
4. `_Briefs/governance/04_AGENT_HANDOFF_TEMPLATE.md`
5. This ticket.
6. `_Briefs/INTEGRATION_CONTRACT.md` §3 (the IPC contract you're honoring).
7. `content/cartridges/pacman/main.gd` (canonical cart-side arg parser).
