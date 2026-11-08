class_name ShotArt
## Draws shots, pickups and area effects. Enemy bullets are bright rings with white cores in warm colours
## so they always read against the background; player shots are cool and streaky so they never get confused.


## Player shots, on the additive layer.
static func draw_player_shot(ci: CanvasItem, shot: Shot, time: float) -> void:
	var direction := shot.vel.normalized()
	var angle := direction.angle()
	match shot.look:
		"rail":
			var tail := shot.pos - direction * 120.0
			var side := direction.orthogonal()
			var bolt := PackedVector2Array([tail])
			for i in range(1, 7):
				var jitter := sin(shot.pos.x * 0.37 + shot.pos.y * 0.21 + i * 2.7 + time * 40.0) * 9.0
				bolt.append(tail.lerp(shot.pos, i / 7.0) + side * jitter)
			bolt.append(shot.pos)
			ci.draw_polyline(bolt, Art.with_alpha(shot.color, 0.55), 10.0, true)
			ci.draw_polyline(bolt, Color(1, 1, 1, 0.95), 3.0, true)
			Art.draw_glow(ci, shot.pos, 26.0, Art.with_alpha(shot.color, 0.8))
		"missile":
			ci.draw_line(shot.pos - direction * 16.0, shot.pos, Color(1, 0.55, 0.2, 0.7), 5.0, true)
			ci.draw_set_transform(shot.pos, angle, Vector2.ONE)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(7, 0), Vector2(-4, -3), Vector2(-4, 3)]), Color(1, 0.9, 0.75))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			Art.draw_glow(ci, shot.pos - direction * 6.0, 10.0, Color(1, 0.5, 0.2, 0.8))
		"hex", "orb_small":
			var size := 7.0 if shot.look == "hex" else 4.5
			Art.draw_glow(ci, shot.pos, size * 3.0, Art.with_alpha(shot.color, 0.7))
			ci.draw_set_transform(shot.pos, time * 6.0, Vector2.ONE)
			Art.shape(ci, Art.ngon(6, size), Art.with_alpha(shot.color, 0.6), Color(1, 0.9, 1), 1.5)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"crescent":
			ci.draw_set_transform(shot.pos, angle, Vector2.ONE)
			ci.draw_arc(Vector2(-14, 0), 30.0, -1.2, 1.2, 14, Art.with_alpha(shot.color, 0.6), 10.0, true)
			ci.draw_arc(Vector2(-14, 0), 30.0, -1.1, 1.1, 14, Color(1, 1, 1, 0.9), 3.0, true)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"phoenix":
			Art.draw_glow(ci, shot.pos, 22.0, Color(1, 0.5, 0.15, 0.8))
			ci.draw_set_transform(shot.pos, angle, Vector2.ONE)
			var flap := sin(time * 30.0 + shot.pos.x) * 4.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(10, 0), Vector2(-6, -10 - flap), Vector2(-2, 0), Vector2(-6, 10 + flap)]), Color(1, 0.75, 0.3))
			ci.draw_line(Vector2(-2, 0), Vector2(-18, 0), Color(1, 0.4, 0.1, 0.7), 4.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"reflect":
			Art.draw_glow(ci, shot.pos, 14.0, Color(0.6, 1, 1, 0.8))
			ci.draw_set_transform(shot.pos, angle, Vector2.ONE)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(8, 0), Vector2(0, -4), Vector2(-8, 0), Vector2(0, 4)]), Color(0.85, 1, 1))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"bomblet", "shard":
			ci.draw_circle(shot.pos, 3.0, shot.color)
			Art.draw_glow(ci, shot.pos, 9.0, Art.with_alpha(shot.color, 0.7))
		_:
			var length := 14.0 + shot.radius * 1.5
			ci.draw_line(shot.pos - direction * length, shot.pos, Art.with_alpha(shot.color, 0.55), shot.radius * 2.2, true)
			ci.draw_line(shot.pos - direction * length * 0.6, shot.pos, Color(1, 1, 1, 0.95), shot.radius * 0.9, true)


