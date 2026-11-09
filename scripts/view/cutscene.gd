class_name Cutscene
extends Control
## The short transitions around a mission (GDD 5E): launching from the Dropship's bay, arriving at the
## mission (straight into space, down through a planet's atmosphere, or through a dungeon gate), diving
## or breaking out mid-mission, and going home. Purely visual: the mission waits while one plays, so no
## game ticks run and replays are unaffected. A tap skips it.

## How long each one runs, in seconds.
const LENGTHS := {"launch_space": 3.0, "launch_planet": 4.4, "launch_dungeon": 4.4, "dive": 2.4, "breakout": 2.4,
	"return_win": 3.0, "return_loss": 3.0}

var kind := "launch_space"
var frame_id := "vanguard"
var gear: Array = []
var ground := Color(0.3, 0.4, 0.3)     # the planet's ground colour, for landings
var on_done: Callable
var time := 0.0
var finished := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	time += delta
	queue_redraw()
	if time >= LENGTHS.get(kind, 3.0):
		_finish()


func _gui_input(event: InputEvent) -> void:
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed)
	if tapped and time > 0.3:
		PlayLog.button("Cutscene: skip %s" % kind)
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
	var screen := size
	var c := screen * 0.5
	match kind:
		"launch_space", "launch_planet", "launch_dungeon":
			_draw_launch(screen, c)
		"dive":
			_draw_dive(screen, c)
		"breakout":
			_draw_breakout(screen, c)
		"return_win":
			_draw_return(screen, c, true)
		"return_loss":
			_draw_return(screen, c, false)
	# Fade in and out at the edges so it melts into the mission.
	var length: float = LENGTHS.get(kind, 3.0)
	var fade := clampf(1.0 - time / 0.25, 0.0, 1.0) + clampf((time - (length - 0.35)) / 0.35, 0.0, 1.0)
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, screen), Color(0, 0, 0, clampf(fade, 0.0, 1.0)))
	draw_string(UiKit.font("body"), Vector2(0, screen.y - 22), "Tap to skip", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 14, Color(1, 1, 1, 0.35))


func _frame(at: Vector2, form: String, facing: float, scale: float, flash: float = 0.0) -> void:
	FrameArt.draw_frame(self, frame_id, form, at, facing, time, {"speed": 1.0, "scale": scale, "gear": gear, "flash": flash})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stars(screen: Vector2, speed: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.015, 0.04))
	for i in 90:
		var x := fmod(i * 137.0, screen.x)
		var y := fmod(i * 61.0 + time * speed * (0.5 + float(i % 3) * 0.5), screen.y)
		draw_line(Vector2(x, y), Vector2(x, y - speed * 0.02 - 1.0), Color(1, 1, 1, 0.5), 1.5)


## The Dropship's launch bay seen from above: deck plating, guide lights, and bay doors at the top.
func _bay(screen: Vector2, c: Vector2, doors_open: float, zoom: float) -> void:
	var bay := Rect2(c - Vector2(240, 300) * zoom, Vector2(480, 600) * zoom)
	draw_rect(bay, Color(0.1, 0.12, 0.16))
	for i in 7:
		var y := bay.position.y + (i + 0.5) * bay.size.y / 7.0
		draw_line(Vector2(bay.position.x, y), Vector2(bay.end.x, y), Color(0.16, 0.19, 0.24), 3.0 * zoom)
		for side in [0.08, 0.92]:
			var on := int(time * 6.0 - i) % 7 == 0
			draw_circle(Vector2(bay.position.x + bay.size.x * side, y), 5.0 * zoom, Color(1, 0.7, 0.25) if on else Color(0.35, 0.25, 0.1))
	draw_rect(bay, Color(0.45, 0.6, 0.75), false, 4.0 * zoom)
	# Bay doors slide apart onto open space.
	var gap := bay.size.x * 0.5 * doors_open
	var door_h := 70.0 * zoom
	draw_rect(Rect2(bay.position - Vector2(0, door_h), Vector2(bay.size.x * 0.5 - gap, door_h)), Color(0.3, 0.33, 0.38))
	draw_rect(Rect2(Vector2(c.x + gap, bay.position.y - door_h), Vector2(bay.size.x * 0.5 - gap, door_h)), Color(0.3, 0.33, 0.38))
	# The Dropship's hull around the bay.
	var hull := PackedVector2Array([c + Vector2(-340, -420) * zoom, c + Vector2(340, -420) * zoom, c + Vector2(420, 260) * zoom,
		c + Vector2(260, 420) * zoom, c + Vector2(-260, 420) * zoom, c + Vector2(-420, 260) * zoom])
	draw_polyline(hull + PackedVector2Array([hull[0]]), Color(0.45, 0.6, 0.75, 0.8), 6.0 * zoom, true)


