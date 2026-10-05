class_name LeakyCan
extends CoolantJug

## An old oil can on the pump house bench (the water works, S6 in
## `design/PUZZLE_CHANGES.md`): a fallback if the coolant jug was left at
## P2's house. It holds 4 L of coolant at the tap but leaks a litre a
## minute, dripping as you go: it works if you hurry (3 L seals the hose).

const LEAK_PER_S := 1.0 / 60.0
const SIZE := 4.0
var _drip_t := 0.0


func _ready() -> void:
	super._ready()
	item_name = "old oil can"


func capacity() -> float:
	return SIZE


func label() -> String:
	if litres <= 0.05:
		return "old oil can (empty, leaky)"
	return "old oil can (%.1f L, leaking)" % litres


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if litres <= 0.0 or pouring:
		return
	litres = maxf(0.0, litres - LEAK_PER_S * delta)
	_update_mass()
	_drip_t -= delta
	if _drip_t <= 0.0:
		_drip_t = 0.5
		_refresh_prompt()
		if stowed_in == null:
			Sfx.play3d("tick", global_position, -22.0, 0.3)


func _build() -> void:
	var red := ToonMat.make(Color(0.62, 0.20, 0.14), 0.012)
	var tin := ToonMat.make(Color(0.55, 0.55, 0.52), 0.01)
	add_child(Build.cyl(0.11, 0.3, red, Vector3(0, 0.15, 0), Vector3.ZERO, 12, "Body"))
	add_child(Build.cone(0.11, 0.08, red, Vector3(0, 0.34, 0), Vector3.ZERO, 12, "Top"))
	add_child(Build.cyl(0.015, 0.22, tin, Vector3(0.07, 0.42, 0), Vector3(0, 0, -45), 6, "Spout"))
	add_child(Build.sphere(0.03, ToonMat.make(Color(0.20, 0.18, 0.16)), Vector3(0.06, 0.08, 0.1), Vector3(1, 0.6, 0.4), "Dent"))
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.11
	sh.height = 0.4
	cs.shape = sh
	cs.position = Vector3(0, 0.2, 0)
	add_child(cs)