## Enemy bullets, drawn on the normal layer with a glow underneath.
static func draw_enemy_shot(ci: CanvasItem, shot: Shot, time: float) -> void:
	if shot.look == "needle":
		# Long, thin and pointed: a needle, never mistaken for an ordinary round bullet.
		var forward := shot.vel.normalized()
		var tail := shot.pos - forward * 30.0
		ci.draw_line(tail, shot.pos, Art.with_alpha(shot.color, 0.45), 6.0, true)
		ci.draw_line(tail, shot.pos, Color(1, 1, 0.75), 2.0, true)
		ci.draw_colored_polygon(PackedVector2Array([shot.pos + forward * 7.0, shot.pos + forward.orthogonal() * 2.5, shot.pos - forward.orthogonal() * 2.5]), Color(1, 1, 0.9))
		return
	if shot.look == "mine":
		ci.draw_set_transform(shot.pos, time * 3.0, Vector2.ONE)
		Art.shape(ci, Art.star(6, shot.radius + 3.0, shot.radius - 2.0), shot.color.darkened(0.3), shot.color, 1.5)
		var blink := 1.0 if fmod(shot.life, 0.4) < 0.2 else 0.3
		ci.draw_circle(Vector2.ZERO, 3.0, Color(1, 1, 0.8, blink))
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	ci.draw_circle(shot.pos, shot.radius + 1.5, shot.color)
	ci.draw_circle(shot.pos, shot.radius * 0.55, Color(1, 1, 1))
	if shot.slowed:
		ci.draw_arc(shot.pos, shot.radius + 4.0, 0, TAU, 10, Color(0.6, 0.85, 1.0, 0.6), 1.5)


static func draw_enemy_shot_glow(ci: CanvasItem, shot: Shot) -> void:
	Art.draw_glow(ci, shot.pos, shot.radius * 3.6, Art.with_alpha(shot.color, 0.45))


static func draw_pickup(ci: CanvasItem, pickup: Pickup, time: float) -> void:
	var fade := 1.0 if pickup.anchored or pickup.life > 3.0 else (0.4 + 0.6 * float(int(pickup.life * 8.0) % 2))
	var bob := sin(time * 4.0 + pickup.pos.x) * 2.0
	var at := pickup.pos + Vector2(0, bob)
	match pickup.kind:
		"projector":
			# The Clone Projector's device: green like a pickup, with a bouncing arrow over it (GDD 11E).
			Art.shape(ci, Transform2D(time * 1.5, at) * Art.ngon(6, 14.0), Color(0.2, 0.6, 0.3, fade), Color(0.6, 1.0, 0.6, fade), 2.0)
			ci.draw_circle(at, 6.0, Color(0.8, 1.0, 0.8, fade))
			var hop := absf(sin(time * 5.0)) * 10.0
			ci.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -26 - hop), at + Vector2(-11, -44 - hop), at + Vector2(11, -44 - hop)]), Color(0.5, 1.0, 0.5))
		"shard":
			var size := 5.0 if pickup.value < 2.0 else 8.0
			ci.draw_set_transform(at, time * 2.0, Vector2.ONE)
			Art.shape(ci, PackedVector2Array([Vector2(size, 0), Vector2(0, -size * 1.4), Vector2(-size, 0), Vector2(0, size * 1.4)]),
				Color(0.45, 1.0, 0.35, fade), Color(0.9, 1, 0.8, fade), 1.0)
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		"crate":
			Art.shape(ci, PackedVector2Array([at + Vector2(-13, -11), at + Vector2(13, -11), at + Vector2(13, 11), at + Vector2(-13, 11)]),
				Color(0.4, 0.28, 0.08, fade), Color(1, 0.8, 0.3, fade), 2.0)
			ci.draw_line(at + Vector2(-13, -2), at + Vector2(13, -2), Color(1, 0.8, 0.3, fade), 2.0)
			ci.draw_rect(Rect2(at + Vector2(-3, -5), Vector2(6, 7)), Color(1, 0.9, 0.5, fade))
		"blueprint":
			Art.shape(ci, PackedVector2Array([at + Vector2(-12, -9), at + Vector2(12, -9), at + Vector2(12, 9), at + Vector2(-12, 9)]),
				Color(0.12, 0.3, 0.7, fade), Color(0.6, 0.85, 1, fade), 1.5)
			for i in 3:
				ci.draw_line(at + Vector2(-8, -4 + i * 4), at + Vector2(8 - i * 3, -4 + i * 4), Color(0.8, 0.95, 1, fade), 1.0)
		"repair":
			ci.draw_circle(at, 12.0, Color(0.1, 0.35, 0.18, fade))
			ci.draw_arc(at, 12.0, 0, TAU, 20, Color(0.5, 1, 0.6, fade), 2.0, true)
			ci.draw_rect(Rect2(at + Vector2(-2.5, -7), Vector2(5, 14)), Color(0.6, 1, 0.7, fade))
			ci.draw_rect(Rect2(at + Vector2(-7, -2.5), Vector2(14, 5)), Color(0.6, 1, 0.7, fade))
		"key":
			ci.draw_arc(at + Vector2(-6, 0), 7.0, 0, TAU, 16, Art.GOLD, 3.0, true)
			ci.draw_line(at + Vector2(1, 0), at + Vector2(16, 0), Art.GOLD, 3.0)
			ci.draw_line(at + Vector2(12, 0), at + Vector2(12, 6), Art.GOLD, 3.0)
		"pedestal":
			Art.shape(ci, PackedVector2Array([pickup.pos + Vector2(-26, 18), pickup.pos + Vector2(26, 18), pickup.pos + Vector2(18, 4), pickup.pos + Vector2(-18, 4)]),
				Color(0.3, 0.28, 0.32), Color(0.65, 0.6, 0.7), 2.0)
			var card := at + Vector2(0, -24)
			Art.shape(ci, PackedVector2Array([card + Vector2(-12, -16), card + Vector2(12, -16), card + Vector2(12, 16), card + Vector2(-12, 16)]),
				Color(0.35, 0.2, 0.55), Art.GOLD, 2.0)
			ci.draw_string(ThemeDB.fallback_font, card + Vector2(-5, 7), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Art.GOLD)


