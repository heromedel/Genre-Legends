class_name Fx
extends RefCounted
## Visual effects that only exist for the eye: particles, explosion rings, lightning, floating text,
## telegraph lines and the like. Built from the simulation's events; never touches the simulation.
## Uses its own randomness, which is fine because nothing here affects play.

const MAX_PARTICLES := 700


class Particle:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life := 1.0
	var max_life := 1.0
	var size := 3.0
	var color := Color.WHITE
	var drag := 2.0
	var kind := 0          # 0 spark (line), 1 glow dot, 2 smoke, 3 debris chunk
	var spin := 0.0


var particles: Array = []
var rings: Array = []           # {pos, radius, life, max_life, color, width}
var bolts: Array = []           # lightning {points, life}
var texts: Array = []           # {pos, text, color, life}
var telegraphs: Array = []      # {pos, angle, length, life, max_life} or circles {pos, radius, ...}
var lobs: Array = []            # {from, to, life, max_life}
var slashes: Array = []         # enemy slash arcs {pos, angle, life}
var halo: Dictionary = {}       # latest Orbital Halo saw positions
var rng := RandomNumberGenerator.new()


func handle(event: Dictionary, world: World) -> void:
	match event["type"]:
		"explosion":
			explosion(event["pos"], event["size"], event["color"], event.get("ring", false))
		"spark":
			sparks(event["pos"], event["color"], 5 if not event.get("blocked", false) else 8, 220.0)
		"slash_hit":
			sparks(event["pos"], Color(0.7, 1, 1), 6, 260.0)
		"ricochet":
			sparks(event["pos"], Color(0.6, 0.95, 1), 4, 180.0)
		"lightning":
			lightning(event["from"], event["to"])
		"player_hit":
			sparks(event["pos"], Color(1, 0.6, 0.4), 12, 260.0)
			ring(event["pos"], 40.0, 0.25, Color(1, 0.5, 0.4), 3.0)
		"graze":
			sparks(event["pos"] + Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14)), Color(1, 0.9, 0.5), 2, 120.0)
		"floating_text":
			texts.append({"pos": event["pos"], "text": event["text"], "color": event["color"], "life": 1.4})
		"telegraph":
			telegraphs.append({"pos": event["pos"], "angle": event["angle"], "length": event["length"], "life": event["time"], "max_life": event["time"]})
		"telegraph_circle":
			telegraphs.append({"pos": event["pos"], "radius": event["radius"], "life": event["time"], "max_life": event["time"]})
		"lob":
			lobs.append({"from": event["from"], "to": event["to"], "life": event["time"], "max_life": event["time"]})
		"slash_enemy":
			slashes.append({"pos": event["pos"], "angle": event["angle"], "life": 0.25})
		"halo":
			halo = event
		"spawn_in":
			ring(event["pos"], 34.0, 0.35, Color(0.8, 0.5, 1.0), 3.0)
			sparks(event["pos"], Color(0.8, 0.6, 1.0), 6, 120.0)
		"burst_ground":
			debris(event["pos"], Color(0.5, 0.4, 0.3), 14)
		"boss_part_destroyed":
			explosion(event["pos"], 70.0, Color(1, 0.7, 0.4), true)
			debris(event["pos"], Color(0.5, 0.4, 0.35), 16)
		"level_up":
			ring(world.player.pos, 120.0, 0.6, Color(0.5, 1, 0.9), 5.0)
			sparks(world.player.pos, Color(0.6, 1, 0.9), 20, 300.0)
		"stage_start":
			ring(world.player.pos, 130.0, 0.9, Color(0.6, 0.9, 1.0), 6.0)
			sparks(world.player.pos, Color(0.7, 0.95, 1.0), 26, 340.0)
		"crate_opened":
			sparks(world.player.pos, Color(1, 0.85, 0.4), 24, 300.0)


func explosion(at: Vector2, size: float, color: Color, with_ring: bool) -> void:
	var count := clampi(int(size * 0.5), 6, 34)
	for i in count:
		var p := Particle.new()
		p.pos = at
		p.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(60.0, 260.0) * (size / 30.0)
		p.max_life = rng.randf_range(0.25, 0.6)
		p.life = p.max_life
		p.size = rng.randf_range(2.0, 4.5)
		p.color = color.lerp(Color(1, 0.95, 0.8), rng.randf() * 0.6)
		p.kind = 0
		_add(p)
	for i in count / 3:
		var p := Particle.new()
		p.pos = at + Vector2.from_angle(rng.randf() * TAU) * rng.randf() * size * 0.3
		p.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(10.0, 60.0)
		p.max_life = rng.randf_range(0.3, 0.7)
		p.life = p.max_life
		p.size = size * rng.randf_range(0.5, 0.9)
		p.color = color.lerp(Color(1, 0.9, 0.6), 0.4)
		p.kind = 1
		p.drag = 4.0
		_add(p)
	if with_ring or size > 30.0:
		ring(at, size * 1.3, 0.35, color, 4.0)


