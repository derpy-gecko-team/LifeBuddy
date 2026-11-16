#!/usr/bin/env python3
"""Renders the hand-written SVG art in assets/images/*/svg to the PNGs the app ships.

    python3 tool/render_art.py               # everything
    python3 tool/render_art.py wizard_hat    # only the named pieces
"""
import pathlib
import re
import subprocess
import sys
import tempfile

from PIL import Image

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
IMAGES = pathlib.Path(__file__).resolve().parent.parent / "assets/images"

# Longest side of each PNG, in pixels.
SIZES = {
    "guildhall": {
        "boss_dragon": 720,
        "torch": 400,
        "dagger_pin": 300,
        "crest_sword": 180,
        "icon_skull": 72,
        "icon_hourglass": 64,
        "icon_crown": 64,
        "coin_pouch": 96,
        "rank_shield": 128,
        "badge_flame": 144,
        "badge_skull": 144,
        "buddy_envelope": 144,
        "questline_iron_body": 160,
        "questline_scholar_tower": 160,
    },
    "bazaar": {
        "coin_lotus": 160,
        "moonstone": 160,
        "chest_pouch": 160,
        "shop_sign": 1020,
        "curtain": 912,
        "side_plaque": 426,
    },
}
DEFAULT_SIZE = {"guildhall": 360, "bazaar": 480}
SUPERSAMPLE = 960

# Wares that can be dyed are drawn once in their own colour; every other dye
# is the same drawing with that colour swapped. Keep in step with WareDye in
# lib/bazaar/data/models.dart.
DYES = {"indigo": "#3B4071", "brick": "#B95A54", "moss": "#5F7D4E", "umber": "#8A6240"}
DYED = {
    "wizard_hat": "indigo",
    "tryon_wizard_hat": "indigo",
    "crimson_cloak": "brick",
}


def render(svg_text: str, name: str, folder: str, tmp: pathlib.Path) -> None:
    box = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg_text)
    if not box:
        sys.exit(f"{name}: missing viewBox")
    vw, vh = float(box[1]), float(box[2])
    scale = SUPERSAMPLE / max(vw, vh)
    w, h = round(vw * scale), round(vh * scale)

    source = tmp / f"{name}.svg"
    source.write_text(svg_text)
    page = tmp / f"{name}.html"
    page.write_text(
        "<!doctype html><style>html,body{margin:0;background:transparent}"
        f"img{{display:block}}</style><img src='{source.as_uri()}' width={w} height={h}>"
    )
    shot = tmp / f"{name}.png"
    subprocess.run(
        [
            CHROME, "--headless=new", "--disable-gpu", "--no-first-run", "--hide-scrollbars",
            f"--user-data-dir={tmp / 'profile'}", "--default-background-color=00000000",
            f"--window-size={w},{h}", f"--screenshot={shot}", page.as_uri(),
        ],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    image = Image.open(shot).convert("RGBA").crop((0, 0, w, h))
    target = SIZES[folder].get(name.split("@")[0], DEFAULT_SIZE[folder])
    factor = target / max(w, h)
    image = image.resize((round(w * factor), round(h * factor)), Image.LANCZOS)
    out = IMAGES / folder / f"{name.replace('@', '_')}.png"
    image.save(out, optimize=True)
    print(f"{folder}/{out.name}  {image.width}x{image.height}")


def main() -> None:
    wanted = set(sys.argv[1:])
    with tempfile.TemporaryDirectory() as tmp:
        for folder in SIZES:
            for svg in sorted((IMAGES / folder / "svg").glob("*.svg")):
                if wanted and svg.stem not in wanted:
                    continue
                text = svg.read_text()
                render(text, svg.stem, folder, pathlib.Path(tmp))
                own = DYED.get(svg.stem) if folder == "bazaar" else None
                if own is None:
                    continue
                for dye, colour in DYES.items():
                    if dye != own:
                        render(text.replace(DYES[own], colour), f"{svg.stem}@{dye}", folder, pathlib.Path(tmp))


if __name__ == "__main__":
    main()
