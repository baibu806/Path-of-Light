from __future__ import annotations

from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/levels/independent_props/floor_01/source_sheet_v1.png"
OUTPUT = SOURCE.parent / "v1"
PREVIEW = ROOT / "docs/object_catalog/floor_01_independent_v1.png"

# Each source-sheet slot contains exactly one semantic object.  The scroll pair
# is one desk prop, matching the existing scene manifest.
SLOTS = [
    ("pressure_dial", (20, 0, 360, 265), 1),
    ("desk_scrolls", (360, 0, 775, 265), 2),
    ("shelf_crates", (765, 0, 1165, 285), 1),
    ("shelf_jars", (1150, 0, 1536, 285), 1),
    ("front_barrel", (20, 245, 365, 530), 1),
    ("rear_barrel", (365, 245, 750, 530), 1),
    ("wall_lantern", (745, 245, 1125, 530), 1),
    ("manual_on_table", (1110, 245, 1536, 530), 1),
    ("wall_crack_section", (15, 490, 385, 800), 1),
    ("front_parapet", (370, 490, 780, 800), 1),
    ("workbench", (760, 490, 1195, 810), 1),
    ("supply_shelf", (1170, 490, 1536, 810), 1),
    ("pressure_gauge", (15, 740, 385, 1024), 1),
    ("upper_stairs", (390, 730, 835, 1024), 1),
]


def largest_components(mask: np.ndarray, count: int) -> np.ndarray:
    height, width = mask.shape
    seen = np.zeros_like(mask, dtype=np.uint8)
    components: list[list[tuple[int, int]]] = []
    for y in range(height):
        for x in range(width):
            if not mask[y, x] or seen[y, x]:
                continue
            queue = deque([(x, y)])
            seen[y, x] = 1
            component: list[tuple[int, int]] = []
            while queue:
                px, py = queue.popleft()
                component.append((px, py))
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and mask[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = 1
                        queue.append((nx, ny))
            components.append(component)
    keep = np.zeros_like(mask, dtype=np.uint8)
    for component in sorted(components, key=len, reverse=True)[:count]:
        for x, y in component:
            keep[y, x] = 1
    return keep


def remove_connected_background(image: Image.Image, keep_count: int, edge_threshold: float = 6.0) -> Image.Image:
    rgb = np.asarray(image.convert("RGB"), dtype=np.int16)
    height, width = rgb.shape[:2]
    background = np.zeros((height, width), dtype=np.uint8)
    queue: deque[tuple[int, int]] = deque()

    for x in range(width):
        queue.append((x, 0))
        queue.append((x, height - 1))
    for y in range(height):
        queue.append((0, y))
        queue.append((width - 1, y))

    while queue:
        x, y = queue.popleft()
        if background[y, x]:
            continue
        background[y, x] = 1
        current = rgb[y, x]
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if nx < 0 or ny < 0 or nx >= width or ny >= height or background[ny, nx]:
                continue
            delta = rgb[ny, nx].astype(np.int32) - current.astype(np.int32)
            if float(np.sqrt(np.dot(delta, delta))) <= edge_threshold:
                queue.append((nx, ny))

    foreground = largest_components(1 - background, keep_count)
    alpha = Image.fromarray((foreground * 255).astype(np.uint8), "L")
    # Feather only the outside edge; the source RGB remains untouched.
    alpha = alpha.filter(ImageFilter.GaussianBlur(0.65))
    rgba = image.convert("RGBA")
    rgba.putalpha(alpha)
    bounds = alpha.getbbox()
    if bounds is None:
        raise RuntimeError("No foreground found")
    pad = 4
    left = max(0, bounds[0] - pad)
    top = max(0, bounds[1] - pad)
    right = min(width, bounds[2] + pad)
    bottom = min(height, bounds[3] + pad)
    return rgba.crop((left, top, right, bottom))


def checker(size: tuple[int, int], cell: int = 16) -> Image.Image:
    out = Image.new("RGBA", size, (30, 43, 55, 255))
    draw = ImageDraw.Draw(out)
    for y in range(0, size[1], cell):
        for x in range(0, size[0], cell):
            color = (48, 65, 78, 255) if (x // cell + y // cell) % 2 else (32, 47, 59, 255)
            draw.rectangle((x, y, x + cell - 1, y + cell - 1), fill=color)
    return out


def main() -> None:
    source = Image.open(SOURCE).convert("RGBA")
    OUTPUT.mkdir(parents=True, exist_ok=True)
    pieces: list[tuple[str, Image.Image]] = []
    for object_id, box, keep_count in SLOTS:
        piece = remove_connected_background(source.crop(box), keep_count)
        piece.save(OUTPUT / f"{object_id}.png")
        pieces.append((object_id, piece))

    tile_w, tile_h = 360, 260
    sheet = checker((tile_w * 4, tile_h * 4))
    draw = ImageDraw.Draw(sheet)
    for index, (object_id, piece) in enumerate(pieces):
        scale = min((tile_w - 32) / piece.width, (tile_h - 46) / piece.height, 1.0)
        thumb = piece.resize((max(1, int(piece.width * scale)), max(1, int(piece.height * scale))), Image.Resampling.LANCZOS)
        x = (index % 4) * tile_w + (tile_w - thumb.width) // 2
        y = (index // 4) * tile_h + 8
        sheet.alpha_composite(thumb, (x, y))
        draw.text(((index % 4) * tile_w + 10, (index // 4 + 1) * tile_h - 27), object_id, fill=(240, 244, 246, 255))
    PREVIEW.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(PREVIEW)
    print(f"INDEPENDENT_PROPS_OK objects={len(pieces)} output={OUTPUT}")


if __name__ == "__main__":
    main()
