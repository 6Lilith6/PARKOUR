#!/usr/bin/env python3
"""Scripted play-tests for parkour.p8 (uses the headless sim).

Each scenario places the runner somewhere in the level, replays a list of
(frames, buttons) steps and checks where it ends up. Run:

    python3 tools/playtest.py            # all scenarios
    python3 tools/playtest.py roll -v    # one scenario, print trace
    python3 tools/playtest.py --shots    # also save screenshots to /tmp/pt
"""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

CART = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "parkour.p8")

N, E, S, W = .75, 0, .25, .5   # headings: +z, +x, -z, -x

# name: (start x,y,z,heading, [(frames, buttons)], check(state, trace))
SCENARIOS = {
    "run_vault_r1": ((10, 14, 2, N), [(200, "up")],
                     lambda s, tr: s["z"] > 17 and "vault" in tr["pops"]),
    "slide_under_pipe": ((5, 14, 18, N), [(30, "up"), (45, "up+x"), (30, "up")],
                         lambda s, tr: s["z"] > 23.5 and "slide" in tr["states"]),
    "jump_gap_roll": ((10, 14, 26, N), [(70, "up"), (1, "up+z"), (25, "up+z"), (20, "up"), (4, "up+x"), (60, "up")],
                      lambda s, tr: s["z"] > 38 and s["y"] == 12 and "roll" in tr["pops"]),
    "jump_gap_noroll": ((10, 14, 26, N), [(70, "up"), (1, "up+z"), (25, "up+z"), (60, "up")],
                        lambda s, tr: s["z"] > 37 and s["y"] == 12 and "land" in tr["states"]),
    "ladder_up_r3": ((7, 12, 59, N), [(200, "up")],
                     lambda s, tr: s["y"] == 16 and "climb" in tr["states"]),
    "hut_mantles": ((16, 12, 52, N), [(30, "up"), (1, "up+z"), (60, "up"), (20, ""), (1, "up+z"), (80, "up"), (20, ""), (1, "up+z"), (80, "up")],
                    lambda s, tr: s["y"] == 16),
    "wall_runup_r3": ((11, 12, 50, N), [(118, "up"), (1, "up+z"), (60, "up+z"), (60, "up")],
                      lambda s, tr: s["y"] == 16 and "wallup" in tr["states"]),
    "balance_pipe": ((21, 16, 84.12, E), [(240, "up")],
                     lambda s, tr: s["x"] > 31 and s["y"] == 15),
    "billboard_wallrun": ((14, 16, 89, E), [(100, "up"), (1, "up+z"), (70, "up+z"), (60, "up")],
                          lambda s, tr: s["x"] > 30 and s["y"] == 15 and "wallrun" in tr["states"] and "land" not in tr["states"]),
    "safe_step_s1": ((20, 16, 74, E), [(60, "up"), (40, "up"), (1, "up+z"), (60, "up")],
                     lambda s, tr: s["x"] > 30 and s["y"] == 15),
    "fire_escape_p1_p2": ((49.25, 12.75, 90.7, S), [(22, "up"), (1, "up+z"), (100, "up")],
                          lambda s, tr: s["y"] == 10.75),
    "fire_escape_p2_r5": ((48.5, 10.75, 84.5, E), [(20, "up"), (1, "up+z"), (60, "up")],
                          lambda s, tr: s["y"] == 9),
    "drop_r4_r5_roll": ((45, 15, 80, E), [(40, "up"), (45, "up"), (8, "up+x"), (60, "up")],
                        lambda s, tr: s["y"] == 9 and "roll" in tr["pops"]),
    "awning_bounce": ((53, 9, 99.2, E), [(150, "up")],
                      lambda s, tr: s["y"] == 15 and "bounce" in tr["pops"]),
    "balcony_to_r6": ((62, 15, 99.5, N), [(1, "up+z"), (100, "up")],
                      lambda s, tr: s["y"] == 18),
    "drainpipe": ((52.75, 9, 96, N), [(400, "up")],
                  lambda s, tr: s["y"] == 18),
    "expert_r4_r6": ((47.3, 15, 78, N), [(1, "flow=1"), (150, "up"), (1, "up+z"), (80, "up+z"), (60, "up")],
                     lambda s, tr: s["y"] == 18),
    "r6_speed_line": ((56.5, 18, 104, N), [(330, "up"), ],
                      lambda s, tr: s["z"] > 128),
    "beam_r7_r8": ((52.12, 17, 145, N), [(200, "up")],
                   lambda s, tr: s["y"] == 15 and s["z"] > 156),
    "skybridge": ((59.5, 15, 166, N), [(330, "up")],
                  lambda s, tr: s["y"] == 16 and s["z"] > 187),
    "cable": ((50.12, 15, 166, N), [(330, "up")],
              lambda s, tr: s["y"] == 16 and s["z"] > 187),
    "board_chain": ((48.55, 15, 160, N), [(110, "up"), (1, "up+z"), (49, "up+z"), (2, "up"), (1, "up+z"), (130, "up+z")],
                    lambda s, tr: s["y"] == 16 and s["z"] > 185.5 and tr["pops"].count("wallrun") == 2),
    "stairs": ((53.5, 16, 202.5, W), [(85, "up")],
               lambda s, tr: s["y"] == 18),
    "ladder_t": ((46, 18, 202.5, N), [(150, "up")],
                 lambda s, tr: s["y"] == 21),
    "chimney": ((56, 16, 198.6, N), [(1, "up+z"), (72, "up"), (1, "up+z"), (90, "up")],
                lambda s, tr: s["y"] == 21),
    "vault_mantle_chain": ((56, 16, 190, N), [(104, "up"), (1, "up+z"), (40, "up"), (1, "up+z"), (80, "up")],
                           lambda s, tr: s["y"] == 21),
    "goal": ((52, 21, 205, N), [(120, "up")],
             lambda s, tr: tr["mode"] == "done"),
}


