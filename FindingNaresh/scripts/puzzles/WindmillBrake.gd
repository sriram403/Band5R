class_name WindmillBrake
extends Node3D

## W1, the windmill brake (design/WAY_OUT.md, design/PUZZLES.md). A rope is
## snagged round one blade and the mill is braked. One player climbs the
## tower to the platform under the hub and tags the snagged blade; the other
## works the brake lever at the foot. With the brake off the jammed blades
## creep round; the lever player puts the brake on when the tagged blade is
## at the bottom, by the platform, and the climber cuts the rope (hold E).
## Freed, the blades spin up and the miller's box at the foot opens: inside,
## the map of this side of the valley (both roads to Last Fuel drawn in).

const SNAG := 4                  ## which of the 12 blades is snagged
const CREEP := 0.32              ## rad/s: the jammed blades with the brake off
const SPIN := 1.4                ## rad/s: free, with the brake off
const BRAKE := 1.6               ## rad/s² the brake takes off
const REACH_DEG := 16.0          ## the snagged blade within this of the bottom is in reach
const CUT_S := 2.0
const OPEN_AFTER := 3.0          ## s of free spinning before the box opens

var rotor: Node3D
var brake_on := true
var snagged := true
var angle := 0.0                 ## rotor angle, rad (blade k points at angle + k * TAU / 12 from up)
var speed := 0.0
var box_open := false
var map_taken := false
var cut_work := 0.0
var _spun := 0.0
var _cut_idle := 0.0
var _creak_t := 0.0
var _lever: Node3D
var _lid: Node3D
var _rope: Node3D
var _map: Node3D


## Built by LevelLandmarks._windmill() under the windmill's root, after the rotor.
func setup(r: Node3D, lever_at: Vector3, box_at: Vector3) -> void:
	add_to_group("windmill_brake")
	rotor = r
	angle = deg_to_rad(-40.0)     # the snagged blade starts up at the side (80 deg), out of reach
	_build_blade_areas()
	_build_lever(lever_at)
	_build_box(box_at)
	_apply_angle()


func _process(delta: float) -> void:
	var want := 0.0 if brake_on else (CREEP if snagged else SPIN)
	var rate := BRAKE if want < speed else 0.6
	speed = move_toward(speed, want, rate * delta)
	angle = wrapf(angle + speed * delta, -PI, PI)
	_apply_angle()
	if snagged and speed > 0.05:
		_creak_t -= delta
		if _creak_t <= 0.0:
			_creak_t = 2.2
			Sfx.play3d("creak", global_position + Vector3.UP * 14.0, -6.0)
	if not snagged and not box_open and speed > SPIN * 0.8:
		_spun += delta
		if _spun >= OPEN_AFTER:
			_open_box()
	_cut_idle += delta
	if _cut_idle > 0.3:
		cut_work = 0.0


func _apply_angle() -> void:
	# the rotor spins about its local forward axis (-Z): a positive angle
	# turns the blades anticlockwise seen from the front
	rotor.rotation = Vector3(0, 0, angle)


## How far the snagged blade is from pointing straight down (degrees).
func snag_from_bottom() -> float:
	var a := angle + TAU * float(SNAG) / 12.0
	return absf(rad_to_deg(wrapf(a - PI, -PI, PI)))


func snag_in_reach() -> bool:
	return snagged and speed < 0.03 and snag_from_bottom() <= REACH_DEG


func set_brake(on: bool) -> void:
	if on == brake_on:
		return
	brake_on = on
	_lever.rotation.x = deg_to_rad(-35.0 if on else 35.0)
	Sfx.play3d("latch", _lever.global_position, -2.0)
	Sfx.play3d("creak", _lever.global_position, -8.0)


# --- building ------------------------------------------------------------------

func _build_blade_areas() -> void:
	# each blade gets a thin area: tags land on it (and follow it round); the
	# snagged one carries the rope and the cut
	var holders := rotor.get_children()
	for k in holders.size():
		var h := holders[k] as Node3D
		var a := Build.interact_area(Vector3(0.45, 2.3, 0.3), Vector3(0, 1.5, 0), "", func(_p): pass, "BladeArea")
		a.set_meta("tag_name", "the snagged blade" if k == SNAG else "a blade")
		a.set_meta("tag_follow", true)
		a.set_meta("prompt_fn", func(_p) -> String: return "")
		h.add_child(a)
		if k == SNAG:
			_rope = Node3D.new()
			_rope.name = "SnagRope"
			var rope := ToonMat.make(Color(0.55, 0.45, 0.28))
			for y in [1.9, 2.1, 2.3]:
				_rope.add_child(Build.box(Vector3(0.42, 0.06, 0.1), rope, Vector3(0, y, 0), Vector3(0, 0, 12), "Wrap"))
			_rope.add_child(Build.cyl(0.03, 1.8, rope, Vector3(0.18, 1.2, 0.06), Vector3(0, 0, -8), 5, "Tail"))
			h.add_child(_rope)
			a.set_meta("prompt_fn", func(_p) -> String:
				return "Hold to cut the rope" if snag_in_reach() else "")
			a.set_meta("blocked_fn", func() -> String:
				if not snagged:
					return ""
				if speed >= 0.03:
					return "It's turning - they need to put the brake on"
				return "" if snag_from_bottom() <= REACH_DEG else "Out of reach - it has to come down to the platform")
			a.set_meta("hold_fn", func(p, dt: float): _cut(p, dt))


