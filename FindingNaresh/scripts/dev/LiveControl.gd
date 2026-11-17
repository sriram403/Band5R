class_name LiveControl
extends RefCounted

## The live control line (2026-10-02, the user: test closed-loop, the way a
## human does: look, act, check, fix, go on). The game started with
## `--playtest=live` waits on a command file; `tools/live.py` writes one
## command (or a short list), the game does it with the real input (keys,
## pad, mouse: the PlayTest helpers), and writes back the result, the state
## and the latest messages, with a screenshot when asked. A list stops at
## the first command that fails.
##
## Commands ({"do": ..., ...}); a position is [x, y, z], "poi:<name>" or an
## expression ("expr:<GDScript expression on PlayTest>"):
##   state                         just the state
##   eval   expr                   an expression on PlayTest (instant), its value back
##   wait   s
##   until  expr, max          wait till an expression on PlayTest is true (e.g. "creature_to_naresh() < 15")
##   tap / hold / down / up   key ("E", "F1", "SPACE", ...), s for hold
##   pad_tap / pad_hold  btn ("A","B","X","Y","LB","RB","UP","DOWN","LEFT","RIGHT","BACK","L3","R3"), s
##   pad_axis  axis ("LX","LY","RX","RY","LT","RT"), v
##   mouse  btn ("left","right","middle"), down (bool)
##   look   who (1/2), at
##   walk   who (1 keyboard / 2 pad), to, arrive (m), max (s)
##   job    who, at, job ("go", "follow", "hold", ...), zoom (bool: binoculars)
##   menu   tab, row (the text it contains): F1, the tab, the row, Enter, F1
##   drive  road, to (a position on it), until (expression), kmh, max
##   shot   name
##
## A watched run (v4, notes/TESTING_METHOD.md): {"walk": {...}, "from": step}
## plays a planned walk's steps back to back, not waiting for the client. A
## walk: {"name", "setup": [cmds, run every time], "steps": [{"name", "needs":
## [watch names], "do": [cmds], "expect": [{"name", "expr", "within" (s),
## "watch" (true: checked alongside the next steps; else waited for here)}],
## "allow": [what's fine in this step: "taken", "naresh_still", or a line
## like "Found a way round!"]}]}. A watcher checks every 0.1 s, alongside the
## actions: the open watches and the always-on rules (Naresh stuck while he
## should be moving, a give-up line, a player taken, a script error the
## client saw in the log). The first failure stops the actions; the game
## stays open and the report goes back. Every step starts with a save point
## (user://live/points/<walk>_<n>.json): "from" loads that step's save into a
## fresh game and plays on from there.
## RESUME IS THE DEFAULT (the user, 2026-11-10): a failed run writes
## points/<walk>_last_fail.json; tools/live.py --walk (and tools/play_walk.sh,
## tools/record_walk.sh) then start from that step unless --fresh. A save
## point is the game's save taken raw (no rewind mid-encounter) plus the live
## part a game save leaves out: what's in hand, Naresh, the creatures, and the
## script variables of the puzzle nodes in LIVE_GROUPS and their creature
## (#6: Problem's phase, timers, suspicion), so a resume starts where the step did.

## T4 v2 (speed research, 2026-11-11): save points are IMMUTABLE, one folder per walk run
## (points/<run>/<i>.json, never overwritten; last_fail names the point ID "<run>/<i>"); each point
## has an independent observation taken in the same tick (<i>.obs.json, dev/GateObs.gd) and a +3 game s
## sample of the step as it really played (<i>.t3.json: observation, walk lines, messages, inputs).
## A resume names its point by ID, restores, observes again at once (before any await: layer 2), then
## waits for tools/method/walkgate.py's verdict before the step's first input. The first FAIL closes
## the input gate and cancels helpers (PlayTest.cancel_inputs) before the failure picture.
## Lanes: instance.json (pid, lane) lets the client refuse a misrouted command.

const GateObs := preload("res://scripts/dev/GateObs.gd")
const ResumeV1 := preload("res://scripts/dev/ResumeV1.gd")

var pt: PlayTest
var dir := ""
var _run := ""                   ## this walk run's points folder name (T4 v2)
var _trace_msgs: Array = []      ## [game ms, who, sees/hears, text]: the +3 s sample reads it
var _last_id := -1
var _messages: Array = []
var _events: Array = []          ## [who, "sees"/"hears", text] for the watcher
var _fail := ""                  ## the watched run's first failure ("" = none)
var _log: Array = []             ## the watched run's PASS / FAIL lines
var _walk_name := ""
var rv                           ## ResumeV1 (resume fix v1, 2026-11-17)


func _init(test: PlayTest) -> void:
	pt = test
	rv = ResumeV1.new(self)


