class_name RigBeat
extends Node

## c1, the rig layer (test code only; research trial c1, 2026-11-05).
## Proves a play-test run was alive, in control and complete. Writes, to
## <progress dir>/rig.txt, one flushed line every 0.5 s (a heartbeat) and one
## line per rig event. tools/rig/rig_watch.py reads it from OUTSIDE the game:
## a frozen game can't report itself, so the watcher notices the silence.
##
## Beat line, tab separated key=value:
##   beat  ms (wall clock), gen (scene generation: +1 per PlayTest), pid,
##         pf (engine physics frames: stop only when the main loop stops or
##         time_scale is 0), wf (world frames: a pausable node's own physics
##         ticks, stop while the tree is paused), paused, note (pause note),
##         scen (scenario now running), p1 / p2 (ok / missing), p2dev (PAD0 /
##         KBM / none), step (the last [test] line)
## Event lines: "ev<TAB><kind><TAB><text>"; kinds: start, end, lint, need,
##   input_lost, pause_hold, quit.
## It never reads the injection switches (dev/RigInject.gd): it sees effects.

static var path := ""
static var scen := ""
static var step := ""
static var gen := 0
static var _inst: RigBeat = null

var boot: Node
var _world_frames := 0
var _tick: Node
var _t := 0.0
var _pending: Array = []     ## input receipts waiting for the next frames
var _latest := {}            ## channel ("axis1", "key87") -> the last value the test sent on it


## One per process: it sits on the root so it outlives the `save` reload.
static func ensure(b: Node, progress_path: String) -> RigBeat:
	gen += 1
	if progress_path == "":
		return null
	path = progress_path.get_base_dir().path_join("rig.txt")
	if _inst == null or not is_instance_valid(_inst):
		_inst = RigBeat.new()
		_inst.name = "RigBeat"
		_inst.process_mode = Node.PROCESS_MODE_ALWAYS
		b.get_tree().root.add_child.call_deferred(_inst)
	_inst.boot = b
	return _inst


static func event(kind: String, text: String) -> void:
	if path == "":
		return
	_append("ev\t%s\t%s" % [kind, text.replace("\t", " ").replace("\n", " ")])
	print("[rig] %s: %s" % [kind, text])


static func _append(line: String) -> void:
	var fa := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	if fa == null:
		return
	fa.seek_end()
	fa.store_string(line + "\n")
	fa.close()


func _ready() -> void:
	# the world clock: an ordinary pausable node; its ticks stop when the game pauses
	_tick = Node.new()
	_tick.name = "WorldTick"
	_tick.process_mode = Node.PROCESS_MODE_PAUSABLE
	_tick.set_script(_tick_script())
	add_child(_tick)


func _tick_script() -> GDScript:
	var s := GDScript.new()
	s.source_code = "extends Node\nvar n := 0\nfunc _physics_process(_d: float) -> void:\n\tn += 1\n"
	s.reload()
	return s


func _process(delta: float) -> void:
	_t += delta
	if _t < 0.5:
		return
	_t = 0.0
	_beat()


func _physics_process(_d: float) -> void:
	_check_receipts()


func _beat() -> void:
	var b := boot
	var p1 := "missing"
	var p2 := "missing"
	var p2dev := "none"
	var note := ""
	var paused := get_tree().paused
	if b != null and is_instance_valid(b):
		var pl: Array = b.players
		if pl.size() > 0 and is_instance_valid(pl[0]) and pl[0].is_inside_tree():
			p1 = "ok"
		if pl.size() > 1 and is_instance_valid(pl[1]) and pl[1].is_inside_tree():
			p2 = "ok"
		if b.devices.size() > 1 and b.devices[1] != null:
			var d: InputDevice = b.devices[1]
			p2dev = ("PAD%d" % d.pad) if d.kind == InputDevice.Kind.PAD else "KBM"
		note = str(b.pause_note).substr(0, 60)
	_append("beat\tms=%d\tgen=%d\tpid=%d\tpf=%d\twf=%d\tpaused=%d\tnote=%s\tscen=%s\tp1=%s\tp2=%s\tp2dev=%s\tstep=%s" % [
		int(Time.get_unix_time_from_system() * 1000.0), gen, OS.get_process_id(),
		Engine.get_physics_frames(), _tick.get("n") if _tick != null else -1,
		1 if paused else 0, note, scen, p1, p2, p2dev, step.substr(0, 80).replace("\t", " ")])


