# Secondary Level UI Standard

This standard defines the shared Tab-menu interface for live, per-level map tuning inside cartridges.

Goal: different games can expose different knobs, but the interface should still feel like the same instrument.

## Core Intent

- The menu is for live level interpretation, not general game options.
- Every control should visibly affect how the current level is read, fit, previewed, or played.
- Changes should apply immediately when possible.
- A player or builder should be able to move from one game to another and still recognize the menu structure.

## Required Group Order

When a cartridge exposes secondary level controls, use these groups in this order:

1. `Preview`
2. `Collision`
3. `Secondary`
4. `Gameplay`
5. `Actions`

Do not invent a different top-level order unless the cartridge has a very strong game-specific reason.

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

Notes:

- `Scale Grid Overlay` is not gameplay collision by itself.
- It is a visual ruler for proportion, spacing, and alignment across views.
- Default it `On` for map-fitting games where scale tuning matters.
- Default it `Off` for games where it adds clutter and no alignment value.

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

- Prefer nouns the player can understand over implementation names.
- Use `Expand` instead of `Dilate`, `Shrink`, or morphology terminology.
- Negative `Expand` is allowed and should behave predictably.
- If a control changes collision, it belongs here even if it also affects visuals.

### Secondary

Purpose: tune the second interpretation layer that sits between source map and final gameplay.

This is where cartridges get more freedom, but keep labels plain and visual.

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

- Secondary controls should modify an in-memory interpretation or a per-level edit artifact, not the original `semantic_map.png`.
- The live preview should always make the effect legible.
- If a game only has one or two meaningful secondary knobs, still keep them in this group.

### Gameplay

Purpose: expose the small set of play-feel controls that are needed to make the interpreted level actually work.

Examples:

- `Ship Scale`
- `Movement Scale`
- `Jump Height`
- `Spawn Spacing`
- `Enemy Density`

Rules:

- Keep this group short.
- Only include gameplay knobs that are tightly coupled to level fit or readability.
- Broad difficulty settings belong elsewhere, not in the secondary level tuning menu.

### Actions

Purpose: explicit commands, not continuous tuning.

Examples:

- `Reset Secondary`
- `Save Level Edit`
- `Reload Level`
- `Restore Defaults`

Rules:

- Actions should be clearly separate from sliders and toggles.
- Destructive actions should be rare and plainly named.

## Naming Rules

- Use title case labels.
- Prefer plain words over engine words.
- Recommended wording:
  - `Background`, not `Source Raster`
  - `Scale Grid Overlay`, not `Debug Grid`
  - `Expand`, not `Dilate`
  - `Invert`, not `Boolean Not`
  - `Collision`, not `Mask Logic`

## Interaction Rules

- Mouse, keyboard, and controller should all work.
- Sliders must update live.
- Sliders must ignore mouse-wheel changes while scrolling the menu.
- Groups should be collapsible.
- Collapsed state should persist per cartridge if settings persistence already exists.

## Visual Rules

- Use the shared Tab menu shell.
- Keep section headers yellow and clearly clickable.
- Keep controls vertically stacked and left-aligned.
- The menu should read like a technical instrument, not a marketing panel.

## Persistence Rules

- Per-level secondary edits should be storable separately from source assets.
- Do not overwrite `semantic_map.png` or `background.png`.
- If a cartridge persists secondary edits, store them as a per-level artifact local to that level.

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
3. Prefer standard labels from this document.
4. Expose only knobs that have visible, live effect.
5. Include a `Scale Grid Overlay` toggle whenever a visual measuring grid is drawn.
