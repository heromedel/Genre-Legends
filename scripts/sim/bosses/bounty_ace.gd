class_name BountyAce
extends BossBase
## Star Cluster boss, and the Tempest Run's prize fight: a rival hunter frame with two shield drones.
## It strafes the field dropping mines, then, shield down, snipes along telegraphed lines and finally
## calls in other hunters and throws a closing net of bullets with one gap.


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Bounty Hunter Ace"
	title = "Dead or Alive"
	look = "bounty_ace"
	color = Color(1.0, 0.75, 0.3)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, -140)
	add_part("core", Vector2.ZERO, 2400, 48, {"invulnerable": true})
	add_part("drone0", Vector2(-80, 0), 420, 16)
	add_part("drone1", Vector2(80, 0), 420, 16)
	place_parts()


func behave(dt: float) -> void:
	var core := part_named("core")
	var drones := living_parts("drone")
	if entering:
		origin.y = move_toward(origin.y, 170.0, 200.0 * dt)
		_place_drones(drones)
		if origin.y >= 170.0:
			entering = false
		return
	# A strafing run every few seconds; otherwise it weaves across the top of the field.
	var cycle := fmod(time, 6.0)
	var center := world.bounds.get_center()
	if cycle < 1.4:
		var direction := 1.0 if int(time / 6.0) % 2 == 0 else -1.0
		origin.x = move_toward(origin.x, center.x + direction * 520.0, 820.0 * dt)
		if fmod(time, 0.18) < dt:
			world.enemy_shot(origin, PI * 0.5, 70.0, {"radius": 9.0, "look": "mine", "life": 2.2, "color": Color(1, 0.6, 0.3)})
	else:
		origin.x = move_toward(origin.x, center.x + sin(time * 0.9) * 360.0, 300.0 * dt)
		origin.y = 160.0 + sin(time * 1.6) * 40.0
	_place_drones(drones)
	if phase == 0 and drones.is_empty():
		core.invulnerable = false
		set_phase(1, "SHIELD DOWN - HE'S EXPOSED")
	if phase == 1 and hp_fraction() < 0.4:
		set_phase(2, "BOUNTY CALLED IN")
		for i in 2:
			var hunter := world.spawn_enemy("ace", Vector2(center.x + (i * 2 - 1) * 300.0, -40))
			hunter.memory["no_formation"] = true
	for drone: Enemy in drones:
		if fmod(time + drone.id * 0.4, 1.3) < dt:
			world.enemy_aimed(drone.pos, 1, 0.0, 280.0, {"color": Color(1, 0.75, 0.35)})
	if fmod(time, 1.5) < dt and cycle >= 1.4:
		world.enemy_aimed(core.pos, 3 if phase == 0 else 5, 0.5, 270.0, {"color": Color(1, 0.65, 0.3)})
		world.emit("sound", {"name": "enemy_shot"})
	if phase >= 1 and fmod(time, 4.0) < dt:
		# The sniper line: shown first, then one fast, heavy shot along it.
		var aim := (world.player.pos - core.pos).angle()
		world.add_zone("laser", core.pos, 0.0, 0.25, 20.0 * world.enemy_damage_scale, true,
			{"warn": 0.9, "angle": aim, "length": 1100.0, "width": 14.0, "color": Color(1, 0.75, 0.3)})
		world.emit("sound", {"name": "charge"})
	if phase == 2 and fmod(time, 5.0) < dt:
		_net()


func _place_drones(drones: Array) -> void:
	var core := part_named("core")
	core.pos = origin
	for drone: Enemy in drones:
		var side := -1.0 if drone.part == "drone0" else 1.0
		drone.pos = origin + Vector2.from_angle(time * 2.2 + (0.0 if side < 0 else PI)) * 110.0


## A ring of bullets around you that closes in, with a gap to slip through.
func _net() -> void:
	var count := 22
	var gap := world.rng.randi() % count
	for i in count:
		if absi(i - gap) <= 1 or absi(i - gap) == count - 1:
			continue
		var at := world.player.pos + Vector2.from_angle(TAU * i / count) * 300.0
		world.enemy_shot(at, (world.player.pos - at).angle(), 110.0, {"color": Color(1, 0.8, 0.4), "life": 3.6})
	world.emit("sound", {"name": "curtain"})
