class_name StarMapView
extends Control
## The star map canvas (GDD 5C, 5D): drag to pan, tap a planet to see what it needs.
## Cleared planets are ticked, reachable ones pulse, locked ones sit dim. Themed branches are traced
## in gold with their prize shown up front. Each region carries its name across the map.

signal node_selected(node_id: String)

var star_map: StarMap
var selected := ""
var offset := Vector2.ZERO          # pan offset in map units
var time := 0.0
var _drag_from := Vector2.ZERO
var _dragging := false
var _drag_distance := 0.0
var _press_pos := Vector2.ZERO
var _stars := PackedVector2Array()


var _centered := false
## The map is laid out for about this much height; a shorter view zooms out a little so a whole region
## still fits top to bottom (the planet card sits under the map).
const FIT_HEIGHT := 620.0
var zoom := 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(func():
		zoom = clampf(size.y / FIT_HEIGHT, 0.72, 1.0)
		if not _centered and size.x > 10.0 and selected != "":
			_centered = true
			center_on(selected))
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 260:
		_stars.append(Vector2(rng.randf() * 3000.0, rng.randf() * 1400.0))


func is_cleared(node_id: String) -> bool:
	return Save.is_cleared(node_id)


func center_on(node_id: String) -> void:
	if star_map.get_node(node_id).is_empty():
		return
	# The selected planet sits in the left fifth, with the routes ahead of it filling the rest; vertically the
	# map's rows are centred, with room above them for the region's name.
	var top := INF
	var bottom := -INF
	for other in star_map.all_node_ids():
		var y := star_map.position_of(other).y
		top = minf(top, y)
		bottom = maxf(bottom, y)
	offset = Vector2(-star_map.position_of(node_id).x - _view().x * 0.3, -(top + bottom) * 0.5 + 20.0)
	_clamp_offset()


## The view's size in map units: the canvas is drawn zoomed, so everything inside works in these.
func _view() -> Vector2:
	return size / zoom


func _map_to_screen(at: Vector2) -> Vector2:
	return _view() * 0.5 + at + offset


func _process(delta: float) -> void:
	time += delta
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventMouse):
		return
	var at: Vector2 = event.position / zoom
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_dragging = true
			_drag_from = at
			_press_pos = at
			_drag_distance = 0.0
		else:
			_dragging = false
			if _drag_distance < 14.0:
				_tap(at)
	elif event is InputEventMouseMotion and _dragging:
		offset += at - _drag_from
		_drag_distance += (at - _drag_from).length()
		_drag_from = at
		_clamp_offset()
	elif event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		offset.x += 60.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -60.0
		_clamp_offset()


func _clamp_offset() -> void:
	var last_column := star_map.columns.size() - 1
	var max_x := last_column * StarMap.COLUMN_SPACING
	offset.x = clampf(offset.x, -max_x - 200.0, 200.0)
	offset.y = clampf(offset.y, -420.0, 420.0)


func _tap(at: Vector2) -> void:
	var best := ""
	var best_distance := 60.0
	for node_id in star_map.all_node_ids():
		var d := _map_to_screen(star_map.position_of(node_id)).distance_to(at)
		if d < best_distance:
			best_distance = d
			best = node_id
	if best != "":
		selected = best
		PlayLog.button("Star map: planet %s (%s)" % [star_map.get_node(best)["name"], best])
		Sound.play("ui")
		node_selected.emit(best)
	else:
		# Screen pixels, not map units, so a log reader can match it to what was on screen.
		PlayLog.note("tap", "tapped empty space on the star map at screen (%d, %d)" % [at.x * zoom + global_position.x, at.y * zoom + global_position.y])


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(zoom, zoom))
	var screen := _view()
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.02, 0.03, 0.07))
	for star in _stars:
		var at := Vector2(fposmod(star.x + offset.x * 0.3, screen.x + 100.0) - 50.0, fposmod(star.y + offset.y * 0.3, screen.y + 100.0) - 50.0)
		draw_rect(Rect2(at, Vector2(1.5, 1.5)), Color(0.7, 0.8, 1.0, 0.35 + 0.2 * sin(time + star.x)))
	# Faint console grid.
	var grid := 80.0
	var gx := fposmod(offset.x, grid)
	while gx < screen.x:
		draw_line(Vector2(gx, 0), Vector2(gx, screen.y), Color(0.3, 0.5, 0.8, 0.05), 1.0)
		gx += grid
	var gy := fposmod(offset.y, grid)
	while gy < screen.y:
		draw_line(Vector2(0, gy), Vector2(screen.x, gy), Color(0.3, 0.5, 0.8, 0.05), 1.0)
		gy += grid
	_draw_region_names()
	_draw_links()
	for node_id in star_map.all_node_ids():
		_draw_planet(node_id)


func _draw_region_names() -> void:
	var font := UiKit.font("title")
	for region in star_map.regions.size():
		var x := region * (StarMap.COLUMNS_PER_REGION + 1) * StarMap.COLUMN_SPACING - 60.0
		var at := _map_to_screen(Vector2(x, -330))
		# While the region is in view, its name stays pinned inside the left edge instead of sliding off it.
		var region_end := _map_to_screen(Vector2(x + StarMap.COLUMNS_PER_REGION * StarMap.COLUMN_SPACING, -330)).x
		at.x = maxf(at.x, minf(16.0, region_end - 440.0))
		at.y = maxf(at.y, 40.0)
		var palette: Dictionary = star_map.regions[region]["palette"]
		draw_string(font, at, star_map.regions[region]["name"].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Art.with_alpha(palette["accent"], 0.35))
		draw_line(at + Vector2(0, 12), at + Vector2(420, 12), Art.with_alpha(palette["accent"], 0.2), 2.0)