func run() -> void:
	dir = ProjectSettings.globalize_path("user://live")
	DirAccess.make_dir_recursive_absolute(dir)
	for f in ["cmd.json", "res.json"]:
		if FileAccess.file_exists(dir + "/" + f):
			DirAccess.remove_absolute(dir + "/" + f)
	for i in pt.boot.players.size():
		var p: PlayerRig = pt.boot.players[i]
		var who := "P%d" % (i + 1)
		p.message.connect(func(t, _s):
			_messages.append("%s sees: %s" % [who, t])
			_events.append([who, "sees", String(t)])
			_trace_msgs.append([PlayTest.gms(), who, "sees", String(t)]))
		p.speech.connect(func(w, t, _s):
			_messages.append("%s hears %s: %s" % [who, w, t])
			_events.append([who, "hears", String(t)])
			_trace_msgs.append([PlayTest.gms(), who, "hears", String(t)]))
	# T4 v2 lanes: who answers here (tools/live.py refuses an answer from another lane's game)
	var lane := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lane="):
			lane = a.substr(7)
	var inst := FileAccess.open(dir + "/instance.json", FileAccess.WRITE)
	inst.store_string(JSON.stringify({"pid": OS.get_process_id(), "lane": lane, "dir": dir, "shots": ProjectSettings.globalize_path(pt.shots_dir),
		"recording": Engine.get_write_movie_path()}))
	inst.close()
	print("[live] ready, commands in %s/cmd.json" % dir)
	_write({"id": -1, "ready": true, "state": state()})
	_heartbeat()
	while true:
		await pt.get_tree().create_timer(0.05, true, false, true).timeout
		var path := dir + "/cmd.json"
		if not FileAccess.file_exists(path):
			continue
		var txt := FileAccess.get_file_as_string(path)
		var data = JSON.parse_string(txt)
		if typeof(data) != TYPE_DICTIONARY or int(data.get("id", -1)) == _last_id:
			continue
		_last_id = int(data["id"])
		if data.has("walk"):
			var rep: Dictionary = await _run_walk(data["walk"], String(data.get("from", "")), data)
			_messages.clear()
			rep["id"] = _last_id
			rep["state"] = state()
			_write(rep)
			continue
		var cmds: Array = data.get("cmds", [])
		# a new client batch that sends input opens the gate a failed walk closed (eval / state don't)
		for c0 in cmds:
			if String(c0.get("do", "")) in INPUT_CMDS:
				pt.open_inputs()
				break
		var results: Array = []
		var shot_path := ""
		for c in cmds:
			var r: Dictionary = await _do(c)
			results.append(r)
			if r.has("shot"):
				shot_path = r["shot"]
			if not bool(r.get("ok", true)):
				break
		if bool(data.get("quit", false)):
			_write({"id": _last_id, "results": results, "bye": true})
			pt.get_tree().quit()
			return
		var msgs := _messages.duplicate()
		_messages.clear()
		_write({"id": _last_id, "results": results, "messages": msgs, "state": state(), "shot": shot_path})


const INPUT_CMDS := ["tap", "hold", "down", "up", "pad_tap", "pad_hold", "pad_down", "pad_up", "pad_axis", "mouse", "look", "walk", "job", "menu", "drive", "call", "spawn"]


## T4 v2 lanes: physics frames written every 0.5 s (a sentinel reads it advancing)
func _heartbeat() -> void:
	while true:
		var f := FileAccess.open(dir + "/heartbeat.tmp", FileAccess.WRITE)
		f.store_string(JSON.stringify({"pid": OS.get_process_id(), "physics_frames": Engine.get_physics_frames(), "wall_ms": Time.get_ticks_msec()}))
		f.close()
		DirAccess.rename_absolute(dir + "/heartbeat.tmp", dir + "/heartbeat.json")
		await pt.get_tree().create_timer(0.5, true, false, true).timeout


func _write(d: Dictionary) -> void:
	var tmp := dir + "/res.tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "  "))
	f.close()
	DirAccess.rename_absolute(tmp, dir + "/res.json")


func _v3(v) -> Vector3:
	if v is Array and v.size() == 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	if v is String and String(v).begins_with("poi:"):
		return pt.boot.builder.poi.get(String(v).substr(4), Vector3.INF)
	if v is String and String(v).begins_with("expr:"):
		var r = _eval(String(v).substr(5))
		return r if r is Vector3 else Vector3.INF
	return Vector3.INF


func _eval(code: String):
	var e := Expression.new()
	if e.parse(code) != OK:
		return "parse error: " + e.get_error_text()
	var r = e.execute([], pt, true)
	if e.has_execute_failed():
		return "error: " + e.get_error_text()
	return r


func _who(c: Dictionary) -> PlayerRig:
	return pt.p2() if int(c.get("who", 1)) == 2 else pt.p1()


const PAD := {"A": JOY_BUTTON_A, "B": JOY_BUTTON_B, "X": JOY_BUTTON_X, "Y": JOY_BUTTON_Y, "LB": JOY_BUTTON_LEFT_SHOULDER,
	"RB": JOY_BUTTON_RIGHT_SHOULDER, "UP": JOY_BUTTON_DPAD_UP, "DOWN": JOY_BUTTON_DPAD_DOWN, "LEFT": JOY_BUTTON_DPAD_LEFT,
	"RIGHT": JOY_BUTTON_DPAD_RIGHT, "BACK": JOY_BUTTON_BACK, "START": JOY_BUTTON_START, "L3": JOY_BUTTON_LEFT_STICK, "R3": JOY_BUTTON_RIGHT_STICK}
const AXIS := {"LX": JOY_AXIS_LEFT_X, "LY": JOY_AXIS_LEFT_Y, "RX": JOY_AXIS_RIGHT_X, "RY": JOY_AXIS_RIGHT_Y,
	"LT": JOY_AXIS_TRIGGER_LEFT, "RT": JOY_AXIS_TRIGGER_RIGHT}


func _key(name: String) -> Key:
	return OS.find_keycode_from_string(name) as Key


