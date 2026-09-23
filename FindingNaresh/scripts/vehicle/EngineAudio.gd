class_name EngineAudio
extends Node3D

## Fully procedural engine + road noise, so the prototype has driving feel
## without shipping any third-party audio files.
##
## Replaceable later: swap this node for sampled loops and keep set_state().

const MIX_RATE := 22050.0
const BASE_HZ := 26.0
const REV_HZ := 96.0

var _engine: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback

var _on := false
var _rpm := 0.0
var _speed := 0.0
var _rpm_smooth := 0.0
var _gain := 0.0
var _phase := 0.0
var _lp := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	# Generous buffer: latency does not matter for an engine drone, and a short
	# one ran dry (audible crackle) on any frame hitch.
	gen.buffer_length = 0.3

	_engine = AudioStreamPlayer3D.new()
	_engine.name = "EngineVoice"
	_engine.stream = gen
	_engine.unit_size = 6.0
	_engine.max_db = 2.0
	_engine.volume_db = -4.0
	_engine.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_engine.max_distance = 90.0
	_engine.position = Vector3(0, 0.8, -2.6)
	add_child(_engine)
	_engine.play()
	_playback = _engine.get_stream_playback()


func set_state(engine_on: bool, rpm_norm: float, speed: float) -> void:
	_on = engine_on
	_rpm = rpm_norm
	_speed = speed


func _process(delta: float) -> void:
	if _playback == null:
		return
	_rpm_smooth = lerp(_rpm_smooth, _rpm, clampf(delta * 6.0, 0.0, 1.0))
	_gain = lerp(_gain, 1.0 if _on else 0.0, clampf(delta * 3.0, 0.0, 1.0))
	_fill()


func _fill() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var freq := BASE_HZ + _rpm_smooth * REV_HZ
	var step := freq / MIX_RATE
	var road := clampf(_speed / 26.0, 0.0, 1.0)
	var engine_amp := (0.10 + _rpm_smooth * 0.30) * _gain

	for _i in frames:
		_phase = fmod(_phase + step, 1.0)
		# stacked saw harmonics give a lumpy four-cylinder character
		var s := 0.0
		s += (_phase * 2.0 - 1.0)
		s += (fmod(_phase * 2.0, 1.0) * 2.0 - 1.0) * 0.55
		s += (fmod(_phase * 3.0, 1.0) * 2.0 - 1.0) * 0.28
		s *= 0.42
		# combustion rasp
		s += _rng.randf_range(-1.0, 1.0) * 0.20 * _rpm_smooth
		s *= engine_amp
		# tyre roar / wind, present even with the engine off while rolling
		s += _rng.randf_range(-1.0, 1.0) * 0.055 * road * road
		# one-pole low pass keeps it from sounding like white noise
		_lp = lerp(_lp, s, 0.34)
		var v: float = clampf(_lp, -1.0, 1.0)
		_playback.push_frame(Vector2(v, v))
