class_name BotPilot
extends RefCounted
## A competent bot that plays any mission type through InputFrames only, like a player would.
## Used by the QA harness (GDD 4A). It dodges bullets, chases objectives, explores dungeons room by room,
## uses its special when things get hairy, and picks level-up cards by a simple preference.
## Its aim is tracked: a bot that misses when it shouldn't is a bug (GDD 4D).

var mission: Mission
var rng := RandomNumberGenerator.new()
var fork_preference := "a"
var stuck_timer := 0.0
var last_pos := Vector2.ZERO
var wander := Vector2.ZERO
## "average" plays like an average player: notices bullets later, sometimes freezes, picks cards loosely.
var average := false


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
	var dodge := _dodge_vector()
	if player.form == "ship":
		var target_x := world.bounds.get_center().x
		var nearest := world.nearest_enemy(player.pos, 2000.0)
		if nearest != null:
			target_x = nearest.pos.x
		var desired := Vector2(target_x, world.bounds.end.y - 120.0) - player.pos
		if mission.stage is CorridorStage:
			var stage: CorridorStage = mission.stage
			var mid := (stage.left_edge(player.pos.y) + stage.right_edge(player.pos.y)) * 0.5
			desired.x = clampf(desired.x, stage.left_edge(player.pos.y) + 40.0 - player.pos.x, stage.right_edge(player.pos.y) - 40.0 - player.pos.x)
			if absf(player.pos.x - mid) > 200.0:
				desired.x = mid - player.pos.x
		var move := desired.limit_length(14.0) + dodge * 22.0
		frame.drag = move.limit_length(26.0)
	else:
		var goal := _ground_goal()
		var to_goal := goal - player.pos
		var direction := to_goal.normalized() if to_goal.length() > 30.0 else Vector2.ZERO
		var nearest := world.nearest_enemy(player.pos, 400.0)
		if nearest != null and nearest.pos.distance_to(player.pos) < 170.0:
			direction += (player.pos - nearest.pos).normalized() * 0.8
		var boss := mission.stage.active_boss()
		if boss != null and not boss.defeated and boss.origin.distance_to(player.pos) < 300.0:
			direction += (player.pos - boss.origin).normalized() * 1.5
		direction += dodge * 1.6
		direction = _avoid_walls(direction)
		if player.pos.distance_to(last_pos) < 1.0 and direction.length() > 0.2:
			stuck_timer += World.DT
		else:
			stuck_timer = 0.0
		last_pos = player.pos
		if stuck_timer > 0.6:
			wander = Vector2.from_angle(rng.randf() * TAU)
			stuck_timer = 0.0
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


func _dodge_vector() -> Vector2:
	var player := mission.player
	var push := Vector2.ZERO
	var notice := 150.0
	if average:
		# Average players react late and now and then don't react at all.
		notice = 85.0
		if int(mission.tick / 20) % 4 == 0:
			return Vector2.ZERO
	for shot: Shot in mission.world.enemy_shots:
		var offset := player.pos - shot.pos
		var distance := offset.length()
		if distance > notice or distance < 0.01:
			continue
		var heading := shot.vel.normalized()
		var closing := -offset.normalized().dot(heading)
		if closing < -0.2:
			continue
		var side := offset - heading * offset.dot(heading)
		if side.length() < 0.01:
			side = heading.orthogonal()
		push += side.normalized() * (150.0 - distance) / 150.0
	for zone: Zone in mission.world.zones:
		if zone.hostile and zone.kind != "laser" and player.pos.distance_to(zone.pos) < zone.radius + 30.0:
			push += (player.pos - zone.pos).normalized()
	return push.limit_length(1.0)


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
	# Something in the way (a block in the middle of the room)? Detour round the side first.
	if not _clear_line(player.pos, goal):
		var side := Vector2(DungeonStage.DIRECTIONS[direction]).orthogonal()
		for detour in [player.pos + side * 260.0, player.pos - side * 260.0, rect.get_center() + side * 300.0, rect.get_center() - side * 300.0]:
			if not mission.world.point_in_wall(detour) and _clear_line(player.pos, detour):
				return detour
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
