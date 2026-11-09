class_name InputRecording
extends RefCounted
## A mission's inputs, one InputFrame per tick, kept as runs (a frame and how many ticks in a row it held) so
## minutes of play stay small. Replaying them through a Mission rebuilt from the same launch reproduces the
## mission exactly (the simulation is deterministic). The play log keeps one for replays; the mission
## checkpoint keeps one to resume a mission after the browser closes.

var _texts := PackedStringArray()   # each run already written as text; the last one is rewritten as it grows
var _last_frame := ""               # the last run's encoded frame
var _last_count := 0                # how many ticks in a row it has held
var ticks := 0


func add(frame: InputFrame) -> void:
	var encoded := frame.encode()
	if _last_count > 0 and encoded == _last_frame:
		_last_count += 1
		_texts[-1] = "%s*%d" % [encoded, _last_count]
	else:
		_last_frame = encoded
		_last_count = 1
		_texts.append(encoded)
	ticks += 1


func clear() -> void:
	_texts = PackedStringArray()
	_last_frame = ""
	_last_count = 0
	ticks = 0


## The runs as text: "frame;frame*repeats;..." (InputFrame.decode_runs reads it back). Each run is written
## once as it happens, so saving a long mission every few seconds is a single join, not a rewrite.
func encode() -> String:
	return ";".join(_texts)
