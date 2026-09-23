class_name Camper
extends VehicleBody3D

## The shared camper van: chassis, driving model, seats, dashboard gauges.
##
## All tuning constants live at the top so the driving feel can be adjusted
## without touching logic.

# --- tuning --------------------------------------------------------------------
const MASS := 2150.0
const ENGINE_PEAK := 7000.0        ## N at low speed
const ENGINE_FADE := 30.0          ## m/s at which the engine runs out of pull
const REVERSE_FORCE := 2100.0
const BRAKE_FORCE := 42.0
const HANDBRAKE_FORCE := 90.0
const STEER_MAX := 0.55            ## rad at standstill
const STEER_MIN := 0.15            ## rad at high speed
const STEER_SPEED := 3.4           ## how fast the wheels reach the target angle
const STEER_RETURN := 5.2
const IDLE_DRAG := 0.35
const HOLD_BRAKE := 14.0           ## auto-hold at a standstill so a parked van does not creep
const HOLD_SPEED := 1.0            ## m/s below which the hold engages

const FUEL_CAPACITY := 70.0
const FUEL_PER_KM := 4.0           ## game-readable, not realistic: ~17 km on a tank
const FUEL_IDLE_PER_S := 0.004
const TEMP_AMBIENT := 62.0
const TEMP_MAX := 122.0
const TEMP_NORMAL := 88.0          ## where the needle sits in ordinary driving
const TEMP_WARN := 104.0           ## warning lamp
const TEMP_CLIMB_GAIN := 30.0      ## extra degrees per unit of load above flat full throttle
const TEMP_RISE_RATE := 1.2        ## deg/s toward the target
const TEMP_FALL_RATE := 0.8

const WHEEL_RADIUS := 0.44
const WHEEL_REST := 0.30
const TRACK := 1.00
const WHEELBASE := 1.95

## The chassis origin sits at the suspension mounting point, which is
## WHEEL_RADIUS + WHEEL_REST above the road. Everything visible and everything
## the players sit on hangs off _body_root, shifted down by this much so the van
## rides on its wheels instead of floating above them.
const BODY_Y := -(WHEEL_RADIUS + WHEEL_REST) - 0.11

# --- state ---------------------------------------------------------------------
var engine_on := false
var headlights_on := false
var fuel := 52.0
var temp := TEMP_AMBIENT
var battery := 1.0
var odometer := 0.0
var rpm_norm := 0.0                ## 0..1, drives audio and the tacho

var driver: PlayerRig = null
var passenger: PlayerRig = null

var seat_nodes := {}               ## role -> Node3D
var _steer := 0.0
var _wheels: Array[VehicleWheel3D] = []
var _wheel_meshes: Array[Node3D] = []
var _wheel_spin := 0.0
var _needles := {}
var _steering_wheel: Node3D
var _headlight_nodes: Array[Node3D] = []
var _body_root: Node3D
var _audio: EngineAudio
var debug_throttle := 0.0          ## used by the dev capture mode only
var debug_steer := 0.0
var _nav_timer := 0.0
var _parked_t := 0.0


func _ready() -> void:
	add_to_group("camper")
	mass = MASS
	collision_layer = 8
	collision_mask = 1 | 2
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.30, 0)
	continuous_cd = true
	_body_root = Node3D.new()
	_body_root.name = "Body"
	_body_root.position = Vector3(0, BODY_Y, 0)
	add_child(_body_root)
	_build_collision()
	_build_wheels()
	_build_body()
	_build_interior()
	_build_seats()
	_audio = EngineAudio.new()
	add_child(_audio)


# --- construction --------------------------------------------------------------

func _build_collision() -> void:
	var cs := CollisionShape3D.new()
	cs.name = "Hull"
	var box := BoxShape3D.new()
	box.size = Vector3(2.24, 2.00, 5.80)
	cs.shape = box
	cs.position = Vector3(0, BODY_Y + 1.70, 0)
	add_child(cs)


