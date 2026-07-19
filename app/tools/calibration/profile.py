"""Calibration profile helpers for KE_ArKade output mapping.

Profiles describe the final output warp after a cartridge has rendered a
normal 1920x1080 frame. The same format supports simple four-corner pinning
and denser mesh refinement.
"""

from __future__ import annotations

import argparse
import datetime as _dt
import json
import os
import re
from pathlib import Path
from typing import Any

try:
    import yaml
except ModuleNotFoundError:
    yaml = None


SCHEMA = "ke_arkade.calibration_profile"
VERSION = "1.1.0"
DEFAULT_WIDTH = 1920
DEFAULT_HEIGHT = 1080
PROFILE_ID_RE = re.compile(r"^[a-z0-9][a-z0-9_-]*$")


def utc_now_iso() -> str:
    return _dt.datetime.now(_dt.UTC).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def parse_mesh(value: str) -> tuple[int, int]:
    text = value.lower().replace(",", "x").strip()
    parts = [p for p in text.split("x") if p]
    if len(parts) != 2:
        raise ValueError("mesh must look like 2x2, 3x3, or 4x4")
    cols, rows = int(parts[0]), int(parts[1])
    if cols < 2 or rows < 2:
        raise ValueError("mesh must be at least 2x2 vertices")
    if cols > 16 or rows > 16:
        raise ValueError("mesh is capped at 16x16 vertices for interactive calibration")
    return cols, rows


def _grid_point(col: int, row: int, cols: int, rows: int, width: int, height: int) -> list[float]:
    x = 0.0 if cols == 1 else (width - 1) * (col / float(cols - 1))
    y = 0.0 if rows == 1 else (height - 1) * (row / float(rows - 1))
    return [round(x, 3), round(y, 3)]


def build_mesh_pins(cols: int, rows: int, width: int, height: int) -> list[dict[str, Any]]:
    pins: list[dict[str, Any]] = []
    for row in range(rows):
        for col in range(cols):
            point = _grid_point(col, row, cols, rows, width, height)
            edge = row == 0 or col == 0 or row == rows - 1 or col == cols - 1
            corner = (row in (0, rows - 1)) and (col in (0, cols - 1))
            pins.append(
                {
                    "id": f"r{row}_c{col}",
                    "row": row,
                    "col": col,
                    "source": point,
                    "target": list(point),
                    "role": "corner" if corner else "edge" if edge else "interior",
                }
            )
    return pins


def new_profile(
    profile_id: str,
    label: str,
    width: int = DEFAULT_WIDTH,
    height: int = DEFAULT_HEIGHT,
    mesh: tuple[int, int] = (2, 2),
    display_index: int = 0,
    scene_id: str = "",
) -> dict[str, Any]:
    profile_id = profile_id.strip()
    if not PROFILE_ID_RE.match(profile_id):
        raise ValueError("profile_id must be lowercase letters, numbers, hyphens, or underscores")
    cols, rows = mesh
    now = utc_now_iso()
    return {
        "schema": SCHEMA,
        "version": VERSION,
        "profile_id": profile_id,
        "label": label.strip() or profile_id,
        "scope": "preset",
        "scene_id": scene_id,
        "created_at": now,
        "updated_at": now,
        "source_space": {
            "name": "canonical_frame",
            "width": int(width),
            "height": int(height),
        },
        "output": {
            "display_index": int(display_index),
            "native_resolution": [int(width), int(height)],
        },
        "workflow": {
            "apply_to": "final_output_frame",
            "operator_view": "same_window",
            "notes": "Use 2x2 for global corner pinning; increase mesh_size for local wall refinement.",
        },
        "warp": {
            "mode": "mesh",
            "mesh_size": [cols, rows],
            "interpolation": "piecewise_bilinear",
            "pins": build_mesh_pins(cols, rows, int(width), int(height)),
        },
    }