func _do(c: Dictionary) -> Dictionary:
	var what := String(c.get("do", ""))
	var r := {"do": what, "ok": true}
	match what:
		"state":
			pass
		"eval":
			r["value"] = str(_eval(String(c.get("expr", ""))))
		"wait":
			await pt.wait(float(c.get("s", 1.0)))
		"call":
			# a PlayTest helper, awaited ("walk_in_driver", args ["p1"]): "p1",
			# "p2" and "expr:..." args are resolved first
			var args: Array = []
			for a in c.get("args", []):
				if a is String and a == "p1":
					args.append(pt.p1())
				elif a is String and a == "p2":
					args.append(pt.p2())
				elif a is String and String(a).begins_with("expr:"):
					args.append(_eval(String(a).substr(5)))
				elif a is float and is_equal_approx(a, roundf(a)):
					args.append(int(a))          # JSON has no ints: 0 came as 0.0 for an int parameter
				else:
					args.append(a)
			var v = await pt.callv(String(c.get("fn", "")), args)
			if v is bool:
				r["ok"] = v
			r["value"] = str(v)
		"spawn":
			# a PlayTest helper started alongside, not waited for (a second
			# player's job: P2 on guard with the flare gun); counted while it runs (T4 v2:
			# a boundary with a running helper is refused)
			_spawn_helper(String(c.get("fn", "")), c.get("args", []))
		"marker":
			# T4 v2: one drawn frame of solid magenta, its drawn-frame number logged, so the
			# recording's drawn-frame -> movie-frame mapping can be proved (tools/method/join_check.py)
			var cl := CanvasLayer.new()
			cl.layer = 128
			var rect := ColorRect.new()
			rect.color = Color(1, 0, 1)
			rect.set_anchors_preset(Control.PRESET_FULL_RECT)
			cl.add_child(rect)
			pt.add_child(cl)
			await RenderingServer.frame_post_draw
			var mf := Engine.get_frames_drawn()
			cl.queue_free()
			r["frame"] = mf
			_say("marker at frame %d" % mf)
		"until":
			# wait in the game till an expression is true (checked every 0.1 s):
			# a shell loop round the client broke on a missing tool (bc) and
			# Naresh was taken while it spun
			var t := 0.0
			var mx := float(c.get("max", 60.0))
			r["ok"] = false
			while t < mx:
				if bool(_eval(String(c.get("expr", "false")))):
					r["ok"] = true
					break
				await pt.wait(0.1)
				t += 0.1
			r["after"] = snappedf(t, 0.1)
		"tap":
			await pt.tap(_key(String(c["key"])))
		"hold":
			await pt.hold_physics(_key(String(c["key"])), float(c.get("s", 1.0)))
		"down":
			pt.key(_key(String(c["key"])), true)
		"up":
			pt.key(_key(String(c["key"])), false)
		"pad_tap":
			pt.pad_button(PAD[String(c["btn"])], true)
			await pt.physics_frames(5)
			pt.pad_button(PAD[String(c["btn"])], false)
			await pt.physics_frames(3)
		"pad_hold":
			pt.pad_button(PAD[String(c["btn"])], true)
			await pt.wait(float(c.get("s", 1.0)))
			pt.pad_button(PAD[String(c["btn"])], false)
			await pt.physics_frames(3)
		"pad_down":
			pt.pad_button(PAD[String(c["btn"])], true)
			await pt.physics_frames(2)
		"pad_up":
			pt.pad_button(PAD[String(c["btn"])], false)
			await pt.physics_frames(2)
		"pad_axis":
			pt.pad_axis(AXIS[String(c["axis"])], float(c.get("v", 0.0)))
			await pt.physics_frames(2)
		"mouse":
			var b := MOUSE_BUTTON_RIGHT if String(c.get("btn", "right")) == "right" else (MOUSE_BUTTON_MIDDLE if String(c.get("btn", "")) == "middle" else MOUSE_BUTTON_LEFT)
			pt.mouse_button(b, bool(c.get("down", true)))
			await pt.physics_frames(3)
		"look":
			var at := _v3(c.get("at"))
			r["ok"] = at != Vector3.INF
			if r["ok"]:
				await pt.look_at_point(_who(c), at)
		"walk":
			var to := _v3(c.get("to"))
			if to == Vector3.INF:
				r["ok"] = false
			elif int(c.get("who", 1)) == 2:
				r["ok"] = await pt.pad_walk_to(pt.p2(), to, float(c.get("arrive", 0.8)), float(c.get("max", 40.0)))
			else:
				# stuck (a tree, a corner): step aside and go on, as a person
				# would; three tries
				for k in 4:
					r["ok"] = await pt.walk_to(pt.p1(), to, "live", float(c.get("arrive", 0.8)), float(c.get("max", 40.0)))
					if r["ok"] or k == 3:
						break
					await pt.hold_physics(KEY_D if k % 2 == 0 else KEY_A, 1.0)
					r["sidesteps"] = k + 1
		"job":
			var at := _v3(c.get("at"))
			if at == Vector3.INF:
				# a bad position aimed at nothing and looked like the game's
				# fault (Expression knows no Vector3.UP: write Vector3(0, 1, 0))
				return {"do": what, "ok": false, "error": "no position from %s" % str(c.get("at"))}
			var p := _who(c)
			var zoom := bool(c.get("zoom", false))
			if zoom:
				if p == pt.p2():
					pt.pad_axis(JOY_AXIS_TRIGGER_LEFT, 1.0)
				else:
					pt.mouse_button(MOUSE_BUTTON_RIGHT, true)
				await pt.wait(0.6)
			if p == pt.p2():
				await pt.look_at_point(p, at)
				pt.pad_button(JOY_BUTTON_DPAD_UP, true)
				await pt.physics_frames(5)
				pt.pad_button(JOY_BUTTON_DPAD_UP, false)
				await pt.physics_frames(4)
				r["ok"] = true
			else:
				r["ok"] = await pt.naresh_job(p, at, String(c.get("job", "follow")))
			if zoom:
				pt.pad_axis(JOY_AXIS_TRIGGER_LEFT, 0.0)
				pt.mouse_button(MOUSE_BUTTON_RIGHT, false)
		"menu":
			r["ok"] = await pt.menu_pick(String(c.get("tab", "Story")), String(c.get("row", "")))
		"drive":
			var rn := String(c.get("road", "coast_road"))
			var road: Route = pt.tunnel().road if rn == "tunnel" else pt.boot.builder.network.road(rn)
			var to := _v3(c.get("to"))
			var stop := road.point_count() - 2 if to == Vector3.INF else int(road.nearest(to.x, to.z)["index"])
			var cond := String(c.get("until", "false"))
			await pt.drive_until(road, stop, func() -> bool: return bool(_eval(cond)), float(c.get("max", 120.0)), float(c.get("kmh", -1.0)))
			pt.key(KEY_W, false)
		"shot":
			var nm := "live_" + String(c.get("name", "x"))
			await pt.shot(nm)
			r["shot"] = ProjectSettings.globalize_path(pt.shots_dir + "/test_%s.png" % nm)
		_:
			r["ok"] = false
			r["error"] = "unknown command"
	return r


## T4 control only (WALK_FAIL_AT): a deliberate break s game seconds into a step, as a take broken
## by something outside the game would be (the join verifier's demo needs a failed part).
func _break_after(nm: String, s: float) -> void:
	var g0 := PlayTest.gms()
	while PlayTest.gms() - g0 < int(s * 1000.0):
		await pt.get_tree().physics_frame
	if _fail == "":
		_failed("deliberate break (test-only control) %.1f game s into '%s'" % [s, nm])


