class_name BackgroundArt
extends RefCounted
## Backgrounds for each mission type: parallax space with nebulae for the shooters, armored trench walls
## for the corridor, a textured planet surface with rocks and craters, and stone dungeon rooms with
## torches and doors that tell you what they are (open, sealed, boss, locked).

var palette: Dictionary
var stars: Array = []           # three layers of PackedVector2Array
var decor: Array = []           # planet surface decorations {pos, kind, size, rot}
var seed_value := 0
var ground: Texture2D
var nebula_a: Texture2D
var nebula_b: Texture2D
var floor_texture: Texture2D


func _init(region_palette: Dictionary, background_seed: int) -> void:
	palette = region_palette
	seed_value = background_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = background_seed
	for layer in 3:
		var points := PackedVector2Array()
		for i in 70 + layer * 30:
			points.append(Vector2(rng.randf() * 1400.0, rng.randf() * 1000.0))
		stars.append(points)
	var sky: Color = palette["sky"]
	var nebula: Color = palette["nebula"]
	nebula_a = Art.nebula_texture("nebula_a_%d" % (background_seed % 7), background_seed % 7, nebula)
	nebula_b = Art.nebula_texture("nebula_b_%d" % (background_seed % 5), 99 + background_seed % 5, nebula.lerp(Color(0.6, 0.3, 0.8), 0.4))


func prepare_planet(world_size: Vector2) -> void:
	var g: Color = palette["ground"]
	ground = Art.noise_texture("ground_%d_%s" % [seed_value % 9, g.to_html()], seed_value % 9, 256, 0.025, g.darkened(0.45), g.lightened(0.28), 5)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 7
	for i in 260:
		var kinds := ["crater", "crater", "pebbles", "crystal", "grass", "grass"]
		decor.append({"pos": Vector2(rng.randf() * world_size.x, rng.randf() * world_size.y),
			"kind": kinds[rng.randi() % kinds.size()], "size": rng.randf_range(10, 46), "rot": rng.randf() * TAU})


func prepare_dungeon() -> void:
	if Art._cache.has("dungeon_floor"):
		floor_texture = Art._cache["dungeon_floor"]
		return
	var size := 128
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var noise := FastNoiseLite.new()
	noise.seed = 4
	noise.frequency = 0.08
	for y in size:
		for x in size:
			var tile := Vector2i(x / 32, y / 32)
			var mortar := x % 32 < 2 or y % 32 < 2
			var tone := 0.13 + noise.get_noise_2d(x, y) * 0.03 + float((tile.x * 7 + tile.y * 13) % 5) * 0.006
			var color := Color(tone, tone * 0.95, tone * 1.1) if not mortar else Color(0.06, 0.055, 0.07)
			image.set_pixel(x, y, color)
	floor_texture = ImageTexture.create_from_image(image)
	Art._cache["dungeon_floor"] = floor_texture


# ---------------------------------------------------------------- space

func draw_space(ci: CanvasItem, view: Rect2, scroll: float, time: float, far_planet: bool = true) -> void:
	ci.draw_rect(view, palette["sky"])
	var region_a := Rect2(Vector2(view.position.x * 0.3, view.position.y - scroll * 0.25) / 3.0, view.size / 3.0)
	ci.draw_texture_rect_region(nebula_a, view, region_a, Color(1, 1, 1, 0.9))
	var region_b := Rect2(Vector2(view.position.x * 0.5 + 300.0, view.position.y - scroll * 0.5) / 2.2, view.size / 2.2)
	ci.draw_texture_rect_region(nebula_b, view, region_b, Color(1, 1, 1, 0.55))
	# A far planet drifts by.
	if far_planet:
		var planet_at := view.position + Vector2(view.size.x * 0.78, fmod(scroll * 0.06 + 300.0, view.size.y + 600.0) - 300.0)
		ci.draw_circle(planet_at, 120.0, palette["ground"].darkened(0.2))
		ci.draw_circle(planet_at + Vector2(-30, -30), 96.0, palette["ground"].lightened(0.05))
		ci.draw_arc(planet_at, 170.0, -0.3, PI + 0.3, 40, Art.with_alpha(palette["accent"], 0.25), 6.0, true)
	for layer in 3:
		var speed: float = [0.15, 0.4, 0.9][layer]
		var size: float = [1.2, 1.8, 2.6][layer]
		var alpha: float = [0.45, 0.7, 1.0][layer]
		for star: Vector2 in stars[layer]:
			var y := fposmod(star.y + scroll * speed, 1000.0) - 100.0
			var at := view.position + Vector2(fposmod(star.x, view.size.x + 40.0) - 20.0, y * view.size.y / 800.0)
			if layer == 2:
				ci.draw_line(at, at + Vector2(0, 6.0 + speed * 4.0), Color(0.9, 0.95, 1.0, alpha * 0.6), size)
			else:
				ci.draw_rect(Rect2(at, Vector2(size, size)), Color(0.85, 0.9, 1.0, alpha * (0.7 + 0.3 * sin(time * 2.0 + star.x))))


