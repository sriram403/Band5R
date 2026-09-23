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
const ACCEL_AIR := 2.5
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

var index := 0
var dev: InputDevice
var body_color := Color(0.90, 0.62, 0.24)

var head: Node3D
var flashlight: SpotLight3D
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
var _using: Node = null                ## thing being used with the held item while E is held
var force_exit := false            ## request an exit from outside the physics step


func _ready() -> void:
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
	if force_exit:
		force_exit = false
		exit_vehicle()
	# Look itself is applied per rendered frame in _process; the physics step
	# only copies the result onto the body, the head and the interaction ray.
	rotation.y = yaw
	head.rotation = Vector3(pitch, _seat_yaw if seat != null else 0.0, 0)
	_update_map()
	if seat != null:
		_seated(delta)
	else:
		_walk(delta)
	if map_open:
		_map_controls()
	else:
		_scan()


## Look and camera run every rendered frame, not every physics tick, so the
## view stays smooth on high-refresh monitors. Positions come from the
## interpolated transforms, so movement and driving are smooth too.
func _process(delta: float) -> void:
	if dev != null and not get_tree().paused:
		if map_open and paper_map != null:
			paper_map.move_cursor(dev.cursor_delta(delta))
		else:
			_look(delta)
	if cam == null:
		return
	var xf: Transform3D
	if seat != null:
		var sx := seat.get_global_transform_interpolated()
		xf = sx * Transform3D(Basis.from_euler(Vector3(pitch, _seat_yaw, 0)), Vector3(0, SEATED_EYE, 0))
	else:
		var origin := get_global_transform_interpolated().origin + Vector3(0, eye_height, 0) + bob_offset
		xf = Transform3D(Basis.from_euler(Vector3(pitch, yaw, 0)), origin)
	var b := xf.basis.rotated(xf.basis.z.normalized(), cam_roll)
	cam.global_transform = Transform3D(b, xf.origin)


func _look(delta: float) -> void:
	var d := dev.look(delta)
	if seat != null:
		_seat_yaw = clampf(_seat_yaw - d.x, -SEAT_YAW_LIMIT, SEAT_YAW_LIMIT)
	else:
		yaw = wrapf(yaw - d.x, -PI, PI)
	pitch = clampf(pitch - d.y, -PITCH_LIMIT, PITCH_LIMIT)


func _walk(delta: float) -> void:
	var want_crouch := dev.held("crouch")
	if want_crouch != crouching:
		crouching = want_crouch
		_capsule.height = CROUCH_HEIGHT if crouching else STAND_HEIGHT
		var cs := get_node("Collider") as CollisionShape3D
		cs.position.y = _capsule.height * 0.5

	var target_eye: float = (CROUCH_HEIGHT if crouching else STAND_HEIGHT) - 0.16
	eye_height = lerp(eye_height, target_eye, 1.0 - pow(0.001, delta))
	head.position.y = eye_height

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif dev.just_pressed("jump") and not map_open:
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
	velocity.x = move_toward(velocity.x, target.x, accel * delta * 6.0)
	velocity.z = move_toward(velocity.z, target.z, accel * delta * 6.0)
	move_and_slide()
	# Walking into loose items nudges them along instead of stopping dead.
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var rb := hit.get_collider() as RigidBody3D
		if rb != null and not rb.freeze and rb != held and not rb is VehicleBody3D:
			var push := -hit.get_normal()
			push.y = 0.0
			rb.apply_central_impulse(push.normalized() * 55.0 * delta)

	# head bob keyed to actual ground speed
	var planar := Vector2(velocity.x, velocity.z).length()
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


func toggle_flashlight() -> void:
	flashlight.visible = not flashlight.visible
	beam.visible = flashlight.visible


# --- interaction ---------------------------------------------------------------

func _scan() -> void:
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
			var blocked: String = (node.get_meta("blocked_fn") as Callable).call() if node.has_meta("blocked_fn") else ""
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
	elif dev.just_pressed("map_remove"):
		paper_map.remove_stamp()
	if dev.just_pressed("map_next"):
		paper_map.cycle_stamp(1)
	elif dev.just_pressed("map_prev"):
		paper_map.cycle_stamp(-1)


func say(text: String, seconds := 6.0) -> void:
	message.emit(text, seconds)


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
		else:
			drop_held()
		return
	if _using != null:
		if dev.held("interact") and _using == ctx and held != null:
			(ctx.get_meta("held_action") as Callable).call(self, held, get_physics_process_delta_time(), false)
		else:
			_using = null


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
	var sag := lerpf(0.42, 0.72, item.heaviness())
	return xf.origin + fwd * 1.0 + right * 0.42 + Vector3.DOWN * sag


func pick_up(item: Carryable) -> void:
	if held != null or seat != null:
		return
	if not item.holders.is_empty() and not item.two_handed:
		return
	held = item
	item.grab(self)
	ray.add_exception(item)


func drop_held() -> void:
	if held == null:
		return
	var it := held
	held = null
	_using = null
	ray.remove_exception(it)
	it.release(self)


func throw_held() -> void:
	if held == null:
		return
	var it := held
	held = null
	_using = null
	ray.remove_exception(it)
	it.throw_from(self, -head.global_transform.basis.z)


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


func _can_exit() -> bool:
	return vehicle == null or vehicle.linear_velocity.length() < EXIT_MAX_SPEED


## What to show while seated: only what you can do right now, and nothing at
## all while the van is moving, so the road view stays clean.
func _seated_prompt() -> String:
	var parts: Array[String] = []
	if seat_role == "driver" and not vehicle.engine_on:
		parts.append("[%s]  Start engine" % dev.glyph("ignition"))
	if _can_exit():
		parts.append("[%s]  Get out" % dev.glyph("interact"))
		parts.append("[%s]  Swap seats" % dev.glyph("swap_seat"))
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
	_follow_seat()
	reset_physics_interpolation()
	if v.has_method("on_seat_entered"):
		v.on_seat_entered(self, role)


func exit_vehicle() -> void:
	if seat == null:
		return
	var v = vehicle
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
	(get_node("Collider") as CollisionShape3D).disabled = false
	if v.has_method("on_seat_exited"):
		v.on_seat_exited(self, seat_role)
	seat = null
	vehicle = null
	seat_role = ""


func _follow_seat() -> void:
	global_transform = Transform3D(seat.global_transform.basis, seat.global_position)
