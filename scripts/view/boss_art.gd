class_name BossArt
## Draws each boss as one big set piece (GDD 6H proposal) from its parts' live state:
## broken bays smoke, armor plates slide open, legs buckle, the king fades between pillars.
## Redrawn bosses use the five-pass vector art in res://art/bosses: a hull drawn in place around the boss's
## origin (facing down, game units) and a small piece for each part, drawn where the part is. Ships that fly
## are authored facing up like the enemies and turned to face down.

const ART := "res://art/bosses/%s.svg"


static func draw(ci: CanvasItem, boss: BossBase, time: float) -> void:
	match boss.look:
		"hive_carrier": _hive_carrier(ci, boss, time)
		"wyrm_engine": _wyrm_engine(ci, boss, time)
		"siege_crawler": _siege_crawler(ci, boss, time)
		"hollow_king": _hollow_king(ci, boss, time)
		"mirror_dreadnought": _mirror_dreadnought(ci, boss, time)
		"twin_aces": _twin_aces(ci, boss, time)
		"turret_fortress": _turret_fortress(ci, boss, time)
		"brood_queen": _brood_queen(ci, boss, time)
		"mimic_king": _mimic_king(ci, boss, time)
		"clone_projector": _clone_projector(ci, boss, time)
		"bounty_ace": _bounty_ace(ci, boss, time)
		"crusher_gate": _crusher_gate(ci, boss, time)
		"leviathan": _leviathan(ci, boss, time)
		"dune_maw": _dune_maw(ci, boss, time)
		"storm_colossus": _storm_colossus(ci, boss, time)
		"gazer": _gazer(ci, boss, time)
		"warden": _warden(ci, boss, time)
		"swarm_marshal": _swarm_marshal(ci, boss, time)
		"salvo_barge": _salvo_barge(ci, boss, time)
		"ring_obelisk": _ring_obelisk(ci, boss, time)
		"blade_wraith": _blade_wraith(ci, boss, time)


