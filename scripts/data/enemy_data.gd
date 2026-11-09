class_name EnemyData
## Enemy archetypes. "brain" picks the shared behaviour in EnemySystem; "look" picks the art in EnemyArt.
## Each mission type has its own roster so genres feel different (GDD 2C).
## hp and contact are base values; Stage scales them by danger. Contact is one of the hit sizes (GDD 13C):
## 10 for small enemies, 15 for big ones, 20 for elites.

const ENEMIES := {
	# ---- Star Cluster and Corridor (ship form)
	"dart": {"name": "Dart", "hp": 14, "radius": 13, "speed": 210, "contact": 10, "xp": 1,
		"brain": "formation", "look": "dart", "color": Color(1.0, 0.42, 0.35)},
	"wasp": {"name": "Wasp", "hp": 22, "radius": 14, "speed": 150, "contact": 10, "xp": 2,
		"brain": "weaver", "look": "wasp", "color": Color(1.0, 0.85, 0.3)},
	"splitter": {"name": "Splitter", "hp": 48, "radius": 22, "speed": 90, "contact": 15, "xp": 3,
		"brain": "drifter", "look": "splitter", "color": Color(0.6, 1.0, 0.6), "splits_into": "dart"},
	"bulwark_wing": {"name": "Bulwark Wing", "hp": 60, "radius": 20, "speed": 70, "contact": 15, "xp": 4,
		"brain": "drifter", "look": "bulwark_wing", "color": Color(0.85, 0.5, 1.0), "front_shield": true},
	"minelayer": {"name": "Minelayer", "hp": 40, "radius": 18, "speed": 120, "contact": 10, "xp": 3,
		"brain": "crosser", "look": "minelayer", "color": Color(1.0, 0.5, 0.4)},
	"ace": {"name": "Ace", "hp": 160, "radius": 18, "speed": 260, "contact": 20, "xp": 8,
		"brain": "ace", "look": "ace", "color": Color(1.0, 0.35, 0.5), "elite": true},
	"supply_barge": {"name": "Supply Barge", "hp": 90, "radius": 24, "speed": 95, "contact": 0, "xp": 4,
		"brain": "barge", "look": "barge", "color": Color(0.95, 0.85, 0.4), "drops_crate": true},
	"wall_turret": {"name": "Wall Turret", "hp": 40, "radius": 16, "speed": 0, "contact": 10, "xp": 2,
		"brain": "wall_turret", "look": "turret", "color": Color(1.0, 0.6, 0.35)},
	"drill": {"name": "Drill", "hp": 30, "radius": 14, "speed": 300, "contact": 15, "xp": 2,
		"brain": "rammer", "look": "drill", "color": Color(0.85, 0.85, 0.9)},
	# ---- Planet Exploration (mech form)
	"crawler": {"name": "Crawler", "hp": 18, "radius": 13, "speed": 165, "contact": 10, "xp": 1,
		"brain": "chaser", "look": "crawler", "color": Color(0.75, 1.0, 0.4)},
	"spitter": {"name": "Spitter", "hp": 34, "radius": 16, "speed": 80, "contact": 10, "xp": 2,
		"brain": "lobber", "look": "spitter", "color": Color(0.4, 1.0, 0.75)},
	"sentry": {"name": "Sentry", "hp": 70, "radius": 18, "speed": 0, "contact": 10, "xp": 3,
		"brain": "sentry", "look": "sentry", "color": Color(1.0, 0.7, 0.3)},
	"brute": {"name": "Brute", "hp": 150, "radius": 26, "speed": 85, "contact": 15, "xp": 5,
		"brain": "charger", "look": "brute", "color": Color(1.0, 0.45, 0.35)},
	"burrower": {"name": "Burrower", "hp": 45, "radius": 16, "speed": 140, "contact": 10, "xp": 3,
		"brain": "burrower", "look": "burrower", "color": Color(0.9, 0.75, 0.5)},
	"hive_nest": {"name": "Hive Nest", "hp": 650, "radius": 34, "speed": 0, "contact": 15, "xp": 10,
		"brain": "nest", "look": "nest", "color": Color(0.85, 0.45, 1.0), "objective": true},
	"warlord": {"name": "Warlord", "hp": 320, "radius": 24, "speed": 120, "contact": 20, "xp": 12,
		"brain": "warlord", "look": "warlord", "color": Color(1.0, 0.3, 0.3), "elite": true},
	# ---- Dungeon (mech form)
	"skullbot": {"name": "Skullbot", "hp": 26, "radius": 14, "speed": 190, "contact": 10, "xp": 2,
		"brain": "bouncer", "look": "skullbot", "color": Color(0.95, 0.95, 0.85)},
	"wisp": {"name": "Wisp", "hp": 20, "radius": 12, "speed": 95, "contact": 10, "xp": 2,
		"brain": "phaser", "look": "wisp", "color": Color(0.65, 1.0, 0.7), "ghost": true},
	"pillar_turret": {"name": "Pillar Eye", "hp": 90, "radius": 20, "speed": 0, "contact": 10, "xp": 3,
		"brain": "spinner", "look": "pillar_eye", "color": Color(1.0, 0.4, 0.6)},
	"mimic": {"name": "Mimic", "hp": 120, "radius": 20, "speed": 230, "contact": 15, "xp": 6,
		"brain": "mimic", "look": "mimic", "color": Color(1.0, 0.75, 0.3), "drops_crate": true},
	"gloop": {"name": "Gloop", "hp": 60, "radius": 22, "speed": 70, "contact": 15, "xp": 2,
		"brain": "chaser", "look": "gloop", "color": Color(0.45, 0.95, 0.5), "splits_into": "gloopling"},
	"gloopling": {"name": "Gloopling", "hp": 16, "radius": 12, "speed": 120, "contact": 10, "xp": 1,
		"brain": "chaser", "look": "gloop", "color": Color(0.55, 1.0, 0.6)},
	"knight": {"name": "Hollow Knight-Drone", "hp": 110, "radius": 19, "speed": 105, "contact": 15, "xp": 4,
		"brain": "knight", "look": "knight", "color": Color(0.85, 0.75, 0.6), "front_shield": true},
	# ---- Milestone arrivals (GDD 9D): they join the galaxy once announced.
	"cluster_drone": {"name": "Cluster Drone", "hp": 44, "radius": 17, "speed": 110, "contact": 10, "xp": 3,
		"brain": "drifter", "look": "cluster_drone", "color": Color(1.0, 0.55, 0.85), "splits_into": "drone_shard", "split_count": 4},
	"drone_shard": {"name": "Drone Shard", "hp": 8, "radius": 8, "speed": 240, "contact": 10, "xp": 1,
		"brain": "homer", "look": "drone_shard", "color": Color(1.0, 0.6, 0.9)},
	"centi_mech": {"name": "Centi-Mech", "hp": 70, "radius": 18, "speed": 150, "contact": 15, "xp": 3,
		"brain": "centi", "look": "centi_head", "color": Color(1.0, 0.7, 0.35)},
	"centi_segment": {"name": "Centi-Mech Segment", "hp": 40, "radius": 15, "speed": 150, "contact": 10, "xp": 1,
		"brain": "centi", "look": "centi_segment", "color": Color(0.95, 0.6, 0.3), "front_shield": false},
	"cracked_wall": {"name": "Cracked Wall", "hp": 50, "radius": 30, "speed": 0, "contact": 0, "xp": 0,
		"brain": "inert", "look": "cracked_wall", "color": Color(0.7, 0.65, 0.6)},
	# ---- Boss parts are spawned by boss scripts, not rosters.
	"boss_part": {"name": "Boss", "hp": 100, "radius": 30, "speed": 0, "contact": 20, "xp": 0,
		"brain": "boss_part", "look": "boss_part", "color": Color(1, 1, 1)},
}

## Which enemies each mission type draws from, and how often (weights).
const ROSTERS := {
	"star_cluster": {"dart": 10, "wasp": 6, "splitter": 3, "bulwark_wing": 2, "minelayer": 2},
	"corridor": {"drill": 6, "wasp": 5, "dart": 4, "minelayer": 2},
	"planet": {"crawler": 10, "spitter": 5, "brute": 2, "burrower": 3},
	"dungeon": {"skullbot": 6, "wisp": 5, "gloop": 4, "knight": 2, "pillar_turret": 2},
}


static func get_enemy(kind: String) -> Dictionary:
	return ENEMIES.get(kind, ENEMIES["dart"])
