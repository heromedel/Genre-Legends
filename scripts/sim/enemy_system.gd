class_name EnemySystem
extends RefCounted
## Runs every regular enemy's behaviour ("brain"), and contact damage between enemies and the player.
## Boss parts are driven by their boss script instead (brain "boss_part").
## Patterns lean on their genre's tropes (GDD 1B): formation fighters peel off and dive, a Mimic is a
## treasure chest until you get close, burrowers erupt under your feet, knights must be flanked.

## Seconds of grace after a boss's body hits you (ordinary hits give FrameData.HIT_GRACE).
const BOSS_CONTACT_GRACE := 1.0

var world: World
var stage = null        # the current Stage, for room bounds and scrolling


func _init(target_world: World) -> void:
	world = target_world


func update(dt: float) -> void:
	var time_scale := world.enemy_time_scale()
	var edt := dt * time_scale
	var player := world.player
	var fire_scale := world.enemy_fire_scale * (0.75 if world.gentle else 1.0)
	for enemy: Enemy in world.enemies:
		if enemy.dead:
			continue
		enemy.flash = maxf(enemy.flash - dt, 0.0)
		enemy.spawn_age += edt
		if enemy.brain == "boss_part":
			_contact(enemy, player)
			continue
		# Ground enemies idle until you come near or shoot them, so the map isn't one giant stampede.
		if player.form == "mech" and not enemy.memory.get("awake", false):
			if enemy.pos.distance_to(player.pos) < 640.0 or enemy.flash > 0.0:
				enemy.memory["awake"] = true
			else:
				continue
		enemy.timer += edt
		enemy.fire_timer -= edt * fire_scale
		match enemy.brain:
			"formation": _formation(enemy, edt)
			"weaver": _weaver(enemy, edt)
			"drifter": _drifter(enemy, edt)
			"crosser": _crosser(enemy, edt)
			"ace": _ace(enemy, edt)
			"barge": _barge(enemy, edt)
			"wall_turret": _wall_turret(enemy, edt)
			"rammer": _rammer(enemy, edt)
			"chaser": _chaser(enemy, edt)
			"lobber": _lobber(enemy, edt)
			"sentry": _sentry(enemy, edt)
			"charger": _charger(enemy, edt)
			"burrower": _burrower(enemy, edt)
			"nest": _nest(enemy, edt)
			"warlord": _warlord(enemy, edt)
			"bouncer": _bouncer(enemy, edt)
			"phaser": _phaser(enemy, edt)
			"spinner": _spinner(enemy, edt)
			"mimic": _mimic(enemy, edt)
			"knight": _knight(enemy, edt)
			"homer": _homer(enemy, edt)
			"centi": _centi(enemy, edt)
		if world.player.form == "mech" and not enemy.ghost and not world.walls.is_empty():
			enemy.pos = world.push_out_of_walls(enemy.pos, enemy.radius)
		_contact(enemy, player)


func _contact(enemy: Enemy, player: PlayerFrame) -> void:
	if enemy.hidden or enemy.contact <= 0.0 or not player.alive:
		return
	var reach := enemy.radius + player.radius - 3.0
	if enemy.pos.distance_squared_to(player.pos) > reach * reach:
		return
	var servos := world.run.field_count("overclocked_servos")
	if servos > 0 and enemy.boss == null:
		world.hurt_enemy(enemy, 25.0 * servos, "ram")
		world.damage_player(enemy.contact * 0.5, enemy.kind)
	else:
		world.damage_player(enemy.contact, enemy.kind)
	# A boss's body shoves you clear and gives you a moment, so you're never pinned and drained.
	if enemy.boss != null:
		var away := (player.pos - enemy.pos)
		player.pos = enemy.pos + (away.normalized() if away.length() > 1.0 else Vector2.DOWN) * (reach + 30.0)
		player.grace = maxf(player.grace, BOSS_CONTACT_GRACE)


func _aim_angle(enemy: Enemy) -> float:
	return (world.player.pos - enemy.pos).angle()


