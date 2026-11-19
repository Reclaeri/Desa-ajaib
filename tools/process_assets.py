from __future__ import annotations

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "new_folder_11" / "New folder (4)"
ASSETS = ROOT / "assets"
REPORTS = ASSETS / "reports"

BACKGROUNDS = {
    "b87p6gb87p6gb87p": "bg_level_01_forest.png",
    "iwmvxbiwmvxbiwmv": "bg_level_02_meadow.png",
    "cdyd2scdyd2scdyd": "bg_level_03_river.png",
    "ewfs7iewfs7iewfs": "bg_level_04_festival.png",
    "yzlconyzlconyzlc": "bg_level_05_garden_dirty.png",
    "jia4s5jia4s5jia4": "bg_level_05_garden_clean.png",
    "lsyr3mlsyr3mlsyr": "bg_ending_village.png",
}

SHEETS = {
    "2mogzx2mogzx2mog": ("characters/lili", "lili"),
    "4vtlrw4vtlrw4vtl": ("characters/tutu", "tutu"),
    "709gyl709gyl709g": ("characters/villagers/hedgehog", "hedgehog"),
    "70i53h70i53h70i5": ("characters/momo", "momo"),
    "a6hmnva6hmnva6hm": ("characters/villagers/deer", "deer"),
    "amuuzwamuuzwamuu": ("characters/villagers/rabbit", "rabbit_villager"),
    "bd5q4bd5q4bd5q4b": ("characters/villagers/squirrel", "squirrel"),
    "s3ueevs3ueevs3ue": ("characters/villagers/bird", "bird"),
}

OBJECTS = {
    "1qcitc1qcitc1qci": ("objects/drinks", "obj_juice"),
    "26gszo26gszo26gs": ("objects/food", "obj_strawberry"),
    "4kghgl4kghgl4kgh": ("objects/tableware", "obj_tableware"),
    "5iir9p5iir9p5iir": ("objects/decorations", "decor_bush"),
    "avrmvdavrmvdavrm": ("objects/bridge", "obj_wood"),
    "chhakvchhakvchha": ("objects/garden", "obj_trash"),
    "eo7gpfeo7gpfeo7g": ("objects/garden", "obj_watering_can"),
    "hemg2nhemg2nhemg": ("objects/food", "obj_cake"),
    "k5jmjak5jmjak5jm": ("objects/garden", "obj_dry_branch"),
    "riirrzriirrzriir": ("objects/mission", "obj_basket"),
    "rkdcyrkdcyrkdcyr": ("objects/mission", "obj_fruit_basket"),
    "s7r7yqs7r7yqs7r7": ("objects/food", "obj_bread"),
    "t64hedt64hedt64h": ("objects/bridge", "obj_rope"),
    "ujw848ujw848ujw8": ("objects/food", "obj_fruit"),
}

MARKER = (0, 255, 255)


def source_for(token: str) -> Path:
    matches = list(SOURCE.glob(f"*{token}*"))
    if len(matches) != 1:
        raise RuntimeError(f"Expected one source for {token}; found {matches}")
    return matches[0]


def remove_background(image: Image.Image) -> Image.Image:
    """Remove edge-connected white or gray printed checkerboard pixels.

    Background candidates are flood-filled from the image edge. This keeps
    white eyes and clothing intact when they are enclosed by the dark outline.
    """
    rgb = image.convert("RGB")
    mask = Image.new("L", rgb.size, 0)
    source_pixels = rgb.load()
    mask_pixels = mask.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            red, green, blue = source_pixels[x, y]
            if max(red, green, blue) - min(red, green, blue) <= 12 and (red + green + blue) // 3 >= 120:
                mask_pixels[x, y] = 255
    ImageDraw.floodfill(mask, (0, 0), 128, thresh=0)
    alpha = mask.point(lambda value: 0 if value == 128 else 255)
    alpha_pixels = alpha.load()
    for y in range(rgb.height):
        for x in range(rgb.width):
            red, green, blue = source_pixels[x, y]
            average = (red + green + blue) // 3
            # Printed checkerboards can also appear inside enclosed handles.
            # Their near-gray 180/230 tones are distinct from the colored art.
            if max(red, green, blue) - min(red, green, blue) <= 4 and 165 <= average <= 240:
                alpha_pixels[x, y] = 0
    rgba = rgb.convert("RGBA")
    rgba.putalpha(alpha)
    return rgba