func _build_wheels() -> void:
	var tyre := ToonMat.make(Color(0.13, 0.13, 0.15), 0.02, 0.98)
	var hub := ToonMat.make(Color(0.82, 0.80, 0.74), 0.015, 0.5)
	var layout := [
		{"nm": "FL", "pos": Vector3(-TRACK, 0.0, -WHEELBASE), "steer": true},
		{"nm": "FR", "pos": Vector3(TRACK, 0.0, -WHEELBASE), "steer": true},
		{"nm": "RL", "pos": Vector3(-TRACK, 0.0, WHEELBASE), "steer": false},
		{"nm": "RR", "pos": Vector3(TRACK, 0.0, WHEELBASE), "steer": false},
	]
	for w in layout:
		var wheel := VehicleWheel3D.new()
		wheel.name = "Wheel" + str(w["nm"])
		wheel.position = w["pos"]
		wheel.use_as_steering = w["steer"]
		wheel.use_as_traction = not w["steer"]
		wheel.wheel_radius = WHEEL_RADIUS
		wheel.wheel_rest_length = WHEEL_REST
		wheel.wheel_friction_slip = 3.6 if not w["steer"] else 3.1
		wheel.suspension_travel = 0.30
		wheel.suspension_stiffness = 34.0
		wheel.suspension_max_force = 9500.0
		wheel.damping_compression = 0.75
		wheel.damping_relaxation = 1.15
		wheel.wheel_roll_influence = 0.22
		add_child(wheel)
		_wheels.append(wheel)

		var holder := Node3D.new()
		holder.name = "Spin"
		wheel.add_child(holder)
		var t := Build.cyl(WHEEL_RADIUS, 0.34, tyre, Vector3.ZERO, Vector3(0, 0, 90), 16, "Tyre")
		holder.add_child(t)
		var side: float = signf(float(w["pos"].x))
		holder.add_child(Build.cyl(WHEEL_RADIUS * 0.46, 0.30, hub, Vector3(side * 0.03, 0, 0), Vector3(0, 0, 90), 12, "Hub"))
		# fender flare over each wheel, so they read as part of the van
		_body_root.add_child(Build.box(Vector3(0.22, 0.14, 1.30),
			ToonMat.make(Color(0.32, 0.34, 0.38)),
			Vector3(side * 1.18, -BODY_Y + 0.30, w["pos"].z), Vector3.ZERO, "Fender"))
		_wheel_meshes.append(holder)


