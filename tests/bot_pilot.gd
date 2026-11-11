class_name BotPilot
extends RefCounted
## A competent bot that plays any mission type through InputFrames only, like a player would.
## Used by the QA harness (GDD 4A). It plans its dodges (reads shot paths ahead, picks a safe spot that keeps it
## on target, commits until it re-plans), chases objectives, explores dungeons room by room,
## uses its special when things get hairy, and picks level-up cards by a simple preference.
## Its aim is tracked: a bot that misses when it shouldn't is a bug (GDD 4D).

var mission: Mission
var rng := RandomNumberGenerator.new()
var fork_preference := "a"
var stuck_timer := 0.0
var frozen_timer := 0.0          # seconds since the last stuck check
var escape_timer := 0.0          # while > 0, head for the middle of the area to get unstuck
var frozen_pos := Vector2.ZERO
var last_pos := Vector2.ZERO
var wander := Vector2.ZERO
var grid := AStarGrid2D.new()
var grid_key := ""
var cached_path: PackedVector2Array = PackedVector2Array()
var cached_goal := Vector2.INF
var path_age := 0
const CELL := 40.0
## "average" plays like an average player: notices bullets later, sometimes freezes, picks cards loosely.
var average := false
## How well it dodges, 0 to 1 (heromedel: a bot that's too good is as misleading as one that's too bad). It sets
## how often it re-plans (reaction), how far ahead it reads shots, how wide a margin it keeps, and how often it
## lapses. Left at -1: 1.0, or 0.45 for an "average" bot. Calibrated against heromedel's own logs.
var skill := -1.0
var plan_target := Vector2.INF    # the safe spot it's heading for until the next re-plan
var plan_age := 999
const COMMIT_MARGIN := 12.0       # how much better another spot must score before it changes its mind
## Calibrated on planet 1 at 0.6.1's density (2026-11-11), where heromedel took 0 hits: skill 1.0 takes 0, 0.8 about
## half a hit, 0.4 about 2 (the design's "average player" target there), 0.2 about 6, 0.0 about 10.
const AVERAGE_SKILL := 0.4
const HEROMEDEL_SKILL := 0.85


func _init(target: Mission, bot_seed: int, prefer_fork: String = "a") -> void:
	mission = target
	rng.seed = bot_seed
	fork_preference = prefer_fork