## Slides along walls instead of pushing into them: if the way ahead is blocked, turn to whichever side is open.
func _around_walls(enemy: Enemy, direction: Vector2) -> Vector2:
	if world.walls.is_empty() or enemy.ghost:
		return direction
	if not world.point_in_wall(enemy.pos + direction * (enemy.radius + 18.0)):
		return direction
	var side := 1.0 if enemy.id % 2 == 0 else -1.0
	for turn in [PI * 0.5, -PI * 0.5, PI * 0.25, -PI * 0.25]:
		var tried := direction.rotated(turn * side)
		if not world.point_in_wall(enemy.pos + tried * (enemy.radius + 18.0)):
			return tried
	return -direction


func _move_toward(enemy: Enemy, target: Vector2, speed: float, dt: float) -> void:
	var offset := target - enemy.pos
	if offset.length() < 1.0:
		return
	enemy.vel = _around_walls(enemy, offset.normalized()) * speed
	enemy.pos += enemy.vel * dt


func _speed(enemy: Enemy) -> float:
	return EnemyData.get_enemy(enemy.kind)["speed"]


# ---------------------------------------------------------------- shooter brains

## Formation fighters fly in along a curve to a slot, sway in formation, and peel off to dive at you.
func _formation(enemy: Enemy, dt: float) -> void:
	var memory := enemy.memory
	if memory.get("no_formation", false):
		enemy.pos += enemy.vel * dt
		enemy.vel = enemy.vel.lerp(Vector2(0, 220), dt * 1.5)
		_despawn_if_gone(enemy)
		return
	var slot: Vector2 = memory.get("slot", enemy.pos)
	var sway := Vector2(sin(world.time * 0.9 + slot.y * 0.01) * 38.0, sin(world.time * 1.7 + slot.x) * 6.0)
	match enemy.state:
		0:  # entering along a curve
			memory["t"] = float(memory.get("t", 0.0)) + dt * 0.75
			var t: float = minf(memory["t"], 1.0)
			var start: Vector2 = memory.get("start", enemy.pos)
			var control: Vector2 = memory.get("control", (start + slot) * 0.5)
			var previous := enemy.pos
			enemy.pos = start.lerp(control, t).lerp(control.lerp(slot + sway, t), t)
			enemy.facing = (enemy.pos - previous).angle() if enemy.pos != previous else PI * 0.5
			if t >= 1.0:
				enemy.state = 1
				enemy.timer = world.rng.randf_range(0.0, 3.0)
		1:  # holding formation
			enemy.pos = enemy.pos.lerp(slot + sway, dt * 4.0)
			# Formation potshots: the odd bullet from the ranks keeps you moving.
			if enemy.fire_timer <= 0.0:
				enemy.fire_timer = world.rng.randf_range(4.0, 8.0)
				if world.rng.randf() < 0.5:
					world.enemy_aimed(enemy.pos, 1, 0.0, 210.0)
			enemy.facing = lerp_angle(enemy.facing, PI * 0.5, dt * 6.0)
			var dive_wait: float = memory.get("dive_wait", world.rng.randf_range(3.5, 8.0) / world.enemy_fire_scale)
			memory["dive_wait"] = dive_wait
			if enemy.timer > dive_wait:
				enemy.state = 2
				enemy.timer = 0.0
				memory["dive_side"] = 1.0 if enemy.pos.x < world.player.pos.x else -1.0
				memory.erase("dive_wait")
				world.emit("sound", {"name": "dive"})
		2:  # diving: a looping swoop at the player, firing once
			var side: float = memory.get("dive_side", 1.0)
			var desired := (world.player.pos + Vector2(side * 60.0, 0) - enemy.pos).normalized()
			var current := Vector2.from_angle(enemy.facing)
			var turned := current.slerp(desired, clampf(dt * 2.2, 0.0, 1.0)) if enemy.timer < 1.2 else current
			enemy.facing = turned.angle()
			enemy.pos += turned * _speed(enemy) * 1.25 * dt
			if enemy.timer > 0.35 and not memory.get("dive_shot", false):
				memory["dive_shot"] = true
				world.enemy_aimed(enemy.pos, 3, 0.35, 240.0)
			if enemy.pos.y > world.bounds.end.y + 40.0 or enemy.pos.x < -60.0 or enemy.pos.x > world.bounds.end.x + 60.0:
				enemy.pos = Vector2(slot.x, -40.0)
				enemy.state = 3
				memory["dive_shot"] = false
		3:  # returning from the top of the screen
			enemy.pos = enemy.pos.move_toward(slot + sway, _speed(enemy) * dt)
			enemy.facing = PI * 0.5
			if enemy.pos.distance_to(slot + sway) < 4.0:
				enemy.state = 1
				enemy.timer = 0.0


