## (no class_name: preloaded by LiveControl, test only)
extends RefCounted

## Resume fix v1 (2026-11-17; design notes/speed_research/resume_fix_design.md v2, audited by GPT before
## the build). A save point is the game's save + LiveControl's live part; this adds what a restore still
## lost, so a resume can come back SAME as the fresh run that made the point:
##  - live_bodies: the van's and every carryable's freeze / freeze_mode / sleeping / STORED velocities
##    (SaveGame.apply unfreezes the van and zeroes them; a frozen van's stale stored speed is kept as it was)
##  - live_vars: plain script vars of the van, its VanAttack, every carryable and both players
##    (engine_on, nav_aside, _safe_t, ...); objects are skipped (their owners rebuild them)
##  - live_players: full transform + velocity (a game save keeps position and yaw only, zeroes velocity)
##  - live_problem_children: Problem's built children (by child index: names are per process), their
##    local transforms and script vars, the eye / glow material (its _show sets them every frame)
##  - live_clock + live_hearing: every wall-clock stamp as an AGE (typed: ms / s, unset sentinel kept),
##    and the hearing queue (ids, ages) + its serial: put back as now - age, again right before each
##    observation and at release, so ages stay frozen through the paused hold
##  - rng_seed (seed-v1): the global RNG is seeded with it right before the step's first action, in the
##    fresh run and in the resume alike
## Test-only drops (GATE_DROP=hearing / vars / bodies): skip one restore, for the planted controls.

const VERSION := "rv1"
const SEED_PROTO := "seed-v1"
## [owner, field, unit, unset sentinel or null]; the gate's inventory "wallstamps" lists the same three
const STAMPS := [["problem", "_item_ms", "ms", -99999], ["item", "_last_hit_t", "ms", 0], ["van", "_cap_t", "s", null]]

var lc
var pt: PlayTest


func _init(l) -> void:
	lc = l
	pt = l.pt


static func _now(unit: String) -> float:
	return float(Time.get_ticks_msec()) if unit == "ms" else Time.get_ticks_msec() / 1000.0


func _items() -> Array:
	var out: Array = []
	for n in pt.get_tree().get_nodes_in_group("carryable"):
		if n is Carryable and not (n as Node).is_queued_for_deletion():
			out.append(n)
	out.sort_custom(func(x, y): return String(x.name) < String(y.name))
	return out


func _problem() -> Creature:
	var gh := pt.get_tree().get_first_node_in_group("ghat") as Ghat
	if gh != null and gh.problem != null and is_instance_valid(gh.problem):
		return gh.problem
	return null


func _owner(own: String) -> Object:
	if own == "van":
		return pt.boot.camper
	if own == "problem":
		return _problem()
	if own.begins_with("item:"):
		return pt.boot.world.find_child(own.substr(5), true, false)
	return null


func _body(key: String, b: RigidBody3D) -> Dictionary:
	# xf bit-exact (R1: SaveGame's float arrays came back 1 ulp off on every item and the van)
	return {"key": key, "freeze": b.freeze, "freeze_mode": int(b.freeze_mode), "sleeping": b.sleeping,
		"lv": var_to_str(b.linear_velocity), "av": var_to_str(b.angular_velocity),
		"xf": Marshalls.raw_to_base64(var_to_bytes(b.global_transform))}


## Physics-frame stamps (they keep counting while the tree is paused: R1's hold +15 frames in 209 ms):
## saved as AGES, put back as now - age. [owner, field, kind, unset sentinel]
const FRAMES := [["attack", "_last_pull", "dict", null], ["attack", "_hold_start", "dict", null],
	["attack", "_done_f", "int", -1], ["players", "_climb_since", "int", 0]]


func _frame_owners(own: String) -> Array:
	if own == "attack":
		return [["attack", pt.boot.camper.attack]] if pt.boot.camper.attack != null else []
	var out: Array = []
	for i in pt.boot.players.size():
		out.append(["p%d" % i, pt.boot.players[i]])
	return out


func _frame_ages(pf: int) -> Array:
	var out: Array = []
	for s in FRAMES:
		for ow in _frame_owners(String(s[0])):
			var v = (ow[1] as Object).get(String(s[1]))
			if s[2] == "dict":
				var d := {}
				for k in v:
					if k is PlayerRig:
						d[str(pt.boot.players.find(k))] = pf - int(v[k])
				out.append({"own": ow[0], "field": s[1], "kind": "dict", "ages": d})
			elif s[3] != null and int(v) == int(s[3]):
				out.append({"own": ow[0], "field": s[1], "kind": "int", "unset": true})
			else:
				out.append({"own": ow[0], "field": s[1], "kind": "int", "unset": false, "age": pf - int(v)})
	return out


