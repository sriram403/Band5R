class_name WindmillPower
extends Node3D

## Puzzle #2, the windmill (design/PUZZLE_CHANGES.md #2, agreed 2026-10-07).
## The junction gate at J1 has no power: the old windmill that fed it has
## stopped. One player holds the starter lever (hold E) and the fan winds up
## over SPIN_UP_S; let go early and it runs down twice as fast. As it speeds
## up the cracked footings let the legs walk: at 20, 40, 60 and 80 % one leg
## (random) starts sliding out, and the other player head-butts it back onto
## its footing (BUTTS butts from the start of the slide). A leg that slides
## all the way brings the windmill down on whoever is nearest; then it all
## starts again. At full speed the fan catches the wind (the lever can be let
## go), the gate opens, the street lamps beyond it light, and the shaking
## unrolls the rope ladder from the walkway. At the top: a chest with the
## napin, the one map pin (MapState.napin).

const HUB_Y := 24.0
const WALK_Y := 22.6             ## top of the walkway round the head
const NECK_R := 1.0
const NECK_FROM := 6.6
const COLLAR_Y := 7.0
const FOOT := 4.0                ## leg feet at (±FOOT, 0, ±FOOT): 8 m apart
const LEG_TOP := 1.25            ## leg tops at (±LEG_TOP, COLLAR_Y, ±LEG_TOP)
const FAN_R := 6.0
const BLADES := 18
const ROTOR_Z := -3.4            ## the fan in front of the head (local -Z faces the lane)
const LEVER_AT := Vector3(0, 0, -18.0)
const LADDER_Z := 2.45           ## the rope ladder hangs off the walkway's back edge

const SPIN_UP_S := 45.0          ## held, 0 -> full
const RUN_DOWN := 2.0            ## let go: it slows this many times faster
const FULL_SPIN := 2.4           ## rad/s of the fan at full speed
const SLIP_AT := [0.2, 0.4, 0.6, 0.8]
const SLIDE_S := 8.0             ## a leg left alone slides all the way in this
const SLIDE_M := 0.5
const BUTTS := 3                 ## butts to knock a leg back from the start of its slide
const LEAN_DEG := 5.0            ## lean of the whole windmill at a full slide
const FALL_WARN := 2.0           ## s of groaning before it goes
const FALL_S := 2.6              ## s from starting to fall to the ground
const RESET_AFTER := 3.0         ## s after it lands, the challenge starts again
const LADDER_AFTER := 5.0        ## s after catching the wind, the ladder shakes loose

var power := 0.0                 ## 0..1 the fan's speed
var caught := false              ## the wind has it: powered for good
var leg_slide := [0.0, 0.0, 0.0, 0.0]   ## 0..1 of SLIDE_M out
var leg_state := [0, 0, 0, 0]    ## 0 firm, 1 sliding, 2 butted back
var slips := 0                   ## slips started (one per SLIP_AT)
var reslip_chance := 0.25        ## S2: a butted leg may go again (tests set 0)
var spin_up := SPIN_UP_S         ## s held to full speed (quick tests shorten it)
var falling := false
var fall_t := 0.0
var fall_dir := Vector3.FORWARD  ## local, flat: the way it falls
var ladder_down := false
var chest_open := false
var napin_taken := false
var angle := 0.0
var rng := RandomNumberGenerator.new()
var lever_held := false

var tower: Node3D                ## everything that leans and falls
var rotor: Node3D
var gate: Node3D
var _legs: Array = []            ## AnimatableBody3D per leg
var _lever: Node3D
var _lever_t := 9.0              ## s since the lever's hold_fn last ran
var _reslip_t := [-1.0, -1.0, -1.0, -1.0]
var _reslipped := [false, false, false, false]
var _lean_ang := 0.0
var _lean_dir := Vector3.FORWARD
var _caught_t := 0.0
var _landed := false
var _reset_t := 0.0
var _creak_t := 0.0
var _fan_noise: NoiseLoop
var _hum: NoiseLoop
var _roll: Node3D                ## the rolled-up ladder on the walkway
var _ladder_hang: Node3D         ## the ladder's top: scaled from 0 to 1 as it unrolls
var _ladder: Ladder
var _lid: Node3D
var _napin_mesh: Node3D
var _boom: Node3D
var _boom_body: StaticBody3D
var _gate_lamp: MeshInstance3D
var _lamps: Array = []           ## [MeshInstance3D head, OmniLight3D]
var _lamp_off: Material
var _lamp_on: Material
var _lamp_t := -1.0
var _crushed: Array = []
var _viewed := false             ## someone has looked out from the walkway
var _wxf := Transform3D.IDENTITY   ## where it stands (set before it is in the tree)


