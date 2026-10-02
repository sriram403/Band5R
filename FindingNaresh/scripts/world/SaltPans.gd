class_name SaltPans
extends Node

## F4, the salt pans and R2 "red light, green light" (design/RETURN.md).
## The coast road crosses open salt flats. On an old salt-works gantry in the
## middle of the pans a creature stands watch: its gaze is a pale beam that
## stares one way for a few seconds, then turns to the next, back and forth
## across the road. White salt heaps line the road's seaward side; behind one
## the van is hidden. In the beam while moving, the van is seen at once;
## stopped in the open, after STILL_SEEN s (not under the tarp). Seen, the
## creature climbs down and comes for the van (VanAttack); drive away and it
## gives up. Naresh, in the back, calls out when it turns your way, but only
## right about two times in three.
##
## State in the story's flags: "pans_seen" (it saw the van), "pans_crossed".

const GANTRY_H := 6.0
const HOLD := 3.0                       ## s it stares one way
const TURN := 1.3                       ## s to turn to the next
## Where it stares, in order, degrees from straight at the road; 180 is out
## to sea (its back to the road: the green light), and it stares there longer.
const AIMS := [-45.0, -15.0, 15.0, 45.0, 180.0, 45.0, 15.0, -15.0, -45.0, 180.0]
const SEA_HOLD := 4.5
const BEAM := 9.0                       ## half-angle, degrees
const RANGE := 165.0
const STILL_SEEN := 2.5                 ## s in the beam, stopped in the open
const CORNER := 25.0                    ## degrees: something moving in the open this near its gaze catches its eye
const SNAP := 0.5                       ## s to turn and stare at it
const MOVING := 1.0                     ## m/s: faster than this is moving
const HEAP_EVERY := 34.0                ## m along the road
const HEAP_OFF := 6.8                   ## m off the road's middle, on the gantry's side
const HEAP_R := 5.4
const HEAP_H := 5.0
const SPAN := 150.0                     ## m of road either side of the pans' middle that is open ground

var centre := Vector3.ZERO
var eye := Vector3.ZERO                 ## the creature's eyes up on the gantry
var watcher: Creature
var gaze := 0.0                         ## radians, world yaw of the beam now (tests)
var seen := false                       ## it saw the van (tests)
var auto_sweep := true                  ## tests hold its gaze still
var glances := 0                        ## times movement caught its eye (tests)
var in_beam_s := 0.0
var heaps: Array[Vector3] = []
var road_start := Vector3.ZERO          ## the open ground, south end (the van comes from here)
var road_end := Vector3.ZERO
var _base := 0.0                        ## yaw from the gantry straight at the road
var _seq := 0
var _t := 0.0
var _from := 0.0
var _to := 0.0
var _turn_now := TURN
var _beam: MeshInstance3D
var _beam_mat: StandardMaterial3D
var _story: Story
var _call_seq := -1
var _rng := RandomNumberGenerator.new()


func setup(b) -> void:
	add_to_group("salt_pans")
	_rng.seed = 2207
	centre = LevelBuilder.SALT_PANS
	centre.y = b._h(centre.x, centre.z)
	_gantry(b)
	_heaps(b)


