from __future__ import annotations

import json
from pathlib import Path

from PIL import Image

from split_independent_prop_sheet import remove_connected_background


ROOT = Path(__file__).resolve().parents[1]
ASSET_ROOT = ROOT / "assets/levels/independent_props"

ORDERS = {
    "floor_02": [
        "outlet_valve", "pump_core", "front_rail", "intake_valve",
        "manual_and_tools", "drain_grate", "control_box", "pressure_indicator",
        "filter_tank", "intake_tank", "wall_lantern", "pipe_assembly", "upper_stairs",
    ],
    "floor_03": [
        "generator_rotor", "fuse_bank", "front_rail", "drain_grate",
        "right_switch_panel", "red_controller", "middle_breaker_panel", "upper_alarm_panel",
        "left_switch_panel", "wall_lantern", "front_parapet", "workbench", "upper_stairs",
    ],
    "floor_04": [
        "front_gear", "rear_gear", "front_rail", "oil_bucket",
        "manual_on_bench", "detached_gear", "rear_cog", "left_handwheel",
        "upper_gear", "wall_lantern", "front_parapet", "workbench",
        "gear_train", "upper_stairs",
    ],
    "floor_05": [
        "right_mirror", "center_mirror", "left_mirror", "front_rail",
        "manual_on_bench", "right_banner", "left_banner", "floor_lever",
        "red_crystal", "sun_emitter", "wall_lantern", "front_parapet",
        "workbench", "mirror_array", "upper_stairs",
    ],
    "floor_06": [
        "emitter_head", "lens_face", "front_rail", "back_ladder",
        "lens_support", "calibration_vials", "manual_on_bench", "red_toolkit",
        "upper_wall_lantern", "lower_wall_lamp", "front_parapet", "workbench",
        "light_emitter", "focus_ring", "upper_stairs",
    ],
    "floor_07": [
        "lamp_light_core", "direction_wheel", "lamp_chamber", "front_rail",
        "blue_toolbox", "repair_manual", "console_buttons", "lamp_roof",
        "right_wall_lantern", "left_wall_lantern", "front_parapet", "side_controls",
        "control_console", "main_lamp", "upper_stairs",
    ],
}


def trim_alpha(image: Image.Image, padding: int = 4) -> Image.Image:
    rgba = remove_border_bleed(image.convert("RGBA"))
    bounds = rgba.getchannel("A").getbbox()
    if bounds is None:
        raise RuntimeError("Empty sprite cell")
    left = max(0, bounds[0] - padding)
    top = max(0, bounds[1] - padding)
    right = min(rgba.width, bounds[2] + padding)
    bottom = min(rgba.height, bounds[3] + padding)
    return rgba.crop((left, top, right, bottom))


def remove_border_bleed(image: Image.Image) -> Image.Image:
    """Drop small disconnected fragments leaked in from neighbouring sheet cells.

    The generated prop boards occasionally let a few opaque pixels cross a grid
    boundary.  Real multipart props are retained; only secondary components that
    touch a cell edge and are much smaller than the principal component are
    removed.
    """
    rgba = image.copy()
    alpha = rgba.getchannel("A").point(lambda value: 0 if value < 32 else value)
    rgba.putalpha(alpha)
    width, height = rgba.size
    pixels = alpha.load()
    seen: set[tuple[int, int]] = set()
    components: list[tuple[list[tuple[int, int]], bool]] = []
    for y in range(height):
        for x in range(width):
            if pixels[x, y] == 0 or (x, y) in seen:
                continue
            stack = [(x, y)]
            seen.add((x, y))
            points: list[tuple[int, int]] = []
            touches_edge = False
            while stack:
                px, py = stack.pop()
                points.append((px, py))
                if px <= 2 or py <= 2 or px >= width - 3 or py >= height - 3:
                    touches_edge = True
                for nx, ny in ((px - 1, py), (px + 1, py), (px, py - 1), (px, py + 1)):
                    if 0 <= nx < width and 0 <= ny < height and pixels[nx, ny] > 0 and (nx, ny) not in seen:
                        seen.add((nx, ny))
                        stack.append((nx, ny))
            components.append((points, touches_edge))
    if not components:
        return rgba
    largest = max(len(points) for points, _ in components)
    cleaned = alpha.copy()
    cleaned_pixels = cleaned.load()
    for points, touches_edge in components:
        # Generator spill can sit a few pixels inside the grid edge, so it is
        # not sufficient to test edge contact alone.  Real multipart assets in
        # these boards have substantial components; isolated fragments below
        # 15% of the principal silhouette are neighbouring-cell contamination.
        is_small_fragment = len(points) < largest * 0.15
        is_edge_fragment = touches_edge and len(points) < largest * 0.35
        if is_small_fragment or is_edge_fragment:
            for x, y in points:
                cleaned_pixels[x, y] = 0
    rgba.putalpha(cleaned)
    return rgba


