class_name UpgradeData
## Mission-only field upgrades and fusions. Pure data; UpgradeOffers builds the level-up cards from it.

## Field upgrades last for the current mission only. "limit" caps how many times one can be taken.
const FIELD := {
	"echo_chamber": {
		"name": "Echo Chamber", "limit": 2, "icon": "echo", "element": "energy",
		"text": "Every 4th main weapon volley fires twice. Taking it again makes it every 3rd.",
	},
	"vampiric_plating": {
		"name": "Vampiric Plating", "limit": 2, "icon": "vampire", "element": "mawjig",
		"text": "Every kill patches a little armor.",
	},
	"last_stand": {
		"name": "Last Stand", "limit": 1, "icon": "last_stand", "element": "explosive",
		"text": "Below a third of your armor, deal +60% damage and burn with a red aura.",
	},
	"shrapnel_skin": {
		"name": "Shrapnel Skin", "limit": 2, "icon": "shrapnel", "element": "kinetic",
		"text": "Getting hit blasts a ring of shrapnel out of your hull.",
	},
	"overclocked_servos": {
		"name": "Overclocked Servos", "limit": 2, "icon": "servos", "element": "kinetic",
		"text": "Move 15% faster, and ramming enemies hurts them more than you.",
	},
	"tractor_beam": {
		"name": "Tractor Beam", "limit": 1, "icon": "magnet", "element": "kinetic",
		"text": "Data Shards and drops fly to you from across the field.",
	},
	"field_repair": {
		"name": "Field Repair", "limit": 2, "icon": "repair", "element": "",
		"text": "Repair 40% of your armor right now.",
	},
	"lucky_salvage": {
		"name": "Lucky Salvage", "limit": 1, "icon": "crate", "element": "",
		"text": "Salvage Crate reels always land on at least 3 upgrades.",
	},
}

## Risky cards: big power with a real cost. Taking one is a bet on how you play (GDD 1A, 1C).
const RISKY := ["glass_reactor", "adrenaline_junkie", "blood_pact"]
const RISKY_FIELD := {
	"glass_reactor": {
		"name": "Glass Reactor", "limit": 1, "icon": "last_stand", "element": "explosive",
		"text": "+50% damage. Your shield is gone for the rest of the mission.",
	},
	"adrenaline_junkie": {
		"name": "Adrenaline Junkie", "limit": 1, "icon": "overclocked_servos", "element": "kinetic",
		"text": "Bullets that barely miss you give XP. Enemy bullets fly 15% faster.",
	},
	"blood_pact": {
		"name": "Blood Pact", "limit": 1, "icon": "vampiric_plating", "element": "mawjig",
		"text": "Every kill repairs armor. Your shield never recharges.",
	},
}

## Resonance: levels of online tech (and field upgrades, worth 2) of one element add up. Reaching a
## threshold unlocks that element's next tier, so every pick is also a choice of direction.
const RESONANCE_THRESHOLDS := [5, 10, 15]
const FIELD_RESONANCE_POINTS := 2
const ELEMENTS := ["energy", "explosive", "kinetic", "mawjig"]
const RESONANCE := {
	"energy": {"name": "Energy", "tiers": [
		["Static Charge", "Every 6th hit arcs lightning to another enemy."],
		["Capacitor Shields", "Your shield recharges 60% faster."],
		["Storm Front", "Every 3rd hit arcs, and the lightning chains twice."]]},
	"explosive": {"name": "Explosive", "tiers": [
		["Volatile", "Kills have a 1 in 4 chance to explode."],
		["Big Bang", "Every explosion is a third bigger."],
		["Scorched Earth", "Explosions leave the ground burning."]]},
	"kinetic": {"name": "Kinetic", "tiers": [
		["Penetrator", "Shots punch through one extra enemy."],
		["Momentum", "Shots that have flown a while hit 40% harder."],
		["Railstorm", "Every 2 s a slug tears through the nearest enemy and everything behind it."]]},
	"mawjig": {"name": "Mawjig", "tiers": [
		["Hex Touch", "Hits hex enemies. Hexed enemies take 20% more damage."],
		["Contagion", "Hexed enemies burst when they die and hex everything nearby."],
		["Doom Bell", "Every 8 s, meteors fall on up to three hexed enemies."]]},
}

## Fusions: two pieces of tech, both at max level, merge into something new (GDD 7F proposal).
## The fusion keeps both techs working and adds the "effect" flag WeaponSystem reads.
const FUSIONS := {
	"reflex_blade": {
		"name": "Reflex Blade", "needs": ["arc_blade", "mirror_aegis"],
		"text": "Blade sweeps catch bullets and hurl them back as homing blades.",
	},
	"armageddon_protocol": {
		"name": "Armageddon Protocol", "needs": ["swarm_pods", "starfall"],
		"text": "Missiles call down meteors, and meteors launch missiles.",
	},
	"phoenix_driver": {
		"name": "Phoenix Driver", "needs": ["pulse_driver", "graze_engine"],
		"text": "Bolts become piercing firebirds, and Overdrive comes twice as often.",
	},
	"supernova_core": {
		"name": "Supernova Core", "needs": ["overheat_core", "nova_bomb"],
		"text": "Every heat vent is a full Nova that wipes the screen of bullets.",
	},
	"storm_halo": {
		"name": "Storm Halo", "needs": ["orbital_halo", "thunder_lance"],
		"text": "Halo saws crackle with lightning that leaps to nearby enemies.",
	},
	"event_horizon": {
		"name": "Event Horizon", "needs": ["hex_repeater", "time_brake"],
		"text": "Hex orbs drag enemy bullets into themselves and devour them.",
	},
}

## Salvage Crate reel: how many upgrades it lands on, and how often (weights).
const CRATE_REEL := [[1, 60], [3, 30], [5, 10]]
## Rerolls per mission on the level-up screen.
const REROLLS := 2


static func field_upgrade(upgrade_id: String) -> Dictionary:
	if FIELD.has(upgrade_id):
		return FIELD[upgrade_id]
	return RISKY_FIELD.get(upgrade_id, {})
