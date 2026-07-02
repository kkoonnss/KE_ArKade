extends Node

# Normalizes inputs via SDL3 bindings (simulated via standard Godot Input for MVP)
# Up to 4 player slots

class_name HubInputManager

signal device_connected(device_id, name)
signal device_disconnected(device_id)
signal slot_reassigned(slot_index)

var slots = {
	0: {"device_id": -1, "type": "none"},
	1: {"device_id": -1, "type": "none"},
	2: {"device_id": -1, "type": "none"},
	3: {"device_id": -1, "type": "none"}
}

func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	_load_config()
	
	if slots[0]["device_id"] == -1:
		slots[0] = {"device_id": -2, "type": "keyboard"}
		
	# Auto-assign connected gamepads that aren't already mapped
	for joy_id in Input.get_connected_joypads():
		if not _is_device_assigned(joy_id):
			_assign_joypad(joy_id)
			
	_save_config()

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		emit_signal("device_connected", device_id, Input.get_joy_name(device_id))
		if not _is_device_assigned(device_id):
			_assign_joypad(device_id)
			_save_config()
	else:
		emit_signal("device_disconnected", device_id)
		# We don't automatically unassign saved slots so they persist across disconnections

func _is_device_assigned(device_id: int) -> bool:
	for i in range(4):
		if slots[i]["device_id"] == device_id:
			return true
	return false

func _assign_joypad(device_id: int):
	for i in range(4):
		if slots[i]["device_id"] == -1 or slots[i]["device_id"] == -2:
			var old_dev = slots[i]["device_id"]
			slots[i] = {"device_id": device_id, "type": "gamepad"}
			print("Auto-assigned gamepad ", device_id, " to slot ", i)
			
			if old_dev == -2:
				# Move keyboard down to next empty slot
				for j in range(i + 1, 4):
					if slots[j]["device_id"] == -1:
						slots[j] = {"device_id": -2, "type": "keyboard"}
						print("Moved keyboard to slot ", j)
						break
			return

func _unassign_joypad(device_id: int):
	for i in range(4):
		if slots[i]["device_id"] == device_id:
			slots[i] = {"device_id": -1, "type": "none"}
			print("Unassigned gamepad ", device_id, " from slot ", i)
			break

func reassign_slot(slot_index: int, device_id: int):
	# Unassign this device if it is assigned to another slot
	for i in range(4):
		if slots[i]["device_id"] == device_id and i != slot_index:
			slots[i] = {"device_id": -1, "type": "none"}
			emit_signal("slot_reassigned", i)
			
	# Assign it to the new slot
	if device_id == -2:
		slots[slot_index] = {"device_id": -2, "type": "keyboard"}
	else:
		slots[slot_index] = {"device_id": device_id, "type": "gamepad"}
		
	print("Manually reassigned device ", device_id, " to slot ", slot_index)
	emit_signal("slot_reassigned", slot_index)
	_save_config()

func get_config_path() -> String:
	var dir = ProjectSettings.globalize_path("res://").replace("\\", "/").simplify_path()
	if dir.ends_with("/"):
		dir = dir.substr(0, dir.length() - 1)
	for _i in range(10):
		var shared_dir = dir.path_join("app").path_join("shared")
		if DirAccess.dir_exists_absolute(shared_dir):
			return shared_dir.path_join("input_config.json")
		var parent = dir.get_base_dir()
		if parent == dir or parent == "":
			break
		dir = parent
	return ""

func _save_config():
	var path = get_config_path()
	if path == "": return
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		var data = {"slots": slots}
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func _load_config():
	var path = get_config_path()
	if path == "" or not FileAccess.file_exists(path):
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			if typeof(data) == TYPE_DICTIONARY and data.has("slots"):
				var saved_slots = data["slots"]
				for key in saved_slots:
					var int_key = int(key)
					slots[int_key] = saved_slots[key]
		file.close()
