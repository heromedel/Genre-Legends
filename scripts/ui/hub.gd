class_name Hub
extends Control
## The command center (GDD 5A): a console menu with text and icons. Tabs along the top switch pages:
## Star Map (pick where to go), Hangar (frame and loadout), R&D (spend blueprints), Guide, Records and
## Settings. The tabs sit on top, not in a side rail, so the star map gets the screen's full width (heromedel).

## event: what a route event (RouteEvents) leaves for the mission, or {} for a quiet trip.
signal launch_requested(node_id: String, event: Dictionary)
## The player chose to continue the mission the browser closed on (main rebuilds and fast-forwards it).
## abandon: settle it as abandoned instead (fast-forwarded first, so the partial rewards of a loss still pay).
signal resume_requested(abandon: bool)

var star_map: StarMap
var page := "map"
var content: Control
var tab_buttons := {}
var tab_dots := {}              # page id -> its green dot, refreshed on every rebuild
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
	var main := VBoxContainer.new()
	main.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main.add_theme_constant_override("separation", 0)
	add_child(main)
	main.add_child(_build_top_bar())
	content = MarginContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		content.add_theme_constant_override("margin_" + side, 14)
	main.add_child(content)
	show_page(page)
	Sound.play_music("hub")
	_show_radio_queue()
	_offer_saved_mission()


## A mission the browser closed on: continue it, or let it go. A checkpoint from an older build can't be
## replayed (the game plays differently), so the player is told instead.
func _offer_saved_mission() -> void:
	var checkpoint := Save.read_checkpoint()
	if checkpoint.is_empty() or not checkpoint.has("launch"):
		return
	var launch: Dictionary = checkpoint["launch"]
	var planet: String = launch["node"].get("name", "a planet")
	if launch.get("build", "") != BuildInfo.label():
		Save.clear_checkpoint()
		_confirm("Mission lost in the update", "You left %s mid-mission, but the game has updated since, so it can't be picked up again." % planet, "OK", func(): pass, "")
		return
	_confirm("Mission in progress", "You left %s mid-mission. Pick up where you left off?" % planet, "Continue",
		func(): resume_requested.emit(false), "Abandon", func(): resume_requested.emit(true))


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


## A pop-up that asks before doing something you can't take back: a title, what will happen, and two buttons.
func _confirm(title: String, text: String, confirm_label: String, on_confirm: Callable, cancel_label: String = "Cancel", on_cancel: Callable = Callable()) -> void:
	var box := UiKit.panel(Color(0.03, 0.07, 0.12, 0.98), Color(1.0, 0.75, 0.35))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(520, 0)
	column.add_theme_constant_override("separation", 12)
	box.add_child(column)
	column.add_child(UiKit.label(title, 22, Color(1.0, 0.8, 0.45), "title"))
	column.add_child(UiKit.wrapped(text, 17, Color(1, 1, 1)))
	var popup := Overlays._floating(box)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)
	if cancel_label != "":
		buttons.add_child(UiKit.button(cancel_label, func():
			popup.queue_free()
			if on_cancel.is_valid():
				on_cancel.call(), "%s: %s" % [title, cancel_label]))
	buttons.add_child(UiKit.button(confirm_label, func():
		popup.queue_free()
		on_confirm.call(), "%s: %s" % [title, confirm_label], true))
	add_child(popup)


## On the way to a planet something may happen (RouteEvents): a choice, its outcome, then the launch.
func _launch(node: Dictionary) -> void:
	var missions_flown: int = Save.data["stats"]["missions"]
	var event_id := RouteEvents.roll(node, missions_flown, Save.data["map_seed"], Save.data["last_event"])
	if event_id == "":
		launch_requested.emit(node["id"], {})
		return
	Save.data["last_event"] = event_id
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
		if not RouteEvents.offered(choice, Save.data["loadout"]):
			continue
		var affordable: bool = _largest_blueprint_pile() >= int(choice.get("needs_blueprints", 0)) \
			and Save.data["crystals"] >= int(choice.get("needs_crystals", 0))
		# Just the action: what each choice leads to is for the player to learn or intuit. An option your loadout
		# unlocks names the tech that makes it possible.
		var label: String = choice["label"]
		var needs: Array = choice.get("needs_tech", [])
		if not needs.is_empty():
			var having: Array = needs.filter(func(t): return Save.data["loadout"].has(t))
			label = "%s: %s" % [TechData.TECH[having[0]]["name"], label]
		var button := UiKit.button(label, func():
			var outcome := RouteEvents.resolve(event_id, i, node["id"], missions_flown, Save.data["map_seed"])
			_route_outcome(popup, column, node, event, choice, outcome), "Event %s: %s" % [event_id, choice["label"]])
		button.disabled = not affordable
		if not needs.is_empty():
			# Your build opened this option: it stands out in the tech's cyan.
			button.add_theme_color_override("font_color", Color(0.5, 0.95, 1.0))
			button.add_theme_stylebox_override("normal", UiKit._box(Color(0.04, 0.12, 0.18), Color(0.4, 0.85, 1.0), 2))
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
		var ids := TechData.findable_ids()
		for n in int(effects["blueprints_random"]):
			Save.add_blueprints(ids[randi() % ids.size()], 1)
	if effects.has("crystals"):
		if int(effects["crystals"]) > 0:
			Save.add_crystals(int(effects["crystals"]), "route event")
		else:
			Save.data["crystals"] = maxi(Save.data["crystals"] + int(effects["crystals"]), 0)
	Save.data["frame_blueprints"] += int(effects.get("frame_blueprints", 0))
	Save.data["free_dives"] += int(effects.get("free_dive", 0))
	if effects.has("blueprints_planet"):
		Save.add_blueprints(node["reward_tech"], int(effects["blueprints_planet"]))
	if effects.has("spend_blueprints"):
		var pile := _largest_blueprint_pile_id()
		Save.add_blueprints(pile, -int(effects["spend_blueprints"]))
	Save.write()
	_refresh_top_bar()
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


