class_name C2Watch
extends Node
## Trial c2 (test-method research): state checks. A test-side observer that
## reads the game's own state and moves nothing. Seven rules, each with a
## trigger (the state it needs): a rule whose trigger never held in the run is
## NOT REACHED, never a pass (ruling R12). Generic rules (G*) were written as
## "what should always hold"; declared rules (D*) are written for this puzzle's
## places. They're counted apart. Every finding saves one picture from an
## observer camera no player owns (ruling R2) and its numbers.
## Writes appdata/playtest/runs/c2.txt (one line per look / finding) and
## c2_verdict.txt (rewritten at each watched scenario's end).
## It never reads which practice patch is applied: only the game's state.

const WATCHED := ["ramp", "c2_more"]
## measured limits (see notes/method_research/trial_c2.md for the margins)
const DRIFT_LIMIT := 0.30        ## m, horizontal, after the game's reset, before any input
const DRIFT_WINDOW := 5.0        ## s at most
const SWIM_DRY := 0.30           ## m: ground above the swimmer's water by this = dry ground
const SWIM_SECS := 1.0
const SWIM_OUT := 5.0            ## m farther from the river than the swimmer's own bank point
const SUNK_LIMIT := -0.12        ## m below the ground under it. Clean worst -0.067 (a tyre, q3), clean hub -0.013; P6's hub -0.19 (referee)
const HUD_SECS := 0.5

## The final method (M4): every field a rule reads, validated by name, type
## and (for objects) instance before use, at the scenario's start (preflight)
## and on every read. A failed read makes the observation invalid (STALE ->
## TEST). Objects marked "must" are required by the manifest (M5): a valid
## read that finds them null / freed is ABSENT -> FAIL, owner UNRESOLVED.
## key -> tag, member, type ("obj": an object member, null allowed unless must), must exist
const REQ := {
	"rj.failing": ["rj", "failing", TYPE_BOOL, false],
	"rj.van_wheel": ["rj", "van_wheel", "obj", false],
	"rj.hut": ["rj", "hut", "obj", true],
	"rj._window": ["rj", "_window", TYPE_VECTOR3, false],
	"rj.water_y": ["rj", "water_y", TYPE_FLOAT, false],
	"van.parking_brake": ["van", "parking_brake", TYPE_BOOL, false],
	"van.freeze": ["van", "freeze", TYPE_BOOL, false],
	"van._wheel_meshes": ["van", "_wheel_meshes", TYPE_ARRAY, false],
	"van._wheels": ["van", "_wheels", TYPE_ARRAY, false],
	"van._bare_hub": ["van", "_bare_hub", "obj", true],
	"p1.swimming": ["p1", "swimming", TYPE_BOOL, false],
	"p1._swim_y": ["p1", "_swim_y", TYPE_FLOAT, false],
	"p1._swim_to": ["p1", "_swim_to", TYPE_VECTOR3, false],
	"p2.swimming": ["p2", "swimming", TYPE_BOOL, false],
	"p2._swim_y": ["p2", "_swim_y", TYPE_FLOAT, false],
	"p2._swim_to": ["p2", "_swim_to", TYPE_VECTOR3, false],
	"hud0._warn": ["hud0", "_warn", "obj", true],
	"boot.players": ["boot", "players", TYPE_ARRAY, false],
	"boot.huds": ["boot", "huds", TYPE_ARRAY, false],
}
var bad := {}                    ## key -> why (once per scenario)
var absent := {}                 ## object -> true (once per scenario)
var stat := {}                   ## rule id -> {eval, win, err, find}

var pt: Node                     ## PlayTest
var boot: Node
var dir := ""
var scen := ""
var rules := {}                  ## id -> {kind, what, looks, fired, finding, note, vals: []}
var _t_scen := 0.0
var _static_done := false
# G1 drift
var _van_last := Vector3.ZERO
var _win_open := false
var _win_t := 0.0
var _win_p0 := Vector3.ZERO
var _win_brake_on_all := true
var _win_brake_last := true
# G2 swim
var _swim_t := [0.0, 0.0]
var _swim_seen := [false, false]
# G3 sunk
var _frozen_t := 0.0
var _sunk_done := false
# G4 hud
var _hud_bad_t := 0.0