func sparks(at: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		var p := Particle.new()
		p.pos = at
		p.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(speed * 0.4, speed)
		p.max_life = rng.randf_range(0.15, 0.35)
		p.life = p.max_life
		p.size = 2.0
		p.color = color
		p.kind = 0
		p.drag = 5.0
		_add(p)


func debris(at: Vector2, color: Color, count: int) -> void:
	for i in count:
		var p := Particle.new()
		p.pos = at
		p.vel = Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(80.0, 280.0)
		p.max_life = rng.randf_range(0.5, 1.0)
		p.life = p.max_life
		p.size = rng.randf_range(3.0, 7.0)
		p.color = color
		p.kind = 3
		p.spin = rng.randf_range(-10.0, 10.0)
		p.drag = 3.0
		_add(p)


func ring(at: Vector2, radius: float, life: float, color: Color, width: float) -> void:
	rings.append({"pos": at, "radius": radius, "life": life, "max_life": life, "color": color, "width": width})


func lightning(from: Vector2, to: Vector2) -> void:
	var points := PackedVector2Array([from])
	var steps := 6
	for i in range(1, steps):
		var t := float(i) / steps
		var offset := (to - from).orthogonal().normalized() * rng.randf_range(-16.0, 16.0)
		points.append(from.lerp(to, t) + offset)
	points.append(to)
	bolts.append({"points": points, "life": 0.16})


func _add(p: Particle) -> void:
	if particles.size() >= MAX_PARTICLES:
		particles.pop_front()
	particles.append(p)


func update(dt: float) -> void:
	for p: Particle in particles:
		p.life -= dt
		p.pos += p.vel * dt
		p.vel *= maxf(0.0, 1.0 - p.drag * dt)
	particles = particles.filter(func(p): return p.life > 0.0)
	for list in [rings, bolts, texts, telegraphs, lobs, slashes]:
		for item in list:
			item["life"] -= dt
	rings = rings.filter(func(r): return r["life"] > 0.0)
	bolts = bolts.filter(func(b): return b["life"] > 0.0)
	texts = texts.filter(func(t): return t["life"] > 0.0)
	telegraphs = telegraphs.filter(func(t): return t["life"] > 0.0)
	lobs = lobs.filter(func(l): return l["life"] > 0.0)
	slashes = slashes.filter(func(s): return s["life"] > 0.0)


## Drawn on the additive layer.
func draw(ci: CanvasItem, font: Font) -> void:
	for p: Particle in particles:
		var fade := p.life / p.max_life
		match p.kind:
			0:
				ci.draw_line(p.pos, p.pos - p.vel * 0.03, Art.with_alpha(p.color, fade), p.size, true)
			1:
				Art.draw_glow(ci, p.pos, p.size * (1.4 - fade * 0.4), Art.with_alpha(p.color, fade * 0.8))
			3:
				var corner := Vector2.from_angle(p.spin * p.life) * p.size
				ci.draw_colored_polygon(PackedVector2Array([p.pos + corner, p.pos + corner.orthogonal(), p.pos - corner]), Art.with_alpha(p.color, fade))
	for r in rings:
		var progress: float = 1.0 - r["life"] / r["max_life"]
		ci.draw_arc(r["pos"], r["radius"] * ease(progress, 0.4), 0, TAU, 40, Art.with_alpha(r["color"], 1.0 - progress), r["width"] * (1.0 - progress) + 1.0, true)
	for bolt in bolts:
		ci.draw_polyline(bolt["points"], Color(0.6, 0.85, 1.0, 0.6), 6.0, true)
		ci.draw_polyline(bolt["points"], Color(1, 1, 1), 2.0, true)
	for telegraph in telegraphs:
		var blink := 0.3 + 0.5 * float(int(telegraph["life"] * 14.0) % 2)
		if telegraph.has("angle"):
			var end: Vector2 = telegraph["pos"] + Vector2.from_angle(telegraph["angle"]) * telegraph["length"]
			ci.draw_line(telegraph["pos"], end, Color(1, 0.3, 0.3, blink), 4.0, true)
		else:
			Art.dashed_circle(ci, telegraph["pos"], telegraph["radius"], Color(1, 0.4, 0.4, blink), 3.0, 10, telegraph["life"] * 4.0)
	for lob in lobs:
		var t: float = 1.0 - lob["life"] / lob["max_life"]
		var at: Vector2 = lob["from"].lerp(lob["to"], t) + Vector2(0, -sin(t * PI) * 120.0)
		ci.draw_circle(at, 7.0, Color(0.6, 1.0, 0.4))
		Art.draw_glow(ci, at, 20.0, Color(0.5, 1.0, 0.4, 0.6))
	for slash in slashes:
		var fade: float = slash["life"] / 0.25
		ci.draw_arc(slash["pos"], 70.0, slash["angle"] - 0.9, slash["angle"] + 0.9, 16, Color(0.75, 0.8, 1.0, fade), 6.0, true)
	if not halo.is_empty():
		for saw: Vector2 in halo["saws"]:
			Art.draw_glow(ci, saw, 22.0, Color(1, 0.85, 0.5, 0.6))
	for text in texts:
		var rise: float = (1.4 - text["life"]) * 40.0
		ci.draw_string_outline(font, text["pos"] + Vector2(-60, -30 - rise), text["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 15, 4, Color(0, 0, 0, 0.8))
		ci.draw_string(font, text["pos"] + Vector2(-60, -30 - rise), text["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 15, Art.with_alpha(text["color"], minf(text["life"], 1.0)))
