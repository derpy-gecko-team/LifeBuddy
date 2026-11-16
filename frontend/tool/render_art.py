#!/usr/bin/env python3
import pathlib
import re
import subprocess
import sys
import tempfile

from PIL import Image

CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
ROOT = pathlib.Path(__file__).resolve().parent.parent / "assets/images/guildhall"

SIZES = {
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
}
DEFAULT_SIZE = 360
SUPERSAMPLE = 960


def render(svg: pathlib.Path, tmp: pathlib.Path) -> None:
    box = re.search(r'viewBox="0 0 ([\d.]+) ([\d.]+)"', svg.read_text())
    if not box:
        sys.exit(f"{svg.name}: missing viewBox")
    vw, vh = float(box[1]), float(box[2])
    scale = SUPERSAMPLE / max(vw, vh)
    w, h = round(vw * scale), round(vh * scale)

    page = tmp / f"{svg.stem}.html"
    page.write_text(
        "<!doctype html><style>html,body{margin:0;background:transparent}"
        f"img{{display:block}}</style><img src='{svg.as_uri()}' width={w} height={h}>"
    )
    shot = tmp / f"{svg.stem}.png"
    subprocess.run(
        [
            CHROME, "--headless=new", "--disable-gpu", "--no-first-run", "--hide-scrollbars",
            f"--user-data-dir={tmp / 'profile'}", "--default-background-color=00000000",
            f"--window-size={w},{h}", f"--screenshot={shot}", page.as_uri(),
        ],
        check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    image = Image.open(shot).convert("RGBA").crop((0, 0, w, h))
    target = SIZES.get(svg.stem, DEFAULT_SIZE)
    factor = target / max(w, h)
    image = image.resize((round(w * factor), round(h * factor)), Image.LANCZOS)
    image.save(ROOT / f"{svg.stem}.png", optimize=True)
    print(f"{svg.stem}.png  {image.width}x{image.height}")


def main() -> None:
    wanted = set(sys.argv[1:])
    with tempfile.TemporaryDirectory() as tmp:
        for svg in sorted((ROOT / "svg").glob("*.svg")):
            if not wanted or svg.stem in wanted:
                render(svg, pathlib.Path(tmp))


if __name__ == "__main__":
    main()
