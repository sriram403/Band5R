class_name Ladder
extends Area3D

## A ladder you climb (the windmill tower). E at it to get on, W / S (stick up
## and down) to climb, E or jump to let go. At the top you step off onto what
## it leads to; at the bottom you step back onto the ground. Your hands are on
## the rungs, so nothing can be carried up (the prompt says so).

const SPEED := 2.2               ## m/s up or down
const STANDOFF := 0.42           ## m from the rungs to the middle of the climber
const RUNG := 0.3

var height := 10.0               ## m from the foot to the top rung
var exit_top := Vector3.ZERO     ## local: where you stand after stepping off at the top
var exit_bottom := Vector3.ZERO  ## local: where you stand after stepping off at the bottom


## A ladder at `foot` (local to `parent`), `h` tall, climbed facing `facing`
## (local, flat: the direction from the climber to the rungs).
static func make(parent: Node3D, foot: Vector3, h: float, facing: Vector3, top_exit: Vector3, nm := "Ladder") -> Ladder:
	var l := Ladder.new()
	l.name = nm
	l.height = h
	var f := Vector3(facing.x, 0, facing.z).normalized()
	l.basis = Basis.looking_at(f, Vector3.UP)
	l.position = foot
	l.exit_top = l.transform.affine_inverse() * top_exit
	l.exit_bottom = Vector3(0, 0, STANDOFF + 0.6)
	var steel := ToonMat.make(Color(0.34, 0.36, 0.38), 0.01)
	for s in [-0.25, 0.25]:
		l.add_child(Build.box(Vector3(0.05, h + 1.0, 0.05), steel, Vector3(s, (h + 1.0) * 0.5, 0), Vector3.ZERO, "Rail"))
	var k := 0.3
	while k < h + 0.05:
		l.add_child(Build.box(Vector3(0.5, 0.035, 0.035), steel, Vector3(0, k, 0), Vector3.ZERO, "Rung"))
		k += RUNG
	l.collision_layer = 4
	l.collision_mask = 0
	l.monitoring = false
	l.monitorable = true
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.8, h + 1.4, 0.6)
	cs.shape = sh
	cs.position = Vector3(0, (h + 1.4) * 0.5, 0.2)
	l.add_child(cs)
	l.set_meta("tag_name", "the ladder")
	l.set_meta("prompt", "Climb the ladder")      # PlayerRig finds interactables by this meta
	l.set_meta("prompt_fn", func(p) -> String:
		return "Climb down" if p.global_position.y > l.global_position.y + h * 0.5 else "Climb the ladder")
	l.set_meta("blocked_fn", func(p) -> String:
		return "Hands full - put it down to climb" if p.held != null else "")
	l.set_meta("callback", func(p): p.start_climb(l))
	parent.add_child(l)
	return l


## Where a climber at height `h` up the ladder stands (global).
func point_at(h: float) -> Vector3:
	return global_transform * Vector3(0, clampf(h, 0.0, height), STANDOFF)


## The way a climber faces (yaw), towards the rungs.
func climb_yaw() -> float:
	var f := -global_transform.basis.z
	return atan2(-f.x, -f.z)
