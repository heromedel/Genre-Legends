class_name VectorArt
## Draws art written as SVG (res://art/...): the five-pass style, where each component is drawn as
## outline, fill, shading, highlights and details. The SVG is read once into a list of shapes, cached, and
## drawn with CanvasItem calls each frame, so the game keeps what hand-drawn code art can do:
## - named groups (<g id="flame">) can be moved by the caller each frame, for animation,
## - colours can be swapped (a frame's trim tinted by its Resonance), the whole piece flashed white on a hit,
## - a rim of light can be traced around the outline, so dark art still stands out against dark space.
##
## The SVG subset: <g> (id, transform translate/scale/rotate, opacity, fill, stroke, stroke-width),
## <path> (M L H V C Q Z, absolute or relative), <polygon>, <circle>, <ellipse>, <rect>, and <use href>.
## A closed shape's stroke becomes an outline drawn under its fill, as a true rounded offset of the shape.
## Art is authored facing up (-y), in game units; callers rotate it to the facing they need.
##
## Poses: a group can carry places to stand, data-pose-<name>="x, y, degrees, scale x, scale y", so one
## set of parts can be arranged two ways (a frame's mech and ship, GDD 5E). poses() returns them.

## Shape kinds in the cache.
enum { FILL, LINE }

static var _cache := {}
static var _poses := {}         # path -> {group id: {pose name: Transform2D}}


## Draws an SVG file. xf places it (position, rotation, scale). options:
##   remap: {"#ffc759": Color}   swap any colour written in the file for another (lower-case hex)
##   flash: 0..1                  pull every colour toward white (a hit)
##   alpha: 0..1                  fade the whole piece (a transformation's crossfade)
##   dim: 0..1                    pull every colour toward a dark steel (offline gear)
##   rim: Color                   trace a thin rim of this colour around every outline (alpha 0: none)
##   groups: {"flame": Transform2D}   extra transform for a named group, in the art's own space
##   hide: ["stock_arms"]         named groups to leave out
static func draw(ci: CanvasItem, path: String, xf: Transform2D, options: Dictionary = {}) -> void:
	var shapes := _load(path)
	var remap: Dictionary = options.get("remap", {})
	var flash: float = options.get("flash", 0.0)
	var dim: float = options.get("dim", 0.0)
	var alpha: float = options.get("alpha", 1.0)
	var rim: Color = options.get("rim", Color(0, 0, 0, 0))
	var groups: Dictionary = options.get("groups", {})
	var hide: Array = options.get("hide", [])
	# Pass 0: the rim, under everything, so the silhouette gets a thin edge of light.
	if rim.a > 0.0:
		var rim_colour := rim.lerp(Color.WHITE, flash)
		rim_colour.a *= alpha
		for shape: Dictionary in shapes:
			if shape["rim"].is_empty() or hide.has(shape["group"]):
				continue
			ci.draw_set_transform_matrix(xf * groups.get(shape["group"], Transform2D.IDENTITY))
			for polygon: PackedVector2Array in shape["rim"]:
				ci.draw_colored_polygon(polygon, rim_colour)
	for shape: Dictionary in shapes:
		if hide.has(shape["group"]):
			continue
		ci.draw_set_transform_matrix(xf * groups.get(shape["group"], Transform2D.IDENTITY))
		var colour: Color = remap.get(shape["key"], shape["colour"])
		colour.a *= shape["opacity"] * alpha
		if flash > 0.0:
			colour = colour.lerp(Color(1, 1, 1, colour.a), flash)
		if dim > 0.0:
			colour = colour.lerp(Color(0.1, 0.12, 0.16, colour.a), dim)
		if shape["kind"] == FILL:
			for polygon: PackedVector2Array in shape["polygons"]:
				ci.draw_colored_polygon(polygon, colour)
		else:
			ci.draw_polyline(shape["points"], colour, shape["width"], true)
			# Round caps, so thick strokes end like the SVG's.
			if shape["width"] >= 1.2 and not shape["closed"]:
				ci.draw_circle(shape["points"][0], shape["width"] * 0.5, colour)
				ci.draw_circle(shape["points"][-1], shape["width"] * 0.5, colour)
	ci.draw_set_transform_matrix(Transform2D.IDENTITY)


