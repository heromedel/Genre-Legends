class_name TechData
## Every piece of tech the frame can equip: its slot, what each level adds, and its two forks.
## Pure data. WeaponSystem reads it to decide how tech behaves; nothing here holds game state.
## GDD 7A–7F: blueprints unlock and upgrade tech, it is equipped in a limited loadout,
## it starts offline in a mission (except the main weapon) and is levelled up in the mission,
## and at the fork level the player picks one of two very different behaviours.

## Loadout slots, in order. Index 0 is always the main weapon, online at mission start like the plating (the
## frame's outer armour is worn, not switched on). The Generator slot holds the parts that keep you alive, so
## that kind of defence is one choice rather than a stack (GDD 13J, 13K).
const SLOTS := ["main", "weapon", "weapon", "support", "special", "generator", "plating"]
const SLOT_NAMES := {
	"main": "Main Weapon",
	"weapon": "Weapon",
	"support": "Support",
	"special": "Special",
	"generator": "Generator",
	"plating": "Plating",
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
		"name": "Pulse Driver", "slot": "main", "element": "energy", "weight": 1, "draw": 1,
		"text": "Rapid energy bolts. Its forks make kills arc on through a crowd, or bolts burst into fans.",
		"levels": ["Rapid bolts", "Twin bolts", "Fork", "Triple fan", "Overcharged bolts: faster fire"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Chain Bolts", "text": "A bolt that kills arcs as lightning to the next enemy, and keeps going while it keeps killing: twice, three times at level 5."},
			"b": {"name": "Splitfire", "text": "Every bolt bursts into a fan of smaller bolts mid-flight."},
		},
	},
	"thunder_lance": {
		"name": "Thunder Lance", "slot": "main", "element": "energy", "weight": 1, "draw": 3,
		"text": "A rail of lightning that punches through every enemy in a line.",
		"levels": ["Piercing rail", "Faster rails", "Fork", "Heavier rail", "Storm-forged rail: harder, faster rails"],
		"blueprint_from": ["corridor", "planet"],
		"forks": {
			"a": {"name": "Chain Storm", "text": "Every hit arcs lightning into the enemies around it."},
			"b": {"name": "Twin Rails", "text": "Fires two rails in a V. Three at level 5."},
		},
	},
	"hex_repeater": {
		"name": "Hex Repeater", "slot": "main", "element": "mawjig", "weight": 1, "draw": 2,
		"text": "Mawjig orbs that hunt down enemies on their own.",
		"levels": ["Seeking orbs", "Faster orbs", "Fork", "Third orb", "Deep hex: orbs hit harder"],
		"blueprint_from": ["dungeon", "planet"],
		"forks": {
			"a": {"name": "Hexplosion", "text": "Hexed enemies explode when they die, and the blast spreads the hex."},
			"b": {"name": "Hex Swarm", "text": "Orbs shatter into three smaller hunters on impact."},
		},
	},
	# ---- Weapons: start offline, brought online by level-ups and Salvage Crates.
	"arc_blade": {
		"name": "Arc Blade", "slot": "generator", "element": "energy", "weight": 1, "draw": 2,
		"text": "A huge energy sword sweeps around the frame and cuts bullets out of the air.",
		"levels": ["Blade sweep", "Longer reach", "Fork", "Wider sweep", "Master's edge: longer, harder sweeps"],
		"blueprint_from": ["dungeon", "planet"],
		"forks": {
			"a": {"name": "Phantom Edge", "text": "Each sweep throws a crescent of light that cuts through everything."},
			"b": {"name": "Whirlwind", "text": "Full 360° spins, two at a time."},
		},
	},
	"swarm_pods": {
		"name": "Swarm Pods", "slot": "weapon", "element": "explosive", "weight": 3, "draw": 0,
		"text": "Shoulder pods launch salvos of homing micro-missiles.",
		"levels": ["Missile salvo", "Bigger salvo", "Fork", "Bigger blasts", "Saturation salvo: eight missiles"],
		"blueprint_from": ["star_cluster", "planet"],
		"forks": {
			"a": {"name": "Cluster Warheads", "text": "Each blast scatters bomblets that blow up again."},
			"b": {"name": "Hunter Swarm", "text": "Twice the missiles, and they hunt a new target if theirs dies."},
		},
	},
	"orbital_halo": {
		"name": "Orbital Halo", "slot": "weapon", "element": "kinetic", "weight": 2, "draw": 1,
		"text": "Saw blades orbit the frame, shredding enemies and bullets they touch.",
		"levels": ["Two saws", "Three saws", "Fork", "Four saws", "Diamond edges: saws cut harder"],
		"blueprint_from": ["dungeon", "star_cluster"],
		"forks": {
			"a": {"name": "Supernova Rings", "text": "Every few seconds the halo flares out wide, then snaps back."},
			"b": {"name": "Saw Storm", "text": "Double the saws, spinning twice as fast."},
		},
	},
	"starfall": {
		"name": "Starfall", "slot": "weapon", "element": "mawjig", "weight": 1, "draw": 3,
		"text": "Calls Mawjig meteors down where nearby enemies are heading. Each one blasts everything it lands on.",
		"levels": ["One meteor", "Two meteors", "Fork", "Three meteors", "Cataclysm: harder, faster meteors"],
		"blueprint_from": ["planet", "corridor"],
		"forks": {
			"a": {"name": "Comet Trail", "text": "Meteors leave a flaming trail that burns anything in it."},
			"b": {"name": "Meteor Shower", "text": "Three extra meteors per volley, smaller and weaker."},
		},
	},
	# ---- Support: passive systems that change how the frame plays.
	"mirror_aegis": {
		"name": "Mirror Aegis", "slot": "generator", "element": "energy", "weight": 1, "draw": 3,
		"text": "A mirror bubble flickers on and fires enemy bullets back at them.",
		"levels": ["Mirror pulse", "Longer pulse", "Fork", "Faster pulse", "Perfect mirror: longer, more frequent pulses"],
		"blueprint_from": ["star_cluster", "dungeon"],
		"forks": {
			"a": {"name": "Prism", "text": "Every reflected bullet splits into three."},
			"b": {"name": "Bastion", "text": "A mirror arc always guards the way you face."},
		},
	},
	"graze_engine": {
		"name": "Graze Engine", "slot": "support", "element": "kinetic", "weight": 1, "draw": 0,
		"text": "Bullets that barely miss you charge Overdrive: nearly double fire rate and a golden glow.",
		"levels": ["Graze charge", "Faster charge", "Fork", "Longer Overdrive", "Adrenaline: Overdrive charges faster, lasts longer"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Adrenal Mend", "text": "Every Overdrive repairs 5 Armor."},
			"b": {"name": "Rage Engine", "text": "During Overdrive, afterimages burst into rings of bolts."},
		},
	},
	"overheat_core": {
		"name": "Overheat Core", "slot": "support", "element": "explosive", "weight": 2, "draw": 0,
		"text": "Main weapon fire heats the frame. Running hot (above 70%) you fire 25% faster, and every time the frame vents it blasts a shockwave that hits enemies and wipes nearby bullets.",
		"levels": ["Heat vent", "Bigger vent", "Fork", "Hotter core: vents more often", "Reactor: vents more often and wider"],
		"blueprint_from": ["planet", "dungeon"],
		"forks": {
			"a": {"name": "Meltdown", "text": "Vents leave a ring of fire behind."},
			"b": {"name": "Chain Vent", "text": "Each vent goes off twice, the second one bigger."},
		},
	},
	"option_pods": {
		"name": "Drone Pods", "slot": "support", "element": "kinetic", "weight": 2, "draw": 1,
		"text": "Two pods trail your path and fire weaker copies of your main weapon.",
		"levels": ["Two pods", "Stronger copies", "Fork", "Third pod", "Strongest copies"],
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {
			"a": {"name": "Formation", "text": "Pods lock beside you in a firing line and hit harder."},
			"b": {"name": "Hunter Pods", "text": "Pods break away to circle the nearest enemy and fire from there."},
		},
	},
	# Power parts run the frame itself, so they're running from the start of a mission like the plating (GDD 21A).
	"coolant_loop": {
		"name": "Coolant Loop", "slot": "support", "element": "none", "weight": 2, "draw": 0,
		"text": "Pumps coolant through the frame: one pip past your Mawjig Output runs without heat. Running from the start of a mission.",
		"levels": ["Cools one pip", "Vents trip for 2 s, not 3", "Fork", "Cools one and a half pips", "Cools two pips"],
		"starts_online": true,
		"blueprint_from": ["corridor", "planet"],
		"forks": {
			"a": {"name": "Cryo Purge", "text": "Every vent blasts out a freezing ring: bullets near you slow to a crawl."},
			"b": {"name": "Flash Cooling", "text": "Every kill sheds 2% heat."},
		},
	},
	"aux_generator": {
		"name": "Auxiliary Generator", "slot": "support", "element": "none", "weight": 3, "draw": 0,
		"text": "A second Mawjig generator bolted to the frame: +3 Mawjig Output. Running from the start of a mission.",
		"levels": ["+3 Output", "+4 Output", "Fork", "+5 Output", "+6 Output"],
		"starts_online": true,
		"blueprint_from": ["star_cluster", "dungeon"],
		"forks": {
			"a": {"name": "Surge Cell", "text": "Every pip of Output you aren't using gives your weapons 3% more damage."},
			"b": {"name": "Vent Tap", "text": "Every time the frame vents, you go into Overdrive for 3 s."},
		},
	},
	"soul_lantern": {
		"name": "Soul Lantern", "slot": "generator", "element": "mawjig", "weight": 1, "draw": 2,
		"text": "Enemies you destroy leave Mawjig wisps that circle you. Each wisp swallows one enemy bullet.",
		"levels": ["Two wisps", "Three wisps", "Fork", "Five wisps", "Soul storm: six wisps"],
		"blueprint_from": ["planet", "dungeon"],
		"forks": {
			"a": {"name": "Will-o'-Wisps", "text": "Wisps dart out at enemies on their own."},
			"b": {"name": "Lantern Ward", "text": "Three more wisps, and when a hit gets through, a wisp throws itself in front and takes half."},
		},
	},
	# ---- Generator: what keeps you alive (GDD 13K). Arc Blade, Mirror Aegis and Soul Lantern live here too.
	"shield_generator": {
		"name": "Shield Generator", "slot": "generator", "element": "energy", "weight": 1, "draw": 3,
		"text": "A bubble that takes one hit of any size, then recharges.",
		"levels": ["One charge, back 8 s after it breaks", "Back in 7 s", "Fork", "Back in 5 s", "Hardened bubble: back in 4 s"],
		"blueprint_from": ["planet", "dungeon", "star_cluster"],
		"forks": {
			"a": {"name": "Twin Cell", "text": "Holds two charges."},
			"b": {"name": "Breaker Pulse", "text": "A breaking bubble blasts the bullets around you away."},
		},
	},
	# ---- Plating: the frame's outer armour, worn from the start of every mission (GDD 13L).
	"dsp1_plate": {
		"name": "DSP-1 Drop Plate", "slot": "plating", "element": "none", "weight": 2, "draw": 0,
		"text": "Dropship Standard Plating, version 1: the armor your Dropship fits to every frame. Each level adds Armor.",
		"levels": ["Standard plating", "+10 Armor", "Fork", "+10 Armor", "+10 Armor"],
		"starts_online": true, "plate_armor": 0.0, "armor_per_level": 10.0,
		"blueprint_from": [], "source": "Printed by your Dropship: every frame has it.",
		"forks": {
			"a": {"name": "Spaced Armor", "text": "+10 Armor, and hits of 20 or more do 5 less."},
			"b": {"name": "Field Patches", "text": "+10 Armor, and every repair you pick up restores 5 more."},
		},
	},
	# Basic plates trade Armor against weight and speed (GDD 13L, 21H); they come from ordinary planets.
	"qrf_shell": {
		"name": "QRF Shell", "slot": "plating", "element": "none", "weight": 1, "draw": 0,
		"text": "Quick Reaction Force plating: first in, fast. 10 less Armor, but you move 10% faster. Each level, 5% faster still.",
		"levels": ["10% faster", "15% faster", "20% faster", "25% faster", "30% faster"],
		"starts_online": true, "plate_armor": -10.0, "plate_speed": 0.10, "speed_per_level": 0.05,
		"blueprint_from": ["star_cluster", "corridor"],
		"forks": {},
	},
	"jig_weave_plate": {
		"name": "Jig-Weave Composite", "slot": "plating", "element": "none", "weight": 3, "draw": 0,
		"text": "Armor woven through with Jigawatt-powered fibers. +15 Armor, and it shrugs off one light hit (10 or less), then needs 20 s to recover. Each level, 3 s sooner.",
		"levels": ["A light hit every 20 s", "Every 17 s", "Every 14 s", "Every 11 s", "Every 8 s"],
		"starts_online": true, "plate_armor": 15.0,
		"blueprint_from": ["star_cluster", "planet", "dungeon"],
		"forks": {},
	},
	"lunarium_plate": {
		"name": "Lunarium Bulk Plate", "slot": "plating", "element": "none", "weight": 4, "draw": 0,
		"text": "A slab of lunarium wonder-alloy. +30 Armor, 10% slower. It work-hardens: every hit you survive adds 1 max Armor for the mission, up to 5 per level.",
		"levels": ["Hardens up to +5", "Up to +10", "Up to +15", "Up to +20", "Up to +25"],
		"starts_online": true, "plate_armor": 30.0, "plate_speed": -0.10,
		"blueprint_from": ["corridor", "planet", "dungeon"],
		"forks": {},
	},
	# Uncommon plates: each is the prize of the boss it's named after, paid only when that boss falls (GDD 21G).
	"mirrorwork_plate": {
		"name": "Mirrorwork Half Plate", "slot": "plating", "element": "none", "weight": 2, "draw": 0,
		"text": "Cut from the Mirror Dreadnought's hull. +10 Armor, and lasers and beams do half. From level 3, a beam that hits you fires a mirror bolt at the nearest enemy.",
		"levels": ["Beams do half", "Beams do 40%", "Beams fire a mirror bolt at the nearest enemy", "Beams do 30%", "Beams do a quarter"],
		"starts_online": true, "plate_armor": 10.0, "from_boss": "mirror_dreadnought",
		"blueprint_from": [],
		"forks": {},
	},
	"crusher_plate": {
		"name": "Crusher-Rated Plate", "slot": "plating", "element": "none", "weight": 3, "draw": 0,
		"text": "Rated to survive the Crusher Gate. +10 Armor, and blasts and shockwaves do half. From level 3, a blast or shockwave that hits you clears the bullets around you.",
		"levels": ["Blasts do half", "Blasts do 40%", "Blasts clear bullets around you", "Blasts do 30%", "Blasts do a quarter"],
		"starts_online": true, "plate_armor": 10.0, "from_boss": "crusher_gate",
		"blueprint_from": [],
		"forks": {},
	},
	"arc_lined_plate": {
		"name": "Arc-Lined Plate", "slot": "plating", "element": "none", "weight": 1, "draw": 1,
		"text": "Plate lined with live current, stripped from the Storm Colossus. +20 Armor for very little weight, but it draws 1 Mawjig Output. Each level, +5 Armor.",
		"levels": ["+20 Armor", "+25 Armor", "+30 Armor", "+35 Armor", "+40 Armor"],
		"starts_online": true, "plate_armor": 20.0, "armor_per_level": 5.0, "from_boss": "storm_colossus",
		"blueprint_from": [],
		"forks": {},
	},
	# Rare plates: strange, game-changing, and themed-branch prizes (GDD 21G).
	"jig_phase_plate": {
		"name": "Jig Phase Plate", "slot": "plating", "element": "none", "weight": 2, "draw": 0,
		"text": "Salvaged from a Jig Phase Drive: hits phase partly out of this dimension. Half of every hit is held off for 3 s. If you're hit again in that time, the held part lands too; if not, it fades away. Each level, 5% more is held off.",
		"levels": ["Half held off", "55% held off", "60% held off", "65% held off", "70% held off"],
		"starts_online": true, "plate_armor": 0.0,
		"blueprint_from": [], "source": "Prize at the end of the Undervault.",
		"forks": {},
	},
	"last_legend_plate": {
		"name": "Last Legend Plate", "slot": "plating", "element": "none", "weight": 2, "draw": 0,
		"text": "Worn by the last of the old Guardians. 10 less Armor, but below a third of your Armor your weapons fire 30% faster. Each level, 5% faster.",
		"levels": ["30% faster when low", "35% faster", "40% faster", "45% faster", "50% faster"],
		"starts_online": true, "plate_armor": -10.0,
		"blueprint_from": [], "source": "Prize at the end of the Tempest Run.",
		"forks": {},
	},
	# ---- Specials: fired with the special button, on a cooldown.
	"nova_bomb": {
		"name": "Nova Bomb", "slot": "special", "element": "explosive", "weight": 2, "draw": 0,
		"text": "Your reactor erupts in a white-hot nova that erases every bullet on screen and blasts everything around you.",
		"levels": ["Nova", "Faster recharge", "Fork", "Bigger nova", "Star-killer: harder blast, faster recharge"],
		"blueprint_from": ["star_cluster", "dungeon"],
		"forks": {
			"a": {"name": "Black Hole", "text": "Drags enemies into one point, then detonates."},
			"b": {"name": "Twin Nova", "text": "Holds two charges."},
		},
	},
	"time_brake": {
		"name": "Time Brake", "slot": "special", "element": "mawjig", "weight": 1, "draw": 3,
		"text": "Hits the brakes on time: for a few seconds everything but you crawls at a quarter speed.",
		"levels": ["Slow time", "Faster recharge", "Fork", "Longer brake", "Longest brake"],
		"blueprint_from": ["corridor", "dungeon"],
		"forks": {
			"a": {"name": "Stasis Shatter", "text": "When time resumes, slowed bullets shatter. Every two leave a Data Shard."},
			"b": {"name": "Overclock Brake", "text": "Longer, and your weapons fire faster while it lasts."},
		},
	},
	"ion_cannon": {
		"name": "Ion Cannon", "slot": "special", "element": "energy", "weight": 2, "draw": 3,
		"text": "A beam the length of the battlefield that burns through everything and erases bullets in its path.",
		"levels": ["Ion beam", "Faster recharge", "Fork", "Wider beam", "Planet-cutter: the beam lasts longer"],
		"blueprint_from": ["corridor", "planet"],
		"forks": {
			"a": {"name": "Sweeping Beam", "text": "The beam sweeps across the field as it fires."},
			"b": {"name": "Twin Ion", "text": "Two beams fan out from your frame."},
		},
	},
	"thruster_explosion": {
		"name": "Thruster Explosion", "slot": "special", "element": "kinetic", "weight": 2, "draw": 0,
		"text": "Your thrusters detonate and hurl you forward, untouchable, blowing up everything along the way.",
		"levels": ["Blast dash", "Faster recharge", "Fork", "Longer dash", "Supernova burn: harder blast, faster recharge"],
		"blueprint_from": ["star_cluster", "planet"],
		"forks": {
			"a": {"name": "Afterburner", "text": "The dash leaves a trail of fire."},
			"b": {"name": "Shockwave", "text": "The dash ends in a shockwave that hits enemies and wipes bullets nearby."},
		},
	},
}

