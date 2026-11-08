class_name Hub
extends Control
## The command center (GDD 5A): a console menu with text and icons. A rail on the left switches pages:
## Star Map (pick where to go), Hangar (frame and loadout), R&D (spend blueprints) and Settings.

## event: what a route event (RouteEvents) leaves for the mission, or {} for a quiet trip.
signal launch_requested(node_id: String, event: Dictionary)

var star_map: StarMap
var page := "map"
var content: Control
var rail_buttons := {}
var rail_dots := {}             # page id -> its green dot, refreshed on every rebuild
var selected_node := ""
var picker_slot := -1
var admin: AdminConsole


func _init(map: StarMap, start_page: String = "map") -> void:
	star_map = map
	page = start_page


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.035, 0.07)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)
	root.add_child(_build_rail())
	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 0)
	root.add_child(main)
	main.add_child(_build_top_bar())
	content = MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 14)
	main.add_child(content)
	show_page(page)
	Sound.play_music("hub")
	_show_radio_queue()


## Messages waiting from the operations officer: lessons, new arrivals (GDD 9E).
func _show_radio_queue() -> void:
	var queue: Array = Save.data["radio_queue"]
	if queue.is_empty():
		return
	var text: String = queue.pop_front()
	Save.write()
	PlayLog.note("radio", text)
	var box := UiKit.panel(Color(0.03, 0.07, 0.12, 0.98), Color(0.45, 0.9, 1.0))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(560, 0)
	column.add_theme_constant_override("separation", 12)
	box.add_child(column)
	column.add_child(UiKit.label("INCOMING: " + Radio.OFFICER.to_upper(), 14, Color(0.5, 0.9, 1.0), "bold"))
	column.add_child(UiKit.wrapped(text, 19, Color(1, 1, 1)))
	var popup := Overlays._floating(box)
	column.add_child(UiKit.button("Understood", func():
		popup.queue_free()
		_show_radio_queue(), "Radio: understood", true))
	add_child(popup)


## On the way to a planet something may happen (RouteEvents): a choice, its outcome, then the launch.
func _launch(node: Dictionary) -> void:
	var missions_flown: int = Save.data["stats"]["missions"]
	var event_id := RouteEvents.roll(node, missions_flown, Save.data["map_seed"])
	if event_id == "":
		launch_requested.emit(node["id"], {})
		return
	var event: Dictionary = RouteEvents.EVENTS[event_id]
	PlayLog.note("event", "On the way to %s: %s" % [node["name"], event["title"]])
	Sound.play("radio")
	var box := UiKit.panel(Color(0.04, 0.06, 0.1, 0.98), Color(1, 0.75, 0.35))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(600, 0)
	column.add_theme_constant_override("separation", 10)
	box.add_child(column)
	column.add_child(UiKit.label("EN ROUTE TO " + node["name"].to_upper(), 13, Color(1, 0.75, 0.35), "bold"))
	column.add_child(UiKit.label(event["title"], 26, Color(1, 1, 1), "title"))
	column.add_child(UiKit.wrapped(event["text"], 17, Color(0.85, 0.9, 1.0)))
	var popup := Overlays._floating(box)
	var choices: Array = event["choices"]
	for i in choices.size():
		var choice: Dictionary = choices[i]
		var affordable: bool = _largest_blueprint_pile() >= int(choice.get("needs_blueprints", 0))
		var label: String = choice["label"] + ("" if choice["hint"] == "" else "  -  " + choice["hint"])
		var button := UiKit.button(label, func():
			var outcome := RouteEvents.resolve(event_id, i, node["id"], missions_flown, Save.data["map_seed"])
			_route_outcome(popup, column, node, event, choice, outcome), "Event %s: %s" % [event_id, choice["label"]])
		button.disabled = not affordable
		column.add_child(button)
	add_child(popup)


## Shows what happened, pays out anything immediate, and launches with the rest.
func _route_outcome(popup: Control, column: VBoxContainer, node: Dictionary, event: Dictionary, choice: Dictionary, outcome: Array) -> void:
	for child in column.get_children():
		if child is Button:
			child.queue_free()
	var effects: Dictionary = outcome[1]
	column.add_child(UiKit.wrapped(outcome[0], 17, Color(1, 0.85, 0.55)))
	if effects.has("blueprints_random"):
		var ids := TechData.TECH.keys()
		for n in int(effects["blueprints_random"]):
			Save.add_blueprints(ids[randi() % ids.size()], 1)
	if effects.has("blueprints_planet"):
		Save.add_blueprints(node["reward_tech"], int(effects["blueprints_planet"]))
	if effects.has("spend_blueprints"):
		var pile := _largest_blueprint_pile_id()
		Save.add_blueprints(pile, -int(effects["spend_blueprints"]))
	Save.write()
	PlayLog.note("event", "%s: chose \"%s\" - %s" % [event["title"], choice["label"], outcome[0]])
	var carried := effects.duplicate()
	carried["title"] = event["title"]
	column.add_child(UiKit.button("Launch", func():
		popup.queue_free()
		launch_requested.emit(node["id"], carried), "Event: launch", true))


