class_name StormColossus
extends BossBase
## Planet Exploration boss: a titan of the storm wading across the plain. Its two arms spray wheeling
## streams of bullets and it calls lightning down on you. Break the arms and it kneels, head exposed,
## and turns the sky itself on you: four storm beams that wheel a quarter turn, shown in advance.


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Storm Colossus"
	title = "The Sky Walks"
	look = "storm_colossus"
	color = Color(0.55, 0.8, 1.0)


func spawn() -> void:
	var away := Vector2.from_angle(world.rng.randf() * TAU) * 440.0
	origin = (world.player.pos + away).clamp(world.bounds.position + Vector2(220, 220), world.bounds.end - Vector2(220, 220))
	add_part("core", Vector2.ZERO, 3000, 44, {"invulnerable": true})
	add_part("arm0", Vector2(-120, 10), 640, 28)
	add_part("arm1", Vector2(120, 10), 640, 28)
	place_parts()
	world.emit("shake", {"amount": 16.0})
	world.emit("flash", {"color": Color(0.7, 0.9, 1.0), "amount": 0.5})
	memory["landing"] = 1.2


func behave(dt: float) -> void:
	if entering:
		memory["landing"] = float(memory["landing"]) - dt
		if memory["landing"] <= 0.0:
			entering = false
		return
	var core := part_named("core")
	var arms := living_parts("arm")
	origin = origin.move_toward(world.player.pos, (22.0 if phase == 0 else 0.0) * dt)
	place_parts()
	if phase == 0 and arms.is_empty():
		core.invulnerable = false
		set_phase(1, "THE COLOSSUS KNEELS")
	if phase == 1 and hp_fraction() < 0.35:
		set_phase(2, "THE STORM BREAKS")
	# Arms: wheeling streams in opposite directions.
	for arm: Enemy in arms:
		var spin := 1.0 if arm.part == "arm0" else -1.0
		if fmod(time + arm.id * 0.05, 0.13) < dt:
			world.enemy_shot(arm.pos, time * 1.5 * spin, 200.0, {"color": Color(1.0, 0.9, 0.45)})
	# Lightning on you and around you.
	if fmod(time, 3.0 if phase < 2 else 2.0) < dt:
		for i in 3:
			var at := world.player.pos + (Vector2.ZERO if i == 0 else Vector2.from_angle(world.rng.randf() * TAU) * world.rng.randf_range(90.0, 200.0))
			world.add_zone("bomb_warning", at, 60.0, 0.1, MissionData.HIT_HEAVY * world.enemy_damage_scale, true, {"warn": 1.0, "color": Color(0.6, 0.85, 1.0)})
		world.emit("sound", {"name": "mortar"})
	if phase == 0:
		return
	# Storm beams: four beams wheel a quarter turn each, so three quarters of the circle stay safe.
	if fmod(time, 5.5) < dt:
		var start := world.rng.randf() * TAU
		var direction := 1.0 if world.rng.randf() < 0.5 else -1.0
		for i in 4:
			world.add_zone("laser", core.pos, 0.0, 1.6, MissionData.HIT_HEAVY * world.enemy_damage_scale, true,
				{"warn": 1.2, "angle": start + TAU * i / 4.0, "length": 900.0, "width": 24.0,
				"spin": direction * (PI * 0.25) / 1.6, "color": Color(0.6, 0.85, 1.0)})
		world.emit("sound", {"name": "charge"})
	if fmod(time, 1.6) < dt:
		world.enemy_aimed(core.pos, 7, 0.9, 240.0, {"color": Color(1.0, 0.85, 0.4)})
	if phase == 2 and fmod(time, 7.0) < dt:
		for i in 3:
			world.spawn_enemy("crawler", core.pos + Vector2.from_angle(TAU * i / 3.0) * 80.0)
