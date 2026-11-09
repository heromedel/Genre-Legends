class_name BroodQueen
extends BossBase
## Planet mini-boss: the hive's queen bursts out of the ground. Two egg sacs keep birthing crawlers and
## shield her head; burst the sacs to get at her. She spits acid where you're about to be.


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Brood Queen"
	title = "The Brood Wakes"
	look = "brood_queen"
	color = Color(0.75, 1.0, 0.4)


func spawn() -> void:
	var away := Vector2.from_angle(world.rng.randf() * TAU) * 360.0
	origin = (world.player.pos + away).clamp(world.bounds.position + Vector2(200, 200), world.bounds.end - Vector2(200, 200))
	add_part("core", Vector2(36, 0), 1100, 30, {"invulnerable": true})
	add_part("sac0", Vector2(-40, -42), 360, 26)
	add_part("sac1", Vector2(-40, 42), 360, 26)
	place_parts()
	world.emit("burst_ground", {"pos": origin})
	world.emit("shake", {"amount": 12.0})
	memory["rise"] = 1.0


func behave(dt: float) -> void:
	if entering:
		memory["rise"] = float(memory["rise"]) - dt
		if memory["rise"] <= 0.0:
			entering = false
		return
	var to_player := world.player.pos - origin
	origin += to_player.normalized() * 40.0 * dt if to_player.length() > 260.0 else Vector2.ZERO
	place_parts(to_player.angle())
	var core := part_named("core")
	var sacs := living_parts("sac")
	if phase == 0 and sacs.is_empty():
		core.invulnerable = false
		set_phase(1, "THE QUEEN IS EXPOSED")
	if fmod(time, 3.0) < dt:
		for sac: Enemy in sacs:
			for i in 2:
				var brood := world.spawn_enemy("crawler", sac.pos + Vector2.from_angle(world.rng.randf() * TAU) * 30.0)
				brood.memory["awake"] = true
	if fmod(time, 2.4) < dt:
		var lead := world.player.pos + world.player.vel * 0.7
		for i in (2 if phase == 0 else 4):
			var at := lead + Vector2.from_angle(world.rng.randf() * TAU) * world.rng.randf_range(0.0, 90.0)
			world.add_zone("acid_warning", at, 50.0, 0.1, 9.0, true, {"warn": 0.9, "color": Color(0.5, 1.0, 0.4)})
		world.emit("sound", {"name": "lob"})
	if phase == 1 and fmod(time, 1.6) < dt:
		world.enemy_aimed(core.pos, 7, 1.0, 230.0, {"color": Color(0.7, 1.0, 0.4)})
