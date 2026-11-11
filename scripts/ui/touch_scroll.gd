class_name TouchScroll
extends ScrollContainer
## A scroll area you can swipe like a phone list (heromedel: "in menus I should be able to swipe to scroll").
## Godot's own touch scrolling only starts when the swipe begins on the scroll area itself, and these menus are
## mostly buttons and cards, which keep the touch. So this watches touches over its whole area: once a finger
## has moved far enough, it scrolls with it, lets the button it started on go (so a swipe never presses it), and
## coasts a little when the finger lifts. A tap stays a tap.

const SWIPE_START := 14.0        # px a finger must move before it's a swipe, not a tap
const COAST_DECAY := 5.0         # how quickly a fling slows down

var _finger := -1
var _start := Vector2.ZERO
var _swiping := false
var _velocity := 0.0


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _finger < 0 and get_global_rect().has_point(event.position):
			_finger = event.index
			_start = event.position
			_swiping = false
			_velocity = 0.0
		elif not event.pressed and event.index == _finger:
			_finger = -1
			if _swiping:
				_swiping = false
				get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == _finger:
		if not _swiping and absf(event.position.y - _start.y) > SWIPE_START:
			_swiping = true
			_let_go_of_buttons()
		if _swiping:
			scroll_vertical -= int(event.relative.y)
			_velocity = -event.relative.y / maxf(get_process_delta_time(), 0.001)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _finger < 0 and absf(_velocity) > 20.0:
		scroll_vertical += int(_velocity * delta)
		_velocity = lerpf(_velocity, 0.0, clampf(COAST_DECAY * delta, 0.0, 1.0))


## The button the swipe started on has a press waiting. Disabling it for a moment clears that press, so lifting
## the finger later doesn't trigger it. (Faking a release here instead would press it: the finger is still on it.)
func _let_go_of_buttons() -> void:
	var under := get_viewport().gui_get_hovered_control()
	while under != null and not (under is BaseButton) and under != self:
		under = under.get_parent() as Control
	if under is BaseButton and not under.disabled:
		var button := under as BaseButton
		button.disabled = true
		button.set_deferred("disabled", false)
