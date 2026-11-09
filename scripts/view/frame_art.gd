class_name FrameArt
## Draws the player's frame in each form (GDD 5E): a fighter in ship form, a walking mech in mech form,
## and the transformation flash between them. Each frame has its own silhouette and colours.
## The bodies are vector art (art/frames/<frame>_<form>.svg, drawn by VectorArt in the five-pass style);
## this class animates them: the engine flame, the mech's stride, a hit flash, the Resonance-tinted trim,
## and a thin rim of light so the player's frame always stands out. Gear is drawn on top (GearArt).

## Each mech's size, for scaling its gear (GearArt mounts are written for the Vanguard's).
const MECH_GEAR_SCALE := {"vanguard": 1.0, "tempest": 0.8, "bulwark": 1.2}
## How much larger a mech is drawn than its ship (the art is the same scale; the hitbox doesn't change).
const MECH_DRAW_SCALE := 1.2
## The rim of light around the player's frame: one colour for every frame, so "this one is you" reads the same.
const PLAYER_RIM := Color(0.62, 0.95, 1.0, 0.9)


## state: speed, flash, scale, and optionally gear (see GearArt), fusions, and resonance [element, tier].
static func draw_frame(ci: CanvasItem, frame_id: String, form: String, at: Vector2, facing: float, time: float, state: Dictionary) -> void:
	var data := FrameData.get_frame(frame_id)
	var trim: Color = data["trim"]
	# Mechs draw a fifth larger than ships: seen from above they're compact, and small on an iPad mini.
	var scale: float = state.get("scale", 1.3) * (MECH_DRAW_SCALE if form == "mech" else 1.0)
	# Resonance tints the trim toward its element as tiers come online (GDD 11F), and adds a glow (GDD 9H).
	var resonance: Array = state.get("resonance", [])
	if not resonance.is_empty() and int(resonance[1]) > 0:
		var tier := int(resonance[1])
		var element_color: Color = TechData.ELEMENT_COLORS[resonance[0]]
		trim = trim.lerp(element_color, minf(0.35 + 0.25 * tier, 1.0))
		var pulse := 0.75 + 0.25 * sin(time * 4.0)
		Art.draw_glow(ci, at, (30.0 + 10.0 * tier) * scale, Art.with_alpha(element_color, 0.12 * tier * pulse))
		if tier >= 3:
			Art.dashed_circle(ci, at, 34.0 * scale, Art.with_alpha(element_color, 0.5 * pulse), 2.0, 10, time * 1.5)
	var gear: Array = state.get("gear", [])
	var groups := {}
	var hide := []
	if form == "ship":
		# The flame stretches with speed and flickers; it hangs from the engines at y = 20.
		var thrust: float = 0.7 + state.get("speed", 0.0) * 0.6 + sin(time * 40.0) * 0.12
		groups["flame"] = Transform2D(0.0, Vector2(1.0, thrust), 0.0, Vector2(0.0, 20.0 - 20.0 * thrust))
	else:
		# The feet step forward and back in turn while it walks.
		var stride: float = sin(time * 11.0) * 6.0 * clampf(state.get("speed", 0.0), 0.0, 1.0)
		groups["foot_l"] = Transform2D(0.0, Vector2(0.0, -stride))
		groups["foot_r"] = Transform2D(0.0, Vector2(0.0, stride))
		# Equipped tech takes the place of the stock arms (GearArt).
		if not gear.is_empty():
			hide.append("stock_arms")
	# The art faces up; the frame's facing is measured from +x.
	var body := Transform2D(facing + PI * 0.5, Vector2(scale, scale), 0.0, at)
	VectorArt.draw(ci, "res://art/frames/%s_%s.svg" % [frame_id, form], body, {
		"remap": {"#" + data["trim"].to_html(false): trim},
		"flash": 0.7 if state.get("flash", 0.0) > 0.0 else 0.0,
		"rim": PLAYER_RIM,
		"groups": groups,
		"hide": hide,
	})
	if not gear.is_empty():
		GearArt.draw_gear(ci, Transform2D(facing, Vector2(scale, scale), 0.0, at), form, gear, state.get("fusions", []), time,
			1.0 if form == "ship" else MECH_GEAR_SCALE.get(frame_id, 1.0))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The glow that sits under the frame on the additive layer.
static func draw_glow(ci: CanvasItem, frame_id: String, form: String, at: Vector2, facing: float, state: Dictionary) -> void:
	var data := FrameData.get_frame(frame_id)
	var hull: Color = data["hull"]
	Art.draw_glow(ci, at, 46.0, Art.with_alpha(hull, 0.35))
	if form == "ship":
		Art.draw_glow(ci, at - Vector2.from_angle(facing) * 26.0, 26.0, Color(1, 0.6, 0.25, 0.8))
	if state.get("overdrive", false):
		Art.draw_glow(ci, at, 70.0, Color(1, 0.8, 0.3, 0.55))
	if state.get("last_stand", false):
		Art.draw_glow(ci, at, 64.0, Color(1, 0.2, 0.2, 0.5))


## The shift between forms: a burst of light with the outline of the old and new forms.
static func draw_transform(ci: CanvasItem, at: Vector2, progress: float, color: Color) -> void:
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	var ring := 20.0 + progress * 90.0
	ci.draw_arc(at, ring, 0, TAU, 40, Art.with_alpha(color, 1.0 - progress), 4.0, true)
	Art.draw_glow(ci, at, 60.0 + progress * 40.0, Art.with_alpha(color, (1.0 - progress) * 0.9))
	for i in 8:
		var a := TAU * i / 8.0 + progress * 2.0
		ci.draw_line(at + Vector2.from_angle(a) * ring * 0.4, at + Vector2.from_angle(a) * ring, Art.with_alpha(Color.WHITE, 1.0 - progress), 2.0, true)
