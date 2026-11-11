extends Node
## The game's flow, top to bottom: title, then the command center; launch a planet's mission; show the
## results and bank the rewards; back to the command center. Everything else is a step this calls.

## A lesson planet whose tech you already own pays this many of its blueprints instead (GDD 9C).
const LESSON_BLUEPRINTS_IF_OWNED := 4

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
	hub.resume_requested.connect(resume_saved_mission)
	_set_screen(hub)


func launch_mission(node_id: String, event: Dictionary = {}) -> void:
	var node := _test_node(node_id.trim_prefix("test:")) if node_id.begins_with("test:") else star_map.get_node(node_id).duplicate(true)
	node["event"] = event
	node["threat"] = Save.setting("threat")
	node["auto_aim"] = Save.setting("auto_aim")
	node["autofire"] = Save.setting("autofire")
	node["radio"] = Radio.mission_start_line(node, int(Save.data["stats"]["missions"]))
	node["arrivals"] = Save.data["enemies_unlocked"].duplicate()
	# Everything that decides how the mission plays, so it can be rebuilt exactly to resume it (Save checkpoint).
	var mk := {}
	for tech_id in Save.data["loadout"]:
		if tech_id != "":
			mk[tech_id] = Save.tech_mk(tech_id)
	var launch := {"build": BuildInfo.label(), "node_id": node_id, "node": node, "seed": randi(), "frame": Save.data["frame"],
		"frame_tiers": Save.frame_tiers(Save.data["frame"]).duplicate(),
		"loadout": Save.data["loadout"].duplicate(), "mk": mk, "first_clear": not Save.is_cleared(node_id)}
	Save.data["stats"]["missions"] += 1
	_start_mission(launch, "")


## Builds the mission from its launch and opens it. With saved inputs it resumes: the mission is rebuilt and
## fast-forwarded through them to exactly where it was (the simulation is deterministic).
func _start_mission(launch: Dictionary, inputs: String, abandon_after_restore: bool = false) -> void:
	var node_id: String = launch["node_id"]
	var mk: Dictionary = launch["mk"]
	var mission := Mission.new(launch["node"], launch["seed"], launch["frame"], launch["loadout"], func(tech_id): return int(mk.get(tech_id, 1)),
		launch.get("frame_tiers", []))
	var view := MissionView.new()
	view.setup(mission, launch["first_clear"])
	view.checkpoint_launch = launch
	view.resume_frames = InputFrame.decode_runs(inputs)
	view.abandon_after_restore = abandon_after_restore
	view.skip_cutscenes = _debug_options.has("test") and not _debug_options.has("cutscene")
	view.finished.connect(func(result):
		Save.clear_checkpoint()
		finish_mission(node_id, result))
	view.abandoned.connect(func():
		Save.clear_checkpoint()
		var result := mission.results(false)
		result["abandoned"] = true
		finish_mission(node_id, result))
	_set_screen(view, false)


## A mission the browser closed on: resumable on the same build, otherwise only something to tell the player.
func resume_saved_mission(abandon: bool) -> void:
	var checkpoint := Save.read_checkpoint()
	if checkpoint.is_empty():
		return
	PlayLog.note("mission", "%s a saved mission (%d inputs)" % ["Abandoning" if abandon else "Resuming", int(checkpoint.get("ticks", 0))])
	_start_mission(checkpoint["launch"], checkpoint["inputs"], abandon)


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
	elif lesson_tech != "":
		# Found it early: the lesson planet pays toward its next Mk instead.
		Save.add_blueprints(lesson_tech, LESSON_BLUEPRINTS_IF_OWNED)
		Save.queue_radio(Radio.came_prepared_line(lesson_tech))
		hints.append("+%d %s blueprints." % [LESSON_BLUEPRINTS_IF_OWNED, TechData.TECH[lesson_tech]["name"]])
		PlayLog.note("unlock", "Lesson tech %s already owned: +%d blueprints" % [lesson_tech, LESSON_BLUEPRINTS_IF_OWNED])
	if result["won"] and not is_test:
		Save.mark_cleared(node_id)
		Save.data["stats"]["wins"] += 1
	if result["prize"] != "" and not is_test:
		Save.claim_prize(node_id, result["prize"])
	Save.data["stats"]["kills"] += result["kills"]
	if int(result.get("frame_blueprints", 0)) > 0 and not is_test:
		Save.data["frame_blueprints"] += int(result["frame_blueprints"])
		var cost := Save.next_tier_cost(Save.data["frame"])
		if cost > 0 and Save.data["frame_blueprints"] >= cost:
			hints.append("Enough Frame Blueprints for a new %s tier: buy it in the Hangar." % FrameData.get_frame(Save.data["frame"])["name"])
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
##   god=1        invulnerable             page=<map|hangar|rnd|guide|records|settings>  open the hub on a page
##   frame=<id>   fly a frame              mk=3     all tech unlocked at that Mk
##   chain=<type>  the test planet chains into that mission type partway       cutscene=1  keep the transitions
##   bossid=<id> / minibossid=<id>   pick the test planet's boss or mini-boss (see BossRoster)
##   crate=<n>    open n Salvage Crates as soon as play starts      event=<id>  the next launch meets that route event      phase=<n>  with boss=1, the boss starts in phase n
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
	RouteEvents.forced = options.get("event", "")
	if options.has("test"):
		launch_mission("test:" + options["test"])
		var view := screen as MissionView
		if options.has("power"):
			view.mission.debug_power_up(options["power"])
		if options.has("boss"):
			view.mission.stage.debug_skip_to_boss()
			view.mission.stage.debug_boss_phase = int(options.get("phase", "0"))
		if options.has("miniboss"):
			view.mission.stage.debug_skip_to_miniboss()
		if options.has("offer"):
			view.mission.open_offer("level_up", 3)
		if options.has("crate"):
			view.mission.pending_crates += int(options["crate"])
		return true
	if options.has("page"):
		show_hub(options["page"])
		return true
	# Art tests: one piece of art alone at a set zoom (ArtGallery).
	if options.has("gallery"):
		var gallery := ArtGallery.new()
		gallery.subject = options["gallery"]
		gallery.zoom = float(options.get("zoom", "3"))
		gallery.rim = options.has("rim")
		gallery.backdrop = options.get("bg", "")
		_set_screen(gallery)
		return true
	return false


## A stand-in planet for the debug console's "test" command. Debug launches can make it a lesson planet.
func _test_node(mission_type: String) -> Dictionary:
	var lesson: String = _debug_options.get("lesson", "")
	var boss_id: String = "mirror_dreadnought" if lesson == "mirror" else _debug_options.get("bossid", "")
	return {"lesson": lesson, "boss": boss_id, "miniboss": _debug_options.get("minibossid", ""), "chain": _debug_options.get("chain", ""), "baseline": int(_debug_options.get("planet", "2")) - 1,"id": "test:" + mission_type, "name": "Test Range", "region": 0, "column": 2, "row": 0.0, "type": mission_type,
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