def run(name, verbose=False, shots=False):
    (x, y, z, a), steps, check = SCENARIOS[name]
    pc = Pico(CART)
    if name[0] == "L" and name[2] == ":":
        pc.L.execute("setlv(%d)" % (int(name[1]) - 1))
    pc.g.mode = "play"
    pc.teleport(x, y, z, a)
    tr = {"states": [], "pops": [], "mode": "play"}
    f = 0
    for n, btns in steps:
        if "=" in btns:
            pc.L.execute(btns)
            continue
        for _ in range(n):
            b = btns.split("+") if btns else []
            if "az" in b:             # jump again ~0.1s after landing
                b.remove("az")
                if pc.g.st == "ground" and pc.g.stt > .1 and pc.g.stt < .14: b.append("z")
            if "ej" in b:             # jump where the floor ends
                b.remove("ej")
                if pc.g.st == "ground" and not pc.L.eval("solid(px+cos(ang)*.7,py-.1,pz+sin(ang)*.7)"): b.append("z")
            if "rl" in b:             # tap roll while falling
                b.remove("rl")
                if pc.g.st == "air" and pc.g.vy < -3 and f % 2 == 0: b.append("x")
            if "ax" in b:             # slide when a low bar is just ahead
                b.remove("ax")
                if pc.g.st in ("ground", "slide") and pc.L.eval(
                        "(function() for d=.5,2.5,.5 do if solid(px+cos(ang)*d,py+1.3,pz+sin(ang)*d) and not solid(px+cos(ang)*d,py+.4,pz+sin(ang)*d) then return true end end end)()"):
                    b.append("x")
            if "bal" in b:            # human-like balance correction
                b.remove("bal")
                if pc.g.bal > .12: b.append("left")
                if pc.g.bal < -.12: b.append("right")
            pc.step(b, draw=False)
            s = pc.state()
            if s["st"] == "ground":
                tr["gy"] = max(tr.get("gy", -99), s["y"])
                tr["gx"] = max(tr.get("gx", -99), s["x"])
            if not tr["states"] or tr["states"][-1] != s["st"]:
                tr["states"].append(s["st"])
                if verbose:
                    print("%4d %-8s %s" % (f, btns, s))
            if s["pop"] and (not tr["pops"] or tr["pops"][-1] != s["pop"]) and pc.g.popt > .98:
                tr["pops"].append(s["pop"])
            if shots and f % 15 == 0:
                os.makedirs("/tmp/pt", exist_ok=True)
                pc.shot("/tmp/pt/%s_%03d.png" % (name, f), 2)
            f += 1
    tr["mode"] = pc.g.mode
    s = pc.state()
    ok = check(s, tr)
    print("%-20s %s  end=%s pops=%s" % (name, "PASS" if ok else "FAIL",
                                       {k: s[k] for k in ("st", "x", "y", "z", "hs")}, tr["pops"]))
    if verbose:
        print("   states:", tr["states"])
    return ok


if __name__ == "__main__":
    import glob, importlib.util
    # per-level scenario files: tools/tests/l<n>.py define SCENARIOS
    for p in sorted(glob.glob(os.path.join(os.path.dirname(os.path.abspath(__file__)), "tests", "l*.py"))):
        n = os.path.basename(p)[1]
        spec = importlib.util.spec_from_file_location("t" + n, p)
        m = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(m)
        SCENARIOS.update({"L%s:%s" % (n, k): v for k, v in m.SCENARIOS.items()})
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    names = [k for k in SCENARIOS if any(k == a or k.startswith(a) for a in args)] if args else list(SCENARIOS)
    res = [run(n, "-v" in sys.argv, "--shots" in sys.argv) for n in names]
    print("%d/%d passed" % (sum(res), len(res)))
    sys.exit(0 if all(res) else 1)
