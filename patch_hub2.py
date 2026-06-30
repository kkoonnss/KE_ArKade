import sys

def patch():
    with open('app/hub/main.gd', 'r') as f:
        lines = f.readlines()
        
    out = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Add new variables at the top
        if "var debug_panel: VBoxContainer = null" in line:
            out.append(line)
            out.append("@onready var main_panel = $UI/Content/MainPanel\n")
            out.append("var splash_overlay: ColorRect\n")
            out.append("var design_screen_scene = preload(\"res://design_screen.tscn\")\n")
            out.append("var content_vbox: VBoxContainer\n")
            i += 1
            continue
            
        # Fix splash_overlay in _ready()
        if "var splash_overlay = ColorRect.new()" in line:
            out.append(line.replace("var splash_overlay = ColorRect.new()", "splash_overlay = ColorRect.new()"))
            i += 1
            continue
            
        # Fix content_vbox in _ready()
        if "var content_vbox = VBoxContainer.new()" in line:
            out.append(line.replace("var content_vbox = VBoxContainer.new()", "content_vbox = VBoxContainer.new()"))
            i += 1
            continue
            
        # Remove var main_panel = $UI/Content/MainPanel in _ready() if it exists
        if "var main_panel = $UI/Content/MainPanel" in line:
            # Skip it, already @onready
            i += 1
            continue
            
        # Fix _prepare_scroll_view
        if "func _prepare_scroll_view(show_default_grid: bool):" in line:
            out.append(line)
            out.append("\tif content_vbox:\n")
            out.append("\t\tcontent_vbox.visible = true\n")
            out.append("\tif main_panel:\n")
            out.append("\t\tfor child in main_panel.get_children():\n")
            out.append("\t\t\tif child != content_vbox and child != main_panel.get_node_or_null(\"ScrollContainer\"):\n") # ScrollContainer might be there? No, we reparented it!
            out.append("\t\t\t\tchild.queue_free()\n")
            i += 1
            continue
            
        # Add clear_main_panel right before _on_design_nav_pressed
        if "func _on_design_nav_pressed():" in line:
            out.append("func clear_main_panel():\n")
            out.append("\tif content_vbox:\n")
            out.append("\t\tcontent_vbox.visible = false\n")
            out.append("\tif main_panel:\n")
            out.append("\t\tfor child in main_panel.get_children():\n")
            out.append("\t\t\tif child != content_vbox:\n")
            out.append("\t\t\t\tchild.queue_free()\n\n")
            out.append(line)
            i += 1
            continue
            
        out.append(line)
        i += 1
        
    with open('app/hub/main.gd', 'w') as f:
        f.writelines(out)

patch()
