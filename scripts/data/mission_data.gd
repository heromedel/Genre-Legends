class_name MissionData
## Mission types, the special conditions a planet can carry, and the words the star map is built from.
## ROADMAP Plan A builds the first three mission types (Star Cluster with Corridor Run, Planet, Dungeon).

const TYPES := {
	"star_cluster": {
		"name": "Star Cluster", "form": "ship", "genre": "Formation Shooter",
		"text": "Break the enemy formations, then take down their carrier.",
		"boss": "hive_carrier",
	},
	"corridor": {
		"name": "Corridor Run", "form": "ship", "genre": "Corridor Shooter",
		"text": "Thread a fortified corridor at full speed. Something lives at the end of it.",
		"boss": "wyrm_engine",
	},
	"planet": {
		"name": "Planet Exploration", "form": "mech", "genre": "Open-Area Bullet Hell",
		"text": "Land, roam the surface, wreck what needs wrecking, survive what comes for you.",
		"boss": "siege_crawler",
	},
	"dungeon": {
		"name": "Dungeon Delve", "form": "mech", "genre": "Bullet Hell Crawler",
		"text": "Room by room into the dark. Doors lock behind you until the room is clear.",
		"boss": "hollow_king",
	},
}
const PLAYABLE_TYPES := ["star_cluster", "corridor", "planet", "dungeon"]

## Hand-set difficulty for the first region's six steps (GDD 9A): each was tuned with the average-player
## bot to land in its target. Index = column in the first region (5 = the gate). After that, a formula
## takes over from where the gate leaves off.
const FIRST_REGION_BASELINE := [
	{"enemy_hp": 0.85, "damage": 0.9, "fire": 0.85, "bullet_speed": 0.88},   # planet 1: learn to fly
	{"enemy_hp": 0.95, "damage": 0.85, "fire": 0.88, "bullet_speed": 0.92},  # planet 2: first real fights
	{"enemy_hp": 1.0, "damage": 0.95, "fire": 0.95, "bullet_speed": 0.95},   # planet 3: the needle lesson
	{"enemy_hp": 1.1, "damage": 1.0, "fire": 1.0, "bullet_speed": 1.0},      # planet 4: builds start to matter
	{"enemy_hp": 1.2, "damage": 1.05, "fire": 1.05, "bullet_speed": 1.0},    # planet 5
	{"enemy_hp": 1.3, "damage": 1.1, "fire": 1.1, "bullet_speed": 1.03},     # planet 6: the gate
]
## Each genre's own weight, found with the average-player bot: the shooters' open field is easy to dodge in,
## the corridor's walls and the planet's open swarm are not.
const TYPE_DIFFICULTY := {
	"star_cluster": {"damage": 1.08, "fire": 1.08},
	"corridor": {"damage": 0.75, "fire": 0.85},
	"planet": {"damage": 0.75, "fire": 0.78},
	"dungeon": {"damage": 1.3, "fire": 1.25},
}
## Hazard routes on top of their column's difficulty.
const HAZARD := {"enemy_hp": 1.4, "damage": 1.25, "fire": 1.25, "bullet_speed": 1.05}

## Threat setting: how hard every mission hits. Standard is the default.
const THREAT := {
	"standard": {"name": "Standard", "text": "The intended challenge. Enemies fight back hard enough that builds matter.",
		"damage": 1.0, "fire": 1.0, "bullet_speed": 1.0, "enemy_hp": 1.0, "blueprints": 1.0},
	"veteran": {"name": "Veteran", "text": "For players who know these genres: denser fire, harder hits, tougher enemies, and 50% more blueprints.",
		"damage": 1.3, "fire": 1.35, "bullet_speed": 1.12, "enemy_hp": 1.25, "blueprints": 1.5},
	"casual": {"name": "Casual", "text": "A relaxed ride: slower, sparser fire and softer hits.",
		"damage": 0.65, "fire": 0.7, "bullet_speed": 0.85, "enemy_hp": 0.8, "blueprints": 1.0},
}

## Special conditions shown on a planet before you commit (GDD 5C proposal: the info is the choice).
## Each one changes play and pays for it.
const MODIFIERS := {
	"": {"name": "", "text": ""},
	"ion_storm": {"name": "Ion Storm", "text": "Enemy bullets fly faster. Data Shards are worth 50% more.",
		"bullet_speed": 1.25, "xp": 1.5},
	"swarm_season": {"name": "Swarm Season", "text": "Twice the enemies at half the toughness.",
		"spawn": 2.0, "enemy_hp": 0.5},
	"derelict_field": {"name": "Derelict Field", "text": "Wreckage everywhere: more Salvage Crates, tougher enemies.",
		"crates": 2.0, "enemy_hp": 1.3},
	"bounty_hunters": {"name": "Bounty Hunters", "text": "Elites hunt you. Each one carries blueprints.",
		"elites": 2.0, "elite_blueprints": true},
	"blackout": {"name": "Blackout", "text": "The lights are out. Your frame's lamp is all you get. Double blueprints.",
		"dark": true, "blueprints": 2.0},
}

