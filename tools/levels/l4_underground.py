"""LEVEL 4 - UNDERGROUND

Metro station, rail tunnel, service rooms. Style: TIGHT SPACES, quick
decisions: short precise jumps, slides, vaults, and constant height
changes:  platform -> rail tunnel -> maintenance walkway -> upper tunnel.
Black fog close in; tiled walls; artificial light strips.

  station A   platform (benches, columns) | train roof (y5.5) | track bed
  tunnel      4m wide: maintenance walkway with gaps and a low cable to
              slide under | track bed with signal box + pipe to slide |
              expert: zig-zag wallrun -> wall jump -> wallrun between
              the tunnel walls
  junction    7m climb to the upper landing: ladder | crate chain from
              the walkway | run up the landing face from a crate
  upper tunnel duct to slide under, a 3m pit, vent to vault, two narrow
              beams over the vent shaft
  exit        ticket barriers, stairs to the street exit
"""
from .common import *

NAME = "underground"
PALETTE = {12: 129, 6: 134, 13: 133, 10: 135, 3: 131, 11: 139, 4: 132}
SKY = (0, 0, 0, 0, 0, 0, 0, 14, 27, 192, 0)
MATS = {
    A: (6, 13, 13, 0x58),     # concrete floors
    B: (13, 3, 3, 0x51),      # tiled walls, ad bands
    PROP: (9, 4, 2, 0x55),    # benches, signal boxes, vents
    BEAM: (6, 5, 5, 0x07),    # walkways, beams
    TRIM: (13, 5, 5, 0),      # pipes, ducts, cables
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (11, 11, 3, 0x03),
    WOOD: (4, 4, 2, 0),
    GLASS: (10, 10, 10, 0x76),  # light strips
    DARK: (5, 0, 0, 0),       # track bed, columns
    ACCENT: (6, 9, 9, 0xa1),  # train, lit windows
}


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- station A (z 0..40), tracks x 9..13 ----------
    box(-1, 0, -1, 23, 2, 41, DARK)                   # track bed
    box(0, 2, 0, 9, 3.25, 40, A)                      # platform W
    box(13, 2, 0, 22, 3.25, 40, A)                    # platform E
    box(-1, 2, 0, 0, 9, 40, B)
    box(22, 2, 0, 23, 9, 40, B)
    box(-1, 2, -1, 23, 9, 0, B)
    box(-1, 9, -1, 23, 9.5, 41, B)                    # ceiling
    box(-1, 2, 40, 9, 9, 41, B)                       # end walls
    box(13, 2, 40, 23, 9, 41, B)
    for z in (10, 20, 30):
        box(7, 3.25, z, 8, 9, z + 1, DARK)            # columns
        box(14, 3.25, z, 15, 9, z + 1, DARK)
    box(2, 3.25, 12, 3, 4.25, 15, PROP)               # benches
    box(19, 3.25, 22, 20, 4.25, 25, PROP)
    box(9.25, 2, 4, 12.75, 5.5, 22, ACCENT)           # train
    box(9.25, 2, 23.5, 12.75, 5.5, 36, ACCENT)
    box(9, 2, 37, 13, 3.25, 40, A)                    # crossing slab
    box(9, 8, 40, 13, 9, 41, B)                       # above tunnel mouth
    box(3, 6, 39.75, 7, 7.5, 40, SIGN)                # station sign
    for z in (6, 18, 30):
        box(4, 8.75, z, 5, 9, z + 4, GLASS)
        box(17, 8.75, z, 18, 9, z + 4, GLASS)
    L.cp(2, 3.25, 1, 6, 3, 0)
    L.hint(0, 3.25, 0, 9, 6, 0)

    # ---------- tunnel (z 41..90), interior x 9..13 ----------
    box(8, 0, 41, 14, 2, 90, DARK)                    # tunnel floor
    box(8, 2, 41, 9, 8, 90, B)
    box(13, 2, 41, 14, 8, 90, B)
    box(8, 8, 41, 14, 8.5, 90, B)
    for z0, z1 in ((41, 55), (58, 70), (73, 90)):
        box(9, 3.25, z0, 10.25, 4.25, z1, BEAM)       # walkway
    box(11.5, 2, 48, 12.75, 3, 49, PROP)              # signal box
    box(10.25, 3, 60, 13, 3.5, 60.5, TRIM)            # pipe: slide
    box(9, 5.25, 64, 10.25, 5.5, 64.5, TRIM)          # cable: slide
    for z in (50, 66, 82):
        box(10.5, 7.75, z, 11.5, 8, z + 2, GLASS)
    L.hint(9, 3.25, 41, 13, 46, 1)
    L.hint(9, 2, 52, 13, 59, 2)
    L.cp(9, 2, 41, 13, 42, 1)

    # ---------- junction room (z 90..116) ----------
    box(-6, 0, 89, 28, 2, 117, DARK)
    box(-7, 2, 89, -6, 15, 117, B)
    box(28, 2, 89, 29, 15, 117, B)
    box(-7, 2, 89, 8, 15, 90, B)
    box(14, 2, 89, 29, 15, 90, B)
    box(-7, 2, 116, 9, 15, 117, B)
    box(13, 2, 116, 29, 15, 117, B)
    box(9, 13.5, 116, 13, 15, 117, B)
    box(-7, 15, 89, 29, 15.5, 117, B)                 # ceiling
    box(-6, 8.5, 111, 28, 9, 116, A)                  # upper landing
    box(-6, 2, 110.75, 28, 8.5, 111, B)               # its face
    box(0, 2, 110.5, 1.5, 9, 110.75, CLIMB)           # ladder (7m)
    box(9, 3.25, 90, 10.25, 4.25, 100, BEAM)          # walkway goes on
    box(9, 2, 100, 11.5, 5.5, 102.5, WOOD)            # crate chain
    box(9, 2, 103.5, 11.5, 6.75, 106, WOOD)
    box(9, 2, 107, 11.5, 8, 109.5, WOOD)
    P(18, 96, 2, 3, 3, 2.5)                           # transformers
    P(22, 102, 2, 3, 2, 1.25)
    box(-6, 6, 100, -5.75, 8, 104, SIGN)
    for x in (2, 18):
        box(x, 14.75, 96, x + 2, 15, 100, GLASS)
    L.cp(-6, 2, 90, 28, 92, 2)
    L.cp(9, 4.25, 90, 10.25, 92, 2)
    L.hint(-6, 2, 104, 28, 110.5, 3)
    L.cp(-6, 9, 112, 28, 116, 3)

    # ---------- upper tunnel (z 117..166) at y9 ----------
    box(9, 8.5, 117, 13, 9, 130, A)
    box(9, 8.5, 133, 13, 9, 140, A)                   # pit z 130..133
    box(9.5, 8.5, 140, 10, 9, 148, BEAM)              # beams over shaft
    box(12, 8.5, 140, 12.5, 9, 148, BEAM)
    box(9, 8.5, 148, 13, 9, 166, A)
    box(8, 9, 117, 9, 13.5, 166, B)
    box(13, 9, 117, 14, 13.5, 166, B)
    box(8, 13.5, 117, 14, 14, 166, B)
    box(9, 10, 124, 13, 10.5, 124.5, TRIM)            # duct: slide
    box(9.5, 9, 137, 12.5, 10, 138, PROP)             # vent: vault
    for z in (121, 135, 152):
        box(10.5, 13.25, z, 11.5, 13.5, z + 2, GLASS)
    L.hint(9, 9, 134, 13, 139.5, 4)
    L.cp(9, 9, 133, 13, 134, 4)

    # ---------- station B exit (z 166..190) ----------
    box(0, 8.5, 166, 22, 9, 190, A)
    box(-1, 9, 165, 9, 16, 166, B)
    box(13, 9, 165, 23, 16, 166, B)
    box(-1, 9, 166, 0, 16, 190, B)
    box(22, 9, 166, 23, 16, 190, B)
    box(-1, 9, 190, 23, 16, 191, B)
    box(-1, 16, 165, 23, 16.5, 191, B)
    for i in range(8):
        x0 = .5 + i * 2.75
        box(x0, 9, 172, x0 + 1.25, 10, 173.5, PROP)   # ticket gates
    for i in range(10):
        box(8, 9, 180 + i, 14, 9.5 + i * .5, 190, A)  # stairs
    box(9, 15, 189.75, 13, 16, 190, SIGN)             # exit sign
    L.cp(9, 9, 166, 13, 168, 5)
    L.goal(8, 14, 186, 14, 190)
    return L
