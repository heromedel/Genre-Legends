class_name EnemyArt
## Draws every regular enemy by its "look". Each one gets its own silhouette so a glance tells you
## what it does: darts are arrows, wasps are striped, knights carry a shield plate, mimics are chests.
## The art lives in res://art/enemies/<look>.svg in the five-pass style (VectorArt), authored facing up at
## a nominal radius of 16 and scaled to the enemy's radius. Moving parts are named groups, set here each
## frame: wings flap, legs scuttle, sacs swell, a pupil follows its target.

const ART := "res://art/enemies/%s.svg"
## Looks seen from above that don't turn to face where they're going (they look at the camera).
const UPRIGHT := ["skullbot", "wisp", "pillar_eye", "mimic", "gloop", "nest"]


static func draw(ci: CanvasItem, enemy: Enemy, time: float) -> void:
	if enemy.hidden and enemy.look != "burrower":
		return
	# Drawn a little larger than the hitbox: shots that graze the art still miss, which feels fair.
	var scale := enemy.radius / 16.0 * 1.2
	var t := time + enemy.id * 0.37
	if enemy.look == "cracked_wall":
		_draw_cracked_wall(ci, enemy, t)
	elif enemy.look == "burrower" and enemy.hidden:
		_draw_burrow_mound(ci, enemy, t, scale)
	else:
		var file := _file(enemy)
		if not FileAccess.file_exists(file):
			file = ART % "dart"
		var turn := 0.0 if enemy.look in UPRIGHT else enemy.facing + PI * 0.5
		var size := Vector2(scale, scale)
		if enemy.look == "gloop":
			size *= Vector2(1.0 + sin(t * 5.0) * 0.1, 1.0 - sin(t * 5.0) * 0.1)
		elif enemy.look == "nest":
			size *= 1.0 + sin(t * 3.0) * 0.04
		VectorArt.draw(ci, file, Transform2D(turn, size, 0.0, enemy.pos), {
			"flash": 1.0 if enemy.flash > 0.0 else 0.0,
			"alpha": 0.9 if enemy.look == "wisp" else 1.0,
			"rim": Art.with_alpha(enemy.color, 0.45),
			"groups": _moving_parts(enemy, t)})
	if enemy.unstable:
		Art.dashed_circle(ci, enemy.pos, enemy.radius + 8.0, Color(0.85, 0.45, 1.0, 0.8), 2.0, 6, time * 2.0)
	_draw_elite_twist(ci, enemy, time)
	if (enemy.elite or enemy.objective) and enemy.hp < enemy.max_hp:
		_health_bar(ci, enemy)


## Which drawing the enemy wears right now (a sleeping Mimic is just a chest).
static func _file(enemy: Enemy) -> String:
	if enemy.look == "mimic" and enemy.state == 0:
		return ART % "mimic_closed"
	return ART % enemy.look


## Where each moving part is this frame, in the art's own space (facing up).
static func _moving_parts(enemy: Enemy, t: float) -> Dictionary:
	var flicker := 1.0 + sin(t * 40.0) * 0.18
	match enemy.look:
		"dart", "ace", "barge":
			var nozzle: float = {"dart": 9.0, "ace": 13.0, "barge": 15.0}[enemy.look]
			return {"flame": VectorArt.about(Vector2(0, nozzle), 0.0, Vector2(1.0, flicker))}
		"drill":
			return {"flame": VectorArt.about(Vector2(0, 10), 0.0, Vector2(1.0, flicker)),
				"bands": Transform2D(0.0, Vector2(0.0, fmod(t * 24.0, 6.0) - 3.0))}
		"wasp":
			var flap := 0.55 + absf(sin(t * 30.0)) * 0.65
			return {"wing_l": VectorArt.about(Vector2(-3, -4), 0.0, Vector2(flap, 1.0)), "wing_r": VectorArt.about(Vector2(3, -4), 0.0, Vector2(flap, 1.0))}
		"splitter":
			var seam := 0.6 + absf(sin(t * 6.0)) * 1.6
			return {"half_l": Transform2D(0.0, Vector2(-seam, 0)), "half_r": Transform2D(0.0, Vector2(seam, 0))}
		"minelayer":
			return {"core": VectorArt.about(Vector2(0, 7), 0.0, Vector2.ONE * (1.0 + sin(t * 8.0) * 0.15))}
		"crawler":
			var step := sin(t * 18.0) * 0.28
			return {"legs_a": Transform2D(step, Vector2.ZERO), "legs_b": Transform2D(-step, Vector2.ZERO)}
		"spitter":
			return {"sac": VectorArt.about(Vector2(0, 4), 0.0, Vector2.ONE * (1.0 + sin(t * 4.0) * 0.14))}
		"burrower":
			return {"maw": Transform2D(t * 3.0, Vector2.ZERO)}
		"nest":
			return {"core": Transform2D(0.0, Vector2.ONE * (1.0 + sin(t * 5.0) * 0.12), 0.0, Vector2.ZERO)}
		"warlord":
			# The banner ripples on its pole.
			return {"banner": VectorArt.about(Vector2(-1, -18), 0.0, Vector2(1.0 + sin(t * 4.0) * 0.12, 1.0))}
		"wisp":
			return {"flame": VectorArt.about(Vector2(0, 10), 0.0, Vector2(1.0, 1.0 + sin(t * 7.0) * 0.1))}
		"pillar_eye":
			return {"pupil": Transform2D(0.0, Vector2.from_angle(enemy.facing) * 3.0)}
		"mimic":
			# The lid lifts and the dark mouth stretches open beneath it.
			var open := 0.5 + absf(sin(t * 7.0)) * 0.5
			return {"lid": Transform2D(0.0, Vector2(0, -7.0 * open)), "mouth": VectorArt.about(Vector2(0, 1), 0.0, Vector2(1.0, 1.0 + open))}
		"knight":
			# Knocked aside, the shield hangs off its arm and leaves the front open.
			return {} if enemy.front_shield else {"shield": VectorArt.about(Vector2(-13, -12), -1.2, Vector2.ONE) * Transform2D(0.0, Vector2(-2, 14))}
		"cluster_drone":
			return {"pods": Transform2D(t, Vector2.ZERO)}
		"centi_segment":
			return {"legs": Transform2D(sin(t * 14.0) * 0.2, Vector2.ZERO)}
	return {}


