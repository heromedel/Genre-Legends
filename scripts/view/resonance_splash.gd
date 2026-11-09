class_name ResonanceSplash
extends Control
## The moment a Resonance tier unlocks (GDD 9H): the action holds while a splash in the element's colour
## names the tier and says what it does, then play resumes. Purely visual like a Cutscene: the mission
## waits, no ticks run, so replays are unaffected. A tap skips it.

const LENGTH := 2.6

var element := "energy"
var tier := 1
var on_done: Callable
var time := 0.0
var finished := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	time += delta
	queue_redraw()
	if time >= LENGTH:
		_finish()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	# A short guard so the tap that picked the card doesn't also skip the splash.
	if tapped and time > 0.4:
		PlayLog.button("Resonance splash: skip")
		_finish()
		accept_event()


func _finish() -> void:
	if finished:
		return
	finished = true
	if on_done.is_valid():
		on_done.call()
	queue_free()


func _draw() -> void:
	var info: Dictionary = UpgradeData.RESONANCE[element]
	var tier_info: Array = info["tiers"][tier - 1]
	var color: Color = TechData.ELEMENT_COLORS[element]
	var fade := minf(time / 0.15, 1.0) * minf((LENGTH - time) / 0.3, 1.0)
	var pop := 1.0 + 0.25 * maxf(0.0, 1.0 - time / 0.25)
	var c := size * 0.5 + Vector2(0, -40)
	# A band across the screen, so the fight behind stays visible but quiet.
	draw_rect(Rect2(0, c.y - 150, size.x, 300), Color(0.02, 0.03, 0.06, 0.82 * fade))
	draw_rect(Rect2(0, c.y - 150, size.x, 3), Art.with_alpha(color, fade))
	draw_rect(Rect2(0, c.y + 147, size.x, 3), Art.with_alpha(color, fade))
	# The tier's diamond, as on the HUD chip, but big, with rays turning behind it.
	Art.draw_glow(self, c + Vector2(0, -50), 150.0 * pop, Art.with_alpha(color, 0.5 * fade))
	for i in 12:
		var angle := TAU * i / 12.0 + time * 0.6
		draw_line(c + Vector2(0, -50) + Vector2.from_angle(angle) * 60.0, c + Vector2(0, -50) + Vector2.from_angle(angle) * 110.0 * pop,
			Art.with_alpha(color, 0.35 * fade), 3.0, true)
	var r := 48.0 * pop
	var top := c + Vector2(0, -50)
	var diamond := PackedVector2Array([top + Vector2(0, -r), top + Vector2(r, 0), top + Vector2(0, r), top + Vector2(-r, 0)])
	draw_colored_polygon(diamond, Art.with_alpha(color.darkened(0.3), 0.9 * fade))
	draw_polyline(diamond + PackedVector2Array([diamond[0]]), Art.with_alpha(color.lightened(0.4), fade), 4.0, true)
	draw_string(UiKit.font("title"), top + Vector2(-60, 16), UpgradeOffers.ROMAN[tier], HORIZONTAL_ALIGNMENT_CENTER, 120, 42, Art.with_alpha(Color.WHITE, fade))
	var title := "%s RESONANCE %s" % [String(info["name"]).to_upper(), UpgradeOffers.ROMAN[tier]]
	draw_string(UiKit.font("title"), Vector2(0, c.y + 40), title, HORIZONTAL_ALIGNMENT_CENTER, size.x, 34, Art.with_alpha(color.lightened(0.3), fade))
	draw_string(UiKit.font("bold"), Vector2(0, c.y + 80), tier_info[0], HORIZONTAL_ALIGNMENT_CENTER, size.x, 26, Art.with_alpha(Color.WHITE, fade))
	draw_string(UiKit.font("body"), Vector2(0, c.y + 116), tier_info[1], HORIZONTAL_ALIGNMENT_CENTER, size.x, 18, Art.with_alpha(Color(0.8, 0.88, 0.95), fade))
