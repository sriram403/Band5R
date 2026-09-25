class_name CardboardBox
extends Carryable

## A big cardboard box (design/CREATURES.md, "Hiding on foot"). Carry it like
## anything else; E while holding it puts it over you. Inside you shuffle at
## crouch speed and, standing still, you are just a box: a creature only
## notices you within 3 m (6 m if you move). But a box that moves while one is
## watching gets looked at ("that box moved").

const SIZE := Vector3(0.95, 1.12, 0.95)

var wearer: PlayerRig = null


func _ready() -> void:
	item_name = "cardboard box"
	kind = "box"
	mass = 2.5
	var card := ToonMat.make(Color(0.72, 0.56, 0.36), 0.01)
	var tape := ToonMat.make(Color(0.86, 0.78, 0.6), 0.008)
	add_child(Build.box(SIZE, card, Vector3(0, SIZE.y * 0.5, 0), Vector3.ZERO, "Card"))
	add_child(Build.box(Vector3(0.12, 0.01, SIZE.z + 0.01), tape, Vector3(0, SIZE.y + 0.003, 0), Vector3.ZERO, "Tape"))
	for s in [-1.0, 1.0]:
		add_child(Build.box(Vector3(0.12, 0.25, 0.01), tape, Vector3(0, SIZE.y - 0.12, s * (SIZE.z * 0.5 + 0.004)), Vector3.ZERO, "TapeEnd"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = SIZE
	cs.shape = sh
	cs.position = Vector3(0, SIZE.y * 0.5, 0)
	add_child(cs)
	super._ready()


## Over `p`: rides on them with no collision, drawn on their private layer so
## their own camera looks out from inside it and their partner sees a box.
func wear(p: PlayerRig, slot: Node3D) -> void:
	stow(slot)
	wearer = p
	_set_layers(1 << (1 + p.index))


## Lifted off again: back in the world, drawn for everyone.
func take_off() -> void:
	wearer = null
	unstow()
	_set_layers(1)


func _set_layers(layer: int) -> void:
	for m in get_children():
		if m is VisualInstance3D:
			(m as VisualInstance3D).layers = layer
