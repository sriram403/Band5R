class_name GhatWatch
extends Node

## #6's state rules (the test method ported to the ghat, notes/method_research/
## FINAL.md "starter checklist"). Test code only. Every physics tick of a #6
## scenario it reads the game's own state and reports, through MethodRec, a
## FIRE (a FAIL in the verdict) the moment a rule breaks, and at the end of the
## scenario how often each rule looked (RULES):
##   H1  heat only while it's interested: the van's Problem heat never grows
##       while no Problem is interested (the heat rule's core)
##   H2  the dash needle shows the real heat (an indicator matches the state)
##   H3  coolant only rises when something is poured (nothing from nowhere),
##       while the encounter is on
## A rule that never looked is reported NOT REACHED by the verdict.

const RULES := ["H1", "H2", "H3"]
const NEEDLE_TOL := 3.0          ## deg

static var inst: GhatWatch = null

var scen := ""
var stat := {}
var _heat := 0.0
var _was_int := false
var _cool := -1.0
var _added := 0.0
var _fired := {}


static func ensure(p: Node) -> GhatWatch:
	if inst == null or not is_instance_valid(inst):
		inst = GhatWatch.new()
		inst.name = "GhatWatch"
		p.add_child(inst)
	return inst


func _mr() -> MethodRec:
	return MethodRec.inst if MethodRec.inst != null and is_instance_valid(MethodRec.inst) else null


func _physics_process(_delta: float) -> void:
	var now := RigBeat.scen if RigBeat.scen.begins_with("ghat") else ""
	if now != scen:
		_end()
		scen = now
		stat = {}
		for r in RULES:
			stat[r] = {"eval": 0, "win": 0, "err": 0, "find": 0}
		_fired = {}
		_cool = -1.0
	if scen == "":
		return
	var c := get_tree().get_first_node_in_group("camper") as Camper
	var g := get_tree().get_first_node_in_group("ghat") as Ghat
	if c == null or c.attack == null or g == null:
		return
	# H1: the interest is read a tick late by the van (creatures may tick after it)
	var inter: bool = c.attack.interested()
	var heat: float = c.attack.heat_added
	if heat < _heat - 0.001:
		_heat = heat            # a new encounter starts from 0
	_look("H1")
	if heat > _heat + 0.001 and not inter and not _was_int:
		_fire("H1", "the van heated %.2f C with no Problem interested (phase '%s')" % [heat - _heat, g.phase])
	_heat = heat
	_was_int = inter
	# H2: the needle against the temperature
	var n: Node3D = c._needles.get("temp")
	if n != null:
		_look("H2")
		var want := remap((c.temp - Camper.TEMP_AMBIENT) / (Camper.TEMP_MAX - Camper.TEMP_AMBIENT), 0.0, 1.0, 60.0, -60.0)
		if absf(n.rotation_degrees.z - want) > NEEDLE_TOL:
			_fire("H2", "the temperature needle reads %.0f deg, the engine is at %.1f C (%.0f deg)" % [n.rotation_degrees.z, c.temp, want])
	# H3: coolant up only with something poured, during the encounter
	if g.phase != "" and _cool >= 0.0:
		_look("H3")
		if c.coolant > _cool + 0.0005 and c.coolant_added <= _added + 0.00001:
			_fire("H3", "the coolant rose %.1f %% with nothing poured" % ((c.coolant - _cool) * 100.0))
	_cool = c.coolant
	_added = c.coolant_added


func _look(r: String) -> void:
	stat[r]["eval"] += 1


func _fire(r: String, text: String) -> void:
	stat[r]["find"] += 1
	if _fired.has(r):
		return               # once a scenario is enough to name it
	_fired[r] = true
	RigBeat.event("rule", "%s: %s" % [r, text])
	print("[ghatwatch] FIRE %s: %s" % [r, text])
	if _mr():
		_mr().ev("FIRE", {"rule": r, "text": text, "picture": ""})


func _end() -> void:
	if scen == "":
		return
	print("[ghatwatch] %s: %s" % [scen, str(stat)])
	if _mr():
		_mr().ev("RULES", {"scen_end": scen, "stat": stat.duplicate(true), "reached": stat.keys().filter(func(k): return stat[k]["eval"] > 0)})
