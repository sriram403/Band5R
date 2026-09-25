class_name SpareWheel
extends Carryable

## Physical spare taken from the camper's rear mount during the opening, or
## (flat = true) the punctured wheel that comes off the hub.
var flat := false


func _init() -> void:
	item_name = "spare wheel"
	kind = "spare_wheel"
	mass = 18.0


static func make_flat() -> SpareWheel:
	var w := SpareWheel.new()
	w.flat = true
	w.item_name = "flat tyre"
	w.kind = "flat_wheel"
	w.mass = 16.0
	return w


func _ready() -> void:
	super._ready()
	var tyre := ToonMat.make(Color(0.13, 0.13, 0.15), 0.02, 0.98)
	var t := Build.cyl(0.44, 0.26, tyre, Vector3.ZERO, Vector3(90, 0, 0), 16, "Tyre")
	if flat:
		t.scale = Vector3(1.0, 1.15, 0.8)   # sagging, bulged at the bottom
		t.position.y = -0.06
	add_child(t)
	var hub := ToonMat.make(Color(0.82, 0.80, 0.74), 0.015, 0.5)
	add_child(Build.cyl(0.20, 0.28, hub, Vector3.ZERO, Vector3(90, 0, 0), 12, "Hub"))
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.44
	shape.height = 0.26
	cs.shape = shape
	cs.rotation_degrees.x = 90.0
	add_child(cs)
