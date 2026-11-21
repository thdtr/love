"""Generates the card shown when someone shares a link to love.

Writes docs/social-preview.png at 1280x640, GitHub's size. Upload it by hand
in the repository's Settings, under "Social preview".

The card is read as a small thumbnail, so it holds the logo, one line set
large and a terminal window listing the skills, with what matters at least
80px from the edges. Needs Pillow and ImageMagick 7 (`magick`, for the logo).

    python3 tools/make_social_preview.py
"""

import subprocess
import tempfile
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
W, H = 1280, 640
MARGIN = 80

BACKGROUND = "#121116"
PANEL = "#18171d"
BORDER = "#2c2a31"
INK = "#ece6da"
MUTED = "#7d786f"
ACCENT = "#e0605a"
LINES = ["You decide.", "Claude does the work."]


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


def skills_window(draw, left, top, right, bottom):
    skills = sorted(p.name for p in (ROOT / "plugins" / "love" / "skills").iterdir() if p.is_dir())
    draw.rounded_rectangle([left, top, right, bottom], 16, fill=PANEL, outline=BORDER, width=1)
    for i, color in enumerate(("#ff5f57", "#febc2e", "#28c840")):
        cx, cy = left + 28 + i * 21, top + 26
        draw.ellipse([cx - 6, cy - 6, cx + 6, cy + 6], fill=color)

    font = ImageFont.truetype(str(ROOT / "tools" / "fonts" / "SourceCodePro-Regular.otf"), 25)
    x, y, row = left + 44, top + 70, 42
    draw.text((x, y), "$ ", font=font, fill=ACCENT)
    draw.text((x + font.getlength("$ "), y), "tree love/skills", font=font, fill=INK)
    y += row
    draw.text((x, y), "love/skills/", font=font, fill=INK)
    for i, name in enumerate(skills):
        y += row
        branch = "└── " if i == len(skills) - 1 else "├── "
        draw.text((x, y), branch, font=font, fill=MUTED)
        draw.text((x + font.getlength(branch), y), name + "/", font=font, fill=ACCENT)


def main():
    canvas = Image.new("RGBA", (W, H), BACKGROUND)
    draw = ImageDraw.Draw(canvas)

    canvas.alpha_composite(logo(300), (MARGIN, 150))
    font = ImageFont.truetype(str(ROOT / "tools" / "fonts" / "FiraSans-Light.ttf"), 52)
    y = 340
    for line in LINES:
        draw.text((MARGIN - 3, y), line, font=font, fill=INK)
        y += 64

    skills_window(draw, 760, 100, W - MARGIN, H - 100)

    out = ROOT / "docs" / "social-preview.png"
    canvas.convert("RGB").save(out, optimize=True)
    print(f"Wrote {out.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