## Built by LevelLandmarks._windmill(): this node is the windmill, at
## `xf` (world; its -Z faces the lane). The gate goes across the lane at
## `gate_xf` and the street lamps at `lamp_at`, both under `world` (world
## space).
func setup(xf: Transform3D, world: Node3D, gate_xf: Transform3D, fence_len: Array, lamp_at: Array) -> void:
	add_to_group("windmill")
	transform = xf
	_wxf = xf
	rng.randomize()
	_build_tower()
	_build_lever()
	_build_ladder()
	_build_chest()
	_build_gate(world, gate_xf, fence_len)
	_build_lamps(world, lamp_at)
	_fan_noise = NoiseLoop.new()
	_fan_noise.name = "FanWhoosh"
	_fan_noise.kind = NoiseLoop.Kind.WIND
	_fan_noise.volume_db = -4.0
	_fan_noise.position = Vector3(0, HUB_Y - 4.0, ROTOR_Z)
	tower.add_child(_fan_noise)
	_hum = NoiseLoop.new()
	_hum.name = "GearHum"
	_hum.kind = NoiseLoop.Kind.HUM
	_hum.volume_db = -14.0
	_hum.position = Vector3(0, COLLAR_Y, 0)
	tower.add_child(_hum)
	_show()


# --- the frame -----------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_lever_t += delta
	lever_held = _lever_t < 0.2 and not falling
	if falling:
		_fall(delta)
		_show()
		return
	if not caught:
		var all_back := slips == SLIP_AT.size() and not leg_state.has(0) and not leg_state.has(1) and not _reslip_pending()
		var cap := 1.0 if all_back else 0.97
		if lever_held:
			power = minf(power + delta / spin_up, cap)
		else:
			power = maxf(0.0, power - delta * RUN_DOWN / spin_up)
		if slips < SLIP_AT.size() and power >= SLIP_AT[slips] and not leg_state.has(1) and not _reslip_pending():
			var firm := []
			for k in 4:
				if leg_state[k] == 0:
					firm.append(k)
			if not firm.is_empty():
				_start_slip(firm[rng.randi_range(0, firm.size() - 1)])
			slips += 1
		if power >= 1.0:
			_catch()
	for k in 4:
		if _reslip_t[k] >= 0.0:
			_reslip_t[k] -= delta
			if _reslip_t[k] < 0.0 and not caught:
				_start_slip(k)
		if leg_state[k] == 1:
			leg_slide[k] = minf(1.0, leg_slide[k] + delta / SLIDE_S)
			if leg_slide[k] >= 1.0:
				_start_fall(k)
				return
	if not _viewed:
		_look_out()
	if caught:
		_caught_t += delta
		if not ladder_down and _caught_t >= LADDER_AFTER:
			_unroll_ladder()
	if _lamp_t >= 0.0:
		_lamp_t += delta
		for i in _lamps.size():
			_light_lamp(i, _lamp_t >= 0.5 + i * 0.4)
		if _lamp_t > 0.5 + _lamps.size() * 0.4:
			_lamp_t = -1.0
	angle = wrapf(angle + power * FULL_SPIN * delta, -PI, PI)
	_creak_t -= delta
	if power > 0.05 and not caught and _creak_t <= 0.0:
		_creak_t = lerpf(2.6, 0.9, power)
		Sfx.play3d("creak", global_position + Vector3.UP * COLLAR_Y, -8.0 + power * 6.0)
	_show()


func _reslip_pending() -> bool:
	for t in _reslip_t:
		if t >= 0.0:
			return true
	return false


func _show() -> void:
	rotor.rotation = Vector3(0, 0, angle)
	_fan_noise.target = power
	_hum.target = 0.6 if caught else power * 0.4
	_hum.pitch = 0.8 + power * 0.6
	# the lever: down while held (or caught)
	_lever.rotation.x = deg_to_rad(40.0 if lever_held or caught else -30.0)
	# legs: each foot slid out along its diagonal, the top still at the collar
	var worst := 0.0
	var worst_k := -1
	for k in 4:
		_place_leg(k)
		if leg_state[k] == 1 and leg_slide[k] > worst:
			worst = leg_slide[k]
			worst_k = k
	if not falling:
		_lean_ang = deg_to_rad(LEAN_DEG) * worst
		if worst_k >= 0:
			_lean_dir = _leg_out(worst_k)
		var wob := 0.0
		if power > 0.1 and not caught:
			wob = sin(Time.get_ticks_msec() * 0.011) * deg_to_rad(0.35) * power
		tower.transform = Transform3D(Basis(Vector3.UP.cross(_lean_dir).normalized(), _lean_ang + wob), Vector3.ZERO)


func _leg_out(k: int) -> Vector3:
	var sx := 1.0 if k % 2 == 0 else -1.0
	var sz := 1.0 if k < 2 else -1.0
	return Vector3(sx, 0, sz).normalized()


func _place_leg(k: int) -> void:
	var sx := 1.0 if k % 2 == 0 else -1.0
	var sz := 1.0 if k < 2 else -1.0
	var foot: Vector3 = Vector3(sx * FOOT, 0, sz * FOOT) + _leg_out(k) * SLIDE_M * leg_slide[k]
	var top := Vector3(sx * LEG_TOP, COLLAR_Y, sz * LEG_TOP)
	var d := top - foot
	var b := Basis(Quaternion(Vector3.UP, d.normalized()))
	(_legs[k] as Node3D).transform = Transform3D(b, (foot + top) * 0.5)


# --- the lever -------------------------------------------------------------------

func _hold_lever(_p, _dt: float) -> void:
	if caught or falling:
		return
	if _lever_t > 0.3:
		Sfx.play3d("latch", _lever.global_position, -4.0)
	_lever_t = 0.0


