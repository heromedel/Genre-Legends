extends Node
## Autoload "Save": the single owner of persistent state. Everything else asks Save rather than
## keeping its own copy (Elegant Code Principle 11).
## On the web, user:// lives in the browser's IndexedDB for the GitHub Pages origin.
## Every write also refreshes a backup copy; loading falls back to it if the main file is damaged.

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save_backup.json"
## A mission in progress, saved every few seconds so it can be resumed after the browser closes (MissionView).
const CHECKPOINT_PATH := "user://mission_checkpoint.json"
const VERSION := 1

signal changed

var data: Dictionary = {}


func _ready() -> void:
	load_game()


func _log(category: String, text: String) -> void:
	var play_log := get_node_or_null("/root/PlayLog")
	if play_log != null:
		play_log.note(category, text)


func fresh_data() -> Dictionary:
	var tech_mk := {}
	for tech_id in TechData.STARTING_UNLOCKS:
		tech_mk[tech_id] = 1
	return {
		"version": VERSION,
		"map_seed": randi() % 1000000,
		"cleared": {},
		"blueprints": {},
		"tech_mk": tech_mk,
		"loadout": TechData.STARTING_LOADOUT.duplicate(),
		"frame": FrameData.STARTING_FRAME,
		"frames_unlocked": [FrameData.STARTING_FRAME],
		"prizes_claimed": [],
		"settings": {"music": 0.6, "sfx": 0.8, "play_log": true, "screen_shake": true, "fullscreen": true, "threat": "standard", "bullet_glow": false, "auto_aim": false, "autofire": true, "transform_spin": true, "double_tap_special": true},
		"stats": {"missions": 0, "wins": 0, "kills": 0, "play_seconds": 0.0},
		"new_unlocks": [],
		"radio_queue": [],
		"milestones": {},
		"counters": {},
		"enemies_unlocked": [],
	}


func load_game() -> void:
	var loaded := _read_json(SAVE_PATH)
	if loaded.is_empty():
		loaded = _read_json(BACKUP_PATH)
		if not loaded.is_empty():
			_log("save", "Main save missing or damaged; restored from backup.")
	data = repair(loaded)


func write() -> void:
	var text := JSON.stringify(data)
	for path in [SAVE_PATH, BACKUP_PATH]:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(text)
			file.close()
	changed.emit()


## The mission in progress: how it was launched and every input so far (InputRecording). Replaying the
## inputs through a Mission built from the same launch puts it back exactly where it was.
func write_checkpoint(checkpoint: Dictionary) -> void:
	var file := FileAccess.open(CHECKPOINT_PATH, FileAccess.WRITE)
	if file:
		# Godot's own text format, not JSON: the mission is rebuilt from it, so its numbers must keep their types.
		file.store_string(var_to_str(checkpoint))
		file.close()


## The saved mission in progress, or {} if there isn't one.
func read_checkpoint() -> Dictionary:
	if not FileAccess.file_exists(CHECKPOINT_PATH):
		return {}
	var file := FileAccess.open(CHECKPOINT_PATH, FileAccess.READ)
	var parsed = str_to_var(file.get_as_text()) if file else null
	return parsed if parsed is Dictionary else {}


## Forgets the mission in progress: it finished, was abandoned, or was resumed and is being saved anew.
func clear_checkpoint() -> void:
	if FileAccess.file_exists(CHECKPOINT_PATH):
		DirAccess.remove_absolute(CHECKPOINT_PATH)


## Makes any save, old or damaged, safe to use: missing keys get defaults, wrong types are replaced.
func repair(raw: Dictionary) -> Dictionary:
	var clean := fresh_data()
	if raw.is_empty():
		return clean
	for key in clean:
		if raw.has(key) and typeof(raw[key]) == typeof(clean[key]):
			clean[key] = raw[key]
	# Map seed arrives as a float from JSON.
	if raw.has("map_seed") and (typeof(raw["map_seed"]) == TYPE_FLOAT or typeof(raw["map_seed"]) == TYPE_INT):
		clean["map_seed"] = int(raw["map_seed"])
	# Settings and stats: merge so new keys get defaults.
	var default_settings: Dictionary = fresh_data()["settings"]
	for key in default_settings:
		if not clean["settings"].has(key) or typeof(clean["settings"][key]) != typeof(default_settings[key]):
			clean["settings"][key] = default_settings[key]
	var default_stats: Dictionary = fresh_data()["stats"]
	for key in default_stats:
		if not clean["stats"].has(key):
			clean["stats"][key] = default_stats[key]
	# Tech: drop unknown ids, clamp grades, keep the starters unlocked.
	var tech_mk := {}
	for tech_id in clean["tech_mk"]:
		if TechData.TECH.has(tech_id):
			tech_mk[tech_id] = clampi(int(clean["tech_mk"][tech_id]), 0, TechData.MAX_MK)
	for tech_id in TechData.STARTING_UNLOCKS:
		tech_mk[tech_id] = maxi(int(tech_mk.get(tech_id, 0)), 1)
	clean["tech_mk"] = tech_mk
	var blueprints := {}
	for tech_id in clean["blueprints"]:
		if TechData.TECH.has(tech_id):
			blueprints[tech_id] = maxi(int(clean["blueprints"][tech_id]), 0)
	clean["blueprints"] = blueprints
	clean["loadout"] = _repair_loadout(clean["loadout"], tech_mk)
	var frames: Array = []
	for frame_id in clean["frames_unlocked"]:
		if FrameData.FRAMES.has(frame_id) and not frames.has(frame_id):
			frames.append(frame_id)
	if not frames.has(FrameData.STARTING_FRAME):
		frames.append(FrameData.STARTING_FRAME)
	clean["frames_unlocked"] = frames
	if not frames.has(clean["frame"]):
		clean["frame"] = FrameData.STARTING_FRAME
	clean["version"] = VERSION
	return clean


