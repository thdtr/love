"""Generates the card shown when someone shares a link to love.

Writes docs/social-preview.png at 1280x640, GitHub's size. Upload it by hand
in the repository's Settings, under "Social preview".

The card is read as a small thumbnail, so it holds the logo, one line set
large and the editor screenshot, cropped, with what matters at least 80px
from the edges. Needs Pillow and ImageMagick 7 (`magick`, for the logo).

    python3 tools/make_social_preview.py
"""

import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
W, H = 1280, 640
MARGIN = 80

PANEL = "#121116"
INK = "#ece6da"
ACCENT = "#f2626a"
LINES = ["You decide.", "Claude does the work."]

# Where the window sits inside docs/screenshot.png, as fractions of its size
# (the rest is the macOS shadow).
WINDOW_X, WINDOW_Y = 112 / 2584, 76 / 1808


def logo(width):
    template = (ROOT / "assets" / "logo-template.svg").read_text()
    svg = template.replace("{INK}", INK).replace("{ACCENT}", ACCENT)
    with tempfile.TemporaryDirectory() as tmp:
        src, out = Path(tmp) / "logo.svg", Path(tmp) / "logo.png"
        src.write_text(svg)
        subprocess.run(
            ["magick", "-background", "none", "-density", "600", str(src), "-resize", f"{width}x", str(out)],
            check=True,
        )
        return Image.open(out).convert("RGBA")


def main():
    canvas = Image.new("RGBA", (W, H), PANEL)

    shot = Image.open(ROOT / "docs" / "screenshot.png").convert("RGBA")
    scale = 1150 / shot.width
    shot = shot.resize((round(shot.width * scale), round(shot.height * scale)), Image.LANCZOS)
    left, top = 640, 150
    canvas.alpha_composite(shot, (left - round(shot.width * WINDOW_X), top - round(shot.height * WINDOW_Y)))

    canvas.alpha_composite(logo(300), (MARGIN, 150))

    font = ImageFont.truetype(str(ROOT / "tools" / "fonts" / "FiraSans-Light.ttf"), 52)
    draw = ImageDraw.Draw(canvas)
    y = 340
    for line in LINES:
        draw.text((MARGIN - 3, y), line, font=font, fill=INK)
        y += 64

    out = ROOT / "docs" / "social-preview.png"
    canvas.convert("RGB").save(out, optimize=True)
    print(f"Wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
