class_name BridgeStone
extends Carryable

## #5, the lift bridge: a flat river stone, about 25 kg (one person carries
## it, slowly). The repair crew heaped some by the leaf's axle; more lie on
## the near bank. On the leaf each one pulls it down by its weight times its
## distance from the axle (`LiftBridge`). Flat and rough, so it stays put on
## the tilted deck. One that ends up in the river is gone.

const WEIGHT := 25.0
const SIZE := Vector3(0.52, 0.26, 0.40)

var home := Transform3D()        ## where the reset puts it back (local to the bridge)
var lost := false                ## in the river: sunk, out of the game until a reset
## lying on the lift bridge's leaf: it rides along with it (a rough 25 kg
## stone doesn't skate about on timber), until picked up or a slam throws it
var riding := false
var ride_xf := Transform3D()     ## local to the leaf


func _ready() -> void:
	item_name = "stone"
	kind = "stone"
	mass = WEIGHT
	add_to_group("bridge_stone")
	var grey := Color(0.52, 0.52, 0.50).lerp(Color(0.46, 0.43, 0.38), randf())
	var mat := ToonMat.make(grey, 0.02)
	# a rounded slab: a squashed ball over a slightly smaller box
	add_child(Build.sphere(0.5, mat, Vector3.ZERO, Vector3(SIZE.x, SIZE.y * 1.15, SIZE.z), "Stone"))
	add_child(Build.box(SIZE * Vector3(0.82, 0.7, 0.82), mat, Vector3(0, -0.02, 0), Vector3(0, 15, 0), "StoneCore"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = SIZE * Vector3(0.95, 0.9, 0.95)
	cs.shape = sh
	add_child(cs)
	var pm := PhysicsMaterial.new()
	pm.friction = 1.0
	pm.rough = true
	pm.bounce = 0.05
	physics_material_override = pm
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	super._ready()


## Lying still on the leaf: from now on it moves with it.
func ride(leaf: Node3D) -> void:
	riding = true
	ride_xf = leaf.global_transform.affine_inverse() * global_transform
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


## Carried, it doesn't catch on the other stones: P2's stone wedged on the
## one riding the leaf by the axle and was let go as P2 walked past (2 runs
## in 3, 2026-10-17). Your legs still bump them.
func grab(p) -> void:
	riding = false
	super.grab(p)
	for s in get_tree().get_nodes_in_group("bridge_stone"):
		if s != self:
			add_collision_exception_with(s)


func release(p) -> void:
	super.release(p)
	if holders.is_empty():
		for s in get_tree().get_nodes_in_group("bridge_stone"):
			if s != self:
				remove_collision_exception_with(s)


## Off the leaf's back again (picked up, thrown by a slam, the leaf locked).
func unride() -> void:
	if not riding:
		return
	riding = false
	freeze = false
	sleeping = false


func _physics_process(delta: float) -> void:
	if lost:
		return           # sunk: no safety net hauling it back up
	super._physics_process(delta)


## Back where the reset found it, in the world again.
func put_home() -> void:
	for p in holders.duplicate():
		p.drop_held()
	riding = false
	lost = false
	visible = true
	freeze = false
	collision_layer = LAYER
	transform = home
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	_last_safe = global_transform
	sleeping = true


## Into the river: it sinks out of sight and stays gone.
func sink() -> void:
	if lost:
		return
	lost = true
	riding = false
	for p in holders.duplicate():
		p.drop_held()
	Sfx.play3d("splat", global_position, 2.0, 0.1, 0.6)
	Sfx.play3d("gurgle", global_position, -2.0)
	freeze = true
	collision_layer = 0
	var tw := create_tween()
	tw.tween_property(self, "global_position", global_position + Vector3.DOWN * 1.5, 1.2)
	tw.tween_callback(func(): visible = false)
