class_name VanAttack
extends Node

## The van and the creatures (design/CREATURES.md, "Near the van").
## - The noises it makes that they hear: the engine (idle / driving / revving),
##   the doors and the horn.
## - What one does to it while it stays within 15 m: a fuel leak at once, the
##   engine failing (power down 40%, coughing) after 30 s, a puncture after
##   60 s. Nothing is permanent: once nothing has been near for a few seconds
##   it all stops (a flat tyre stays flat).
## - The tarp, rolled up on the back: stop, engine off, and hold E at either
##   back corner (or the roll) for 4 s; the lights go off with it and the van
##   becomes a lump under canvas that they do not notice. The pulling is
##   kept, so one player can start it and the other finish. You can sit
##   inside a tarped van and hide; only the door mirrors poke out past the
##   canvas, so they are how you watch. The engine won't start under it.

const NEAR := 15.0
const LEAK_AFTER := 2.0
const ENGINE_AFTER := 30.0
const PUNCTURE_AFTER := 60.0
const LET_GO := 5.0              ## s with nothing near before it all stops
const SICK_POWER := 0.6
const TARP_ON_S := 4.0
const TARP_OFF_S := 2.0
const TAKEN_LEAK_S := 90.0       ## how long the leak lasts that they leave when they take you both

var van: Camper
var attacked_t := 0.0            ## s a creature has been at the van
var attacker: Node3D = null
var tarped := false
var coughing := 0.0              ## s left of a cough (almost no power)
var leak_left := 0.0             ## s left of `van.fuel_leak`, if it is timed
var tarp_work := 0.0             ## s of pulling so far (tests read it)
var _stage := 0
var _near_tick := false
var _away_t := 0.0
var _engine_t := 0.0
var _horn_t := 0.0
var _honk_extra := 0.0            ## s of horn someone else is pressing (Naresh)
var last_honk_ms := -1            ## when the horn last sounded (tests read it)
var _drip_t := 0.0
var _cough_t := 3.0
var _pull_idle := 0.0
var _horn: NoiseLoop
var _tarp: Node3D
var _roll: Node3D


func _init(v: Camper) -> void:
	van = v
	name = "VanAttack"


func _ready() -> void:
	_horn = NoiseLoop.new()
	_horn.kind = NoiseLoop.Kind.HORN
	_horn.volume_db = 2.0
	van.add_child(_horn)
	_horn.position = Vector3(0, 0.2, -2.6)
	_build_tarp()


## 0 nothing, 1 leaking, 2 the engine failing too, 3 punctured as well.
func stage() -> int:
	if attacked_t <= LEAK_AFTER:
		return 0
	if attacked_t <= ENGINE_AFTER:
		return 1
	return 2 if attacked_t <= PUNCTURE_AFTER else 3


## A creature at the van calls this every physics tick it stays near.
func creature_near(c: Node3D, delta: float) -> void:
	if tarped:
		return
	attacker = c
	_near_tick = true
	attacked_t += delta


## Engine pull multiplier: 1 when well, 0.6 when failing, near 0 mid-cough.
func power() -> float:
	if coughing > 0.0:
		return 0.12
	return SICK_POWER if stage() >= 2 else 1.0


## Litres a minute leaking out, whatever the cause.
func leak_rate() -> float:
	return van.fuel_leak + (Camper.CREATURE_LEAK if stage() >= 1 else 0.0)


func tick(delta: float, speed: float, throttle: float) -> void:
	_noises(delta, speed, throttle)
	# the attack runs while something stays; a few seconds without and it stops
	if _near_tick:
		_away_t = 0.0
	else:
		_away_t += delta
		if _away_t > LET_GO and attacked_t > 0.0:
			attacked_t = 0.0
			attacker = null
	_near_tick = false
	var s := stage()
	if s != _stage:
		if s > _stage:
			_telegraph(s)
		_stage = s
	if s >= 1:
		_drip_t -= delta
		if _drip_t <= 0.0:
			_drip_t = 1.1
			Sfx.play3d("tick", _side_point(0.3), -10.0)
	if s >= 2 and van.engine_on:
		_cough_t -= delta
		if _cough_t <= 0.0:
			_cough_t = randf_range(3.0, 6.0)
			coughing = 0.45
			Sfx.play3d("hit_soft", van.global_transform * Vector3(0, 0.8, -3.0), -2.0)
	coughing = maxf(0.0, coughing - delta)
	if leak_left > 0.0:
		leak_left -= delta
		if leak_left <= 0.0:
			van.fuel_leak = 0.0
	# the pulling is kept when you let go: the other player can finish it


