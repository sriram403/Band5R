class_name MethodRec
extends Node
## The final method (test-method research, Stage 4, notes/method_research/
## final_method_draft.md + final_decisions.md). Test code only.
## Writes <progress dir>/method_events.txt: one JSON line per event, flushed at
## once, read from OUTSIDE by tools/method/method_watch.py (the one supervisor).
## Events: OPEN / CLOSE (step deadlines with unique instance ids, M3), CHECK
## (every check() with its outcome, M9), WORK (required-work receipts, M9),
## ATTEMPT (every ramp attempt, M11 / M12), PREFLIGHT / STALE (validated reads,
## M4), ABSENT (a required object validly seen missing, M5), FIRE / EVAL /
## WINDOW (the state rules, from C2Watch), PROFILE.
## The fixtures (--method-fixture=<id>) are for the builder's controls only,
## off by default; nothing here or in the supervisor reads them to judge.

const WATCHED := ["ramp", "c2_more",
	# #6, the ghat (ported 2026-11-09)
	"ghat_heat", "ghat_looks", "ghat_net", "ghat_places", "ghat_jug", "ghat_spring", "ghat_marks"]
## M12: the fixed five-profile schedule (target km/h, lane m)
const PROFILES := {"k0": [62.0, -0.5], "k1": [64.0, 0.5], "k2": [66.0, 0.0], "k3": [80.0, -0.5], "k4": [80.0, 0.5]}

static var inst: MethodRec = null

var path := ""
var seq := 0
var _n := 0                       ## OPEN instance counter
var _fa: FileAccess
var profile := "k3"
var fixture := ""                 ## the builder's controls only (never read to judge)


static func ensure(p: Node, progress_path: String) -> MethodRec:
	if progress_path == "":
		return null
	if inst == null or not is_instance_valid(inst):
		inst = MethodRec.new()
		inst.name = "MethodRec"
		inst.path = progress_path.get_base_dir().path_join("method_events.txt")
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--method-profile="):
				inst.profile = a.get_slice("=", 1)
			elif a.begins_with("--method-fixture="):
				inst.fixture = a.get_slice("=", 1)
		if not PROFILES.has(inst.profile):
			inst.ev("PLAN_BAD", {"what": "unknown profile '%s'" % inst.profile})
			inst.profile = "k3"
		p.add_child(inst)
	return inst


func active() -> bool:
	return RigBeat.scen in WATCHED


func target() -> float:
	return float(PROFILES[profile][0])


func lane() -> float:
	return float(PROFILES[profile][1])


func ev(kind: String, data := {}) -> void:
	var d := {"ev": kind, "seq": seq, "unix": Time.get_unix_time_from_system(), "pf": Engine.get_physics_frames(), "scen": RigBeat.scen}
	d.merge(data)
	seq += 1
	if _fa == null:
		_fa = FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
		if _fa == null:
			return
		_fa.seek_end()
	_fa.store_line(JSON.stringify(d))
	_fa.flush()


## A step deadline published before the step is entered (M3). Returns the
## unique instance id ("" outside a watched scenario). Only the host's clock
## judges it; a repeated OPEN is a new instance and can't renew an old one.
func open(step: String, secs: float) -> String:
	if not active():
		return ""
	_n += 1
	var id := "%s#%d" % [step, _n]
	ev("OPEN", {"id": id, "step": step, "secs": snappedf(secs, 0.01)})
	return id


func close(id: String) -> void:
	if id != "":
		ev("CLOSE", {"id": id})


func work(id: String, ok: bool, data := {}) -> void:
	var d := data.duplicate()
	d["id"] = id
	d["ok"] = ok
	ev("WORK", d)


func check(what: String, ok: bool) -> void:
	if active():
		ev("CHECK", {"text": what, "ok": ok})
