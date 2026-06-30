# KE_ArKade Operator Instructions

This document provides a guide on how to launch the Hub, compile custom maps, switch games, and use the debug/service tools.

---

## 1. Operating the Hub
- Launch the Hub project by running the Godot project located in `app/hub/`.
- Use the sidebar navigation buttons:
  - **Scenes**: Lists physical venues scanned from `content/scenes/`.
  - **Levels**: Displays levels belonging to the selected Scene.
  - **Service**: Opens the **IPC Debug Console** to view socket packets and process status.
  - **Test Pattern**: Renders a display calibration grid.
- Click a Scene card to view its levels (e.g. `demo_level` or custom-painted levels).
- Click a Level card to bring up the **Launch Dialog**. Choose between **Lumen Maze** and **Neon Stack**.

---

## 2. Using the Service / Debug Panel
- Navigate to the **Service** tab in the Hub.
- **Active PID**: Displays the OS process ID of the currently running game.
- **IPC Port**: The TCP socket port used for communication (50000–60000).
- **IPC State**: Connection status between the Hub and the game.
- **Real-time NDJSON Log**:
  - **Yellow**: Game launch execution commands.
  - **Green**: Messages received from the game (e.g., `heartbeat`, `ready`, `score`).
  - **Blue**: Messages sent to the game (e.g., `blank`).
  - **Red**: Process termination, timeouts, and force-kill events.
- **Controls**: Use **Force Kill Process** to manually shut down a game, and **Clear Log** to reset the console text.

---

## 3. Creating & Editing Levels
1. Run the authoring tool:
   ```bash
   python app/tools/level_authoring/author.py
   ```
2. **To Draw From Scratch:** Click **Load Background Image** to load a wall photo or reference frame, choose colors from the **Palette** (e.g., `solid`, `path`, `spawn`), adjust the brush, and paint.
3. **To Edit An Existing Map:** Click **Load Existing Map** and select your level's `semantic_map.png`.
4. Click **Save Level** and choose/create a level directory in `content/scenes/<scene_name>/levels/` (e.g. `custom_level`).
5. The authoring tool will save `semantic_map.png` and `level.yaml`, then auto-execute the OpenCV compilation scripts (`navgraph`, `container`, `occupancy`) in the background.

---

## 4. Troubleshooting
- If a game fails to start or says "Not compatible," check the console in the **Service** tab to view compatibility gate logs.
- If a game hangs, it will be automatically terminated after 3 missed heartbeats (3 seconds) and the Hub will return to the menu.