## One tab per page: an icon and its name, in a row across the top bar.
func _build_tabs() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	# Settings is the gear alone, so seven tabs fit an iPad's width.
	for entry in [["map", "map", "STAR MAP"], ["hangar", "hangar", "HANGAR"], ["rnd", "lab", "R&D"], ["depot", "depot", "DEPOT"], ["guide", "guide", "GUIDE"], ["records", "prize", "RECORDS"], ["settings", "settings", ""]]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(108 if entry[2] != "" else 50, 46)
		button.focus_mode = Control.FOCUS_NONE
		var page_id: String = entry[0]
		button.pressed.connect(func():
			PlayLog.button("Tab: %s" % page_id)
			Sound.play("ui")
			show_page(page_id))
		var box := HBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		box.add_theme_constant_override("separation", 6)
		var icon := IconView.make(entry[1], 22, Color(0.6, 0.9, 1.0))
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		if entry[2] != "":
			var text := UiKit.label(entry[2], 13, Color(0.7, 0.85, 1.0), "bold")
			text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(text)
		button.add_child(box)
		row.add_child(button)
		tab_buttons[page_id] = button
		if page_id in ["hangar", "rnd", "depot"]:
			var dot := NewDot.new()
			button.add_child(dot)
			tab_dots[page_id] = dot
	return row


## Green dots (GDD 9C): Hangar while new tech waits to be equipped, R&D while something can be unlocked
## or upgraded. Refreshed on every rebuild so they clear the moment you act on them.
func _refresh_tab_dots() -> void:
	tab_dots["hangar"].visible = not Save.data["new_unlocks"].is_empty()
	tab_dots["rnd"].visible = TechData.TECH.keys().any(func(tech_id): return Save.can_upgrade(tech_id))
	tab_dots["depot"].visible = Save.checkin_ready() or Save.data["crystals"] >= DepotData.DIVE_COST or Save.data["free_dives"] > 0 or not Save.data["dive_wrecks"].is_empty()


func _build_top_bar() -> Control:
	var bar := PanelContainer.new()
	bar.add_theme_stylebox_override("panel", UiKit._box(Color(0.04, 0.06, 0.1), Color(0.15, 0.24, 0.35), 0, 0))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	bar.add_child(row)
	row.add_child(UiKit.label("GL", 26, Art.GOLD, "title"))
	row.add_child(_build_tabs())
	var filler := Control.new()
	filler.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(filler)
	# Who you are and how far you've come, stacked small so the tabs keep their room.
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", -2)
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(stats)
	_frame_label = UiKit.label("", 14, Color.WHITE, "bold")
	_frame_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_frame_label)
	_progress_label = UiKit.label("", 13, Color(0.6, 0.78, 0.95))
	_progress_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats.add_child(_progress_label)
	_refresh_top_bar()
	return bar


var _frame_label: Label
var _progress_label: Label


## The top bar's frame and progress, refreshed on every rebuild so a check-in or a new frame shows at once.
func _refresh_top_bar() -> void:
	var frame := FrameData.get_frame(Save.data["frame"])
	var total_blueprints := 0
	for tech_id in Save.data["blueprints"]:
		total_blueprints += int(Save.data["blueprints"][tech_id])
	_frame_label.text = "Frame: %s" % frame["name"]
	_frame_label.add_theme_color_override("font_color", frame["hull"])
	_progress_label.text = "Cleared %d  •  Blueprints %d  •  Crystals %d" % [Save.data["cleared"].size(), total_blueprints, Save.data["crystals"]]


func show_page(page_id: String) -> void:
	page = page_id
	last_haul = {}
	picker_slot = -1
	PlayLog.set_screen(page_id)
	_rebuild()