func next_input() -> InputFrame:
	var frame := InputFrame.new()
	if mission.state == "offer":
		frame.choice = _choose_card()
		return frame
	if mission.state == "crate":
		frame.choice = 0
		return frame
	var player := mission.player
	var world := mission.world
	if player.form == "ship":
		var target_x := world.bounds.get_center().x
		var nearest := _hittable_target(player.pos)
		if nearest != null:
			target_x = nearest.pos.x
		var desired := Vector2(target_x, world.bounds.end.y - 120.0) - player.pos
		if mission.stage is CorridorStage:
			var stage: CorridorStage = mission.stage
			var mid := (stage.left_edge(player.pos.y) + stage.right_edge(player.pos.y)) * 0.5
			desired.x = clampf(desired.x, stage.left_edge(player.pos.y) + 40.0 - player.pos.x, stage.right_edge(player.pos.y) - 40.0 - player.pos.x)
			if absf(player.pos.x - mid) > 200.0:
				desired.x = mid - player.pos.x
		# Plan a safe spot that keeps it under its target, and go there at a player's pace.
		var target := _plan(player.pos + desired)
		frame.drag = (target - player.pos).limit_length(player.speed * 1.25 * World.DT)
	else:
		var goal := _waypoint(_ground_goal())
		var to_goal := goal - player.pos
		var direction := to_goal.normalized() if to_goal.length() > 30.0 else Vector2.ZERO
		var nearest := world.nearest_enemy(player.pos, 400.0)
		if nearest != null and nearest.pos.distance_to(player.pos) < 170.0:
			direction += (player.pos - nearest.pos).normalized() * 0.8
		var boss := mission.stage.active_boss()
		if boss != null and not boss.defeated and boss.origin.distance_to(player.pos) < 300.0:
			direction += (player.pos - boss.origin).normalized() * 1.5
		# Plan a safe spot on the way to the goal, and walk to it.
		var planned := _plan(player.pos + direction.normalized() * 120.0 if direction.length() > 0.05 else player.pos)
		direction = (planned - player.pos).normalized() if planned.distance_to(player.pos) > 4.0 else Vector2.ZERO
		direction = _avoid_walls(direction)
		if player.pos.distance_to(last_pos) < 1.0 and direction.length() > 0.2:
			stuck_timer += World.DT
		else:
			stuck_timer = 0.0
		last_pos = player.pos
		if stuck_timer > 0.6:
			wander = Vector2.from_angle(rng.randf() * TAU)
			stuck_timer = 0.0
		# A last resort: if we haven't moved at all for 3 s, head for the middle of the room or area.
		# Checked every 3 s: barely moved since the last check (standing or jittering in place) means stuck.
		frozen_timer += World.DT
		if frozen_timer >= 3.0:
			frozen_timer = 0.0
			if player.pos.distance_to(frozen_pos) < 40.0 and mission.state == "play":
				escape_timer = 1.5
			frozen_pos = player.pos
		if escape_timer > 0.0:
			escape_timer -= World.DT
			var middle := (mission.stage as DungeonStage).room_rect((mission.stage as DungeonStage).current).get_center() if mission.stage is DungeonStage else world.bounds.get_center()
			direction = (middle - player.pos).normalized()
		if wander != Vector2.ZERO:
			direction = (direction + wander * 1.5)
			wander *= 0.97
			if wander.length() < 0.1:
				wander = Vector2.ZERO
		frame.move = direction.limit_length(1.0)
	var threats := 0
	for shot: Shot in world.enemy_shots:
		if shot.pos.distance_to(player.pos) < 160.0:
			threats += 1
	frame.special = threats > 10 or (player.armor_fraction() < 0.35 and threats > 3)
	return frame.quantized()


## The closest enemy on screen that a shot can actually hurt: an armoured boss core isn't worth lining up under,
## so the bot goes for the turrets, pods or legs that open it (a bot shooting at what can't be hurt is a bug,
## GDD 4D).
func _hittable_target(from: Vector2) -> Enemy:
	var best: Enemy = null
	var best_distance := INF
	for enemy: Enemy in mission.world.enemies:
		if enemy.dead or enemy.hidden or enemy.invulnerable or enemy.pos.y <= 0.0:
			continue
		var distance := from.distance_squared_to(enemy.pos)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func _skill() -> float:
	if skill >= 0.0:
		return skill
	return AVERAGE_SKILL if average else 1.0


