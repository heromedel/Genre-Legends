class_name SalvoBarge
extends BossBase
## Corridor mini-boss: a heavy barge lumbers down the trench, its two launch pods firing salvos of
## homing drones that you can shoot out of the air. Break the pods and the barge's core is exposed.
## The corridor waits until it falls.


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Salvo Barge"
	title = "Incoming!"
	look = "salvo_barge"
	color = Color(0.95, 0.75, 0.4)


func spawn() -> void:
	var half_width := float(memory.get("half_width", 300.0))
	origin = Vector2(origin.x if origin.x != 0.0 else world.bounds.get_center().x, -110)
	var spread := minf(150.0, half_width - 60.0)
	add_part("core", Vector2(0, -6), 1100, 34, {"invulnerable": true})
	add_part("pod0", Vector2(-spread, 14), 420, 24)
	add_part("pod1", Vector2(spread, 14), 420, 24)
	place_parts()


func behave(dt: float) -> void:
	if entering:
		origin.y = move_toward(origin.y, 140.0, 110.0 * dt)
		place_parts()
		if origin.y >= 140.0:
			entering = false
			world.emit("shake", {"amount": 10.0})
		return
	glide_to(Vector2(origin.x, 140.0 + sin(time * 0.8) * 20.0), 60.0, dt)
	place_parts()
	var core := part_named("core")
	var pods := living_parts("pod")
	if phase == 0 and pods.is_empty():
		core.invulnerable = false
		set_phase(1, "THE BARGE'S HOLD SPLITS OPEN")
	# Salvos: each pod launches homing drones you can shoot down.
	if fmod(time, 3.2) < dt:
		for pod: Enemy in pods:
			for i in 3:
				var drone := world.spawn_enemy("drone_shard", pod.pos + Vector2((i - 1) * 18.0, 20.0), {"elite": false})
				drone.memory["awake"] = true
				drone.vel = Vector2.from_angle(PI * 0.5 + (i - 1) * 0.5) * 220.0
		if not pods.is_empty():
			world.emit("sound", {"name": "missiles"})
	if fmod(time, 2.4) < dt:
		world.enemy_ring(core.pos, 12 if phase == 0 else 20, 160.0, time, {"color": Color(1, 0.75, 0.4)})
	if phase == 1 and fmod(time, 0.9) < dt:
		world.enemy_aimed(core.pos, 5, 0.6, 260.0, {"color": Color(1, 0.8, 0.45)})
