class_name BarnMaze
extends Node3D

## W2, guide from a height (design/PUZZLES.md, optional, valley road). A
## walled hedge maze beside the barn; its walls are too high to see over.
## One climbs the ladder to the barn's loft door and guides the walker by
## tagging the next turn. Halfway through, hay dust blows over the middle of
## the maze and hides it from the loft for a while, so the walker has to say
## what they see (a red gate, a scarecrow, a blue drum) until the loft finds
## them again. At the far end, a feed chest: spare coolant and a crate.

const N := 6                     ## cells a side
const CELL := 3.0                ## m
const WALL_H := 2.6
const WALL_T := 0.3
const DUST_S := 25.0             ## s the dust hangs there

var walls_h: Array = []          ## [x][z] wall on the -Z side of cell (x, z); z == N is the far edge
var walls_v: Array = []          ## [x][z] wall on the -X side of cell (x, z); x == N is the far edge
var entrance := Vector2i(0, N - 1)   ## the cell by the gap in the +Z edge
var goal := Vector2i(N - 1, 0)
var chest_open := false
var dust_on := false
var _dust: Node3D
var _dust_t := 0.0
var _dust_done := false
var _chest_lid: Node3D
var _landmarks: Array[Node3D] = []


## `xf`: the maze's middle on the ground, in the barn's frame (+Z towards the
## road, where the way in is).
func setup(xf: Transform3D) -> void:
	add_to_group("barn_maze")
	transform = xf
	_generate(20260926)
	_build()