## Rebuilds the current page from Save, keeping in-page state such as the open slot picker.
func _rebuild() -> void:
	var page_id := page
	for key in tab_buttons:
		tab_buttons[key].add_theme_stylebox_override("normal", UiKit._box(Color(0.12, 0.2, 0.3) if key == page_id else Color(0.06, 0.09, 0.14), Color(0.5, 0.85, 1.0) if key == page_id else Color(0.2, 0.3, 0.42), 2))
	_refresh_tab_dots()
	if _progress_label != null:
		_refresh_top_bar()
	for child in content.get_children():
		child.queue_free()
	match page_id:
		"map": content.add_child(_build_map_page())
		"hangar": content.add_child(_build_hangar_page())
		"rnd": content.add_child(_build_rnd_page())
		"settings": content.add_child(_build_settings_page())
		"guide": content.add_child(_build_guide_page())
		"records": content.add_child(_build_records_page())
		"depot": content.add_child(_build_depot_page())


# ---------------------------------------------------------------- star map

var _map_view: StarMapView
var _info: HBoxContainer


## The map across the full width, and the selected planet's card as a strip underneath it.
func _build_map_page() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	var frame := UiKit.panel(Color(0.02, 0.03, 0.06), Color(0.2, 0.32, 0.46))
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(frame)
	_map_view = StarMapView.new()
	_map_view.star_map = star_map
	_map_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_view.node_selected.connect(_on_node_selected)
	frame.add_child(_map_view)
	var info_panel := UiKit.panel()
	info_panel.custom_minimum_size = Vector2(0, 204)
	column.add_child(info_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Most planets fit; the rare one with more to say still scrolls, without a bar eating the width.
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	scroll.custom_minimum_size = Vector2(0, 184)
	info_panel.add_child(scroll)
	_info = HBoxContainer.new()
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info.add_theme_constant_override("separation", 28)
	scroll.add_child(_info)
	if selected_node == "" or star_map.get_node(selected_node).is_empty():
		selected_node = _frontier_node()
	_map_view.selected = selected_node
	_fill_info(selected_node)
	return column


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
	# Three columns: which planet it is, what you'll face there, and what it pays (with LAUNCH).
	var identity := _info_column(1.25)
	var threat := _info_column(1.25)
	var payout := _info_column(0.9)
	var mission_type: Dictionary = MissionData.TYPES[node["type"]]
	var region_name: String = star_map.regions[node["region"]]["name"]
	identity.add_child(UiKit.label(region_name.to_upper(), 13, Color(0.5, 0.65, 0.8), "bold"))
	identity.add_child(UiKit.label(node["name"], 25, Color(1, 1, 1), "title"))
	if node["branch"] != "":
		identity.add_child(UiKit.label(node["branch_name"], 16, Art.GOLD, "bold"))
	var type_row := HBoxContainer.new()
	type_row.add_child(IconView.make(node["type"], 30, Color(0.6, 0.9, 1.0)))
	var type_text := VBoxContainer.new()
	type_text.add_theme_constant_override("separation", 0)
	type_text.add_child(UiKit.label(mission_type["name"], 19, Color(0.6, 0.9, 1.0), "bold"))
	type_text.add_child(UiKit.label("%s  •  %s form" % [mission_type["genre"], mission_type["form"].capitalize()], 13, Color(0.6, 0.7, 0.85)))
	type_row.add_child(type_text)
	identity.add_child(type_row)
	identity.add_child(UiKit.wrapped(node["need"], 16, Color(0.85, 0.9, 1.0)))
	if node.get("chain", "") != "":
		var next_type: Dictionary = MissionData.TYPES[node["chain"]]
		identity.add_child(UiKit.wrapped("CHAINED: partway through, it becomes a %s (%s form)." % [next_type["name"], next_type["form"]], 15, Color(0.6, 1.0, 0.8)))
	if node.get("hazard", false):
		identity.add_child(UiKit.label("HAZARD ROUTE", 17, Color(1, 0.4, 0.4), "bold"))
		identity.add_child(UiKit.wrapped("Much harder than its neighbours, and pays double blueprints. Optional.", 14, Color(1, 0.75, 0.7)))
	threat.add_child(UiKit.label("You'll face", 14, Color(0.6, 0.7, 0.85)))
	var boss_line := "Boss: %s   Mini-boss: %s" % [GuideData.BOSSES[BossRoster.for_node(node, "boss")][0], GuideData.BOSSES[BossRoster.for_node(node, "miniboss")][0]]
	threat.add_child(UiKit.wrapped(boss_line, 14, Color(1, 0.6, 0.5)))
	for enemy_trait in MissionData.traits_for(node, Save.data["enemies_unlocked"]):
		threat.add_child(UiKit.wrapped("- " + enemy_trait, 14, Color(1, 0.8, 0.6)))
	var danger_row := HBoxContainer.new()
	danger_row.add_child(UiKit.label("Danger", 15, Color(0.7, 0.8, 0.9)))
	for i in 5:
		danger_row.add_child(IconView.make("danger", 24, Color(1, 0.4, 0.35) if i < node["danger"] else Color(0.25, 0.28, 0.35)))
	threat.add_child(danger_row)
	if node["modifier"] != "":
		var modifier: Dictionary = MissionData.MODIFIERS[node["modifier"]]
		threat.add_child(UiKit.label("Special condition: " + modifier["name"], 15, Color(1, 0.75, 0.35), "bold"))
		threat.add_child(UiKit.wrapped(modifier["text"], 14, Color(0.9, 0.8, 0.65)))
	var reward_row := HBoxContainer.new()
	reward_row.add_child(IconView.make(node["reward_tech"], 28, TechData.element_color(node["reward_tech"])))
	var reward_text := VBoxContainer.new()
	reward_text.add_theme_constant_override("separation", 0)
	reward_text.add_child(UiKit.label("Blueprints", 13, Color(0.6, 0.7, 0.85)))
	reward_text.add_child(UiKit.label(TechData.TECH[node["reward_tech"]]["name"], 17, TechData.element_color(node["reward_tech"]), "bold"))
	reward_row.add_child(reward_text)
	payout.add_child(reward_row)
	if TechData.TECH[node["reward_tech"]].has("from_boss"):
		payout.add_child(UiKit.wrapped("Paid only if you beat the %s." % GuideData.BOSSES[TechData.TECH[node["reward_tech"]]["from_boss"]][0], 13, Color(1, 0.8, 0.6)))
	if int(node.get("frame_blueprints", 0)) > 0:
		var frame_row := HBoxContainer.new()
		frame_row.add_child(IconView.make("frame_blueprint", 26, Art.GOLD))
		frame_row.add_child(UiKit.label("Frame Blueprints x%d" % int(node["frame_blueprints"]), 15, Art.GOLD, "bold"))
		payout.add_child(frame_row)
	if node["prize"] != "":
		var claimed: bool = Save.data["prizes_claimed"].has(node_id)
		payout.add_child(UiKit.label("PRIZE" + (" (claimed)" if claimed else ""), 16, Art.GOLD, "bold"))
		payout.add_child(UiKit.wrapped(node["prize_text"], 15, Color(1, 0.9, 0.7)))
	payout.add_child(UiKit.spacer(6))
	var available := star_map.is_available(node_id, Save.is_cleared)
	if Save.is_cleared(node_id):
		payout.add_child(UiKit.label("Cleared — fly it again any time.", 14, Color(0.5, 1.0, 0.65)))
	var power := Save.power_summary()
	if available and power["over_load"]:
		var blocked := UiKit.button("LAUNCH", func(): pass, "Launch blocked %s" % node_id, true)
		blocked.disabled = true
		payout.add_child(blocked)
		payout.add_child(UiKit.wrapped("Your build weighs %d, over its Max Load of %d. Lighten it in the Hangar." % [power["weight"], power["load"]], 14, Color(1, 0.5, 0.45)))
	elif available:
		payout.add_child(UiKit.button("LAUNCH", func(): _launch(node), "Launch %s" % node_id, true))
	else:
		payout.add_child(UiKit.wrapped("Out of reach. Clear a planet linked to this one first.", 14, Color(0.65, 0.7, 0.8)))


## One column of the planet card strip; weight sets its share of the width.
func _info_column(weight: float) -> VBoxContainer:
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.size_flags_stretch_ratio = weight
	column.add_theme_constant_override("separation", 3)
	_info.add_child(column)
	return column


# ---------------------------------------------------------------- hangar

func _build_hangar_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	# The loadout comes first: it's what changes before most missions. The frames, chosen far less often, sit below.
	column.add_child(UiKit.label("LOADOUT", 20, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(UiKit.wrapped("Your main weapon, plating and power parts are ready when a mission starts. Level-ups and Salvage Crates bring the rest online. The Generator slot holds what keeps you alive: a shield, a blade, a mirror or a lantern, one at a time.", 14, Color(0.65, 0.75, 0.88)))
	# Load and Mawjig Output (GDD 21B): what the build weighs and draws against what the frame can take.
	var power := Save.power_summary()
	var meters := PowerMeters.new()
	meters.summary = power
	column.add_child(meters)
	if power["over_load"]:
		column.add_child(UiKit.wrapped("Over Max Load: swap a heavy part for a lighter one, or leave a slot empty, before you launch.", 15, Color(1, 0.45, 0.4)))
	elif power["overclocked"]:
		column.add_child(UiKit.wrapped("Overclocked: this build draws more power than your Output gives. In a mission the frame heats up as those parts come online, and at full heat it vents: for 3 s every powered part but your main weapon goes quiet, shield included. With everything online, it vents about every %d s." % roundi(power["vent_every"]), 14, Color(1, 0.7, 0.35)))
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 8)
	column.add_child(slots_row)
	for slot_index in TechData.SLOTS.size():
		slots_row.add_child(_slot_card(slot_index))
	column.add_child(UiKit.label("FRAME", 20, Color(0.6, 0.9, 1.0), "title"))
	var frames_row := HBoxContainer.new()
	frames_row.add_theme_constant_override("separation", 12)
	column.add_child(frames_row)
	for frame_id in FrameData.FRAMES:
		frames_row.add_child(_frame_card(frame_id))
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
	var stats := FrameData.stats(frame_id, Save.frame_tiers(frame_id))
	column.add_child(UiKit.label("Armor %d   Speed %d" % [stats["armor"], stats["speed"]], 13, Color(0.6, 0.75, 0.9)))
	column.add_child(UiKit.label("Max Load %d   Mawjig Output %d" % [stats["load"], stats["output"]], 13, Color(0.6, 0.75, 0.9)))
	column.add_child(UiKit.label(data["trait_name"], 15, Art.GOLD, "bold"))
	column.add_child(UiKit.wrapped(data["trait_text"], 13, Color(0.85, 0.8, 0.65)))
	if unlocked:
		_frame_tiers(column, frame_id)
	if not unlocked:
		column.add_child(UiKit.wrapped("Locked. " + data["unlock"], 13, Color(1, 0.6, 0.5)))
	elif not selected:
		column.add_child(UiKit.button("Fly this frame", func():
			Save.select_frame(frame_id)
			_rebuild(), "Hangar: select %s" % frame_id))
	else:
		column.add_child(UiKit.label("Selected", 15, Color(0.5, 1.0, 0.65), "bold"))
	return card


## Frame upgrades (GDD 21F): each bought tier shows its pick, and tapping it moves to the next pick. The next tier
## can be bought with Frame Blueprints.
func _frame_tiers(column: VBoxContainer, frame_id: String) -> void:
	var picks := Save.frame_tiers(frame_id)
	for tier in picks.size():
		var pick: String = picks[tier]
		var next_pick: String = FrameData.TIER_PICKS[(FrameData.TIER_PICKS.find(pick) + 1) % FrameData.TIER_PICKS.size()]
		var row := HBoxContainer.new()
		row.add_child(UiKit.label("Tier %d" % (tier + 1), 13, Art.GOLD, "bold"))
		var button := UiKit.button(FrameData.TIER_PICK_NAMES[pick], func():
			Save.set_tier_pick(frame_id, tier, next_pick)
			_rebuild(), "Hangar: %s tier %d -> %s" % [frame_id, tier + 1, next_pick])
		button.tooltip_text = FrameData.TIER_PICK_TEXT[pick]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(button)
		column.add_child(row)
	if not picks.is_empty():
		column.add_child(UiKit.wrapped("Tap a tier to change what it gives. Changing is free.", 12, Color(0.6, 0.7, 0.8)))
	var cost := Save.next_tier_cost(frame_id)
	if cost > 0:
		var have: int = Save.data["frame_blueprints"]
		var buy := UiKit.button("Buy tier %d: %d / %d Frame Blueprints" % [picks.size() + 1, have, cost], func():
			if Save.buy_frame_tier(frame_id):
				Sound.play("upgrade")
				_rebuild(), "Hangar: buy %s tier %d" % [frame_id, picks.size() + 1], have >= cost)
		buy.disabled = have < cost
		column.add_child(buy)


func _slot_card(slot_index: int) -> Control:
	var slot: String = TechData.SLOTS[slot_index]
	var tech_id: String = Save.data["loadout"][slot_index]
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(118, 174)
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
	box.offset_top = 10
	box.alignment = BoxContainer.ALIGNMENT_BEGIN
	box.add_theme_constant_override("separation", 6)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)
	for new_id in Save.data["new_unlocks"]:
		if TechData.TECH.has(new_id) and TechData.TECH[new_id]["slot"] == slot:
			button.add_child(NewDot.new())
			break
	var slot_label := UiKit.label(TechData.SLOT_NAMES[slot].to_upper(), 14, Color(0.55, 0.7, 0.85), "bold")
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(slot_label)
	if tech_id == "":
		var plus := UiKit.label("+", 40, Color(0.45, 0.6, 0.75), "bold")
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(plus)
		var empty := UiKit.label("empty", 15, Color(0.5, 0.55, 0.65))
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
		var mk := UiKit.label("Mk %d" % Save.tech_mk(tech_id), 15, Art.GOLD)
		mk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mk.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(mk)
		var cost := UiKit.label("Weight %d · Draw %d" % [TechData.weight_of(tech_id), TechData.draw_of(tech_id)], 12, Color(0.65, 0.75, 0.85))
		cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(cost)
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
		text.add_child(UiKit.label(TechData.power_text(tech_id), 12, Color(0.7, 0.75, 0.6)))
		if TechData.has_forks(tech_id):
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
	column.add_child(UiKit.label(TechData.power_text(tech_id), 13, Color(0.7, 0.75, 0.6)))
	column.add_child(UiKit.wrapped(_source_text(tech_id), 13, Color(0.55, 0.7, 0.85)))
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


## Where a tech's blueprints come from: planet types, a boss it's named after, or a one-off prize.
func _source_text(tech_id: String) -> String:
	var tech: Dictionary = TechData.TECH[tech_id]
	if tech.has("from_boss"):
		return "Prize of the %s: beat it to win its blueprints." % GuideData.BOSSES[tech["from_boss"]][0]
	if tech["blueprint_from"].is_empty():
		return tech.get("source", "")
	var sources := []
	for source in tech["blueprint_from"]:
		sources.append(MissionData.TYPES[source]["name"])
	return "Found on: %s" % ", ".join(sources)


# ---------------------------------------------------------------- supply depot (DepotData)

var last_haul: Dictionary = {}  # what the last Derelict Dive brought, shown until you leave the page


func _build_depot_page() -> Control:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 12)
	scroll.add_child(column)
	var head := HBoxContainer.new()
	var title := UiKit.label("SUPPLY DEPOT", 20, Color(0.6, 0.9, 1.0), "title")
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(IconView.make("crystal", 30, Color(0.55, 0.9, 1.0)))
	head.add_child(UiKit.label("%d Mawjig Crystals" % Save.data["crystals"], 22, Color(0.65, 0.95, 1.0), "bold"))
	column.add_child(head)
	column.add_child(UiKit.wrapped("Crystals come from missions (more for a win, most for a first clear), milestones and checking in. They can't be bought, only earned.", 14, Color(0.65, 0.75, 0.88)))
	var waiting: int = Save.data["start_crate"]
	if waiting > 0:
		column.add_child(UiKit.wrapped("%s waiting for you at the start of your next mission." % ("A Salvage Crate is" if waiting == 1 else "%d Salvage Crates are" % waiting), 14, Color(1, 0.85, 0.5)))
	column.add_child(_checkin_panel())
	column.add_child(_dives_panel())
	return scroll


