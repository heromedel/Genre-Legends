class_name FrameData
## Frames are the base machines the pilot flies (GDD 5G). Each has its own stats, colours and a trait
## that changes how it plays, and each one shifts between forms to match the mission (GDD 5E).

const FRAMES := {
	"vanguard": {
		"name": "Vanguard",
		"tagline": "The first frame through the breach, plated for it.",
		"armor": 60.0, "built_in_armor": 20.0, "speed": 300.0, "load": 12, "output": 9,
		"hull": Color(0.36, 0.78, 1.0), "trim": Color(1.0, 0.78, 0.35),
		"trait": "breacher_plating",
		"trait_name": "Breacher Plating",
		"trait_text": "Extra plating bolted onto the hull: 20 more Armor, two hits' worth, on top of any plating you wear.",
		"unlock": "",
	},
	"tempest": {
		"name": "Tempest",
		"tagline": "Fast and fragile, trailed by afterimages that fire when it does.",
		"armor": 45.0, "speed": 370.0, "load": 9, "output": 13,
		"hull": Color(0.55, 1.0, 0.7), "trim": Color(0.95, 0.4, 1.0),
		"trait": "afterimage",
		"trait_name": "Afterimage",
		"trait_text": "Each main weapon volley is echoed by an afterimage behind you at 40% damage.",
		"unlock": "Prize of the Tempest Run, a themed branch in the first region.",
	},
	"bulwark": {
		"name": "Bulwark",
		"tagline": "A walking fortress whose armored front throws bullets back.",
		"armor": 100.0, "speed": 250.0, "load": 16, "output": 6,
		"hull": Color(1.0, 0.62, 0.3), "trim": Color(0.6, 0.85, 1.0),
		"trait": "fortress_field",
		"trait_name": "Fortress Field",
		"trait_text": "A quarter of the bullets that hit your front are thrown back.",
		"unlock": "Prize for breaching the second region's gate.",
	},
}

const STARTING_FRAME := "vanguard"
## Frame upgrades (GDD 21F): three tiers bought with Frame Blueprints. Each tier holds one pick, which can be
## changed in the Hangar at any time, so two Vanguards can grow differently and nobody is locked into a mistake.
const TIER_COSTS := [3, 6, 10]
const TIER_PICKS := ["load", "output", "armor", "cooling"]
const TIER_PICK_NAMES := {"load": "+1 Max Load", "output": "+1 Mawjig Output", "armor": "+10 Armor", "cooling": "25% slower heat"}
const TIER_PICK_TEXT := {
	"load": "Room for one more pip of weight.",
	"output": "One more pip of Mawjig Output before you overclock.",
	"armor": "A hit's worth more Armor.",
	"cooling": "Heat builds a quarter slower.",
}
## After a hit, the frame can't be hit again for this long (failure by attrition, not instant, GDD 13E),
## and a little longer after a big hit.
const HIT_GRACE := 1.0
const HEAVY_HIT_GRACE := 1.3
const HEAVY_HIT := 20.0          # the default; in a mission a big hit is two of that planet's plain bullets
## Bulwark's Fortress Field: how wide its armoured front is, either side of where it faces (radians).
const FORTRESS_FRONT := 1.05


static func get_frame(frame_id: String) -> Dictionary:
	return FRAMES.get(frame_id, FRAMES[STARTING_FRAME])


## A frame's numbers with its tier picks applied: armor, speed, load, output and heat_rate (1.0 is normal).
## The one place they're worked out, so the Hangar and the mission always agree.
static func stats(frame_id: String, tier_picks: Array) -> Dictionary:
	var data := get_frame(frame_id)
	var result := {
		"armor": data["armor"] + data.get("built_in_armor", 0.0),
		"speed": data["speed"],
		"load": int(data["load"]),
		"output": int(data["output"]),
		"heat_rate": 1.0,
	}
	for pick in tier_picks:
		match pick:
			"load": result["load"] += 1
			"output": result["output"] += 1
			"armor": result["armor"] += 10.0
			"cooling": result["heat_rate"] *= 0.75
	return result