# --- legs ------------------------------------------------------------------------

func _start_slip(k: int) -> void:
	leg_state[k] = 1
	_reslip_t[k] = -1.0
	var at := (_legs[k] as Node3D).global_position
	Sfx.play3d("hit_metal_heavy", at, 2.0)
	Sfx.play3d("creak", at, 4.0)
	PlayerRig._dust_puff(global_transform * (_leg_out(k) * FOOT * 1.41) + Vector3.UP * 0.3, 14.0)
	for p in _players_near(80.0):
		p.say("A screech of metal: one of the windmill's legs is sliding off its footing!", 3.5)


## A head-butt on leg k (PlayerRig.headbutt finds the leg's "on_headbutt").
func butt_leg(k: int, p: PlayerRig) -> void:
	if leg_state[k] != 1:
		Sfx.play3d("hit_metal", p.global_position + Vector3.UP * 1.5, -4.0)
		return
	leg_slide[k] = maxf(0.0, leg_slide[k] - 1.0 / BUTTS)
	Sfx.play3d("hit_metal_heavy", p.global_position + Vector3.UP * 1.5, 0.0)
	if leg_slide[k] <= 0.001:
		leg_slide[k] = 0.0
		leg_state[k] = 2
		Sfx.play3d("latch", (_legs[k] as Node3D).global_position, 2.0)
		p.say("CLANG. The leg drops back onto its footing.", 2.5)
		if not caught and not _reslipped[k] and rng.randf() < reslip_chance:
			_reslipped[k] = true
			_reslip_t[k] = 3.0


func _start_fall(k: int) -> void:
	falling = true
	fall_t = 0.0
	_landed = false
	_crushed.clear()
	# down on whoever is nearest (it's always on top of you)
	var near: PlayerRig = null
	for p in get_tree().get_nodes_in_group("player"):
		var q := p as PlayerRig
		if q.seat != null:
			continue
		if near == null or q.global_position.distance_to(global_position) < near.global_position.distance_to(global_position):
			near = q
	if near != null:
		var to := global_transform.affine_inverse() * near.global_position
		to.y = 0.0
		fall_dir = to.normalized() if to.length() > 0.5 else _leg_out(k)
	else:
		fall_dir = _leg_out(k)
	Sfx.play3d("groan", global_position + Vector3.UP * COLLAR_Y, 6.0)
	Sfx.play3d("creak", global_position + Vector3.UP * HUB_Y, 6.0)
	for p in _players_near(120.0):
		p.say("The leg's gone - the whole windmill is groaning over. RUN!", 3.0)


func _fall(delta: float) -> void:
	fall_t += delta
	var ang := 0.0
	if fall_t < FALL_WARN:
		ang = deg_to_rad(LEAN_DEG + 4.0 * fall_t / FALL_WARN)
	else:
		var u := clampf((fall_t - FALL_WARN) / FALL_S, 0.0, 1.0)
		ang = lerpf(deg_to_rad(LEAN_DEG + 4.0), deg_to_rad(88.0), u * u)
	# it pivots on the feet on the side it falls to
	var pivot := fall_dir * FOOT
	var axis := Vector3.UP.cross(fall_dir).normalized()
	tower.transform = Transform3D(Basis(axis, ang), pivot) * Transform3D(Basis(), -pivot)
	angle = wrapf(angle + power * FULL_SPIN * delta, -PI, PI)
	power = maxf(0.0, power - delta * 0.3)
	if not _landed and fall_t >= FALL_WARN + FALL_S:
		_land(pivot)
	if _landed:
		_reset_t += delta
		if _reset_t >= RESET_AFTER:
			_restart()


func _land(pivot: Vector3) -> void:
	_landed = true
	_reset_t = 0.0
	var at := global_transform * (pivot + fall_dir * 14.0)
	Sfx.play3d("bang", at, 10.0)
	Sfx.play3d("hit_metal_heavy", at, 10.0)
	for i in 4:
		PlayerRig._dust_puff(global_transform * (pivot + fall_dir * (6.0 + i * 6.0)) + Vector3.UP * 0.5, 40.0)
	# under it: along the fall within the windmill's length, inside its width
	for p in get_tree().get_nodes_in_group("player"):
		var q := p as PlayerRig
		if q.seat != null:
			continue
		var lp := global_transform.affine_inverse() * q.global_position - pivot
		var along := lp.dot(fall_dir)
		var side := (lp - fall_dir * along)
		side.y = 0.0
		var width := FAN_R + 0.6 if along > HUB_Y - FAN_R - 2.0 else 2.6
		if along > -1.0 and along < HUB_Y + FAN_R + 1.0 and side.length() < width:
			_crushed.append(q)
			q.whiteout = 1.0
			q.taken_hold = RESET_AFTER + 0.5
	for p in get_tree().get_nodes_in_group("player"):
		var q := p as PlayerRig
		if q in _crushed:
			q.say("CRASH. Everything goes white...", RESET_AFTER)
		elif q.global_position.distance_to(global_position) < 150.0:
			q.say("The windmill came down with an almighty crash.", RESET_AFTER)
	print("[windmill] fell towards %s, crushed %d" % [fall_dir, _crushed.size()])


