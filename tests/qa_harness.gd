extends SceneTree
## QA harness (GDD 4A): bots play every mission type at several progress levels, headless and fast,
## and report crashes, softlocks, NaNs, runaway entity counts, pacing, balance and bot accuracy.
##
## Run:  godot --headless -s tests/qa_harness.gd -- [type|all] [runs] [progress|all]
## Progress levels: fresh (starter kit, Mk 1), mid (more tech, Mk 2), max (everything, Mk 3).

const MAX_MINUTES := 9.0
const PROGRESS := ["fresh", "mid", "max"]

var failures := 0


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var type_filter := args[0] if args.size() > 0 else "all"
	var runs := int(args[1]) if args.size() > 1 else 1
	var progress_filter := args[2] if args.size() > 2 else "all"
	var types := MissionData.PLAYABLE_TYPES if type_filter == "all" else [type_filter]
	var levels := PROGRESS if progress_filter == "all" else [progress_filter]
	print("QA harness: types=%s runs=%d progress=%s" % [str(types), runs, str(levels)])
	for mission_type in types:
		for progress in levels:
			for run_index in runs:
				_run_one(mission_type, progress, run_index)
	print("QA done: %d problem(s)" % failures)
	quit(1 if failures > 0 else 0)


func _loadout_for(progress: String, run_index: int) -> Dictionary:
	var mk := {}
	var loadout: Array = TechData.STARTING_LOADOUT.duplicate()
	match progress:
		"fresh":
			for tech_id in TechData.STARTING_UNLOCKS:
				mk[tech_id] = 1
		"mid", "max":
			for tech_id in TechData.TECH:
				mk[tech_id] = 2 if progress == "mid" else 3
			var mains := ["pulse_driver", "thunder_lance", "hex_repeater"]
			var weapons := ["arc_blade", "swarm_pods", "orbital_halo", "starfall"]
			var supports := ["mirror_aegis", "graze_engine", "overheat_core", "option_pods", "soul_lantern"]
			var specials := ["nova_bomb", "time_brake", "ion_cannon", "thruster_explosion"]
			loadout = [mains[run_index % 3], weapons[run_index % 4], weapons[(run_index + 1) % 4],
				supports[(run_index + (3 if progress == "max" else 0)) % 5], specials[(run_index + (2 if progress == "max" else 0)) % 4]]
	return {"mk": mk, "loadout": loadout}


func _node_for(mission_type: String, progress: String, run_index: int) -> Dictionary:
	var region: int = {"fresh": 0, "mid": 1, "max": 3}[progress]
	return {
		"id": "qa_%s_%s_%d" % [mission_type, progress, run_index], "name": "QA", "region": region, "column": 1,
		"row": 0.0, "type": mission_type, "need": MissionData.NEEDS[mission_type][run_index % 3],
		"difficulty": 1.0 + 0.3 * region + 0.06 * (run_index % 4), "danger": region + 1,
		"modifier": ["", "ion_storm", "swarm_season", "derelict_field", "bounty_hunters", "blackout"][run_index % 6] if progress != "fresh" else "",
		"reward_tech": "arc_blade", "is_gate": false, "branch": "", "prize": "", "prize_text": "",
		"links": [], "incoming": [], "planet_look": 0,
	}


func _run_one(mission_type: String, progress: String, run_index: int) -> void:
	var kit := _loadout_for(progress, run_index)
	var node := _node_for(mission_type, progress, run_index)
	var frames := ["vanguard", "tempest", "bulwark"]
	var frame: String = frames[run_index % 3] if progress != "fresh" else "vanguard"
	var mk_lookup := func(tech_id): return int(kit["mk"].get(tech_id, 1))
	var mission := Mission.new(node, 1000 + run_index * 77, frame, kit["loadout"], mk_lookup)
	var bot := BotPilot.new(mission, run_index, "a" if run_index % 2 == 0 else "b")
	var start_msec := Time.get_ticks_msec()
	var max_ticks := int(MAX_MINUTES * 60.0 * 60.0)
	var peak_enemies := 0
	var peak_bullets := 0
	var problems := []
	var boss_seen := false
	var offers := 0
	var shots_fired := 0
	var shots_hit := 0
	var last_progress_tick := 0
	var last_objective := ""
	var known_shots := {}
	while not mission.is_finished() and mission.tick < max_ticks:
		var before := mission.world.player_shots.duplicate()
		if mission.state == "offer":
			offers += 1
		mission.step(bot.next_input())
		for event in mission.drain_events():
			if event["type"] == "boss_warning":
				boss_seen = true
		# Accuracy: of main-weapon shots that ended, how many hit something.
		for shot in before:
			if shot.dead and shot.tech == mission.run.main_weapon() and not known_shots.has(shot):
				known_shots[shot] = true
				shots_fired += 1
				if not shot.hit_ids.is_empty():
					shots_hit += 1
		if known_shots.size() > 4000:
			known_shots.clear()
		peak_enemies = maxi(peak_enemies, mission.world.enemies.size())
		peak_bullets = maxi(peak_bullets, mission.world.enemy_shots.size())
		var player := mission.player
		if is_nan(player.pos.x) or is_nan(player.pos.y) or is_nan(player.armor):
			problems.append("NaN in player state at tick %d" % mission.tick)
			break
		if peak_enemies > 220 or peak_bullets > 1600:
			problems.append("runaway entities: %d enemies, %d bullets" % [peak_enemies, peak_bullets])
			break
		var objective := mission.stage.objective_text()
		if objective != last_objective:
			last_objective = objective
			last_progress_tick = mission.tick
		elif mission.tick - last_progress_tick > 60 * 150 and mission.state == "play":
			problems.append("no progress for 150 s (objective: %s)" % objective)
			break
	if not mission.is_finished() and problems.is_empty():
		problems.append("softlock: not finished after %.0f minutes (state %s, objective %s)" % [MAX_MINUTES, mission.state, mission.stage.objective_text()])
	var result := mission.results(true)
	var seconds_real := (Time.get_ticks_msec() - start_msec) / 1000.0
	var accuracy := float(shots_hit) / maxf(shots_fired, 1.0)
	if accuracy < 0.04 and shots_fired > 200:
		problems.append("bot accuracy only %d%%: shots aren't reaching enemies" % int(accuracy * 100))
	print("%-12s %-5s #%d %-4s %5.0fs lvl %2d kills %3d hits %3d dmg %4.0f crates %d missed %3d boss %s acc %2d%% peak %3d/%4d  forks %s fusions %s  (%.1fs real)" % [
		mission_type, progress, run_index, "WON" if result["won"] else "LOST", result["seconds"], result["level"],
		result["kills"], result["hits_taken"], result["damage_taken"], result["crates"], result["shards_missed"],
		"yes" if boss_seen else "no", int(accuracy * 100), peak_enemies, peak_bullets,
		str(result["forks"]), str(result["fusions"]), seconds_real])
	for problem in problems:
		failures += 1
		print("    PROBLEM: %s" % problem)