func _spawn_helper(fn: String, args: Array) -> void:
	pt.helpers_running += 1
	await pt.callv(fn, args)
	pt.helpers_running -= 1


func _f3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.1), snappedf(v.y, 0.1), snappedf(v.z, 0.1)]


## What a player would see and know, in a few lines.
func state() -> Dictionary:
	var b := pt.boot
	var d := {}
	for i in b.players.size():
		var p: PlayerRig = b.players[i]
		d["p%d" % (i + 1)] = {"pos": _f3(p.global_position), "yaw": snappedf(rad_to_deg(p.yaw), 1.0), "seat": p.seat_role if p.seat != null else "",
			"held": p.held.name if p.held != null else "", "prompt": p.prompt_text, "binoculars": p.has_binoculars,
			"zoom": snappedf(p.zoom, 0.1), "torch": p.flashlight.visible, "ladder": p.ladder != null}
	var n: Naresh = b.naresh
	if n != null and is_instance_valid(n):
		d["naresh"] = {"pos": _f3(n.global_position), "state": Naresh.State.keys()[n.state], "job": n.job,
			"leader": n.leader.name if n.leader != null else "", "holding": n.held.name if n.held != null else ""}
	# creatures within 150 m of a player: where, doing what, how far from him
	var cs: Array = []
	for cr in pt.get_tree().get_nodes_in_group("creature"):
		var near := INF
		for p in b.players:
			near = minf(near, (p as Node3D).global_position.distance_to(cr.global_position))
		if near < 150.0:
			cs.append({"pos": _f3(cr.global_position), "state": Creature.State.keys()[cr.state],
				"to_goal": snappedf(Vector2(cr.goal_now.x - cr.global_position.x, cr.goal_now.z - cr.global_position.z).length(), 0.1),
				"to_naresh": snappedf(cr.global_position.distance_to(n.global_position), 0.1) if n != null else -1.0})
	d["creatures"] = cs
	var c: Camper = b.camper
	d["van"] = {"pos": _f3(c.global_position), "kmh": snappedf(c.linear_velocity.length() * 3.6, 0.1), "fuel": snappedf(c.fuel, 0.1),
		"engine": c.engine_on, "handbrake": c.parking_brake, "battery": snappedf(c.battery, 0.01), "upright": c.global_transform.basis.y.y > 0.8}
	if b.story != null:
		d["story"] = {"id": b.story.current()["id"], "text": b.story.current()["text"]}
	var m := pt.get_tree().get_first_node_in_group("mood") as Mood
	if m != null:
		d["mood"] = snappedf(m.value, 0.01)
	d["menu_open"] = b.dev_menu.open
	return d


# --- the watched run ------------------------------------------------------------

func _say(line: String) -> void:
	_log.append(line)
	print("[walk] " + line)
	var path := dir + "/walk.log"
	var f := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	f.seek_end()
	f.store_line(line)
	f.close()
	if _run != "":
		# T4 v2: the run's own copy (walk.log is replaced by the next walk; the gate reads this one)
		var rp := "%s/points/%s/walk.log" % [dir, _run]
		var g := FileAccess.open(rp, FileAccess.READ_WRITE if FileAccess.file_exists(rp) else FileAccess.WRITE)
		g.seek_end()
		g.store_line(line)
		g.close()


func _release() -> void:
	for k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_E, KEY_SPACE]:
		pt.key(k, false)
	pt.mouse_button(MOUSE_BUTTON_RIGHT, false)
	for a in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		pt.pad_axis(a, 0.0)
	for b in PAD.values():
		pt.pad_button(b, false)


func _failed(why: String) -> void:
	if _fail == "":
		_fail = why
		_say("FAIL " + why)
		# T4 v2: cancel helpers and close the input gate at once (before the failure picture)
		pt.cancel_inputs("walk FAIL: " + why.substr(0, 80))


## --- a save point's live part (test only) -------------------------------------
## The game's own save is for players: it rewinds a half-done encounter and
## doesn't keep a creature's mind. A resumed walk needs the world as the step
## found it, so a save point also keeps the script variables of the puzzle
## nodes below (plain values only; a player reference as its index) and of the
## creature they run.

const LIVE_GROUPS := ["ghat"]
const _PLAIN := [TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME, TYPE_VECTOR2,
	TYPE_VECTOR3, TYPE_TRANSFORM3D, TYPE_BASIS, TYPE_COLOR, TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_FLOAT32_ARRAY]


func _plain(v) -> bool:
	var t := typeof(v)
	if t in _PLAIN or t == TYPE_NIL:
		return true
	if t == TYPE_ARRAY:
		for x in v:
			if not _plain(x):
				return false
		return true
	if t == TYPE_DICTIONARY:
		for k in v:
			if not _plain(k) or not _plain(v[k]):
				return false
		return true
	return false


func _snap_vars(o: Object) -> Dictionary:
	var out := {}
	for p in o.get_property_list():
		if not (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE):
			continue
		var v = o.get(p["name"])
		if v is PlayerRig:
			out[p["name"]] = "player:%d" % pt.boot.players.find(v)
		elif v == null and int(p["type"]) == TYPE_OBJECT and String(p["class_name"]) == "PlayerRig":
			out[p["name"]] = "player:-1"
		elif typeof(v) != TYPE_OBJECT and _plain(v):
			out[p["name"]] = var_to_str(v)
	return out


func _unsnap_vars(o: Object, d: Dictionary) -> void:
	for k in d:
		var s := String(d[k])
		if s.begins_with("player:"):
			var pi := int(s.substr(7))
			o.set(k, pt.boot.players[pi] if pi >= 0 and pi < pt.boot.players.size() else null)
		else:
			o.set(k, str_to_var(s))


func _snap_live(point: Dictionary) -> void:
	var live := {}
	for g in LIVE_GROUPS:
		var n := pt.get_tree().get_first_node_in_group(g)
		if n == null:
			continue
		var e := {"vars": _snap_vars(n)}
		var cr = n.get("problem")
		if cr is Creature and is_instance_valid(cr):
			e["creature"] = {"xf": var_to_str((cr as Node3D).global_transform), "vars": _snap_vars(cr)}
		live[g] = e
	point["live_puzzles"] = live


