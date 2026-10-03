"""Level 3 (factory) route checks."""
N, E, S, W = .75, 0, .25, .5
SCENARIOS = {
    "vault_conveyor": ((6, 2, -6, E), [(130, "up")], lambda s, tr: s["x"] > 14 and "vault" in " ".join(tr["pops"])),
    "slide_pipe": ((14.5, 2, -6, E), [(150, "up+ax")], lambda s, tr: s["x"] > 24),
    "catwalk_ladder": ((1.5, 2, 17.25, E), [(140, "up")], lambda s, tr: tr.get("gy", 0) >= 6),
    "catwalk_crates": ((15, 2, 8, N), [(52, "up"), (1, "up+z"), (40, "up"), (1, "up+z"), (80, "up")], lambda s, tr: tr.get("gy", 0) >= 6),
    "catwalk_to_containers": ((5, 6, 17.25, E), [(1, "flow=.6"), (345, "up"), (1, "up+z"), (420, "up+az")], lambda s, tr: tr.get("gx", 0) > 90 and tr.get("gy", 0) >= 7),
    "singles_to_double": ((52, 2, 12.25, E), [(200, "up+az")], lambda s, tr: tr.get("gy", 0) >= 4.5),
    "tank_wallrun": ((84, 7, 18.1, E), [(1, "flow=.8"), (1, "spd=8"), (80, "up"), (1, "up+z"), (150, "up+z"), (90, "up")], lambda s, tr: "wallrun" in tr["pops"] and tr.get("gx", 0) >= 106 and tr.get("gy", 0) >= 7),
    "rack_ladder": ((102, 2, 17, E), [(250, "up")], lambda s, tr: tr.get("gy", 0) >= 7),
    "rack_run": ((109, 7, 17, E), [(1, "flow=.8"), (420, "up+ax")], lambda s, tr: tr.get("gx", 0) > 145),
    "plank_bridge": ((147, 2, 6.25, E), [(400, "up+bal")], lambda s, tr: tr.get("gx", 0) > 165),
    "hook_container": ((143, 7, 17, E), [(40, "up"), (300, "up+az")], lambda s, tr: tr.get("gx", 0) > 160 and tr.get("gy", 0) >= 7),
    "long_jump": ((112, 7, 17, E), [(1, "flow=1"), (1, "spd=8.5"), (230, "up+ax"), (1, "up+z"), (160, "up")], lambda s, tr: tr.get("gx", 0) > 157 and "hard landing" not in tr["pops"]),
    "conveyor_ladder": ((166.75, 2, 10, N), [(200, "up")], lambda s, tr: tr.get("gy", 0) >= 7),
    "silo_goal": ((176, 7, 16.5, E), [(400, "up+az")], lambda s, tr: tr["mode"] == "done"),
}