# ---------------------------------------------------------------- corridor

func draw_corridor_walls(ci: CanvasItem, stage: CorridorStage, time: float) -> void:
	var metal := Color(0.16, 0.18, 0.24)
	var edge: Color = palette["accent"]
	var step := 20.0
	for side in [0, 1]:
		var outer_x := -260.0 if side == 0 else 1460.0
		var edge_line := PackedVector2Array()
		var y := -60.0
		while y <= 880.0:
			var x0 := stage.left_edge(y) if side == 0 else stage.right_edge(y)
			var x1 := stage.left_edge(y + step) if side == 0 else stage.right_edge(y + step)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(outer_x, y), Vector2(x0, y), Vector2(x1, y + step), Vector2(outer_x, y + step)]), metal)
			# A darker inner band gives the wall some depth.
			var inset := 26.0 if side == 0 else -26.0
			ci.draw_colored_polygon(PackedVector2Array([Vector2(x0 - inset, y), Vector2(x0, y), Vector2(x1, y + step), Vector2(x1 - inset, y + step)]), metal.lightened(0.12))
			edge_line.append(Vector2(x0, y))
			y += step
		ci.draw_polyline(edge_line, edge.darkened(0.2), 4.0, true)
		ci.draw_polyline(edge_line, Color(1, 1, 1, 0.5), 1.0, true)
	# Panel seams and blinking lights scroll with the corridor.
	var seam_offset := fposmod(stage.distance, 120.0)
	var y2 := -120.0 + seam_offset
	while y2 < 860.0:
		var left := stage.left_edge(y2)
		var right := stage.right_edge(y2)
		ci.draw_line(Vector2(left - 140, y2), Vector2(left - 8, y2), Color(0.1, 0.11, 0.15), 3.0)
		ci.draw_line(Vector2(right + 8, y2), Vector2(right + 140, y2), Color(0.1, 0.11, 0.15), 3.0)
		var blink := 0.3 + 0.7 * float(int(time * 3.0 + y2 * 0.01) % 2)
		ci.draw_circle(Vector2(left - 24, y2 + 30), 3.0, Art.with_alpha(edge, blink))
		ci.draw_circle(Vector2(right + 24, y2 + 30), 3.0, Art.with_alpha(edge, blink))
		if right - left < 470.0:
			for i in 4:
				ci.draw_line(Vector2(left - 12 - i * 14, y2 + 50), Vector2(left - 26 - i * 14, y2 + 70), Color(1, 0.75, 0.2, 0.7), 4.0)
				ci.draw_line(Vector2(right + 12 + i * 14, y2 + 50), Vector2(right + 26 + i * 14, y2 + 70), Color(1, 0.75, 0.2, 0.7), 4.0)
		y2 += 120.0


# ---------------------------------------------------------------- planet