## Panelled construction: thin slabs so the interior surfaces are real geometry
## and the van reads correctly from inside as well as outside.
func _build_body() -> void:
	var shell := ToonMat.make(Color(0.94, 0.90, 0.80))
	var accent := ToonMat.make(Color(0.20, 0.58, 0.62))
	var patch := ToonMat.make(Color(0.86, 0.55, 0.22))
	var dark := ToonMat.make(Color(0.28, 0.30, 0.34))
	var glass := _glass()

	var g := Node3D.new()
	g.name = "Shell"
	_body_root.add_child(g)

	# floor / roof
	g.add_child(Build.box(Vector3(2.24, 0.12, 5.80), dark, Vector3(0, 0.72, 0), Vector3.ZERO, "Floor"))
	g.add_child(Build.box(Vector3(2.30, 0.12, 5.60), shell, Vector3(0, 2.62, 0.05), Vector3.ZERO, "Roof"))

	# side walls, split so there is a window band you can actually see out of
	for s in [-1.0, 1.0]:
		var x: float = s * 1.12
		g.add_child(Build.box(Vector3(0.10, 0.72, 5.80), shell, Vector3(x, 1.14, 0), Vector3.ZERO, "LowerWall"))
		g.add_child(Build.box(Vector3(0.10, 0.42, 5.80), shell, Vector3(x, 2.35, 0), Vector3.ZERO, "UpperWall"))
		# stripe
		g.add_child(Build.box(Vector3(0.12, 0.22, 5.60), accent, Vector3(x, 1.02, 0), Vector3.ZERO, "Stripe"))
		# window band: glass + pillars
		g.add_child(Build.box(Vector3(0.04, 0.66, 5.60), glass, Vector3(x, 1.83, 0), Vector3.ZERO, "SideGlass"))
		for pz in [-2.84, -1.15, 0.55, 2.75]:
			g.add_child(Build.box(Vector3(0.12, 0.70, 0.14), shell, Vector3(x, 1.83, pz), Vector3.ZERO, "Pillar"))
		# a mismatched repair panel, one side only
		if s < 0:
			g.add_child(Build.box(Vector3(0.06, 0.60, 1.30), patch, Vector3(x - 0.05, 1.20, 1.30), Vector3.ZERO, "RepairPanel"))

	# rear wall + doors
	g.add_child(Build.box(Vector3(2.24, 1.90, 0.10), shell, Vector3(0, 1.70, 2.90), Vector3.ZERO, "Rear"))
	g.add_child(Build.box(Vector3(0.96, 1.20, 0.06), accent, Vector3(-0.53, 1.45, 2.96), Vector3.ZERO, "DoorL"))
	g.add_child(Build.box(Vector3(0.96, 1.20, 0.06), accent, Vector3(0.53, 1.45, 2.96), Vector3.ZERO, "DoorR"))
	# spare wheel on the back
	g.add_child(Build.cyl(0.44, 0.26, ToonMat.make(Color(0.15, 0.15, 0.17)), Vector3(0.0, 2.05, 3.10), Vector3(90, 0, 0), 16, "Spare"))

	# nose: bonnet high enough to meet the windscreen, so the driver's sightline
	# starts just above the dash instead of into bodywork
	# Two-tone nose: a cream bonnet filled the bottom of the windscreen with a
	# glaring white slab from the driver's seat.
	g.add_child(Build.box(Vector3(2.20, 0.72, 0.90), accent, Vector3(0, 1.30, -3.32), Vector3.ZERO, "Bonnet"))
	g.add_child(Build.box(Vector3(2.20, 0.40, 0.30), dark, Vector3(0, 0.72, -3.80), Vector3.ZERO, "Bumper"))
	g.add_child(Build.box(Vector3(2.10, 0.40, 0.10), ToonMat.make(Color(0.55, 0.58, 0.60)), Vector3(0, 1.20, -3.78), Vector3.ZERO, "Grille"))
	g.add_child(Build.box(Vector3(2.24, 1.06, 0.06), glass, Vector3(0, 2.16, -2.98), Vector3(-18, 0, 0), "Windscreen"))
	g.add_child(Build.box(Vector3(2.24, 0.14, 0.34), shell, Vector3(0, 2.66, -2.83), Vector3(-18, 0, 0), "Visor"))

	# roof rack, ladder, awning: makes the silhouette read as "improvised camper"
	var rack := Node3D.new()
	rack.name = "Rack"
	g.add_child(rack)
	for rz in [-1.6, -0.2, 1.2, 2.4]:
		rack.add_child(Build.box(Vector3(2.20, 0.08, 0.10), dark, Vector3(0, 2.74, rz), Vector3.ZERO, "Bar"))
	for rs in [-1.0, 1.0]:
		rack.add_child(Build.box(Vector3(0.08, 0.20, 4.30), dark, Vector3(rs * 1.06, 2.78, 0.4), Vector3.ZERO, "Rail"))
	rack.add_child(Build.box(Vector3(1.10, 0.45, 0.80), patch, Vector3(-0.4, 3.00, -0.6), Vector3(0, 8, 0), "RoofCrate"))
	rack.add_child(Build.cyl(0.20, 1.60, ToonMat.make(Color(0.30, 0.55, 0.70)), Vector3(0.6, 2.98, 1.4), Vector3(90, 0, 0), 10, "RolledAwning"))
	for lz in range(5):
		g.add_child(Build.box(Vector3(0.44, 0.05, 0.05), dark, Vector3(1.14, 1.05 + lz * 0.40, 2.55), Vector3.ZERO, "LadderRung"))
	for ls in [-1.0, 1.0]:
		g.add_child(Build.box(Vector3(0.05, 1.90, 0.05), dark, Vector3(1.14 + ls * 0.20, 1.85, 2.55), Vector3.ZERO, "LadderRail"))

	# headlights
	for hs in [-1.0, 1.0]:
		var lamp := Build.cyl(0.20, 0.10, ToonMat.make(Color(0.98, 0.96, 0.86), 0.012, 0.2),
			Vector3(hs * 0.78, 1.20, -3.78), Vector3(90, 0, 0), 12, "Lamp")
		g.add_child(lamp)
		var sl := SpotLight3D.new()
		sl.name = "Headlight"
		sl.position = Vector3(hs * 0.78, 1.20, -3.82)
		sl.rotation_degrees = Vector3(-3.0, 180, 0)
		sl.light_color = Color(1.0, 0.96, 0.86)
		sl.light_energy = 7.0
		sl.spot_range = 60.0
		sl.spot_angle = 40.0
		sl.spot_angle_attenuation = 0.6
		sl.shadow_enabled = false
		sl.visible = false
		g.add_child(sl)
		_headlight_nodes.append(sl)
	for ts in [-1.0, 1.0]:
		g.add_child(Build.box(Vector3(0.26, 0.14, 0.06), ToonMat.make(Color(0.75, 0.12, 0.14), 0.01, 0.3),
			Vector3(ts * 0.88, 1.42, 2.96), Vector3.ZERO, "TailLight"))


