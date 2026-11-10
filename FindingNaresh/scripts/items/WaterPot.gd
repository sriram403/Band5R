class_name WaterPot
extends CoolantJug

## An old steel water pot left at a spring pipe on the ghat (#6, agreed
## 2026-11-09): fill it at the pipe, carry it to the van, pour it into the
## radiator. Plain water works in a real radiator. It holds 2.5 L: hide well
## and one pot is enough; hide badly and it takes two trips.

const POT_L := 2.5


func _init() -> void:
	litres = 0.0


func _ready() -> void:
	super._ready()
	item_name = "steel pot"
	_refresh_prompt()


func capacity() -> float:
	return POT_L


func label() -> String:
	if litres <= 0.05:
		return "steel pot (empty)"
	return "steel pot (%.1f L of water)" % litres


## Water from the spring: returns what went in.
func fill(amount: float) -> float:
	var got := minf(amount, POT_L - litres)
	litres += got
	_update_mass()
	_refresh_prompt()
	return got


func _update_mass() -> void:
	mass = 0.8 + litres


func _build() -> void:
	var steel := ToonMat.make(Color(0.62, 0.64, 0.66), 0.02)
	var dent := ToonMat.make(Color(0.48, 0.50, 0.52), 0.02)
	# a squat round pot with a rolled rim, a dent, and a wire handle
	add_child(Build.cyl(0.15, 0.24, steel, Vector3(0, 0.12, 0), Vector3.ZERO, 12, "Body"))
	add_child(Build.cyl(0.165, 0.025, steel, Vector3(0, 0.245, 0), Vector3.ZERO, 12, "Rim"))
	add_child(Build.box(Vector3(0.06, 0.07, 0.02), dent, Vector3(0.1, 0.1, 0.105), Vector3(0, 35, 8), "Dent"))
	add_child(Build.box(Vector3(0.30, 0.012, 0.012), dent, Vector3(0, 0.33, 0), Vector3(0, 0, 0), "Handle"))
	for sx in [-0.15, 0.15]:
		add_child(Build.box(Vector3(0.012, 0.09, 0.012), dent, Vector3(sx, 0.29, 0), Vector3.ZERO, "HandleSide"))
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.16
	sh.height = 0.26
	cs.shape = sh
	cs.position = Vector3(0, 0.13, 0)
	add_child(cs)
