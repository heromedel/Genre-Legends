class_name InputRecording
extends RefCounted
## A mission's inputs, one InputFrame per tick, kept as runs (a frame and how many ticks in a row it held) so
## minutes of play stay small. Replaying them through a Mission rebuilt from the same launch reproduces the
## mission exactly (the simulation is deterministic). The play log keeps one for replays; the mission
## checkpoint keeps one to resume a mission after the browser closes.

var _runs: Array = []          # [encoded frame, repeat count]
var ticks := 0


func add(frame: InputFrame) -> void:
	var encoded := frame.encode()
	if not _runs.is_empty() and _runs[-1][0] == encoded:
		_runs[-1][1] += 1
	else:
		_runs.append([encoded, 1])
	ticks += 1


func clear() -> void:
	_runs = []
	ticks = 0


## The runs as text: "frame;frame*repeats;..." (InputFrame.decode_runs reads it back).
func encode() -> String:
	var parts := []
	for run in _runs:
		parts.append(run[0] if run[1] == 1 else "%s*%d" % [run[0], run[1]])
	return ";".join(parts)