func _largest_blueprint_pile() -> int:
	var pile := _largest_blueprint_pile_id()
	return Save.blueprints(pile) if pile != "" else 0


func _largest_blueprint_pile_id() -> String:
	var best := ""
	for tech_id in Save.data["blueprints"]:
		if best == "" or Save.blueprints(tech_id) > Save.blueprints(best):
			best = tech_id
	return best


func _build_rail() -> Control:
	var rail := PanelContainer.new()
	rail.add_theme_stylebox_override("panel", UiKit._box(Color(0.04, 0.06, 0.1), Color(0.15, 0.24, 0.35), 0, 0))
	rail.custom_minimum_size = Vector2(112, 0)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	rail.add_child(column)
	var logo := UiKit.label("GL", 30, Art.GOLD, "title")
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(UiKit.spacer(6))
	column.add_child(logo)
	column.add_child(UiKit.spacer(8))
	for entry in [["map", "map", "STAR MAP"], ["hangar", "hangar", "HANGAR"], ["rnd", "lab", "R&D"], ["guide", "guide", "GUIDE"], ["records", "prize", "RECORDS"], ["settings", "settings", "SETTINGS"]]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(96, 84)
		button.focus_mode = Control.FOCUS_NONE
		var page_id: String = entry[0]
		button.pressed.connect(func():
			PlayLog.button("Rail: %s" % entry[2])
			Sound.play("ui")
			show_page(page_id))
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		var icon := IconView.make(entry[1], 34, Color(0.6, 0.9, 1.0))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		var text := UiKit.label(entry[2], 12, Color(0.7, 0.85, 1.0), "bold")
		text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(text)
		button.add_child(box)
		column.add_child(button)
		rail_buttons[page_id] = button
		if page_id in ["hangar", "rnd"]:
			var dot := NewDot.new()
			button.add_child(dot)
			rail_dots[page_id] = dot
	return rail


## Green dots (GDD 9C): Hangar while new tech waits to be equipped, R&D while something can be unlocked
## or upgraded. Refreshed on every rebuild so they clear the moment you act on them.
func _refresh_rail_dots() -> void:
	rail_dots["hangar"].visible = not Save.data["new_unlocks"].is_empty()
	rail_dots["rnd"].visible = TechData.TECH.keys().any(func(tech_id): return Save.can_upgrade(tech_id))


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit._box(Color(0.04, 0.06, 0.1), Color(0.15, 0.24, 0.35), 0, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	bar.add_child(row)
	row.add_child(UiKit.label("COMMAND CENTER", 22, Color(0.6, 0.9, 1.0), "title"))
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)
	var frame := FrameData.get_frame(Save.data["frame"])
	row.add_child(UiKit.label("Frame: %s" % frame["name"], 16, frame["hull"], "bold"))
	row.add_child(UiKit.label("Planets cleared: %d" % Save.data["cleared"].size(), 16, Color(0.7, 0.85, 1.0)))
	var total_blueprints := 0
	for tech_id in Save.data["blueprints"]:
		total_blueprints += int(Save.data["blueprints"][tech_id])
	row.add_child(UiKit.label("Blueprints: %d" % total_blueprints, 16, Color(0.5, 0.8, 1.0)))
	return bar


func show_page(page_id: String) -> void:
	page = page_id
	picker_slot = -1
	PlayLog.set_screen(page_id)
	_rebuild()


## Rebuilds the current page from Save, keeping in-page state such as the open slot picker.
func _rebuild() -> void:
	var page_id := page
	for key in rail_buttons:
		rail_buttons[key].add_theme_stylebox_override("normal", UiKit._box(Color(0.12, 0.2, 0.3) if key == page_id else Color(0.06, 0.09, 0.14), Color(0.5, 0.85, 1.0) if key == page_id else Color(0.2, 0.3, 0.42), 2))
	_refresh_rail_dots()
	for child in content.get_children():
		child.queue_free()
	match page_id:
		"map": content.add_child(_build_map_page())
		"hangar": content.add_child(_build_hangar_page())
		"rnd": content.add_child(_build_rnd_page())
		"settings": content.add_child(_build_settings_page())
		"guide": content.add_child(_build_guide_page())
		"records": content.add_child(_build_records_page())


# ---------------------------------------------------------------- star map

var _map_view: StarMapView
var _info: VBoxContainer


