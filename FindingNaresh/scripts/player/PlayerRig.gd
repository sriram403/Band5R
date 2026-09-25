class_name PlayerRig
extends CharacterBody3D

## First-person player. One instance per local player.
##
## The camera does NOT live under this node: each player renders into its own
## SubViewport, so the split-screen shell owns the Camera3D and this script
## drives its transform every frame from the head marker.

signal prompt_changed(text: String)
signal message(text: String, seconds: float)   ## a note, board or story line to read

const WALK := 4.3
const SPRINT := 7.6
const CROUCH := 2.1
const ACCEL_GROUND := 12.0
## Enough air control that a standing jump carries you onto a crate you are
## pressed against; with 2.5 you had to back off and take a run-up every time.
const ACCEL_AIR := 7.0
const JUMP_VELOCITY := 4.7
const GRAVITY := 22.0
const STAND_HEIGHT := 1.72
const CROUCH_HEIGHT := 1.05
const INTERACT_RANGE := 3.2
const SEAT_YAW_LIMIT := deg_to_rad(125.0)
const PITCH_LIMIT := deg_to_rad(85.0)
const SEATED_EYE := 0.62
const SEATED_PITCH := deg_to_rad(-5.0)   ## settle slightly down the road, not at the roof
const EXIT_MAX_SPEED := 2.5              ## m/s; the doors stay shut above a crawl
const BINOCULAR_ZOOM := 4.0              ## magnification while zoom is held

var index := 0
var dev: InputDevice
var body_color := Color(0.90, 0.62, 0.24)

var head: Node3D
var flashlight: SpotLight3D
var flashlight_seconds := 600.0       ## one set lasts about ten minutes of use
var beam: MeshInstance3D
var ray: RayCast3D
var _capsule: CapsuleShape3D
var _mesh_root: Node3D

var cam: Camera3D                      ## injected by the split-screen shell
var yaw := 0.0
var pitch := 0.0
var eye_height := STAND_HEIGHT
var crouching := false
var bob_t := 0.0
var bob_offset := Vector3.ZERO
var cam_roll := 0.0

var seat: Node3D = null                ## non-null while seated in the camper
var vehicle = null                     ## Camper reference while seated
var seat_role := ""                    ## "driver" | "passenger"
var _seat_yaw := 0.0

var current_target: Node = null
var prompt_text := ""
var held: Carryable = null             ## item in this player's hands
var paper_map: PaperMap = null         ## injected by this player's HUD
var map_open := false
var _plan_vel := Vector2.ZERO          ## intended horizontal velocity (see _walk)
var journal_open := false              ## reading the van's travel journal
var phone_open := false                ## read-only opening texts
var journal_sel := 0
var journal_confirm := false
var journal_note := ""
var _step_phase := 0.0
var _was_on_floor := true
var _using: Node = null                ## thing being used with the held item while E is held
var force_exit := false            ## request an exit from outside the physics step
var knocked_t := 0.0                   ## > 0 while tumbling after being hit by the van
var _tumble_spin := 0.0
var _knock_van: PhysicsBody3D = null   ## no collision with it until we are clear of it
var _pose_stand := {}                  ## avatar part name -> standing transform
var has_binoculars := false
var zoom := 1.0                        ## current magnification (eases to BINOCULAR_ZOOM)
var base_fov := 78.0                   ## the layout's field of view, set by Boot
var taken_grace := 0.0                 ## s left in which no creature can take you
var taken_hold := 0.0                  ## s left frozen while being taken (Taken.gd)
var whiteout := 0.0                    ## 0..1 white over this player's view
var in_box := false                    ## hiding under the cardboard box
var box: CardboardBox = null           ## the box you are in
var peeking := false                   ## leaning out from cover
var peek_offset := Vector3.ZERO        ## head offset while peeking (body space)
var _peek_side := Vector3.ZERO         ## the way you last leaned (kept while it works)
var _box_slot: Node3D


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 8 | Carryable.LAYER   # world, vehicle body, loose items
	floor_max_angle = deg_to_rad(52)
	floor_snap_length = 0.5
	_build()


