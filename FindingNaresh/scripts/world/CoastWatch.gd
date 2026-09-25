class_name CoastWatch
extends Node3D

## D11, the coast watchtower (design/WAY_OUT.md 21:00): the first sight of the
## sea and Bessi. A creature paces round the tower's base; you learn to hide
## on foot (cover, crouch, peek, the cardboard boxes stacked by the road) to
## get up the ramp. From the deck, stamp the beach on the paper map; the nav
## follows the stamp (as built).
##
## The creature only comes out once you are on foot near the tower, or the
## van is parked with its engine off: the lesson here is hiding on foot, not
## the van again (that was the ghat).

const WAKE := 130.0              ## m: someone on foot this close wakes it
const PATROL_R := 13.0           ## m round the tower's middle

var tower_xf := Transform3D.IDENTITY
var creature: Creature = null
var patrol := PackedVector3Array()
var covers: Array[Node3D] = []
var boxes: Array[CardboardBox] = []
var _check_t := 0.0


## `xf`: the tower's frame (-Z towards Bessi, the ramp on +Z). `arrive`: the
## road point you come to it from.
func setup(xf: Transform3D, ramp_foot: Vector3, arrive: Vector3, ground: Callable) -> void:
	add_to_group("coast_watch")
	tower_xf = xf
	# the patrol: an oval round the legs and the ramp's foot
	var mid := xf * Vector3(0, 0, 8.0)
	for k in 10:
		var a := TAU * k / 10.0
		var p := mid + xf.basis.x * cos(a) * PATROL_R + xf.basis.z * sin(a) * (PATROL_R + 5.0)
		p.y = ground.call(p.x, p.z)
		patrol.append(p)
	# cover on the way in from the road: rocks, a broken wall, crates
	var way := ramp_foot - arrive
	way.y = 0.0
	var dist := way.length()
	way = way.normalized()
	var side := way.cross(Vector3.UP)
	var rock := ToonMat.make(Color(0.52, 0.50, 0.46))
	var specs := [
		# rocks as in the stealth gym (top 1.2 m: hides you crouched, you can
		# peek over it); the wall hides you standing, you lean past its end
		[0.25, 4.0, "rock", Vector3(1.8, 1.35, 1.6)],
		[0.42, -3.5, "wall", Vector3(4.0, 1.6, 0.5)],
		[0.58, 3.0, "rock", Vector3(2.0, 1.35, 1.7)],
		[0.72, -2.5, "crates", Vector3(1.4, 1.2, 1.0)],
	]
	for s in specs:
		var at := arrive + way * dist * float(s[0]) + side * float(s[1])
		at.y = ground.call(at.x, at.z)
		var sz: Vector3 = s[3]
		var n: Node3D
		if s[2] == "rock":
			n = Build.solid_box(sz, rock, at + Vector3.UP * (sz.y * 0.5 - 0.15), Vector3(0, randf_range(0, 90), randf_range(-6, 6)), "CoverRock")
		elif s[2] == "wall":
			n = Build.solid_box(sz, ToonMat.make(Color(0.66, 0.60, 0.52)), at + Vector3.UP * (sz.y * 0.5 - 0.1), Vector3.ZERO, "CoverWall")
			n.basis = Basis.looking_at(way, Vector3.UP)
		else:
			n = Build.solid_box(sz, ToonMat.make(Color(0.50, 0.38, 0.24)), at + Vector3.UP * (sz.y * 0.5), Vector3.ZERO, "CoverCrates")
		add_child(n)
		covers.append(n)
	# a stack of flattened-then-folded boxes by the road, and a sign
	var stack := arrive + side * 5.0 + way * 3.0
	stack.y = ground.call(stack.x, stack.z)
	for k in 3:
		var bx := CardboardBox.new()
		bx.name = "TowerBox%d" % k
		add_child(bx)
		bx.position = stack + side * (k * 1.1) + Vector3.UP * 0.6
		boxes.append(bx)
	var sign_n := Node3D.new()
	sign_n.position = stack - side * 1.4
	sign_n.basis = Basis.looking_at(-way, Vector3.UP)
	sign_n.add_child(Build.cyl(0.06, 1.4, ToonMat.make(Color(0.40, 0.30, 0.20)), Vector3(0, 0.7, 0), Vector3.ZERO, 6, "Post"))
	sign_n.add_child(Build.box(Vector3(0.9, 0.45, 0.04), ToonMat.make(Color(0.9, 0.86, 0.72)), Vector3(0, 1.35, 0), Vector3.ZERO, "Card"))
	sign_n.add_child(Build.label3d("FREE BOXES\ntake one", Vector3(0, 1.35, -0.03), Vector3(0, 180, 0), 0.1, Color(0.2, 0.18, 0.15)))
	add_child(sign_n)


func _physics_process(delta: float) -> void:
	_check_t -= delta
	if _check_t > 0.0:
		return
	_check_t = 0.5
	if creature != null:
		return
	var here := tower_xf.origin
	var wake := false
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat == null and Vector2(p.global_position.x - here.x, p.global_position.z - here.z).length() < WAKE:
			wake = true
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van != null and not van.engine_on and Vector2(van.global_position.x - here.x, van.global_position.z - here.z).length() < WAKE:
		wake = true
	if wake:
		spawn()


func spawn() -> void:
	if creature != null:
		return
	creature = Creature.new()
	creature.name = "TowerCreature"
	get_tree().get_first_node_in_group("world_root").add_child(creature)
	creature.global_position = patrol[0]
	creature.patrol = patrol
	var st = get_tree().current_scene.get("story")
	if st != null and not st.flags.has("tower_seen"):
		st.flags["tower_seen"] = true
		for n in get_tree().get_nodes_in_group("player"):
			var p := n as PlayerRig
			if p.global_position.distance_to(tower_xf.origin) < WAKE + 40.0:
				p.say("Something tall is pacing round the foot of the watchtower, slow, round and round.\n\nIt hasn't seen you. Keep low (Ctrl / B), keep things between you and it, and peek out (hold RMB / LT) to watch it. The boxes by the road might help.", 11.0)


## Someone standing on the deck.
func on_deck(deck: Vector3) -> bool:
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.global_position.distance_to(deck) < 3.5 and p.is_on_floor():
			return true
	return false
