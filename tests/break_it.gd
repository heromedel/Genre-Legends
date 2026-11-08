extends SceneTree
## Break-it playtester (GDD 4A), headless half: plays every mission wrong on purpose. Garbage and
## extreme inputs, special spam, out-of-range card picks, mashing through offers, idling, hand-off spam,
## and damaged saves. Looks for crashes, NaNs, runaway entities and softlocks.
## The browser half (tap storms, rotating, backgrounding, reloading) is tests/web/break_it.js.
## Run:  godot --headless -s tests/break_it.gd

var problems := 0


func _init() -> void:
	print("Break-it (headless)")
	for mission_type in MissionData.PLAYABLE_TYPES:
		for style in ["garbage", "masher", "idler", "wall_hugger"]:
			_abuse_mission(mission_type, style)
	_abuse_handoffs()
	_abuse_saves()
	print("Break-it done: %d problem(s)" % problems)
	quit(1 if problems > 0 else 0)


func report(text: String) -> void:
	problems += 1
	print("  PROBLEM: ", text)


func _node(mission_type: String) -> Dictionary:
	return {"id": "b", "name": "B", "region": 1, "column": 2, "row": 0.0, "type": mission_type, "need": "x",
		"difficulty": 1.4, "danger": 3, "modifier": "swarm_season", "reward_tech": "starfall", "prize": "", "prize_text": ""}


func _abuse_mission(mission_type: String, style: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mission_type + style)
	var all_tech := ["hex_repeater", "orbital_halo", "starfall", "overheat_core", "time_brake"]
	var mission := Mission.new(_node(mission_type), rng.randi(), "tempest", all_tech, func(t): return 3)
	mission.debug_power_up("b")
	var peak := 0
	for tick in 60 * 90:
		var frame := InputFrame.new()
		match style:
			"garbage":
				frame.move = Vector2(rng.randf_range(-50, 50), rng.randf_range(-50, 50))
				frame.drag = Vector2(rng.randf_range(-5000, 5000), rng.randf_range(-5000, 5000))
				frame.aim = Vector2(rng.randf_range(-9, 9), rng.randf_range(-9, 9))
				frame.special = rng.randf() < 0.5
				frame.choice = rng.randi_range(-5, 12)
			"masher":
				frame.special = true
				frame.choice = tick % 6
				frame.move = Vector2.from_angle(tick * 0.7)
			"idler":
				frame.choice = 0 if tick % 600 == 0 else -1
			"wall_hugger":
				frame.move = Vector2(-1, 0) if (tick / 300) % 2 == 0 else Vector2(1, 1)
				frame.drag = Vector2(-40, 0)
				frame.choice = 1
		mission.step(frame.quantized())
		mission.drain_events()
		var player := mission.player
		if is_nan(player.pos.x) or is_nan(player.pos.y) or is_nan(player.armor) or is_inf(player.pos.x):
			report("%s/%s: NaN or infinity in the frame at tick %d" % [mission_type, style, tick])
			return
		if not mission.world.bounds.grow(5).has_point(player.pos):
			report("%s/%s: frame escaped the arena at %s" % [mission_type, style, str(player.pos)])
			return
		peak = maxi(peak, mission.world.enemy_shots.size() + mission.world.enemies.size() + mission.world.player_shots.size())
		if mission.is_finished():
			break
	if peak > 3000:
		report("%s/%s: %d entities at peak" % [mission_type, style, peak])
	print("  %-12s %-12s state %-5s ticks %5d peak %4d" % [mission_type, style, mission.state, mission.tick, peak])


## Stage hand-offs in quick succession must keep the run, the frame and the world consistent.
func _abuse_handoffs() -> void:
	var mission := Mission.new(_node("planet"), 77, "vanguard", TechData.STARTING_LOADOUT, func(t): return 2)
	mission.run.level = 7
	for i in 12:
		var next_type: String = MissionData.PLAYABLE_TYPES[i % MissionData.PLAYABLE_TYPES.size()]
		mission.start_stage(StageFactory.make(next_type, mission))
		for tick in 120:
			mission.step(InputFrame.new())
			mission.drain_events()
		if mission.run.level != 7:
			report("hand-off lost the run's level")
		if mission.player.form != MissionData.TYPES[next_type]["form"]:
			report("hand-off to %s left the frame in %s form" % [next_type, mission.player.form])
	print("  hand-offs: %d stages, state %s" % [mission.stages_played.size(), mission.state])


func _abuse_saves() -> void:
	var save_script = load("res://scripts/save/save_data.gd")
	var save = save_script.new()
	var garbage := [
		{}, {"version": "banana"}, {"tech_mk": {"pulse_driver": 99, "not_a_tech": 3}, "loadout": [1, 2, 3]},
		{"loadout": ["arc_blade", "arc_blade", "arc_blade", "arc_blade", "arc_blade"]},
		{"frame": "unicorn", "frames_unlocked": ["unicorn"], "settings": "loud", "blueprints": {"pulse_driver": -5}},
		{"map_seed": 1.5e300, "cleared": [1, 2], "stats": null},
	]
	for raw in garbage:
		var fixed: Dictionary = save.repair(raw)
		if fixed["loadout"].size() != TechData.SLOTS.size() or fixed["loadout"][0] == "":
			report("save repair left a broken loadout from %s" % str(raw))
		if not FrameData.FRAMES.has(fixed["frame"]):
			report("save repair left an unknown frame from %s" % str(raw))
		for tech_id in fixed["tech_mk"]:
			if fixed["tech_mk"][tech_id] > TechData.MAX_MK or not TechData.TECH.has(tech_id):
				report("save repair kept a bad tech entry %s" % tech_id)
		for tech_id in fixed["blueprints"]:
			if fixed["blueprints"][tech_id] < 0:
				report("save repair kept negative blueprints")
	save.free()
	print("  saves: %d damaged saves repaired" % garbage.size())
