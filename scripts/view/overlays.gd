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
	var touched := false          # the finger came down on this card after it settled
	var age := 0.0                # seconds since the card appeared
	var press_at := Vector2.ZERO  # where the finger came down

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP
		custom_minimum_size = Vector2(236, 360)

	func _process(delta: float) -> void:
		appear = minf(appear + delta * 4.0, 1.0)
		age += delta
		queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		# A pick is a deliberate tap: it starts on the card once the cards have settled, and the finger
		# doesn't slide on the way. A finger still steering when the cards appear, or one that slips across
		# the screen, picks nothing (heromedel lost upgrades both ways).
		if Overlays.is_tap_down(event):
			touched = age >= Overlays.CARD_SETTLE_SECONDS
			press_at = event.position
		elif Overlays.is_tap_up(event) and touched and on_pick.is_valid():
			touched = false
			if event.position.distance_to(press_at) <= Overlays.TAP_SLOP:
				on_pick.call()
			accept_event()

	func _draw() -> void:
		var rarity: Color = Art.RARITY.get(card["rarity"], Color.WHITE)
		var lift := (1.0 - ease(appear, 0.4)) * 40.0
		var rect := Rect2(Vector2(0, lift), size)
		draw_rect(rect, Color(0.04, 0.06, 0.1, 0.96 * appear))
		draw_rect(Rect2(rect.position, Vector2(size.x, 6)), Art.with_alpha(rarity, appear))
		draw_rect(rect, Art.with_alpha(rarity, 0.9 * appear), false, 3.0)
		# A card that unlocks a Resonance tier wears the element's colour and a badge, so it stands out while you choose.
		var unlocks_tier: int = card.get("unlocks_tier", 0)
		if unlocks_tier > 0:
			var tier_color: Color = TechData.ELEMENT_COLORS[card["element"]]
			var pulse := 0.6 + 0.4 * sin(Time.get_ticks_msec() / 160.0)
			draw_rect(rect.grow(4), Art.with_alpha(tier_color, pulse * appear), false, 4.0)
			var badge := Rect2(Vector2(size.x * 0.5 - 78, lift - 14), Vector2(156, 26))
			draw_rect(badge, Art.with_alpha(tier_color.darkened(0.35), appear))
			draw_rect(badge, Art.with_alpha(tier_color.lightened(0.3), appear), false, 2.0)
			draw_string(UiKit.font("bold"), badge.position + Vector2(0, 19), "RESONANCE %s" % UpgradeOffers.ROMAN[unlocks_tier],
				HORIZONTAL_ALIGNMENT_CENTER, badge.size.x, 14, Art.with_alpha(Color.WHITE, appear))
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
			var synergy_color: Color = TechData.ELEMENT_COLORS[element] if unlocks else TechData.ELEMENT_COLORS.get(element, Color(0.7, 0.8, 0.9))
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


## Cards ignore taps for this long after they appear, so a finger already moving can't land a pick.
const CARD_SETTLE_SECONDS := 0.5
## How far a finger may slide between touching and lifting and still count as a tap, not a slip.
const TAP_SLOP := 24.0


## A finger or the mouse coming down (the emulated mouse copy of a touch is ignored).
static func is_tap_down(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and event.pressed) or \
		(event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)


## A finger or the mouse lifting.
static func is_tap_up(event: InputEvent) -> bool:
	return (event is InputEventScreenTouch and not event.pressed) or \
		(event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.device != InputEvent.DEVICE_ID_EMULATION)


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


