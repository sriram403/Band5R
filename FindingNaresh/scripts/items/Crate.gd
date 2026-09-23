class_name Crate
extends Carryable

## A wooden crate: light enough to carry, sturdy enough to stand on. Stack
## two and you can jump up onto a shed roof.

const SIZE := Vector3(0.62, 0.45, 0.62)


func _ready() -> void:
	item_name = "crate"
	kind = "crate"
	mass = 8.0
	var wood := ToonMat.make(Color(0.62, 0.46, 0.28), 0.012)
	var dark := ToonMat.make(Color(0.42, 0.30, 0.18), 0.01)
	add_child(Build.box(SIZE, wood, Vector3(0, SIZE.y * 0.5, 0), Vector3.ZERO, "Box"))
	for s in [-1.0, 1.0]:
		add_child(Build.box(Vector3(SIZE.x + 0.02, 0.06, 0.06), dark, Vector3(0, SIZE.y * 0.5, s * (SIZE.z * 0.5 + 0.005)), Vector3(0, 0, 32), "Slat"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = SIZE
	cs.shape = sh
	cs.position = Vector3(0, SIZE.y * 0.5, 0)
	add_child(cs)
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	physics_material_override = pm
	super._ready()
