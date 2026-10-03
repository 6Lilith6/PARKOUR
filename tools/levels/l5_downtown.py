"""LEVEL 5 - DOWNTOWN

Glass offices, a shopping street, rooftop gardens, a parking garage and a
setback tower. Style: URBAN VERTICAL FLOW - street furniture and vehicles
are the first steps up:
  street -> car roof -> van -> awning -> balcony -> fire escape -> roof
  -> cable / skybridge -> next building -> garage -> tower

  street   safe: fire escape ladders right at the start | normal: taxi,
           van, awning bounce, balcony, ladder or run up to the podium
           roof | west: parked car, low awning, shop roofs
  cross    skybridge roof | cable from the shop roofs (balance) | the
           canopy in front of the next office
  office   rooftop playground: AC units, skylight, planters, penthouse,
           water tank, billboard
  garage   top deck: weave between the cars or hop the car roofs
  tower    three 4m setbacks: ladder | AC units / window-washer gondola |
           wall run-up; goal on the crown
"""
from .common import *

NAME = "downtown"
PALETTE = {14: 140, 9: 137, 3: 139}
SKY = (12, 6, 13, 1, 5, 7, 6, 28, 32, 192, 22)
MATS = {
    A: (6, 13, 13, 0x11),     # stone offices, sidewalks
    B: (5, 4, 2, 0x11),       # brick shops
    PROP: (6, 13, 5, 0x55),   # AC units, van
    BEAM: (5, 0, 0, 0),       # fire escapes, balconies
    TRIM: (6, 5, 5, 0),       # rails, cables, canopies
    CLIMB: (10, 9, 9, 0x02),
    SIGN: (5, 7, 6, 0x03),    # billboards, bus
    BOUNCE: (8, 8, 2, 0x78),  # striped awnings
    WOOD: (3, 4, 4, 0),       # planters
    GLASS: (13, 12, 14, 0x11),  # glass offices
    DARK: (5, 5, 0, 0),       # asphalt, garage
    ACCENT: (14, 14, 1, 0x05),  # cars
}


