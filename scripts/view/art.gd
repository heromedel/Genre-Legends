class_name Art
## Shared drawing helpers and generated textures. All art in the game is drawn in code: vector shapes
## with layered shading and additive glow, so it stays sharp at any screen size and costs no downloads.

static var _glow: Texture2D
static var _ring: Texture2D
static var _dark_hole: Texture2D
static var _cache := {}

## The palette everything shares, so the game reads as one place.
const INK := Color(0.02, 0.03, 0.06)
const PANEL := Color(0.06, 0.09, 0.15)
const STEEL := Color(0.55, 0.66, 0.8)
const CYAN := Color(0.4, 0.9, 1.0)
const AMBER := Color(1.0, 0.75, 0.3)
const DANGER := Color(1.0, 0.3, 0.4)
const GOOD := Color(0.45, 1.0, 0.6)
const VIOLET := Color(0.75, 0.5, 1.0)
const GOLD := Color(1.0, 0.82, 0.35)
const RARITY := {
	"common": Color(0.65, 0.75, 0.9),
	"rare": Color(0.35, 0.8, 1.0),
	"epic": Color(0.8, 0.45, 1.0),
	"legendary": Color(1.0, 0.75, 0.25),
	"field": Color(0.45, 1.0, 0.6),
}


## A soft white radial glow, drawn tinted and additive for every light in the game.
static func glow() -> Texture2D:
	if _glow == null:
		_glow = _radial(128, func(d: float) -> float: return pow(clampf(1.0 - d, 0.0, 1.0), 2.2))
	return _glow


static func ring_texture() -> Texture2D:
	if _ring == null:
		_ring = _radial(128, func(d: float) -> float: return clampf(1.0 - absf(d - 0.8) * 8.0, 0.0, 1.0))
	return _ring


## Black everywhere except a soft clear hole in the middle: the lamp in Blackout rooms.
static func dark_hole() -> Texture2D:
	if _dark_hole == null:
		var image := Image.create(128, 128, false, Image.FORMAT_RGBA8)
		for y in 128:
			for x in 128:
				var d := Vector2(x - 63.5, y - 63.5).length() / 63.5
				image.set_pixel(x, y, Color(0, 0, 0, smoothstep(0.35, 1.0, d)))
		_dark_hole = ImageTexture.create_from_image(image)
	return _dark_hole


## White at the edges, clear in the middle: tinted for the hurt vignette.
static func vignette() -> Texture2D:
	if not _cache.has("vignette"):
		_cache["vignette"] = _radial(128, func(d: float) -> float: return smoothstep(0.55, 1.15, d))
	return _cache["vignette"]


static func _radial(size: int, falloff: Callable) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := (size - 1) * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x - half, y - half).length() / half
			image.set_pixel(x, y, Color(1, 1, 1, falloff.call(d)))
	return ImageTexture.create_from_image(image)


## A tileable noise texture coloured between two colours. Cached by key.
static func noise_texture(key: String, seed_value: int, size: int, frequency: float, dark: Color, light: Color, octaves: int = 4) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = frequency
	noise.fractal_octaves = octaves
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	var gray := noise.get_seamless_image(size, size, false, false, 0.1, true)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var v := gray.get_pixel(x, y).r
			image.set_pixel(x, y, dark.lerp(light, v))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


## A nebula: soft clouds that fade to transparent, for the space backgrounds.
static func nebula_texture(key: String, seed_value: int, tint: Color) -> Texture2D:
	if _cache.has(key):
		return _cache[key]
	var noise := FastNoiseLite.new()
	noise.seed = seed_value
	noise.frequency = 0.012
	noise.fractal_octaves = 5
	var size := 256
	var gray := noise.get_seamless_image(size, size, false, false, 0.1, true)
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var v := gray.get_pixel(x, y).r
			var a := smoothstep(0.42, 0.95, v)
			image.set_pixel(x, y, Color(tint.r * (0.6 + v * 0.6), tint.g * (0.6 + v * 0.6), tint.b * (0.6 + v * 0.6), a * 0.75))
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func draw_glow(ci: CanvasItem, at: Vector2, radius: float, color: Color) -> void:
	ci.draw_texture_rect(glow(), Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, color)


## Regular polygon points, pointing along +x.
static func ngon(sides: int, radius: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		points.append(Vector2.from_angle(rotation + TAU * i / sides) * radius)
	return points


static func star(points_count: int, outer: float, inner: float, rotation: float = 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in points_count * 2:
		var r := outer if i % 2 == 0 else inner
		points.append(Vector2.from_angle(rotation + PI * i / points_count) * r)
	return points


static func scaled(points: PackedVector2Array, factor: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for p in points:
		result.append(p * factor)
	return result


## A filled polygon with an outline: the basic building block of every sprite.
static func shape(ci: CanvasItem, points: PackedVector2Array, fill: Color, line: Color, width: float = 2.0) -> void:
	ci.draw_colored_polygon(points, fill)
	var closed := points.duplicate()
	closed.append(points[0])
	ci.draw_polyline(closed, line, width, true)


static func mirrored(half: PackedVector2Array) -> PackedVector2Array:
	## Builds a symmetric shape from its top half (points from nose to tail with y <= 0).
	var full := half.duplicate()
	for i in range(half.size() - 1, -1, -1):
		var p := half[i]
		if absf(p.y) > 0.01:
			full.append(Vector2(p.x, -p.y))
	return full


static func arc_points(center: Vector2, radius: float, from_angle: float, to_angle: float, segments: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in segments + 1:
		points.append(center + Vector2.from_angle(lerpf(from_angle, to_angle, float(i) / segments)) * radius)
	return points


static func dashed_circle(ci: CanvasItem, center: Vector2, radius: float, color: Color, width: float, dashes: int, offset: float) -> void:
	for i in dashes:
		var a := offset + TAU * i / dashes
		ci.draw_arc(center, radius, a, a + TAU / dashes * 0.55, 6, color, width, true)


static func darker(color: Color, amount: float) -> Color:
	return color.darkened(amount)


static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
