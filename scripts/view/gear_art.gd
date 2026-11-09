class_name GearArt
## The equipment you can see on the frame (GDD 11F): every equipped tech has a part mounted where its slot
## sits, in both forms. Offline tech is folded away and dark; it unfolds with a flash when it comes online,
## gains detail as it levels, changes shape with its fork, and a fusion links its two parts with gold.
## Parts are drawn in the frame's local space (facing +x), at its mount, before FrameArt's rotation ends.

## Where each loadout slot mounts, per form: [position, rotation]. Slots: main, weapon, weapon, support, special.
const SHIP_MOUNTS := [
	[Vector2(24, 0), 0.0],          # main: under the nose
	[Vector2(-6, -17), 0.0],        # weapon: left wing pylon
	[Vector2(-6, 17), 0.0],         # weapon: right wing pylon
	[Vector2(-15, 0), PI],          # support: on the spine, facing back
	[Vector2(-4, 0), 0.0],          # special: the core on the spine, just behind the canopy (not over it)
]
const MECH_MOUNTS := [
	[Vector2(6, 17), 0.0],          # main: the right arm
	[Vector2(-3, -20), 0.0],        # weapon: left shoulder
	[Vector2(-3, 20), 0.0],         # weapon: right shoulder
	[Vector2(-19, 0), PI],          # support: the backpack
	[Vector2(-11, 0), 0.0],         # special: on the back, between cockpit and backpack (not over the face)
]
## The colours the gear art writes for its glow and the glow's hot core; swapped for the tech's element colour.
const GLOW_TOKEN := "#39ff14"
const CORE_TOKEN := "#d8ffcc"
## Seconds a part takes to unfold when its tech comes online.
const DEPLOY_SECONDS := 0.45


## Gear for a loadout outside a mission (hangar, title): every part shown online and settled.
static func loadout_gear(loadout: Array, level: int) -> Array:
	return loadout.map(func(tech_id): return {"tech": tech_id, "level": level if tech_id != "" else 0, "fork": "", "online_for": 99.0})


## Draws every equipped part. gear: Array of {tech, level, fork, online_for}; fusions: fusion ids.
## frame: the frame's own transform (position, facing, scale); parts are placed inside it.
static func draw_gear(ci: CanvasItem, frame: Transform2D, form: String, gear: Array, fusions: Array, time: float, size_scale: float) -> void:
	ci.draw_set_transform_matrix(frame)
	var mounts: Array = SHIP_MOUNTS if form == "ship" else MECH_MOUNTS
	var placed := {}
	for slot in gear.size():
		var part: Dictionary = gear[slot]
		if part.get("tech", "") == "":
			continue
		var mount: Array = mounts[slot]
		var at: Vector2 = mount[0] * size_scale
		placed[part["tech"]] = at
		_draw_part(ci, frame, part, at, mount[1], slot, form, time)
	# Fusions: a crackling gold link between the two fused parts.
	for fusion_id in fusions:
		var needs: Array = UpgradeData.FUSIONS[fusion_id]["needs"]
		if placed.has(needs[0]) and placed.has(needs[1]):
			var a: Vector2 = placed[needs[0]]
			var b: Vector2 = placed[needs[1]]
			var mid := (a + b) * 0.5 + (b - a).orthogonal().normalized() * sin(time * 9.0) * 4.0
			ci.draw_polyline(PackedVector2Array([a, mid, b]), Color(1, 0.85, 0.35, 0.85), 2.0, true)
			ci.draw_circle(mid, 2.5, Color(1, 1, 0.8))


static func _draw_part(ci: CanvasItem, frame: Transform2D, part: Dictionary, at: Vector2, rotation: float, slot: int, form: String, time: float) -> void:
	var tech_id: String = part["tech"]
	var level: int = part.get("level", 0)
	var online := level > 0
	var since: float = part.get("online_for", 99.0)
	# Offline parts sit folded close to the hull; coming online they unfold with a flash.
	var unfold := clampf(since / DEPLOY_SECONDS, 0.0, 1.0) if online else 0.0
	var size := lerpf(0.5, 1.0, ease(unfold, 0.4))
	var color := TechData.element_color(tech_id)
	var flash := clampf(1.0 - since / DEPLOY_SECONDS, 0.0, 1.0) if online else 0.0
	# The right-hand weapon pylon is the mirror image of the left.
	var mirror := -1.0 if slot == 2 else 1.0
	var local := frame * Transform2D(rotation, Vector2(size, size * mirror), 0.0, at)
	_draw_vector_part(ci, local, tech_id, part.get("fork", ""), level, color, online)
	ci.draw_set_transform_matrix(local)
	_draw_live(ci, tech_id, part.get("fork", ""), level, color, time)
	if flash > 0.0:
		ci.draw_circle(Vector2.ZERO, 10.0 * flash + 3.0, Color(1, 1, 1, flash * 0.8))
	# Level 5: a gold spark marks a maxed part.
	if level >= TechData.MAX_LEVEL:
		ci.draw_circle(Vector2(0, -6), 1.8 + 0.6 * sin(time * 6.0), Art.GOLD)
	ci.draw_set_transform_matrix(frame)


## The part's body: art/gear/<tech>.svg, turned from facing up to the frame's facing (+x), its glow in the
## tech's element colour, dimmed while offline, showing only its fork's pieces.
static func _draw_vector_part(ci: CanvasItem, local: Transform2D, tech_id: String, fork: String, level: int, color: Color, online: bool) -> void:
	var hide := []
	if fork != "a":
		hide.append("fork_a")
	if fork != "b":
		hide.append("fork_b")
	# Some forks replace a piece rather than add to it.
	if tech_id == "pulse_driver" and fork == "a":
		hide.append("barrels")
	if tech_id == "mirror_aegis" and fork == "b":
		hide.append("plate")
	var groups := {}
	if tech_id == "arc_blade":
		# The blade grows with level, from its hilt.
		var length := (12.0 + 2.0 * maxi(level, 1)) / 14.0
		groups["blade"] = Transform2D(0.0, Vector2(1.0, length), 0.0, Vector2(0.0, -0.5 + 0.5 * length))
	VectorArt.draw(ci, "res://art/gear/%s.svg" % tech_id, local * Transform2D(PI * 0.5, Vector2.ZERO), {
		"remap": {GLOW_TOKEN: color, CORE_TOKEN: color.lightened(0.6)},
		"dim": 0.0 if online else 0.55,
		"groups": groups,
		"hide": hide,
	})


## The parts that move: drawn live on top of the art, in the part's own space (facing +x).
static func _draw_live(ci: CanvasItem, tech_id: String, fork: String, level: int, color: Color, time: float) -> void:
	var bright := color.lightened(0.35)
	match tech_id:
		"thunder_lance":
			if level > 0:
				ci.draw_line(Vector2(14.5, 0), Vector2(17.5, sin(time * 30.0) * 2.0), Color(0.8, 1, 1), 1.2, true)
		"orbital_halo":
			for i in 3:
				ci.draw_circle(Vector2.from_angle(time * 4.0 + TAU * i / 3.0) * 6.5, 1.5, bright)
		"starfall":
			if fork == "b":
				for i in 3:
					ci.draw_circle(Vector2(8.5, 0) + Vector2.from_angle(time * 3.0 + TAU * i / 3.0) * 4.5, 0.9, color)
		"time_brake":
			ci.draw_line(Vector2.ZERO, Vector2.from_angle(time * (0.5 if level > 0 else 0.0)) * 3.2, bright, 1.1, true)
