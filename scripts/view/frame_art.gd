class_name FrameArt
## Draws the player's frame (GDD 5E). Each frame is one set of parts (art/frames/<frame>.svg, drawn by
## VectorArt in the five-pass style) that stands as the mech or folds into the ship, like a transforming
## robot: every part has a mech pose and a ship pose, and the transformation moves each part from one to
## the other on its own schedule. This class poses and animates the parts: the stride, the engine flames,
## a hit flash, the Resonance-tinted trim, and a rim of light so the player's frame always stands out.
## Gear is drawn on top (GearArt).

## Each mech's size, for scaling its gear (GearArt mounts are written for the Vanguard's).
const MECH_GEAR_SCALE := {"vanguard": 1.0, "tempest": 0.8, "bulwark": 1.2}
## How much larger the mech is drawn than the ship (the parts are the same; the hitbox doesn't change).
const MECH_DRAW_SCALE := 1.2
## The rim of light around the player's frame: one colour for every frame, so "this one is you" reads the same.
const PLAYER_RIM := Color(0.62, 0.95, 1.0, 0.9)
## When each part moves during the transformation (0 = mech, 1 = ship), so it unfolds in a readable order:
## legs swing back first, then the arms tuck and the shoulders sweep out, the chest stretches, the helmet
## slides forward into the cockpit, and the engines light last. Parts not listed move across the middle.
const MORPH_WINDOWS := {
	"leg_l": Vector2(0.0, 0.55), "leg_r": Vector2(0.0, 0.55),
	"arm_l": Vector2(0.05, 0.5), "arm_r": Vector2(0.05, 0.5),
	"backpack": Vector2(0.15, 0.65),
	"shoulder_l": Vector2(0.2, 0.75), "shoulder_r": Vector2(0.2, 0.75),
	"torso": Vector2(0.3, 0.8),
	"helmet": Vector2(0.45, 1.0),
	"flame_l": Vector2(0.8, 1.0), "flame_r": Vector2(0.8, 1.0),
}


## state: speed, flash, scale, alpha, tint, rim, and optionally gear (see GearArt), fusions, and resonance [element, tier].
static func draw_frame(ci: CanvasItem, frame_id: String, form: String, at: Vector2, facing: float, time: float, state: Dictionary) -> void:
	var p := 1.0 if form == "ship" else 0.0
	_draw_parts(ci, frame_id, p, at, facing, time, state)
	var gear: Array = state.get("gear", [])
	if not gear.is_empty():
		var scale := _scale(state, p)
		GearArt.draw_gear(ci, Transform2D(facing, Vector2(scale, scale), 0.0, at), form, gear, state.get("fusions", []), time,
			1.0 if form == "ship" else MECH_GEAR_SCALE.get(frame_id, 1.0))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## The frame mid-transformation: progress 0 is the mech, 1 the ship. Each part moves between its two poses
## in its own window (MORPH_WINDOWS), a line of light sweeps across, and with the spin setting it turns a
## full circle as it changes (Settings: "Transformation spin"). Gear folds away for the moment.
static func draw_morph(ci: CanvasItem, frame_id: String, at: Vector2, facing: float, progress: float, time: float, state: Dictionary) -> void:
	var p := clampf(progress, 0.0, 1.0)
	var spin: bool = state.get("spin", Save.setting("transform_spin"))
	var turned := facing + (TAU * smoothstep(0.0, 1.0, p) if spin else 0.0)
	_draw_parts(ci, frame_id, p, at, turned, time, state)
	var scale := _scale(state, p)
	ci.draw_set_transform_matrix(Transform2D(turned + PI * 0.5, Vector2(scale, scale), 0.0, at))
	var y := lerpf(-26.0, 24.0, p)
	var light := sin(p * PI)
	ci.draw_line(Vector2(-26, y), Vector2(26, y), Color(0.6, 0.95, 1.0, 0.85 * light), 2.5, true)
	ci.draw_line(Vector2(-26, y), Vector2(26, y), Color(1, 1, 1, 0.9 * light), 1.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Art.draw_glow(ci, at, 30.0 * scale, Color(0.5, 0.9, 1.0, 0.3 * light))


## The frame's size: the mech is drawn a fifth larger than the ship, eased between during a transformation.
static func _scale(state: Dictionary, p: float) -> float:
	return state.get("scale", 1.3) * lerpf(MECH_DRAW_SCALE, 1.0, p)


## Every part placed between its mech pose (p = 0) and ship pose (p = 1), animated, tinted and drawn.
static func _draw_parts(ci: CanvasItem, frame_id: String, p: float, at: Vector2, facing: float, time: float, state: Dictionary) -> void:
	var path := "res://art/frames/%s.svg" % frame_id
	var data := FrameData.get_frame(frame_id)
	var trim: Color = data["trim"]
	var scale := _scale(state, p)
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
	var groups := {}
	var poses := VectorArt.poses(path)
	for part in poses:
		var window: Vector2 = MORPH_WINDOWS.get(part, Vector2(0.25, 0.75))
		var t := smoothstep(window.x, window.y, p)
		groups[part] = (poses[part]["mech"] as Transform2D).interpolate_with(poses[part]["ship"], t)
	# Walking: the legs step forward and back in turn (mech only).
	var walk := clampf(state.get("speed", 0.0), 0.0, 1.0) * (1.0 - p)
	if walk > 0.0:
		var stride: float = sin(time * 11.0) * 6.0 * walk
		for leg in [["leg_l", -1.0], ["leg_r", 1.0]]:
			if groups.has(leg[0]):
				groups[leg[0]] = Transform2D(0.0, Vector2(0.0, stride * leg[1])) * groups[leg[0]]
	# Flying: the engine flames stretch with speed and flicker (they hang from the bells, at their origin).
	var thrust: float = 0.7 + state.get("speed", 0.0) * 0.6 + sin(time * 40.0) * 0.12
	for flame in ["flame_l", "flame_r"]:
		if groups.has(flame):
			groups[flame] = groups[flame] * Transform2D(0.0, Vector2(1.0, thrust), 0.0, Vector2.ZERO)
	# Equipped tech takes the place of the stock arms (GearArt).
	var hide := []
	if not state.get("gear", []).is_empty():
		hide = ["arm_l", "arm_r"]
	VectorArt.draw(ci, path, Transform2D(facing + PI * 0.5, Vector2(scale, scale), 0.0, at), {
		"remap": {"#" + data["trim"].to_html(false): trim},
		"flash": 0.7 if state.get("flash", 0.0) > 0.0 else 0.0,
		"alpha": state.get("alpha", 1.0),
		"tint": state.get("tint", Color(0, 0, 0, 0)),
		"rim": state.get("rim", PLAYER_RIM),
		"groups": groups,
		"hide": hide,
	})


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
