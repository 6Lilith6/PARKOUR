#!/usr/bin/env python3
"""Assemble parkour.p8 from src/*.lua, the level script and sfx defs.

    python3 tools/build.py            -> writes parkour.p8

Each src module becomes its own PICO-8 code tab. The level geometry is
compiled into map memory (0x2000) so it costs no code tokens.
"""
import os, struct, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import level_rooftops as level  # noqa: E402

# code tabs, in order
MODULES = ["main", "level", "collide", "parkour", "player", "anim",
           "camera", "render", "fx"]


def encode_level(boxes):
    """9 bytes per box: x,z int16 (/8) y,w,h,d uint8 (/4) mat|arg<<4."""
    out = bytearray(struct.pack("<h", len(boxes)))
    for (x0, y0, z0, x1, y1, z1, m, k) in boxes:
        vals = [(x1 - x0) * 4, (y1 - y0) * 4, (z1 - z0) * 4, y0 * 4]
        for v in vals:
            assert v == int(v) and 0 <= v < 256, (x0, y0, z0, x1, y1, z1)
        assert x0 * 8 == int(x0 * 8) and z0 * 8 == int(z0 * 8)
        out += struct.pack("<hhBBBBB", int(x0 * 8), int(z0 * 8), int(y0 * 4),
                           int((x1 - x0) * 4), int((y1 - y0) * 4),
                           int((z1 - z0) * 4), m | (k << 4))
    assert len(out) <= 0x1000, "level too big for map memory"
    return out


# sfx: (speed, [(pitch, wave, vol, fx), ...])
SFX = [
    (3, [(30, 6, 2, 5)]),                                   # 0 footstep
    (2, [(22, 4, 3, 1), (29, 4, 3, 0), (34, 4, 2, 5)]),     # 1 jump
    (3, [(14, 6, 4, 5), (8, 6, 2, 5)]),                     # 2 land
    (4, [(32, 6, 2, 4), (36, 6, 3, 0), (33, 6, 2, 5)]),     # 3 roll/slide
    (2, [(40, 2, 3, 5), (45, 2, 2, 5)]),                    # 4 grab/kick
    (3, [(26, 6, 2, 5), (28, 6, 1, 5), (26, 6, 2, 5), (28, 6, 1, 5)]),  # 5 wallrun
    (5, [(36, 0, 4, 0), (40, 0, 4, 0), (43, 0, 4, 0), (48, 0, 4, 5)]),  # 6 checkpoint
    (2, [(28, 6, 3, 5), (34, 6, 2, 5)]),                    # 7 vault
    (5, [(10, 6, 6, 5), (6, 6, 5, 5), (12, 0, 5, 3)]),      # 8 hard landing
    (7, [(36, 5, 4, 0), (40, 5, 4, 0), (43, 5, 4, 0), (48, 5, 5, 0),
         (43, 5, 3, 0), (48, 5, 5, 5)]),                    # 9 finish
    (3, [(20, 0, 4, 1), (32, 0, 4, 1), (44, 0, 3, 5)]),     # 10 bounce
    (5, [(18, 3, 5, 3), (12, 3, 4, 5)]),                    # 11 bonk/fall
]


def sfx_lines():
    lines = []
    for speed, notes in SFX:
        s = "00%02x0000" % speed
        for i in range(32):
            if i < len(notes):
                pi, w, vo, fx = notes[i]
                s += "%02x%x%x%x" % (pi, w, vo, fx)
            else:
                s += "00000"
        lines.append(s)
    while len(lines) < 64:
        lines.append("00" + "10" + "0000" + "0" * 160)
    return lines


def build(out_path=None):
    tabs = []
    for m in MODULES:
        with open(os.path.join(ROOT, "src", m + ".lua"), encoding="utf-8") as f:
            tabs.append(f.read().rstrip("\n"))
    code = "\n-->8\n".join(tabs)
    data = encode_level(level.build())
    mem = bytes(data) + bytes(0x1000 - len(data))
    map_lines = [mem[i:i + 128].hex() for i in range(0, 0x1000, 128)]
    p8 = ["pico-8 cartridge // http://www.pico-8.com", "version 42",
          "__lua__", code, "__map__"] + map_lines + ["__sfx__"] + sfx_lines()
    out_path = out_path or os.path.join(ROOT, "parkour.p8")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(p8) + "\n")
    return out_path, len(level.build())


if __name__ == "__main__":
    path, n = build()
    print("wrote %s (%d boxes)" % (path, n))
