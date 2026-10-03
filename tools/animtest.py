#!/usr/bin/env python3
"""Animation test area.

Builds a flat test level in the sim (an endless floor at y=2 with a 1m vault
box, a wallrun wall and a 2.5m ledge), plays each move and renders
filmstrips of the runner from behind, from the side and at an angle, plus a
foot-slip meter for the run cycle (world speed of a foot while it is on the
ground: should be near 0 even when the body runs at 9 m/s).

    python3 tools/animtest.py                 # all moves -> /tmp/anim_*.png
    python3 tools/animtest.py run,jump,vault  # some moves
    python3 tools/animtest.py --slip          # foot slip numbers only
"""
import math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico, PALETTE  # noqa: E402
from PIL import Image, ImageDraw  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")

AREA = ("local function bx(x0,y0,z0,x1,y1,z1) local b={x0,y0,z0,x1,y1,z1,m=1,k=0,f=1} add(boxes,b) add(dl,b) end "
        "boxes={} dl={} trig={} bx(-200,0,-200,200,2,200) "
        "bx(-2,2,10,2,3,10.5) "      # 1m vault box
        "bx(1.5,2,30,2,7,50) "       # wallrun wall on the +x side
        "bx(-3,2,60,3,4.5,64) "      # 2.5m ledge
        "add(dl,plb)")

# name: start (x,y,z,heading), setup lua, steps, (every n frames, skip)
MOVES = {
    "idle":    ((0, 2, 0, .75), "", [(80, "")], (6, 0)),
    "walk":    ((0, 2, -20, .75), "", [(25, "up"), (100, "")], (3, 22)),
    "run":     ((0, 2, -30, .75), "", [(160, "up")], (2, 120)),
    "sprint":  ((0, 2, -40, .75), "flow=1", [(160, "up")], (2, 130)),
    "turn":    ((0, 2, -30, .75), "", [(80, "up"), (40, "up+left"), (40, "up+right")], (6, 70)),
    "stop":    ((0, 2, -30, .75), "", [(90, "up"), (50, "down")], (4, 80)),
    "jump":    ((0, 2, -14, .75), "", [(60, "up"), (1, "up+z"), (70, "up")], (4, 40)),
    "land3m":  ((0, 5, 0, .75), "spd=4", [(1, ""), (60, "up")], (3, 24)),
    "roll":    ((0, 8, 0, .75), "spd=6", [(36, "up"), (2, "up+x"), (60, "up")], (3, 38)),
    "slide":   ((0, 2, -20, .75), "", [(80, "up"), (1, "up+x"), (50, "up+x"), (30, "up")], (4, 60)),
    "vault":   ((0, 2, 0, .75), "", [(160, "up")], (2, 106)),
    "wallrun": ((0.9, 2, 18, .75), "flow=.8 spd=7", [(66, "up"), (1, "up+z"), (80, "up+z"), (30, "up")], (4, 62)),
    "ledge":   ((0, 2, 55, .75), "", [(42, "up"), (1, "up+z"), (90, "up")], (3, 62)),
}
VIEWS = (("behind", 0, 1.3), ("side", .25, 1.0), ("angle", .12, 1.6))


def setcam(pc, dist, yawoff, h, fl=100):
    pc.L.execute(("local a=bang+%f cpos={px-cos(a)*%f,py+%f,pz-sin(a)*%f} "
                  "local lx,ly,lz=px-cpos[1],py+.9-cpos[2],pz-cpos[3] "
                  "local yaw,pit=atan2(lx,lz),atan2(sqrt(lx*lx+lz*lz),ly) "
                  "ccy,csy,ccp,csp=cos(yaw),sin(yaw),cos(pit),sin(pit) cfw={ccy*ccp,csp,csy*ccp} fl=%d")
                 % (yawoff, dist, h, dist, fl))


def shot(pc):
    pc.L.execute("cls(6) rectfill(0,64,127,127,13)")
    pc.L.execute("plb[1],plb[2],plb[3],plb[4],plb[5],plb[6]=px-r,py,pz-r,px+r,py+ph,pz+r drawplayer()")
    im = Image.new("RGB", (128, 128))
    im.putdata([PALETTE[c] for c in pc.fb])
    return im.crop((16, 0, 112, 128))


def start(name):
    sp, setup, steps, _ = MOVES[name]
    pc = Pico(CART)
    pc.L.execute(AREA)
    pc.g.mode = "play"
    pc.teleport(*sp)
    pc.L.execute("fade=0 " + setup)
    return pc, steps


def film(name, n=10):
    every, skip = MOVES[name][3]
    rows = []
    for vname, yo, h in VIEWS:
        pc, steps = start(name)
        frames, f = [], 0
        for k, b in steps:
            for _ in range(k):
                pc.step(b.split("+") if b else [])
                if f >= skip and (f - skip) % every == 0 and len(frames) < n:
                    setcam(pc, 2.6, yo, h)
                    im = shot(pc)
                    ImageDraw.Draw(im).text((1, 118), pc.g.st[:6], fill=(0, 0, 0))
                    frames.append(im)
                f += 1
        rows.append((vname, frames))
    w = Image.new("RGB", (96 * n, 128 * len(rows)), (255, 255, 255))
    d = ImageDraw.Draw(w)
    for r, (vname, ims) in enumerate(rows):
        for i, im in enumerate(ims):
            w.paste(im, (i * 96, r * 128))
        d.text((2, r * 128 + 2), name + " / " + vname, fill=(0, 0, 0))
    return w.resize((w.width * 2, w.height * 2), Image.NEAREST)


def slip(setup="", frames=240):
    """mean and worst world speed of a grounded foot while running"""
    pc = Pico(CART)
    pc.L.execute(AREA)
    pc.g.mode = "play"
    pc.teleport(0, 2, -100, .75)
    pc.L.execute("fade=0 " + setup)
    pc.run(40, "up")
    prev, worst, tot, cnt = {}, 0, 0, 0
    for _ in range(frames):
        pc.step(["up"])
        g = pc.g
        bfx, bfz = math.cos(2 * math.pi * g.bang), -math.sin(2 * math.pi * g.bang)
        for i, sd in ((4, -1), (6, 1)):
            fwd, up, s = g.q[i], g.q[i + 1], sd * .12 + g.q[13]
            wx, wz = g.px + bfx * fwd - bfz * s, g.pz + bfz * fwd + bfx * s
            if up < .09:
                if i in prev:
                    v = math.hypot(wx - prev[i][0], wz - prev[i][1]) * 60
                    worst, tot, cnt = max(worst, v), tot + v, cnt + 1
                prev[i] = (wx, wz)
            else:
                prev.pop(i, None)
    return g.hs(), tot / max(cnt, 1), worst


if __name__ == "__main__":
    for label, setup in (("run", ""), ("sprint", "flow=1")):
        hs, mean, worst = slip(setup)
        print("%-6s body %.1f m/s  grounded foot: mean %.2f m/s, worst %.2f m/s" % (label, hs, mean, worst))
    if "--slip" in sys.argv:
        sys.exit()
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    names = args[0].split(",") if args else list(MOVES)
    for nm in names:
        out = "/tmp/anim_%s.png" % nm
        film(nm).save(out)
        print("wrote", out)