## Starting kit: interesting from minute one (GDD 1C). Starters are unlocked at Mk 1. Both weapon slots and the
## support slot start empty: the lesson planets hand out the Shield Generator and Swarm Pods (GDD 9C, 13T), and
## everything else is found. The Arc Blade starts in the Generator slot, so the first frame has no shield (13B).
const STARTING_LOADOUT := ["pulse_driver", "", "", "", "nova_bomb", "arc_blade", "dsp1_plate"]
const STARTING_UNLOCKS := ["pulse_driver", "arc_blade", "nova_bomb", "dsp1_plate"]
## Starters that begin above Mk 1: your Dropship prints the DSP-1, so it's fully known from the start.
const STARTING_MK := {"dsp1_plate": 3}


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


## Whether reaching the fork level asks for a choice. Plates level in their own way, with no forks (GDD 13M).
static func has_forks(tech_id: String) -> bool:
	return not get_tech(tech_id).get("forks", {}).is_empty()


## Load and Mawjig Output (GDD 21A–21C): every part weighs something, powered parts draw Output.
static func weight_of(tech_id: String) -> int:
	return int(get_tech(tech_id).get("weight", 0))


static func draw_of(tech_id: String) -> int:
	return int(get_tech(tech_id).get("draw", 0))


## What a whole loadout weighs, and what it draws with everything online.
static func loadout_weight(loadout: Array) -> int:
	var total := 0
	for tech_id in loadout:
		total += weight_of(tech_id)
	return total


static func loadout_draw(loadout: Array) -> int:
	var total := 0
	for tech_id in loadout:
		total += draw_of(tech_id)
	return total


## Output the loadout itself adds: an Auxiliary Generator, at its first level.
static func loadout_output_bonus(loadout: Array) -> int:
	return 3 if loadout.has("aux_generator") else 0


## "Weight 2, draws 3": what a part costs in Load and Output, for the Hangar and R&D.
static func power_text(tech_id: String) -> String:
	if tech_id == "aux_generator":
		return "Weight %d, adds 3 Output" % weight_of(tech_id)
	var draw := draw_of(tech_id)
	return "Weight %d, %s" % [weight_of(tech_id), "draws %d" % draw if draw > 0 else "unpowered"]


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
