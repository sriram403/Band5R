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

var pt: PlayTest
var dir := ""
var _last_id := -1
var _messages: Array = []
var _events: Array = []          ## [who, "sees"/"hears", text] for the watcher
var _fail := ""                  ## the watched run's first failure ("" = none)
var _log: Array = []             ## the watched run's PASS / FAIL lines
var _walk_name := ""


func _init(test: PlayTest) -> void:
	pt = test


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
			_events.append([who, "sees", String(t)]))
		p.speech.connect(func(w, t, _s):
			_messages.append("%s hears %s: %s" % [who, w, t])
			_events.append([who, "hears", String(t)]))
	print("[live] ready, commands in %s/cmd.json" % dir)
	_write({"id": -1, "ready": true, "state": state()})
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
			var rep: Dictionary = await _run_walk(data["walk"], String(data.get("from", "")))
			_messages.clear()
			rep["id"] = _last_id
			rep["state"] = state()
			_write(rep)
			continue
		var cmds: Array = data.get("cmds", [])
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
				else:
					args.append(a)
			var v = await pt.callv(String(c.get("fn", "")), args)
			if v is bool:
				r["ok"] = v
			r["value"] = str(v)
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
			var road: Route = pt.boot.builder.network.road(String(c.get("road", "coast_road")))
			var to := _v3(c.get("to"))
			var stop := road.point_count() - 2 if to == Vector3.INF else int(road.nearest(to.x, to.z)["index"])
			var cond := String(c.get("until", "false"))
			await pt.drive_until(road, stop, func() -> bool: return bool(_eval(cond)), float(c.get("max", 120.0)), float(c.get("kmh", -1.0)))
			pt.key(KEY_W, false)
		"shot":
			var nm := "live_" + String(c.get("name", "x"))
			await pt.shot(nm)
			r["shot"] = ProjectSettings.globalize_path("res://_shots/test_%s.png" % nm)
		_:
			r["ok"] = false
			r["error"] = "unknown command"
	return r


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


func _release() -> void:
	for k in [KEY_W, KEY_A, KEY_S, KEY_D, KEY_SHIFT, KEY_E, KEY_SPACE]:
		pt.key(k, false)
	pt.mouse_button(MOUSE_BUTTON_RIGHT, false)
	for a in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y, JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		pt.pad_axis(a, 0.0)


func _failed(why: String) -> void:
	if _fail == "":
		_fail = why
		_say("FAIL " + why)


func _run_walk(walk: Dictionary, from: String) -> Dictionary:
	_walk_name = String(walk.get("name", "walk"))
	_fail = ""
	_log.clear()
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
	var t0 := Time.get_ticks_msec()
	var ctx := {"watches": [], "passed": {}, "allow": [], "running": true}
	for c in walk.get("setup", []):
		await _do(c)
	if start > 0:
		var pp := "%s/points/%s_%d.json" % [dir, _walk_name, start]
		if not FileAccess.file_exists(pp):
			return {"ok": false, "fail": "no save point for %s (run the walk once from the start)" % from, "log": []}
		SaveGame.apply(pt.boot, JSON.parse_string(FileAccess.get_file_as_string(pp)))
		await pt.wait(1.0)
		_say("resumed at %s from its save point" % from)
	_watcher(ctx)
	var i := start
	while i < steps.size() and _fail == "":
		var st: Dictionary = steps[i]
		var nm := String(st.get("name", "step %d" % i))
		var f := FileAccess.open("%s/points/%s_%d.json" % [dir, _walk_name, i], FileAccess.WRITE)
		f.store_string(JSON.stringify(SaveGame.collect(pt.boot)))
		f.close()
		ctx["allow"] = st.get("allow", [])
		# what this step needs from earlier watches
		for need in st.get("needs", []):
			while not ctx["passed"].has(need) and _fail == "":
				await pt.wait(0.1)
		if _fail != "":
			break
		_say("step %s (%.0f s)" % [nm, (Time.get_ticks_msec() - t0) / 1000.0])
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
				"until": Time.get_ticks_msec() + int(within * 1000.0), "from": Time.get_ticks_msec()}
			if bool(e.get("watch", false)):
				ctx["watches"].append(w)
				continue
			while _fail == "" and not ctx["passed"].has(w["name"]):
				if bool(_eval(w["expr"])):
					ctx["passed"][w["name"]] = true
					_say("PASS %s (%.1f s)" % [w["name"], (Time.get_ticks_msec() - w["from"]) / 1000.0])
				elif Time.get_ticks_msec() > w["until"]:
					_failed("%s: expected '%s' (%s) within %.0f s" % [nm, w["name"], w["expr"], within])
				else:
					await pt.wait(0.1)
		if _fail == "":
			i += 1
	# the open watches still get their time once the steps are done
	while _fail == "" and not ctx["watches"].is_empty():
		await pt.wait(0.1)
	ctx["running"] = false
	_release()
	var shot := ""
	if _fail != "":
		await pt.shot("walk_fail")
		shot = ProjectSettings.globalize_path("res://_shots/test_walk_fail.png")
	_say("%s %s in %.0f s" % ["FAILED" if _fail != "" else "DONE", _walk_name, (Time.get_ticks_msec() - t0) / 1000.0])
	return {"ok": _fail == "", "fail": _fail, "failed_step": String(steps[i].get("name", "")) if _fail != "" and i < steps.size() else "",
		"log": _log.duplicate(), "shot": shot}


const GIVE_UP := ["I can't get there.", "I can't get any closer than this.", "Found a way round!"]

## Alongside the steps, every 0.1 s: the open watches and the always-on rules.
func _watcher(ctx: Dictionary) -> void:
	_events.clear()
	var n: Naresh = pt.boot.naresh
	var mark := n.global_position
	var still := 0.0
	while bool(ctx["running"]) and _fail == "":
		await pt.wait(0.1)
		var allow: Array = ctx["allow"]
		var watches: Array = ctx["watches"]
		for w in watches.duplicate():
			if bool(_eval(w["expr"])):
				ctx["passed"][w["name"]] = true
				watches.erase(w)
				_say("PASS %s (%.1f s, watched)" % [w["name"], (Time.get_ticks_msec() - w["from"]) / 1000.0])
			elif Time.get_ticks_msec() > w["until"]:
				_failed("%s: expected '%s' (%s) in time (watched)" % [w["step"], w["name"], w["expr"]])
		for ev in _events:
			var t := String(ev[2])
			if ev[1] == "hears" and t in GIVE_UP and not t in allow:
				_failed("Naresh: '%s' (%s at %s, job '%s')" % [t, Naresh.State.keys()[n.state], _f3(n.global_position), n.job])
			elif ev[1] == "sees" and t.begins_with("You wake up") and not "taken" in allow:
				_failed("%s was taken: %s" % [ev[0], t])
		_events.clear()
		# Naresh should be moving: on his way somewhere, or following someone far off
		var moving := n.state == Naresh.State.GO or (n.state == Naresh.State.FOLLOW and n.leader != null
			and Vector2(n.leader.global_position.x - n.global_position.x, n.leader.global_position.z - n.global_position.z).length() > 4.0)
		if moving and n.global_position.distance_to(mark) < 0.3:
			still += 0.1
			if still > 6.0 and not "naresh_still" in allow:
				_failed("Naresh stuck for 6 s in %s at %s (job '%s')" % [Naresh.State.keys()[n.state], _f3(n.global_position), n.job])
		else:
			still = 0.0
			mark = n.global_position
		if FileAccess.file_exists(dir + "/abort"):
			_failed("the client saw in the log: " + FileAccess.get_file_as_string(dir + "/abort").strip_edges())
