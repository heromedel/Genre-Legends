class_name Overlays
## Builders for the in-mission overlays: level-up cards, the Salvage Crate reel, the pause menu,
## and the round touch buttons (special, pause).


## A round on-screen button with an icon and an optional cooldown sweep.
class TouchButton:
	extends Control
	var icon := ""
	var color := Color(0.9, 0.95, 1.0)
	var on_press: Callable
	var cooldown := 0.0          # 0..1 fraction still cooling down
	var charges := 1
	var enabled := true
	var label := ""

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventScreenTouch and event.pressed) or \
			(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
		if pressed and enabled and on_press.is_valid():
			on_press.call()
			accept_event()

	func _draw() -> void:
		var r := size.x * 0.5
		var c := size * 0.5
		var ready := enabled and cooldown <= 0.0
		draw_circle(c, r, Color(0.04, 0.07, 0.12, 0.7))
		draw_arc(c, r - 2, 0, TAU, 40, Art.with_alpha(color, 0.9 if ready else 0.35), 3.0, true)
		if cooldown > 0.0:
			draw_arc(c, r - 7, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - cooldown), 40, Art.with_alpha(color, 0.6), 6.0, true)
		IconPainter.draw(self, icon, Rect2(c - Vector2(r, r) * 0.55, Vector2(r, r) * 1.1), Art.with_alpha(color, 1.0 if ready else 0.4))
		if charges > 1:
			draw_string(UiKit.font("bold"), c + Vector2(r * 0.35, r * 0.85), "x%d" % charges, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)
		if label != "":
			draw_string(UiKit.font("body"), Vector2(0, size.y + 16), label, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Art.with_alpha(color, 0.8))