func _restore_live(point: Dictionary) -> void:
	var live: Dictionary = point.get("live_puzzles", {})
	for g in live:
		var n := pt.get_tree().get_first_node_in_group(g)
		if n == null:
			continue
		var e: Dictionary = live[g]
		if n is Ghat:
			var gh := n as Ghat
			if e.has("creature") and (gh.problem == null or not is_instance_valid(gh.problem)):
				gh._spawn_problem(gh.road.point(gh.hairpins[gh.seen_hp()]), pt.camper())
			elif not e.has("creature") and gh.problem != null and is_instance_valid(gh.problem):
				gh.problem.queue_free()
				gh.problem = null
				gh.attacker = null
		_unsnap_vars(n, e["vars"])
		if n is Ghat:
			# the fog only reaches the mood when it changes: show it as restored
			var mood := pt.get_tree().get_first_node_in_group("mood") as Mood
			if mood != null:
				mood.fog_boost = (n as Ghat).fog
				mood.apply()
		if e.has("creature"):
			var cr = n.get("problem")
			if cr is Creature:
				_unsnap_vars(cr, e["creature"]["vars"])
				(cr as Node3D).global_transform = str_to_var(String(e["creature"]["xf"]))
				(cr as Node3D).reset_physics_interpolation()


func _json_out(path: String, d: Dictionary) -> void:
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	f.store_string(JSON.stringify(d, "", true, true))
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)


## The +3 game s sample of a step (layer 3's evidence): taken while the step's actions run.
func _t3_sample(path: String, idx: int, step: String, gms0: int, log0: int, msg0: int, in0: int) -> void:
	while PlayTest.gms() - gms0 < 3000:
		await pt.get_tree().physics_frame
	var obs := GateObs.observe(pt)
	var msgs: Array = []
	for m in _trace_msgs.slice(msg0):
		msgs.append([int(m[0]) - gms0, m[1], m[2], m[3]])
	var ins: Array = []
	for e in pt.input_trace.slice(in0):
		ins.append([int(e[0]) - gms0, e[1], e[2], e[3]])
	var lines: Array = []
	for ln in _log.slice(log0):
		lines.append(String(ln))
	_json_out(path, {"index": idx, "step": step, "at_game_ms": PlayTest.gms() - gms0, "obs": obs,
		"lines": lines, "messages": msgs, "inputs": ins, "failed_before": _fail})


## A gate verdict file written by the client (tools/live.py); waits on the wall clock, also while paused.
func _gate_verdict(path: String):
	var t0 := Time.get_ticks_msec()
	while not FileAccess.file_exists(path) and Time.get_ticks_msec() - t0 < 30000:
		await pt.get_tree().create_timer(0.05, true, false, true).timeout
	return JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null


