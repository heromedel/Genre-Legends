class_name StarMap
extends RefCounted
## The procedurally generated, forever-expanding star map (GDD 5C, 5D).
## Built region by region from the save's map seed, so the same save always shows the same map.
## Routes fork: each planet links to one or two planets in the next column, and you choose which way to push.
## Every region ends in a gate planet that opens the next region. Themed branches split off the main
## route, lean on one genre and show their prize before you commit.
##
## The map holds no progress of its own: what's cleared lives in Save, and availability is worked out from it.

const COLUMNS_PER_REGION := 5  # plus one gate column

## Lesson planets (GDD 9C): built to beat you without one tech, which unlocks win or lose.
## Keyed by region and column ("r0c2") or a region's gate ("r0gate").
const LESSONS := {
	"r0c2": {"lesson": "needles", "tech": "mirror_aegis",
		"traits": ["Needle swarms"], "need": "Needle swarms are shredding everything that flies here."},
	"r0gate": {"lesson": "mirror", "tech": "swarm_pods", "type": "star_cluster", "boss": "mirror_dreadnought",
		"traits": ["Mirrored hull"], "need": "A mirror-hulled dreadnought holds the gate. Straight shots bounce right back."},
}
const COLUMN_SPACING := 210.0
const ROW_SPACING := 125.0

var seed_value: int
var nodes: Dictionary = {}       # id -> node Dictionary
var columns: Array = []          # global column index -> Array of node ids
var regions: Array = []          # region index -> {name, palette}
var _generated_regions := 0


func _init(map_seed: int) -> void:
	seed_value = map_seed


## Generates regions up to one beyond the furthest region reached, so the frontier always has
## somewhere visible to point at.
func ensure_generated(is_cleared: Callable) -> void:
	if _generated_regions == 0:
		_generate_region(0)
	while _region_reached(_generated_regions - 1, is_cleared):
		_generate_region(_generated_regions)


func _region_reached(region: int, is_cleared: Callable) -> bool:
	if region == 0:
		return true
	var first_column: Array = columns[region * (COLUMNS_PER_REGION + 1)]
	for node_id in first_column:
		if is_available(node_id, is_cleared):
			return true
	return false


func get_node(node_id: String) -> Dictionary:
	return nodes.get(node_id, {})


## A planet can be launched if it's the very first one, or any planet linking to it is cleared.
func is_available(node_id: String, is_cleared: Callable) -> bool:
	var node := get_node(node_id)
	if node.is_empty():
		return false
	if node["incoming"].is_empty():
		return true
	for from_id in node["incoming"]:
		if is_cleared.call(from_id):
			return true
	return false


func region_count() -> int:
	return _generated_regions


func position_of(node_id: String) -> Vector2:
	var node := get_node(node_id)
	return Vector2(node["column"] * COLUMN_SPACING, node["row"] * ROW_SPACING)


# ---- Generation