func _draw_links() -> void:
	for node_id in star_map.all_node_ids():
		var node := star_map.get_node(node_id)
		var from := _map_to_screen(star_map.position_of(node_id))
		for to_id in node["links"]:
			var to := _map_to_screen(star_map.position_of(to_id))
			var target := star_map.get_node(to_id)
			var travelled := is_cleared(node_id)
			var branch: bool = target["branch"] != ""
			var color := Color(1.0, 0.8, 0.35) if branch else Color(0.45, 0.75, 1.0)
			color.a = 0.75 if travelled else 0.22
			if branch:
				_dashed_line(from, to, color, 3.0)
			else:
				draw_line(from, to, color, 3.0 if travelled else 2.0, true)
			if travelled and not is_cleared(to_id):
				var t := fmod(time * 0.6, 1.0)
				draw_circle(from.lerp(to, t), 3.5, Color(1, 1, 1, 0.8))


func _dashed_line(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	var length := from.distance_to(to)
	var steps := int(length / 14.0)
	for i in range(0, steps, 2):
		draw_line(from.lerp(to, float(i) / steps), from.lerp(to, float(i + 1) / steps), color, width, true)


func _draw_planet(node_id: String) -> void:
	var node := star_map.get_node(node_id)
	var at := _map_to_screen(star_map.position_of(node_id))
	if not Rect2(Vector2(-80, -80), _view() + Vector2(160, 160)).has_point(at):
		return
	var cleared := is_cleared(node_id)
	var available := star_map.is_available(node_id, is_cleared)
	var palette: Dictionary = star_map.regions[node["region"]]["palette"]
	var type_colors := {"star_cluster": Color(0.45, 0.8, 1.0), "corridor": Color(0.6, 1.0, 0.75), "planet": Color(1.0, 0.7, 0.35), "dungeon": Color(0.8, 0.55, 1.0)}
	var accent: Color = type_colors.get(node["type"], palette["accent"])
	var locked := not cleared and not available
	# Locked planets read as out of reach at a glance: grey, smaller and quiet, so the ones you can fly stand out
	# (the blind playtester couldn't tell them apart).
	var radius := (34.0 if node["is_gate"] else 26.0) * (0.82 if locked else 1.0)
	var dim := 0.6 if locked else 1.0
	var look_rng := RandomNumberGenerator.new()
	look_rng.seed = node["planet_look"]
	var body := accent.darkened(0.5 + look_rng.randf() * 0.2).lerp(palette["ground"], 0.4)
	if locked:
		accent = accent.lerp(Color(0.45, 0.48, 0.55), 0.8)
		body = body.lerp(Color(0.22, 0.24, 0.28), 0.8)
	if available and not cleared:
		var pulse := 0.5 + 0.5 * sin(time * 3.0)
		draw_arc(at, radius + 10.0 + pulse * 4.0, 0, TAU, 32, Art.with_alpha(accent, 0.5 * pulse + 0.2), 2.5, true)
	if node_id == selected:
		draw_arc(at, radius + 16.0, time, time + TAU * 0.8, 32, Color(1, 1, 1, 0.9), 3.0, true)
	draw_circle(at, radius, Art.with_alpha(body.darkened(0.3), dim))
	draw_circle(at + Vector2(-radius * 0.25, -radius * 0.25), radius * 0.72, Art.with_alpha(body.lightened(0.15), dim))
	draw_circle(at + Vector2(-radius * 0.4, -radius * 0.4), radius * 0.25, Art.with_alpha(body.lightened(0.45), dim * 0.6))
	if look_rng.randf() < 0.4 or node["is_gate"]:
		draw_arc(at, radius * 1.45, 2.7, 6.9, 24, Art.with_alpha(accent, 0.6 * dim), 3.0, true)
	if node["is_gate"]:
		Art.dashed_circle(self, at, radius + 24.0, Art.with_alpha(Color(1, 0.4, 0.4), 0.7 * dim), 3.0, 8, time * 0.6)
	IconPainter.draw(self, node["type"], Rect2(at - Vector2(15, radius + 38), Vector2(30, 30)), Art.with_alpha(accent, dim))
	if cleared:
		draw_circle(at + Vector2(radius * 0.7, radius * 0.7), 10.0, Color(0.1, 0.4, 0.2))
		IconPainter.draw(self, "check", Rect2(at + Vector2(radius * 0.7 - 8, radius * 0.7 - 8), Vector2(16, 16)), Color(0.6, 1, 0.7))
	elif not available:
		IconPainter.draw(self, "lock", Rect2(at - Vector2(8, 8), Vector2(16, 16)), Color(0.6, 0.65, 0.75, 0.7))
	if node["prize"] != "" and not cleared:
		IconPainter.draw(self, "prize", Rect2(at + Vector2(radius * 0.6, -radius - 6), Vector2(22, 22)), Art.GOLD)
	var label_color := Color(0.55, 0.58, 0.65) if locked else Color(0.85, 0.92, 1.0)
	draw_string(UiKit.font("bold"), at + Vector2(-80, radius + 24), node["name"], HORIZONTAL_ALIGNMENT_CENTER, 160, 16, label_color)
	if available and not cleared:
		draw_string(UiKit.font("bold"), at + Vector2(-80, radius + 42), "NEXT", HORIZONTAL_ALIGNMENT_CENTER, 160, 13, Art.with_alpha(Art.GOLD, 0.7 + 0.3 * sin(time * 3.0)))
	if node["branch"] != "" and node_id.ends_with("_0"):
		draw_string(UiKit.font("bold"), at + Vector2(-110, -radius - 44), node["branch_name"].to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 220, 15, Art.with_alpha(Art.GOLD, 0.9))
