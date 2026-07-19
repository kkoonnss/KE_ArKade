extends RefCounted

const SCHEMA := "cartridge_level_adjustments"
const VERSION := "1.0.0"
const SETTINGS_PATH := "user://level_adjustments.json"

static func load_level_settings(cartridge_id: String, level_dir: String, defaults: Dictionary = {}, scene_dir: String = "", legacy_filename: String = "settings.json") -> Dictionary:
    var out := defaults.duplicate(true)
    var registry := _load_registry(cartridge_id)
    var key := level_key(level_dir, scene_dir)
    var levels: Dictionary = registry.get("levels", {})
    var stored = levels.get(key, null)
    if typeof(stored) == TYPE_DICTIONARY:
        _merge_dict(out, stored)
        return out

    var legacy := _load_legacy_settings(level_dir, legacy_filename)
    if not legacy.is_empty():
        _merge_dict(out, legacy)
    return out

static func save_level_settings(cartridge_id: String, level_dir: String, values: Dictionary, scene_dir: String = "") -> void:
    if level_dir == "":
        return
    var registry := _load_registry(cartridge_id)
    registry["schema"] = SCHEMA
    registry["version"] = VERSION
    registry["cartridge_id"] = cartridge_id
    if typeof(registry.get("levels", {})) != TYPE_DICTIONARY:
        registry["levels"] = {}
    var levels: Dictionary = registry["levels"]
    levels[level_key(level_dir, scene_dir)] = values.duplicate(true)
    registry["levels"] = levels

    var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(registry, "  "))

static func level_key(level_dir: String, scene_dir: String = "") -> String:
    var info := _read_level_yaml(level_dir)
    var scene_id := str(info.get("scene_id", ""))
    var level_id := str(info.get("level_id", ""))
    if scene_id == "":
        scene_id = _basename(scene_dir)
    if level_id == "":
        level_id = _basename(level_dir)
    if scene_id == "":
        scene_id = "unknown_scene"
    if level_id == "":
        level_id = "unknown_level"
    return scene_id + "/" + level_id

static func _load_registry(cartridge_id: String) -> Dictionary:
    var registry := {
        "schema": SCHEMA,
        "version": VERSION,
        "cartridge_id": cartridge_id,
        "levels": {}
    }
    if not FileAccess.file_exists(SETTINGS_PATH):
        return registry
    var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
    if not file:
        return registry
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return registry
    if typeof(parsed.get("levels", {})) != TYPE_DICTIONARY:
        parsed["levels"] = {}
    if str(parsed.get("cartridge_id", cartridge_id)) == "":
        parsed["cartridge_id"] = cartridge_id
    return parsed

static func _load_legacy_settings(level_dir: String, legacy_filename: String) -> Dictionary:
    if level_dir == "" or legacy_filename == "":
        return {}
    var path := level_dir.path_join(legacy_filename)
    if not FileAccess.file_exists(path):
        return {}
    var file := FileAccess.open(path, FileAccess.READ)
    if not file:
        return {}
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) == TYPE_DICTIONARY:
        return parsed
    return {}

static func _read_level_yaml(level_dir: String) -> Dictionary:
    var data := {}
    if level_dir == "":
        return data
    var yaml_path := level_dir.path_join("level.yaml")
    if not FileAccess.file_exists(yaml_path):
        return data
    var file := FileAccess.open(yaml_path, FileAccess.READ)
    if not file:
        return data
    while not file.eof_reached():
        var line := file.get_line().strip_edges()
        if line == "" or line.begins_with("#"):
            continue
        if ":" in line:
            var parts := line.split(":", true, 1)
            var key := parts[0].strip_edges()
            var val := parts[1].strip_edges()
            if (val.begins_with("\"") and val.ends_with("\"")) or (val.begins_with("'") and val.ends_with("'")):
                val = val.substr(1, val.length() - 2)
            if key == "scene_id" or key == "level_id":
                data[key] = val
    return data

static func _merge_dict(target: Dictionary, source: Dictionary) -> void:
    for key in source.keys():
        target[key] = source[key]

static func _basename(path: String) -> String:
    var normalized := path.replace("\\", "/").trim_suffix("/")
    if normalized == "":
        return ""
    return normalized.get_file()
