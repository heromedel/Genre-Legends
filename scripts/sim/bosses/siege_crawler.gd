class_name SiegeCrawler
extends BossBase
## Planet Exploration boss. A four-legged war machine stomps toward you, every leg a gun turret.
## Shoot out its legs and it crashes down, exposing its core, then fights on with mortar barrages.

const LEG_OFFSETS := [Vector2(-78, -62), Vector2(78, -62), Vector2(-78, 62), Vector2(78, 62)]

var collapsed := false


func spawn() -> void:
	boss_name = "Siege Crawler"
	title = "Walker of the Burning Plain"
	look = "siege_crawler"
	color = Color(1.0, 0.6, 0.3)
	var away := Vector2.from_angle(world.rng.randf() * TAU) * 420.0
	origin = (world.player.pos + away).clamp(world.bounds.position + Vector2(200, 200), world.bounds.end - Vector2(200, 200))
	add_part("core", Vector2.ZERO, 2600, 50, {"invulnerable": true})
	for i in LEG_OFFSETS.size():
		add_part("leg%d" % i, LEG_OFFSETS[i], 420, 24)
	place_parts()
	world.add_zone("enemy_ring", origin, 340.0, 0.8, 14.0 * world.enemy_damage_scale, true, {"color": Color(1, 0.6, 0.3)})
	world.emit("shake", {"amount": 16.0})
	memory["landing"] = 1.2


func behave(dt: float) -> void:
	if entering:
		memory["landing"] = float(memory["landing"]) - dt
		if memory["landing"] <= 0.0:
			entering = false
		return
	var core := part_named("core")
	var legs := living_parts("leg")
	if not collapsed:
		origin = origin.move_toward(world.player.pos, 46.0 * dt)
	place_parts(sin(time * 0.6) * 0.15)
	if not collapsed and legs.size() <= 1:
		collapsed = true
		core.invulnerable = false
		for leg: Enemy in legs:
			world.kill_enemy(leg)
		world.add_zone("enemy_ring", origin, 420.0, 0.9, 16.0 * world.enemy_damage_scale, true, {"color": Color(1, 0.6, 0.3)})
		set_phase(1, "IT'S DOWN - HIT THE CORE")
	if phase == 1 and hp_fraction() < 0.35:
		set_phase(2, "REACTOR UNSTABLE")
	# Legs: staggered aimed bursts.
	for leg: Enemy in legs:
		if fmod(time + float(leg.part.right(1)) * 0.6, 2.5) < dt:
			world.enemy_aimed(leg.pos, 3, 0.35, 250.0, {"color": Color(1, 0.6, 0.3)})
			world.emit("sound", {"name": "enemy_shot"})
	if phase == 0:
		if fmod(time, 4.5) < dt:
			world.enemy_ring(core.pos, 14, 160.0, time)
		return
	# Collapsed: mortar barrages and a flame spiral.
	if fmod(time, 3.0) < dt:
		for i in 5:
			var at := world.player.pos + (Vector2.ZERO if i == 0 else Vector2.from_angle(world.rng.randf() * TAU) * world.rng.randf_range(80, 220))
			world.add_zone("bomb_warning", at, 70.0, 0.1, 18.0 * world.enemy_damage_scale, true, {"warn": 1.1, "color": Color(1, 0.45, 0.3)})
		world.emit("sound", {"name": "mortar"})
	var spiral_every := 0.13 if phase == 1 else 0.09
	if fmod(time, spiral_every) < dt:
		for arm in 3:
			world.enemy_shot(core.pos, time * 1.4 + TAU * arm / 3.0, 175.0, {"color": Color(1, 0.6, 0.25)})
	if phase == 2 and fmod(time, 7.0) < dt:
		for i in 4:
			world.spawn_enemy("crawler", core.pos + Vector2.from_angle(TAU * i / 4.0) * 70.0)