func _weaver(enemy: Enemy, dt: float) -> void:
	var base_x: float = enemy.memory.get("base_x", enemy.pos.x)
	enemy.memory["base_x"] = base_x
	enemy.pos.y += _speed(enemy) * 0.55 * dt
	enemy.pos.x = base_x + sin(enemy.timer * 2.2) * 120.0
	enemy.facing = PI * 0.5
	if enemy.fire_timer <= 0.0 and enemy.pos.y > 20.0:
		enemy.fire_timer = world.rng.randf_range(1.5, 2.4)
		world.enemy_aimed(enemy.pos, 3, 0.3, 255.0)
		world.emit("sound", {"name": "enemy_shot"})
	_despawn_if_gone(enemy)


func _drifter(enemy: Enemy, dt: float) -> void:
	var target_x := world.player.pos.x
	enemy.pos.x = move_toward(enemy.pos.x, target_x, 30.0 * dt)
	enemy.pos.y += _speed(enemy) * dt * (1.0 if enemy.pos.y < 320.0 else 0.35)
	enemy.facing = PI * 0.5
	if enemy.fire_timer <= 0.0 and enemy.pos.y > 30.0:
		if enemy.kind == "splitter":
			enemy.fire_timer = 3.2
			world.enemy_ring(enemy.pos, 8, 170.0, enemy.timer)
		else:
			enemy.fire_timer = 2.4
			world.enemy_aimed(enemy.pos, 3, 0.5, 220.0)
		world.emit("sound", {"name": "enemy_shot"})
	_despawn_if_gone(enemy)


func _crosser(enemy: Enemy, dt: float) -> void:
	var direction: float = enemy.memory.get("direction", 1.0)
	enemy.pos.x += direction * _speed(enemy) * dt
	enemy.pos.y += sin(enemy.timer * 1.5) * 20.0 * dt
	enemy.facing = PI * 0.5
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 1.4
		# Mines drift down and burst into a ring when their fuse runs out (World handles the burst).
		world.enemy_shot(enemy.pos, PI * 0.5, 60.0, {"radius": 9.0, "look": "mine", "life": 2.4, "color": Color(1, 0.5, 0.3)})
	if enemy.pos.x < -80.0 or enemy.pos.x > world.bounds.end.x + 80.0:
		enemy.dead = true


func _ace(enemy: Enemy, dt: float) -> void:
	var target := Vector2(
		world.bounds.get_center().x + sin(enemy.timer * 1.3) * world.bounds.size.x * 0.4,
		140.0 + sin(enemy.timer * 2.1) * 70.0)
	if enemy.timer > 16.0:
		target = Vector2(enemy.pos.x, -200.0)
		if enemy.pos.y < -60.0:
			enemy.dead = true
			world.emit("escaped", {"name": "Ace"})
			return
	enemy.pos = enemy.pos.move_toward(target, _speed(enemy) * dt)
	enemy.facing = PI * 0.5
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 1.1
		world.enemy_aimed(enemy.pos, 3, 0.35, 300.0, {"color": Color(1, 0.3, 0.5)})
		world.emit("sound", {"name": "enemy_shot"})


## The bonus ship that crosses the screen: kill it before it leaves or the crate goes with it.
func _barge(enemy: Enemy, dt: float) -> void:
	var direction: float = enemy.memory.get("direction", 1.0)
	enemy.pos.x += direction * _speed(enemy) * dt
	enemy.facing = 0.0 if direction > 0 else PI
	if enemy.pos.x < -100.0 or enemy.pos.x > world.bounds.end.x + 100.0:
		enemy.dead = true
		world.emit("escaped", {"name": "Supply Barge"})


