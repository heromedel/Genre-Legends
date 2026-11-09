class_name InputFrame
extends RefCounted
## One simulation tick's worth of player input. The simulation reads input only through this,
## so a recorded list of InputFrames replays a mission exactly (GDD 4C, 4D proposal).
## Values are quantized before use so recorded and live play see identical numbers.

var move := Vector2.ZERO    # movement stick, each axis -1..1
var drag := Vector2.ZERO    # ship form: finger drag this tick, in field units
var aim := Vector2.ZERO     # aim stick; zero means auto-aim
var special := false        # special button pressed this tick
var choice := -1            # chosen card when a level-up or crate is showing
var fire := true            # holding fire; only matters with auto-fire off (Settings)


func quantized() -> InputFrame:
	var q := InputFrame.new()
	q.move = (move.limit_length(1.0) * 64.0).round() / 64.0
	q.aim = (aim.limit_length(1.0) * 64.0).round() / 64.0
	q.drag = (drag.limit_length(40.0) * 4.0).round() / 4.0
	q.special = special
	q.choice = clampi(choice, -1, 9)
	q.fire = fire
	return q


func equals(other: InputFrame) -> bool:
	return move == other.move and drag == other.drag and aim == other.aim \
		and special == other.special and choice == other.choice and fire == other.fire


## Compact text form for the play log: "mx,my,dx,dy,ax,ay,s,c,f" with integers. Logs from before the
## fire field (8 values) decode as always firing, which is what auto-fire meant then.
func encode() -> String:
	return "%d,%d,%d,%d,%d,%d,%d,%d,%d" % [
		roundi(move.x * 64), roundi(move.y * 64), roundi(drag.x * 4), roundi(drag.y * 4),
		roundi(aim.x * 64), roundi(aim.y * 64), int(special), choice, int(fire)]


## Decodes a run-length list of frames ("a;b*3;c") as written by the play log.
static func decode_runs(text: String) -> Array:
	var frames := []
	if text == "":
		return frames
	for part in text.split(";"):
		var pieces := part.split("*")
		var count := 1 if pieces.size() == 1 else int(pieces[1])
		for i in count:
			frames.append(decode(pieces[0]))
	return frames


static func decode(text: String) -> InputFrame:
	var parts := text.split(",")
	var frame := InputFrame.new()
	if parts.size() < 8:
		return frame
	frame.move = Vector2(int(parts[0]), int(parts[1])) / 64.0
	frame.drag = Vector2(int(parts[2]), int(parts[3])) / 4.0
	frame.aim = Vector2(int(parts[4]), int(parts[5])) / 64.0
	frame.special = int(parts[6]) != 0
	frame.choice = int(parts[7])
	frame.fire = parts.size() < 9 or int(parts[8]) != 0
	return frame
