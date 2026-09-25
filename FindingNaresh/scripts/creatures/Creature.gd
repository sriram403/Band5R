class_name Creature
extends CharacterBody3D

## One of them (design/CREATURES.md). Tall, thin, hard to see straight on, two
## glowing eyes. It never hurts anyone; it takes things away. It sees (no cones
## drawn: you read its eyes and hear its whine) and hears (`Hearing`), and one
## suspicion value from 0 to 1 decides what it does:
##   0-0.3 wander its patrol, 0.3-0.7 curious (walks to what it noticed),
##   0.7-1 searching (faster, around that spot), 1 takes: straight for you.
## It gives up a chase 10 s after losing sight of you.

signal took(player: PlayerRig)

enum State { WANDER, CURIOUS, SEARCH, TAKE }

const FOV_DEG := 110.0
const CLOSE_SENSE := 3.0          ## m; nearer than this it notices you whatever you do
const CATCH := 1.5
const SPEED := {State.WANDER: 1.3, State.CURIOUS: 1.9, State.SEARCH: 3.2, State.TAKE: 7.0}
const RISE_NEAR := 1.0 / 1.5      ## suspicion per second when seen at 10 m
const RISE_EDGE := 1.0 / 4.0      ## ... at the edge of sight
const FALL := 0.07                ## per second when nothing is noticed
const SOUND_STEP := 0.25          ## a sound raises it a step, never past SOUND_CAP
const SOUND_CAP := 0.9            ## sounds alone make it search, only sight makes it take
const GIVE_UP := 10.0             ## s after losing sight of the one it chases
const ATTEND := 2.5               ## s it stops and stares towards anything it noticed
const SIGHT_HZ := 10.0
const HEIGHT := 2.6
const GRAVITY := 22.0

var patrol := PackedVector3Array()   ## wander path (loops); empty = stand
var light := 0                       ## 0 day, 1 dusk, 2 night (sight ranges shrink)
var suspicion := 0.0
var state := State.WANDER
var last_noticed := Vector3.ZERO
var target: PlayerRig = null         ## the player it is after
var seen_now: Array = []             ## players it can see right now (tests read this)
var _pi := 0
var _sight_t := 0.0
var _noticed_t := 99.0               ## s since it last noticed anything
var _lost_t := 0.0                   ## s since it last saw its target
var _heard_id := 0
var _search_t := 0.0
var _eyes: Array[MeshInstance3D] = []
var _eye_mat: StandardMaterial3D
var _glow_mat: StandardMaterial3D
var _hum: NoiseLoop


func _ready() -> void:
	add_to_group("creature")
	collision_layer = 32
	collision_mask = 1 | 8
	set_meta("tag_name", "it")
	_build()
	_heard_id = Hearing.last_id()


func _build() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = HEIGHT
	cs.shape = cap
	cs.position = Vector3(0, HEIGHT * 0.5, 0)
	add_child(cs)
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.16, 0.17, 0.2, 0.82)
	skin.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	skin.roughness = 1.0
	add_child(Build.cyl(0.2, HEIGHT - 0.5, skin, Vector3(0, (HEIGHT - 0.5) * 0.5, 0), Vector3.ZERO, 8, "Body"))
	add_child(Build.box(Vector3(0.9, 0.08, 0.1), skin, Vector3(0, HEIGHT - 0.75, 0), Vector3(0, 0, 8), "Shoulders"))
	for sx in [-0.42, 0.42]:
		add_child(Build.cyl(0.05, 1.5, skin, Vector3(sx, HEIGHT - 1.5, 0), Vector3(0, 0, sx * 6.0), 6, "Arm"))
	add_child(Build.sphere(0.2, skin, Vector3(0, HEIGHT - 0.3, 0), Vector3(0.8, 1.25, 0.8), "Head"))
	_eye_mat = StandardMaterial3D.new()
	_eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_eye_mat.albedo_color = Color(0.85, 0.95, 1.0)
	_eye_mat.emission_enabled = true
	_eye_mat.emission = Color(0.7, 0.9, 1.0)
	# a soft additive halo around each eye: the thing you learn to watch for,
	# visible as two points of light well before the body is
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	tex.gradient = g
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_glow_mat.albedo_texture = tex
	_glow_mat.albedo_color = Color(0.6, 0.85, 1.0)
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	for sx in [-0.07, 0.07]:
		var e := Build.sphere(0.045, _eye_mat, Vector3(sx, HEIGHT - 0.27, -0.16), Vector3.ONE, "Eye")
		e.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(e)
		_eyes.append(e)
		var halo := MeshInstance3D.new()
		halo.name = "Glow"
		halo.mesh = quad
		halo.material_override = _glow_mat
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.position = Vector3(sx, HEIGHT - 0.27, -0.22)
		add_child(halo)
	_hum = NoiseLoop.new()
	_hum.kind = NoiseLoop.Kind.HUM
	_hum.volume_db = -4.0
	_hum.position = Vector3(0, HEIGHT - 0.4, 0)
	add_child(_hum)


func _physics_process(delta: float) -> void:
	_noticed_t += delta
	_sight_t += delta
	if _sight_t >= 1.0 / SIGHT_HZ:
		_look(_sight_t)
		_sight_t = 0.0
	_listen()
	if _noticed_t > 1.0 and state != State.TAKE:
		suspicion = maxf(0.0, suspicion - FALL * delta)
	if state == State.TAKE:
		if target == null or not is_instance_valid(target) or not _can_take(target):
			_give_up()
		elif not seen_now.has(target):
			_lost_t += delta
			if _lost_t > GIVE_UP:
				_give_up()
	_update_state()
	_move(delta)
	_show(delta)


