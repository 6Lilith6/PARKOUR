"""LEVEL 8 - MEGASTRUCTURE

A colossal industrial tower at dusk: a lit concrete core, catwalks,
orange girders, hazard panels, containers and hanging cargo, a glowing
reactor pit far below. Style: EVERYTHING - a switchback climb from the
bottom of the pit to the top of the core using every move.

  Catwalk legs alternate sides of the core, each one tier (8m) higher:
    A  y2  west, north   vault, slide, gap (jump | beam)
    B  y10 east, south   slide, 8m gap (panel wallrun | plates | pipe)
    C  y18 west, north   gap (core wallrun | plates | pipe), slide
    D  y26 east, south   bounce pad, gap (core wallrun | pipe), vault
  Every 8m climb: ladders | step chain (containers, hanging cargo) |
  run up a 4m machine block, then run up again.
  Finale: the crown (top of the core, y42) - one last sprint.

Legs never overlap in plan, so a fall drops into the pit and respawns.
"""
from .common import *

NAME = "megastructure"
PALETTE = {12: 140, 9: 137, 6: 134, 14: 136, 3: 131, 13: 141}
SKY = (2, 9, 5, 0, 0, 8, 2, 26, 50, 192, 30)
MATS = {
    A: (6, 5, 0, 0x58),       # catwalk decks, tier blocks
    B: (13, 5, 2, 0x51),      # machine blocks
    PROP: (6, 13, 5, 0x55),   # vents
    BEAM: (9, 4, 4, 0x07),    # orange girders
    TRIM: (13, 5, 5, 0),      # pipes, ducts
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (10, 10, 0, 0x04),  # hazard panels
    BOUNCE: (8, 8, 2, 0x78),  # bounce pads
    WOOD: (4, 4, 2, 0),       # hanging cargo
    GLASS: (12, 12, 1, 0),    # reactor glow
    DARK: (5, 1, 0, 0x18),    # the core
    ACCENT: (8, 8, 2, 0x04),  # containers
}


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- the core, the pit, the tier blocks ----------
    box(10, 0, 0, 18, 42, 48, DARK)                   # core, crown at 42
    box(-4, -4, -9, 32, 0, 53, GLASS)                 # reactor glow (pit)
    box(0, 2, 48, 28, 10, 54, A)                      # N1 (10)
    box(0, 10, -8, 28, 18, 0, A)                      # S1 (18)
    box(0, 18, 48, 28, 26, 54, A)                     # N2 (26)
    box(0, 26, -8, 28, 34, 0, A)                      # S2 (34)

    # ---------- leg A: y2, x 0..6, north ----------
    box(0, 1.5, -6, 6, 2, 20, A)
    box(0, 1.5, 23, 6, 2, 48, A)                      # gap z 20..23
    box(4.75, 1.75, 20, 5, 2, 23, TRIM)               # beam over it
    L.cp(1, 2, -6, 5, -3, 0)
    L.hint(0, 2, -6, 6, 0, 0)
    P(1, 6, 2, 4, 1.5, 1)                             # vent: vault
    box(0, 3, 14, 6, 3.5, 14.5, TRIM)                 # duct: slide
    # climb 1 (2 -> 10, face z 48)
    box(3, 2, 38, 6, 6, 48, B)                        # machine (6)
    box(4.5, 2, 37.75, 6, 6, 38, CLIMB)
    box(4.5, 6, 47.75, 6, 10, 48, CLIMB)
    box(0, 2, 40, 3, 4.5, 42.5, ACCENT)               # containers
    box(0, 2, 42.5, 3, 7, 45, ACCENT)
    box(0, 2, 45, 3, 9.5, 48, ACCENT)
    L.hint(0, 2, 30, 6, 36, 1)
    L.cp(0, 10, 48, 10, 54, 1)

    # ---------- leg B: y10, x 22..28, south ----------
    P(14, 50, 10, 1.5, 3, 1)                          # vent on N1
    box(22, 9.5, 30, 28, 10, 48, A)
    box(22, 9.5, 0, 28, 10, 20, A)                    # gap z 20..30
    box(22, 11, 40, 28, 11.5, 40.5, TRIM)             # duct: slide
    box(28, 11, 18, 28.5, 16, 32, SIGN)               # wallrun panel
    for z in (26, 22):
        box(24.5, 9.75, z, 26, 10, z + 1.5, WOOD)     # plates
    box(22.5, 9.75, 20, 22.75, 10, 30, TRIM)          # pipe: balance
    L.hint(22, 10, 32, 28, 38, 2)
    P(23, 12, 10, 4, 1.5, 1)                          # vent: vault
    # climb 2 (10 -> 18, face z 0)
    box(26, 10, 0, 27.5, 18, .25, CLIMB)
    box(22, 12.25, 4, 25, 12.5, 6, WOOD)              # hanging cargo
    box(22, 14.75, 1, 25, 15, 3, WOOD)
    for x in (22, 24.75):
        box(x, 12.5, 5.75, x + .25, 18, 6, TRIM)
        box(x, 15, 2.75, x + .25, 18, 3, TRIM)
    L.cp(0, 18, -8, 28, -5, 2)

    # ---------- leg C: y18, x 6..10, north ----------
    box(6, 17.5, 0, 10, 18, 12, A)
    box(6, 17.5, 24, 10, 18, 48, A)                   # gap z 12..24
    P(6.5, 3, 18, 3, 1.5, 1)                          # vent
    box(6, 19, 8, 10, 19.5, 8.5, TRIM)                # duct: slide
    for z in (14.5, 18, 21.5):
        box(7.5, 17.75, z, 9, 18, z + 1.5, WOOD)      # plates
    box(6.25, 17.75, 12, 6.5, 18, 24, TRIM)           # pipe
    L.hint(6, 18, 0, 10, 2, 3)
    # climb 3 (18 -> 26, face z 48)
    box(8, 18, 36, 10, 22, 48, B)                     # machine (22)
    box(6.25, 18, 47.75, 7.75, 26, 48, CLIMB)
    box(6, 20.25, 41, 8, 20.5, 43, WOOD)              # hanging cargo
    box(6, 22.75, 44.5, 8, 23, 46.5, WOOD)
    L.cp(0, 26, 48, 28, 54, 3)

    # ---------- leg D: y26, x 18..22, south ----------
    box(18, 25.5, 30, 22, 26, 48, A)
    box(18, 25.5, 0, 22, 26, 18, A)                   # gap z 18..30
    box(19, 26, 40, 21, 26.75, 43, BOUNCE)            # bounce pad
    box(21.5, 25.75, 18, 21.75, 26, 30, TRIM)         # pipe
    for z in (20, 23.5, 27):
        box(19.5, 25.75, z, 21, 26, z + 1.5, WOOD)    # plates
    P(18.5, 10, 26, 3, 1.5, 1)                        # vent: vault
    L.hint(18, 26, 40, 22, 46, 4)
    # climb 4 (26 -> 34, face z 0)
    box(18, 26, 0, 20, 30, 8, B)                      # machine (30)
    box(20.25, 26, 0, 21.75, 34, .25, CLIMB)
    box(20, 28.5, 4, 22, 28.75, 6, WOOD)              # hanging cargo
    box(20, 31, 1, 22, 31.25, 3, WOOD)
    L.cp(0, 34, -8, 28, -5, 4)

    # ---------- climb 5 (34 -> 42, core face z 0) + crown ----------
    box(15.75, 34, -.25, 17.25, 42, 0, CLIMB)
    box(12.25, 34, -7, 15.25, 36.5, -4.5, ACCENT)     # containers
    box(12.25, 34, -4.5, 15.25, 39, -2, ACCENT)
    box(12.25, 34, -2, 15.25, 41.5, 0, ACCENT)
    box(10, 34, -6, 12, 38, 0, B)                     # machine (38)
    L.hint(0, 34, -8, 28, -5, 5)
    L.cp(10, 42, 0, 18, 3, 5)
    P(11, 14, 42, 6, 1.5, 1)
    box(10, 43.25, 26, 18, 43.75, 26.5, TRIM)
    P(12, 36, 42, 4, 2, 1.25)
    L.goal(10, 42, 44, 18, 48)

    # ---------- skyline: other towers ----------
    box(-40, 0, -10, -28, 56, 4, DARK)
    box(50, 0, 10, 62, 50, 24, DARK)
    box(-36, 0, 50, -24, 40, 64, A)
    box(44, 0, 60, 56, 60, 72, DARK)
    return L
