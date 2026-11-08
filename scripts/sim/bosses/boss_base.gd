class_name BossBase
extends RefCounted
## The shared shape of every boss (GDD 6H proposal: every boss is a set piece). A boss is a group of
## hittable parts (Enemy objects with brain "boss_part") moved and fired by the boss script, with phases
## that change how the fight plays. Each subclass writes its own entrance, phases and attacks.

var world: World
var boss_name := "Boss"
var title := ""
var look := ""                  # picks the art in BossArt
var parts: Array = []
var origin := Vector2.ZERO
var phase := 0
var time := 0.0
var entering := true
var defeated := false
var finished := false
var death_timer := 0.0
var memory := {}
var color := Color(1, 0.5, 0.4)


func _init(target_world: World) -> void:
	world = target_world


## A pickup this fight dropped was collected (the Clone Projector's projector).
func pickup_taken(_kind: String) -> void:
	pass


## Dungeon bosses fight inside a room; the stage hands them its rectangle before they spawn.
func setup_room(_room_rect: Rect2) -> void:
	pass


## Creates the parts and starts the entrance.
func spawn() -> void:
	pass


func update(dt: float) -> void:
	if finished:
		return
	if defeated:
		_death_sequence(dt)
		return
	# Danger and Threat make bosses cycle their attacks (and move) faster.
	var boss_dt := dt * world.enemy_time_scale() * world.enemy_fire_scale
	time += boss_dt
	# Debug launches can start the fight in a later phase, once the entrance is over.
	if not entering and int(memory.get("debug_phase", 0)) > phase:
		set_phase(int(memory["debug_phase"]), "")
	behave(boss_dt)


## Movement, phases and attacks. Subclasses fill this in.
func behave(_dt: float) -> void:
	pass


func add_part(part_name: String, offset: Vector2, hp: float, radius: float, options: Dictionary = {}) -> Enemy:
	var part := world.spawn_enemy("boss_part", origin + offset)
	part.boss = self
	part.part = part_name
	part.max_hp = hp * 1.3 * world.enemy_hp_scale
	part.hp = part.max_hp
	part.radius = radius
	part.look = look
	part.color = color
	part.contact = 18.0 * world.enemy_damage_scale
	part.xp = 0
	part.memory["offset"] = offset
	for key in options:
		part.set(key, options[key])
	parts.append(part)
	return part


func part_named(part_name: String) -> Enemy:
	for part: Enemy in parts:
		if part.part == part_name:
			return part
	return null


func living_parts(prefix: String) -> Array:
	return parts.filter(func(p): return not p.dead and p.part.begins_with(prefix))


## Places each living part at origin + its offset (rotated if the boss turns).
func place_parts(rotation: float = 0.0) -> void:
	for part: Enemy in parts:
		if not part.dead:
			var offset: Vector2 = part.memory.get("offset", Vector2.ZERO)
			part.pos = origin + offset.rotated(rotation)


func on_part_destroyed(_world: World, part: Enemy) -> void:
	world.emit("boss_part_destroyed", {"pos": part.pos, "part": part.part})
	world.emit("shake", {"amount": 8.0})
	for i in 3:
		world.drop_pickup("shard", part.pos, 3.0)
	part_lost(part)


## Reacts to losing a part. Losing the core part ends the fight.
func part_lost(part: Enemy) -> void:
	if part.part == "core":
		defeat()


func hp_fraction() -> float:
	var total := 0.0
	var remaining := 0.0
	for part: Enemy in parts:
		if part.reflects or part.part.begins_with("mirror") or part.memory.get("unbreakable", false):
			continue
		total += part.max_hp
		if part.reflects or part.part.begins_with("mirror"):
			continue
		remaining += maxf(part.hp, 0.0) if not part.dead else 0.0
	return remaining / total if total > 0.0 else 0.0


func defeat() -> void:
	if defeated:
		return
	defeated = true
	death_timer = 2.4
	world.run.bosses_defeated.append(look)
	world.clear_bullets(origin, 4000.0)
	world.zones = world.zones.filter(func(z): return not z.hostile)
	for part: Enemy in parts:
		if not part.dead:
			part.dead = true
	for i in 10:
		world.drop_pickup("shard", origin + Vector2.from_angle(TAU * i / 10.0) * 30.0, 3.0)
	if memory.get("final", false):
		# The mission's prize: the planet's blueprints in one big pickup. The mission ends once it's taken.
		var prize := world.drop_pickup("prize", origin)
		prize.vel = Vector2.ZERO
		prize.anchored = true
		world.prize_waiting = true
	else:
		world.drop_pickup("crate", origin)
	var reward_tech: String = world.elite_blueprint_tech
	if reward_tech == "":
		var ids := TechData.TECH.keys()
		reward_tech = ids[world.rng.randi() % ids.size()]
	world.drop_pickup("blueprint", origin + Vector2(30, 0), 1.0, reward_tech)
	world.emit("boss_defeated", {"name": boss_name, "pos": origin})
	world.emit("sound", {"name": "boss_down"})
	world.emit("flash", {"color": Color(1, 0.9, 0.7), "amount": 0.6})


func _death_sequence(dt: float) -> void:
	death_timer -= dt
	if fmod(death_timer, 0.18) < dt:
		var at := origin + Vector2(world.rng.randf_range(-90, 90), world.rng.randf_range(-60, 60))
		world.emit("explosion", {"pos": at, "size": world.rng.randf_range(30, 70), "color": color})
		world.emit("shake", {"amount": 5.0})
		world.emit("sound", {"name": "explode"})
	if death_timer <= 0.0:
		finished = true
		world.emit("explosion", {"pos": origin, "size": 220.0, "color": Color(1, 0.9, 0.7), "ring": true})
		world.emit("shake", {"amount": 18.0})
		world.emit("sound", {"name": "explode_big"})


func set_phase(new_phase: int, banner: String) -> void:
	if new_phase <= phase:
		return
	phase = new_phase
	if banner != "":
		world.emit("banner", {"text": banner, "style": "red"})
	world.emit("sound", {"name": "phase"})
	world.emit("shake", {"amount": 10.0})
