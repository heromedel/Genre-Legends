class_name Hud
extends Control
## The in-mission heads-up display, drawn in screen space: armor and shield, level and XP, the objective,
## the boss bar, which tech is online, support meters, the dungeon minimap, arrows to objectives,
## banners, the boss WARNING, screen flashes and the low-armor vignette.
## Readable at a glance (Information & Feedback): numbers where they matter, colour everywhere else.

## How long a radio line stays up (GDD 9E): long enough to read during the transformation.
const RADIO_SECONDS := 5.0
## Boss health bars share one colour, unlike any of the player's own bars.
const BOSS_BAR_COLOR := Color(0.95, 0.2, 0.42)

var mission: Mission
var view_rect_world := Rect2()
var world_to_screen: Transform2D
var font_body: Font
var font_bold: Font
var font_title: Font

var banners: Array = []          # queued {text, style}
var banner_time := 0.0
var current_banner: Dictionary = {}
var warning_time := 0.0
var radio_text := ""
var radio_time := 0.0
var covered := false            # a card or crate screen is open: the radio waits underneath, unseen
var warning_name := ""
var warning_title := ""
var flash_color := Color.WHITE
var flash_amount := 0.0
var damage_vignette := 0.0
var time := 0.0
var armor_trail := -1.0         # the Armor bar's flash: where the bar was before the last hit, draining away

## How long a banner stays up: long enough to read comfortably, longer for longer lines (heromedel: 1.2 s
## was too fast even for a fast reader).
static func banner_seconds(text: String) -> float:
	return minf(2.0 + 0.04 * text.length(), 3.2)


