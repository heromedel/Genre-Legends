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
		"name": "Tractor Beam", "limit": 2, "icon": "magnet", "element": "kinetic",
		"text": "Beams of light reel in Data Shards and drops from three times as far. Taking it again reaches further.",
	},
	"field_repair": {
		"name": "Field Repair", "limit": 2, "icon": "repair", "element": "",
		"text": "Repair 40% of your armor right now.",
	},
	"lucky_salvage": {
		"name": "Lucky Salvage", "limit": 1, "icon": "crate", "element": "",
		"text": "Crates have improved odds: always at least 2 upgrades.",
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
		["Wildfire", "Explosions leave flames that keep burning."]]},
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
	"starbreaker": {
		"name": "Starbreaker", "needs": ["ion_cannon", "option_pods"],
		"text": "Every option pod fires its own ion beam alongside yours.",
	},
	"wraith_drive": {
		"name": "Wraith Drive", "needs": ["thruster_explosion", "soul_lantern"],
		"text": "Each Thruster Explosion launches your wisps as homing spirits, then refills the lantern.",
	},
	"event_horizon": {
		"name": "Event Horizon", "needs": ["hex_repeater", "time_brake"],
		"text": "Hex orbs drag enemy bullets into themselves and devour them.",
	},
}

## Salvage Crate: three reels, and the crate gives the sum of the faces they land on, 1 to 6 upgrades.
## Zeros outnumber ones, which outnumber twos; the last reel has no zeros, so every crate gives at least 1.
## Odds: 1 = 28.8%, 2 = 36%, 3 = 24%, 4 = 9%, 5 = 2%, 6 = 0.2% (average 2.2).
const CRATE_REELS := [
	[0, 0, 0, 0, 0, 0, 1, 1, 1, 2],
	[0, 0, 0, 0, 0, 0, 1, 1, 1, 2],
	[1, 1, 1, 1, 1, 1, 1, 1, 2, 2],
]
## Rerolls per mission on the level-up screen.
const REROLLS := 2


static func field_upgrade(upgrade_id: String) -> Dictionary:
	if FIELD.has(upgrade_id):
		return FIELD[upgrade_id]
	return RISKY_FIELD.get(upgrade_id, {})
