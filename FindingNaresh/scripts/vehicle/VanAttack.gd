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
## The heat rule (#6 teaches it, every encounter from then on; design/
## PUZZLE_CHANGES.md #6): once a Problem has seen the van and while it stays
## interested, the van heats and leaks fuel, wherever it is. Driving harder
## heats it faster; switched off, the needle still creeps. It all stops only
## when the Problem loses interest. The longer it lasts, the more coolant
## boils away.
const PROBLEM_LEAK := 4.0        ## L a minute while one is interested
const LEAK_CAP := 17.5           ## L per encounter at most (a quarter of a tank)
const LEAK_FLOOR := 4.0          ## L: it never drains the tank below this
const HEAT_BASE := 0.3           ## deg/s, engine running
const HEAT_THROTTLE := 1.9       ## deg/s more at full throttle
const HEAT_PER_M := 0.12         ## deg per metre driven
const HEAT_OFF := 0.6            ## deg/s with the engine off: the needle still creeps
const BOIL_AWAY := 0.005         ## coolant (0..1) a second, while interested and steaming
const BOILED_TO := 0.5           ## coolant left the moment it boils
const CALM_AFTER := 1.0          ## s without interest before the encounter is over

var van: Camper
var attacked_t := 0.0            ## s a creature has been at the van
var attacker: Node3D = null
var tarped := false
var coughing := 0.0              ## s left of a cough (almost no power)
var leak_left := 0.0             ## s left of `van.fuel_leak`, if it is timed
var tarp_work := 0.0             ## s of pulling so far (tests read it)
var interest_t := 0.0            ## s a Problem has been interested, this encounter
var encounter_leaked := 0.0      ## L leaked this encounter
var watcher: Node3D = null       ## the Problem that is interested now
var heat_added := 0.0            ## deg it has added this encounter (tests read it)
var _interested := false
var _interest_tick := false
var _calm_t := 0.0
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


## A Problem that has seen the van calls this every physics tick it stays
## interested (near or far, tarped or not).
func creature_interested(c: Node3D, delta: float) -> void:
	watcher = c
	_interest_tick = true
	interest_t += delta


## A Problem is interested in the van right now: it heats and leaks.
func interested() -> bool:
	return _interested


## Degrees a second the interest adds on top of the engine's own heat.
func heat_rate(speed: float, throttle: float, running: bool) -> float:
	if not _interested:
		return 0.0
	if not running:
		return HEAT_OFF
	return HEAT_BASE + HEAT_THROTTLE * clampf(throttle, 0.0, 1.0) + HEAT_PER_M * speed


## Engine pull multiplier: 1 when well, 0.6 when failing, near 0 mid-cough.
func power() -> float:
	if coughing > 0.0:
		return 0.12
	return SICK_POWER if stage() >= 2 else 1.0


## Litres a minute leaking out, whatever the cause.
func leak_rate() -> float:
	return van.fuel_leak + (Camper.CREATURE_LEAK if stage() >= 1 else 0.0) + problem_leak()


## The interest's own leak: on while it lasts, up to a quarter of a tank.
func problem_leak() -> float:
	if _interested and encounter_leaked < LEAK_CAP and van.fuel > LEAK_FLOOR:
		return PROBLEM_LEAK
	return 0.0


func tick(delta: float, speed: float, throttle: float) -> void:
	_noises(delta, speed, throttle)
	# the heat rule: interest seen this tick (or the last: creatures may tick
	# after the van) keeps it on; a second without and the encounter is over
	var was := _interested
	_interested = _interest_tick
	_interest_tick = false
	if _interested:
		_calm_t = 0.0
		encounter_leaked += problem_leak() / 60.0 * delta
		if not was:
			Sfx.play3d("hit_metal", _side_point(0.6), -8.0)
	else:
		_calm_t += delta
		if _calm_t > CALM_AFTER and interest_t > 0.0:
			interest_t = 0.0
			encounter_leaked = 0.0
			heat_added = 0.0
			watcher = null
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
	if s >= 1 or problem_leak() > 0.0:
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
		p.say("The van is a dark lump under the old shade net now. Get in and keep still and quiet: from inside you can see out through the weave." if tarped else "The net is off and rolled up on the back.", 6.0)


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
	interest_t = 0.0
	encounter_leaked = 0.0
	heat_added = 0.0
	watcher = null
	_interested = false
	_interest_tick = false


func _build_tarp() -> void:
	# #6 (agreed 2026-11-09, S1): old shade netting, not canvas. From outside
	# a dark lump; from inside you see out through the weave (shade_net.gdshader)
	# two layers on each piece: an opaque dark skin seen from outside, a faint
	# weave seen from inside (one see-through layer let the glass show through)
	var net_out := ShaderMaterial.new()
	net_out.shader = load("res://shaders/shade_net_out.gdshader")
	var net_in := ShaderMaterial.new()
	net_in.shader = load("res://shaders/shade_net.gdshader")
	var rolled := ToonMat.make(Color(0.17, 0.20, 0.15))
	# rolled up on the back, above the spare wheel (clear of its handle)
	_roll = Build.cyl(0.13, 1.5, rolled, Vector3(0, 2.80, 3.02), Vector3(0, 0, 90), 10, "TarpRoll")
	van._body_root.add_child(_roll)
	# over the van: the whole van, down to just above the wheels' middle
	_tarp = Node3D.new()
	_tarp.name = "Tarp"
	_tarp.visible = false
	van._body_root.add_child(_tarp)
	# bumper (z -3.95) to the spare wheel (3.23), roof rack and crate on top
	for spec in [[Vector3(2.56, 2.25, 7.45), Vector3(0, 1.72, -0.325), "Sheet"],
			[Vector3(2.2, 0.62, 5.6), Vector3(0, 3.1, 0.0), "OverRack"]]:
		_tarp.add_child(Build.box(spec[0], net_out, spec[1], Vector3.ZERO, String(spec[2])))
		_tarp.add_child(Build.box(spec[0], net_in, spec[1], Vector3.ZERO, String(spec[2]) + "In"))
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
