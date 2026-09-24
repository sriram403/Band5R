class_name NoiseLoop
extends Node3D

## A shaped-noise sound made on the fly, for things there is no sample of:
## pouring (a low gurgle), steam (a bright hiss), wind (a slow, soft rush) and
## water (a babbling river or lapping lake shore).
## Set `target` 0..1 to fade it in and out; nothing is played while silent.

enum Kind { POUR, STEAM, WIND, WATER }

const MIX_RATE := 22050.0

var kind := Kind.STEAM
var target := 0.0                  ## desired loudness 0..1
var positional := true
var volume_db := -6.0

var _player: Node
var _playback: AudioStreamGeneratorPlayback
var _gain := 0.0
var _lp := 0.0
var _lp2 := 0.0
var _phase := 0.0
var _gurgle := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	gen.buffer_length = 0.3
	if positional:
		var p3 := AudioStreamPlayer3D.new()
		p3.unit_size = 5.0
		p3.max_distance = 50.0
		_player = p3
	else:
		_player = AudioStreamPlayer.new()
	_player.stream = gen
	_player.volume_db = volume_db
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()


func _process(delta: float) -> void:
	if _playback == null:
		return
	var goal := 0.0 if Sfx.muted else target
	_gain = lerpf(_gain, goal, clampf(delta * 4.0, 0.0, 1.0))
	var frames := _playback.get_frames_available()
	if _gain < 0.002 and goal == 0.0:
		# silent: feed zeros in one call instead of a per-sample loop
		var z := PackedVector2Array()
		z.resize(frames)
		_playback.push_buffer(z)
		return
	for _i in frames:
		var n := _rng.randf_range(-1.0, 1.0)
		var v := 0.0
		match kind:
			Kind.STEAM:
				# bright: high-passed noise
				_lp = lerpf(_lp, n, 0.25)
				v = (n - _lp) * 0.5
			Kind.POUR:
				# low gurgle: dark noise, chopped by random bubbles
				_lp = lerpf(_lp, n, 0.08)
				_gurgle = maxf(0.0, _gurgle - 0.0006)
				if _rng.randf() < 0.0009:
					_gurgle = _rng.randf_range(0.5, 1.0)
				v = _lp * (0.6 + _gurgle) * 1.6
			Kind.WIND:
				# slow gusts: very dark noise with a wandering level
				_lp = lerpf(_lp, n, 0.02)
				_lp2 = lerpf(_lp2, _lp, 0.05)
				_phase += 1.0 / MIX_RATE
				v = _lp2 * 3.0 * (0.6 + 0.4 * sin(_phase * 0.7) * sin(_phase * 0.23))
			Kind.WATER:
				# babbling: mid-band noise with a quick, wandering flutter
				_lp = lerpf(_lp, n, 0.35)
				_lp2 = lerpf(_lp2, _lp, 0.06)
				_phase += 1.0 / MIX_RATE
				_gurgle = maxf(0.0, _gurgle - 0.0004)
				if _rng.randf() < 0.0012:
					_gurgle = _rng.randf_range(0.3, 0.9)
				v = (_lp - _lp2) * (0.7 + 0.3 * sin(_phase * 5.3) * sin(_phase * 1.7) + _gurgle) * 1.4
		var s := clampf(v * _gain, -1.0, 1.0)
		_playback.push_frame(Vector2(s, s))
