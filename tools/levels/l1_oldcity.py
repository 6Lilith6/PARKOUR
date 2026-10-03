"""LEVEL 1 - OLD CITY ROOFTOPS

Dense old brick district at dusk. Style: FLOW - short quick combos of
vaults, small gaps, ledge grabs and short wallruns across neighbouring
roofs. Introductory, but every major section already has a safe, a
skilled and an expert line.

  R1 start     tutorial roof: vault AC units + low wall, slide under pipe
  R1 -> R2     3m alley with a 2m drop: teaches the roll
  R2 -> R3     4m wall: ladder / crate+hut mantles / jump + wall run-up
  R3 -> R4     6m gap: drop to stepping roof S1 / balance pipe /
               wallrun along the billboard
  R4 -> R6     R6 is 3m above R4, 9m above R5: fire escape down to R5
               + drainpipe / awning bounce -> balcony / flow long jump +
               wall run-up
  R6 -> R8     speed section: vault/slide line, gaps, beam bridge
  R8 -> R9     13m street: skybridge / balance cable / wallrun -> wall
               jump -> wallrun between two billboards
  R9 -> tower  stairs+ladder / chimney grab / vault-mantle chain
"""
from .common import *

NAME = "old city rooftops"
# display palette: warm dusk (0,1,2,5,7,8,12?,15 kept for the runner)
PALETTE = {12: 140, 9: 143, 13: 141, 4: 132, 6: 134, 14: 142, 10: 135, 3: 131, 11: 139}
# sky: top, haze, silhouette a, b, ground, sun, fog, fog dist,
# hint base, spawn heading (0..255 = turns), silhouette height
SKY = (12, 9, 13, 4, 5, 10, 13, 26, 0, 192, 8)
MATS = {
    A: (6, 4, 2, 0x11),      # brick block, tan roof, dark windows
    B: (13, 14, 4, 0x01),    # salmon brick, mauve roof
    PROP: (6, 13, 5, 0x55),  # ac units / vents
    BEAM: (5, 0, 0, 0),      # iron fire escapes
    TRIM: (6, 13, 5, 0),     # pipes, parapets, cables
    CLIMB: (10, 9, 9, 0x02), # ladders, drainpipes
    SIGN: (5, 14, 2, 0x03),  # painted signs
    BOUNCE: (8, 2, 2, 0x74), # striped awnings
    WOOD: (4, 4, 2, 0),
    GLASS: (12, 1, 1, 0),
    DARK: (13, 5, 1, 0xa1),  # lit windows
    ACCENT: (0, 4, 2, 0x48), # sooty chimneys
}