const STYLE_COLORS := {
	"gold": Color(1.0, 0.8, 0.35), "red": Color(1.0, 0.35, 0.4), "cyan": Color(0.45, 0.9, 1.0),
	"violet": Color(0.8, 0.55, 1.0), "blue": Color(0.5, 0.75, 1.0),
	"energy": Color(0.45, 0.9, 1.0), "explosive": Color(1.0, 0.6, 0.3), "kinetic": Color(1.0, 0.85, 0.45), "mawjig": Color(0.85, 0.55, 1.0),
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	font_body = UiKit.font("body")
	font_bold = UiKit.font("bold")
	font_title = UiKit.font("title")


func show_banner(text: String, style: String) -> void:
	if banners.size() < 4:
		banners.append({"text": text, "style": style})


## One short line from the operations officer, shown for a few seconds (GDD 9E).
func show_radio(text: String) -> void:
	radio_text = text
	radio_time = RADIO_SECONDS
	Sound.play("radio")


func show_warning(boss_name: String, title: String) -> void:
	radio_time = minf(radio_time, 0.4)
	warning_time = 2.4
	warning_name = boss_name
	warning_title = title


func flash(color: Color, amount: float) -> void:
	flash_color = color
	flash_amount = maxf(flash_amount, amount)


func hurt() -> void:
	damage_vignette = 1.0


func tick(delta: float) -> void:
	time += delta
	flash_amount = maxf(flash_amount - delta * 2.5, 0.0)
	damage_vignette = maxf(damage_vignette - delta * 2.0, 0.0)
	warning_time = maxf(warning_time - delta, 0.0)
	if mission != null:
		# The ticks a hit took flash, then drain down to the bar over half a second.
		var armor := mission.player.armor
		armor_trail = armor if armor_trail < armor else move_toward(armor_trail, armor, delta * mission.player.max_armor * 0.5)
	queue_redraw()
	# While a card or crate screen is up, the radio and banners wait underneath, unseen and unspent.
	if covered:
		return
	radio_time = maxf(radio_time - delta, 0.0)
	if banner_time > 0.0:
		banner_time -= delta
	elif not banners.is_empty():
		current_banner = banners.pop_front()
		current_banner["length"] = banner_seconds(current_banner["text"])
		banner_time = current_banner["length"]
		# Its band is picked once, as it appears, so it doesn't jump when the boss moves.
		current_banner["y"] = _banner_height(get_viewport_rect().size) if mission != null else 220.0
	else:
		current_banner = {}


func _draw() -> void:
	if mission == null:
		return
	var screen := get_viewport_rect().size
	var player := mission.player
	var run := mission.run
	_draw_vignette(screen)
	_draw_objective_arrows(screen)
	# Armor, read as hits (GDD 13A), and the Shield Generator's charges.
	var x := 18.0
	var y := 16.0
	_armor_bar(Vector2(x, y), Vector2(250, 18), player)
	_shield_cells(Vector2(x, y + 25), player)
	# Level and XP.
	var level_at := Vector2(x, y + 44)
	draw_string(font_bold, level_at + Vector2(0, 16), "LV %d" % run.level, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.6, 1.0, 0.85))
	_bar(level_at + Vector2(52, 4), Vector2(198, 8), run.xp / run.xp_to_next, Color(0.5, 1.0, 0.4), "")
	# Support meters.
	var meter_y := level_at.y + 28.0
	if run.is_online("graze_engine"):
		var needed := mission.weapons.graze_needed()
		_bar(Vector2(x, meter_y), Vector2(150, 7), player.graze / needed if player.overdrive <= 0.0 else 1.0, Color(1, 0.85, 0.3), "")
		draw_string(font_body, Vector2(x + 158, meter_y + 8), "OVERDRIVE" if player.overdrive > 0.0 else "GRAZE", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.85, 0.4))
		meter_y += 14.0
	if run.is_online("overheat_core"):
		var heat_max := 60.0 - 4.0 * run.level_of("overheat_core")
		_bar(Vector2(x, meter_y), Vector2(150, 7), player.heat / heat_max, Color(1, 0.45, 0.25), "")
		draw_string(font_body, Vector2(x + 158, meter_y + 8), "HEAT", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.6, 0.4))
		meter_y += 14.0
	# Objective, in the HUD column under the bars: top centre is where a dungeon room's top door is
	# (heromedel couldn't see the doorways under it), and the boss bar takes that spot in a fight anyway.
	var objective := "COLLECT THE SALVAGE" if mission.world.prize_waiting else mission.stage.objective_text()
	if mission.state in ["won", "lost"]:
		objective = ""
	var shown_boss := mission.stage.active_boss()
	if shown_boss == null or shown_boss.entering:
		# A dark plate behind it, so over a boss's hull it still reads as HUD, not as part of the boss.
		if objective != "":
			var objective_at := Vector2(x, meter_y + 20.0)
			var text_width := font_bold.get_string_size(objective.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
			draw_rect(Rect2(objective_at + Vector2(-8, -19), Vector2(text_width + 16, 26)), Color(0.02, 0.04, 0.08, 0.6))
			draw_string_outline(font_bold, objective_at, objective.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, 5, Color(0, 0, 0, 0.7))
			draw_string(font_bold, objective_at, objective.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.9, 0.95, 1.0))
	else:
		_draw_boss_bar(screen)
	_draw_tech_chips(screen)
	if mission.stage is DungeonStage:
		_draw_minimap(screen, mission.stage)
	_draw_banner(screen)
	_draw_warning(screen)
	_draw_radio(screen)
	if flash_amount > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(flash_color.r, flash_color.g, flash_color.b, flash_amount * 0.6))


