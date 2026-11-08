extends Node
## The game's flow, top to bottom: title, then the command center; launch a planet's mission; show the
## results and bank the rewards; back to the command center. Everything else is a step this calls.

var star_map: StarMap
var _debug_options := {}
var screen: Node = null
var ui_layer: CanvasLayer


func _ready() -> void:
	get_tree().root.theme = UiKit.theme()
	ui_layer = CanvasLayer.new()
	add_child(ui_layer)
	Browser.set_fullscreen_wanted(Save.setting("fullscreen"))
	star_map = StarMap.new(int(Save.data["map_seed"]))
	star_map.ensure_generated(Save.is_cleared)
	if not _debug_launch():
		show_title()


func show_title() -> void:
	var title := TitleScreen.new()
	title.started.connect(func(): show_hub("map"))
	_set_screen(title)


func show_hub(page: String) -> void:
	star_map.ensure_generated(Save.is_cleared)
	var hub := Hub.new(star_map, page)
	hub.launch_requested.connect(launch_mission)
	_set_screen(hub)


func launch_mission(node_id: String) -> void:
	var node := _test_node(node_id.trim_prefix("test:")) if node_id.begins_with("test:") else star_map.get_node(node_id).duplicate(true)
	node["threat"] = Save.setting("threat")
	node["arrivals"] = Save.data["enemies_unlocked"].duplicate()
	var first_clear := not Save.is_cleared(node_id)
	var mission_seed := randi()
	var mission := Mission.new(node, mission_seed, Save.data["frame"], Save.data["loadout"], Save.tech_mk)
	var view := MissionView.new()
	view.setup(mission, first_clear)
	view.finished.connect(func(result): finish_mission(node_id, result))
	view.abandoned.connect(func():
		var result := mission.results(false)
		result["abandoned"] = true
		finish_mission(node_id, result))
	Save.data["stats"]["missions"] += 1
	_set_screen(view, false)


## Banks rewards in Save, then shows the results screen.
func finish_mission(node_id: String, result: Dictionary) -> void:
	var hints := []
	var is_test := node_id.begins_with("test:")
	# Lesson planets hand over their tech win or lose (GDD 9C).
	var node := star_map.get_node(node_id) if not is_test else {}
	var lesson_tech: String = node.get("lesson_tech", "")
	if lesson_tech != "" and Save.tech_mk(lesson_tech) == 0:
		Save.unlock_tech(lesson_tech)
		Save.queue_radio(Radio.lesson_line(lesson_tech, result["won"]))
		hints.append("New tech: %s. Equip it in the Hangar." % TechData.TECH[lesson_tech]["name"])
		PlayLog.note("unlock", "Lesson tech %s unlocked (%s)" % [lesson_tech, "won" if result["won"] else "lost"])
	if result["won"] and not is_test:
		Save.mark_cleared(node_id)
		Save.data["stats"]["wins"] += 1
	if result["prize"] != "" and not is_test:
		Save.claim_prize(node_id, result["prize"])
	Save.data["stats"]["kills"] += result["kills"]
	for tech_id in result["blueprints"]:
		Save.add_blueprints(tech_id, int(result["blueprints"][tech_id]))
		var mk := Save.tech_mk(tech_id)
		var need := TechData.blueprints_for_next_mk(mk)
		if need > 0 and Save.blueprints(tech_id) >= need:
			hints.append("%s can be %s in R&D." % [TechData.TECH[tech_id]["name"], "unlocked" if mk == 0 else "upgraded to Mk %d" % (mk + 1)])
	var earned := [] if is_test else Milestones.record_mission(result)
	for milestone in earned:
		hints.append("Milestone: %s. %s" % [milestone["name"], Milestones.reward_text(milestone)])
	Save.write()
	star_map.ensure_generated(Save.is_cleared)
	var results := ResultsScreen.new(result, hints)
	results.continued.connect(func(): show_hub("map"))
	_set_screen(results)


## Debug launches for the playtesters and capture harness, from the page URL (?test=planet&boss=1)
## or command-line user args (-- test=planet boss=1). Options:
##   test=<type>  launch a test mission    boss=1   skip to its boss    power=a|b  everything online
##   god=1        invulnerable             page=<map|hangar|rnd|settings>  open the hub on a page
##   frame=<id>   fly a frame              mk=3     all tech unlocked at that Mk
func _debug_launch() -> bool:
	var options := {}
	var raw := ""
	if OS.has_feature("web"):
		var search = JavaScriptBridge.eval("window.location.search", true)
		raw = str(search).trim_prefix("?").replace("&", " ") if search != null else ""
	else:
		raw = " ".join(OS.get_cmdline_user_args())
	for pair in raw.split(" ", false):
		var parts := pair.split("=")
		options[parts[0]] = parts[1] if parts.size() > 1 else "1"
	_debug_options = options
	if options.is_empty():
		return false
	PlayLog.note("debug", "Debug launch: %s" % str(options))
	if options.has("mk"):
		for tech_id in TechData.TECH:
			Save.data["tech_mk"][tech_id] = clampi(int(options["mk"]), 1, TechData.MAX_MK)
	if options.has("frame") and FrameData.FRAMES.has(options["frame"]):
		if not Save.data["frames_unlocked"].has(options["frame"]):
			Save.data["frames_unlocked"].append(options["frame"])
		Save.data["frame"] = options["frame"]
	if options.has("loadout"):
		Save.data["loadout"] = Array(options["loadout"].split(","))
		Save.data = Save.repair(Save.data)
	AdminConsole.god_mode = options.has("god")
	if options.has("test"):
		launch_mission("test:" + options["test"])
		var view := screen as MissionView
		if options.has("power"):
			view.mission.debug_power_up(options["power"])
		if options.has("boss"):
			view.mission.stage.debug_skip_to_boss()
		if options.has("miniboss"):
			view.mission.stage.debug_skip_to_miniboss()
		if options.has("offer"):
			view.mission.open_offer("level_up", 3)
		return true
	if options.has("page"):
		show_hub(options["page"])
		return true
	return false


## A stand-in planet for the debug console's "test" command. Debug launches can make it a lesson planet.
func _test_node(mission_type: String) -> Dictionary:
	var lesson: String = _debug_options.get("lesson", "")
	return {"lesson": lesson, "boss": "mirror_dreadnought" if lesson == "mirror" else "", "baseline": int(_debug_options.get("planet", "2")) - 1,"id": "test:" + mission_type, "name": "Test Range", "region": 0, "column": 2, "row": 0.0, "type": mission_type,
		"need": MissionData.NEEDS[mission_type][0], "difficulty": 1.0, "danger": 1, "modifier": "", "reward_tech": "arc_blade",
		"is_gate": false, "branch": "", "prize": "", "prize_text": "", "links": [], "incoming": [], "planet_look": 5}


## Swaps the current screen. Menus live on a CanvasLayer; the mission view is a Node2D world.
func _set_screen(next: Node, is_ui: bool = true) -> void:
	if screen != null:
		screen.queue_free()
	screen = next
	if is_ui:
		ui_layer.add_child(next)
	else:
		add_child(next)
