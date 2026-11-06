from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/levels/independent_props"
OUTPUT = ROOT / "docs/independent_prop_catalog"


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    image = Image.new("RGBA", size, (31, 44, 56, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            fill = (48, 64, 77, 255) if (x // cell + y // cell) % 2 else (31, 45, 57, 255)
            draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=fill)
    return image


def main() -> None:
    manifest = json.loads((ROOT / "assets/levels/layers/manifest.json").read_text(encoding="utf-8"))
    OUTPUT.mkdir(parents=True, exist_ok=True)
    tile_w, tile_h = 360, 260
    for floor_id, floor_data in manifest["floors"].items():
        sheet = checker((tile_w * 4, tile_h * 4))
        draw = ImageDraw.Draw(sheet)
        for index, entry in enumerate(floor_data["objects"]):
            object_id = entry["id"]
            refined = ASSETS / floor_id / "v2" / f"{object_id}.png"
            source = refined if refined.exists() else ASSETS / floor_id / "v1" / f"{object_id}.png"
            sprite = Image.open(source).convert("RGBA")
            scale = min((tile_w - 28) / sprite.width, (tile_h - 44) / sprite.height, 1.0)
            thumb = sprite.resize((max(1, round(sprite.width * scale)), max(1, round(sprite.height * scale))), Image.Resampling.LANCZOS)
            left = index % 4 * tile_w + (tile_w - thumb.width) // 2
            top = index // 4 * tile_h + 7
            sheet.alpha_composite(thumb, (left, top))
            draw.text((index % 4 * tile_w + 9, (index // 4 + 1) * tile_h - 25), object_id, fill=(241, 244, 247, 255))
        sheet.convert("RGB").save(OUTPUT / f"{floor_id}_independent_v1.jpg", quality=92)
    print("INDEPENDENT_CATALOG_OK floors=7")


if __name__ == "__main__":
    main()
