#!/usr/bin/env python3
"""Top-down map of a level (colour = top height) for layout checks.
    python3 tools/levelmap.py 2 /tmp/l2.png"""
import importlib, os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image, ImageDraw
from levels import ORDER, common as C

def draw(n, out, scale=6):
    mod = importlib.import_module("levels." + ORDER[n - 1])
    bx = mod.build().boxes
    xs = [b[0] for b in bx] + [b[3] for b in bx]
    zs = [b[2] for b in bx] + [b[5] for b in bx]
    x0, x1, z0, z1 = min(xs) - 2, max(xs) + 2, min(zs) - 2, max(zs) + 2
    ymax = max(b[4] for b in bx)
    im = Image.new("RGB", (int((x1 - x0) * scale), int((z1 - z0) * scale)), (20, 20, 30))
    d = ImageDraw.Draw(im)
    for b in sorted(bx, key=lambda b: b[4]):
        if b[6] in (C.HINT,):
            continue
        t = b[4] / ymax
        col = (int(60 + 195 * t), int(60 + 120 * t), int(200 - 150 * t))
        if b[6] == C.CP: col = (0, 255, 0)
        if b[6] == C.GOAL: col = (255, 255, 0)
        if b[6] == C.CLIMB: col = (255, 220, 0)
        r = [(b[0] - x0) * scale, (z1 - b[5]) * scale, (b[3] - x0) * scale, (z1 - b[2]) * scale]
        d.rectangle(r, fill=col if b[6] not in (C.CP, C.GOAL) else None,
                    outline=(0, 0, 0) if b[6] not in (C.CP, C.GOAL) else col)
        if (b[3] - b[0]) * scale > 14 and (b[5] - b[2]) * scale > 8 and b[6] not in (C.CP,):
            d.text((r[0] + 2, r[1] + 1), "%g" % b[4], fill=(0, 0, 0))
    im.save(out)
    print(out, im.size)

if __name__ == "__main__":
    draw(int(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else "/tmp/map.png")
