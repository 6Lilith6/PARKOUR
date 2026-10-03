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


def music_sfx():
    """Ambient running loop: two bass patterns + a beat."""
    def seq(pitches, wave, vol):
        return [(p, wave, vol if p else 0, 0) for p in pitches]
    bass1 = [21, 0, 0, 21, 0, 0, 21, 0, 24, 0, 0, 24, 0, 0, 28, 0,
             17, 0, 0, 17, 0, 0, 17, 0, 19, 0, 0, 19, 0, 0, 23, 0]
    bass2 = [17, 0, 0, 17, 0, 0, 17, 0, 19, 0, 0, 19, 0, 0, 19, 0,
             21, 0, 0, 21, 0, 0, 24, 0, 23, 0, 0, 23, 0, 0, 28, 0]
    beat = [(24, 0, 4, 3) if i % 8 == 0 else (52, 6, 1, 5) if i % 2 == 0
            else (0, 0, 0, 0) for i in range(32)]
    return {16: (14, seq(bass1, 1, 3)), 17: (14, beat), 18: (14, seq(bass2, 1, 3))}


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
    for i, (speed, notes) in music_sfx().items():
        lines[i] = "00%02x0000" % speed + "".join("%02x%x%x%x" % n for n in notes)
    return lines


# patterns: (flags, [ch0..ch3]) flags 1=loop start 2=loop end; 0x40=off
MUSIC = [(1, [16, 17, 0x40, 0x40]), (2, [18, 17, 0x40, 0x40])]


def music_lines():
    out = ["%02x %s" % (fl, "".join("%02x" % c for c in ch)) for fl, ch in MUSIC]
    while len(out) < 64:
        out.append("00 40404040")
    return out


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
          "__lua__", code, "__map__"] + map_lines + ["__sfx__"] + sfx_lines() + \
        ["__music__"] + music_lines()
    label = os.path.join(ROOT, "tools", "label.txt")
    if os.path.exists(label):
        with open(label) as f:
            p8 += ["__label__"] + f.read().split()
    out_path = out_path or os.path.join(ROOT, "parkour.p8")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(p8) + "\n")
    return out_path, len(level.build())


if __name__ == "__main__":
    path, n = build()
    print("wrote %s (%d boxes)" % (path, n))
