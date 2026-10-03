"""LEVEL 2 - CONSTRUCTION SITE

A skyscraper frame going up. Style: VERTICAL TECHNICAL parkour - climb a
floor, cross it, step outside, cross to the next structure, climb again.
Concrete slabs, orange girders, yellow cranes, hanging pallets, safety
nets. Falling to the dirt (y<1) respawns.

  start   site-office containers (y5), scaffold deck
  T1      unfinished tower, floors at 9 / 13 / 17. Every 4m climb has:
            ladder | pallets / crates / hanging pallet | formwork wall
            to run up
          F2 has a hole in the slab (jump it or walk around the core),
          F1 has a formwork bar you must slide under (or go round)
  gap     20m between towers at y17: hanging pallets (precision hops)
          | 0.4m girder (balance) | hazard panel (wallrun, needs flow)
  T2      staggered decks rising east 17 / 21 / 25 / 29, each rise:
            ladder | safety net bounce or hanging pallets | wall run-up
  finale  crane mast ladder (or pallet+mantle), then walk the jib 34m
          above the ground to the cab
"""
from .common import *

NAME = "construction site"
PALETTE = {}
# top, haze, sil a, sil b, ground, sun, fog, fog dist, hint base,
# heading, silhouette height
SKY = (12, 6, 13, 6, 4, 7, 6, 30, 14, 192, 6)
MATS = {
    A: (6, 13, 13, 0x58),     # concrete slabs, grime
    B: (9, 4, 4, 0x24),       # formwork panels
    PROP: (12, 12, 1, 0x14),  # site containers, bags
    BEAM: (9, 4, 4, 0),       # orange girders
    TRIM: (5, 0, 5, 0),       # rebar, cables
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (10, 10, 9, 0x04),  # hazard panel
    BOUNCE: (11, 3, 3, 0x38), # safety nets
    WOOD: (4, 4, 2, 0),       # pallets, boards
    GLASS: (12, 1, 1, 0),
    DARK: (5, 5, 1, 0),       # lift core
    ACCENT: (10, 10, 9, 0x07),  # crane lattice
}


