class_name CloneProjector
extends BossBase
## Star Cluster mini-boss (GDD 11E): a projector scans your frame and fields a hologram clone that
## mirrors you and fires your own bolts back. Kill the clone, or break the projector's shell and grab
## the projector: the clone switches sides and flies beside you for the rest of the mission.

const CLONE_Y := 170.0


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Clone Projector"
	title = "Know Thyself"
	look = "clone_projector"
	color = Color(0.75, 0.55, 1.0)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, -120)
	add_part("clone", Vector2.ZERO, 1400, 20)
	var side := -1.0 if world.rng.randf() < 0.5 else 1.0
	add_part("shell", Vector2(side * 380, 0), 520, 28)
	memory["shell_side"] = side
	place_parts()
	world.emit("banner", {"text": "IT'S SCANNING YOU", "style": "violet"})


func behave(dt: float) -> void:
	var clone := part_named("clone")
	var shell := part_named("shell")
	if entering:
		clone.pos.y = move_toward(clone.pos.y, CLONE_Y, 220.0 * dt)
		if shell != null:
			shell.pos = Vector2(world.bounds.get_center().x + float(memory["shell_side"]) * 380.0, clone.pos.y - 70.0)
		if clone.pos.y >= CLONE_Y:
			entering = false
		return
	# The clone shadows your x and fires your twin bolts straight back down at you.
	var mirror_x := world.player.pos.x
	clone.pos.x = move_toward(clone.pos.x, mirror_x, (260.0 if phase == 0 else 340.0) * dt)
	clone.pos.y = CLONE_Y + sin(time * 1.7) * 30.0
	clone.facing = PI * 0.5
	_mirror_main_weapon(clone, dt)
	# And one of your other tricks, if you've brought it online: Swarm Pods come back at you as missiles.
	if world.run.is_online("swarm_pods") and fmod(time, 3.6) < dt:
		for i in 4:
			var missile := world.enemy_shot(clone.pos, PI * 0.5 + (i - 1.5) * 0.5, 160.0, {"color": Color(0.85, 0.6, 1.0), "look": "needle", "life": 3.0})
			missile.homing = 1.6
		world.emit("sound", {"name": "missiles"})
	# Every few seconds it copies one of your tricks: a ring, like your Nova, or a fan.
	if fmod(time, 4.2) < dt:
		if int(time / 4.2) % 2 == 0:
			world.enemy_ring(clone.pos, 14, 170.0, time, {"color": Color(0.8, 0.55, 1.0)})
		else:
			world.enemy_aimed(clone.pos, 5, 0.7, 260.0, {"color": Color(0.8, 0.55, 1.0)})
		world.emit("sound", {"name": "enemy_shot"})
	# The projector shell bobs on its side of the field, protected by a slow spin of bullets.
	if shell != null and not shell.dead:
		shell.pos = Vector2(world.bounds.get_center().x + float(memory["shell_side"]) * 380.0, 110.0 + sin(time * 1.2) * 40.0)
		if fmod(time, 2.0) < dt:
			world.enemy_ring(shell.pos, 8, 140.0, time * 2.0, {"color": Color(0.6, 1.0, 0.7)})


## The clone fires a hologram copy of your own main weapon back down at you (GDD 11E).
func _mirror_main_weapon(clone: Enemy, dt: float) -> void:
	var hologram := Color(0.75, 0.6, 1.0)
	match world.run.main_weapon():
		"thunder_lance":
			if fmod(time, 1.1 if phase == 0 else 0.85) < dt:
				world.enemy_shot(clone.pos + Vector2(0, 16), PI * 0.5, 620.0, {"radius": 6.0, "color": hologram, "look": "needle", "damage": 14.0})
		"hex_repeater":
			if fmod(time, 0.9 if phase == 0 else 0.7) < dt:
				var orb := world.enemy_shot(clone.pos + Vector2(0, 16), PI * 0.5, 150.0, {"radius": 8.0, "color": hologram})
				orb.homing = 1.2
		_:
			if fmod(time, 0.5 if phase == 0 else 0.38) < dt:
				for offset in [-9.0, 9.0]:
					world.enemy_shot(clone.pos + Vector2(offset, 14), PI * 0.5, 330.0, {"radius": 5.0, "color": hologram, "look": "bolt"})


func part_lost(part: Enemy) -> void:
	match part.part:
		"clone":
			defeat()
		"shell":
			# The device inside drops to the field: touch it to take control of the clone.
			var device := world.drop_pickup("projector", part.pos)
			device.vel = Vector2.ZERO
			device.anchored = true
			set_phase(1, "PROJECTOR EXPOSED - GRAB IT")


func pickup_taken(kind: String) -> void:
	if kind != "projector" or defeated:
		return
	var clone := part_named("clone")
	if clone != null and not clone.dead:
		world.allies.append({"pos": clone.pos, "fire_timer": 0.5, "look": "clone"})
		clone.dead = true
	world.emit("banner", {"text": "THE CLONE FIGHTS FOR YOU", "style": "gold"})
	memory["turned"] = true
	defeat()
