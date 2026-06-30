import argparse
import json
import os
import sys
import tempfile
from pathlib import Path

import cv2
import numpy as np
import yaml

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), "../../..")))
from app.shared.palette import CLASSES
from app.tools.arena_compiler.derive import container
from app.tools.arena_compiler.derive import grid
from app.tools.arena_compiler.derive import navgraph
from app.tools.arena_compiler.derive import occupancy
from app.tools.arena_compiler.derive import platform_edges
from app.tools.arena_compiler.derive import track_centerline


DERIVED_FILES = (
    "navgraph.json",
    "container.json",
    "grid.json",
    "occupancy.png",
    "platform_edges.json",
    "track_centerline.json",
    "authoring_profile.json",
)


def hex_to_bgr(hex_str):
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i:i + 2], 16) for i in (4, 2, 0))


def _class_bgr(class_name):
    for info in CLASSES.values():
        if info["name"] == class_name:
            return hex_to_bgr(info["authoring_color"])
    raise ValueError(f"Palette has no '{class_name}' class")


def _read_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def _read_yaml(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = yaml.safe_load(f)
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def _resolve_level_and_source(input_path, allow_legacy_occupancy=True):
    path = Path(input_path)
    if path.is_file():
        return path.parent, path, "semantic_map"

    level_dir = path
    semantic_map = level_dir / "semantic_map.png"
    if semantic_map.exists():
        return level_dir, semantic_map, "semantic_map"

    if allow_legacy_occupancy:
        for candidate in (level_dir / "derived" / "occupancy.png", level_dir / "occupancy.png"):
            if candidate.exists():
                return level_dir, candidate, "legacy_occupancy"

    raise FileNotFoundError(f"No semantic_map.png found for level: {level_dir}")


def _cell_px(level_dir, explicit_cell_px=None):
    if explicit_cell_px:
        return int(explicit_cell_px)

    level_yaml = _read_yaml(level_dir / "level.yaml")
    procedural = level_yaml.get("procedural", {})
    if isinstance(procedural, dict):
        grid_config = procedural.get("grid", {})
        if isinstance(grid_config, dict) and grid_config.get("cell_px"):
            return int(grid_config["cell_px"])

    settings = _read_json(level_dir / "settings.json")
    if isinstance(settings, dict) and settings.get("cell_px"):
        return int(settings["cell_px"])

    existing_grid = _read_json(level_dir / "derived" / "grid.json")
    if isinstance(existing_grid, dict) and existing_grid.get("cell_px"):
        return int(existing_grid["cell_px"])

    return 32


def _semantic_from_legacy_occupancy(occupancy_path, semantic_path):
    img = cv2.imread(str(occupancy_path), cv2.IMREAD_GRAYSCALE)
    if img is None:
        raise ValueError(f"Could not load legacy occupancy at {occupancy_path}")

    solid = np.array(_class_bgr("solid"), dtype=np.uint8)
    path = np.array(_class_bgr("path"), dtype=np.uint8)
    semantic = np.zeros((img.shape[0], img.shape[1], 3), dtype=np.uint8)
    semantic[:] = solid
    semantic[img > 0] = path
    cv2.imwrite(str(semantic_path), semantic)
    return semantic_path


def _normalize_json_file(path):
    data = _read_json(path)
    if data is None:
        return
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")


def _image_size(source_path):
    img = cv2.imread(str(source_path), cv2.IMREAD_UNCHANGED)
    if img is None:
        return {"width": 0, "height": 0}
    return {"width": int(img.shape[1]), "height": int(img.shape[0])}


def _default_authoring_profile(level_dir, source_name, source_kind, cell_px, source_path):
    return {
        "schema": "authoring_profile",
        "version": "1.0.0",
        "intent": "compile_all_derived",
        "level_id": level_dir.name,
        "compiler": {
            "entry_point": "app/tools/arena_compiler/compile_level.py",
            "source": source_name,
            "source_kind": source_kind,
            "cell_px": int(cell_px),
            "image_size": _image_size(source_path),
            "derived_files": list(DERIVED_FILES),
        },
    }


def _write_authoring_profile(out_path, profile, level_dir, source_name, source_kind, cell_px, source_path):
    data = dict(profile) if isinstance(profile, dict) else {}
    if not data:
        data = _default_authoring_profile(level_dir, source_name, source_kind, cell_px, source_path)
    data.setdefault("schema", "authoring_profile")
    data.setdefault("version", "1.0.0")
    data.setdefault("intent", "compile_all_derived")
    data["compiler"] = {
        "entry_point": "app/tools/arena_compiler/compile_level.py",
        "source": source_name,
        "source_kind": source_kind,
        "cell_px": int(cell_px),
        "image_size": _image_size(source_path),
        "derived_files": list(DERIVED_FILES),
    }
    with open(out_path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=2, sort_keys=True)
        f.write("\n")


def compile_level(input_path, out_dir=None, cell_px=None, authoring_profile=None, allow_legacy_occupancy=True):
    """Regenerate the full derived set for one level directory or semantic map."""
    level_dir, source_path, source_kind = _resolve_level_and_source(input_path, allow_legacy_occupancy)
    output_dir = Path(out_dir) if out_dir else level_dir / "derived"
    output_dir.mkdir(parents=True, exist_ok=True)
    resolved_cell_px = _cell_px(level_dir, cell_px)

    temp_dir = None
    semantic_path = source_path
    source_name = source_path.name
    try:
        if source_kind == "legacy_occupancy":
            temp_dir = tempfile.TemporaryDirectory()
            semantic_path = Path(temp_dir.name) / "semantic_from_occupancy.png"
            _semantic_from_legacy_occupancy(source_path, semantic_path)
            try:
                source_name = str(source_path.relative_to(level_dir)).replace("\\", "/")
            except ValueError:
                source_name = source_path.name

        steps = (
            ("navgraph", navgraph.extract_navgraph, (semantic_path, output_dir / "navgraph.json"), {}),
            ("container", container.extract_container, (semantic_path, output_dir / "container.json"), {}),
            ("occupancy", occupancy.generate_occupancy, (semantic_path, output_dir / "occupancy.png"), {}),
            ("grid", grid.generate_grid, (semantic_path, output_dir / "grid.json"), {"cell_px": resolved_cell_px, "verbose": False}),
            ("platform_edges", platform_edges.extract_platform_edges, (semantic_path, output_dir / "platform_edges.json"), {}),
            ("track_centerline", track_centerline.extract_track_centerline, (semantic_path, output_dir / "track_centerline.json"), {}),
        )
        for name, fn, args, kwargs in steps:
            try:
                fn(*(str(arg) for arg in args), **kwargs)
            except Exception as exc:
                raise RuntimeError(f"{name}: {exc}") from exc

        for json_name in (
            "navgraph.json",
            "container.json",
            "grid.json",
            "platform_edges.json",
            "track_centerline.json",
        ):
            _normalize_json_file(output_dir / json_name)

        _write_authoring_profile(
            output_dir / "authoring_profile.json",
            authoring_profile,
            level_dir,
            source_name,
            source_kind,
            resolved_cell_px,
            semantic_path,
        )

        return {
            "level_dir": str(level_dir),
            "derived_dir": str(output_dir),
            "source_kind": source_kind,
            "cell_px": resolved_cell_px,
            "files": [str(output_dir / name) for name in DERIVED_FILES],
        }
    finally:
        if temp_dir:
            temp_dir.cleanup()


def compile_all_levels(scenes_root, allow_legacy_occupancy=True):
    scenes_root = Path(scenes_root)
    results = []
    for level_dir in sorted(scenes_root.glob("*/levels/*")):
        if not level_dir.is_dir():
            continue
        results.append(compile_level(level_dir, allow_legacy_occupancy=allow_legacy_occupancy))
    return results


def verify_level_complete(level_dir):
    derived_dir = Path(level_dir) / "derived"
    return all((derived_dir / name).exists() for name in DERIVED_FILES)


def main(argv=None):
    parser = argparse.ArgumentParser(description="Compile all derived layers for one KE_ArKade level.")
    parser.add_argument("input", help="Level directory or semantic_map.png")
    parser.add_argument("--out-dir", help="Override derived output directory")
    parser.add_argument("--cell-px", type=int, help="Override grid cell size")
    parser.add_argument("--no-legacy-occupancy", action="store_true", help="Require semantic_map.png for level dirs")
    args = parser.parse_args(argv)

    result = compile_level(
        args.input,
        out_dir=args.out_dir,
        cell_px=args.cell_px,
        allow_legacy_occupancy=not args.no_legacy_occupancy,
    )
    print(json.dumps(result, indent=2, sort_keys=True))


if __name__ == "__main__":
    main()
