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
	# A tap arrives as a touch and again as an emulated mouse click; only the touch counts.
	var tapped: bool = (event is InputEventScreenTouch and event.pressed) or \
		(event is InputEventMouseButton and event.pressed and event.device != InputEvent.DEVICE_ID_EMULATION)
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
	draw_string(UiKit.font("bold"), Vector2(0, screen.y - 22), "Tap to skip", HORIZONTAL_ALIGNMENT_CENTER, screen.x, 16, Color(1, 1, 1, 0.65))


func _frame(at: Vector2, form: String, facing: float, scale: float, flash: float = 0.0) -> void:
	FrameArt.draw_frame(self, frame_id, form, at, facing, time, {"speed": 1.0, "scale": scale, "gear": gear, "flash": flash})
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _stars(screen: Vector2, speed: float) -> void:
	draw_rect(Rect2(Vector2.ZERO, screen), Color(0.01, 0.015, 0.04))
	for i in 90:
		var x := fmod(i * 137.0, screen.x)
		var y := fmod(i * 61.0 + time * speed * (0.5 + float(i % 3) * 0.5), screen.y)
		draw_line(Vector2(x, y), Vector2(x, y - speed * 0.02 - 1.0), Color(1, 1, 1, 0.5), 1.5)


## The Dropship seen from above (art/scenes/dropship.svg), its bay doors open by doors_open (0-1), its guide
## lights chasing toward the bay mouth. rotation PI turns it bow-down (the return trip, climbing in from below).
func _dropship(center: Vector2, doors_open: float, zoom: float, rotation: float = 0.0) -> void:
	var xf := Transform2D(rotation, Vector2(zoom, zoom), 0.0, center)
	# The doors fold back into the hull's sides like a concertina, each toward its own edge (x = -240 / 240).
	var folded := 1.0 - 0.88 * doors_open
	VectorArt.draw(self, "res://art/scenes/dropship.svg", xf, {"groups": {
		"door_l": Transform2D(0.0, Vector2(folded, 1.0), 0.0, Vector2(-240.0 * (1.0 - folded), 0.0)),
		"door_r": Transform2D(0.0, Vector2(folded, 1.0), 0.0, Vector2(240.0 * (1.0 - folded), 0.0)),
	}})
	draw_set_transform_matrix(xf)
	for i in 7:
		var y := 260.0 - i * 86.0
		var lit := int(time * 8.0) % 7 == i
		for x in [-220.0, 220.0]:
			draw_circle(Vector2(x, y), 9.0, Color(1, 0.72, 0.28) if lit else Color(0.32, 0.22, 0.1))
			if lit:
				Art.draw_glow(self, Vector2(x, y), 30.0, Color(1, 0.6, 0.2, 0.6))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_launch(screen: Vector2, c: Vector2) -> void:
	# 0-1.0 s: the mech stands in the bay as the doors open. 1.0-1.5: it folds into the ship.
	# 1.5-2.6: it blasts out as the Dropship falls away. Then the arrival, by mission type.
	if time < 2.6:
		_stars(screen, 40.0 + maxf(time - 1.5, 0.0) * 900.0)
		var zoom := 1.0 - clampf((time - 1.5) / 1.1, 0.0, 1.0) * 0.55
		var bay_center := c + Vector2(0, clampf((time - 1.5) / 1.1, 0.0, 1.0) * 260.0)
		_dropship(bay_center, clampf(time / 1.0, 0.0, 1.0), zoom)
		if time < 1.25:
			_frame(bay_center + Vector2(0, 80) * zoom, "mech", -PI * 0.5, 3.2 * zoom)
		else:
			var lift := clampf((time - 1.5) / 1.1, 0.0, 1.0)
			var at := bay_center + Vector2(0, 80) * zoom - Vector2(0, ease(lift, 2.4) * (screen.y * 0.9))
			# The catapult fires: a flash down the rails, then speed lines and a long thruster trail.
			if lift < 0.25:
				Art.draw_glow(self, bay_center + Vector2(0, 80) * zoom, 260.0 * zoom, Color(1, 0.85, 0.5, 0.7 * (1.0 - lift / 0.25)))
			for i in 14:
				var x := c.x + (fmod(i * 97.0, 700.0) - 350.0)
				var y := fmod(i * 173.0 + time * 2600.0, screen.y + 200.0) - 100.0
				draw_line(Vector2(x, y), Vector2(x, y + 60.0 + 140.0 * lift), Color(0.8, 0.9, 1.0, 0.35 * lift), 2.0)
			draw_line(at + Vector2(0, 30), at + Vector2(0, 30 + 220.0 * lift), Color(1, 0.65, 0.3, 0.8), 16.0 * (1.0 - lift * 0.5))
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
			# Seen from above: the ground swells as you come down through the atmosphere wrapped in fire, your
			# shadow closes in under you, and the ship touches down and stands up as the mech.
			var descent := clampf(t / 1.2, 0.0, 1.0)
			var land := clampf((t - 1.2) / 0.5, 0.0, 1.0)
			draw_rect(Rect2(Vector2.ZERO, screen), ground.darkened(0.25))
			var ground_zoom := lerpf(0.35, 1.0, ease(descent, 0.6))
			for i in 14:
				var spot := Vector2(fmod(i * 211.0, 1400.0) - 700.0, fmod(i * 157.0, 900.0) - 450.0)
				var radius := (30.0 + float(i % 4) * 22.0) * ground_zoom
				draw_circle(c + spot * ground_zoom, radius, ground.darkened(0.42))
				draw_circle(c + spot * ground_zoom + Vector2(-0.18, -0.18) * radius, radius * 0.82, ground.darkened(0.3))
			var altitude := 1.0 - descent
			draw_circle(c + Vector2(90, 90) * altitude, 70.0 * (1.0 - altitude * 0.4), Color(0, 0, 0, 0.25 + 0.2 * descent))
			if t < 1.2:
				var heat := altitude
				for i in 6:
					var angle := PI * 0.5 + (i - 2.5) * 0.28
					draw_line(c + Vector2.from_angle(angle) * 50.0, c + Vector2.from_angle(angle) * (150.0 + 60.0 * sin(time * 30.0 + i)),
						Color(1, 0.45 + i * 0.07, 0.2, 0.65 * heat), 18.0 - i * 2.0)
				Art.draw_glow(self, c, 170.0, Color(1, 0.5, 0.2, 0.75 * heat))
				_frame(c, "ship", -PI * 0.5, 3.0)
			else:
				for i in 3:
					draw_arc(c, 40.0 + land * 180.0 + i * 34.0, 0, TAU, 32, ground.lightened(0.35) * Color(1, 1, 1, (1.0 - land) * 0.7), 8.0, true)
				_frame(c, "mech" if land > 0.4 else "ship", -PI * 0.5, 3.0)
				if land < 0.6:
					FrameArt.draw_transform(self, c, land / 0.6, Color(0.5, 0.9, 1.0))
		"launch_dungeon":
			# Landing at the dungeon gate, walking in, and the gate slamming shut behind.
			draw_rect(Rect2(Vector2.ZERO, screen), Color(0.14, 0.13, 0.13))
			# The gate: a stone arch cut into the cliff (art/scenes/dungeon_gate.svg), torches either side.
			var gate := Rect2(c + Vector2(-110, -280), Vector2(220, 220))
			VectorArt.draw(self, "res://art/scenes/dungeon_gate.svg", Transform2D(0.0, c))
			for side in [-1.0, 1.0]:
				var flame := c + Vector2(side * 195.0, -215.0)
				Art.draw_glow(self, flame, 52.0, Color(1, 0.6, 0.25, 0.7 + 0.2 * sin(time * 9.0 + side)))
				draw_colored_polygon(PackedVector2Array([flame + Vector2(-8, 10), flame + Vector2(0, -16 - 4.0 * sin(time * 14.0 + side)), flame + Vector2(8, 10)]), Color(1, 0.6, 0.2))
				draw_circle(flame + Vector2(0, 4), 5.0, Color(1, 0.92, 0.6))
			var walk := clampf((t - 0.4) / 1.0, 0.0, 1.0)
			var at := c + Vector2(0, 220) - Vector2(0, walk * 360.0)
			if t < 0.4:
				FrameArt.draw_transform(self, c + Vector2(0, 220), t / 0.4, Color(0.5, 0.9, 1.0))
			_frame(at, "mech", -PI * 0.5, 2.6 * (1.0 - walk * 0.35))
			# Stepping into the gate, the dark swallows it.
			var swallowed := clampf((gate.end.y + 40.0 - at.y) / 140.0, 0.0, 1.0)
			if swallowed > 0.0:
				draw_rect(Rect2(gate.position.x, gate.position.y, gate.size.x, gate.size.y + 60.0), Color(0.01, 0.005, 0.015, swallowed))
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
	# The Dropship sweeps in overhead, bow down, bay doors open toward you.
	var ship_y := lerpf(-260.0, 120.0, ease(t, 0.5))
	var zoom := 0.42
	_dropship(Vector2(c.x, ship_y), 1.0, zoom, PI)
	var mouth_y := ship_y + 330.0 * zoom
	if won:
		# The frame folds into its ship and climbs into the bay.
		var climb := clampf((time - 0.6) / 1.6, 0.0, 1.0)
		var at := Vector2(c.x, lerpf(screen.y * 0.75, mouth_y, ease(climb, 2.0)))
		_frame(at, "ship", -PI * 0.5, lerpf(2.6, 1.0, climb))
		if time < 0.6:
			FrameArt.draw_transform(self, Vector2(c.x, screen.y * 0.75), time / 0.6, Color(0.5, 0.9, 1.0))
	else:
		# Recovered, not lost: a tractor beam hauls the battered frame aboard.
		var haul := clampf((time - 0.7) / 1.6, 0.0, 1.0)
		var at := Vector2(c.x, lerpf(screen.y * 0.78, mouth_y, haul))
		draw_colored_polygon(PackedVector2Array([Vector2(c.x - 50, mouth_y), Vector2(c.x + 50, mouth_y), Vector2(c.x + 110, at.y + 40), Vector2(c.x - 110, at.y + 40)]),
			Color(0.5, 1.0, 0.85, 0.18 + 0.06 * sin(time * 12.0)))
		_frame(at, "mech", -PI * 0.5 + sin(time * 2.0) * 0.3, lerpf(2.4, 1.0, haul), 0.3 if int(time * 8.0) % 2 == 0 else 0.0)
	draw_string(UiKit.font("title"), Vector2(0, screen.y * 0.9), "RECOVERED BY THE DROPSHIP" if not won else "RETURNING TO THE DROPSHIP",
		HORIZONTAL_ALIGNMENT_CENTER, screen.x, 22, Color(1, 0.85, 0.5) if won else Color(0.6, 1.0, 0.85))
