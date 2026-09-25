class_name SpareWheel
extends Carryable

## Physical spare taken from the camper's rear mount during the opening.
func _init() -> void:
	item_name = "spare wheel"
	kind = "spare_wheel"
	mass = 18.0


func _ready() -> void:
	super._ready()
	var tyre := ToonMat.make(Color(0.13, 0.13, 0.15), 0.02, 0.98)
	add_child(Build.cyl(0.44, 0.26, tyre, Vector3.ZERO, Vector3(90, 0, 0), 16, "Tyre"))
	var hub := ToonMat.make(Color(0.82, 0.80, 0.74), 0.015, 0.5)
	add_child(Build.cyl(0.20, 0.28, hub, Vector3.ZERO, Vector3(90, 0, 0), 12, "Hub"))
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.44
	shape.height = 0.26
	cs.shape = shape
	cs.rotation_degrees.x = 90.0
	add_child(cs)
