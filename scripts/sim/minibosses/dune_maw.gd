class_name DuneMaw
extends BossBase
## Planet mini-boss: a giant sand worm hunting you from underground. The ground rumbles where it will
## erupt (shown in advance); it bursts up in a ring of debris, spits at you while it's above ground,
## then dives again. Every third eruption it stays up longer, thrashing.

const SURFACE_SECONDS := 2.6
const LONG_SURFACE_SECONDS := 5.0

var eruptions := 0


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Dune Maw"
	title = "The Ground Has Teeth"
	look = "dune_maw"
	color = Color(0.95, 0.75, 0.45)


func spawn() -> void:
	origin = world.player.pos + Vector2.from_angle(world.rng.randf() * TAU) * 300.0
	add_part("core", Vector2.ZERO, 1500, 36, {"invulnerable": true, "hidden": true})
	place_parts()
	memory["state"] = "under"
	memory["timer"] = 2.0
	world.emit("shake", {"amount": 8.0})


func behave(dt: float) -> void:
	var core := part_named("core")
	memory["timer"] = float(memory["timer"]) - dt
	match memory["state"]:
		"under":
			# Tunnelling toward you; the rumble marks where it will come up.
			origin = origin.move_toward(world.player.pos, 260.0 * dt)
			place_parts()
			if memory["timer"] <= 0.0:
				memory["state"] = "rising"
				memory["timer"] = 1.0
				memory["target"] = world.player.pos
				world.add_zone("bomb_warning", world.player.pos, 95.0, 0.1, 22.0 * world.enemy_damage_scale, true,
					{"warn": 1.0, "color": Color(1, 0.75, 0.4)})
				world.emit("sound", {"name": "burrow"})
		"rising":
			if memory["timer"] <= 0.0:
				origin = memory["target"]
				place_parts()
				eruptions += 1
				core.hidden = false
				core.invulnerable = false
				entering = false
				memory["state"] = "up"
				memory["timer"] = LONG_SURFACE_SECONDS if eruptions % 3 == 0 else SURFACE_SECONDS
				world.enemy_ring(origin, 16 if phase == 0 else 22, 190.0, time, {"color": Color(1, 0.8, 0.5)})
				world.emit("burst_ground", {"pos": origin})
				world.emit("shake", {"amount": 12.0})
		"up":
			core.facing = (world.player.pos - origin).angle()
			if fmod(time, 0.7) < dt:
				world.enemy_aimed(origin, 3 if phase == 0 else 5, 0.5, 240.0, {"color": Color(0.95, 0.8, 0.5)})
			# A long surface: thrashing spirals of sand.
			if eruptions % 3 == 0 and fmod(time, 0.1) < dt:
				world.enemy_shot(origin, time * 3.0, 200.0, {"color": Color(1, 0.75, 0.4)})
			if memory["timer"] <= 0.0:
				core.hidden = true
				core.invulnerable = true
				memory["state"] = "under"
				memory["timer"] = 2.2
				world.emit("burst_ground", {"pos": origin})
				if phase >= 1:
					for i in 3:
						var brood := world.spawn_enemy("crawler", origin + Vector2.from_angle(TAU * i / 3.0) * 50.0)
						brood.memory["awake"] = true
	if phase == 0 and hp_fraction() < 0.5:
		set_phase(1, "THE MAW IS FURIOUS")