func _wall_turret(enemy: Enemy, dt: float) -> void:
	enemy.facing = _aim_angle(enemy)
	if enemy.fire_timer <= 0.0 and enemy.pos.y > 0.0 and enemy.pos.y < world.bounds.end.y - 80.0:
		enemy.fire_timer = world.rng.randf_range(1.6, 2.4)
		world.enemy_aimed(enemy.pos, 3, 0.3, 240.0)
		world.emit("sound", {"name": "enemy_shot"})
	_despawn_if_gone(enemy)


func _rammer(enemy: Enemy, dt: float) -> void:
	match enemy.state:
		0:
			enemy.pos.y += 90.0 * dt
			enemy.facing = _aim_angle(enemy)
			if enemy.timer > 0.7:
				enemy.state = 1
				enemy.vel = Vector2.from_angle(enemy.facing) * _speed(enemy) * 1.6
				world.emit("sound", {"name": "dive"})
		1:
			enemy.pos += enemy.vel * dt
	_despawn_if_gone(enemy)


func _despawn_if_gone(enemy: Enemy) -> void:
	var margin := 120.0
	if enemy.pos.y > world.bounds.end.y + margin or enemy.pos.y < -400.0 \
			or enemy.pos.x < -margin * 2 or enemy.pos.x > world.bounds.end.x + margin * 2:
		enemy.dead = true


# ---------------------------------------------------------------- ground brains

func _chaser(enemy: Enemy, dt: float) -> void:
	var to_player := world.player.pos - enemy.pos
	var wobble := Vector2.from_angle(enemy.timer * 3.0 + enemy.id) * 0.35
	var direction := _around_walls(enemy, (to_player.normalized() + wobble).normalized())
	enemy.vel = enemy.vel.lerp(direction * _speed(enemy), dt * 5.0)
	enemy.pos += enemy.vel * dt
	enemy.facing = enemy.vel.angle()


func _lobber(enemy: Enemy, dt: float) -> void:
	var to_player := world.player.pos - enemy.pos
	var distance := to_player.length()
	var desired := 300.0
	var direction := to_player.normalized() * (1.0 if distance > desired else -0.7)
	direction += to_player.normalized().orthogonal() * 0.5
	enemy.pos += direction.normalized() * _speed(enemy) * dt
	enemy.facing = to_player.angle()
	if enemy.fire_timer <= 0.0 and distance < 620.0:
		enemy.fire_timer = world.rng.randf_range(2.4, 3.2)
		var target := world.player.pos + world.player.vel * 0.5
		var warning := world.add_zone("acid_warning", target, 46.0, 0.1, 8.0, true, {"warn": 0.9, "color": Color(0.5, 1.0, 0.4)})
		warning.hit_ids = {"from": enemy.pos}
		world.emit("lob", {"from": enemy.pos, "to": target, "time": 0.9})
		world.emit("sound", {"name": "lob"})


func _sentry(enemy: Enemy, dt: float) -> void:
	enemy.facing = lerp_angle(enemy.facing, _aim_angle(enemy), dt * 3.0)
	if enemy.fire_timer <= 0.0 and enemy.pos.distance_to(world.player.pos) < 560.0:
		enemy.fire_timer = 2.0
		enemy.memory["burst"] = 4
	if int(enemy.memory.get("burst", 0)) > 0 and fmod(enemy.timer, 0.12) < dt:
		enemy.memory["burst"] = int(enemy.memory["burst"]) - 1
		world.enemy_shot(enemy.pos, enemy.facing, 300.0)
		world.emit("sound", {"name": "enemy_shot"})


