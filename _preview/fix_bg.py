from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import os, shutil

KEY = (255, 0, 255)
os.makedirs('_preview/backup', exist_ok=True)

for idx in [2, 3, 4]:
    f = f'assets/volcano_asset_{idx:02d}.webp'
    shutil.copy(f, f'_preview/backup/volcano_asset_{idx:02d}.webp')

    base = Image.open(f).convert('RGB')
    w, h = base.size
    work = base.copy()

    # Seed flood fill from border points that look near-white.
    step = max(1, w // 120)
    seeds = []
    for x in range(0, w, step):
        seeds += [(x, 0), (x, h - 1)]
    for y in range(0, h, step):
        seeds += [(0, y), (w - 1, y)]
    for s in seeds:
        px = work.getpixel(s)
        if px[0] > 232 and px[1] > 232 and px[2] > 232:
            ImageDraw.floodfill(work, s, KEY, thresh=42)

    warr = np.array(work)
    mask = np.all(warr == np.array(KEY), axis=-1)

    # Keep original (white) RGB, only drive alpha from the mask, so bilinear
    # scaling never bleeds the magenta key colour into the sprite edges.
    rgb = np.array(base)
    alpha = np.where(mask, 0, 255).astype(np.uint8)
    rgba = np.dstack([rgb, alpha])
    out = Image.fromarray(rgba, 'RGBA')

    # Soften the cut edge a touch.
    a = out.split()[-1].filter(ImageFilter.GaussianBlur(0.7))
    out.putalpha(a)
    out.save(f, 'WEBP', lossless=True)

    # Preview on a dark background.
    prev = Image.new('RGB', (w, h), (26, 19, 32))
    prev.paste(out, (0, 0), out)
    prev.resize((300, int(300 * h / w))).save(f'_preview/fixed_{idx:02d}.png')
    print('processed', f, 'transparent_px', int(mask.sum()), 'of', w * h)
