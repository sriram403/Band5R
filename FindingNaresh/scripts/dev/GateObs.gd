## (no class_name: preloaded by LiveControl, so a fresh copy needs no import to find it)
extends RefCounted

## T4 v2 (speed research, test only): an independent observation of the world a walk's resume
## gate compares (tools/method/walkgate.py judges it; this only reads, never writes the world).
## It does NOT reuse the save-point serializer: it reads every script variable of the scoped
## objects itself, plus the engine-side state a script variable doesn't hold (physics, children's
## transforms, the eye material, the hum, statics, held inputs, open work).
## Scope (T4 v2 "scoped field inventory"): the ghat node, Problem and its children, the van
## (Camper) and its VanAttack, both players, every carryable, the van's physics, the mood's fog,
## the story's step, Hearing's and Creature's statics, the tree's running tweens, the inputs held
## and the walk's open work. Values are canonical strings (var_to_str for plain values, a reference
## descriptor for objects) so two observations compare exactly.

const KEYS := [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_SPACE, KEY_CTRL, KEY_E, KEY_X, KEY_F, KEY_L, KEY_R, KEY_C, KEY_ESCAPE, KEY_H, KEY_Q, KEY_TAB]


static func observe(pt: PlayTest, extra: Dictionary = {}) -> Dictionary:
	# resume fix v1: the clocks are read at the START (a big observation takes ~20 ms; the ages it shows
	# are from this moment, the one a resume's re-applied clocks line up with)
	var wall0 := Time.get_ticks_msec()
	var pf0 := Engine.get_physics_frames()
	var f := {}
	var b := pt.boot
	var gh := pt.get_tree().get_first_node_in_group("ghat") as Ghat
	if gh != null:
		_vars(f, "ghat.", gh, pt)
		var pr = gh.problem
		if pr is Creature and is_instance_valid(pr):
			_vars(f, "problem.", pr, pt)
			_node3d(f, "problem.@", pr as Node3D)
			_children(f, "problem/", pr, pr, pt)
	var c: Camper = b.camper
	if c != null:
		_vars(f, "van.", c, pt)
		f["van.@xf"] = var_to_str(c.global_transform)
		f["van.@lv"] = var_to_str(c.linear_velocity)
		f["van.@av"] = var_to_str(c.angular_velocity)
		f["van.@sleeping"] = var_to_str(c.sleeping)
		f["van.@freeze"] = var_to_str(c.freeze)
		f["van.@exceptions"] = _exc(c, pt)
		if c.attack != null:
			_vars(f, "van.attack.", c.attack, pt)
	for i in b.players.size():
		var p: PlayerRig = b.players[i]
		_vars(f, "p%d." % (i + 1), p, pt)
		f["p%d.@xf" % (i + 1)] = var_to_str(p.global_transform)
		f["p%d.@vel" % (i + 1)] = var_to_str(p.velocity)
		# resume fix v1 (GPT audit #2): the body a script var doesn't hold
		var col := p.get_node_or_null("Collider") as CollisionShape3D
		f["p%d.@capsule" % (i + 1)] = "none" if col == null or not (col.shape is CapsuleShape3D) else "%s:%s:%s" % [
			var_to_str((col.shape as CapsuleShape3D).height), var_to_str(col.position), col.disabled]
		f["p%d.@exceptions" % (i + 1)] = _exc(p, pt)
		f["p%d.@layers" % (i + 1)] = "%d:%d" % [p.collision_layer, p.collision_mask]
	var items: Array = []
	for n in pt.get_tree().get_nodes_in_group("carryable"):
		if n is Carryable and not (n as Node).is_queued_for_deletion():
			items.append(n)
	items.sort_custom(func(x, y): return String(x.name) < String(y.name))
	for it in items:
		var k := "item[%s]." % _nm(String(it.name))
		_vars(f, k, it, pt)
		f[k + "@xf"] = var_to_str((it as Node3D).global_transform)
		f[k + "@lv"] = var_to_str((it as RigidBody3D).linear_velocity)
		f[k + "@av"] = var_to_str((it as RigidBody3D).angular_velocity)
		f[k + "@sleeping"] = var_to_str((it as RigidBody3D).sleeping)
		# resume fix v1 (GPT audit #2): stow / hold links and collision state
		var rb := it as RigidBody3D
		f[k + "@freeze"] = "%s:%d" % [rb.freeze, int(rb.freeze_mode)]
		f[k + "@parent"] = _ref(rb.get_parent(), pt)
		f[k + "@layers"] = "%d:%d:%d" % [rb.collision_layer, rb.collision_mask, int(rb.process_mode)]
		f[k + "@exceptions"] = _exc(rb, pt)
	var mood := pt.get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		f["mood.@value"] = var_to_str(mood.value)
		f["mood.@fog_boost"] = var_to_str(mood.fog_boost)
	if b.story != null:
		f["story.@id"] = var_to_str(String(b.story.current()["id"]))
	var nz = b.naresh
	f["naresh.@present"] = var_to_str(nz != null and is_instance_valid(nz))
	# statics (T4 v2 D4 A: classified, observed where they can be)
	var rec: Array = []
	for s in Hearing.recent:
		rec.append({"id": int(s["id"]), "t": int(s["t"]), "what": String(s["what"]), "pos": var_to_str(s["pos"]), "r": float(s["radius"])})
	f["static.Hearing.recent"] = JSON.stringify(rec)
	f["static.Hearing._next_id"] = var_to_str(Hearing._next_id)
	f["static.Creature.on_return"] = var_to_str(Creature.on_return)
	f["static.Creature.funnels"] = var_to_str(Creature.funnels.size())
	f["static.TagMarker.live"] = var_to_str(TagMarker.live.size())
	f["tree.@tweens"] = var_to_str(pt.get_tree().get_processed_tweens().size())
	# inputs held right now (a boundary with a held input is refused)
	var held: Array = []
	for k in KEYS:
		if Input.is_physical_key_pressed(k):
			held.append("key:%d" % k)
	for bt in range(JOY_BUTTON_SDL_MAX):
		if Input.is_joy_button_pressed(0, bt as JoyButton):
			held.append("pad:%d" % bt)
	for a in range(JOY_AXIS_SDL_MAX):
		if absf(Input.get_joy_axis(0, a as JoyAxis)) > 0.0:
			held.append("axis:%d" % a)
	for m in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if Input.is_mouse_button_pressed(m):
			held.append("mouse:%d" % m)
	f["input.@held"] = JSON.stringify(held)
	f["test.@helpers_running"] = var_to_str(pt.helpers_running)
	for k in extra:
		f[k] = str(extra[k])
	return {"fields": f, "meta": {"wall_ms": wall0, "game_ms": PlayTest.gms(),
		"physics_frames": pf0, "frames_drawn": Engine.get_frames_drawn(),
		"pid": OS.get_process_id(), "recording": Engine.get_write_movie_path() != ""}}


