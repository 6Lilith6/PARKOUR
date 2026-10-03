#!/usr/bin/env python3
"""Random-input robustness test: mashes buttons from many start points and
checks for Lua errors, NaN positions, states that never end, and the
runner ending up embedded in geometry.

    python3 tools/fuzz.py [seconds-per-run] [runs]
"""
import math, os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")
STARTS = [(10, 14, 2), (12, 12, 50), (14, 16, 80), (40, 15, 80), (60, 9, 90),
          (56, 18, 110), (60, 17, 135), (50, 15, 165), (52, 16, 195)]
TRANSIENT = {"vault": 1, "pull": 1, "roll": 1, "land": 1.5, "wallrun": 3, "wallup": 3}
BTNS = ["up", "down", "left", "right", "z", "x"]


def fuzz(seconds=20, runs=9, seed=1):
    rnd = random.Random(seed)
    problems = 0
    for k in range(runs):
        x, y, z = STARTS[k % len(STARTS)]
        pc = Pico(CART, seed=seed + k)
        pc.g.mode = "play"
        pc.teleport(x, y, z, rnd.random())
        held, st_since, last_st = set(["up"]), 0, None
        for f in range(int(seconds * 60)):
            if rnd.random() < .08:          # change the held buttons
                held = {b for b in BTNS if rnd.random() < (.7 if b == "up" else .2)}
            try:
                pc.step(held, draw=(f % 97 == 0))
            except Exception as e:  # lua error
                print("run %d frame %d: LUA ERROR %s" % (k, f, e))
                problems += 1
                break
            g = pc.g
            if any(math.isnan(v) or abs(v) > 1000 for v in (g.px, g.py, g.pz, g.vx, g.vy, g.vz)):
                print("run %d frame %d: bad numbers %s" % (k, f, pc.state()))
                problems += 1
                break
            if g.st != last_st:
                last_st, st_since = g.st, f
            elif g.st in TRANSIENT and (f - st_since) / 60 > TRANSIENT[g.st]:
                print("run %d frame %d: stuck in %s %s" % (k, f, g.st, pc.state()))
                problems += 1
                break
            if g.st in ("ground", "air", "slide", "roll") and pc.L.eval("phit()"):
                b = pc.L.eval("phit()")
                print("run %d frame %d: inside box %s %s" % (k, f, [b[i] for i in range(1, 7)], pc.state()))
                problems += 1
                break
        else:
            print("run %d ok (%s)" % (k, pc.state()["st"]))
    print("problems:", problems)
    return problems


if __name__ == "__main__":
    a = sys.argv[1:]
    sys.exit(1 if fuzz(float(a[0]) if a else 20, int(a[1]) if len(a) > 1 else 9) else 0)
