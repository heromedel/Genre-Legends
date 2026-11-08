extends Node
## Autoload "PlayLog": the play log (GDD 4C). When heromedel sends it, it should be as good as watching
## him play: every screen visited, every button tapped, taps that hit nothing, every mission's choices,
## hits and outcome, a once-a-second snapshot, and the full input recording so the mission can be
## replayed exactly with tests/replay_log.gd.
##
## Hints such as "possibly stuck" and "possibly panicking" are hints, never verdicts (GDD 4D):
## a player missing a lot may just be messing around.
## On by default; Settings has the off switch. Problems with the game itself are always recorded.

const MAX_LINES := 6000
const IDLE_HINT_SECONDS := 25.0
const BUILD := "0.1.0"

var lines: Array = []
var screen := "boot"
var _last_input_msec := 0
var _idle_hinted := false
var _start_msec := 0

# Mission recording
var recording := false
var record: Dictionary = {}
var last_record: Dictionary = {}
var _input_runs: Array = []        # [encoded input, repeat count]
var _reversals: Array = []         # times the move stick flipped direction, for panic hints
var _last_move := Vector2.ZERO
var _hit_times: Array = []
var _panic_hinted_at := -100.0
var _stuck_anchor := Vector2.ZERO
var _stuck_since := 0.0
var _stuck_hinted := false


func _ready() -> void:
	_start_msec = Time.get_ticks_msec()
	_last_input_msec = _start_msec
	process_mode = Node.PROCESS_MODE_ALWAYS
	note("boot", "Genre Legends %s on %s, screen %s" % [BUILD, OS.get_name(), str(DisplayServer.screen_get_size())])


func enabled() -> bool:
	var save := get_node_or_null("/root/Save")
	if save == null or save.data.is_empty():
		return true
	return bool(save.setting("play_log"))


func clock() -> String:
	var seconds := (Time.get_ticks_msec() - _start_msec) / 1000
	return "%02d:%02d:%02d" % [seconds / 3600, (seconds / 60) % 60, seconds % 60]


## Adds a timeline line. Problems ("problem") are recorded even with the play log off.
func note(category: String, text: String) -> void:
	if category != "problem" and not enabled():
		return
	lines.append("%s  %-8s %s" % [clock(), category, text])
	if lines.size() > MAX_LINES:
		lines = lines.slice(lines.size() - MAX_LINES)
	if OS.is_debug_build():
		print("[log] %s %s" % [category, text])


func set_screen(screen_name: String) -> void:
	screen = screen_name
	note("screen", screen_name)


func button(label: String) -> void:
	_last_input_msec = Time.get_ticks_msec()
	_idle_hinted = false
	note("tap", "%s  (on %s)" % [label, screen])


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton or event is InputEventKey or event is InputEventJoypadButton:
		if event.is_pressed():
			_last_input_msec = Time.get_ticks_msec()
			_idle_hinted = false


## Taps the menus didn't use: a sign the player expected something to be tappable.
func _unhandled_input(event: InputEvent) -> void:
	if screen.begins_with("mission"):
		return
	if event is InputEventScreenTouch and event.pressed:
		note("tap", "tapped nothing at (%d, %d) on %s" % [event.position.x, event.position.y, screen])
	elif event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION:
		note("tap", "clicked nothing at (%d, %d) on %s" % [event.position.x, event.position.y, screen])


func _process(_delta: float) -> void:
	if recording or _idle_hinted:
		return
	var idle := (Time.get_ticks_msec() - _last_input_msec) / 1000.0
	if idle > IDLE_HINT_SECONDS and screen != "title":
		_idle_hinted = true
		note("hint", "possibly stuck or away: no input for %d s on %s" % [int(idle), screen])


# ---------------------------------------------------------------- missions

func begin_mission(mission: Mission, loadout: Array, mk: Dictionary) -> void:
	recording = true
	_input_runs = []
	_reversals = []
	_hit_times = []
	_stuck_since = 0.0
	_stuck_hinted = false
	_stuck_anchor = mission.player.pos
	record = {
		"build": BUILD,
		"seed": mission.seed_value,
		"node": mission.node.duplicate(true),
		"frame": mission.run.frame_id,
		"loadout": loadout.duplicate(),
		"mk": mk.duplicate(),
		"snapshots": [],
	}
	var node := mission.node
	note("mission", "Launched %s \"%s\" (danger %d, %s) with %s; loadout %s" % [
		MissionData.TYPES[node["type"]]["name"], node["name"], node["danger"],
		node["modifier"] if node["modifier"] != "" else "no special condition",
		mission.run.frame_id, ", ".join(loadout.filter(func(t): return t != ""))])


func record_input(frame: InputFrame) -> void:
	if not recording:
		return
	var encoded := frame.encode()
	if not _input_runs.is_empty() and _input_runs[_input_runs.size() - 1][0] == encoded:
		_input_runs[_input_runs.size() - 1][1] += 1
	else:
		_input_runs.append([encoded, 1])


