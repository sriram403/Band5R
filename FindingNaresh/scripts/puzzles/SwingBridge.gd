class_name SwingBridge
extends Node

## F5, the estuary bridge and R3 the three-hand swing bridge (design/RETURN.md).
## The bridge's middle span turns on its middle pier, and it stands swung
## open along the river. On the near bank: two cranks and a brake lever. The
## span only comes round while the brake is held off AND someone works a
## crank; let the brake go and the current swings it open again. One crank
## alone is slow; both, ~30 s. That's three pairs of hands: you two on the
## cranks, Naresh on the brake (V on the lever: Hold the brake). Once, half
## way, he lets go to wave at a boat; grab it (or tell him again) before it
## swings open. A tide gauge by the pier is the clock: at the red mark the
## current pulls twice as hard (no fail: it's harder, that's all). Closed,
## it bolts home and the road is open.
##
## State in the story's flags: "swing_locked", "swing_waved".

const OPEN_DEG := 90.0
const CRANK_RATE := 1.6               ## deg/s per crank turning (the brake held)
const DRIFT := 2.5                    ## deg/s it swings open, the brake let go
const TIDE_S := 240.0                 ## s from your arrival to the red mark
const GAP_HALF := 11.0                ## m: the swing span is twice this, over the middle pier
const WAVE_AFTER := 4.0               ## s of all three on it before he waves

var angle := OPEN_DEG
var locked := false
var tide := 0.0                       ## 0..1, the gauge (tests read)
var pivot := Vector3.ZERO
var span: AnimatableBody3D
var crank_a: Workable
var crank_b: Workable
var brake: Workable
var barriers: StaticBody3D
var panel: Label3D
var _fwd := Vector3.FORWARD
var _gauge_mark: Node3D
var _wheels: Array[Node3D] = []
var _story: Story
var _tide_on := false
var _all_t := 0.0
var _hum: NoiseLoop


## `road` crosses the river; `mid` is the index of the middle pier.
func setup(b, road: Route, mid: int) -> void:
	add_to_group("swing_bridge")
	pivot = road.point(mid)
	_fwd = road.forward(mid)
	_fwd.y = 0.0
	_fwd = _fwd.normalized()
	var right := Vector3.UP.cross(-_fwd).normalized()
	if right.dot(road.right(mid)) < 0.0:
		right = -right
	var deck := ToonMat.make(Color(0.62, 0.62, 0.60), 0.012)
	var steel := ToonMat.make(b.C_STEEL)
	var red := ToonMat.make(Color(0.80, 0.22, 0.18))
	# the swing span
	span = AnimatableBody3D.new()
	span.name = "SwingSpan"
	span.sync_to_physics = false
	b.world.add_child(span)
	span.position = pivot + Vector3.UP * 0.02          # (the world sits at the origin; not in the tree yet)
	var w := Landscape.ROAD_HALF * 2.0 + 1.0
	var l := GAP_HALF * 2.0 + 0.6
	span.add_child(Build.box(Vector3(w, 0.4, l), deck, Vector3.ZERO, Vector3.ZERO, "Deck"))
	span.add_child(b._box_shape(Vector3(w, 0.4, l), Transform3D.IDENTITY))
	for sd in [-1.0, 1.0]:
		var rp := Vector3(sd * (Landscape.ROAD_HALF + 0.35), 0.6, 0)
		span.add_child(Build.box(Vector3(0.15, 0.9, l), steel, rp, Vector3.ZERO, "Rail"))
		span.add_child(b._box_shape(Vector3(0.2, 1.0, l), Transform3D(Basis(), rp)))
	# the turntable drum on the pier
	b.world.add_child(Build.cyl(2.2, 0.6, steel, pivot + Vector3.DOWN * 0.45, Vector3.ZERO, 16, "Turntable"))
	# barriers at both ends of the gap until it's locked
	barriers = StaticBody3D.new()
	barriers.name = "SwingBarriers"
	b.world.add_child(barriers)
	for s in [-1.0, 1.0]:
		var at: Vector3 = pivot + _fwd * float(s) * (GAP_HALF + 2.0) + Vector3.UP * 0.9
		var bx := Transform3D(Basis.looking_at(_fwd, Vector3.UP), at)
		var bar := Build.box(Vector3(w, 0.25, 0.25), red)
		bar.transform = bx
		barriers.add_child(bar)
		barriers.add_child(b._box_shape(Vector3(w, 1.8, 0.4), bx))
	# the controls on the near bank (the van comes from the south: lower index)
	var near_i := mid
	while near_i > 0 and Landscape.over_river(road.point(near_i)):
		near_i -= 1
	var base := road.point(near_i - 4) + road.right(near_i - 4) * (Landscape.ROAD_HALF + 4.0)
	base.y = b._h(base.x, base.z)
	var face := Basis.looking_at(Vector3(pivot.x - base.x, 0, pivot.z - base.z).normalized(), Vector3.UP)
	var along := face.x
	crank_a = _crank(b, "CrankA", base - along * 3.0, face, steel)
	crank_b = _crank(b, "CrankB", base, face, steel)
	brake = _lever(b, base + along * 3.0, face, red, steel)
	panel = Build.label3d("SWING BRIDGE", base + Vector3.UP * 2.2 - along * 1.5, Vector3.ZERO, 0.12, Color(1, 0.95, 0.8))
	panel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	b.world.add_child(panel)
	b.poi["swing_controls"] = base
	b.poi["swing_crank_a"] = crank_a.position
	b.poi["swing_crank_b"] = crank_b.position
	b.poi["swing_brake"] = brake.position
	b.poi["swing_near"] = road.point(near_i - 10)
	# the tide gauge by the pier: a white post, a red band near the top, a float
	var gp := pivot + right * 6.0
	gp.y = Landscape.SEA_Y - 1.0
	var gauge := Node3D.new()
	gauge.name = "TideGauge"
	gauge.position = gp
	b.world.add_child(gauge)
	gauge.add_child(Build.box(Vector3(0.3, 6.0, 0.08), ToonMat.make(Color(0.95, 0.95, 0.92)), Vector3(0, 3.0, 0), Vector3.ZERO, "Post"))
	gauge.add_child(Build.box(Vector3(0.32, 0.5, 0.09), red, Vector3(0, 4.6, 0), Vector3.ZERO, "RedMark"))
	_gauge_mark = Build.box(Vector3(0.5, 0.15, 0.3), ToonMat.make(Color(0.95, 0.75, 0.2)), Vector3(0, 1.6, 0), Vector3.ZERO, "Float")
	gauge.add_child(_gauge_mark)
	b.poi["tide_gauge"] = gp + Vector3.UP * 3.0
	_apply()


