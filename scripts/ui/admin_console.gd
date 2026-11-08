class_name AdminConsole
extends RefCounted
## Debug and admin commands, typed into Settings > Debug Console. More commands are better than fewer
## (Game Project Standards), especially ones that help reproduce real play. Every command is logged.

signal changed
signal launch_test(mission_type: String)

static var god_mode := false

var star_map: StarMap
var output: Label

const HELP := """Commands:
  help                     this list
  blueprints <n>           add n blueprints to every tech
  unlockall                unlock every tech at Mk 3 and every frame
  mk <tech_id> <0-3>       set a tech's Mk
  frame <id>               unlock and select a frame (vanguard, tempest, bulwark)
  clear <n>                clear the next n reachable planets
  god                      toggle invulnerability in missions
  test <type>              launch a test mission (star_cluster, corridor, planet, dungeon)
  log                      show the last 15 play log lines
  seed <n>                 new star map seed (keeps tech, clears the map)"""


func build() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	var row := HBoxContainer.new()
	var field := LineEdit.new()
	field.placeholder_text = "type help"
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.custom_minimum_size = Vector2(0, 44)
	row.add_child(field)
	var run := func():
		var text := field.text.strip_edges()
		field.text = ""
		output.text = execute(text)
	field.text_submitted.connect(func(_t): run.call())
	row.add_child(UiKit.button("Run", run, "Console: run"))
	column.add_child(row)
	output = UiKit.wrapped("God mode: %s" % ("on" if god_mode else "off"), 13, Color(0.75, 0.9, 0.75))
	output.add_theme_font_override("font", UiKit.font("body"))
	column.add_child(output)
	return column


func execute(text: String) -> String:
	if text == "":
		return HELP
	PlayLog.note("admin", text)
	var parts := text.split(" ", false)
	var command := parts[0].to_lower()
	match command:
		"help":
			return HELP
		"blueprints":
			var amount := int(parts[1]) if parts.size() > 1 else 10
			for tech_id in TechData.TECH:
				Save.add_blueprints(tech_id, amount)
			Save.write()
			changed.emit()
			return "Added %d blueprints to every tech." % amount
		"unlockall":
			for tech_id in TechData.TECH:
				Save.data["tech_mk"][tech_id] = TechData.MAX_MK
			for frame_id in FrameData.FRAMES:
				if not Save.data["frames_unlocked"].has(frame_id):
					Save.data["frames_unlocked"].append(frame_id)
			Save.write()
			changed.emit()
			return "Everything unlocked at Mk 3."
		"mk":
			if parts.size() < 3 or not TechData.TECH.has(parts[1]):
				return "Usage: mk <tech_id> <0-3>. Tech ids: %s" % ", ".join(TechData.TECH.keys())
			Save.data["tech_mk"][parts[1]] = clampi(int(parts[2]), 0, TechData.MAX_MK)
			Save.data = Save.repair(Save.data)
			Save.write()
			changed.emit()
			return "%s is now Mk %d." % [parts[1], Save.tech_mk(parts[1])]
		"frame":
			if parts.size() < 2 or not FrameData.FRAMES.has(parts[1]):
				return "Usage: frame <vanguard|tempest|bulwark>"
			if not Save.data["frames_unlocked"].has(parts[1]):
				Save.data["frames_unlocked"].append(parts[1])
			Save.select_frame(parts[1])
			changed.emit()
			return "Flying %s." % parts[1]
		"clear":
			var count := int(parts[1]) if parts.size() > 1 else 1
			var cleared := []
			for i in count:
				star_map.ensure_generated(Save.is_cleared)
				var next := ""
				var best_column := 9999
				for node_id in star_map.all_node_ids():
					var node := star_map.get_node(node_id)
					if not Save.is_cleared(node_id) and star_map.is_available(node_id, Save.is_cleared) and node["column"] < best_column and node["branch"] == "":
						best_column = node["column"]
						next = node_id
				if next == "":
					break
				Save.mark_cleared(next)
				cleared.append(next)
			Save.write()
			star_map.ensure_generated(Save.is_cleared)
			changed.emit()
			return "Cleared: %s" % ", ".join(cleared)
		"god":
			god_mode = not god_mode
			return "God mode %s." % ("on" if god_mode else "off")
		"test":
			var mission_type := parts[1] if parts.size() > 1 else "star_cluster"
			if not MissionData.TYPES.has(mission_type):
				return "Usage: test <%s>" % "|".join(MissionData.PLAYABLE_TYPES)
			launch_test.emit(mission_type)
			return "Launching a %s test." % mission_type
		"log":
			var lines := PlayLog.lines.slice(maxi(PlayLog.lines.size() - 15, 0))
			return "\n".join(lines)
		"seed":
			Save.data["map_seed"] = int(parts[1]) if parts.size() > 1 else randi() % 1000000
			Save.data["cleared"] = {}
			Save.write()
			return "New map seed %d. Reopen the game to see it." % Save.data["map_seed"]
	return "Unknown command. Type help."
