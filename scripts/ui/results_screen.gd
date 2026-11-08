class_name ResultsScreen
extends Control
## After a mission: how it went, what you earned, and what it unlocked. Says plainly why you won or lost
## (Information & Feedback): damage taken, what hit you most, and what to try next.

signal continued

var result: Dictionary
var unlock_hints: Array = []


func _init(mission_result: Dictionary, hints: Array) -> void:
	result = mission_result
	unlock_hints = hints


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	PlayLog.set_screen("results")
	var backdrop := Backdrop.new()
	backdrop.won = result["won"]
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := UiKit.panel(Color(0.04, 0.07, 0.12), Art.GOLD if result["won"] else Color(1, 0.4, 0.4))
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(620, 0)
	column.add_theme_constant_override("separation", 10)
	panel.add_child(column)
	var heading := "MISSION COMPLETE" if result["won"] else ("MISSION ABANDONED" if result.get("abandoned", false) else "FRAME WRECKED")
	var title := UiKit.label(heading, 40, Art.GOLD if result["won"] else Color(1, 0.45, 0.45), "title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var seconds := int(result["seconds"])
	var stats := GridContainer.new()
	stats.columns = 4
	stats.add_theme_constant_override("h_separation", 26)
	column.add_child(stats)
	for pair in [["Time", "%d:%02d" % [seconds / 60, seconds % 60]], ["Level", str(result["level"])], ["Kills", str(result["kills"])],
			["Damage taken", "%d (%d hits)" % [int(result["damage_taken"]), result["hits_taken"]]], ["Crates", str(result["crates"])],
			["Shards missed", str(result["shards_missed"])]]:
		stats.add_child(UiKit.label(pair[0], 14, Color(0.6, 0.72, 0.85)))
		stats.add_child(UiKit.label(pair[1], 18, Color(1, 1, 1), "bold"))
	if not result["forks"].is_empty() or not result["fusions"].is_empty():
		var built := []
		for tech_id in result["forks"]:
			built.append("%s: %s" % [TechData.TECH[tech_id]["name"], TechData.fork_name(tech_id, result["forks"][tech_id])])
		for fusion_id in result["fusions"]:
			built.append(UpgradeData.FUSIONS[fusion_id]["name"])
		column.add_child(UiKit.wrapped("Your build: " + ", ".join(built), 15, Color(0.8, 0.6, 1.0)))
	column.add_child(UiKit.label("BLUEPRINTS" + ("" if result["won"] else " (half kept)"), 18, Color(0.6, 0.9, 1.0), "title"))
	var earned := HFlowContainer.new()
	earned.add_theme_constant_override("h_separation", 16)
	column.add_child(earned)
	if result["blueprints"].is_empty():
		earned.add_child(UiKit.label("None this time.", 15, Color(0.6, 0.65, 0.75)))
	for tech_id in result["blueprints"]:
		if int(result["blueprints"][tech_id]) <= 0:
			continue
		var chip := HBoxContainer.new()
		chip.add_child(IconView.make(tech_id, 30, TechData.element_color(tech_id)))
		chip.add_child(UiKit.label("%s +%d" % [TechData.TECH[tech_id]["name"], result["blueprints"][tech_id]], 16, Color(1, 1, 1)))
		earned.add_child(chip)
	if result["prize_text"] != "":
		column.add_child(UiKit.label("PRIZE: " + result["prize_text"], 20, Art.GOLD, "bold"))
	for hint in unlock_hints:
		column.add_child(UiKit.wrapped(hint, 15, Color(0.5, 1.0, 0.7)))
	column.add_child(UiKit.spacer(6))
	column.add_child(UiKit.button("Continue", func(): continued.emit(), "Results: continue", true))
	Sound.play("victory" if result["won"] else "boss_down")


## A slow starfield behind the results, gold-tinted for a win and red for a loss.
class Backdrop:
	extends Control
	var won := true
	var time := 0.0
	var background := BackgroundArt.new(MissionData.REGION_PALETTES[0], 5)

	func _ready() -> void:
		texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		background.draw_space(self, Rect2(Vector2.ZERO, size), time * 40.0, time)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.45))
		Art.draw_glow(self, size * 0.5, size.x * 0.45, Color(1, 0.75, 0.3, 0.18) if won else Color(1, 0.25, 0.25, 0.18))