func _repair_loadout(loadout: Array, tech_mk: Dictionary) -> Array:
	var result := []
	for slot_index in TechData.SLOTS.size():
		var slot: String = TechData.SLOTS[slot_index]
		var tech_id := ""
		if slot_index < loadout.size() and typeof(loadout[slot_index]) == TYPE_STRING:
			tech_id = loadout[slot_index]
		var valid: bool = TechData.TECH.has(tech_id) and TechData.TECH[tech_id]["slot"] == slot \
			and int(tech_mk.get(tech_id, 0)) > 0 and not result.has(tech_id)
		if not valid:
			tech_id = ""
		result.append(tech_id)
	if result[0] == "":
		result[0] = TechData.STARTING_LOADOUT[0]
	return result


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


# ---- Questions other systems ask

func tech_mk(tech_id: String) -> int:
	return int(data["tech_mk"].get(tech_id, 0))


func blueprints(tech_id: String) -> int:
	return int(data["blueprints"].get(tech_id, 0))


func is_cleared(node_id: String) -> bool:
	return data["cleared"].has(node_id)


func setting(key: String):
	return data["settings"].get(key)


# ---- Changes other systems request

func set_setting(key: String, value) -> void:
	data["settings"][key] = value
	write()


func add_blueprints(tech_id: String, amount: int) -> void:
	data["blueprints"][tech_id] = blueprints(tech_id) + amount


## True when there are enough blueprints to unlock this tech or raise its Mk.
func can_upgrade(tech_id: String) -> bool:
	var cost := TechData.blueprints_for_next_mk(tech_mk(tech_id))
	return cost > 0 and blueprints(tech_id) >= cost


## Spend blueprints to raise a tech's Mk. Returns true if it happened.
func upgrade_tech(tech_id: String) -> bool:
	if not can_upgrade(tech_id):
		return false
	var mk := tech_mk(tech_id)
	var cost := TechData.blueprints_for_next_mk(mk)
	data["blueprints"][tech_id] = blueprints(tech_id) - cost
	data["tech_mk"][tech_id] = mk + 1
	if mk == 0:
		mark_new(tech_id)
	_log("rnd", "%s raised to Mk %d" % [TechData.TECH[tech_id]["name"], mk + 1])
	write()
	return true


func unlock_tech(tech_id: String) -> void:
	if tech_mk(tech_id) == 0:
		data["tech_mk"][tech_id] = 1
		mark_new(tech_id)


## New unlocks show a green dot until equipped (GDD 9C).
func mark_new(tech_id: String) -> void:
	if not data["new_unlocks"].has(tech_id):
		data["new_unlocks"].append(tech_id)


func is_new(tech_id: String) -> bool:
	return data["new_unlocks"].has(tech_id)


## Radio messages wait here until the command center shows them (GDD 9E).
func queue_radio(text: String) -> void:
	if not data["radio_queue"].has(text):
		data["radio_queue"].append(text)


func equip(slot_index: int, tech_id: String) -> void:
	var loadout: Array = data["loadout"]
	# A tech can only sit in one slot; equipping it elsewhere empties the old slot.
	for i in loadout.size():
		if loadout[i] == tech_id:
			loadout[i] = ""
	loadout[slot_index] = tech_id
	data["new_unlocks"].erase(tech_id)
	data["loadout"] = _repair_loadout(loadout, data["tech_mk"])
	write()


func select_frame(frame_id: String) -> void:
	if data["frames_unlocked"].has(frame_id):
		data["frame"] = frame_id
		write()


## Applies a prize string such as "frame:tempest" or "tech:starfall". Prizes are only ever given once.
func claim_prize(prize_id: String, prize: String) -> void:
	if data["prizes_claimed"].has(prize_id):
		return
	data["prizes_claimed"].append(prize_id)
	var parts := prize.split(":")
	if parts[0] == "frame" and not data["frames_unlocked"].has(parts[1]):
		data["frames_unlocked"].append(parts[1])
	elif parts[0] == "tech":
		unlock_tech(parts[1])
	_log("prize", "Claimed %s (%s)" % [prize_id, prize])


func mark_cleared(node_id: String) -> void:
	data["cleared"][node_id] = true


func reset() -> void:
	data = fresh_data()
	write()
