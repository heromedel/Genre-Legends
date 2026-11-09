class_name RingObelisk
extends BossBase
## Planet mini-boss: an ancient pylon that wakes as you come near and fills the air with patterns:
## wheeling spiral arms and rings with a gap you slip through. Three crystals orbit it and keep it
## shielded; break them and it pulses faster, but it can finally be hurt.


func spawn() -> void:
	boss_name = "Ring Obelisk"
	title = "The Old Machine Wakes"
	look = "ring_obelisk"
	color = Color(0.5, 1.0, 0.85)
	var away := Vector2.from_angle(world.rng.randf() * TAU) * 360.0
	origin = (world.player.pos + away).clamp(world.bounds.position + Vector2(200, 200), world.bounds.end - Vector2(200, 200))
	add_part("core", Vector2.ZERO, 850, 34, {"invulnerable": true})
	for i in 3:
		add_part("crystal%d" % i, Vector2.from_angle(TAU * i / 3.0) * 110.0, 300, 18)
	place_parts()
	world.emit("burst_ground", {"pos": origin})
	memory["wake"] = 1.0


func behave(dt: float) -> void:
	var core := part_named("core")
	var crystals := living_parts("crystal")
	# It hovers after you if you keep your distance, so it can't be outwaited.
	if origin.distance_to(world.player.pos) > 280.0:
		origin = origin.move_toward(world.player.pos, 45.0 * dt)
	core.pos = origin
	for crystal: Enemy in crystals:
		var index := int(crystal.part.right(1))
		crystal.pos = origin + Vector2.from_angle(time * 0.9 + TAU * index / 3.0) * 110.0
	if entering:
		memory["wake"] = float(memory["wake"]) - dt
		if memory["wake"] <= 0.0:
			entering = false
		return
	if phase == 0 and crystals.is_empty():
		core.invulnerable = false
		set_phase(1, "THE OBELISK IS OPEN")
	var pace := 1.0 if phase == 0 else 1.4
	# Spiral arms, wheeling.
	if fmod(time, 0.17 / pace) < dt:
		for arm in 4:
			world.enemy_shot(core.pos, time * 0.9 + TAU * arm / 4.0, 170.0, {"color": Color(1.0, 0.55, 0.8)})
	# A ring with a gap: find the gap and slip through.
	if fmod(time, 3.0 / pace) < dt:
		var count := 28
		var gap := world.rng.randi() % count
		for i in count:
			if absi(i - gap) <= 1 or absi(i - gap) == count - 1:
				continue
			world.enemy_shot(core.pos, TAU * i / count, 140.0, {"color": Color(1.0, 0.85, 0.45), "radius": 7.0})
		world.emit("sound", {"name": "curtain"})
