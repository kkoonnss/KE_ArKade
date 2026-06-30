# KE_ArKade — Design System v1 (tokens)

The implementable layer under `design-brief.md`. Build agents skin the hub and
cartridges to these tokens. First visual pass lives at
`design/frames/arkade_design_v1.html` (open it). Refine in Claude Design; keep
this doc in sync as the lock.

## Foundations
- **Base:** pure black `#000000`. Projectors can't emit black, so black = "off" =
  free at a night festival. Design ON black.
- **Surfaces:** `#0A0A0A` (panel), `#111418` (raised), hairline borders only.
- **Contrast rule:** no mid-tones, no gradients-as-fills, no small text. Thin
  bright lines + saturated neon on black. Everything must survive ambient LEDs.

## Color tokens
| Token | Hex | Use |
|---|---|---|
| `ink/white` | `#FFFFFF` | structure, hairlines, primary text |
| `ink/dim` | `#9AA0A6` | secondary labels, inactive nav |
| `neon/cyan` | `#00E5FF` | play / active / path · primary accent |
| `neon/orange` | `#FF7A00` | hazard |
| `neon/green` | `#00E676` | spawn |
| `neon/magenta` | `#FF2EC4` | goal |
| `neon/yellow` | `#FFD400` | pickup |
| `surface/0` | `#000000` | arena + app background |
| `surface/1` | `#0A0A0A` | panels |
| `state/disabled` | `#3A3A3A` | ui_safe / disabled |

These map 1:1 to `semantic-palette-v1` `ui_color`s so games and UI share one
language. Neon is used semantically and sparingly — not as ambient glow.

## Type
- **Display / wordmark:** geometric sans, heavy weight, tight tracking. System
  stack: `"Space Grotesk", "Archivo", system-ui, sans-serif`.
- **Technical labels / HUD:** monospace (Blackmagic/TouchDesigner register).
  Stack: `ui-monospace, "SF Mono", "Consolas", monospace`, uppercase, `letter-spacing: .08em`.
- Scale (px): display 40 / 28 · h 20 / 16 · body 14 · label 12 / 11 (mono caps).

## The K (restraint)
The K is the brand signature but **this product is not about stamping the K
everywhere.** Running UI uses a clean, uniform `KE_ArKade` wordmark — no special
per-K treatment in the hub or games. When the K *is* featured, make it **bold and
edgy** (oversized, angular). Reserve that featured-K moment for a **splash / load
/ game-start screen** — parked as a Phase-end idea, not built now.

## Line & glow (punchier for festival)
- Hairlines 1px `ink/white` ~70% opacity; active edges 2px full neon.
- Glow is brighter than a subtle UI bloom so it survives ambient festival LEDs,
  but still **one controlled layer** — not "gamer RGB." Implementable target:
  a neon stroke + `drop-shadow(0 0 6–10px <neon> @ ~85%)`; key hero elements may
  add a second wider, lower-opacity pass (`0 0 18px @ ~25%`). Keep fine lines
  legible — never let bloom swallow the thin white structure or small detail.

## Motion
- **Panic Black:** instant cut to `#000` (0ms) — no animation, ever.
- Transitions: 120ms ease-out fades for panels; selection snaps, no bounce.
- Launch: quick neon wipe (≤200ms) then hand off to the cartridge.

## Grid / tile treatment (gridified games)
- Cells = thin `ink/white` 1px lattice on black.
- Filled cells (blocks, walls) = translucent neon fill (~18%) + 1px neon edge +
  one soft glow. Pickups/dots = solid neon discs with a tight glow.
- Player/agent tokens = bright neon outline shapes, never raster sprites.

## Layout principles
- The **Arena View is the hero** — largest object, centered, framed by a thin
  white rule. App chrome (nav, status) is quiet mono on black around it.
- Large touch targets (min 44px), generous spacing, very low density.

## Gameplay rendering rules (from the first engine pass)
The first real screenshots showed two concrete misses. These are now rules:
- **Reference photo is an authoring aid, not a play layer.** During play it is
  **off by default** (or dimmed to ≤15% if a game opts to show it). The neon
  semantic graphics — never a full-opacity gray photo — own the screen.
- **The arena fills the frame.** Scale/letterbox the semantic map to fill the
  projection surface; never render gameplay tiny in one corner.
- **Cool, cyan-led.** Cyan is the primary accent across hub and games; orange/
  magenta/green/yellow appear only where their semantic class does.
- Every game inherits the palette + grid/tile treatment above — a cartridge
  should look like it belongs to the same platform as the hub.