## A rotation and scale about a point in the art's own space (a wing's root, a flame's nozzle), for "groups".
static func about(point: Vector2, rotation: float, scale: Vector2) -> Transform2D:
	return Transform2D(0.0, point) * Transform2D(rotation, scale, 0.0, Vector2.ZERO) * Transform2D(0.0, -point)


## A file's posed groups: {group id: {pose name: Transform2D}}, in the art's own space.
static func poses(path: String) -> Dictionary:
	_load(path)
	return _poses.get(path, {})


## The art's shapes, read from the file the first time and cached after.
static func _load(path: String) -> Array:
	if _cache.has(path):
		return _cache[path]
	var shapes := []
	var parser := XMLParser.new()
	if parser.open(path) != OK:
		push_error("VectorArt: can't open %s" % path)
		_cache[path] = shapes
		return shapes
	var templates := {}          # id -> [[element name, attributes], ...]: a <defs> group, drawn only through <use>
	var stack := [{"xf": Transform2D.IDENTITY, "group": "", "style": {}, "opacity": 1.0}]
	var recording := []          # <defs> groups being read, innermost last
	var in_defs := false
	while parser.read() == OK:
		var node_type := parser.get_node_type()
		if node_type == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "defs":
				in_defs = false
			if parser.get_node_name() == "g" and stack.size() > 1:
				stack.pop_back()
				if not recording.is_empty() and recording[-1]["depth"] == stack.size():
					var finished: Dictionary = recording.pop_back()
					templates[finished["id"]] = finished["elements"]
			continue
		if node_type != XMLParser.NODE_ELEMENT:
			continue
		var name := parser.get_node_name()
		var attributes := {}
		for i in parser.get_attribute_count():
			attributes[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
		var context: Dictionary = stack[-1]
		if name == "g":
			var child := _child_context(context, attributes)
			if attributes.has("id"):
				for key in attributes:
					if String(key).begins_with("data-pose-"):
						var v := _numbers(attributes[key])
						var pose := Transform2D(deg_to_rad(v[2]), Vector2(v[3], v[4]), 0.0, Vector2(v[0], v[1]))
						if not _poses.has(path):
							_poses[path] = {}
						if not _poses[path].has(attributes["id"]):
							_poses[path][attributes["id"]] = {}
						_poses[path][attributes["id"]][String(key).trim_prefix("data-pose-")] = pose
			if not parser.is_empty():
				stack.append(child)
				if in_defs and attributes.has("id"):
					recording.append({"id": attributes["id"], "depth": stack.size() - 1, "elements": []})
			continue
		if name == "svg":
			continue
		if name == "defs":
			in_defs = not parser.is_empty()
			continue
		if in_defs:
			# Template parts: kept for <use>, never drawn where they're defined.
			if not recording.is_empty():
				recording[-1]["elements"].append([name, attributes])
			continue
		if name == "use":
			var id := String(attributes.get("href", attributes.get("xlink:href", ""))).trim_prefix("#")
			var at := Transform2D(0.0, Vector2(float(attributes.get("x", "0")), float(attributes.get("y", "0"))))
			var used := _child_context(context, {})
			used["xf"] = context["xf"] * at
			for element: Array in templates.get(id, []):
				_add_element(shapes, element[0], element[1], used)
			continue
		_add_element(shapes, name, attributes, context)
	_cache[path] = shapes
	return shapes


## A group's context: its transform, its id (or its parent's, for animation), its inherited style.
static func _child_context(parent: Dictionary, attributes: Dictionary) -> Dictionary:
	var style: Dictionary = parent["style"].duplicate()
	for key in ["fill", "stroke", "stroke-width"]:
		if attributes.has(key):
			style[key] = attributes[key]
	return {
		"xf": parent["xf"] * _parse_transform(attributes.get("transform", "")),
		"group": attributes.get("id", parent["group"]),
		"style": style,
		"opacity": parent["opacity"] * float(attributes.get("opacity", "1")),
	}


## Turns one element into shapes: an outline (from a closed shape's stroke), then the fill; or a line.
static func _add_element(shapes: Array, name: String, attributes: Dictionary, context: Dictionary) -> void:
	var style: Dictionary = context["style"].duplicate()
	for key in ["fill", "stroke", "stroke-width"]:
		if attributes.has(key):
			style[key] = attributes[key]
	var opacity: float = context["opacity"] * float(attributes.get("opacity", "1")) * float(attributes.get("fill-opacity", "1"))
	var subpaths := _outline_of(name, attributes)    # [[points, closed], ...]
	if subpaths.is_empty():
		return
	var xf: Transform2D = context["xf"]
	for subpath: Array in subpaths:
		subpath[0] = xf * PackedVector2Array(subpath[0])
	var fill := String(style.get("fill", "#000000"))
	var stroke := String(style.get("stroke", "none"))
	var width := float(style.get("stroke-width", "1")) * xf.get_scale().x
	var closed_polygons: Array = subpaths.filter(func(s): return s[1] and s[0].size() >= 3).map(func(s): return s[0])
	# 1. Outline: the stroke of a closed shape, as a rounded offset drawn under the fill.
	if stroke != "none" and not closed_polygons.is_empty():
		var outline := []
		var rim := []
		for polygon: PackedVector2Array in closed_polygons:
			outline.append_array(_safe(Geometry2D.offset_polygon(polygon, width * 0.5, Geometry2D.JOIN_ROUND)))
			if width >= 1.5:
				rim.append_array(_safe(Geometry2D.offset_polygon(polygon, width * 0.5 + 1.3, Geometry2D.JOIN_ROUND)))
		shapes.append({"kind": FILL, "polygons": outline, "colour": Color.html(stroke), "key": stroke.to_lower(), "opacity": opacity,
			"group": context["group"], "rim": rim})
	# 2. Fill.
	if fill != "none" and not closed_polygons.is_empty():
		var filled := []
		for polygon: PackedVector2Array in closed_polygons:
			filled.append_array(_safe([polygon]))
		shapes.append({"kind": FILL, "polygons": filled, "colour": Color.html(fill), "key": fill.to_lower(), "opacity": opacity,
			"group": context["group"], "rim": []})
	# Lines: open strokes (panel seams, trim stripes, glints).
	if stroke != "none":
		for subpath: Array in subpaths:
			if subpath[1] and fill != "none":
				continue
			var points: PackedVector2Array = subpath[0]
			if subpath[1]:
				points.append(points[0])
			shapes.append({"kind": LINE, "points": points, "colour": Color.html(stroke), "key": stroke.to_lower(), "opacity": opacity,
				"width": width, "closed": subpath[1], "group": context["group"], "rim": []})


## Polygons that can actually be drawn (enough points, and Godot can triangulate them).
static func _safe(polygons: Array) -> Array:
	return polygons.filter(func(p): return p.size() >= 3 and not Geometry2D.triangulate_polygon(p).is_empty())


## An element's geometry, in its own space: a list of [points, closed].
static func _outline_of(name: String, attributes: Dictionary) -> Array:
	match name:
		"path":
			return _parse_path(attributes.get("d", ""))
		"polygon", "polyline":
			var numbers := _numbers(attributes.get("points", ""))
			var points := PackedVector2Array()
			for i in range(0, numbers.size() - 1, 2):
				points.append(Vector2(numbers[i], numbers[i + 1]))
			return [[points, name == "polygon"]]
		"circle":
			return [[_ellipse(Vector2(float(attributes.get("cx", "0")), float(attributes.get("cy", "0"))), Vector2.ONE * float(attributes.get("r", "0"))), true]]
		"ellipse":
			return [[_ellipse(Vector2(float(attributes.get("cx", "0")), float(attributes.get("cy", "0"))),
				Vector2(float(attributes.get("rx", "0")), float(attributes.get("ry", "0")))), true]]
		"rect":
			var at := Vector2(float(attributes.get("x", "0")), float(attributes.get("y", "0")))
			var size := Vector2(float(attributes.get("width", "0")), float(attributes.get("height", "0")))
			return [[_rounded_rect(Rect2(at, size), float(attributes.get("rx", "0"))), true]]
	return []


static func _ellipse(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	var segments := clampi(int(maxf(radius.x, radius.y) * 2.0), 10, 40)
	for i in segments:
		var angle := TAU * i / segments
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	return points


static func _rounded_rect(rect: Rect2, corner: float) -> PackedVector2Array:
	corner = minf(corner, minf(rect.size.x, rect.size.y) * 0.5)
	if corner <= 0.0:
		return PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var points := PackedVector2Array()
	var corners := [[Vector2(rect.end.x - corner, rect.position.y + corner), -PI * 0.5], [rect.end - Vector2(corner, corner), 0.0],
		[Vector2(rect.position.x + corner, rect.end.y - corner), PI * 0.5], [rect.position + Vector2(corner, corner), PI]]
	for entry: Array in corners:
		for i in 4:
			points.append(entry[0] + Vector2.from_angle(entry[1] + PI * 0.5 * i / 3.0) * corner)
	return points


## Path data: M L H V C Q Z, upper case absolute, lower case relative. Curves are flattened to points.
static func _parse_path(d: String) -> Array:
	var tokens := _tokens(d)
	var subpaths := []
	var points := PackedVector2Array()
	var pen := Vector2.ZERO
	var start := Vector2.ZERO
	var command := ""
	var i := 0
	while i < tokens.size():
		if tokens[i] is String:
			command = tokens[i]
			i += 1
			if command in ["Z", "z"]:
				if points.size() >= 2:
					subpaths.append([points, true])
				points = PackedVector2Array()
				pen = start
				continue
		var relative := command == command.to_lower()
		var base := pen if relative else Vector2.ZERO
		match command.to_upper():
			"M":
				if points.size() >= 2:
					subpaths.append([points, false])
				points = PackedVector2Array()
				pen = base + Vector2(tokens[i], tokens[i + 1])
				start = pen
				points.append(pen)
				i += 2
				command = "l" if relative else "L"    # further pairs are line-tos
			"L":
				pen = base + Vector2(tokens[i], tokens[i + 1])
				points.append(pen)
				i += 2
			"H":
				pen = Vector2((pen.x if relative else 0.0) + tokens[i], pen.y)
				points.append(pen)
				i += 1
			"V":
				pen = Vector2(pen.x, (pen.y if relative else 0.0) + tokens[i])
				points.append(pen)
				i += 1
			"C":
				var c1 := base + Vector2(tokens[i], tokens[i + 1])
				var c2 := base + Vector2(tokens[i + 2], tokens[i + 3])
				var end := base + Vector2(tokens[i + 4], tokens[i + 5])
				for step in range(1, 11):
					var t := step / 10.0
					points.append(pen.bezier_interpolate(c1, c2, end, t))
				pen = end
				i += 6
			"Q":
				var control := base + Vector2(tokens[i], tokens[i + 1])
				var end := base + Vector2(tokens[i + 2], tokens[i + 3])
				for step in range(1, 9):
					var t := step / 8.0
					points.append(pen.lerp(control, t).lerp(control.lerp(end, t), t))
				pen = end
				i += 4
			"A":
				var end := base + Vector2(tokens[i + 5], tokens[i + 6])
				points.append_array(_arc(pen, Vector2(tokens[i], tokens[i + 1]), deg_to_rad(tokens[i + 2]), tokens[i + 3] != 0.0, tokens[i + 4] != 0.0, end))
				pen = end
				i += 7
			_:
				push_warning("VectorArt: path command %s isn't supported" % command)
				return subpaths
	if points.size() >= 2:
		subpaths.append([points, false])
	return subpaths


## An elliptical arc from one point to another, flattened (the SVG spec's endpoint-to-centre conversion).
static func _arc(from: Vector2, radius: Vector2, rotation: float, large: bool, sweep: bool, to: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	radius = radius.abs()
	if radius.x < 0.001 or radius.y < 0.001 or from.is_equal_approx(to):
		points.append(to)
		return points
	var half := ((from - to) * 0.5).rotated(-rotation)
	# Radii too small to reach are scaled up just enough.
	var reach := (half.x * half.x) / (radius.x * radius.x) + (half.y * half.y) / (radius.y * radius.y)
	if reach > 1.0:
		radius *= sqrt(reach)
	var rx2 := radius.x * radius.x
	var ry2 := radius.y * radius.y
	var numerator := maxf(rx2 * ry2 - rx2 * half.y * half.y - ry2 * half.x * half.x, 0.0)
	var factor := sqrt(numerator / (rx2 * half.y * half.y + ry2 * half.x * half.x)) * (-1.0 if large == sweep else 1.0)
	var center_local := Vector2(radius.x * half.y / radius.y, -radius.y * half.x / radius.x) * factor
	var center := center_local.rotated(rotation) + (from + to) * 0.5
	var start_angle := Vector2((half.x - center_local.x) / radius.x, (half.y - center_local.y) / radius.y).angle()
	var end_angle := Vector2((-half.x - center_local.x) / radius.x, (-half.y - center_local.y) / radius.y).angle()
	var delta := wrapf(end_angle - start_angle, -PI, PI)
	if sweep and delta < 0.0:
		delta += TAU
	elif not sweep and delta > 0.0:
		delta -= TAU
	var steps := maxi(4, int(absf(delta) / TAU * 32.0))
	for step in range(1, steps + 1):
		var angle := start_angle + delta * step / steps
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y).rotated(rotation))
	return points


## Path data split into commands (Strings) and numbers (floats).
static func _tokens(d: String) -> Array:
	var tokens := []
	var regex := RegEx.create_from_string("[MmLlHhVvCcQqAaZz]|-?(?:\\d+\\.?\\d*|\\.\\d+)(?:[eE][-+]?\\d+)?")
	for found in regex.search_all(d):
		var text := found.get_string()
		tokens.append(text if text.length() == 1 and text.to_upper() in ["M", "L", "H", "V", "C", "Q", "A", "Z"] else float(text))
	return tokens


static func _numbers(text: String) -> PackedFloat32Array:
	var numbers := PackedFloat32Array()
	for found in RegEx.create_from_string("-?(?:\\d+\\.?\\d*|\\.\\d+)").search_all(text):
		numbers.append(float(found.get_string()))
	return numbers


## transform="translate(x,y) rotate(deg) scale(s)" in that written order.
static func _parse_transform(text: String) -> Transform2D:
	var xf := Transform2D.IDENTITY
	for found in RegEx.create_from_string("(translate|rotate|scale)\\s*\\(([^)]*)\\)").search_all(text):
		var values := _numbers(found.get_string(2))
		match found.get_string(1):
			"translate":
				xf = xf * Transform2D(0.0, Vector2(values[0], values[1] if values.size() > 1 else 0.0))
			"rotate":
				xf = xf * Transform2D(deg_to_rad(values[0]), Vector2.ZERO)
			"scale":
				xf = xf * Transform2D(0.0, Vector2(values[0], values[1] if values.size() > 1 else values[0]), 0.0, Vector2.ZERO)
	return xf