## The shoot-'em-up loop (heromedel's three steps, and two more): read where every nearby shot will be over the
## next fraction of a second; find the spots the frame can reach that none of them crosses on the way; among
## those, prefer the one that keeps it on target (want); re-plan only at its reaction speed and commit in
## between; and let shots the Arc Blade is about to cut through count for less.
func _plan(want: Vector2) -> Vector2:
	var player := mission.player
	var world := mission.world
	var level := _skill()
	var reaction := int(round(lerpf(36.0, 3.0, level)))
	plan_age += 1
	if plan_age < reaction and plan_target != Vector2.INF:
		return plan_target
	plan_age = 0
	# A weaker player sometimes simply doesn't react this time.
	if rng.randf() < maxf(0.6 - level, 0.0) * 0.8:
		plan_target = want if plan_target == Vector2.INF else plan_target
		return plan_target
	var horizon := lerpf(0.2, 0.8, level)
	var notice := lerpf(110.0, 380.0, level)
	var margin := lerpf(0.0, 14.0, level)
	# And misjudges where shots are by up to this much.
	var misread := lerpf(28.0, 0.0, level)
	var speed := player.speed * (1.25 if player.form == "ship" else 1.0)
	var threats := []
	for shot: Shot in world.enemy_shots:
		if not shot.dead and shot.pos.distance_to(player.pos) < notice:
			threats.append([shot.pos + Vector2(rng.randf_range(-misread, misread), rng.randf_range(-misread, misread)), shot.vel, shot.radius])
	for enemy: Enemy in world.enemies:
		if not enemy.dead and not enemy.hidden and enemy.contact > 0.0 and enemy.pos.distance_to(player.pos) < notice:
			threats.append([enemy.pos, enemy.vel, enemy.radius])
	var blade_ready: bool = mission.run.is_online("arc_blade") and float(mission.run.tech_timer.get("arc_blade", 9.0)) < 0.35
	var blade_reach := 118.0 + 12.0 * mission.run.level_of("arc_blade")
	var best := player.pos
	var best_score := INF
	var current_score := INF          # how the spot it's already heading for scores now
	var candidates := [player.pos, plan_target if plan_target != Vector2.INF else player.pos, want]
	for ring in [40.0, 80.0, 130.0, 190.0]:
		for i in 12:
			candidates.append(player.pos + Vector2.from_angle(TAU * i / 12.0) * ring)
	for spot: Vector2 in candidates:
		if not _spot_allowed(spot):
			continue
		var distance := player.pos.distance_to(spot)
		var danger := 0.0
		for k in range(1, 9):
			var t := horizon * k / 8.0
			var at := player.pos.move_toward(spot, speed * t)
			for threat in threats:
				var future: Vector2 = threat[0] + threat[1] * t
				var clearance: float = at.distance_to(future) - (player.radius + float(threat[2]) + margin)
				var weight := 1.0
				if blade_ready and future.y < at.y and future.distance_to(at) < blade_reach:
					weight = 0.25
				if clearance < 0.0:
					danger += 1000.0 * weight / (1.0 + t * 3.0)
				else:
					danger += weight * exp(-clearance / 18.0) * 4.0
		for zone: Zone in world.zones:
			if zone.hostile and _zone_covers(zone, spot):
				danger += 1500.0
		var score := danger + spot.distance_to(want) * 0.08 + distance * 0.02
		if plan_target != Vector2.INF and spot == plan_target:
			current_score = score
		if score < best_score:
			best_score = score
			best = spot
	# Commit: keep heading for the chosen spot unless another is clearly better. Dodging left and dodging
	# right score almost the same against a shot coming straight at you; re-picking every few ticks would
	# swing between them and go nowhere (the first planning bot did exactly that).
	if current_score < INF and best_score > current_score - COMMIT_MARGIN and player.pos.distance_to(plan_target) > 6.0:
		best = plan_target
	plan_target = best
	return best


func _spot_allowed(spot: Vector2) -> bool:
	var world := mission.world
	if not world.bounds.grow(-24.0).has_point(spot) or world.point_in_wall(spot):
		return false
	if mission.stage is CorridorStage:
		var stage: CorridorStage = mission.stage
		return spot.x > stage.left_edge(spot.y) + 26.0 and spot.x < stage.right_edge(spot.y) - 26.0
	return true


func _zone_covers(zone: Zone, spot: Vector2) -> bool:
	if zone.kind == "laser":
		var direction := Vector2.from_angle(zone.angle)
		var along := (spot - zone.pos).dot(direction)
		var across := absf((spot - zone.pos).dot(direction.orthogonal()))
		return along >= 0.0 and along <= zone.length and across < zone.width * 0.5 + 16.0
	return spot.distance_to(zone.pos) < zone.radius + 14.0


