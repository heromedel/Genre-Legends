class_name Warden
extends BossBase
## Dungeon boss: the dungeon's jailer, chained to the floor by two shackles and swinging a great flail.
## The flail can't be hurt and blocks shots. Break the shackles and the Warden breaks free: its core is
## exposed, it stalks you, the flail swings wider, and its stomps send shockwaves through the room.

## How far the Warden's stomp shockwaves reach (shown before each one lands).
const STOMP_RADIUS := 320.0

var room: Rect2


func setup_room(room_rect: Rect2) -> void:
	room = room_rect


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "The Warden"
	title = "No One Leaves"
	look = "warden"
	color = Color(0.85, 0.7, 0.5)


func spawn() -> void:
	if room.size == Vector2.ZERO:
		room = Rect2(world.bounds.get_center() - Vector2(400, 260), Vector2(800, 520))
	origin = room.get_center() + Vector2(0, -40)
	add_part("core", Vector2.ZERO, 3200, 52, {"invulnerable": true})
	add_part("shackle0", Vector2(-room.size.x * 0.4, 0), 440, 20)
	add_part("shackle1", Vector2(room.size.x * 0.4, 0), 440, 20)
	var flail := add_part("flail", Vector2(170, 0), 1, 26, {"invulnerable": true, "contact": MissionData.HIT_BODY * world.enemy_damage_scale})
	flail.memory["unbreakable"] = true
	place_parts()
	memory["rise"] = 1.3


func behave(dt: float) -> void:
	var core := part_named("core")
	var flail := part_named("flail")
	var shackles := living_parts("shackle")
	if entering:
		memory["rise"] = float(memory["rise"]) - dt
		_swing(flail, 120.0)
		if memory["rise"] <= 0.0:
			entering = false
		return
	if phase == 0 and shackles.is_empty():
		core.invulnerable = false
		set_phase(1, "THE WARDEN BREAKS FREE")
		world.add_zone("enemy_ring", origin, STOMP_RADIUS, 0.9, MissionData.HIT_BODY * world.enemy_damage_scale, true, {"warn": 0.8, "color": Color(0.9, 0.7, 0.45)})
	if phase == 1 and hp_fraction() < 0.35:
		set_phase(2, "LOCKDOWN")
	# Chained: it stays put. Free: it stalks you across the room.
	if phase >= 1:
		var walk := room.grow(-90.0)
		origin = origin.move_toward(world.player.pos, (55.0 if phase == 1 else 75.0) * dt).clamp(walk.position, walk.end)
	core.pos = origin
	for shackle: Enemy in shackles:
		shackle.pos = origin + Vector2((-1.0 if shackle.part == "shackle0" else 1.0) * room.size.x * 0.4, 0)
	_swing(flail, 170.0 if phase == 0 else (220.0 if phase == 1 else 260.0))
	if fmod(time, 2.0) < dt:
		world.enemy_aimed(core.pos, 5, 0.6, 230.0, {"color": Color(0.95, 0.75, 0.5)})
		world.emit("sound", {"name": "enemy_shot"})
	if phase == 0 and fmod(time, 6.0) < dt and world.enemies.filter(func(e): return e.kind == "skullbot").size() < 4:
		for side in [-1.0, 1.0]:
			var guard := world.spawn_enemy("skullbot", origin + Vector2(side * 90.0, 60.0))
			guard.memory["awake"] = true
	if phase >= 1 and fmod(time, 4.0) < dt:
		# Each stomp shows its reach first; step outside the line and it can't touch you.
		world.add_zone("enemy_ring", origin, STOMP_RADIUS, 0.9, MissionData.HIT_BODY * world.enemy_damage_scale, true, {"warn": 0.8, "color": Color(0.9, 0.7, 0.45)})
		world.emit("shake", {"amount": 9.0})
		world.emit("sound", {"name": "door_slam"})
	if phase == 2 and fmod(time, 3.0) < dt:
		for i in 4:
			var at := world.player.pos + Vector2.from_angle(TAU * i / 4.0 + time) * 110.0
			world.add_zone("bomb_warning", at, 60.0, 0.1, MissionData.HIT_HEAVY * world.enemy_damage_scale, true, {"warn": 1.0, "color": Color(0.95, 0.7, 0.4)})


## The flail circles on its chain; it blocks your shots and hurts on contact.
func _swing(flail: Enemy, reach: float) -> void:
	var speed := 1.5 if phase == 0 else (2.0 if phase == 1 else 2.5)
	# The angle builds up tick by tick, so a faster phase spins it faster instead of snapping it across the room.
	memory["flail_angle"] = float(memory.get("flail_angle", 0.0)) + speed * World.DT
	# The chain pays out to its new length rather than snapping to it.
	var current := move_toward(float(memory.get("reach", reach)), reach, 80.0 * World.DT)
	flail.pos = origin + Vector2.from_angle(memory["flail_angle"]) * current
	memory["reach"] = current


func part_lost(part: Enemy) -> void:
	if part.part == "core":
		defeat()