static func ensure(p: Node, b: Node, progress_path: String) -> C2Watch:
	if progress_path == "":
		return null
	var w := C2Watch.new()
	w.name = "C2Watch"
	w.pt = p
	w.boot = b
	w.dir = progress_path.get_base_dir()
	w._define()
	p.add_child(w)
	for f in ["c2.txt", "c2_verdict.txt"]:
		if FileAccess.file_exists(w.dir.path_join(f)):
			DirAccess.remove_absolute(w.dir.path_join(f))
	return w


func _define() -> void:
	_rule("G1", "generic", "after the game's reset, nothing moves before any input (the brake is read and reported)")
	_rule("G2", "generic", "nobody is in swim mode on dry ground farther from the river than the bank they swim to")
	_rule("G3", "generic", "a parked van's wheels and bare hub sit on the ground, not in it")
	_rule("G3b", "generic", "a parked van's bare hub and visible tyres sit where they were built on their own wheel (attachment, M8)")
	_rule("G4", "generic", "the HUD's wheel warning matches the van's physical front-left wheel")
	_rule("D1", "declared", "the crate's spot under the hut's window is clear of solids")
	_rule("D2", "declared", "the river wreck shows above the water")
	_rule("D3", "declared", "P1 walks in through the open hut door on W alone")


func _rule(id: String, kind: String, what: String) -> void:
	rules[id] = {"kind": kind, "what": what, "looks": 0, "fired": false, "finding": "", "note": "", "vals": []}
	stat[id] = {"eval": 0, "win": 0, "err": 0, "find": 0}


func _mr() -> MethodRec:
	return MethodRec.inst if MethodRec.inst != null and is_instance_valid(MethodRec.inst) else null


func _obj(tag: String) -> Object:
	match tag:
		"rj": return _rj()
		"van": return _van()
		"boot": return boot
		"p1", "p2":
			var pl = boot.get("players") if boot != null else null
			var i := 0 if tag == "p1" else 1
			if typeof(pl) == TYPE_ARRAY and (pl as Array).size() > i:
				return (pl as Array)[i]
			return null
		"hud0":
			var hs = boot.get("huds") if boot != null else null
			if typeof(hs) == TYPE_ARRAY and (hs as Array).size() > 0:
				return (hs as Array)[0]
			return null
	return null


## A validated read (M4). Returns [ok, value]. A missing owner object, member
## or wrong type is invalid (STALE, once). A valid read of a required object
## that is null / freed is ABSENT (M5): ok false too, so nothing reads it.
func rd(key: String, rule := "") -> Array:
	var spec: Array = REQ[key]
	var o := _obj(spec[0])
	var member: String = spec[1]
	if o == null or not is_instance_valid(o):
		return _bad(key, "owner object '%s' not found" % spec[0], rule)
	if not (member in o):
		return _bad(key, "no member '%s' on %s" % [member, o.get_class()], rule)
	var v: Variant = o.get(member)
	if typeof(spec[2]) == TYPE_STRING:      # an object member
		if typeof(v) == TYPE_NIL or (typeof(v) == TYPE_OBJECT and not is_instance_valid(v)):
			if spec[3]:
				_absent(key, "null" if typeof(v) == TYPE_NIL else "freed", rule)
				return [false, null]
			return [true, null]
		if typeof(v) != TYPE_OBJECT:
			return _bad(key, "type %s, wanted an object" % type_string(typeof(v)), rule)
		return [true, v]
	if typeof(v) != int(spec[2]):
		return _bad(key, "type %s, wanted %s" % [type_string(typeof(v)), type_string(int(spec[2]))], rule)
	if typeof(v) == TYPE_FLOAT and not is_finite(v):
		return _bad(key, "not finite (%s)" % v, rule)
	if typeof(v) == TYPE_VECTOR3 and not (v as Vector3).is_finite():
		return _bad(key, "not finite (%s)" % v, rule)
	return [true, v]


func _bad(key: String, why: String, rule: String) -> Array:
	if rule != "" and stat.has(rule):
		stat[rule]["err"] += 1
	if not bad.has(key):
		bad[key] = why
		_log("STALE\t%s\t%s\t%s" % [key, scen, why])
		if _mr():
			_mr().ev("STALE", {"field": key, "why": why, "rule": rule})
	return [false, null]


## M5: a required object positively seen missing (valid binding, null / freed / empty).
func _absent(what: String, why: String, rule: String) -> void:
	if absent.has(what):
		return
	absent[what] = true
	_log("ABSENT\t%s\t%s\t%s" % [what, scen, why])
	if _mr():
		_mr().ev("ABSENT", {"object": what, "why": why, "rule": rule})