def validate_profile(profile: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if profile.get("schema") != SCHEMA:
        errors.append(f"schema must be {SCHEMA}")
    if not PROFILE_ID_RE.match(str(profile.get("profile_id", ""))):
        errors.append("profile_id is missing or invalid")

    source = profile.get("source_space", {})
    width = source.get("width")
    height = source.get("height")
    if not isinstance(width, int) or not isinstance(height, int) or width <= 0 or height <= 0:
        errors.append("source_space.width and source_space.height must be positive ints")

    warp = profile.get("warp", {})
    if warp.get("mode") != "mesh":
        errors.append("warp.mode must be mesh")
    mesh_size = warp.get("mesh_size")
    if not isinstance(mesh_size, list) or len(mesh_size) != 2:
        errors.append("warp.mesh_size must be [cols, rows]")
        cols = rows = 0
    else:
        cols, rows = mesh_size
        if not isinstance(cols, int) or not isinstance(rows, int) or cols < 2 or rows < 2:
            errors.append("warp.mesh_size entries must be ints >= 2")

    pins = warp.get("pins", [])
    if not isinstance(pins, list):
        errors.append("warp.pins must be a list")
        pins = []
    elif mesh_size and isinstance(mesh_size, list) and len(mesh_size) == 2:
        expected = int(mesh_size[0]) * int(mesh_size[1])
        if len(pins) != expected:
            errors.append(f"warp.pins must contain {expected} pins for mesh_size {mesh_size}")

    seen: set[tuple[int, int]] = set()
    for idx, pin in enumerate(pins):
        if not isinstance(pin, dict):
            errors.append(f"pin {idx} must be an object")
            continue
        row = pin.get("row")
        col = pin.get("col")
        if not isinstance(row, int) or not isinstance(col, int):
            errors.append(f"pin {idx} row/col must be ints")
        else:
            key = (row, col)
            if key in seen:
                errors.append(f"duplicate pin at row={row} col={col}")
            seen.add(key)
        for field in ("source", "target"):
            point = pin.get(field)
            if (
                not isinstance(point, list)
                or len(point) != 2
                or not all(isinstance(v, (int, float)) for v in point)
            ):
                errors.append(f"pin {idx} {field} must be [x, y] numbers")
    return errors


def load_profile(path: Path) -> dict[str, Any]:
    with path.open("r", encoding="utf-8") as handle:
        if yaml:
            data = yaml.safe_load(handle) or {}
        else:
            data = json.load(handle)
    if not isinstance(data, dict):
        raise ValueError("profile file must contain a YAML object")
    return data


def save_profile(path: Path, profile: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temp_path = path.with_suffix(path.suffix + ".tmp")
    with temp_path.open("w", encoding="utf-8", newline="\n") as handle:
        if yaml:
            yaml.safe_dump(profile, handle, sort_keys=False, allow_unicode=False)
        else:
            json.dump(profile, handle, indent=2)
            handle.write("\n")
    os.replace(temp_path, path)


def cmd_new(args: argparse.Namespace) -> int:
    mesh = parse_mesh(args.mesh)
    profile = new_profile(
        profile_id=args.profile_id,
        label=args.label,
        width=args.width,
        height=args.height,
        mesh=mesh,
        display_index=args.display_index,
        scene_id=args.scene_id,
    )
    errors = validate_profile(profile)
    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1
    save_profile(Path(args.out), profile)
    print(f"wrote {args.out}")
    return 0


def cmd_validate(args: argparse.Namespace) -> int:
    profile = load_profile(Path(args.path))
    errors = validate_profile(profile)
    if errors:
        for error in errors:
            print("ERROR:", error)
        return 1
    print(f"{args.path} is valid")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Create and validate KE_ArKade calibration profiles.")
    sub = parser.add_subparsers(dest="command", required=True)

    new_cmd = sub.add_parser("new", help="create a neutral calibration preset")
    new_cmd.add_argument("out", help="output YAML path")
    new_cmd.add_argument("--profile-id", required=True)
    new_cmd.add_argument("--label", default="")
    new_cmd.add_argument("--width", type=int, default=DEFAULT_WIDTH)
    new_cmd.add_argument("--height", type=int, default=DEFAULT_HEIGHT)
    new_cmd.add_argument("--mesh", default="2x2")
    new_cmd.add_argument("--display-index", type=int, default=0)
    new_cmd.add_argument("--scene-id", default="")
    new_cmd.set_defaults(func=cmd_new)

    validate_cmd = sub.add_parser("validate", help="validate a calibration profile")
    validate_cmd.add_argument("path")
    validate_cmd.set_defaults(func=cmd_validate)
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return int(args.func(args))


if __name__ == "__main__":
    raise SystemExit(main())
