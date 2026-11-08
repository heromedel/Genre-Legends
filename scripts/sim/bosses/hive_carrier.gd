class_name HiveCarrier
extends BossBase
## Star Cluster boss. A huge carrier parks across the top of the screen and launches fighters from four
## hangar bays. Its core is armored shut until you break enough bays; then it opens, spins out spirals
## and, near the end, sweeps the field with lasers.

const BAY_OFFSETS := [Vector2(-250, 6), Vector2(-125, 36), Vector2(125, 36), Vector2(250, 6)]


func spawn() -> void:
	boss_name = "Hive Carrier"
	title = "Mother of the Swarm"
	look = "hive_carrier"
	color = Color(1.0, 0.45, 0.4)
	origin = Vector2(world.bounds.get_center().x, -200)
	add_part("core", Vector2(0, -10), 2400, 44, {"invulnerable": true})
	for i in BAY_OFFSETS.size():
		add_part("bay%d" % i, BAY_OFFSETS[i], 330, 26)
	add_part("turret0", Vector2(-70, 48), 220, 18)
	add_part("turret1", Vector2(70, 48), 220, 18)
	place_parts()


func behave(dt: float) -> void:
	var settle_y := 150.0
	if entering:
		origin.y = move_toward(origin.y, settle_y, 140.0 * dt)
		place_parts()
		if origin.y >= settle_y:
			entering = false
		return
	origin.x = world.bounds.get_center().x + sin(time * 0.35) * (90.0 if phase == 0 else 220.0)
	place_parts()
	var core := part_named("core")
	var bays := living_parts("bay")
	if phase == 0 and bays.size() <= 2:
		core.invulnerable = false
		set_phase(1, "CORE EXPOSED")
	if phase == 1 and hp_fraction() < 0.3:
		set_phase(2, "CARRIER CRITICAL")
	# Hangar bays launch fighters that swoop at you.
	if fmod(time, 5.0) < dt:
		for bay: Enemy in bays:
			var fighter := world.spawn_enemy("dart", bay.pos + Vector2(0, 20))
			fighter.memory["no_formation"] = true
			fighter.vel = (world.player.pos - bay.pos).normalized() * 230.0
			world.emit("sound", {"name": "spawn"})
	# Turrets snipe.
	for turret: Enemy in living_parts("turret"):
		if fmod(time + turret.id * 0.3, 1.4) < dt:
			world.enemy_aimed(turret.pos, 1, 0.0, 280.0)
	match phase:
		0:
			if fmod(time, 2.4) < dt:
				world.enemy_aimed(core.pos, 5, 0.7, 230.0, {"radius": 7.0})
				world.emit("sound", {"name": "enemy_shot"})
		1, 2:
			if fmod(time, 0.11) < dt:
				var spin := time * 1.9
				for arm in 3:
					world.enemy_shot(core.pos, spin + TAU * arm / 3.0, 190.0, {"color": Color(1, 0.55, 0.3)})
			if fmod(time, 3.2) < dt:
				world.enemy_ring(core.pos, 18, 150.0, time, {"radius": 7.0, "color": Color(1, 0.35, 0.5)})
	if phase == 2 and fmod(time, 6.0) < dt:
		for side: float in [-1.0, 1.0]:
			var start_angle := PI * 0.5 + side * 0.9
			world.add_zone("laser", core.pos, 0.0, 2.0, 22.0 * world.enemy_damage_scale, true,
				{"warn": 1.0, "angle": start_angle, "length": 1100.0, "width": 26.0, "spin": -side * 0.8, "color": Color(1, 0.3, 0.4)})
		world.emit("sound", {"name": "charge"})