def build():
    L = Level()
    box, P = L.box, L.prop

    # ---------- start: site offices + deck ----------
    box(-2, 0, -2, 8, 5, 8, PROP)
    box(5, 5, -2, 8, 7.5, 4, PROP)
    L.cp(1, 5, 0, 4, 2, 0)
    L.hint(-2, 5, -2, 8, 6, 0)
    box(-2, 4.75, 8, 10, 5, 12, WOOD)                 # scaffold deck
    for x in (-2, 9.75):
        box(x, 0, 11.5, x + .25, 4.75, 11.75, BEAM)

    # ---------- tower T1 ----------
    box(-4, 8.5, 12, 20, 9, 36, A)                    # F1 top 9
    box(-4, 12.5, 12, 20, 13, 22, A)                  # F2 top 13
    box(-4, 12.5, 25, 20, 13, 28, A)                  # (hole z 22..25)
    box(12, 12.5, 22, 20, 13, 25, A)
    box(-4, 16.5, 20, 20, 17, 36, A)                  # F3 top 17
    box(12, 0, 30, 16, 21, 34, DARK)                  # lift core
    for x in (-4, 19.25):
        for z in (12, 35.25):
            box(x, 0, z, x + .75, 16.5, z + .75, A)   # columns
    # climb 5 -> 9 (F1 south face z=12)
    box(0, 5, 11.75, 1.5, 9, 12, CLIMB)              # ladder
    box(4.5, 5, 10, 6.5, 6.25, 12, WOOD)             # pallets
    box(7, 5, 11.75, 10, 9, 12, B)                   # formwork: run up
    L.hint(-2, 5, 8, 10, 11.75, 1)
    L.cp(-4, 9, 13, 20, 15, 1)
    # F1: rebar to vault, bags, a bar to slide under
    box(-4, 9, 18, 6, 9.75, 18.5, TRIM)
    P(13, 20, 9, 3, 2, 1)
    box(-4, 10.25, 25, 8, 10.75, 25.5, TRIM)
    box(-4, 9, 25, -3.75, 10.25, 25.5, TRIM)
    box(7.75, 9, 25, 8, 10.25, 25.5, TRIM)
    L.hint(-4, 9, 21, 8, 24.5, 2)
    # climb 9 -> 13 (F2 north face z=28, 8m strip z 28..36)
    box(1, 9, 28, 2.5, 13, 28.25, CLIMB)
    box(5, 9, 28.5, 7.5, 10.25, 30.5, WOOD)
    box(5, 10.25, 28, 7.5, 11.5, 29.5, WOOD)
    box(-4, 9, 28, 0, 13, 28.25, B)
    # F2: drywall stack, slab hole z 22..25
    P(13, 14, 13, 2, 2, 1)
    # climb 13 -> 17 (F3 south face z=20, strip z 12..20)
    box(15, 13, 19.75, 16.5, 17, 20, CLIMB)
    box(2, 14.75, 16.5, 4, 15, 18.5, WOOD)           # hanging pallet
    box(2, 15, 18.25, 2.25, 26, 18.5, TRIM)
    box(6, 13, 19.75, 9, 17, 20, B)
    L.hint(-4, 13, 12, 20, 15.5, 3)
    L.cp(-4, 17, 21, 20, 23, 2)

    # ---------- the gap (x 20..40) at y 17 ----------
    box(18, 26, 26.75, 42, 26.5, 27.25, BEAM)        # gantry
    for i in range(5):
        x0 = 21.5 + i * 4
        box(x0, 16.75, 26, x0 + 2.5, 17, 28, WOOD)   # hanging pallets
        box(x0 + 1.125, 17, 27.75, x0 + 1.375, 26, 28, TRIM)
    box(20, 16.75, 30.5, 40, 17, 31, BEAM)           # girder: balance
    box(22, 17.5, 25.75, 37, 21, 26, SIGN)           # panel: wallrun
    L.hint(14, 17, 23, 20, 36, 4)
    # ---------- tower T2: staggered decks rising east ----------
    box(40, 16.5, 12, 56, 17, 36, A)                  # D1 17
    box(46, 20.5, 12, 62, 21, 36, A)                  # D2 21
    box(52, 24.5, 12, 68, 25, 36, A)                  # D3 25
    box(58, 28.5, 12, 75.75, 29, 36, A)               # D4 29
    for x, h in ((40, 16.5), (55.25, 16.5), (61.25, 20.5), (67.25, 24.5), (75, 28.5)):
        for z in (12, 35.25):
            box(x, 0, z, x + .75, h, z + .75, A)      # columns
    L.cp(40, 17, 13, 43, 35, 3)
    # rise 1: D1 -> D2 (face x=46)
    box(45.75, 17, 12, 46, 21, 36, B)                # formwork face
    box(45.5, 17, 14, 45.75, 21, 15.5, CLIMB)
    box(43, 17, 20, 45.75, 17.75, 24, BOUNCE)        # safety net
    L.hint(40, 17, 18, 45, 26, 5)
    # rise 2: D2 -> D3 (face x=52)
    box(51.75, 21, 12, 52, 25, 36, B)
    box(51.5, 21, 32, 51.75, 25, 33.5, CLIMB)
    box(48, 22.75, 20, 50, 23, 22, WOOD)             # hanging pallet
    box(48.875, 23, 21.75, 49.125, 33, 22, TRIM)
    for i, h in enumerate((1.25, 2.5)):
        box(47.5 + i, 21, 13, 51.75, 21 + h, 16, WOOD)  # crate steps
    # rise 3: D3 -> D4 (face x=58)
    box(57.75, 25, 12, 58, 29, 36, B)
    box(57.5, 25, 14, 57.75, 29, 15.5, CLIMB)
    box(55, 25, 26, 57.75, 25.75, 30, BOUNCE)
    L.cp(58, 29, 13, 61, 35, 4)
    P(64, 18, 29, 2, 3, 1.25)
    P(66, 28, 29, 3, 2, 1)

    # ---------- finale: crane ----------
    box(76, 0, 22, 78, 34.5, 24, ACCENT)             # mast
    box(75.75, 29, 22.5, 76, 34.5, 23.5, CLIMB)      # mast ladder
    box(52, 34, 22.75, 76, 34.5, 23.25, BEAM)        # jib (walk it)
    box(78, 33, 22, 82, 35, 24, PROP)                # counterweight
    box(70, 31.25, 25, 72, 31.5, 27, WOOD)           # hook pallet
    box(70.875, 31.5, 26.75, 71.125, 34, 27, TRIM)
    L.hint(66, 29, 18, 75.75, 30, 6)
    box(56, 31, 21.75, 60, 34, 24.25, PROP)        # cab under the jib
    L.goal(60, 34.5, 22, 64, 24)

    # ---------- scenery ----------
    box(-20, 0, 40, -8, 12, 52, A)                   # distant frames
    box(-20, 12, 40, -8, 12.5, 52, A)
    box(-20, 16, 40, -8, 16.5, 52, A)
    box(20, 0, 50, 34, 3, 60, PROP)                  # material heaps
    box(-14, 0, 0, -8, 2, 6, WOOD)
    box(30, 0, 0, 36, 2.5, 3, PROP)                  # excavator
    box(31, 2.5, 0, 34, 4, 3, BEAM)
    box(90, 0, 0, 92, 40, 2, ACCENT)                 # far crane
    box(70, 40, .75, 98, 40.5, 1.25, BEAM)
    box(-30, 0, 70, -10, 30, 90, A)
    box(60, 0, 50, 80, 24, 70, A)
    return L
