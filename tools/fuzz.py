#!/usr/bin/env python3
"""Random-input robustness test: mashes buttons from every checkpoint of
every level and checks for Lua errors, NaN positions, states that never
end, and the runner ending up embedded in geometry.

    python3 tools/fuzz.py [seconds-per-run] [runs-per-level] [levels]
"""
import math, os, random, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")
TRANSIENT = {"vault": 1, "pull": 1, "roll": 1, "land": 1.5, "wallrun": 3, "wallup": 3}
BTNS = ["up", "down", "left", "right", "z", "x"]


def starts(lv):
    """checkpoint centres of a level"""
    pc = Pico(CART)
    pc.L.execute("setlv(%d)" % lv)
    return [tuple(c.values()) for c in pc.L.eval(
        "(function() local t={} for b in all(trig) do if b.m==11 then add(t,{(b[1]+b[4])/2,b[2],(b[3]+b[6])/2}) end end return t end)()").values()]


def fuzz(seconds=20, runs=9, levels=range(8), seed=int(os.environ.get("SEED", 1))):
    rnd = random.Random(seed)
    problems = 0
    for lv in levels:
        sp = starts(lv)
        problems += fuzz_level(lv, sp, seconds, runs, rnd, seed)
    print("problems:", problems)
    return problems


def fuzz_level(lv, sp, seconds, runs, rnd, seed):
    problems = 0
    for k in range(runs):
        x, y, z = sp[k % len(sp)]
        pc = Pico(CART, seed=seed + k)
        pc.L.execute("setlv(%d)" % lv)
        pc.g.mode = "play"
        pc.teleport(x, y, z, rnd.random())
        held, st_since, last_st = set(["up"]), 0, None
        for f in range(int(seconds * 60)):
            if rnd.random() < .08:          # change the held buttons
                held = {b for b in BTNS if rnd.random() < (.7 if b == "up" else .2)}
            try:
                pc.step(held, draw=(f % 97 == 0))
            except Exception as e:  # lua error
                print("L%d run %d frame %d: LUA ERROR %s" % (lv + 1, k, f, e))
                problems += 1
                break
            g = pc.g
            if any(math.isnan(v) or abs(v) > 1000 for v in (g.px, g.py, g.pz, g.vx, g.vy, g.vz)):
                print("L%d run %d frame %d: bad numbers %s" % (lv + 1, k, f, pc.state()))
                problems += 1
                break
            if g.st != last_st:
                last_st, st_since = g.st, f
            elif g.st in TRANSIENT and (f - st_since) / 60 > TRANSIENT[g.st]:
                print("L%d run %d frame %d: stuck in %s %s" % (lv + 1, k, f, g.st, pc.state()))
                problems += 1
                break
            # embedded deeper than 1cm (touching faces can overlap by a
            # float rounding error here; PICO-8 uses 16.16 fixed point)
            deep = "hit(px-r+.01,py+.01,pz-r+.01,px+r-.01,py+ph-.01,pz+r-.01)"
            if g.st in ("ground", "air", "slide", "roll") and pc.L.eval(deep):
                b = pc.L.eval(deep)
                print("L%d run %d frame %d: inside box %s %s" % (lv + 1, k, f, [b[i] for i in range(1, 7)], pc.state()))
                problems += 1
                break
        else:
            print("L%d run %d ok (%s)" % (lv + 1, k, pc.state()["st"]))
    return problems


if __name__ == "__main__":
    a = sys.argv[1:]
    lvs = [int(c) - 1 for c in a[2].split(",")] if len(a) > 2 else range(8)
    sys.exit(1 if fuzz(float(a[0]) if a else 20, int(a[1]) if len(a) > 1 else 6, lvs) else 0)
