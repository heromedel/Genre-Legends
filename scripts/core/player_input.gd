class_name PlayerInput
extends Control
## Input: turns touches, keyboard, mouse and controllers into one InputFrame per simulation tick.
## Touch controls match the frame's form (GDD 2B):
##   ship  - drag anywhere: the ship follows your finger, offset so your thumb never hides it.
##   mech  - left half of the screen is a floating move stick, right half a floating aim stick.
##           Weapons always fire on their own. With auto-aim on (Settings) the mech turns to the nearest
##           enemy when you let go; otherwise it faces where you move.
## Keyboard: WASD / arrows move, Space special. Mouse: hold to aim (mech) or drag (ship).
## Controller (GDD 2D): left stick moves, right stick aims, A or a shoulder button fires the special.
## It also draws the stick rings while thumbs are down.

const STICK_RADIUS := 70.0
const DEADZONE := 0.18

var form := "ship"
var world_scale := 1.0              # screen pixels per world unit, from the camera
var blocked_rects: Array = []       # screen rects owned by buttons (special, pause)

var _drag_accumulated := Vector2.ZERO
var _special_queued := false
var _choice_queued := -1
var _touches := {}                  # index -> {role, origin, pos, last}
var _mouse_down := false
var _mouse_last := Vector2.ZERO
var _mouse_aim := Vector2.ZERO
var _player_screen_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ensure_actions()


## Adds the keyboard and controller actions if the project doesn't define them.
func _ensure_actions() -> void:
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"special": [KEY_SPACE, KEY_SHIFT], "pause": [KEY_ESCAPE, KEY_P],
	}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode in keys[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
	for pair in [["special", JOY_BUTTON_A], ["special", JOY_BUTTON_RIGHT_SHOULDER], ["pause", JOY_BUTTON_START]]:
		var joy := InputEventJoypadButton.new()
		joy.button_index = pair[1]
		InputMap.action_add_event(pair[0], joy)


func set_player_screen_position(at: Vector2) -> void:
	_player_screen_pos = at


func queue_special() -> void:
	_special_queued = true


func queue_choice(index: int) -> void:
	_choice_queued = index


func clear() -> void:
	_touches.clear()
	_drag_accumulated = Vector2.ZERO
	_mouse_down = false
	queue_redraw()


## Builds this tick's InputFrame and resets the one-shot parts.
func poll() -> InputFrame:
	var frame := InputFrame.new()
	var keyboard := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var left_stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	var right_stick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X), Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	frame.move = keyboard
	if left_stick.length() > DEADZONE:
		frame.move = left_stick
	if right_stick.length() > DEADZONE:
		frame.aim = right_stick
	for touch in _touches.values():
		var offset: Vector2 = touch["pos"] - touch["origin"]
		var stick := (offset / STICK_RADIUS).limit_length(1.0)
		if stick.length() < DEADZONE:
			stick = Vector2.ZERO
		if touch["role"] == "move":
			frame.move = stick
		elif touch["role"] == "aim":
			frame.aim = stick
	if form == "mech" and _mouse_down and _mouse_aim != Vector2.ZERO:
		frame.aim = _mouse_aim
	frame.drag = _drag_accumulated / maxf(world_scale, 0.01)
	_drag_accumulated = Vector2.ZERO
	frame.special = _special_queued or Input.is_action_just_pressed("special")
	_special_queued = false
	frame.choice = _choice_queued
	_choice_queued = -1
	return frame.quantized()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and event.device != InputEvent.DEVICE_ID_EMULATION and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _blocked(event.position):
			return
		_mouse_down = event.pressed
		_mouse_last = event.position
		_update_mouse_aim(event.position)
	elif event is InputEventMouseMotion and event.device != InputEvent.DEVICE_ID_EMULATION and _mouse_down:
		if form == "ship":
			_drag_accumulated += event.position - _mouse_last
		_mouse_last = event.position
		_update_mouse_aim(event.position)


func _update_mouse_aim(at: Vector2) -> void:
	var offset := at - _player_screen_pos
	_mouse_aim = offset.normalized() if offset.length() > 20.0 else Vector2.ZERO


func _blocked(at: Vector2) -> bool:
	for rect: Rect2 in blocked_rects:
		if rect.has_point(at):
			return true
	return false


func _on_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if _blocked(event.position):
			return
		var role := "drag"
		if form == "mech":
			role = "move" if event.position.x < get_viewport_rect().size.x * 0.5 else "aim"
			# One thumb per side: a second touch on the same side takes over.
			for index in _touches.keys():
				if _touches[index]["role"] == role:
					_touches.erase(index)
		_touches[event.index] = {"role": role, "origin": event.position, "pos": event.position, "last": event.position}
	else:
		_touches.erase(event.index)
	queue_redraw()


func _on_drag(event: InputEventScreenDrag) -> void:
	if not _touches.has(event.index):
		return
	var touch: Dictionary = _touches[event.index]
	if touch["role"] == "drag":
		_drag_accumulated += event.position - touch["last"]
	else:
		# A floating stick follows the thumb if it strays too far, so it never feels stuck.
		var offset: Vector2 = event.position - touch["origin"]
		if offset.length() > STICK_RADIUS * 1.4:
			touch["origin"] = event.position - offset.normalized() * STICK_RADIUS * 1.4
	touch["last"] = event.position
	touch["pos"] = event.position
	queue_redraw()


func _draw() -> void:
	for touch in _touches.values():
		if touch["role"] == "drag":
			continue
		var origin: Vector2 = touch["origin"]
		var knob: Vector2 = origin + (touch["pos"] - origin).limit_length(STICK_RADIUS)
		var color := Color(0.5, 0.9, 1.0) if touch["role"] == "move" else Color(1.0, 0.75, 0.4)
		draw_circle(origin, STICK_RADIUS, Color(color.r, color.g, color.b, 0.08))
		draw_arc(origin, STICK_RADIUS, 0, TAU, 40, Color(color.r, color.g, color.b, 0.45), 2.0, true)
		draw_circle(knob, 26.0, Color(color.r, color.g, color.b, 0.35))
		draw_arc(knob, 26.0, 0, TAU, 24, Color(1, 1, 1, 0.6), 2.0, true)
