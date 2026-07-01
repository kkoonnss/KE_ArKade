---
doc_id: governance-02-verification-gates
audience: [orchestrators, codex, antigravity, sonnet, claude_threads]
authority: contract
last_revised: 2026-06-30
---

# 02 — Verification Gates ("done" = real output)

**The #1 rule of this project, learned the hard way:**

> A ticket marked `done` is NOT proof. Agents have repeatedly marked tickets
> done without compiling, launching, or producing output. Before any "done"
> claim is accepted by the orchestrator or cascaded into dependent work, it
> must pass a gate that produces real, observable evidence.

This document defines the gate per lane. No ticket closes without its gate.
No orchestrator releases a lock or flips a status without the gate's evidence
in the receipt.

---

## 1. Universal close-out gate (every lane)

Every ticket, every lane, before `status: done`:

1. **Real-output evidence** in `vault/40-agent-runs/<agent>_<topic>_<date>.md`:
   - Command(s) run, with stdout/stderr captured.
   - Path(s) to any artifact produced (screenshot, log, derived file).
   - For visual work: at least one screenshot path under `vault/70-qa/`.
2. **Gate-specific grep results** pasted into the receipt (see lane gates below).
3. **Lock released:** the lock file under `vault/35-locks/` is deleted by the
   closing agent.
4. **Ticket frontmatter flipped:** `status: done`, `closed_at: <ISO timestamp>`,
   `closing_receipt: vault/40-agent-runs/<filename>.md`.
5. **OPEN_QUESTIONS triaged:** if the ticket surfaced any unresolved decisions,
   they are appended (not rewritten) into
   `vault/40-agent-runs/OPEN_QUESTIONS.md` under the relevant section.

A ticket that meets steps 1–3 but not 4–5 is **not done** — it's pending close.
The orchestrator does not cascade from it.

## 2. Cartridge gate (lane: `cartridge`)

Every cartridge must pass all five before close:

1. `grep -E "SharedLoader" content/cartridges/<game>/` → **non-empty**.
2. `grep -E "Adapter\.new\(\)|TabMenu\.new\(\)" content/cartridges/<game>/` →
   **empty**.
3. `ls content/cartridges/<game>/adapter_base.gd` → **does not exist** (no
   copied shared files).
4. Cart launches without flash-loop or parse error. Captured log path in
   receipt.
5. **Kons launch confirmation** (visual check): reads the map, Tab menu opens,
   game plays, never boots empty. Kons posts confirmation in the receipt or
   in `_Briefs/HANDOFF.md`.

Steps 1–4 the agent can verify itself. Step 5 requires Kons because
**the orchestrator cannot launch Godot.**

## 3. Hub gate (lane: `hub`)

Every hub change before close:

1. `app/hub/main.gd` parses (no `Parse Error` in `godot --headless --check`).
2. Hub boots to the main screen without grey-screen. Captured screenshot path
   in receipt.
3. The specific feature changed in this ticket demonstrably works (e.g.
   thumbnails load, favorites persist, design screen saves derived).
4. **Kons launch confirmation** for any visual or interactive change.
5. **Pre-edit snapshot exists:** the closing receipt names the git commit hash
   that captured pre-edit state (see `03_RECOVERY_PROTOCOL.md` §2.1). For
   hub edits this is mandatory because the corruption event hit here.

## 4. Tools gate (lane: `tools`)

Every tools change before close:

1. **Golden tests green** from a clean checkout. Receipt names the test
   command and pastes the pass count.
2. **Real run on real data:** the tool executes against at least one live
   level (or scene/cartridge as applicable) end-to-end. Output path in
   receipt.
3. No new dependencies introduced without a note in
   `vault/40-agent-runs/OPEN_QUESTIONS.md` for orchestrator review.

## 5. Shared gate (lane: `shared`)

Every `app/shared/**` change before close:

1. Each consumer (hub + every dependent cartridge) is grep-checked to confirm
   it still resolves the contract (`SharedLoader.load_*` calls succeed).
2. The change is **additive** by default. A breaking change requires an
   orchestrator escalation (see `01_LANES.md` §4).
3. After close, `app/shared/**` is **frozen**: subsequent change tickets must
   route through the orchestrator like schema changes.

## 6. Schema gate (lane: `schemas`)

Orchestrator-only edits.

1. Backward-compatible (additive within v1.x) unless a v2 bump is explicit
   in the ticket title.
2. `app/shared/**` regenerated from the YAML (palette class IDs + colors as
   GDScript const + Python module) in the same commit.
3. Every consumer audited and any required follow-on tickets opened.

## 7. Governance gate (lane: `governance`)

Orchestrator-only edits to `_Briefs/governance/**`, `_Briefs/HANDOFF.md`,
`_Briefs/PLAN_*.md`.

1. The doc says what supersedes what (the `supersedes` field in frontmatter).
2. Cross-references via Obsidian wiki-links are valid (`[[doc_id]]` resolves).
3. The change is summarized in `_Briefs/HANDOFF.md` so the next orchestrator
   thread sees it on cold-start.

## 8. The "I cannot verify this" escape

If an agent **cannot** complete its lane's gate (e.g. the cart parses but the
agent has no way to launch Godot to confirm visual playability), it does NOT
mark the ticket `done`. It marks it `pending_kons_verify`, names exactly what
needs visual confirmation in the receipt, and releases the lock. The
orchestrator picks it up on the next sweep, requests the launch from Kons,
and flips the status when confirmation lands.

`pending_kons_verify` is a real status. It is the honest answer.

## 9. Orchestrator verification cadence

After every batch of returned tickets:

1. Orchestrator runs the gate grep for every claimed-done cartridge.
2. Orchestrator confirms the lock is released and the receipt exists.
3. Orchestrator pings Kons with a single launch list (multiple games in one
   ask, not one ping per game) for visual confirmations needed.
4. Only after launch confirmation does the orchestrator flip `status: done`
   and unblock dependents.

This is what "the orchestrator holds the chair" means in practice.

---

*Authority: this document. Companions: [[01_LANES]] (where work happens),
[[03_RECOVERY_PROTOCOL]] (what to do when a gate fails),
[[04_AGENT_HANDOFF_TEMPLATE]] (the receipt format). Index: [[00_README]].*
