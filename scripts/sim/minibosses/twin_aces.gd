class_name TwinAces
extends BossBase
## Star Cluster mini-boss: two ace pilots flying mirror-image loops, crossing fire through the middle.
## Kill one and the survivor gets angry.

var angry := false


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Twin Aces"
	title = "Red and Blue"
	look = "twin_aces"
	color = Color(1.0, 0.4, 0.5)


func spawn() -> void:
	origin = Vector2(world.bounds.get_center().x, 180)
	add_part("ace0", Vector2(-200, -300), 520, 20)
	add_part("ace1", Vector2(200, -300), 520, 20)


func behave(dt: float) -> void:
	var speed := 1.6 if angry else 1.1
	var aces := living_parts("ace")
	# The aces dive in from off screen; once both are on the field the fight (and its health bar) starts.
	if entering and aces.all(func(ace): return ace.pos.y > 40.0):
		entering = false
	for ace: Enemy in aces:
		var side := -1.0 if ace.part == "ace0" else 1.0
		var target := origin + Vector2(side * cos(time * speed) * 360.0, sin(time * speed * 2.0) * 90.0)
		ace.pos = ace.pos.move_toward(target, 420.0 * dt)
		ace.facing = PI * 0.5
		if fmod(time + (0.0 if side < 0 else 0.5), 1.0 if angry else 1.4) < dt:
			world.enemy_aimed(ace.pos, 3, 0.4, 290.0, {"color": Color(1, 0.35, 0.5) if side < 0 else Color(0.5, 0.6, 1.0)})
			world.emit("sound", {"name": "enemy_shot"})
	if aces.size() == 2 and fmod(time, 4.0) < dt:
		# Crossfire: a line of bullets drawn between the two aces.
		for i in 9:
			var at: Vector2 = aces[0].pos.lerp(aces[1].pos, (i + 0.5) / 9.0)
			world.enemy_shot(at, PI * 0.5, 160.0, {"color": Color(1, 0.8, 0.9)})


func part_lost(part: Enemy) -> void:
	if living_parts("ace").is_empty():
		defeat()
	elif not angry:
		angry = true
		world.emit("banner", {"text": "THE SURVIVOR IS FURIOUS", "style": "red"})
