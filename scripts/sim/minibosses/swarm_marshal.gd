class_name SwarmMarshal
extends BossBase
## Star Cluster mini-boss: a command ship that drills its escort into formations (a ring around itself,
## a wedge aimed at you, a wall that sweeps down the field) and sends escorts diving at you one by one.
## Its core is shielded while half the escort still flies.

const ESCORTS := 8
const SHAPES := ["ring", "wedge", "wall"]


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Swarm Marshal"
	title = "On My Mark"
	look = "swarm_marshal"
	color = Color(1.0, 0.5, 0.35)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, -120)
	add_part("core", Vector2.ZERO, 900, 30, {"invulnerable": true})
	for i in ESCORTS:
		add_part("escort%d" % i, Vector2.ZERO, 120, 14)
	_place_escorts(0.0)


func behave(dt: float) -> void:
	var core := part_named("core")
	var escorts := living_parts("escort")
	if entering:
		origin.y = move_toward(origin.y, 150.0, 180.0 * dt)
		if origin.y >= 150.0:
			entering = false
	else:
		glide_to(Vector2(world.bounds.get_center().x + sin(time * 0.6) * 300.0, origin.y), 260.0, dt)
	core.pos = origin
	_place_escorts(dt)
	if phase == 0 and escorts.size() <= ESCORTS / 2:
		core.invulnerable = false
		set_phase(1, "THE MARSHAL HAS NO ESCORT LEFT")
	if entering:
		return
	# One escort peels off and dives at you, Galaga style.
	if fmod(time, 2.2) < dt and not escorts.is_empty():
		var diver: Enemy = escorts[world.rng.randi() % escorts.size()]
		diver.dead = true
		var dart := world.spawn_enemy("dart", diver.pos, {"elite": false})
		dart.memory["no_formation"] = true
		dart.vel = (world.player.pos - diver.pos).normalized() * 300.0
		world.emit("sound", {"name": "dive"})
	if fmod(time, 1.6) < dt:
		world.enemy_aimed(core.pos, 3 if phase == 0 else 5, 0.5, 260.0, {"color": Color(1, 0.55, 0.4)})
	for escort: Enemy in escorts:
		if fmod(time + escort.id * 0.37, 3.0) < dt:
			world.enemy_aimed(escort.pos, 1, 0.0, 240.0, {"color": Color(1, 0.6, 0.45)})


## The escorts glide into the current formation, which changes every few seconds.
func _place_escorts(dt: float) -> void:
	var shape: String = SHAPES[int(time / 5.0) % SHAPES.size()]
	var escorts := living_parts("escort")
	var to_player := (world.player.pos - origin).normalized()
	for i in escorts.size():
		var escort: Enemy = escorts[i]
		var slot := origin
		match shape:
			"ring":
				slot = origin + Vector2.from_angle(time * 1.2 + TAU * i / escorts.size()) * 90.0
			"wedge":
				var rank := (i + 1) / 2
				var side := -1.0 if i % 2 == 0 else 1.0
				slot = origin + to_player * (60.0 - rank * 26.0) + to_player.orthogonal() * side * rank * 34.0
			"wall":
				var sweep := fmod(time, 5.0) / 5.0
				slot = Vector2(origin.x - 210.0 + i * 60.0, origin.y + 60.0 + sweep * 220.0)
		escort.pos = escort.pos.lerp(slot, 1.0 if dt == 0.0 else minf(1.0, 4.0 * dt))
		escort.facing = PI * 0.5


func part_lost(part: Enemy) -> void:
	if part.part == "core":
		defeat()
