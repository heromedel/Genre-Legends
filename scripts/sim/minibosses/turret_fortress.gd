class_name TurretFortress
extends BossBase
## Corridor mini-boss: an armored bulkhead slams across the trench. Three turrets guard a sealed gate;
## knock them out and the gate's core is exposed. The corridor stops scrolling until it falls.

const TURRET_OFFSETS := [Vector2(-170, 10), Vector2(0, 28), Vector2(170, 10)]


## Who this boss is, known from the moment it's made so its warning can name it.
func introduce() -> void:
	boss_name = "Bulkhead Fortress"
	title = "None Shall Pass"
	look = "turret_fortress"
	color = Color(1.0, 0.65, 0.3)


func spawn() -> void:
	origin = Vector2(origin.x if origin.x != 0.0 else world.bounds.get_center().x, -90)
	var spread := minf(170.0, float(memory.get("half_width", 300.0)) - 50.0) / 170.0
	add_part("core", Vector2(0, -24), 900, 34, {"invulnerable": true})
	for i in TURRET_OFFSETS.size():
		var offset: Vector2 = TURRET_OFFSETS[i]
		add_part("turret%d" % i, Vector2(offset.x * spread, offset.y), 300, 22)
	place_parts()


func behave(dt: float) -> void:
	if entering:
		origin.y = move_toward(origin.y, 140.0, 120.0 * dt)
		place_parts()
		if origin.y >= 140.0:
			entering = false
			world.emit("shake", {"amount": 12.0})
		return
	place_parts()
	var core := part_named("core")
	var turrets := living_parts("turret")
	if phase == 0 and turrets.is_empty():
		core.invulnerable = false
		set_phase(1, "THE FORTRESS GUNS FALL SILENT")
	# Each gun fires a short spread in turn; with hits that matter (GDD 13), three guns at full rate down a
	# trench was a wall of fire, so they take turns and the core's ring comes less often.
	for turret: Enemy in turrets:
		turret.facing = (world.player.pos - turret.pos).angle()
		if fmod(time + turret.id * 0.7, 2.2) < dt:
			world.enemy_aimed(turret.pos, 3, 0.45, 260.0, {"color": Color(1, 0.6, 0.3)})
			world.emit("sound", {"name": "enemy_shot"})
	if fmod(time, 4.5) < dt:
		world.enemy_ring(core.pos, 14 if phase == 0 else 22, 150.0, time, {"color": Color(1, 0.5, 0.35)})
	if phase == 1 and fmod(time, 0.15) < dt:
		world.enemy_shot(core.pos, PI * 0.5 + sin(time * 2.0) * 1.1, 220.0, {"color": Color(1, 0.75, 0.4)})
