"""Draws the app icon (used for the home-screen shortcut): the frame's ship form over a dark console tile."""
import sys
from PIL import Image, ImageDraw, ImageFilter

def icon(size):
    scale = 4
    s = size * scale
    img = Image.new("RGBA", (s, s), (5, 8, 16, 255))
    d = ImageDraw.Draw(img)
    # Glow
    glow = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([s * 0.18, s * 0.18, s * 0.82, s * 0.82], fill=(60, 150, 255, 120))
    glow = glow.filter(ImageFilter.GaussianBlur(s * 0.08))
    img.alpha_composite(glow)
    d = ImageDraw.Draw(img)
    # Ship, nose up.
    half = [(0, -0.30), (0.05, -0.14), (0.08, -0.04), (0.24, 0.04), (0.26, 0.14), (0.10, 0.11), (0.09, 0.20), (0, 0.17)]
    pts = half + [(-x, y) for x, y in reversed(half[1:-1])]
    c = s / 2
    poly = [(c + x * s * 1.25, c + y * s * 1.25) for x, y in pts]
    d.polygon([(px, py + s * 0.04) for px, py in [(c - s * 0.05, c + 0.2 * s * 1.25), (c, c + 0.42 * s), (c + s * 0.05, c + 0.2 * s * 1.25)]], fill=(255, 190, 80, 255))
    d.polygon(poly, fill=(40, 90, 140, 255), outline=(110, 210, 255, 255), width=scale * 3)
    inner = [(c + x * s * 0.85, c + y * s * 0.8 - s * 0.01) for x, y in pts]
    d.polygon(inner, fill=(70, 150, 210, 255))
    d.polygon([(c, c - 0.2 * s), (c + 0.03 * s, c - 0.08 * s), (c, c - 0.04 * s), (c - 0.03 * s, c - 0.08 * s)], fill=(200, 240, 255, 255))
    d.rounded_rectangle([scale * 2, scale * 2, s - scale * 2, s - scale * 2], radius=s * 0.18, outline=(255, 190, 80, 255), width=scale * 4)
    return img.resize((size, size), Image.LANCZOS)

out = sys.argv[1]
icon(512).save(out)