## The fall is over: the windmill stands again, still, and you're both
## back by the gate (S4: back to trying within a few seconds).
func _restart() -> void:
	falling = false
	reset()
	var spot := global_transform * (LEVER_AT + Vector3(-2.5, 0, -4.0))     # the lane side of the lever
	var i := 0
	for p in get_tree().get_nodes_in_group("player"):
		var q := p as PlayerRig
		q.whiteout = 0.0
		q.taken_hold = 0.0
		if q.seat != null:
			continue
		if q in _crushed or q.global_position.distance_to(global_position) < HUB_Y + FAN_R + 4.0:
			q.ladder = null
			q.global_position = _ground(spot + Vector3(i * 1.6, 0, 0))
			q.velocity = Vector3.ZERO
			q.reset_physics_interpolation()
		i += 1
	for q in _crushed:
		var other := _other(q)
		var who := "P%d" % (q.index + 1)
		if other != null and not other in _crushed:
			other.say("Text from %s: \"you ok? I think I'm flat\"" % who, 4.0)
		q.say("You come to by the gate, dust in your eyes. The windmill stands again, as if nothing happened.", 4.0)
	_crushed.clear()


func _other(p: PlayerRig) -> PlayerRig:
	for n in get_tree().get_nodes_in_group("player"):
		if n != p:
			return n as PlayerRig
	return null


# --- catching the wind -------------------------------------------------------------

func _catch() -> void:
	caught = true
	power = 1.0
	_caught_t = 0.0
	Sfx.play3d("bong", global_position + Vector3.UP * HUB_Y, 4.0)
	_open_gate(true)
	_lamp_t = 0.0
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["windmill_power"] = true
	for p in _players_near(150.0):
		p.say("The fan catches the wind with a deep hum. Down at the junction, the gate's lamp blinks and the barrier swings up.", 6.0)
	print("[windmill] caught the wind")


func _open_gate(open: bool, at_once := false) -> void:
	var to := deg_to_rad(84.0) if open else 0.0
	(_boom_body.get_child(0) as CollisionShape3D).disabled = open
	(_gate_lamp as MeshInstance3D).material_override = _lamp_on if open else _lamp_off
	if at_once:
		_boom.rotation.z = to
		return
	if open:
		Sfx.play3d("bong", _boom.global_position, 0.0)
		Sfx.play3d("latch", _boom.global_position, 0.0)
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_property(_boom, "rotation:z", to, 3.0).set_trans(Tween.TRANS_SINE)


func _light_lamp(i: int, on: bool) -> void:
	var l: Array = _lamps[i]
	var was: bool = (l[1] as OmniLight3D).visible
	(l[0] as MeshInstance3D).material_override = _lamp_on if on else _lamp_off
	(l[1] as OmniLight3D).visible = on
	if on and not was:
		Sfx.play3d("click", (l[0] as Node3D).global_position, -2.0)


func _unroll_ladder() -> void:
	ladder_down = true
	_roll.visible = false
	_ladder_hang.visible = true
	Sfx.play3d("hit_metal", _ladder_hang.global_position, 4.0)
	var tw := create_tween()
	tw.tween_property(_ladder_hang, "scale:y", 1.0, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_ladder.collision_layer = 4
		Sfx.play3d("hit_metal_heavy", _ladder.global_position + Vector3.UP, 2.0))
	for p in _players_near(120.0):
		p.say("The shaking works the rolled-up ladder loose: it clatters down the neck and hangs to the ground.", 5.0)


## The view from the walkway: both roads on to Last Fuel, the lake, the
## barn and the ridge lookout go onto the map.
func _look_out() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		var q := p as PlayerRig
		if q.global_position.y > global_position.y + WALK_Y - 1.0 and q.global_position.distance_to(global_position) < 30.0:
			_viewed = true
			var ms = get_tree().current_scene.get("map_state")
			if ms != null:
				ms.reveal_valley()
			q.say("What a view: both roads on to Last Fuel, the lake, the barn and the ridge lookout. It all goes onto the map.", 6.0)
			return


# --- the chest and the napin ---------------------------------------------------------

