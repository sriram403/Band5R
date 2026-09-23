class_name FuelCan
extends Carryable

## A 20 L jerrycan. Its weight follows its contents, so a full can is a
## two-hand lug and an empty one swings about - which is also how an attentive
## player can tell a can is empty without being told.

const CAPACITY := 20.0
const EMPTY_MASS := 2.0
const KG_PER_L := 0.8

var litres := CAPACITY


static func create(fill := CAPACITY) -> FuelCan:
	var c := FuelCan.new()
	c.litres = fill
	return c


func _ready() -> void:
	item_name = "fuel can"
	kind = "fuel_can"
	_update_mass()
	_build()
	super._ready()


func _update_mass() -> void:
	mass = EMPTY_MASS + litres * KG_PER_L


func label() -> String:
	if litres <= 0.05:
		return "fuel can (empty)"
	if litres >= CAPACITY - 0.05:
		return "fuel can (full)"
	return "fuel can (%d L)" % int(round(litres))


## Pour up to `amount` litres out; returns how much actually came out.
func pour(amount: float) -> float:
	var out := minf(amount, litres)
	litres -= out
	_update_mass()
	_refresh_prompt()
	return out


func _build() -> void:
	var red := ToonMat.make(Color(0.80, 0.16, 0.14), 0.012)
	var dark := ToonMat.make(Color(0.22, 0.22, 0.24), 0.01)
	add_child(Build.box(Vector3(0.36, 0.46, 0.17), red, Vector3(0, 0.23, 0), Vector3.ZERO, "Body"))
	# embossed X on the side, the classic jerrycan look
	for s in [-1.0, 1.0]:
		add_child(Build.box(Vector3(0.30, 0.03, 0.02), red, Vector3(0, 0.23, 0.09 * s), Vector3(0, 0, 38), "RibA"))
		add_child(Build.box(Vector3(0.30, 0.03, 0.02), red, Vector3(0, 0.23, 0.09 * s), Vector3(0, 0, -38), "RibB"))
	add_child(Build.box(Vector3(0.20, 0.05, 0.05), dark, Vector3(-0.02, 0.50, 0), Vector3.ZERO, "Handle"))
	add_child(Build.cyl(0.035, 0.09, dark, Vector3(0.13, 0.50, 0), Vector3(0, 0, -30), 8, "Spout"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.36, 0.52, 0.17)
	cs.shape = sh
	cs.position = Vector3(0, 0.25, 0)
	add_child(cs)