## Preflight at a watched scenario's start: every required read once.
func preflight() -> void:
	var before := bad.size()
	for k in REQ:
		rd(k)
	var n_bad := bad.size() - before
	_log("PREFLIGHT\t%s\t%d reads, %d invalid" % [scen, REQ.size(), n_bad])
	if _mr():
		_mr().ev("PREFLIGHT", {"n": REQ.size(), "bad": bad.keys(), "ok": n_bad == 0})


## true when every listed read is valid (each failure counted on the rule)
func _ok(rule: String, keys: Array) -> bool:
	var good := true
	for k in keys:
		if not rd(k, rule)[0]:
			good = false
	return good


func _window(id: String, complete: bool, data := {}) -> void:
	if complete:
		stat[id]["win"] += 1
	var d := data.duplicate()
	d["rule"] = id
	d["complete"] = complete
	if _mr():
		_mr().ev("WINDOW", d)


func _rj() -> Node:
	return get_tree().get_first_node_in_group("ramp_jump")


func _van() -> Camper:
	return get_tree().current_scene.get("camper") as Camper


func _log(line: String) -> void:
	var path := dir.path_join("c2.txt")
	var fa := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if fa != null:
		fa.seek_end()
		fa.store_string(line + "\n")
		fa.close()
	print("[c2] " + line)


func _look(id: String, val: float, note := "") -> void:
	var r: Dictionary = rules[id]
	r["looks"] += 1
	stat[id]["eval"] += 1
	(r["vals"] as Array).append(val)
	if note != "":
		r["note"] = note


func _fire(id: String, text: String, at: Vector3, view_from: Vector3) -> void:
	var r: Dictionary = rules[id]
	if r["fired"]:
		return
	r["fired"] = true
	stat[id]["find"] += 1
	var pic := "_shots/c2_%s.png" % id
	if _mr():
		_mr().ev("FIRE", {"rule": id, "text": text, "picture": pic})
	r["finding"] = "%s [%s] picture %s" % [text, scen, pic]
	_log("FIRE\t%s\t%s\t%s" % [id, scen, text])
	_snap(id, at, view_from)


## One picture from an observer camera (R2): nobody's view, moves nothing.
func _snap(id: String, at: Vector3, from: Vector3) -> void:
	if pt.get("headless"):
		return
	var sv := SubViewport.new()
	sv.size = Vector2i(800, 450)
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var cam := Camera3D.new()
	sv.add_child(cam)
	get_tree().root.add_child(sv)
	cam.look_at_from_position(from, at, Vector3.UP)
	cam.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img := sv.get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://_shots"))
	img.save_png("res://_shots/c2_%s.png" % id)
	sv.queue_free()


# --- the scenario boundary (from RigBeat.scen, c1's) ---------------------------

func _process(_d: float) -> void:
	sync()


## Called by PlayTest at each scenario's end too (the run may quit before
## the next frame).
func sync() -> void:
	var s: String = RigBeat.scen
	if s == scen:
		return
	if scen in WATCHED:
		_end_scenario()
	scen = s
	if scen in WATCHED:
		_t_scen = 0.0
		_static_done = false
		_win_open = false
		_frozen_t = 0.0
		_sunk_done = false
		_hud_bad_t = 0.0
		_swim_t = [0.0, 0.0]
		bad = {}
		absent = {}
		for id in stat:
			stat[id] = {"eval": 0, "win": 0, "err": 0, "find": 0}
		_log("START\t%s" % scen)
		preflight()


func _physics_process(delta: float) -> void:
	if not scen in WATCHED:
		return
	_t_scen += delta
	var r := _rj()
	var c := _van()
	if r == null or c == null:
		_bad("owner", "ramp_jump %s, camper %s" % ["found" if r != null else "MISSING", "found" if c != null else "MISSING"], "")
		return
	if not _static_done and _t_scen > 1.0:
		_static_done = true
		_static_checks(r)
	_g1_drift(r, c, delta)
	_g2_swim(delta)
	_g3_sunk(c, delta)
	_g4_hud(r, c, delta)


# --- G1: drift after the game's reset -------------------------------------------

