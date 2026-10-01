class_name Storm
extends Node

## F1, the storm (design/RETURN.md): the weather you drive through on the old
## road. Gusts that push the van sideways and can tip it at speed, rain, fog
## that closes in to ~60 m, lightning and thunder. Tuned in the storm gym
## (`--gym=storm`); placed over the ghat in F2.
##
## The gust model, game-readable rather than an aerodynamics sim:
## - A gust rises over GUST_RISE s, holds, then dies away. Its push grows with
##   the square of the rise, so the first second (the windsocks lift, the wind
##   roars) is the warning.
## - Only the part of the wind across the van counts: driving into it or with
##   it, a gust does little.
## - The sideways push grows with speed (a moving van meets more air), and the
##   road is wet (`Camper.set_wet`: less grip), so it slides.
## - The roll grows with speed too, and is zero below SAFE_KMH: a careful
##   driver can never be tipped. Above ~45 km/h the strongest gusts put it over.
## Measured in the gym (t_storm_gym), a full gust across the van with hands
## off the wheel: 25-30 km/h leans 0.5-2 deg; 40-42 km/h leans ~20 deg and
## stays up; 45 km/h tips it. At 50 km/h a 55 / 70 / 85 % gust pushes it
## 0.25 / 1 / 5 m sideways.

const GUST_RISE := 1.8
const GUST_HOLD := 1.0
const GUST_FALL := 1.5
const GAP := Vector2(7.0, 14.0)        ## s between gusts
const STRENGTH := Vector2(0.55, 1.0)   ## of a full gust
const PUSH := 16000.0                  ## N of side force, full gust, at PUSH_REF
const PUSH_REF := 14.0                 ## m/s (50 km/h)
const ROLL := 5200.0                   ## N·m of roll per m/s above SAFE_KMH, full gust
const SAFE_KMH := 25.0
const FLASH := Vector2(5.0, 12.0)      ## s between lightning flashes
const RAIN_DROPS := 3000               ## per player
const RAIN_UP := 12.0                  ## m above the player the drops start

## 0..1, how stormy it is (the gym: 1 everywhere; the world: by place, F2)
var intensity := 1.0
## the world (F2): pos -> 0..1, how stormy it is there. Each player and the
## van get their own (eased in and out): your rain falls where you are, the
## van's road is wet and gusty where the van is. `intensity` is then the
## storm on screen (the fog, the sky, the sound): the strongest round a
## player whose view is showing. (It was the strongest round anyone: P2 left
## at J3 kept it raining on P1 up the coast road, gusts and all.)
var zone_fn: Callable
const ZONE_EASE := 0.25                ## per second
var _here := {}                        ## node -> its eased storm
## the way the wind blows (towards), flat
var wind_dir := Vector3(0, 0, -1)
var auto_gusts := true                 ## tests switch the schedule off and call gust_now()
var auto_flashes := true
## the gust now: 0..1 envelope times its strength (windsocks, sound, tests)
var gust := 0.0
var gusts := 0                         ## how many have blown (tests)
var flashes := 0
var flash := 0.0                       ## 0..1 the lightning now (Mood draws it)
var _g_t := -1.0                       ## s into the current gust, -1 = none
var _g_strength := 1.0
var _g_dir := Vector3(0, 0, -1)
var _next := 4.0
var _flash_t := 3.0
var _thunder_in := -1.0
var _rng := RandomNumberGenerator.new()
var _rain := {}                        ## player -> [Node3D, ParticleProcessMaterial]
var _rain_mesh: Mesh
var _rain_mat: StandardMaterial3D
var _wind: NoiseLoop
var _hiss: NoiseLoop
var _thunder: AudioStreamPlayer
var _bolt: DirectionalLight3D
var _shielded := {}                    ## campers given a rain shield
var _tipping := {}                     ## campers thrown over by a gust
## The van's centre of mass is set low for the driving feel (it sits below the
## floor), so a van on its side would roll back up like a toy. Thrown past
## TIP_DEG by a gust, it gets a real van's (the middle of the body) and stays
## down; R rights it and the driving one comes back.
const TIP_DEG := 70.0
const TIP_COM := Vector3(0, 0.55, 0)
const DRIVE_COM := Vector3(0, -0.30, 0)


func _ready() -> void:
	add_to_group("storm")
	_rng.seed = 4141
	_wind = NoiseLoop.new()
	_wind.kind = NoiseLoop.Kind.WIND
	_wind.positional = false
	_wind.volume_db = -3.0
	add_child(_wind)
	_hiss = NoiseLoop.new()
	_hiss.kind = NoiseLoop.Kind.RAIN
	_hiss.positional = false
	_hiss.volume_db = -9.0
	add_child(_hiss)
	_thunder = AudioStreamPlayer.new()
	_thunder.stream = load("res://audio/thunder_far.wav")
	add_child(_thunder)
	_bolt = DirectionalLight3D.new()
	_bolt.name = "Lightning"
	_bolt.light_color = Mood.FLASH_COL
	_bolt.light_energy = 0.0
	_bolt.shadow_enabled = false
	_bolt.rotation = Vector3(deg_to_rad(-55), deg_to_rad(30), 0)
	add_child(_bolt)
	_rain_mesh = BoxMesh.new()
	(_rain_mesh as BoxMesh).size = Vector3(0.012, 0.55, 0.012)
	_rain_mat = StandardMaterial3D.new()
	_rain_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_rain_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_rain_mat.albedo_color = Color(0.72, 0.76, 0.84, 0.32)
	_rain_mesh.surface_set_material(0, _rain_mat)


