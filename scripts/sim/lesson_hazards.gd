class_name LessonHazards
extends RefCounted
## The threats that make a lesson planet a lesson (GDD 9C). Needle swarms: volleys of tiny, fast,
## gently homing needles from off screen, weak alone and deadly in numbers. A Shield Generator answers them:
## a volley costs at most one hit (immunity after a hit, GDD 13E), and a level 1 generator is back for every
## other volley. A blade can cut them, Mirror Aegis turns them around, and dodging well survives them.
## In a dungeon they come out of vents in the room's own walls, glowing first, and only while the room still
## has enemies: never out of nowhere, through walls, or in a room already cleared (heromedel).

const NEEDLE_EVERY := 5.0
const NEEDLES_PER_VOLLEY := 12

var world: World
var lesson := ""
var timer := 3.0
var stage: Stage                 # the stage being played; a dungeon decides where the vents are
var vent := Vector2.ZERO         # a dungeon vent about to fire
var vent_warning := 0.0          # seconds until it does
## How long a dungeon vent glows before its volley.
const VENT_WARNING_SECONDS := 0.6


func _init(target_world: World, lesson_name: String) -> void:
	world = target_world
	lesson = lesson_name


func update(dt: float) -> void:
	if lesson != "needles" or not world.player.alive:
		return
	var dungeon := stage as DungeonStage
	if dungeon != null and dungeon.room_enemies_left().is_empty():
		vent_warning = 0.0
		return
	if vent_warning > 0.0:
		vent_warning -= dt
		if vent_warning <= 0.0:
			_volley(vent)
		return
	timer -= dt * world.enemy_fire_scale * world.enemy_time_scale()
	if timer > 0.0:
		return
	timer = NEEDLE_EVERY
	if dungeon != null:
		# A vent somewhere along the room's walls lights up, then fires.
		var room := dungeon.room_rect(dungeon.current).grow(-12.0)
		var along := world.rng.randf()
		vent = [Vector2(lerpf(room.position.x, room.end.x, along), room.position.y), Vector2(lerpf(room.position.x, room.end.x, along), room.end.y),
			Vector2(room.position.x, lerpf(room.position.y, room.end.y, along)), Vector2(room.end.x, lerpf(room.position.y, room.end.y, along))][world.rng.randi() % 4]
		vent_warning = VENT_WARNING_SECONDS
		world.emit("needle_warning", {"pos": vent})
		return
	_volley(world.player.pos + Vector2.from_angle(world.rng.randf() * TAU) * 560.0)


## One volley of needles from origin toward the player.
func _volley(origin: Vector2) -> void:
	var toward := (world.player.pos - origin).angle()
	# In a dungeon the fan of needles stays inside the room, even from a vent near a corner.
	var dungeon := stage as DungeonStage
	var room := dungeon.room_rect(dungeon.current).grow(-12.0) if dungeon != null else Rect2(-1e6, -1e6, 2e6, 2e6)
	for i in NEEDLES_PER_VOLLEY:
		var start := (origin + Vector2.from_angle(toward + PI * 0.5) * (i - NEEDLES_PER_VOLLEY * 0.5) * 22.0).clamp(room.position, room.end)
		var needle := world.enemy_shot(start, toward + world.rng.randf_range(-0.12, 0.12), 300.0,
			{"radius": 3.0, "damage": 5.0, "look": "needle", "color": Color(0.85, 1.0, 0.45), "life": 4.0})
		needle.homing = 1.5
	world.emit("needle_volley", {"from": origin})
	world.emit("sound", {"name": "dive"})