func _apply_frames(point: Dictionary) -> void:
	var now := Engine.get_physics_frames()
	for e in point.get("live_frames", []):
		var o: Object = null
		var own := String(e["own"])
		if own == "attack":
			o = pt.boot.camper.attack
		elif own.begins_with("p"):
			o = pt.boot.players[int(own.substr(1))]
		if o == null:
			continue
		if String(e["kind"]) == "dict":
			var d := {}
			for k in e["ages"]:
				d[pt.boot.players[int(k)]] = now - int(e["ages"][k])
			o.set(String(e["field"]), d)
		elif bool(e["unset"]):
			for s in FRAMES:
				if s[1] == e["field"]:
					o.set(String(e["field"]), s[3])
		else:
			o.set(String(e["field"]), now - int(e["age"]))


func _clock_ages(wall: int = -1) -> Array:
	var out: Array = []
	for s in STAMPS:
		var owners: Array = []
		if s[0] == "item":
			for it in _items():
				owners.append("item:" + String(it.name))
		else:
			owners.append(String(s[0]))
		for own in owners:
			var o := _owner(own)
			if o == null:
				continue
			var v = o.get(String(s[1]))
			var nw := _now(String(s[2])) if wall < 0 else (float(wall) if s[2] == "ms" else wall / 1000.0)
			if s[3] != null and v == s[3]:
				out.append({"own": own, "field": s[1], "unit": s[2], "unset": true})
			else:
				out.append({"own": own, "field": s[1], "unit": s[2], "unset": false, "age": nw - float(v)})
	return out


## Index path from the creature to each built child ("2/0/3"): names are per process.
func _walk_children(root: Node, n: Node, path: String, out: Array) -> void:
	for i in n.get_child_count():
		var ch := n.get_child(i)
		var p := ("%s/%d" % [path, i]) if path != "" else str(i)
		out.append([p, ch])
		_walk_children(root, ch, p, out)


func _children_snap(pr: Creature) -> Dictionary:
	var kids: Array = []
	_walk_children(pr, pr, "", kids)
	var xf := {}
	var vars := {}
	for e in kids:
		var ch: Node = e[1]
		if ch is Node3D:
			xf[e[0]] = var_to_str((ch as Node3D).transform)
		if ch.get_script() != null:
			vars[e[0]] = lc._snap_vars(ch)
	var d := {"count": kids.size(), "xf": xf, "vars": vars}
	var em = pr.get("_eye_mat")
	var gm = pr.get("_glow_mat")
	if em is StandardMaterial3D:
		d["eye_energy"] = var_to_str((em as StandardMaterial3D).emission_energy_multiplier)
	if gm is StandardMaterial3D:
		d["glow_color"] = var_to_str((gm as StandardMaterial3D).albedo_color)
	return d


## At a point (fresh run or a resumed run's own points), same tick as SaveGame.collect. Ages are taken
## at the point's observation (its wall clock and physics frame), the moment layer 2 compares against.
func collect(point: Dictionary, obs_wall: int, obs_frames: int) -> void:
	point["resume_v"] = VERSION
	point["seed_proto"] = SEED_PROTO
	point["rng_seed"] = int(hash(String(point.get("point_id", "")))) & 0x7fffffff
	point["wall_ms"] = obs_wall
	point["phys_frame"] = obs_frames
	point["live_frames"] = _frame_ages(obs_frames)
	var c0: Camper = pt.boot.camper
	var refs := {"targets": [], "window_fog": {}}
	for p in pt.boot.players:
		var t = (p as Object).get("current_target")
		refs["targets"].append(String((t as Node).get_path()) if t is Node and is_instance_valid(t) and (t as Node).is_inside_tree() else "")
	for role in c0._window_fog:
		refs["window_fog"][role] = c0.window_fog(role)
	point["live_refs"] = refs
	var c: Camper = pt.boot.camper
	var bodies: Array = [_body("van", c)]
	var ivars := {}
	for it in _items():
		bodies.append(_body("item:" + String(it.name), it))
		ivars[String(it.name)] = lc._snap_vars(it)
	point["live_bodies"] = bodies
	var pvars: Array = []
	var pls: Array = []
	for p in pt.boot.players:
		pvars.append(lc._snap_vars(p))
		pls.append({"xf": var_to_str((p as Node3D).global_transform), "vel": var_to_str((p as CharacterBody3D).velocity)})
	point["live_vars"] = {"van": lc._snap_vars(c), "attack": lc._snap_vars(c.attack) if c.attack != null else {},
		"items": ivars, "players": pvars}
	point["live_players"] = pls
	point["live_clock"] = _clock_ages(obs_wall)
	var ev: Array = []
	var now := obs_wall
	for s in Hearing.recent:
		ev.append({"id": int(s["id"]), "pos": var_to_str(s["pos"]), "radius": float(s["radius"]),
			"what": String(s["what"]), "age": now - int(s["t"])})
	point["live_hearing"] = {"next_id": Hearing._next_id, "events": ev}
	var pr := _problem()
	if pr != null:
		point["live_problem_children"] = _children_snap(pr)