func _gantry(b) -> void:
	var wood := ToonMat.make(Color(0.40, 0.32, 0.25), 0.02)
	var body := StaticBody3D.new()
	body.name = "SaltGantry"
	body.position = centre
	b.world.add_child(body)
	for sx in [-1.5, 1.5]:
		for sz in [-1.5, 1.5]:
			body.add_child(Build.box(Vector3(0.25, GANTRY_H, 0.25), wood, Vector3(sx, GANTRY_H * 0.5, sz), Vector3.ZERO, "Leg"))
			body.add_child(b._box_shape(Vector3(0.25, GANTRY_H, 0.25), Transform3D(Basis(), Vector3(sx, GANTRY_H * 0.5, sz))))
	var deck := Vector3(4.0, 0.25, 4.0)
	body.add_child(Build.box(deck, wood, Vector3(0, GANTRY_H, 0), Vector3.ZERO, "Deck"))
	body.add_child(b._box_shape(deck, Transform3D(Basis(), Vector3(0, GANTRY_H, 0))))
	# an old hopper chute down to the pans, so it reads as salt works
	body.add_child(Build.box(Vector3(0.9, 0.9, 5.0), ToonMat.make(Color(0.55, 0.52, 0.48)), Vector3(0, GANTRY_H - 1.6, 3.6), Vector3(-25, 0, 0), "Chute"))
	b.poi["salt_gantry"] = centre + Vector3(0, GANTRY_H, 0)
	# the road: which way it lies from here
	var road: Route = b.network.road("coast_road")
	var near: Dictionary = road.nearest(centre.x, centre.z)
	var at := road.point(int(near["index"]))
	_base = atan2(-(at.x - centre.x), -(at.z - centre.z))
	gaze = _base
	_from = _base
	_to = _base
	# the watcher, standing on the deck
	watcher = Creature.new()
	watcher.name = "SaltWatcher"
	watcher.passive = true
	b.world.add_child(watcher)
	watcher.position = centre + Vector3(0, GANTRY_H + 0.15, 0)
	watcher.rotation.y = _base
	eye = watcher.position + Vector3.UP * (Creature.HEIGHT - 0.27)
	# its gaze: a long pale cone from its eyes
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_mat.albedo_color = Color(0.85, 0.9, 0.7, 0.07)
	var cone := CylinderMesh.new()
	cone.top_radius = 0.15
	cone.bottom_radius = tan(deg_to_rad(BEAM)) * RANGE * 0.6
	cone.height = RANGE * 0.6
	cone.radial_segments = 16
	cone.cap_top = false
	cone.cap_bottom = false
	_beam = Build.node(cone, _beam_mat, Transform3D.IDENTITY, "Gaze")
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(_beam)
	_aim_beam()
	# the open ground's ends along the road
	var k0 := -1
	var k1 := -1
	for i in road.point_count():
		var q := road.point(i)
		var d := Vector2(q.x - centre.x, q.z - centre.z).length()
		if d < SPAN:
			if k0 < 0:
				k0 = i
			k1 = i
	road_start = road.point(k0)
	road_end = road.point(k1)
	b.poi["salt_pans_start"] = road_start
	b.poi["salt_pans_end"] = road_end


## Salt heaps every HEAP_EVERY m along the open stretch, between the road and
## the gantry.
func _heaps(b) -> void:
	var road: Route = b.network.road("coast_road")
	var salt := ToonMat.make(Color(0.94, 0.94, 0.91), 0.0)
	var body := StaticBody3D.new()
	body.name = "SaltHeaps"
	b.world.add_child(body)
	var i0 := int(road.nearest(road_start.x, road_start.z)["index"])
	var i1 := int(road.nearest(road_end.x, road_end.z)["index"])
	var step := maxi(1, int(round(HEAP_EVERY / maxf(road.point(i0).distance_to(road.point(i0 + 1)), 0.1))))
	var i := i0 + step / 2
	while i <= i1 + step:              # one past the end: cover right to the last of the open ground
		var p := road.point(i)
		var right := road.right(i)
		var side := signf(right.dot(centre - p))       # towards the gantry
		var at := p + right * side * HEAP_OFF
		at.y = b._h(at.x, at.z) - 0.2
		var cone := CylinderMesh.new()
		cone.top_radius = 0.4
		cone.bottom_radius = HEAP_R
		cone.height = HEAP_H
		cone.radial_segments = 14
		body.add_child(Build.node(cone, salt, Transform3D(Basis(), at + Vector3(0, HEAP_H * 0.5, 0)), "Heap"))
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = HEAP_R * 0.8
		cyl.height = HEAP_H
		cs.shape = cyl
		cs.position = at + Vector3(0, HEAP_H * 0.5, 0)
		body.add_child(cs)
		heaps.append(at)
		i += step
	b.poi["salt_heap_first"] = heaps[0] if not heaps.is_empty() else road_start


