class_name FrameData
## Frames are the base machines the pilot flies (GDD 5G). Each has its own stats, colours and a trait
## that changes how it plays, and each one shifts between forms to match the mission (GDD 5E).

const FRAMES := {
	"vanguard": {
		"name": "Vanguard",
		"tagline": "The first frame through the breach, plated for it.",
		"armor": 60.0, "built_in_armor": 20.0, "speed": 300.0,
		"hull": Color(0.36, 0.78, 1.0), "trim": Color(1.0, 0.78, 0.35),
		"trait": "breacher_plating",
		"trait_name": "Breacher Plating",
		"trait_text": "Extra armour bolted onto the hull: 20 more Armor, two hits' worth, on top of any plating.",
		"unlock": "",
	},
	"tempest": {
		"name": "Tempest",
		"tagline": "Fast and fragile, trailed by afterimages that fight beside it.",
		"armor": 45.0, "speed": 370.0,
		"hull": Color(0.55, 1.0, 0.7), "trim": Color(0.95, 0.4, 1.0),
		"trait": "afterimage",
		"trait_name": "Afterimage",
		"trait_text": "Each main weapon volley is echoed by an afterimage behind you at 40% damage.",
		"unlock": "Prize of the Tempest Run, a themed branch in the first region.",
	},
	"bulwark": {
		"name": "Bulwark",
		"tagline": "A walking fortress whose armoured front throws bullets back.",
		"armor": 100.0, "speed": 250.0,
		"hull": Color(1.0, 0.62, 0.3), "trim": Color(0.6, 0.85, 1.0),
		"trait": "fortress_field",
		"trait_name": "Fortress Field",
		"trait_text": "A quarter of the bullets that hit your front are thrown back.",
		"unlock": "Prize for breaching the second region's gate.",
	},
}

const STARTING_FRAME := "vanguard"
## After a hit, the frame can't be hit again for this long (failure by attrition, not instant, GDD 13E),
## and a little longer after a big hit.
const HIT_GRACE := 1.0
const HEAVY_HIT_GRACE := 1.3
const HEAVY_HIT := 20.0
## Bulwark's Fortress Field: how wide its armoured front is, either side of where it faces (radians).
const FORTRESS_FRONT := 1.05


static func get_frame(frame_id: String) -> Dictionary:
	return FRAMES.get(frame_id, FRAMES[STARTING_FRAME])
