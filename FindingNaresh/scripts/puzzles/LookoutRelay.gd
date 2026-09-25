class_name LookoutRelay
extends Node3D

## W4, the binocular relay (design/PUZZLES.md, optional, ridge track). A
## padlocked supply box at the foot of the Pine Ridge lookout has four dials
## of pictures, not numbers. The code is painted on two boards far out across
## the valley, 1 and 2, readable only through binoculars from the deck. The
## one up top reads the pictures in order; the one at the box turns the dials
## (E) until they match. Inside: a full can of fuel.

const SHAPES := ["circle", "square", "triangle", "cross", "ring", "diamond"]
## All one colour: by eye the pictures are pale blobs; only the binoculars
## show their shapes.
const COLOURS := {
	"circle": Color(0.96, 0.95, 0.90), "square": Color(0.96, 0.95, 0.90), "triangle": Color(0.96, 0.95, 0.90),
	"cross": Color(0.96, 0.95, 0.90), "ring": Color(0.96, 0.95, 0.90), "diamond": Color(0.96, 0.95, 0.90),
}
const SHAPE_SIZE := 1.6          ## m across, on the boards (~150 m: blobs by eye, shapes zoomed)

var code: Array[int] = []        ## four indices into SHAPES
var dials: Array[int] = [0, 0, 0, 0]
var opened := false
var boards: Array[Node3D] = []
var _dial_faces: Array[Node3D] = []
var _lid: Node3D
var _box_at := Vector3.ZERO


## `deck`: the lookout's deck (global), `board_xz`: where the boards stand
## (LevelLayout.relay_boards, which also keeps their sightlines clear of trees); `box_at`: the box's place (global, on the ground); `ground` the
## height function.
func setup(deck: Vector3, board_xz: Array[Vector2], box_at: Vector3, ground: Callable) -> void:
	add_to_group("lookout_relay")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4417
	var pool := range(SHAPES.size())
	for k in 4:
		var i := rng.randi_range(0, pool.size() - 1)
		code.append(pool[i])
		pool.remove_at(i)
	dials = [(code[0] + 3) % 6, (code[1] + 2) % 6, (code[2] + 4) % 6, (code[3] + 1) % 6]
	for b in 2:
		var at := Vector3(board_xz[b].x, 0, board_xz[b].y)
		at.y = ground.call(at.x, at.z)
		boards.append(_board(at, deck, b))
	_box_at = box_at
	_build_box(box_at, deck)


## A board on two posts, 5 m up, facing the deck: its number and two pictures.
func _board(at: Vector3, deck: Vector3, b: int) -> Node3D:
	var n := Node3D.new()
	n.name = "RelayBoard%d" % (b + 1)
	add_child(n)
	var look := deck - at
	look.y = 0.0
	n.transform = Transform3D(Basis.looking_at(-look, Vector3.UP), at)   # +Z towards the deck
	var wood := ToonMat.make(Color(0.40, 0.30, 0.20))
	for sx in [-2.4, 2.4]:
		n.add_child(Build.cyl(0.15, 6.0, wood, Vector3(sx, 3.0, 0), Vector3.ZERO, 6, "Post"))
	n.add_child(Build.box(Vector3(6.0, 2.4, 0.15), ToonMat.make(Color(0.14, 0.14, 0.16)), Vector3(0, 5.6, 0), Vector3.ZERO, "Board"))
	n.add_child(Build.label3d(str(b + 1), Vector3(-2.3, 5.6, 0.1), Vector3.ZERO, 1.6, Color(0.95, 0.92, 0.8)))
	for k in 2:
		var s := shape_node(SHAPES[code[b * 2 + k]], SHAPE_SIZE)
		s.position = Vector3(-0.3 + k * 2.1, 5.6, 0.1)
		n.add_child(s)
	return n