# --- the watch -------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
		match_story()
	if seen or not _story.flags.has("storm_on"):
		return
	_sweep(delta)
	var van: Camper = get_tree().current_scene.get("camper")
	if van == null:
		return
	var vis := van_in_view(van)
	var moving := Vector2(van.linear_velocity.x, van.linear_velocity.z).length() > MOVING
	if moving and not vis and auto_sweep and _off_gaze(van) < CORNER and not _hidden(van):
		_glance(van)
	if vis and (moving or not van.attack.tarped):
		in_beam_s += delta
		if (moving and in_beam_s > 0.35) or in_beam_s > STILL_SEEN:
			_seen(van)
	else:
		in_beam_s = maxf(0.0, in_beam_s - delta * 2.0)
	_naresh_calls(van)
	if not _story.flags.has("pans_crossed") and _past_end(van):
		_story.flags["pans_crossed"] = true


func _sweep(delta: float) -> void:
	if not auto_sweep:
		watcher.rotation.y = gaze
		_aim_beam()
		return
	_t += delta
	if _t > _hold_now() + _turn_now:
		_t = 0.0
		_seq += 1
		_from = _to
		_to = _aim(_seq)
		_turn_now = TURN * clampf(absf(angle_difference(_from, _to)) / deg_to_rad(60.0), 1.0, 2.0)
	var f := clampf(_t / _turn_now, 0.0, 1.0)
	gaze = lerp_angle(_from, _to, smoothstep(0.0, 1.0, f))
	watcher.rotation.y = gaze
	_aim_beam()


## Where it will stare after the current one (its pattern repeats: a player
## who watches learns it).
func next_aim() -> float:
	return _aim(_seq + 1)


func _aim(k: int) -> float:
	return _base + deg_to_rad(float(AIMS[k % AIMS.size()]))


## Looking out to sea now (its back to the road)?
func looking_away() -> bool:
	return float(AIMS[_seq % AIMS.size()]) > 90.0


func _hold_now() -> float:
	return SEA_HOLD if looking_away() else HOLD


## Degrees between its gaze and the van.
func _off_gaze(van: Camper) -> float:
	var to := van.global_position - eye
	return absf(rad_to_deg(Vector2(-sin(gaze), -cos(gaze)).angle_to(Vector2(to.x, to.z).normalized())))


## Movement in the corner of its eye: it turns to stare at it, fast.
func _glance(van: Camper) -> void:
	var to := van.global_position - eye
	var want := atan2(-to.x, -to.z)
	if absf(angle_difference(_to, want)) < deg_to_rad(BEAM * 0.5):
		return
	_from = gaze
	_to = want
	_turn_now = TURN
	_t = TURN - SNAP          # the rest of a turn, then the full stare
	glances += 1


func _aim_beam() -> void:
	if _beam == null:
		return
	var dir := Vector3(-sin(gaze), -0.06, -cos(gaze)).normalized()
	var len := RANGE * 0.6
	# a cylinder stands along +Y: point its -Y (the wide end) along the gaze
	var b := Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(90))
	_beam.global_transform = Transform3D(b, eye + dir * len * 0.5)
	_beam.visible = not seen and (_story == null or _story.flags.has("storm_on"))


## Is the van inside its gaze and in plain view (no heap in the way)?
func van_in_view(van: Camper) -> bool:
	var to := van.global_position + Vector3.UP * 0.6 - eye
	var flat := Vector2(to.x, to.z)
	if flat.length() > RANGE:
		return false
	var dir := Vector2(-sin(gaze), -cos(gaze))
	if rad_to_deg(dir.angle_to(flat.normalized())) > BEAM or rad_to_deg(dir.angle_to(flat.normalized())) < -BEAM:
		return false
	var space := get_viewport().get_world_3d().direct_space_state
	var ex: Array[RID] = [watcher.get_rid()]
	# seen if its middle is: half behind a heap counts as hidden
	var q := PhysicsRayQueryParameters3D.create(eye, van.global_position + Vector3.UP * 1.0, 1, ex)
	return space.intersect_ray(q).is_empty()