## Ages back to stamps on this process's clock (called after the restore, before each observation and
## at release: the ages stay as they were at the point while the world is held paused).
func apply_clock(point: Dictionary, drop: Array) -> void:
	_apply_frames(point)
	for e in point.get("live_clock", []):
		var o := _owner(String(e["own"]))
		if o == null:
			continue
		var sentinel = null
		for s in STAMPS:
			if s[1] == e["field"]:
				sentinel = s[3]
		if bool(e["unset"]):
			o.set(String(e["field"]), sentinel)
		elif String(e["unit"]) == "ms":
			o.set(String(e["field"]), int(round(_now("ms") - float(e["age"]))))
		else:
			o.set(String(e["field"]), _now("s") - float(e["age"]))
	if "hearing" in drop:
		return
	var h: Dictionary = point.get("live_hearing", {})
	var now := Time.get_ticks_msec()
	var rec: Array = []
	for s in h.get("events", []):
		rec.append({"id": int(s["id"]), "pos": str_to_var(String(s["pos"])), "radius": float(s["radius"]),
			"t": now - int(s["age"]), "what": String(s["what"])})
	Hearing.recent = rec
	Hearing._next_id = int(h.get("next_id", Hearing._next_id))


## After SaveGame.apply + LiveControl's live restore (puzzle vars, creature, held, Naresh).
func restore(point: Dictionary, drop: Array) -> void:
	var c: Camper = pt.boot.camper
	var v: Dictionary = point.get("live_vars", {})
	if not "vars" in drop:
		lc._unsnap_vars(c, v.get("van", {}))
		if c.attack != null:
			lc._unsnap_vars(c.attack, v.get("attack", {}))
		var iv: Dictionary = v.get("items", {})
		for it in _items():
			if iv.has(String(it.name)):
				lc._unsnap_vars(it, iv[String(it.name)])
		var pv: Array = v.get("players", [])
		for i in mini(pv.size(), pt.boot.players.size()):
			lc._unsnap_vars(pt.boot.players[i], pv[i])
	var pls: Array = point.get("live_players", [])
	for i in mini(pls.size(), pt.boot.players.size()):
		var p: CharacterBody3D = pt.boot.players[i]
		p.global_transform = str_to_var(String(pls[i]["xf"]))
		p.velocity = str_to_var(String(pls[i]["vel"]))
		p.reset_physics_interpolation()
	if not "bodies" in drop:
		for b in point.get("live_bodies", []):
			var o := _owner(String(b["key"]))
			if not (o is RigidBody3D):
				continue
			var rb := o as RigidBody3D
			if b.has("xf"):
				rb.global_transform = bytes_to_var(Marshalls.base64_to_raw(String(b["xf"])))
				rb.reset_physics_interpolation()
			rb.freeze_mode = int(b["freeze_mode"]) as RigidBody3D.FreezeMode
			rb.freeze = bool(b["freeze"])
			rb.linear_velocity = str_to_var(String(b["lv"]))
			rb.angular_velocity = str_to_var(String(b["av"]))
			rb.sleeping = bool(b["sleeping"])
	var pr := _problem()
	var cd: Dictionary = point.get("live_problem_children", {})
	if pr != null and not cd.is_empty():
		var kids: Array = []
		_walk_children(pr, pr, "", kids)
		var byp := {}
		for e in kids:
			byp[e[0]] = e[1]
		for p in cd.get("xf", {}):
			if byp.has(p) and byp[p] is Node3D:
				(byp[p] as Node3D).transform = str_to_var(String(cd["xf"][p]))
		for p in cd.get("vars", {}):
			if byp.has(p):
				lc._unsnap_vars(byp[p], cd["vars"][p])
		var em = pr.get("_eye_mat")
		if em is StandardMaterial3D and cd.has("eye_energy"):
			(em as StandardMaterial3D).emission_energy_multiplier = str_to_var(String(cd["eye_energy"]))
		var gm = pr.get("_glow_mat")
		if gm is StandardMaterial3D and cd.has("glow_color"):
			(gm as StandardMaterial3D).albedo_color = str_to_var(String(cd["glow_color"]))
		pr.reset_physics_interpolation()
	# references a plain-var snapshot skips (R1): what each player looks at, the van's window mist meshes
	var refs: Dictionary = point.get("live_refs", {})
	var tg: Array = refs.get("targets", [])
	for i in mini(tg.size(), pt.boot.players.size()):
		(pt.boot.players[i] as Object).set("current_target", pt.get_tree().root.get_node_or_null(NodePath(String(tg[i]))) if String(tg[i]) != "" else null)
	var wf: Dictionary = refs.get("window_fog", {})
	for role in wf:
		c.fog_window(String(role), 0.0)
		var m: MeshInstance3D = c._window_fog.get(role)
		if m != null:
			(m.material_override as StandardMaterial3D).albedo_color.a = float(wf[role])
			m.visible = float(wf[role]) > 0.01
	apply_clock(point, drop)
