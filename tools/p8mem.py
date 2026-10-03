"""Cart memory <-> .p8 text sections (gfx, gff, map, music, sfx).

The cart stores level data as raw bytes spread over the gfx, map, flag and
unused sfx areas; these helpers convert a 0x4300-byte ROM image to the .p8
section text and back, byte-exact.
"""

GFX, GFF, MAP, MUSIC, SFX, ROM_END = 0x0000, 0x3000, 0x2000, 0x3100, 0x3200, 0x4300


def rom_to_sections(rom):
    s = {}
    s["gfx"] = ["".join("%x%x" % (b & 15, b >> 4) for b in rom[GFX + y * 64:GFX + y * 64 + 64])
                for y in range(128)]
    s["gff"] = [rom[GFF + y * 128:GFF + y * 128 + 128].hex() for y in range(2)]
    s["map"] = [rom[MAP + y * 128:MAP + y * 128 + 128].hex() for y in range(32)]
    mus = []
    for y in range(64):
        ch = rom[MUSIC + y * 4:MUSIC + y * 4 + 4]
        flags = sum(((c >> 7) & 1) << i for i, c in enumerate(ch))
        mus.append("%02x %s" % (flags, "".join("%02x" % (c & 0x7f) for c in ch)))
    s["music"] = mus
    sfx = []
    for y in range(64):
        a = SFX + y * 68
        line = rom[a + 64:a + 68].hex()
        for n in range(32):
            v = rom[a + n * 2] | rom[a + n * 2 + 1] << 8
            line += "%02x%x%x%x" % (v & 0x3f, ((v >> 6) & 7) | ((v >> 15) & 1) << 3,
                                     (v >> 9) & 7, (v >> 12) & 7)
        sfx.append(line)
    s["sfx"] = sfx
    return s


def sections_to_rom(text):
    rom = bytearray(ROM_END)
    secs, cur = {}, None
    for line in text.split("\n"):
        if line.startswith("__") and line.endswith("__"):
            cur = line[2:-2]
            secs[cur] = []
        elif cur:
            secs[cur].append(line.strip())
    for y, line in enumerate(secs.get("gfx", [])):
        for x in range(0, len(line), 2):
            rom[GFX + y * 64 + x // 2] = int(line[x], 16) | int(line[x + 1], 16) << 4
    for y, line in enumerate(secs.get("gff", [])):
        b = bytes.fromhex(line)
        rom[GFF + y * 128:GFF + y * 128 + len(b)] = b
    for y, line in enumerate(secs.get("map", [])):
        b = bytes.fromhex(line)
        rom[MAP + y * 128:MAP + y * 128 + len(b)] = b
    for y, line in enumerate(secs.get("music", [])):
        if not line:
            continue
        flags, ids = int(line[:2], 16), bytes.fromhex(line[3:11])
        for i, c in enumerate(ids):
            rom[MUSIC + y * 4 + i] = c | ((flags >> i) & 1) << 7
    for y, line in enumerate(secs.get("sfx", [])):
        if not line:
            continue
        a = SFX + y * 68
        rom[a + 64:a + 68] = bytes.fromhex(line[:8])
        for n in range(32):
            f = line[8 + n * 5:13 + n * 5]
            if len(f) < 5:
                break
            p, w, v, e = int(f[:2], 16), int(f[2], 16), int(f[3], 16), int(f[4], 16)
            val = p | (w & 7) << 6 | v << 9 | e << 12 | (w >> 3) << 15
            rom[a + n * 2] = val & 255
            rom[a + n * 2 + 1] = val >> 8
    return rom