func _seen(van: Camper) -> void:
	var near_heap := 999.0
	for h in heaps:
		near_heap = minf(near_heap, Vector2(h.x - van.global_position.x, h.z - van.global_position.z).length())
	print("[pans] seen: %.1f m/s, %.1f s in its gaze, %.0f m from it, nearest heap %.1f m, gaze off %.0f deg" % [
		Vector2(van.linear_velocity.x, van.linear_velocity.z).length(), in_beam_s, van.global_position.distance_to(eye), near_heap, _off_gaze(van)])
	seen = true
	_story.flags["pans_seen"] = true
	_beam.visible = false
	# down off the gantry, and it comes for the van
	var foot := centre + Vector3(0, 0.3, 3.5)
	foot.y = Landscape.ground(foot.x, foot.z) + 0.3
	watcher.global_position = foot
	watcher.reset_physics_interpolation()
	watcher.passive = false
	watcher.van_interest = 40.0
	Sfx.play3d("whoosh", eye, 4.0)
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say("The thing on the gantry has seen the van. It drops down and comes across the pans towards you. Go!", 6.0)


## Naresh in the back calls out as its gaze turns your way: right about two
## times in three.
func _naresh_calls(van: Camper) -> void:
	var nz: Naresh = get_tree().current_scene.get("naresh")
	if nz == null or not is_instance_valid(nz) or nz.state != Naresh.State.SEATED or _call_seq == _seq or _t > 0.3:
		return
	var to := van.global_position - eye
	var a := absf(rad_to_deg(Vector2(-sin(_to), -cos(_to)).angle_to(Vector2(to.x, to.z).normalized())))
	if a > 25.0 or van_in_view(van) == false and _hidden(van):
		return
	_call_seq = _seq
	if _rng.randf() < 0.67:
		nz.say("Stop! It's turning this way!")
	else:
		nz.say("Go, go! It's not looking!")


func _hidden(van: Camper) -> bool:
	return hidden_at(van.global_position)


## Would a van here be behind something (a heap) from its eyes?
func hidden_at(at: Vector3) -> bool:
	var space := get_viewport().get_world_3d().direct_space_state
	var ex: Array[RID] = [watcher.get_rid()]
	var van: Camper = get_tree().current_scene.get("camper")
	if van != null:
		ex.append(van.get_rid())
	var q := PhysicsRayQueryParameters3D.create(eye, at + Vector3.UP * 1.0, 1, ex)
	return not space.intersect_ray(q).is_empty()


func _past_end(van: Camper) -> bool:
	# past the far end, along the road's way north
	var along := (road_end - road_start)
	along.y = 0.0
	return (van.global_position - road_end).dot(along.normalized()) > 0.0


## After a load or a story jump.
func match_story() -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
	if _story == null:
		return
	if _story.flags.has("pans_seen") and not seen:
		seen = true
		watcher.passive = false
		var foot := centre + Vector3(0, 0.3, 3.5)
		foot.y = Landscape.ground(foot.x, foot.z) + 0.3
		watcher.global_position = foot
	elif not _story.flags.has("pans_seen") and seen:
		seen = false
		watcher.passive = true
		watcher.van_interest = 0.0
		watcher.global_position = centre + Vector3(0, GANTRY_H + 0.15, 0)
		watcher.reset_physics_interpolation()
	in_beam_s = 0.0
	# its pattern from the start (a jump plays the same every time)
	_seq = 0
	_t = 0.0
	_from = _base
	_to = _base
	_turn_now = TURN
	gaze = _base
	auto_sweep = true
	_aim_beam()