func _run_walk(walk: Dictionary, from: String, msg: Dictionary = {}) -> Dictionary:
	_walk_name = String(walk.get("name", "walk"))
	_fail = ""
	_log.clear()
	pt.open_inputs()
	pt.input_trace.clear()
	_trace_msgs.clear()
	# T4 v2: this run's own, never-overwritten points folder
	_run = String(msg.get("run", ""))
	if _run == "":
		_run = "%s_%s_%d" % [_walk_name, Time.get_datetime_string_from_system().replace(":", "").replace("-", ""), OS.get_process_id()]
	var rdir := "%s/points/%s" % [dir, _run]
	if DirAccess.dir_exists_absolute(rdir):
		return {"ok": false, "fail": "points folder %s exists already (a run ID is used once)" % _run, "log": []}
	DirAccess.make_dir_recursive_absolute(rdir)
	var identity: Dictionary = msg.get("identity", {})
	_json_out(rdir + "/walk.json", walk)
	_json_out(rdir + "/run.json", {"run": _run, "walk": _walk_name, "identity": identity, "from": from,
		"from_point": String(msg.get("from_point", "")), "pid": OS.get_process_id(), "recording": Engine.get_write_movie_path()})
	for old in ["walk.log", "abort"]:
		if FileAccess.file_exists(dir + "/" + old):
			DirAccess.remove_absolute(dir + "/" + old)
	DirAccess.make_dir_recursive_absolute(dir + "/points")
	var steps: Array = walk.get("steps", [])
	var start := 0
	if from != "":
		start = -1
		for k in steps.size():
			if String(steps[k].get("name", "")) == from:
				start = k
		if start < 0:
			return {"ok": false, "fail": "no step named " + from, "log": []}
	var t0 := pt.clk()
	var ctx := {"watches": [], "passed": {}, "allow": [], "running": true}
	for c in walk.get("setup", []):
		await _do(c)
	var gate := {}
	if start > 0:
		# T4 v2: the point is named by its ID ("<run>/<i>"), checked by the client (identity, refusal
		# rules) before this command was sent; here: it exists and is this step's
		var pid := String(msg.get("from_point", ""))
		var pp := "%s/points/%s.json" % [dir, pid]
		if pid == "" or not FileAccess.file_exists(pp):
			return {"ok": false, "fail": "resume needs a point ID (from_point); '%s' not found" % pid, "log": []}
		var point = JSON.parse_string(FileAccess.get_file_as_string(pp))
		if typeof(point) != TYPE_DICTIONARY or String(point.get("live_step", "")) != from:
			return {"ok": false, "fail": "point %s is not step '%s'" % [pid, from], "log": []}
		gate = {"point": pid, "l2": "%s/%d.l2.json" % [rdir, start]}
		SaveGame.apply(pt.boot, point)
		# a puzzle's live state the game's own save leaves out or rewinds
		# (#6: a save mid-encounter goes back before the bend; Problem isn't saved)
		_restore_live(point)
		# the creatures aren't in a game save: put them back where they were
		# (after a resume they started elsewhere, which changed the situation)
		var crs := pt.get_tree().get_nodes_in_group("creature")
		var was: Array = point.get("live_creatures", [])
		for k in mini(crs.size(), was.size()):
			(crs[k] as Node3D).global_position = Vector3(float(was[k][0]), float(was[k][1]), float(was[k][2]))
		var held: Array = point.get("live_held", [])
		for k in mini(held.size(), pt.boot.players.size()):
			if String(held[k]) == "":
				continue
			var item := pt.boot.world.find_child(String(held[k]), true, false) as Carryable
			var pl: PlayerRig = pt.boot.players[k]
			if item != null and pl.held == null:
				pl.pick_up(item)
		var ln: Dictionary = point.get("live_naresh", {})
		var nz: Naresh = pt.boot.naresh
		if not ln.is_empty() and nz != null:
			# only the states a step starts from; a job or a ride isn't put back
			var st0 := int(ln["state"])
			if st0 in [Naresh.State.FOLLOW, Naresh.State.WAIT, Naresh.State.GO, Naresh.State.IDLE]:
				if nz.state == Naresh.State.SEATED:
					nz.command(null, "get_out")
				nz.global_position = Vector3(float(ln["pos"][0]), float(ln["pos"][1]), float(ln["pos"][2]))
				nz.reset_physics_interpolation()
				var li := int(ln["leader"])
				nz.leader = pt.boot.players[li] if li >= 0 else null
				nz.go_point = Vector3(float(ln["go"][0]), float(ln["go"][1]), float(ln["go"][2]))
				nz.state = st0
		# resume fix v1 (2026-11-17): what the restore above still lost (bodies' stored speeds and freeze,
		# van / item / player vars, players' full pose, Problem's children, clocks as ages, hearing)
		var drop: Array = msg.get("drop", [])
		var rv1 := String(point.get("resume_v", "")) == ResumeV1.VERSION
		if rv1:
			rv.restore(point, drop)
			gate["seed"] = int(point.get("rng_seed", 0))
			if not drop.is_empty():
				_say("gate control (TEST ONLY): restore without %s" % str(drop))
		# the paused hold (GPT audit #1): no game time passes between the restore and the step's first
		# action, as in the fresh run (h1's 1 s running settle and the running verdict wait are gone)
		var tree := pt.get_tree()
		var hold0 := [Time.get_ticks_msec(), Engine.get_physics_frames(), PlayTest.gms()]
		if rv1:
			tree.paused = true
			await tree.process_frame
			await tree.process_frame
			rv.apply_clock(point, drop)
		# T4 v2 layer 2: observe NOW, before any game time passes (rv1: after 2 paused frames for deferred work)
		_json_out("%s/%d.restored.obs.json" % [rdir, start], GateObs.observe(pt, {"test.@open_watches": "[]", "test.@needs": "[]"}))
		_say("gate: restored observation written (%s)" % String(gate["point"]))
		var pert: Dictionary = msg.get("perturb", {})
		if not rv1:
			# test-only control (T4 v2 layer 3): move an actor AFTER the immediate observation
			if not pert.is_empty() and String(pert.get("what", "")) == "van":
				pt.camper().global_position += Vector3(float(pert.get("dx", 0.0)), 0, 0)
				_say("gate control: van moved %.2f m after the immediate observation" % float(pert.get("dx", 0.0)))
			await pt.wait(1.0)
		# the client's layer 1+2 verdict before the step's first input (rv1: still paused)
		var v = await _gate_verdict(String(gate["l2"]))
		if typeof(v) == TYPE_DICTIONARY and String(v.get("verdict", "")) != "SAME" and bool(msg.get("l2_continue", false)):
			# test-only control (GATE_L2_CONTINUE): go on past a layer 1+2 DIFFERENT so layer 3 can be shown live;
			# the receipt keeps the DIFFERENT (such a run never counts as a resume)
			_say("gate control (TEST ONLY): layer 1+2 %s, continuing to show layer 3" % String(v.get("verdict", "")))
		elif typeof(v) != TYPE_DICTIONARY or String(v.get("verdict", "")) != "SAME":
			_failed("gate: %s before any input (%s)" % ["no layer 1+2 verdict in 30 s" if typeof(v) != TYPE_DICTIONARY else "layer 1+2 " + String(v.get("verdict", "?")),
				"" if typeof(v) != TYPE_DICTIONARY else String(v.get("why", "")).substr(0, 200)])
		else:
			_say("gate: layer 1+2 SAME (%s)" % String(gate["point"]))
		if rv1 and _fail == "":
			# the final pre-input check (GPT audit #1): the world as it will start the step must still equal the point
			rv.apply_clock(point, drop)
			_json_out("%s/%d.final.obs.json" % [rdir, start], GateObs.observe(pt, {"test.@open_watches": "[]", "test.@needs": "[]"}))
			var vf = await _gate_verdict("%s/%d.l2f.json" % [rdir, start])
			if typeof(vf) != TYPE_DICTIONARY or String(vf.get("verdict", "")) != "SAME":
				if not bool(msg.get("l2_continue", false)):
					_failed("gate: final pre-input check %s (%s)" % ["missing" if typeof(vf) != TYPE_DICTIONARY else String(vf.get("verdict", "?")),
						"" if typeof(vf) != TYPE_DICTIONARY else String(vf.get("why", "")).substr(0, 200)])
			else:
				_say("gate: final pre-input check SAME (%s)" % String(gate["point"]))
			# test-only control (layer 3): move an actor after the final check, just before the step
			if not pert.is_empty() and String(pert.get("what", "")) == "van":
				pt.camper().global_position += Vector3(float(pert.get("dx", 0.0)), 0, 0)
				_say("gate control: van moved %.2f m after the final check" % float(pert.get("dx", 0.0)))
			rv.apply_clock(point, drop)
		if rv1:
			tree.paused = false
			_say("gate: held paused %d wall ms; physics frames +%d, game ms +%d while held" % [Time.get_ticks_msec() - int(hold0[0]),
				Engine.get_physics_frames() - int(hold0[1]), PlayTest.gms() - int(hold0[2])])
		# no Naresh in some puzzles (#6): the old line read his state and died on it
		var nz2: Naresh = pt.boot.naresh
		var nar := "none" if nz2 == null or not is_instance_valid(nz2) else "%s %s" % [Naresh.State.keys()[nz2.state], _f3(nz2.global_position)]
		var gh2 := pt.get_tree().get_first_node_in_group("ghat") as Ghat
		_say("resumed at %s from its save point (Naresh %s, creatures %s%s)" % [from, nar, str(was.slice(0, 2)),
			"" if gh2 == null else ", ghat phase '%s', Problem %s" % [gh2.phase, "out" if gh2.problem != null else "none"]])
	if _fail != "":
		return await _end_walk(steps, start, from, t0)
	_watcher(ctx)
	var i := start
	while i < steps.size() and _fail == "":
		if FileAccess.file_exists(dir + "/abort"):
			_failed("the client saw in the log: " + FileAccess.get_file_as_string(dir + "/abort").strip_edges())
			break
		var st: Dictionary = steps[i]
		var nm := String(st.get("name", "step %d" % i))
		# T4 v2: the boundary's independent observation, in the same tick as the point (no await between)
		var open_w: Array = []
		for w0 in ctx["watches"]:
			open_w.append(String(w0["name"]))
		var needs_open: Array = []
		for nd0 in st.get("needs", []):
			if not ctx["passed"].has(nd0):
				needs_open.append(String(nd0))
		_json_out("%s/%d.obs.json" % [rdir, i], GateObs.observe(pt, {"test.@open_watches": JSON.stringify(open_w), "test.@needs": JSON.stringify(needs_open)}))
		var point := SaveGame.collect(pt.boot, true)
		point["live_step"] = nm
		point["point_id"] = "%s/%d" % [_run, i]
		point["identity"] = identity
		_snap_live(point)
		var crs: Array = []
		for cr in pt.get_tree().get_nodes_in_group("creature"):
			var cp: Vector3 = (cr as Node3D).global_position
			crs.append([cp.x, cp.y, cp.z])
		point["live_creatures"] = crs
		# a game save doesn't keep what's in hand or where Naresh stands and
		# whom he follows (a resume put him at the van, P1's hands empty)
		var held: Array = []
		for pl in pt.boot.players:
			held.append(String(pl.held.name) if pl.held != null else "")
		point["live_held"] = held
		var nz: Naresh = pt.boot.naresh
		if nz != null and is_instance_valid(nz):
			point["live_naresh"] = {"pos": [nz.global_position.x, nz.global_position.y, nz.global_position.z],
				"state": int(nz.state), "leader": pt.boot.players.find(nz.leader) if nz.leader != null else -1,
				"go": [nz.go_point.x, nz.go_point.y, nz.go_point.z]}
		rv.collect(point)
		_json_out("%s/%d.json" % [rdir, i], point)
		ctx["allow"] = st.get("allow", [])
		# what this step needs from earlier watches
		for need in st.get("needs", []):
			var armed: bool = ctx["passed"].has(need)
			for w in ctx["watches"]:
				armed = armed or w["name"] == need
			if not armed:
				# a watch from a step before the resume point: arm it now (a
				# resumed run waited 23 min for a watch nobody had armed)
				var plan := {}
				for st2 in steps:
					for e2 in st2.get("expect", []):
						if String(e2.get("name", "")) == need:
							plan = e2
				if plan.is_empty():
					_failed("%s needs '%s', which no step expects" % [nm, need])
					break
				ctx["watches"].append({"name": need, "expr": String(plan.get("expr", "true")), "step": nm,
					"within_ms": int(float(plan.get("within", 5.0)) * 1000.0), "from": pt.clk()})
				_say("armed '%s' again (resumed past the step that set it)" % need)
			while not ctx["passed"].has(need) and _fail == "":
				await pt.wait(0.1)
		if _fail != "":
			break
		# the frame: a recording at a fixed fps cuts a resumed take here (tools/record_walk.sh)
		_say("step %s (%.0f s, frame %d)" % [nm, pt.el_ms(t0) / 1000.0, Engine.get_frames_drawn()])
		_t3_sample("%s/%d.t3.json" % [rdir, i], i, nm, PlayTest.gms(), _log.size() - 1, _trace_msgs.size(), pt.input_trace.size())
		var fa: Dictionary = msg.get("fail_at", {})
		if not fa.is_empty() and int(fa.get("step", -1)) == i:
			_break_after(nm, float(fa.get("s", 0.0)))
		ctx["step_from"] = pt.clk()
		ctx["step_max_ms"] = int(float(st.get("max", 300.0)) * 1000.0)
		ctx["step_name"] = nm
		# seed-v1 (resume fix): the global RNG from the same seed right before the step's first action, in the
		# fresh run (its own point's seed) and in a resume (the restored point's seed)
		seed(int(gate["seed"]) if i == start and gate.has("seed") else int(point.get("rng_seed", 0)))
		for c in st.get("do", []):
			if _fail != "":
				break
			var r: Dictionary = await _do(c)
			if not bool(r.get("ok", true)):
				_failed("%s: '%s' did not work %s" % [nm, String(c.get("do", "")), JSON.stringify(c)])
		for e in st.get("expect", []):
			if _fail != "":
				break
			var within := float(e.get("within", 5.0))
			var w := {"name": String(e.get("name", nm)), "expr": String(e.get("expr", "true")), "step": nm,
				"within_ms": int(within * 1000.0), "from": pt.clk()}
			if bool(e.get("watch", false)):
				ctx["watches"].append(w)
				continue
			while _fail == "" and not ctx["passed"].has(w["name"]):
				if bool(_eval(w["expr"])):
					ctx["passed"][w["name"]] = true
					_say("PASS %s (%.1f s)" % [w["name"], pt.el_ms(w["from"]) / 1000.0])
				elif pt.el_ms(w["from"]) > int(w["within_ms"]):
					_failed("%s: expected '%s' (%s) within %.0f s" % [nm, w["name"], w["expr"], within])
				else:
					await pt.wait(0.1)
		if _fail == "":
			i += 1
	# the open watches still get their time once the steps are done
	while _fail == "" and not ctx["watches"].is_empty() and not FileAccess.file_exists(dir + "/abort"):
		await pt.wait(0.1)
	ctx["running"] = false
	return await _end_walk(steps, i, from, t0)


