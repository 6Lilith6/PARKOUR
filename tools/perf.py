#!/usr/bin/env python3
"""Performance report (the full version of the in-cart perf overlay).

For every level it samples the heaviest views (fixed spots, the runner
moving) and prints per drawn frame:

  draw   Lua VM instructions in _draw (sim count, includes the emulated
         built-ins, so real PICO-8 is somewhat cheaper)
  upd    instructions for the two 1/60s physics steps of a 30fps frame
  obj    boxes sorted + drawn in full (far fog silhouettes excluded)
  far    far boxes drawn as one flat rect
  poly   polygons filled          rows  scanlines filled
  col    collision boxes near the runner (broad phase)

    python3 tools/perf.py            # all levels
    python3 tools/perf.py 2 5        # some levels
    python3 tools/perf.py --run      # also level 1's expert route at speed
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")

SPOTS = {
    1: [(21, 16, 84.12, 0), (10, 14, 2, .75), (52, 21, 195, .75)],
    2: [(14, 17, 27, 0), (8, 9, 20, .75), (60, 29, 24, 0)],
    3: [(20, 6, 17, 0), (110, 7, 17, 0), (84, 7, 18.1, 0)],
    4: [(11, 9, 166, .75), (4, 3.25, 3, .75), (9.6, 4.25, 44, .75)],
    5: [(7.5, 2, 1.5, .75), (10, 14, 53, .75), (5, 11, 80, .75)],
    6: [(6, 22, 60, .75), (2, 19, 150, .75), (6, 24, -3, .75)],
    7: [(1, 20, 88, .75), (6, 18, 54, .75), (3, 6, 26, .75)],
    8: [(25, 10, 46, .25), (13.5, 34, -7.5, .75), (8, 18, 2, .75)],
}

COUNTERS = """
__np,__nr,__nf=0,0,0
local _poly,_rf=poly,rectfill
function poly(v,c)
 __np=__np+1
 local y0,y1=999,-1
 for p in all(v) do y0=min(y0,p[2]) y1=max(y1,p[2]) end
 __nr=__nr+max(0,min(y1,127)-max(y0,0))
 return _poly(v,c)
end
"""


def frame_stats(pc):
    pc.L.execute("__np,__nr=0,0")
    pc.step(["up"], draw=True, count=True)
    upd, draw = pc.instr
    g = pc.g
    obj = pc.L.eval("(function() local n=0 for b in all(dl) do if b.mk==fr then n=n+1 end end return n end)()")
    far = pc.L.eval("(function() local n=0 for b in all(dl) do if b.e and b.mk~=fr and b.bx and b.e>sk[8]+10 and b.e<sk[8]+24 then n=n+1 end end return n end)()")
    return dict(draw=draw, upd=upd * 2, obj=obj, far=far, poly=g["__np"], rows=int(g["__nr"]), col=len(g.nb))


def level_report(lv, busy=False):
    worst = None
    for sp in SPOTS[lv]:
        pc = Pico(CART)
        pc.L.execute("setlv(%d)" % (lv - 1))
        pc.L.execute(COUNTERS)
        if busy:      # a loaded PICO-8 reports stat(1)>.9: facade details off
            pc.L.execute("function stat() return 1 end")
        pc.g.mode = "play"
        pc.teleport(*sp)
        pc.g.fade = 0
        for f in range(48):
            if f % 8 == 7:
                s = frame_stats(pc)
                if not worst or s["draw"] + s["upd"] > worst["draw"] + worst["upd"]:
                    worst = s
            else:
                pc.step(["up"])
    return worst


def route_report():
    import bot
    pc = Pico(CART)
    pc.L.execute(COUNTERS)
    costs = []
    orig = pc.step

    def step(hold=(), draw=False, count=False):
        n = len(costs)
        if pc.frame % 2 == 0:
            pc.L.execute("__np,__nr=0,0")
            orig(hold, True, True)
            costs.append(sum(pc.instr) + pc.instr[0])
        else:
            orig(hold, False, False)
    pc.step = step
    bot.play_with(pc, "expert") if hasattr(bot, "play_with") else None
    return costs


if __name__ == "__main__":
    lvs = [int(a) for a in sys.argv[1:] if a.isdigit()] or list(range(1, 9))
    busy = "--busy" in sys.argv
    print("lvl   draw    upd  total  obj far poly rows col" + ("   (facade details off)" if busy else ""))
    for lv in lvs:
        s = level_report(lv, busy)
        print("L%d %7d %6d %6d %4d %3d %4d %4d %3d" % (lv, s["draw"], s["upd"], s["draw"] + s["upd"],
                                                     s["obj"], s["far"], s["poly"], s["rows"], s["col"]))