func _build_map_page() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var frame := UiKit.panel(Color(0.02, 0.03, 0.06), Color(0.2, 0.32, 0.46))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(frame)
	_map_view = StarMapView.new()
	_map_view.star_map = star_map
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.node_selected.connect(_on_node_selected)
	frame.add_child(_map_view)
	var info_panel := UiKit.panel()
	info_panel.custom_minimum_size = Vector2(340, 0)
	row.add_child(info_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	info_panel.add_child(scroll)
	_info = VBoxContainer.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_constant_override("separation", 8)
	scroll.add_child(_info)
	if selected_node == "" or star_map.get_node(selected_node).is_empty():
		selected_node = _frontier_node()
	_map_view.selected = selected_node
	_fill_info(selected_node)

	return row


## The planet to suggest: the first reachable planet not yet cleared, preferring the main route.
func _frontier_node() -> String:
	var best := ""
	var best_column := 9999
	for node_id in star_map.all_node_ids():
		var node := star_map.get_node(node_id)
		if Save.is_cleared(node_id) or not star_map.is_available(node_id, Save.is_cleared):
			continue
		var column: int = node["column"] + (1 if node["branch"] != "" else 0)
		if column < best_column:
			best_column = column
			best = node_id
	return best if best != "" else "r0c0n0"


func _on_node_selected(node_id: String) -> void:
	selected_node = node_id
	_fill_info(node_id)


func _fill_info(node_id: String) -> void:
	for child in _info.get_children():
		child.queue_free()
	var node := star_map.get_node(node_id)
	if node.is_empty():
		return
	var mission_type: Dictionary = MissionData.TYPES[node["type"]]
	var region_name: String = star_map.regions[node["region"]]["name"]
	_info.add_child(UiKit.label(region_name.to_upper(), 13, Color(0.5, 0.65, 0.8), "bold"))
	_info.add_child(UiKit.label(node["name"], 30, Color(1, 1, 1), "title"))
	if node["branch"] != "":
		_info.add_child(UiKit.label(node["branch_name"], 16, Art.GOLD, "bold"))
	var type_row := HBoxContainer.new()
	type_row.add_child(IconView.make(node["type"], 30, Color(0.6, 0.9, 1.0)))
	var type_text := VBoxContainer.new()
	type_text.add_theme_constant_override("separation", 0)
	type_text.add_child(UiKit.label(mission_type["name"], 19, Color(0.6, 0.9, 1.0), "bold"))
	type_text.add_child(UiKit.label("%s  •  %s form" % [mission_type["genre"], mission_type["form"].capitalize()], 13, Color(0.6, 0.7, 0.85)))
	type_row.add_child(type_text)
	_info.add_child(type_row)
	_info.add_child(UiKit.wrapped(node["need"], 16, Color(0.85, 0.9, 1.0)))
	if node.get("hazard", false):
		_info.add_child(UiKit.label("HAZARD ROUTE", 17, Color(1, 0.4, 0.4), "bold"))
		_info.add_child(UiKit.wrapped("Much harder than its neighbours, and pays double blueprints. Optional.", 14, Color(1, 0.75, 0.7)))
	_info.add_child(UiKit.label("You'll face", 14, Color(0.6, 0.7, 0.85)))
	var boss_line := "Boss: %s   Mini-boss: %s" % [GuideData.BOSSES[BossRoster.for_node(node, "boss")][0], GuideData.BOSSES[BossRoster.for_node(node, "miniboss")][0]]
	_info.add_child(UiKit.wrapped(boss_line, 14, Color(1, 0.6, 0.5)))
	for enemy_trait in MissionData.traits_for(node, Save.data["enemies_unlocked"]):
		_info.add_child(UiKit.wrapped("- " + enemy_trait, 14, Color(1, 0.8, 0.6)))
	var danger_row := HBoxContainer.new()
	danger_row.add_child(UiKit.label("Danger", 15, Color(0.7, 0.8, 0.9)))
	for i in 5:
		danger_row.add_child(IconView.make("danger", 24, Color(1, 0.4, 0.35) if i < node["danger"] else Color(0.25, 0.28, 0.35)))
	_info.add_child(danger_row)
	if node["modifier"] != "":
		var modifier: Dictionary = MissionData.MODIFIERS[node["modifier"]]
		_info.add_child(UiKit.label("Special condition: " + modifier["name"], 17, Color(1, 0.75, 0.35), "bold"))
		_info.add_child(UiKit.wrapped(modifier["text"], 14, Color(0.9, 0.8, 0.65)))
	var reward_row := HBoxContainer.new()
	reward_row.add_child(IconView.make(node["reward_tech"], 28, TechData.element_color(node["reward_tech"])))
	var reward_text := VBoxContainer.new()
	reward_text.add_theme_constant_override("separation", 0)
	reward_text.add_child(UiKit.label("Blueprints", 13, Color(0.6, 0.7, 0.85)))
	reward_text.add_child(UiKit.label(TechData.TECH[node["reward_tech"]]["name"], 17, TechData.element_color(node["reward_tech"]), "bold"))
	reward_row.add_child(reward_text)
	_info.add_child(reward_row)
	if node["prize"] != "":
		var claimed: bool = Save.data["prizes_claimed"].has(node_id)
		_info.add_child(UiKit.label("PRIZE" + (" (claimed)" if claimed else ""), 16, Art.GOLD, "bold"))
		_info.add_child(UiKit.wrapped(node["prize_text"], 15, Color(1, 0.9, 0.7)))
	_info.add_child(UiKit.spacer(6))
	var available := star_map.is_available(node_id, Save.is_cleared)
	if Save.is_cleared(node_id):
		_info.add_child(UiKit.label("Cleared — fly it again any time.", 14, Color(0.5, 1.0, 0.65)))
	if available:
		_info.add_child(UiKit.button("LAUNCH", func(): _launch(node), "Launch %s" % node_id, true))
	else:
		_info.add_child(UiKit.wrapped("Out of reach. Clear a planet linked to this one first.", 14, Color(0.65, 0.7, 0.8)))


# ---------------------------------------------------------------- hangar

func _build_hangar_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	column.add_child(UiKit.label("FRAME", 20, Color(0.6, 0.9, 1.0), "title"))
	var frames_row := HBoxContainer.new()
	frames_row.add_theme_constant_override("separation", 12)
	column.add_child(frames_row)
	for frame_id in FrameData.FRAMES:
		frames_row.add_child(_frame_card(frame_id))
	column.add_child(UiKit.label("LOADOUT", 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.wrapped("Only the main weapon is online when a mission starts. Level-ups and Salvage Crates bring the rest online.", 14, Color(0.65, 0.75, 0.88)))
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 10)
	column.add_child(slots_row)
	for slot_index in TechData.SLOTS.size():
		slots_row.add_child(_slot_card(slot_index))
	if picker_slot < 0:
		return scroll
	# The picker opens as a pop-up over the hangar, so it's never off the bottom of the screen.
	var page_root := Control.new()
	page_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	page_root.add_child(scroll)
	var popup := Overlays._floating(_tech_picker(picker_slot))
	popup.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed:
			picker_slot = -1
			_rebuild())
	page_root.add_child(popup)
	return page_root