func _end_walk(steps: Array, i: int, from: String, t0: Vector2i) -> Dictionary:
	_release()
	pt.release_everything()
	# T4 v2 (found by the cancel control, run A): the releases are queued input events; until they
	# are flushed the old presses still read as held (CTRL was "held" at the picture). Flush, then
	# check and take the picture.
	Input.flush_buffered_events()
	await pt.get_tree().physics_frame
	var held_at_shot: Array = []
	for k in GateObs.KEYS:
		if Input.is_physical_key_pressed(k):
			held_at_shot.append("key:%d" % k)
	for bt in range(JOY_BUTTON_SDL_MAX):
		if Input.is_joy_button_pressed(0, bt as JoyButton):
			held_at_shot.append("pad:%d" % bt)
	var shot := ""
	if _fail != "":
		_say("inputs held at the failure picture: %s; presses dropped by the gate so far: %d" % [str(held_at_shot), pt.blocked_sends])
		await pt.shot("walk_fail")
		shot = ProjectSettings.globalize_path(pt.shots_dir + "/test_walk_fail.png")
	_say("%s %s in %.0f s" % ["FAILED" if _fail != "" else "DONE", _walk_name, pt.el_ms(t0) / 1000.0])
	var failed_step := String(steps[mini(i, steps.size() - 1)].get("name", "")) if _fail != "" and steps.size() > 0 else ""
	# where the next run starts by default (tools/live.py: resume from the last failed step)
	var lf := "%s/points/%s_last_fail.json" % [dir, _walk_name]
	if _fail != "":
		var ff := FileAccess.open(lf, FileAccess.WRITE)
		ff.store_string(JSON.stringify({"step": failed_step, "index": mini(i, steps.size() - 1), "fail": _fail,
			"from": from, "at": Time.get_datetime_string_from_system(), "run": _run,
			"point": "%s/%d" % [_run, mini(i, steps.size() - 1)]}))
		ff.close()
	elif FileAccess.file_exists(lf):
		DirAccess.remove_absolute(lf)
	return {"ok": _fail == "", "fail": _fail, "failed_step": failed_step,
		"log": _log.duplicate(), "shot": shot, "run": _run, "held_at_shot": held_at_shot,
		"blocked_sends": pt.blocked_sends, "input_sends": pt.input_sends, "walk_gen": pt.walk_gen}