func _build() -> void:
	_capsule = CapsuleShape3D.new()
	_capsule.radius = 0.34
	_capsule.height = STAND_HEIGHT
	var cs := CollisionShape3D.new()
	cs.name = "Collider"
	cs.shape = _capsule
	cs.position = Vector3(0, STAND_HEIGHT * 0.5, 0)
	add_child(cs)

	head = Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, STAND_HEIGHT - 0.16, 0)
	add_child(head)

	_box_slot = Node3D.new()
	_box_slot.name = "BoxSlot"
	add_child(_box_slot)

	flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.light_color = Color(1.0, 0.95, 0.82)
	flashlight.light_energy = 5.5
	flashlight.spot_range = 34.0
	flashlight.spot_angle = 33.0
	flashlight.spot_angle_attenuation = 0.7
	flashlight.spot_attenuation = 1.1
	flashlight.shadow_enabled = true
	flashlight.position = Vector3(0.22, -0.12, 0.0)
	flashlight.visible = false
	head.add_child(flashlight)

	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 3.4
	cone.height = 11.0
	cone.radial_segments = 14
	beam = Build.node(cone, ToonMat.glow(Color(1.0, 0.96, 0.80), 0.045),
		Transform3D(Basis.from_euler(Vector3(deg_to_rad(90), 0, 0)), Vector3(0, 0, -5.5)), "Beam")
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	beam.visible = false
	flashlight.add_child(beam)

	ray = RayCast3D.new()
	ray.name = "InteractRay"
	ray.target_position = Vector3(0, 0, -INTERACT_RANGE)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = 1 | 4 | 8 | Carryable.LAYER
	head.add_child(ray)

	# A small visible avatar so the other player can see you in their view.
	_mesh_root = Node3D.new()
	_mesh_root.name = "Avatar"
	add_child(_mesh_root)
	var suit := ToonMat.make(body_color, 0.018)
	var skin := ToonMat.make(Color(0.88, 0.70, 0.55), 0.018)
	_mesh_root.add_child(Build.cyl(0.28, 1.05, suit, Vector3(0, 0.62, 0), Vector3.ZERO, 10, "Torso"))
	_mesh_root.add_child(Build.sphere(0.22, skin, Vector3(0, 1.36, 0), Vector3.ONE, "Head"))
	_mesh_root.add_child(Build.box(Vector3(0.16, 0.7, 0.16), suit, Vector3(-0.34, 0.75, 0), Vector3.ZERO, "ArmL"))
	_mesh_root.add_child(Build.box(Vector3(0.16, 0.7, 0.16), suit, Vector3(0.34, 0.75, 0), Vector3.ZERO, "ArmR"))
	_mesh_root.add_child(Build.box(Vector3(0.18, 0.62, 0.18), ToonMat.make(Color(0.24, 0.28, 0.36), 0.018), Vector3(-0.13, 0.16, 0), Vector3.ZERO, "LegL"))
	_mesh_root.add_child(Build.box(Vector3(0.18, 0.62, 0.18), ToonMat.make(Color(0.24, 0.28, 0.36), 0.018), Vector3(0.13, 0.16, 0), Vector3.ZERO, "LegR"))
	for m in _mesh_root.get_children():
		_pose_stand[m.name] = (m as Node3D).transform


## Seated, the standing avatar poked through the roof: fold it into the seat,
## hips on the cushion (0.14 below the seat marker), head at the eye point.
const SEATED_POSE := {
	"Torso": [Vector3(0, 0.19, 0.02), Vector3(0, 0, 0), Vector3(0.80, 0.56, 0.80)],
	"Head": [Vector3(0, 0.60, 0.02), Vector3(0, 0, 0), Vector3(0.72, 0.72, 0.72)],
	"ArmL": [Vector3(-0.25, 0.28, -0.18), Vector3(-65, 0, 0), Vector3(0.8, 0.75, 0.8)],
	"ArmR": [Vector3(0.25, 0.28, -0.18), Vector3(-65, 0, 0), Vector3(0.8, 0.75, 0.8)],
	"LegL": [Vector3(-0.12, -0.10, -0.28), Vector3(90, 0, 0), Vector3(0.85, 0.85, 0.85)],
	"LegR": [Vector3(0.12, -0.10, -0.28), Vector3(90, 0, 0), Vector3(0.85, 0.85, 0.85)],
}


func _set_seated_pose(on: bool) -> void:
	for m in _mesh_root.get_children():
		var n := m as Node3D
		if on and SEATED_POSE.has(n.name):
			var p: Array = SEATED_POSE[n.name]
			var e: Vector3 = p[1]
			n.transform = Transform3D(Basis.from_euler(e * (PI / 180.0)).scaled(p[2]), p[0])
		elif _pose_stand.has(n.name):
			n.transform = _pose_stand[n.name]


func set_view_camera(c: Camera3D) -> void:
	cam = c


## Visual layer 1 is the shared world. Each player's own avatar and light cone
## live on a private layer that their own camera masks out, so you see your
## partner's body but never the inside of your own head.
func set_player_index(i: int) -> void:
	index = i
	var layer := 1 << (1 + i)
	for m in _mesh_root.get_children():
		(m as VisualInstance3D).layers = layer
	beam.layers = layer


static func cull_mask_for(i: int) -> int:
	return 0xFFFFF & ~(1 << (1 + i))


func recolor(c: Color) -> void:
	body_color = c
	if _mesh_root:
		var suit := ToonMat.make(c, 0.018)
		for child in _mesh_root.get_children():
			if child.name in ["Torso", "ArmL", "ArmR"]:
				(child as MeshInstance3D).material_override = suit


