class_name UiKit
## The look of every menu: fonts, the theme, and helpers that build buttons, panels and labels.
## Every button built here reports its press to the play log (GDD 4C), so the log shows what was tapped.
## Style: a command-center console. Dark steel panels, cyan readouts, amber for actions.

static var _fonts := {}
static var _theme: Theme


static func font(kind: String = "body") -> Font:
	if not _fonts.has(kind):
		var paths := {
			"body": "res://assets/fonts/ChakraPetch-Medium.ttf",
			"bold": "res://assets/fonts/ChakraPetch-Bold.ttf",
			"title": "res://assets/fonts/Orbitron.ttf",
		}
		var loaded = load(paths[kind])
		if kind == "title" and loaded is FontFile:
			var variation := FontVariation.new()
			variation.base_font = loaded
			variation.variation_opentype = {"wght": 800}
			loaded = variation
		_fonts[kind] = loaded if loaded != null else ThemeDB.fallback_font
	return _fonts[kind]


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = font("body")
	t.default_font_size = 18
	t.set_stylebox("normal", "Button", _box(Color(0.09, 0.13, 0.2), Color(0.3, 0.45, 0.6), 2))
	t.set_stylebox("hover", "Button", _box(Color(0.12, 0.18, 0.27), Color(0.45, 0.8, 1.0), 2))
	t.set_stylebox("pressed", "Button", _box(Color(0.16, 0.26, 0.38), Color(0.6, 0.95, 1.0), 2))
	t.set_stylebox("disabled", "Button", _box(Color(0.07, 0.08, 0.11), Color(0.2, 0.24, 0.3), 2))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color(0.85, 0.93, 1.0))
	t.set_color("font_hover_color", "Button", Color(1, 1, 1))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.45, 0.5, 0.58))
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.05, 0.08, 0.13, 0.94), Color(0.22, 0.34, 0.48), 2))
	t.set_stylebox("panel", "Panel", _box(Color(0.05, 0.08, 0.13, 0.94), Color(0.22, 0.34, 0.48), 2))
	t.set_color("font_color", "Label", Color(0.85, 0.92, 1.0))
	t.set_stylebox("normal", "LineEdit", _box(Color(0.03, 0.05, 0.08), Color(0.3, 0.45, 0.6), 1))
	t.set_stylebox("focus", "LineEdit", _box(Color(0.03, 0.05, 0.08), Color(0.5, 0.85, 1.0), 1))
	t.set_stylebox("normal", "TextEdit", _box(Color(0.03, 0.05, 0.08), Color(0.3, 0.45, 0.6), 1))
	t.set_stylebox("grabber", "VScrollBar", _box(Color(0.3, 0.45, 0.6), Color(0.3, 0.45, 0.6), 0))
	t.set_stylebox("scroll", "VScrollBar", _box(Color(0.05, 0.07, 0.1), Color(0.05, 0.07, 0.1), 0))
	_theme = t
	return t


static func _box(fill: Color, border: Color, width: int, radius: int = 6) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 14
	box.content_margin_right = 14
	box.content_margin_top = 8
	box.content_margin_bottom = 8
	box.anti_aliasing = true
	return box


## A button that logs its press to the play log, then calls back.
static func button(text: String, on_press: Callable, log_name: String = "", accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 52)
	if accent:
		b.add_theme_stylebox_override("normal", _box(Color(0.35, 0.22, 0.05), Color(1.0, 0.75, 0.3), 2))
		b.add_theme_stylebox_override("hover", _box(Color(0.45, 0.3, 0.08), Color(1.0, 0.85, 0.45), 2))
		b.add_theme_stylebox_override("pressed", _box(Color(0.55, 0.36, 0.1), Color(1.0, 0.9, 0.6), 2))
		b.add_theme_color_override("font_color", Color(1, 0.92, 0.75))
		b.add_theme_font_override("font", font("bold"))
	var label := log_name if log_name != "" else text
	b.pressed.connect(func():
		PlayLog.button(label)
		Sound.play("ui")
		on_press.call()
	)
	return b


static func label(text: String, size: int = 18, color: Color = Color(0.85, 0.92, 1.0), kind: String = "body") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(kind))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func wrapped(text: String, size: int = 16, color: Color = Color(0.7, 0.8, 0.92)) -> Label:
	var l := label(text, size, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


static func panel(fill: Color = Color(0.05, 0.08, 0.13, 0.94), border: Color = Color(0.22, 0.34, 0.48)) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(fill, border, 2, 10))
	return p


static func spacer(height: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, height)
	return c
