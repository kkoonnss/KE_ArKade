---
task_id: TASK-shared-slider-focus-style
lane: shared
status: pending_kons_verify
locks_required: [shared-slider-focus-style]
opened_by: claude_opus
opened_at: 2026-07-03
---

> [!note] Codex cleanup, 2026-07-04
> The stale `shared-slider-focus-style` lock was removed during the
> `TASK-shared-start-menu-mouse` takeover. The Claude Sonnet receipt already
> recorded the slider focus work as complete and pending Kons verification.

# Make the shared TabMenu slider's selected/focused state clearly visible

## Problem

Kons: "Sliders in menus, when selected, barely lighten up — I want to be able
to see that it's selected. Either grow in scale or a ring outline."

Screenshot shows the Design screen's knob panel (Background Opacity,
Secondary Photo Mix, etc.) — this is the shared `TabMenu` knob toolkit, used
by every cartridge's settings menu and the hub's Design screen, not a
one-off. Root cause: `HSlider.new()` in `_build_knob_control()` has zero
theme overrides, so the only focus feedback is Godot's stock engine-default
focus style, which barely reads against this project's black/near-black
panels.

## File / location

`app/shared/controls/tab_menu.gd`, function `_build_knob_control()`, the
slider branch (currently lines ~554-565):

```gdscript
var slider = HSlider.new()
slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
slider.min_value = float(knob.min)
slider.max_value = float(knob.max)
slider.step = float(knob.step)
slider.value = float(knob.value)
slider.gui_input.connect(func(event):
    if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_LEFT, MOUSE_BUTTON_WHEEL_RIGHT]:
        slider.accept_event()
)
slider.value_changed.connect(func(v): _apply_knob_from_control(knob, int(round(v)) if knob.type == "int" else v, value_label))
slider_row.add_child(slider)
```

## Requested change

Add a clearly visible focused/selected state to this `HSlider`. Two
acceptable approaches, pick whichever is cleaner in Godot 4.3:

1. **Focus ring** — override the `focus` theme stylebox with a
   `StyleBoxFlat` that draws a visible outline (e.g. border using this
   file's existing accent `Color(0.16, 0.55, 1.0)` at full alpha, ~2-3px
   border, transparent fill) via `slider.add_theme_stylebox_override("focus", ...)`.
2. **Grabber grow + highlight** — override `grabber_area_highlight` /
   `grabber_highlight` icons or styleboxes so the grabber visibly enlarges
   and brightens on focus (e.g. connect `focus_entered`/`focus_exited`
   signals and animate/scale the grabber, or swap in a brighter
   `grabber_highlight` texture/stylebox).

Either is fine — the bar is "obviously different when selected," matching
the existing design language (dark panels, cyan/blue accent per
`_menu_panel_style`, see `Color(0.16, 0.55, 1.0)` used for the settings
panel border at line 135).

## Constraints

- **Scope: this function only.** Do not touch `CheckBox`/`OptionButton`
  styling in the same file unless it's a one-line, obviously-safe addition —
  if you want to extend the same treatment to those, note it as a follow-on
  rather than bundling.
- Read the whole file before editing (governance rule: no range-based edit
  without a full read first — `01_LANES.md` §2.1). File is ~840 lines.
- `app/shared/**` is a shared lane: this must stay additive/backward
  compatible for every cartridge and the hub that consumes `TabMenu` via
  `SharedLoader`. Don't change the knob dictionary contract, signals, or
  function signatures — visual/theme-only change.
- No Godot binary available in the Cowork sandbox to headless-parse-check.
  Do your own careful manual read-through instead. Kons will do the real
  launch confirmation (per `02_VERIFICATION_GATES.md` §5 shared gate + §8
  "cannot verify" escape) — mark the ticket `pending_kons_verify`, not
  `done`.
- Write the receipt at
  `vault/40-agent-runs/claude_sonnet_shared_slider_focus_style_2026-07-03.md`
  per `04_AGENT_HANDOFF_TEMPLATE.md`, and delete
  `vault/35-locks/shared-slider-focus-style.md` when you close out (even
  though status will be `pending_kons_verify`, not `done` — release the lock
  once your edit is complete and you're not actively iterating).

## Acceptance

- Kons launches any cartridge or the hub Design screen, tabs/clicks into a
  slider, and can immediately tell it's selected without squinting.