## The week's check-in tiles: past ones ticked, today's ready to claim, the rest waiting.
func _checkin_panel() -> Control:
	var panel := UiKit.panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(UiKit.label("DAILY CHECK-IN", 17, Art.GOLD, "bold"))
	column.add_child(UiKit.wrapped("One tile for each day you check in, whichever days you like. Missing a day never resets it. Day 7 is the big one, then the week starts over.", 14, Color(0.65, 0.75, 0.88)))
	var ready := Save.checkin_ready()
	var tile := Save.checkin_tile()
	var claimed := tile if (ready or tile > 0) else DepotData.CHECKIN.size()
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	column.add_child(row)
	for i in DepotData.CHECKIN.size():
		var reward: Dictionary = DepotData.CHECKIN[i]
		var today := ready and i == tile
		var done := i < claimed
		var cell := UiKit.panel(Color(0.12, 0.2, 0.3) if today else Color(0.04, 0.06, 0.1), Art.GOLD if today else (Color(0.3, 0.6, 0.45) if done else Color(0.2, 0.3, 0.42)))
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		cell.add_child(box)
		var day := UiKit.label("DAY %d" % (i + 1), 13, Color(0.6, 0.72, 0.86), "bold")
		day.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(day)
		var icon := IconView.make(_checkin_icon(reward), 26 if i < 6 else 34, Color(0.55, 0.9, 1.0) if not done else Color(0.35, 0.5, 0.55))
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(icon)
		var amount := UiKit.wrapped(reward["text"], 12, Color(0.5, 0.7, 0.65) if done else Color(1, 1, 1))
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(amount)
		var state := UiKit.label("CLAIMED" if done else ("TODAY" if today else ""), 12, Color(0.5, 1.0, 0.65) if done else Art.GOLD, "bold")
		state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(state)
		row.add_child(cell)
	if ready:
		column.add_child(UiKit.button("Check in: claim day %d" % (tile + 1), func():
			var reward := Save.claim_checkin()
			if not reward.is_empty():
				Sound.play("upgrade")
			_rebuild(), "Depot: check in", true))
	else:
		column.add_child(UiKit.label("Checked in today. The next tile opens tomorrow.", 14, Color(0.5, 1.0, 0.65)))
	return panel