## A flat picture facing +Z, `size` m across.
static func shape_node(kind: String, size: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Shape_" + kind
	var mat := ToonMat.make(COLOURS[kind], 0.0, 0.8, COLOURS[kind] * 0.25)
	var r := size * 0.5
	match kind:
		"circle":
			n.add_child(Build.cyl(r, 0.04, mat, Vector3.ZERO, Vector3(90, 0, 0), 20, "Disc"))
		"square":
			n.add_child(Build.box(Vector3(size * 0.85, size * 0.85, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Square"))
		"triangle":
			n.add_child(Build.cyl(r * 1.1, 0.04, mat, Vector3(0, -r * 0.1, 0), Vector3(90, 0, 0), 3, "Tri"))
		"cross":
			n.add_child(Build.box(Vector3(size, size * 0.28, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Bar"))
			n.add_child(Build.box(Vector3(size * 0.28, size, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Bar"))
		"ring":
			n.add_child(Build.cyl(r, 0.04, mat, Vector3.ZERO, Vector3(90, 0, 0), 20, "Outer"))
			n.add_child(Build.cyl(r * 0.55, 0.04, ToonMat.make(Color(0.14, 0.14, 0.16), 0.0), Vector3(0, 0, 0.01), Vector3(90, 0, 0), 20, "Hole"))
		"diamond":
			n.add_child(Build.box(Vector3(size * 0.68, size * 0.68, 0.04), mat, Vector3.ZERO, Vector3(0, 0, 45), "Diamond"))
	return n


func _build_box(at: Vector3, deck: Vector3) -> void:
	var box := Node3D.new()
	box.name = "SupplyBox"
	add_child(box)
	var look := deck - at
	look.y = 0.0
	box.transform = Transform3D(Basis.looking_at(look, Vector3.UP), at)   # -Z (the dials) faces the tower
	var steel := ToonMat.make(Color(0.30, 0.40, 0.32), 0.012)
	box.add_child(Build.solid_box(Vector3(1.3, 0.7, 0.8), steel, Vector3(0, 0.35, 0), Vector3.ZERO, "Box"))
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.72, 0.4)
	box.add_child(_lid)
	_lid.add_child(Build.box(Vector3(1.32, 0.08, 0.82), steel, Vector3(0, 0.04, -0.41), Vector3.ZERO, "Lid"))
	box.add_child(Build.label3d("SUPPLY BOX - RIDGE PATROL\nthe code is out there", Vector3(0, 0.82, -0.43), Vector3(0, 180, 0), 0.07, Color(0.95, 0.92, 0.8)))
	for k in 4:
		var d := Node3D.new()
		d.name = "Dial%d" % k
		# seen from the front (-Z) the box's +X is on your left: dial 1 on the left
		d.position = Vector3(0.45 - k * 0.3, 0.4, -0.42)
		d.rotation.y = PI         # pictures face out of the box's front (-Z)
		box.add_child(d)
		d.add_child(Build.box(Vector3(0.24, 0.24, 0.02), ToonMat.make(Color(0.14, 0.14, 0.16), 0.0), Vector3(0, 0, -0.01), Vector3.ZERO, "Plate"))
		_dial_faces.append(d)
		d.add_child(Build.label3d(str(k + 1), Vector3(0, -0.2, 0.01), Vector3.ZERO, 0.07, Color(0.95, 0.92, 0.8)))
		var a := Build.interact_area(Vector3(0.26, 0.3, 0.3), Vector3.ZERO, "", func(_p): turn(k), "DialArea%d" % k)
		a.set_meta("tag_name", "dial %d" % (k + 1))
		a.set_meta("prompt_fn", func(_p) -> String: return "" if opened else "Turn dial %d (%s)" % [k + 1, SHAPES[dials[k]]])
		d.add_child(a)
		_show_dial(k)


func turn(k: int) -> void:
	if opened:
		return
	dials[k] = (dials[k] + 1) % SHAPES.size()
	_show_dial(k)
	Sfx.play3d("click", _dial_faces[k].global_position, -6.0)
	if dials == code:
		_open()


func _show_dial(k: int) -> void:
	var d := _dial_faces[k]
	var old := d.get_node_or_null("Face")
	if old != null:
		old.queue_free()
		old.name = "Old"
	var s := shape_node(SHAPES[dials[k]], 0.18)
	s.name = "Face"
	s.position = Vector3(0, 0, 0.005)
	d.add_child(s)


func _open() -> void:
	opened = true
	var tw := create_tween()
	tw.tween_property(_lid, "rotation:x", deg_to_rad(100.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play3d("latch", _lid.global_position, 0.0)
	var can := FuelCan.create(FuelCan.CAPACITY)
	can.name = "RelayFuel"
	get_tree().get_first_node_in_group("world_root").add_child(can)
	can.global_position = _box_at + Vector3.UP * 0.9
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["relay_done"] = true
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(_box_at) < 40.0:
			q.say("Click-click-click-CLACK: the supply box opens. Inside, a full can of fuel.", 6.0)


func to_dict() -> Dictionary:
	return {"dials": dials.duplicate(), "opened": opened}


func from_dict(d: Dictionary) -> void:
	var dd: Array = d.get("dials", dials)
	for k in 4:
		dials[k] = int(dd[k])
		_show_dial(k)
	opened = bool(d.get("opened", false))
	_lid.rotation.x = deg_to_rad(100.0) if opened else 0.0
