"""Overlay the authored exterior geometry on its AI art, for manual alignment review.

The art is scaled to 1920x1080, exactly as the TextureRect and the depth
occluder shader present it in game. Silhouette edges of the matching geometry
capture are drawn on top in magenta. Optional regions (x,y,w,h in 1080p pixels)
produce zoomed crops with a 10 px grid, used to read offsets by eye.

    python tools/calibration/exterior_alignment_overlay.py 2 out.png
    python tools/calibration/exterior_alignment_overlay.py 2 zoom.png --zoom 2 1180,440,240,500

Requires Pillow. Writes only the requested image; never touches assets.
"""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2] / "assets/backgrounds/env_1/exterior_authored"
ART = {1: "art_cam01_v01.png", 2: "art_cam02_v02.png", 3: "art_cam03_v01.png"}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("shot", type=int, choices=sorted(ART))
    parser.add_argument("output")
    parser.add_argument("regions", nargs="*", help="x,y,w,h in 1080p pixels")
    parser.add_argument("--zoom", type=int, default=3)
    args = parser.parse_args()
    geometry = Image.open(ROOT / f"geometry_cam0{args.shot}.png").convert("RGB")
    art = Image.open(ROOT / ART[args.shot]).convert("RGB").resize(geometry.size, Image.LANCZOS)
    edges = geometry.convert("L").filter(ImageFilter.FIND_EDGES).point(lambda v: 255 if v > 18 else 0)
    magenta = Image.new("RGB", geometry.size, (255, 40, 220))
    if not args.regions:
        dim = Image.blend(art, Image.new("RGB", art.size), 0.15)
        Image.composite(magenta, dim, edges.filter(ImageFilter.MaxFilter(3))).save(args.output)
        return
    z = args.zoom
    tiles = []
    for region in args.regions:
        x, y, w, h = (int(v) for v in region.split(","))
        box = (x, y, x + w, y + h)
        tile = Image.composite(magenta.crop(box), art.crop(box), edges.crop(box)).resize((w * z, h * z), Image.NEAREST)
        draw = ImageDraw.Draw(tile)
        for g in range(0, max(w, h), 10):
            draw.line((g * z, 0, g * z, 14 if g % 50 == 0 else 6), fill=(90, 255, 120))
            draw.line((0, g * z, 14 if g % 50 == 0 else 6, g * z), fill=(90, 255, 120))
        draw.text((18, 4), f"({x},{y}) {w}x{h} ticks=10px", fill=(255, 255, 0))
        tiles.append(tile)
    sheet = Image.new("RGB", (max(t.width for t in tiles), sum(t.height + 6 for t in tiles)), (30, 30, 30))
    top = 0
    for tile in tiles:
        sheet.paste(tile, (0, top))
        top += tile.height + 6
    sheet.save(args.output)


if __name__ == "__main__":
    main()
