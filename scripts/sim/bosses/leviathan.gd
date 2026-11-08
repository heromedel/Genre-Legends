class_name Leviathan
extends BossBase
## Corridor Run boss: a dreadnought far longer than the screen glides down the trench over your head.
## Its gun batteries come into view one after another; when its engine core finally reaches the top of
## the screen the hull stops, and the core fights for its life.

const HULL_LENGTH := 1300.0
const BATTERIES := [Vector2(-110, -180), Vector2(110, -380), Vector2(-110, -580), Vector2(110, -780), Vector2(-110, -980)]
const CORE_OFFSET := Vector2(0, -1180)
const STOP_Y := 220.0


func spawn() -> void:
	boss_name = "Leviathan"
	title = "The Sky Goes Dark"
	look = "leviathan"
	color = Color(0.6, 0.85, 1.0)
	origin = Vector2(world.bounds.get_center().x, -60)
	# The hull passes overhead, so its parts never ram you; only their guns are dangerous.
	add_part("core", CORE_OFFSET, 2600, 40, {"invulnerable": true, "contact": 0.0})
	for i in BATTERIES.size():
		add_part("battery%d" % i, BATTERIES[i], 340, 22, {"contact": 0.0})
	place_parts()


func behave(dt: float) -> void:
	var core := part_named("core")
	# The hull glides down over your head until the engine core reaches the top of the screen; it hurries
	# once its batteries are gone.
	var core_y := origin.y + CORE_OFFSET.y
	if core_y < STOP_Y:
		origin.y += (70.0 if not living_parts("battery").is_empty() else 170.0) * dt
	elif phase == 0:
		core.invulnerable = false
		set_phase(1, "ENGINE CORE EXPOSED")
	place_parts()
	# The fight (and its health bar) starts as the first battery comes into view.
	if entering and origin.y > 80.0:
		entering = false
	for battery: Enemy in living_parts("battery"):
		var on_screen := battery.pos.y > -10.0 and battery.pos.y < world.bounds.end.y - 60.0
		battery.facing = (world.player.pos - battery.pos).angle()
		if on_screen and fmod(time + battery.id * 0.37, 2.0) < dt:
			world.enemy_aimed(battery.pos, 3, 0.45, 250.0, {"color": Color(0.6, 0.85, 1.0)})
			world.emit("sound", {"name": "enemy_shot"})
	if phase == 0:
		return
	if phase == 1 and hp_fraction() < 0.35:
		set_phase(2, "REACTOR BREACH")
	if fmod(time, 0.12 if phase == 1 else 0.09) < dt:
		for arm in 2:
			world.enemy_shot(core.pos, PI * 0.5 + sin(time * 1.3) * 1.2 + (arm * 2 - 1) * 0.35, 210.0, {"color": Color(0.7, 0.9, 1.0)})
	if fmod(time, 3.0) < dt:
		world.enemy_ring(core.pos, 18 if phase == 1 else 26, 150.0, time, {"color": Color(0.5, 0.8, 1.0)})
	if phase == 2 and fmod(time, 5.0) < dt:
		for side in [-1.0, 1.0]:
			var drill := world.spawn_enemy("drill", core.pos + Vector2(side * 140.0, 30.0))
			drill.memory["awake"] = true
