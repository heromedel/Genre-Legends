class_name Synth
extends RefCounted
## Makes every sound in the game from scratch: sound effects from layered tones and noise, and music
## from a small sequencer (bass, arpeggio, lead and drums). Nothing is downloaded.
## Output is 22 kHz mono, which keeps memory low on the iPad mini.

const RATE := 22050

var rng := RandomNumberGenerator.new()


func _init() -> void:
	rng.seed = 7


## One voice: a tone that slides from one frequency to another with an attack/decay envelope.
## wave: "square", "saw", "sine", "triangle", "noise".
func voice(buffer: PackedFloat32Array, start: float, duration: float, freq_from: float, freq_to: float,
		wave: String, volume: float, attack: float = 0.005, duty: float = 0.5) -> void:
	var first := int(start * RATE)
	var count := int(duration * RATE)
	if first + count > buffer.size():
		count = buffer.size() - first
	var phase := 0.0
	var noise_hold := 0.0
	var noise_counter := 0
	for i in count:
		var t := float(i) / RATE
		var progress := float(i) / count
		var freq := lerpf(freq_from, freq_to, progress)
		phase = fmod(phase + freq / RATE, 1.0)
		var sample := 0.0
		match wave:
			"square":
				sample = 1.0 if phase < duty else -1.0
			"saw":
				sample = phase * 2.0 - 1.0
			"sine":
				sample = sin(phase * TAU)
			"triangle":
				sample = 1.0 - 4.0 * absf(phase - 0.5)
			"noise":
				# Pitched noise: hold each random value for a while, so lower "freq" sounds rougher.
				noise_counter += 1
				if noise_counter >= maxi(1, int(RATE / maxf(freq, 1.0))):
					noise_counter = 0
					noise_hold = rng.randf_range(-1.0, 1.0)
				sample = noise_hold
		var envelope := minf(t / attack, 1.0) * pow(1.0 - progress, 1.6)
		buffer[first + i] += sample * volume * envelope