func _build_lever(at: Vector3) -> void:
	var base := Node3D.new()
	base.name = "BrakeLever"
	base.position = at
	add_child(base)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34))
	base.add_child(Build.box(Vector3(0.5, 0.9, 0.5), steel, Vector3(0, 0.45, 0), Vector3.ZERO, "Stand"))
	_lever = Node3D.new()
	_lever.name = "Pivot"
	_lever.position = Vector3(0, 0.9, 0)
	_lever.rotation.x = deg_to_rad(-35.0)
	base.add_child(_lever)
	_lever.add_child(Build.cyl(0.04, 1.0, ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 0.5, 0), Vector3.ZERO, 6, "Handle"))
	base.add_child(Build.label3d("BRAKE\nup: on  -  down: off", Vector3(0, 1.3, 0.3), Vector3.ZERO, 0.14, Color(0.95, 0.92, 0.8)))
	var a := Build.interact_area(Vector3(0.8, 1.6, 0.8), Vector3(0, 0.9, 0), "", func(_p): set_brake(not brake_on), "LeverArea")
	a.set_meta("tag_name", "the brake lever")
	a.set_meta("prompt_fn", func(_p) -> String:
		return "Pull the brake on" if not brake_on else "Let the brake off")
	base.add_child(a)


func _build_box(at: Vector3) -> void:
	var box := Node3D.new()
	box.name = "MillersBox"
	box.position = at
	add_child(box)
	var wood := ToonMat.make(Color(0.48, 0.34, 0.22), 0.012)
	var body := StaticBody3D.new()
	box.add_child(body)
	box.add_child(Build.box(Vector3(1.0, 0.6, 0.7), wood, Vector3(0, 0.3, 0), Vector3.ZERO, "Chest"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.0, 0.6, 0.7)
	cs.shape = sh
	cs.position = Vector3(0, 0.3, 0)
	body.add_child(cs)
	# the lid sits just above the chest so the map can lie on top under it
	_lid = Node3D.new()
	_lid.name = "LidHinge"
	_lid.position = Vector3(0, 0.63, 0.35)
	box.add_child(_lid)
	_lid.add_child(Build.box(Vector3(1.02, 0.08, 0.72), wood, Vector3(0, 0.04, -0.36), Vector3.ZERO, "Lid"))
	# a rod from the mill's gearing holds the lid shut until the mill turns
	box.add_child(Build.label3d("MILLER'S BOX\nopens when the mill turns", Vector3(0, 0.35, -0.36), Vector3(0, 180, 0), 0.1, Color(0.95, 0.92, 0.8)))
	_map = Build.box(Vector3(0.4, 0.03, 0.3), ToonMat.make(Color(0.93, 0.88, 0.72)), Vector3(0, 0.612, -0.05), Vector3.ZERO, "ValleyMap")
	box.add_child(_map)
	var a := Build.interact_area(Vector3(1.1, 0.8, 0.8), Vector3(0, 0.5, 0), "", func(p): _take_map(p), "BoxArea")
	a.set_meta("tag_name", "the miller's box")
	a.set_meta("prompt_fn", func(_p) -> String:
		return "Take the map of the valley" if box_open and not map_taken else "")
	a.set_meta("blocked_fn", func() -> String:
		return "Locked. It opens when the mill turns" if not box_open else "")
	box.add_child(a)


# --- saving --------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"snagged": snagged, "brake_on": brake_on, "angle": angle, "box_open": box_open, "map_taken": map_taken}


func from_dict(d: Dictionary) -> void:
	snagged = bool(d.get("snagged", true))
	brake_on = bool(d.get("brake_on", true))
	angle = float(d.get("angle", angle))
	box_open = bool(d.get("box_open", false))
	map_taken = bool(d.get("map_taken", false))
	speed = 0.0
	_spun = 0.0
	_rope.visible = snagged
	_lever.rotation.x = deg_to_rad(-35.0 if brake_on else 35.0)
	_lid.rotation.x = deg_to_rad(105.0) if box_open else 0.0
	_map.visible = not map_taken
	_apply_angle()


# --- playing -------------------------------------------------------------------

func _cut(p: PlayerRig, dt: float) -> void:
	if not snag_in_reach():
		return
	_cut_idle = 0.0
	if fmod(cut_work, 0.5) < dt:
		Sfx.play3d("pluck", p.global_position + Vector3.UP * 1.4, -6.0)
	cut_work += dt
	if cut_work >= CUT_S:
		snagged = false
		cut_work = 0.0
		_rope.visible = false
		Sfx.play3d("hit_soft", p.global_position + Vector3.UP, -2.0)
		for n in get_tree().get_nodes_in_group("player"):
			var q := n as PlayerRig
			if q.global_position.distance_to(global_position) < 60.0:
				q.say("The rope drops away. The blades are free - let the brake off.", 5.0)


func _open_box() -> void:
	box_open = true
	var tw := create_tween()
	# positive about the hinge at the back swings the front edge up and over
	tw.tween_property(_lid, "rotation:x", deg_to_rad(105.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play3d("latch", _lid.global_position, 0.0)
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 60.0:
			q.say("Clunk: the miller's box at the foot of the tower has sprung open.", 5.0)


func _take_map(p: PlayerRig) -> void:
	if not box_open or map_taken:
		return
	map_taken = true
	_map.visible = false
	Sfx.play3d("paper_open", p.global_position + Vector3.UP, -2.0)
	var boot := get_tree().current_scene
	var ms = boot.get("map_state")
	if ms != null:
		ms.reveal_valley()
	var st = boot.get("story")
	if st != null:
		st.flags["windmill_map"] = true
	p.say("An old hand-drawn map of the valley: both roads to Last Fuel, the lake, the barn and the ridge lookout. It's on your paper map now.", 7.0)
