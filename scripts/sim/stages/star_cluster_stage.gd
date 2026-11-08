class_name StarClusterStage
extends Stage
## Star Cluster (GDD 6A): a formation shooter. Waves fly in along curves, settle into formation and
## peel off to dive at you. A Supply Barge crosses once: kill it before it leaves or lose its crate.
## After the last wave: WARNING, and the Hive Carrier.

const FIELD := Rect2(0, 0, 1200, 800)
const WAVE_TIMEOUT := 20.0

var spawn_queue: Array = []         # {time, kind, pos, memory, overrides}
var wave_plan: Array = []
var wave_index := -1
var wave_started_at := 0.0
var barge_sent := false
var scroll := 0.0                   # background scroll, for the art


func stage_name() -> String:
	return "Star Cluster"


func setup() -> void:
	form = "ship"
	camera_mode = "fixed"
	world.bounds = FIELD
	world.shot_bounds = FIELD.grow(120)
	mission.player.pos = Vector2(FIELD.get_center().x, FIELD.end.y - 110)
	wave_plan = ["formation", "wasps", "formation_splitters", "bulwarks", "minelayers", "formation", "formation_ace", "wasps", "bulwarks", "finale"]
	if world.gentle:
		wave_plan = ["formation", "wasps", "formation_splitters", "formation", "minelayers", "wasps", "formation_ace", "finale"]


func step(dt: float) -> void:
	scroll += dt * (60.0 if boss == null else 30.0)
	_release_queue()
	if boss != null:
		boss.update(dt)
		return
	if mission.state != "play":
		return
	var alive := world.enemies.filter(func(e): return e.brain != "barge").size()
	var wave_done := spawn_queue.is_empty() and (alive <= 2 or world.time - wave_started_at > WAVE_TIMEOUT)
	if wave_index < 0 or wave_done:
		if wave_index + 1 < wave_plan.size():
			wave_index += 1
			wave_started_at = world.time
			_start_wave(wave_plan[wave_index])
		elif alive == 0 and spawn_queue.is_empty():
			start_boss(MirrorDreadnought.new(world) if mission.node.get("boss", "") == "mirror_dreadnought" else HiveCarrier.new(world))
	if not barge_sent and wave_index == 2:
		barge_sent = true
		var from_left := world.rng.randf() < 0.5
		var start := Vector2(-60 if from_left else FIELD.end.x + 60, 90)
		_queue(1.5, "supply_barge", start, {"direction": 1.0 if from_left else -1.0})


func debug_skip_to_boss() -> void:
	spawn_queue.clear()
	for enemy: Enemy in world.enemies:
		enemy.dead = true
	wave_index = wave_plan.size() - 1


func is_cleared() -> bool:
	return boss != null and boss.finished


func objective_text() -> String:
	if boss != null:
		return "Destroy the %s" % boss.boss_name
	return "Wave %d / %d" % [maxi(wave_index + 1, 1), wave_plan.size()]


func _queue(delay: float, kind: String, at: Vector2, memory: Dictionary = {}) -> void:
	spawn_queue.append({"time": world.time + delay, "kind": kind, "pos": at, "memory": memory})


func _release_queue() -> void:
	var remaining := []
	for entry in spawn_queue:
		if world.time >= entry["time"]:
			var enemy := world.spawn_enemy(entry["kind"], entry["pos"])
			for key in entry["memory"]:
				enemy.memory[key] = entry["memory"][key]
		else:
			remaining.append(entry)
	spawn_queue = remaining


func _start_wave(wave: String) -> void:
	mission.note("Wave %d: %s" % [wave_index + 1, wave])
	world.emit("wave", {"index": wave_index + 1, "total": wave_plan.size()})
	var density := world.spawn_scale
	match wave:
		"formation":
			_formation(2, 7, "dart", density)
		"wasps":
			for i in int(6 * density):
				_queue(i * 0.6, "wasp", Vector2(world.rng.randf_range(200, 1000), -30))
			_formation(1, 6, "dart", density)
		"formation_splitters":
			_formation(2, 6, "dart", density)
			_queue(2.0, "splitter", Vector2(350, -40))
			_queue(2.6, "splitter", Vector2(850, -40))
		"bulwarks":
			for i in 3:
				_queue(i * 0.9, "bulwark_wing", Vector2(300 + i * 300, -40))
			_formation(1, 8, "dart", density)
		"minelayers":
			_queue(0.0, "minelayer", Vector2(-50, 200), {"direction": 1.0})
			_queue(1.5, "minelayer", Vector2(FIELD.end.x + 50, 300), {"direction": -1.0})
			for i in int(4 * density):
				_queue(2.0 + i * 0.8, "wasp", Vector2(world.rng.randf_range(200, 1000), -30))
		"formation_ace":
			_formation(2, 7, "dart", density)
			_queue(3.0, "ace", Vector2(FIELD.get_center().x, -60))
			world.emit("banner", {"text": "ACE INBOUND", "style": "red"})
		"finale":
			_formation(3, 8, "dart", density)
			_queue(2.0, "splitter", Vector2(250, -40))
			_queue(2.0, "splitter", Vector2(950, -40))
			_queue(4.0, "bulwark_wing", Vector2(600, -40))


## A Galaga-style formation: fighters fly in on curves from both top corners into a grid of slots.
func _formation(rows: int, columns: int, kind: String, density: float) -> void:
	var count := 0
	var columns_scaled := clampi(int(columns * density), 3, 12)
	var width := (columns_scaled - 1) * 92.0
	for row in rows:
		for column in columns_scaled:
			var slot := Vector2(FIELD.get_center().x - width * 0.5 + column * 92.0, 110 + row * 62.0)
			var from_left := (column + row) % 2 == 0
			var start := Vector2(-40 if from_left else FIELD.end.x + 40, 380 + row * 30)
			var control := Vector2(FIELD.get_center().x + (-260 if from_left else 260), -120)
			_queue(count * 0.11, kind, start, {"slot": slot, "start": start, "control": control})
			count += 1