func _draw_launch(screen: Vector2, c: Vector2) -> void:
	# 0-1.0 s: the mech stands in the bay as the doors open. 1.0-1.5: it folds into the ship.
	# 1.5-2.6: it blasts out as the Dropship falls away. Then the arrival, by mission type.
	if time < 2.6:
		_stars(screen, 40.0 + maxf(time - 1.5, 0.0) * 900.0)
		var zoom := 1.0 - clampf((time - 1.5) / 1.1, 0.0, 1.0) * 0.55
		var bay_center := c + Vector2(0, clampf((time - 1.5) / 1.1, 0.0, 1.0) * 260.0)
		_bay(screen, bay_center, clampf(time / 1.0, 0.0, 1.0), zoom)
		if time < 1.25:
			_frame(bay_center + Vector2(0, 80) * zoom, "mech", -PI * 0.5, 3.2 * zoom)
		else:
			var lift := clampf((time - 1.5) / 1.1, 0.0, 1.0)
			var at := bay_center + Vector2(0, 80) * zoom - Vector2(0, ease(lift, 2.4) * (screen.y * 0.9))
			draw_line(at + Vector2(0, 30), at + Vector2(0, 30 + 140.0 * lift), Color(1, 0.65, 0.3, 0.8), 14.0 * (1.0 - lift * 0.5))
			_frame(at, "ship", -PI * 0.5, 3.2 * zoom)
		if time > 1.0 and time < 1.6:
			FrameArt.draw_transform(self, bay_center + Vector2(0, 80) * zoom, (time - 1.0) / 0.6, Color(0.5, 0.9, 1.0))
		return
	var t := time - 2.6
	match kind:
		"launch_space":
			# Streaking into the fight.
			_stars(screen, 1200.0)
			_frame(c + Vector2(0, 120 - t * 260.0), "ship", -PI * 0.5, 3.0)
		"launch_planet":
			# Down through the atmosphere wrapped in fire, then a flare of thrusters and the mech lands.
			var land := clampf((t - 1.1) / 0.5, 0.0, 1.0)
			draw_rect(Rect2(Vector2.ZERO, screen), ground.darkened(0.6).lerp(ground, clampf(t / 1.1, 0.0, 1.0)))
			if t < 1.1:
				var heat := 1.0 - t / 1.1
				var scale := lerpf(1.2, 3.0, t / 1.1)
				for i in 5:
					draw_line(c - Vector2(0, 40 + i * 30) * scale * 0.4, c - Vector2(0, 200 + i * 40) * scale * 0.4, Color(1, 0.5 + i * 0.08, 0.2, 0.6 * heat), 22.0 - i * 3.0)
				Art.draw_glow(self, c, 120.0 * scale * 0.4, Color(1, 0.55, 0.2, 0.8 * heat))
				_frame(c, "ship", PI * 0.5, scale)
			else:
				for i in 3:
					draw_arc(c, 40.0 + land * 160.0 + i * 30.0, 0, TAU, 32, Color(0.85, 0.75, 0.6, (1.0 - land) * 0.6), 6.0, true)
				_frame(c, "mech" if land > 0.4 else "ship", -PI * 0.5, 3.0)
				if land < 0.6:
					FrameArt.draw_transform(self, c, land / 0.6, Color(0.5, 0.9, 1.0))
		"launch_dungeon":
			# Landing at the dungeon gate, walking in, and the gate slamming shut behind.
			draw_rect(Rect2(Vector2.ZERO, screen), Color(0.14, 0.13, 0.13))
			# A stone archway set into the cliff, torches either side, darkness inside.
			var gate := Rect2(c + Vector2(-110, -280), Vector2(220, 220))
			draw_rect(Rect2(gate.position - Vector2(70, 40), gate.size + Vector2(140, 40)), Color(0.24, 0.22, 0.21))
			draw_rect(gate, Color(0.02, 0.01, 0.03))
			draw_arc(gate.position + Vector2(gate.size.x * 0.5, 0), gate.size.x * 0.5 + 20.0, PI, TAU, 24, Color(0.38, 0.34, 0.3), 40.0)
			for side in [-1.0, 1.0]:
				var pillar := Rect2(Vector2(c.x + side * 130.0 - 20.0, gate.position.y - 10.0), Vector2(40, gate.size.y + 10.0))
				draw_rect(pillar, Color(0.38, 0.34, 0.3))
				var flame := Vector2(c.x + side * 190.0, gate.position.y + 60.0)
				Art.draw_glow(self, flame, 46.0, Color(1, 0.6, 0.25, 0.7 + 0.2 * sin(time * 9.0 + side)))
				draw_circle(flame, 7.0, Color(1, 0.85, 0.4))
			var walk := clampf((t - 0.4) / 1.0, 0.0, 1.0)
			var at := c + Vector2(0, 220) - Vector2(0, walk * 420.0)
			if t < 0.4:
				FrameArt.draw_transform(self, c + Vector2(0, 220), t / 0.4, Color(0.5, 0.9, 1.0))
			if walk < 0.95:
				_frame(at, "mech", -PI * 0.5, 2.6 * (1.0 - walk * 0.4))
			# The portcullis crashes down behind you.
			var slam := clampf((t - 1.4) / 0.2, 0.0, 1.0)
			for i in 6:
				var x := gate.position.x + 12.0 + i * (gate.size.x - 24.0) / 5.0
				draw_line(Vector2(x, gate.position.y), Vector2(x, gate.position.y + gate.size.y * slam), Color(0.55, 0.5, 0.45), 8.0)
			draw_line(Vector2(gate.position.x, gate.position.y + gate.size.y * slam), Vector2(gate.end.x, gate.position.y + gate.size.y * slam), Color(0.55, 0.5, 0.45), 8.0)