## A level-up / pedestal card: rarity-coloured border, icon, title and what it does.
class Card:
	extends Control
	var card: Dictionary
	var on_pick: Callable
	var appear := 0.0

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(236, 360)

	func _process(delta: float) -> void:
		appear = minf(appear + delta * 4.0, 1.0)
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var pressed: bool = (event is InputEventScreenTouch and not event.pressed) or \
			(event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
		if pressed and appear >= 1.0 and on_pick.is_valid():
			on_pick.call()
			accept_event()

	func _draw() -> void:
		var rarity: Color = Art.RARITY.get(card["rarity"], Color.WHITE)
		var lift := (1.0 - ease(appear, 0.4)) * 40.0
		var rect := Rect2(Vector2(0, lift), size)
		draw_rect(rect, Color(0.04, 0.06, 0.1, 0.96 * appear))
		draw_rect(Rect2(rect.position, Vector2(size.x, 6)), Art.with_alpha(rarity, appear))
		draw_rect(rect, Art.with_alpha(rarity, 0.9 * appear), false, 3.0)
		var icon_id: String = card["tech"] if card["tech"] != "" else card.get("field", "")
		if card["kind"] == "fusion":
			icon_id = "fusion"
		if card["kind"] == "cache":
			icon_id = "crate"
		var icon_rect := Rect2(Vector2(size.x * 0.5 - 40, 28 + lift), Vector2(80, 80))
		draw_texture_rect(Art.glow(), icon_rect.grow(30), false, Art.with_alpha(rarity, 0.25 * appear))
		IconPainter.draw(self, icon_id, icon_rect, Art.with_alpha(rarity.lightened(0.3), appear))
		var kind_text: String = {"online": "BRING ONLINE", "upgrade": "UPGRADE", "fork": "CHOOSE A PATH", "fusion": "FUSION",
			"field": "FIELD UPGRADE", "cache": "SALVAGE"}.get(card["kind"], "")
		if card["rarity"] == "risky":
			kind_text = "RISKY"
		# Element chip in the corner.
		var element: String = card.get("element", "")
		if element != "":
			var chip_color: Color = TechData.ELEMENT_COLORS[element]
			draw_string(UiKit.font("bold"), Vector2(0, 26 + lift), element.to_upper(), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 10, 14, Art.with_alpha(chip_color, appear))
		draw_string(UiKit.font("bold"), Vector2(0, 130 + lift), kind_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Art.with_alpha(rarity, appear))
		_draw_wrapped(UiKit.font("bold"), card["title"], Vector2(14, 158 + lift), size.x - 28, 19, Art.with_alpha(Color(1, 1, 1), appear))
		_draw_wrapped(UiKit.font("body"), card["text"], Vector2(14, 214 + lift), size.x - 28, 15, Art.with_alpha(Color(0.75, 0.85, 0.95), appear))
		# What it builds toward (GDD 9H).
		var y := size.y - 44 + lift
		if card.get("fusion_hint", "") != "":
			_draw_wrapped(UiKit.font("bold"), card["fusion_hint"], Vector2(10, y - 22), size.x - 20, 12, Art.with_alpha(Color(0.85, 0.6, 1.0), appear))
		if card.get("synergy", "") != "":
			var unlocks: bool = card["synergy"].begins_with("Unlocks")
			var synergy_color: Color = Art.GOLD if unlocks else TechData.ELEMENT_COLORS.get(element, Color(0.7, 0.8, 0.9))
			_draw_wrapped(UiKit.font("bold"), card["synergy"], Vector2(10, y), size.x - 20, 12 if unlocks else 13, Art.with_alpha(synergy_color, appear))

	func _draw_wrapped(font: Font, text: String, at: Vector2, width: float, font_size: int, color: Color) -> void:
		var lines := []
		var current := ""
		for word in text.split(" "):
			var attempt := word if current == "" else current + " " + word
			if font.get_string_size(attempt, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > width and current != "":
				lines.append(current)
				current = word
			else:
				current = attempt
		lines.append(current)
		for i in lines.size():
			draw_string(font, at + Vector2(0, i * (font_size + 4)), lines[i], HORIZONTAL_ALIGNMENT_CENTER, width, font_size, color)


static func build_offer(cards: Array, source: String, on_pick: Callable, run: RunState, on_reroll: Callable) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.05, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(column)
	var title := UiKit.label("LEVEL UP" if source == "level_up" else "TREASURE", 40, Color(0.55, 1.0, 0.85) if source == "level_up" else Art.GOLD, "title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	var hint := UiKit.label("Pick one", 16, Color(0.7, 0.8, 0.9))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(row)
	for i in cards.size():
		var view := Card.new()
		view.card = cards[i]
		var index := i
		view.on_pick = func(): on_pick.call(index)
		row.add_child(view)
	# Reroll and a look at the whole build before choosing.
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 16)
	column.add_child(actions)
	var reroll := UiKit.button("Reroll (%d left)" % run.rerolls, on_reroll, "Level-up: reroll")
	reroll.disabled = run.rerolls <= 0
	reroll.custom_minimum_size = Vector2(200, 50)
	actions.add_child(reroll)
	var build_view: Control = null
	var view_build := UiKit.button("View build", func(): pass, "Level-up: view build")
	view_build.custom_minimum_size = Vector2(200, 50)
	view_build.pressed.connect(func():
		if build_view != null:
			build_view.queue_free()
			build_view = null
			view_build.text = "View build"
			return
		build_view = _floating(BuildPanel.build(run))
		root.add_child(build_view)
		view_build.text = "Back to cards"
		root.move_child(build_view, root.get_child_count() - 1))
	actions.add_child(view_build)
	return root


## Centres a panel over everything, with a tap-anywhere-outside backdrop that does nothing (so taps
## don't fall through to the cards underneath).
static func _floating(panel: Control) -> Control:
	var holder := CenterContainer.new()
	holder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_child(shade)
	holder.add_child(panel)
	return holder


## The Salvage Crate: three slot-machine reels of gems spin and stop one by one; the crate gives one upgrade
## per gem. Then every upgrade it landed on is listed with what it does.
class CrateReel:
	extends Control
	var cards: Array = []
	var faces: Array = []          # what each reel landed on
	var reels: Array = []          # every face each reel can show while spinning
	var on_done: Callable
	var time := 0.0
	var spin_seconds := 1.8

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _stop_time(reel_index: int) -> float:
		return spin_seconds * (0.45 + 0.27 * reel_index)

	func _process(delta: float) -> void:
		var before := time
		time += delta
		for i in 3:
			if before < _stop_time(i) and time >= _stop_time(i):
				Sound.play("reel_stop")
		if before < spin_seconds and time >= spin_seconds:
			Sound.play("jackpot" if cards.size() >= 5 else "crate")
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		var released: bool = (event is InputEventScreenTouch and not event.pressed) or \
			(event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)
		if released and time > spin_seconds + 0.4 and on_done.is_valid():
			on_done.call()
			accept_event()

	## A reel face is gems, not digits: none, one or two, so it reads at a glance like a slot machine.
	func _draw_reel_face(rect: Rect2, face: int, landed: bool) -> void:
		var center := rect.get_center()
		var alpha := 1.0 if landed else 0.55
		if face == 0:
			draw_line(center + Vector2(-18, 0), center + Vector2(18, 0), Color(0.55, 0.45, 0.3, alpha), 4.0)
			return
		for g in face:
			var at := center + Vector2((g - (face - 1) * 0.5) * 34.0, 0)
			var gem := PackedVector2Array([at + Vector2(0, -20), at + Vector2(14, 0), at + Vector2(0, 20), at + Vector2(-14, 0)])
			draw_colored_polygon(gem, Color(1, 0.82, 0.35, alpha))
			draw_polyline(PackedVector2Array([gem[0], gem[1], gem[2], gem[3], gem[0]]), Color(1, 1, 0.85, alpha), 2.0, true)

	func _draw() -> void:
		var screen := size
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.01, 0.0, 0.8))
		var title_font := UiKit.font("title")
		draw_string(title_font, Vector2(0, screen.y * 0.13), "SALVAGE CRATE", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 34, Art.GOLD)
		# Reel + reel + reel = total.
		var box := Vector2(100, 116)
		var gap := 44.0
		var row_width := box.x * 4 + gap * 3
		var x := screen.x * 0.5 - row_width * 0.5
		var top := screen.y * 0.17
		var jackpot := cards.size() >= 5
		for i in 4:
			var rect := Rect2(Vector2(x + i * (box.x + gap), top), box)
			var is_total := i == 3
			draw_rect(rect, Color(0.18, 0.12, 0.02) if is_total else Color(0.12, 0.08, 0.02))
			draw_rect(rect, Art.GOLD.lightened(0.3) if is_total else Art.GOLD, false, 4.0 if is_total else 3.0)
			if is_total:
				var total := str(cards.size()) if time >= spin_seconds else "?"
				var total_color := Color(1, 0.9, 0.55)
				if jackpot and time >= spin_seconds:
					total_color = Color(1, 1, 1).lerp(Art.GOLD, 0.5 + 0.5 * sin(time * 10.0))
				draw_string(title_font, rect.position + Vector2(0, box.y * 0.7), total, HORIZONTAL_ALIGNMENT_CENTER, box.x, 60, total_color)
			else:
				var options: Array = reels[i]
				var landed := time >= _stop_time(i)
				var face: int = faces[i] if landed else options[int(time * 20.0 + i * 3) % options.size()]
				_draw_reel_face(rect, face, landed)
			if i < 3:
				var sign_at := Vector2(rect.end.x, top + box.y * 0.62)
				draw_string(title_font, sign_at, "=" if i == 2 else "+", HORIZONTAL_ALIGNMENT_CENTER, gap, 34, Color(1, 0.85, 0.5))
		if time < spin_seconds:
			return
		var y := top + box.y + 44.0
		draw_string(UiKit.font("bold"), Vector2(0, y), ("JACKPOT!  " if jackpot else "") + "%d UPGRADE%s" % [cards.size(), "S" if cards.size() > 1 else ""],
			HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color(1, 0.9, 0.6))
		# Each upgrade with what it does, so a crate is never a mystery.
		var width := minf(screen.x * 0.8, 820.0)
		var left := screen.x * 0.5 - width * 0.5
		var step := minf(60.0, (screen.y - y - 70.0) / maxf(cards.size(), 1.0))
		for i in cards.size():
			var reveal := clampf((time - spin_seconds - i * 0.12) / 0.2, 0.0, 1.0)
			var card: Dictionary = cards[i]
			var color: Color = Art.RARITY.get(card["rarity"], Color.WHITE)
			var line_y := y + 34.0 + i * step
			draw_string(UiKit.font("bold"), Vector2(left, line_y), card["title"], HORIZONTAL_ALIGNMENT_CENTER, width, 18, Art.with_alpha(color, reveal))
			draw_multiline_string(UiKit.font("body"), Vector2(left, line_y + 20.0), card["text"], HORIZONTAL_ALIGNMENT_CENTER, width, 14, 2,
				Color(0.85, 0.85, 0.9, reveal))
		if time > spin_seconds + 0.4:
			var blink := 0.5 + 0.5 * sin(time * 5.0)
			draw_string(UiKit.font("body"), Vector2(0, screen.y - 28), "Tap to continue", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 18, Color(1, 1, 1, blink))


static func build_pause(on_resume: Callable, on_abandon: Callable, run: RunState) -> Control:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0.02, 0.05, 0.8)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 16)
	center.add_child(split)
	var box := UiKit.panel()
	split.add_child(box)
	split.add_child(BuildPanel.build(run))
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(330, 0)
	column.add_theme_constant_override("separation", 14)
	box.add_child(column)
	var title := UiKit.label("PAUSED", 34, Color(0.6, 0.9, 1.0), "title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)
	column.add_child(UiKit.button("Resume", on_resume, "Pause: Resume", true))
	var shake_button := UiKit.button("", func(): pass, "Pause: Screen shake")
	var refresh := func(): shake_button.text = "Screen shake: %s" % ("On" if Save.setting("screen_shake") else "Off")
	refresh.call()
	shake_button.pressed.connect(func():
		Save.set_setting("screen_shake", not Save.setting("screen_shake"))
		refresh.call())
	column.add_child(shake_button)
	column.add_child(UiKit.button("Abandon mission", on_abandon, "Pause: Abandon"))
	return root