## The Salvage Crate: three slot-machine drums of gems spin and stop one by one; the crate gives one upgrade
## per gem. Each drum rolls its real strip of faces (UpgradeData.CRATE_REELS) round a curved window, blurs while
## it spins, and settles on its face with a little bounce. Then every upgrade it landed on is listed.
class CrateReel:
	extends Control
	var touched := false          # the finger came down here after the reels stopped
	var cards: Array = []
	var faces: Array = []          # what each reel landed on
	var reels: Array = []          # every face each reel can show while spinning
	var on_done: Callable
	var time := 0.0
	var spin_seconds := 2.3

	func _ready() -> void:
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _stop_time(reel_index: int) -> float:
		return spin_seconds * (0.45 + 0.27 * reel_index)


	## Where a drum is, in faces along its strip: it runs at full speed, then eases onto the landed face with
	## an overshoot (an ease-out-back curve), so it lands like a real reel catching its stop.
	func _drum_position(reel_index: int) -> float:
		var strip: Array = reels[reel_index]
		var landing := float(strip.find(faces[reel_index]))
		var travel := strip.size() * (3.0 + reel_index) + landing
		var x := clampf(time / _stop_time(reel_index), 0.0, 1.0)
		var back := 1.4
		var eased := 1.0 + (back + 1.0) * pow(x - 1.0, 3.0) + back * pow(x - 1.0, 2.0)
		return travel * eased


	## One drum: the faces around its current position, curved onto a cylinder (squashed and dimmed toward the
	## edges), with ghost copies trailing while it spins fast.
	func _draw_drum(rect: Rect2, reel_index: int) -> void:
		var strip: Array = reels[reel_index]
		var position := _drum_position(reel_index)
		var landed := time >= _stop_time(reel_index)
		var speed := absf(_drum_position_at(reel_index, time + 0.02) - position) / 0.02
		var radius := rect.size.y * 0.5
		var center := rect.get_center()
		var base := floori(position)
		for k in range(-2, 3):
			var index := base + k
			var offset := float(index) - position
			var angle := offset * 0.62
			if absf(angle) >= PI * 0.5:
				continue
			var face: int = strip[posmod(index, strip.size())]
			# Faces roll downward, like a real slot reel.
			var at := Vector2(center.x, center.y - sin(angle) * radius * 0.92)
			var squash := cos(angle)
			var on_payline := landed and k == 0 and absf(offset) < 0.05
			_draw_reel_face(at, face, squash, squash * (1.0 if on_payline or not landed else 0.45))
			if speed > 6.0:
				for trail: float in [0.18, 0.36]:
					# The blur trails above each face, where it's coming from.
					var ghost_angle := (offset + trail) * 0.62
					if absf(ghost_angle) < PI * 0.5:
						_draw_reel_face(Vector2(center.x, center.y - sin(ghost_angle) * radius * 0.92), face, cos(ghost_angle), 0.18)
		# Glass: darker at the drum's top and bottom edges, a highlight across the top, and the payline.
		for band in 6:
			var t := band / 6.0
			var shade := Color(0, 0, 0, 0.45 * (1.0 - t))
			draw_rect(Rect2(rect.position + Vector2(0, t * rect.size.y * 0.3), Vector2(rect.size.x, rect.size.y * 0.05)), shade)
			draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - (t + 1.0 / 6.0) * rect.size.y * 0.3), Vector2(rect.size.x, rect.size.y * 0.05)), shade)
		draw_rect(Rect2(rect.position + Vector2(4, 6), Vector2(rect.size.x - 8, 5)), Color(1, 1, 1, 0.12))
		var payline := Art.GOLD if landed else Color(1, 0.8, 0.4, 0.4)
		draw_line(Vector2(rect.position.x - 6, center.y), Vector2(rect.position.x + 2, center.y), payline, 3.0)
		draw_line(Vector2(rect.end.x - 2, center.y), Vector2(rect.end.x + 6, center.y), payline, 3.0)


	func _drum_position_at(reel_index: int, at_time: float) -> float:
		var keep := time
		time = at_time
		var position := _drum_position(reel_index)
		time = keep
		return position

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
		# Like a card: only a tap that starts here once the reels have stopped closes it.
		if Overlays.is_tap_down(event):
			touched = time > spin_seconds + 0.4
		elif Overlays.is_tap_up(event) and touched and on_done.is_valid():
			touched = false
			on_done.call()
			accept_event()

	## A reel face is gems, not digits: none, one or two, so it reads at a glance like a slot machine. squash
	## flattens it vertically as it rolls round the drum.
	func _draw_reel_face(center: Vector2, face: int, squash: float, alpha: float) -> void:
		if face == 0:
			# An empty socket: no gem on this reel (a dash would read as a minus sign next to the "+").
			draw_set_transform(center, 0.0, Vector2(1.0, squash))
			draw_arc(Vector2.ZERO, 14.0, 0, TAU, 20, Color(0.55, 0.45, 0.3, alpha), 3.0, true)
			draw_set_transform(Vector2.ZERO)
			return
		for g in face:
			var at := center + Vector2((g - (face - 1) * 0.5) * 34.0, 0)
			var tall := 20.0 * squash
			var gem := PackedVector2Array([at + Vector2(0, -tall), at + Vector2(14, 0), at + Vector2(0, tall), at + Vector2(-14, 0)])
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
				_draw_drum(rect, i)
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
	# Options you can change mid-mission (they only change what you see and hear).
	column.add_child(SettingsControls.slider("Music", "music"))
	column.add_child(SettingsControls.slider("Sound effects", "sfx"))
	column.add_child(SettingsControls.toggle("Screen shake", "screen_shake"))
	column.add_child(SettingsControls.toggle("Bullets glow in the dark", "bullet_glow"))
	# Saving the play log mid-mission, without leaving it (heromedel): it includes the mission so far.
	var log_button := UiKit.button("Save play log file", func(): pass, "Pause: save play log")
	log_button.pressed.connect(func(): log_button.text = "Saved: %s" % PlayLog.save_file().get_file())
	column.add_child(log_button)
	column.add_child(UiKit.button("Abandon mission", on_abandon, "Pause: Abandon"))
	return root
