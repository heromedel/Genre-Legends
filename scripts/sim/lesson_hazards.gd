class_name LessonHazards
extends RefCounted
## The threats that make a lesson planet a lesson (GDD 9C). Needle swarms: volleys of tiny, fast,
## gently homing needles from off screen, weak alone and deadly in numbers. Shields that reflect them
## (Mirror Aegis) turn the swarm around; a blade can cut them; dodging well survives them.

const NEEDLE_EVERY := 4.2
const NEEDLES_PER_VOLLEY := 10

var world: World
var lesson := ""
var timer := 3.0


func _init(target_world: World, lesson_name: String) -> void:
	world = target_world
	lesson = lesson_name


func update(dt: float) -> void:
	if lesson != "needles" or not world.player.alive:
		return
	timer -= dt * world.enemy_fire_scale * world.enemy_time_scale()
	if timer > 0.0:
		return
	timer = NEEDLE_EVERY
	var from_angle := world.rng.randf() * TAU
	var origin := world.player.pos + Vector2.from_angle(from_angle) * 560.0
	var toward := (world.player.pos - origin).angle()
	for i in NEEDLES_PER_VOLLEY:
		var start := origin + Vector2.from_angle(toward + PI * 0.5) * (i - NEEDLES_PER_VOLLEY * 0.5) * 22.0
		var needle := world.enemy_shot(start, toward + world.rng.randf_range(-0.12, 0.12), 300.0,
			{"radius": 3.0, "damage": 3.0, "look": "needle", "color": Color(0.85, 1.0, 0.45), "life": 4.0})
		needle.homing = 1.3
	world.emit("needle_volley", {"from": origin})
	world.emit("sound", {"name": "dive"})
