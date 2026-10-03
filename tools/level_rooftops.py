"""LEVEL 1 - ROOFTOPS

World units are metres, y is up. The run starts on R1 heading north (+z)
and ends on the helipad of R8. Falling to the street (y<1) respawns at the
last checkpoint.

Route overview (safe / skilled / expert):

  R1 start     tutorial roof: run, vault AC units + low wall, slide pipe
  R1 -> R2     3m gap with a 2m drop: teaches the roll
  R2 -> R3     4m wall:  ladder / crate+hut mantles / jump + wall run-up
  R3 -> R4     6m gap:   drop to stepping roof S1 / balance pipe /
                         wallrun along the billboard
  R4 -> R6     R6 is 3m above R4, 9m above R5:
                 safe:   fire escape down to R5, climb the yellow drainpipe
                 skill:  awning bounce on R5 -> balcony -> roof
                 expert: sprint off R4's north edge across a 6m gap,
                         run up R6's wall and grab the ledge
  R6 -> R8     speed section: vault/slide line, gaps, beam bridge
  R8 -> R9     13m boulevard: skybridge detour / balance cable /
               wallrun -> wall jump -> wallrun between two billboards
  R9 -> T      5m tower: stairs+platform+ladder / chimney grab /
               vault -> mantle -> mantle chain; goal on the helipad

Materials: 1 concrete bldg, 2 brick bldg, 3 metal unit, 4 steel beam,
5 pipe/trim, 6 yellow climbable, 7 billboard, 8 awning (bouncy), 9 wood,
10 glass, 11 checkpoint (arg=index), 12 goal, 13 hint (arg=text index),
14 dark bldg.
"""

CONCRETE, BRICK, METAL, BEAM, PIPE, CLIMB, BOARD, AWNING, WOOD, GLASS, \
    CP, GOAL, HINT, DARK = range(1, 15)