func _frame_card(frame_id: String) -> Control:
	var data := FrameData.get_frame(frame_id)
	var unlocked: bool = Save.data["frames_unlocked"].has(frame_id)
	var selected: bool = Save.data["frame"] == frame_id
	var card := UiKit.panel(Color(0.06, 0.1, 0.16) if selected else Color(0.04, 0.06, 0.1), data["hull"] if selected else Color(0.2, 0.3, 0.42))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var art := FramePreview.new()
	art.frame_id = frame_id
	art.locked = not unlocked
	art.custom_minimum_size = Vector2(0, 130)
	column.add_child(art)
	column.add_child(UiKit.label(data["name"], 22, data["hull"] if unlocked else Color(0.5, 0.55, 0.65), "title"))
	column.add_child(UiKit.wrapped(data["tagline"], 13, Color(0.7, 0.8, 0.9)))
	column.add_child(UiKit.label("Armor %d   Shield %d   Speed %d" % [data["armor"], data["shield"], data["speed"]], 13, Color(0.6, 0.75, 0.9)))
	column.add_child(UiKit.label(data["trait_name"], 15, Art.GOLD, "bold"))
	column.add_child(UiKit.wrapped(data["trait_text"], 13, Color(0.85, 0.8, 0.65)))
	if not unlocked:
		column.add_child(UiKit.wrapped("Locked. " + data["unlock"], 13, Color(1, 0.6, 0.5)))
	elif not selected:
		column.add_child(UiKit.button("Fly this frame", func():
			Save.select_frame(frame_id)
			_rebuild(), "Hangar: select %s" % frame_id))
	else:
		column.add_child(UiKit.label("Selected", 15, Color(0.5, 1.0, 0.65), "bold"))
	return card


func _slot_card(slot_index: int) -> Control:
	var slot: String = TechData.SLOTS[slot_index]
	var tech_id: String = Save.data["loadout"][slot_index]
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(150, 150)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if picker_slot == slot_index:
		button.add_theme_stylebox_override("normal", UiKit._box(Color(0.12, 0.2, 0.3), Color(0.6, 0.95, 1.0), 3))
	button.pressed.connect(func():
		PlayLog.button("Hangar: slot %d (%s)" % [slot_index, slot])
		Sound.play("ui")
		picker_slot = -1 if picker_slot == slot_index else slot_index
		_rebuild())
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	for new_id in Save.data["new_unlocks"]:
		if TechData.TECH.has(new_id) and TechData.TECH[new_id]["slot"] == slot:
			button.add_child(NewDot.new())
			break
	var slot_label := UiKit.label(TechData.SLOT_NAMES[slot].to_upper(), 12, Color(0.55, 0.7, 0.85), "bold")
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(slot_label)
	if tech_id == "":
		var empty := UiKit.label("empty — tap", 14, Color(0.5, 0.55, 0.65))
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(empty)
	else:
		var icon := IconView.make(tech_id, 54, TechData.element_color(tech_id))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		var name := UiKit.label(TechData.TECH[tech_id]["name"], 15, Color(1, 1, 1), "bold")
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(name)
		var mk := UiKit.label("Mk %d" % Save.tech_mk(tech_id), 13, Art.GOLD)
		mk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(mk)
	return button


