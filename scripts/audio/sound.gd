extends Node
## Autoload "Sound": plays sound effects and music made by Synth. Effects are built during boot,
## a few per frame so nothing freezes; each music track is built the first time it's needed,
## also a slice per frame, and fades in when ready.
## On iPad, browsers only allow sound after a tap: the title screen's "tap to start" provides it.

const EFFECT_NAMES := ["shot", "rail", "hex", "slash", "missiles", "explode", "explode_big", "player_hit",
	"enemy_shot", "pickup", "level_up", "upgrade", "pick", "crate", "reel", "reel_stop", "jackpot", "blueprint",
	"key", "repair", "warning", "phase", "boss_down", "victory", "nova", "black_hole", "time_brake", "shatter",
	"mirror", "vent", "overdrive", "meteor", "transform", "dive", "charge", "spawn", "door_slam", "door_open",
	"secret", "mimic", "pedestal", "block", "lob", "splat", "burrow", "mortar", "bounce", "blink", "curtain",
	"laser", "ui", "radio"]
const POLYPHONY := 14
## Quieter or rarer effects get a minimum gap so a hundred bullets don't make a hundred clicks.
const MIN_GAP := {"shot": 0.06, "enemy_shot": 0.09, "pickup": 0.05, "explode": 0.05, "block": 0.08, "hex": 0.12, "rail": 0.08}
const VOLUME := {"shot": -6.0, "enemy_shot": -8.0, "pickup": -6.0, "block": -8.0, "hex": -9.0, "ui": -4.0}

var synth := Synth.new()
var effects := {}
var tracks := {}
var players: Array = []
var music: AudioStreamPlayer
var _last_played := {}
var _building_track := ""
var _wanted_track := ""
var _effects_ready := false
var _audio_check := 0.0           # seconds until the page's audio state is next checked for the play log


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POLYPHONY:
		var player := AudioStreamPlayer.new()
		add_child(player)
		players.append(player)
	music = AudioStreamPlayer.new()
	add_child(music)
	_build_effects()


## Every couple of seconds, anything the browser did to the page's audio goes into the play log, so a sound
## dropout on the iPad shows up there (Browser.audio_events).
func _process(delta: float) -> void:
	_audio_check -= delta
	if _audio_check > 0.0:
		return
	_audio_check = 2.0
	for event in Browser.audio_events():
		PlayLog.note("audio", str(event))


func _build_effects() -> void:
	for effect in EFFECT_NAMES:
		effects[effect] = synth.make_effect(effect)
		await get_tree().process_frame
	_effects_ready = true


func _volume(setting: String) -> float:
	var save := get_node_or_null("/root/Save")
	var value: float = save.setting(setting) if save != null and not save.data.is_empty() else 0.7
	return linear_to_db(maxf(value, 0.0001))


func play(effect: String, volume_db: float = 0.0) -> void:
	if not effects.has(effect):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(effect, -10.0)) < MIN_GAP.get(effect, 0.03):
		return
	_last_played[effect] = now
	for player: AudioStreamPlayer in players:
		if not player.playing:
			player.stream = effects[effect]
			player.volume_db = volume_db + VOLUME.get(effect, 0.0) + _volume("sfx")
			player.play()
			return


func play_music(track: String) -> void:
	_wanted_track = track
	if tracks.has(track):
		_start_track(track)
	elif _building_track == "":
		_build_track(track)


func stop_music() -> void:
	_wanted_track = ""
	music.stop()


func refresh_volume() -> void:
	music.volume_db = _volume("music") - 6.0


func _start_track(track: String) -> void:
	if music.stream == tracks[track] and music.playing:
		return
	music.stream = tracks[track]
	refresh_volume()
	music.play()


## Builds a track a bar at a time across frames, so the game keeps running smoothly.
func _build_track(track: String) -> void:
	_building_track = track
	await get_tree().process_frame
	var buffer := synth.make_track(track)
	await get_tree().process_frame
	tracks[track] = synth.to_stream(buffer, true)
	_building_track = ""
	if _wanted_track == track:
		_start_track(track)
	elif _wanted_track != "" and not tracks.has(_wanted_track):
		_build_track(_wanted_track)
