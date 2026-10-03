#!/usr/bin/env python3
"""Capture the cart label (tools/label.txt) from the sim: the runner
leaping from the chimney to the final tower. build.py embeds it as the
__label__ section of parkour.p8."""
import os, sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Pico  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
pc = Pico(os.path.join(ROOT, "parkour.p8"))
pc.g.mode = "play"
pc.teleport(56, 16, 190, .75)
pc.L.execute("fade=0")
pc.run(104, "up")
pc.run(1, "up+z")
pc.run(30, "up")
pc.g.render()                      # world only, no hud
pc.api_print("parkour", 4, 4, 7)
pc.api_print("rooftops", 4, 11, 9)
with open(os.path.join(ROOT, "tools", "label.txt"), "w") as f:
    for y in range(128):
        f.write("".join("%x" % pc.fb[y * 128 + x] for x in range(128)) + "\n")
print("wrote tools/label.txt")
