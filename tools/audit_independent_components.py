from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1] / "assets/levels/independent_props"


def components(image: Image.Image) -> list[tuple[int, tuple[int, int, int, int]]]:
    alpha = image.convert("RGBA").getchannel("A")
    width, height = alpha.size
    pixels = alpha.load()
    seen: set[tuple[int, int]] = set()
    result: list[tuple[int, tuple[int, int, int, int]]] = []
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in seen:
                continue
            stack = [(x, y)]
            seen.add((x, y))
            points: list[tuple[int, int]] = []
            while stack:
                px, py = stack.pop()
                points.append((px, py))
                for neighbor in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    nx, ny = neighbor
                    if 0 <= nx < width and 0 <= ny < height and pixels[nx, ny] > 0 and neighbor not in seen:
                        seen.add(neighbor)
                        stack.append(neighbor)
            bounds = (
                min(point[0] for point in points),
                min(point[1] for point in points),
                max(point[0] for point in points) + 1,
                max(point[1] for point in points) + 1,
            )
            result.append((len(points), bounds))
    return sorted(result, reverse=True)


def main() -> None:
    for path in sorted(ROOT.glob("floor_*/v1/*.png")):
        found = components(Image.open(path))
        if len(found) > 1 and found[1][0] >= found[0][0] * 0.15:
            print(path.relative_to(ROOT), Image.open(path).size, found[:6])


if __name__ == "__main__":
    main()