func _g1_drift(r: Node, c: Camper, delta: float) -> void:
	if not _ok("G1", ["rj.failing", "van.parking_brake"]):
		return
	var pos := c.global_position
	# the game's reset: while it's failing, the van jumps back to the run-up
	if r.get("failing") and pos.distance_to(_van_last) > 5.0 and not _win_open:
		_win_open = true
		_win_t = 0.0
		_win_p0 = pos
		_win_brake_on_all = c.parking_brake
		_win_brake_last = c.parking_brake
		_log("LOOK\tG1\t%s\treset seen: van put back at %s, brake %s" % [scen, pos, "on" if c.parking_brake else "OFF"])
	_van_last = pos
	if not _win_open:
		return
	_win_t += delta
	var input := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_S) \
		or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D)
	var released := _win_brake_last and not c.parking_brake      # the driver's own release
	_win_brake_last = c.parking_brake
	if not c.parking_brake and not released:
		_win_brake_on_all = false
	if not (input or released or _win_t >= DRIFT_WINDOW):
		return
	_win_open = false
	var d := Vector2(pos.x - _win_p0.x, pos.z - _win_p0.z).length()
	_window("G1", _win_t >= DRIFT_WINDOW, {"secs": snappedf(_win_t, 0.01), "drift": snappedf(d, 0.001), "ended": "input" if input else ("brake released" if released else "full")})
	var why := "input" if input else ("brake released" if released else "%.0f s" % DRIFT_WINDOW)
	_look("G1", d)
	_log("LOOK\tG1\t%s\tdrift %.3f m in %.2f s (window ended: %s); brake on throughout: %s" % [scen, d, _win_t, why, _win_brake_on_all])
	if d > DRIFT_LIMIT:
		var cause := "the handbrake was OFF after the game's reset: the reset left it off" if not _win_brake_on_all \
			else "the brake was ON throughout: cause not named by this rule"
		_fire("G1", "the van moved %.2f m in %.1f s after the game's reset with no input; %s" % [d, _win_t, cause],
			pos, pos + Vector3(0, 5, 0) + c.global_transform.basis.x * 9.0)


# --- G2: swimming on dry ground --------------------------------------------------

func _g2_swim(delta: float) -> void:
	if not _ok("G2", ["boot.players", "p1.swimming", "p1._swim_y", "p1._swim_to", "p2.swimming", "p2._swim_y", "p2._swim_to"]):
		return
	var players: Array = boot.get("players")
	for i in players.size():
		var p := players[i] as PlayerRig
		if p == null or not p.swimming:
			_swim_t[i] = 0.0
			continue
		var water: float = float(p.get("_swim_y")) + 1.3
		# the real surface under the swimmer (a ray: Landscape.ground doesn't
		# carve the river channel, measured 2026-11-06 q1: +3.3 m mid-river)
		var q := PhysicsRayQueryParameters3D.create(p.global_position + Vector3.UP * 0.5, p.global_position + Vector3.DOWN * 6.0)
		var ex: Array[RID] = []
		for n in get_tree().get_nodes_in_group("player"):
			if n is CollisionObject3D:
				ex.append((n as CollisionObject3D).get_rid())
		q.exclude = ex
		var hit := p.get_world_3d().direct_space_state.intersect_ray(q)
		var above := -6.0 if hit.is_empty() else (hit["position"] as Vector3).y - water
		# Farther from the river than the bank point the game is taking them to
		# (PlayerRig._swim_to). A swimmer crosses dry bank in swim mode by design,
		# up to 16.4 m out of the channel by the far hut (q1, q2, q4); it heads
		# for its bank point, so it is never much farther out than that point.
		var out := _river_out(p.global_position)
		var bank: Vector3 = p.get("_swim_to")
		var past := out - _river_out(bank)
		_look("G2", past)
		if above > SWIM_DRY and past > SWIM_OUT:
			_swim_t[i] += delta
			if _swim_t[i] > SWIM_SECS:
				var far := ("%.1f m" % past) if past < 1000.0 else "far (no river near)"
				_fire("G2", "P%d is in swim mode on dry ground, %s farther from the river than the bank they swim to, for %.1f s (ground %.2f m above the water, at %s)" % [i + 1, far, _swim_t[i], above, p.global_position],
					p.global_position, p.global_position + Vector3(3, 3, 3))
		else:
			_swim_t[i] = 0.0


func _river_out(at: Vector3) -> float:
	return minf(Landscape.river_distance(at.x, at.z) - Landscape.RIVER_HALF, 1e6)


# --- G3: wheels / hub in the ground, van parked ---------------------------------