## A burrower underground: churned earth circling where it will surface.
static func _draw_burrow_mound(ci: CanvasItem, enemy: Enemy, t: float, scale: float) -> void:
	ci.draw_set_transform(enemy.pos, 0.0, Vector2(scale, scale))
	for i in 6:
		var a := TAU * i / 6.0 + t * 2.0
		ci.draw_circle(Vector2.from_angle(a) * (10 + sin(t * 9.0 + i) * 3.0), 4.0, Color(0.45, 0.35, 0.25, 0.8))
	ci.draw_circle(Vector2.ZERO, 7.0, Color(0.3, 0.22, 0.15, 0.8))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## A cracked dungeon wall: cracks drawn on the wall itself, spreading as it takes damage.
static func _draw_cracked_wall(ci: CanvasItem, enemy: Enemy, t: float) -> void:
	ci.draw_set_transform(enemy.pos, 0.0, Vector2.ONE)
	var damage := 1.0 - enemy.hp / enemy.max_hp
	var crack := Color(0.1, 0.08, 0.07)
	ci.draw_polyline(PackedVector2Array([Vector2(-18, -14), Vector2(-6, -4), Vector2(-10, 6), Vector2(2, 14)]), crack, 2.5)
	ci.draw_polyline(PackedVector2Array([Vector2(10, -16), Vector2(4, -2), Vector2(16, 8)]), crack, 2.0)
	if damage > 0.3:
		ci.draw_polyline(PackedVector2Array([Vector2(-20, 10), Vector2(-4, 4), Vector2(8, 18)]), crack, 2.0)
	ci.draw_circle(Vector2.ZERO, 3.0, Color(1, 0.85, 0.5, 0.25 + 0.2 * sin(t * 2.0)))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## What an elite's twist looks like, so you can read what it asks of your build at a glance.
static func _draw_elite_twist(ci: CanvasItem, enemy: Enemy, time: float) -> void:
	var r := enemy.radius + 9.0
	match enemy.elite_mod:
		"shielded":
			if enemy.shield_hp > 0.0:
				Art.shape(ci, Transform2D(time * 0.8, enemy.pos) * Art.ngon(6, r), Color(0.4, 0.85, 1.0, 0.12),
					Color(0.5, 0.9, 1.0, 0.75 + 0.2 * sin(time * 6.0)), 2.5)
		"splitting":
			# A glowing fault line: it's going to come apart.
			var a := Vector2.from_angle(0.8) * r
			ci.draw_polyline(PackedVector2Array([enemy.pos - a, enemy.pos - a * 0.3 + a.orthogonal() * 0.15, enemy.pos + a * 0.3 - a.orthogonal() * 0.15, enemy.pos + a]),
				Color(0.6, 1.0, 0.5, 0.85), 2.5, true)
		"mirrored":
			ci.draw_arc(enemy.pos, r, 0, TAU, 24, Color(0.85, 0.95, 1.0, 0.8), 2.5, true)
			for i in 3:
				var glint := enemy.pos + Vector2.from_angle(time * 2.5 + TAU * i / 3.0) * r
				ci.draw_line(glint - Vector2(4, 0), glint + Vector2(4, 0), Color(1, 1, 1), 2.0)
				ci.draw_line(glint - Vector2(0, 4), glint + Vector2(0, 4), Color(1, 1, 1), 2.0)


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
