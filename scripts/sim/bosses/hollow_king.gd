class_name HollowKing
extends BossBase
## Dungeon boss. A Mawjig king that blinks between the pillars of its throne room. At two thirds health
## it snuffs out the lights; at one third the walls themselves fire curtains of bullets with one gap.

var anchors: Array = []
var room: Rect2
var teleport_timer := 0.0
var teleport_to := Vector2.ZERO
var blinking := false


func setup_room(room_rect: Rect2) -> void:
	room = room_rect
	var c := room.get_center()
	anchors = [c + Vector2(-300, -170), c + Vector2(300, -170), c + Vector2(-300, 170), c + Vector2(300, 170), c]


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "The Hollow King"
	title = "Crowned in Empty Light"
	look = "hollow_king"
	color = Color(0.75, 0.55, 1.0)


func spawn() -> void:
	origin = anchors[4]
	add_part("core", Vector2.ZERO, 3000, 34, {"invulnerable": true})
	add_part("orb0", Vector2(70, 0), 260, 16)
	add_part("orb1", Vector2(-70, 0), 260, 16)
	place_parts()
	memory["rise"] = 1.4


func behave(dt: float) -> void:
	var core := part_named("core")
	if entering:
		memory["rise"] = float(memory["rise"]) - dt
		if memory["rise"] <= 0.0:
			entering = false
			core.invulnerable = false
		return
	# Crown orbs circle the king.
	for orb: Enemy in living_parts("orb"):
		var index := float(orb.part.right(1))
		orb.memory["offset"] = Vector2.from_angle(time * 1.6 + PI * index) * 74.0
	place_parts()
	if phase == 0 and hp_fraction() < 0.66:
		set_phase(1, "THE LIGHTS GO OUT")
		world.dark = true
	if phase == 1 and hp_fraction() < 0.33:
		set_phase(2, "THE WALLS ARE WATCHING")
	_teleport(dt, core)
	if blinking:
		return
	var ring_every := 2.0 if phase == 0 else 1.6
	if fmod(time, ring_every) < dt:
		world.enemy_ring(core.pos, 16, 170.0, time * 0.7, {"color": Color(0.75, 0.55, 1.0), "radius": 7.0})
		world.emit("sound", {"name": "enemy_shot"})
	for orb: Enemy in living_parts("orb"):
		if fmod(time + orb.id * 0.5, 1.2) < dt:
			world.enemy_aimed(orb.pos, 1, 0.0, 260.0, {"color": Color(0.9, 0.7, 1.0)})
	if phase >= 1 and fmod(time, 0.14) < dt:
		for arm in 2:
			world.enemy_shot(core.pos, time * -1.5 + PI * arm, 160.0, {"color": Color(0.6, 0.4, 1.0)})
	if fmod(time, 10.0) < dt and world.enemies.size() < 14:
		for i in 2:
			var bot := world.spawn_enemy("skullbot", core.pos + Vector2.from_angle(TAU * i / 2.0) * 60.0)
			bot.room = memory.get("room_key", Vector2i.ZERO)
	if phase == 2 and fmod(time, 2.6) < dt:
		_wall_curtain()


func _teleport(dt: float, core: Enemy) -> void:
	teleport_timer += dt
	var every := 6.0 if phase == 0 else 4.5
	if not blinking and teleport_timer > every:
		blinking = true
		teleport_timer = 0.0
		var choices := anchors.filter(func(a): return a.distance_to(origin) > 10.0)
		teleport_to = choices[world.rng.randi() % choices.size()]
		core.invulnerable = true
		world.emit("telegraph_circle", {"pos": teleport_to, "radius": 50.0, "time": 0.6})
		world.emit("sound", {"name": "blink"})
	elif blinking and teleport_timer > 0.6:
		blinking = false
		teleport_timer = 0.0
		origin = teleport_to
		core.invulnerable = false
		place_parts()
		world.enemy_ring(origin, 10, 200.0, 0.0, {"color": Color(0.75, 0.55, 1.0)})


## A row of bullets from one wall, with a single gap to slip through.
func _wall_curtain() -> void:
	var side := world.rng.randi() % 4
	var count := 22
	var gap := world.rng.randi_range(4, count - 5)
	for i in count:
		if abs(i - gap) <= 1:
			continue
		var t := (float(i) + 0.5) / float(count)
		var at: Vector2
		var angle: float
		match side:
			0:
				at = Vector2(lerpf(room.position.x, room.end.x, t), room.position.y + 50)
				angle = PI * 0.5
			1:
				at = Vector2(lerpf(room.position.x, room.end.x, t), room.end.y - 50)
				angle = -PI * 0.5
			2:
				at = Vector2(room.position.x + 50, lerpf(room.position.y, room.end.y, t))
				angle = 0.0
			_:
				at = Vector2(room.end.x - 50, lerpf(room.position.y, room.end.y, t))
				angle = PI
		world.enemy_shot(at, angle, 150.0, {"color": Color(0.6, 0.4, 1.0), "life": 9.0})
	world.emit("sound", {"name": "curtain"})