# --- frame ---------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if dev == null:
		return
	if dev.just_pressed("phone"):
		phone_open = not phone_open
		if phone_open:
			var st := get_tree().get_first_node_in_group("story") as Story
			if st != null:
				st.mark_phone_read(index)
	if flashlight.visible:
		flashlight_seconds = maxf(0.0, flashlight_seconds - delta)
		if flashlight_seconds <= 0.0:
			flashlight.visible = false
			beam.visible = false
		elif flashlight_seconds < 60.0:
			# Short, increasingly frequent brownouts before the cells die.
			var flicker := sin(Time.get_ticks_msec() * 0.027) > 0.94 - (60.0 - flashlight_seconds) * 0.004
			flashlight.light_energy = 1.5 if flicker else 5.5
		else:
			flashlight.light_energy = 5.5
	taken_grace = maxf(0.0, taken_grace - delta)
	if force_exit:
		force_exit = false
		exit_vehicle()
	if knocked_t > 0.0:
		_knocked(delta)
		return
	if taken_hold > 0.0:
		taken_hold -= delta
		velocity = Vector3.ZERO
		_plan_vel = Vector2.ZERO
		return
	if _knock_van != null and is_instance_valid(_knock_van) and _knock_van.global_position.distance_to(global_position) > 5.0:
		remove_collision_exception_with(_knock_van)
		_knock_van = null
	# Look itself is applied per rendered frame in _process; the physics step
	# only copies the result onto the body, the head and the interaction ray.
	rotation.y = yaw
	head.rotation = Vector3(pitch, _seat_yaw if seat != null else 0.0, 0)
	if journal_open:
		_journal_controls()
		if seat != null:
			_seated(delta)
		return
	_update_map()
	if seat != null:
		_seated(delta)
	else:
		_walk(delta)
	if map_open:
		_map_controls()
	else:
		_scan()
		if dev.just_pressed("tag") and can_tag():
			tag_look()
	if seat != null and not map_open and dev.just_pressed("journal") and _van_parked():
		_open_journal()


## Look and camera run every rendered frame, not every physics tick, so the
## view stays smooth on high-refresh monitors. Positions come from the
## interpolated transforms, so movement and driving are smooth too.
func _process(delta: float) -> void:
	if dev != null and not get_tree().paused:
		var want := BINOCULAR_ZOOM if can_zoom() and dev.held("zoom") else 1.0
		zoom = lerpf(zoom, want, 1.0 - exp(-delta * 14.0))
		if absf(zoom - want) < 0.01:
			zoom = want
		if map_open and paper_map != null:
			paper_map.move_cursor(dev.cursor_delta(delta))
		elif taken_hold <= 0.0:
			_look(delta)
	if cam == null:
		return
	cam.fov = rad_to_deg(2.0 * atan(tan(deg_to_rad(base_fov) * 0.5) / zoom))
	var xf: Transform3D
	if seat != null:
		var sx := seat.get_global_transform_interpolated()
		xf = sx * Transform3D(Basis.from_euler(Vector3(pitch, _seat_yaw, 0)), Vector3(0, SEATED_EYE, 0))
	else:
		var origin := get_global_transform_interpolated().origin + Basis(Vector3.UP, yaw) * (Vector3(0, eye_height, 0) + peek_offset) + bob_offset
		xf = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0)), origin)
	var b := xf.basis.rotated(xf.basis.z.normalized(), cam_roll)
	cam.global_transform = Transform3D(b, xf.origin)


func _look(delta: float) -> void:
	var d := dev.look(delta) / zoom      # the view moves as far on screen, zoomed or not
	if seat != null:
		_seat_yaw = clampf(_seat_yaw - d.x, -SEAT_YAW_LIMIT, SEAT_YAW_LIMIT)
	else:
		yaw = wrapf(yaw - d.x, -PI, PI)
	pitch = clampf(pitch - d.y, -PITCH_LIMIT, PITCH_LIMIT)


