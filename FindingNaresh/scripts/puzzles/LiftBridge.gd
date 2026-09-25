class_name LiftBridge
extends Node3D

## W6, the lift bridge (design/WAY_OUT.md, design/PUZZLES.md). The middle of
## the old bridge is a bascule leaf, stuck up at 70 degrees. It is worked
## from the control hut on the near bank (powered by the water works, D8);
## its gear and counterweight are in the machinery house on the other side of
## the road, which the hut can't see into, except in the safety mirror
## outside the hut window.
##
## 1. A wedge is jammed in the gear. It only comes out while the operator
##    holds RAISE (the gear backs off it) and the deck player pulls it (hold E).
## 2. The counterweight is short a block, so the leaf is nose-heavy: lowered
##    past 30 degrees with nobody on the counterweight it runs away and the
##    safety cut-out hauls it back up to 45. The counterweight rises out of
##    its pit as the leaf comes down; the operator stops it level with the
##    floor ("now!"), the deck player steps on, and with their weight on it
##    the leaf comes all the way down and locks. The barriers come away.

const UP_DEG := 70.0
const SPEED := 5.0               ## deg/s with a lever held
const CUT_OUT_DEG := 30.0        ## below this the leaf needs the rider's weight
const RESET_DEG := 45.0          ## where the cut-out hauls it back to
const PULL_S := 2.5              ## s of pulling to get the wedge out
const CW_LOW := -2.3             ## counterweight centre height (local) with the leaf up
const CW_HIGH := 1.6             ## ... and with it down
const CW_SIZE := Vector3(1.8, 1.0, 2.0)
const STEP_OK := 0.3             ## counterweight top within this of the floor: you can step on

var angle := UP_DEG
var jammed := true
var locked := false
var cut_outs := 0
var pull_work := 0.0
var lowering := false            ## LOWER held this tick
var raising := false             ## RAISE held this tick
var backed_off := false          ## RAISE held recently: the gear is off the wedge
var _lower_t := 0.0
var _raise_t := 0.0
var _pull_idle := 0.0
var _resetting := false
var _strain_said := false
var _hint_said := false
var m := 1.0                     ## local X side of the machinery house (the hut is on -m)
var leaf_len := 10.0
var deck_w := 8.6
var line: PowerLine
var barriers: Node3D
var leaf: AnimatableBody3D
var counterweight: AnimatableBody3D
var gear: Node3D
var wedge: Node3D
var panel_label: Label3D
var _mirror_view: SubViewport
var _mirror_cam: Camera3D
var _mirror_frame := 0
var _hum: NoiseLoop
var _hut_at := Vector3.ZERO


## `xf`: the pivot on the road's centre line, deck top; -Z towards the far
## bank. `machinery_side`: +1 or -1, the local X side away from the hut.
## `panel_xf` and `mirror_xf` are global: the lever panel inside the hut
## window and the safety mirror just outside it (+Z of each faces the operator).
func setup(xf: Transform3D, length: float, width: float, machinery_side: float, panel_xf: Transform3D, mirror_xf: Transform3D, power: PowerLine, barrier_root: Node3D) -> void:
	add_to_group("lift_bridge")
	transform = xf
	leaf_len = length
	deck_w = width
	m = machinery_side
	line = power
	barriers = barrier_root
	_hut_at = panel_xf.origin
	_build_leaf()
	_build_machinery_house()
	_build_panel(panel_xf)
	_build_mirror(mirror_xf)
	_apply()


# --- building ------------------------------------------------------------------

