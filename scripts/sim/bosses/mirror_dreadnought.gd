class_name MirrorDreadnought
extends BossBase
## The first region's gate boss and its lesson (GDD 9C): a dreadnought whose underside is a wall of
## mirrored plates that throw straight shots back at you. Its cooling vents are on its back. Homing
## missiles curve around the mirrors to reach them; so do meteors, blasts and a pilot brave enough
## to fly behind it. Break the vents and the mirrors shatter, exposing the core.

const MIRROR_OFFSETS := [Vector2(-220, 40), Vector2(-110, 62), Vector2(0, 70), Vector2(110, 62), Vector2(220, 40)]
const VENT_OFFSETS := [Vector2(-160, -62), Vector2(0, -84), Vector2(160, -62)]


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Mirror Dreadnought"
	title = "The First Gate Holds"
	look = "mirror_dreadnought"
	color = Color(0.75, 0.9, 1.0)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, -220)
	add_part("core", Vector2(0, -10), 2000, 46, {"invulnerable": true})
	for i in VENT_OFFSETS.size():
		add_part("vent%d" % i, VENT_OFFSETS[i], 300, 24)
	for i in MIRROR_OFFSETS.size():
		add_part("mirror%d" % i, MIRROR_OFFSETS[i], 9999, 40, {"invulnerable": true, "reflects": true, "contact": 0.0})
	place_parts()


func behave(dt: float) -> void:
	var settle_y := 250.0
	if entering:
		origin.y = move_toward(origin.y, settle_y, 150.0 * dt)
		place_parts()
		if origin.y >= settle_y:
			entering = false
			world.emit("banner", {"text": "THE HULL IS MIRRORED", "style": "blue"})
		return
	origin.x = world.bounds.get_center().x + sin(time * 0.4) * 170.0
	place_parts()
	var core := part_named("core")
	var vents := living_parts("vent")
	if phase == 0 and vents.size() <= 1:
		set_phase(1, "MIRRORS SHATTERED")
		core.invulnerable = false
		for mirror: Enemy in living_parts("mirror"):
			mirror.reflects = false
			mirror.invulnerable = false
			world.kill_enemy(mirror)
	if phase == 1 and hp_fraction() < 0.3:
		set_phase(2, "DREADNOUGHT OVERLOAD")
	match phase:
		0:
			if fmod(time, 2.3) < dt:
				var from: Enemy = living_parts("mirror")[int(time) % living_parts("mirror").size()]
				world.enemy_aimed(from.pos, 5, 0.7, 230.0, {"color": Color(0.75, 0.9, 1.0)})
				world.emit("sound", {"name": "enemy_shot"})
			if fmod(time, 6.0) < dt:
				for side in [-1.0, 1.0]:
					var fighter := world.spawn_enemy("dart", origin + Vector2(side * 260.0, 0))
					fighter.memory["no_formation"] = true
					fighter.vel = (world.player.pos - fighter.pos).normalized() * 240.0
		_:
			if fmod(time, 0.12) < dt:
				for arm in 4:
					world.enemy_shot(core.pos, time * (1.2 if phase == 1 else -1.7) + TAU * arm / 4.0, 180.0, {"color": Color(0.6, 0.85, 1.0)})
			if fmod(time, 3.0) < dt:
				world.enemy_ring(core.pos, 24, 140.0, time, {"color": Color(1.0, 0.75, 1.0), "radius": 6.0})
	if phase == 2 and fmod(time, 5.0) < dt:
		world.enemy_aimed(core.pos, 9, 1.6, 300.0, {"radius": 7.0, "color": Color(1, 0.5, 0.6)})
