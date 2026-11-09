class_name CrusherGate
extends BossBase
## Corridor mini-boss: two hydraulic pistons guard a gate core. Every few seconds they slam across the
## trench at your height, leaving one gap, shown in advance. Break a piston and its side goes quiet;
## the core opens once either is gone. The corridor waits until it falls.


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Crusher Gate"
	title = "Mind the Gap"
	look = "crusher_gate"
	color = Color(1.0, 0.8, 0.35)


func spawn() -> void:
	var half_width := float(memory.get("half_width", 300.0))
	memory["half_width"] = half_width
	origin = Vector2(origin.x if origin.x != 0.0 else world.bounds.get_center().x, -90)
	add_part("core", Vector2(0, -10), 1100, 32, {"invulnerable": true})
	add_part("piston0", Vector2(-half_width + 46, 20), 460, 26)
	add_part("piston1", Vector2(half_width - 46, 20), 460, 26)
	place_parts()


func behave(dt: float) -> void:
	if entering:
		origin.y = move_toward(origin.y, 130.0, 120.0 * dt)
		place_parts()
		if origin.y >= 130.0:
			entering = false
			world.emit("shake", {"amount": 12.0})
		return
	place_parts()
	var core := part_named("core")
	var pistons := living_parts("piston")
	if phase == 0 and pistons.size() < 2:
		core.invulnerable = false
		set_phase(1, "GATE CORE EXPOSED")
	if fmod(time, 3.2 if phase == 0 else 2.6) < dt and not pistons.is_empty():
		_slam(pistons)
	for piston: Enemy in pistons:
		if fmod(time + piston.id * 0.5, 1.8) < dt:
			world.enemy_aimed(piston.pos, 3, 0.4, 250.0, {"color": Color(1, 0.8, 0.4)})
	if fmod(time, 2.8) < dt:
		world.enemy_ring(core.pos, 12 if phase == 0 else 18, 160.0, time, {"color": Color(1, 0.7, 0.3)})
		world.emit("sound", {"name": "enemy_shot"})


## The pistons' arms shoot across the trench at your height, from each living side, leaving a gap.
func _slam(pistons: Array) -> void:
	var half_width := float(memory["half_width"])
	var y := world.player.pos.y
	var left := origin.x - half_width
	var right := origin.x + half_width
	var gap_center := world.rng.randf_range(left + 110.0, right - 110.0)
	for piston: Enemy in pistons:
		var from_left := piston.part == "piston0"
		var start := Vector2(left if from_left else right, y)
		var reach := (gap_center - 75.0 - left) if from_left else (right - gap_center - 75.0)
		if pistons.size() == 1:
			reach = half_width * 2.0 - 150.0
		world.add_zone("laser", start, 0.0, 0.35, 18.0 * world.enemy_damage_scale, true,
			{"warn": 0.85, "angle": 0.0 if from_left else PI, "length": maxf(reach, 40.0), "width": 54.0, "color": Color(1, 0.75, 0.3)})
	world.emit("sound", {"name": "door_slam"})
