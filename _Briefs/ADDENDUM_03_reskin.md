# ADDENDUM 03 — Visual re-skin to the locked design system

**You are the executing fleet (Antigravity by capacity; agent-agnostic).** The
build works; now make it *look* like KE_ArKade. Skin the hub + the two MVP games
to the locked spec. This is a visual pass — no new features, no schema changes.

**Read first:** `vault/20-architecture/design-system.md` (the contract — tokens,
glow, gameplay rendering rules) and `vault/20-architecture/design-brief.md`.
**North-star reference:** open `design/frames/arkade_design_v1.html` — match its
language (black base, thin white structure, cool cyan-led neon, mono labels).

## Locked look calls (apply these)
- **Glow:** punchier for festival — neon stroke + `drop-shadow(0 0 6–10px)`, hero
  elements a second wide low-opacity pass. One controlled look, not gamer-RGB;
  never let bloom swallow thin lines.
- **Temperature:** cool, **cyan-led**. Cyan is the primary accent; other neons
  only where their semantic class appears.
- **The K:** clean uniform `KE_ArKade` wordmark in running UI — **do not** stamp
  the K through the UI. (A featured bold-K splash/start screen is parked for later.)

## Fix the two concrete misses from the first screenshots
- **Lumen Maze** (worst offender): the climbing-wall reference photo is shown at
  full opacity and the playfield sits tiny in a corner. Fix: **reference off (or
  ≤15%) during play**, **arena fills the frame**, render corridors/walls/pickups
  in the neon palette with glow — not dim navy on gray.
- **Neon Stack** (already close): keep the black field, white grid lattice, and
  thin-white well; push blocks to translucent neon + glow per the tile rule; make
  the well fill more of the frame.

## Apply across the hub too
Hub chrome to the spec: black, quiet mono nav, the Arena View as the hero filling
its panel with neon semantic zones, the cartridge picker clean and centered with
homage names.

## Capture & compare
Re-screenshot the hub + both games and place them in `vault/70-qa/` (overwrite the
prior runs). In `vault/80-builds/BUILD_REPORT.md`, put the new shots **next to**
the north-star mockup frames and note remaining gaps. Then signal for Opus review —
we'll iterate on the real engine output, not mockups.

## Scope guard
Two MVP games + hub only. Leave the three stub cartridges unstyled for now.