static func draw_pickup_glow(ci: CanvasItem, pickup: Pickup) -> void:
	var colors := {"shard": Color(0.45, 1.0, 0.35, 0.5), "crate": Color(1, 0.8, 0.3, 0.6), "blueprint": Color(0.4, 0.7, 1.0, 0.6),
		"repair": Color(0.4, 1, 0.5, 0.5), "key": Color(1, 0.85, 0.3, 0.8), "pedestal": Color(1, 0.8, 0.4, 0.6)}
	var radius := 16.0 if pickup.kind == "shard" else 34.0
	Art.draw_glow(ci, pickup.pos, radius, colors.get(pickup.kind, Color(1, 1, 1, 0.4)))


## Area effects: telegraphs read as warnings first (dashed, filling), then become the real thing.
static func draw_zone(ci: CanvasItem, zone: Zone, time: float) -> void:
	if zone.warn > 0.0:
		_draw_warning(ci, zone, time)
		return
	var fade := clampf(zone.life / maxf(zone.max_life, 0.01), 0.0, 1.0)
	match zone.kind:
		"acid":
			ci.draw_circle(zone.pos, zone.radius, Color(0.3, 0.8, 0.2, 0.18 * minf(fade * 3.0, 1.0)))
			for i in 5:
				var bubble := zone.pos + Vector2.from_angle(i * 1.3 + time) * zone.radius * 0.55
				ci.draw_circle(bubble, 3.0 + sin(time * 6.0 + i) * 1.5, Color(0.6, 1, 0.4, 0.6))
		"fire":
			for i in 7:
				var flame := zone.pos + Vector2.from_angle(i * 0.9 + time * 0.5) * zone.radius * (0.3 + 0.5 * fmod(i * 0.37, 1.0))
				Art.draw_glow(ci, flame, 18.0 + sin(time * 9.0 + i) * 5.0, Art.with_alpha(zone.color, 0.5 * fade))
			ci.draw_arc(zone.pos, zone.radius, 0, TAU, 30, Art.with_alpha(zone.color, 0.35 * fade), 3.0, true)
		"black_hole":
			ci.draw_circle(zone.pos, 26.0, Color(0, 0, 0, 0.9))
			for i in 4:
				ci.draw_arc(zone.pos, 30.0 + i * 16.0, time * (3.0 + i), time * (3.0 + i) + 2.5, 16, Color(0.7, 0.4, 1.0, 0.6 - i * 0.12), 3.0, true)
		"ring", "enemy_ring":
			var progress := 1.0 - fade
			var radius := zone.radius * progress
			ci.draw_arc(zone.pos, radius, 0, TAU, 48, Art.with_alpha(zone.color, fade), 10.0 * fade + 2.0, true)
		"laser":
			var end := zone.pos + Vector2.from_angle(zone.angle) * zone.length
			ci.draw_line(zone.pos, end, Art.with_alpha(zone.color, 0.3), zone.width * 2.6, true)
			ci.draw_line(zone.pos, end, Art.with_alpha(zone.color, 0.85), zone.width * 1.3, true)
			ci.draw_line(zone.pos, end, Color(1, 1, 1, 0.95), zone.width * 0.45, true)


