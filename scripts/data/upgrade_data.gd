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
		"text": "Up to four beams of light reel in Data Shards and drops from further away. Taking it again reaches further.",
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
		"text": "Bullets that barely miss you give Data Shards. Enemy bullets fly 15% faster.",
	},
	"blood_pact": {
		"name": "Blood Pact", "limit": 1, "icon": "vampiric_plating", "element": "mawjig",
		"text": "Every kill repairs armor. Go two seconds without a kill and your armor bleeds away, down to a third.",
	},
}

## Resonance: levels of online tech (and field upgrades, worth 2) of one element add up. Reaching a
## threshold unlocks that element's next tier, so every pick is also a choice of direction.
const RESONANCE_THRESHOLDS := [5, 10, 15]
const FIELD_RESONANCE_POINTS := 2
const ELEMENTS := ["energy", "explosive", "kinetic", "mawjig"]
const RESONANCE := {
	"energy": {"name": "Energy", "tiers": [
		["Static Charge", "Every 4th hit arcs lightning to another enemy."],
		["Capacitor Discharge", "When your shield breaks, it lets go in a lightning nova that strikes up to six enemies and erases nearby bullets."],
		["Storm Front", "Every 2nd hit arcs, and the lightning chains twice."]]},
	"explosive": {"name": "Explosive", "tiers": [
		["Volatile", "Kills have a 1 in 3 chance to explode."],
		["Chain Reaction", "Anything an explosion kills explodes too, a beat later, so blasts ripple through a crowd."],
		["Wildfire", "Explosions leave flames that keep burning."]]},
	"kinetic": {"name": "Kinetic", "tiers": [
		["Penetrator", "Shots punch through one extra enemy."],
		["Splinter Rounds", "Shots that have flown a while burst into two fragments when they hit."],
		["Railstorm", "Every 2 s a slug tears through the nearest enemy and everything behind it."]]},
	"mawjig": {"name": "Mawjig", "tiers": [
		["Hex Touch", "Your hits hex enemies, and hexed enemies take 30% more damage."],
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
		"text": "Missile blasts sometimes call down meteors, and every meteor launches missiles.",
	},
	"phoenix_driver": {
		"name": "Phoenix Driver", "needs": ["pulse_driver", "graze_engine"],
		"text": "Bolts become piercing firebirds, and Overdrive comes twice as often.",
	},
	"supernova_core": {
		"name": "Supernova Core", "needs": ["overheat_core", "nova_bomb"],
		"text": "Every heat vent wipes the screen of bullets and blasts half again as wide.",
	},
	"storm_halo": {
		"name": "Storm Halo", "needs": ["orbital_halo", "thunder_lance"],
		"text": "Lightning links your saws into a spinning electric fence that shocks enemies and erases bullets. Every saw hit also arcs to a nearby enemy.",
	},
	"starbreaker": {
		"name": "Starbreaker", "needs": ["ion_cannon", "option_pods"],
		"text": "Every pod fires its own ion beam alongside yours.",
	},
	"wraith_drive": {
		"name": "Wraith Drive", "needs": ["thruster_explosion", "soul_lantern"],
		"text": "Dashing turns you into a wraith. Every enemy you tear through releases a hunting spirit, your wisps launch and the lantern refills.",
	},
	"event_horizon": {
		"name": "Event Horizon", "needs": ["hex_repeater", "time_brake"],
		"text": "Hex orbs become small black holes: they swallow bullets, drag in smaller enemies, then collapse in a burst that hexes everything nearby.",
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
