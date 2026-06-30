# KE_ArKade — Design Brief v1

The reference every fleet designs against. Hub UI, cartridge art, and the arena
view all inherit from here. Owner of upkeep: Sonnet lane (propose changes via task note).

## Name & the K

Working name **KE_ArKade** — "arcade with a K." The **K is the brand signature**:
bold, slightly edgy, high contrast. Keep the K in the *name/logo*; do **not**
litter K-spellings or the logo K through the in-app UI. (Festival/platform brand
may surface as "Playa Projections" per source notes — keep that flexible.)

## Positioning

Outdoor/festival projection arena. Tone: **Nintendo × Blackmagic Design ×
Teenage Engineering × Burning Man.** Inventive, playful, technical, reliable,
modular, human. NOT: gamer-RGB, cyberpunk clichés, hacker/military UI, VJ-software.

## Core aesthetic

- **Black & white base.** Pure black backgrounds, thin bright **white lines** on
  high-contrast fields. Modernist wayfinding, not decoration.
- **Poppy neon accents** — saturated, high-luminance. Used sparingly and
  semantically (see palette), not as ambient glow.
- Large geometry, very low clutter, touch-friendly for outdoor night use. The
  **Arena View is the hero object**, never the projector.

## Projection reality (this drives the whole look)

Projectors are additive light — **they cannot project black; black = darkness.**
Design *on* black: pure-black backgrounds are "free" and ideal at a night
festival. Consequences the art must respect:
- **Boost contrast hard.** Subtle mid-tones and gradients wash out against
  ambient light and competing LEDs — avoid them.
- **Saturated neon at high brightness survives** ambient LED competition; muddy
  or pastel colors die. Keep colors pure.
- **Thin bright lines on black read crisply** when projected and keystoned;
  fine detail and small text do not — keep elements large.
- Assume the surface isn't white and the room isn't dark-controlled.

## Color = gameplay (from semantic palette v1 `ui_color`)

Cyan = play/active · Orange = hazard · Green = spawn · Magenta = goal ·
Yellow = pickup · White = solid/structure/lines · Gray = disabled. These are not
chosen to look cool — every game inherits them so meaning is consistent across
the whole platform.

## Logo directions (explore, nothing locked)

Arena grid · projection volume (light defining space) · semantic zone (a shape
broken into meaning-regions). **Avoid:** fire/flames, Burning Man clichés,
literal projectors — they're limiting.

## Do-not list

Gamer RGB overload · cyberpunk neon-noir · low-contrast/pastel palettes that
die under projection · busy gradients · small text · clutter competing with the
arena · the brand K stamped all over the UI.