def build():
    B = []

    def box(x0, y0, z0, x1, y1, z1, m, k=0):
        B.append((x0, y0, z0, x1, y1, z1, m, k))

    def bldg(x0, z0, x1, z1, h, m=CONCRETE):
        box(x0, 0, z0, x1, h, z1, m)

    def ac(x, z, y, w=1.5, d=1, h=1):
        box(x, y, z, x + w, y + h, z + d, METAL)

    def tank(x, z, y):
        # water tank on stilts: you can run underneath
        for dx in (0, 2.75):
            for dz in (0, 2.75):
                box(x + dx, y, z + dz, x + dx + .25, y + 2, z + dz + .25, WOOD)
        box(x - .25, y + 2, z - .25, x + 3.25, y + 4.5, z + 3.25, WOOD)

    def hint(x0, y, z0, x1, z1, k):
        box(x0, y, z0, x1, y + 3, z1, HINT, k)

    # ---------------- R1: start / tutorial ----------------
    bldg(0, 0, 20, 34, 14)
    box(9, 14, 1, 11, 16, 3, CP, 0)               # spawn
    hint(1, 14, .5, 19, 6, 0)                     # controls
    hint(1, 14, 6, 19, 12, 1)                     # vault
    for x in (3, 8.5, 14):
        ac(x, 9, 14)
    box(0, 14, 16, 20, 14.75, 16.5, PIPE)        # low wall: vault it
    hint(1, 14, 18, 19, 22, 2)                    # slide
    box(0, 15, 22.5, 20, 15.25, 22.75, PIPE)      # pipe: slide under/vault
    box(4, 14, 22.5, 4.25, 15, 22.75, PIPE)
    box(15.75, 14, 22.5, 16, 15, 22.75, PIPE)
    tank(15, 26, 14)
    ac(2, 26, 14, 1, 1, .5)
    hint(1, 14, 28, 13, 34, 3)                    # roll

    # ---------------- R2 ----------------
    bldg(2, 37, 22, 63, 12, BRICK)
    box(2, 12, 39, 22, 15, 41, CP, 1)
    hint(2, 12, 42, 22, 52, 10)                   # flow
    box(5, 12, 45, 9, 12.5, 49, GLASS)
    box(14, 12, 45, 18, 12.5, 49, GLASS)
    hint(2, 12, 52, 22, 55, 11)                   # three ways up
    # safe: ladder
    box(6.25, 12, 62.75, 7.75, 16, 63, CLIMB)
    hint(4, 12, 55, 9.5, 62.75, 5)
    # skilled: crate -> hut -> roof
    ac(15, 55, 12, 2, 1.5, 1)
    box(14, 12, 59, 18, 14.5, 63, CONCRETE)
    hint(13.5, 12, 52, 20, 59, 4)
    hint(14, 14.5, 59, 18, 63, 7)
    # expert: run up the wall
    hint(9.5, 12, 55, 13.5, 62.75, 6)

    # ---------------- R3 (dark tower top) ----------------
    bldg(4, 63, 24, 92, 16, DARK)
    box(4, 16, 64, 24, 19, 66, CP, 2)
    ac(8, 70, 16)
    ac(12, 74, 16, 2, 1, 1.25)
    box(6, 16, 78, 10, 19, 84, CONCRETE)          # stair housing
    box(18, 16, 72, 18.25, 22, 72.25, PIPE)       # antenna
    # R3 -> R4 routes
    bldg(25, 68, 29, 80, 13, BRICK)               # safe: stepping roof S1
    box(24, 15.75, 84, 30, 16, 84.25, PIPE)       # skilled: balance pipe
    hint(19, 16, 82, 24, 87, 8)
    box(22, 16.5, 89.75, 32, 20, 90, BOARD, 0)    # expert: wallrun board
    box(26, 8, 90, 26.25, 16.5, 90.25, PIPE)
    box(29, 8, 90, 29.25, 16.5, 90.25, PIPE)
    hint(16, 16, 87, 22, 92, 6)

    # ---------------- R4 ----------------
    bldg(30, 64, 48, 94, 15)
    box(30.5, 15, 64, 33, 18, 94, CP, 3)
    box(37, 15, 70, 41, 15.5, 76, GLASS)
    ac(38, 82, 15)
    ac(42, 82, 15)
    box(43, 15, 66, 47, 18, 70, DARK)             # roof housing
    box(36, 18, 66.5, 42, 21, 66.75, BOARD, 1)    # roof sign
    hint(44, 15, 72, 48, 86, 3)
    # fire escape down the east face (safe route to R5)
    box(48, 12.5, 88, 50.5, 12.75, 91, BEAM)
    box(48, 10.5, 83, 50.5, 10.75, 86, BEAM)

    # ---------------- R5 (low) + R6 south face ----------------
    bldg(52, 72, 70, 100, 9, BRICK)
    ac(60, 80, 9, 2, 1.5, 1)
    ac(64, 86, 9)
    box(52.5, 9, 99.75, 53, 18, 100, CLIMB)       # safe: drainpipe
    hint(52, 9, 95, 54.5, 99.75, 5)
    box(56, 10, 98, 60, 10.25, 100, AWNING)       # skilled: bounce
    box(60.5, 14.75, 98.5, 64.5, 15, 100, BEAM)   # balcony
    hint(54.5, 9, 92, 62, 98, 9)

    # ---------------- R6 ----------------
    bldg(46, 100, 66, 130, 18)
    box(46, 18, 101, 66, 21, 103, CP, 4)
    for x in (48, 52, 56, 60):
        ac(x, 108, 18)
    box(46, 19, 114, 66, 19.25, 114.25, PIPE)     # slide pipe
    box(50, 18, 114, 50.25, 19, 114.25, PIPE)
    box(61.75, 18, 114, 62, 19, 114.25, PIPE)
    box(50, 18, 119, 54, 18.5, 123, GLASS)
    box(58, 18, 119, 62, 18.5, 123, GLASS)
    tank(47, 124, 18)
    box(58, 18, 126, 66, 23, 126.25, BOARD, 2)    # billboard on R6 edge

    # ---------------- R7 / R8 ----------------
    bldg(48, 133, 64, 150, 17, BRICK)
    ac(51, 138, 17, 2, 2, 1.25)
    ac(58, 141, 17)
    box(52, 16.75, 150, 52.25, 17, 154, BEAM)     # beam bridge
    bldg(44, 154, 60, 172, 15)
    box(44, 15, 156, 60, 18, 158, CP, 5)
    ac(46, 162, 15)
    box(54, 15, 163, 56, 15.5, 167, GLASS)
    hint(44, 15, 166, 52, 172, 12)                # wallrun chain

    # ------ boulevard crossing R8 -> R9 (14m wide) ------
    # safe: covered skybridge on the east side (detour)
    box(58, 13, 172, 61, 15, 185, CONCRETE)
    box(58, 15, 172, 58.25, 16.5, 185, PIPE)
    box(60.75, 15, 172, 61, 16.5, 185, PIPE)
    ac(59, 178, 15, 1.5, 1, .75)
    # skilled: balance cable
    box(50, 14.75, 172, 50.25, 15, 185, PIPE)
    # expert: wallrun -> wall jump -> wallrun between boards
    box(47.75, 15.5, 171, 48, 19.5, 178, BOARD, 1)
    box(47.75, 8, 175, 48, 15.5, 175.25, PIPE)
    box(51.75, 16, 177, 52, 20, 186, BOARD, 2)
    box(51.75, 8, 181, 52, 16, 181.25, PIPE)

    # ---------------- R9 + tower T (goal) ----------------
    bldg(42, 185, 62, 204, 16, BRICK)
    box(42, 16, 188, 62, 19, 190, CP, 6)
    ac(45, 193, 16)
    hint(42, 16, 192, 62, 199, 13)                # last climb
    bldg(44, 204, 60, 216, 21, DARK)
    # safe: stairs -> platform -> ladder -> roof
    for k in range(1, 4):
        box(47 + k, 16, 201, 48 + k, 18 - k * .5, 204, CONCRETE)
    box(44, 16, 201, 48, 18, 204, CONCRETE)
    box(45.25, 18, 203.75, 46.75, 21, 204, CLIMB)
    # skilled: grab the chimney, hop to the roof
    box(55, 16, 200, 57, 19, 202.5, CONCRETE)
    # expert: vault the unit, mantle chimney, mantle roof
    ac(55, 196, 16, 2, 1.5, 1.25)
    box(48, 21, 208, 56, 21.25, 214, PIPE)        # helipad
    box(48, 21.25, 208, 56, 24, 214, GOAL)
    box(56, 21, 214, 56.25, 27, 214.25, PIPE)     # mast

    # ---------------- skyline (scenery) ----------------
    bldg(-14, 0, -4, 30, 22, DARK)
    bldg(-12, 36, -2, 70, 10, BRICK)
    bldg(-10, 74, 0, 110, 26)
    bldg(26, 0, 40, 30, 18, BRICK)
    bldg(28, 34, 42, 58, 8)
    bldg(0, 96, 24, 120, 12, BRICK)
    bldg(26, 100, 42, 126, 24, DARK)
    bldg(74, 70, 90, 110, 20, DARK)
    bldg(70, 114, 84, 140, 14, BRICK)
    bldg(24, 140, 42, 170, 20)
    bldg(66, 150, 80, 175, 24, DARK)
    bldg(24, 176, 40, 200, 26, DARK)
    bldg(66, 180, 80, 210, 20)
    bldg(40, 222, 64, 236, 34, BRICK)
    bldg(26, 204, 40, 230, 16)
    box(30, 18, 10, 36, 22, 10.25, BOARD, 3)      # sign on E1
    return B
