#!/usr/bin/env python3
"""Waypoint autopilot: plays full routes through the level in the sim.

    python3 tools/bot.py safe            # run the safe route
    python3 tools/bot.py expert --gif    # also write /tmp/expert.gif

Verifies a complete run reaches every checkpoint and the goal, and
reports time, flow score and the moves performed.
"""
import math, os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")

# (x, z, action): go | jump | jumpz (jump, keep z held) | roll (go, roll
# on next landing) | slide
ROUTES = {
    "safe": [
        (10, 8, "go"), (10, 15, "go"), (10, 21, "slide"), (10, 33.3, "jump"),
        (10, 38, "roll"), (7, 52, "go"), (7, 62.5, "go"),           # ladder
        (9, 70, "go"), (14, 74, "go"), (24.5, 74, "go"),           # off to S1
        (28.4, 74, "jump"), (33, 74, "go"), (47.5, 80, "go"),       # R4
        (52, 80, "roll"), (52.75, 96, "go"), (52.75, 99.4, "go"),   # pipe
        (56, 104, "go"), (56, 129.4, "jump"), (52.12, 140, "go"),
        (52.12, 150, "go"), (52.12, 156, "go"), (59.5, 164, "go"),
        (59.5, 171, "go"), (59.5, 190, "go"), (54, 198, "go"),      # bridge
        (53.5, 202.5, "go"), (47, 202.5, "go"), (46, 202.9, "go"),  # stairs
        (46, 203.4, "go"), (52, 210, "go"),                         # ladder
    ],
    "expert": [
        (10, 8, "go"), (10, 15, "go"), (10, 21, "slide"), (10, 33.3, "jump"),
        (10, 38, "roll"), (11, 59.6, "jumpz"),                     # run-up R3
        (11, 84, "go"), (11.5, 89.2, "go"), (16, 89.2, "go"),
        (22.6, 89.2, "jumpz"), (32, 89, "go"),                      # board
        (36, 90.5, "go"), (42, 80, "go"), (47.3, 84, "go"), (47.3, 93.4, "jumpz"),  # gap
        (56, 106, "go"), (56, 129.4, "jump"), (52.12, 140, "go"),
        (52.12, 150, "go"), (52.12, 156, "go"), (48.55, 164, "go"),
        (48.55, 171.4, "jumpz"), (48.4, 177.2, "kick"),             # boards
        (51.4, 186, "go"), (56, 192, "go"), (56, 197.4, "jump"),    # unit
        (56, 202.2, "jump"), (54, 210, "go"),
    ],
}


def heading_to(dx, dz):
    return (math.atan2(-dz, dx) / (2 * math.pi)) % 1


def angd(a):
    return (a + .5) % 1 - .5


def play(route, gif=False, verbose=False, max_frames=60 * 120):
    pc = Pico(CART)
    pc.step(["z"]); pc.step([])          # leave the title
    wps = ROUTES[route]
    i, f, frames, moves, rolling, holdz, cps, kick = 0, 0, [], [], False, 0, [], 0
    last_pop = None
    while f < max_frames and pc.g.mode == "play" and i <= len(wps):
        g = pc.g
        st = g.st
        btns = set()
        if i < len(wps):
            x, z, act = wps[i]
            dx, dz = x - g.px, z - g.pz
            dist = math.hypot(dx, dz)
            if st in ("ground", "slide", "roll") or st == "air" and not holdz:
                d = angd(heading_to(dx, dz) - g.ang) if dist > .3 else 0
                if d > .006: btns.add("left")
                if d < -.006: btns.add("right")
            dang = abs(angd(heading_to(dx, dz) - g.ang))
            if dang < .06 or st != "ground":
                btns.add("up")      # ease off to turn sharply
            elif dang > .12 and g.spd > 4 and dist < 8:
                btns.add("down")    # brake for a tight turn
            near = dist < (0.45 if act.startswith("jump") or act == "slide" else 1.0)
            if near and st == "ground":
                if act.startswith("jump"):
                    btns.add("z")
                    holdz = 90 if act == "jumpz" else 0
                elif act == "slide":
                    btns.add("x")
                rolling = act == "roll"
                i += 1
            elif near and st not in ("ground",) and act in ("go", "roll"):
                rolling = rolling or act == "roll"
                i += 1
            elif act == "kick" and st == "wallrun" and dist < .8:
                kick = 2
                i += 1
            elif dist < 2.5 and abs(angd(heading_to(dx, dz) - g.ang)) > .3 and st != "climb" and act != "kick":
                i += 1          # passed it (e.g. a grab moved us on)
        if holdz > 0:
            btns.add("z"); holdz -= 1
        if kick > 0:
            kick -= 1
            btns.discard("z")
            if kick == 0:
                btns.add("z"); holdz = 80
        if rolling and st == "air" and g.vy < 0 and g.py - g.shy < 1.6:
            btns.add("x")
        if st == "ground":
            rolling = rolling and False
        pc.step(btns, draw=gif and f % 3 == 0)
        if gif and f % 3 == 0:
            from PIL import Image
            from sim import PALETTE
            im = Image.new("RGB", (128, 128))
            im.putdata([PALETTE[c] for c in pc.fb])
            frames.append(im.resize((256, 256), Image.NEAREST))
        if pc.g.popt > .98 and pc.g.pop != last_pop:
            moves.append(pc.g.pop)
        last_pop = pc.g.pop if pc.g.popt > 0 else None
        if pc.g.cpi not in cps:
            cps.append(pc.g.cpi)
        if verbose and f % 30 == 0:
            print(f, i, pc.state())
        f += 1
    done = pc.g.mode == "done"
    print("%-8s %s  time=%.2fs  checkpoints=%s  score=%s  frames=%d" % (
        route, "FINISHED" if done else "STUCK at wp %d %s" % (i, pc.state()),
        pc.g.tm / 60, cps, pc.g.score, f))
    print("   moves:", ", ".join(moves))
    if gif and frames:
        frames[0].save("/tmp/%s.gif" % route, save_all=True, append_images=frames[1:],
                       duration=50, loop=0)
        print("   wrote /tmp/%s.gif (%d frames)" % (route, len(frames)))
    return done


if __name__ == "__main__":
    names = [a for a in sys.argv[1:] if not a.startswith("-")] or list(ROUTES)
    ok = [play(n, "--gif" in sys.argv, "-v" in sys.argv) for n in names]
    sys.exit(0 if all(ok) else 1)
