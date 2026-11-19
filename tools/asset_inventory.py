from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "source" / "new_folder_11"
REPORTS = ROOT / "assets" / "reports"
THUMBNAIL_SIZE = (280, 180)
CELL_SIZE = (310, 230)
COLUMNS = 3


def main() -> None:
    REPORTS.mkdir(parents=True, exist_ok=True)
    image_paths = sorted(path for path in SOURCE.rglob("*") if path.suffix.lower() in {".jfif", ".jpg", ".jpeg", ".png", ".webp"})
    inventory: list[dict[str, object]] = []
    rows = (len(image_paths) + COLUMNS - 1) // COLUMNS
    sheet = Image.new("RGB", (COLUMNS * CELL_SIZE[0], rows * CELL_SIZE[1]), "#202634")
    draw = ImageDraw.Draw(sheet)
    font = ImageFont.load_default()

    for index, image_path in enumerate(image_paths):
        with Image.open(image_path) as image:
            image.load()
            inventory.append({
                "source": str(image_path.relative_to(ROOT)).replace("\\", "/"),
                "format": image.format,
                "mode": image.mode,
                "width": image.width,
                "height": image.height,
                "has_alpha": "A" in image.getbands(),
                "file_size": image_path.stat().st_size,
            })
            preview = image.convert("RGB")
            preview.thumbnail(THUMBNAIL_SIZE)
        column = index % COLUMNS
        row = index // COLUMNS
        x = column * CELL_SIZE[0]
        y = row * CELL_SIZE[1]
        preview_x = x + (CELL_SIZE[0] - preview.width) // 2
        sheet.paste(preview, (preview_x, y + 8))
        label = f"{index + 1:02d} {image_path.stem[-12:]}"
        dimensions = f"{inventory[-1]['width']} x {inventory[-1]['height']}"
        draw.text((x + 8, y + 194), label, fill="white", font=font)
        draw.text((x + 8, y + 211), dimensions, fill="#b9c7de", font=font)

    (REPORTS / "new_folder_11_inventory.json").write_text(json.dumps(inventory, indent=2), encoding="utf-8")
    sheet.save(REPORTS / "new_folder_11_contact_sheet.jpg", quality=92)
    print(json.dumps(inventory, indent=2))


if __name__ == "__main__":
    main()
