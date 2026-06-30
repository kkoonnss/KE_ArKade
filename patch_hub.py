import sys

def patch_hub(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
        
    content = content.replace(
        'ProjectSettings.globalize_path("res://").path_join("../../content/scenes")',
        '_get_repo_root().path_join("content/scenes")'
    )
    
    content = content.replace(
        'ProjectSettings.globalize_path("res://").path_join("../../app/tools/level_authoring/author.py")',
        '_get_repo_root().path_join("app/tools/level_authoring/author.py")'
    )
    
    content = content.replace(
        'ProjectSettings.globalize_path("res://").path_join("../../")',
        '_get_repo_root()'
    )

    with open(filepath, 'w') as f:
        f.write(content)

patch_hub("C:/Users/Kons/Documents/_KE_VibeApps/KE_ArKade/app/hub/main.gd")