def build():
    L = Level()
    # ---------------- R1: start / tutorial ----------------
    L.bldg(0, 0, 20, 34, 14)
    L.box(9, 14, 1, 11, 16, 3, CP, 0)               # spawn
    L.hint(1, 14, .5, 19, 6, 0)                     # controls
    L.hint(1, 14, 6, 19, 12, 1)                     # vault
    for x in (3, 8.5, 14):
        L.prop(x, 9, 14)
    L.box(0, 14, 16, 20, 14.75, 16.5, TRIM)        # low wall: vault it
    L.hint(1, 14, 18, 19, 22, 2)                    # slide
    L.box(0, 15, 22.5, 20, 15.25, 22.75, TRIM)      # pipe: slide under/vault
    L.box(4, 14, 22.5, 4.25, 15, 22.75, TRIM)
    L.box(15.75, 14, 22.5, 16, 15, 22.75, TRIM)
    L.tank(15, 26, 14)
    L.prop(2, 26, 14, 1, 1, .5)
    L.hint(1, 14, 28, 13, 34, 3)                    # roll

    # ---------------- R2 ----------------
    L.bldg(2, 37, 22, 63, 12, B)
    L.box(2, 12, 39, 22, 15, 41, CP, 1)
    L.hint(2, 12, 42, 22, 52, 10)                   # flow
    L.box(5, 12, 45, 9, 12.5, 49, GLASS)
    L.box(14, 12, 45, 18, 12.5, 49, GLASS)
    L.hint(2, 12, 52, 22, 55, 11)                   # three ways up
    # safe: ladder
    L.box(6.25, 12, 62.75, 7.75, 16, 63, CLIMB)
    L.hint(4, 12, 55, 9.5, 62.75, 5)
    # skilled: crate -> hut -> roof
    L.prop(15, 55, 12, 2, 1.5, 1)
    L.box(14, 12, 59, 18, 14.5, 63, A)
    L.hint(13.5, 12, 52, 20, 59, 4)
    L.hint(14, 14.5, 59, 18, 63, 7)
    # expert: run up the wall
    L.hint(9.5, 12, 55, 13.5, 62.75, 6)

    # ---------------- R3 (dark tower top) ----------------
    L.bldg(4, 63, 24, 92, 16, DARK)
    L.box(4, 16, 64, 24, 19, 66, CP, 2)
    L.prop(8, 70, 16)
    L.prop(12, 74, 16, 2, 1, 1.25)
    L.box(6, 16, 78, 10, 19, 84, A)          # stair housing
    L.box(18, 16, 72, 18.25, 22, 72.25, TRIM)       # antenna
    # R3 -> R4 routes
    L.bldg(25, 68, 29, 80, 13, B)               # safe: stepping roof S1
    L.box(24, 15.75, 84, 30, 16, 84.25, TRIM)       # skilled: balance pipe
    L.hint(19, 16, 82, 24, 87, 8)
    L.box(22, 16.5, 89.75, 32, 20, 90, SIGN, 0)    # expert: wallrun board
    L.box(26, 8, 90, 26.25, 16.5, 90.25, TRIM)
    L.box(29, 8, 90, 29.25, 16.5, 90.25, TRIM)
    L.hint(16, 16, 87, 22, 92, 6)

    # ---------------- R4 ----------------
    L.bldg(30, 64, 48, 94, 15)
    L.box(30.5, 15, 64, 33, 18, 94, CP, 3)
    L.box(37, 15, 70, 41, 15.5, 76, GLASS)
    L.prop(38, 82, 15)
    L.prop(42, 82, 15)
    L.box(43, 15, 66, 47, 18, 70, DARK)             # roof housing
    L.box(36, 18, 66.5, 42, 21, 66.75, SIGN, 1)    # roof sign
    L.hint(44, 15, 72, 48, 86, 3)
    # fire escape down the east face (safe route to R5)
    L.box(48, 12.5, 88, 50.5, 12.75, 91, BEAM)
    L.box(48, 10.5, 83, 50.5, 10.75, 86, BEAM)

    # ---------------- R5 (low) + R6 south face ----------------
    L.bldg(52, 72, 70, 100, 9, B)
    L.prop(60, 80, 9, 2, 1.5, 1)
    L.prop(64, 86, 9)
    L.box(52.5, 9, 99.75, 53, 18, 100, CLIMB)       # safe: drainpipe
    L.hint(52, 9, 95, 54.5, 99.75, 5)
    L.box(56, 10, 98, 60, 10.25, 100, BOUNCE)       # skilled: bounce
    L.box(60.5, 14.75, 98.5, 64.5, 15, 100, BEAM)   # balcony
    L.hint(54.5, 9, 92, 62, 98, 9)

    # ---------------- R6 ----------------
    L.bldg(46, 100, 66, 130, 18)
    L.box(46, 18, 101, 66, 21, 103, CP, 4)
    for x in (48, 52, 56, 60):
        L.prop(x, 108, 18)
    L.box(46, 19, 114, 66, 19.25, 114.25, TRIM)     # slide pipe
    L.box(50, 18, 114, 50.25, 19, 114.25, TRIM)
    L.box(61.75, 18, 114, 62, 19, 114.25, TRIM)
    L.box(50, 18, 119, 54, 18.5, 123, GLASS)
    L.box(58, 18, 119, 62, 18.5, 123, GLASS)
    L.tank(47, 124, 18)
    L.box(58, 18, 126, 66, 23, 126.25, SIGN, 2)    # billboard on R6 edge

    # ---------------- R7 / R8 ----------------
    L.bldg(48, 133, 64, 150, 17, B)
    L.prop(51, 138, 17, 2, 2, 1.25)
    L.prop(58, 141, 17)
    L.box(52, 16.75, 150, 52.25, 17, 154, BEAM)     # beam bridge
    L.bldg(44, 154, 60, 172, 15)
    L.box(44, 15, 156, 60, 18, 158, CP, 5)
    L.prop(46, 162, 15)
    L.box(54, 15, 163, 56, 15.5, 167, GLASS)
    L.hint(44, 15, 166, 52, 172, 12)                # wallrun chain

    # ------ boulevard crossing R8 -> R9 (14m wide) ------
    # safe: covered skybridge on the east side (detour)
    L.box(58, 13, 172, 61, 15, 185, A)
    L.box(58, 15, 172, 58.25, 16.5, 185, TRIM)
    L.box(60.75, 15, 172, 61, 16.5, 185, TRIM)
    L.prop(59, 178, 15, 1.5, 1, .75)
    # skilled: balance cable
    L.box(50, 14.75, 172, 50.25, 15, 185, TRIM)
    # expert: wallrun -> wall jump -> wallrun between boards
    L.box(47.75, 15.5, 171, 48, 19.5, 178, SIGN, 1)
    L.box(47.75, 8, 175, 48, 15.5, 175.25, TRIM)
    L.box(51.75, 16, 177, 52, 20, 186, SIGN, 2)
    L.box(51.75, 8, 181, 52, 16, 181.25, TRIM)

    # ---------------- R9 + tower T (goal) ----------------
    L.bldg(42, 185, 62, 204, 16, B)
    L.box(42, 16, 188, 62, 19, 190, CP, 6)
    L.prop(45, 193, 16)
    L.hint(42, 16, 192, 62, 199, 13)                # last climb
    L.bldg(44, 204, 60, 216, 21, DARK)
    # safe: stairs -> platform -> ladder -> roof
    for k in range(1, 4):
        L.box(47 + k, 16, 201, 48 + k, 18 - k * .5, 204, A)
    L.box(44, 16, 201, 48, 18, 204, A)
    L.box(45.25, 18, 203.75, 46.75, 21, 204, CLIMB)
    # skilled: grab the chimney, hop to the roof
    L.box(55, 16, 200, 57, 19, 202.5, A)
    # expert: vault the unit, mantle chimney, mantle roof
    L.prop(55, 196, 16, 2, 1.5, 1.25)
    L.box(48, 21, 208, 56, 21.25, 214, TRIM)        # helipad
    L.box(48, 21.25, 208, 56, 24, 214, GOAL)
    L.box(56, 21, 214, 56.25, 27, 214.25, TRIM)     # mast

    # ---------------- old-city details (off the routes) ----------------
    for x, z, y in ((18.5, 31.5, 14), (2.5, 60.5, 12), (31, 91, 15), (64.5, 128, 18), (61.5, 147, 17)):
        L.box(x, y, z, x + 1, y + 2.5, z + 1, ACCENT)  # chimney stacks
    for x0, x1, y, z in ((-2, 2, 15.5, 44), (66, 74, 21.5, 112)):
        L.box(x0, y, z, x1, y + .25, z + .25, TRIM)    # clotheslines
        for xa, c in ((x0 + .5, 1), (x1 - 1.75, 2)):
            L.box(xa, y - .75, z, xa + 1.25, y, z + .25, SIGN, c)  # laundry

    # ---------------- skyline (scenery) ----------------
    L.bldg(-14, 0, -4, 30, 22, DARK)
    L.bldg(-12, 36, -2, 70, 10, B)
    L.bldg(-10, 74, 0, 110, 26)
    L.bldg(26, 0, 40, 30, 18, B)
    L.bldg(28, 34, 42, 58, 8)
    L.bldg(0, 96, 24, 120, 12, B)
    L.bldg(26, 100, 42, 126, 24, DARK)
    L.bldg(74, 70, 90, 110, 20, DARK)
    L.bldg(70, 114, 84, 140, 14, B)
    L.bldg(24, 140, 42, 170, 20)
    L.bldg(66, 150, 80, 175, 24, DARK)
    L.bldg(24, 176, 40, 200, 26, DARK)
    L.bldg(66, 180, 80, 210, 20)
    L.bldg(40, 222, 64, 236, 34, B)
    L.bldg(26, 204, 40, 230, 16)
    L.box(30, 18, 10, 36, 22, 10.25, SIGN, 3)      # sign on E1
    return L