func to_stream(buffer: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		bytes.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	if loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buffer.size()
	return stream


func blank(seconds: float) -> PackedFloat32Array:
	var buffer := PackedFloat32Array()
	buffer.resize(int(seconds * RATE))
	return buffer


# ---------------------------------------------------------------- sound effects

## Every sound effect by name. Each recipe is a list of voices.
func make_effect(effect: String) -> AudioStreamWAV:
	var b: PackedFloat32Array
	match effect:
		"shot":
			b = blank(0.08); voice(b, 0, 0.08, 1400, 600, "square", 0.16, 0.002, 0.25)
		"rail":
			b = blank(0.3); voice(b, 0, 0.3, 2200, 300, "saw", 0.22); voice(b, 0, 0.12, 4000, 2000, "noise", 0.15)
		"hex":
			# A soft, low falling "thup": it repeats several times a second, so no rising chirp.
			b = blank(0.1); voice(b, 0, 0.1, 440, 300, "triangle", 0.2, 0.004); voice(b, 0, 0.06, 880, 600, "sine", 0.05, 0.004)
		"slash":
			b = blank(0.22); voice(b, 0, 0.22, 3000, 800, "noise", 0.3, 0.01); voice(b, 0, 0.18, 900, 500, "saw", 0.08)
		"missiles":
			b = blank(0.35); voice(b, 0, 0.35, 900, 200, "noise", 0.22, 0.01); voice(b, 0, 0.2, 300, 120, "square", 0.1)
		"explode":
			b = blank(0.35); voice(b, 0, 0.35, 900, 80, "noise", 0.35); voice(b, 0, 0.25, 120, 40, "sine", 0.4)
		"explode_big":
			b = blank(0.9); voice(b, 0, 0.9, 600, 40, "noise", 0.45); voice(b, 0, 0.7, 90, 25, "sine", 0.6)
		"player_hit":
			b = blank(0.25); voice(b, 0, 0.25, 300, 80, "square", 0.3, 0.002, 0.4); voice(b, 0, 0.15, 2000, 500, "noise", 0.25)
		"enemy_shot":
			b = blank(0.1); voice(b, 0, 0.1, 500, 300, "triangle", 0.12)
		"pickup":
			b = blank(0.07); voice(b, 0, 0.07, 1800, 2600, "sine", 0.12)
		"level_up":
			b = blank(0.6)
			for i in 4:
				voice(b, i * 0.08, 0.3, [523.0, 659.0, 784.0, 1046.0][i], [523.0, 659.0, 784.0, 1046.0][i], "square", 0.13, 0.005, 0.3)
		"upgrade", "pick":
			b = blank(0.3); voice(b, 0, 0.15, 660, 990, "square", 0.14, 0.003, 0.3); voice(b, 0.08, 0.2, 990, 1320, "square", 0.12, 0.003, 0.3)
		"crate", "reel":
			b = blank(0.4)
			for i in 6:
				voice(b, i * 0.05, 0.05, 900 + i * 120, 900 + i * 120, "square", 0.1, 0.002, 0.2)
		"reel_stop":
			b = blank(0.12); voice(b, 0, 0.12, 300, 200, "square", 0.2, 0.002, 0.5)
		"jackpot":
			b = blank(1.0)
			var notes := [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0, 1318.0, 1568.0]
			for i in notes.size():
				voice(b, i * 0.07, 0.25, notes[i], notes[i], "square", 0.12, 0.003, 0.25)
		"blueprint", "key":
			b = blank(0.5); voice(b, 0, 0.2, 880, 880, "triangle", 0.2); voice(b, 0.12, 0.35, 1320, 1320, "triangle", 0.2)
		"repair":
			b = blank(0.4); voice(b, 0, 0.4, 400, 900, "sine", 0.25)
		"warning":
			b = blank(1.6)
			for i in 4:
				voice(b, i * 0.4, 0.36, 520, 380, "square", 0.18, 0.01, 0.5)
		"phase":
			b = blank(0.7); voice(b, 0, 0.7, 200, 60, "saw", 0.3); voice(b, 0, 0.5, 1500, 200, "noise", 0.2)
		"boss_down":
			b = blank(1.8); voice(b, 0, 1.8, 300, 30, "noise", 0.5); voice(b, 0, 1.4, 70, 20, "sine", 0.7)
		"victory":
			b = blank(1.4)
			var fanfare := [523.0, 659.0, 784.0, 1046.0, 784.0, 1046.0]
			for i in fanfare.size():
				voice(b, i * 0.12, 0.5 if i == fanfare.size() - 1 else 0.14, fanfare[i], fanfare[i], "square", 0.14, 0.003, 0.3)
		"nova":
			b = blank(1.2); voice(b, 0, 1.2, 1200, 40, "noise", 0.45); voice(b, 0, 1.0, 400, 30, "sine", 0.5)
		"black_hole":
			b = blank(1.4); voice(b, 0, 1.4, 60, 300, "saw", 0.3); voice(b, 0, 1.4, 200, 2000, "noise", 0.12)
		"time_brake":
			b = blank(0.9); voice(b, 0, 0.9, 800, 120, "sine", 0.3); voice(b, 0, 0.9, 1600, 240, "triangle", 0.12)
		"shatter":
			b = blank(0.6); voice(b, 0, 0.6, 5000, 2000, "noise", 0.25)
			for i in 5:
				voice(b, i * 0.04, 0.2, 2000 + i * 300, 2000 + i * 300, "sine", 0.08)
		"mirror":
			b = blank(0.25); voice(b, 0, 0.25, 1200, 1800, "sine", 0.14); voice(b, 0, 0.25, 1810, 2700, "sine", 0.08)
		"vent":
			b = blank(0.6); voice(b, 0, 0.6, 2500, 200, "noise", 0.35); voice(b, 0, 0.4, 150, 50, "sine", 0.4)
		"overdrive":
			b = blank(0.7); voice(b, 0, 0.7, 300, 1200, "saw", 0.2); voice(b, 0.1, 0.5, 600, 2400, "square", 0.08, 0.01, 0.3)
		"meteor":
			b = blank(0.5); voice(b, 0, 0.5, 700, 60, "noise", 0.4); voice(b, 0, 0.3, 100, 40, "sine", 0.45)
		"transform":
			b = blank(0.8); voice(b, 0, 0.8, 200, 1200, "saw", 0.16); voice(b, 0.3, 0.4, 1200, 1800, "square", 0.08, 0.01, 0.25)
		"dive", "charge":
			b = blank(0.4); voice(b, 0, 0.4, 1200, 300, "square", 0.1, 0.01, 0.3)
		"spawn", "door_slam":
			b = blank(0.3); voice(b, 0, 0.3, 160, 60, "square", 0.25, 0.002, 0.5); voice(b, 0, 0.12, 900, 200, "noise", 0.2)
		"door_open", "secret":
			b = blank(0.6)
			for i in 3:
				voice(b, i * 0.1, 0.3, [660.0, 880.0, 1320.0][i], [660.0, 880.0, 1320.0][i], "triangle", 0.18)
		"mimic":
			b = blank(0.6); voice(b, 0, 0.6, 150, 90, "saw", 0.35); voice(b, 0, 0.3, 500, 100, "noise", 0.3)
		"pedestal":
			b = blank(0.8); voice(b, 0, 0.8, 523, 523, "triangle", 0.15); voice(b, 0.1, 0.7, 784, 784, "triangle", 0.12); voice(b, 0.2, 0.6, 1046, 1046, "triangle", 0.1)
		"block":
			b = blank(0.08); voice(b, 0, 0.08, 2200, 1800, "square", 0.08, 0.001, 0.15)
		"lob", "splat", "burrow", "mortar", "bounce", "blink", "curtain", "laser":
			b = blank(0.3); voice(b, 0, 0.3, 400, 120, "noise", 0.22); voice(b, 0, 0.2, 300, 150, "triangle", 0.12)
		"radio":
			# Static, then the two-tone chirp of an open channel.
			b = blank(0.55); voice(b, 0, 0.3, 3000, 1500, "noise", 0.12, 0.005, 0.2)
			voice(b, 0.28, 0.09, 1250, 1250, "square", 0.1, 0.002, 0.3); voice(b, 0.39, 0.12, 1660, 1660, "square", 0.1, 0.002, 0.3)
		"ui":
			b = blank(0.06); voice(b, 0, 0.06, 1500, 1500, "square", 0.08, 0.001, 0.3)
		_:
			b = blank(0.05); voice(b, 0, 0.05, 800, 600, "square", 0.05)
	return to_stream(b)


# ---------------------------------------------------------------- music

## Track styles: tempo, root note, chord progression (scale degrees in natural minor), and character.
const TRACKS := {
	"title": {"bpm": 92, "root": 45, "progression": [0, 5, 3, 4], "drums": "", "lead": true, "bars": 8},
	"hub": {"bpm": 96, "root": 50, "progression": [0, 3, 5, 4], "drums": "", "lead": false, "bars": 8},
	"star_cluster": {"bpm": 140, "root": 45, "progression": [0, 5, 6, 4], "drums": "rock", "lead": true, "bars": 8},
	"corridor": {"bpm": 150, "root": 47, "progression": [0, 0, 5, 6], "drums": "four", "lead": true, "bars": 8},
	"planet": {"bpm": 120, "root": 43, "progression": [0, 3, 4, 5], "drums": "toms", "lead": true, "bars": 8},
	"dungeon": {"bpm": 104, "root": 40, "progression": [0, 1, 0, 6], "drums": "heartbeat", "lead": false, "bars": 8},
	"boss": {"bpm": 158, "root": 40, "progression": [0, 1, 5, 4], "drums": "rock", "lead": true, "bars": 8},
}
## Each genre's instruments (GDD 1B: lean into the tropes): the arcade shooter's chip arpeggios, the
## corridor's galloping saw bass, the planet's toms, the dungeon's slow bells over a heartbeat.
const SOUNDS := {
	"star_cluster": {"arp": "square", "arp_steps": 16, "bass": "square", "bass_style": "octave", "lead": "square", "pad": false},
	"corridor": {"arp": "saw", "arp_steps": 8, "bass": "saw", "bass_style": "gallop", "lead": "saw", "pad": false},
	"planet": {"arp": "triangle", "arp_steps": 8, "bass": "triangle", "bass_style": "octave", "lead": "triangle", "pad": true},
	"dungeon": {"arp": "sine", "arp_steps": 4, "bass": "triangle", "bass_style": "drone", "lead": "sine", "pad": true},
	"boss": {"arp": "saw", "arp_steps": 16, "bass": "saw", "bass_style": "gallop", "lead": "square", "pad": false},
}
const DEFAULT_SOUND := {"arp": "square", "arp_steps": 16, "bass": "triangle", "bass_style": "octave", "lead": "square", "pad": true}
const MINOR := [0, 2, 3, 5, 7, 8, 10]


static func midi_to_freq(note: float) -> float:
	return 440.0 * pow(2.0, (note - 69.0) / 12.0)


## Writes a looping track into a buffer. Long, so callers spread it across frames (see Sound).
func make_track(name: String) -> PackedFloat32Array:
	var style: Dictionary = TRACKS.get(name, TRACKS["hub"])
	rng.seed = hash(name)
	var beat := 60.0 / float(style["bpm"])
	var bars: int = style["bars"]
	var buffer := blank(beat * 4.0 * bars)
	var progression: Array = style["progression"]
	var root: int = style["root"]
	var melody_seed := hash(name) % 1000
	var sound: Dictionary = SOUNDS.get(name, DEFAULT_SOUND)
	var drums: String = style["drums"]
	for bar in bars:
		var degree: int = progression[bar % progression.size()]
		var chord_root: int = root + MINOR[degree % 7] + 12 * int(degree / 7)
		var chord: Array = [chord_root, chord_root + _third(degree), chord_root + 7]
		var bar_start := bar * beat * 4.0
		_bass(buffer, bar_start, beat, chord_root - 12, sound)
		# Arpeggio up and down the chord; the dungeon's is a few slow bell notes.
		var pattern := [0, 1, 2, 1, 0, 2, 1, 2]
		var steps: int = sound["arp_steps"]
		for step in steps:
			var note: int = chord[pattern[step % pattern.size()]] + (24 if sound["arp"] == "sine" else 12)
			var length := beat * 4.0 / steps
			voice(buffer, bar_start + step * length, length * 0.88, midi_to_freq(note), midi_to_freq(note), sound["arp"],
				0.06 if sound["arp"] == "sine" else 0.04, 0.002, 0.25)
		if sound["pad"] or drums == "":
			for tone in chord:
				voice(buffer, bar_start, beat * 4.0, midi_to_freq(tone), midi_to_freq(tone), "sine", 0.05, 0.4)
		# Lead: a simple melody from the scale, seeded per track, repeating every two bars.
		if style["lead"]:
			var motif_rng := RandomNumberGenerator.new()
			motif_rng.seed = melody_seed + (bar % 2) * 31
			var t := 0.0
			while t < 4.0:
				var length: float = [0.5, 0.5, 1.0, 0.25, 0.75][motif_rng.randi() % 5]
				if motif_rng.randf() < 0.8:
					var scale_step := motif_rng.randi() % 7
					var note: int = root + 24 + MINOR[scale_step]
					if motif_rng.randf() < 0.5:
						note = chord[motif_rng.randi() % 3] + 24
					voice(buffer, bar_start + t * beat, length * beat * 0.9, midi_to_freq(note), midi_to_freq(note), sound["lead"],
						0.05 if sound["lead"] == "saw" else 0.06, 0.01, 0.5)
				t += length
		_drums(buffer, bar_start, beat, drums)
	return buffer


## The bass line: octave jumps, a galloping 1-and-a rhythm, or one long drone per bar.
func _bass(buffer: PackedFloat32Array, bar_start: float, beat: float, note: int, sound: Dictionary) -> void:
	var wave: String = sound["bass"]
	match sound["bass_style"]:
		"drone":
			voice(buffer, bar_start, beat * 4.0, midi_to_freq(note), midi_to_freq(note), wave, 0.16, 0.2)
		"gallop":
			for beat_index in 4:
				for offset in [0.0, 0.5, 0.75]:
					var at: float = bar_start + (beat_index + offset) * beat
					voice(buffer, at, beat * 0.22, midi_to_freq(note), midi_to_freq(note), wave, 0.12, 0.003)
		_:
			for step in 8:
				var pitch := note + (12 if step % 2 == 1 else 0)
				voice(buffer, bar_start + step * beat * 0.5, beat * 0.45, midi_to_freq(pitch), midi_to_freq(pitch), wave, 0.16 if wave != "square" else 0.09, 0.004)


## Drum kits: rock (kick 1 and 3, snare 2 and 4), four on the floor, tribal toms, or a slow heartbeat.
func _drums(buffer: PackedFloat32Array, bar_start: float, beat: float, kit: String) -> void:
	match kit:
		"rock", "four":
			for step in 8:
				var at := bar_start + step * beat * 0.5
				if (kit == "four" and step % 2 == 0) or (kit == "rock" and step % 4 == 0):
					voice(buffer, at, 0.18, 140, 40, "sine", 0.55)
				if step % 4 == 2:
					voice(buffer, at, 0.14, 3000, 1200, "noise", 0.22)
					voice(buffer, at, 0.1, 220, 160, "triangle", 0.15)
				voice(buffer, at, 0.04, 9000, 9000, "noise", 0.06 if kit == "rock" else 0.09)
		"toms":
			for hit: Array in [[0.0, 110.0], [0.75, 150.0], [1.5, 110.0], [2.0, 90.0], [2.5, 150.0], [3.0, 110.0], [3.25, 130.0]]:
				voice(buffer, bar_start + hit[0] * beat, 0.22, hit[1], hit[1] * 0.55, "sine", 0.45)
			for step in 4:
				voice(buffer, bar_start + step * beat + beat * 0.5, 0.05, 5000, 5000, "noise", 0.05)
		"heartbeat":
			for offset in [0.0, 0.35]:
				voice(buffer, bar_start + offset * beat, 0.2, 90, 45, "sine", 0.5)
			voice(buffer, bar_start + 2.0 * beat, 0.2, 90, 45, "sine", 0.4)


func _third(degree: int) -> int:
	# Minor-scale chords: i, iv, v and VI-ish voicings; degree 1 is diminished, others major or minor.
	return 3 if degree in [0, 3, 4] else 4
