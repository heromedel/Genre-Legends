class_name TechData
## Every piece of tech the frame can equip: its slot, what each level adds, and its two forks.
## Pure data. WeaponSystem reads it to decide how tech behaves; nothing here holds game state.
## GDD 7A–7F: blueprints unlock and upgrade tech, it is equipped in a limited loadout,
## it starts offline in a mission (except the main weapon) and is levelled up in the mission,
## and at the fork level the player picks one of two very different behaviours.

## Loadout slots, in order. Index 0 is always the main weapon, the only tech online at mission start.
const SLOTS := ["main", "weapon", "weapon", "support", "special"]
const SLOT_NAMES := {
	"main": "Main Weapon",
	"weapon": "Weapon",
	"support": "Support",
	"special": "Special",
}

## In-mission levels run 1..MAX_LEVEL. Reaching FORK_LEVEL asks the player to choose a fork.
const MAX_LEVEL := 5
const FORK_LEVEL := 3

## R&D grade ("Mk") limits how high a tech can be levelled inside a mission.
## Mk 0 means not unlocked yet.
const MK_LEVEL_CAP := [0, 3, 4, 5]
const MAX_MK := 3
## Blueprints needed to reach each Mk: index 0 is the unlock (Mk 1).
const BLUEPRINTS_FOR_MK := [3, 6, 10]
## Each Mk above 1 adds this much damage to the tech, even before it is levelled in a mission.
const MK_DAMAGE_BONUS := 0.12

## Element colours tint shots and icons so each family reads at a glance.
const ELEMENT_COLORS := {
	"energy": Color(0.45, 0.9, 1.0),
	"kinetic": Color(1.0, 0.86, 0.55),
	"explosive": Color(1.0, 0.55, 0.25),
	"mawjig": Color(0.85, 0.5, 1.0),
	"none": Color(0.8, 0.9, 1.0),
}

