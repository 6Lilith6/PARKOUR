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
                     lambda s, tr: s["x"] > 33 and s["y"] == 15),
    "billboard_wallrun": ((14, 16, 89, E), [(100, "up"), (1, "up+z"), (70, "up+z"), (60, "up")],
                          lambda s, tr: s["x"] > 32 and s["y"] == 15 and "wallrun" in tr["states"]),
    "safe_step_s1": ((20, 16, 74, E), [(60, "up"), (1, "up+z"), (40, "up"), (1, "up+z"), (60, "up+z"), (60, "up")],
                     lambda s, tr: s["x"] > 32 and s["y"] == 15),
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
    "beam_to_goal": ((52.12, 17, 145, N), [(300, "up")],
                     lambda s, tr: tr["mode"] == "done"),
}


def run(name, verbose=False, shots=False):
    (x, y, z, a), steps, check = SCENARIOS[name]
    pc = Pico(CART)
    pc.g.mode = "play"
    pc.teleport(x, y, z, a)
    tr = {"states": [], "pops": [], "mode": "play"}
    f = 0
    for n, btns in steps:
        if "=" in btns:
            pc.L.execute(btns)
            continue
        for _ in range(n):
            pc.step(btns.split("+") if btns else [], draw=False)
            s = pc.state()
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
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    names = args or list(SCENARIOS)
    res = [run(n, "-v" in sys.argv, "--shots" in sys.argv) for n in names]
    print("%d/%d passed" % (sum(res), len(res)))
    sys.exit(0 if all(res) else 1)
