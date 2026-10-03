"""Level 2 (construction) route checks: (start x,y,z,heading, steps, check)."""
N, E, S, W = .75, 0, .25, .5
W4 = [(60, "up+z"), (40, "up")]
SCENARIOS = {
    "ladder_f1": ((0.75, 5, 9, N), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 9),
    "pallet_f1": ((5.5, 5, 8.2, N), [(20, "up"), (1, "up+z"), (40, "up"), (1, "up+z"), (60, "up")], lambda s, tr: tr.get("gy", 0) >= 9),
    "wallrun_up_f1": ((7.5, 5, 4.5, N), [(56, "up"), (1, "up+z")] + W4, lambda s, tr: tr.get("gy", 0) >= 9),
    "slide_bar": ((0, 9, 21, N), [(30, "up"), (40, "up+x"), (40, "up")], lambda s, tr: s["z"] > 26 and s["y"] == 9),
    "ladder_f2": ((1.75, 9, 31, S), [(135, "up")], lambda s, tr: tr.get("gy", 0) >= 13),
    "crates_f2": ((6.25, 9, 33, S), [(10, "up"), (150, "up+az")], lambda s, tr: tr.get("gy", 0) >= 13),
    "wall_f2": ((-2, 9, 36, S), [(62, "up"), (1, "up+z")] + W4, lambda s, tr: tr.get("gy", 0) >= 13),
    "hole_f2": ((0, 13, 27.5, S), [(30, "up"), (1, "up+z"), (90, "up")], lambda s, tr: tr.get("gy", 0) >= 13 and s["z"] < 22),
    "ladder_f3": ((15.75, 13, 14, N), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 17),
    "hang_pallet_f3": ((3, 13, 14.5, N), [(1, "up+z"), (150, "up+az")], lambda s, tr: tr.get("gy", 0) >= 17),
    "wall_f3": ((7.5, 13, 12.2, N), [(60, "up"), (1, "up+z")] + W4, lambda s, tr: tr.get("gy", 0) >= 17),
    "gap_pallets": ((19.5, 17, 27, E), [(300, "up+az")], lambda s, tr: tr.get("gx", 0) > 40),
    "gap_girder": ((17, 17, 30.75, E), [(300, "up+bal")], lambda s, tr: tr.get("gx", 0) > 40),
    "gap_panel_wallrun": ((4, 17, 26.35, E), [(1, "flow=.8"), (84, "up"), (1, "up+z"), (150, "up+z"), (120, "up")], lambda s, tr: tr.get("gx", 0) > 40 and "wallrun" in tr["pops"]),
    "t2_ladder": ((44, 17, 14.75, E), [(140, "up")], lambda s, tr: tr.get("gy", 0) >= 21),
    "t2_net": ((40.5, 17, 22, E), [(180, "up")], lambda s, tr: tr.get("gy", 0) >= 21 and "bounce" in tr["pops"]),
    "t2_crates": ((46.5, 21, 14.5, E), [(5, "up"), (150, "up+az")], lambda s, tr: tr.get("gy", 0) >= 25),
    "t2_hangpallet": ((46.5, 21, 21, E), [(1, "up+z"), (150, "up+az")], lambda s, tr: tr.get("gy", 0) >= 25),
    "t2_ladder2": ((50, 21, 32.75, E), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 25),
    "t2_net2": ((52.5, 25, 28, E), [(180, "up")], lambda s, tr: tr.get("gy", 0) >= 29),
    "t2_ladder3": ((56, 25, 14.75, E), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 29),
    "mast": ((70, 29, 23, E), [(195, "up")], lambda s, tr: tr.get("gy", 0) >= 34.5),
    "jib_goal": ((76.5, 34.5, 23, W), [(300, "up+bal")], lambda s, tr: tr["mode"] == "done"),
}
