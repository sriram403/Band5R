class_name Weather
extends Node

## The weather across the journey (puzzle #3, the user 2026-10-08,
## design/PUZZLE_CHANGES.md #3 "The weather across the journey"):
## - clouds from the start (the opening: building, the sun through the gaps),
##   heavier from the windmill on; far-off thunder now and then;
## - a light, pretty snowfall while you travel from the windmill (J1) to the
##   ghat; at the barn maze, heavy snow from its middle until the feed chest
##   (`heavy_target`, set by BarnMaze), then a clear spell of sun;
## - after the maze the world slowly whitens (`snow_cover`, a global shader
##   value read by SnowMat: the ground, trees, bushes and rocks); it melts on
##   the way down to the coast, where the storm (Storm.gd) takes over;
## - clear sun and no snow from leaving Naresh's home.
## Progress is read from the mood dial's target (it only falls on the way out,
## place by place: Mood.WAY_OUT) and the story's flags.

const LIGHT := 0.16              ## of the flakes, the light snow while travelling
const FLAKES := 4000             ## per player, at full (the maze's heavy snow)
const FLAKE_UP := 9.0            ## m above the player the flakes start
const HEAVY_EASE := 0.1          ## per s: the snow comes on in ~10 s
const COVER_EASE := 0.004        ## per s: the world whitens over minutes
const MAZE_NEAR := 140.0         ## m from the maze: its own sky

var heavy_target := 0.0          ## 0..1, the maze's heavy snow (BarnMaze sets it)
var heavy := 0.0
var clouds := 0.45               ## 0..1 cloud cover now (eased)
var cloud_dark := 0.0
var falling := 0.0               ## 0..1 the light snow now (eased)
var snow_cover := 0.0            ## 0..1 how white the world is
var clear_t := 0.0               ## s left of the clear spell after the maze
var frozen := false              ## tests: hold the values as set

var _flakes := {}                ## player -> [GPUParticles3D, ParticleProcessMaterial]
var _flake_mesh: QuadMesh
var _wind: NoiseLoop
var _thunder: AudioStreamPlayer
var _thunder_t := 30.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	add_to_group("weather")
	_rng.seed = 808
	_flake_mesh = QuadMesh.new()
	_flake_mesh.size = Vector2(0.07, 0.07)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.9)
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_flake_mesh.surface_set_material(0, m)
	_wind = NoiseLoop.new()
	_wind.kind = NoiseLoop.Kind.WIND
	_wind.positional = false
	_wind.volume_db = -4.0
	add_child(_wind)
	_thunder = AudioStreamPlayer.new()
	_thunder.stream = load("res://audio/thunder_far.wav")
	_thunder.volume_db = -16.0
	_thunder.pitch_scale = 0.75
	add_child(_thunder)
	_set_cover(0.0)


func clear_spell(seconds: float) -> void:
	clear_t = seconds


func _flag(f: String) -> bool:
	var st := get_tree().get_first_node_in_group("story") as Story
	return st != null and st.flags.has(f)


func _maze() -> Node3D:
	return get_tree().get_first_node_in_group("barn_maze") as Node3D


## What the weather wants to be now: [clouds, darkness, light snow, cover].
func wanted() -> Array:
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	var stage := mood.target if mood != null else 1.0
	if _flag("naresh_home_done"):
		return [0.0, 0.0, 0.0, 0.0]            # the drive home: clear sun
	if _flag("storm_on"):
		return [0.9, 0.3, 0.0, 0.0]            # the storm has it (Storm.gd)
	var c := 0.45
	var dk := 0.0
	var fall := 0.0
	var cover := 0.0
	if stage <= 0.951:                         # past the windmill
		c = 0.65
		dk = 0.1
		fall = LIGHT
	if _flag("maze_done") or stage <= 0.851:   # after the maze, or at Last Fuel
		c = 0.72
		cover = 0.3
	if stage <= 0.851:
		cover = 0.45
	if stage <= 0.781:                         # the bridge
		c = 0.8
		dk = 0.2
		cover = 0.75
	if stage <= 0.701:                         # over the ghat pass: down to the coast
		c = 0.85
		dk = 0.3
		fall = 0.0
		cover = 0.0
	# the maze's own sky: darker as you come near, before the snow
	var mz := _maze()
	if mz != null and _near(mz.global_position, MAZE_NEAR) and not _flag("maze_done"):
		c = maxf(c, 0.8)
		dk = maxf(dk, 0.25)
		fall = maxf(fall, 0.1)
	if clear_t > 0.0:
		c = 0.15
		dk = 0.0
		fall = 0.0
	return [c, dk, fall, cover]


