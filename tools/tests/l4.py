"""Level 4 (underground) route checks."""
N, E, S, W = .75, 0, .25, .5
SCENARIOS = {
    "platform_run": ((4, 3.25, 3, N), [(420, "up")], lambda s, tr: s["z"] > 38),
    "train_roof": ((7.5, 3.25, 12, E), [(10, "up"), (1, "up+z"), (100, "up")], lambda s, tr: tr.get("gy", 0) >= 5.5),
    "platform_to_walkway": ((9.6, 3.25, 37.5, N), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 4.25 and s["z"] > 45),
    "walkway_run": ((9.6, 4.25, 42, N), [(1, "flow=.5"), (700, "up+az+ax")], lambda s, tr: s["z"] > 88),
    "trackbed_run": ((11.5, 2, 42, N), [(600, "up+ax")], lambda s, tr: s["z"] > 88),
    "tunnel_zigzag": ((9.6, 4.25, 42, N), [(1, "flow=.8"), (1, "spd=8"), (10, "up"), (31, "up+z+right"), (30, "up+z"), (2, "up"), (1, "up+z"), (40, "up+z"), (2, "up"), (1, "up+z"), (50, "up+z"), (60, "up")], lambda s, tr: tr["pops"].count("wallrun") >= 2 and s["z"] > 62),
    "crate_chain": ((9.6, 4.25, 92, N), [(400, "up+az")], lambda s, tr: tr.get("gy", 0) >= 9),
    "landing_ladder": ((0.75, 2, 105, N), [(250, "up")], lambda s, tr: tr.get("gy", 0) >= 9),
    "upper_tunnel": ((12.25, 9, 112, N), [(1, "flow=.5"), (700, "up+az+ax+bal")], lambda s, tr: s["z"] > 160),
    "exit_goal": ((11, 9, 168, N), [(400, "up+az")], lambda s, tr: tr["mode"] == "done"),
}