func _build_interior() -> void:
	var g := Node3D.new()
	g.name = "Interior"
	_body_root.add_child(g)

	var uph := ToonMat.make(Color(0.46, 0.37, 0.48), 0.012)
	var dashmat := ToonMat.make(Color(0.30, 0.31, 0.36), 0.012)
	var wood := ToonMat.make(Color(0.62, 0.46, 0.30), 0.012)

	# Cab layout is measured from the seated eye point (seat marker y 1.36,
	# z -1.80, eye 0.62 above it, so eye y = 1.98):
	#   windscreen bottom  ~18 deg below the horizon: road visible from ~6 m out
	#   whole dash         below that line, so nothing floats across the road
	#   gauge cluster      ~20..29 deg below, readable with a glance down
	g.add_child(Build.box(Vector3(2.10, 0.60, 0.50), dashmat, Vector3(0, 1.30, -2.62), Vector3.ZERO, "Dash"))
	g.add_child(Build.box(Vector3(0.10, 0.10, 0.55), dashmat, Vector3(-0.62, 1.36, -2.42), Vector3(28, 0, 0), "Column"))
	var cluster := Node3D.new()
	cluster.name = "Cluster"
	cluster.position = Vector3(-0.62, 1.685, -2.49)
	cluster.rotation_degrees = Vector3(-30, 0, 0)
	g.add_child(cluster)
	# backing plate the dials are mounted on, behind them rather than over them
	cluster.add_child(Build.box(Vector3(0.36, 0.17, 0.03), ToonMat.make(Color(0.20, 0.21, 0.24), 0.008), Vector3(-0.02, -0.01, -0.03), Vector3.ZERO, "Backplate"))
	_needles["speed"] = _gauge(cluster, Vector3(-0.060, 0.0, 0), 0.062, Color(0.93, 0.92, 0.88), "km/h")
	_needles["fuel"] = _gauge(cluster, Vector3(0.068, 0.024, 0), 0.036, Color(0.90, 0.88, 0.80), "FUEL")
	_needles["temp"] = _gauge(cluster, Vector3(0.068, -0.052, 0), 0.036, Color(0.90, 0.88, 0.80), "TEMP")

	# warning lamps
	_needles["lamp_fuel"] = _lamp(cluster, Vector3(-0.155, 0.045, 0.012), Color(0.95, 0.65, 0.15))
	_needles["lamp_temp"] = _lamp(cluster, Vector3(-0.155, 0.0, 0.012), Color(0.90, 0.20, 0.18))
	_needles["lamp_batt"] = _lamp(cluster, Vector3(-0.155, -0.045, 0.012), Color(0.30, 0.85, 0.55))

	# steering wheel
	_steering_wheel = Node3D.new()
	_steering_wheel.name = "SteeringWheel"
	_steering_wheel.position = Vector3(-0.62, 1.50, -2.18)
	_steering_wheel.rotation_degrees = Vector3(-62, 0, 0)
	g.add_child(_steering_wheel)
	var torus := TorusMesh.new()
	torus.inner_radius = 0.15
	torus.outer_radius = 0.19
	torus.rings = 24
	torus.ring_segments = 8
	var rim := Build.node(torus, ToonMat.make(Color(0.16, 0.16, 0.18), 0.01), Transform3D(Basis.from_euler(Vector3(deg_to_rad(90), 0, 0)), Vector3.ZERO), "Rim")
	_steering_wheel.add_child(rim)
	_steering_wheel.add_child(Build.box(Vector3(0.30, 0.03, 0.05), ToonMat.make(Color(0.20, 0.20, 0.22), 0.008), Vector3.ZERO, Vector3.ZERO, "Spoke"))

	# Navigation screen on the centre console, turned toward the passenger.
	# The label is a child sitting just proud of the glass, so it can never end
	# up buried inside the screen box.
	var nav := Node3D.new()
	nav.name = "NavScreen"
	nav.position = Vector3(0.02, 1.72, -2.52)
	nav.rotation_degrees = Vector3(-18, 22, 0)
	g.add_child(nav)
	nav.add_child(Build.box(Vector3(0.40, 0.25, 0.04), ToonMat.make(Color(0.16, 0.17, 0.20), 0.01), Vector3.ZERO, Vector3.ZERO, "Bezel"))
	nav.add_child(Build.box(Vector3(0.36, 0.21, 0.01), ToonMat.flat(Color(0.05, 0.13, 0.14)), Vector3(0, 0, 0.021), Vector3.ZERO, "Glass"))
	var navlabel := Build.label3d("", Vector3(0, 0, 0.03), Vector3.ZERO, 0.040, Color(0.50, 0.98, 0.82))
	navlabel.outline_size = 0
	nav.add_child(navlabel)
	_needles["nav_label"] = navlabel

	# seats
	for s in [-1.0, 1.0]:
		var sx: float = s * 0.62
		g.add_child(Build.box(Vector3(0.58, 0.16, 0.58), uph, Vector3(sx, 1.14, -1.55), Vector3.ZERO, "SeatBase"))
		g.add_child(Build.box(Vector3(0.58, 0.80, 0.14), uph, Vector3(sx, 1.62, -1.26), Vector3(8, 0, 0), "SeatBack"))

	# living area: bunk, table, cupboards, and the travel journal
	g.add_child(Build.box(Vector3(2.10, 0.12, 1.60), wood, Vector3(0, 1.55, 2.00), Vector3.ZERO, "Bunk"))
	g.add_child(Build.box(Vector3(2.10, 0.60, 1.60), uph, Vector3(0, 1.20, 2.00), Vector3.ZERO, "BunkBase"))
	g.add_child(Build.box(Vector3(0.80, 0.06, 0.70), wood, Vector3(-0.55, 1.44, 0.30), Vector3.ZERO, "Table"))
	g.add_child(Build.cyl(0.05, 0.62, ToonMat.make(Color(0.55, 0.56, 0.58)), Vector3(-0.55, 1.10, 0.30), Vector3.ZERO, 8, "TableLeg"))
	g.add_child(Build.box(Vector3(0.70, 0.70, 0.60), wood, Vector3(0.72, 1.13, 0.10), Vector3.ZERO, "Cupboard"))
	g.add_child(Build.box(Vector3(0.26, 0.05, 0.34), ToonMat.make(Color(0.72, 0.24, 0.28), 0.01), Vector3(-0.55, 1.49, 0.30), Vector3(0, 18, 0), "Journal"))

	# warm interior light; the cab needs its own or the dash reads as a black slab
	for lp in [Vector3(0, 2.40, 1.20), Vector3(0, 2.30, -1.60)]:
		var il := OmniLight3D.new()
		il.name = "InteriorLight"
		il.position = lp
		il.light_color = Color(1.0, 0.92, 0.78)
		il.light_energy = 0.75
		il.omni_range = 4.0
		il.omni_attenuation = 1.6
		il.shadow_enabled = false
		g.add_child(il)