def split_grid(floor_id: str, names: list[str]) -> None:
    source = Image.open(ASSET_ROOT / floor_id / "source_sheet_v1.png").convert("RGBA")
    cell_width = source.width // 4
    cell_height = source.height // 4
    output = ASSET_ROOT / floor_id / "v1"
    output.mkdir(parents=True, exist_ok=True)
    for index, name in enumerate(names):
        x = index % 4
        y = index // 4
        cell = source.crop((x * cell_width, y * cell_height, (x + 1) * cell_width, (y + 1) * cell_height))
        trim_alpha(cell).save(output / f"{name}.png")


def split_opaque_supplement(source_path: Path, boxes: list[tuple[str, str, tuple[int, int, int, int]]]) -> None:
    source = Image.open(source_path).convert("RGBA")
    for floor_id, name, box in boxes:
        piece = remove_connected_background(source.crop(box), 1, 6.0)
        output = ASSET_ROOT / floor_id / "v1"
        output.mkdir(parents=True, exist_ok=True)
        piece.save(output / f"{name}.png")


def verify() -> None:
    manifest = json.loads((ROOT / "assets/levels/layers/manifest.json").read_text(encoding="utf-8"))
    report = {
        "version": 2,
        "status": "independent_complete_with_v2_refinements",
        "preferred_overrides": {
            "floor_07": ["left_wall_lantern", "side_controls", "main_lamp", "upper_stairs"]
        },
        "floors": {},
    }
    total = 0
    for floor_id, floor_data in manifest["floors"].items():
        expected = [entry["id"] for entry in floor_data["objects"]]
        output = ASSET_ROOT / floor_id / "v1"
        actual = sorted(path.stem for path in output.glob("*.png"))
        if sorted(expected) != actual:
            raise RuntimeError(f"{floor_id}: expected {sorted(expected)}, got {actual}")
        for object_id in expected:
            image = Image.open(output / f"{object_id}.png").convert("RGBA")
            low, high = image.getchannel("A").getextrema()
            if high == 0 or low == 255:
                raise RuntimeError(f"{floor_id}/{object_id}: invalid transparency {low, high}")
        report["floors"][floor_id] = {"count": len(expected), "objects": expected}
        total += len(expected)
    report["total"] = total
    (ASSET_ROOT / "manifest_v1.json").write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"INDEPENDENT_SET_OK floors=7 objects={total}")


def main() -> None:
    for floor_id, names in ORDERS.items():
        split_grid(floor_id, names)

    # The generator merged these semantic objects in the main boards.  Replace
    # them with dedicated supplementary drawings rather than accepting a chunk.
    supplement_23 = ASSET_ROOT / "supplement_floor_02_03_v1.png"
    split_opaque_supplement(supplement_23, [
        ("floor_02", "front_parapet", (0, 0, 810, 1024)),
        ("floor_02", "workbench", (640, 0, 1340, 1024)),
        ("floor_03", "electrical_cabinets", (1260, 0, 2048, 1024)),
    ])
    supplement_5 = ASSET_ROOT / "supplement_floor_05_v1.png"
    split_opaque_supplement(supplement_5, [
        ("floor_05", "manual_on_bench", (0, 0, 1024, 1024)),
        ("floor_05", "workbench", (1024, 0, 2048, 1024)),
    ])
    verify()


if __name__ == "__main__":
    main()
