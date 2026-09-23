class_name Carryable
extends RigidBody3D

## Anything a player can pick up, carry, drop, throw or stow.
##
## A held item stays a real physics body. Every tick it is steered toward a
## hold point in front of its holder, so it still collides with the world and
## cannot be pushed through walls. Weight is felt through how quickly it
## follows (heavy things lag and sag), how far it throws and how much it slows
## the holder down. Two players can hold the same item; big items need both.

const LAYER := 16                ## physics layer for carryables
const SNAG_DISTANCE := 2.4       ## m; further than this from the hold point and the item is let go

@export var item_name := "item"
@export var kind := "misc"       ## "fuel_can", "coolant", "board", ... used by things that accept items
@export var two_handed := false  ## needs both players to carry at a useful speed

var holders: Array = []          ## PlayerRig list
var stowed_in: Node3D = null     ## storage slot while stowed


func _ready() -> void:
	add_to_group("carryable")
	collision_layer = LAYER
	collision_mask = 1 | 2 | 8 | LAYER
	continuous_cd = true
	can_sleep = true
	linear_damp = 0.1
	angular_damp = 0.8
	_refresh_prompt()


## 0 for featherweights, 1 for the heaviest thing one person can manage.
func heaviness() -> float:
	return clampf((mass - 2.0) / 28.0, 0.0, 1.0)


## How much a holder is slowed: 1.0 = not at all.
func speed_factor() -> float:
	var share := mass / maxf(1.0, holders.size())
	var f := 1.0 - clampf(share / 45.0, 0.0, 0.5)
	if two_handed and holders.size() < 2:
		f *= 0.45
	return f


## Label for prompts, e.g. "fuel can (full)".
func label() -> String:
	return item_name


func _refresh_prompt() -> void:
	set_meta("prompt", "Pick up " + label())
	set_meta("prompt_fn", func(p) -> String:
		if holders.is_empty():
			return "Pick up " + label()
		if two_handed and holders.size() == 1 and not p in holders:
			return "Help carry " + label()
		return "")
	set_meta("blocked_fn", func() -> String:
		if not holders.is_empty() and not two_handed:
			return "P%d is carrying it" % (holders[0].index + 1)
		return "")
	set_meta("callback", func(p): p.pick_up(self))


# --- holding -------------------------------------------------------------------

func grab(p) -> void:
	if p in holders:
		return
	if stowed_in != null:
		unstow()
	holders.append(p)
	add_collision_exception_with(p)
	sleeping = false


func release(p) -> void:
	if not p in holders:
		return
	holders.erase(p)
	remove_collision_exception_with(p)


func throw_from(p, dir: Vector3) -> void:
	release(p)
	if holders.is_empty():
		var speed := lerpf(9.0, 3.0, heaviness())
		# never slam it straight into the ground: throws always carry forward
		var d := dir.normalized()
		d.y = maxf(d.y, -0.15)
		linear_velocity = d.normalized() * speed + Vector3.UP * 1.8
		angular_velocity = Vector3(randf_range(-2, 2), randf_range(-2, 2), randf_range(-2, 2)) * (1.0 - heaviness())


func _physics_process(delta: float) -> void:
	if holders.is_empty() or stowed_in != null:
		return
	var target := Vector3.ZERO
	var yaw := 0.0
	for p in holders:
		target += p.hold_point(self)
		yaw += p.yaw
	target /= holders.size()
	yaw /= holders.size()

	var to := target - global_position
	if to.length() > SNAG_DISTANCE:
		# snagged on something, or the holder walked off: let go
		for p in holders.duplicate():
			p.drop_held()
		return
	var h := heaviness()
	var carriers := float(holders.size())
	if two_handed and carriers < 2.0:
		h = maxf(h, 0.9)
	var max_v := lerpf(10.0, 3.2, h) * (1.0 if carriers < 2.0 else 1.25)
	var response := lerpf(18.0, 5.0, h)
	var desired := to * 14.0
	if desired.length() > max_v:
		desired = desired.normalized() * max_v
	linear_velocity = linear_velocity.lerp(desired, clampf(response * delta, 0.0, 1.0))

	# turn to face the same way as the holder, upright
	var want := Basis(Vector3.UP, yaw)
	var err := (want * global_transform.basis.orthonormalized().inverse()).get_rotation_quaternion()
	var ang := err.get_angle()
	if ang > PI:
		ang -= TAU
	if absf(ang) > 0.001:
		angular_velocity = angular_velocity.lerp(err.get_axis() * ang * lerpf(10.0, 4.0, h), clampf(10.0 * delta, 0.0, 1.0))


# --- storage -------------------------------------------------------------------

## Park the item in a storage slot: it rides along as a passenger with no
## collision, so a moving van cannot shake it loose or fight its physics.
func stow(slot: Node3D) -> void:
	for p in holders.duplicate():
		p.drop_held()
	stowed_in = slot
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	collision_layer = 0
	collision_mask = 0
	reparent(slot, false)
	transform = Transform3D.IDENTITY
	reset_physics_interpolation()


func unstow() -> void:
	if stowed_in == null:
		return
	var world := stowed_in.get_tree().get_first_node_in_group("world_root")
	var xf := global_transform
	stowed_in = null
	reparent(world if world else get_tree().current_scene, false)
	global_transform = xf.translated(Vector3.UP * 0.2)
	collision_layer = LAYER
	collision_mask = 1 | 2 | 8 | LAYER
	freeze = false
	reset_physics_interpolation()
