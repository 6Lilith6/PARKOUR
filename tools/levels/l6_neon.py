"""LEVEL 6 - NEON DISTRICT

Night. Dark facades with lit windows, neon billboards, cyan-edged beams;
roofs stay light so every surface reads against the navy fog. Style:
SPEED - a long descending rooftop line where a good run never stops:
long runways, long wallruns, big gaps.

  launch    roof at 24: speed vault, slide, 6m gap down to 22 (or the
            hanging sign bridge)
  alley     14m gap: wallrun the billboard | hop the neon letters |
            balance the beam
  highway   wide roof at 20; the bar kiosk bounces you onto the high
            roof (23) for the expert line
  big gap   9m: full-speed long jump | from the high roof with a roll |
            hop the hanging signs
  rail      elevated track: sprint the deck (vault, slide) | wallrun the
            train | run its roof
  finale    leap from the train roof to the tower | run up the sign
            block and the tower face | ladders
"""
from .common import *

NAME = "neon district"
PALETTE = {11: 139, 6: 134, 9: 136}
SKY = (0, 1, 2, 1, 0, 7, 1, 32, 39, 192, 18)
MATS = {
    A: (13, 1, 2, 0xa1),      # roofs, lit windows (yellow)
    B: (13, 2, 1, 0xe1),      # roofs, lit windows (pink)
    PROP: (6, 13, 5, 0x55),   # AC units, kiosks
    BEAM: (12, 1, 1, 0),      # cyan-edged beams
    TRIM: (6, 13, 13, 0),     # pipes, gantries
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (14, 14, 12, 0x03),  # neon billboards
    BOUNCE: (14, 14, 2, 0x78),
    WOOD: (4, 4, 2, 0),       # water tanks
    GLASS: (12, 1, 1, 0xc1),  # glass tower, skylights
    DARK: (5, 0, 0, 0),       # pillars, poles
    ACCENT: (6, 1, 13, 0xc5),   # train, lit windows
}


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- launch: roof R1 at 24 ----------
    box(-2, 0, -6, 14, 24, 32, A)
    L.cp(4, 24, -5, 8, -2, 0)
    L.hint(-2, 24, -6, 14, 2, 0)
    P(2, 8, 24, 8, 1.5, 1)                            # AC: speed vault
    box(-2, 25.25, 18, 14, 25.75, 18.5, TRIM)         # pipe: slide
    L.tank(9.5, 24, 24)
    box(14, 14, 6, 14.75, 22, 7.5, SIGN, 1)           # blade signs
    box(-2.75, 12, 20, -2, 21, 21.5, SIGN, 2)
    box(-1, 21, 32, 1, 22, 38, SIGN, 2)               # hanging sign bridge
    box(12.5, 24, 2, 13.5, 31, 3, SIGN, 1)            # rooftop blade sign

    # ---------- R2 at 22 ----------
    box(-2, 0, 38, 14, 22, 70, B)
    L.cp(-2, 22, 38, 14, 41, 1)
    box(3, 22, 44, 9, 22.75, 48, GLASS)               # skylight: vault
    box(-2, 23.25, 60, 8, 26, 60.25, SIGN, 3)         # billboard: slide
    for x in (-2, 7.75):
        box(x, 22, 60, x + .25, 23.25, 60.25, BEAM)
    L.hint(-2, 22, 62, 14, 70, 1)
    box(-2, 22, 40, -1.75, 27, 52, SIGN, 2)           # side billboard
    # alley gap z 70..84
    box(12, 19, 70, 12.5, 25, 84, SIGN)               # wallrun billboard
    box(12, 0, 76.5, 12.5, 19, 77.5, DARK)
    for i, z in enumerate((73, 77, 81)):
        box(4.5, 21.25 - i * .5, z, 6.5, 21.5 - i * .5, z + 2, SIGN, i + 1)  # letters
    box(0, 21.75, 70, .5, 22, 84, BEAM)               # beam: balance

    # ---------- highway: R3 at 20 ----------
    box(-6, 0, 84, 14, 20, 130, A)
    L.cp(-6, 20, 84, 14, 87, 2)
    box(8, 20, 97, 14, 20.75, 100, PROP)              # bar kiosk
    box(8, 20.75, 97, 14, 21, 100, BOUNCE)            # its awning
    box(8, 20, 100, 14, 23, 130, B)                   # high roof (23)
    box(13.75, 23, 112, 14, 26, 112.25, TRIM)         # antenna
    box(-6, 20, 96, -5.75, 25, 108, SIGN, 3)          # side billboard
    P(-4, 92, 20, 3, 2, 1)                            # AC units
    P(0, 104, 20, 2, 3, 1.25)
    P(-5, 114, 20, 2, 2, 1)
    L.tank(-3, 120, 20)
    box(1, 20, 108, 3, 20.75, 112, GLASS)
    L.hint(-6, 20, 86, 14, 92, 2)
    # big gap z 130..139
    box(-4, 19.25, 132, 0, 19.5, 134.5, SIGN, 1)      # hanging signs
    box(-4, 19, 136, 0, 19.25, 137.5, SIGN, 2)

    # ---------- R4 at 19, then the elevated rail ----------
    box(-6, 0, 139, 14, 19, 160, B)
    L.cp(-6, 19, 139, 14, 142, 3)
    P(6, 148, 19, 4, 1.5, 1)
    box(-6, 20.25, 154, 0, 20.75, 154.5, TRIM)
    L.hint(-6, 19, 152, 14, 160, 3)
    box(12.5, 19, 141, 13.5, 26, 142, SIGN, 2)
    box(0, 15.5, 160, 8, 16, 200, A)                  # track deck (16)
    for z in (172, 188):
        box(3, 0, z, 5, 15.5, z + 2, DARK)            # pillars
    box(.5, 16, 164, 3.5, 19, 196, ACCENT)            # train, roof 19
    box(5, 16, 176, 7, 17, 177.5, PROP)               # signal box: vault
    box(3.5, 17.25, 186, 8, 17.75, 186.5, TRIM)       # gantry: slide
    box(7.75, 16, 186, 8, 17.25, 186.5, TRIM)
    L.cp(0, 16, 160, 8, 163, 4)

    # ---------- finale: neon tower ----------
    box(-4, 0, 200, 12, 22, 220, GLASS)               # tower, top 22
    box(3, 16, 197, 8, 19, 200, SIGN, 3)              # sign block (19)
    box(5, 16, 196.75, 6.5, 19, 197, CLIMB)           # ladders
    box(4, 19, 199.75, 5.5, 22, 200, CLIMB)
    L.hint(0, 16, 190, 8, 196, 4)
    L.goal(-2, 22, 201, 10, 209)

    # neon edge strips along the roof sides
    for x0, x1, y, z0, z1, m in ((-2, 14, 24, -6, 32, BEAM), (-2, 14, 22, 38, 70, SIGN),
                                 (-6, 14, 20, 84, 130, BEAM), (-6, 14, 19, 139, 160, SIGN)):
        box(x0, y, z0, x0 + .25, y + .25, z1, m)
        box(x1 - .25, y, z0, x1, y + .25, z1, m)
    # ---------- skyline ----------
    box(-30, 0, 20, -18, 40, 32, B)
    box(26, 0, 50, 38, 45, 62, A)
    box(-28, 0, 100, -16, 36, 114, GLASS)
    box(28, 0, 120, 40, 50, 132, B)
    box(-24, 0, 170, -12, 42, 182, A)
    box(24, 0, 196, 36, 38, 208, GLASS)
    return L