func _region_rng(region: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d/region/%d" % [seed_value, region])
	return rng


func _generate_region(region: int) -> void:
	var rng := _region_rng(region)
	var palette: Dictionary = MissionData.REGION_PALETTES[region % MissionData.REGION_PALETTES.size()]
	var region_name := "%s %s" % [_make_name(rng), MissionData.REGION_WORDS[rng.randi() % MissionData.REGION_WORDS.size()]]
	regions.append({"name": region_name, "palette": palette})
	var first_column := region * (COLUMNS_PER_REGION + 1)
	var previous_ids: Array = columns[columns.size() - 1] if not columns.is_empty() else []

	for local_column in COLUMNS_PER_REGION + 1:
		var column := first_column + local_column
		var is_gate := local_column == COLUMNS_PER_REGION
		var count := 1 if is_gate or (region == 0 and local_column == 0) else (2 + int(rng.randf() < 0.55))
		var hazard_index := rng.randi() % 3 if rng.randf() < 0.45 else -1
		var types := _types_for_column(rng, count, region, local_column)
		if is_gate and LESSONS.has("r%dgate" % region):
			types = [LESSONS["r%dgate" % region]["type"]]
		var ids := []
		for i in count:
			var row := 0.0 if count == 1 else lerpf(-1.0, 1.0, float(i) / float(count - 1)) * (0.8 + 0.25 * count * 0.5)
			row += rng.randf_range(-0.18, 0.18) if count > 1 else 0.0
			var node_id := "r%dc%dn%d" % [region, local_column, i]
			var node := _make_node(rng, node_id, region, column, local_column, row, types[i], is_gate)
			_apply_lesson(node, "r%dgate" % region if is_gate else "r%dc%d" % [region, local_column])
			if not is_gate and count == 3 and local_column >= 3 and i == hazard_index:
				_make_hazard(node)
			nodes[node_id] = node
			ids.append(node_id)
		_link_columns(rng, previous_ids, ids)
		columns.append(ids)
		previous_ids = ids
	_add_themed_branch(rng, region)
	_generated_regions = region + 1


func _types_for_column(rng: RandomNumberGenerator, count: int, region: int, local_column: int) -> Array:
	# The very first planet is a Star Cluster: the most readable genre to learn on.
	if region == 0 and local_column == 0:
		return ["star_cluster"]
	var pool: Array = MissionData.PLAYABLE_TYPES.duplicate()
	# Shuffle with the region rng so it's reproducible.
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var swap = pool[i]
		pool[i] = pool[j]
		pool[j] = swap
	var result := []
	for i in count:
		result.append(pool[i % pool.size()])
	return result


func _make_node(rng: RandomNumberGenerator, node_id: String, region: int, column: int, local_column: int,
		row: float, mission_type: String, is_gate: bool) -> Dictionary:
	var gentle := region == 0 and local_column <= 1
	var modifier := ""
	if not gentle and rng.randf() < 0.35:
		var keys := MissionData.MODIFIERS.keys()
		modifier = keys[1 + rng.randi() % (keys.size() - 1)]
	var reward_choices := []
	for tech_id in TechData.TECH:
		if TechData.TECH[tech_id]["blueprint_from"].has(mission_type):
			reward_choices.append(tech_id)
	var needs: Array = MissionData.NEEDS[mission_type]
	var prize := ""
	var prize_text := ""
	if is_gate and MissionData.GATE_PRIZES.has(region):
		prize = MissionData.GATE_PRIZES[region]
		prize_text = "Unlocks the %s frame." % FrameData.get_frame(prize.split(":")[1])["name"]
	return {
		"id": node_id,
		"name": _make_name(rng) + ("" if rng.randf() < 0.5 else " " + ["Prime", "II", "IV", "Minor", "Major"][rng.randi() % 5]),
		"region": region,
		"column": column,
		"row": row,
		"type": mission_type,
		"need": needs[rng.randi() % needs.size()] if not is_gate else "The region gate. Break through to open the next region.",
		"difficulty": 1.0 + 0.3 * region + 0.06 * local_column + (0.15 if is_gate else 0.0),
		"baseline": local_column if region == 0 else -1,
		"danger": clampi(1 + region + int(local_column >= 3) + int(is_gate), 1, 5),
		"modifier": modifier,
		"reward_tech": reward_choices[rng.randi() % reward_choices.size()],
		"is_gate": is_gate,
		"branch": "",
		"prize": prize,
		"prize_text": prize_text,
		"links": [],
		"incoming": [],
		"planet_look": rng.randi(),
		"lesson": "",
		"lesson_tech": "",
		"boss": "",
		"hazard": false,
		"reward_scale": 1.0,
	}


func _apply_lesson(node: Dictionary, key: String) -> void:
	if not LESSONS.has(key):
		return
	var lesson: Dictionary = LESSONS[key]
	node["lesson"] = lesson["lesson"]
	node["lesson_tech"] = lesson["tech"]
	node["need"] = lesson["need"]
	node["boss"] = lesson.get("boss", "")
	node["modifier"] = ""


## Hazard routes (GDD 9G): an optional planet that's much harder until your build is ready, and pays double.
func _make_hazard(node: Dictionary) -> void:
	node["hazard"] = true
	node["difficulty"] += 0.45
	node["danger"] = mini(node["danger"] + 2, 5)
	node["reward_scale"] = 2.0


## Each planet links to the nearest one or two planets in the next column; every planet gets at least one way in.
func _link_columns(rng: RandomNumberGenerator, from_ids: Array, to_ids: Array) -> void:
	if from_ids.is_empty():
		return
	for from_id in from_ids:
		var from_row: float = nodes[from_id]["row"]
		var sorted := to_ids.duplicate()
		sorted.sort_custom(func(a, b): return absf(nodes[a]["row"] - from_row) < absf(nodes[b]["row"] - from_row))
		var link_count := 1 if to_ids.size() == 1 else (1 + int(rng.randf() < 0.6))
		for i in mini(link_count, sorted.size()):
			_link(from_id, sorted[i])
	for to_id in to_ids:
		if nodes[to_id]["incoming"].is_empty():
			var to_row: float = nodes[to_id]["row"]
			var nearest: String = from_ids[0]
			for from_id in from_ids:
				if absf(nodes[from_id]["row"] - to_row) < absf(nodes[nearest]["row"] - to_row):
					nearest = from_id
			_link(nearest, to_id)


func _link(from_id: String, to_id: String) -> void:
	if not nodes[from_id]["links"].has(to_id):
		nodes[from_id]["links"].append(to_id)
		nodes[to_id]["incoming"].append(from_id)


## A themed branch rises above the main route from the region's second column.
func _add_themed_branch(rng: RandomNumberGenerator, region: int) -> void:
	for branch in MissionData.THEMED_BRANCHES:
		if branch["region"] != region:
			continue
		var start_column := region * (COLUMNS_PER_REGION + 1) + 1
		var attach_ids: Array = columns[start_column]
		var top_id: String = attach_ids[0]
		for node_id in attach_ids:
			if nodes[node_id]["row"] < nodes[top_id]["row"]:
				top_id = node_id
		var previous_id := top_id
		for k in branch["length"]:
			var node_id := "br_%s_%d" % [branch["id"], k]
			var node := _make_node(rng, node_id, region, start_column + 1 + k, 2 + k, -2.35, branch["type"], false)
			node["branch"] = branch["id"]
			node["branch_name"] = branch["name"]
			node["modifier"] = branch["modifier"]
			node["difficulty"] += 0.15
			node["danger"] = mini(node["danger"] + 1, 5)
			if k == branch["length"] - 1:
				node["prize"] = branch["prize"]
				node["prize_text"] = branch["prize_text"]
			nodes[node_id] = node
			_link(previous_id, node_id)
			previous_id = node_id


func _make_name(rng: RandomNumberGenerator) -> String:
	var start: String = MissionData.NAME_STARTS[rng.randi() % MissionData.NAME_STARTS.size()]
	var end: String = MissionData.NAME_ENDS[rng.randi() % MissionData.NAME_ENDS.size()]
	return start + end


## Planets of every column, for drawing. Themed branch planets are included.
func all_node_ids() -> Array:
	return nodes.keys()
