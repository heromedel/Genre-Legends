class_name CorridorStage
extends Stage
## Corridor Run (GDD 6A): a fortified trench at full speed. The walls narrow and widen, turrets line them,
## drills charge down the middle and laser gates flicker across the corridor: wait for the gap or eat it.
## Scraping a wall chips your armor (attrition, never an instant wreck). At the end: the Wyrm Engine.

const FIELD := Rect2(0, 0, 1200, 800)
const SCROLL_SPEED := 170.0
const LENGTH := 20000.0             # pixels of corridor before the boss (about five minutes, GDD 9B)
const FORTRESS_AT := 9500.0          # where the mini-boss bulkhead blocks the trench
const REPAIRS_AT := [0.25, 0.75]    # parts of the run where a repair kit drifts down the trench (GDD 13G)
const SEGMENT := 40.0               # wall collision is built from strips this tall

var distance := 0.0                 # how far the corridor has scrolled
var next_event := 500.0
var gates: Array = []               # {y, zone, period, timer}
var scrape_timer := 0.0
var corridor_seed := 0.0
var fortress_skipped := false
var repairs_sent := 0
var length := LENGTH                 # shorter when a mission dives into this corridor from another stage


func stage_name() -> String:
	return "Corridor Run"


func setup() -> void:
	form = "ship"
	camera_mode = "fixed"
	world.bounds = FIELD
	world.shot_bounds = FIELD.grow(120)
	mission.player.pos = Vector2(FIELD.get_center().x, FIELD.end.y - 110)
	corridor_seed = world.rng.randf() * 100.0
	# Dived into from another stage: a shorter run straight to the boss (the other stage had the mini-boss).
	if short_stage:
		length = LENGTH * 0.45
		fortress_skipped = true
	_rebuild_walls()


## Half-width of the open corridor at a given corridor distance. Narrows as the run goes on;
## opens wide for the boss.
func half_width_at(corridor_y: float) -> float:
	if corridor_y > length + 300.0:
		return 560.0
	var progress := clampf(corridor_y / length, 0.0, 1.0)
	var base := lerpf(420.0, 300.0, progress)
	var wave := sin(corridor_y * 0.0021 + corridor_seed) * 70.0 + sin(corridor_y * 0.0053 + corridor_seed * 2.0) * 35.0
	return clampf(base + wave, 190.0, 560.0)


func center_at(corridor_y: float) -> float:
	if corridor_y > length + 300.0:
		return FIELD.get_center().x
	return FIELD.get_center().x + sin(corridor_y * 0.0013 + corridor_seed * 3.0) * 110.0


## Corridor distance at a screen y: the top of the screen is furthest along.
func corridor_y_at(screen_y: float) -> float:
	return distance + (FIELD.end.y - screen_y)


func left_edge(screen_y: float) -> float:
	var y := corridor_y_at(screen_y)
	return center_at(y) - half_width_at(y)


func right_edge(screen_y: float) -> float:
	var y := corridor_y_at(screen_y)
	return center_at(y) + half_width_at(y)


func _rebuild_walls() -> void:
	var walls := []
	var y := -SEGMENT
	while y < FIELD.end.y + SEGMENT:
		var left := left_edge(y + SEGMENT * 0.5)
		var right := right_edge(y + SEGMENT * 0.5)
		walls.append(Rect2(-200, y, left + 200, SEGMENT))
		walls.append(Rect2(right, y, FIELD.end.x + 200 - right, SEGMENT))
		y += SEGMENT
	world.walls = walls