const TECH := {
	# ---- Main weapons: fire on their own from the moment the mission starts.
	"pulse_driver": {
		"name": "Pulse Driver", "slot": "main", "element": "energy",
		"text": "Rapid energy bolts. A blank slate that grows into something wild.",
		"levels": ["Rapid bolts", "Twin bolts", "Fork", "Triple fan", "Overcharged bolts"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Ricochet Rounds", "text": "Bolts bounce from enemy to enemy, hitting harder each time, and shots that miss glance back in from somewhere out of view instead of flying away."},
			"b": {"name": "Splitfire", "text": "Every bolt bursts into a fan of smaller bolts mid-flight."},
		},
	},
	"thunder_lance": {
		"name": "Thunder Lance", "slot": "main", "element": "energy",
		"text": "A rail of lightning that punches through every enemy in a line.",
		"levels": ["Piercing rail", "Faster charge", "Fork", "Heavier rail", "Storm-forged rail"],
		"blueprint_from": ["corridor", "planet"],
		"forks": {
			"a": {"name": "Chain Storm", "text": "Every hit arcs lightning into the enemies around it."},
			"b": {"name": "Twin Rails", "text": "Fires two rails in a V, then three."},
		},
	},
	"hex_repeater": {
		"name": "Hex Repeater", "slot": "main", "element": "mawjig",
		"text": "Mawjig orbs that hunt down enemies on their own.",
		"levels": ["Seeking orbs", "Faster orbs", "Fork", "Third orb", "Deep hex"],
		"blueprint_from": ["dungeon", "planet"],
		"forks": {
			"a": {"name": "Hexplosion", "text": "Hexed enemies explode when they die, and the blast spreads the hex."},
			"b": {"name": "Hex Swarm", "text": "Orbs shatter into three smaller hunters on impact."},
		},
	},
	# ---- Weapons: start offline, brought online by level-ups and Salvage Crates.
	"arc_blade": {
		"name": "Arc Blade", "slot": "weapon", "element": "energy",
		"text": "A huge energy sword sweeps around the frame and cuts bullets out of the air.",
		"levels": ["Blade sweep", "Wider sweep", "Fork", "Longer blade", "Master's edge"],
		"blueprint_from": ["dungeon", "planet"],
		"forks": {
			"a": {"name": "Phantom Edge", "text": "Each sweep throws a crescent of light that cuts through everything."},
			"b": {"name": "Whirlwind", "text": "Full 360° spins, two at a time."},
		},
	},
	"swarm_pods": {
		"name": "Swarm Pods", "slot": "weapon", "element": "explosive",
		"text": "Shoulder pods launch salvos of homing micro-missiles.",
		"levels": ["Missile salvo", "Bigger salvo", "Fork", "Bigger blasts", "Saturation salvo"],
		"blueprint_from": ["star_cluster", "planet"],
		"forks": {
			"a": {"name": "Cluster Warheads", "text": "Each blast scatters bomblets that blow up again."},
			"b": {"name": "Hunter Swarm", "text": "Twice the missiles, and they hunt a new target if theirs dies."},
		},
	},
	"orbital_halo": {
		"name": "Orbital Halo", "slot": "weapon", "element": "kinetic",
		"text": "Saw blades orbit the frame, shredding enemies and bullets they touch.",
		"levels": ["Two saws", "Three saws", "Fork", "Four saws", "Diamond edges"],
		"blueprint_from": ["dungeon", "star_cluster"],
		"forks": {
			"a": {"name": "Supernova Rings", "text": "The halo blasts outward across the screen, then snaps back."},
			"b": {"name": "Saw Storm", "text": "Double the saws, spinning twice as fast."},
		},
	},
	"starfall": {
		"name": "Starfall", "slot": "weapon", "element": "mawjig",
		"text": "Calls Mawjig meteors down where nearby enemies are heading. Each one blasts everything it lands on.",
		"levels": ["One meteor", "Two meteors", "Fork", "Three meteors", "Cataclysm"],
		"blueprint_from": ["planet", "corridor"],
		"forks": {
			"a": {"name": "Comet Trail", "text": "Meteors leave a flaming trail that burns anything in it."},
			"b": {"name": "Meteor Shower", "text": "Many smaller meteors rain across the field."},
		},
	},
	# ---- Support: passive systems that change how the frame plays.
	"mirror_aegis": {
		"name": "Mirror Aegis", "slot": "support", "element": "energy",
		"text": "A mirror bubble flickers on and fires enemy bullets back at them.",
		"levels": ["Mirror pulse", "Longer pulse", "Fork", "Faster pulse", "Perfect mirror"],
		"blueprint_from": ["star_cluster", "dungeon"],
		"forks": {
			"a": {"name": "Prism", "text": "Every reflected bullet splits into three."},
			"b": {"name": "Bastion", "text": "A mirror arc always guards the way you face."},
		},
	},
	"graze_engine": {
		"name": "Graze Engine", "slot": "support", "element": "kinetic",
		"text": "Bullets that barely miss you charge Overdrive: double fire rate and a golden glow.",
		"levels": ["Graze charge", "Faster charge", "Fork", "Longer Overdrive", "Adrenaline"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Adrenal Mend", "text": "Grazes restore your shield, and Overdrive patches armor."},
			"b": {"name": "Rage Engine", "text": "During Overdrive, afterimages burst into rings of bolts."},
		},
	},
	"overheat_core": {
		"name": "Overheat Core", "slot": "support", "element": "explosive",
		"text": "Firing builds heat. Running hot fires faster, and maxing out vents a shockwave.",
		"levels": ["Heat vent", "Bigger vent", "Fork", "Hotter core", "Reactor"],
		"blueprint_from": ["planet", "dungeon"],
		"forks": {
			"a": {"name": "Meltdown", "text": "Vents leave a ring of fire behind."},
			"b": {"name": "Chain Vent", "text": "Each vent goes off twice, the second one bigger."},
		},
	},
	"option_pods": {
		"name": "Option Pods", "slot": "support", "element": "kinetic",
		"text": "Glowing pods trail your path and fire copies of your main weapon.",
		"levels": ["Two pods", "Stronger copies", "Fork", "Third pod", "Perfect copies"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Formation", "text": "Pods lock beside you in a firing line and hit harder."},
			"b": {"name": "Hunter Pods", "text": "Pods break away to circle the nearest enemy and fire from there."},
		},
	},
	"soul_lantern": {
		"name": "Soul Lantern", "slot": "support", "element": "mawjig",
		"text": "Enemies you destroy leave Mawjig wisps that circle you. Each wisp swallows one enemy bullet.",
		"levels": ["Two wisps", "Three wisps", "Fork", "Four wisps", "Soul storm"],
		"blueprint_from": ["planet", "dungeon"],
		"forks": {
			"a": {"name": "Will-o'-Wisps", "text": "Wisps dart out at enemies on their own."},
			"b": {"name": "Lantern Ward", "text": "Three more wisps, and every swallowed bullet restores shield."},
		},
	},
	# ---- Specials: fired with the special button, on a cooldown.
	"nova_bomb": {
		"name": "Nova Bomb", "slot": "special", "element": "explosive",
		"text": "Your reactor erupts in a white-hot nova that erases every bullet on screen and blasts everything around you.",
		"levels": ["Nova", "Faster recharge", "Fork", "Bigger nova", "Star-killer"],
		"blueprint_from": ["star_cluster", "dungeon"],
		"forks": {
			"a": {"name": "Black Hole", "text": "Drags enemies into one point, then detonates."},
			"b": {"name": "Twin Nova", "text": "Holds two charges."},
		},
	},
	"time_brake": {
		"name": "Time Brake", "slot": "special", "element": "mawjig",
		"text": "Hits the brakes on time: for a few seconds everything but you crawls at a quarter speed.",
		"levels": ["Slow time", "Faster recharge", "Fork", "Longer brake", "Frozen moment"],
		"blueprint_from": ["corridor", "dungeon"],
		"forks": {
			"a": {"name": "Stasis Shatter", "text": "When time resumes, frozen bullets shatter into Data Shards."},
			"b": {"name": "Overclock Brake", "text": "Longer, and your weapons fire faster while it lasts."},
		},
	},
	"ion_cannon": {
		"name": "Ion Cannon", "slot": "special", "element": "energy",
		"text": "A beam the length of the battlefield that burns through everything and erases bullets in its path.",
		"levels": ["Ion beam", "Faster recharge", "Fork", "Wider beam", "Planet-cutter"],
		"blueprint_from": ["corridor", "planet"],
		"forks": {
			"a": {"name": "Sweeping Beam", "text": "The beam sweeps across the field as it fires."},
			"b": {"name": "Twin Ion", "text": "Two beams fan out from your frame."},
		},
	},
	"thruster_explosion": {
		"name": "Thruster Explosion", "slot": "special", "element": "kinetic",
		"text": "Your thrusters detonate and hurl you forward, untouchable, blowing up everything along the way.",
		"levels": ["Blast dash", "Faster recharge", "Fork", "Longer dash", "Supernova burn"],
		"blueprint_from": ["star_cluster", "planet"],
		"forks": {
			"a": {"name": "Afterburner", "text": "The dash leaves a trail of fire."},
			"b": {"name": "Shockwave", "text": "The dash ends in a shockwave that wipes nearby bullets."},
		},
	},
}

