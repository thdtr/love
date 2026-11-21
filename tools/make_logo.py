"""Generates love's logo and icons from one source of truth.

Writes:
  assets/logo.svg                        mark + "love", adapts to light/dark
  assets/logo-template.svg               same, with {INK} and {ACCENT} to fill
  assets/mark.svg                        the mark alone
  plugins/love/.claude-plugin/icon.png   512 px, the plugin's listing icon

The mark is two identical bands turned 180 degrees, each passing under the
other. The wordmark is "love" in Fira Sans Light (tools/fonts/), converted to
outlines so the logo needs no font. The PNG needs ImageMagick 7 (`magick`).

    python3 tools/make_logo.py
"""

import math
import shutil
import subprocess
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
FONT = ROOT / "tools" / "fonts" / "FiraSans-Light.ttf"

ACCENT = "#e0605a"
INK_LIGHT = "#1f1d1b"
INK_DARK = "#ece6da"
NIGHT = "#121116"

# One band on a 64x64 grid. The other is the same band turned 180 degrees.
WIDTH = 10.5
LONG = "M9 49 L 26.5 19.5 C 29.5 14.6, 37.6 14.2, 41 18.6 L 44.2 23.2"
SHORT = "M43.6 22.4 L 52 34.4"
TURN = 'transform="rotate(180 32 32)"'


def tuck_polygon():
    """The side of the other band's outer edge where this band's short leg shows."""
    ax, ay, bx, by = 55, 15, 37.5, 44.5
    dx, dy = bx - ax, by - ay
    length = math.hypot(dx, dy)
    dx, dy = dx / length, dy / length
    nx, ny = -dy, dx
    if (32 - ax) * nx + (32 - ay) * ny < 0:
        nx, ny = -nx, -ny
    ox, oy = ax - nx * WIDTH / 2, ay - ny * WIDTH / 2
    far = 200
    points = [
        (ox - dx * far, oy - dy * far),
        (ox + dx * far, oy + dy * far),
        (ox + dx * far + nx * far, oy + dy * far + ny * far),
        (ox - dx * far + nx * far, oy - dy * far + ny * far),
    ]
    return " ".join(f"{x:.2f},{y:.2f}" for x, y in points)


def band(d, color, width=WIDTH, extra=""):
    return (
        f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{width}" '
        f'stroke-linecap="butt" stroke-linejoin="round"{extra}/>'
    )


def mark(fill, prefix="love"):
    """The mark's SVG body. `fill` is a color or a class attribute."""
    paint = fill if fill.startswith("#") else "currentColor"
    css = "" if fill.startswith("#") else f' class="{fill}"'
    shadow_shift = ' transform="translate(0.6 1.2)"'
    defs = (
        "<defs>"
        f'<clipPath id="{prefix}-cut"><rect x="0" y="0" width="64" height="45"/></clipPath>'
        f'<clipPath id="{prefix}-tuck"><polygon points="{tuck_polygon()}"/></clipPath>'
        f'<mask id="{prefix}-under" maskUnits="userSpaceOnUse" x="0" y="0" width="64" height="64">'
        f'<g clip-path="url(#{prefix}-tuck)">{band(SHORT, "#fff")}</g>'
        f'<g {TURN}><g clip-path="url(#{prefix}-tuck)">{band(SHORT, "#fff")}</g></g>'
        "</mask>"
        f'<filter id="{prefix}-soft" x="-50%" y="-50%" width="200%" height="200%">'
        '<feGaussianBlur stdDeviation="1.6"/></filter>'
        "</defs>"
    )
    shorts = (
        f'<g clip-path="url(#{prefix}-tuck)">{band(SHORT, paint)}</g>'
        f'<g {TURN}><g clip-path="url(#{prefix}-tuck)">{band(SHORT, paint)}</g></g>'
    )
    shadow = (
        f'<g mask="url(#{prefix}-under)" filter="url(#{prefix}-soft)" opacity="0.45">'
        f'{band(LONG, "#000", WIDTH + 1, shadow_shift)}'
        f'<g {TURN}>{band(LONG, "#000", WIDTH + 1, shadow_shift)}</g>'
        "</g>"
    )
    longs = (
        f'<g clip-path="url(#{prefix}-cut)">{band(LONG, paint)}</g>'
        f'<g {TURN}><g clip-path="url(#{prefix}-cut)">{band(LONG, paint)}</g></g>'
    )
    return defs + f"<g{css}>{shorts}</g>" + shadow + f"<g{css}>{longs}</g>"


def wordmark(x0=68.0, baseline=44.0, l_height=26.0):
    """'love' as one SVG path, scaled so the 'l' is `l_height` tall."""
    font = TTFont(FONT)
    glyphs = font.getGlyphSet()
    cmap = font.getBestCmap()
    bounds = BoundsPen(glyphs)
    glyphs[cmap[ord("l")]].draw(bounds)
    scale = l_height / bounds.bounds[3]
    pen = SVGPathPen(glyphs)
    x = 0.0
    for ch in "love":
        glyph = glyphs[cmap[ord(ch)]]
        glyph.draw(TransformPen(pen, (scale, 0, 0, -scale, x0 + x * scale, baseline)))
        x += glyph.width
    return pen.getCommands(), x0 + x * scale


def write_svgs():
    word, right = wordmark()
    box = f"4 6 {right:.1f} 52"
    width = right - 4 + 4

    (ASSETS / "logo.svg").write_text(
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{box}" width="{width * 4:.0f}" height="208" role="img" aria-label="love">\n'
        "  <style>\n"
        f"    .accent {{ color: {ACCENT}; }}\n"
        f"    .ink {{ fill: {INK_LIGHT}; }}\n"
        f"    @media (prefers-color-scheme: dark) {{ .ink {{ fill: {INK_DARK}; }} }}\n"
        "  </style>\n"
        f"  {mark('accent')}\n"
        f'  <path class="ink" d="{word}"/>\n'
        "</svg>\n"
    )
    template = (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{box}">\n'
        f"  {mark('#ACCENT')}\n"
        f'  <path d="{word}" fill="{{INK}}"/>\n'
        "</svg>\n"
    )
    (ASSETS / "logo-template.svg").write_text(template.replace("#ACCENT", "{ACCENT}"))
    (ASSETS / "mark.svg").write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="4 4 56 56" width="224" height="224" role="img" aria-label="love">\n'
        f"  {mark(ACCENT)}\n"
        "</svg>\n"
    )


def write_icon():
    if not shutil.which("magick"):
        raise SystemExit("ImageMagick 7 (`magick`) is needed for the PNG icon.")
    icon_svg = ROOT / "plugins" / "love" / ".claude-plugin" / "icon.svg.tmp"
    icon_svg.write_text(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">'
        f'<rect width="64" height="64" fill="{NIGHT}"/>'
        f'<g transform="translate(32 32) scale(0.78) translate(-32 -32)">{mark(ACCENT)}</g>'
        "</svg>"
    )
    out = ROOT / "plugins" / "love" / ".claude-plugin" / "icon.png"
    subprocess.run(
        ["magick", "-background", "none", "-density", "1200", str(icon_svg), "-resize", "512x512", f"png32:{out}"],
        check=True,
    )
    icon_svg.unlink()


if __name__ == "__main__":
    ASSETS.mkdir(exist_ok=True)
    write_svgs()
    write_icon()
    print("logo and icon written")
