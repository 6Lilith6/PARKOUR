"""LEVEL 3 - INDUSTRIAL FACTORY

Steel, rust and smog. Style: MOMENTUM - long straights where flow builds
to full speed, and one long combo line:
  sprint (catwalk) -> jump onto containers -> keep jumping the rows ->
  wallrun along the tank -> pipe rack -> slide under crossing pipes ->
  vault the valve -> long jump over the slag pit -> conveyor -> silo

The factory floor (y2) is the safe, slow lane: conveyors to vault, pipes
to slide under, machines to go round, ladders up to the next level. The
slag pit near the end is the only place you can fall.

  warehouse  ground lane with obstacles | catwalk at y6 (ladder or crate
             steps) = sprint lane
  yard       ground weave | single containers | double stacks at y7 with
             4m gaps
  tanks/rack ladder up to the rack (y8) | wallrun along tank T1 from the
             last container
  pit        plank bridge on the ground + ladder | hook container
             stepping stone | full-flow long jump to the conveyor
  silo       ladder | crate | wall run-up; goal on top
"""
from .common import *

NAME = "factory"
PALETTE = {12: 132, 9: 137, 13: 133, 6: 134, 3: 131, 11: 139, 14: 9}
SKY = (12, 9, 13, 0, 5, 0, 13, 24, 21, 0, 14)
MATS = {
    A: (6, 13, 5, 0x04),      # corrugated walls
    B: (3, 3, 1, 0x18),       # tanks, silo
    PROP: (9, 4, 2, 0x55),    # machines
    BEAM: (6, 5, 5, 0x07),    # catwalks, rack frames
    TRIM: (13, 5, 5, 0),      # pipes
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (10, 10, 9, 0x04),  # hazard / conveyor
    BOUNCE: (11, 3, 3, 0x38),
    WOOD: (4, 4, 2, 0),
    GLASS: (12, 12, 1, 0x04), # rust containers
    DARK: (13, 0, 0, 0),      # factory floor
    ACCENT: (8, 8, 2, 0x24),  # red containers
}


def cont(L, x0, z0, y0, n=1, length=12, m=ACCENT):
    """container stack n high, along x"""
    L.box(x0, y0, z0, x0 + length, y0 + 2.5 * n, z0 + 2.5, m)


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- floor (pit at x 150..165) ----------
    box(-10, 0, -10, 50, 2, 20, DARK)
    box(50, 0, -10, 110, 2, 30, DARK)
    box(110, 0, -10, 150, 2, 30, DARK)
    box(165, 0, -10, 200, 2, 30, DARK)

    # ---------- warehouse ----------
    box(-.5, 2, -10, 0, 12, 20, A)                    # back wall
    box(0, 2, 19.5, 50, 12, 20, A)                    # north wall
    box(0, 2, -10, 50, 12, -9.5, A)                   # south wall
    box(0, 12, -10, 50, 12.5, 20, A)                  # roof
    L.cp(1, 2, 3, 4, 7, 0)
    L.hint(0, 2, -9.5, 8, 10, 0)
    # ground lane
    box(12, 2, -9.5, 13.5, 3, 12, SIGN)               # conveyor: vault
    box(22, 3, -9.5, 23, 3.5, 12, TRIM)               # pipe: slide
    box(30, 2, 0, 32, 3.25, 6, WOOD)                  # crates
    P(38, -2, 2, 6, 10, 3)                            # machine
    L.hint(18, 2, -9.5, 22, 12, 4)
    # catwalk sprint lane (y6) + access
    box(4, 5.75, 16, 48, 6, 18.5, BEAM)
    box(3.75, 2, 16.5, 4, 6, 18, CLIMB)
    box(14, 2, 11, 16, 3.25, 13, WOOD)                # crate steps north
    box(14, 2, 13, 16, 4.5, 15, WOOD)
    L.hint(2, 2, 12, 8, 19.5, 1)
    L.cp(48, 2, -9, 51, 19, 1)
    L.cp(48, 6, 15, 51, 19, 1)

    # ---------- container yard ----------
    cont(L, 52, 16, 2, 2)                             # expert lane y7
    cont(L, 68, 16, 2, 2, m=GLASS)
    cont(L, 84, 16, 2, 2)
    cont(L, 56, 11, 2, 1, 8, GLASS)                   # middle: single
    cont(L, 70, 11, 2, 1, 8)
    cont(L, 82, 11, 2, 1, 8, GLASS)
    box(54, 2, 11, 56, 3.25, 13.5, WOOD)              # step up
    P(62, 3, 2, 3, 2, 1.25)                           # forklift
    box(75, 2, 0, 77, 3, 8, WOOD)
    box(88, 3.25, -2, 89, 3.75, 9, TRIM)              # low pipe
    L.hint(50, 7, 16, 54, 18.5, 2)
    L.cp(96, 2, -9, 99, 30, 2)

    # ---------- tanks + pipe rack ----------
    box(98, 2, 18.5, 107.75, 14, 26.5, B)             # tank T1: wallrun
    box(112, 2, 21, 120, 12, 29, B)
    box(124, 2, -8, 132, 12, 0, B)
    L.hint(92, 7, 16, 96, 18.5, 3)
    box(106, 6.5, 16, 150, 7, 18.5, TRIM)             # big pipe: rack top
    box(106, 6.5, 13, 150, 7, 13.5, TRIM)             # small pipe: balance
    for x in (106, 122, 136, 149):
        box(x, 2, 13, x + 1, 6.5, 18, BEAM)           # rack frames
    box(105.75, 2, 16.25, 106, 7, 17.75, CLIMB)       # ladder up
    box(120, 8, 12, 121, 8.5, 19, TRIM)               # crossing pipe: slide
    box(130, 7, 15.5, 131.5, 8, 18, PROP)             # valve: vault
    box(140, 8, 12, 141, 8.5, 19, TRIM)
    L.hint(112, 7, 12, 118, 19, 4)
    L.cp(146, 7, 12, 149, 19, 3)
    L.cp(146, 2, -9, 149, 12, 3)

    # ---------- slag pit + finale ----------
    box(150, 1, 6, 165, 2, 6.5, BEAM)                 # plank bridge
    box(153, 4.5, 15.5, 155.5, 6.75, 18.5, GLASS)     # hook container
    box(154.125, 6.75, 18.25, 154.375, 14, 18.5, TRIM)
    box(157, 6.75, 15, 186, 7, 18.5, SIGN)            # conveyor
    for x in (157, 172, 185):
        box(x, 2, 15.5, x + 1, 6.75, 18, BEAM)
    box(166, 2, 14.75, 167.5, 7, 15, CLIMB)           # ladder to conveyor
    L.hint(144, 7, 12, 150, 19, 5)
    box(188, 2, 12, 196, 10, 22, B)                   # silo
    box(187.75, 2, 14, 188, 10, 15.5, CLIMB)
    box(183, 7, 15.5, 185, 8.25, 18, WOOD)
    L.goal(189, 10, 13, 195, 21)

    # ---------- skyline ----------
    for i, (x, z, h) in enumerate(((20, 40, 30), (70, 50, 40), (130, 45, 35), (180, 40, 25),
                                   (60, -30, 30), (140, -30, 28))):
        box(x, 0, z, x + 3, h, z + 3, A if i % 2 else B)   # chimneys
    box(0, 0, 30, 40, 16, 50, A)
    box(90, 0, 40, 120, 20, 60, A)
    box(200, 0, -10, 220, 18, 30, A)
    return L
