class_name EngineAudio
extends Node3D

## Engine and road sound. The engine is a recorded CC0 loop (audio/engine_loop.wav,
## see CREDITS.md) pitched by a simple virtual gearbox: revs climb through each
## gear and drop at every shift, so acceleration sounds like a van working
## through its gears. Load (throttle, climbing) makes it louder and rougher; a
## short cranking chug plays on start-up. Tyre and wind roar is procedural.

const MIX_RATE := 22050.0
## Upshift speeds in m/s: 1st to 2nd at 20 km/h, and so on.
const SHIFT_AT := [5.5, 11.0, 17.0, 24.0]
const IDLE_RPM := 0.14
const PITCH_IDLE := 0.62           ## sample pitch at idle
const PITCH_SPAN := 1.25           ## added pitch at the redline
const CRANK_TIME := 0.75

var _engine: AudioStreamPlayer3D
var _road: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback

var _on := false
var _rpm_in := 0.0                 ## the van's own 0..1 rpm estimate (throttle + speed)
var _throttle := 0.0
var _speed := 0.0
var _rpm := 0.0                    ## smoothed virtual rpm 0..1
var _gear := 0
var _gain := 0.0
var _crank_t := 0.0
var _lp := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4242
	_engine = AudioStreamPlayer3D.new()
	_engine.name = "EngineVoice"
	var s := load("res://audio/engine_loop.wav") as AudioStreamWAV
	if s != null:
		s = s.duplicate() as AudioStreamWAV
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)
		_engine.stream = s
	_engine.unit_size = 7.0
	_engine.max_db = 3.0
	_engine.volume_db = -80.0
	_engine.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_engine.max_distance = 110.0
	_engine.position = Vector3(0, 0.8, -2.8)
	add_child(_engine)

	var gen := AudioStreamGenerator.new()
	gen.mix_rate = MIX_RATE
	# Generous buffer: a short one ran dry (audible crackle) on any frame hitch.
	gen.buffer_length = 0.3
	_road = AudioStreamPlayer3D.new()
	_road.name = "RoadVoice"
	_road.stream = gen
	_road.unit_size = 6.0
	_road.volume_db = -4.0
	_road.max_distance = 70.0
	add_child(_road)
	_road.play()
	_playback = _road.get_stream_playback()


func set_state(engine_on: bool, rpm_norm: float, speed: float, throttle := 0.0) -> void:
	if engine_on and not _on:
		_crank_t = CRANK_TIME
	_on = engine_on
	_rpm_in = rpm_norm
	_speed = speed
	_throttle = throttle


## Revs from the virtual gearbox: position within the current gear's speed band.
func _gear_rpm() -> float:
	var g := 0
	while g < SHIFT_AT.size() and _speed > SHIFT_AT[g] + (0.0 if g >= _gear else -1.5):
		g += 1        # (the -1.5 m/s hysteresis stops it hunting between two gears)
	_gear = g
	var lo: float = 0.0 if g == 0 else SHIFT_AT[g - 1]
	var hi: float = SHIFT_AT[g] if g < SHIFT_AT.size() else 36.0
	var band := clampf((_speed - lo) / (hi - lo), 0.0, 1.0)
	var rpm := lerpf(0.30 if g > 0 else IDLE_RPM, 0.92, band)
	# revving against the handbrake or in neutral-ish crawling
	rpm = maxf(rpm, IDLE_RPM + _throttle * (0.45 if _speed < 1.0 else 0.15))
	return rpm


func _process(delta: float) -> void:
	if Sfx.muted:
		_engine.volume_db = -80.0
		return
	var want := _gear_rpm() if _on else 0.0
	# revs fall fast at a shift and rise with the throttle
	var rate := 9.0 if want < _rpm else (3.0 + _throttle * 4.0)
	_rpm = lerpf(_rpm, want, clampf(delta * rate, 0.0, 1.0))
	_gain = lerpf(_gain, 1.0 if _on else 0.0, clampf(delta * (4.0 if _on else 2.5), 0.0, 1.0))

	var pitch := PITCH_IDLE + _rpm * PITCH_SPAN
	var vol := lerpf(-9.0, -1.0, clampf(_rpm * 0.6 + _throttle * 0.5, 0.0, 1.0))
	if _crank_t > 0.0:
		# starter motor: slow, lumpy chug that catches into idle
		_crank_t -= delta
		var k := 1.0 - _crank_t / CRANK_TIME
		pitch = lerpf(0.34, PITCH_IDLE, k * k)
		vol += -4.0 + 3.0 * sin(Time.get_ticks_msec() * 0.075)
	if _gain < 0.01:
		if _engine.playing:
			_engine.stop()
	else:
		if not _engine.playing and _engine.stream != null:
			_engine.play()
		_engine.pitch_scale = clampf(pitch, 0.2, 3.0)
		_engine.volume_db = vol + linear_to_db(maxf(_gain, 0.001))
	_fill()


## Tyre and wind roar: present even with the engine off while rolling.
func _fill() -> void:
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	var road := clampf(_speed / 26.0, 0.0, 1.0)
	var amp := 0.07 * road * road
	if amp < 0.0005:
		var z := PackedVector2Array()
		z.resize(frames)
		_playback.push_buffer(z)
		_lp = 0.0
		return
	for _i in frames:
		# one-pole low pass keeps it a rumble, not a hiss
		_lp = lerpf(_lp, _rng.randf_range(-1.0, 1.0) * amp, 0.30)
		_playback.push_frame(Vector2(_lp, _lp))
