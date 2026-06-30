# ADDENDUM 04 — Re-skin pass 2 (kill the gray, bring the neon)

**You are the executing fleet (Antigravity by capacity; agent-agnostic).** Pass 1
improved structure but missed the headline rule: both games still read **gray and
muddy**, not black and neon. The fresh screenshots show the reference photo still
dominating (Lumen Maze ~50%, and inside the Neon Stack well), and the neon under-
saturated. Verify against the captured pixels this time, not the code parameter.

**Read:** `vault/20-architecture/design-system.md` → "Gameplay rendering rules".
**Compare to:** `design/frames/arkade_design_v1.html` (the north star).

## The root fix: black is the play background
The game is **projected onto the physical wall.** In play, the engine background
must be **pure `#000000`, edge to edge** — on the real wall, black = no light, so
the wall itself becomes the backdrop and only the neon projects. Therefore:
- **Reference photo OFF by default in play** for both games. Move it to an
  optional "preview on surface" toggle that is **off** unless explicitly enabled.
  Do not render it as the play background at 15% or any value by default.
- Confirm in the actual screenshot that the background is solid black with no
  photo and no climbing-hold color bleed.

## Lumen Maze
- Black background, photo off. Walls: stop rendering the gray blocky cell mass —
  render corridors/walls as **clean thin neon line-work** (cyan paths, crisp
  white/edge walls) so it reads as neon vector art on black, like the mockup.
- Player cyan, pickups yellow, all with the punchier festival glow.

## Neon Stack
- Black **inside** the well too (no photo). Keep the white grid lattice + cyan
  well outline (those are good).
- Settled and falling blocks: **saturated translucent neon (~18% fill) + 1px neon
  edge + glow** per the tile rule — not dark gray. Each piece reads as its color.

## Verify by eye, then capture
Bump reference `visible=false` and raise neon alpha/glow until the **capture**
matches the north star. Regenerate the 5 screenshots in `vault/70-qa/`, update the
comparison table in `vault/80-builds/BUILD_REPORT.md`, and signal for Opus review.

## Scope guard
Visual fidelity only — 2 games + hub. No new features, no schema changes, stubs untouched.
