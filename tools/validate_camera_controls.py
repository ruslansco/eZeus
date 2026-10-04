#!/usr/bin/env python3
"""Validate camera bindings; optionally capture the designated test city.

Requires the project's C++/SDL build dependencies. In-game checks also require
macOS display access and a rebuilt, deployed, ad-hoc-signed Bin/eZeus.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
import time


REPO = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def bindings_test():
    sources = ["tests/camera_controls_smoke.cpp", "esettings.cpp", "egamedir.cpp",
               "eloadtexthelper.cpp", "estringhelpers.cpp", "widgets/emouseevent.cpp",
               "widgets/eresolution.cpp"]
    flags = shlex.split(subprocess.check_output(
        ["pkg-config", "--cflags", "--libs", "sdl2", "SDL2_image", "SDL2_ttf", "SDL2_mixer"], text=True))
    with tempfile.TemporaryDirectory(prefix="ezeus-camera-bindings-") as directory:
        exe = Path(directory) / "eZeus/Bin/camera_controls_smoke"
        exe.parent.mkdir(parents=True)
        subprocess.run(["c++", "-std=c++17", "-O1", "-I.", *sources, *flags, "-o", str(exe)], cwd=REPO, check=True)
        subprocess.run(["codesign", "--force", "--sign", "-", str(exe)], check=True, capture_output=True)
        env = os.environ.copy()
        # The smoke test intentionally writes its own disposable settings.
        env.pop("EZEUS_SHOT", None)
        env.pop("EZEUS_MENU_SHOT", None)
        subprocess.run([str(exe)], env=env, check=True)


def city_test(output):
    save = REPO / "Save/Hippodamus/CLAUDE-TESTING-ADVENTURE.ez"
    if not save.is_file():
        raise RuntimeError("Designated test save is missing")
    protected = [save, REPO / "settings.txt"]
    before = {str(path): digest(path) for path in protected}
    cases = [(f"view-{d}", d, "en", "1920x1080", False, 1) for d in range(4)]
    cases += [(f"controls-{lang}-{size}", 0, lang, size, True, 1)
              for lang in ("en", "ru") for size in ("1280x720", "2560x1440")]
    cases += [(f"zoom-{zoom}", 0, "en", "1920x1080", False, zoom) for zoom in (2, 3)]
    results = []
    try:
        for name, direction, lang, size, controls, zoom in cases:
            image = output / (name + ".png")
            env = {key: value for key, value in os.environ.items() if not key.startswith("EZEUS_")}
            env.update(EZEUS_SHOT=f"{save};{image};{zoom};0.5;0.5", EZEUS_SHOT_DIR=str(direction),
                       EZEUS_TEST_CAMERA="1", EZEUS_MENU_SHOT_LANG=lang, EZEUS_MENU_SHOT_SIZE=size)
            if controls:
                env["EZEUS_SHOT_CONTROLS"] = "1"
            started = time.monotonic()
            result = subprocess.run([str(REPO / "Bin/eZeus")], env=env, cwd=REPO,
                                    capture_output=True, text=True, timeout=180)
            log = output / (name + ".log")
            log.write_text(result.stdout + result.stderr, encoding="utf-8")
            if result.returncode or "TEST_CAMERA PASS" not in result.stdout or not image.is_file():
                raise RuntimeError(f"{name} failed; inspect {log}")
            entry = {"case": name, "seconds": round(time.monotonic() - started, 1),
                     "screenshot": str(image), "passed": True}
            results.append(entry)
            print(json.dumps(entry), flush=True)
    finally:
        unchanged = before == {str(path): digest(path) for path in protected}
        (output / "validation.json").write_text(json.dumps(
            {"cases": results, "protected_files_unchanged": unchanged}, indent=2) + "\n", encoding="utf-8")
        if not unchanged:
            raise RuntimeError("Player settings or test save changed")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--in-game", action="store_true")
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    bindings_test()
    if args.in_game:
        output = args.output or Path(tempfile.mkdtemp(prefix="ezeus-camera-captures-"))
        output = output.resolve()
        output.mkdir(parents=True, exist_ok=True)
        city_test(output)
        print(f"Validation captures: {output}")


if __name__ == "__main__":
    main()