## The Armor bar as cells: one cell per 10 Armor (one bullet), a wider gap every three, so how many hits you
## have left can be counted at a glance (GDD 13A). The cells a hit just took flash white and drain away.
func _armor_bar(at: Vector2, size: Vector2, player: PlayerFrame) -> void:
	var maximum := maxf(player.max_armor, 1.0)
	var low := player.armor / maximum < 0.34
	var color := Color(1.0, 0.62, 0.25) if not low else Color(1.0, 0.35, 0.25).lerp(Color(1.0, 0.62, 0.25), 0.5 + 0.5 * sin(time * 8.0))
	var cells := int(ceil(maximum / 10.0 - 0.01))
	var gap := 3.0
	var group_gap := 7.0
	var cell_width := (size.x - gap * (cells - 1) - (group_gap - gap) * ((cells - 1) / 3)) / cells
	draw_rect(Rect2(at - Vector2(3, 3), size + Vector2(6, 6)), Color(0, 0, 0, 0.55))
	var x := at.x
	for i in cells:
		var low_edge := i * 10.0
		var high_edge := minf((i + 1) * 10.0, maximum)
		var cell := Rect2(Vector2(x, at.y), Vector2(cell_width * (high_edge - low_edge) / 10.0, size.y))
		draw_rect(cell, color.darkened(0.78))
		var filled := clampf((player.armor - low_edge) / (high_edge - low_edge), 0.0, 1.0)
		var flashing := clampf((armor_trail - low_edge) / (high_edge - low_edge), 0.0, 1.0)
		if flashing > filled:
			draw_rect(Rect2(cell.position, Vector2(cell.size.x * flashing, cell.size.y)), Color(1, 1, 1, 0.85))
		if filled > 0.0:
			draw_rect(Rect2(cell.position, Vector2(cell.size.x * filled, cell.size.y)), color)
			draw_rect(Rect2(cell.position, Vector2(cell.size.x * filled, cell.size.y * 0.35)), Color(1, 1, 1, 0.25))
		x += cell_width + (group_gap if (i + 1) % 3 == 0 else gap)
	draw_string_outline(font_bold, at + Vector2(size.x + 10, size.y - 3), "ARMOR %d" % ceili(player.armor), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, 4, Color(0, 0, 0, 0.7))
	draw_string(font_bold, at + Vector2(size.x + 10, size.y - 3), "ARMOR %d" % ceili(player.armor), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, color.lightened(0.2))


## Shield Generator charges as bright cells under the Armor bar: full ones glow, an empty one fills as it
## recharges, so "shield up" and "recharging" read at a glance.
func _shield_cells(at: Vector2, player: PlayerFrame) -> void:
	if player.max_shield_charges <= 0:
		return
	var recharge_total := mission.world.shield_recharge_seconds()
	for i in player.max_shield_charges:
		var cell := Rect2(at + Vector2(i * 46, 0), Vector2(40, 12))
		draw_rect(cell.grow(3), Color(0, 0, 0, 0.6))
		if i < player.shield_charges:
			var pulse := 0.85 + 0.15 * sin(time * 5.0)
			draw_rect(cell.grow(2), Color(0.45, 0.88, 1.0, 0.35 * pulse))
			draw_rect(cell, Color(0.5, 0.92, 1.0) * pulse)
			draw_rect(Rect2(cell.position, Vector2(cell.size.x, 4)), Color(1, 1, 1, 0.5))
		else:
			draw_rect(cell, Color(0.08, 0.15, 0.22))
			var filled := 1.0 - clampf(player.shield_recharge / recharge_total, 0.0, 1.0) if i == player.shield_charges else 0.0
			draw_rect(Rect2(cell.position, Vector2(cell.size.x * filled, cell.size.y)), Color(0.25, 0.55, 0.75))
	draw_string_outline(font_bold, at + Vector2(player.max_shield_charges * 46 + 4, 11), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.7))
	draw_string(font_bold, at + Vector2(player.max_shield_charges * 46 + 4, 11), "SHIELD", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.92, 1.0))


