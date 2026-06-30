import os

tasks = [
    {
        "id": "TASK-barrel-jumper",
        "cart_id": "donkey_kong",
        "game_name": "Donkey Kong",
        "objective": "Flesh out the `donkey_kong` cartridge stub into a fully playable Donkey Kong-like platformer conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Donkey Kong fully playable platforming logic implemented (player jumps over rolling barrels, climbs ladders)",
            "Barrels spawn at top, roll down inclined girders, and fall off ladders randomly",
            "Safe spawns, dynamic score updates, levels/wave transitions, and neon graphical representation",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing ladders, platforms, and barrels"
        ]
    },
    {
        "id": "TASK-brick-breaker",
        "cart_id": "breakout",
        "game_name": "Breakout",
        "objective": "Flesh out the `breakout` cartridge stub into a fully playable Breakout-like brick breaking game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Breakout fully playable brick breaking logic implemented (player controls paddle at bottom, ball bounces and breaks bricks)",
            "Different brick layers/types (e.g. multi-hit bricks, speed-up bricks, power-ups)",
            "Dynamic score updates, levels/wave transitions, and ball spawn safety",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing bricks, paddle, and particles"
        ]
    },
    {
        "id": "TASK-bubble-dragons",
        "cart_id": "bubble_bobble",
        "game_name": "Bubble Bobble",
        "objective": "Flesh out the `bubble_bobble` cartridge stub into a fully playable Bubble Bobble-like bubble shooter platformer conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Bubble Bobble fully playable platformer logic implemented (player blows bubbles to trap enemies, then pops them)",
            "Trapped enemies float up, and pop when touched, spawning fruit or points",
            "Dynamic score updates, wave transitions, enemy AI, and spawn safety checks",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing bubbles, platforms, and characters"
        ]
    },
    {
        "id": "TASK-drill-dug",
        "cart_id": "dig_dug",
        "game_name": "Dig Dug",
        "objective": "Flesh out the `dig_dug` cartridge stub into a fully playable Dig Dug-like digging action game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Dig Dug fully playable digging and inflation logic implemented (player digs tunnels, pumps enemies until they pop)",
            "Enemies roam tunnels, can turn into ghosts to pass through walls, and drop rocks to crush them",
            "Dynamic score updates, levels/wave transitions, and spawn safety checks",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing dirt, tunnels, rocks, and pumps"
        ]
    },
    {
        "id": "TASK-dungeon-crawl",
        "cart_id": "gauntlet",
        "game_name": "Gauntlet",
        "objective": "Flesh out the `gauntlet` cartridge stub into a fully playable Gauntlet-like dungeon crawler conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Gauntlet fully playable top-down hack & slash dungeon crawling logic implemented (player shoots projectiles, fights monster generators)",
            "Monsters spawn continuously from spawners until destroyed; food/keys are collectable",
            "Dynamic health decay, score updates, multiple levels/depths, and spawn safety checks",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing dungeon walls, generators, keys, and monsters"
        ]
    },
    {
        "id": "TASK-marble-run",
        "cart_id": "marble_madness",
        "game_name": "Marble Madness",
        "objective": "Flesh out the `marble_madness` cartridge stub into a fully playable Marble Madness-like isometric-styled rolling marble game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Marble Madness fully playable rolling marble physics logic implemented (player guides marble through a race course with hazards)",
            "Hazards like enemies, slippery areas, and drop-offs that destroy the marble",
            "Time limit, checkpoint bonuses, dynamic score updates, and spawn safety",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing grid tracks, height contours, and marble particles"
        ]
    },
    {
        "id": "TASK-neon-joust",
        "cart_id": "joust",
        "game_name": "Joust",
        "objective": "Flesh out the `joust` cartridge stub into a fully playable Joust-like flying ostriches action game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Joust fully playable flap-and-collide platformer physics logic implemented (player flaps wings, collides from above to defeat enemies)",
            "Defeated enemies spawn eggs that must be collected before they hatch into stronger enemies",
            "Lava pool at bottom, pterodactyl hazard, wave transitions, and spawn safety",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing platforms, lava, and flapping riders"
        ]
    },
    {
        "id": "TASK-neon-snake",
        "cart_id": "snake",
        "game_name": "Snake",
        "objective": "Flesh out the `snake` cartridge stub into a fully playable Snake-like eating and growth game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Snake fully playable grid-locked growth and movement logic implemented (snake eats food, grows longer, dies on self/wall collision)",
            "Multiplayer support, power-ups, food spawning avoiding obstacles/snake body",
            "Dynamic speed adjustments, score updates, and level/boundary checks",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing neon snake body and food particles"
        ]
    },
    {
        "id": "TASK-neon-tapper",
        "cart_id": "tapper",
        "game_name": "Tapper",
        "objective": "Flesh out the `tapper` cartridge stub into a fully playable Tapper-like soda serving game conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Tapper fully playable serving arcade logic implemented (player pours drinks, slides them down counters to customers, collects empty mugs)",
            "Multiple bar counters, advancing customer queues, tip collecting, and glass breaking penalties",
            "Dynamic difficulty, wave transitions, score updates, and spawn safety",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing bar counters, mugs, and customer silhouettes"
        ]
    },
    {
        "id": "TASK-neon-tempest",
        "cart_id": "tempest",
        "game_name": "Tempest",
        "objective": "Flesh out the `tempest` cartridge stub into a fully playable Tempest-like tube shooter conforming to the design brief and IPC requirements.",
        "acceptance": [
            "Tempest fully playable tube shooter logic implemented (player moves along outer rim of 3D-like geometric tube, shooting down lanes)",
            "Enemies crawl up lanes, can capture player if they reach the rim, superzapper utility",
            "Dynamic level/tube configurations, score updates, wave transitions, and spawn safety",
            "Full IPC NDJSON compliance (load, pause, resume, quit, ready, score, heartbeat)",
            "Skinned in classic neon vector style with glowing wireframe tubes and vector enemies"
        ]
    }
]

for task in tasks:
    path = f"vault/30-tasks/{task['id']}.md"
    content = f"""---
task_id: {task['id']}
stage: 4
status: todo
owner_agent: Codex
touches: [content/cartridges/{task['cart_id']}]
locks_required: [{task['cart_id']}]
acceptance:
"""
    for criteria in task['acceptance']:
        content += f"  - {criteria}\n"
    content += f"""---

# Objective
{task['objective']}

## Handoff & Instructions
Refer to `_Briefs/BUILD_INSTRUCTIONS_HARDENED.md` for full implementation details, IPC compliance, and design aesthetics.
All assets and logic must be implemented inside `content/cartridges/{task['cart_id']}`. Make sure to run compile/headless tests to verify correct code execution before marking the task as completed.
"""
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"Created task file: {path}")