## A perfect maze by depth-first carving, the same every time (fixed seed).
func _generate(seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	walls_h = []
	walls_v = []
	for x in N + 1:
		walls_h.append([])
		walls_v.append([])
		for z in N + 1:
			walls_h[x].append(true)
			walls_v[x].append(true)
	var seen := {}
	var stack: Array[Vector2i] = [entrance]
	seen[entrance] = true
	while not stack.is_empty():
		var c: Vector2i = stack[stack.size() - 1]
		var options: Array[Vector2i] = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x >= 0 and n.x < N and n.y >= 0 and n.y < N and not seen.has(n):
				options.append(n)
		if options.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		_open(c, n)
		seen[n] = true
		stack.append(n)
	walls_h[entrance.x][N] = false      # the way in, on the road side


func _open(a: Vector2i, b: Vector2i) -> void:
	if a.x != b.x:
		walls_v[maxi(a.x, b.x)][a.y] = false
	else:
		walls_h[a.x][maxi(a.y, b.y)] = false


## The middle of a cell, local.
func cell_pos(c: Vector2i) -> Vector3:
	var half := N * CELL * 0.5
	return Vector3(-half + (c.x + 0.5) * CELL, 0, -half + (c.y + 0.5) * CELL)


## Is there a wall between two neighbouring cells?
func wall_between(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return walls_v[maxi(a.x, b.x)][a.y]
	return walls_h[a.x][maxi(a.y, b.y)]


## The way from one cell to another (breadth-first), cells in order.
func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var prev := {from: from}
	var q: Array[Vector2i] = [from]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == to:
			break
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if n.x >= 0 and n.x < N and n.y >= 0 and n.y < N and not prev.has(n) and not wall_between(c, n):
				prev[n] = c
				q.append(n)
	var out: Array[Vector2i] = []
	if not prev.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(c)
		c = prev[c]
	out.push_front(from)
	return out


func _build() -> void:
	var hedge := ToonMat.make(Color(0.30, 0.46, 0.24))
	var body := StaticBody3D.new()
	body.name = "MazeWalls"
	add_child(body)
	var half := N * CELL * 0.5
	for x in N + 1:
		for z in N + 1:
			if x < N and walls_h[x][z]:
				_wall(body, hedge, Vector3(-half + (x + 0.5) * CELL, 0, -half + z * CELL), Vector3(CELL + WALL_T, WALL_H, WALL_T))
			if z < N and walls_v[x][z]:
				_wall(body, hedge, Vector3(-half + x * CELL, 0, -half + (z + 0.5) * CELL), Vector3(WALL_T, WALL_H, CELL + WALL_T))
	# things to describe, in the middle cells: a red gate, a scarecrow, a blue drum
	var marks := [[Vector2i(2, 2), "gate"], [Vector2i(3, 3), "scarecrow"], [Vector2i(2, 4), "drum"], [Vector2i(4, 1), "cart"]]
	for m in marks:
		var at := cell_pos(m[0])
		var n := Node3D.new()
		n.name = "Mark_" + String(m[1])
		n.position = at + Vector3(0.7, 0, 0.7)
		add_child(n)
		match m[1]:
			"gate":
				n.add_child(Build.box(Vector3(1.2, 1.1, 0.08), ToonMat.make(Color(0.78, 0.20, 0.18)), Vector3(0, 0.55, 0), Vector3.ZERO, "Gate"))
			"scarecrow":
				n.add_child(Build.cyl(0.05, 2.2, ToonMat.make(Color(0.45, 0.33, 0.2)), Vector3(0, 1.1, 0), Vector3.ZERO, 5, "Pole"))
				n.add_child(Build.box(Vector3(1.3, 0.08, 0.08), ToonMat.make(Color(0.45, 0.33, 0.2)), Vector3(0, 1.7, 0), Vector3.ZERO, "Arms"))
				n.add_child(Build.sphere(0.2, ToonMat.make(Color(0.86, 0.74, 0.40)), Vector3(0, 2.25, 0), Vector3.ONE, "Head"))
			"drum":
				n.add_child(Build.solid_cyl(0.35, 0.9, ToonMat.make(Color(0.20, 0.36, 0.72)), Vector3(0, 0.45, 0), Vector3.ZERO, "Drum"))
			"cart":
				n.add_child(Build.solid_box(Vector3(1.0, 0.5, 0.7), ToonMat.make(Color(0.55, 0.42, 0.26)), Vector3(0, 0.45, 0), Vector3.ZERO, "Cart"))
		n.set_meta("tag_name", "the " + String(m[1]))
		_landmarks.append(n)
	# a sign at the way in
	var in_at := cell_pos(entrance) + Vector3(-1.8, 0, CELL * 0.5 + 1.2)
	var sign_n := Node3D.new()
	sign_n.position = in_at
	sign_n.add_child(Build.cyl(0.06, 1.6, ToonMat.make(Color(0.45, 0.33, 0.2)), Vector3(0, 0.8, 0), Vector3.ZERO, 5, "Post"))
	sign_n.add_child(Build.box(Vector3(1.4, 0.6, 0.05), ToonMat.make(Color(0.9, 0.86, 0.72)), Vector3(0, 1.55, 0), Vector3.ZERO, "Board"))
	sign_n.add_child(Build.label3d("HAY MAZE\nfeed chest at the far end\nthe loft sees it all", Vector3(0, 1.55, 0.03), Vector3.ZERO, 0.08, Color(0.2, 0.18, 0.15)))
	add_child(sign_n)
	# the feed chest in the goal cell
	var chest := Node3D.new()
	chest.name = "FeedChest"
	chest.position = cell_pos(goal)
	add_child(chest)
	var wood := ToonMat.make(Color(0.48, 0.34, 0.22), 0.012)
	chest.add_child(Build.solid_box(Vector3(1.1, 0.6, 0.7), wood, Vector3(0, 0.3, 0), Vector3.ZERO, "Chest"))
	_chest_lid = Node3D.new()
	_chest_lid.position = Vector3(0, 0.63, -0.35)
	chest.add_child(_chest_lid)
	_chest_lid.add_child(Build.box(Vector3(1.12, 0.08, 0.72), wood, Vector3(0, 0.04, 0.36), Vector3.ZERO, "Lid"))
	var a := Build.interact_area(Vector3(1.3, 1.0, 1.0), Vector3(0, 0.5, 0), "Open the feed chest", func(p): open_chest(p), "ChestArea")
	a.set_meta("tag_name", "the feed chest")
	a.set_meta("prompt_fn", func(_p) -> String: return "" if chest_open else "Open the feed chest")
	chest.add_child(a)
	# the dust cloud over the middle, hidden until it blows in
	_dust = Node3D.new()
	_dust.name = "HayDust"
	_dust.visible = false
	add_child(_dust)
	var dust_mat := StandardMaterial3D.new()
	dust_mat.albedo_color = Color(0.82, 0.74, 0.52, 0.72)
	dust_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dust_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dust_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in 14:
		var p := Vector3(rng.randf_range(-4.5, 4.5), rng.randf_range(2.2, 4.2), rng.randf_range(-4.5, 4.5))
		var puff := Build.sphere(rng.randf_range(2.0, 3.0), dust_mat, p, Vector3(1, 0.6, 1), "Puff")
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_dust.add_child(puff)


func _wall(body: StaticBody3D, mat: Material, at: Vector3, size: Vector3) -> void:
	add_child(Build.box(size, mat, at + Vector3.UP * size.y * 0.5, Vector3.ZERO, "Hedge"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = at + Vector3.UP * size.y * 0.5
	body.add_child(cs)


## Which cell a point (global) is in, or (-1, -1) outside the maze.
func cell_at(p: Vector3) -> Vector2i:
	var l := global_transform.affine_inverse() * p
	var half := N * CELL * 0.5
	var c := Vector2i(floori((l.x + half) / CELL), floori((l.z + half) / CELL))
	if c.x < 0 or c.x >= N or c.y < 0 or c.y >= N:
		return Vector2i(-1, -1)
	return c


func _physics_process(delta: float) -> void:
	if dust_on:
		_dust_t += delta
		_dust.rotation.y += delta * 0.05
		if _dust_t > DUST_S:
			dust_on = false
			_dust.visible = false
		return
	if _dust_done:
		return
	# the dust blows in once someone walks into the middle of the maze
	for n in get_tree().get_nodes_in_group("player"):
		var c := cell_at((n as Node3D).global_position)
		if c.x >= 2 and c.x <= 3 and c.y >= 2 and c.y <= 3:
			blow_dust()
			return


func blow_dust() -> void:
	_dust_done = true
	dust_on = true
	_dust_t = 0.0
	_dust.visible = true
	Sfx.play3d("hit_soft", global_position + Vector3.UP * 3.0, -4.0)
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 40.0:
			q.say("A gust off the fields: hay dust blows up over the middle of the maze. From the loft you can't see into it - the one inside has to say what's around them.", 7.0)


func open_chest(p: PlayerRig) -> void:
	if chest_open:
		return
	chest_open = true
	var tw := create_tween()
	tw.tween_property(_chest_lid, "rotation:x", deg_to_rad(-100.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play3d("latch", _chest_lid.global_position, 0.0)
	var root := get_tree().get_first_node_in_group("world_root")
	var jug := CoolantJug.new()
	jug.name = "MazeCoolant"
	root.add_child(jug)
	jug.global_position = global_transform * (cell_pos(goal) + Vector3(-0.2, 0.9, 0.8))
	var crate := Crate.new()
	crate.name = "MazeCrate"
	root.add_child(crate)
	crate.global_position = global_transform * (cell_pos(goal) + Vector3(0.9, 0.5, 0.9))
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["maze_done"] = true
	p.say("Inside the feed chest: a jug of coolant mix and a sturdy crate. Worth taking.", 6.0)


func to_dict() -> Dictionary:
	return {"chest_open": chest_open, "dust_done": _dust_done}


func from_dict(d: Dictionary) -> void:
	chest_open = bool(d.get("chest_open", false))
	_dust_done = bool(d.get("dust_done", false))
	dust_on = false
	_dust.visible = false
	_chest_lid.rotation.x = deg_to_rad(-100.0) if chest_open else 0.0