# --- input receipts: requested -> accepted on the intended player's device -----

## Called by PlayTest's input helpers. Checked two physics frames later
## (parse_input_event is flushed on the next frame).
func request(kind: String, code: int, value: float) -> void:
	_latest["%s%d" % [kind, code]] = value     # the last value sent on this channel
	# releases (key up, button up, stick back to 0) aren't judged: only what
	# asks a player to do something; and only inside a scenario (the teardown
	# between scenarios unplugs the pretend pad on purpose)
	if scen == "" or absf(value) < 0.05:
		return
	_pending.append({"kind": kind, "code": code, "v": value, "at": Engine.get_physics_frames(),
		"pa": Engine.get_process_frames(), "scen": scen})


func _check_receipts() -> void:
	if _pending.is_empty():
		return
	var now := Engine.get_physics_frames()
	# parse_input_event is applied at the start of the next PROCESS frame; at a
	# low frame rate (after a screenshot) several physics steps run in one, so
	# wait for two process frames as well as two physics frames (q3)
	var pnow := Engine.get_process_frames()
	while not _pending.is_empty() and now >= int(_pending[0]["at"]) + 2 and pnow >= int(_pending[0]["pa"]) + 2:
		var r: Dictionary = _pending.pop_front()
		if r["scen"] != scen:
			continue       # its scenario ended before the check
		if absf(float(_latest.get("%s%d" % [r["kind"], r["code"]], r["v"])) - float(r["v"])) > 0.05:
			continue       # the test itself sent a different value on that channel since (a resend of the same value doesn't count)
		var why := _receipt(r)
		if why != "":
			RigBeat.event("input_lost", "%s in %s: %s" % [_req_text(r), scen, why])


func _req_text(r: Dictionary) -> String:
	match r["kind"]:
		"axis":
			return "pad axis %d = %.2f" % [r["code"], r["v"]]
		"button":
			return "pad button %d %s" % [r["code"], "down" if r["v"] > 0.5 else "up"]
	return "key %s %s" % [OS.get_keycode_string(r["code"]), "down" if r["v"] > 0.5 else "up"]


## "" when the input reached the intended device, else why not. Only whether
## it REACHED the device: what the body then did is the game's business.
func _receipt(r: Dictionary) -> String:
	var b := boot
	if b == null or not is_instance_valid(b) or b.devices.size() < 2:
		return ""
	if r["kind"] == "key":
		if r["v"] < 0.5:
			return ""      # releases: nothing to receive
		if not Input.is_physical_key_pressed(r["code"]):
			# released again by the test within 2 frames (a tap) is not a loss
			return ""
		for d in b.devices:
			if d.kind == InputDevice.Kind.KBM and d.active:
				return ""
		return "no player is on the keyboard"
	# pad inputs are P2's (the pretend pad is device 0)
	var d: InputDevice = b.devices[1]
	if d.kind != InputDevice.Kind.PAD:
		return "P2's device is the keyboard, not a pad: the pad input never reached P2"
	if d.pad != 0:
		return "P2's pad is device %d, the test sent to device 0" % d.pad
	if b.players.size() < 2 or not is_instance_valid(b.players[1]) or b.players[1].dev != d:
		return "P2's player isn't reading P2's device"
	if r["kind"] == "axis":
		var want: float = r["v"]
		var axis: int = r["code"]
		var now_v := Input.get_joy_axis(0, axis)
		if absf(now_v - want) > 0.05:
			return "" if absf(want) < 0.05 else ("axis reads %.2f, sent %.2f" % [now_v, want])
		if (axis == JOY_AXIS_LEFT_X or axis == JOY_AXIS_LEFT_Y) and absf(want) > 0.3 and d.active and d.move().length() < 0.2:
			return "the stick moved but P2's device reads no movement (%s)" % str(d.move())
		return ""
	if r["v"] > 0.5 and not Input.is_joy_button_pressed(0, r["code"]):
		return ""      # a tap released within 2 frames
	return ""