func _near(p: Vector3, r: float) -> bool:
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(p) < r:
			return true
	return false


func _process(delta: float) -> void:
	clear_t = maxf(0.0, clear_t - delta)
	if not frozen:
		var w := wanted()
		heavy = move_toward(heavy, heavy_target, HEAVY_EASE * delta)
		clouds = move_toward(clouds, maxf(float(w[0]), heavy), 0.02 * delta)
		cloud_dark = move_toward(cloud_dark, maxf(float(w[1]), heavy * 0.6), 0.02 * delta)
		falling = move_toward(falling, float(w[2]), 0.05 * delta)
		snow_cover = move_toward(snow_cover, float(w[3]), COVER_EASE * delta)
	_set_cover(snow_cover)
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.clouds = clouds
		mood.cloud_dark = cloud_dark
		mood.snow = heavy
	_wind.target = clampf(heavy * 0.9 + falling * 0.8, 0.0, 1.0)
	var mz := _maze()
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		var amount := falling
		if mz != null and p.global_position.distance_to(mz.global_position) < MAZE_NEAR:
			amount = maxf(amount, heavy)
		_flakes_for(p, amount)
	# far-off thunder now and then under a heavy sky (not in the storm: it has its own)
	_thunder_t -= delta
	if _thunder_t <= 0.0:
		_thunder_t = _rng.randf_range(45.0, 110.0)
		if clouds > 0.4 and heavy < 0.5 and not _flag("storm_on") and not Sfx.muted:
			_thunder.volume_db = -20.0 + clouds * 6.0
			_thunder.play()


func _set_cover(v: float) -> void:
	RenderingServer.global_shader_parameter_set("snow_cover", v)


## Snow falls round each player: drifting, slow; heavy = thick and close.
func _flakes_for(p: PlayerRig, amount: float) -> void:
	var on := amount > 0.005
	if not _flakes.has(p):
		if not on:
			return
		_flakes[p] = _make_flakes()
	var r: Array = _flakes[p]
	var node := r[0] as GPUParticles3D
	node.emitting = on
	if not on:
		return
	node.amount_ratio = clampf(amount, 0.02, 1.0)
	var vel: Vector3 = p.vehicle.linear_velocity if p.vehicle != null else p.velocity
	node.global_position = p.global_position + Vector3(0, FLAKE_UP, 0) + Vector3(vel.x, 0, vel.z) * 1.2
	var pm := r[1] as ParticleProcessMaterial
	pm.direction = (Vector3.DOWN + Vector3(0.35, 0, 0.2) * (0.3 + heavy)).normalized()
	pm.initial_velocity_min = 1.2 + heavy * 1.5
	pm.initial_velocity_max = 2.0 + heavy * 2.5


func _make_flakes() -> Array:
	var pp := GPUParticles3D.new()
	pp.name = "Snow"
	pp.amount = FLAKES
	pp.lifetime = 4.5
	pp.preprocess = 4.0
	pp.local_coords = false
	pp.top_level = true
	pp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pp.visibility_aabb = AABB(Vector3(-25, -FLAKE_UP - 6, -25), Vector3(50, FLAKE_UP + 10, 50))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(16, 0.5, 16)
	pm.direction = Vector3.DOWN
	pm.spread = 18.0
	pm.initial_velocity_min = 1.2
	pm.initial_velocity_max = 2.0
	pm.gravity = Vector3(0, -0.6, 0)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.turbulence_noise_scale = 3.0
	pm.turbulence_influence_min = 0.05
	pm.turbulence_influence_max = 0.15
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	pp.process_material = pm
	pp.draw_pass_1 = _flake_mesh
	add_child(pp)
	return [pp, pm]
