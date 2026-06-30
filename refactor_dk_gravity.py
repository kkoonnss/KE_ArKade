import re
with open('content/cartridges/donkey_kong/main.gd', 'r') as f:
    code = f.read()

# 1. Declaration
old_decl = '''var current_jump_height = 1.0'''
new_decl = '''var current_jump_height = 1.0\nvar current_gravity = 1.0'''
code = code.replace(old_decl, new_decl)

# 2. Registration
old_reg = '''    tab_menu.register_knob_float("jump_height", "Jump Height", 1.0, 0.5, 2.0, 0.1)'''
new_reg = '''    tab_menu.register_knob_float("jump_height", "Jump Height", 1.0, 0.5, 2.0, 0.1)\n    tab_menu.register_knob_float("gravity", "Gravity", 1.0, 0.5, 2.0, 0.1)'''
code = code.replace(old_reg, new_reg)

# 3. Knob changed
old_kc = '''func _on_knob_changed(knob_id: String, value):
    if knob_id == "jump_height": current_jump_height = float(value)'''
new_kc = '''func _on_knob_changed(knob_id: String, value):
    if knob_id == "jump_height": current_jump_height = float(value)
    elif knob_id == "gravity": current_gravity = float(value)'''
code = code.replace(old_kc, new_kc)

# 4. Apply to barrel gravity
old_bg = '''        # Gravity
        if not b.get("ladder", false):
            b["vel"].y += 500 * delta'''
new_bg = '''        # Gravity
        if not b.get("ladder", false):
            b["vel"].y += 500 * current_gravity * delta'''
code = code.replace(old_bg, new_bg)

# 5. Apply to player gravity
old_pg = '''    else:
        vel.y += 520 * delta
        if can_jump and _action() and player["on_ground"]:
            vel.y = -310 * current_jump_height'''
new_pg = '''    else:
        vel.y += 520 * current_gravity * delta
        if can_jump and _action() and player["on_ground"]:
            vel.y = -310 * current_jump_height'''
code = code.replace(old_pg, new_pg)

with open('content/cartridges/donkey_kong/main.gd', 'w') as f:
    f.write(code)