## Starting kit: interesting from minute one (GDD 1C). Starters are unlocked at Mk 1.
## Two slots start empty on purpose: Mirror Aegis and Swarm Pods are earned at the lesson planets (GDD 9C).
const STARTING_LOADOUT := ["pulse_driver", "arc_blade", "", "", "nova_bomb"]
const STARTING_UNLOCKS := ["pulse_driver", "arc_blade", "nova_bomb"]


static func get_tech(tech_id: String) -> Dictionary:
	return TECH.get(tech_id, {})


static func ids_for_slot(slot: String) -> Array:
	var result := []
	for tech_id in TECH:
		if TECH[tech_id]["slot"] == slot:
			result.append(tech_id)
	return result


static func element_color(tech_id: String) -> Color:
	return ELEMENT_COLORS.get(get_tech(tech_id).get("element", "none"), ELEMENT_COLORS["none"])


static func fork_name(tech_id: String, fork: String) -> String:
	if fork == "":
		return ""
	return TECH[tech_id]["forks"][fork]["name"]


## Text for the upgrade card that takes a tech from level-1 to level.
static func level_text(tech_id: String, level: int) -> String:
	var levels: Array = TECH[tech_id]["levels"]
	return levels[clampi(level - 1, 0, levels.size() - 1)]


static func blueprints_for_next_mk(current_mk: int) -> int:
	if current_mk >= MAX_MK:
		return 0
	return BLUEPRINTS_FOR_MK[current_mk]