func step(dt: float) -> void:
	# The trench stops while the bulkhead fortress blocks it.
	var scroll := SCROLL_SPEED * dt * (0.6 if boss != null else (0.0 if miniboss_active() else 1.0))
	distance += scroll
	_rebuild_walls()
	# Everything attached to the corridor scrolls with it.
	for enemy: Enemy in world.enemies:
		if enemy.brain == "wall_turret":
			enemy.pos.y += scroll
			var on_left: bool = enemy.memory.get("left", true)
			enemy.pos.x = left_edge(enemy.pos.y) + 16.0 if on_left else right_edge(enemy.pos.y) - 16.0
	for pickup: Pickup in world.pickups:
		pickup.pos.y += scroll * 0.5
	_update_gates(dt, scroll)
	update_miniboss(dt)
	if boss != null:
		boss.update(dt)
		return
	if mission.state != "play":
		return
	if miniboss == null and distance >= FORTRESS_AT and not fortress_skipped:
		# The bulkhead fits the trench where it lands, so every turret is in reach.
		var fortress := BossRoster.make(BossRoster.for_node(mission.node, "miniboss"), world)
		var y := corridor_y_at(140.0)
		fortress.origin.x = center_at(y)
		fortress.memory["half_width"] = half_width_at(y)
		# Anything still waiting above the screen would sit frozen there while the trench stops.
		for enemy: Enemy in world.enemies:
			if enemy.pos.y < 20.0:
				enemy.dead = true
		start_miniboss(fortress)
	if miniboss_active():
		return
	if distance >= next_event and distance < length:
		_spawn_event()
		next_event += world.rng.randf_range(260.0, 420.0) / world.spawn_scale
	# The trench has nothing placed to repair at, so kits drift down it, one each side of the bulkhead.
	if repairs_sent < REPAIRS_AT.size() and distance >= length * REPAIRS_AT[repairs_sent]:
		repairs_sent += 1
		world.drop_pickup("repair", Vector2(center_at(corridor_y_at(-20.0)), -20.0))
	if distance >= length + 500.0 and not boss_started:
		start_boss(BossRoster.make(BossRoster.for_node(mission.node, "boss"), world))


func after_player_moved() -> void:
	var player := mission.player
	scrape_timer -= World.DT
	var left := left_edge(player.pos.y)
	var right := right_edge(player.pos.y)
	if player.pos.x - player.radius <= left + 2.0 or player.pos.x + player.radius >= right - 2.0:
		if scrape_timer <= 0.0:
			scrape_timer = 0.35
			world.damage_player(MissionData.HIT_CHIP * world.enemy_damage_scale, "wall scrape")
			world.emit("spark", {"pos": player.pos, "color": Color(1, 0.8, 0.5)})


func _spawn_event() -> void:
	var roll := world.rng.randf()
	var top := -30.0
	var left := left_edge(0)
	var right := right_edge(0)
	if roll < 0.26:
		var on_left := world.rng.randf() < 0.5
		var turret := world.spawn_enemy("wall_turret", Vector2(left + 16.0 if on_left else right - 16.0, top))
		turret.memory["left"] = on_left
	elif roll < 0.55:
		for i in 2:
			world.spawn_enemy("drill", Vector2(world.rng.randf_range(left + 60, right - 60), top - i * 60))
	elif roll < 0.75:
		for i in 3:
			var wasp := world.spawn_enemy("wasp", Vector2(lerpf(left + 80, right - 80, (i + 0.5) / 3.0), top - i * 40))
			wasp.memory["base_x"] = wasp.pos.x
	elif roll < 0.88 and distance > 1500.0:
		_add_gate()
	else:
		for i in 4:
			var dart := world.spawn_enemy("dart", Vector2(world.rng.randf_range(left + 60, right - 60), top - i * 50))
			dart.memory["no_formation"] = true
			dart.vel = Vector2(0, 160)


## A laser gate spans the corridor and cycles: warning flicker, then a deadly beam, then off. No banner: the
## flicker says it all (heromedel).
func _add_gate() -> void:
	gates.append({"y": -20.0, "zone": null, "timer": world.rng.randf_range(0.0, 1.0)})


func _update_gates(dt: float, scroll: float) -> void:
	for gate in gates:
		gate["y"] += scroll
		gate["timer"] -= dt
		if gate["timer"] <= 0.0 and gate["zone"] == null:
			var zone := world.add_zone("laser", Vector2(-100, gate["y"]), 0.0, 1.4, 16.0 * world.enemy_damage_scale, true,
				{"warn": 0.9, "angle": 0.0, "length": FIELD.end.x + 200, "width": 18.0, "color": Color(1, 0.3, 0.4)})
			gate["zone"] = zone
		var zone: Zone = gate["zone"]
		if zone != null:
			zone.pos.y = gate["y"]
			if zone.dead:
				gate["zone"] = null
				gate["timer"] = 1.4
	gates = gates.filter(func(g): return g["y"] < FIELD.end.y + 60.0)


func debug_skip_to_boss() -> void:
	distance = length + 480.0
	fortress_skipped = true
	for enemy: Enemy in world.enemies:
		enemy.dead = true


func debug_skip_to_miniboss() -> void:
	distance = FORTRESS_AT - 60.0


func stage_progress() -> float:
	return distance / length


func is_cleared() -> bool:
	return boss != null and boss.finished


func objective_text() -> String:
	if boss != null:
		return "Destroy the %s" % boss.boss_name
	if miniboss_active():
		return "Break the %s" % miniboss.boss_name
	return "Corridor %d%%" % int(clampf(distance / length, 0.0, 1.0) * 100.0)
