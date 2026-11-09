class_name WyrmEngine
extends BossBase
## Corridor Run boss. A segmented mechanical serpent snakes through the corridor. Its head is armored
## until you shoot away half its segments; then it starts charging at you along telegraphed lines.

const SEGMENTS := 12
const SPACING := 7               # trail samples between segments

var trail: Array = []
var charge_dir := Vector2.ZERO
var charge_time := 0.0


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Wyrm Engine"
	title = "The Corridor's End"
	look = "wyrm_engine"
	color = Color(0.5, 1.0, 0.75)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, -120)
	add_part("core", Vector2.ZERO, 2000, 32, {"invulnerable": true})
	for i in SEGMENTS:
		add_part("segment%d" % i, Vector2.ZERO, 150, 22)
	for i in SEGMENTS * SPACING + 2:
		trail.append(origin)
	_place()


func behave(dt: float) -> void:
	var head := part_named("core")
	var segments := living_parts("segment")
	if entering:
		origin = origin.move_toward(Vector2(world.bounds.get_center().x, 220), 260.0 * dt)
		if origin.y >= 219.0:
			entering = false
	elif charge_time > 0.0:
		charge_time -= dt
		if charge_time < 1.0:
			origin += charge_dir * 760.0 * dt
			origin = origin.clamp(world.bounds.position + Vector2(40, 40), world.bounds.end - Vector2(40, 140))
	else:
		var center := world.bounds.get_center()
		var target := Vector2(center.x + sin(time * 0.75) * 400.0, 230.0 + sin(time * 1.3) * 140.0)
		origin = origin.move_toward(target, 260.0 * dt)
	trail.push_front(origin)
	trail.pop_back()
	_place()
	if phase == 0 and segments.size() <= SEGMENTS / 2:
		head.invulnerable = false
		set_phase(1, "HEAD EXPOSED")
	if phase == 1 and hp_fraction() < 0.25:
		set_phase(2, "THE WYRM IS ENRAGED")
	# Segments fire in a rolling wave down the body.
	if fmod(time, 2.6) < dt:
		var start := int(time / 2.6) % 3
		for i in range(start, segments.size(), 3):
			world.enemy_aimed(segments[i].pos, 1, 0.0, 220.0, {"color": Color(0.5, 1.0, 0.7)})
	if entering or charge_time > 0.0:
		return
	if fmod(time, 1.8) < dt:
		world.enemy_aimed(head.pos, 5 if phase == 0 else 7, 0.8, 250.0, {"radius": 7.0})
		world.emit("sound", {"name": "enemy_shot"})
	if phase >= 1 and fmod(time, 8.0) < dt:
		charge_dir = (world.player.pos - origin).normalized()
		charge_time = 1.8
		world.emit("telegraph", {"pos": origin, "angle": charge_dir.angle(), "length": 900.0, "time": 0.8})
		world.emit("sound", {"name": "charge"})
	if phase == 2 and fmod(time, 2.2) < dt:
		for segment: Enemy in segments:
			world.enemy_ring(segment.pos, 4, 140.0, time, {"color": Color(0.5, 1.0, 0.7)})


func _place() -> void:
	var head := part_named("core")
	if not head.dead:
		head.pos = origin
		if trail.size() > 2:
			head.facing = (trail[0] - trail[2]).angle() if trail[0] != trail[2] else PI * 0.5
	for i in SEGMENTS:
		var segment := part_named("segment%d" % i)
		if segment == null or segment.dead:
			continue
		var index := mini((i + 1) * SPACING, trail.size() - 1)
		segment.pos = trail[index]
		segment.facing = (trail[maxi(index - 2, 0)] - trail[index]).angle()