func _charger(enemy: Enemy, dt: float) -> void:
	match enemy.state:
		0:
			_move_toward(enemy, world.player.pos, _speed(enemy), dt)
			enemy.facing = enemy.vel.angle()
			if enemy.pos.distance_to(world.player.pos) < 320.0 and enemy.timer > 2.0:
				enemy.state = 1
				enemy.timer = 0.0
				enemy.memory["charge_dir"] = _aim_angle(enemy)
				world.emit("telegraph", {"pos": enemy.pos, "angle": enemy.memory["charge_dir"], "length": 360.0, "time": 0.7})
		1:
			enemy.facing = enemy.memory["charge_dir"]
			if enemy.timer > 0.7:
				enemy.state = 2
				enemy.timer = 0.0
				world.emit("sound", {"name": "charge"})
		2:
			enemy.pos += Vector2.from_angle(enemy.memory["charge_dir"]) * 560.0 * dt
			if enemy.timer > 0.6:
				enemy.state = 0
				enemy.timer = 0.0
				world.enemy_ring(enemy.pos, 10, 180.0, world.rng.randf() * TAU)
				world.emit("shake", {"amount": 4.0})


func _burrower(enemy: Enemy, dt: float) -> void:
	match enemy.state:
		0:  # underground, closing in
			enemy.hidden = true
			_move_toward(enemy, world.player.pos, _speed(enemy), dt)
			if enemy.pos.distance_to(world.player.pos) < 150.0 and enemy.timer > 1.0:
				enemy.state = 1
				enemy.timer = 0.0
				world.emit("telegraph_circle", {"pos": enemy.pos, "radius": 60.0, "time": 0.5})
		1:  # rumbling
			if enemy.timer > 0.5:
				enemy.state = 2
				enemy.timer = 0.0
				enemy.hidden = false
				world.enemy_ring(enemy.pos, 12, 200.0, world.rng.randf() * TAU)
				world.emit("burst_ground", {"pos": enemy.pos})
				world.emit("sound", {"name": "burrow"})
		2:  # surfaced and shooting
			enemy.facing = _aim_angle(enemy)
			if enemy.fire_timer <= 0.0:
				enemy.fire_timer = 0.8
				world.enemy_aimed(enemy.pos, 2, 0.2, 260.0)
			if enemy.timer > 2.8:
				enemy.state = 0
				enemy.timer = 0.0


func _nest(enemy: Enemy, dt: float) -> void:
	var distance := enemy.pos.distance_to(world.player.pos)
	if distance > 760.0:
		return
	var spawned: int = enemy.memory.get("spawned", 0)
	# The first time it's hurt, the hive screams and its brood pours out.
	if enemy.hp < enemy.max_hp and not enemy.memory.get("alarmed", false):
		enemy.memory["alarmed"] = true
		world.emit("banner", {"text": "THE HIVE IS AWAKE", "style": "violet"})
		for i in 6:
			var brood := world.spawn_enemy("crawler" if i % 3 != 0 else "spitter", enemy.pos + Vector2.from_angle(TAU * i / 6.0) * 70.0)
			brood.memory["awake"] = true
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 3.8
		world.enemy_ring(enemy.pos, 12, 150.0, enemy.timer)
		if spawned < 14:
			for i in 2:
				var crawler := world.spawn_enemy("crawler", enemy.pos + Vector2.from_angle(world.rng.randf() * TAU) * 40.0)
				crawler.room = enemy.room
			enemy.memory["spawned"] = spawned + 2
		world.emit("sound", {"name": "spawn"})


func _warlord(enemy: Enemy, dt: float) -> void:
	var angle: float = enemy.memory.get("orbit", world.rng.randf() * TAU)
	angle += dt * 0.7
	enemy.memory["orbit"] = angle
	var target := world.player.pos + Vector2.from_angle(angle) * 260.0
	enemy.pos = enemy.pos.move_toward(target, _speed(enemy) * dt)
	enemy.facing = _aim_angle(enemy)
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 1.6
		world.enemy_aimed(enemy.pos, 5, 0.8, 240.0, {"color": Color(1, 0.3, 0.3)})
		world.emit("sound", {"name": "enemy_shot"})
	if fmod(enemy.timer, 8.0) < dt:
		for i in 3:
			world.spawn_enemy("crawler", enemy.pos + Vector2.from_angle(TAU * i / 3.0) * 40.0)


# ---------------------------------------------------------------- dungeon brains

## Skullbots ricochet around the room like a screensaver and fire every time they hit a wall.
## How far inside a room's walls the bouncing skullbots turn back: clear of the corners and the HUD.
const BOUNCER_MARGIN := 110.0


