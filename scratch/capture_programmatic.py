import subprocess
import os

# Paths
app_dir = r"C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade"
godot_exe = os.path.join(app_dir, "Godot_v4.3-stable_win64_console.exe")
if not os.path.exists(godot_exe):
    godot_exe = os.path.join(app_dir, "Godot_v4.3-stable_win64.exe")

scene_path = os.path.join(app_dir, "content", "scenes", "scene_demo_wall")
level_path = os.path.join(scene_path, "levels", "demo_level")
qa_dir = os.path.join(app_dir, "vault", "70-qa")

def run_godot_capture(project_dir, args):
    cmd = [godot_exe, "--path", project_dir] + args
    print(f"Running: {' '.join(cmd)}")
    
    # Run synchronously because Godot will call get_tree().quit() after screenshot
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, timeout=15)
    print(f"Stdout:\n{proc.stdout}")
    if proc.stderr:
        print(f"Stderr:\n{proc.stderr}")
    print(f"Exited with code: {proc.returncode}\n")

def main():
    os.makedirs(qa_dir, exist_ok=True)
    
    # 1. Capture Hub Cartridge Picker
    run_godot_capture(
        os.path.join(app_dir, "app", "hub"),
        ["--test-screenshot", "picker", "--screenshot-path", os.path.join(qa_dir, "hub_cartridge_picker.png")]
    )
    
    # 2. Capture Panic Black
    run_godot_capture(
        os.path.join(app_dir, "app", "hub"),
        ["--test-screenshot", "panic", "--screenshot-path", os.path.join(qa_dir, "hub_panic_black.png")]
    )
    
    # 3. Capture Restore logs
    run_godot_capture(
        os.path.join(app_dir, "app", "hub"),
        ["--test-screenshot", "restore", "--screenshot-path", os.path.join(qa_dir, "hub_restore_log.png")]
    )
    
    # 4. Capture Lumen Maze gameplay
    run_godot_capture(
        os.path.join(app_dir, "content", "cartridges", "pacman"),
        ["--", "--scene", scene_path, "--level", level_path, "--ipc", "0", "--screenshot", os.path.join(qa_dir, "lumen_maze_run.png")]
    )
    
    # 5. Capture Neon Stack gameplay
    run_godot_capture(
        os.path.join(app_dir, "content", "cartridges", "tetris"),
        ["--", "--scene", scene_path, "--level", level_path, "--ipc", "0", "--screenshot", os.path.join(qa_dir, "neon_stack_run.png")]
    )

if __name__ == "__main__":
    main()