func _avoid_walls(direction: Vector2) -> Vector2:
	var player := mission.player
	if direction.length() < 0.1:
		return direction
	var probe := player.pos + direction.normalized() * 50.0
	if not mission.world.point_in_wall(probe):
		return direction
	for angle in [0.6, -0.6, 1.2, -1.2, 1.8, -1.8]:
		var turned := direction.rotated(angle)
		if not mission.world.point_in_wall(player.pos + turned.normalized() * 50.0):
			return turned
	return -direction


func _ground_goal() -> Vector2:
	var stage := mission.stage
	var player := mission.player
	if stage is PlanetStage:
		var fighting := stage.active_boss()
		if fighting != null and not fighting.defeated:
			return fighting.origin + (player.pos - fighting.origin).normalized() * 330.0
		var targets: Array = stage.objective_positions()
		var best := player.pos
		var best_distance := INF
		for target in targets:
			if player.pos.distance_to(target) < best_distance:
				best_distance = player.pos.distance_to(target)
				best = target
		var nearest := mission.world.nearest_enemy(player.pos, 500.0)
		if nearest != null and nearest.objective:
			return nearest.pos + (player.pos - nearest.pos).normalized() * 220.0
		for pickup: Pickup in mission.world.pickups:
			if pickup.kind in ["crate", "repair"] and player.pos.distance_to(pickup.pos) < 500.0:
				return pickup.pos
		return best
	if stage is DungeonStage:
		return _dungeon_goal(stage)
	return player.pos


func _dungeon_goal(stage: DungeonStage) -> Vector2:
	var player := mission.player
	var room: Dictionary = stage.rooms[stage.current]
	var rect := stage.room_rect(stage.current)
	if room["state"] == "active":
		var target := mission.world.nearest_enemy(player.pos, 1500.0)
		if target != null:
			# No clear line of fire? Walk toward it; the wall-avoidance steers around the block.
			if not _clear_line(player.pos, target.pos):
				var best := target.pos
				var best_distance := INF
				for i in 8:
					var spot := target.pos + Vector2.from_angle(TAU * i / 8.0) * 230.0
					if mission.world.point_in_wall(spot) or not _clear_line(spot, target.pos):
						continue
					if spot.distance_to(player.pos) < best_distance:
						best_distance = spot.distance_to(player.pos)
						best = spot
				return best
			return target.pos + (player.pos - target.pos).normalized() * 230.0
		for enemy: Enemy in mission.world.enemies:
			if enemy.brain == "mimic" and enemy.state == 0:
				return enemy.pos
		return rect.get_center()
	for pickup: Pickup in mission.world.pickups:
		if pickup.kind in ["key", "pedestal", "crate", "repair"] and rect.has_point(pickup.pos):
			return pickup.pos
	# Pick the next room: the nearest unvisited room, or the boss room once we hold the key.
	var target_room := _next_room(stage)
	var path := _path(stage, stage.current, target_room)
	if path.size() < 2:
		return rect.get_center()
	var step: Vector2i = path[1]
	var direction := ""
	for d in DungeonStage.DIRECTIONS:
		if stage.current + DungeonStage.DIRECTIONS[d] == step:
			direction = d
	var door := rect.get_center() + Vector2(DungeonStage.DIRECTIONS[direction]) * (rect.size * 0.5 + Vector2(60, 60))
	# Line up with the door before walking through it.
	var lineup := rect.get_center() + Vector2(DungeonStage.DIRECTIONS[direction]) * (rect.size * 0.5 - Vector2(140, 140))
	var horizontal := direction == "e" or direction == "w"
	var aligned := absf((player.pos.y - rect.get_center().y) if horizontal else (player.pos.x - rect.get_center().x)) < 40.0
	var goal := door if aligned else lineup
	# Blocks in the way are routed round by the A* waypoints (_waypoint), so no hand-made detours here.
	return goal


func _clear_line(from: Vector2, to: Vector2) -> bool:
	var steps := int(from.distance_to(to) / 20.0)
	for i in range(1, steps):
		if mission.world.point_in_wall(from.lerp(to, float(i) / steps)):
			return false
	return true