func _open_chest(p: PlayerRig) -> void:
	if not chest_open:
		chest_open = true
		var tw := create_tween()
		tw.tween_property(_lid, "rotation:x", deg_to_rad(105.0), 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Sfx.play3d("latch", _lid.global_position, 0.0)
		return
	if napin_taken:
		return
	napin_taken = true
	_napin_mesh.visible = false
	Sfx.play3d("pickup", p.global_position + Vector3.UP, 0.0)
	var boot := get_tree().current_scene
	var ms = boot.get("map_state")
	if ms != null:
		ms.find_napin()
	var st = boot.get("story")
	if st != null:
		st.flags["napin"] = true
	p.say("The napin: a brass map pin with a little dial. Whoever has the map can stick it in (M, then click): the van's nav points at it.", 8.0)


# --- saving ----------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"caught": caught, "chest_open": chest_open, "napin_taken": napin_taken}


func from_dict(d: Dictionary) -> void:
	reset()
	if bool(d.get("caught", false)):
		caught = true
		power = 1.0
		slips = SLIP_AT.size()
		leg_state = [2, 2, 2, 2]
		_caught_t = LADDER_AFTER
		_open_gate(true, true)
		for i in _lamps.size():
			_light_lamp(i, true)
		ladder_down = true
		_roll.visible = false
		_ladder_hang.visible = true
		_ladder_hang.scale.y = 1.0
		_ladder.collision_layer = 4
	chest_open = bool(d.get("chest_open", false))
	napin_taken = bool(d.get("napin_taken", false))
	_lid.rotation.x = deg_to_rad(105.0) if chest_open else 0.0
	_napin_mesh.visible = not napin_taken
	_show()


## F1 (Puzzles, or a story jump to the windmill or before): still, braked,
## firm legs, the gate down, the ladder rolled up, the napin in its chest.
func reset() -> void:
	power = 0.0
	caught = false
	falling = false
	_viewed = false
	slips = 0
	leg_slide = [0.0, 0.0, 0.0, 0.0]
	leg_state = [0, 0, 0, 0]
	_reslip_t = [-1.0, -1.0, -1.0, -1.0]
	_reslipped = [false, false, false, false]
	_lever_t = 9.0
	lever_held = false
	_lean_ang = 0.0
	ladder_down = false
	_roll.visible = true
	_ladder_hang.visible = false
	_ladder_hang.scale.y = 0.02
	_ladder.collision_layer = 0
	chest_open = false
	napin_taken = false
	_lid.rotation.x = 0.0
	_napin_mesh.visible = true
	_open_gate(false, true)
	_lamp_t = -1.0
	for i in _lamps.size():
		_light_lamp(i, false)
	tower.transform = Transform3D.IDENTITY
	_show()


# --- helpers ---------------------------------------------------------------------

func _players_near(r: float) -> Array:
	var out := []
	for p in get_tree().get_nodes_in_group("player"):
		if (p as Node3D).global_position.distance_to(global_position) < r:
			out.append(p)
	return out


func _ground(at: Vector3) -> Vector3:
	return Vector3(at.x, Landscape.ground(at.x, at.z) + 0.1, at.z)


## Where a player stands to work the lever (world).
func lever_spot() -> Vector3:
	return _ground(_wxf * (LEVER_AT + Vector3(0, 0, -1.0)))


## Leg k's foot (world), on the ground.
func leg_foot(k: int) -> Vector3:
	var sx := 1.0 if k % 2 == 0 else -1.0
	var sz := 1.0 if k < 2 else -1.0
	return _wxf * Vector3(sx * FOOT, 0, sz * FOOT)


func sliding_leg() -> int:
	for k in 4:
		if leg_state[k] == 1:
			return k
	return -1


# --- building --------------------------------------------------------------------

func _build_tower() -> void:
	var steel := ToonMat.make(Color(0.44, 0.40, 0.36), 0.012)
	var rust := ToonMat.make(Color(0.55, 0.33, 0.22), 0.012)
	var stone := ToonMat.make(Color(0.58, 0.56, 0.52), 0.01)
	tower = Node3D.new()
	tower.name = "Tower"
	add_child(tower)
	# footings stay put (they don't lean or fall)
	for k in 4:
		var sx := 1.0 if k % 2 == 0 else -1.0
		var sz := 1.0 if k < 2 else -1.0
		var f := Build.solid_box(Vector3(1.4, 0.5, 1.4), stone, Vector3(sx * FOOT, -0.13, sz * FOOT), Vector3(0, 45, 0), "Footing%d" % k)
		add_child(f)
		# a crack across each footing
		add_child(Build.box(Vector3(1.0, 0.02, 0.06), ToonMat.flat(Color(0.2, 0.2, 0.2)), Vector3(sx * FOOT, 0.13, sz * FOOT), Vector3(0, -30 * sx * sz, 0), "Crack"))
	# legs: one body each, so a butt knows which leg it hit
	var leg_len := Vector3(FOOT - LEG_TOP, COLLAR_Y, FOOT - LEG_TOP).length() + 0.3
	for k in 4:
		var body := AnimatableBody3D.new()
		body.name = "Leg%d" % k
		body.sync_to_physics = false
		var cs := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.24
		cap.height = leg_len
		cs.shape = cap
		body.add_child(cs)
		body.add_child(Build.cyl(0.2, leg_len, steel, Vector3.ZERO, Vector3.ZERO, 8, "LegMesh"))
		body.add_child(Build.cyl(0.32, 0.5, rust, Vector3(0, -leg_len * 0.5 + 0.3, 0), Vector3.ZERO, 8, "Shoe"))
		var kk := k
		body.set_meta("on_headbutt", func(p): butt_leg(kk, p))
		body.set_meta("tag_name", "that leg")
		tower.add_child(body)
		_legs.append(body)
		_place_leg(k)
	# the neck, the collar, the walkway and its rails: one body that leans
	var tb := AnimatableBody3D.new()
	tb.name = "TowerBody"
	tb.sync_to_physics = false
	tower.add_child(tb)
	var neck_h := WALK_Y - 0.2 - NECK_FROM
	tower.add_child(Build.cyl(NECK_R, neck_h, rust, Vector3(0, NECK_FROM + neck_h * 0.5, 0), Vector3.ZERO, 20, "Neck"))
	_cyl_shape(tb, NECK_R, neck_h, Vector3(0, NECK_FROM + neck_h * 0.5, 0))
	tower.add_child(Build.cyl(1.55, 0.7, steel, Vector3(0, COLLAR_Y, 0), Vector3.ZERO, 16, "Collar"))
	for y in [11.0, 15.0, 19.0]:
		tower.add_child(Build.cyl(NECK_R + 0.06, 0.2, steel, Vector3(0, y, 0), Vector3.ZERO, 20, "Band"))
	var deck := ToonMat.make(Color(0.40, 0.36, 0.30), 0.012)
	tower.add_child(Build.box(Vector3(4.8, 0.2, 4.8), deck, Vector3(0, WALK_Y - 0.1, 0), Vector3.ZERO, "Walkway"))
	_box_shape(tb, Vector3(4.8, 0.2, 4.8), Vector3(0, WALK_Y - 0.1, 0))
	var rail := ToonMat.make(Color(0.75, 0.22, 0.16), 0.01)
	var e := 2.35
	# the back rail has a gap in the middle where the ladder hangs
	for spec in [[Vector3(4.8, 1.0, 0.06), Vector3(0, 0.55, -e)], [Vector3(0.06, 1.0, 4.8), Vector3(-e, 0.55, 0)],
			[Vector3(0.06, 1.0, 4.8), Vector3(e, 0.55, 0)], [Vector3(1.9, 1.0, 0.06), Vector3(-1.45, 0.55, e)],
			[Vector3(1.9, 1.0, 0.06), Vector3(1.45, 0.55, e)]]:
		var sz: Vector3 = spec[0]
		var at: Vector3 = spec[1] + Vector3(0, WALK_Y, 0)
		tower.add_child(Build.box(Vector3(sz.x, 0.07, sz.z), rail, at + Vector3(0, 0.45, 0), Vector3.ZERO, "Rail"))
		tower.add_child(Build.box(Vector3(sz.x, 0.05, sz.z), rail, at, Vector3.ZERO, "MidRail"))
		_box_shape(tb, sz, at)
	# the head: gearbox housing, a tail vane up behind it
	var red := ToonMat.make(Color(0.68, 0.24, 0.20), 0.012)
	tower.add_child(Build.box(Vector3(1.8, 1.7, 3.2), red, Vector3(0, WALK_Y + 1.2, -0.6), Vector3.ZERO, "Head"))
	_box_shape(tb, Vector3(1.8, 1.7, 3.2), Vector3(0, WALK_Y + 1.2, -0.6))
	tower.add_child(Build.cyl(0.35, 2.4, steel, Vector3(0, HUB_Y, -2.4), Vector3(90, 0, 0), 10, "Shaft"))
	tower.add_child(Build.box(Vector3(0.12, 0.12, 4.2), steel, Vector3(0, WALK_Y + 2.6, 2.4), Vector3.ZERO, "TailBoom"))
	tower.add_child(Build.box(Vector3(0.08, 2.4, 3.0), red, Vector3(0, WALK_Y + 3.0, 4.2), Vector3.ZERO, "TailVane"))
	tower.add_child(Build.label3d("POWER CO-OP\nNo. 3", Vector3(0.92, WALK_Y + 1.2, -0.6), Vector3(0, 90, 0), 0.22, Color(0.95, 0.92, 0.8)))
	# the fan
	rotor = Node3D.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, HUB_Y, ROTOR_Z)
	tower.add_child(rotor)
	var blade := ToonMat.make(Color(0.90, 0.88, 0.82), 0.012)
	rotor.add_child(Build.cyl(1.1, 0.5, steel, Vector3.ZERO, Vector3(90, 0, 0), 16, "Hub"))
	for b in BLADES:
		var h := Node3D.new()
		h.rotation = Vector3(0, 0, TAU * b / BLADES)
		h.add_child(Build.box(Vector3(0.9, FAN_R - 1.1, 0.05), blade, Vector3(0, (FAN_R + 1.1) * 0.5, 0), Vector3(0, 22, 0), "Blade"))
		h.add_child(Build.box(Vector3(0.08, FAN_R - 0.8, 0.08), steel, Vector3(0, (FAN_R + 0.8) * 0.5, 0.06), Vector3.ZERO, "Spoke"))
		rotor.add_child(h)
	# an outer ring of short struts round the blade tips
	for b in BLADES:
		var a := TAU * (b + 0.5) / BLADES
		var seg := Build.box(Vector3(2.2, 0.1, 0.08), steel, Vector3(-sin(a), cos(a), 0) * (FAN_R - 0.3), Vector3(0, 0, rad_to_deg(a)), "Ring")
		rotor.add_child(seg)