## What they hear of the van, re-sent twice a second while it lasts.
func _noises(delta: float, speed: float, throttle: float) -> void:
	if van.engine_on and van.fuel > 0.0:
		_engine_t -= delta
		if _engine_t <= 0.0:
			_engine_t = 0.5
			var r := Hearing.ENGINE_IDLE
			if speed > 1.0:
				r = Hearing.ENGINE_DRIVE
			if van.rpm_norm > 0.8 or (throttle > 0.8 and speed < 4.0):
				r = Hearing.ENGINE_REV
			Hearing.emit(van.global_position, r, "engine")
	var d = van.driver.dev if van.driver != null else null
	var honk: bool = d != null and d.held("horn") and van.battery > 0.05 and not van.driver.map_open
	_honk_extra = maxf(0.0, _honk_extra - delta)
	honk = honk or (_honk_extra > 0.0 and van.battery > 0.05)
	_horn.target = 1.0 if honk else 0.0
	if honk:
		last_honk_ms = Time.get_ticks_msec()
		_horn_t -= delta
		if _horn_t <= 0.0:
			_horn_t = 1.0
			Hearing.emit(van.global_position, Hearing.HORN, "horn")
	else:
		_horn_t = 0.0


## The horn for `seconds`, pressed by someone who isn't the driver (Naresh).
func honk_for(seconds: float) -> void:
	_honk_extra = maxf(_honk_extra, seconds)


func is_honking() -> bool:
	return _horn.target > 0.5


func _telegraph(s: int) -> void:
	match s:
		1:
			Sfx.play3d("hit_metal", _side_point(0.6), -4.0)
			_tell("Something is at the van. A dripping sound: it's leaking fuel.")
		2:
			Sfx.play3d("bang", van.global_transform * Vector3(0, 0.8, -3.0), -4.0)
			_tell("The engine coughs and loses power. Get it away from here.")
		3:
			van.puncture()


## Players in the van or near it hear it.
func _tell(text: String) -> void:
	for n in van.get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.global_position.distance_to(van.global_position) < 40.0:
			p.say(text, 6.0)


## A point on the side of the van the creature is on (the dash side it's on).
func _side_point(h: float) -> Vector3:
	var side := -1.0
	if attacker != null and is_instance_valid(attacker):
		side = signf((van.global_transform.affine_inverse() * attacker.global_position).x)
		if side == 0.0:
			side = 1.0
	return van.global_transform * Vector3(side * 1.1, h, -1.5)


# --- the tarp ------------------------------------------------------------------

## Why the tarp can't go on right now, or "".
func tarp_blocked() -> String:
	if tarped:
		return ""
	if van.linear_velocity.length() > 0.5:
		return "Stop the van first"
	if van.engine_on:
		return "Engine off first (%s), then the tarp can go over" % _key_hint()
	return ""


func _key_hint() -> String:
	for n in van.get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null:
			return p.dev.glyph("ignition")
	return "X"


## How far along the pulling is, 0..1 (on, or off when it's on).
func tarp_progress() -> float:
	return clampf(tarp_work / (TARP_OFF_S if tarped else TARP_ON_S), 0.0, 1.0)


func _pull(p: PlayerRig, dt: float) -> void:
	if tarp_blocked() != "":
		return
	# pulling a big sheet of canvas is not quiet
	if fmod(tarp_work, 1.5) < dt:
		Hearing.emit(van.global_position, Hearing.DOOR, "tarp")
		Sfx.play3d("hit_soft", p.global_position + Vector3.UP, -8.0)
	tarp_work += dt
	if tarp_work >= (TARP_OFF_S if tarped else TARP_ON_S):
		tarp_work = 0.0
		set_tarp(not tarped)
		p.say("The van is a lump under the canvas now. Keep still and quiet - you can hide inside it. Only the door mirrors show what's out there." if tarped else "The tarp is off and rolled up on the back.", 6.0)