func _bouncer(enemy: Enemy, dt: float) -> void:
	if enemy.vel == Vector2.ZERO:
		var diagonal: Vector2 = [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)][world.rng.randi() % 4]
		enemy.vel = diagonal.normalized() * _speed(enemy)
	var next := enemy.pos + enemy.vel * dt
	var bounced := false
	# They keep well clear of the walls, so they never sit in a corner under the HUD (heromedel).
	var area: Rect2 = stage.room_rect(enemy.room).grow(-BOUNCER_MARGIN) if stage != null and stage.has_method("room_rect") else world.bounds
	if next.x < area.position.x or next.x > area.end.x or world.point_in_wall(Vector2(next.x, enemy.pos.y)):
		enemy.vel.x = -enemy.vel.x
		bounced = true
	if next.y < area.position.y or next.y > area.end.y or world.point_in_wall(Vector2(enemy.pos.x, next.y)):
		enemy.vel.y = -enemy.vel.y
		bounced = true
	# Each bounce turns them a little, so their path sweeps the room instead of shuttling along one diagonal
	# between two corners; never so flat that they run along a wall.
	if bounced:
		var angle := enemy.vel.angle() + world.rng.randf_range(-0.3, 0.3)
		var direction := Vector2.from_angle(angle)
		direction = Vector2(signf(direction.x) * maxf(absf(direction.x), 0.4), signf(direction.y) * maxf(absf(direction.y), 0.4)).normalized()
		enemy.vel = direction * _speed(enemy)
	enemy.pos += enemy.vel * dt
	# Never wedged in a corner: knocked outside the room's inner area (walls push things around), it
	# turns back toward the middle on a fresh diagonal.
	if not area.has_point(enemy.pos):
		var home := area.get_center() - enemy.pos
		enemy.vel = Vector2(signf(home.x) if home.x != 0.0 else 1.0, signf(home.y) if home.y != 0.0 else 1.0).normalized() * _speed(enemy)
		enemy.pos = enemy.pos.move_toward(area.get_center(), _speed(enemy) * dt)
	enemy.facing = enemy.vel.angle()
	if bounced and enemy.fire_timer <= 0.0:
		enemy.fire_timer = 0.6
		world.enemy_aimed(enemy.pos, 1, 0.0, 250.0)
		world.emit("sound", {"name": "bounce"})


func _phaser(enemy: Enemy, dt: float) -> void:
	_move_toward(enemy, world.player.pos + Vector2.from_angle(enemy.timer) * 80.0, _speed(enemy), dt)
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 2.8
		world.enemy_aimed(enemy.pos, 3, 0.6, 170.0, {"color": Color(0.5, 0.9, 1.0)})


func _spinner(enemy: Enemy, dt: float) -> void:
	if enemy.pos.distance_to(world.player.pos) > 900.0:
		return
	enemy.facing += dt * 1.6
	if enemy.fire_timer <= 0.0:
		enemy.fire_timer = 0.16
		for arm in 2:
			world.enemy_shot(enemy.pos, enemy.facing + PI * arm, 170.0, {"color": Color(1, 0.4, 0.6)})


## A treasure chest. Until it isn't.
func _mimic(enemy: Enemy, dt: float) -> void:
	match enemy.state:
		0:
			enemy.facing = PI * 0.5
			if enemy.pos.distance_to(world.player.pos) < 130.0:
				enemy.state = 1
				enemy.timer = 0.0
		1:
			if enemy.memory.get("revealed", false) == false:
				enemy.memory["revealed"] = true
				enemy.untargetable = false
				enemy.timer = 0.0
				world.emit("banner", {"text": "IT'S A MIMIC!", "style": "red"})
				world.emit("sound", {"name": "mimic"})
			# Hop at the player; land with a ring of teeth.
			var hop := fmod(enemy.timer, 1.1)
			if hop < 0.5:
				enemy.pos = enemy.pos.move_toward(world.player.pos, _speed(enemy) * dt)
			elif hop - dt < 0.5:
				world.enemy_ring(enemy.pos, 10, 200.0, enemy.timer)
				world.emit("shake", {"amount": 3.0})


