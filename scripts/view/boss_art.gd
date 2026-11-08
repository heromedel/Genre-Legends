class_name BossArt
## Draws each boss as one big set piece (GDD 6H proposal) from its parts' live state:
## broken bays smoke, armor plates slide open, legs buckle, the king fades between pillars.


static func draw(ci: CanvasItem, boss: BossBase, time: float) -> void:
	match boss.look:
		"hive_carrier": _hive_carrier(ci, boss, time)
		"wyrm_engine": _wyrm_engine(ci, boss, time)
		"siege_crawler": _siege_crawler(ci, boss, time)
		"hollow_king": _hollow_king(ci, boss, time)


static func draw_glow(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var core := boss.part_named("core")
	if core == null:
		return
	var pulse := 0.5 + sin(time * 4.0) * 0.15
	Art.draw_glow(ci, core.pos, core.radius * 4.0, Art.with_alpha(boss.color, pulse * (0.8 if not core.invulnerable else 0.35)))
	for part: Enemy in boss.parts:
		if not part.dead and part.part != "core":
			Art.draw_glow(ci, part.pos, part.radius * 2.2, Art.with_alpha(boss.color, 0.3))


static func _flash(part: Enemy, color: Color) -> Color:
	return Color.WHITE if part != null and part.flash > 0.0 else color


static func _hive_carrier(ci: CanvasItem, boss: BossBase, time: float) -> void:
	var o := boss.origin
	var hull := PackedVector2Array([
		Vector2(-330, -40), Vector2(-260, -70), Vector2(-90, -84), Vector2(90, -84), Vector2(260, -70), Vector2(330, -40),
		Vector2(300, 20), Vector2(170, 60), Vector2(70, 92), Vector2(-70, 92), Vector2(-170, 60), Vector2(-300, 20)])
	ci.draw_set_transform(o, 0.0, Vector2.ONE)
	Art.shape(ci, hull, Color(0.16, 0.08, 0.1), Color(1.0, 0.45, 0.4), 3.0)
	Art.shape(ci, Art.scaled(hull, Vector2(0.82, 0.6)), Color(0.24, 0.12, 0.14), Color(0.7, 0.3, 0.3), 1.5)
	# Panel lines and running lights.
	for i in 9:
		var x := -240.0 + i * 60.0
		ci.draw_line(Vector2(x, -60), Vector2(x * 0.9, 40), Color(0.4, 0.18, 0.2), 1.0)
		var blink := 0.4 + 0.6 * float(int(time * 2.0 + i) % 3 == 0)
		ci.draw_circle(Vector2(x, -70 + absf(x) * 0.05), 2.5, Color(1, 0.5, 0.4, blink))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	# Hangar bays.
	for i in 4:
		var bay := boss.part_named("bay%d" % i)
		if bay == null:
			continue
		var at: Vector2 = o + bay.memory["offset"]
		if bay.dead:
			ci.draw_rect(Rect2(at - Vector2(26, 14), Vector2(52, 28)), Color(0.05, 0.03, 0.03))
			for s in 3:
				ci.draw_circle(at + Vector2(sin(time * 3.0 + s * 2.0) * 10.0, -10.0 - fmod(time * 30.0 + s * 12.0, 36.0)), 6.0 + s * 2.0, Color(0.2, 0.2, 0.2, 0.5))
		else:
			ci.draw_rect(Rect2(at - Vector2(28, 16), Vector2(56, 32)), _flash(bay, Color(0.35, 0.12, 0.12)))
			ci.draw_rect(Rect2(at - Vector2(22, 8), Vector2(44, 18)), Color(1, 0.35, 0.25, 0.6 + 0.3 * sin(time * 6.0 + i)))
			ci.draw_rect(Rect2(at - Vector2(28, 16), Vector2(56, 32)), Color(1, 0.55, 0.45), false, 2.0)
	# Turrets track you.
	for i in 2:
		var turret := boss.part_named("turret%d" % i)
		if turret == null or turret.dead:
			continue
		ci.draw_circle(turret.pos, 16.0, _flash(turret, Color(0.3, 0.15, 0.15)))
		ci.draw_arc(turret.pos, 16.0, 0, TAU, 18, Color(1, 0.55, 0.45), 2.0, true)
		var aim := (boss.world.player.pos - turret.pos).angle()
		ci.draw_line(turret.pos, turret.pos + Vector2.from_angle(aim) * 26.0, Color(1, 0.7, 0.6), 6.0)
	# Core: armor plates slide apart when it opens.
	var core := boss.part_named("core")
	if core != null and not core.dead:
		var open := 0.0 if core.invulnerable else 1.0
		ci.draw_circle(core.pos, 40.0, _flash(core, Color(0.3, 0.05, 0.08)))
		ci.draw_circle(core.pos, 26.0 + sin(time * 6.0) * 3.0, Color(1, 0.3, 0.35))
		ci.draw_circle(core.pos, 12.0, Color(1, 0.9, 0.8))
		for side in [-1.0, 1.0]:
			var slide: float = side * (8.0 + 44.0 * open)
			Art.shape(ci, PackedVector2Array([core.pos + Vector2(slide, -44), core.pos + Vector2(slide + side * 40, -36),
				core.pos + Vector2(slide + side * 40, 36), core.pos + Vector2(slide, 44)]), Color(0.4, 0.2, 0.2), Color(1, 0.5, 0.45), 2.0)


static func _wyrm_engine(ci: CanvasItem, boss: BossBase, time: float) -> void:
	# Tail first so the head draws on top.
	for i in range(WyrmEngine.SEGMENTS - 1, -1, -1):
		var segment := boss.part_named("segment%d" % i)
		if segment == null or segment.dead:
			continue
		ci.draw_set_transform(segment.pos, segment.facing, Vector2.ONE)
		Art.shape(ci, Art.ngon(8, 22, PI / 8.0), _flash(segment, Color(0.1, 0.25, 0.18)), Color(0.5, 1.0, 0.75), 2.5)
		Art.shape(ci, Art.ngon(8, 13, PI / 8.0 + time), Color(0.15, 0.4, 0.3), Color(0.7, 1.0, 0.85), 1.5)
		for side in [-1.0, 1.0]:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(-6, 20 * side), Vector2(4, 34 * side), Vector2(8, 18 * side)]), Color(0.6, 0.9, 0.75))
	var head := boss.part_named("core")
	if head != null and not head.dead:
		ci.draw_set_transform(head.pos, head.facing, Vector2.ONE)
		var bite := 0.2 + absf(sin(time * 3.0)) * 0.5
		for side in [-1.0, 1.0]:
			Art.shape(ci, PackedVector2Array([Vector2(10, 14 * side), Vector2(52, (10 + 18 * bite) * side), Vector2(36, 4 * side)]), Color(0.75, 0.9, 0.8), Color(0.9, 1, 0.95), 1.5)
		var shell := Art.mirrored(PackedVector2Array([Vector2(34, 0), Vector2(22, -18), Vector2(-6, -30), Vector2(-26, -22), Vector2(-30, 0)]))
		Art.shape(ci, shell, _flash(head, Color(0.08, 0.22, 0.16)), Color(0.5, 1.0, 0.75), 3.0)
		var eye := Color(1, 0.3, 0.3) if not head.invulnerable else Color(0.5, 0.6, 0.55)
		ci.draw_circle(Vector2(12, 0), 9.0, eye)
		ci.draw_circle(Vector2(14, 0), 4.0, Color(1, 1, 0.9))
		if head.invulnerable:
			ci.draw_arc(Vector2(0, 0), 28.0, -2.2, 2.2, 16, Color(0.7, 0.85, 0.8), 5.0, true)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