func draw_planet(ci: CanvasItem, view: Rect2, world: World, time: float) -> void:
	ci.draw_rect(view, Color(0.03, 0.03, 0.04))
	var bounds := world.bounds
	var visible := view.intersection(bounds)
	if visible.size.x > 0.0:
		ci.draw_texture_rect_region(ground, visible, Rect2(visible.position / 2.0, visible.size / 2.0))
	for item in decor:
		var at: Vector2 = item["pos"]
		if not view.grow(60).has_point(at):
			continue
		var size: float = item["size"]
		match item["kind"]:
			"crater":
				ci.draw_circle(at, size, Color(0, 0, 0, 0.18))
				ci.draw_arc(at, size, 3.6, 6.0, 12, Color(1, 1, 1, 0.08), 3.0)
				ci.draw_arc(at, size, 0.5, 2.9, 12, Color(0, 0, 0, 0.2), 3.0)
			"pebbles":
				for i in 4:
					ci.draw_circle(at + Vector2.from_angle(item["rot"] + i * 1.7) * size * 0.4, 3.0 + i, palette["ground"].lightened(0.15))
			"crystal":
				var accent: Color = palette["accent"]
				ci.draw_circle(at, size * 0.6, Art.with_alpha(accent, 0.12))
				for i in 3:
					var tip := at + Vector2.from_angle(item["rot"] + i * 0.5 - 0.5) * size * 0.8
					ci.draw_colored_polygon(PackedVector2Array([at + Vector2(-5, 0).rotated(i), tip, at + Vector2(5, 0).rotated(i)]), Art.with_alpha(accent, 0.75))
			"grass":
				for i in 5:
					var sway := sin(time * 1.5 + at.x * 0.01 + i) * 3.0
					ci.draw_line(at + Vector2(i * 4 - 8, 0), at + Vector2(i * 4 - 8 + sway, -size * 0.35), palette["ground"].lightened(0.3), 2.0)
	for rock: Rect2 in world.walls:
		if view.grow(100).intersects(rock):
			draw_rock(ci, rock)
	# Cliff edge around the playable area.
	ci.draw_rect(bounds, Art.with_alpha(palette["accent"], 0.35), false, 6.0)


func draw_rock(ci: CanvasItem, rock: Rect2) -> void:
	var c := rock.get_center()
	var h := rock.size * 0.5
	var points := PackedVector2Array([c + Vector2(-h.x, -h.y * 0.6), c + Vector2(-h.x * 0.5, -h.y), c + Vector2(h.x * 0.6, -h.y * 0.95),
		c + Vector2(h.x, -h.y * 0.3), c + Vector2(h.x * 0.9, h.y * 0.7), c + Vector2(h.x * 0.2, h.y), c + Vector2(-h.x * 0.8, h.y * 0.85)])
	ci.draw_colored_polygon(Transform2D(0, Vector2(8, 10)) * points, Color(0, 0, 0, 0.35))
	Art.shape(ci, points, palette["ground"].darkened(0.5), palette["ground"].lightened(0.2), 2.5)
	ci.draw_colored_polygon(PackedVector2Array([points[1], points[2], points[3], c]), palette["ground"].darkened(0.2))


# ---------------------------------------------------------------- dungeon

func draw_dungeon(ci: CanvasItem, view: Rect2, stage: DungeonStage, time: float) -> void:
	ci.draw_rect(view, Color(0.015, 0.012, 0.02))
	for key: Vector2i in stage.rooms:
		var rect := stage.room_rect(key)
		if not view.grow(10).intersects(rect):
			continue
		var visited: bool = stage.rooms[key]["visited"]
		var tint := Color(1, 1, 1) if visited or key == stage.current else Color(0.45, 0.45, 0.5)
		if stage.rooms[key]["kind"] == "boss":
			tint *= Color(1.0, 0.8, 0.85)
		ci.draw_texture_rect_region(floor_texture, rect, Rect2(Vector2.ZERO, rect.size * 0.5), tint)
		for wall: Rect2 in stage.room_walls(key):
			_draw_wall(ci, wall)
		_draw_doors(ci, stage, key, time)
		_draw_torches(ci, rect, time)