## Which bodies it ignores, by identity (GPT results audit #3: a count hides a swapped body).
static func _exc(b: PhysicsBody3D, pt: PlayTest) -> String:
	var out: Array = []
	for e in b.get_collision_exceptions():
		out.append(_ref(e, pt))
	out.sort()
	return "[" + ", ".join(out) + "]"


## Auto-named nodes ("@Node3D@123") get a per-process number: volatile process metadata.
static func _nm(n: String) -> String:
	if n.begins_with("@"):
		var parts := n.split("@")
		if parts.size() >= 3:
			return "@%s@#" % parts[1]
	return n


static func _ref(v, pt: PlayTest) -> String:
	if typeof(v) == TYPE_NIL:
		return "null"
	if v is PlayerRig:
		return "player:%d" % pt.boot.players.find(v)
	if v is Callable:
		var cb := v as Callable
		var o = cb.get_object() if cb.is_valid() else null
		return "callable:%s:%s:%s" % [cb.is_valid(), "null" if o == null else String(o.get_class()) + ("/" + _nm(String((o as Node).name)) if o is Node else ""), cb.get_method()]
	if v is Object and not is_instance_valid(v):
		return "freed"
	if v is Node:
		var n := v as Node
		if not n.is_inside_tree():
			return "node-outside:" + _nm(String(n.name))
		var parts: Array = []
		for s in String(n.get_path()).split("/"):
			parts.append(_nm(s))
		return "node:" + "/".join(parts)
	if v is StandardMaterial3D:
		var m := v as StandardMaterial3D
		return "mat:%s:%s:%s:%s" % [var_to_str(m.albedo_color), m.emission_enabled, var_to_str(m.emission), var_to_str(m.emission_energy_multiplier)]
	if v is RandomNumberGenerator:
		return "rng:state=%d" % (v as RandomNumberGenerator).state
	if v is Resource:
		return "res:%s:%s" % [(v as Resource).get_class(), (v as Resource).resource_path]
	if v is Object:
		return "obj:" + (v as Object).get_class()
	return ""


