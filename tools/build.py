#!/usr/bin/env python3
"""Assemble parkour.p8 from src/*.lua, the level script and sfx defs.

    python3 tools/build.py            -> writes parkour.p8

Each src module becomes its own PICO-8 code tab. The level geometry is
compiled into map memory (0x2000) so it costs no code tokens.
"""
import importlib, os, struct, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import p8mem  # noqa: E402
from levels import ORDER  # noqa: E402

# code tabs, in order
MODULES = ["main", "level", "collide", "parkour", "player", "anim",
           "camera", "render", "fx"]

# memory free for level data: gfx+map+flags, and sfx slots 19..63
REGIONS = [(0x0010, 0x3100), (0x3200 + 19 * 68, 0x4300)]


def level_blob(mod):
    """palette(16) sky(11) materials(15x4) count(2) boxes(10 each)"""
    out = bytearray(mod.PALETTE.get(i, i) for i in range(16))
    out += bytes(mod.SKY)
    for m in range(1, 16):
        out += bytes(mod.MATS.get(m, (0, 0, 0, 0)))
    boxes = mod.build().boxes
    out += struct.pack("<h", len(boxes))
    for (x0, y0, z0, x1, y1, z1, m, k) in boxes:
        dims = [(x1 - x0) * 4, (y1 - y0) * 4, (z1 - z0) * 4]
        for v in dims:
            assert v == int(v) and 0 < v < 256, (mod.NAME, x0, y0, z0, x1, y1, z1)
        for v in (x0, y0, z0):
            assert v * 8 == int(v * 8), (mod.NAME, x0, y0, z0)
        out += struct.pack("<hhhBBBB", int(x0 * 8), int(z0 * 8), int(y0 * 8),
                           *map(int, dims), m | (k << 4))
    return out, len(boxes)


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
    rom = bytearray(p8mem.ROM_END)
    # sound
    for i, line in enumerate(sfx_lines()[:19]):
        a = p8mem.SFX + i * 68
        rom[a + 64:a + 68] = bytes.fromhex(line[:8])
        for n in range(32):
            f = line[8 + n * 5:13 + n * 5]
            p, w, v, e = int(f[:2], 16), int(f[2], 16), int(f[3], 16), int(f[4], 16)
            val = p | (w & 7) << 6 | v << 9 | e << 12 | (w >> 3) << 15
            rom[a + n * 2:a + n * 2 + 2] = struct.pack("<H", val)
    for i, (fl, ch) in enumerate(MUSIC):
        for c, sid in enumerate(ch):
            rom[p8mem.MUSIC + i * 4 + c] = sid | ((fl >> c) & 1) << 7
    for i in range(len(MUSIC), 64):
        rom[p8mem.MUSIC + i * 4:p8mem.MUSIC + i * 4 + 4] = b"\x40\x40\x40\x40"
    # levels: first fit into the free regions
    free = [list(r) for r in REGIONS]
    stats = []
    for n, name in enumerate(ORDER):
        try:
            mod = importlib.import_module("levels." + name)
        except ModuleNotFoundError:
            mod = importlib.import_module("levels." + ORDER[0])
        blob, nb = level_blob(mod)
        for r in free:
            if r[1] - r[0] >= len(blob):
                rom[r[0]:r[0] + len(blob)] = blob
                struct.pack_into("<H", rom, n * 2, r[0])
                r[0] += len(blob)
                break
        else:
            raise SystemExit("out of cart memory at level %s" % name)
        stats.append((mod.NAME, nb, len(blob)))
    sec = p8mem.rom_to_sections(rom)
    p8 = ["pico-8 cartridge // http://www.pico-8.com", "version 42", "__lua__", code]
    for name in ("gfx", "gff", "map", "sfx", "music"):
        p8 += ["__%s__" % name] + sec[name]
    label = os.path.join(ROOT, "tools", "label.txt")
    if os.path.exists(label):
        with open(label) as f:
            p8 += ["__label__"] + f.read().split()
    out_path = out_path or os.path.join(ROOT, "parkour.p8")
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(p8) + "\n")
    free_left = sum(r[1] - r[0] for r in free)
    return out_path, stats, free_left


if __name__ == "__main__":
    path, stats, free_left = build()
    for name, nb, size in stats:
        print("  %-20s %4d boxes %5d bytes" % (name, nb, size))
    print("wrote %s, %d bytes of level memory free" % (path, free_left))