func _next_room(stage: DungeonStage) -> Vector2i:
	if stage.has_key:
		return stage.boss_room
	var best := stage.current
	var best_length := 999
	for key in stage.rooms:
		if stage.rooms[key]["visited"] or key == stage.boss_room or key == stage.secret_room:
			continue
		var length := _path(stage, stage.current, key).size()
		if length > 0 and length < best_length:
			best_length = length
			best = key
	if best == stage.current:
		return stage.key_room
	return best


func _path(stage: DungeonStage, from: Vector2i, to: Vector2i) -> Array:
	var came := {from: from}
	var queue := [from]
	while not queue.is_empty():
		var at: Vector2i = queue.pop_front()
		if at == to:
			break
		for d in stage.rooms[at]["doors"]:
			var next: Vector2i = stage.rooms[at]["doors"][d]
			if next == stage.secret_room:
				continue
			if not came.has(next):
				came[next] = at
				queue.append(next)
	if not came.has(to):
		return []
	var path := [to]
	while path[0] != from:
		path.push_front(came[path[0]])
	return path


func _choose_card() -> int:
	var best := 0
	var best_score := -1.0
	for i in mission.offer_cards.size():
		var card: Dictionary = mission.offer_cards[i]
		var score := 1.0
		match card["kind"]:
			"fusion": score = 10.0
			"online": score = 6.0
			"fork": score = 5.0 if card["fork"] == fork_preference else 4.0
			"upgrade": score = 3.0
			"field": score = 4.5 if card["field"] == "field_repair" and mission.player.armor_fraction() < 0.5 else 2.0
		score += rng.randf() * (4.0 if average else 0.5)
		if score > best_score:
			best_score = score
			best = i
	return best



## Grid pathfinding round walls and rocks (Godot's AStarGrid2D), rebuilt whenever the walls change.
## Returns the next point to walk toward on the way to the goal.
func _waypoint(goal: Vector2) -> Vector2:
	var world := mission.world
	if world.walls.is_empty():
		return goal
	var key := "%d|%s|%s" % [world.walls.size(), str(world.walls[0]), str(world.walls[world.walls.size() - 1])]
	if key != grid_key:
		grid_key = key
		var bounds := world.bounds
		grid = AStarGrid2D.new()
		grid.region = Rect2i(Vector2i(floori(bounds.position.x / CELL), floori(bounds.position.y / CELL)), Vector2i(ceili(bounds.size.x / CELL) + 1, ceili(bounds.size.y / CELL) + 1))
		grid.cell_size = Vector2(CELL, CELL)
		grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		grid.update()
		for wall: Rect2 in world.walls:
			var grown := wall.grow(20.0)
			for x in range(floori(grown.position.x / CELL), ceili(grown.end.x / CELL) + 1):
				for y in range(floori(grown.position.y / CELL), ceili(grown.end.y / CELL) + 1):
					var cell := Vector2i(x, y)
					if grid.is_in_boundsv(cell) and grown.has_point(Vector2(cell) * CELL + Vector2(CELL, CELL) * 0.5):
						grid.set_point_solid(cell, true)
		cached_path = PackedVector2Array()
	path_age += 1
	if cached_path.is_empty() or path_age > 15 or cached_goal.distance_to(goal) > 60.0:
		path_age = 0
		cached_goal = goal
		var from := _cell(mission.player.pos)
		var to := _cell(goal)
		if not grid.is_in_boundsv(from) or not grid.is_in_boundsv(to) or grid.is_point_solid(to):
			return goal
		grid.set_point_solid(from, false)
		cached_path = grid.get_point_path(from, to)
	if cached_path.size() < 2:
		return goal
	for point in cached_path:
		var center := point + Vector2(CELL, CELL) * 0.5
		if center.distance_to(mission.player.pos) > CELL * 1.2:
			return center
	return goal


func _cell(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x / CELL), floori(at.y / CELL))