static func _val(v, pt: PlayTest) -> String:
	var t := typeof(v)
	if t == TYPE_NIL:
		return "null"
	if t == TYPE_OBJECT or t == TYPE_CALLABLE:
		return _ref(v, pt)
	if t == TYPE_ARRAY:
		var out: Array = []
		for x in v:
			out.append(_val(x, pt))
		return "[" + ", ".join(out) + "]"
	if t == TYPE_DICTIONARY:
		var keys: Array = (v as Dictionary).keys()
		var out2: Array = []
		for k in keys:
			out2.append(_val(k, pt) + ": " + _val(v[k], pt))
		out2.sort()
		return "{" + ", ".join(out2) + "}"
	if t == TYPE_SIGNAL:
		return "signal"
	return var_to_str(v)


static func _vars(f: Dictionary, prefix: String, o: Object, pt: PlayTest) -> void:
	for p in o.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		f[prefix + String(p["name"])] = _val(o.get(p["name"]), pt)


static func _node3d(f: Dictionary, k: String, n: Node3D) -> void:
	f[k + "xf"] = var_to_str(n.global_transform)


## Problem's children: each Node3D's local transform, a mesh's material emission, an audio
## player's playing / pitch / volume, any Timer's time left, and each child's own script vars.
static func _children(f: Dictionary, prefix: String, root: Node, n: Node, pt: PlayTest) -> void:
	for ch in n.get_children():
		var rel := ""
		for s in String(root.get_path_to(ch)).split("/"):
			rel += ("/" if rel != "" else "") + _nm(s)
		var k := prefix + rel
		if ch is Node3D:
			f[k + ".@local"] = var_to_str((ch as Node3D).transform)
			f[k + ".@visible"] = var_to_str((ch as Node3D).visible)
		if ch is MeshInstance3D:
			var mi := ch as MeshInstance3D
			var mat = mi.material_override if mi.material_override != null else (mi.get_surface_override_material(0) if mi.get_surface_override_material_count() > 0 else null)
			f[k + ".@mat"] = _ref(mat, pt)
		if ch is AudioStreamPlayer3D:
			var ap := ch as AudioStreamPlayer3D
			f[k + ".@audio"] = "%s:%s:%s" % [ap.playing, var_to_str(ap.pitch_scale), var_to_str(ap.volume_db)]
		if ch is AudioStreamPlayer:
			var ap2 := ch as AudioStreamPlayer
			f[k + ".@audio"] = "%s:%s:%s" % [ap2.playing, var_to_str(ap2.pitch_scale), var_to_str(ap2.volume_db)]
		if ch is Timer:
			f[k + ".@timer"] = "%s:%s" % [not (ch as Timer).is_stopped(), var_to_str((ch as Timer).time_left)]
		if ch.get_script() != null:
			_vars(f, k + ".", ch, pt)
		_children(f, prefix, root, ch, pt)


