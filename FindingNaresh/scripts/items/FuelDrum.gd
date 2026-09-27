class_name FuelDrum
extends FuelCan

## A 40 L fuel drum (E6, under the upturned boat): heavy, a two-person carry
## back to the van, and it pours into the tank like a can.

const DRUM_L := 40.0


static func create_drum(fill := DRUM_L) -> FuelDrum:
	var d := FuelDrum.new()
	d.litres = fill
	return d


func _ready() -> void:
	super._ready()
	item_name = "fuel drum"
	two_handed = true
	_refresh_prompt()


func label() -> String:
	if litres <= 0.05:
		return "fuel drum (empty)"
	if litres >= DRUM_L - 0.05:
		return "fuel drum (full)"
	return "fuel drum (%d L)" % int(round(litres))


func _build() -> void:
	for c in get_children():
		c.queue_free()
	var blue := ToonMat.make(Color(0.20, 0.36, 0.62), 0.012)
	var dark := ToonMat.make(Color(0.18, 0.18, 0.2), 0.01)
	add_child(Build.cyl(0.3, 0.85, blue, Vector3(0, 0.425, 0), Vector3.ZERO, 14, "Drum"))
	for y in [0.2, 0.65]:
		add_child(Build.cyl(0.31, 0.04, dark, Vector3(0, y, 0), Vector3.ZERO, 14, "Hoop"))
	add_child(Build.cyl(0.05, 0.04, dark, Vector3(0.15, 0.87, 0), Vector3.ZERO, 8, "Bung"))
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.3
	sh.height = 0.85
	cs.shape = sh
	cs.position = Vector3(0, 0.425, 0)
	add_child(cs)
