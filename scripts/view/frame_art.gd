class_name FrameArt
## Draws the player's frame in each form (GDD 5E): a fighter in ship form, a walking mech in mech form,
## and the transformation flash between them. Each frame has its own silhouette and colours.
## Shapes are drawn facing +x, then rotated to the frame's facing.

## Top halves of each ship silhouette, nose first (mirrored to make the full hull).
const SHIP_HULLS := {
	"vanguard": [Vector2(30, 0), Vector2(14, -5), Vector2(4, -8), Vector2(-4, -24), Vector2(-14, -26), Vector2(-11, -10), Vector2(-20, -9), Vector2(-17, 0)],
	"tempest": [Vector2(34, 0), Vector2(18, -4), Vector2(10, -6), Vector2(14, -22), Vector2(4, -22), Vector2(-10, -8), Vector2(-20, -12), Vector2(-16, 0)],
	"bulwark": [Vector2(24, 0), Vector2(16, -9), Vector2(6, -12), Vector2(2, -26), Vector2(-16, -28), Vector2(-16, -14), Vector2(-24, -12), Vector2(-22, 0)],
}
const MECH_SIZES := {
	"vanguard": {"torso": 15.0, "shoulder": 9.0, "foot": Vector2(10, 6), "gun": 22.0},
	"tempest": {"torso": 12.0, "shoulder": 7.0, "foot": Vector2(9, 5), "gun": 24.0},
	"bulwark": {"torso": 18.0, "shoulder": 11.0, "foot": Vector2(12, 8), "gun": 20.0},
}