func _cyl_shape(body: CollisionObject3D, r: float, h: float, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	cs.shape = c
	cs.position = at
	body.add_child(cs)


func _box_shape(body: CollisionObject3D, size: Vector3, at: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = size
	cs.shape = b
	cs.position = at
	body.add_child(cs)


func _build_lever() -> void:
	var base := Node3D.new()
	base.name = "StarterLever"
	base.position = LEVER_AT
	base.position.y = _local_ground(LEVER_AT)
	add_child(base)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34))
	base.add_child(Build.solid_box(Vector3(0.5, 1.0, 0.5), steel, Vector3(0, 0.5, 0), Vector3.ZERO, "Stand"))
	_lever = Node3D.new()
	_lever.name = "Pivot"
	_lever.position = Vector3(0, 1.0, 0)
	base.add_child(_lever)
	_lever.add_child(Build.cyl(0.04, 1.1, ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 0.55, 0), Vector3.ZERO, 6, "Handle"))
	_lever.add_child(Build.sphere(0.08, ToonMat.make(Color(0.1, 0.1, 0.1)), Vector3(0, 1.1, 0), Vector3.ONE, "Knob"))
	# a cable from the stand towards the windmill
	base.add_child(Build.label3d("STARTER\nhold down", Vector3(0, 0.85, -0.26), Vector3(0, 180, 0), 0.07, Color(0.95, 0.92, 0.8)))
	var a := Build.interact_area(Vector3(1.0, 1.8, 1.0), Vector3(0, 1.0, 0), "", func(_p): pass, "LeverArea")
	a.set_meta("tag_name", "the starter lever")
	a.set_meta("prompt_fn", func(_p) -> String:
		if caught:
			return ""
		return "Keep holding: it's winding up" if lever_held else "Hold down the starter lever")
	a.set_meta("blocked_fn", func() -> String:
		return "The windmill is turning on its own now" if caught else "")
	a.set_meta("hold_fn", func(p, dt: float): _hold_lever(p, dt))
	base.add_child(a)
	NareshNote.make(base, "wm_lever", Vector3(0, 0.45, -0.26), 180.0,
		"Starter lever. Hold it down till she catches the wind, don't let go.\nThe footings are cracked and the legs walk when she spins up.\nHead-butt them back (G). Works every time.\n- N")