const GIVE_UP := ["I can't get there.", "I can't get any closer than this.", "Found a way round!"]

## Alongside the steps, every 0.1 s: the open watches and the always-on rules.
func _watcher(ctx: Dictionary) -> void:
	_events.clear()
	var mark := Vector3.INF
	var still := 0.0
	var van_mark := Vector3.INF
	var van_still := 0.0
	while bool(ctx["running"]) and _fail == "":
		await pt.wait(0.1)
		if FileAccess.file_exists(dir + "/abort"):
			_failed("the client saw in the log: " + FileAccess.get_file_as_string(dir + "/abort").strip_edges())
			break
		# read fresh each tick: there's no Naresh before a jump, and a jump
		# makes a new one (the first watcher read him once and died on it).
		# No Naresh (the bridge, #5) must not switch the rest off: it skipped
		# the step limits and the watches too, and a stuck van sat 90 s
		# unwatched (the user, 2026-10-20)
		var n: Naresh = pt.boot.naresh
		var has_n := n != null and is_instance_valid(n)
		var allow: Array = ctx["allow"]
		var watches: Array = ctx["watches"]
		if ctx.has("step_from") and pt.el_ms(ctx["step_from"]) > int(ctx["step_max_ms"]):
			_failed("step %s took longer than its limit" % ctx["step_name"])
			break
		for w in watches.duplicate():
			if bool(_eval(w["expr"])):
				ctx["passed"][w["name"]] = true
				watches.erase(w)
				_say("PASS %s (%.1f s, watched)" % [w["name"], pt.el_ms(w["from"]) / 1000.0])
			elif pt.el_ms(w["from"]) > int(w["within_ms"]):
				_failed("%s: expected '%s' (%s) in time (watched)" % [w["step"], w["name"], w["expr"]])
		# the van: someone driving with the throttle down, and it doesn't move
		# for 5 s = stuck (the skill's "nothing that should move stands still")
		var c: Camper = pt.camper()
		var pushing := c != null and c.engine_on and pt.p1().seat != null and Input.is_physical_key_pressed(KEY_W)
		if pushing and van_mark != Vector3.INF and c.global_position.distance_to(van_mark) < 0.3:
			van_still += 0.1
			if van_still > 5.0 and not "van_still" in allow:
				_failed("the van stuck for 5 s, throttle down: " + await pt.van_stuck_report())
				break
		elif c != null:
			van_still = 0.0
			van_mark = c.global_position
		if not has_n:
			continue
		for ev in _events:
			var t := String(ev[2])
			if ev[1] == "hears" and t in GIVE_UP and not t in allow:
				_failed("Naresh: '%s' (%s at %s, job '%s')" % [t, Naresh.State.keys()[n.state], _f3(n.global_position), n.job])
			elif ev[1] == "sees" and t.begins_with("You wake up") and not "taken" in allow:
				_failed("%s was taken: %s" % [ev[0], t])
		_events.clear()
		if n.state == Naresh.State.TAKEN and not "naresh_taken" in allow:
			_failed("Naresh was taken (near %s)" % n.taken_near)
			break
		# Naresh should be moving: on his way somewhere, or following someone far off
		var moving := n.state == Naresh.State.GO or (n.state == Naresh.State.FOLLOW and n.leader != null
			and Vector2(n.leader.global_position.x - n.global_position.x, n.leader.global_position.z - n.global_position.z).length() > 4.0)
		if moving and mark != Vector3.INF and n.global_position.distance_to(mark) < 0.3:
			still += 0.1
			if still > 6.0 and not "naresh_still" in allow:
				_failed("Naresh stuck for 6 s in %s at %s (job '%s')" % [Naresh.State.keys()[n.state], _f3(n.global_position), n.job])
		else:
			still = 0.0
			mark = n.global_position
