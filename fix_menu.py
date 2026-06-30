import re

with open('app/shared/controls/tab_menu.gd', 'r') as f:
    code = f.read()

# Add _focus_first
focus_func = '''func _focus_first(node: Node) -> bool:
	if node is Control and node.focus_mode == Control.FOCUS_ALL and node.visible:
		node.grab_focus()
		return true
	for child in node.get_children():
		if _focus_first(child):
			return true
	return false'''

if 'func _focus_first' not in code:
    code += '\n\n' + focus_func + '\n'

# Call _focus_first in _set_overlay_mode
old_mode = '''	else:
		if overlay_mode == "settings":
			_rebuild_settings_controls()
		_update_menu_overlay()'''
new_mode = '''	else:
		if overlay_mode == "settings":
			_rebuild_settings_controls()
			if settings_box:
				_focus_first(settings_box)
		_update_menu_overlay()'''

code = code.replace(old_mode, new_mode)

with open('app/shared/controls/tab_menu.gd', 'w') as f:
    f.write(code)