func _checkin_icon(reward: Dictionary) -> String:
	if reward.has("free_dive"):
		return "scan"
	if reward.has("start_crate"):
		return "crate"
	if reward.has("main_blueprints"):
		return Save.data["loadout"][0]
	if reward.has("frame_blueprints") and not reward.has("crystals"):
		return "frame_blueprint"
	return "crystal"


## Derelict Dives: scan a field of wrecks, pick one to board, see what the drone brings back.
func _dives_panel() -> Control:
	var panel := UiKit.panel()
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	column.add_child(UiKit.label("DERELICT DIVES", 17, Art.GOLD, "bold"))
	column.add_child(UiKit.wrapped("The Dropship scans a field of wrecks and sends its drone aboard the one you pick. Each kind of wreck carries its own salvage. Odds: Common 67%, Rare 28%, Prototype 5% (unlocks a tech you don't have yet), and a Rare or better at least every 10 dives.", 14, Color(0.65, 0.75, 0.88)))
	var wrecks: Array = Save.data["dive_wrecks"]
	if wrecks.is_empty():
		var free: int = Save.data["free_dives"]
		var label := "Scan for wrecks: uses 1 of %d free dives" % free if free > 0 else "Scan for wrecks: %d crystals" % DepotData.DIVE_COST
		var can: bool = free > 0 or Save.data["crystals"] >= DepotData.DIVE_COST
		var button := UiKit.button(label, func():
			if not DerelictDives.scan().is_empty():
				Sound.play("ui")
			last_haul = {}
			_rebuild(), "Depot: scan", can)
		button.disabled = not can
		column.add_child(button)
	else:
		column.add_child(UiKit.label("Three wrecks on the scanner. Pick one to board:", 15, Color(0.85, 0.92, 1.0), "bold"))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		column.add_child(row)
		for kind in wrecks:
			var wreck: Dictionary = DepotData.WRECKS[kind]
			var card := Button.new()
			card.focus_mode = Control.FOCUS_NONE
			card.custom_minimum_size = Vector2(0, 138)
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_theme_stylebox_override("normal", UiKit._box(Color(0.05, 0.08, 0.13), wreck["color"], 2))
			card.pressed.connect(func():
				PlayLog.button("Depot: board %s" % kind)
				last_haul = DerelictDives.board(kind)
				Sound.play("jackpot" if last_haul.get("rarity", "") == "legendary" else "crate")
				_rebuild())
			var box := VBoxContainer.new()
			box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			box.offset_top = 8
			box.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(box)
			var icon := IconView.make("wreck_" + kind, 48, wreck["color"])
			icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(icon)
			var name := UiKit.label(wreck["name"], 16, wreck["color"], "bold")
			name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			name.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(name)
			var text := UiKit.wrapped(wreck["text"], 12, Color(0.75, 0.82, 0.92))
			text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			box.add_child(text)
			row.add_child(card)
	if not last_haul.is_empty():
		var reveal := DropCard.new()
		reveal.result = last_haul
		column.add_child(reveal)
	return panel


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
			var text: String = "%s\n%s" % [data["text"], TechData.power_text(tech_id)]
			if TechData.has_forks(tech_id):
				text += "\nFork %s: %s\nFork %s: %s" % [forks["a"]["name"], forks["a"]["text"], forks["b"]["name"], forks["b"]["text"]]
			tech.append([data["name"], text, TechData.element_color(tech_id)])
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
	column.add_child(SettingsControls.slider("Music", "music"))
	column.add_child(SettingsControls.slider("Sound effects", "sfx"))
	column.add_child(SettingsControls.toggle("Full screen (iPad Safari: applies on your next tap)", "fullscreen"))
	column.add_child(_threat_picker())
	column.add_child(SettingsControls.toggle("Double-tap special", "double_tap_special"))
	column.add_child(UiKit.wrapped("Tap, then tap again and hold: the second touch aims (or steers) as usual and fires your special when you lift it.", 13, Color(0.65, 0.75, 0.88)))
	column.add_child(SettingsControls.toggle("Transformation spin", "transform_spin"))
	column.add_child(UiKit.wrapped("Your frame spins a full turn as it changes between ship and mech.", 13, Color(0.65, 0.75, 0.88)))
	column.add_child(UiKit.label("ACCESSIBILITY", 18, Color(0.6, 0.9, 1.0), "title"))
	column.add_child(SettingsControls.toggle("Screen shake", "screen_shake"))
	column.add_child(SettingsControls.toggle("Bullets glow in the dark", "bullet_glow"))
	column.add_child(UiKit.wrapped("On Blackout planets and in dark boss phases, enemy bullets glow so you can always see them coming.", 13, Color(0.65, 0.75, 0.88)))
	column.add_child(SettingsControls.toggle("Auto-aim (mech)", "auto_aim"))
	column.add_child(UiKit.wrapped("On planets and in dungeons, your mech turns to the nearest enemy whenever you aren't aiming. From your next mission.", 13, Color(0.65, 0.75, 0.88)))
	column.add_child(SettingsControls.toggle("Auto-fire", "autofire"))
	column.add_child(UiKit.wrapped("Weapons fire on their own. Off: they fire while you steer the ship or hold the aim stick (or the fire key). From your next mission.", 13, Color(0.65, 0.75, 0.88)))
	column.add_child(SettingsControls.toggle("Play log", "play_log"))
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
		_confirm("Get the latest version?", "The game reloads with the newest build. Your progress is kept.", "Reload", func():
			PlayLog.note("update", "Cleared the offline copy and reloaded (was %s)" % BuildInfo.label())
			Save.write()
			update_note.text = "Reloading..."
			Browser.clear_cache_and_reload()), "Settings: get the latest version"))
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


