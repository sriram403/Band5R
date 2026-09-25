class_name Mood
extends Node

## The mood curve (DESIGN.md sections 1-2, design/WAY_OUT.md): one number from
## 1 (bright, lively) to 0 (dark), never shown to the players. It drives the
## sky and fog colours, the sun, the colour grade, the birds and forest
## (`Ambience.liveliness`, birds go quiet first), the traffic (`Traffic.density`)
## and how well the creatures can see (dusk and night shorten their sight).
## `value` eases towards `target` slowly, so the world greys without a jump.
## On the way out the target only ever falls, as the van passes each place.

const EASE := 0.012                   ## per second: 0.4 of the dial takes ~35 s
## [poi name, mood there]: the way out greys from P2's home to the coast.
const WAY_OUT := [["p2_home", 1.0], ["j1", 0.95], ["j2", 0.85], ["bridge", 0.78],
	["ghat_pass", 0.7], ["coast_tower", 0.62], ["roses", 0.6]]
const REACH := 70.0                   ## m from a place to count as there

## Three looks the dial blends between: dark (0), grey (0.5), bright (1).
const LOOKS := {
	"sky_top": [Color(0.10, 0.12, 0.22), Color(0.40, 0.48, 0.58), Color(0.16, 0.40, 0.82)],
	"sky_horizon": [Color(0.40, 0.34, 0.40), Color(0.70, 0.73, 0.77), Color(0.62, 0.80, 0.93)],
	"fog": [Color(0.28, 0.30, 0.36), Color(0.64, 0.68, 0.72), Color(0.68, 0.80, 0.90)],
	"sun_color": [Color(1.0, 0.70, 0.52), Color(0.96, 0.94, 0.90), Color(1.0, 0.965, 0.88)],
	"sun": [0.25, 1.0, 1.6],
	"ambient": [0.28, 0.45, 0.55],
	"saturation": [0.80, 0.98, 1.22],
	"fog_begin": [70.0, 150.0, 260.0],
	"fog_end": [700.0, 1100.0, 1500.0],
}

var value := 1.0
var fog_boost := 0.0             ## 0..1 local fog on top (the ghat hairpins), set by Ghat
var target := 1.0
var _env: Environment
var _sky: ProceduralSkyMaterial
var _sun: DirectionalLight3D
var _shown := -1.0
var _check_t := 0.0


func _ready() -> void:
	add_to_group("mood")
	var world := get_parent()
	var we := world.get_node_or_null("Environment") as WorldEnvironment
	if we != null:
		_env = we.environment
		_sky = _env.sky.sky_material as ProceduralSkyMaterial
	_sun = world.get_node_or_null("Sun") as DirectionalLight3D
	apply()


## Jump straight to a mood (loading a save, the developer menu, tests).
func set_now(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	target = value
	apply()


func _process(delta: float) -> void:
	_check_t -= delta
	if _check_t <= 0.0:
		_check_t = 0.5
		_way_out()
	value = move_toward(value, target, EASE * delta)
	if absf(value - _shown) > 0.002:
		apply()


## The van (or a player) at a place on the way out: the mood falls to that
## place's value, never rises (the drive home brightens it on its own terms).
func _way_out() -> void:
	var builder = get_tree().current_scene.get("builder")
	if builder == null:
		return
	var poi: Dictionary = builder.poi
	var at: Array = []
	for n in get_tree().get_nodes_in_group("player"):
		at.append((n as Node3D).global_position)
	for spec in WAY_OUT:
		if not poi.has(spec[0]):
			continue
		var p: Vector3 = poi[spec[0]]
		for q in at:
			if Vector2(q.x - p.x, q.z - p.z).length() < REACH:
				target = minf(target, float(spec[1]))


func apply() -> void:
	_shown = value
	if _sky != null:
		_sky.sky_top_color = _blend("sky_top")
		_sky.sky_horizon_color = _blend("sky_horizon")
		_sky.ground_horizon_color = _blend("sky_horizon").darkened(0.25)
	if _env != null:
		_env.fog_light_color = _blend("fog")
		_env.fog_depth_begin = lerpf(_blend("fog_begin"), 3.0, fog_boost)
		_env.fog_depth_end = lerpf(_blend("fog_end"), 40.0, fog_boost)
		if fog_boost > 0.0:
			_env.fog_light_color = _blend("fog").lerp(Color(0.72, 0.74, 0.76), fog_boost)
		_env.ambient_light_energy = _blend("ambient")
		_env.adjustment_saturation = _blend("saturation")
	if _sun != null:
		_sun.light_energy = _blend("sun")
		_sun.light_color = _blend("sun_color")
	var amb := get_parent().get_node_or_null("Ambience") as Ambience
	if amb != null:
		amb.liveliness = value
	var builder = get_tree().current_scene.get("builder") if get_tree() != null and get_tree().current_scene != null else null
	if builder != null and builder.get("traffic") != null:
		# cars thin out from about 0.9 and are all gone by 0.6
		(builder.traffic as Traffic).density = clampf((value - 0.6) / 0.3, 0.0, 1.0)
	for c in get_tree().get_nodes_in_group("creature"):
		(c as Creature).light = light()


## For the creatures' eyes: 0 day, 1 dusk, 2 night.
func light() -> int:
	if value < 0.2:
		return 2
	return 1 if value < 0.45 else 0


func _blend(key: String):
	var l: Array = LOOKS[key]
	if value >= 0.5:
		return _lerp(l[1], l[2], (value - 0.5) * 2.0)
	return _lerp(l[0], l[1], value * 2.0)


func _lerp(a, b, t: float):
	if a is Color:
		return (a as Color).lerp(b, t)
	return lerpf(a, b, t)
