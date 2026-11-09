class_name PlanetStage
extends Stage
## Planet Exploration (GDD 6C): a big open surface to roam, bullet-hell style. Hive nests sit in camps
## guarded by the local wildlife; packs roam between them. Wreck every nest and the Siege Crawler lands.
## Rock spires give cover. Repair cells and wreckage crates are scattered for those who explore.

const WORLD_SIZE := Vector2(3400, 3400)
const MAX_ROAMERS := 26

var camps: Array = []           # {pos, nest_id}
var rocks: Array = []           # Rect2 cover; also the art's rock list
var roam_timer := 1.5
var objective_ids: Array = []
var roster: Dictionary
var fissure_open := false        # chained missions: the way down into the next stage
var fissure_pos := Vector2.ZERO
var dived := false


func stage_name() -> String:
	return "Planet Surface"


func setup() -> void:
	form = "mech"
	camera_mode = "follow"
	world.bounds = Rect2(Vector2.ZERO, WORLD_SIZE)
	world.shot_bounds = world.bounds.grow(200)
	var start := WORLD_SIZE * 0.5 + Vector2(0, 1150)
	mission.player.pos = start
	roster = EnemyData.ROSTERS["planet"].duplicate()
	var need: String = mission.node.get("need", "")
	if need.find("burrowed") >= 0:
		roster["burrower"] = 8
	elif need.find("war machine") >= 0:
		roster["brute"] = 5
	if mission.node.get("arrivals", []).has("centi_mech"):
		roster["centi_mech"] = 3
	_place_camps(start)
	_place_rocks(start)
	_place_loot()


func _place_camps(start: Vector2) -> void:
	# A breakout from below lands on a shorter surface run: two nests, then the boss.
	var camp_count := 2 if short_stage else 4
	for i in camp_count:
		var angle := -PI * 0.5 + (i - 1.5) * 1.05 + world.rng.randf_range(-0.2, 0.2)
		var at := WORLD_SIZE * 0.5 + Vector2.from_angle(angle) * world.rng.randf_range(1050.0, 1350.0)
		at = at.clamp(Vector2(300, 300), WORLD_SIZE - Vector2(300, 300))
		if at.distance_to(start) < 700.0:
			at = WORLD_SIZE * 0.5 + Vector2.from_angle(angle) * 1250.0
		var nest := world.spawn_enemy("hive_nest", at)
		objective_ids.append(nest.id)
		camps.append({"pos": at, "nest_id": nest.id})
		for j in 3:
			var guard_kind := "sentry" if j == 0 else "spitter"
			world.spawn_enemy(guard_kind, at + Vector2.from_angle(TAU * j / 3.0 + 0.4) * 150.0)
		for j in 4:
			world.spawn_enemy("crawler", at + Vector2.from_angle(world.rng.randf() * TAU) * 110.0)
	# One camp has a Warlord: the elite that guards the best loot.
	var warlord_camp: Dictionary = camps[world.rng.randi() % camps.size()]
	world.spawn_enemy("warlord", warlord_camp["pos"] + Vector2(0, -180))


func _place_rocks(start: Vector2) -> void:
	var tries := 0
	while rocks.size() < 22 and tries < 200:
		tries += 1
		var size := Vector2(world.rng.randf_range(60, 150), world.rng.randf_range(60, 140))
		var at := Vector2(world.rng.randf_range(150, WORLD_SIZE.x - 300), world.rng.randf_range(150, WORLD_SIZE.y - 300))
		var rect := Rect2(at, size)
		var clear := rect.grow(160).has_point(start) == false
		for camp in camps:
			if rect.grow(200).has_point(camp["pos"]):
				clear = false
		if clear:
			rocks.append(rect)
	world.walls = rocks.duplicate()


func _place_loot() -> void:
	for i in 3:
		var repair := world.drop_pickup("repair", Vector2(world.rng.randf_range(300, WORLD_SIZE.x - 300), world.rng.randf_range(300, WORLD_SIZE.y - 300)))
		repair.vel = Vector2.ZERO
		repair.anchored = true
	for i in 1:
		var crate := world.drop_pickup("crate", Vector2(world.rng.randf_range(300, WORLD_SIZE.x - 300), world.rng.randf_range(300, WORLD_SIZE.y - 300)))
		crate.vel = Vector2.ZERO
		crate.anchored = true
	for pickup: Pickup in world.pickups:
		pickup.pos = world.push_out_of_walls(pickup.pos, 20.0)