func _gauge(parent: Node3D, pos: Vector3, radius: float, face_col: Color, tag: String) -> Node3D:
	var g := Node3D.new()
	g.name = "Gauge" + tag
	g.position = pos
	parent.add_child(g)
	g.add_child(Build.cyl(radius, 0.02, ToonMat.make(Color(0.14, 0.14, 0.16), 0.008), Vector3(0, 0, -0.012), Vector3(90, 0, 0), 20, "Bezel"))
	g.add_child(Build.cyl(radius * 0.88, 0.012, ToonMat.flat(face_col), Vector3(0, 0, 0.0), Vector3(90, 0, 0), 20, "Face"))
	g.add_child(Build.label3d(tag, Vector3(0, -radius * 0.45, 0.012), Vector3.ZERO, radius * 0.34, Color(0.25, 0.25, 0.30)))
	var needle := Node3D.new()
	needle.name = "Needle"
	needle.position = Vector3(0, 0, 0.016)
	g.add_child(needle)
	var n := Build.box(Vector3(0.012, radius * 0.82, 0.008), ToonMat.flat(Color(0.82, 0.14, 0.16)), Vector3(0, radius * 0.34, 0), Vector3.ZERO, "Pin")
	needle.add_child(n)
	return needle


func _lamp(parent: Node3D, pos: Vector3, col: Color) -> MeshInstance3D:
	var m := Build.cyl(0.011, 0.01, ToonMat.flat(col.darkened(0.72)), pos, Vector3(90, 0, 0), 10, "Lamp")
	parent.add_child(m)
	m.set_meta("on_color", col)
	m.set_meta("off_color", col.darkened(0.72))
	return m