func _bar(at: Vector2, size: Vector2, fraction: float, color: Color, text: String) -> void:
	draw_rect(Rect2(at - Vector2(2, 2), size + Vector2(4, 4)), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(at, size), color.darkened(0.75))
	draw_rect(Rect2(at, Vector2(size.x * clampf(fraction, 0.0, 1.0), size.y)), color)
	draw_rect(Rect2(at, Vector2(size.x * clampf(fraction, 0.0, 1.0), size.y * 0.35)), Color(1, 1, 1, 0.25))
	if text != "":
		draw_string(font_bold, at + Vector2(6, size.y - 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, int(size.y), Color(0.1, 0.05, 0.0))


func _draw_boss_bar(screen: Vector2) -> void:
	var boss := mission.stage.active_boss()
	var width := minf(screen.x * 0.5, 560.0)
	var at := Vector2((screen.x - width) * 0.5, 14)
	draw_string_outline(font_title, at + Vector2(0, 16), boss.boss_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, width, 16, 5, Color(0, 0, 0, 0.8))
	draw_string(font_title, at + Vector2(0, 16), boss.boss_name.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, width, 16, boss.color.lightened(0.3))
	# Every boss bar is the same crimson in a dark frame, never your armor's orange or your shield's blue.
	draw_rect(Rect2(at + Vector2(-5, 19), Vector2(width + 10, 22)), Color(0.35, 0.02, 0.08, 0.85))
	_bar(at + Vector2(0, 24), Vector2(width, 12), boss.hp_fraction(), BOSS_BAR_COLOR, "")
	# Ticks for phase thresholds.
	for threshold in [0.66, 0.33]:
		draw_line(at + Vector2(width * threshold, 22), at + Vector2(width * threshold, 38), Color(0, 0, 0, 0.6), 2.0)


## Equipped tech along the bottom left: lit when online, dim when still offline, with level pips.
func _draw_tech_chips(screen: Vector2) -> void:
	var run := mission.run
	var size := 46.0
	var at := Vector2(16, screen.y - size - 16)
	for tech_id in run.loadout:
		if tech_id == "":
			continue
		var online := run.is_online(tech_id)
		var color := TechData.element_color(tech_id) if online else Color(0.4, 0.45, 0.55)
		var rect := Rect2(at, Vector2(size, size))
		draw_rect(rect, Color(0.03, 0.05, 0.09, 0.8))
		draw_rect(rect, Art.with_alpha(color, 0.9 if online else 0.4), false, 2.0)
		IconPainter.draw(self, tech_id, rect.grow(-9), Art.with_alpha(color, 1.0 if online else 0.5))
		var level := run.level_of(tech_id)
		var cap: int = run.tech_cap.get(tech_id, 3)
		for pip in cap:
			var pip_rect := Rect2(at + Vector2(4 + pip * 8, size - 7), Vector2(6, 4))
			draw_rect(pip_rect, color if pip < level else Color(0.2, 0.22, 0.28))
		if run.fork_of(tech_id) != "":
			draw_circle(at + Vector2(size - 6, 6), 4.0, Color(0.85, 0.55, 1.0))
		at.x += size + 8
	# Resonance: one chip per element you've put points into, with its tier.
	at.x += 6
	for element in UpgradeData.ELEMENTS:
		var tier := run.resonance_tier(element)
		if tier <= 0:
			continue
		var color: Color = TechData.ELEMENT_COLORS[element]
		var center := at + Vector2(16, size * 0.5)
		var diamond := PackedVector2Array([center + Vector2(0, -15), center + Vector2(15, 0), center + Vector2(0, 15), center + Vector2(-15, 0)])
		draw_colored_polygon(diamond, Art.with_alpha(color, 0.25 + 0.2 * tier))
		draw_polyline(diamond + PackedVector2Array([diamond[0]]), color, 2.0, true)
		draw_string(font_bold, center + Vector2(-16, 6), UpgradeOffers.ROMAN[tier], HORIZONTAL_ALIGNMENT_CENTER, 32, 14, Color(1, 1, 1))
		at.x += 38


func _draw_minimap(screen: Vector2, stage: DungeonStage) -> void:
	var cell := Vector2(30, 20)
	var origin := Vector2(screen.x - 260, 70)
	var min_key := Vector2i(999, 999)
	for key: Vector2i in stage.rooms:
		min_key = Vector2i(mini(min_key.x, key.x), mini(min_key.y, key.y))
	for key: Vector2i in stage.rooms:
		var room: Dictionary = stage.rooms[key]
		var seen: bool = room["visited"]
		var neighbour_seen := false
		for d in room["doors"]:
			if stage.rooms[room["doors"][d]]["visited"]:
				neighbour_seen = true
		if key == stage.secret_room and not seen:
			continue
		if not seen and not neighbour_seen:
			continue
		var at := origin + Vector2(key - min_key) * (cell + Vector2(4, 4))
		var color := Color(0.35, 0.45, 0.6, 0.85) if seen else Color(0.2, 0.25, 0.32, 0.6)
		if key == stage.current:
			color = Color(0.5, 0.95, 1.0)
		draw_rect(Rect2(at, cell), color)
		if key == stage.boss_room:
			draw_circle(at + cell * 0.5, 4.0, Color(1, 0.3, 0.35))
		elif room["kind"] == "treasure" and seen:
			draw_circle(at + cell * 0.5, 3.5, Art.GOLD)
		elif key == stage.key_room and not stage.has_key and seen:
			draw_circle(at + cell * 0.5, 3.5, Color(1, 0.9, 0.4))


## Arrows at the screen edge pointing to objectives that are off screen.
func _draw_objective_arrows(screen: Vector2) -> void:
	var targets: Array = mission.stage.objective_positions() if mission.stage.has_method("objective_positions") else []
	# The last few enemies in a locked dungeon room get arrows too, so none hides under the HUD.
	if mission.stage is DungeonStage:
		var last_ones: Array = (mission.stage as DungeonStage).room_enemies_left()
		if last_ones.size() <= 3:
			targets = targets + last_ones.map(func(e): return e.pos)
	# A dropped projector gets a green arrow, like a pickup (GDD 11E).
	var projectors: Array = mission.world.pickups.filter(func(p): return p.kind in ["projector", "prize"]).map(func(p): return p.pos)
	var center := screen * 0.5
	for target: Vector2 in targets + projectors:
		var on_screen := world_to_screen * target
		# On screen and clear of the HUD's corners? No arrow needed.
		if Rect2(Vector2(150, 110), screen - Vector2(300, 220)).has_point(on_screen):
			continue
		var direction := (on_screen - center).normalized()
		var edge := center + direction * minf(absf((screen.x * 0.5 - 50) / maxf(absf(direction.x), 0.01)), absf((screen.y * 0.5 - 50) / maxf(absf(direction.y), 0.01)))
		var pulse := 0.7 + 0.3 * sin(time * 5.0)
		var tip := edge + direction * 16.0
		var arrow_color := Color(0.5, 1.0, 0.5, pulse) if projectors.has(target) else Color(1, 0.75, 0.3, pulse)
		draw_colored_polygon(PackedVector2Array([tip, edge + direction.orthogonal() * 11.0, edge - direction.orthogonal() * 11.0]), arrow_color)


func _draw_banner(screen: Vector2) -> void:
	# Banners wait while a card or crate screen is up, so a big moment is never hidden behind one.
	if current_banner.is_empty() or covered:
		return
	var color: Color = STYLE_COLORS.get(current_banner["style"], Color.WHITE)
	var t: float = current_banner["length"] - banner_time
	var slide := ease(clampf(t / 0.2, 0.0, 1.0), 0.3)
	var fade := clampf(banner_time / 0.3, 0.0, 1.0)
	var y: float = current_banner["y"]
	var band := Rect2(Vector2(0, y - 26), Vector2(screen.x, 36))
	draw_rect(band, Color(0, 0, 0, 0.62 * fade))
	draw_line(band.position, band.position + Vector2(screen.x * slide, 0), Art.with_alpha(color, fade), 2.0)
	draw_line(band.end - Vector2(screen.x * slide, 0), band.end, Art.with_alpha(color, fade), 2.0)
	draw_string_outline(font_title, Vector2(0, y), current_banner["text"], HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, 9, Color(0, 0, 0, fade))
	draw_string(font_title, Vector2(0, y), current_banner["text"], HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Art.with_alpha(color.lightened(0.55), fade))


## Banners sit below the HUD bars and the radio box, so nothing piles up at the top (0.2.2 cold review).
## In a boss fight they take whichever band, upper or lower, is further from both the boss and you,
## so they never cut through either (0.4 cold review).
func _banner_height(screen: Vector2) -> float:
	var upper := maxf(screen.y * 0.3, 250.0)
	var boss := mission.stage.active_boss()
	if boss == null:
		return upper
	var lower := screen.y * 0.66
	var boss_y := (world_to_screen * boss.origin).y
	var player_y := (world_to_screen * mission.player.pos).y
	var clearance := func(band_y: float) -> float: return minf(absf(band_y - boss_y), absf(band_y - player_y))
	return upper if clearance.call(upper) >= clearance.call(lower) else lower


## The shooter-genre boss intro: flashing red WARNING with hazard stripes and the boss's name.
func _draw_warning(screen: Vector2) -> void:
	if warning_time <= 0.0:
		return
	var blink := 0.55 + 0.45 * float(int(warning_time * 6.0) % 2)
	var fade := clampf(warning_time / 0.4, 0.0, 1.0)
	var y := screen.y * 0.42
	draw_rect(Rect2(Vector2(0, y - 70), Vector2(screen.x, 140)), Color(0.25, 0, 0.02, 0.4 * fade))
	var stripe := 40.0
	var offset := fmod(time * 120.0, stripe * 2.0)
	for band_y in [y - 70.0, y + 58.0]:
		var sx := -stripe * 2.0 + offset
		while sx < screen.x:
			draw_colored_polygon(PackedVector2Array([Vector2(sx, band_y), Vector2(sx + stripe, band_y), Vector2(sx + stripe + 12, band_y + 12), Vector2(sx + 12, band_y + 12)]), Color(1, 0.75, 0.1, 0.85 * fade))
			sx += stripe * 2.0
	draw_string_outline(font_title, Vector2(0, y + 4), "WARNING", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 56, 8, Color(0, 0, 0, fade))
	draw_string(font_title, Vector2(0, y + 4), "WARNING", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 56, Color(1, 0.2, 0.25, blink * fade))
	draw_string(font_bold, Vector2(0, y + 38), "%s  —  %s" % [warning_name.to_upper(), warning_title], HORIZONTAL_ALIGNMENT_CENTER, screen.x, 18, Color(1, 0.85, 0.8, fade))


func _draw_radio(screen: Vector2) -> void:
	if radio_time <= 0.0 or covered:
		return
	var fade := clampf(radio_time / 0.4, 0.0, 1.0) * clampf((RADIO_SECONDS - radio_time) / 0.3, 0.0, 1.0)
	var width := minf(screen.x * 0.42, 480.0)
	var box := Rect2(Vector2(16, 136), Vector2(width, 78))
	draw_rect(box, Color(0.02, 0.06, 0.1, 0.7 * fade))
	draw_rect(box, Color(0.4, 0.85, 1.0, 0.9 * fade), false, 2.5)
	# A blinking "on air" light and the officer's name.
	var blink := 0.5 + 0.5 * float(int(radio_time * 3.0) % 2)
	draw_circle(box.position + Vector2(18, 20), 5.0, Color(0.3, 1.0, 0.6, fade * blink))
	draw_string(font_bold, box.position + Vector2(30, 25), "OPS  " + Radio.OFFICER.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.9, 1.0, fade))
	draw_multiline_string(font_body, box.position + Vector2(12, 48), radio_text, HORIZONTAL_ALIGNMENT_LEFT, width - 24, 16, 2, Color(1, 1, 1, fade))


func _draw_vignette(screen: Vector2) -> void:
	var low := 1.0 - clampf(mission.player.armor_fraction() / 0.3, 0.0, 1.0)
	var amount := maxf(damage_vignette * 0.6, low * (0.35 + 0.15 * sin(time * 6.0)))
	if amount <= 0.01:
		return
	# Darkness with a clear centre, tinted red: the screen edges close in when you're hurt.
	draw_texture_rect(Art.vignette(), Rect2(-screen * 0.1, screen * 1.2), false, Color(1, 0.1, 0.08, amount))