# --- senses --------------------------------------------------------------------

func _look(dt: float) -> void:
	seen_now.clear()
	var eye := global_position + Vector3.UP * (HEIGHT - 0.27)
	var fwd := -global_transform.basis.z
	var space := get_world_3d().direct_space_state
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or not _can_take(p):
			continue
		var to := p.global_position - global_position
		var d := to.length()
		var reach: float = p.sight_range(light)
		if d > maxf(reach, CLOSE_SENSE):
			continue
		if d > CLOSE_SENSE:
			var flat := Vector3(to.x, 0, to.z).normalized()
			if rad_to_deg(fwd.angle_to(flat)) > FOV_DEG * 0.5:
				continue
			if not _line_clear(space, eye, p, p.global_position + Vector3.UP * (p.eye_height + 0.1)) \
					and not _line_clear(space, eye, p, p.global_position + Vector3.UP * (p.eye_height * 0.55)):
				continue
		seen_now.append(p)
		var near := clampf((d - 10.0) / maxf(reach - 10.0, 1.0), 0.0, 1.0)
		suspicion = minf(1.0, suspicion + lerpf(RISE_NEAR, RISE_EDGE, near) * dt)
		_notice(p.global_position)
		if target == null or target == p or d < global_position.distance_to(target.global_position):
			target = p
	if target != null and seen_now.has(target):
		_lost_t = 0.0


func _line_clear(space: PhysicsDirectSpaceState3D, from: Vector3, p: PlayerRig, to: Vector3) -> bool:
	var ex: Array[RID] = [get_rid(), p.get_rid()]
	if p.held != null:
		ex.append(p.held.get_rid())     # your own box does not hide you from yourself
	var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 8 | Carryable.LAYER, ex)
	return space.intersect_ray(q).is_empty()


func _listen() -> void:
	for s in Hearing.since(_heard_id):
		_heard_id = maxi(_heard_id, int(s["id"]))
		var pos: Vector3 = s["pos"]
		if pos.distance_to(global_position) <= float(s["radius"]):
			if suspicion < SOUND_CAP:
				suspicion = minf(SOUND_CAP, suspicion + SOUND_STEP)
			_notice(pos)


func _notice(pos: Vector3) -> void:
	last_noticed = pos
	_noticed_t = 0.0
	_search_t = 0.0


func _can_take(p: PlayerRig) -> bool:
	return p.taken_grace <= 0.0 and p.visible


# --- deciding and moving -------------------------------------------------------

func _update_state() -> void:
	if state == State.TAKE:
		return
	if suspicion >= 1.0 and target != null:
		state = State.TAKE
		_lost_t = 0.0
		Sfx.play3d("whoosh", global_position + Vector3.UP * 2.0, 2.0)
	elif suspicion >= 0.7:
		state = State.SEARCH
	elif suspicion >= 0.3:
		state = State.CURIOUS
	else:
		state = State.WANDER
		target = null


func _give_up() -> void:
	state = State.SEARCH
	suspicion = 0.69
	target = null


func _move(delta: float) -> void:
	var goal := global_position
	match state:
		State.WANDER:
			if _noticed_t < ATTEND:
				goal = global_position       # stop and look (below)
			elif patrol.size() > 0:
				goal = patrol[_pi]
				if _flat_dist(goal) < 1.0:
					_pi = (_pi + 1) % patrol.size()
		State.CURIOUS:
			goal = last_noticed
		State.SEARCH:
			# circle the spot it last noticed something
			_search_t += delta
			var a := _search_t * 0.6
			goal = last_noticed + Vector3(cos(a), 0, sin(a)) * 3.5
		State.TAKE:
			# it only knows where you are while it can see you
			goal = target.global_position if seen_now.has(target) else last_noticed
			if global_position.distance_to(target.global_position) < CATCH:
				var p := target
				state = State.WANDER
				suspicion = 0.2
				target = null
				took.emit(p)
				Taken.take(p, self)
	var to := goal - global_position
	to.y = 0.0
	var v := Vector3.ZERO
	var stop := 0.3 if state != State.CURIOUS else 1.5
	if to.length() > stop:
		v = to.normalized() * float(SPEED[state])
		var want := atan2(-to.x, -to.z)
		rotation.y = lerp_angle(rotation.y, want, 1.0 - exp(-delta * (10.0 if state == State.TAKE else 4.0)))
	elif (state != State.WANDER or _noticed_t < ATTEND) and last_noticed != global_position:
		var look := last_noticed - global_position
		if Vector2(look.x, look.z).length() > 0.2:
			rotation.y = lerp_angle(rotation.y, atan2(-look.x, -look.z), 1.0 - exp(-delta * 4.0))
	velocity.x = v.x
	velocity.z = v.z
	velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	move_and_slide()


func _flat_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


## Eyes brighten and the whine rises with suspicion.
func _show(_delta: float) -> void:
	var glow := lerpf(0.4, 6.0, suspicion)
	_eye_mat.emission_energy_multiplier = glow
	_glow_mat.albedo_color.a = lerpf(0.35, 1.0, suspicion)
	_hum.target = 0.35 + suspicion * 0.65
	_hum.pitch = 1.0 + suspicion * 1.6
