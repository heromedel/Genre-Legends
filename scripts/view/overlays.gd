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
		custom_minimum_size = Vector2(230, 300)

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
		if card["kind"] == "repair":
			icon_id = "repair"
		var icon_rect := Rect2(Vector2(size.x * 0.5 - 40, 28 + lift), Vector2(80, 80))
		draw_texture_rect(Art.glow(), icon_rect.grow(30), false, Art.with_alpha(rarity, 0.25 * appear))
		IconPainter.draw(self, icon_id, icon_rect, Art.with_alpha(rarity.lightened(0.3), appear))
		var kind_text: String = {"online": "BRING ONLINE", "upgrade": "UPGRADE", "fork": "CHOOSE A PATH", "fusion": "FUSION",
			"field": "FIELD UPGRADE", "repair": "REPAIR"}.get(card["kind"], "")
		draw_string(UiKit.font("bold"), Vector2(0, 130 + lift), kind_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, 13, Art.with_alpha(rarity, appear))
		_draw_wrapped(UiKit.font("bold"), card["title"], Vector2(14, 158 + lift), size.x - 28, 19, Art.with_alpha(Color(1, 1, 1), appear))
		_draw_wrapped(UiKit.font("body"), card["text"], Vector2(14, 214 + lift), size.x - 28, 15, Art.with_alpha(Color(0.75, 0.85, 0.95), appear))

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


static func build_offer(cards: Array, source: String, on_pick: Callable) -> Control:
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
	return root


## The Salvage Crate: three slot-machine reels spin, then land on how many upgrades you got.
class CrateReel:
	extends Control
	var cards: Array = []
	var on_done: Callable
	var time := 0.0
	var spin_seconds := 1.6

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(delta: float) -> void:
		var before := time
		time += delta
		for i in 3:
			var stop_at := spin_seconds * (0.55 + 0.22 * i)
			if before < stop_at and time >= stop_at:
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

	func _draw() -> void:
		var screen := size
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.01, 0.0, 0.75))
		var title_font := UiKit.font("title")
		draw_string(title_font, Vector2(0, screen.y * 0.2), "SALVAGE CRATE", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 36, Art.GOLD)
		var reel_size := Vector2(120, 140)
		var start := Vector2(screen.x * 0.5 - reel_size.x * 1.5 - 20, screen.y * 0.27)
		var faces := ["1", "3", "5"]
		var result := str(cards.size())
		for i in 3:
			var rect := Rect2(start + Vector2(i * (reel_size.x + 20), 0), reel_size)
			draw_rect(rect, Color(0.12, 0.08, 0.02))
			draw_rect(rect, Art.GOLD, false, 3.0)
			var stop_at := spin_seconds * (0.55 + 0.22 * i)
			var face: String = result if time >= stop_at else faces[int(time * 18.0 + i) % 3]
			draw_string(title_font, rect.position + Vector2(0, reel_size.y * 0.68), face, HORIZONTAL_ALIGNMENT_CENTER, reel_size.x, 64, Color(1, 0.9, 0.55))
		if time < spin_seconds:
			return
		var y := start.y + reel_size.y + 46.0
		draw_string(UiKit.font("bold"), Vector2(0, y), "%d UPGRADE%s" % [cards.size(), "S" if cards.size() > 1 else ""], HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color(1, 0.9, 0.6))
		for i in cards.size():
			var reveal := clampf((time - spin_seconds - i * 0.12) / 0.2, 0.0, 1.0)
			var card: Dictionary = cards[i]
			var color: Color = Art.RARITY.get(card["rarity"], Color.WHITE)
			draw_string(UiKit.font("body"), Vector2(0, y + 34 + i * 28), card["title"], HORIZONTAL_ALIGNMENT_CENTER, screen.x, 19, Art.with_alpha(color, reveal))
		if time > spin_seconds + 0.4:
			var blink := 0.5 + 0.5 * sin(time * 5.0)
			draw_string(UiKit.font("body"), Vector2(0, screen.y - 40), "Tap to continue", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 18, Color(1, 1, 1, blink))


static func build_pause(on_resume: Callable, on_abandon: Callable) -> Control:
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
	var box := UiKit.panel()
	center.add_child(box)
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(360, 0)
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
	column.add_child(UiKit.button("Abandon mission (keep half the blueprints)", on_abandon, "Pause: Abandon"))
	return root
