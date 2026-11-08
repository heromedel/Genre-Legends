class_name EnemyArt
## Draws every regular enemy by its "look". Each one gets its own silhouette so a glance tells you
## what it does: darts are arrows, wasps are striped, knights carry a shield plate, mimics are chests.
## Shapes are drawn facing +x at a nominal radius of 16, then scaled to the enemy's radius.


static func draw(ci: CanvasItem, enemy: Enemy, time: float) -> void:
	if enemy.hidden and enemy.look != "burrower":
		return
	# Drawn a little larger than the hitbox: shots that graze the art still miss, which feels fair.
	var scale := enemy.radius / 16.0 * 1.2
	var color := enemy.color
	var flash := enemy.flash > 0.0
	ci.draw_set_transform(enemy.pos, enemy.facing, Vector2(scale, scale))
	var body := color.darkened(0.55) if not flash else Color(1, 1, 1)
	var line := color if not flash else Color(1, 1, 1)
	var t := time + enemy.id * 0.37
	match enemy.look:
		"dart":
			Art.shape(ci, PackedVector2Array([Vector2(18, 0), Vector2(-10, -13), Vector2(-4, 0), Vector2(-10, 13)]), body, line, 2.0)
			ci.draw_circle(Vector2(4, 0), 3.0, Color(1, 1, 1))
		"wasp":
			Art.shape(ci, Art.scaled(Art.ngon(10, 14), Vector2(1.2, 0.7)), body, line, 2.0)
			for i in 3:
				ci.draw_line(Vector2(-8 + i * 7, -9), Vector2(-8 + i * 7, 9), Color(0.1, 0.08, 0.02), 3.0)
			var flap := 0.6 + absf(sin(t * 30.0)) * 0.6
			for side in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(0, 6 * side), Vector2(-14, 22 * side * flap), Vector2(6, 18 * side * flap)]), Color(1, 1, 1, 0.35))
		"splitter":
			var seam := 2.0 + sin(t * 6.0) * 1.5
			for side in [-1.0, 1.0]:
				Art.shape(ci, PackedVector2Array([Vector2(14, seam * side), Vector2(4, 15 * side), Vector2(-12, 12 * side), Vector2(-14, seam * side)]), body, line, 2.0)
			ci.draw_line(Vector2(14, 0), Vector2(-14, 0), Color(0.8, 1, 0.8), 2.0)
		"bulwark_wing":
			Art.shape(ci, Art.ngon(5, 12), body, line, 2.0)
			var plate := Art.arc_points(Vector2(-6, 0), 22.0, -1.25, 1.25, 10)
			ci.draw_polyline(plate, Color(0.7, 0.85, 1.0), 6.0, true)
			ci.draw_polyline(plate, Color(1, 1, 1, 0.8), 2.0, true)
		"minelayer":
			Art.shape(ci, PackedVector2Array([Vector2(12, -16), Vector2(12, 16), Vector2(-12, 12), Vector2(-12, -12)]), body, line, 2.0)
			ci.draw_circle(Vector2(-2, 0), 6.0, Color(1, 0.5, 0.3, 0.8 + sin(t * 8.0) * 0.2))
		"ace":
			Art.shape(ci, PackedVector2Array([Vector2(22, 0), Vector2(-2, -6), Vector2(-14, -20), Vector2(-8, 0), Vector2(-14, 20), Vector2(-2, 6)]), body, line, 2.0)
			ci.draw_line(Vector2(-6, 0), Vector2(14, 0), Color(1, 0.8, 0.9), 2.0)
		"barge":
			Art.shape(ci, Art.scaled(Art.ngon(12, 16), Vector2(1.5, 0.8)), body, line, 2.0)
			for i in 3:
				var box := Rect2(Vector2(-14 + i * 10, -5), Vector2(8, 10))
				ci.draw_rect(box, Color(1, 0.85, 0.35))
				ci.draw_rect(box, Color(0.4, 0.3, 0.1), false, 1.0)
		"turret":
			Art.shape(ci, Art.ngon(8, 14), body, line, 2.0)
			ci.draw_rect(Rect2(Vector2(0, -4), Vector2(22, 8)), line)
			ci.draw_circle(Vector2.ZERO, 5.0, Color(1, 0.9, 0.7))
		"drill":
			Art.shape(ci, PackedVector2Array([Vector2(22, 0), Vector2(-10, -12), Vector2(-10, 12)]), body, line, 2.0)
			for i in 3:
				var x := fmod(t * 60.0 + i * 10.0, 30.0) - 10.0
				ci.draw_line(Vector2(x, -12 + (x + 10) * 0.37), Vector2(x, 12 - (x + 10) * 0.37), line, 1.5)
		"crawler":
			for leg in 3:
				for side in [-1.0, 1.0]:
					var swing := sin(t * 18.0 + leg * 2.0) * 4.0
					ci.draw_line(Vector2(-6 + leg * 6, 0), Vector2(-8 + leg * 7 + swing, 15 * side), line.darkened(0.2), 2.0, true)
			Art.shape(ci, Art.scaled(Art.ngon(8, 12), Vector2(1.3, 0.85)), body, line, 2.0)
			ci.draw_circle(Vector2(10, -4), 2.5, Color(1, 0.3, 0.3))
			ci.draw_circle(Vector2(10, 4), 2.5, Color(1, 0.3, 0.3))
		"spitter":
			Art.shape(ci, Art.ngon(9, 14), body, line, 2.0)
			var sac := 7.0 + sin(t * 4.0) * 2.0
			ci.draw_circle(Vector2(-6, 0), sac, Color(0.5, 1.0, 0.4, 0.7))
			ci.draw_circle(Vector2(10, 0), 4.0, Color(0.2, 0.3, 0.1))
		"sentry":
			for i in 3:
				ci.draw_line(Vector2.ZERO, Vector2.from_angle(TAU * i / 3.0 + PI) * 18.0, line.darkened(0.3), 3.0)
			Art.shape(ci, Art.ngon(6, 11), body, line, 2.0)
			ci.draw_rect(Rect2(Vector2(4, -3), Vector2(18, 6)), line)
		"brute":
			Art.shape(ci, Art.ngon(6, 16), body, line, 2.5)
			Art.shape(ci, Art.ngon(6, 10), color.darkened(0.3), line.lightened(0.2), 1.5)
			for side in [-1.0, 1.0]:
				ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 10 * side), Vector2(22, 16 * side), Vector2(12, 4 * side)]), Color(0.95, 0.9, 0.8))
		"burrower":
			if enemy.hidden:
				ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
				for i in 6:
					var a := TAU * i / 6.0 + t * 2.0
					ci.draw_circle(Vector2.from_angle(a) * (10 + sin(t * 9.0 + i) * 3.0), 4.0, Color(0.45, 0.35, 0.25, 0.8))
				ci.draw_circle(Vector2.ZERO, 7.0, Color(0.3, 0.22, 0.15, 0.8))
			else:
				Art.shape(ci, Art.ngon(10, 14), body, line, 2.0)
				Art.shape(ci, Art.star(5, 12, 5, t), Color(0.15, 0.05, 0.05), Color(1, 0.5, 0.4), 1.5)
		"nest":
			var pulse := 1.0 + sin(t * 3.0) * 0.05
			Art.shape(ci, Art.scaled(Art.ngon(14, 16), Vector2(pulse, pulse)), body, line, 2.5)
			for i in 6:
				var egg := Vector2.from_angle(TAU * i / 6.0 + 0.3) * 9.0
				ci.draw_circle(egg, 3.5, color.lightened(0.3))
			ci.draw_circle(Vector2.ZERO, 5.0, Color(1, 0.6, 1.0, 0.6 + sin(t * 5.0) * 0.3))
		"warlord":
			Art.shape(ci, Art.ngon(6, 16), body, line, 2.5)
			Art.shape(ci, Art.star(5, 11, 6, -PI * 0.5), Color(1, 0.8, 0.3), Color(1, 0.95, 0.6), 1.0)
			ci.draw_rect(Rect2(Vector2(6, 12), Vector2(18, 5)), line)
		"skullbot":
			ci.draw_circle(Vector2.ZERO, 15.0, body)
			ci.draw_arc(Vector2.ZERO, 15.0, 0, TAU, 20, line, 2.0, true)
			ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
			for side in [-1.0, 1.0]:
				ci.draw_circle(Vector2(5 * side, -3), 4.5, Color(0, 0, 0))
				ci.draw_circle(Vector2(5 * side, -3), 2.0, Color(1, 0.3, 0.3))
			for i in 4:
				ci.draw_rect(Rect2(Vector2(-6 + i * 3.2, 6), Vector2(2, 4)), Color(0.9, 0.9, 0.85))
		"wisp":
			ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
			for i in 4:
				var flicker := sin(t * 7.0 + i) * 2.0
				ci.draw_circle(Vector2(0, -i * 4 + flicker), 12.0 - i * 2.5, Color(color.r, color.g, color.b, 0.25 + i * 0.12))
			ci.draw_circle(Vector2(-3, 0), 2.0, Color.WHITE)
			ci.draw_circle(Vector2(3, 0), 2.0, Color.WHITE)
		"pillar_eye":
			ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
			Art.shape(ci, Art.ngon(8, 16, PI / 8.0), Color(0.25, 0.22, 0.28), Color(0.5, 0.45, 0.55), 2.0)
			ci.draw_circle(Vector2.ZERO, 8.0, Color(1, 1, 1))
			ci.draw_circle(Vector2.from_angle(enemy.facing) * 3.0, 4.0, color)
			ci.draw_circle(Vector2.from_angle(enemy.facing) * 3.0, 2.0, Color(0, 0, 0))
		"mimic":
			_draw_mimic(ci, enemy, t, scale, flash)
		"gloop":
			ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
			var wobble := Vector2(1.0 + sin(t * 5.0) * 0.1, 1.0 - sin(t * 5.0) * 0.1)
			Art.shape(ci, Art.scaled(Art.ngon(14, 15), wobble), Art.with_alpha(color.darkened(0.3), 0.9), line, 2.0)
			ci.draw_circle(Vector2(-5, -5), 4.0, Color(1, 1, 1, 0.6))
			ci.draw_circle(Vector2(3, 0), 2.0, Color(0, 0.1, 0))
			ci.draw_circle(Vector2(-2, 1), 2.0, Color(0, 0.1, 0))
		"knight":
			Art.shape(ci, Art.ngon(6, 13), body, line, 2.0)
			ci.draw_circle(Vector2(2, 0), 4.0, Color(0.6, 0.8, 1.0))
			var shield := PackedVector2Array([Vector2(12, -16), Vector2(20, -10), Vector2(22, 0), Vector2(20, 10), Vector2(12, 16)])
			if not enemy.front_shield:
				shield = Transform2D(1.4, Vector2(-4, 6)) * shield
			ci.draw_polyline(shield, Color(0.75, 0.8, 1.0) if enemy.front_shield else Color(0.5, 0.5, 0.6), 6.0, true)
			ci.draw_polyline(shield, Color(1, 1, 1), 2.0, true)
		"cluster_drone":
			for i in 4:
				var pod := Vector2.from_angle(TAU * i / 4.0 + t) * 8.0
				Art.shape(ci, Transform2D(0, pod) * Art.ngon(4, 7, PI / 4.0), body, line, 1.5)
			ci.draw_circle(Vector2.ZERO, 6.0, Color(1, 0.8, 0.95))
		"drone_shard":
			Art.shape(ci, PackedVector2Array([Vector2(14, 0), Vector2(-8, -9), Vector2(-4, 0), Vector2(-8, 9)]), body, line, 1.5)
		"centi_head":
			Art.shape(ci, Art.scaled(Art.ngon(8, 15), Vector2(1.2, 1.0)), body, line, 2.0)
			for side in [-1.0, 1.0]:
				ci.draw_line(Vector2(10, 6 * side), Vector2(22, 12 * side), line, 3.0)
			ci.draw_circle(Vector2(8, -5), 3.0, Color(1, 0.3, 0.2))
			ci.draw_circle(Vector2(8, 5), 3.0, Color(1, 0.3, 0.2))
		"centi_segment":
			Art.shape(ci, Art.ngon(6, 14), body, line, 2.0)
			for side in [-1.0, 1.0]:
				var swing := sin(t * 14.0) * 3.0
				ci.draw_line(Vector2(0, 12 * side), Vector2(swing, 22 * side), line.darkened(0.2), 2.5)
		"cracked_wall":
			ci.draw_set_transform(enemy.pos, 0.0, Vector2.ONE)
			var damage := 1.0 - enemy.hp / enemy.max_hp
			var crack := Color(0.1, 0.08, 0.07)
			ci.draw_polyline(PackedVector2Array([Vector2(-18, -14), Vector2(-6, -4), Vector2(-10, 6), Vector2(2, 14)]), crack, 2.5)
			ci.draw_polyline(PackedVector2Array([Vector2(10, -16), Vector2(4, -2), Vector2(16, 8)]), crack, 2.0)
			if damage > 0.3:
				ci.draw_polyline(PackedVector2Array([Vector2(-20, 10), Vector2(-4, 4), Vector2(8, 18)]), crack, 2.0)
			ci.draw_circle(Vector2.ZERO, 3.0, Color(1, 0.85, 0.5, 0.25 + 0.2 * sin(t * 2.0)))
		_:
			Art.shape(ci, Art.ngon(6, 14), body, line, 2.0)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if enemy.hex_marked:
		Art.dashed_circle(ci, enemy.pos, enemy.radius + 8.0, Color(0.85, 0.45, 1.0, 0.8), 2.0, 6, time * 2.0)
	if (enemy.elite or enemy.objective) and enemy.hp < enemy.max_hp:
		_health_bar(ci, enemy)