func _build_seats() -> void:
	for role in ["driver", "passenger"]:
		var s := Node3D.new()
		s.name = "Seat_" + role
		var sx := -0.62 if role == "driver" else 0.62
		s.position = Vector3(sx, 1.36, -1.80)
		_body_root.add_child(s)
		seat_nodes[role] = s

		# The prompt volume sits just outside the door so the ray can reach it.
		var area := Build.interact_area(
			Vector3(0.7, 1.8, 1.6),
			Vector3(sx * 2.35, 1.40, -1.80),
			"Sit in the %s seat" % ("driver's" if role == "driver" else "passenger"),
			func(p: PlayerRig): _try_seat(p, role),
			"SeatPrompt_" + role)
		area.set_meta("blocked_fn", func() -> String:
			var taken: PlayerRig = driver if role == "driver" else passenger
			return "" if taken == null else "Seat taken - P%d is in it" % (taken.index + 1))
		_body_root.add_child(area)


func _glass() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.62, 0.80, 0.86, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Glossy glass put a hard sun glint in the middle of the driver's view.
	m.roughness = 0.45
	m.metallic = 0.0
	m.metallic_specular = 0.15
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	return m


# --- seating -------------------------------------------------------------------

func _try_seat(p: PlayerRig, role: String) -> void:
	if role == "driver" and driver != null:
		return
	if role == "passenger" and passenger != null:
		return
	p.enter_seat(self, seat_nodes[role], role)


func on_seat_entered(p: PlayerRig, role: String) -> void:
	if role == "driver":
		driver = p
	else:
		passenger = p
	# The hull and the door prompt volumes must not block the seated player's
	# view ray, or they permanently show "sit in the seat you are already in".
	p.ray.add_exception(self)
	for c in _body_root.get_children():
		if c is Area3D:
			p.ray.add_exception(c)


func on_seat_exited(p: PlayerRig, role: String) -> void:
	if role == "driver":
		driver = null
	else:
		passenger = null
	p.ray.remove_exception(self)
	for c in _body_root.get_children():
		if c is Area3D:
			p.ray.remove_exception(c)


func exit_transform_for(role: String) -> Transform3D:
	var side := -1.0 if role == "driver" else 1.0
	var local := Vector3(side * 2.1, 0.2, -1.7)
	var world_pos := global_transform * local
	# drop the player onto the ground rather than into the air
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(world_pos + Vector3.UP * 3.0, world_pos - Vector3.UP * 6.0)
	q.collision_mask = 1
	q.exclude = [get_rid()]
	var hit := space.intersect_ray(q)
	if hit:
		world_pos = hit["position"] + Vector3.UP * 0.1
	var yaw := global_transform.basis.get_euler().y + (PI * 0.5 * side)
	return Transform3D(Basis(Vector3.UP, yaw), world_pos)


func swap_roles() -> void:
	if linear_velocity.length() > 1.0:
		return
	var d := driver
	var p := passenger
	if d != null:
		d.exit_vehicle()
	if p != null:
		p.exit_vehicle()
	if d != null:
		d.enter_seat(self, seat_nodes["passenger"], "passenger")
	if p != null:
		p.enter_seat(self, seat_nodes["driver"], "driver")