## autoq (2026-11-17, GPT audit #7): the WIDE observation, a DIAGNOSTIC only (never a receipt). Generic, so a new
## puzzle's node shows without being named here: every scripted node under the game (dev / test nodes left out): its
## script vars, local pose, visible, a body's speed / sleep / freeze; and its unscripted descendants (up to the next
## scripted node): engine state (timers, sounds, animations, particles) and, within 2 levels and below scripted nodes
## of <= 400 descendants, local pose + visible. Auto-named siblings are told apart by their child index.
## Blind spots (listed in every restore-check report): autoloads, script statics, a resource's insides (a mesh,
## a material's parameters other than what a scripted var holds), the physics server's contacts.
static func wide(pt: PlayTest) -> Dictionary:
	var t0 := Time.get_ticks_usec()
	var f := {}
	var root: Node = pt.boot
	_wide_walk(f, root, "", null, 0, pt, {})
	return {"meta": {"wall_ms": Time.get_ticks_msec(), "physics_frames": Engine.get_physics_frames(),
		"capture_us": Time.get_ticks_usec() - t0, "fields": f.size()}, "fields": f}


static func _wide_key(n: Node) -> String:
	var nm := String(n.name)
	if nm.begins_with("@"):
		return "%s%d" % [_nm(nm), n.get_index()]
	return nm


static func _wide_walk(f: Dictionary, n: Node, path: String, scripted_anc: Node, depth: int, pt: PlayTest, cache: Dictionary) -> void:
	var k := path + "/" + _wide_key(n) if path != "" else _wide_key(n)
	var sc = n.get_script()
	var is_dev: bool = sc != null and String((sc as Script).resource_path).contains("/scripts/dev/")
	if is_dev:
		return
	var scripted: bool = sc != null
	if scripted:
		_vars(f, "w:" + k + ".", n, pt)
		scripted_anc = n
		depth = 0
	var near: bool = scripted or (depth <= 2 and scripted_anc != null and _desc_count(scripted_anc, cache) <= 400)
	if n is Node3D and near:
		f["w:" + k + ".@local"] = var_to_str((n as Node3D).transform)
		f["w:" + k + ".@visible"] = var_to_str((n as Node3D).visible)
	if n is RigidBody3D and near:
		var rb := n as RigidBody3D
		f["w:" + k + ".@body"] = "%s:%s:%s:%s" % [var_to_str(rb.linear_velocity), var_to_str(rb.angular_velocity), rb.sleeping, rb.freeze]
	if n is Timer:
		f["w:" + k + ".@timer"] = "%s:%s" % [not (n as Timer).is_stopped(), var_to_str((n as Timer).time_left)]
	if n is AudioStreamPlayer3D:
		var a3 := n as AudioStreamPlayer3D
		f["w:" + k + ".@audio"] = "%s:%s:%s" % [a3.playing, var_to_str(a3.pitch_scale), var_to_str(a3.volume_db)]
	if n is AudioStreamPlayer:
		var a2 := n as AudioStreamPlayer
		f["w:" + k + ".@audio"] = "%s:%s:%s" % [a2.playing, var_to_str(a2.pitch_scale), var_to_str(a2.volume_db)]
	if n is AnimationPlayer:
		var ap := n as AnimationPlayer
		f["w:" + k + ".@anim"] = "%s:%s:%s" % [ap.is_playing(), ap.current_animation, var_to_str(snappedf(ap.current_animation_position, 0.0001)) if ap.is_playing() else "-"]
	if n is GPUParticles3D:
		f["w:" + k + ".@particles"] = var_to_str((n as GPUParticles3D).emitting)
	if n is CPUParticles3D:
		f["w:" + k + ".@particles"] = var_to_str((n as CPUParticles3D).emitting)
	for ch in n.get_children():
		_wide_walk(f, ch, k, scripted_anc, depth + 1, pt, cache)


static func _desc_count(n: Node, cache: Dictionary) -> int:
	# a local cache (an observer never writes the world, not even metadata)
	var id := n.get_instance_id()
	if not cache.has(id):
		cache[id] = _count(n)
	return int(cache[id])


static func _count(n: Node) -> int:
	var c := n.get_child_count()
	for ch in n.get_children():
		c += _count(ch)
	return c
