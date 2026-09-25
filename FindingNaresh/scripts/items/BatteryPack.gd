class_name BatteryPack
extends Carryable

## A spare set for the hand torch. F while carrying it fits the cells.

func _ready() -> void:
	item_name = "torch batteries"
	kind = "batteries"
	mass = 0.3
	var yellow := ToonMat.make(Color(0.93, 0.77, 0.20))
	var black := ToonMat.make(Color(0.14, 0.16, 0.18))
	for x in [-0.09, 0.09]:
		add_child(Build.cyl(0.075, 0.32, yellow, Vector3(x, 0.18, 0), Vector3.ZERO, 8, "Cell"))
		add_child(Build.cyl(0.05, 0.03, black, Vector3(x, 0.355, 0), Vector3.ZERO, 8, "Cap"))
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.33, 0.4, 0.2)
	cs.shape = box
	cs.position = Vector3(0, 0.18, 0)
	add_child(cs)
	super._ready()
