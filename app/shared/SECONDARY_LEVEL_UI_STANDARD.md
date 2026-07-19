# Secondary Level UI Standard

This standard defines the shared Tab-menu interface for live, per-level map
tuning inside cartridges.

Goal: different games can expose different knobs, but the interface should
feel like the same projection-mapping instrument.

## Core Intent

- The menu is for live level interpretation, not general game options.
- Visual/source inspection comes first because the builder is usually checking
  how a physical scene, semantic map, secondary layer, or collision view is
  being read.
- Every control should visibly affect how the current level is read, fit,
  previewed, or played.
- Changes should apply immediately when possible.
- A player or builder should be able to move from one game to another and
  recognize the menu structure.

## Required Group Order

When a cartridge exposes secondary level controls, use these groups in this
order:

1. `Preview`
2. `Secondary`
3. `Collision`
4. `Gameplay`
5. `Actions`
6. `General`

`TabMenu` renders groups in this canonical order even when cartridges register
knobs in a different order.

Compatibility aliases:

- `Map` renders as `Secondary`.
- `Level` renders as `Secondary`.
- `General` is supported but always renders last.

Do not invent a different top-level order unless the cartridge has a strong
game-specific reason. New knobs should use an explicit standard group; avoid
`General` unless the control is temporary and still being classified.

## Group Responsibilities

### Preview

Purpose: help the player understand what source data is being interpreted.

Preferred controls:

- `Background View`
  - Typical values: `final`, `photo`, `semantic`, `secondary`, `collision`
- `Background Layer`
  - Toggles the reference image layer on/off
- `Background Opacity`
  - Controls how visible the source/reference image is
- `Secondary Photo Mix`
  - Blends faint source photo under the secondary view
- `Scale Grid Overlay`
  - Toggles the neutral gray measuring grid

Rules:

- Put this group first because most projection-mapping tuning begins by
  checking alignment, source visibility, and visual interpretation.
- `Scale Grid Overlay` is not gameplay collision by itself. It is a visual
  ruler for proportion, spacing, and alignment across views.
- Default `Scale Grid Overlay` on for map-fitting games where scale tuning
  matters; default it off for games where it adds clutter and no alignment
  value.

### Secondary

Purpose: tune the second interpretation layer that sits between source map and
final gameplay.

Common control families:

- Strength
  - `Secondary Strength`
- Coverage
  - `Secondary Fill`
  - `Secondary Lanes`
  - `Secondary Outline`
- Transform
  - `Secondary Offset X/Y`
  - `Secondary Rotation`
  - `Secondary Scale`
- Filtering
  - `Threshold`
  - `Noise Cleanup`
  - `Island Minimum`
- Shape style
  - `Outline`
  - `Rounding`
  - `Organic Merge`

Rules:

- Use this group for controls that reshape the interpreted map before final
  collision/gameplay consumption.
- Secondary controls should modify an in-memory interpretation or a per-level
  edit artifact, not the original `semantic_map.png`.
- The live preview should always make the effect legible.
- If a game only has one or two meaningful secondary knobs, still keep them in
  this group.

### Collision

Purpose: define the playable/blocked interpretation of the map.

Common controls:

- `Collision Mode`
  - Example values: `grid`, `organic`
- `Grid Resolution`
  - Coarser/finer interpretation of the map-derived grid
- `Grid Expand`
  - Positive expands blocked grid regions, negative shrinks them
- `Lane Expand`
  - Positive expands lane-derived areas, negative shrinks them
- `Invert Grid`
- `Invert Lanes`
- `Organic Boundary`
- `Organic Rounding`
- `Bounds Clamp`
- `Central Block` or other named local exclusion controls

Rules:

- If a control changes collision, it belongs here even if it also affects
  visuals.
- Prefer nouns the player can understand over implementation names.
- Use `Expand` instead of `Dilate`, `Shrink`, or morphology terminology.
- Negative `Expand` is allowed and should behave predictably.

### Gameplay

Purpose: expose the small set of play-feel controls needed to make the
interpreted level actually work.

Examples:

- `Players`
- `Ship Scale`
- `Movement Scale`
- `Jump Height`
- `Spawn Spacing`
- `Enemy Density`

Rules:

- Keep this group short.
- Only include gameplay knobs tightly coupled to level fit, readability, or
  map adaptation.
