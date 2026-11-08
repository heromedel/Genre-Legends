class_name FrameData
## Frames are the base machines the pilot flies (GDD 5G). Each has its own stats, colours and a trait
## that changes how it plays, and each one shifts between forms to match the mission (GDD 5E).

const FRAMES := {
	"vanguard": {
		"name": "Vanguard",
		"tagline": "Balanced all-rounder that refuses to die.",
		"armor": 110.0, "shield": 45.0, "speed": 300.0,
		"hull": Color(0.36, 0.78, 1.0), "trim": Color(1.0, 0.78, 0.35),
		"trait": "second_wind",
		"trait_name": "Second Wind",
		"trait_text": "Once per mission, a hit that would wreck you leaves 1 armor and detonates a Nova instead.",
		"unlock": "",
	},
	"tempest": {
		"name": "Tempest",
		"tagline": "Fast and fragile, trailed by afterimages that fight beside it.",
		"armor": 75.0, "shield": 35.0, "speed": 370.0,
		"hull": Color(0.55, 1.0, 0.7), "trim": Color(0.95, 0.4, 1.0),
		"trait": "afterimage",
		"trait_name": "Afterimage",
		"trait_text": "Each main weapon volley is echoed by an afterimage behind you at 40% damage.",
		"unlock": "Prize of the Tempest Run, a themed branch in the first region.",
	},
	"bulwark": {
		"name": "Bulwark",
		"tagline": "A walking fortress whose shield throws bullets back.",
		"armor": 165.0, "shield": 80.0, "speed": 250.0,
		"hull": Color(1.0, 0.62, 0.3), "trim": Color(0.6, 0.85, 1.0),
		"trait": "fortress_field",
		"trait_name": "Fortress Field",
		"trait_text": "A quarter of the bullets that hit your shield are reflected back.",
		"unlock": "Prize for breaching the second region's gate.",
	},
}

const STARTING_FRAME := "vanguard"
## Seconds without damage before the shield starts recharging, and how fast it recharges.
const SHIELD_DELAY := 2.5
const SHIELD_REGEN_PER_SECOND := 18.0
## After a hit, the frame can't be hit again for this long (failure by attrition, not instant).
const HIT_GRACE := 0.45


static func get_frame(frame_id: String) -> Dictionary:
	return FRAMES.get(frame_id, FRAMES[STARTING_FRAME])
