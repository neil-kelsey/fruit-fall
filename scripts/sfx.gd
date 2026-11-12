class_name Sfx
extends Node
## All sounds are synthesised at startup: wooden thunks scaled by fruit size,
## bell chimes on the Japanese "In" scale for merges, a koto-like game-over phrase.

const RATE := 22050
const IN_SCALE := [0, 1, 5, 7, 8, 12, 13, 17, 19, 20, 24]
var players: Array[AudioStreamPlayer] = []
var _next := 0
var thunks: Array[AudioStreamWAV] = []
var chimes: Array[AudioStreamWAV] = []
var drop_snd: AudioStreamWAV
var over_snd: AudioStreamWAV
var click_snd: AudioStreamWAV
var _last_thunk_ms := 0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	for i in 12:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	for i in 10:
		thunks.append(_thunk(230.0 - i * 16.0, 0.16 + i * 0.025))
	for i in 11:
		chimes.append(_chime(293.66 * pow(2.0, IN_SCALE[i] / 12.0)))
	drop_snd = _pluck(880.0, 0.12, 0.25)
	click_snd = _pluck(1320.0, 0.08, 0.3)
	over_snd = _over()


func _wav(s: PackedFloat32Array) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, int(clampf(s[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


func _thunk(f0: float, dur: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := f0 * (1.0 + 0.7 * exp(-t * 45.0))
		ph += TAU * f / RATE
		lp += (rng.randf_range(-1.0, 1.0) - lp) * 0.25
		var env := exp(-t * (14.0 / dur * 0.25)) * minf(1.0, t * 800.0)
		s[i] = (sin(ph) * 0.75 + sin(ph * 2.03) * 0.12) * env + lp * exp(-t * 70.0) * 0.5
	return _wav(s)


func _chime(f: float) -> AudioStreamWAV:
	var dur := 1.3
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	var parts := [[1.0, 1.0, 3.0], [2.0, 0.45, 4.5], [3.01, 0.25, 6.0], [4.2, 0.12, 8.0], [5.43, 0.07, 11.0]]
	for i in n:
		var t := float(i) / RATE
		var v := 0.0
		for p in parts:
			v += sin(TAU * f * p[0] * t) * p[1] * exp(-t * p[2])
		s[i] = v * 0.38 * minf(1.0, t * 300.0)
	return _wav(s)


func _pluck(f: float, dur: float, vol: float) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for i in n:
		var t := float(i) / RATE
		s[i] = (sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)) * exp(-t * 30.0) * vol * minf(1.0, t * 500.0)
	return _wav(s)


func _over() -> AudioStreamWAV:
	var notes := [20, 17, 13, 12, 8, 5]
	var step := 0.28
	var dur := step * notes.size() + 1.2
	var n := int(dur * RATE)
	var s := PackedFloat32Array()
	s.resize(n)
	for k in notes.size():
		var f := 196.0 * pow(2.0, notes[k] / 12.0)
		var start := int(k * step * RATE)
		for i in range(start, n):
			var t := float(i - start) / RATE
			var vib := 1.0 + 0.006 * sin(TAU * 5.5 * t) * minf(1.0, t * 3.0)
			var v := (sin(TAU * f * vib * t) + 0.5 * sin(TAU * 2.0 * f * t) * exp(-t * 6.0) + 0.25 * sin(TAU * 3.0 * f * t) * exp(-t * 9.0))
			s[i] += v * exp(-t * 2.6) * 0.3 * minf(1.0, t * 400.0)
	return _wav(s)


func _play(stream: AudioStream, db := 0.0, pitch := 1.0) -> void:
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = stream
	p.volume_db = db
	p.pitch_scale = pitch
	p.play()


func play_thunk(tier: int, strength: float) -> void:
	var now := Time.get_ticks_msec()
	if now - _last_thunk_ms < 35:
		return
	_last_thunk_ms = now
	var db := linear_to_db(clampf(strength / 1600.0, 0.12, 1.0)) - 3.0
	_play(thunks[tier], db, rng.randf_range(0.92, 1.08))


func play_merge(new_tier: int, combo: int) -> void:
	_play(chimes[clampi(new_tier, 0, 10)], -4.0, 1.0 + minf(combo - 1, 4) * 0.0)
	_play(thunks[clampi(new_tier, 0, 9)], -6.0, 1.3)


func play_drop() -> void:
	_play(drop_snd, -8.0, rng.randf_range(0.95, 1.05))


func play_click() -> void:
	_play(click_snd, -6.0)


func play_over() -> void:
	_play(over_snd, -2.0)
