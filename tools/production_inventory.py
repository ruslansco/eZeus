#!/usr/bin/env python3
"""Inventory release candidates without assuming that new artwork is cleared.

Uses file metadata only; never opens saves, executes Blender, or changes assets.
This is discovery, not a legal clearance or a release-package validator.
"""
import argparse
import json
import os
from collections import Counter
from pathlib import Path


def summarize(root, relative, status, reason):
    base = root / relative
    files, links, errors = [], [], []
    if base.is_symlink():
        links.append(relative)
    elif base.is_file():
        files.append(base)
    elif base.is_dir():
        def onerror(error):
            errors.append(str(error))
        for directory, dirs, names in os.walk(base, followlinks=False, onerror=onerror):
            for name in list(dirs):
                path = Path(directory) / name
                if path.is_symlink():
                    links.append(path.relative_to(root).as_posix())
                    dirs.remove(name)
            for name in names:
                path = Path(directory) / name
                if path.is_symlink():
                    links.append(path.relative_to(root).as_posix())
                else:
                    files.append(path)
    sizes = []
    for path in sorted(files):
        try:
            sizes.append((path, path.stat().st_size))
        except OSError as error:
            errors.append(str(error))
    return {
        "path": relative, "review_status": status, "reason": reason,
        "file_count": len(sizes), "bytes": sum(size for _, size in sizes),
        "extensions": dict(sorted(Counter(path.suffix.lower() or "<none>" for path, _ in sizes).items())),
        "examples": [path.relative_to(root).as_posix() for path, _ in sizes[:3]],
        "symlinks_not_followed": links, "read_errors": errors,
    }


def inventory(root):
    groups = []
    def add(path, status="needs_evidence", reason="Record creator, source inputs, commercial rights and attribution; directory name is not clearance."):
        if (root / path).exists() or (root / path).is_symlink():
            groups.append(summarize(root, path, status, reason))
    legacy = "Original or compatibility material: exclude from independent release unless specific distribution rights are documented."
    for path in ("DATA", "Audio", "Model", "Adventures", "Binks", "Zeus.exe", "poseidon adventure editor.pdf"):
        add(path, "exclude_or_license", legacy)
    textures = root / "Textures"
    if textures.is_dir():
        for path in sorted(textures.iterdir()):
            relative = path.relative_to(root).as_posix()
            if path.name == "Remastered" and path.is_dir() and not path.is_symlink():
                for family in sorted(path.iterdir()):
                    if family.name == "characters" and family.is_dir() and not family.is_symlink():
                        for character in sorted(family.iterdir()):
                            add(character.relative_to(root).as_posix())
                    else:
                        add(family.relative_to(root).as_posix())
            else:
                original = "Original" in path.name or "backup" in path.name.lower() or path.name == "_disabled"
                add(relative, "exclude_or_license" if original else "needs_evidence", legacy if original else
                    "Audit source images and derived masks as well as final textures; runtime may still fall back to original resources.")
    engine = root / "eZeus"
    for pattern in ("*.e", "Zeus_Text*.xml", "Zeus_MM*.xml"):
        for path in sorted(engine.glob(pattern)):
            add(path.relative_to(root).as_posix(), "exclude_or_license", legacy)
    for path in ("eZeus/fonts", "eZeus/text", "eZeus/Adventures", "eZeus/textureTemplates"):
        add(path)
    add("eZeus/LICENSE.md", "retain_notice", "Engine GPLv3 license; preserve notices and satisfy corresponding-source obligations when distributing covered code.")
    scenes, manifests = [], []
    for directory, dirs, names in os.walk(root / "art", followlinks=False):
        dirs[:] = [name for name in dirs if not (Path(directory) / name).is_symlink()]
        for name in names:
            path = Path(directory) / name
            if path.is_symlink():
                continue
            if path.suffix.lower() == ".blend":
                scenes.append(path.relative_to(root).as_posix())
            if name in ("manifest.json", "rollout.json", "DESIGN_REFERENCE.md"):
                manifests.append(path.relative_to(root).as_posix())
    return {
        "schema_version": 1, "scope": "Runtime asset families plus art source-scene references; saves and build outputs excluded.",
        "release_cleared": False,
        "limitations": "Metadata discovery only. No content hashes, transitive dependency proof, code license audit or rights approvals. Deleted/new paths require regeneration.",
        "totals": {"families": len(groups), "files": sum(g["file_count"] for g in groups),
                   "bytes": sum(g["bytes"] for g in groups), "blend_scenes": len(scenes)},
        "families": groups, "blend_scenes": sorted(scenes), "art_evidence_candidates": sorted(manifests),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    if not (root / "eZeus/LICENSE.md").is_file():
        parser.error("root must contain eZeus/LICENSE.md")
    report = inventory(root)
    output = args.output or root / "eZeus/docs/asset-inventory.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"report": str(output), **report["totals"], "release_cleared": False}))
    return 1 if any(g["read_errors"] for g in report["families"]) else 0


if __name__ == "__main__":
    raise SystemExit(main())
