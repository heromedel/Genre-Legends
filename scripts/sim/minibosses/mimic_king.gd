class_name MimicKing
extends BossBase
## Dungeon mini-boss: the treasure room was a trap. A chest the size of a cart, crowned, hopping at you
## and landing in rings of teeth. When hurt it spills gold coins (Data Shards) everywhere.


func spawn() -> void:
	boss_name = "Mimic King"
	title = "All That Glitters"
	look = "mimic_king"
	color = Color(1.0, 0.8, 0.35)
	add_part("core", Vector2.ZERO, 1300, 40)
	place_parts()
	memory["hop"] = 0.0
	world.emit("banner", {"text": "IT'S A MIMIC! A BIG ONE!", "style": "gold"})


func behave(dt: float) -> void:
	var core := part_named("core")
	if entering:
		if time > 0.8:
			entering = false
		return
	var hop := fmod(time, 1.4 if hp_fraction() > 0.5 else 1.0)
	if hop < 0.55:
		origin = origin.move_toward(world.player.pos, 300.0 * dt)
	elif hop - dt < 0.55:
		world.enemy_ring(origin, 14 if hp_fraction() > 0.5 else 20, 190.0, time, {"color": Color(1, 0.95, 0.85)})
		world.emit("shake", {"amount": 5.0})
		world.emit("sound", {"name": "mimic"})
	place_parts()
	core.memory["hop"] = hop
	if fmod(time, 5.0) < dt:
		for i in 4:
			world.drop_pickup("shard", origin, 1.0)
		world.enemy_aimed(origin, 5, 0.9, 260.0, {"color": Color(1, 0.8, 0.35)})
