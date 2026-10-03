"""Shared level-building helpers.

Units are metres, y is up. Every object is an axis-aligned box
(x0, y0, z0, x1, y1, z1, material, arg). Material ids are fixed across
levels (their colours and surface detail are per level):

  1 A  main structure      2 B  secondary structure   3 PROP small props
  4 BEAM steel/iron         5 TRIM pipes, rails, slabs 6 CLIMB yellow climbable
  7 SIGN boards/signs       8 BOUNCE awnings/nets      9 WOOD timber
 10 GLASS                  11 CP checkpoint (arg=n)   12 GOAL
 13 HINT (arg=text)        14 DARK structure          15 ACCENT
"""

A, B, PROP, BEAM, TRIM, CLIMB, SIGN, BOUNCE, WOOD, GLASS, CP, GOAL, HINT, DARK, ACCENT = range(1, 16)


class Level:
    def __init__(self):
        self.boxes = []

    def box(self, x0, y0, z0, x1, y1, z1, m, k=0):
        self.boxes.append((x0, y0, z0, x1, y1, z1, m, k))

    def bldg(self, x0, z0, x1, z1, h, m=A, y0=0):
        self.box(x0, y0, z0, x1, y0 + h, z1, m)

    def tall(self, x0, z0, x1, z1, h, m=A, y0=0):
        """building taller than 63.75m: stacked boxes"""
        while h > 0:
            s = min(h, 60)
            self.box(x0, y0, z0, x1, y0 + s, z1, m)
            y0, h = y0 + s, h - s

    def prop(self, x, z, y, w=1.5, d=1, h=1, m=PROP):
        self.box(x, y, z, x + w, y + h, z + d, m)

    def tank(self, x, z, y, m=WOOD):
        for dx in (0, 2.75):
            for dz in (0, 2.75):
                self.box(x + dx, y, z + dz, x + dx + .25, y + 2, z + dz + .25, m)
        self.box(x - .25, y + 2, z - .25, x + 3.25, y + 4.5, z + 3.25, m)

    def cp(self, x0, y, z0, x1, z1, k):
        self.box(x0, y, z0, x1, y + 3, z1, CP, k)

    def hint(self, x0, y, z0, x1, z1, k):
        self.box(x0, y, z0, x1, y + 3, z1, HINT, k)

    def goal(self, x0, y, z0, x1, z1):
        self.box(x0, y, z0, x1, y + 3, z1, GOAL)