# --- driving -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	var speed := linear_velocity.length()
	var fwd_speed := -global_transform.basis.z.dot(linear_velocity)

	var throttle_in := debug_throttle
	var brake_in := 0.0
	var steer_in := debug_steer
	var handbrake := false

	if driver != null and driver.dev != null:
		var dev := driver.dev
		throttle_in = maxf(debug_throttle, dev.throttle())
		brake_in = dev.brake()
		steer_in = dev.steer() if absf(dev.steer()) > 0.001 else debug_steer
		handbrake = dev.held("handbrake")
		if dev.just_pressed("ignition"):
			toggle_engine()
		if dev.just_pressed("headlights"):
			set_headlights(not headlights_on)
		if dev.just_pressed("swap_seat"):
			swap_roles()
			return
	if passenger != null and passenger.dev != null:
		var pdev := passenger.dev
		if pdev.just_pressed("headlights"):
			set_headlights(not headlights_on)
		if pdev.just_pressed("swap_seat"):
			swap_roles()
			return

	# steering: less lock the faster you go, springs back to centre
	var lock: float = lerp(STEER_MAX, STEER_MIN, clampf(speed / 24.0, 0.0, 1.0))
	var target := steer_in * lock
	var rate := STEER_SPEED if absf(steer_in) > 0.05 else STEER_RETURN
	_steer = move_toward(_steer, target, rate * lock * delta)
	# Godot's `steering` is positive-left; our input is positive-right.
	steering = -_steer

	# engine
	var out := 0.0
	if engine_on and fuel > 0.0:
		if throttle_in > 0.01:
			var fade: float = clampf(1.0 - maxf(fwd_speed, 0.0) / ENGINE_FADE, 0.04, 1.0)
			out = ENGINE_PEAK * throttle_in * fade
		elif brake_in > 0.01 and fwd_speed < 0.6:
			out = -REVERSE_FORCE * brake_in
	# Measured: positive engine_force pushes this rig toward +Z, but the van's
	# nose is -Z, so drive forces are negated here rather than flipping the mesh.
	engine_force = -out

	var b := 0.0
	if brake_in > 0.01 and fwd_speed > 0.6:
		b = BRAKE_FORCE * brake_in
	if handbrake:
		b = HANDBRAKE_FORCE
	if not engine_on or throttle_in < 0.01:
		b += IDLE_DRAG
	# Parking brake with the engine off, auto-hold with it idling: without
	# this the van crept downhill on its own after every stop.
	if speed < HOLD_SPEED and throttle_in < 0.01 and brake_in < 0.01:
		b = maxf(b, HANDBRAKE_FORCE if not engine_on else HOLD_BRAKE)
	_update_parked(delta, speed, throttle_in, brake_in)
	brake = b

	_update_condition(delta, speed, throttle_in)
	_update_visuals(delta, speed)


func _update_condition(delta: float, speed: float, throttle_in: float) -> void:
	odometer += speed * delta
	if engine_on:
		var load: float = throttle_in * (1.0 + clampf(_grade() * 4.0, 0.0, 1.6))
		var km := speed * delta / 1000.0
		fuel = maxf(0.0, fuel - km * FUEL_PER_KM * (0.6 + load) - FUEL_IDLE_PER_S * delta)
		# Equilibrium model: heat target rises with load, falls with airflow.
		# Ordinary driving settles near TEMP_NORMAL; only load beyond flat full
		# throttle (climbing, towing) pushes it toward the warning lamp.
		var target_temp: float = TEMP_NORMAL + maxf(0.0, load - 0.9) * TEMP_CLIMB_GAIN - clampf(speed, 0.0, 25.0) * 0.25
		target_temp = clampf(target_temp, TEMP_AMBIENT, TEMP_MAX)
		temp = move_toward(temp, target_temp, (TEMP_RISE_RATE if target_temp > temp else TEMP_FALL_RATE) * delta)
		battery = minf(1.0, battery + 0.02 * delta)
		rpm_norm = clampf(0.16 + throttle_in * 0.55 + clampf(speed / 26.0, 0.0, 1.0) * 0.42, 0.0, 1.0)
		if fuel <= 0.0:
			toggle_engine()
	else:
		temp = maxf(TEMP_AMBIENT, temp - 1.6 * delta)
		rpm_norm = maxf(0.0, rpm_norm - 1.8 * delta)
		if headlights_on:
			battery = maxf(0.0, battery - 0.004 * delta)
	if _audio:
		_audio.set_state(engine_on, rpm_norm, speed)


