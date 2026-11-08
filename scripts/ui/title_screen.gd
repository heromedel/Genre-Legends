class_name TitleScreen
extends Control
## The title: a living starfield, the frame streaking across and shifting between ship and mech, and
## "tap to start" (which also unlocks sound on iPad, where browsers need a tap first).

signal started

var background: BackgroundArt
var time := 0.0
var scroll := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	background = BackgroundArt.new(MissionData.REGION_PALETTES[0], 11)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	PlayLog.set_screen("title")
	Sound.play_music("title")


func _process(delta: float) -> void:
	time += delta
	scroll += delta * 90.0
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed)
	if tapped and time > 0.6:
		accept_event()
		PlayLog.button("Title: tap to start")
		Sound.play("transform")
		Sound.play_music("hub")
		started.emit()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_pressed() and time > 0.6:
		started.emit()


func _draw() -> void:
	var screen := size
	background.draw_space(self, Rect2(Vector2.ZERO, screen), scroll, time)
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, 0.25))
	# The frame flies a lazy figure-eight and shifts form every few seconds.
	var path := Vector2(screen.x * 0.5 + sin(time * 0.5) * screen.x * 0.32, screen.y * 0.66 + sin(time * 1.0) * 60.0)
	var heading := Vector2(cos(time * 0.5) * screen.x * 0.16, cos(time) * 60.0).angle()
	var form := "ship" if int(time / 4.0) % 2 == 0 else "mech"
	var frames := ["vanguard", "tempest", "bulwark"]
	var frame_id: String = frames[int(time / 8.0) % 3]
	Art.draw_glow(self, path, 150.0, Color(0.4, 0.8, 1.0, 0.35))
	FrameArt.draw_frame(self, frame_id, form, path, heading, time, {"speed": 1.0, "scale": 3.2})
	var since_shift := fmod(time, 4.0)
	if since_shift < 0.6:
		FrameArt.draw_transform(self, path, since_shift / 0.6, FrameData.get_frame(frame_id)["hull"])
	# Title.
	var title_font := UiKit.font("title")
	var title_size := int(clampf(screen.x / 11.0, 48.0, 110.0))
	var title_y := screen.y * 0.3
	for i in 3:
		draw_string(title_font, Vector2(0, title_y + 3 - i), "GENRE", HORIZONTAL_ALIGNMENT_CENTER, screen.x, title_size, Color(0.2, 0.5, 1.0, 0.25))
	draw_string_outline(title_font, Vector2(0, title_y), "GENRE", HORIZONTAL_ALIGNMENT_CENTER, screen.x, title_size, 10, Color(0.02, 0.05, 0.12))
	draw_string(title_font, Vector2(0, title_y), "GENRE", HORIZONTAL_ALIGNMENT_CENTER, screen.x, title_size, Color(0.55, 0.9, 1.0))
	draw_string_outline(title_font, Vector2(0, title_y + title_size * 0.95), "LEGENDS", HORIZONTAL_ALIGNMENT_CENTER, screen.x, int(title_size * 0.8), 10, Color(0.1, 0.04, 0.0))
	draw_string(title_font, Vector2(0, title_y + title_size * 0.95), "LEGENDS", HORIZONTAL_ALIGNMENT_CENTER, screen.x, int(title_size * 0.8), Color(1.0, 0.78, 0.35))
	# Subtitle: the player's role, framed by rules that grow out from the centre.
	var subtitle_y := title_y + title_size * 1.5
	var subtitle_size := int(clampf(screen.x / 42.0, 18.0, 30.0))
	var subtitle := "GUARDIAN  OF  THE  REALMS"
	var subtitle_width := title_font.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, subtitle_size).x
	var reach := minf(time * 0.6, 1.0) * 120.0
	var rule_color := Color(1.0, 0.8, 0.4, 0.7)
	draw_line(Vector2(screen.x * 0.5 - subtitle_width * 0.5 - 20.0 - reach, subtitle_y - subtitle_size * 0.35), Vector2(screen.x * 0.5 - subtitle_width * 0.5 - 20.0, subtitle_y - subtitle_size * 0.35), rule_color, 2.0)
	draw_line(Vector2(screen.x * 0.5 + subtitle_width * 0.5 + 20.0, subtitle_y - subtitle_size * 0.35), Vector2(screen.x * 0.5 + subtitle_width * 0.5 + 20.0 + reach, subtitle_y - subtitle_size * 0.35), rule_color, 2.0)
	draw_string_outline(title_font, Vector2(0, subtitle_y), subtitle, HORIZONTAL_ALIGNMENT_CENTER, screen.x, subtitle_size, 6, Color(0.05, 0.03, 0.0))
	draw_string(title_font, Vector2(0, subtitle_y), subtitle, HORIZONTAL_ALIGNMENT_CENTER, screen.x, subtitle_size, Color(1.0, 0.88, 0.6))
	var blink := 0.45 + 0.55 * absf(sin(time * 2.2))
	draw_string(UiKit.font("bold"), Vector2(0, screen.y - 60), "TAP TO START", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 26, Color(1, 1, 1, blink))
	draw_string(UiKit.font("body"), Vector2(0, screen.y - 22), BuildInfo.label(), HORIZONTAL_ALIGNMENT_RIGHT, screen.x - 16, 13, Color(0.5, 0.6, 0.7))