func _tech_picker(slot_index: int) -> Control:
	var slot: String = TechData.SLOTS[slot_index]
	var panel := UiKit.panel(Color(0.04, 0.07, 0.12, 0.98), Color(0.5, 0.85, 1.0))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	column.custom_minimum_size = Vector2(640, 0)
	panel.add_child(column)
	var header := HBoxContainer.new()
	var heading := UiKit.label("Choose %s" % TechData.SLOT_NAMES[slot], 20, Color(0.6, 0.9, 1.0), "bold")
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(heading)
	header.add_child(UiKit.button("Close", func():
		picker_slot = -1
		_rebuild(), "Hangar: close picker"))
	column.add_child(header)
	var list_scroll := ScrollContainer.new()
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.custom_minimum_size = Vector2(640, 420)
	column.add_child(list_scroll)
	var grid := GridContainer.new()
	grid.columns = 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_scroll.add_child(grid)
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	if slot_index > 0:
		grid.add_child(UiKit.button("Leave empty", func():
			Save.equip(slot_index, "")
			picker_slot = -1
			_rebuild(), "Hangar: empty slot %d" % slot_index))
	for tech_id in TechData.ids_for_slot(slot):
		var mk := Save.tech_mk(tech_id)
		var tech: Dictionary = TechData.TECH[tech_id]
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(IconView.make(tech_id, 40, TechData.element_color(tech_id) if mk > 0 else Color(0.35, 0.4, 0.5)))
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_child(UiKit.label("%s  %s%s" % [tech["name"], ("Mk %d" % mk) if mk > 0 else "(locked)", "   NEW" if Save.is_new(tech_id) else ""], 16,
			Color(0.5, 1.0, 0.55) if Save.is_new(tech_id) else (Color(1, 1, 1) if mk > 0 else Color(0.5, 0.55, 0.65)), "bold"))
		text.add_child(UiKit.wrapped(tech["text"], 13, Color(0.7, 0.8, 0.9)))
		text.add_child(UiKit.wrapped("Forks: %s / %s" % [tech["forks"]["a"]["name"], tech["forks"]["b"]["name"]], 12, Color(0.8, 0.6, 1.0)))
		row.add_child(text)
		if mk > 0:
			row.add_child(UiKit.button("Equip", func():
				Save.equip(slot_index, tech_id)
				picker_slot = -1
				_rebuild(), "Hangar: equip %s in slot %d" % [tech_id, slot_index]))
		grid.add_child(row)
	return panel


# ---------------------------------------------------------------- R&D

