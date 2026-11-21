"""Draws the plugin's folder tree as `tree` would print it in a terminal.

Writes docs/tree-dark.png and docs/tree-light.png, at twice the size they're
shown in the README. The tree is read from plugins/love, so it follows the
plugin. Skill folders and .claude-plugin are shown closed, and evals/ is left
out. Needs Pillow.

    python3 tools/make_tree.py
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
PLUGIN = ROOT / "plugins" / "love"
MONO = ROOT / "tools" / "fonts" / "SourceCodePro-Regular.otf"

SCALE = 2
CORAL = "#e0605a"
THEMES = {
    "dark": {"panel": "#18171d", "border": "#2c2a31", "ink": "#ece6da", "muted": "#7d786f"},
    "light": {"panel": "#ffffff", "border": "#e3ded5", "ink": "#1f1d1b", "muted": "#9a948a"},
}
HIDDEN = {"evals"}
CLOSED = {".claude-plugin"}


def entries():
    """(prefix, name, is_skill) for each line under the root."""
    lines = []

    def walk(folder, prefix, in_skills):
        children = sorted(
            (p for p in folder.iterdir() if p.name not in HIDDEN),
            key=lambda p: (not p.is_dir(), p.name),
        )
        for i, child in enumerate(children):
            last = i == len(children) - 1
            branch = "└── " if last else "├── "
            name = child.name + ("/" if child.is_dir() else "")
            lines.append((prefix + branch, name, in_skills))
            if child.is_dir() and not in_skills and child.name not in CLOSED:
                walk(child, prefix + ("    " if last else "│   "), child.name == "skills")

    walk(PLUGIN, "", False)
    return lines


def draw(theme_name):
    theme = THEMES[theme_name]
    s = SCALE
    font = ImageFont.truetype(str(MONO), 21 * s)
    row = 37 * s
    pad_x, pad_top, pad_bottom = 46 * s, 84 * s, 40 * s
    lines = entries()

    text_width = max(font.getlength(p + n) for p, n, _ in lines)
    width = int(pad_x * 2 + max(text_width, font.getlength("$ tree love")) + 40 * s)
    height = int(pad_top + row * (len(lines) + 2) + pad_bottom)

    image = Image.new("RGBA", (width, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(image)
    d.rounded_rectangle([0, 0, width - 1, height - 1], 18 * s, fill=theme["panel"], outline=theme["border"], width=s)
    for i, color in enumerate(("#ff5f57", "#febc2e", "#28c840")):
        cx, cy = 30 * s + i * 22 * s, 28 * s
        d.ellipse([cx - 6 * s, cy - 6 * s, cx + 6 * s, cy + 6 * s], fill=color)

    x, y = pad_x, pad_top
    d.text((x, y), "$ ", font=font, fill=CORAL)
    d.text((x + font.getlength("$ "), y), "tree love", font=font, fill=theme["ink"])
    y += row
    d.text((x, y), "love/", font=font, fill=theme["ink"])
    y += row
    for prefix, name, is_skill in lines:
        d.text((x, y), prefix, font=font, fill=theme["muted"])
        d.text((x + font.getlength(prefix), y), name, font=font, fill=CORAL if is_skill else theme["ink"])
        y += row

    out = ROOT / "docs" / f"tree-{theme_name}.png"
    image.save(out, optimize=True)
    print(f"Wrote {out.relative_to(ROOT)} ({width}x{height})")


if __name__ == "__main__":
    for name in THEMES:
        draw(name)
