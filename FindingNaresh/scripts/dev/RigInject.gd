class_name RigInject
extends Node

## c1's injection hooks FOR THE REFEREE (test code; research trial c1).
## Breaks the test or the run on purpose, so the rig can be scored on noticing
## the EFFECT. The rig (RigBeat.gd, tools/rig/rig_watch.py) never reads these.
##
##   ARGS="--inject=<ID>[@<s>][:<text>]" tools/rig_run.sh <scenarios>
##   <s>: seconds after the first scenario starts (default 20)
##   T1  P2's pad unplugged mid-run: boot._on_joy_changed(0, false)
##   T2  a stale expression in the scenario's declared needs (<text>, default
##       "rj().ramp_lip"), checked before the run
##   T3  the test plan runs `save` first, so the rest are queued after it
##   N1  the game frozen: the main thread blocks for good
##   N2  the game paused: get_tree().paused = true
##   N3  a player missing: P2 taken out of the scene
##   N4  a scenario asked for but skipped: the plan drops the first one silently

var id := ""
var at_s := 20.0
var text := ""
var _armed := false
var _t := 0.0
var boot: Node


static func from_args(b: Node) -> RigInject:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--inject="):
			var r := RigInject.new()
			r.boot = b
			var v := a.substr(9)
			if ":" in v:
				r.text = v.get_slice(":", 1)
				v = v.get_slice(":", 0)
			if "@" in v:
				r.at_s = v.get_slice("@", 1).to_float()
				v = v.get_slice("@", 0)
			r.id = v
			r.name = "RigInject"
			r.process_mode = Node.PROCESS_MODE_ALWAYS
			print("[inject] %s at %.0f s %s" % [r.id, r.at_s, r.text])
			return r
	return null


## The plan, as the test would run it, misbehaving for T3 / N4.
func plan(order: Array, selection: String) -> Array:
	var o := order.duplicate()
	if id == "T3" and "save" in o:
		o.erase("save")
		o.insert(0, "save")
	elif id == "N4":
		for s in o:
			if selection == "" or s in selection.split(","):
				o.erase(s)      # the first scenario that would run, dropped
				break
	return o


## The declared needs, misbehaving for T2.
func needs(n: Dictionary) -> Dictionary:
	if id != "T2":
		return n
	var out := n.duplicate(true)
	for k in out.keys():
		out[k].append(text if text != "" else "rj().ramp_lip")
	return out


## Called when the first scenario starts: the timed ones go off at_s later.
func arm() -> void:
	if id in ["T1", "N1", "N2", "N3"]:
		_armed = true
		_t = 0.0


func _process(delta: float) -> void:
	if not _armed:
		return
	_t += delta
	if _t < at_s:
		return
	_armed = false
	print("[inject] %s now" % id)
	match id:
		"T1":
			boot._on_joy_changed(0, false)
		"N1":
			while true:
				OS.delay_msec(1000)
		"N2":
			get_tree().paused = true
		"N3":
			var q: Node = boot.players[1]
			q.get_parent().remove_child(q)
