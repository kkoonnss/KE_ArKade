# KE_ArKade

KE_ArKade is a local-first arena abstraction platform for projected game cartridges.
This repo is expected to live at `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade`.

## Fresh Clone Setup (Windows)

1. Clone the private repo into the expected path:
   `git clone <github-private-url> C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade`
2. Install Git for Windows if it is not already present:
   [https://git-scm.com/download/win](https://git-scm.com/download/win)
3. Install Godot 4.3 stable for Windows:
   - Download the standard editor exe and the console exe from the official Godot release page.
   - Place them at repo root with these exact filenames:
     - `Godot_v4.3-stable_win64.exe`
     - `Godot_v4.3-stable_win64_console.exe`
   - Optional: keep `godot.zip` outside the repo; it is ignored and not required once the exes are in place.
4. Install the local Git hooks from the repo root:
   `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\_Briefs\governance\scripts\install_hooks_2026-07-01.cmd`
5. Verify the backup remote is configured:
   `git -C C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade remote -v`
6. Verify the working copy:
   - `git -C C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade status`
   - Launch with the local Godot exes or the existing KE_ArKade launcher flow.

## Backup Workflow

- Manual backup push:
  `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade\_Briefs\governance\scripts\push_backup.cmd`
- Automatic backup push:
  `.git/hooks/post-commit` starts `push_backup.cmd` in the background after each commit.
- Snapshot tags:
  Daily tags (`daily/YYYY-MM-DD`) and weekly tags (`week/YYYY-Www`) are pushed by the same backup script when they exist locally.

## Recovery From Remote

1. Clone fresh into `C:\Users\Kons\Documents\_KE_VibeApps\KE_ArKade`.
2. Inspect the available daily tags:
   `git tag -l "daily/*"`
3. Check out the last known good snapshot:
   `git checkout daily/<YYYY-MM-DD>`
4. Re-run the install steps above so the local Godot executables and hooks are back in place.