## Knights block shots from the front. They lunge when you're near, slash, and then stand exposed with
## their shield lowered for a moment: the window to punish them (or flank them any time).
func _knight(enemy: Enemy, dt: float) -> void:
	var distance := enemy.pos.distance_to(world.player.pos)
	match enemy.state:
		0:  # advance, shield up
			enemy.front_shield = true
			enemy.facing = rotate_toward(enemy.facing, _aim_angle(enemy), dt * 1.0)
			if distance > 90.0:
				enemy.pos += Vector2.from_angle(enemy.facing) * _speed(enemy) * dt
			if distance < 300.0 and enemy.fire_timer <= 0.0:
				enemy.state = 1
				enemy.timer = 0.0
				world.emit("telegraph", {"pos": enemy.pos, "angle": enemy.facing, "length": 260.0, "time": 0.45})
		1:  # wind-up
			if enemy.timer > 0.45:
				enemy.state = 2
				enemy.timer = 0.0
				world.emit("sound", {"name": "charge"})
		2:  # lunge, then slash
			enemy.pos += Vector2.from_angle(enemy.facing) * 520.0 * dt
			if enemy.timer > 0.32:
				enemy.state = 3
				enemy.timer = 0.0
				world.enemy_aimed(enemy.pos, 5, 1.2, 230.0, {"color": Color(0.75, 0.75, 1.0)})
				world.emit("slash_enemy", {"pos": enemy.pos, "angle": enemy.facing})
				world.emit("sound", {"name": "slash"})
		3:  # exposed: shield down
			enemy.front_shield = false
			if enemy.timer > 1.4:
				enemy.state = 0
				enemy.timer = 0.0
				enemy.fire_timer = 2.0



# ---------------------------------------------------------------- milestone arrivals

## Drone shards: little kamikazes that curve in on you.
func _homer(enemy: Enemy, dt: float) -> void:
	var desired := (world.player.pos - enemy.pos).normalized() * _speed(enemy)
	enemy.vel = enemy.vel.lerp(desired, clampf(dt * 2.5, 0.0, 1.0))
	enemy.pos += enemy.vel * dt
	enemy.facing = enemy.vel.angle()
	if enemy.timer > 6.0:
		enemy.dead = true


## Centi-Mechs: a head that weaves toward you and a chain of segments that follow its trail. Kill the
## head and the next segment takes over: the classic arcade centipede.
func _centi(enemy: Enemy, dt: float) -> void:
	var leader := world.enemy_by_id(int(enemy.memory.get("leader", -1)))
	if leader == null:
		# Head: weave toward the player, leaving a trail for the segments.
		enemy.look = "centi_head"
		var weave := Vector2.from_angle(enemy.timer * 2.4) * 0.6
		var direction := ((world.player.pos - enemy.pos).normalized() + weave.orthogonal() * 0.8).normalized()
		enemy.vel = enemy.vel.lerp(direction * _speed(enemy), clampf(dt * 3.0, 0.0, 1.0))
		enemy.pos += enemy.vel * dt
		enemy.facing = enemy.vel.angle()
		if enemy.fire_timer <= 0.0:
			enemy.fire_timer = 1.8
			world.enemy_aimed(enemy.pos, 3, 0.4, 230.0, {"color": Color(1, 0.7, 0.35)})
	else:
		var trail: Array = leader.memory.get("trail", [])
		var target: Vector2 = trail[mini(8, trail.size() - 1)] if not trail.is_empty() else leader.pos
		enemy.pos = enemy.pos.move_toward(target, _speed(enemy) * 1.3 * dt)
		enemy.facing = (leader.pos - enemy.pos).angle()
		if enemy.fire_timer <= 0.0:
			enemy.fire_timer = world.rng.randf_range(3.0, 5.0)
			world.enemy_shot(enemy.pos, enemy.facing + PI * 0.5 * (1 if enemy.id % 2 == 0 else -1), 180.0, {"color": Color(1, 0.7, 0.35)})
	var own_trail: Array = enemy.memory.get("trail", [])
	own_trail.push_front(enemy.pos)
	if own_trail.size() > 12:
		own_trail.pop_back()
	enemy.memory["trail"] = own_trail