## What a planet "needs", by mission type. Flavour that tells you what the mission is about.
const NEEDS := {
	"star_cluster": [
		"A carrier fleet has parked over the shipping lanes.",
		"Raider formations are stripping the cluster's beacons.",
		"Something big is launching fighters from behind the moon.",
	],
	"corridor": [
		"The only way through is a fortified trench run.",
		"A smuggler's tunnel leads straight to the enemy's engine.",
		"Their reactor sits at the end of a very long, very angry corridor.",
	],
	"planet": [
		"Hive nests are spreading across the surface.",
		"The colony went quiet. Something burrowed in.",
		"A war machine is stomping toward the last settlement.",
	],
	"dungeon": [
		"Ruins under the crust are humming with Mawjig.",
		"A vault was opened. Whatever was sealed in it is awake.",
		"The mines below the colony go deeper than anyone dug.",
	],
}

## Region and planet names are built from these, seeded by the save's star map seed.
const NAME_STARTS := ["Ar", "Bel", "Cor", "Dra", "Ely", "Fen", "Gal", "Hyr", "Ix", "Jor", "Kal", "Lum",
	"Mor", "Nyx", "Or", "Pyr", "Quel", "Ryn", "Sol", "Tor", "Ul", "Vex", "Wyr", "Xan", "Zel"]
const NAME_ENDS := ["a", "ion", "is", "ara", "eth", "os", "une", "ax", "or", "ia", "ex", "oth", "yne", "ar"]
const REGION_WORDS := ["Reach", "Expanse", "Verge", "Drift", "Rift", "Shoals", "Frontier", "Maw", "Deep", "Spiral"]

## Region palettes cycle so neighbouring regions look different.
const REGION_PALETTES := [
	{"sky": Color(0.04, 0.07, 0.16), "nebula": Color(0.2, 0.35, 0.75), "ground": Color(0.16, 0.3, 0.26), "accent": Color(0.45, 0.95, 1.0)},
	{"sky": Color(0.12, 0.05, 0.06), "nebula": Color(0.7, 0.25, 0.15), "ground": Color(0.42, 0.24, 0.15), "accent": Color(1.0, 0.6, 0.3)},
	{"sky": Color(0.04, 0.11, 0.08), "nebula": Color(0.15, 0.6, 0.4), "ground": Color(0.2, 0.36, 0.18), "accent": Color(0.6, 1.0, 0.5)},
	{"sky": Color(0.09, 0.05, 0.14), "nebula": Color(0.55, 0.25, 0.75), "ground": Color(0.32, 0.2, 0.38), "accent": Color(0.9, 0.6, 1.0)},
	{"sky": Color(0.05, 0.1, 0.13), "nebula": Color(0.2, 0.6, 0.7), "ground": Color(0.3, 0.38, 0.44), "accent": Color(0.7, 0.95, 1.0)},
]

## Themed branches (GDD 5D): side routes that lean on one genre and end in a prize shown up front.
const THEMED_BRANCHES := [
	{"id": "tempest_run", "name": "The Tempest Run", "type": "star_cluster", "length": 3, "region": 0,
		"modifier": "bounty_hunters", "prize": "frame:tempest",
		"prize_text": "Unlocks the Tempest frame."},
	{"id": "undervault", "name": "The Undervault", "type": "dungeon", "length": 3, "region": 1,
		"modifier": "blackout", "prize": "tech:time_brake",
		"prize_text": "Unlocks Time Brake at Mk 1."},
	{"id": "meteor_coast", "name": "The Meteor Coast", "type": "planet", "length": 3, "region": 2,
		"modifier": "derelict_field", "prize": "tech:starfall",
		"prize_text": "Unlocks Starfall at Mk 1."},
]
## The second region's gate unlocks Bulwark.
const GATE_PRIZES := {1: "frame:bulwark"}


## What you'll face on a planet (GDD 9F), so loadout choice matters before you launch.
const TYPE_TRAITS := {
	"star_cluster": ["Diving formations", "Shielded wings (hit them from the side)"],
	"corridor": ["Wall turrets", "Laser gates", "Narrow walls"],
	"planet": ["Hive nests", "Swarms of crawlers", "Acid spitters"],
	"dungeon": ["Shielded knights (strike after they lunge)", "Mimics", "Locked doors"],
}
const LESSON_TRAITS := {
	"needles": "Needle swarms (shields that reflect them help a lot)",
	"mirror": "Mirrored hull (straight shots bounce back; homing gets around it)",
}
const ARRIVAL_TRAITS := {
	"cluster_drone": ["star_cluster", "Cluster Drones (split when hit)"],
	"centi_mech": ["planet", "Centi-Mechs"],
}


static func traits_for(node: Dictionary, arrivals: Array) -> Array:
	var traits: Array = TYPE_TRAITS.get(node["type"], []).duplicate()
	if node.get("lesson", "") != "":
		traits.push_front(LESSON_TRAITS[node["lesson"]])
	for kind in arrivals:
		if ARRIVAL_TRAITS.has(kind) and ARRIVAL_TRAITS[kind][0] == node["type"]:
			traits.append(ARRIVAL_TRAITS[kind][1])
	return traits
