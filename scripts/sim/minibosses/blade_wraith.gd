class_name BladeWraith
extends BossBase
## Dungeon mini-boss: a ghost in an empty room, three swords circling it. The swords can't be broken and
## cut whatever they touch. Every few seconds they line up on you (the lines show first) and dash;
## while its swords are thrown the ghost turns solid and can be hurt.

var room: Rect2


func setup_room(room_rect: Rect2) -> void:
	room = room_rect


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Blade Wraith"
	title = "Three Swords, No Hands"
	look = "blade_wraith"
	color = Color(0.7, 0.85, 1.0)


func spawn() -> void:
	if room.size == Vector2.ZERO:
		room = Rect2(world.bounds.get_center() - Vector2(400, 260), Vector2(800, 520))
	origin = room.get_center() + Vector2(0, -60)
	add_part("core", Vector2.ZERO, 1200, 36, {"invulnerable": true})
	for i in 3:
		var sword := add_part("sword%d" % i, Vector2.from_angle(TAU * i / 3.0) * 90.0, 1, 24, {"invulnerable": true, "contact": MissionData.HIT_BODY * world.enemy_damage_scale})
		sword.memory["unbreakable"] = true
	place_parts()
	memory["state"] = "circle"
	memory["timer"] = 1.5


func behave(dt: float) -> void:
	var core := part_named("core")
	var swords := living_parts("sword")
	memory["timer"] = float(memory["timer"]) - dt
	# The ghost keeps its distance, drifting to stay about 260 away from you inside its room; its swords do the work.
	var walk := room.grow(-80.0)
	var away := (origin - world.player.pos)
	var keep := world.player.pos + (away.normalized() if away.length() > 1.0 else Vector2.UP) * 260.0
	origin = origin.move_toward(keep, 60.0 * dt).clamp(walk.position, walk.end)
	core.pos = origin
	match memory["state"]:
		"circle":
			for sword: Enemy in swords:
				var index := int(sword.part.right(1))
				sword.pos = origin + Vector2.from_angle(time * 2.4 + TAU * index / 3.0) * 90.0
				sword.facing = (sword.pos - origin).angle()
			if memory["timer"] <= 0.0:
				entering = false
				memory["state"] = "aim"
				memory["timer"] = 0.8
				for sword: Enemy in swords:
					sword.memory["dir"] = (world.player.pos - sword.pos).normalized()
					sword.facing = (sword.memory["dir"] as Vector2).angle()
					world.emit("telegraph", {"pos": sword.pos, "angle": sword.facing, "length": 700.0, "time": 0.8})
				world.emit("sound", {"name": "charge"})
		"aim":
			if memory["timer"] <= 0.0:
				memory["state"] = "dash"
				memory["timer"] = 0.7
				core.invulnerable = false
				world.emit("sound", {"name": "slash"})
		"dash":
			for sword: Enemy in swords:
				sword.pos = (sword.pos + (sword.memory["dir"] as Vector2) * 900.0 * dt).clamp(room.position, room.end)
			if memory["timer"] <= 0.0:
				memory["state"] = "return"
				memory["timer"] = 1.8
		"return":
			for sword: Enemy in swords:
				var index := int(sword.part.right(1))
				var home := origin + Vector2.from_angle(time * 2.4 + TAU * index / 3.0) * 90.0
				sword.pos = sword.pos.move_toward(home, 500.0 * dt)
			if memory["timer"] <= 0.0:
				core.invulnerable = true
				memory["state"] = "circle"
				memory["timer"] = 2.6 if hp_fraction() > 0.5 else 1.8
	if fmod(time, 2.4) < dt:
		world.enemy_ring(core.pos, 10, 150.0, time, {"color": Color(0.9, 0.55, 1.0)})


func part_lost(part: Enemy) -> void:
	if part.part == "core":
		defeat()
