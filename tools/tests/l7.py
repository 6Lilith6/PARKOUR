"""Level 7 (cliff village) route checks."""
N, E, S, W = .75, 0, .25, .5
SCENARIOS = {
    "ravine_bridge": ((1.5, 6, -5.5, N), [(300, "up")], lambda s, tr: s["y"] == 6 and s["z"] > 15),
    "ravine_rope": ((-2, 6, 0, N), [(400, "up+bal")], lambda s, tr: s["y"] == 6 and s["z"] > 15),
    "house_roofs": ((8.5, 6, -8, N), [(120, "up+az"), (1, "flow=.4"), (160, "up+ej+rl")],
                    lambda s, tr: tr.get("gy", 0) >= 9 and s["y"] >= 6 and s["z"] > 14),
    "cliff_ladders": ((-3.25, 6, 28, N), [(200, "up"), (1, "px=-1.5 pz=32.75 ang=0"), (110, "up"), (1, "px=2.75 pz=32 ang=.75"), (200, "up")],
                      lambda s, tr: tr.get("gy", 0) >= 18),
    "rock_crack": ((6.25, 6, 31, N), [(400, "up")], lambda s, tr: tr.get("gy", 0) >= 18),
    "outcrops": ((11, 6, 27, N), [(600, "up+az")], lambda s, tr: tr.get("gy", 0) >= 18),
    "gorge_bridge": ((.75, 18, 56, N), [(500, "up+ej")], lambda s, tr: tr.get("gy", 0) >= 20),
    "gorge_beams": ((6.25, 18, 56, N), [(700, "up+bal")], lambda s, tr: tr.get("gy", 0) >= 20),
    "gorge_pillars": ((11.75, 18, 56, N), [(400, "up+ej")], lambda s, tr: tr.get("gy", 0) >= 20),
    "terrace_ladders": ((-2.25, 20, 88, N), [(550, "up")], lambda s, tr: tr.get("gy", 0) >= 28),
    "terrace_grabs": ((3, 20, 86, N), [(600, "up+az")], lambda s, tr: tr.get("gy", 0) >= 28),
    "summit_ladder": ((-1.25, 28, 124, N), [(300, "up")], lambda s, tr: tr["mode"] == "done"),
    "summit_ledge": ((6.5, 28, 120, N), [(400, "up+az")], lambda s, tr: tr["mode"] == "done"),
}
