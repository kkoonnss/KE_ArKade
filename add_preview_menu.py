import re

with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Add variables
if "var reference_opacity =" not in code:
    code = code.replace(
        "var show_reference = false",
        "var show_reference = false\nvar reference_opacity = 0.15\nvar show_debug_grid = false"
    )

# 2. Register knobs
if 'tab_menu.register_knob_bool("reference"' not in code:
    code = code.replace(
        'tab_menu.register_knob_float("barrel_ladder_chance", "Barrel Ladder %", 0.5, 0.0, 1.0, 0.05, "Secondary")',
        'tab_menu.register_knob_float("barrel_ladder_chance", "Barrel Ladder %", 0.5, 0.0, 1.0, 0.05, "Secondary")\n    tab_menu.register_knob_bool("reference", "Background Layer", show_reference, "Preview")\n    tab_menu.register_knob_float("reference_opacity", "Background Opacity", reference_opacity, 0.0, 1.0, 0.05, "Preview")\n    tab_menu.register_knob_bool("show_debug_grid", "Scale Grid Overlay", show_debug_grid, "Preview")'
    )

# 3. Handle knob changes
if 'elif knob_id == "reference":' not in code:
    code = code.replace(
        'elif knob_id == "barrel_ladder_chance":\n        current_barrel_ladder_chance = float(value)',
        'elif knob_id == "barrel_ladder_chance":\n        current_barrel_ladder_chance = float(value)\n    elif knob_id == "reference": show_reference = bool(value)\n    elif knob_id == "reference_opacity": reference_opacity = float(value)\n    elif knob_id == "show_debug_grid": show_debug_grid = bool(value)'
    )

# 4. Use reference_opacity in _draw
code = code.replace(
    'draw_texture_rect(reference_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, 0.15))',
    'draw_texture_rect(reference_texture, Rect2(0, 0, map_w, map_h), false, Color(1, 1, 1, reference_opacity))'
)

# 5. Use show_debug_grid in _draw
code = code.replace(
    '    _draw_grid()',
    '    if show_debug_grid:\n        _draw_grid()'
)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