def build():
    L = Level()
    box, P = L.box, L.prop
    # ---------- street (z -10..44) ----------
    box(-14, 0, -10, 40, 2, 46, DARK)
    box(-14, 0, 46, 40, 2, 100, DARK)
    box(-14, 0, 100, 40, 2, 140, DARK)
    box(0, 2, -6, 3, 2.25, 44, A)                     # sidewalks
    box(13, 2, -6, 16, 2.25, 44, A)
    box(-12, 2, -10, 30, 14, -6, B)                   # street end
    box(-12, 2, -6, 0, 6.5, 18, B)                    # shops W1
    box(-12, 2, 18, 0, 10.5, 44, B)                   # shops W2
    box(16, 2, -6, 30, 11, 44, A)                     # office podium
    box(22, 11, -6, 30, 30, 20, GLASS)                # office tower
    L.cp(6, 2, 0, 9, 3, 0)
    L.hint(3, 2, -6, 13, 5, 0)
    # safe: fire escape
    box(13.75, 6.25, 2, 16, 6.5, 8, BEAM)
    box(14, 2.25, 1.75, 15.5, 6.5, 2, CLIMB)
    box(15.75, 6.5, 6, 16, 11, 7.5, CLIMB)
    # normal: taxi -> van -> awning -> balcony -> ladder
    box(9.5, 2, 6, 11.5, 3.5, 10, ACCENT)             # taxi
    box(10.5, 2, 11, 13, 4.25, 17.5, PROP)            # van
    box(12, 4.75, 19, 16, 5, 23, BOUNCE)               # awning
    box(13.5, 7.25, 25, 16, 7.5, 33, BEAM)            # balcony
    box(13.5, 10.75, 33, 16, 11, 39, BEAM)            # fire escape top
    box(14, 7.5, 32.75, 15.5, 11, 33, CLIMB)
    box(9.5, 2, 26, 12.5, 5.5, 41, SIGN, 1)           # bus
    L.hint(6, 2, 5, 13, 11, 1)
    # west: parked car -> low awning -> shop roofs
    box(3, 2, 3, 5, 3.5, 7, ACCENT)
    box(0, 4, 8, 2.5, 4.25, 12, BOUNCE)
    P(-5, 4, 6.5, 2, 1.5, 1.25)                       # AC units
    P(-9, 11, 6.5, 1.5, 2, 1.25)
    box(-3, 6.5, 16, -1, 8.25, 18, PROP)              # step to W2
    box(-8, 10.5, 30, -6, 12, 32, PROP)
    box(-7, 11.75, 36, -1, 15.75, 36.25, SIGN, 2)           # billboard: slide
    for x in (-7, -1.25):
        box(x, 10.5, 36, x + .25, 11.75, 36.25, BEAM)
    # podium roof garden
    box(17, 11, 10, 19, 11.75, 16, WOOD)
    P(18, 20, 11, 2, 1.5, 1.25)
    box(16, 12.25, 24, 22, 12.5, 24.5, TRIM)          # pergola: slide
    box(16, 11, 24, 16.25, 12.25, 24.5, TRIM)
    box(21.75, 11, 24, 22, 12.25, 24.5, TRIM)
    box(23, 11, 26, 28, 11.75, 32, GLASS)             # skylight: vault
    box(24, 11, 36, 28, 12.25, 38, PROP)
    L.hint(16, 11, 0, 22, 8, 2)

    # ---------- cross street (z 44..50) ----------
    box(18, 8, 44, 22, 10.75, 49, GLASS)              # skybridge
    box(-2.25, 10.25, 44, -2, 10.5, 49, TRIM)         # cable
    box(-12, 10.75, 49, 30, 11, 52, A)                # canopy
    L.hint(-12, 10.5, 40, 0, 44, 3)
    L.cp(-12, 11, 49, 30, 52, 1)
    # canopy -> office roof (14)
    box(19, 11, 51.75, 20.5, 14, 52, CLIMB)
    P(-3, 50.5, 11, 2, 1.5, 1.25)
    box(6, 11, 50.25, 8.5, 11.75, 51.75, WOOD)

    # ---------- office 2 roof playground (z 52..76) ----------
    box(-12, 2, 52, 30, 14, 76, GLASS)
    box(2, 14, 60, 10, 17.5, 68, B)                   # penthouse
    box(4, 14, 59.75, 5.5, 17.5, 60, CLIMB)
    P(10, 61, 14, 2, 2.5, 1.25)
    box(14, 14, 57, 20, 14.75, 63, GLASS)             # skylight
    box(-9, 14, 56, -7, 14.75, 64, WOOD)              # planters
    box(-4, 14, 58, 0, 14.75, 59.5, WOOD)
    P(22, 56, 14, 3, 2, 1.25)
    L.tank(23, 66, 14, A)                              # water tank
    box(-11, 15.25, 70, -3, 19.25, 70.25, SIGN, 3)      # billboard: slide
    for x in (-11, -3.25):
        box(x, 14, 70, x + .25, 15.25, 70.25, BEAM)
    box(-2, 14, 66, 0, 15.5, 70, PROP)
    box(14, 15.25, 68, 20, 15.5, 68.5, TRIM)          # pipe: slide
    L.hint(-12, 14, 52, 30, 56, 4)

    # ---------- parking garage (z 76..112), deck 11 ----------
    box(-8, 2, 76, 24, 10.5, 112, DARK)
    box(-8, 10.5, 76, 24, 11, 112, A)
    for x in (-8, 23.75):
        box(x, 11, 80, x + .25, 12, 112, TRIM)        # parapets
    for z in (82, 90, 98):                            # car rows
        box(-5, 11, z, -3, 12.25, z + 4, ACCENT)
        box(3, 11, z + 2, 5, 12.25, z + 6, PROP)
        box(13, 11, z, 15, 12.25, z + 4, ACCENT)
    box(18, 11, 92, 24, 14, 98, B)                    # stair house
    box(17.75, 11, 93, 18, 14, 94.5, CLIMB)
    box(8, 12.5, 88, 11, 12.75, 88.25, TRIM)          # barrier arm
    for z in (86, 102):
        box(9, 11, z, 9.25, 15, z + .25, TRIM)        # lamp posts
    L.cp(-8, 11, 77, 24, 80, 2)
    L.hint(-8, 11, 80, 24, 86, 5)

    # ---------- setback tower (z 112..134) ----------
    box(-8, 2, 112, 24, 15, 134, GLASS)               # base, top 15
    box(2, 15, 118, 18, 19, 134, GLASS)               # setback, top 19
    box(6, 19, 124, 14, 23, 134, GLASS)               # crown, top 23
    box(9.75, 23, 131, 10.25, 30, 131.5, TRIM)        # antenna
    L.cp(-8, 11, 106, 24, 111.5, 3)
    L.hint(-8, 11, 106, 24, 111.5, 6)
    # 11 -> 15
    box(0, 11, 111.75, 1.5, 15, 112, CLIMB)
    box(8, 13, 110, 11, 13.25, 112, WOOD)             # gondola
    for x in (8, 10.75):
        box(x, 13.25, 111.75, x + .25, 26, 112, TRIM)
    # 15 -> 19
    box(3, 15, 117.75, 4.5, 19, 118, CLIMB)
    P(9, 114, 15, 2.5, 2, 1.25)                       # AC steps
    box(9, 15, 116, 11.5, 17.5, 118, PROP)
    # 19 -> 23
    box(7, 19, 123.75, 8.5, 23, 124, CLIMB)
    box(8.5, 20.75, 121.5, 11.5, 21, 124, WOOD)       # gondola
    for x in (8.5, 11.25):
        box(x, 21, 123.75, x + .25, 26, 124, TRIM)
    L.goal(6, 23, 125, 14, 133)

    # ---------- skyline ----------
    box(40, 0, 0, 52, 60, 12, GLASS)
    box(-40, 0, 60, -28, 50, 72, A)
    box(40, 0, 70, 55, 45, 85, GLASS)
    box(-34, 0, 110, -20, 40, 124, A)
    box(32, 0, 120, 46, 55, 134, GLASS)
    box(-10, 0, 150, 8, 62, 166, GLASS)
    return L