func step(dt: float) -> void:
	update_miniboss(dt)
	if boss != null:
		boss.update(dt)
	if mission.state != "play":
		return
	roam_timer -= dt
	if roam_timer <= 0.0 and boss == null:
		roam_timer = world.rng.randf_range(4.0, 6.5) / world.spawn_scale
		_spawn_roaming_pack()
	if miniboss == null and objectives_left() <= 2 and not short_stage:
		start_miniboss(BossRoster.make(BossRoster.for_node(mission.node, "miniboss"), world))
	# Chained: the last nest cracks the ground open, and the way on is down (GDD 6G).
	if has_next_stage() and objectives_left() == 0 and not miniboss_active():
		if not fissure_open:
			fissure_open = true
			fissure_pos = (mission.player.pos + Vector2(0, -320)).clamp(Vector2(300, 300), WORLD_SIZE - Vector2(300, 300))
			world.emit("banner", {"text": "A FISSURE HAS OPENED", "style": "gold"})
			world.emit("shake", {"amount": 14.0})
			world.emit("burst_ground", {"pos": fissure_pos})
			mission.note("Fissure opened")
		elif mission.player.pos.distance_to(fissure_pos) < 70.0:
			dived = true
		return
	if boss == null and objectives_left() == 0 and not miniboss_active():
		mission.note("All hive nests destroyed")
		start_boss(BossRoster.make(BossRoster.for_node(mission.node, "boss"), world))


func _spawn_roaming_pack() -> void:
	if world.enemies.size() > MAX_ROAMERS:
		return
	var angle := world.rng.randf() * TAU
	var at := (mission.player.pos + Vector2.from_angle(angle) * world.rng.randf_range(720.0, 900.0)).clamp(Vector2(60, 60), WORLD_SIZE - Vector2(60, 60))
	var kind := pick_from_roster(roster)
	if kind == "centi_mech":
		_spawn_centi_mech(at)
		return
	var count := 1 if kind == "brute" else world.rng.randi_range(3, 5)
	for i in count:
		var enemy := world.spawn_enemy(kind, at + Vector2(world.rng.randf_range(-60, 60), world.rng.randf_range(-60, 60)))
		enemy.pos = world.push_out_of_walls(enemy.pos, enemy.radius)
		enemy.memory["awake"] = true


func debug_skip_to_boss() -> void:
	for nest_id in objective_ids:
		var nest := world.enemy_by_id(nest_id)
		if nest != null:
			nest.dead = true


func debug_skip_to_miniboss() -> void:
	for i in 2:
		var nest := world.enemy_by_id(objective_ids[i])
		if nest != null:
			nest.dead = true


func stage_progress() -> float:
	return 1.0 - float(objectives_left()) / float(maxi(objective_ids.size(), 1))


func _spawn_centi_mech(at: Vector2) -> void:
	var leader := world.spawn_enemy("centi_mech", at)
	leader.memory["awake"] = true
	for i in 7:
		var segment := world.spawn_enemy("centi_segment", at - Vector2(20.0 * (i + 1), 0))
		segment.memory["leader"] = leader.id
		segment.memory["awake"] = true
		leader = segment


func objectives_left() -> int:
	var left := 0
	for nest_id in objective_ids:
		if world.enemy_by_id(nest_id) != null:
			left += 1
	return left


## Where the HUD's arrows point: living nests, or the boss.
func is_cleared() -> bool:
	return dived or (boss != null and boss.finished)


func objective_positions() -> Array:
	if fissure_open:
		return [fissure_pos]
	if boss != null and not boss.defeated:
		return [boss.origin]
	if miniboss_active():
		return [miniboss.origin]
	var positions := []
	for nest_id in objective_ids:
		var nest := world.enemy_by_id(nest_id)
		if nest != null:
			positions.append(nest.pos)
	return positions


func objective_text() -> String:
	if boss != null:
		return "Destroy the %s" % boss.boss_name
	if miniboss_active():
		return "Destroy the %s" % miniboss.boss_name
	if fissure_open:
		return "Dive into the fissure"
	return "Hive nests: %d left" % objectives_left()
