import re

with open('content/cartridges/pacman/main.gd', 'r') as f:
    code = f.read()

# p.x -> p["x"]
code = code.replace("p.x", "p[\"x\"]")
code = code.replace("p.y", "p[\"y\"]")
code = code.replace("pk.x", "pk[\"x\"]")
code = code.replace("pk.y", "pk[\"y\"]")
code = code.replace("e.x", "e[\"x\"]")
code = code.replace("e.y", "e[\"y\"]")
code = code.replace("sp.x", "sp[\"x\"]")
code = code.replace("sp.y", "sp[\"y\"]")
code = code.replace("sp.id", "sp[\"id\"]")
code = code.replace("pickup.x", "pickup[\"x\"]")
code = code.replace("pickup.y", "pickup[\"y\"]")

# e.speed -> e["speed"]
code = code.replace("e.speed", "e[\"speed\"]")

# e.target_node_id -> e["target_node_id"]
code = code.replace("e.target_node_id", "e[\"target_node_id\"]")
code = code.replace("e.current_node_id", "e[\"current_node_id\"]")
code = code.replace("e.prev_node_id", "e[\"prev_node_id\"]")
code = code.replace("p.target_node_id", "p[\"target_node_id\"]")
code = code.replace("p.current_node_id", "p[\"current_node_id\"]")
code = code.replace("p.alive", "p[\"alive\"]")

with open('content/cartridges/pacman/main.gd', 'w') as f:
    f.write(code)