## state: speed, flash, scale, and optionally gear (see GearArt), fusions, and resonance [element, tier].
static func draw_frame(ci: CanvasItem, frame_id: String, form: String, at: Vector2, facing: float, time: float, state: Dictionary) -> void:
	var data := FrameData.get_frame(frame_id)
	var hull: Color = data["hull"]
	var trim: Color = data["trim"]
	# Resonance tints the trim toward its element as tiers come online (GDD 11F).
	var resonance: Array = state.get("resonance", [])
	if not resonance.is_empty() and int(resonance[1]) > 0:
		trim = trim.lerp(TechData.ELEMENT_COLORS[resonance[0]], 0.25 + 0.2 * int(resonance[1]))
	if state.get("flash", 0.0) > 0.0:
		hull = hull.lerp(Color.WHITE, 0.7)
	var scale: float = state.get("scale", 1.3)
	ci.draw_set_transform(at, facing, Vector2(scale, scale))
	var gear: Array = state.get("gear", [])
	if form == "ship":
		_draw_ship(ci, frame_id, hull, trim, time, state)
	else:
		_draw_mech(ci, frame_id, hull, trim, time, state, gear.is_empty())
	if not gear.is_empty():
		GearArt.draw_gear(ci, Transform2D(facing, Vector2(scale, scale), 0.0, at), form, gear, state.get("fusions", []), time,
			1.0 if form == "ship" else MECH_SIZES.get(frame_id, MECH_SIZES["vanguard"])["torso"] / 15.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _draw_ship(ci: CanvasItem, frame_id: String, hull: Color, trim: Color, time: float, state: Dictionary) -> void:
	var half: Array = SHIP_HULLS.get(frame_id, SHIP_HULLS["vanguard"])
	var points := Art.mirrored(PackedVector2Array(half))
	# Engine flame, flickering, longer when moving fast.
	var thrust: float = 0.7 + state.get("speed", 0.0) * 0.6 + sin(time * 40.0) * 0.12
	var flame := PackedVector2Array([Vector2(-16, -5), Vector2(-16 - 22 * thrust, 0), Vector2(-16, 5)])
	ci.draw_colored_polygon(flame, Color(1.0, 0.7, 0.3, 0.9))
	ci.draw_colored_polygon(Art.scaled(flame, Vector2(0.7, 0.5)), Color(1, 1, 0.85))
	Art.shape(ci, points, hull.darkened(0.45), hull, 2.0)
	Art.shape(ci, Art.scaled(points, Vector2(0.7, 0.55)), hull.darkened(0.15), hull.lightened(0.3), 1.0)
	# Wing trim stripes.
	for side in [-1.0, 1.0]:
		ci.draw_line(Vector2(2, -9 * side), Vector2(-10, -20 * side), trim, 2.5, true)
	# Cockpit.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(16, 0), Vector2(6, -4), Vector2(2, 0), Vector2(6, 4)]), Color(0.75, 0.95, 1.0))


static func _draw_mech(ci: CanvasItem, frame_id: String, hull: Color, trim: Color, time: float, state: Dictionary, stock_arms: bool) -> void:
	var size: Dictionary = MECH_SIZES.get(frame_id, MECH_SIZES["vanguard"])
	var torso: float = size["torso"]
	var shoulder: float = size["shoulder"]
	var foot: Vector2 = size["foot"]
	var walk := clampf(state.get("speed", 0.0), 0.0, 1.0)
	var stride: float = sin(time * 11.0) * 8.0 * walk
	var dark := hull.darkened(0.55)
	# Legs: thigh struts out to big feet that step forward and back.
	for side in [-1.0, 1.0]:
		var hip := Vector2(-torso * 0.2, torso * 0.45 * side)
		var foot_pos := Vector2(stride * side - torso * 0.1, torso * 1.05 * side)
		ci.draw_line(hip, foot_pos, hull.darkened(0.35), 5.0, true)
		Art.shape(ci, PackedVector2Array([foot_pos + Vector2(foot.x * 1.1, -foot.y * 0.55), foot_pos + Vector2(-foot.x * 0.7, -foot.y * 0.55),
			foot_pos + Vector2(-foot.x * 0.7, foot.y * 0.55), foot_pos + Vector2(foot.x * 1.1, foot.y * 0.55)]), dark, hull.darkened(0.1), 1.5)
	# Backpack with twin thrusters.
	Art.shape(ci, PackedVector2Array([Vector2(-torso * 0.55, -torso * 0.55), Vector2(-torso * 1.25, -torso * 0.4),
		Vector2(-torso * 1.25, torso * 0.4), Vector2(-torso * 0.55, torso * 0.55)]), hull.darkened(0.5), trim.darkened(0.2), 1.5)
	for side in [-1.0, 1.0]:
		ci.draw_circle(Vector2(-torso * 1.3, torso * 0.22 * side), 3.0, Color(1, 0.7, 0.35, 0.6 + 0.4 * walk))
	# Torso: a chevron chest that points where the mech aims.
	var chest := PackedVector2Array([Vector2(torso * 1.0, 0), Vector2(torso * 0.55, -torso * 0.8), Vector2(-torso * 0.6, -torso * 0.75),
		Vector2(-torso * 0.75, 0), Vector2(-torso * 0.6, torso * 0.75), Vector2(torso * 0.55, torso * 0.8)])
	Art.shape(ci, chest, hull.darkened(0.4), hull, 2.0)
	Art.shape(ci, Art.scaled(chest, Vector2(0.6, 0.55)), hull.darkened(0.1), hull.lightened(0.3), 1.0)
	# Shoulder armor: angled plates, trimmed in the frame's accent colour.
	for side in [-1.0, 1.0]:
		var pad := PackedVector2Array([Vector2(torso * 0.5, torso * 0.7 * side), Vector2(torso * 0.2, (torso * 0.7 + shoulder * 1.4) * side),
			Vector2(-torso * 0.6, (torso * 0.65 + shoulder * 1.2) * side), Vector2(-torso * 0.55, torso * 0.6 * side)])
		Art.shape(ci, pad, hull.darkened(0.3), trim, 1.8)
	# Stock arms (a long cannon and a blade emitter) when there's no gear to show; otherwise the
	# equipped tech's parts take their place (GearArt).
	if stock_arms:
		var gun: float = size["gun"]
		Art.shape(ci, PackedVector2Array([Vector2(torso * 0.1, torso * 0.95), Vector2(gun * 1.15, torso * 0.85), Vector2(gun * 1.15, torso * 1.2), Vector2(torso * 0.1, torso * 1.3)]),
			dark, trim, 1.5)
		ci.draw_circle(Vector2(gun * 1.15, torso * 1.02), 3.0, Color(0.85, 1, 1))
		ci.draw_line(Vector2(torso * 0.2, -torso * 1.05), Vector2(torso * 0.9, -torso * 1.05), trim.lightened(0.2), 4.0)
	else:
		for side in [-1.0, 1.0]:
			ci.draw_circle(Vector2(torso * 0.35, torso * 1.1 * side), torso * 0.22, hull.darkened(0.3))
	_draw_mech_signature(ci, frame_id, hull, trim, torso)
	# Cockpit dome.
	ci.draw_circle(Vector2(torso * 0.45, 0), torso * 0.28, Color(0.15, 0.3, 0.4))
	ci.draw_circle(Vector2(torso * 0.5, -torso * 0.06), torso * 0.17, Color(0.7, 1, 1))


## What makes each frame's mech its own (GDD 5G): the Vanguard's knightly crest, the Tempest's swept
## fins, the Bulwark's slab armor.
static func _draw_mech_signature(ci: CanvasItem, frame_id: String, hull: Color, trim: Color, torso: float) -> void:
	match frame_id:
		"vanguard":
			for side in [-1.0, 1.0]:
				ci.draw_line(Vector2(torso * 0.55, 0), Vector2(torso * 1.05, torso * 0.42 * side), trim, 2.2, true)
		"tempest":
			for side in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(-torso * 0.9, torso * 0.3 * side), Vector2(-torso * 2.1, torso * 1.3 * side),
					Vector2(-torso * 1.2, torso * 0.45 * side)]), Art.with_alpha(trim, 0.85))
		"bulwark":
			ci.draw_arc(Vector2(torso * 0.2, 0), torso * 1.05, -0.9, 0.9, 12, hull.lightened(0.15), 4.0, true)
			for side in [-1.0, 1.0]:
				Art.shape(ci, PackedVector2Array([Vector2(-torso * 0.5, torso * 0.75 * side), Vector2(torso * 0.4, torso * 0.8 * side),
					Vector2(torso * 0.3, torso * 1.0 * side), Vector2(-torso * 0.6, torso * 0.95 * side)]), hull.darkened(0.35), trim, 1.2)


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