- Broad difficulty settings belong elsewhere unless they are needed to tune a
  projection-mapped level.

### Actions

Purpose: explicit commands, not continuous tuning.

Examples:

- `Start Game`
- `Back to Hub`
- `Back`
- `Reset Secondary`
- `Save Level Edit`
- `Reload Level`
- `Restore Defaults`

Rules:

- `TabMenu` renders built-in settings buttons inside this group.
- Actions should be clearly separate from sliders and toggles.
- Destructive actions should be rare and plainly named.

### General

Purpose: fallback only.

Rules:

- Existing cartridges with older knobs can keep working with `General`.
- New work should classify controls into the standard groups.
- `General` always renders last so projection-mapping controls stay
  discoverable first.

## Interaction Rules

- Mouse, keyboard, and controller should all work.
- Sliders must update live.
- Sliders must ignore mouse-wheel changes while scrolling the menu.
- Groups are collapsible.
- Groups default collapsed the first time a cartridge/level has no saved
  layout state.
- Collapsed/expanded state persists per cartridge and per level.

Persisted layout state lives next to the existing settings in the adjustment
JSON:

```json
{
  "settings": {},
  "ui_state": {
    "version": "tab_menu_layout_v1",
    "collapsed_groups": {
      "Preview": true,
      "Secondary": false
    }
  }
}
```

Rules:

- Save collapsed/expanded state immediately when a group header is toggled.
- Preserve existing `settings` values and unknown JSON fields.
- V1 caches group layout only. Do not persist scroll position or last focus
  until there is a concrete need.

## Visual Rules

- Use the shared Tab menu shell.
- Keep section headers yellow and clearly clickable.
- Keep controls vertically stacked and left-aligned.
- The menu should read like a technical instrument, not a marketing panel.

## Naming Rules

- Use title case labels.
- Prefer plain words over engine words.
- Recommended wording:
  - `Background`, not `Source Raster`
  - `Scale Grid Overlay`, not `Debug Grid`
  - `Expand`, not `Dilate`
  - `Invert`, not `Boolean Not`
  - `Collision`, not `Mask Logic`

## Persistence Rules

- Per-level secondary edits should be storable separately from source assets.
- Do not overwrite `semantic_map.png` or `background.png`.
- If a cartridge persists secondary edits, store them as a per-level artifact
  local to that level.
- `ui_state` is a layout cache, not gameplay data. It should never affect the
  interpreted level.

## Current Audit

Closest to the standard:

- Asteroids
- Paperboy
- Tetris

Needs group/order cleanup but already uses shared `TabMenu`:

- Pac-Man
- Rampage
- Donkey Kong

Shared `TabMenu` but mostly still `General`:

- Frogger
- Galaga
- GTA
- On Track
- Space Invaders

Bespoke settings overlays remain a later migration lane. Do not migrate those
inside a shared-shell cleanup unless the ticket explicitly owns that cartridge.

## Archetype Guidance

### Arena / Asteroids / Galaga-style

Best secondary settings:

- collision mode
- grid resolution
- grid expand
- lane expand
- invert grid
- invert lanes
- organic boundary
- organic rounding
- secondary strength/fill/outline
- ship or actor scale

### Region / GTA-style

Best secondary settings:

- block expansion/shrink
- road width
- building padding
- spawn spacing
- traffic density

### Lane / Frogger / Paperboy-style

Best secondary settings:

- lane width
- lane spacing
- lane invert
- shoulder width
- safe-zone padding

### Platform

Best secondary settings:

- platform thickness
- platform gap tolerance
- ledge padding
- climbable threshold

### Track

Best secondary settings:

- road width
- checkpoint tolerance
- centerline smoothing
- shoulder expansion

### Maze / Well / Grid-locked

Best secondary settings:

- cell scale
- wall thickness
- fill invert
- corridor smoothing

## Agent Rule

When adding secondary level UI to a new cartridge:

1. Reuse the shared Tab menu.
2. Follow the required group order.
3. Use explicit standard groups; avoid `General` for new knobs.
4. Prefer standard labels from this document.
5. Expose only knobs that have visible, live effect.
6. Include a `Scale Grid Overlay` toggle whenever a visual measuring grid is
   drawn.
7. Do not migrate bespoke settings overlays in the same pass unless the ticket
   owns that cartridge.