func _build_leaf() -> void:
	var wood := ToonMat.make(Color(0.46, 0.34, 0.24), 0.012)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	leaf = AnimatableBody3D.new()
	leaf.name = "Leaf"
	leaf.sync_to_physics = true
	add_child(leaf)
	var deck := Vector3(deck_w, 0.3, leaf_len)
	leaf.add_child(Build.box(deck, wood, Vector3(0, -0.15, -leaf_len * 0.5), Vector3.ZERO, "LeafDeck"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = deck
	cs.shape = sh
	cs.position = Vector3(0, -0.15, -leaf_len * 0.5)
	leaf.add_child(cs)
	# steel edges and a stripe at the nose, so the leaf reads as a moving part
	for sx in [-1.0, 1.0]:
		leaf.add_child(Build.box(Vector3(0.25, 0.5, leaf_len), steel, Vector3(sx * (deck_w * 0.5 - 0.12), 0.1, -leaf_len * 0.5), Vector3.ZERO, "LeafGirder"))
	leaf.add_child(Build.box(Vector3(deck_w, 0.06, 0.6), ToonMat.make(Color(0.95, 0.75, 0.15)), Vector3(0, 0.03, -leaf_len + 0.3), Vector3.ZERO, "NoseStripe"))
	# the axle, out to the machinery house
	add_child(Build.cyl(0.2, deck_w * 0.5 + 3.4, steel, Vector3(m * (deck_w * 0.5 + 3.4) * 0.5, -0.4, 0), Vector3(0, 0, 90), 10, "Axle"))


func _build_machinery_house() -> void:
	var wall := ToonMat.make(Color(0.56, 0.54, 0.50))
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	var inner := deck_w * 0.5 + 0.3          # the house's wall on the road side
	var outer := inner + 3.4
	var cx := m * (inner + outer) * 0.5
	const Z0 := -1.2
	const Z1 := 5.0
	const H := 4.6
	var house := Node3D.new()
	house.name = "MachineryHouse"
	add_child(house)
	# floor with the counterweight pit cut out of it
	var pit_x := Vector2(m * (inner + 0.1), m * (inner + 0.1 + CW_SIZE.x))
	var px0 := minf(pit_x.x, pit_x.y)
	var px1 := maxf(pit_x.x, pit_x.y)
	var pz0 := 1.6
	var pz1 := pz0 + CW_SIZE.z
	var fx0 := minf(m * inner, m * outer)
	var fx1 := maxf(m * inner, m * outer)
	for r in [Rect2(fx0, Z0, fx1 - fx0, pz0 - Z0), Rect2(fx0, pz1, fx1 - fx0, Z1 - pz1),
			Rect2(fx0, pz0, px0 - fx0, pz1 - pz0), Rect2(px1, pz0, fx1 - px1, pz1 - pz0)]:
		if r.size.x > 0.01 and r.size.y > 0.01:
			house.add_child(Build.solid_box(Vector3(r.size.x, 0.2, r.size.y), ToonMat.make(Color(0.48, 0.47, 0.45)), Vector3(r.position.x + r.size.x * 0.5, -0.1, r.position.y + r.size.y * 0.5), Vector3.ZERO, "HouseFloor"))
	# walls: back (hut side of the river, +Z), outer, and the road side with a
	# door from the deck; the river end (-Z) is open over the water
	house.add_child(Build.solid_box(Vector3(fx1 - fx0, H, 0.2), wall, Vector3(cx, H * 0.5, Z1), Vector3.ZERO, "HouseBack"))
	house.add_child(Build.solid_box(Vector3(0.2, H, Z1 - Z0), wall, Vector3(m * outer, H * 0.5, (Z0 + Z1) * 0.5), Vector3.ZERO, "HouseOuter"))
	const DOOR := Vector2(-0.2, 1.4)          # z range of the door from the deck
	house.add_child(Build.solid_box(Vector3(0.2, H, DOOR.x - Z0), wall, Vector3(m * inner, H * 0.5, (Z0 + DOOR.x) * 0.5), Vector3.ZERO, "HouseInnerA"))
	house.add_child(Build.solid_box(Vector3(0.2, H, Z1 - DOOR.y), wall, Vector3(m * inner, H * 0.5, (DOOR.y + Z1) * 0.5), Vector3.ZERO, "HouseInnerB"))
	house.add_child(Build.solid_box(Vector3(0.2, H - 2.4, DOOR.y - DOOR.x), wall, Vector3(m * inner, 2.4 + (H - 2.4) * 0.5, (DOOR.x + DOOR.y) * 0.5), Vector3.ZERO, "HouseDoorHead"))
	house.add_child(Build.solid_box(Vector3(fx1 - fx0 + 0.4, 0.2, Z1 - Z0 + 0.4), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(cx, H + 0.1, (Z0 + Z1) * 0.5), Vector3.ZERO, "HouseRoof"))
	house.add_child(Build.label3d("MACHINERY", Vector3(m * (inner - 0.12), 2.9, 0.6), Vector3(0, -90 * m, 0), 0.22, Color(0.95, 0.92, 0.8)))
	# the gear on the axle by the outer wall, a pinion above it, the wedge between
	gear = Node3D.new()
	gear.name = "Gear"
	gear.position = Vector3(m * (outer - 0.5), -0.4, 0)
	house.add_child(gear)
	gear.add_child(Build.cyl(1.25, 0.25, steel, Vector3.ZERO, Vector3(0, 0, 90), 20, "GearDisc"))
	for k in 18:
		var a := TAU * k / 18.0
		var tooth := Build.box(Vector3(0.25, 0.3, 0.22), steel, Vector3(0, sin(a) * 1.35, cos(a) * 1.35), Vector3.ZERO, "Tooth")
		tooth.rotation.x = PI * 0.5 - a
		gear.add_child(tooth)
	gear.add_child(Build.box(Vector3(0.27, 1.1, 0.14), ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 0.55, 0), Vector3.ZERO, "Mark"))
	house.add_child(Build.cyl(0.35, 0.3, steel, Vector3(m * (outer - 0.5), -0.4 + 1.25 + 0.4, -0.9), Vector3(0, 0, 90), 12, "Pinion"))
	wedge = Node3D.new()
	wedge.name = "Wedge"
	wedge.position = Vector3(m * (outer - 0.75), 1.05, -0.55)
	house.add_child(wedge)
	wedge.add_child(Build.box(Vector3(0.12, 0.2, 0.9), ToonMat.make(Color(0.55, 0.42, 0.26)), Vector3.ZERO, Vector3(35, 0, 0), "Plank"))
	var wa := Build.interact_area(Vector3(0.9, 0.9, 1.2), Vector3.ZERO, "", func(_p): pass, "WedgeArea")
	wa.set_meta("tag_name", "the wedge")
	wa.set_meta("prompt_fn", func(_p) -> String: return "Hold to pull the wedge out" if jammed else "")
	wa.set_meta("blocked_fn", func() -> String:
		if not jammed:
			return ""
		return "" if backed_off else "Wedged tight: the gear is pressing on it. They need to back it off (RAISE)")
	wa.set_meta("hold_fn", func(p, dt: float): _pull(p, dt))
	wedge.add_child(wa)
	# the counterweight: concrete in the pit, with a gap where a block fell off
	counterweight = AnimatableBody3D.new()
	counterweight.name = "Counterweight"
	counterweight.sync_to_physics = true
	counterweight.position = Vector3((px0 + px1) * 0.5, CW_LOW, (pz0 + pz1) * 0.5)
	house.add_child(counterweight)
	var cw_size := CW_SIZE - Vector3(0.1, 0, 0.1)
	counterweight.add_child(Build.box(cw_size, ToonMat.make(Color(0.62, 0.62, 0.60)), Vector3.ZERO, Vector3.ZERO, "Block"))
	counterweight.add_child(Build.box(Vector3(cw_size.x + 0.02, 0.08, 0.3), ToonMat.make(Color(0.95, 0.75, 0.15)), Vector3(0, CW_SIZE.y * 0.5 - 0.02, -cw_size.z * 0.5 + 0.15), Vector3.ZERO, "Stripe"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = cw_size
	cs.shape = sh
	counterweight.add_child(cs)
	counterweight.set_meta("tag_name", "the counterweight")
	# the fallen block, down in the pit
	house.add_child(Build.box(Vector3(0.8, 0.5, 0.8), ToonMat.make(Color(0.62, 0.62, 0.60)), Vector3((px0 + px1) * 0.5 + 0.3, -3.2, pz1 - 0.5), Vector3(0, 20, 8), "FallenBlock"))
	# a plate by the pit
	house.add_child(Build.label3d("COUNTERWEIGHT\n4 BLOCKS", Vector3(m * (inner + 0.12), 1.6, 3.4), Vector3(0, 90 * m, 0), 0.12, Color(0.95, 0.92, 0.8)))


func _build_panel(xf: Transform3D) -> void:
	var panel := Node3D.new()
	panel.name = "LeverPanel"
	panel.transform = transform.affine_inverse() * xf
	add_child(panel)
	var steel := ToonMat.make(Color(0.30, 0.34, 0.32))
	panel.add_child(Build.box(Vector3(1.2, 1.0, 0.4), steel, Vector3(0, 0.5, 0), Vector3.ZERO, "Desk"))
	panel_label = Build.label3d("", Vector3(0, 1.15, 0.05), Vector3(-30, 0, 0), 0.08, Color(0.95, 0.92, 0.8))
	panel.add_child(panel_label)
	for spec in [["RAISE", -0.3, Color(0.2, 0.5, 0.3)], ["LOWER", 0.3, Color(0.75, 0.2, 0.18)]]:
		var nm: String = spec[0]
		var x: float = spec[1]
		var col: Color = spec[2]
		panel.add_child(Build.cyl(0.03, 0.5, ToonMat.make(col), Vector3(x, 1.2, 0.0), Vector3(-20, 0, 0), 6, nm + "Handle"))
		panel.add_child(Build.label3d(nm, Vector3(x, 1.02, 0.21), Vector3.ZERO, 0.08, Color(0.95, 0.92, 0.8)))
		var a := Build.interact_area(Vector3(0.45, 0.7, 0.7), Vector3(x, 1.1, 0.1), "", func(_p): pass, nm + "Lever")
		a.set_meta("tag_name", "the %s lever" % nm.to_lower())
		a.set_meta("prompt_fn", func(_p) -> String: return "Hold: %s the bridge" % nm.to_lower())
		a.set_meta("blocked_fn", func() -> String:
			if line != null and not line.hut_powered:
				return "No power. The line from the water works is dead."
			return "The leaf is down and locked" if locked else "")
		if nm == "RAISE":
			a.set_meta("hold_fn", func(_p, _dt: float): _raise_t = 0.15)
		else:
			a.set_meta("hold_fn", func(_p, _dt: float): _lower_t = 0.15)
		panel.add_child(a)


## The safety mirror: a round glass outside the hut window showing the inside
## of the machinery house (the gear, the wedge and the counterweight pit).
func _build_mirror(xf: Transform3D) -> void:
	_mirror_view = SubViewport.new()
	_mirror_view.name = "SafetyMirrorView"
	_mirror_view.size = Vector2i(320, 320)
	_mirror_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_mirror_view.positional_shadow_atlas_size = 0
	add_child(_mirror_view)
	_mirror_cam = Camera3D.new()
	_mirror_cam.fov = 70.0
	_mirror_cam.near = 0.2
	_mirror_cam.far = 60.0
	_mirror_view.add_child(_mirror_cam)
	var mirror := Node3D.new()
	mirror.name = "SafetyMirror"
	mirror.transform = transform.affine_inverse() * xf
	add_child(mirror)
	var q := QuadMesh.new()
	q.size = Vector2(1.1, 1.1)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = _mirror_view.get_texture()
	mat.uv1_scale = Vector3(-1, 1, 1)
	mat.uv1_offset = Vector3(1, 0, 0)
	# round: a disc mesh would need UVs; a circular alpha cut in a shader is
	# overkill for a block-out, so a square glass in a round-ish frame
	var glass := MeshInstance3D.new()
	glass.name = "Glass"
	glass.mesh = q
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mirror.add_child(glass)
	var frame := ToonMat.make(Color(0.95, 0.75, 0.15), 0.01)
	for spec in [[Vector3(1.25, 0.08, 0.06), Vector3(0, 0.6, -0.02)], [Vector3(1.25, 0.08, 0.06), Vector3(0, -0.6, -0.02)],
			[Vector3(0.08, 1.25, 0.06), Vector3(0.6, 0, -0.02)], [Vector3(0.08, 1.25, 0.06), Vector3(-0.6, 0, -0.02)]]:
		mirror.add_child(Build.box(spec[0], frame, spec[1], Vector3.ZERO, "Frame"))
	mirror.add_child(Build.cyl(0.05, 2.6, ToonMat.make(Color(0.30, 0.32, 0.34)), Vector3(0, -1.9, -0.05), Vector3.ZERO, 6, "Post"))
	mirror.add_child(Build.label3d("SAFETY MIRROR", Vector3(0, 0.75, 0.01), Vector3.ZERO, 0.07, Color(0.15, 0.12, 0.1)))
	# the camera: up in the machinery house's back corner, looking at the gear and pit
	var inner := deck_w * 0.5 + 0.3
	var outer := inner + 3.4
	var cam_local := Vector3(m * (inner + 0.35), 2.6, 4.75)
	var look_local := Vector3(m * (outer - 0.9), 0.4, 0.0)
	_mirror_cam.set_meta("local", Transform3D(Basis.looking_at(look_local - cam_local, Vector3.UP), cam_local))


# --- running -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_raise_t -= delta
	_lower_t -= delta
	raising = _raise_t > 0.0 and not locked
	lowering = _lower_t > 0.0 and not locked and not raising
	backed_off = raising
	_pull_idle += delta
	if _pull_idle > 0.3:
		pull_work = 0.0
	if not locked:
		if _resetting:
			angle = move_toward(angle, RESET_DEG, SPEED * 2.0 * delta)
			if absf(angle - RESET_DEG) < 0.01:
				_resetting = false
		elif jammed:
			if lowering and not _strain_said:
				_strain_said = true
				_tell_near("The motor strains and the leaf shudders, but it won't come down. Something's jamming the gear in the machinery house - have a look in the safety mirror.", 7.0)
		elif lowering:
			angle = maxf(angle - SPEED * delta, 0.0)
			if angle < CUT_OUT_DEG and not rider_on():
				_cut_out()
			elif angle <= 0.0:
				_lock()
		elif raising:
			angle = minf(angle + SPEED * delta, UP_DEG)
	var moving := (lowering or raising or _resetting) and not locked
	if _hum == null:
		_hum = NoiseLoop.new()
		_hum.kind = NoiseLoop.Kind.HUM
		_hum.volume_db = -10.0
		_hum.position = Vector3(m * (deck_w * 0.5 + 2.0), 1.0, 1.0)
		add_child(_hum)
	_hum.target = 1.0 if moving else 0.0
	_hum.pitch = 1.0 + (0.6 if jammed and lowering else 0.2)
	_apply()


func _process(_delta: float) -> void:
	_update_mirror()
	_update_panel()


func _apply() -> void:
	var shake := 0.0
	if jammed and (lowering or raising):
		shake = sin(Time.get_ticks_msec() * 0.06) * 0.4
	var a := angle + shake + (0.8 if jammed and raising else 0.0)
	leaf.rotation = Vector3(deg_to_rad(a), 0, 0)
	gear.rotation.x = deg_to_rad(a * 2.0)
	var t := 1.0 - clampf(angle / UP_DEG, 0.0, 1.0)
	counterweight.position.y = lerpf(CW_LOW, CW_HIGH, t)


## The counterweight's top above the floor (m).
func counterweight_top() -> float:
	return counterweight.position.y + CW_SIZE.y * 0.5


func can_step_on() -> bool:
	return absf(counterweight_top()) <= STEP_OK


## Someone standing on the counterweight.
func rider_on() -> bool:
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null:
			continue
		var l := counterweight.global_transform.affine_inverse() * p.global_position
		if absf(l.x) < CW_SIZE.x * 0.5 + 0.1 and absf(l.z) < CW_SIZE.z * 0.5 + 0.1 and l.y > CW_SIZE.y * 0.5 - 0.15 and l.y < CW_SIZE.y * 0.5 + 0.6:
			return true
	return false


func _pull(p: PlayerRig, dt: float) -> void:
	if not jammed or not backed_off:
		return
	_pull_idle = 0.0
	if fmod(pull_work, 0.6) < dt:
		Sfx.play3d("hit_wood", wedge.global_position, -6.0)
	pull_work += dt
	if pull_work >= PULL_S:
		jammed = false
		pull_work = 0.0
		var tw := create_tween()
		tw.tween_property(wedge, "position", wedge.position + Vector3(0, -4.0, -1.5), 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func(): wedge.visible = false)
		Sfx.play3d("hit_wood_heavy", wedge.global_position, 0.0)
		_tell_near("The wedge comes free and drops into the river. The gear's clear.", 5.0)
		p.say("Got it out. Tell them to try lowering it.", 4.0)


func _cut_out() -> void:
	_resetting = true
	cut_outs += 1
	_lower_t = 0.0
	Sfx.play3d("bang", global_transform * Vector3(m * (deck_w * 0.5 + 2.0), 1.0, 1.0), 0.0)
	var extra := ""
	if not _hint_said:
		_hint_said = true
		extra = " The leaf is nose-heavy: the counterweight is short a block. Someone's weight on the counterweight would balance it - it comes up level with the machinery house floor on the way down."
	_tell_near("CLUNK - the safety cut-out trips: the leaf ran away and the motor hauls it back up." + extra, 9.0)


func _lock() -> void:
	locked = true
	angle = 0.0
	_apply()
	Sfx.play3d("hit_metal_heavy", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	Sfx.play3d("latch", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	_open_road()
	_tell_near("The leaf thumps down onto the far bank and the lock bolts shoot home. The road's open.", 7.0)
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["bridge_down"] = true


func _open_road() -> void:
	if barriers != null:
		barriers.visible = false
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", true)


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 80.0:
			q.say(text, secs)


func _update_panel() -> void:
	if panel_label == null:
		return
	var t: String
	if line != null and not line.hut_powered:
		t = "NO POWER"
	elif locked:
		t = "LEAF DOWN - LOCKED"
	elif _resetting:
		t = "CUT-OUT: OVERSPEED"
	else:
		t = "LEAF %d deg%s" % [roundi(angle), "  - JAMMED" if jammed and (lowering or raising) else ""]
	if panel_label.text != t:
		panel_label.text = t


## Like the van's mirrors: only drawn while someone is in or by the hut, and
## only every other frame.
func _update_mirror() -> void:
	var near := false
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(_hut_at) < 12.0:
			near = true
	if not near:
		_mirror_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	_mirror_frame += 1
	if _mirror_frame % 2 == 1:
		return
	_mirror_cam.global_transform = global_transform * (_mirror_cam.get_meta("local") as Transform3D)
	_mirror_view.render_target_update_mode = SubViewport.UPDATE_ONCE


# --- saving --------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"angle": angle, "jammed": jammed, "locked": locked, "cut_outs": cut_outs}


func from_dict(d: Dictionary) -> void:
	locked = bool(d.get("locked", false))
	jammed = bool(d.get("jammed", true)) and not locked
	angle = 0.0 if locked else float(d.get("angle", UP_DEG))
	cut_outs = int(d.get("cut_outs", 0))
	_resetting = false
	wedge.visible = jammed
	if not jammed:
		wedge.position.y = -10.0
	if barriers != null:
		barriers.visible = not locked
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).disabled = locked
	_apply()