func _ground_under(at: Vector3, c: Camper) -> float:
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 1.5, at + Vector3.DOWN * 3.0)
	var ex: Array[RID] = [c.get_rid()]
	for n in get_tree().get_nodes_in_group("player"):
		if n is CollisionObject3D:
			ex.append((n as CollisionObject3D).get_rid())
	q.exclude = ex
	var hit := c.get_world_3d().direct_space_state.intersect_ray(q)
	if hit.is_empty():
		return NAN
	return (hit["position"] as Vector3).y


func _g3_sunk(c: Camper, delta: float) -> void:
	if not _ok("G3", ["van.freeze", "van._wheel_meshes", "van._wheels", "van._bare_hub"]):
		return
	if not c.freeze:
		_frozen_t = 0.0
		_sunk_done = false
		return
	_frozen_t += delta
	if _sunk_done or _frozen_t < 0.5:
		return
	_sunk_done = true          # once per parked spell, steady (frozen 0.5 s)
	var parts: Array = []
	for i in c._wheel_meshes.size():
		var m := c._wheel_meshes[i] as Node3D
		if m.is_visible_in_tree():
			parts.append(["tyre%d" % i, m.global_position, Camper.WHEEL_RADIUS])
	if c._bare_hub != null and c._bare_hub.is_visible_in_tree():
		parts.append(["bare hub", c._bare_hub.global_position, Camper.WHEEL_RADIUS * 0.5])
	_g3b_attach(c)
	var worst := INF
	var worst_part = null
	var txt := ""
	var probes_ok := true
	for pa in parts:
		var at: Vector3 = pa[1]
		var g := _ground_under(at, c)
		if is_nan(g):
			# a required ground probe that fails is an invalid observation (M8)
			probes_ok = false
			_bad("probe.G3." + str(pa[0]), "no ground hit under the %s at %s" % [pa[0], at], "G3")
			continue
		var dep: float = at.y - float(pa[2]) - g
		txt += " %s %+.3f" % [pa[0], dep]
		if dep < worst:
			worst = dep
			worst_part = pa
	_window("G3", probes_ok and worst_part != null, {"parts": parts.size()})
	if worst_part == null:
		return
	_look("G3", worst)
	_log("LOOK\tG3\t%s\tparked: bottom vs ground under it:%s" % [scen, txt])
	if worst < SUNK_LIMIT:
		var at2: Vector3 = worst_part[1]
		_fire("G3", "the van's %s sits %.2f m into the ground (parked, steady 0.5 s) at %s" % [worst_part[0], -worst, at2],
			at2, at2 + (at2 - c.global_position).normalized() * 3.0 + Vector3(0, 0.6, 0))


## G3b (M8): each visible part's centre in its own wheel's frame against the
## construction's centre (Camper.gd: the Tyre at zero in its Spin holder, the
## holder at zero on the wheel, only rotated / scaled about its centre; the
## BareHub at zero on wheel 0). The residual is logged; the host judges it
## against the tolerance frozen in tools/method/frozen.json from the clean runs.
func _g3b_attach(c: Camper) -> void:
	var res: Array = []
	var worst := 0.0
	var worst_part := ""
	for i in c._wheels.size():
		var wh := c._wheels[i] as Node3D
		if wh == null or not is_instance_valid(wh):
			_absent("van._wheels[%d]" % i, "null / freed", "G3b")
			continue
		var inv := wh.global_transform.affine_inverse()
		if i < c._wheel_meshes.size():
			var holder := c._wheel_meshes[i] as Node3D
			var tyre: Node3D = holder.get_node_or_null("Tyre") as Node3D if holder != null and is_instance_valid(holder) else null
			if tyre == null:
				_absent("van.wheel%d.Tyre" % i, "no Tyre mesh under the wheel's Spin holder", "G3b")
			elif tyre.is_visible_in_tree():
				var r := inv * tyre.global_position
				res.append(["tyre%d" % i, snappedf(r.length(), 0.0001), [snappedf(r.x, 0.0001), snappedf(r.y, 0.0001), snappedf(r.z, 0.0001)]])
				if r.length() > worst:
					worst = r.length()
					worst_part = "tyre%d" % i
		if i == 0 and c._bare_hub != null and c._bare_hub.is_visible_in_tree():
			var rh := inv * c._bare_hub.global_position
			res.append(["bare hub", snappedf(rh.length(), 0.0001), [snappedf(rh.x, 0.0001), snappedf(rh.y, 0.0001), snappedf(rh.z, 0.0001)]])
			if rh.length() > worst:
				worst = rh.length()
				worst_part = "bare hub"
	if res.is_empty():
		return
	rules["G3b"]["looks"] += 1
	(rules["G3b"]["vals"] as Array).append(worst)
	stat["G3b"]["eval"] += 1
	_window("G3b", true, {"parts": res.size()})
	_log("LOOK\tG3b\t%s\tparked: centre on own wheel vs built %s" % [scen, str(res)])
	if _mr():
		_mr().ev("G3B", {"res": res, "worst": snappedf(worst, 0.0001), "worst_part": worst_part, "van_at": [snappedf(c.global_position.x, 0.01), snappedf(c.global_position.y, 0.01), snappedf(c.global_position.z, 0.01)]})


