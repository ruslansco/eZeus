#!/usr/bin/env python3
"""Owned 1080p Metal camera profile with disposable saves/preferences.

The temporary city subclass only adds timers to the current _process body.
It is never installed into the game. Profile JSON is evidence, not an FPS gate.
"""
import hashlib
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
from run_godot_pilot import REPO, ROOT, GODOT, SAVE


def fingerprint(path):
    return hashlib.sha256(path.read_bytes()).hexdigest() if path.exists() else None


def instrumented_city():
    source = (REPO / "godot/scripts/main.gd").read_text()
    start = source.index("func _process(dt: float) -> void:")
    end = source.index("\n# The developer overlay", start)
    body = source[start:end].replace(
        "func _process(dt: float) -> void:\n",
        "func _process(dt: float) -> void:\n\tsection_start = Time.get_ticks_usec()\n", 1)
    marks = [
        ("\tfor entry in walkers.values():", "systems"),
        ("\twater_life.update_workers(self)", "walkers"),
        ("\twalker_streets.hover(self)", "workers_effects"),
        ("\tif frame_count % CitizenLod.CHECK_FRAMES", "hover_walkers"),
        ("\tif not state.is_empty():", "citizen_lod"),
        ("\t\tif get_viewport().gui_get_hovered_control() == null", "city_inspection"),
        ("\t\tif frame_count % 6 == 0", "picking"),
        ("\t\tif frame_count % 12 == 0", "minimap"),
        ("\t\tif frame_count % 30 == 0", "native_view_box"),
    ]
    for marker, label in marks:
        if marker not in body:
            raise RuntimeError(f"Profile section changed: {label}; update the reviewer")
        indent = "\t\t" if marker.startswith("\t\t") else "\t"
        body = body.replace(marker, indent + f'stamp("{label}")\n' + marker, 1)
    header = '''extends "res://scripts/main.gd"
var section_start := 0
var sections := {}
var profile_legacy := false
var profile_legacy_batches
func stamp(label: String) -> void:
	var now := Time.get_ticks_usec()
	if not sections.has(label): sections[label] = []
	sections[label].append((now-section_start)/1000.0)
	section_start = now
'''
    build_start = source.index("func update_buildings() -> void:")
    build_end = source.index("\n# Inventory/work changes", build_start)
    buildings = source[build_start:build_end].replace(
        "func update_buildings() -> void:\n",
        "func update_buildings() -> void:\n\tif profile_legacy:\n\t\tbaseline_update_buildings()\n\t\treturn\n", 1)
    baseline = (REPO / "tools/profile_baselines/update_buildings_pass1.gd").read_text().replace(
        "\thud.minimap.set_buildings(state.buildings)",
        "\tlegacy_chart()").replace(
        "\tstatic_batches.rebuild(groups)",
        "\tprofile_legacy_batches.rebuild(groups)")
    # Exact old chart painting, with the current native palette/coordinate transform.
    legacy = '''
func legacy_chart() -> void:
	var chart = hud.minimap
	chart.composed.copy_from(chart.terrain)
	for entry in state.buildings:
		var asset := str(entry.asset)
		if asset in ["native_marker", "terrain_road"]: continue
		var colour: Color = chart.HOUSE_COLOUR if asset.begins_with("common_house") or asset.begins_with("elite_house") else chart.BUILDING_COLOUR
		for dy in int(entry.h):
			for dx in int(entry.w):
				var pixel := Vector2i(int(entry.x)+dx-chart.origin.x, chart.extent.y-1-(int(entry.y)+dy-chart.origin.y))
				if pixel.x >= 0 and pixel.y >= 0 and pixel.x < chart.extent.x and pixel.y < chart.extent.y:
					chart.composed.set_pixelv(pixel, colour)
	chart.texture.update(chart.composed)
	chart.queue_redraw()
'''
    return header + body + "\n" + buildings + "\n" + baseline + legacy


def main():
    protected = [SAVE, REPO / "settings.txt", ROOT / "settings.txt",
                 Path.home() / "Library/Application Support/Godot/app_userdata/City Rebuild • 3D Pilot/settings.cfg"]
    before = {path: fingerprint(path) for path in protected}
    log = REPO / "godot/captures/camera-performance-review-engine.log"
    log.parent.mkdir(parents=True, exist_ok=True)
    try:
        with tempfile.TemporaryDirectory(prefix="ezeus-camera-profile-") as folder:
            temporary = Path(folder)
            script = temporary / "timed_city.gd"
            script.write_text(instrumented_city())
            env = os.environ.copy()
            env["EZEUS_REVIEW_SETTINGS_PATH"] = str(temporary / "settings.cfg")
            env["EZEUS_REVIEW_SAVE_DIRECTORY"] = str(temporary / "saves")
            env["EZEUS_CAMERA_PROFILE_SCRIPT"] = str(script)
            baseline = temporary / "legacy_batches.gd"
            baseline.write_text((REPO / "tools/profile_baselines/building_batches_pass1.gd").read_text())
            env["EZEUS_CAMERA_BASELINE_SCRIPT"] = str(baseline)
            log.write_text("")
            process = subprocess.Popen([
                str(GODOT), "--path", str(REPO / "godot"),
                "--rendering-method", "mobile", "--rendering-driver", "metal",
                "--script", "res://scripts/review_camera_performance.gd",
                "--log-file", str(log), "--", "--camera-profile-review", "--silent", "--lang=en",
                *(["--refresh-only"] if "--refresh-only" in sys.argv else [])
            ], cwd=REPO, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.STDOUT)
            deadline = time.monotonic() + 120
            try:
                while process.poll() is None:
                    time.sleep(.2)
                    output = log.read_text(errors="replace")
                    if "SCRIPT ERROR:" in output or time.monotonic() >= deadline:
                        process.terminate()
                        break
                process.wait(timeout=5)
            finally:
                if process.poll() is None:
                    process.kill()
                    process.wait()
            output = log.read_text(errors="replace")
            for line in output.splitlines():
                if line.startswith("CAMERA_") or "ERROR:" in line:
                    print(line, flush=True)
            if process.returncode or "CAMERA_PROFILE_VALIDATION PASS" not in output or "ERROR:" in output:
                raise RuntimeError(f"Camera profile failed; see {log}")
    finally:
        changed = [str(path) for path in protected if before[path] != fingerprint(path)]
        if changed:
            raise RuntimeError("Protected files changed: " + ", ".join(changed))
        print("Designated save and player preferences unchanged.", flush=True)


if __name__ == "__main__":
    main()
