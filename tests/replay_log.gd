extends SceneTree
## Replays the mission at the end of a play log heromedel sent (GDD 4C): rebuilds the mission from the
## log's REPLAY line, feeds it the recorded input, and prints what happened, tick for tick, with the
## log's own once-a-second snapshots beside the replay's so any drift shows.
## Run:  godot --headless -s tests/replay_log.gd -- path/to/genre-legends-log.txt [--every N]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: godot --headless -s tests/replay_log.gd -- <log file> [--every seconds]")
		quit(2)
		return
	var every := 5
	if args.has("--every"):
		every = int(args[args.find("--every") + 1])
	var text := FileAccess.get_file_as_string(args[0])
	var replay_line := ""
	var snapshots := {}
	for line in text.split("\n"):
		if line.begins_with("REPLAY "):
			replay_line = line.trim_prefix("REPLAY ")
		elif line.begins_with("t=") and line.contains("s pos="):
			snapshots[int(line.get_slice("s", 0).trim_prefix("t="))] = line
	if replay_line == "":
		print("No REPLAY line in that log.")
		quit(1)
		return
	var replay: Dictionary = JSON.parse_string(replay_line)
	var mk: Dictionary = replay["mk"]
	var mission := Mission.new(replay["node"], int(replay["seed"]), replay["frame"], replay["loadout"],
		func(tech_id): return int(mk.get(tech_id, 1)))
	var frames := InputFrame.decode_runs(replay["inputs"])
	print("Replaying %s on build %s: %d ticks of input (%s)" % [replay["node"]["type"], replay["build"], frames.size(), str(replay.get("result", {}))])
	var drift := 0
	for frame in frames:
		mission.step(frame)
		for event in mission.drain_events():
			if event["type"] in ["player_hit", "boss_warning", "boss_defeated", "level_up", "stage_start", "crate_opened"]:
				print("  %6.2fs %s %s" % [mission.world.time, event["type"], _short(event)])
		if mission.tick % 60 == 0:
			var second := mission.tick / 60
			var mine := "t=%ds pos=(%d,%d) armor=%d" % [second, mission.player.pos.x, mission.player.pos.y, mission.player.armor]
			if snapshots.has(second) and not snapshots[second].begins_with(mine):
				drift += 1
				if drift <= 3:
					print("  DRIFT at %ds:\n    log:    %s\n    replay: %s" % [second, snapshots[second], mine])
			if second % every == 0:
				print("  %s  enemies %d bullets %d level %d state %s" % [mine, mission.world.enemies.size(), mission.world.enemy_shots.size(), mission.run.level, mission.state])
	print("Replay ended: state %s at %.1fs, level %d, kills %d, damage taken %d. %s" % [
		mission.state, mission.world.time, mission.run.level, mission.run.kills, mission.run.damage_taken,
		"No drift." if drift == 0 else "%d snapshot(s) drifted (log likely from a different build)." % drift])
	quit(0)


func _short(event: Dictionary) -> String:
	var parts := []
	for key in event:
		if key != "type" and typeof(event[key]) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT]:
			parts.append("%s=%s" % [key, str(event[key])])
	return " ".join(parts)
