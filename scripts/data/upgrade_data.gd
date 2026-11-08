class_name UpgradeData
## Mission-only field upgrades and fusions. Pure data; UpgradeOffers builds the level-up cards from it.

## Field upgrades last for the current mission only. "limit" caps how many times one can be taken.
const FIELD := {
	"echo_chamber": {
		"name": "Echo Chamber", "limit": 2, "icon": "echo",
		"text": "Every 4th main weapon volley fires twice. Taking it again makes it every 3rd.",
	},
	"vampiric_plating": {
		"name": "Vampiric Plating", "limit": 2, "icon": "vampire",
		"text": "Every kill patches a little armor.",
	},
	"last_stand": {
		"name": "Last Stand", "limit": 1, "icon": "last_stand",
		"text": "Below a third of your armor, deal +60% damage and burn with a red aura.",
	},
	"shrapnel_skin": {
		"name": "Shrapnel Skin", "limit": 2, "icon": "shrapnel",
		"text": "Getting hit blasts a ring of shrapnel out of your hull.",
	},
	"overclocked_servos": {
		"name": "Overclocked Servos", "limit": 2, "icon": "servos",
		"text": "Move 15% faster, and ramming enemies hurts them more than you.",
	},
	"tractor_beam": {
		"name": "Tractor Beam", "limit": 1, "icon": "magnet",
		"text": "Data Shards and drops fly to you from across the field.",
	},
	"field_repair": {
		"name": "Field Repair", "limit": 2, "icon": "repair",
		"text": "Repair 40% of your armor right now.",
	},
	"lucky_salvage": {
		"name": "Lucky Salvage", "limit": 1, "icon": "crate",
		"text": "Salvage Crate reels always land on at least 3 upgrades.",
	},
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
const CRATE_REEL := [[1, 55], [3, 33], [5, 12]]
