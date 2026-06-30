import cv2
import numpy as np
import json
import os
import sys

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../..')))
try:
    from app.shared.palette import CLASSES
except ImportError:
    CLASSES = {}

def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip('#')
    return tuple(int(hex_str[i:i+2], 16) for i in (4, 2, 0))


def _zhang_suen_thinning(mask):
    skeleton = (mask > 0).astype(np.uint8)
    interior = np.zeros_like(skeleton, dtype=bool)
    interior[1:-1, 1:-1] = True
    changed = True
    while changed:
        changed = False
        for step in (0, 1):
            p2 = np.roll(skeleton, 1, axis=0)
            p3 = np.roll(np.roll(skeleton, 1, axis=0), -1, axis=1)
            p4 = np.roll(skeleton, -1, axis=1)
            p5 = np.roll(np.roll(skeleton, -1, axis=0), -1, axis=1)
            p6 = np.roll(skeleton, -1, axis=0)
            p7 = np.roll(np.roll(skeleton, -1, axis=0), 1, axis=1)
            p8 = np.roll(skeleton, 1, axis=1)
            p9 = np.roll(np.roll(skeleton, 1, axis=0), 1, axis=1)

            count = p2 + p3 + p4 + p5 + p6 + p7 + p8 + p9
            transitions = (
                ((p2 == 0) & (p3 == 1)).astype(np.uint8)
                + ((p3 == 0) & (p4 == 1)).astype(np.uint8)
                + ((p4 == 0) & (p5 == 1)).astype(np.uint8)
                + ((p5 == 0) & (p6 == 1)).astype(np.uint8)
                + ((p6 == 0) & (p7 == 1)).astype(np.uint8)
                + ((p7 == 0) & (p8 == 1)).astype(np.uint8)
                + ((p8 == 0) & (p9 == 1)).astype(np.uint8)
                + ((p9 == 0) & (p2 == 1)).astype(np.uint8)
            )
            base = (
                (skeleton == 1)
                & interior
                & (count >= 2)
                & (count <= 6)
                & (transitions == 1)
            )
            if step == 0:
                delete_mask = base & (p2 * p4 * p6 == 0) & (p4 * p6 * p8 == 0)
            else:
                delete_mask = base & (p2 * p4 * p8 == 0) & (p2 * p6 * p8 == 0)
            if np.any(delete_mask):
                skeleton[delete_mask] = 0
                changed = True
    return skeleton.astype(bool)


def _add_edge(graph, a, b, weight):
    if a == b:
        return
    graph.setdefault(a, {})
    graph.setdefault(b, {})
    if b not in graph[a] or weight < graph[a][b]:
        graph[a][b] = float(weight)
        graph[b][a] = float(weight)


def _remove_node(graph, node):
    for neighbor in list(graph.get(node, {})):
        graph[neighbor].pop(node, None)
    graph.pop(node, None)


def _build_graph(skeleton):
    graph = {}
    points = set(zip(*np.where(skeleton)))
    for y, x in sorted(points):
        node = (int(y), int(x))
        graph.setdefault(node, {})
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if dy == 0 and dx == 0:
                    continue
                neighbor = (int(y + dy), int(x + dx))
                if neighbor in points:
                    _add_edge(graph, node, neighbor, float(np.sqrt(dy * dy + dx * dx)))
    return graph


def _simplify_graph(graph):
    for node in list(graph.keys()):
        if node not in graph or len(graph[node]) != 2:
            continue
        neighbors = list(graph[node])
        u, v = neighbors
        weight = graph[node][u] + graph[node][v]
        _add_edge(graph, u, v, weight)
        _remove_node(graph, node)

    changed = True
    while changed:
        changed = False
        for leaf in [node for node, edges in list(graph.items()) if len(edges) == 1]:
            if leaf not in graph or len(graph[leaf]) != 1:
                continue
            neighbor = next(iter(graph[leaf]))
            if graph[leaf][neighbor] < 20:
                _remove_node(graph, leaf)
                changed = True

    nodes = sorted(graph.keys())
    for i, u in enumerate(nodes):
        if u not in graph:
            continue
        for v in nodes[i + 1:]:
            if v not in graph:
                continue
            dist = np.sqrt((u[0] - v[0]) ** 2 + (u[1] - v[1]) ** 2)
            if dist < 15:
                for neighbor, weight in list(graph[v].items()):
                    if neighbor != u:
                        _add_edge(graph, u, neighbor, weight)
                _remove_node(graph, v)
    return graph


def extract_navgraph(semantic_map_path, out_path):
    img = cv2.imread(semantic_map_path)
    if img is None:
        raise ValueError(f"Could not load image at {semantic_map_path}")

    path_color = None
    for cid, info in CLASSES.items():
        if info['name'] == 'path':
            path_color = hex_to_bgr(info['authoring_color'])
            break
            
    if path_color is None:
        raise ValueError("Palette has no 'path' class")

    path_color_arr = np.array(path_color)
    diff = np.abs(img.astype(np.int32) - path_color_arr)
    mask = np.max(diff, axis=2) == 0

    skeleton = _zhang_suen_thinning(mask)
    graph = _simplify_graph(_build_graph(skeleton))
    nodes = sorted(graph.keys())
    edges = []
    for source in nodes:
        for target, weight in graph[source].items():
            if source < target:
                edges.append((source, target, weight))
    edges.sort()

    output_data = {
        "nodes": [{"id": f"{n[0]}_{n[1]}", "x": int(n[1]), "y": int(n[0])} for n in nodes],
        "edges": [{"source": f"{u[0]}_{u[1]}", "target": f"{v[0]}_{v[1]}", "weight": float(w)} for u, v, w in edges]
    }
    
    with open(out_path, 'w') as f:
        json.dump(output_data, f, indent=2)

if __name__ == '__main__':
    if len(sys.argv) < 3:
        print("Usage: python navgraph.py <in_semantic_map> <out_navgraph>")
        sys.exit(1)
    extract_navgraph(sys.argv[1], sys.argv[2])
