#!/usr/bin/env python3
"""Build staged HD terrain atlases without changing the checked-in originals."""

from __future__ import annotations

import argparse
import re
import shutil
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageOps


ROOT = Path(__file__).resolve().parents[3]
TOOL_DIR = Path(__file__).resolve().parent
ENTRY_RE = re.compile(
    r"eSpriteData\{\s*(-?\d+),\s*(\d+),\s*(\d+),\s*(\d+),\s*(\d+)\s*\}"
    r"\s*,?\s*//\s*(\d+)"
)


@dataclass(frozen=True)
class Sprite:
    sheet: int
    x: int
    y: int
    width: int
    height: int
    number: int


JOBS = (
    {
        "name": "zeusLand1",
        "source": ROOT / "Textures/60/zeusLand1_0.png",
        "header": ROOT / "eZeus/spriteData/zeusLand160.h",
        "material": TOOL_DIR / "materials/aegean_dry_land.png",
        "ranges": ((106, 163),),
        "phase": (0.0, 0.0),
    },
    {
        "name": "zeusLand3",
        "source": ROOT / "Textures/60/zeusLand3_0.png",
        "header": ROOT / "eZeus/spriteData/zeusLand360.h",
        "material": TOOL_DIR / "materials/aegean_water.png",
        "ranges": ((99, 189),),
        "phase": (0.17, 0.29),
    },
)


def parse_header(path: Path) -> list[Sprite]:
    result = [Sprite(*(int(v) for v in m.groups())) for m in ENTRY_RE.finditer(path.read_text())]
    if not result:
        raise ValueError(f"No sprite metadata found in {path}")
    return result


def diamond_mask(width: int, height: int, supersample: int = 4) -> Image.Image:
    """Return the exact 2:1 footprint with antialiased one-pixel coverage."""
    scale = supersample
    mask = Image.new("L", (width * scale, height * scale), 0)
    draw = ImageDraw.Draw(mask)
    points = [
        (width * scale // 2, 0),
        (width * scale - 1, (height * scale - 1) // 2),
        (width * scale // 2, height * scale - 1),
        (0, (height * scale - 1) // 2),
    ]
    draw.polygon(points, fill=255)
    return mask.resize((width, height), Image.Resampling.LANCZOS)


def projected_material(material: Image.Image, width: int, height: int,
                       phase: tuple[float, float]) -> Image.Image:
    """Map periodic UV space to a dimetric diamond so all four edges agree."""
    original = material.convert("RGB")
    sw, sh = original.size
    # Mirrored repetition guarantees continuity even when a supplied master
    # material is attractive but not mathematically seamless at its borders.
    src = Image.new("RGB", (sw * 2, sh * 2))
    src.paste(original, (0, 0))
    src.paste(ImageOps.mirror(original), (sw, 0))
    src.paste(ImageOps.flip(original), (0, sh))
    src.paste(ImageOps.mirror(ImageOps.flip(original)), (sw, sh))
    sw, sh = src.size
    pixels = src.load()
    result = Image.new("RGB", (width, height))
    output = result.load()
    # Inverse 2:1 dimetric transform. The material is sampled periodically,
    # therefore u=0/1 and v=0/1 meet without a seam on neighboring tiles.
    for y in range(height):
        for x in range(width):
            u = x / width + y / height - 0.5 + phase[0]
            v = -x / width + y / height + 0.5 + phase[1]
            sx = int((u % 1.0) * sw) % sw
            sy = int((v % 1.0) * sh) % sh
            output[x, y] = pixels[sx, sy]
    return result


def extrude_rgb(rgba: Image.Image, radius: int) -> Image.Image:
    """Copy edge color into transparent pixels while leaving alpha unchanged."""
    image = rgba.copy()
    original_alpha = image.getchannel("A")
    known = {(x, y) for y in range(image.height) for x in range(image.width)
             if image.getpixel((x, y))[3] > 0}
    for _ in range(radius):
        additions: dict[tuple[int, int], tuple[int, int, int, int]] = {}
        for x, y in known:
            color = image.getpixel((x, y))
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1),
                           (-1, -1), (-1, 1), (1, -1), (1, 1)):
                point = (x + dx, y + dy)
                if (0 <= point[0] < image.width and 0 <= point[1] < image.height
                        and point not in known and point not in additions):
                    additions[point] = color
        for point, color in additions.items():
            image.putpixel(point, (color[0], color[1], color[2], 0))
        known.update(additions)
    image.putalpha(original_alpha)
    return image


def selected(number: int, ranges: tuple[tuple[int, int], ...]) -> bool:
    return any(lo <= number <= hi for lo, hi in ranges)


def build_job(job: dict, output_dir: Path, bleed: int) -> tuple[Path, int, list[str]]:
    source = Image.open(job["source"]).convert("RGBA")
    material = Image.open(job["material"]).convert("RGB")
    sprites = parse_header(job["header"])
    warnings: list[str] = []
    changed = 0

    for sprite in sprites:
        if sprite.sheet != 0 or not selected(sprite.number, job["ranges"]):
            continue
        if sprite.width != 116 or sprite.height != 60:
            warnings.append(
                f"sprite {sprite.number}: kept original {sprite.width}x{sprite.height} content"
            )
            continue
        tile = projected_material(material, sprite.width, sprite.height, job["phase"])
        tile.putalpha(diamond_mask(sprite.width, sprite.height))
        tile = extrude_rgb(tile, bleed)
        # Paste all four channels. Alpha compositing would discard the RGB held
        # by fully transparent bleed pixels, defeating anti-fringe filtering.
        source.paste(tile, (sprite.x, sprite.y))
        changed += 1

    output_dir.mkdir(parents=True, exist_ok=True)
    output = output_dir / f'{job["name"]}_0.png'
    source.save(output, "PNG", optimize=True)
    return output, changed, warnings


def validate_output(path: Path, expected: tuple[int, int]) -> None:
    image = Image.open(path)
    if image.size != expected or image.mode != "RGBA":
        raise ValueError(f"{path}: expected RGBA {expected}, got {image.mode} {image.size}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", type=Path, default=TOOL_DIR / "output")
    parser.add_argument("--bleed", type=int, default=4, choices=range(2, 5))
    parser.add_argument(
        "--install",
        action="store_true",
        help="back up the current Textures/60 sheets and install generated atlases",
    )
    args = parser.parse_args()

    built: list[Path] = []
    for job in JOBS:
        output, changed, warnings = build_job(job, args.output_dir, args.bleed)
        validate_output(output, Image.open(job["source"]).size)
        built.append(output)
        print(f"built {output} ({changed} terrain sprites replaced)")
        for warning in warnings:
            print(f"warning: {job['name']} {warning}")

    if args.install:
        backup_dir = ROOT / "Textures/60/terrain_remaster_backup"
        backup_dir.mkdir(parents=True, exist_ok=True)
        for output, job in zip(built, JOBS):
            destination = job["source"]
            backup = backup_dir / destination.name
            if not backup.exists():
                shutil.copy2(destination, backup)
            shutil.copy2(output, destination)
            print(f"installed {destination} (backup: {backup})")


if __name__ == "__main__":
    main()