func _draw_wall(ci: CanvasItem, wall: Rect2) -> void:
	ci.draw_rect(wall, Color(0.2, 0.18, 0.24))
	ci.draw_rect(Rect2(wall.position, Vector2(wall.size.x, minf(6.0, wall.size.y))), Color(0.36, 0.33, 0.42))
	var row := 0
	var y := wall.position.y
	while y < wall.end.y:
		var x := wall.position.x + (14.0 if row % 2 == 1 else 0.0)
		while x < wall.end.x:
			ci.draw_line(Vector2(x, y), Vector2(x, minf(y + 14.0, wall.end.y)), Color(0.12, 0.1, 0.14), 1.0)
			x += 28.0
		ci.draw_line(Vector2(wall.position.x, y), Vector2(wall.end.x, y), Color(0.12, 0.1, 0.14), 1.0)
		y += 14.0
		row += 1


func _draw_doors(ci: CanvasItem, stage: DungeonStage, key: Vector2i, time: float) -> void:
	var rect := stage.room_rect(key)
	var room: Dictionary = stage.rooms[key]
	for direction in room["doors"]:
		if room.get("secret_dir", "") == direction:
			continue
		var to: Vector2i = room["doors"][direction]
		var dir := Vector2(DungeonStage.DIRECTIONS[direction])
		var at := rect.get_center() + dir * (rect.size * 0.5 - Vector2(DungeonStage.WALL, DungeonStage.WALL) * 0.5)
		var across := dir.orthogonal() * DungeonStage.DOOR * 0.5
		var open := stage.door_open(key, direction)
		if to == stage.boss_room:
			# Boss door: skull and red glow, the trope everyone knows.
			Art.draw_glow(ci, at, 90.0, Color(1, 0.2, 0.25, 0.35 + 0.15 * sin(time * 3.0)))
			ci.draw_circle(at - dir * 40.0, 16.0, Color(0.9, 0.88, 0.8))
			ci.draw_circle(at - dir * 40.0 + Vector2(-6, -2), 4.0, Color(0.1, 0, 0))
			ci.draw_circle(at - dir * 40.0 + Vector2(6, -2), 4.0, Color(0.1, 0, 0))
			if not stage.has_key:
				ci.draw_rect(Rect2(at - Vector2(12, 8), Vector2(24, 20)), Art.GOLD)
				ci.draw_arc(at - Vector2(0, 8), 9.0, PI, TAU, 10, Art.GOLD, 4.0)
		if not open and room["doors"].has(direction) and not (to == stage.boss_room and not stage.has_key):
			# Sealed by combat: energy bars.
			for i in 5:
				var t := (i + 0.5) / 5.0
				var p := at - across + across * 2.0 * t
				ci.draw_line(p - dir * 22.0, p + dir * 22.0, Color(0.85, 0.4, 1.0, 0.75 + 0.25 * sin(time * 10.0 + i)), 4.0)


func _draw_torches(ci: CanvasItem, rect: Rect2, time: float) -> void:
	for corner in [Vector2(70, 70), Vector2(rect.size.x - 70, 70), Vector2(70, rect.size.y - 70), Vector2(rect.size.x - 70, rect.size.y - 70)]:
		var at: Vector2 = rect.position + corner
		ci.draw_circle(at, 6.0, Color(0.3, 0.25, 0.2))
		var flicker := 1.0 + sin(time * 13.0 + at.x) * 0.15 + sin(time * 7.0 + at.y) * 0.1
		ci.draw_circle(at + Vector2(0, -4), 4.0 * flicker, Color(1, 0.75, 0.3))


func draw_dungeon_light(ci: CanvasItem, view: Rect2, stage: DungeonStage, time: float) -> void:
	for key: Vector2i in stage.rooms:
		var rect := stage.room_rect(key)
		if not view.grow(10).intersects(rect):
			continue
		for corner in [Vector2(70, 70), Vector2(rect.size.x - 70, 70), Vector2(70, rect.size.y - 70), Vector2(rect.size.x - 70, rect.size.y - 70)]:
			var flicker := 1.0 + sin(time * 13.0 + corner.x) * 0.1
			Art.draw_glow(ci, rect.position + corner, 110.0 * flicker, Color(1, 0.6, 0.25, 0.35))