## The Hangar's two rows of pips (GDD 21B): Max Load, a hard limit, and Mawjig Output, which you may run past
## on purpose. Pips past the limit turn red (Load) or orange (Output, OVERCLOCKED).
class PowerMeters:
	extends Control
	const PIP := Vector2(18, 16)
	const GAP := 4.0
	var summary := {}

	func _ready() -> void:
		custom_minimum_size = Vector2(0, 62)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		_row(0.0, "MAX LOAD", summary["weight"], summary["load"], Color(0.55, 0.85, 1.0), Color(1, 0.35, 0.35), "weighs", "OVER LOAD")
		var notes := []
		if TechData.loadout_output_bonus(Save.data["loadout"]) > 0:
			notes.append("+%d from the Auxiliary Generator" % TechData.loadout_output_bonus(Save.data["loadout"]))
		if summary["cooled"] > 0 and summary["draw"] > summary["output"]:
			notes.append("the Coolant Loop cancels 1")
		var note := "  (%s)" % ", ".join(notes) if not notes.is_empty() else ""
		_row(32.0, "MAWJIG OUTPUT", summary["draw"], summary["output"], Color(0.85, 0.55, 1.0), Color(1, 0.6, 0.2), "draws", "OVERCLOCKED" if summary["overclocked"] else "", note)

	func _row(y: float, title: String, used: int, limit: int, color: Color, over_color: Color, verb: String, over_word: String, note: String = "") -> void:
		var font := UiKit.font("bold")
		draw_string(font, Vector2(0, y + 14), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.6, 0.72, 0.86))
		var x := 150.0
		for i in maxi(used, limit):
			var rect := Rect2(Vector2(x, y), PIP)
			var fill := Color(0.12, 0.16, 0.22)
			if i < used:
				fill = over_color if i >= limit else color
			draw_rect(rect, fill)
			draw_rect(rect, Color(0.3, 0.4, 0.5) if i < limit else over_color, false, 1.5)
			x += PIP.x + GAP
		var over := used > limit
		draw_string(font, Vector2(x + 8, y + 14), "%s %d of %d%s%s" % [verb, used, limit, "   " + over_word if over and over_word != "" else "", note], HORIZONTAL_ALIGNMENT_LEFT, -1, 15,
			over_color if over else Color(0.85, 0.9, 1.0))


