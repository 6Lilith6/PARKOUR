"""LEVEL 7 - CLIFF VILLAGE

A mountain settlement on rock ledges above a deep valley: stone, white
houses with flat roofs, wooden bridges, old ladders, ropes and beams.
Style: PRECISION AND VERTICALITY - careful hops, balance, cat leaps and
climbs, with long falls if you miss (a fall respawns at the last flag).
Only the yellow rock and ladders can be climbed.

  ravine    plank bridge with rope rails | balance on the rope | run the
            house roof and jump for the far house
  cliff     12m face: zig-zag ladders over wooden shelves | the yellow
            rock crack | jump-grab up the stepped outcrops
  gorge     broken plank bridge (one hop) | beams between rock spires |
            hop the rock pillars
  village   terraced houses: ladders | crate + jump-grabs | run-ups
  summit    long ladder | run up the ledge and the summit wall
"""
from .common import *

NAME = "cliff village"
PALETTE = {13: 134, 3: 131, 11: 139, 4: 132}
SKY = (12, 7, 6, 13, 3, 7, 6, 30, 44, 192, 26)
MATS = {
    A: (6, 13, 5, 0x58),      # rock
    B: (4, 7, 6, 0x51),       # white houses, flat roofs
    PROP: (4, 4, 2, 0),       # crates, sheds
    BEAM: (4, 2, 2, 0),       # timber beams
    TRIM: (9, 4, 4, 0),       # ropes, rails
    CLIMB: (10, 9, 9, 0x02),  # ladders, climbable rock
    SIGN: (8, 12, 10, 0x03),  # prayer flags
    BOUNCE: (8, 8, 2, 0x78),
    WOOD: (4, 4, 2, 0),       # planks, shelves
    GLASS: (7, 6, 6, 0),      # snow
    DARK: (5, 0, 0, 0),
    ACCENT: (11, 3, 3, 0),    # grass ledges
}


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- start ledge + ravine ----------
    box(-4, 0, -8, 12, 6, 8, A)                       # ledge R0 (6)
    L.cp(1, 6, -7, 4, -4, 0)
    L.hint(-4, 6, -8, 12, -2, 0)
    box(6, 6, -4, 11, 9, 8, B)                        # house roof 9
    box(7, 6, -6, 10, 7.25, -4, PROP)                 # crate up
    box(.5, 5.75, 8, 2.5, 6, 14, WOOD)                # bridge
    for x in (.25, 2.5):
        box(x, 6.75, 8, x + .25, 7, 14, TRIM)         # rope rails
    box(-2.125, 5.75, 8, -1.875, 6, 14, TRIM)         # rope: balance
    L.hint(-4, 6, 2, 6, 8, 1)
    box(-4, 0, 14, 14, 6, 34, A)                      # ledge R1 (6)
    box(6, 6, 14, 11, 8, 20, B)                       # far house, roof 8
    box(-4, 6, 22, 1, 9.5, 27, B)
    P(2, 18, 6, 1.5, 1.5, 1)
    L.cp(-4, 6, 14, 6, 17, 1)

    # ---------- the cliff: 6 -> 18 at z 34 ----------
    box(-6, 0, 34, 14, 18, 60, A)                     # upper ledge R2 (18)
    box(-5, 9.75, 31, 0, 10, 34, WOOD)                # shelf 10
    box(-4, 6, 30.75, -2.5, 10, 31, CLIMB)
    box(0, 13.75, 31, 5, 14, 34, WOOD)                # shelf 14
    box(-.25, 10, 32, 0, 14, 33.5, CLIMB)
    box(2, 14, 33.75, 3.5, 18, 34, CLIMB)
    box(5.5, 6, 33.75, 7, 18, 34, CLIMB)              # yellow rock crack
    box(9, 6, 29, 13, 8.5, 34, A)                     # outcrops
    box(8.5, 8.5, 30.5, 12.5, 11, 34, A)
    box(9.5, 11, 31.75, 13.5, 13.5, 34, A)
    box(9, 13.5, 33, 13, 16, 34, A)
    L.hint(-4, 6, 26, 14, 30, 2)
    L.cp(-6, 18, 34, 14, 37, 2)
    box(-5, 18, 44, -1, 21, 49, B)
    P(8, 46, 18, 2, 2, 1.25)

    # ---------- the gorge (z 60..86) at 18 ----------
    box(0, 17.75, 60, 1.5, 18, 72, WOOD)              # bridge, broken
    box(0, 17.75, 74, 1.5, 18, 86, WOOD)
    for x in (-.25, 1.5):
        box(x, 18.75, 60, x + .25, 19, 86, TRIM)
    box(0, 18, 85.75, 1.5, 20, 86, CLIMB)
    box(6, 17.75, 60, 6.5, 18, 70, BEAM)              # beams + spires
    box(5, 0, 70, 7.5, 18.5, 72.5, A)
    box(6, 18.25, 72.5, 6.5, 18.5, 78, BEAM)
    box(5, 0, 78, 7.5, 19, 80.5, A)
    box(6, 18.75, 80.5, 6.5, 19, 86, BEAM)
    for i in range(8):                                # rock pillars
        z = 61.75 + i * 3.25
        box(11, 0, z, 12.5, 18.25 + i * .25, z + 1.5, A)
    L.hint(-6, 18, 54, 14, 60, 3)

    # ---------- upper village (z 86..112) at 20 ----------
    box(-6, 0, 86, 14, 20, 112, ACCENT)               # grass terrace R3
    L.cp(-6, 20, 86, 14, 89, 3)
    L.hint(-6, 20, 89, 14, 91, 4)
    box(-4, 20, 92, 6, 23, 98, B)                     # terraced houses
    box(-4, 20, 98, 6, 25.5, 104, B)
    box(-4, 20, 104, 6, 28, 112, B)
    box(-3, 20, 91.75, -1.5, 23, 92, CLIMB)           # ladders
    box(-3, 23, 97.75, -1.5, 25.5, 98, CLIMB)
    box(-3, 25.5, 103.75, -1.5, 28, 104, CLIMB)
    box(2, 20, 90, 4, 21.25, 92, PROP)                # crate
    box(6, 22.75, 100, 7.5, 23, 103, WOOD)            # balcony
    box(8, 20, 96, 12, 22.5, 100, PROP)               # goat shed
    for z in (95, 101):
        box(6, 25.75, z, 14, 26, z + .25, TRIM)       # washing lines
    box(10, 20, 104, 14, 26, 108, A)                  # stone tower

    # ---------- summit (z 112..150) ----------
    box(-6, 0, 112, 14, 28, 130, A)                   # R4 (28)
    L.cp(-6, 28, 112, 14, 115, 4)
    box(-6, 0, 130, 10, 34, 150, GLASS)               # snowy summit (34)
    box(-2, 28, 129.75, -.5, 34, 130, CLIMB)          # long ladder
    box(4, 28, 128, 9, 31, 130, A)                    # ledge (31)
    L.hint(-6, 28, 120, 14, 126, 5)
    box(0, 34, 140, 4, 37, 144, B)                    # stupa
    for x in (-4, 8):
        box(x, 34, 138, x + .25, 38, 138.25, TRIM)     # flag poles
    box(-3.75, 37.25, 138, 8, 37.5, 138.25, SIGN, 1)  # prayer flags
    L.goal(-4, 34, 132, 8, 137)

    # ---------- far peaks ----------
    box(-50, 0, 40, -30, 50, 70, A)
    box(-46, 50, 46, -34, 56, 64, GLASS)
    box(34, 0, 80, 56, 46, 110, A)
    box(38, 46, 86, 52, 52, 104, GLASS)
    box(-40, 0, 150, -16, 60, 180, A)
    box(20, 0, 160, 44, 40, 184, A)
    return L