func _local_ground(at: Vector3) -> float:
	var w := _wxf * at
	return Landscape.ground(w.x, w.z) - _wxf.origin.y


func _build_ladder() -> void:
	# rolled up on the walkway's back edge
	var ropey := ToonMat.make(Color(0.52, 0.42, 0.28), 0.012)
	_roll = Build.cyl(0.32, 1.0, ropey, Vector3(0, WALK_Y + 0.35, LADDER_Z - 0.15), Vector3(0, 0, 90), 12, "LadderRoll")
	tower.add_child(_roll)
	# hanging: the top fixed at the walkway, scaled down from there
	_ladder_hang = Node3D.new()
	_ladder_hang.name = "LadderHang"
	_ladder_hang.position = Vector3(0, WALK_Y, LADDER_Z)
	tower.add_child(_ladder_hang)
	var h := WALK_Y + 0.02
	_ladder = Ladder.make(_ladder_hang, Vector3(0, -h, 0), h, Vector3(0, 0, -1), Vector3(0, -0.0, -1.3), "WindmillLadder")
	_ladder.collision_layer = 0
	_ladder_hang.scale.y = 0.02
	_ladder_hang.visible = false


func _build_chest() -> void:
	var box := Node3D.new()
	box.name = "Chest"
	box.position = Vector3(1.45, WALK_Y, 1.1)
	box.rotation_degrees = Vector3(0, -90, 0)
	tower.add_child(box)
	var wood := ToonMat.make(Color(0.48, 0.34, 0.22), 0.012)
	box.add_child(Build.box(Vector3(0.9, 0.5, 0.6), wood, Vector3(0, 0.25, 0), Vector3.ZERO, "ChestBox"))
	_lid = Node3D.new()
	_lid.name = "LidHinge"
	_lid.position = Vector3(0, 0.52, 0.3)
	box.add_child(_lid)
	_lid.add_child(Build.box(Vector3(0.92, 0.07, 0.62), wood, Vector3(0, 0.035, -0.31), Vector3.ZERO, "Lid"))
	_napin_mesh = Node3D.new()
	_napin_mesh.name = "Napin"
	_napin_mesh.position = Vector3(0, 0.52, 0)
	box.add_child(_napin_mesh)
	var brass := ToonMat.make(Color(0.85, 0.66, 0.22), 0.008)
	_napin_mesh.add_child(Build.cyl(0.015, 0.16, brass, Vector3(0, 0.08, 0), Vector3.ZERO, 6, "Needle"))
	_napin_mesh.add_child(Build.sphere(0.05, ToonMat.make(Color(0.85, 0.15, 0.12)), Vector3(0, 0.17, 0), Vector3.ONE, "Head"))
	var a := Build.interact_area(Vector3(1.1, 0.9, 0.9), Vector3(0, 0.45, 0), "", func(p): _open_chest(p), "ChestArea")
	a.set_meta("tag_name", "the chest")
	a.set_meta("prompt_fn", func(_p) -> String:
		if not chest_open:
			return "Open the chest"
		return "" if napin_taken else "Take the napin")
	box.add_child(a)
	NareshNote.make(tower, "wm_chest", Vector3(0.92, WALK_Y + 0.9, 0.6), 90.0,
		"The napin. Stick it in the map wherever you're going -\nthe van knows the way after that.\n- N")