## One Derelict Dive's haul: a card that flips in, coloured by its rarity, a Prototype with a gold burst.
class DropCard:
	extends Control
	const SCAN_SECONDS := 0.9         # the drone's sweep through the wreck before the haul shows
	var result := {}
	var delay := 0.0
	var time := 0.0

	func _ready() -> void:
		custom_minimum_size = Vector2(196, 176)
		size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _process(delta: float) -> void:
		time += delta
		if time < delay + SCAN_SECONDS + 2.0:
			queue_redraw()

	func _draw() -> void:
		var t := time - delay
		if t <= 0.0:
			return
		var color: Color = DepotData.RARITY_COLORS[result["rarity"]]
		var font := UiKit.font("bold")
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.04, 0.06, 0.1))
		if t < SCAN_SECONDS:
			# Boarding: a scan line sweeps the hull while the drone searches it.
			var sweep := t / SCAN_SECONDS
			draw_rect(rect, Color(0.3, 0.5, 0.7), false, 2.0)
			var y := size.y * sweep
			draw_rect(Rect2(Vector2(0, y - 18), Vector2(size.x, 18)), Color(0.4, 0.8, 1.0, 0.18))
			draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.6, 0.95, 1.0, 0.9), 2.0)
			draw_string(font, Vector2(0, size.y * 0.5), "BOARDING THE %s..." % str(result.get("wreck", "WRECK")).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Color(0.6, 0.9, 1.0))
			return
		var reveal := clampf((t - SCAN_SECONDS) / 0.3, 0.0, 1.0)
		var bright: bool = result["rarity"] != "common"
		if bright:
			Art.draw_glow(self, size * 0.5, size.x * 0.4, Art.with_alpha(color, (0.35 if result["rarity"] == "legendary" else 0.2) * reveal))
			for i in 12:
				var angle := TAU * i / 12.0 + t * 0.4
				var from := size * 0.5 + Vector2.from_angle(angle) * 50.0
				draw_line(from, from + Vector2.from_angle(angle) * (30.0 + 20.0 * reveal), Art.with_alpha(color, 0.35 * (1.0 - reveal * 0.5)), 2.0)
		draw_rect(rect, color, false, 3.0)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, 30)), Art.with_alpha(color, 0.25))
		draw_string(font, Vector2(14, 21), DepotData.RARITY_NAMES[result["rarity"]].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, color)
		draw_string(UiKit.font(), Vector2(0, 21), "from the %s" % result.get("wreck", "wreck"), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 14, 13, Color(0.7, 0.8, 0.9))
		var icon_color := TechData.element_color(result["icon"]) if TechData.TECH.has(result["icon"]) else Art.GOLD
		var icon_size := 56.0 * (0.6 + 0.4 * ease(reveal, 0.4))
		IconPainter.draw(self, result["icon"], Rect2(Vector2(size.x * 0.5 - icon_size * 0.5, 74 - icon_size * 0.5), Vector2(icon_size, icon_size)), Art.with_alpha(icon_color, reveal))
		draw_string(font, Vector2(8, 128), result["title"], HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 20, Color(1, 1, 1, reveal))
		draw_string(UiKit.font(), Vector2(8, 154), result["text"], HORIZONTAL_ALIGNMENT_CENTER, size.x - 16, 15, Color(0.75, 0.85, 0.95, reveal))


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