def bands(values: list[bool], minimum_gap: int = 5) -> list[tuple[int, int]]:
    segments: list[tuple[int, int]] = []
    start = None
    for index, value in enumerate(values + [False]):
        if value and start is None:
            start = index
        elif not value and start is not None:
            if index - start >= 3:
                segments.append((start, index))
            start = None
    return segments


def split_components(image: Image.Image) -> list[Image.Image]:
    alpha = image.getchannel("A")
    _, y_projection = alpha.getprojection()
    width, height = image.size
    row_occupied = [value > 0 for value in y_projection]
    parts: list[Image.Image] = []
    for y_start, y_end in bands(row_occupied):
        x_projection, _ = alpha.crop((0, y_start, width, y_end)).getprojection()
        column_occupied = [value > 0 for value in x_projection]
        for x_start, x_end in bands(column_occupied):
            crop = image.crop((x_start, y_start, x_end, y_end))
            bbox = crop.getchannel("A").getbbox()
            if bbox is None:
                continue
            crop = crop.crop(bbox)
            if crop.width * crop.height < 350:
                continue
            padded = Image.new("RGBA", (crop.width + 12, crop.height + 12), (0, 0, 0, 0))
            padded.alpha_composite(crop, (6, 6))
            parts.append(padded)
    return parts


def save_parts(source: Path, destination: Path, prefix: str) -> list[dict[str, object]]:
    destination.mkdir(parents=True, exist_ok=True)
    for old_output in destination.glob(f"{prefix}_*.png"):
        old_output.unlink()
    transparent = remove_background(Image.open(source))
    parts = split_components(transparent)
    if not parts:
        parts = [transparent]
    entries: list[dict[str, object]] = []
    for number, part in enumerate(parts, start=1):
        filename = f"{prefix}_{number:02d}.png"
        target = destination / filename
        part.save(target, optimize=True)
        entries.append({
            "source": str(source.relative_to(ROOT)).replace("\\", "/"),
            "output": str(target.relative_to(ROOT)).replace("\\", "/"),
            "width": part.width,
            "height": part.height,
            "alpha": True,
        })
    return entries


def save_background(source: Path, filename: str) -> dict[str, object]:
    destination = ASSETS / "backgrounds" / filename
    destination.parent.mkdir(parents=True, exist_ok=True)
    image = Image.open(source).convert("RGB")
    image.save(destination, optimize=True)
    return {
        "source": str(source.relative_to(ROOT)).replace("\\", "/"),
        "output": str(destination.relative_to(ROOT)).replace("\\", "/"),
        "width": image.width,
        "height": image.height,
        "alpha": False,
    }


def main() -> None:
    processed: list[dict[str, object]] = []
    groups = set(sys.argv[1:]) or {"backgrounds", "sheets", "objects"}
    if "backgrounds" in groups:
        for token, filename in BACKGROUNDS.items():
            processed.append(save_background(source_for(token), filename))
    if "sheets" in groups:
        for token, (folder, prefix) in SHEETS.items():
            processed.extend(save_parts(source_for(token), ASSETS / folder, prefix))
    if "objects" in groups:
        for token, (folder, prefix) in OBJECTS.items():
            processed.extend(save_parts(source_for(token), ASSETS / folder, prefix))
    REPORTS.mkdir(parents=True, exist_ok=True)
    report = {
        "source_images": 29,
        "backgrounds": len(BACKGROUNDS),
        "processed_images": len(processed),
        "transparent_images": sum(1 for item in processed if item["alpha"]),
        "assets": processed,
    }
    report["groups"] = sorted(groups)
    (REPORTS / ("new_folder_11_processing_%s.json" % "_".join(sorted(groups)))).write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
