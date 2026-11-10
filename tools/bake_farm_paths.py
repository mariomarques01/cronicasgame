"""Generate the road mask from the farm layout. Requires Pillow; run at project root."""
import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
layout = json.loads((ROOT / "data/regions/farm_paths.json").read_text())
SIZE = 2048
left, top, right, bottom = layout["mask_bounds"]


def pixel(point):
    return ((point[0] - left) / (right - left) * SIZE,
            (point[1] - top) / (bottom - top) * SIZE)


mask = Image.new("L", (SIZE, SIZE))
draw = ImageDraw.Draw(mask)
for path in layout["paths"]:
    points = [pixel(point) for point in path["points"]]
    width = path["width"] / (right - left) * SIZE
    draw.line(points, fill=255, width=round(width), joint="curve")
    for x, y in points:
        draw.ellipse((x - width / 2, y - width / 2,
                      x + width / 2, y + width / 2), fill=255)
mask = mask.filter(ImageFilter.GaussianBlur(1.5))
# Cultivated lots remain intact, even when an access spur ends at their gate.
draw = ImageDraw.Draw(mask)
for plot in layout["protected_plots"]:
    x0, z0, x1, z1 = plot["bounds"]
    draw.rectangle([pixel((x0, z0)), pixel((x1, z1))], fill=0)
mask.resize((1024, 1024), Image.Resampling.LANCZOS).save(
    ROOT / "assets/textures/farm_paths_mask.png")
print("Farm road mask: 1024 px, protected cultivated lots, round path junctions")