func _build_gate(world: Node3D, xf: Transform3D, fence_len: Array) -> void:
	gate = Node3D.new()
	gate.name = "JunctionGate"
	gate.transform = xf
	world.add_child(gate)          # x across the lane, -z up the lane
	var steel := ToonMat.make(Color(0.32, 0.33, 0.35), 0.01)
	var white := ToonMat.make(Color(0.95, 0.95, 0.92), 0.01)
	var redm := ToonMat.make(Color(0.80, 0.14, 0.12), 0.01)
	var half := 4.4
	gate.add_child(Build.solid_box(Vector3(0.5, 1.2, 0.5), steel, Vector3(-half, 0.6, 0), Vector3.ZERO, "PivotPost"))
	gate.add_child(Build.solid_box(Vector3(0.3, 0.9, 0.3), steel, Vector3(half, 0.45, 0), Vector3.ZERO, "RestPost"))
	gate.add_child(Build.box(Vector3(0.5, 0.9, 0.12), steel, Vector3(-half, 1.65, 0.0), Vector3.ZERO, "SignPost"))
	gate.add_child(Build.label3d("JUNCTION CLOSED\nNO POWER", Vector3(-half, 2.4, 0.3), Vector3.ZERO, 0.26, Color(0.95, 0.2, 0.15)))
	gate.add_child(Build.label3d("JUNCTION CLOSED\nNO POWER", Vector3(-half, 2.4, -0.3), Vector3(0, 180, 0), 0.26, Color(0.95, 0.2, 0.15)))
	_lamp_off = ToonMat.make(Color(0.25, 0.22, 0.18), 0.01)
	_lamp_on = ToonMat.make(Color(1.0, 0.86, 0.45), 0.01, 0.9, Color(1.0, 0.75, 0.3) * 2.5)
	_gate_lamp = Build.sphere(0.16, _lamp_off, Vector3(-half, 1.35, 0), Vector3.ONE, "GateLamp")
	gate.add_child(_gate_lamp)
	_boom = Node3D.new()
	_boom.name = "Boom"
	_boom.position = Vector3(-half, 1.0, 0)
	gate.add_child(_boom)
	var n := 8
	for i in n:
		var seg := Build.box(Vector3(2.0 * half / n, 0.16, 0.12), white if i % 2 == 0 else redm,
			Vector3((i + 0.5) * 2.0 * half / n, 0, 0), Vector3.ZERO, "BoomSeg")
		_boom.add_child(seg)
	_boom_body = StaticBody3D.new()
	_boom_body.name = "BoomBody"
	# a tall box: the van can't jump it, and you can't walk under it either
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0 * half, 1.0, 0.3)
	cs.shape = bs
	cs.position = Vector3(0, 0.6, 0)
	_boom_body.add_child(cs)
	gate.add_child(_boom_body)
	# fences either side, rails a van can't cross; walkers step through
	# the gap between the post and the fence
	var wood := ToonMat.make(Color(0.45, 0.34, 0.24), 0.012)
	var rock := ToonMat.make(Color(0.50, 0.48, 0.45), 0.01)
	for side in [-1.0, 1.0]:
		var from := half + 1.3
		var to: float = from + float(fence_len[0 if side < 0 else 1])
		var x := from
		while x <= to:
			gate.add_child(Build.box(Vector3(0.18, 1.3, 0.18), wood, Vector3(side * x, 0.65, 0), Vector3.ZERO, "FencePost"))
			x += 3.0
		var mid := (from + to) * 0.5
		var len := to - from
		gate.add_child(Build.box(Vector3(len, 0.12, 0.08), wood, Vector3(side * mid, 1.05, 0), Vector3.ZERO, "FenceRail"))
		gate.add_child(Build.box(Vector3(len, 0.12, 0.08), wood, Vector3(side * mid, 0.6, 0), Vector3.ZERO, "FenceRail"))
		var fb := StaticBody3D.new()
		fb.name = "FenceBody"
		_box_shape(fb, Vector3(len, 1.6, 0.4), Vector3(side * mid, 0.6, 0))
		gate.add_child(fb)
		var k := from + 4.0
		while k < to:
			gate.add_child(Build.solid_box(Vector3(1.3, 0.9, 1.1), rock, Vector3(side * k, 0.3, 1.2), Vector3(8, k * 37.0, 5), "Boulder"))
			k += 7.0


func _build_lamps(world: Node3D, at: Array) -> void:
	var post := ToonMat.make(Color(0.30, 0.31, 0.33), 0.01)
	var holder := Node3D.new()
	holder.name = "StreetLamps"
	world.add_child(holder)
	for p in at:
		var w: Vector3 = p
		var n := Node3D.new()
		n.position = w
		holder.add_child(n)
		n.add_child(Build.cyl(0.08, 5.0, post, Vector3(0, 2.5, 0), Vector3.ZERO, 6, "LampPost"))
		var head := Build.sphere(0.22, _lamp_off, Vector3(0, 5.1, 0), Vector3(1, 0.7, 1), "LampHead")
		n.add_child(head)
		var l := OmniLight3D.new()
		l.position = Vector3(0, 4.8, 0)
		l.light_color = Color(1.0, 0.85, 0.55)
		l.light_energy = 1.4
		l.omni_range = 9.0
		l.visible = false
		n.add_child(l)
		_lamps.append([head, l])