# --- G4: the HUD's wheel warning vs the physical wheel ----------------------------

func _g4_hud(r: Node, c: Camper, delta: float) -> void:
	if not _ok("G4", ["boot.huds", "hud0._warn", "rj.van_wheel", "van._wheel_meshes"]):
		return
	var huds: Array = boot.get("huds")
	var w0 := c._wheel_meshes[0] as Node3D
	var wheel_obj = r.get("van_wheel")
	var away := false
	if wheel_obj != null and is_instance_valid(wheel_obj):
		away = (wheel_obj as Node3D).global_position.distance_to(w0.global_position) > 1.5
	var gone := (not w0.visible) or away
	var bad := ""
	var looked := false
	for h in huds:
		var hud := h as PlayerHUD
		if hud == null or not hud.is_visible_in_tree():
			continue
		var t := hud._warn.text
		if t == "":
			continue
		if gone:
			looked = true
			if t.contains("PUNCTURE"):
				bad = "the HUD says '%s' while the front-left wheel is physically gone (mesh shown: %s, the wheel %s)" % [t, w0.visible, "away from the hub" if away else "not loose"]
		elif t.contains("ON THE HUB"):
			looked = true
			bad = "the HUD says '%s' while the front-left wheel is on (mesh shown, no loose wheel)" % t
	if looked:
		_look("G4", 1.0 if bad != "" else 0.0)
	if bad == "":
		_hud_bad_t = 0.0
		return
	_hud_bad_t += delta
	if _hud_bad_t > HUD_SECS:
		_fire("G4", bad, w0.global_position, w0.global_position + (w0.global_position - c.global_position).normalized() * 3.5 + Vector3(0, 1.0, 0))


# --- D1, D2: the built world, read once per watched scenario ----------------------

func _static_checks(r: Node) -> void:
	var hut: Node3D = null
	if _ok("D1", ["rj.hut", "rj._window"]):
		hut = r.get("hut") as Node3D
	if hut != null:
		var hx := hut.global_transform
		var ws := 1.0 if (hx.affine_inverse() * (r as Node3D).global_position).x > 0.0 else -1.0
		# the spot: outside the window's wall, at its foot, under the window
		# (the window's middle comes from the game's own _window)
		var win: Vector3 = r.get("_window")
		var spot := hx * Vector3(win.x + ws * 0.85, 0.5, win.z)
		var box := BoxShape3D.new()
		box.size = Vector3(1.0, 0.7, 1.2)
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = box
		q.transform = Transform3D(hx.basis.orthonormalized(), spot)
		var names := _solids_in(q, hut)
		# the margin: the same box grown 1 m out from the wall and 1 m each side
		var q2 := PhysicsShapeQueryParameters3D.new()
		var box2 := BoxShape3D.new()
		box2.size = Vector3(2.0, 0.7, 3.2)
		q2.shape = box2
		q2.transform = Transform3D(hx.basis.orthonormalized(), spot + hx.basis.x.normalized() * ws * 0.5)
		var near := _solids_in(q2, hut)
		_look("D1", float(names.size()))
		_log("LOOK\tD1\t%s\tcrate spot %s: %d fixed solid(s) in it %s; within 1 m more: %d %s" % [scen, spot, names.size(), names, near.size(), near])
		if names.size() > 0:
			_fire("D1", "the crate's spot under the window is taken by %s" % ", ".join(names), spot, spot + hx.basis.x * ws * 5.0 + Vector3(0, 3, 0))
	var wreck := (r as Node).get_node_or_null("RiverWreck/WreckCar") as Node3D
	if wreck == null:
		# validly bound ramp_jump, the wreck node it builds is not there (M5)
		_absent("rj.RiverWreck/WreckCar", "node not found under the ramp jump", "D2")
	if wreck != null and not _ok("D2", ["rj.water_y"]):
		wreck = null
	if wreck != null:
		var top := -INF
		var meshes := wreck.find_children("*", "MeshInstance3D", true, false)
		if meshes.is_empty():
			_absent("rj.WreckCar meshes", "the wreck has no mesh (empty required mesh set)", "D2")
			return
		for m in meshes:
			var mi := m as MeshInstance3D
			var bb := mi.global_transform * mi.get_aabb()
			top = maxf(top, bb.end.y)
		var water: float = r.get("water_y")
		_look("D2", top - water)
		_log("LOOK\tD2\t%s\twreck: top %.2f m %s the water (middle %.2f m)" % [scen, absf(top - water), "above" if top >= water else "UNDER", wreck.global_position.y - water])
		if top < water:
			_fire("D2", "the river wreck is under the water: its top %.2f m below it, at %s" % [water - top, wreck.global_position],
				wreck.global_position, wreck.global_position + Vector3(0, 6, 0) + (r as Node3D).global_transform.basis.x * -8.0)


