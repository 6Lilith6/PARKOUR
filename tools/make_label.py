#!/usr/bin/env python3
"""Capture the cart label (tools/label.txt) from the sim: the runner
running at the gap on the construction site
(that level keeps the default palette, so the label colours match).
build.py embeds it as the __label__ section of parkour.p8."""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pc = Pico(os.path.join(ROOT, "parkour.p8"))
pc.L.execute("setlv(1)")
pc.g.mode = "play"
pc.teleport(17, 17, 27, 0)
pc.L.execute("fade=0 flow=.5")
pc.run(30, "up")
pc.g.render()                      # world only, no hud
pc.api_print("parkour", 4, 4, 7)
pc.api_print("8 levels of flow", 4, 11, 10)
with open(os.path.join(ROOT, "tools", "label.txt"), "w") as f:
    for y in range(128):
        f.write("".join("%x" % pc.fb[y * 128 + x] for x in range(128)) + "\n")
print("wrote tools/label.txt")