## Start a gust now (tests, the developer menu). `dir` flat, where it blows.
func gust_now(strength := 1.0, dir := Vector3.ZERO) -> void:
	_g_t = 0.0
	_g_strength = strength
	_g_dir = (dir if dir != Vector3.ZERO else wind_dir).normalized()
	gusts += 1


## How stormy it is round this player or van.
func local(n: Node) -> float:
	return float(_here.get(n, 0.0)) if zone_fn.is_valid() else intensity


func _physics_process(delta: float) -> void:
	var most := intensity
	if zone_fn.is_valid():
		var boot := get_tree().current_scene
		var views = boot.get("views") if boot != null else null
		var shown := 0.0
		most = 0.0
		for n in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("camper"):
			var v := move_toward(float(_here.get(n, 0.0)), float(zone_fn.call((n as Node3D).global_position)), ZONE_EASE * delta)
			_here[n] = v
			most = maxf(most, v)
			if n is PlayerRig:
				var i: int = (n as PlayerRig).index
				if views == null or i >= views.size() or (views[i] as Control).visible:
					shown = maxf(shown, v)
		intensity = shown
	for c in get_tree().get_nodes_in_group("camper"):
		(c as Camper).set_wet(local(c))
	if most <= 0.01:
		gust = 0.0
		_g_t = -1.0
		return
	if auto_gusts and _g_t < 0.0:
		_next -= delta
		if _next <= 0.0:
			_next = _rng.randf_range(GAP.x, GAP.y)
			# mostly from one side, swinging a little
			var d := wind_dir.rotated(Vector3.UP, _rng.randf_range(-0.35, 0.35))
			gust_now(_rng.randf_range(STRENGTH.x, STRENGTH.y), d)
	if _g_t >= 0.0:
		_g_t += delta
		gust = envelope(_g_t) * _g_strength
		if _g_t > GUST_RISE + GUST_HOLD + GUST_FALL:
			_g_t = -1.0
			gust = 0.0
	else:
		gust = 0.0
	for n in get_tree().get_nodes_in_group("camper"):
		var c := n as Camper
		if gust > 0.0:
			_blow(c)
		_tip_check(c)


func _tip_check(c: Camper) -> void:
	var up := c.global_transform.basis.y.y
	if not _tipping.has(c):
		if gust > 0.0 and up < cos(deg_to_rad(TIP_DEG)):
			_tipping[c] = true
			c.center_of_mass = TIP_COM
	elif up > 0.9:
		_tipping.erase(c)
		c.center_of_mass = DRIVE_COM


static func envelope(t: float) -> float:
	if t < GUST_RISE:
		return smoothstep(0.0, GUST_RISE, t)
	if t < GUST_RISE + GUST_HOLD:
		return 1.0
	return 1.0 - smoothstep(0.0, GUST_FALL, t - GUST_RISE - GUST_HOLD)


func _blow(c: Camper) -> void:
	if c == null or c.freeze:
		return
	var b := c.global_transform.basis
	var right := Vector3(b.x.x, 0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0, -b.z.z).normalized()
	var across := _g_dir.dot(right)          # signed: + pushes it to its right
	var v := absf(c.linear_velocity.dot(fwd))
	var bite := gust * gust * local(c)       # the rise is the warning; none out of the storm
	var push := PUSH * bite * across * (0.35 + 0.65 * v / PUSH_REF)
	c.apply_central_force(right * push)
	var over := maxf(0.0, v - SAFE_KMH / 3.6)
	if over > 0.0:
		# a torque about the forward axis rolls the top towards +right
		c.apply_torque(fwd * ROLL * bite * across * over)


# --- what you see and hear --------------------------------------------------------

func _process(delta: float) -> void:
	var on := intensity > 0.01
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.storm = intensity
		mood.flash = flash
	_wind.target = (0.25 * intensity + 0.75 * gust) if on else 0.0
	_hiss.target = 0.8 * intensity if on else 0.0
	_bolt.light_energy = flash * 2.4
	for c in get_tree().get_nodes_in_group("camper"):
		_shield(c as Camper)
	for p in get_tree().get_nodes_in_group("player"):
		_rain_for(p as PlayerRig, local(p) > 0.01)
	_windsocks(delta)
	if not on:
		return
	if auto_flashes:
		_flash_t -= delta
		if _flash_t <= 0.0:
			_flash_t = _rng.randf_range(FLASH.x, FLASH.y)
			lightning()
	if _thunder_in >= 0.0:
		_thunder_in -= delta
		if _thunder_in < 0.0 and not Sfx.muted:
			_thunder.play()