func _draw_dive(screen: Vector2, c: Vector2) -> void:
	# Down into the fissure: the mech falls, shifts into its ship form mid-fall, and the tunnel opens out.
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.03, 0.02, 0.02))
	var fall := clampf(time / 1.6, 0.0, 1.0)
	for i in 6:
		var r := fmod(time * 380.0 + i * 120.0, 720.0)
		draw_arc(c, r, 0, TAU, 40, Color(1, 0.55, 0.25, 0.35 * (1.0 - r / 720.0)), 8.0, true)
	_frame(c, "mech" if fall < 0.5 else "ship", PI * 0.5 if fall >= 0.5 else -PI * 0.5, lerpf(3.2, 1.8, fall))
	if fall > 0.35 and fall < 0.7:
		FrameArt.draw_transform(self, c, (fall - 0.35) / 0.35, Color(0.5, 0.9, 1.0))


func _draw_breakout(screen: Vector2, c: Vector2) -> void:
	# Up the shaft toward a circle of daylight that swells until it fills the screen.
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.04, 0.03, 0.05))
	var rise := clampf(time / 1.8, 0.0, 1.0)
	var light := lerpf(40.0, screen.length(), ease(rise, 2.6))
	draw_circle(c, light, ground.lightened(0.3))
	_frame(c + Vector2(0, 160.0 * (1.0 - rise)), "mech", -PI * 0.5, lerpf(1.8, 3.2, rise))


func _draw_return(screen: Vector2, c: Vector2, won: bool) -> void:
	_stars(screen, 160.0)
	var t := clampf(time / 2.4, 0.0, 1.0)
	# The Dropship sweeps in overhead.
	var ship_y := lerpf(-260.0, 150.0, ease(t, 0.5))
	var hull := PackedVector2Array([Vector2(-220, -70), Vector2(220, -70), Vector2(280, 30), Vector2(160, 90), Vector2(-160, 90), Vector2(-280, 30)])
	var placed := PackedVector2Array()
	for point in hull:
		placed.append(point + Vector2(c.x, ship_y))
	draw_colored_polygon(placed, Color(0.14, 0.18, 0.26))
	draw_polyline(placed + PackedVector2Array([placed[0]]), Color(0.45, 0.6, 0.75), 3.0, true)
	draw_rect(Rect2(Vector2(c.x - 50, ship_y + 60), Vector2(100, 30)), Color(1, 0.75, 0.35, 0.6))
	if won:
		# The frame folds into its ship and climbs into the bay.
		var climb := clampf((time - 0.6) / 1.6, 0.0, 1.0)
		var at := Vector2(c.x, lerpf(screen.y * 0.75, ship_y + 75.0, ease(climb, 2.0)))
		_frame(at, "ship", -PI * 0.5, lerpf(2.6, 1.0, climb))
		if time < 0.6:
			FrameArt.draw_transform(self, Vector2(c.x, screen.y * 0.75), time / 0.6, Color(0.5, 0.9, 1.0))
	else:
		# Recovered, not lost: a tractor beam hauls the battered frame aboard.
		var haul := clampf((time - 0.7) / 1.6, 0.0, 1.0)
		var at := Vector2(c.x, lerpf(screen.y * 0.78, ship_y + 75.0, haul))
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - 50, ship_y + 85), Vector2(c.x + 50, ship_y + 85), Vector2(c.x + 110, at.y + 40), Vector2(c.x - 110, at.y + 40)]),
			Color(0.5, 1.0, 0.85, 0.18 + 0.06 * sin(time * 12.0)))
		_frame(at, "mech", -PI * 0.5 + sin(time * 2.0) * 0.3, lerpf(2.4, 1.0, haul), 0.3 if int(time * 8.0) % 2 == 0 else 0.0)
	draw_string(UiKit.font("title"), Vector2(0, screen.y * 0.9), "RECOVERED BY THE DROPSHIP" if not won else "RETURNING TO THE DROPSHIP",
		HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color(1, 0.85, 0.5) if won else Color(0.6, 1.0, 0.85))