func _crank(b, nm: String, at: Vector3, face: Basis, steel: Material) -> Workable:
	var c := Workable.new()
	c.name = nm
	c.kind = "hold"
	c.label = "crank"
	c.verb = "turn"
	c.work_s = 0.4
	c.close_s = 0.3
	c.stand = Vector3(0, 0, 1.0)
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	c.add_child(wheel)
	wheel.add_child(Build.cyl(0.4, 0.06, steel, Vector3.ZERO, Vector3(90, 0, 0), 14, "Rim"))
	wheel.add_child(Build.box(Vector3(0.06, 0.06, 0.35), ToonMat.make(Color(0.9, 0.7, 0.2)), Vector3(0.34, 0, 0.17), Vector3.ZERO, "Knob"))
	c.add_child(Build.box(Vector3(0.3, 1.0, 0.3), steel, Vector3(0, -0.5, -0.1), Vector3.ZERO, "Post"))
	c.add_child(b._box_shape(Vector3(0.8, 1.9, 0.5), Transform3D(Basis(), Vector3(0, -0.1, 0))))
	c.position = at + Vector3.UP * 1.0
	c.basis = face
	c.set_meta("tag_name", "a crank")
	b.world.add_child(c)
	_wheels.append(wheel)
	return c


func _lever(b, at: Vector3, face: Basis, red: Material, steel: Material) -> Workable:
	var lv := Workable.new()
	lv.name = "SwingBrake"
	lv.kind = "hold"
	lv.label = "brake"
	lv.verb = "hold off"
	lv.work_s = 0.5
	lv.close_s = 0.3
	lv.stand = Vector3(0, 0, 0.9)
	var arm := Node3D.new()
	arm.name = "Arm"
	lv.add_child(arm)
	arm.add_child(Build.box(Vector3(0.08, 1.0, 0.08), red, Vector3(0, 0.5, 0), Vector3.ZERO, "Handle"))
	lv.add_child(Build.box(Vector3(0.4, 1.0, 0.3), steel, Vector3(0, -0.5, 0), Vector3.ZERO, "Post"))
	lv.add_child(b._box_shape(Vector3(0.5, 1.9, 0.5), Transform3D(Basis(), Vector3(0, 0, 0))))
	lv.on_amount = func(a: float): arm.rotation.x = deg_to_rad(-65.0) * a
	lv.position = at + Vector3.UP * 1.0
	lv.basis = face
	lv.set_meta("tag_name", "the brake lever")
	b.world.add_child(lv)
	return lv


