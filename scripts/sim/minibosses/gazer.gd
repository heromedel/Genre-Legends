class_name Gazer
extends BossBase
## Dungeon mini-boss: two great eyes set into the room take turns opening. Shut, they can't be hurt.
## Open, an eye locks a beam onto you (the line shows first) and the other spits rings. Close one for
## good and the survivor stares wider and longer.

var room: Rect2


func setup_room(room_rect: Rect2) -> void:
	room = room_rect


func spawn() -> void:
	boss_name = "Gazer"
	title = "It Sees You"
	look = "gazer"
	color = Color(1.0, 0.45, 0.6)
	if room.size == Vector2.ZERO:
		room = Rect2(world.bounds.get_center() - Vector2(400, 260), Vector2(800, 520))
	origin = room.get_center()
	add_part("eye0", Vector2(-room.size.x * 0.3, -room.size.y * 0.3), 420, 30, {"invulnerable": true})
	add_part("eye1", Vector2(room.size.x * 0.3, -room.size.y * 0.3), 420, 30, {"invulnerable": true})
	place_parts()
	memory["open"] = "eye0"
	memory["timer"] = 1.2


func behave(dt: float) -> void:
	var eyes := living_parts("eye")
	if entering:
		memory["timer"] = float(memory["timer"]) - dt
		if memory["timer"] <= 0.0:
			entering = false
			memory["timer"] = 0.0
		return
	if phase == 0 and eyes.size() == 1:
		set_phase(1, "THE OTHER EYE WIDENS")
	memory["timer"] = float(memory["timer"]) - dt
	if memory["timer"] <= 0.0:
		_open_next(eyes)
	for eye: Enemy in eyes:
		var is_open := not eye.invulnerable
		eye.facing = (world.player.pos - eye.pos).angle()
		if not is_open and fmod(time + eye.id * 0.3, 2.2) < dt:
			world.enemy_ring(eye.pos, 10, 140.0, time, {"color": Color(1, 0.5, 0.65)})
	# A small drift so the eyes feel alive.
	for eye: Enemy in eyes:
		var base: Vector2 = eye.memory.get("offset", Vector2.ZERO)
		eye.pos = origin + base + Vector2(sin(time * 1.3 + eye.id), cos(time * 0.9 + eye.id)) * 12.0


## Shuts the open eye and opens the next one, which locks its beam onto you.
func _open_next(eyes: Array) -> void:
	if eyes.is_empty():
		return
	var next: Enemy = eyes[0]
	for eye: Enemy in eyes:
		eye.invulnerable = true
		if eye.part != memory["open"]:
			next = eye
	if eyes.size() == 1:
		next = eyes[0]
	next.invulnerable = false
	memory["open"] = next.part
	memory["timer"] = 3.2 if phase == 0 else 4.2
	var aim := (world.player.pos - next.pos).angle()
	world.add_zone("laser", next.pos, 0.0, 0.5, 18.0 * world.enemy_damage_scale, true,
		{"warn": 1.0, "angle": aim, "length": 1100.0, "width": 26.0, "color": Color(1, 0.45, 0.6)})
	if phase == 1:
		world.add_zone("laser", next.pos, 0.0, 0.5, 18.0 * world.enemy_damage_scale, true,
			{"warn": 1.6, "angle": aim + 0.35, "length": 1100.0, "width": 26.0, "color": Color(1, 0.45, 0.6)})
	world.emit("sound", {"name": "charge"})


func part_lost(_part: Enemy) -> void:
	if living_parts("eye").is_empty():
		defeat()
