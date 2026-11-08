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
	[Vector2(4, 0), 0.0],           # special: the core under the canopy
]
const MECH_MOUNTS := [
	[Vector2(6, 17), 0.0],          # main: the right arm
	[Vector2(-3, -20), 0.0],        # weapon: left shoulder
	[Vector2(-3, 20), 0.0],         # weapon: right shoulder
	[Vector2(-19, 0), PI],          # support: the backpack
	[Vector2(3, 0), 0.0],           # special: the chest
]
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
	if not online:
		color = color.darkened(0.6)
	var flash := clampf(1.0 - since / DEPLOY_SECONDS, 0.0, 1.0) if online else 0.0
	# The right-hand weapon pylon is the mirror image of the left.
	var mirror := -1.0 if slot == 2 else 1.0
	ci.draw_set_transform_matrix(frame * Transform2D(rotation, Vector2(size, size * mirror), 0.0, at))
	_draw_shape(ci, tech_id, part.get("fork", ""), level, color, form, time)
	if flash > 0.0:
		ci.draw_circle(Vector2.ZERO, 10.0 * flash + 3.0, Color(1, 1, 1, flash * 0.8))
	# Level 5: a gold spark marks a maxed part.
	if level >= TechData.MAX_LEVEL:
		ci.draw_circle(Vector2(0, -6), 1.8 + 0.6 * sin(time * 6.0), Art.GOLD)
	ci.draw_set_transform_matrix(frame)


## One part's shape, about 12 units across, drawn at the origin facing +x.
static func _draw_shape(ci: CanvasItem, tech_id: String, fork: String, level: int, color: Color, form: String, time: float) -> void:
	var dark := color.darkened(0.55)
	var bright := color.lightened(0.35)
	match tech_id:
		"pulse_driver":
			# Twin barrels; Ricochet angles them into prongs, Splitfire adds a third.
			var barrels := [-2.5, 2.5] if fork != "b" else [-3.5, 0.0, 3.5]
			for y: float in barrels:
				var tip := Vector2(9, y * (1.6 if fork == "a" else 1.0))
				ci.draw_line(Vector2(-3, y), tip, bright, 2.2, true)
			Art.shape(ci, PackedVector2Array([Vector2(-6, -4), Vector2(1, -4), Vector2(1, 4), Vector2(-6, 4)]), dark, color, 1.2)
		"thunder_lance":
			# A long rail between coils; the coils crackle when online.
			ci.draw_line(Vector2(-7, 0), Vector2(13, 0), bright, 2.4, true)
			for i in 3:
				ci.draw_arc(Vector2(-3 + i * 4.5, 0), 3.2, 0, TAU, 8, color, 1.2, true)
			if level > 0:
				ci.draw_line(Vector2(13, 0), Vector2(16, sin(time * 30.0) * 2.0), Color(0.8, 1, 1), 1.2, true)
		"hex_repeater":
			Art.shape(ci, Art.ngon(6, 5.5), dark, color, 1.4)
			ci.draw_circle(Vector2.ZERO, 2.2, bright)
			ci.draw_line(Vector2(5, 0), Vector2(10, 0), color, 2.0, true)
		"arc_blade":
			# A hilt and a glowing blade; Whirlwind doubles it into a twin blade.
			ci.draw_line(Vector2(-4, 0), Vector2(0, 0), dark.lightened(0.3), 3.0, true)
			ci.draw_line(Vector2(0, -3), Vector2(0, 3), color, 1.6, true)
			var blade := 12.0 + 2.0 * level
			ci.draw_line(Vector2(0, 0), Vector2(blade, 0), Art.with_alpha(bright, 0.9), 2.4, true)
			if fork == "b":
				ci.draw_line(Vector2(-4, 0), Vector2(-4 - blade * 0.7, 0), Art.with_alpha(bright, 0.9), 2.4, true)
			if fork == "a":
				ci.draw_arc(Vector2(blade * 0.6, 0), 4.0, -1.2, 1.2, 8, bright, 1.2, true)
		"swarm_pods":
			# A missile rack; Cluster Warheads fatten the tips, Hunter Swarm adds a row.
			var rows := 3 if fork == "b" else 2
			Art.shape(ci, PackedVector2Array([Vector2(-6, -4.5), Vector2(4, -4.5), Vector2(4, 4.5), Vector2(-6, 4.5)]), dark, color, 1.2)
			for r in rows:
				for c in 2:
					ci.draw_circle(Vector2(5.0 - r * 3.0, -2.5 + c * 5.0), 1.6 if fork != "a" else 2.2, bright)
		"orbital_halo":
			ci.draw_arc(Vector2.ZERO, 5.5, 0, TAU, 14, color, 1.6, true)
			for i in 3:
				var a := time * 4.0 + TAU * i / 3.0
				ci.draw_circle(Vector2.from_angle(a) * 5.5, 1.6, bright)
		"starfall":
			# A beacon mast with a Mawjig orb.
			ci.draw_line(Vector2(-4, 0), Vector2(8, 0), dark.lightened(0.3), 2.0, true)
			ci.draw_circle(Vector2(9, 0), 3.0 + 0.5 * sin(time * 5.0), bright)
			if fork == "b":
				for i in 3:
					ci.draw_circle(Vector2(9, 0) + Vector2.from_angle(time * 3.0 + TAU * i / 3.0) * 5.0, 1.0, color)
		"mirror_aegis":
			# A curved mirror plate; Bastion makes it a full wall.
			var span := 1.1 if fork != "b" else 1.5
			ci.draw_arc(Vector2(-4, 0), 8.0, -span, span, 10, bright, 2.4, true)
			ci.draw_arc(Vector2(-4, 0), 6.0, -span, span, 10, Art.with_alpha(Color(0.85, 1, 1), 0.5), 1.0, true)
		"graze_engine":
			for side in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 0), Vector2(4, 6 * side), Vector2(2, 2 * side)]), color)
			ci.draw_circle(Vector2(-6, 0), 1.8, bright)
		"overheat_core":
			# Radiator fins that glow hotter with level.
			for i in 3:
				ci.draw_line(Vector2(-5 + i * 4.0, -5), Vector2(-5 + i * 4.0, 5), color, 2.0, true)
			ci.draw_circle(Vector2(0, 0), 2.0, Color(1, 0.5 + 0.1 * level, 0.2))
		"nova_bomb":
			Art.shape(ci, Art.star(4, 6.0, 2.5), Art.with_alpha(color, 0.6), bright, 1.2)
			if fork == "b":
				ci.draw_circle(Vector2(0, 0), 1.6, Color(1, 1, 0.8))
		"time_brake":
			ci.draw_arc(Vector2.ZERO, 5.5, 0, TAU, 14, color, 1.4, true)
			ci.draw_line(Vector2.ZERO, Vector2.from_angle(time * (0.5 if level > 0 else 0.0)) * 4.5, bright, 1.4, true)
			ci.draw_line(Vector2.ZERO, Vector2(0, -3.5), bright, 1.2, true)
		_:
			ci.draw_circle(Vector2.ZERO, 3.0, color)