static func _draw_warning(ci: CanvasItem, zone: Zone, time: float) -> void:
	var color := Color(1, 0.3, 0.3) if zone.hostile else zone.color
	match zone.kind:
		"laser":
			var end := zone.pos + Vector2.from_angle(zone.angle) * zone.length
			var blink := 0.35 + 0.35 * float(int(time * 14.0) % 2)
			# A sweeping beam shades everything it will cross, so the safe lane is plain to see.
			if zone.spin != 0.0:
				var fan := PackedVector2Array([zone.pos])
				var sweep := zone.spin * zone.life
				for i in 13:
					fan.append(zone.pos + Vector2.from_angle(zone.angle + sweep * i / 12.0) * zone.length)
				ci.draw_colored_polygon(fan, Art.with_alpha(color, 0.07))
				# Laser-path stripes across the swept area and bright edges, so it reads as danger, not scenery.
				for i in 9:
					var stripe := zone.angle + sweep * (i + 0.5) / 9.0
					ci.draw_line(zone.pos, zone.pos + Vector2.from_angle(stripe) * zone.length, Art.with_alpha(color, 0.25 + 0.2 * blink), 3.0, true)
				for edge in [zone.angle, zone.angle + sweep]:
					ci.draw_line(zone.pos, zone.pos + Vector2.from_angle(edge) * zone.length, Art.with_alpha(Color(1, 0.85, 0.85), 0.6 + 0.3 * blink), 3.0, true)
			ci.draw_line(zone.pos, end, Art.with_alpha(color, blink), 2.0, true)
		"ring":
			Art.dashed_circle(ci, zone.pos, zone.radius * 0.25, Art.with_alpha(color, 0.6), 2.0, 10, time * 3.0)
		"meteor":
			# The target circle, plus the meteor itself streaking in toward it.
			Art.dashed_circle(ci, zone.pos, zone.radius, Art.with_alpha(color, 0.85), 2.5, 12, time * 2.0)
			var rock := zone.pos + World.METEOR_FROM * 520.0 * clampf(zone.warn / 0.5, 0.0, 1.0)
			ci.draw_line(rock, rock + World.METEOR_FROM * 90.0, Art.with_alpha(color, 0.5), 10.0, true)
			ci.draw_line(rock, rock + World.METEOR_FROM * 50.0, Color(1, 0.9, 1.0, 0.8), 4.0, true)
			ci.draw_circle(rock, 9.0, Color(1, 0.85, 1.0))
		_:
			var total := 1.1
			var fill := clampf(1.0 - zone.warn / total, 0.0, 1.0)
			ci.draw_circle(zone.pos, zone.radius * fill, Art.with_alpha(color, 0.18))
			Art.dashed_circle(ci, zone.pos, zone.radius, Art.with_alpha(color, 0.85), 2.5, 12, time * 2.0)


## Tractor Beam's pull: a thin shimmering ribbon from the frame to a drop, drawn on the additive layer.
static func draw_tractor_beam(ci: CanvasItem, from: Vector2, to: Vector2, time: float) -> void:
	var color := Color(0.5, 1.0, 0.85)
	var shimmer := 0.18 + 0.1 * sin(time * 12.0 + to.x * 0.05)
	ci.draw_line(from, to, Art.with_alpha(color, shimmer), 7.0, true)
	ci.draw_line(from, to, Art.with_alpha(color, shimmer + 0.15), 1.5, true)
	ci.draw_arc(to, 11.0, 0, TAU, 12, Art.with_alpha(color, 0.5), 1.5, true)
