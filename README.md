# KE_ArKade

KE_ArKade is a local-first arena abstraction platform that turns a projected
physical space into a controller-driven arcade. A shared semantic scene/level
model is interpreted by independently launched Godot game cartridges.

The development source of truth is the K Main checkout. K Micro is a real-device
test target for the 1920x1080 projector and controller loop.

## Required software

- Windows 11
- Git for Windows 2.52.0 or newer
- Git LFS 3.7.1 or newer
- Godot `4.3.stable.official.77dcf97d8`
- Python 3.11 or newer for the optional compiler/calibration tools
- Python packages from `app/tools/requirements.txt`
- An XInput-compatible controller for the intended arcade experience

Godot projects declare the `4.3` feature set. Do not upgrade their engine
version as part of machine setup.

## Fresh clone setup on K Micro

Open PowerShell and run:

```powershell
git lfs install
git clone https://github.com/kkoonnss/KE_ArKade.git C:\KE_ArKade_Test
git -C C:\KE_ArKade_Test lfs pull
```

Confirm these LFS-managed files exist at the repository root:

- `Godot_v4.3-stable_win64.exe`
- `Godot_v4.3-stable_win64_console.exe`

If they are unavailable through LFS, download the official Godot 4.3 stable
Windows build and restore those exact filenames. Install the repository hooks
only on a development checkout; the K Micro test mirror does not need them.

To restore the optional Python toolchain:

```powershell
python -m venv venv
.\venv\Scripts\python.exe -m pip install -r app\tools\requirements.txt
```

## Development launch

From the repository root:

```powershell
.\Godot_v4.3-stable_win64.exe --editor --path app\hub
```

To launch the hub directly:

```powershell
.\Godot_v4.3-stable_win64.exe --path app\hub
```

The hub owns navigation and launches cartridges as separate Godot processes.
Do not open every cartridge project in the editor at once.

## Controller and projector testing

1. Set the projector to 1920x1080 and make it the intended active display.
2. Connect the controller before starting the hub; XInput is the baseline.
3. Launch the hub and verify controller-only navigation.
4. Launch at least Pac-Man and one dissimilar cartridge.
5. Verify pause/settings, return-to-hub, relaunch, and controller reconnect.
6. Keep the mouse nearby for setup and recovery, not normal play.

Machine-specific display placement, calibration, caches, logs, and editor state
remain local. Scene calibration source under `content/scenes/**/calibration/`
is project content and should remain versioned when intentionally authored.

## Validation

Run the Python tests when the toolchain is installed:

```powershell
.\venv\Scripts\python.exe -m unittest discover -s app\tools\tests -p "test_*.py"
```

Check the hub project without opening the editor:

```powershell
.\Godot_v4.3-stable_win64_console.exe --headless --path app\hub --editor --quit
```

Interactive or visual work is not complete until the hub and affected
cartridges are launched with the real controller. See
`_Briefs/governance/02_VERIFICATION_GATES.md` for lane-specific evidence.

## Packaged playable build

No canonical export preset is committed yet. Until one is added and validated,
the supported K Micro deployment is the repository checkout plus the pinned
Godot executable. Do not claim a packaged release from an editor-only run.

When packaging is implemented:

1. Add and review `export_presets.cfg` for the hub and required cartridges.
2. Export to an ignored `exports/` directory.
3. Include all runtime scene, level, cartridge, and shared assets.
4. Test the exported build on K Micro with no dependency on untracked source.

## Backup and migration

The private remote is `https://github.com/kkoonnss/KE_ArKade.git`; the existing
primary branch is `master` and its history must not be rewritten.

Manual backup:

```powershell
.\_Briefs\governance\scripts\push_backup.cmd
```

Full backup and restore policy is documented in `BACKUP.md` and
`_Briefs/governance/07_GIT_GOVERNANCE.md`.