## Uphill grade, 0 on the flat or downhill. The nose is -Z, so a raised nose
## makes basis.z point down.
func _grade() -> float:
	return maxf(0.0, -global_transform.basis.z.y)


func _update_visuals(delta: float, speed: float) -> void:
	_wheel_spin += speed * delta / WHEEL_RADIUS
	for i in _wheel_meshes.size():
		_wheel_meshes[i].rotation.x = -_wheel_spin
	if _steering_wheel:
		_steering_wheel.rotation_degrees.z = -rad_to_deg(_steer) * 3.6

	var kmh := speed * 3.6
	_set_needle("speed", remap(clampf(kmh, 0.0, 140.0), 0.0, 140.0, 140.0, -140.0))
	_set_needle("fuel", remap(fuel / FUEL_CAPACITY, 0.0, 1.0, 60.0, -60.0))
	_set_needle("temp", remap((temp - TEMP_AMBIENT) / (TEMP_MAX - TEMP_AMBIENT), 0.0, 1.0, 60.0, -60.0))

	_set_lamp("lamp_fuel", fuel / FUEL_CAPACITY < 0.18)
	_set_lamp("lamp_temp", temp > TEMP_WARN)
	_set_lamp("lamp_batt", not engine_on and battery > 0.02)

	_nav_timer -= delta
	var nav: Label3D = _needles.get("nav_label")
	if nav and _nav_timer <= 0.0:
		_nav_timer = 0.25
		nav.text = _nav_text()


## Broad direction only, per the design: no map, no route, just where Bessi is.
func _nav_text() -> String:
	if battery <= 0.02:
		return ""
	var to := LevelBuilder.ROSE_CENTRE - global_position
	to.y = 0.0
	var local := global_transform.basis.inverse() * to
	var ang := rad_to_deg(atan2(local.x, -local.z))
	var dir := "AHEAD"
	if absf(ang) > 150.0:
		dir = "BEHIND"
	elif ang > 30.0:
		dir = "RIGHT >"
	elif ang < -30.0:
		dir = "< LEFT"
	return "BESSI  %.2f km\n%s\nODO %.1f km" % [to.length() * 0.001, dir, odometer * 0.001]


func _set_needle(key: String, deg: float) -> void:
	var n: Node3D = _needles.get(key)
	if n:
		n.rotation_degrees.z = deg


func _set_lamp(key: String, on: bool) -> void:
	var m: MeshInstance3D = _needles.get(key)
	if m == null:
		return
	var want: Color = m.get_meta("on_color") if on else m.get_meta("off_color")
	var mat := m.material_override as StandardMaterial3D
	if mat and mat.albedo_color != want:
		m.material_override = ToonMat.flat(want)


## Raycast-wheel brakes still let a van creep a few cm/s on a steep grade. Once
## it has properly stopped with its wheels down, freeze it in place; any
## throttle or brake input releases it on the same tick.
func _update_parked(delta: float, speed: float, throttle_in: float, brake_in: float) -> void:
	var grounded := true
	for w in _wheels:
		if not w.is_in_contact():
			grounded = false
	var settle := speed < 0.25 and throttle_in < 0.01 and brake_in < 0.01 and grounded
	_parked_t = _parked_t + delta if settle else 0.0
	var want := _parked_t > 0.6
	if want != freeze:
		freeze = want


## On its side or roof and not going anywhere.
func is_upset() -> bool:
	return global_transform.basis.y.y < 0.5 and linear_velocity.length() < 3.0


## Put the van back on its wheels where it lies, facing the way it was.
## There is no other way out of a roll, so this must always be available.
func recover() -> void:
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	if fwd.length() < 0.1:
		fwd = global_transform.basis.y
		fwd.y = 0.0
	fwd = fwd.normalized()
	freeze = false
	_parked_t = 0.0
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), global_position + Vector3.UP * 1.6)
	reset_physics_interpolation()


# --- systems -------------------------------------------------------------------

func toggle_engine() -> void:
	if engine_on:
		engine_on = false
		return
	if battery < 0.05 or fuel <= 0.0:
		return
	engine_on = true
	temp = maxf(temp, TEMP_AMBIENT + 1.0)


func set_headlights(on: bool) -> void:
	headlights_on = on
	for l in _headlight_nodes:
		l.visible = on and battery > 0.02
