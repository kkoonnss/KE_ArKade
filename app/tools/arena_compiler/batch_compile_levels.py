import argparse
import json
import os
import sys
from pathlib import Path

sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..')))

from app.tools.arena_compiler.compile_level import DERIVED_FILES
from app.tools.arena_compiler.compile_level import compile_all_levels
from app.tools.arena_compiler.compile_level import verify_level_complete


def main(argv=None):
    parser = argparse.ArgumentParser(description="Compile full derived layers for every level in content/scenes.")
    parser.add_argument(
        "--scenes-root",
        default=str(Path(__file__).resolve().parents[3] / "content" / "scenes"),
        help="Path to content/scenes",
    )
    parser.add_argument("--no-legacy-occupancy", action="store_true", help="Skip levels without semantic_map.png")
    args = parser.parse_args(argv)

    scenes_root = Path(args.scenes_root)
    results = compile_all_levels(scenes_root, allow_legacy_occupancy=not args.no_legacy_occupancy)
    incomplete = [
        str(path)
        for path in sorted(scenes_root.glob("*/levels/*"))
        if path.is_dir() and not verify_level_complete(path)
    ]
    report = {
        "scenes_root": str(scenes_root),
        "compiled_count": len(results),
        "required_files": list(DERIVED_FILES),
        "incomplete": incomplete,
        "results": results,
    }
    print(json.dumps(report, indent=2, sort_keys=True))
    if incomplete:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
