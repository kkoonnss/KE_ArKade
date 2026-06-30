extends RefCounted
class_name CompatibilityGate

static func is_compatible(cartridge_reqs: Dictionary, level_provides: Dictionary) -> bool:
    # Check orientation
    var level_orientation = level_provides.get("orientation", "")
    var req_orientations = cartridge_reqs.get("orientation", [])
    if level_orientation != "" and not level_orientation in req_orientations:
        return false
        
    # Check semantic classes
    var level_classes = level_provides.get("semantic_classes", [])
    for req_class in cartridge_reqs.get("semantic_classes", []):
        if not req_class in level_classes:
            return false
            
    # Check derived layers
    var level_layers = level_provides.get("derived_layers", [])
    for req_layer in cartridge_reqs.get("derived_layers", []):
        if not req_layer in level_layers:
            return false
            
    return true