# --- running it ----------------------------------------------------------------------------

func brake_off() -> bool:
	return brake.holding_now() and brake.amount > 0.6


func cranks_turning() -> int:
	return int(crank_a.holding_now()) + int(crank_b.holding_now())


func _physics_process(delta: float) -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
		match_story()
	if locked:
		return
	var boot := get_tree().current_scene
	var van: Camper = boot.get("camper")
	if van != null and not _tide_on and van.global_position.distance_to(pivot) < 160.0 and _story.flags.has("storm_on"):
		_tide_on = true
	if _tide_on:
		var was := tide
		tide = minf(1.0, tide + delta / TIDE_S)
		if was < 1.0 and tide >= 1.0:
			_tell_near("The float on the tide gauge has reached the red mark. The current's pulling the span open harder now.", 6.0)
	var drift := DRIFT * (2.0 if tide >= 1.0 else 1.0)
	var moving := false
	if brake_off():
		var n := cranks_turning()
		if n > 0:
			angle = maxf(0.0, angle - CRANK_RATE * float(n) * delta)
			moving = true
	else:
		if angle < OPEN_DEG:
			angle = minf(OPEN_DEG, angle + drift * delta)
			moving = true
	if _hum == null:
		_hum = NoiseLoop.new()
		_hum.kind = NoiseLoop.Kind.HUM
		_hum.volume_db = -12.0
		add_child(_hum)
		_hum.global_position = pivot
	_hum.target = 0.7 if moving else 0.0
	_naresh_waves(delta, boot)
	if angle <= 0.0:
		_lock(true)
	_apply()


## Once, with all three on it and the span half way: he lets go to wave.
func _naresh_waves(delta: float, boot: Node) -> void:
	if _story.flags.has("swing_waved"):
		return
	var nz: Naresh = boot.get("naresh")
	if nz == null or not is_instance_valid(nz):
		return
	var his := nz.state == Naresh.State.JOB and nz.job == "hold" and nz.job_target == brake
	if his and cranks_turning() == 2 and angle < 60.0:
		_all_t += delta
		if _all_t >= WAVE_AFTER:
			_story.flags["swing_waved"] = true
			nz.command(nz.job_for, "wait")
			brake.release_by(nz)
			nz.say("Ooh, a boat! HELLO! ... Oh. Was I holding something?")
	else:
		_all_t = 0.0


func _lock(tell: bool) -> void:
	locked = true
	angle = 0.0
	_apply()          # put it there now: locked from a load or a script it never moved otherwise
	_story.flags["swing_locked"] = true
	barriers.visible = false
	for c in barriers.find_children("*", "CollisionShape3D", true, false):
		(c as CollisionShape3D).set_deferred("disabled", true)
	if tell:
		Sfx.play3d("hit_metal_heavy", pivot, 2.0)
		Sfx.play3d("latch", pivot, 0.0)
		_tell_near("The span swings home against the far end and the bolts drop. The road north is open.", 6.0)
		var nz: Naresh = get_tree().current_scene.get("naresh")
		if nz != null and is_instance_valid(nz) and nz.state == Naresh.State.JOB and nz.job_target == brake:
			nz.command(nz.job_for, "follow")


func _apply() -> void:
	if span == null:
		return
	span.transform = Transform3D(Basis.looking_at(_fwd, Vector3.UP).rotated(Vector3.UP, deg_to_rad(angle)), pivot + Vector3.UP * 0.02)
	for wl in _wheels:
		wl.rotation.z = -deg_to_rad(OPEN_DEG - angle) * 6.0
	if _gauge_mark != null:
		_gauge_mark.position.y = lerpf(1.6, 4.6, tide)
	if panel != null:
		var t := "SWING BRIDGE\nLOCKED" if locked else "SWING BRIDGE  %d deg\nBRAKE %s" % [roundi(angle), "OFF" if brake_off() else "ON"]
		if panel.text != t:
			panel.text = t


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(pivot) < 120.0:
			q.say(text, secs)


## After a load or a story jump.
func match_story() -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
	if _story == null:
		return
	if _story.flags.has("swing_locked"):
		if not locked:
			_lock(false)
	else:
		locked = false
		angle = OPEN_DEG
		tide = 0.0
		_tide_on = false
		barriers.visible = true
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", false)
	_apply()
