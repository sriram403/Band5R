class_name CoolantJug
extends Carryable

## A 5 L jug of coolant mix from the water works. Poured into the van's
## radiator it tops the system up and seals the split hose for the trip.

const CAPACITY := 5.0
var litres := CAPACITY


func _ready() -> void:
	item_name = "coolant jug"
	kind = "coolant"
	_update_mass()
	_build()
	super._ready()


func label() -> String:
	if litres <= 0.05:
		return "coolant jug (empty)"
	return "coolant jug (%d L)" % int(ceil(litres))


## The jug weighs what is in it (SaveGame calls this after restoring litres).
func _update_mass() -> void:
	mass = 1.0 + litres


func pour(amount: float) -> float:
	var out := minf(amount, litres)
	litres -= out
	_update_mass()
	_refresh_prompt()
	return out


func _build() -> void:
	var blue := ToonMat.make(Color(0.30, 0.62, 0.92), 0.012)
	var cap := ToonMat.make(Color(0.95, 0.85, 0.30), 0.008)
	add_child(Build.box(Vector3(0.26, 0.36, 0.18), blue, Vector3(0, 0.18, 0), Vector3.ZERO, "Body"))
	add_child(Build.cyl(0.05, 0.08, cap, Vector3(0.06, 0.40, 0), Vector3.ZERO, 8, "Cap"))
	add_child(Build.box(Vector3(0.06, 0.12, 0.05), blue, Vector3(-0.08, 0.40, 0), Vector3.ZERO, "Handle"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.26, 0.44, 0.18)
	cs.shape = sh
	cs.position = Vector3(0, 0.22, 0)
	add_child(cs)