func set_tarp(on: bool) -> void:
	tarped = on
	_tarp.visible = on
	_roll.visible = not on
	tarp_work = 0.0
	if on:
		attacked_t = 0.0
		attacker = null
		if van.headlights_on:
			van.set_headlights(false)


## Everything a creature did to the van, undone (the developer menu's fix).
func reset() -> void:
	attacked_t = 0.0
	attacker = null
	coughing = 0.0
	leak_left = 0.0
	_stage = 0
	_away_t = 0.0


func _build_tarp() -> void:
	var canvas := ToonMat.make(Color(0.40, 0.42, 0.30))
	var fold := ToonMat.make(Color(0.33, 0.35, 0.25))
	# rolled up on the back, above the spare wheel (clear of its handle)
	_roll = Build.cyl(0.13, 1.5, canvas, Vector3(0, 2.80, 3.02), Vector3(0, 0, 90), 10, "TarpRoll")
	van._body_root.add_child(_roll)
	# over the van: a big lump of canvas down to just above the wheels' middle
	_tarp = Node3D.new()
	_tarp.name = "Tarp"
	_tarp.visible = false
	van._body_root.add_child(_tarp)
	# the canvas covers everything but the front doors' side windows: there it
	# is tucked below and above them, so from a seat you can still see out of
	# your side window to the door mirror (the only way to watch from inside)
	const GAP_Z := Vector2(-3.75, -1.1)      # front of the van to behind the front seats
	const GAP_Y := Vector2(1.52, 2.2)        # the window band
	var front_len := GAP_Z.y - GAP_Z.x
	var front_z := (GAP_Z.x + GAP_Z.y) * 0.5
	_tarp.add_child(Build.box(Vector3(2.56, 2.25, 3.25 - GAP_Z.y), canvas, Vector3(0, 1.72, (3.25 + GAP_Z.y) * 0.5), Vector3.ZERO, "Sheet"))
	_tarp.add_child(Build.box(Vector3(2.56, GAP_Y.x - 0.6, front_len), canvas, Vector3(0, (0.6 + GAP_Y.x) * 0.5, front_z), Vector3.ZERO, "SheetLow"))
	_tarp.add_child(Build.box(Vector3(2.56, 2.85 - GAP_Y.y, front_len), canvas, Vector3(0, (GAP_Y.y + 2.85) * 0.5, front_z), Vector3.ZERO, "SheetHigh"))
	_tarp.add_child(Build.box(Vector3(2.56, GAP_Y.y - GAP_Y.x, 0.06), canvas, Vector3(0, (GAP_Y.x + GAP_Y.y) * 0.5, GAP_Z.x + 0.03), Vector3.ZERO, "SheetFront"))
	_tarp.add_child(Build.box(Vector3(2.2, 0.62, 5.6), canvas, Vector3(0, 3.1, 0.0), Vector3.ZERO, "OverRack"))
	for z in [-2.2, 0.0, 2.2]:
		_tarp.add_child(Build.box(Vector3(2.62, 0.08, 0.1), fold, Vector3(0, 2.2, z), Vector3.ZERO, "Fold"))
	# handles: the roll up top, and both back corners at waist height (clear
	# of the fuel filler, the rack and the spare wheel)
	for spec in [[Vector3(1.6, 0.5, 0.5), Vector3(0, 2.75, 3.75), "TarpHandle"],
			[Vector3(0.6, 1.8, 0.8), Vector3(-1.3, 1.3, 2.85), "TarpCornerL"],
			[Vector3(0.6, 1.8, 0.8), Vector3(1.3, 1.3, 2.85), "TarpCornerR"]]:
		var area := Build.interact_area(spec[0], spec[1], "", func(_p): pass, spec[2])
		area.set_meta("tag_name", "the tarp")
		area.set_meta("prompt_fn", func(_p) -> String:
			var pct := "" if tarp_work <= 0.0 else "  (%d%%)" % roundi(tarp_progress() * 100.0)
			if tarped:
				return "Hold to pull the tarp off" + pct
			return ("Hold to pull the tarp over the van" + pct) if tarp_blocked() == "" else "")
		area.set_meta("blocked_fn", func() -> String:
			return tarp_blocked())
		area.set_meta("hold_fn", func(p, dt: float): _pull(p, dt))
		van._body_root.add_child(area)