func _walk(delta: float) -> void:
	var want_crouch := dev.held("crouch") or in_box
	if want_crouch != crouching:
		crouching = want_crouch
		_capsule.height = CROUCH_HEIGHT if crouching else STAND_HEIGHT
		var cs := get_node("Collider") as CollisionShape3D
		cs.position.y = _capsule.height * 0.5

	var target_eye: float = (CROUCH_HEIGHT if crouching else STAND_HEIGHT) - 0.16
	eye_height = lerp(eye_height, target_eye, 1.0 - pow(0.001, delta))
	_update_peek(delta)
	head.position = Vector3(peek_offset.x, eye_height + peek_offset.y, 0.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif dev.just_pressed("jump") and not map_open and not in_box:
		velocity.y = JUMP_VELOCITY

	var mv := dev.move()
	if map_open:
		mv *= 0.4        # shuffle along while reading
	var dir := (transform.basis.x * mv.x + -transform.basis.z * mv.y)
	dir.y = 0.0
	if dir.length() > 1.0:
		dir = dir.normalized()

	var speed := WALK
	var heavy_load := held != null and held.heaviness() > 0.4
	if crouching:
		speed = CROUCH
	elif dev.held("sprint") and mv.y > 0.1 and not heavy_load:
		speed = SPRINT
	if held != null:
		speed *= held.speed_factor()

	var accel := ACCEL_GROUND if is_on_floor() else ACCEL_AIR
	var target := dir * speed
	# Accelerate the *intended* horizontal velocity, not what is left after the
	# last collision: pressing into a crate side zeroed velocity every tick, so
	# a jump from against it never had the momentum to carry you on top.
	_plan_vel = _plan_vel.move_toward(Vector2(target.x, target.z), accel * delta * 6.0)
	velocity.x = _plan_vel.x
	velocity.z = _plan_vel.y
	move_and_slide()
	# Walking into loose items nudges them along instead of stopping dead.
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var rb := hit.get_collider() as RigidBody3D
		if rb != null and not rb.freeze and rb != held and not rb is VehicleBody3D:
			var push := -hit.get_normal()
			push.y = 0.0
			rb.apply_central_impulse(push.normalized() * 55.0 * delta)

	# footsteps and landings, by surface
	var planar := Vector2(velocity.x, velocity.z).length()
	if is_on_floor():
		if not _was_on_floor:
			Sfx.play3d(_surface_step(), global_position, -2.0)
			Hearing.emit(global_position, Hearing.LANDING, "landing")
		elif planar > 0.8:
			_step_phase += delta * planar * 0.55
			if _step_phase >= 1.0:
				_step_phase -= 1.0
				Sfx.play3d(_surface_step(), global_position, -10.0 + minf(planar, 7.0))
				var loud := Hearing.WALK_STEP
				if crouching:
					loud = Hearing.CROUCH_STEP
				elif planar > WALK + 0.5:
					loud = Hearing.SPRINT_STEP
				Hearing.emit(global_position, loud, "step")
	_was_on_floor = is_on_floor()

	# head bob keyed to actual ground speed
	if is_on_floor() and planar > 0.4:
		bob_t += delta * planar * 1.55
		var amp: float = 0.032 * clampf(planar / SPRINT, 0.3, 1.0)
		bob_offset = Vector3(cos(bob_t) * amp * 0.7, absf(sin(bob_t)) * amp, 0.0)
		cam_roll = lerp(cam_roll, cos(bob_t) * 0.008, 0.2)
	else:
		bob_offset = bob_offset.lerp(Vector3.ZERO, 0.12)
		cam_roll = lerp(cam_roll, 0.0, 0.12)

	if dev.just_pressed("flashlight"):
		toggle_flashlight()


func _seated(_delta: float) -> void:
	_follow_seat()
	velocity = Vector3.ZERO
	bob_offset = bob_offset.lerp(Vector3.ZERO, 0.2)
	if dev.just_pressed("flashlight"):
		toggle_flashlight()


## Hit by the van: thrown along `impulse`, tumbling, then back on your feet
## after a moment that grows with the hit.
func knock(impulse: Vector3, van: PhysicsBody3D = null) -> void:
	if seat != null or knocked_t > 0.0:
		return
	leave_box(false)
	drop_held()
	set_map_open(false)
	journal_open = false
	if van != null:
		_knock_van = van
		add_collision_exception_with(van)
	velocity = impulse
	_plan_vel = Vector2.ZERO
	var hit := impulse.length()
	knocked_t = clampf(0.9 + hit * 0.12, 1.2, 4.0)
	_tumble_spin = (1.0 if randf() < 0.5 else -1.0) * clampf(hit * 0.8, 3.0, 14.0)
	Sfx.play3d("hit_soft", global_position + Vector3.UP, 4.0)
	Sfx.play3d("hit_metal_heavy", global_position + Vector3.UP, -2.0)
	_dust_puff(global_position + Vector3.UP * 0.6, hit)


func _knocked(delta: float) -> void:
	knocked_t -= delta
	velocity.y -= GRAVITY * delta
	if is_on_floor():
		# sliding along the ground, the spin dies away
		var h := Vector2(velocity.x, velocity.z).move_toward(Vector2.ZERO, 16.0 * delta)
		velocity.x = h.x
		velocity.z = h.y
		_tumble_spin = move_toward(_tumble_spin, 0.0, 24.0 * delta)
		eye_height = lerpf(eye_height, 0.35, 1.0 - pow(0.01, delta))
	move_and_slide()
	cam_roll += _tumble_spin * delta
	_mesh_root.rotation = Vector3(-PI * 0.5, 0.0, cam_roll)
	head.position.y = eye_height
	if knocked_t <= 0.0:
		if is_on_floor():
			# get up: the roll unwinds to level in _walk
			knocked_t = 0.0
			cam_roll = wrapf(cam_roll, -PI, PI)
			_mesh_root.rotation = Vector3.ZERO
			velocity = Vector3.ZERO
		else:
			knocked_t = 0.05     # wait until we land


static func _dust_puff(at: Vector3, strength: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var root := tree.get_first_node_in_group("world_root") if tree else null
	if root == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = int(clampf(10.0 + strength * 1.5, 12.0, 40.0))
	p.lifetime = 1.1
	p.explosiveness = 0.9
	p.direction = Vector3.UP
	p.spread = 70.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 2.0 + strength * 0.15
	p.gravity = Vector3(0, -1.5, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var sm := SphereMesh.new()
	sm.radius = 0.18
	sm.height = 0.36
	sm.radial_segments = 8
	sm.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.64, 0.52, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.material = mat
	p.mesh = sm
	root.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)


func toggle_flashlight() -> void:
	if held is BatteryPack:
		var pack := held
		held = null
		_using = null
		ray.remove_exception(pack)
		pack.queue_free()
		flashlight_seconds = 600.0
		flashlight.visible = true
		beam.visible = true
		message.emit("Fresh batteries. The torch is working.", 3.0)
		return
	if flashlight_seconds <= 0.0:
		message.emit("Your torch is dead. It needs new batteries.", 2.5)
		return
	flashlight.visible = not flashlight.visible
	beam.visible = flashlight.visible


# --- interaction ---------------------------------------------------------------

func _scan() -> void:
	if in_box:
		_scan_box()
		return
	if held != null:
		_scan_holding()
		return
	var target: Node = null
	var text := ""
	if ray.is_colliding():
		var col := ray.get_collider()
		var node := _find_interactable(col)
		if node != null:
			# An optional "blocked_fn" explains why something cannot be used
			# right now, instead of offering a button that does nothing.
			var blocked := ""
			if node.has_meta("blocked_fn"):
				var bf: Callable = node.get_meta("blocked_fn")
				# blocked_fn may take the player (for reach checks) or nothing
				blocked = bf.call(self) if bf.get_argument_count() > 0 else bf.call()
			if blocked != "":
				text = blocked
			else:
				var label: String = (node.get_meta("prompt_fn") as Callable).call(self) if node.has_meta("prompt_fn") else node.get_meta("prompt", "Use")
				if label != "":
					target = node
					text = "[%s]  %s" % [dev.glyph("interact"), label]
	if text == "" and _near_upset_van() != null:
		text = "[%s]  Right the van" % dev.glyph("recover")
	if seat != null and text == "":
		text = _seated_prompt()

	if text != prompt_text:
		prompt_text = text
		prompt_changed.emit(text)
	current_target = target

	if dev.just_pressed("recover"):
		var van = _near_upset_van()
		if van != null:
			van.recover()

	if dev.just_pressed("interact"):
		if target != null:
			var cb: Callable = target.get_meta("callback", Callable())
			if cb.is_valid():
				cb.call(self)
		elif seat != null and _can_exit():
			exit_vehicle()
	# things you hold E on (pump handles, cranks) get called every tick
	if target != null and target.has_meta("hold_fn") and dev.held("interact"):
		(target.get_meta("hold_fn") as Callable).call(self, get_physics_process_delta_time())


# --- hiding --------------------------------------------------------------------

## Under the box you are crouched, can't jump, can't use or pick anything up.
func enter_box() -> void:
	var b := held as CardboardBox
	if b == null or seat != null:
		return
	drop_held()
	box = b
	in_box = true
	b.wear(self, _box_slot)
	Sfx.play3d("drop", global_position + Vector3.UP * 0.5, -12.0)


## Out of the box: lifted off and held again (`hold`), or left where you are
## (being taken, knocked down).
func leave_box(hold := true) -> void:
	if box == null:
		in_box = false
		return
	var b := box
	box = null
	in_box = false
	b.take_off()
	if hold:
		pick_up(b)


func _scan_box() -> void:
	var text := "[%s]  Lift the box off" % dev.glyph("interact")
	if text != prompt_text:
		prompt_text = text
		prompt_changed.emit(text)
	current_target = null
	if dev.just_pressed("interact"):
		leave_box(true)


## Peeking (CREATURES.md): crouched right behind cover, hold RMB / LT and your
## head comes up over it or out past its side, wherever the view is clear.
## While you peek a creature sees you as if you stood (your head is out).
const PEEK_UP := 0.72        ## crouched eye up to standing eye
const PEEK_SIDE := 0.6
const PEEK_COVER := 1.3      ## m; cover must be this close in front of you

func _update_peek(delta: float) -> void:
	var want := Vector3.ZERO
	peeking = false
	if crouching and not in_box and held == null and not map_open and knocked_t <= 0.0 and dev.held("zoom"):
		want = _peek_offset()
		peeking = want != Vector3.ZERO
	_peek_side = want
	peek_offset = peek_offset.lerp(want, 1.0 - exp(-delta * 10.0))
	if peek_offset.length() < 0.005:
		peek_offset = Vector3.ZERO


## Where the head goes to see past the cover in front, or zero if there is no
## cover right in front or no clear way past it.
func _peek_offset() -> Vector3:
	var space := get_world_3d().direct_space_state
	var b := Basis(Vector3.UP, yaw)
	var fwd := b * Vector3.FORWARD
	var eye := global_position + Vector3.UP * (CROUCH_HEIGHT - 0.16)
	if not _blocked(space, eye, eye + fwd * PEEK_COVER):
		return Vector3.ZERO
	var tries: Array = [Vector3(0, PEEK_UP, 0), Vector3(-PEEK_SIDE, 0, 0), Vector3(PEEK_SIDE, 0, 0)]
	if _peek_side != Vector3.ZERO:
		tries.push_front(_peek_side)
	for t in tries:
		var at: Vector3 = eye + b * (t as Vector3)
		if _blocked(space, eye, at):
			continue           # never lean through the thing you hide behind
		if not _blocked(space, at, at + fwd * (PEEK_COVER + 0.8)):
			return t
	return Vector3.ZERO


func _blocked(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1 | 8 | Carryable.LAYER, [get_rid()])
	return not space.intersect_ray(q).is_empty()


# --- being seen ----------------------------------------------------------------

## How far away a creature can see you, by what you are doing (CREATURES.md,
## "Sight"). `light`: 0 day, 1 dusk, 2 night. Walls are the creature's job.
const SIGHT_STAND := [35.0, 25.0, 15.0]
const SIGHT_SPRINT := [45.0, 35.0, 20.0]
const SIGHT_TORCH := 40.0

func sight_range(light: int) -> float:
	if seat != null:
		return 0.0
	light = clampi(light, 0, 2)
	var planar := Vector2(velocity.x, velocity.z).length()
	var r: float = SIGHT_STAND[light]
	if in_box:
		r = 3.0 if planar < 0.3 else 6.0
	elif crouching and not peeking:
		r *= 0.5
	elif planar > WALK + 0.5:
		r = SIGHT_SPRINT[light]
	if flashlight.visible and light >= 2:
		r = maxf(r, SIGHT_TORCH)
	return r


# --- binoculars ----------------------------------------------------------------

## Hands free, on foot or as the passenger, nothing else open.
func can_zoom() -> bool:
	return has_binoculars and held == null and not map_open and not journal_open and not phone_open \
		and knocked_t <= 0.0 and seat_role != "driver" and not peeking and not in_box


# --- tagging -------------------------------------------------------------------

## On foot or from the passenger seat. The driver's RT is the throttle.
func can_tag() -> bool:
	return not phone_open and not journal_open and knocked_t <= 0.0 and seat_role != "driver"


## Tags what you are looking at, up to TagMarker.RANGE away. Solid things and
## the small interactable areas (levers, handles) both count; big invisible
## trigger volumes do not. Returns the marker, or null if nothing was in reach.
func tag_look() -> TagMarker:
	var xf := head.global_transform
	var from := xf.origin
	var to := from - xf.basis.z * (TagMarker.RANGE_ZOOMED if zoom > 2.0 else TagMarker.RANGE)
	var space := get_world_3d().direct_space_state
	var ex: Array[RID] = [get_rid()]
	if held != null:
		ex.append(held.get_rid())
	if vehicle != null:
		# from a seat, look past the van itself: its body and its handles
		ex.append(vehicle.get_rid())
		for a in vehicle.find_children("*", "CollisionObject3D", true, false):
			ex.append((a as CollisionObject3D).get_rid())
	var q := PhysicsRayQueryParameters3D.create(from, to, TagMarker.MASK & ~4, ex)
	var hit := space.intersect_ray(q)
	var qa := PhysicsRayQueryParameters3D.create(from, to, 4, ex)
	qa.collide_with_areas = true
	qa.collide_with_bodies = false
	var hit_a := space.intersect_ray(qa)
	if not hit_a.is_empty() and (hit.is_empty() or from.distance_to(hit_a.position) < from.distance_to(hit.position)):
		hit = hit_a
	if hit.is_empty():
		Sfx.play_ui("ui_error", -12.0)
		return null
	return TagMarker.place(self, hit.position, hit.collider)


# --- paper map -----------------------------------------------------------------

## The map can be read on foot, or in the van while it is stopped.
func can_read_map() -> bool:
	if seat == null:
		return true
	return vehicle != null and vehicle.linear_velocity.length() < 1.0


func _update_map() -> void:
	if paper_map == null:
		return
	if dev.just_pressed("map"):
		set_map_open(not map_open and can_read_map())
	elif map_open and not can_read_map():
		set_map_open(false)      # the van pulled away: fold it up


func set_map_open(open: bool) -> void:
	if open != map_open:
		Sfx.play3d("paper_open" if open else "paper_close", head.global_position, -4.0)
	map_open = open
	if paper_map != null:
		paper_map.visible = open
		paper_map.queue_redraw()
	if open and prompt_text != "":
		prompt_text = ""
		prompt_changed.emit("")


func _map_controls() -> void:
	if dev.just_pressed("map_place"):
		paper_map.place_stamp()
		Sfx.play3d("stamp", head.global_position, -2.0)
	elif dev.just_pressed("map_remove"):
		if paper_map.remove_stamp():
			Sfx.play3d("page", head.global_position, -6.0)
	if dev.just_pressed("map_zoom_in"):
		paper_map.zoom_by(1.5)
	elif dev.just_pressed("map_zoom_out"):
		paper_map.zoom_by(1.0 / 1.5)
	if dev.just_pressed("map_next"):
		paper_map.cycle_stamp(1)
		Sfx.play3d("tick", head.global_position, -8.0)
	elif dev.just_pressed("map_prev"):
		paper_map.cycle_stamp(-1)
		Sfx.play3d("tick", head.global_position, -8.0)


func say(text: String, seconds := 6.0) -> void:
	message.emit(text, seconds)
	Sfx.play3d("page", head.global_position, -10.0)


## While carrying: E uses the item on what you are looking at (pour, stow...),
## or drops it if there is nothing to use it on; throw flings it.
func _scan_holding() -> void:
	var ctx: Node = null
	var ctx_text := ""
	if ray.is_colliding():
		var n := ray.get_collider() as Node
		while n != null and not n.has_meta("held_prompt_fn"):
			n = n.get_parent()
		if n != null:
			ctx_text = (n.get_meta("held_prompt_fn") as Callable).call(self, held)
			if ctx_text != "":
				ctx = n
	var text := ""
	if ctx != null:
		text = "[%s]  %s" % [dev.glyph("interact"), ctx_text]
	else:
		text = "%s     [%s]  Drop     [%s]  Throw" % [held.label().capitalize(), dev.glyph("interact"), dev.glyph("throw")]
		if held is CardboardBox:
			text = "Cardboard box     [%s]  Get under it     [%s]  Throw" % [dev.glyph("interact"), dev.glyph("throw")]
		if held is BatteryPack:
			text = "[%s]  Fit the batteries in your torch     [%s]  Drop" % [dev.glyph("flashlight"), dev.glyph("interact")]
	if text != prompt_text:
		prompt_text = text
		prompt_changed.emit(text)
	current_target = ctx

	if dev.just_pressed("throw"):
		throw_held()
		return
	if dev.just_pressed("interact"):
		if ctx != null:
			_using = ctx
			(ctx.get_meta("held_action") as Callable).call(self, held, get_physics_process_delta_time(), true)
		elif held is CardboardBox:
			enter_box()
		else:
			drop_held()
		return
	if _using != null:
		# Keep pouring while E is held and you are still right there, even if
		# the aim wobbles off the (small) target for a moment.
		var still_there := _using == ctx or (is_instance_valid(_using) and (_using as Node3D).global_position.distance_to(head.global_position) < 3.0)
		if dev.held("interact") and still_there and held != null:
			(_using.get_meta("held_action") as Callable).call(self, held, get_physics_process_delta_time(), false)
			if held != null:  # an action may consume the carried item
				held.pouring = _using.has_meta("pour")
			else:
				_using = null
		else:
			_using = null
			if held != null:
				held.pouring = false


# --- carrying ------------------------------------------------------------------

## Where a held item is steered to: low and to the right of the view, so it
## never covers the crosshair or what you are about to use it on. Heavier
## things hang lower; two-handed things are carried out in front.
func hold_point(item: Carryable) -> Vector3:
	var xf := head.global_transform
	var fwd := -xf.basis.z
	var right := xf.basis.x
	if item.two_handed:
		return xf.origin + fwd * 1.6 + Vector3.DOWN * 0.7
	# pouring: bring it down to just above the filler you are using
	if item.pouring and is_instance_valid(_using):
		return (_using as Node3D).global_position + Vector3.UP * 0.25 + right * 0.1
	var sag := lerpf(0.42, 0.72, item.heaviness())
	return xf.origin + fwd * 1.0 + right * 0.42 + Vector3.DOWN * sag


## What the feet are on: road, gravel track, wood (decks, crates, boards) or grass.
func _surface_step() -> String:
	var floor_body: Object = null
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		if c.get_normal().y > 0.6:
			floor_body = c.get_collider()
	if floor_body != null and (floor_body as Node).name != "Terrain":
		return "step_wood"
	var d := Landscape.road_distance(global_position.x, global_position.z)
	if d < Landscape.ROAD_HALF + 0.5:
		var r = Landscape.network.nearest(global_position.x, global_position.z)["road"] if Landscape.network else null
		return "step_gravel" if r != null and r.surface == "gravel" else "step_road"
	return "step_grass"


func pick_up(item: Carryable) -> void:
	if held != null or seat != null:
		return
	if not item.holders.is_empty() and not item.two_handed:
		return
	held = item
	item.grab(self)
	ray.add_exception(item)
	Sfx.play3d("pickup", item.global_position, -4.0)


func drop_held() -> void:
	if held == null:
		return
	var it := held
	held = null
	_using = null
	it.pouring = false
	ray.remove_exception(it)
	it.release(self)
	Sfx.play3d("drop", it.global_position, -8.0)


func throw_held() -> void:
	if held == null:
		return
	var it := held
	held = null
	_using = null
	it.pouring = false
	ray.remove_exception(it)
	it.throw_from(self, -head.global_transform.basis.z)
	Sfx.play3d("pluck", it.global_position, -6.0)


## The camper, if it is tipped over and this player is in it or close by.
func _near_upset_van():
	var van = vehicle
	if van == null:
		for c in get_tree().get_nodes_in_group("camper"):
			if (c as Node3D).global_position.distance_to(global_position) < 9.0:
				van = c
	if van != null and van.is_upset():
		return van
	return null


# --- travel journal ---------------------------------------------------------------

func _van_parked() -> bool:
	return vehicle != null and vehicle.linear_velocity.length() < 0.3


func _open_journal() -> void:
	set_map_open(false)
	journal_open = true
	Sfx.play3d("paper_open", head.global_position, -4.0)
	journal_confirm = false
	journal_note = ""
	if prompt_text != "":
		prompt_text = ""
		prompt_changed.emit("")


func _journal_controls() -> void:
	if not _van_parked() or seat == null:
		journal_open = false
		return
	var up := dev.just_pressed("menu_up") or (dev.kind == InputDevice.Kind.KBM and dev.just_pressed("fwd"))
	var down := dev.just_pressed("menu_down") or (dev.kind == InputDevice.Kind.KBM and dev.just_pressed("back"))
	if up or down:
		journal_sel = wrapi(journal_sel + (1 if down else -1), 0, SaveGame.SLOTS)
		journal_confirm = false
		journal_note = ""
	if dev.just_pressed("journal") or dev.just_pressed("menu_back"):
		journal_open = false
		return
	if dev.just_pressed("menu_ok") or dev.just_pressed("interact"):
		var st := get_tree().get_first_node_in_group("story") as Story
		if st == null or st.roses() < 1:
			journal_note = "You have no Memory Rose to spend."
			return
		if not journal_confirm:
			journal_confirm = true
			return
		st.roses_spent += 1
		Sfx.play3d("bong", head.global_position, -6.0)
		var boot := get_tree().current_scene
		if SaveGame.write(boot, journal_sel):
			if boot.has_method("mark_saved"):
				boot.mark_saved()
			journal_open = false
			for pl in get_tree().get_nodes_in_group("player"):
				pl.say("You write the day into the travel journal. The Memory Rose crumbles to petals between the pages.\n(Saved to slot %d.)" % (journal_sel + 1), 5.0)
		else:
			st.roses_spent -= 1
			journal_note = "The journal would not take the ink. (Could not write the save file.)"
		journal_confirm = false


func _can_exit() -> bool:
	return vehicle == null or vehicle.linear_velocity.length() < EXIT_MAX_SPEED


## What to show while seated: only what you can do right now, and nothing at
## all while the van is moving, so the road view stays clean.
func _seated_prompt() -> String:
	var parts: Array[String] = []
	if seat_role == "driver" and not vehicle.engine_on:
		parts.append("[%s]  Start engine" % dev.glyph("ignition"))
	if vehicle.linear_velocity.length() < 1.0:
		parts.append("[%s]  %s" % [dev.glyph("handbrake"), "Release handbrake" if vehicle.parking_brake else "Pull handbrake"])
	if _can_exit():
		parts.append("[%s]  Get out" % dev.glyph("interact"))
		parts.append("[%s]  Swap seats" % dev.glyph("swap_seat"))
	if _van_parked():
		parts.append("[%s]  Journal" % dev.glyph("journal"))
	return "     ".join(parts)


func _find_interactable(col: Object) -> Node:
	var n := col as Node
	while n != null:
		if n.has_meta("prompt"):
			return n
		n = n.get_parent()
	return null


# --- vehicle -------------------------------------------------------------------

## Seating never reparents the player. The body stays in the world with its
## collider switched off and is snapped onto the seat marker every physics tick.
## Reparenting a CharacterBody3D under a moving VehicleBody3D made GodotPhysics
## blow the vehicle apart on exit, and this is simpler besides.
func enter_seat(v, seat_node: Node3D, role: String) -> void:
	if seat != null:
		return
	drop_held()
	Sfx.play3d("door_close", global_position, -4.0)
	vehicle = v
	seat = seat_node
	seat_role = role
	velocity = Vector3.ZERO
	crouching = false
	_capsule.height = STAND_HEIGHT
	(get_node("Collider") as CollisionShape3D).disabled = true
	head.position = Vector3(0, SEATED_EYE, 0)
	eye_height = SEATED_EYE
	_seat_yaw = 0.0
	pitch = SEATED_PITCH
	bob_offset = Vector3.ZERO
	cam_roll = 0.0
	_set_seated_pose(true)
	_follow_seat()
	reset_physics_interpolation()
	if v.has_method("on_seat_entered"):
		v.on_seat_entered(self, role)


func exit_vehicle() -> void:
	if seat == null:
		return
	var v = vehicle
	Sfx.play3d("door_open", global_position, -4.0)
	var exit_xf: Transform3D = v.exit_transform_for(seat_role)
	yaw = exit_xf.basis.get_euler().y
	pitch = 0.0
	global_transform = Transform3D(Basis(Vector3.UP, yaw), exit_xf.origin)
	reset_physics_interpolation()
	head.rotation = Vector3(pitch, 0, 0)
	head.position = Vector3(0, STAND_HEIGHT - 0.16, 0)
	eye_height = STAND_HEIGHT - 0.16
	# Inherit the camper's motion so stepping out of a rolling van does not
	# resolve as a violent interpenetration on the next physics tick.
	velocity = v.linear_velocity
	_plan_vel = Vector2.ZERO
	(get_node("Collider") as CollisionShape3D).disabled = false
	_set_seated_pose(false)
	if v.has_method("on_seat_exited"):
		v.on_seat_exited(self, seat_role)
	seat = null
	vehicle = null
	seat_role = ""


func _follow_seat() -> void:
	global_transform = Transform3D(seat.global_transform.basis, seat.global_position)