static func _draw_mimic(ci: CanvasItem, enemy: Enemy, t: float, scale: float, flash: bool) -> void:
	ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
	var wood := Color(0.55, 0.32, 0.14) if not flash else Color.WHITE
	var gold := Color(1, 0.8, 0.3)
	if enemy.state == 0:
		Art.shape(ci, PackedVector2Array([Vector2(-16, -6), Vector2(16, -6), Vector2(16, 12), Vector2(-16, 12)]), wood, gold, 2.0)
		Art.shape(ci, PackedVector2Array([Vector2(-16, -6), Vector2(-13, -15), Vector2(13, -15), Vector2(16, -6)]), wood.lightened(0.1), gold, 2.0)
		ci.draw_rect(Rect2(Vector2(-3, -8), Vector2(6, 7)), gold)
		return
	var open := 0.5 + absf(sin(t * 7.0)) * 0.5
	Art.shape(ci, PackedVector2Array([Vector2(-16, 0), Vector2(16, 0), Vector2(16, 14), Vector2(-16, 14)]), wood, gold, 2.0)
	Art.shape(ci, PackedVector2Array([Vector2(-16, -2), Vector2(-13, -10 - 10 * open), Vector2(13, -10 - 10 * open), Vector2(16, -2)]), wood.lightened(0.1), gold, 2.0)
	ci.draw_rect(Rect2(Vector2(-14, -4 - 8 * open), Vector2(28, 6 + 6 * open)), Color(0.3, 0.02, 0.05))
	for i in 6:
		var x := -12.0 + i * 5.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, -2), Vector2(x + 2, 3), Vector2(x + 4, -2)]), Color(1, 1, 0.95))
	ci.draw_circle(Vector2(0, -2 - 6 * open), 3.0, Color(1, 0.4, 0.6))


static func _health_bar(ci: CanvasItem, enemy: Enemy) -> void:
	var width := maxf(enemy.radius * 2.4, 36.0)
	var at := enemy.pos + Vector2(-width * 0.5, -enemy.radius - 14.0)
	ci.draw_rect(Rect2(at, Vector2(width, 5)), Color(0, 0, 0, 0.6))
	ci.draw_rect(Rect2(at, Vector2(width * clampf(enemy.hp / enemy.max_hp, 0, 1), 5)), enemy.color.lightened(0.2))


## Glow under each enemy on the additive layer, so the field reads in the dark.
static func draw_glow(ci: CanvasItem, enemy: Enemy) -> void:
	if enemy.hidden or enemy.look == "cracked_wall":
		return
	var strength := 0.28 if not enemy.elite else 0.5
	Art.draw_glow(ci, enemy.pos, enemy.radius * 2.6, Art.with_alpha(enemy.color, strength))