## Called once per tick after the mission steps: snapshots, hit tracking and hints.
func observe(mission: Mission, frame: InputFrame, events: Array) -> void:
	if not recording:
		return
	var time := mission.world.time
	var player := mission.player
	for event in events:
		match event["type"]:
			"player_hit":
				_hit_times.append(time)
				note("hit", "took %d from %s (armor %d/%d, shield %d)" % [
					event["amount"], event["source"], player.armor, player.max_armor, player.shield])
			"boss_warning":
				note("mission", "Boss: %s" % event["name"])
			"boss_defeated":
				note("mission", "Boss defeated: %s" % event["name"])
			"escaped":
				note("mission", "%s escaped" % event["name"])
			"special_used":
				note("input", "used special %s" % event["tech"])
			"room_entered":
				note("mission", "entered %s room %s" % [event["kind"], str(event["room"])])
	if mission.tick % 60 == 0:
		var snapshot := "t=%ds pos=(%d,%d) armor=%d shield=%d lvl=%d enemies=%d bullets=%d state=%s" % [
			mission.tick / 60, player.pos.x, player.pos.y, player.armor, player.shield, mission.run.level,
			mission.world.enemies.size(), mission.world.enemy_shots.size(), mission.state]
		record["snapshots"].append(snapshot)
	_watch_for_panic(time, frame, player)
	_watch_for_stuck(mission, time)


func _watch_for_panic(time: float, frame: InputFrame, player: PlayerFrame) -> void:
	var move := frame.move if frame.move != Vector2.ZERO else frame.drag.normalized()
	if move.length() > 0.5 and _last_move.length() > 0.5 and move.dot(_last_move) < -0.3:
		_reversals.append(time)
	if move.length() > 0.5:
		_last_move = move
	_reversals = _reversals.filter(func(t): return time - t < 1.5)
	_hit_times = _hit_times.filter(func(t): return time - t < 3.0)
	if time - _panic_hinted_at < 8.0:
		return
	# Hints only: a player flipping direction or eating hits may just be playing loose (GDD 4D).
	var hurting := player.armor_fraction() < 0.6
	if hurting and (_reversals.size() >= 6 or _hit_times.size() >= 3):
		_panic_hinted_at = time
		note("hint", "possibly panicking at %ds: %d direction flips, %d hits in the last few seconds, armor %d%%" % [
			int(time), _reversals.size(), _hit_times.size(), int(player.armor_fraction() * 100)])


func _watch_for_stuck(mission: Mission, time: float) -> void:
	if mission.player.form != "mech" or mission.state != "play":
		return
	if mission.player.pos.distance_to(_stuck_anchor) > 200.0:
		_stuck_anchor = mission.player.pos
		_stuck_since = time
		_stuck_hinted = false
	elif not _stuck_hinted and time - _stuck_since > 30.0:
		_stuck_hinted = true
		note("hint", "possibly stuck at %ds: hasn't moved far in 30 s (objective: %s)" % [int(time), mission.stage.objective_text()])


func record_choice(card: Dictionary, offered: Array) -> void:
	var titles := []
	for c in offered:
		titles.append(c["title"])
	note("choice", "picked \"%s\" from [%s]" % [card["title"], ", ".join(titles)])


func end_mission(mission: Mission, result: Dictionary) -> void:
	if not recording:
		return
	recording = false
	for line in mission.log_lines:
		record["snapshots"].append("note " + line)
	note("mission", "%s after %ds: level %d, %d kills, took %d damage over %d hits, %d crates, %d shards missed, forks %s" % [
		"WON" if result["won"] else "LOST", int(result["seconds"]), result["level"], result["kills"],
		int(result["damage_taken"]), result["hits_taken"], result["crates"], result["shards_missed"], str(result["forks"])])
	record["result"] = {"won": result["won"], "seconds": result["seconds"], "ticks": mission.tick}
	record["inputs"] = _encode_runs()
	last_record = record


func abandon_mission(mission: Mission) -> void:
	if recording:
		note("mission", "Abandoned at %ds" % int(mission.world.time))
		record["result"] = {"won": false, "seconds": mission.world.time, "ticks": mission.tick, "abandoned": true}
		record["inputs"] = _encode_runs()
		last_record = record
		recording = false


func _encode_runs() -> String:
	var parts := []
	for run in _input_runs:
		parts.append(run[0] if run[1] == 1 else "%s*%d" % [run[0], run[1]])
	return ";".join(parts)


# ---------------------------------------------------------------- export

func export_text() -> String:
	var out := []
	out.append("GENRE LEGENDS PLAY LOG")
	out.append("build %s, %s, exported %s" % [BUILD, OS.get_name(), Time.get_datetime_string_from_system()])
	var save := get_node_or_null("/root/Save")
	if save != null:
		var data: Dictionary = save.data
		out.append("frame %s, loadout %s, planets cleared %d" % [data["frame"], str(data["loadout"]), data["cleared"].size()])
		out.append("tech Mk %s" % JSON.stringify(data["tech_mk"]))
		out.append("blueprints %s" % JSON.stringify(data["blueprints"]))
	out.append("")
	out.append("== TIMELINE ==")
	out.append_array(lines)
	if not last_record.is_empty():
		out.append("")
		out.append("== LAST MISSION SNAPSHOTS ==")
		out.append_array(last_record.get("snapshots", []))
		out.append("")
		out.append("== REPLAY (for tests/replay_log.gd) ==")
		var replay := last_record.duplicate()
		replay.erase("snapshots")
		out.append("REPLAY " + JSON.stringify(replay))
	return "\n".join(out)


## Saves the log as a file: on iPad this goes to the Files app / Downloads, ready to send.
func save_file() -> String:
	var text := export_text()
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	var file_name := "genre-legends-log-%s.txt" % stamp
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), file_name, "text/plain")
		return file_name
	var path := "user://" + file_name
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(text)
		file.close()
	return ProjectSettings.globalize_path(path)