static func draw_glow(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null:
		return
	var pulse := 0.5 + sin(time * 4.0) * 0.15
	Art.draw_glow(ci, core.pos, core.radius * 4.0, Art.with_alpha(boss.color, pulse * (0.8 if not core.invulnerable else 0.35)))
	for part: Enemy in boss.parts:
		if not part.dead and part.part != "core":
			Art.draw_glow(ci, part.pos, part.radius * 2.2, Art.with_alpha(boss.color, 0.3))


## One piece of boss art at a place, turned and scaled, flashing white while its part is hit.
static func _piece(ci: CanvasItem, art: String, at: Vector2, part: Enemy = null, rotation := 0.0, scale := 1.0, options := {}) -> void:
	var drawn := options.duplicate()
	if part != null and part.flash > 0.0:
		drawn["flash"] = 0.55
	VectorArt.draw(ci, ART % art, Transform2D(rotation, Vector2(scale, scale), 0.0, at), drawn)


## A ship authored facing up, flown facing down: mirrored top to bottom rather than turned around, so its
## light still falls from the top-left like everything else.
static func _ship_down(ci: CanvasItem, art: String, at: Vector2, part: Enemy, scale: float, options := {}) -> void:
	var drawn := options.duplicate()
	if part != null and part.flash > 0.0:
		drawn["flash"] = 0.55
	VectorArt.draw(ci, ART % art, Transform2D(0.0, Vector2(scale, -scale), 0.0, at), drawn)


## A boss's armoured core (art/bosses/core.svg) in the boss's own colour: shutters closed and the heart dim
## while it's protected, shutters open and the heart pulsing once it can be hurt.
static func _core(ci: CanvasItem, core: Enemy, time: float, colour: Color, scale := 1.0) -> void:
	if core == null or core.dead:
		return
	var open := 0.0 if core.invulnerable else 18.0
	var heart := colour if not core.invulnerable else colour.darkened(0.55)
	_piece(ci, "core", core.pos, core, 0.0, scale, {
		"remap": {"#ff8a3a": heart, "#ffd08a": heart.lightened(0.5)},
		"groups": {"shutter_l": Transform2D(0.0, Vector2(-open, 0)), "shutter_r": Transform2D(0.0, Vector2(open, 0)),
			"heart": Transform2D(0.0, Vector2.ONE * (1.0 + sin(time * 6.0) * 0.08 * float(open > 0.0)), 0.0, Vector2.ZERO)}})


## Smoke rising from a wrecked part.
static func _smoke(ci: CanvasItem, at: Vector2, time: float) -> void:
	for s in 3:
		ci.draw_circle(at + Vector2(sin(time * 3.0 + s * 2.0) * 10.0, -10.0 - fmod(time * 30.0 + s * 12.0, 36.0)), 6.0 + s * 2.0, Color(0.2, 0.2, 0.2, 0.5))


static func _flash(part: Enemy, color: Color) -> Color:
	return color.lerp(Color.WHITE, 0.45) if part != null and part.flash > 0.0 else color


static func _hive_carrier(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	_piece(ci, "hive_carrier", o)
	# Hangar bays: glowing doors, or a smoking hole once broken.
	for i in 4:
		var bay := boss.part_named("bay%d" % i)
		if bay == null:
			continue
		var at: Vector2 = o + bay.memory["offset"]
		if bay.dead:
			_piece(ci, "hive_bay_broken", at)
			_smoke(ci, at, time)
		else:
			_piece(ci, "hive_bay", at, bay)
	# Turrets track you.
	for i in 2:
		var turret := boss.part_named("turret%d" % i)
		if turret != null and not turret.dead:
			_piece(ci, "hive_turret", turret.pos, turret, (boss.world.player.pos - turret.pos).angle() - PI * 0.5)
	# Core: armor plates slide apart when it opens.
	var core := boss.part_named("core")
	if core != null and not core.dead:
		var open := 0.0 if core.invulnerable else 44.0
		_piece(ci, "hive_core", core.pos, core, 0.0, 1.0, {"groups": {
			"plate_l": Transform2D(0.0, Vector2(-open, 0)), "plate_r": Transform2D(0.0, Vector2(open, 0)),
			"heart": Transform2D(0.0, Vector2.ONE * (1.0 + sin(time * 6.0) * 0.1), 0.0, Vector2.ZERO)}})


## A great armoured worm: segments with spinning drive gears, and a head whose mandibles snap.
static func _wyrm_engine(ci: CanvasItem, boss: BossBase, time: float) -> void:
	# Tail first so the head draws on top.
	for i in range(WyrmEngine.SEGMENTS - 1, -1, -1):
		var segment := boss.part_named("segment%d" % i)
		if segment != null and not segment.dead:
			_piece(ci, "wyrm_segment", segment.pos, segment, segment.facing + PI * 0.5, 1.0, {"groups": {"gear": Transform2D(time * 2.0, Vector2.ZERO)}})
	var head := boss.part_named("core")
	if head != null and not head.dead:
		var bite := 0.1 + absf(sin(time * 3.0)) * 0.35
		var eye := {} if not head.invulnerable else {"#ff4a3a": Color(0.4, 0.5, 0.46), "#fff4d8": Color(0.6, 0.7, 0.66)}
		_piece(ci, "wyrm_head", head.pos, head, head.facing + PI * 0.5, 1.0, {"remap": eye, "groups": {
			"jaw_l": VectorArt.about(Vector2(-14, -8), -bite, Vector2.ONE), "jaw_r": VectorArt.about(Vector2(14, -8), bite, Vector2.ONE)}})
		if head.invulnerable:
			ci.draw_arc(head.pos, 36.0, 0, TAU, 24, Color(0.7, 0.9, 0.8, 0.6), 4.0, true)

static func _siege_crawler(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	var body_at := boss.origin
	var collapsed := (boss as SiegeCrawler).collapsed
	# Legs: two-joint struts from the body out to each leg turret.
	for i in 4:
		var leg := boss.part_named("leg%d" % i)
		if leg == null or leg.dead:
			continue
		var knee := body_at.lerp(leg.pos, 0.5) + (leg.pos - body_at).orthogonal().normalized() * 26.0 * (1.0 if i % 2 == 0 else -1.0)
		ci.draw_polyline(PackedVector2Array([body_at, knee, leg.pos]), Color(0.35, 0.22, 0.12), 14.0, true)
		ci.draw_polyline(PackedVector2Array([body_at, knee, leg.pos]), Color(1, 0.6, 0.3), 3.0, true)
		ci.draw_circle(leg.pos, 24.0, _flash(leg, Color(0.3, 0.18, 0.1)))
		ci.draw_arc(leg.pos, 24.0, 0, TAU, 20, Color(1, 0.65, 0.35), 2.5, true)
		ci.draw_circle(leg.pos, 8.0, Color(1, 0.75, 0.4, 0.6 + 0.4 * sin(time * 5.0 + i)))
	ci.draw_set_transform(body_at, time * 0.1 if not collapsed else 0.3, Vector2.ONE)
	var hull := Art.ngon(6, 64, PI / 6.0)
	Art.shape(ci, hull, Color(0.22, 0.13, 0.08) if not collapsed else Color(0.14, 0.08, 0.06), Color(1, 0.6, 0.3), 3.0)
	Art.shape(ci, Art.ngon(6, 44, PI / 6.0), Color(0.32, 0.2, 0.12), Color(0.8, 0.45, 0.25), 2.0)
	if collapsed:
		ci.draw_polyline(PackedVector2Array([Vector2(-50, -20), Vector2(-20, 0), Vector2(-30, 30)]), Color(0.05, 0.02, 0.0), 3.0)
		ci.draw_polyline(PackedVector2Array([Vector2(40, -30), Vector2(18, 4), Vector2(44, 26)]), Color(0.05, 0.02, 0.0), 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if core != null and not core.dead:
		var glow := Color(1, 0.55, 0.2) if not core.invulnerable else Color(0.5, 0.35, 0.25)
		ci.draw_circle(core.pos, 30.0, _flash(core, glow.darkened(0.5)))
		ci.draw_circle(core.pos, 18.0 + sin(time * 7.0) * 3.0, glow)
		ci.draw_circle(core.pos, 8.0, Color(1, 0.95, 0.8))


static func _hollow_king(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var king := boss as HollowKing
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var alpha := 0.25 if king.blinking else 1.0
	if boss.entering:
		alpha = clampf(1.0 - float(boss.memory.get("rise", 0.0)) / 1.4, 0.0, 1.0)
	ci.draw_set_transform(core.pos, 0.0, Vector2.ONE)
	var robe := Art.star(7, 46, 30, time * 0.3)
	Art.shape(ci, robe, Color(0.12, 0.06, 0.2, alpha), Color(0.75, 0.55, 1.0, alpha), 2.5)
	ci.draw_circle(Vector2.ZERO, 26.0, _flash(core, Color(0.05, 0.02, 0.1, alpha)))
	ci.draw_arc(Vector2.ZERO, 26.0, 0, TAU, 24, Color(0.6, 0.45, 0.9, alpha), 2.0, true)
	for i in 5:
		var a := -PI * 0.5 + (i - 2) * 0.32
		ci.draw_colored_polygon(PackedVector2Array([Vector2.from_angle(a - 0.1) * 24.0, Vector2.from_angle(a) * 40.0, Vector2.from_angle(a + 0.1) * 24.0]), Color(1, 0.8, 0.35, alpha))
	for side in [-1.0, 1.0]:
		ci.draw_circle(Vector2(8 * side, -2), 5.0, Color(0.9, 0.95, 1.0, alpha * (0.7 + 0.3 * sin(time * 5.0))))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for orb: Enemy in boss.living_parts("orb"):
		ci.draw_circle(orb.pos, 16.0, _flash(orb, Color(0.35, 0.2, 0.6, alpha)))
		Art.shape(ci, Transform2D(time * 2.0, orb.pos) * Art.ngon(4, 12), Color(0.8, 0.65, 1.0, alpha), Color(1, 1, 1, alpha), 1.5)


static func _mirror_dreadnought(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	_piece(ci, "mirror_dreadnought", o)
	# Vents on its back: glowing grilles, smoking once broken.
	for i in MirrorDreadnought.VENT_OFFSETS.size():
		var vent := boss.part_named("vent%d" % i)
		if vent == null:
			continue
		var at: Vector2 = o + MirrorDreadnought.VENT_OFFSETS[i]
		if vent.dead:
			_piece(ci, "dreadnought_vent_broken", at)
			_smoke(ci, at, time)
		else:
			_piece(ci, "dreadnought_vent", at, vent)
	# Mirror plates on its underside: bright, with a shine that sweeps across them.
	for i in MirrorDreadnought.MIRROR_OFFSETS.size():
		var mirror := boss.part_named("mirror%d" % i)
		if mirror == null or mirror.dead:
			continue
		var at: Vector2 = o + MirrorDreadnought.MIRROR_OFFSETS[i]
		_piece(ci, "dreadnought_mirror", at, mirror)
		var sweep := fmod(time * 0.8 + i * 0.2, 1.6) - 0.3
		if sweep >= 0.0 and sweep <= 1.0:
			var x := lerpf(-34, 34, sweep)
			ci.draw_line(at + Vector2(x, -18), at + Vector2(x - 10, 20), Color(1, 1, 1, 0.85), 5.0)
	# The core: a cold blue heart, dark while it's sealed.
	var core := boss.part_named("core")
	if core != null and not core.dead:
		var sealed := {"#5ab4ff": Color(0.22, 0.36, 0.56), "#9ad9ff": Color(0.32, 0.48, 0.68), "#ffffff": Color(0.55, 0.66, 0.82)}
		_piece(ci, "dreadnought_core", core.pos, core, 0.0, 1.0, {"remap": sealed if core.invulnerable else {},
			"groups": {"heart": Transform2D(0.0, Vector2.ONE * (1.0 + sin(time * 5.0) * 0.1), 0.0, Vector2.ZERO)}})

static func _twin_aces(ci: CanvasItem, boss: BossBase, time: float) -> void:
	for ace: Enemy in boss.living_parts("ace"):
		var red := ace.part == "ace0"
		# The blue twin is the same fighter in its own colours.
		var blue := {"#f2507a": Color(0.36, 0.56, 1.0), "#b8325a": Color(0.22, 0.36, 0.76), "#8a2040": Color(0.16, 0.26, 0.58),
			"#ffc2d6": Color(0.8, 0.88, 1.0), "#ffd0e0": Color(0.82, 0.9, 1.0), "#2a0712": Color(0.04, 0.07, 0.18)}
		var trail := Color(1, 0.35, 0.45) if red else Color(0.45, 0.6, 1.0)
		for i in 4:
			ci.draw_circle(ace.pos - Vector2(0, 26 + i * 9), 4.0 - i * 0.8, Art.with_alpha(trail, 0.5 - i * 0.1))
		_ship_down(ci, "twin_ace", ace.pos, ace, 0.8, {"remap": {} if red else blue,
			"groups": {"flame": VectorArt.about(Vector2(0, 22), 0.0, Vector2(1.0, 1.0 + sin(time * 40.0) * 0.2))}})


static func _turret_fortress(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	_piece(ci, "turret_fortress", o)
	# Warning lights that blink along its top edge.
	for i in 4:
		var on := int(time * 3.0 + i) % 2 == 0
		ci.draw_circle(o + Vector2(-380 + i * 254, -74), 6.0, Color(1, 0.3, 0.2) if on else Color(0.35, 0.1, 0.08))
	for i in 3:
		var turret := boss.part_named("turret%d" % i)
		if turret != null and not turret.dead:
			_piece(ci, "fortress_turret", turret.pos, turret, turret.facing - PI * 0.5)
	_core(ci, boss.part_named("core"), time, Color(1.0, 0.5, 0.25))

static func _brood_queen(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	var facing := (boss.world.player.pos - o).angle()
	ci.draw_set_transform(o, facing, Vector2.ONE)
	for leg in 4:
		for side in [-1.0, 1.0]:
			var swing := sin(time * 6.0 + leg) * 8.0
			ci.draw_polyline(PackedVector2Array([Vector2(-30 + leg * 20, 20 * side), Vector2(-26 + leg * 22 + swing, 54 * side), Vector2(-40 + leg * 22, 76 * side)]), Color(0.45, 0.6, 0.25), 5.0, true)
	Art.shape(ci, Art.scaled(Art.ngon(14, 46), Vector2(1.4, 0.9)), Color(0.18, 0.28, 0.1), Color(0.75, 1.0, 0.4), 3.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for sac: Enemy in boss.living_parts("sac"):
		var pulse := 1.0 + sin(time * 4.0 + sac.id) * 0.08
		ci.draw_circle(sac.pos, 26.0 * pulse, _flash(sac, Color(0.55, 0.85, 0.3, 0.9)))
		for e in 5:
			ci.draw_circle(sac.pos + Vector2.from_angle(e * 1.3) * 12.0, 4.0, Color(0.9, 1.0, 0.6))
	var core := boss.part_named("core")
	if core != null and not core.dead:
		ci.draw_circle(core.pos, 28.0, _flash(core, Color(0.25, 0.35, 0.1)))
		for side in [-1.0, 1.0]:
			ci.draw_circle(core.pos + Vector2.from_angle(facing + side * 0.5) * 14.0, 5.0, Color(1, 0.25, 0.2) if not core.invulnerable else Color(0.5, 0.3, 0.3))
		if core.invulnerable:
			ci.draw_arc(core.pos, 34.0, 0, TAU, 24, Color(0.75, 1.0, 0.4, 0.6), 3.0, true)


static func _mimic_king(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var hop: float = core.memory.get("hop", 0.0)
	var lift := sin(clampf(hop / 0.55, 0.0, 1.0) * PI) * 24.0 if hop < 0.55 else 0.0
	ci.draw_circle(core.pos + Vector2(0, 30), 46.0, Color(0, 0, 0, 0.3))
	ci.draw_set_transform(core.pos - Vector2(0, lift), 0.0, Vector2(2.6, 2.6))
	var wood := Color(0.55, 0.32, 0.14) if core.flash <= 0.0 else Color.WHITE
	var open := 0.4 + absf(sin(time * 5.0)) * 0.6
	Art.shape(ci, PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(16, 14), Vector2(-16, 14)]), wood, Art.GOLD, 1.5)
	Art.shape(ci, PackedVector2Array([Vector2(-16, -2), Vector2(-13, -10 - 10 * open), Vector2(13, -10 - 10 * open), Vector2(16, -2)]), wood.lightened(0.1), Art.GOLD, 1.5)
	ci.draw_rect(Rect2(Vector2(-14, -4 - 8 * open), Vector2(28, 6 + 6 * open)), Color(0.3, 0.02, 0.05))
	for i in 6:
		var x := -12.0 + i * 5.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -2), Vector2(x + 2, 3), Vector2(x + 4, -2)]), Color(1, 1, 0.95))
	# The crown.
	ci.draw_colored_polygon(PackedVector2Array([Vector2(-10, -12 - 10 * open), Vector2(-8, -20 - 10 * open), Vector2(-4, -15 - 10 * open), Vector2(0, -22 - 10 * open),
		Vector2(4, -15 - 10 * open), Vector2(8, -20 - 10 * open), Vector2(10, -12 - 10 * open)]), Art.GOLD)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ---------------------------------------------------------------- build 0.3 bosses


## A hologram of your own frame, facing you, with the projector's beam feeding it.
static func _clone_projector(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var clone := boss.part_named("clone")
	var shell := boss.part_named("shell")
	if clone != null and not clone.dead and shell != null and not shell.dead:
		var beam := PackedVector2Array([shell.pos, clone.pos + Vector2(-26, 0), clone.pos + Vector2(26, 0)])
		ci.draw_colored_polygon(beam, Color(0.7, 0.5, 1.0, 0.12 + 0.05 * sin(time * 8.0)))
	if clone != null and not clone.dead:
		draw_hologram(ci, boss.world.run.frame_id, clone.pos, PI * 0.5, time, clone.flash > 0.0, boss.world.run.loadout)
	if shell != null and not shell.dead:
		_piece(ci, "clone_shell", shell.pos, shell, time * 0.4, 1.0, {"groups": {
			"heart": Transform2D(0.0, Vector2.ONE * (1.0 + sin(time * 6.0) * 0.12), 0.0, Vector2.ZERO)}})

static func draw_hologram(ci: CanvasItem, frame_id: String, at: Vector2, facing: float, time: float, hit: bool, loadout: Array = []) -> void:
	var flicker := 0.75 + 0.25 * sin(time * 23.0)
	# Violet, see-through and flickering, with no player rim: a projection, never mistaken for you.
	FrameArt.draw_frame(ci, frame_id, "ship", at, facing, time, {"speed": 0.5, "scale": 1.4, "flash": 1.0 if hit else 0.0,
		"alpha": 0.55 + 0.15 * flicker, "tint": Color(0.75, 0.45, 1.0, 0.6), "rim": Color(0.8, 0.55, 1.0, 0.8),
		"gear": GearArt.loadout_gear(loadout, 3) if not loadout.is_empty() else []})
	# Scanlines rolling over it.
	for i in 7:
		var y := -24.0 + i * 8.0 + fmod(time * 30.0, 8.0)
		ci.draw_line(at + Vector2(-32, y), at + Vector2(32, y), Color(0.85, 0.6, 1.0, 0.55 * flicker), 2.0)
	ci.draw_arc(at, 36.0, 0, TAU, 24, Color(0.8, 0.55, 1.0, 0.7 * flicker), 2.5, true)


static func _bounty_ace(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	for drone: Enemy in boss.living_parts("drone"):
		ci.draw_line(core.pos, drone.pos, Color(1, 0.45, 0.35, 0.7), 2.5)
		_piece(ci, "bounty_drone", drone.pos, drone, time * 3.0)
	# A rival hunter frame, far bigger than yours, with swept blade-wings.
	_ship_down(ci, "bounty_ace", core.pos, core, 1.0, {"groups": {"flame": VectorArt.about(Vector2(0, 40), 0.0, Vector2(1.0, 1.0 + sin(time * 40.0) * 0.15))}})
	if core.invulnerable:
		ci.draw_arc(core.pos, 84.0, 0, TAU, 32, Color(1, 0.8, 0.4, 0.5 + 0.2 * sin(time * 5.0)), 3.0, true)


static func _crusher_gate(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	# The wall is drawn for a half-width of 300 and stretched to however wide this gate is.
	var half_width := float(boss.memory.get("half_width", 300.0))
	VectorArt.draw(ci, ART % "crusher_gate", Transform2D(0.0, Vector2(half_width / 300.0, 1.0), 0.0, o))
	for piston: Enemy in boss.living_parts("piston"):
		var inward := 1.0 if piston.part == "piston0" else -1.0
		var rod := 18.0 + 10.0 * sin(time * 3.0)
		ci.draw_line(piston.pos + Vector2(26 * inward, 0), piston.pos + Vector2((26 + rod) * inward, 0), Color(0.12, 0.1, 0.08), 13.0)
		ci.draw_line(piston.pos + Vector2(26 * inward, 0), piston.pos + Vector2((26 + rod) * inward, 0), Color(0.78, 0.8, 0.86), 9.0)
		_piece(ci, "crusher_piston", piston.pos, piston)
	var core := boss.part_named("core")
	_core(ci, core, time, Color(1.0, 0.72, 0.25))
	if core != null and not core.dead and core.invulnerable:
		ci.draw_arc(core.pos, 38.0, 0, TAU, 20, Color(1, 0.8, 0.4, 0.6), 3.0, true)


## A hull longer than the screen: plated, ribbed, with turret batteries and an engine core at its tail.
static func _leviathan(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	var hull := PackedVector2Array([Vector2(0, 80), Vector2(90, -40), Vector2(150, -200), Vector2(150, -1150), Vector2(110, -1300),
		Vector2(0, -1320), Vector2(-110, -1300), Vector2(-150, -1150), Vector2(-150, -200), Vector2(-90, -40)])
	# It flies overhead: a shadow on the trench floor, and a hull you can half see through.
	ci.draw_colored_polygon(Transform2D(0.0, o + Vector2(40, 30)) * hull, Color(0, 0, 0, 0.3))
	_piece(ci, "leviathan", o, null, 0.0, 1.0, {"alpha": 0.85})
	for i in Leviathan.BATTERIES.size():
		var battery := boss.part_named("battery%d" % i)
		var at: Vector2 = o + Leviathan.BATTERIES[i]
		if battery == null or battery.dead:
			_piece(ci, "leviathan_battery_broken", at)
		else:
			_piece(ci, "leviathan_battery", at, battery, battery.facing - PI * 0.5)
	var core := boss.part_named("core")
	if core != null and not core.dead:
		_piece(ci, "leviathan_engines", core.pos, core, 0.0, 1.0, {"groups": {"glow": VectorArt.about(Vector2(0, -86), 0.0, Vector2.ONE * (1.0 + sin(time * 7.0) * 0.12))}})
		_core(ci, core, time, Color(0.55, 0.85, 1.0), 1.4)

static func _dune_maw(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	if core.hidden:
		# Underground: a churning mound of sand and ripples where it's tunnelling, plain to see.
		ci.draw_circle(boss.origin, 44.0, Color(0.55, 0.42, 0.25, 0.55))
		for i in 6:
			var a := time * 3.0 + TAU * i / 6.0
			ci.draw_circle(boss.origin + Vector2.from_angle(a) * 30.0, 9.0, Color(0.7, 0.55, 0.35, 0.8))
		for i in 3:
			var r := 46.0 + fmod(time * 60.0 + i * 26.0, 78.0)
			ci.draw_arc(boss.origin, r, 0, TAU, 24, Color(1, 0.85, 0.55, 0.85 - r / 150.0), 4.0, true)
		return
	var o := core.pos
	for i in 4:
		ci.draw_circle(o - Vector2.from_angle(core.facing) * (26.0 + i * 22.0), 34.0 - i * 5.0, Color(0.5, 0.38, 0.22).darkened(i * 0.1))
	ci.draw_circle(o, 40.0, _flash(core, Color(0.6, 0.45, 0.25)))
	ci.draw_circle(o, 26.0, Color(0.15, 0.05, 0.05))
	for i in 12:
		var a := TAU * i / 12.0 + time * 0.8
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2.from_angle(a - 0.12) * 26.0, o + Vector2.from_angle(a + 0.12) * 26.0, o + Vector2.from_angle(a) * 14.0]), Color(1, 0.95, 0.85))
	ci.draw_arc(o, 40.0, 0, TAU, 24, Color(1, 0.8, 0.5), 3.0, true)


static func _storm_colossus(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var o := boss.origin
	var kneel := 0.0 if boss.phase == 0 else 1.0
	# Torso: a broad armored mass, crackling with storm light.
	var torso := Art.scaled(Art.ngon(8, 70.0, PI / 8.0), Vector2(1.3, 1.0 - 0.12 * kneel))
	var placed := PackedVector2Array()
	for point in torso:
		placed.append(o + point + Vector2(0, 14 * kneel))
	ci.draw_colored_polygon(placed, Color(0.12, 0.17, 0.26))
	ci.draw_polyline(placed + PackedVector2Array([placed[0]]), Color(0.55, 0.8, 1.0), 3.0, true)
	for i in 5:
		var a := time * 2.0 + i * 1.7
		var from := o + Vector2.from_angle(a) * 30.0
		ci.draw_polyline(PackedVector2Array([from, from + Vector2.from_angle(a + 0.6) * 18.0, from + Vector2.from_angle(a - 0.4) * 34.0]), Color(0.75, 0.95, 1.0, 0.7), 2.0, true)
	for arm: Enemy in boss.living_parts("arm"):
		ci.draw_line(o, arm.pos, Color(0.3, 0.42, 0.6), 18.0)
		Art.shape(ci, PackedVector2Array([arm.pos + Vector2(-28, -24), arm.pos + Vector2(28, -24), arm.pos + Vector2(34, 22), arm.pos + Vector2(-34, 22)]), _flash(arm, Color(0.2, 0.28, 0.4)), Color(0.6, 0.85, 1.0), 2.5)
		ci.draw_circle(arm.pos, 9.0 + sin(time * 9.0 + arm.id) * 2.0, Color(0.8, 0.95, 1.0))
	ci.draw_circle(core.pos, 34.0, _flash(core, Color(0.18, 0.25, 0.38)))
	ci.draw_circle(core.pos + Vector2(0, -4), 12.0, Color(0.8, 0.95, 1.0) if not core.invulnerable else Color(0.4, 0.5, 0.65))
	if core.invulnerable:
		ci.draw_arc(core.pos, 42.0, 0, TAU, 24, Color(0.6, 0.85, 1.0, 0.55), 3.0, true)


static func _gazer(ci: CanvasItem, boss: BossBase, time: float) -> void:
	for eye: Enemy in boss.living_parts("eye"):
		var is_open := not eye.invulnerable
		var lid := PackedVector2Array()
		for i in 17:
			var t := float(i) / 16.0 * TAU
			lid.append(eye.pos + Vector2(cos(t) * 40.0, sin(t) * (24.0 if is_open else 4.0)))
		ci.draw_colored_polygon(lid, _flash(eye, Color(0.95, 0.9, 0.85) if is_open else Color(0.35, 0.2, 0.25)))
		ci.draw_polyline(lid, Color(1, 0.45, 0.6), 3.0, true)
		if is_open:
			var look := Vector2.from_angle(eye.facing) * 10.0
			ci.draw_circle(eye.pos + look, 15.0, Color(0.85, 0.15, 0.3))
			ci.draw_circle(eye.pos + look, 6.0, Color(0.05, 0.0, 0.02))
		for side in [-1.0, 1.0]:
			ci.draw_line(eye.pos + Vector2(40 * side, 0), eye.pos + Vector2(56 * side, -8), Color(1, 0.45, 0.6, 0.6), 2.0)


static func _warden(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var o := core.pos
	for shackle: Enemy in boss.living_parts("shackle"):
		# A heavy chain from the wall shackle to the Warden.
		var links := 10
		for i in links:
			var at := shackle.pos.lerp(o, (i + 0.5) / links) + Vector2(0, sin(time * 2.0 + i) * 3.0)
			ci.draw_arc(at, 6.0, 0, TAU, 8, Color(0.6, 0.55, 0.45), 3.0, true)
		ci.draw_circle(shackle.pos, 20.0, _flash(shackle, Color(0.3, 0.27, 0.22)))
		ci.draw_arc(shackle.pos, 20.0, 0, TAU, 16, Color(0.9, 0.75, 0.5), 3.0, true)
	var flail := boss.part_named("flail")
	if flail != null and not flail.dead:
		var segments := 8
		for i in segments:
			ci.draw_circle(o.lerp(flail.pos, (i + 0.5) / segments), 4.0, Color(0.55, 0.5, 0.42))
		Art.shape(ci, Transform2D(time * 3.0, flail.pos) * Art.star(10, 30.0, 20.0), Color(0.3, 0.28, 0.25), Color(0.85, 0.8, 0.7), 2.0)
	# The jailer: huge pauldrons, a horned helm with burning eyes, and a barred chest like a cell door.
	for side in [-1.0, 1.0]:
		Art.shape(ci, PackedVector2Array([o + Vector2(36 * side, -40), o + Vector2(78 * side, -52), o + Vector2(86 * side, -10), o + Vector2(44 * side, 6)]),
			_flash(core, Color(0.3, 0.26, 0.22)), Color(0.9, 0.75, 0.5), 3.0)
		ci.draw_colored_polygon(PackedVector2Array([o + Vector2(20 * side, -66), o + Vector2(52 * side, -104), o + Vector2(34 * side, -60)]), Color(0.85, 0.8, 0.7))
	var body := PackedVector2Array([o + Vector2(-46, -46), o + Vector2(46, -46), o + Vector2(54, 30), o + Vector2(30, 62), o + Vector2(-30, 62), o + Vector2(-54, 30)])
	ci.draw_colored_polygon(body, _flash(core, Color(0.22, 0.19, 0.17)))
	ci.draw_polyline(body + PackedVector2Array([body[0]]), Color(0.9, 0.75, 0.5), 3.0, true)
	for i in 4:
		ci.draw_line(o + Vector2(-27 + i * 18, -10), o + Vector2(-27 + i * 18, 52), Color(0.5, 0.45, 0.38), 4.0)
	var helm := Transform2D(0.0, o + Vector2(0, -60)) * Art.ngon(6, 26.0, PI / 6.0)
	Art.shape(ci, helm, _flash(core, Color(0.28, 0.24, 0.2)), Color(0.9, 0.75, 0.5), 3.0)
	var eyes := Color(1, 0.5, 0.15) if not core.invulnerable else Color(0.6, 0.35, 0.2)
	for side in [-1.0, 1.0]:
		ci.draw_circle(o + Vector2(10 * side, -60), 5.0, eyes)
	if not core.invulnerable:
		Art.draw_glow(ci, o + Vector2(0, -60), 40.0, Color(1, 0.5, 0.15, 0.5))


# ---------------------------------------------------------------- build 0.3.2 mini-bosses

static func _swarm_marshal(ci: CanvasItem, boss: BossBase, time: float) -> void:
	for escort: Enemy in boss.living_parts("escort"):
		VectorArt.draw(ci, EnemyArt.ART % "dart", Transform2D(0.0, Vector2(0.9, -0.9), 0.0, escort.pos), {"flash": 0.55 if escort.flash > 0.0 else 0.0})
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	# The command carrier: launch bays glowing on both flanks and signal lights blinking in turn.
	var blink := int(time * 4.0) % 2 == 0
	var dim := VectorArt.about(Vector2(-44, -14), 0.0, Vector2.ONE * 0.5)
	_ship_down(ci, "swarm_marshal", core.pos, core, 1.0, {"groups": {
		"light_l": dim if blink else Transform2D.IDENTITY,
		"light_r": Transform2D.IDENTITY if blink else VectorArt.about(Vector2(44, -14), 0.0, Vector2.ONE * 0.5)}})
	if core.invulnerable:
		ci.draw_arc(core.pos, 58.0, 0, TAU, 28, Color(1, 0.55, 0.4, 0.55), 3.0, true)


static func _salvo_barge(ci: CanvasItem, boss: BossBase, time: float) -> void:
	_piece(ci, "salvo_barge", boss.origin)
	for pod: Enemy in boss.living_parts("pod"):
		_piece(ci, "salvo_pod", pod.pos, pod)
	var core := boss.part_named("core")
	_core(ci, core, time, Color(1.0, 0.75, 0.3))
	if core != null and not core.dead and core.invulnerable:
		ci.draw_arc(core.pos, 38.0, 0, TAU, 20, Color(1, 0.8, 0.45, 0.6), 3.0, true)

static func _ring_obelisk(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var o := core.pos
	# A tall four-sided pylon seen from above: a diamond with runes that glow brighter as it wakes.
	var spire := PackedVector2Array([o + Vector2(0, -56), o + Vector2(40, 0), o + Vector2(0, 56), o + Vector2(-40, 0)])
	ci.draw_colored_polygon(spire, _flash(core, Color(0.12, 0.22, 0.2)))
	ci.draw_polyline(spire + PackedVector2Array([spire[0]]), Color(0.5, 1.0, 0.85), 3.0, true)
	for i in 4:
		var glow := 0.4 + 0.4 * sin(time * 3.0 + i)
		ci.draw_circle(o + Vector2.from_angle(PI * 0.5 * i) * 22.0, 4.0, Color(0.6, 1.0, 0.9, glow))
	ci.draw_circle(o, 12.0, Color(0.7, 1.0, 0.9) if not core.invulnerable else Color(0.3, 0.5, 0.45))
	for crystal: Enemy in boss.living_parts("crystal"):
		ci.draw_line(o, crystal.pos, Color(0.5, 1.0, 0.85, 0.35), 2.0)
		Art.shape(ci, Transform2D(time * 2.0, crystal.pos) * Art.ngon(4, 18.0), _flash(crystal, Color(0.2, 0.5, 0.45)), Color(0.75, 1.0, 0.95), 2.0)
	if core.invulnerable:
		ci.draw_arc(o, 64.0, 0, TAU, 28, Color(0.5, 1.0, 0.85, 0.5), 3.0, true)


static func _blade_wraith(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null or core.dead:
		return
	var solid := not core.invulnerable
	var o := core.pos + Vector2(0, sin(time * 2.0) * 5.0)
	# The ghost: a hooded wisp, faint while it's untouchable, bright and solid while its swords are out.
	var alpha := 0.95 if solid else 0.4
	var hood := PackedVector2Array()
	for point in [Vector2(0, -36), Vector2(24, -8), Vector2(18, 30), Vector2(6, 22), Vector2(0, 34), Vector2(-6, 22), Vector2(-18, 30), Vector2(-24, -8)]:
		hood.append(o + point * 1.5)
	Art.draw_glow(ci, o, 70.0, Color(0.6, 0.8, 1.0, 0.25 if not solid else 0.45))
	ci.draw_colored_polygon(hood, Color(0.42, 0.5, 0.66, alpha))
	ci.draw_polyline(hood + PackedVector2Array([hood[0]]), Color(0.7, 0.85, 1.0, alpha), 2.5, true)
	for side in [-1.0, 1.0]:
		ci.draw_circle(o + Vector2(12 * side, -18), 5.0, Color(0.6, 0.9, 1.0, alpha) if solid else Color(0.4, 0.5, 0.6, alpha))
	for sword: Enemy in boss.living_parts("sword"):
		ci.draw_set_transform(sword.pos, sword.facing, Vector2(1.7, 1.7))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(30, 0), Vector2(-6, -4), Vector2(-6, 4)]), Color(0.85, 0.92, 1.0))
		ci.draw_line(Vector2(-6, -9), Vector2(-6, 9), Color(0.75, 0.6, 0.35), 3.0)
		ci.draw_line(Vector2(-6, 0), Vector2(-16, 0), Color(0.45, 0.3, 0.2), 4.0)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
