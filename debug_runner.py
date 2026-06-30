import argparse
import os
import subprocess
import sys
from datetime import datetime


APP_DIR = os.path.abspath(os.path.dirname(__file__))
GODOT_EXE = os.path.join(APP_DIR, "Godot_v4.3-stable_win64_console.exe")
if not os.path.exists(GODOT_EXE):
    GODOT_EXE = os.path.join(APP_DIR, "Godot_v4.3-stable_win64.exe")

CARTRIDGES_DIR = os.path.join(APP_DIR, "content", "cartridges")
SCENES_DIR = os.path.join(APP_DIR, "content", "scenes")
QA_DIR = os.path.join(APP_DIR, "vault", "70-qa")
TMP_DIR = os.path.join(APP_DIR, "scratch")

SYMPTOMS = {
    "launch": "Game does not open, crashes, or instantly restarts",
    "input": "Movement, aiming, or buttons feel wrong",
    "ipc": "Hub launch, ready, score, or heartbeat looks broken",
    "visual": "Cover art, splash, crop, scaling, or rendering looks wrong",
    "level": "Custom/classic level compatibility or spawn behavior is wrong",
}


def read_manifest_value(manifest_path: str, key: str) -> str:
    if not os.path.exists(manifest_path):
        return ""
    with open(manifest_path, "r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith(f"{key}:"):
                return line.split(":", 1)[1].strip().strip('"').strip("'")
    return ""


def read_project_name(project_path: str) -> str:
    if not os.path.exists(project_path):
        return ""
    with open(project_path, "r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            if line.startswith('config/name='):
                return line.split("=", 1)[1].strip().strip('"')
    return ""


def list_dirs(path: str) -> list[str]:
    return sorted(
        [
            name
            for name in os.listdir(path)
            if os.path.isdir(os.path.join(path, name))
        ]
    )


def choose_from_list(label: str, values: list[str], default_index: int = 0) -> str:
    print(f"\nAvailable {label}:")
    for idx, value in enumerate(values, 1):
        print(f" {idx}. {value}")
    raw = input(f"Select {label} (1-{len(values)}) [default {default_index + 1}]: ").strip()
    if raw.isdigit():
        idx = int(raw) - 1
        if 0 <= idx < len(values):
            return values[idx]
    return values[default_index]


def run_command(args: list[str], timeout: int = 15) -> dict:
    try:
        proc = subprocess.run(
            args,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            text=True,
            timeout=timeout,
            encoding="utf-8",
            errors="replace",
        )
        return {
            "ok": proc.returncode == 0,
            "returncode": proc.returncode,
            "output": proc.stdout.strip(),
            "timed_out": False,
            "environment_blocked": "Failed to open user://logs" in (proc.stdout or ""),
            "cmd": " ".join(args),
        }
    except subprocess.TimeoutExpired as exc:
        output = (exc.stdout or "").strip()
        return {
            "ok": False,
            "returncode": None,
            "output": output,
            "timed_out": True,
            "environment_blocked": "Failed to open user://logs" in output,
            "cmd": " ".join(args),
        }


def detect_findings(symptom: str, checks: list[dict]) -> list[str]:
    findings = []
    environment_blocked = False
    for check in checks:
        if check.get("environment_blocked"):
            environment_blocked = True
            continue
        if not check["ok"]:
            if check["name"] == "headless_launch":
                findings.append("Headless cartridge boot failed, so the problem is below hub/UI level.")
            elif check["name"] == "level_smoke":
                findings.append("Cartridge booted headless but failed when scene/level args were applied.")
            elif check["name"] == "screenshot_smoke":
                findings.append("Gameplay screenshot smoke did not complete, which usually means startup flow or post-splash timing is unhealthy.")
    if symptom == "ipc":
        findings.append("IPC symptoms are usually one of three things: cartridge never sends `ready`, sends it before socket connection, or misses heartbeat after startup.")
    if symptom == "input":
        findings.append("Input bugs usually live in cartridge-side movement/aim persistence, not the hub.")
    if symptom == "level":
        findings.append("Level issues usually come from spawn selection, cell walkability, inverted solids, or level-specific tuning.")
    if environment_blocked:
        findings.insert(0, "This run was partially blocked by the environment before Godot could fully initialize, so the result is not a clean cartridge verdict yet.")
    return findings


def next_questions(symptom: str, cartridge: str, scene: str, level: str) -> list[str]:
    questions = {
        "launch": [
            f"Does `{cartridge}` fail only from the hub, or also when launched directly with `{scene}/{level}`?",
            "Does it reach splash and then die, or never paint a frame at all?",
            "If it restarts, is there a game-over/reset loop in `_process` or `_handle_ipc(load)`?",
        ],
        "input": [
            "Is the problem keyboard-only, controller-only, or both?",
            "Does direction reset when the player stops moving, suggesting aim/facing persistence is missing?",
            "Is movement snapping to walkable cells, causing jitter or unwanted reversal?",
        ],
        "ipc": [
            "Does the hub log ever show `Cartridge connected to socket` and `Received: {\"type\":\"ready\"}`?",
            "If `ready` appears, do heartbeats continue every ~1s after splash?",
            "Are score/state messages using the expected NDJSON envelope with `type` and `data`?",
        ],
        "visual": [
            "Is the issue in `thumbnail.png`, `splash.png`, start menu composition, or live in-game scaling?",
            "Does the cartridge look correct on `scene_demo_wall` but wrong on `scene_classic_pack`?",
            "Is the reference image overlay or tab menu covering gameplay in a way that blocks tuning?",
        ],
        "level": [
            "Does the bug happen on both `demo_level` and the classic tester level?",
            "Are entities spawning inside solids because nearest-walkable fallback is missing or not applied everywhere?",
            "Does the cartridge need per-level tuning loaded from saved settings rather than another map asset?",
        ],
    }
    return questions[symptom]


def write_report(report_path: str, payload: dict) -> None:
    lines = [
        "# Debug Doctor Report",
        "",
        f"Date: {payload['timestamp']}",
        f"Cartridge: `{payload['cartridge']}`",
        f"Symptom: `{payload['symptom']}`",
        f"Scene: `{payload['scene']}`",
        f"Level: `{payload['level']}`",
        "",
        "## Metadata",
        "",
        f"- Project name: `{payload['project_name'] or 'missing'}`",
        f"- Manifest game name: `{payload['manifest_name'] or 'missing'}`",
        f"- Godot executable: `{payload['godot_exe']}`",
        "",
        "## Checks",
        "",
    ]
    for check in payload["checks"]:
        status = "PASS" if check["ok"] else "FAIL"
        if check["timed_out"]:
            status = "TIMEOUT"
        if check.get("environment_blocked"):
            status += " (ENVIRONMENT-BLOCKED)"
        lines.append(f"- `{check['name']}`: {status}")
        lines.append(f"  cmd: `{check['cmd']}`")
        if check["output"]:
            trimmed = check["output"][:1200]
            lines.append("  output:")
            lines.append("```text")
            lines.append(trimmed)
            lines.append("```")
    lines.extend(
        [
            "",
            "## Findings",
            "",
        ]
    )
    for finding in payload["findings"]:
        lines.append(f"- {finding}")
    lines.extend(
        [
            "",
            "## Next Technical Questions",
            "",
        ]
    )
    for question in payload["questions"]:
        lines.append(f"- {question}")
    with open(report_path, "w", encoding="utf-8") as handle:
        handle.write("\n".join(lines) + "\n")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="KE_ArKade symptom-based debug doctor")
    parser.add_argument("--cartridge", help="Classic cartridge folder id, for example pacman or battlezone")
    parser.add_argument("--scene", help="Scene folder id, for example scene_demo_wall")
    parser.add_argument("--level", help="Level folder id inside the chosen scene")
    parser.add_argument("--symptom", choices=sorted(SYMPTOMS.keys()), help="Troubleshooting symptom to guide checks")
    parser.add_argument("--interactive-launch", action="store_true", help="Launch the cartridge normally after the automated checks")
    parser.add_argument("--timeout", type=int, default=15, help="Per-check timeout in seconds")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    if not os.path.exists(GODOT_EXE):
        print("Godot executable not found.")
        return 1

    os.makedirs(QA_DIR, exist_ok=True)
    os.makedirs(TMP_DIR, exist_ok=True)

    cartridges = [name for name in list_dirs(CARTRIDGES_DIR) if name != "loopback"]
    scenes = list_dirs(SCENES_DIR)

    symptom = args.symptom or choose_from_list("symptom", list(SYMPTOMS.keys()))
    cartridge = args.cartridge if args.cartridge in cartridges else choose_from_list("cartridge", cartridges)
    scene = args.scene if args.scene in scenes else choose_from_list("scene", scenes)

    levels_dir = os.path.join(SCENES_DIR, scene, "levels")
    levels = list_dirs(levels_dir)
    default_level = 0
    if scene == "scene_demo_wall" and "demo_level" in levels:
        default_level = levels.index("demo_level")
    level = args.level if args.level in levels else choose_from_list("level", levels, default_level)

    cart_path = os.path.join(CARTRIDGES_DIR, cartridge)
    scene_path = os.path.join(SCENES_DIR, scene)
    level_path = os.path.join(levels_dir, level)
    manifest_path = os.path.join(cart_path, "manifest.yaml")
    project_path = os.path.join(cart_path, "project.godot")
    screenshot_path = os.path.join(TMP_DIR, f"debug_doctor_{cartridge}_{level}.png")

    print("=========================================")
    print("      KE_ArKade Debug Doctor")
    print("=========================================")
    print(f"Symptom: {symptom} - {SYMPTOMS[symptom]}")
    print(f"Cartridge: {cartridge}")
    print(f"Scene: {scene}")
    print(f"Level: {level}")

    checks = []

    headless_cmd = [GODOT_EXE, "--headless", "--path", cart_path, "--quit"]
    checks.append({"name": "headless_launch", **run_command(headless_cmd, timeout=args.timeout)})

    level_cmd = [
        GODOT_EXE,
        "--headless",
        "--path",
        cart_path,
        "--quit-after",
        "8",
        "--",
        "--scene",
        scene_path,
        "--level",
        level_path,
        "--ipc",
        "0",
    ]
    checks.append({"name": "level_smoke", **run_command(level_cmd, timeout=max(args.timeout, 12))})

    if symptom in ["launch", "visual", "level"]:
        screenshot_cmd = [
            GODOT_EXE,
            "--headless",
            "--path",
            cart_path,
            "--quit-after",
            "10",
            "--",
            "--scene",
            scene_path,
            "--level",
            level_path,
            "--ipc",
            "0",
            "--screenshot",
            screenshot_path,
        ]
        checks.append({"name": "screenshot_smoke", **run_command(screenshot_cmd, timeout=max(args.timeout, 14))})

    findings = detect_findings(symptom, checks)
    if not findings:
        findings.append("Automated checks passed, so the next step is targeted gameplay observation rather than basic boot repair.")

    report_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    report_stamp = datetime.now().strftime("%Y-%m-%d_%H%M%S")
    report_path = os.path.join(QA_DIR, f"debug_doctor_{cartridge}_{report_stamp}.md")
    payload = {
        "timestamp": report_time,
        "cartridge": cartridge,
        "symptom": symptom,
        "scene": scene,
        "level": level,
        "project_name": read_project_name(project_path),
        "manifest_name": read_manifest_value(manifest_path, "game_name"),
        "godot_exe": GODOT_EXE,
        "checks": checks,
        "findings": findings,
        "questions": next_questions(symptom, cartridge, scene, level),
    }
    write_report(report_path, payload)

    print("\nFindings:")
    for finding in findings:
        print(f" - {finding}")

    print("\nNext technical questions:")
    for question in payload["questions"]:
        print(f" - {question}")

    print(f"\nReport written to: {report_path}")

    if args.interactive_launch:
        run_cmd = [
            GODOT_EXE,
            "--path",
            cart_path,
            "--",
            "--scene",
            scene_path,
            "--level",
            level_path,
            "--ipc",
            "0",
        ]
        print(f"\nLaunching interactively: {' '.join(run_cmd)}")
        subprocess.run(run_cmd, check=False)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