func _build_rnd_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)
	scroll.add_child(column)
	column.add_child(UiKit.label("RESEARCH & DEVELOPMENT", 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.wrapped("Each planet's card on the Star Map shows which tech it rewards. More in the Guide to Guardians.", 14, Color(0.6, 0.7, 0.84)))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	column.add_child(grid)
	for tech_id in TechData.TECH:
		grid.add_child(_rnd_card(tech_id))
	return scroll


func _rnd_card(tech_id: String) -> Control:
	var tech: Dictionary = TechData.TECH[tech_id]
	var mk := Save.tech_mk(tech_id)
	var have := Save.blueprints(tech_id)
	var need := TechData.blueprints_for_next_mk(mk)
	var color := TechData.element_color(tech_id)
	var card := UiKit.panel(Color(0.05, 0.08, 0.13), color.darkened(0.4) if mk > 0 else Color(0.18, 0.22, 0.3))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	card.add_child(column)
	var head := HBoxContainer.new()
	head.add_child(IconView.make(tech_id, 44, color if mk > 0 else Color(0.4, 0.45, 0.55)))
	var title := VBoxContainer.new()
	title.add_theme_constant_override("separation", 0)
	title.add_child(UiKit.label(tech["name"], 17, Color(1, 1, 1) if mk > 0 else Color(0.6, 0.65, 0.75), "bold"))
	title.add_child(UiKit.label("%s  •  %s" % [TechData.SLOT_NAMES[tech["slot"]], ("Mk %d" % mk) if mk > 0 else "Locked"], 12, Art.GOLD if mk > 0 else Color(0.55, 0.6, 0.7)))
	head.add_child(title)
	column.add_child(head)
	column.add_child(UiKit.wrapped(tech["text"], 14, Color(0.72, 0.82, 0.92)))
	var sources := []
	for source in tech["blueprint_from"]:
		sources.append(MissionData.TYPES[source]["name"])
	column.add_child(UiKit.label("Found on: %s" % ", ".join(sources), 13, Color(0.55, 0.7, 0.85)))
	if need > 0:
		var progress := ProgressBar.new()
		progress.max_value = need
		progress.value = mini(have, need)
		progress.show_percentage = false
		progress.custom_minimum_size = Vector2(0, 10)
		column.add_child(progress)
		column.add_child(UiKit.label("%d / %d blueprints" % [have, need], 12, Color(0.6, 0.8, 1.0)))
		var action := "Unlock" if mk == 0 else "Upgrade to Mk %d" % (mk + 1)
		var button := UiKit.button(action, func():
			if Save.upgrade_tech(tech_id):
				Sound.play("upgrade")
				_rebuild(), "R&D: %s %s" % [action, tech_id], have >= need)
		button.disabled = have < need
		column.add_child(button)
	else:
		column.add_child(UiKit.label("Maxed: Mk %d" % mk, 13, Art.GOLD, "bold"))
	return card


# ---------------------------------------------------------------- records

## Milestones (GDD 9D): what's been earned, what's still out there. Hidden ones stay "???" until earned.
func _build_records_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	var earned: Dictionary = Save.data["milestones"]
	column.add_child(UiKit.label("RECORDS  %d / %d" % [earned.size(), MilestoneData.MILESTONES.size()], 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.wrapped("Milestones pay out whether a mission was won or lost. Some bring new enemies into the galaxy.", 15, Color(0.65, 0.75, 0.88)))
	var counters: Dictionary = Save.data["counters"]
	for milestone in MilestoneData.MILESTONES:
		var done := earned.has(milestone["id"])
		var hidden: bool = milestone.get("hidden", false) and not done
		var row := UiKit.panel(Color(0.05, 0.1, 0.08) if done else Color(0.04, 0.06, 0.1), Art.GOLD if done else Color(0.2, 0.28, 0.38))
		var text := VBoxContainer.new()
		row.add_child(text)
		text.add_child(UiKit.label(("DONE  " if done else "") + ("???" if hidden else milestone["name"]), 17, Art.GOLD if done else Color(1, 1, 1), "bold"))
		text.add_child(UiKit.wrapped("A rare feat. Keep playing differently and you might stumble on it." if hidden else milestone["text"], 14, Color(0.72, 0.82, 0.92)))
		if milestone.has("counter") and not done:
			text.add_child(UiKit.label("%d / %d" % [int(counters.get(milestone["counter"], 0)), milestone["goal"]], 13, Color(0.5, 0.85, 1.0)))
		if not hidden:
			text.add_child(UiKit.label("Reward: " + Milestones.reward_text(milestone), 13, Color(0.6, 1.0, 0.7)))
		column.add_child(row)
	return scroll


# ---------------------------------------------------------------- guide

## The Guide to Guardians: lore and how things work are always there; enemies, bosses, tech and fusions
## fill in as you meet, beat or unlock them, so the guide is also a record of how far you've come.
func _build_guide_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	scroll.add_child(column)
	column.add_child(UiKit.label("GUIDE TO GUARDIANS", 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.wrapped("Enemies, bosses, tech and fusions fill in as you meet, beat or unlock them.", 14, Color(0.6, 0.7, 0.84)))
	var counters: Dictionary = Save.data["counters"]
	var lore_color := TechData.ELEMENT_COLORS["mawjig"]
	_guide_section(column, "LORE", GuideData.LORE.map(func(entry): return [entry[0], entry[1], lore_color]), 0)
	_guide_section(column, "HOW IT WORKS", GuideData.HOW_IT_WORKS.map(func(entry): return [entry[0], entry[1], Color(0.6, 0.9, 1.0)]), 0)
	var resonance := []
	for element in UpgradeData.ELEMENTS:
		var info: Dictionary = UpgradeData.RESONANCE[element]
		var lines := []
		for i in info["tiers"].size():
			lines.append("%s  %s: %s" % [UpgradeOffers.ROMAN[i + 1], info["tiers"][i][0], info["tiers"][i][1]])
		resonance.append([info["name"], "\n".join(lines), TechData.ELEMENT_COLORS[element]])
	_guide_section(column, "RESONANCE", resonance, 0)
	var tech := []
	for tech_id in TechData.TECH:
		if Save.tech_mk(tech_id) > 0:
			var data: Dictionary = TechData.TECH[tech_id]
			var forks: Dictionary = data["forks"]
			tech.append([data["name"], "%s\nFork %s: %s\nFork %s: %s" % [data["text"], forks["a"]["name"], forks["a"]["text"],
				forks["b"]["name"], forks["b"]["text"]], TechData.element_color(tech_id)])
	_guide_section(column, "TECH", tech, TechData.TECH.size() - tech.size())
	var fusions := []
	for fusion_id in UpgradeData.FUSIONS:
		var fusion: Dictionary = UpgradeData.FUSIONS[fusion_id]
		if fusion["needs"].all(func(needed): return Save.tech_mk(needed) > 0):
			fusions.append([fusion["name"], "%s + %s: %s" % [TechData.TECH[fusion["needs"][0]]["name"], TechData.TECH[fusion["needs"][1]]["name"], fusion["text"]], Art.GOLD])
	_guide_section(column, "FUSIONS", fusions, UpgradeData.FUSIONS.size() - fusions.size())
	var enemies := []
	for kind in GuideData.ENEMIES:
		if int(counters.get("kill_" + kind, 0)) > 0:
			enemies.append([EnemyData.ENEMIES[kind]["name"], GuideData.ENEMIES[kind], EnemyData.ENEMIES[kind]["color"]])
	_guide_section(column, "ENEMIES", enemies, GuideData.ENEMIES.size() - enemies.size())
	var bosses := []
	for boss_look in GuideData.BOSSES:
		if int(counters.get("boss_" + boss_look, 0)) > 0:
			bosses.append([GuideData.BOSSES[boss_look][0], GuideData.BOSSES[boss_look][1], Color(1, 0.55, 0.45)])
	_guide_section(column, "BOSSES", bosses, GuideData.BOSSES.size() - bosses.size())
	var conditions := []
	for modifier_id in MissionData.MODIFIERS:
		if modifier_id != "":
			conditions.append([MissionData.MODIFIERS[modifier_id]["name"], MissionData.MODIFIERS[modifier_id]["text"], Color(1, 0.8, 0.45)])
	_guide_section(column, "SPECIAL CONDITIONS", conditions, 0)
	return scroll


## One guide section: a heading, its entries two to a row, and how many are still undiscovered.
func _guide_section(column: VBoxContainer, heading: String, entries: Array, undiscovered: int) -> void:
	column.add_child(UiKit.spacer(4))
	column.add_child(UiKit.label(heading, 16, Art.GOLD, "bold"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for entry in entries:
		var box := UiKit.panel(Color(0.04, 0.07, 0.11), Color(entry[2]).darkened(0.45))
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", 2)
		box.add_child(text)
		text.add_child(UiKit.label(entry[0], 16, entry[2], "bold"))
		text.add_child(UiKit.wrapped(entry[1], 13, Color(0.75, 0.83, 0.92)))
		grid.add_child(box)
	if undiscovered > 0:
		column.add_child(UiKit.label("%d still to discover" % undiscovered, 13, Color(0.5, 0.58, 0.7)))


# ---------------------------------------------------------------- settings

func _build_settings_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	column.add_child(UiKit.label("SETTINGS", 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(_slider("Music", "music"))
	column.add_child(_slider("Sound effects", "sfx"))
	column.add_child(_toggle("Full screen (iPad Safari: applies on your next tap)", "fullscreen"))
	column.add_child(_threat_picker())
	column.add_child(_toggle("Screen shake", "screen_shake"))
	column.add_child(_toggle("Play log", "play_log"))
	column.add_child(UiKit.wrapped("The play log records what you tap and how missions go, so it can be sent and read like a replay. Nothing leaves this device unless you save the file and send it.", 13, Color(0.65, 0.75, 0.88)))
	var log_row := HBoxContainer.new()
	log_row.add_theme_constant_override("separation", 10)
	var log_status := UiKit.label("", 13, Color(0.5, 1, 0.65))
	log_row.add_child(UiKit.button("Save play log file", func():
		var saved := PlayLog.save_file()
		log_status.text = "Saved: %s" % saved, "Settings: save play log"))
	log_row.add_child(log_status)
	column.add_child(log_row)
	column.add_child(UiKit.label("VERSION", 18, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.label("You're on " + BuildInfo.label(), 14, Color(0.7, 0.8, 0.92)))
	var update_row := HBoxContainer.new()
	update_row.add_theme_constant_override("separation", 10)
	var update_note := UiKit.wrapped("Clears the offline copy and reloads the newest build. Your save is kept.", 13, Color(0.6, 0.7, 0.85))
	update_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	update_row.add_child(UiKit.button("Get the latest version", func():
		PlayLog.note("update", "Cleared the offline copy and reloaded (was %s)" % BuildInfo.label())
		Save.write()
		update_note.text = "Reloading..."
		Browser.clear_cache_and_reload(), "Settings: get the latest version"))
	update_row.add_child(update_note)
	column.add_child(update_row)
	column.add_child(UiKit.label("DEBUG CONSOLE", 18, Color(1, 0.75, 0.35), "title"))
	admin = AdminConsole.new()
	admin.star_map = star_map
	admin.changed.connect(func(): _rebuild())
	admin.launch_test.connect(func(mission_type): launch_requested.emit("test:" + mission_type, {}))
	column.add_child(admin.build())
	column.add_child(UiKit.label("RESET", 18, Color(1, 0.4, 0.4), "title"))
	var reset_button := UiKit.button("Reset all progress", func(): pass, "Settings: reset (first tap)")
	reset_button.pressed.connect(func():
		if reset_button.text.begins_with("Tap again"):
			PlayLog.note("save", "Progress reset by player")
			Save.reset()
			get_tree().reload_current_scene()
		else:
			reset_button.text = "Tap again to really reset everything")
	column.add_child(reset_button)
	column.add_child(UiKit.label("Genre Legends " + BuildInfo.label(), 12, Color(0.45, 0.55, 0.65)))
	return scroll


func _slider(label: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var name := UiKit.label(label, 17)
	name.custom_minimum_size = Vector2(180, 0)
	row.add_child(name)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = Save.setting(key)
	slider.custom_minimum_size = Vector2(300, 40)
	slider.value_changed.connect(func(value):
		Save.data["settings"][key] = value
		Sound.refresh_volume())
	slider.drag_ended.connect(func(_changed):
		Save.write()
		PlayLog.note("tap", "%s volume set to %d%%" % [label, int(slider.value * 100)]))
	row.add_child(slider)
	return row


func _toggle(label: String, key: String) -> Control:
	var button := UiKit.button("", func(): pass, "Settings: %s" % label)
	var refresh := func(): button.text = "%s: %s" % [label, "On" if Save.setting(key) else "Off"]
	refresh.call()
	button.pressed.connect(func():
		Save.set_setting(key, not Save.setting(key))
		if key == "fullscreen":
			Browser.set_fullscreen_wanted(Save.setting(key))
			if not Save.setting(key):
				Browser.leave_fullscreen()
		refresh.call())
	return button


## Threat: how hard missions hit. Shown as "Name: Default > Other" options (labelling guide 5).
func _threat_picker() -> Control:
	var column := VBoxContainer.new()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.add_child(UiKit.label("Threat", 17))
	var note := UiKit.wrapped("", 14, Color(0.7, 0.8, 0.92))
	for level in ["standard", "veteran", "casual"]:
		var info: Dictionary = MissionData.THREAT[level]
		var chosen: bool = Save.setting("threat") == level
		var button := UiKit.button(info["name"], func():
			Save.set_setting("threat", level)
			_rebuild(), "Settings: threat %s" % level, chosen)
		button.custom_minimum_size = Vector2(150, 48)
		row.add_child(button)
		if chosen:
			note.text = info["text"]
	column.add_child(row)
	column.add_child(note)
	return column


## A small drawing of a frame for the hangar cards: ship and mech side by side.
class FramePreview:
	extends Control
	var frame_id := "vanguard"
	var locked := false
	var time := 0.0

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5
		if locked:
			# A dark silhouette to tease what's coming, with the lock on top.
			modulate = Color(0.25, 0.27, 0.32)
			FrameArt.draw_frame(self, frame_id, "ship", c + Vector2(-50, 0), -PI * 0.5, time, {"speed": 0.2, "scale": 1.7})
			FrameArt.draw_frame(self, frame_id, "mech", c + Vector2(50, 0), -PI * 0.5, time, {"scale": 1.7})
			IconPainter.draw(self, "lock", Rect2(c + Vector2(-16, 26), Vector2(32, 32)), Color(1.6, 1.6, 1.8))
			return
		Art.draw_glow(self, c + Vector2(-50, 0), 40.0, Art.with_alpha(FrameData.get_frame(frame_id)["hull"], 0.25))
		# The selected frame wears your loadout, so the hangar shows what you'll fly.
		var gear: Array = GearArt.loadout_gear(Save.data["loadout"], 3) if Save.data["frame"] == frame_id else []
		FrameArt.draw_frame(self, frame_id, "ship", c + Vector2(-50, 0), -PI * 0.5, time, {"speed": 0.4, "scale": 1.7, "gear": gear})
		FrameArt.draw_frame(self, frame_id, "mech", c + Vector2(50, 0), -PI * 0.5 + sin(time) * 0.4, time, {"speed": 0.6, "scale": 1.7, "gear": gear})


## A pulsing green dot in a control's corner: something new is waiting there (GDD 9C).
class NewDot:
	extends Control
	var time := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	func _process(delta: float) -> void:
		time += delta
		queue_redraw()

	func _draw() -> void:
		var at := Vector2(size.x - 12, 12)
		var pulse := 0.6 + 0.4 * sin(time * 5.0)
		draw_circle(at, 9.0 + pulse * 3.0, Color(0.3, 1.0, 0.45, 0.25 * pulse))
		draw_circle(at, 7.0, Color(0.35, 1.0, 0.5))