## A flash: two quick pulses, the land lit pale blue, thunder a moment after.
func lightning() -> void:
	flashes += 1
	var tw := create_tween()
	tw.tween_property(self, "flash", 1.0, 0.04)
	tw.tween_property(self, "flash", 0.15, 0.10)
	tw.tween_property(self, "flash", 0.8, 0.05)
	tw.tween_property(self, "flash", 0.0, 0.35)
	_thunder_in = _rng.randf_range(0.6, 3.0)


## Rain falls round each player (drops stay where they fell as you move).
func _rain_for(p: PlayerRig, on: bool) -> void:
	if not _rain.has(p):
		if not on:
			return
		_rain[p] = _make_rain()
	var r: Array = _rain[p]
	var node := r[0] as GPUParticles3D
	node.emitting = on
	if not on:
		return
	node.amount_ratio = clampf(local(p), 0.05, 1.0)
	# lead the drops a little by how fast you go, so a van never outruns them
	var vel: Vector3 = p.vehicle.linear_velocity if p.vehicle != null else p.velocity
	node.global_position = p.global_position + Vector3(0, RAIN_UP, 0) + Vector3(vel.x, 0, vel.z) * 0.8
	var pm := r[1] as ParticleProcessMaterial
	pm.direction = (Vector3.DOWN + wind_dir * (0.15 + 0.4 * gust)).normalized()


func _make_rain() -> Array:
	var pp := GPUParticles3D.new()
	pp.name = "Rain"
	pp.amount = RAIN_DROPS
	pp.lifetime = 1.1
	pp.preprocess = 1.0
	pp.local_coords = false
	pp.top_level = true
	pp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pp.visibility_aabb = AABB(Vector3(-30, -RAIN_UP - 10, -30), Vector3(60, RAIN_UP + 14, 60))
	pp.collision_base_size = 0.02
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(20, 0.5, 20)
	pm.direction = Vector3.DOWN
	pm.spread = 2.0
	pm.initial_velocity_min = 15.0
	pm.initial_velocity_max = 18.0
	pm.gravity = Vector3.ZERO
	pm.particle_flag_align_y = true
	pm.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	pp.process_material = pm
	pp.draw_pass_1 = _rain_mesh
	add_child(pp)
	return [pp, pm]


## The van's body keeps the rain out of the cab (drops that touch it go).
func _shield(c: Camper) -> void:
	if c == null or _shielded.has(c):
		return
	var box := GPUParticlesCollisionBox3D.new()
	box.name = "RainShield"
	box.size = Vector3(2.4, 2.2, 6.0)
	box.position = Vector3(0, Camper.BODY_Y + 1.70, 0)
	c.add_child(box)
	_shielded[c] = box


# --- windsocks ------------------------------------------------------------------------

## A windsock on a pole: it hangs in the calm, streams out and swings with a
## gust, so you see one coming. `Storm` moves every one in the group.
static func make_windsock(at: Vector3) -> Node3D:
	var root := Node3D.new()
	root.name = "Windsock"
	root.add_to_group("windsock")
	root.position = at
	var pole := ToonMat.make(Color(0.6, 0.62, 0.64))
	root.add_child(Build.cyl(0.06, 4.0, pole, Vector3(0, 2.0, 0), Vector3.ZERO, 8, "Pole"))
	var turn := Node3D.new()
	turn.name = "Turn"
	turn.position = Vector3(0, 3.9, 0)
	root.add_child(turn)
	var swing := Node3D.new()
	swing.name = "Swing"
	turn.add_child(swing)
	var orange := ToonMat.make(Color(0.95, 0.45, 0.12))
	var white := ToonMat.make(Color(0.95, 0.94, 0.9))
	for k in 4:
		var m := CylinderMesh.new()
		m.top_radius = 0.26 - k * 0.04
		m.bottom_radius = 0.22 - k * 0.04
		m.height = 0.42
		m.radial_segments = 10
		var seg := Build.node(m, orange if k % 2 == 0 else white,
			Transform3D(Basis.from_euler(Vector3(deg_to_rad(90), 0, 0)), Vector3(0, 0, -0.25 - k * 0.42)), "Sock")
		seg.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		swing.add_child(seg)
	return root


func _windsocks(_delta: float) -> void:
	var socks := get_tree().get_nodes_in_group("windsock")
	if socks.is_empty():
		return
	var t := Time.get_ticks_msec() / 1000.0
	var lift := clampf(0.2 * intensity + 0.85 * gust, 0.0, 1.0)
	var dir := _g_dir if gust > 0.05 else wind_dir
	for s in socks:
		var n := s as Node3D
		var turn := n.get_node("Turn") as Node3D
		var swing := turn.get_node("Swing") as Node3D
		var flutter := sin(t * (6.0 + 8.0 * lift) + n.position.x * 0.3) * (0.04 + 0.08 * lift)
		turn.global_basis = Basis.looking_at(dir, Vector3.UP).rotated(Vector3.UP, flutter)
		# the sock is built along -Z: a positive tilt about X raises its tip
		swing.rotation.x = deg_to_rad(lerpf(-80.0, -4.0, lift))