## Fixed solids (static bodies, not the terrain) in a box. Things players
## carry (the crate) are rigid bodies and don't count.
func _solids_in(q: PhysicsShapeQueryParameters3D, n: Node3D) -> Array:
	q.collide_with_areas = false
	var names: Array = []
	for h in n.get_world_3d().direct_space_state.intersect_shape(q, 16):
		var o = h["collider"]
		if not (o is StaticBody3D) or (o as Node).name == "Terrain":
			continue
		names.append(str((o as Node).name) + "@" + str((o as Node3D).global_position.snapped(Vector3.ONE * 0.01)))
	return names


# --- D3: the door walk (run by PlayTest.t_c2_more, reported here) -------------------

func door_result(reached: bool, crossed: bool, short_m: float, at: Vector3, door_at: Vector3) -> void:
	if not reached:
		_log("NOTREACHED\tD3\t%s\tsetup didn't hold" % scen)
		return
	_look("D3", short_m)
	_log("LOOK\tD3\t%s\tP1 on W: %s; %.2f m short of the door line at the end" % [scen, "in through the door" if crossed else "NOT in", short_m])
	if not crossed:
		_fire("D3", "P1 holding W from 2 m outside the open door is stuck %.2f m short of the door line, at %s" % [short_m, at], door_at, door_at + (at - door_at).normalized() * 4.0 + Vector3(0, 2.5, 0))


# --- the verdict -------------------------------------------------------------------

func _end_scenario() -> void:
	_log("END\t%s" % scen)
	if _mr():
		_mr().ev("RULES", {"scen_end": scen, "stat": stat.duplicate(true), "reached": rules.keys().filter(func(k): return rules[k]["looks"] > 0)})
	var fired := 0
	var lines: Array = []
	for kind in ["generic", "declared"]:
		lines.append("  %s rules:" % kind)
		for id in rules:
			var r: Dictionary = rules[id]
			if r["kind"] != kind:
				continue
			var vals: Array = r["vals"]
			var st := "NOT REACHED"
			if r["fired"]:
				st = "FIRED: " + str(r["finding"])
				fired += 1
			elif r["looks"] > 0:
				st = "clean"
			var rng := ""
			if vals.size() > 0:
				rng = " values %.3f..%.3f" % [vals.min(), vals.max()]
			lines.append("    %s looked %d%s: %s" % [id, r["looks"], rng, st])
			lines.append("       (%s)" % r["what"])
	var head := "==== C2 STATE CHECKS: %s (after %s) ====" % [("%d rule(s) FIRED" % fired) if fired > 0 else "no rule fired", scen]
	var reached := 0
	for id in rules:
		if rules[id]["looks"] > 0 or rules[id]["fired"]:
			reached += 1
	var txt := head + "\n  reached %d / 7 rules; a rule not reached is neither a pass nor a fail (R12)\n" % reached + "\n".join(lines) + \
		"\n  The driver's own result (a miss, a drive-off) is not c2's verdict: see the rig's INNER CHECKS.\n"
	var fa := FileAccess.open(dir.path_join("c2_verdict.txt"), FileAccess.WRITE)
	if fa != null:
		fa.store_string(txt)
		fa.close()
