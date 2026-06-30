import os
import glob
import re

def patch_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    original_content = content
    
    # Check if SharedLoader is already imported
    has_sl = "var SL" in content or "const SharedLoader" in content
    
    if not has_sl:
        # Inject SharedLoader at the top after extends Node2D or class_name
        lines = content.split('\n')
        insert_idx = 0
        for i, line in enumerate(lines):
            if line.startswith("extends ") or line.startswith("class_name "):
                insert_idx = i + 1
        
        lines.insert(insert_idx, 'const SharedLoader = preload("res://../../../app/shared/shared_loader.gd")')
        content = '\n'.join(lines)
    
    def replacer_axis(match):
        pid = match.group(1).strip()
        axis = match.group(2).strip()
        if "SharedLoader.get_joy_id" in pid or "SL.get_joy_id" in pid:
            return match.group(0) # already patched
        return f"Input.get_joy_axis(SharedLoader.get_joy_id({pid}), {axis})"

    content = re.sub(r'Input\.get_joy_axis\(([^,]+),\s*([^)]+)\)', replacer_axis, content)
    
    def replacer_button(match):
        pid = match.group(1).strip()
        btn = match.group(2).strip()
        if "SharedLoader.get_joy_id" in pid or "SL.get_joy_id" in pid:
            return match.group(0) # already patched
        return f"Input.is_joy_button_pressed(SharedLoader.get_joy_id({pid}), {btn})"

    content = re.sub(r'Input\.is_joy_button_pressed\(([^,]+),\s*([^)]+)\)', replacer_button, content)
    
    def replacer_name(match):
        pid = match.group(1).strip()
        if "SharedLoader.get_joy_id" in pid or "SL.get_joy_id" in pid:
            return match.group(0)
        return f"Input.get_joy_name(SharedLoader.get_joy_id({pid}))"
        
    content = re.sub(r'Input\.get_joy_name\(([^)]+)\)', replacer_name, content)
    
    if content != original_content:
        with open(filepath, 'w') as f:
            f.write(content)
        print(f"Patched {filepath}")

if __name__ == '__main__':
    search_path = os.path.join("content", "cartridges", "*", "*.gd")
    files = glob.glob(search_path)
    for f in files:
        patch_file(f)
    print(f"Finished patching {len(files)} files.")
