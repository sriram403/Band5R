class_name LookoutRelay
extends Node3D

## #4, the lookout boards (reworked 2026-10-14, `design/PUZZLE_CHANGES.md`
## #4). The Ridge Patrol's supply box at the foot of the Pine Ridge lookout
## has four picture dials. The code is painted on the landmarks round the
## valley, one picture to a place, big enough to read from the deck with the
## binoculars (2x-8x): the windmill's neck, the silo (behind the barn's snow
## shower, seen when it thins), the barn, the Last Fuel sign, the water
## tower at the works (1.1 km: 8x, steadied on the rail) and the windmill's
## switch house. The patrol's sheet at the box says which, in riddles; the
## last riddle is on the patrol sign up the slope, under old snow that only
## snowballs knock off (it's out of reach). Pull the handle to try: right,
## the lid opens on a full can of fuel; wrong, the lock's spring spins the
## dials round to somewhere new.

const SHAPES := ["circle", "square", "triangle", "cross", "ring", "diamond"]
const WHITE := Color(0.96, 0.95, 0.90)
const DARK := Color(0.14, 0.14, 0.16)
## Each player has half the screen: at 8x a 3 m picture at 500 m is ~25 px
## (the survey shots); the far one (1.1 km) is painted bigger.
const PLATE := 3.0
const PRACTICE_SHAPE := 1.6
const PLATE_IDS := ["windmill", "silo", "barn", "last_fuel", "water_tower", "switch_house"]
const SNOW_CHUNKS := 4

const SHEET := "RIDGE PATROL - SUPPLY BOX

The code is painted out in the valley, one picture to a place. Read it from the deck. (The practice boards don't count.)

1: It works for the wind and never leaves home.
2: The red barn's tall sister.
3: The only picture you'll find in two places.
4: On the patrol sign, up the slope.

Pull the handle to try. A wrong try spins the dials."
const SIGN_TEXT := "4: Past the last fuel,\nthe water that\nstands on legs."

var code: Array[int] = []        ## four indices into SHAPES: the answer
var plate_shape := {}            ## plate id -> index into SHAPES
var plates := {}                 ## plate id -> the node (board or painted decal)
var dials: Array[int] = [0, 0, 0, 0]
var opened := false
var snow_left := SNOW_CHUNKS     ## frozen lumps still on the patrol sign
var boards: Array[Node3D] = []   ## the two practice boards
var sign_at := Vector3.ZERO      ## the patrol sign's face (global), for tests
var patches: Array[Node3D] = []  ## the old snow you make snowballs from
var _dial_faces: Array[Node3D] = []
var _lid: Node3D
var _box: Node3D
var _box_at := Vector3.ZERO
var _reward: Node = null
var _chunks: Array[Node3D] = []
var _spinning := false
var _ground: Callable
var _deck := Vector3.ZERO
var start_dials: Array[int] = []


## `deck`: the lookout's deck (global), `board_xz`: the practice boards
## (LevelLayout.relay_boards, whose sightlines are kept clear of trees);
## `box_at`: the box (global, on the ground); `ground`: the height function.
## The plates go up later, once every landmark stands (`mount_plates`).
## Built before the world joins the scene: positions are worked out with
## `_gxf`, never global_transform.
func setup(deck: Vector3, board_xz: Array[Vector2], box_at: Vector3, ground: Callable) -> void:
	add_to_group("lookout_relay")
	add_to_group("snow_target")
	_ground = ground
	_deck = deck
	var rng := RandomNumberGenerator.new()
	rng.seed = 4417
	# five different pictures; the barn and Last Fuel share one (riddle 3)
	var pool := range(SHAPES.size())
	var pick: Array[int] = []
	for k in 5:
		var i := rng.randi_range(0, pool.size() - 1)
		pick.append(pool[i])
		pool.remove_at(i)
	plate_shape = {"windmill": pick[0], "silo": pick[1], "barn": pick[2], "last_fuel": pick[2],
		"water_tower": pick[3], "switch_house": pick[4]}
	code = [pick[0], pick[1], pick[2], pick[3]]
	start_dials = [(code[0] + 3) % 6, (code[1] + 2) % 6, (code[2] + 4) % 6, (code[3] + 1) % 6]
	dials = start_dials.duplicate()
	for b in 2:
		var at := Vector3(board_xz[b].x, 0, board_xz[b].y)
		at.y = ground.call(at.x, at.z)
		boards.append(_practice_board(at, deck, b, rng))
	_box_at = box_at
	_build_box(box_at, deck)
	_build_sign()


## A node's transform in the world, from its parents' (the world itself
## sits at the origin), usable before the world is in the scene.
static func _gxf(n: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent()
	while p is Node3D:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t


# --- the practice boards (S4) ------------------------------------------------

## A board on two posts, 5 m up, facing the deck: PRACTICE, its number and
## two pictures, readable at 2x: where a new spotter learns the zoom.
func _practice_board(at: Vector3, deck: Vector3, b: int, rng: RandomNumberGenerator) -> Node3D:
	var n := Node3D.new()
	n.name = "RelayBoard%d" % (b + 1)
	add_child(n)
	var look := deck - at
	look.y = 0.0
	n.transform = Transform3D(Basis.looking_at(-look, Vector3.UP), at)   # +Z towards the deck
	var wood := ToonMat.make(Color(0.40, 0.30, 0.20))
	for sx in [-2.4, 2.4]:
		n.add_child(Build.cyl(0.15, 6.0, wood, Vector3(sx, 3.0, 0), Vector3.ZERO, 6, "Post"))
	n.add_child(Build.box(Vector3(6.0, 2.4, 0.15), ToonMat.make(DARK), Vector3(0, 5.6, 0), Vector3.ZERO, "Board"))
	n.add_child(Build.label3d(str(b + 1), Vector3(-2.3, 5.6, 0.1), Vector3.ZERO, 1.6, WHITE))
	n.add_child(Build.label3d("PRACTICE", Vector3(0.6, 6.55, 0.1), Vector3.ZERO, 0.45, WHITE))
	for k in 2:
		var s := shape_node(SHAPES[rng.randi_range(0, SHAPES.size() - 1)], PRACTICE_SHAPE)
		s.position = Vector3(-0.3 + k * 2.1, 5.45, 0.1)
		n.add_child(s)
	return n


# --- the plates on the landmarks ---------------------------------------------

## Once every landmark is built (LevelBuilder._landmarks): the patrol's
## pictures on the six places, each turned to face the deck, and the
## direction table and rail rests on the deck (S3).
func mount_plates(b) -> void:
	var w: Node3D = b.world
	var wm := w.get_node_or_null("Windmill")
	if wm != null:
		# a board strapped round the windmill's neck, 14 m up, turned to the deck
		var tower: Node3D = wm.get("tower")
		var h := 14.0
		var out := _flat_dir_local(tower, Vector3(0, h, 0))
		var p := _plate_board("windmill", PLATE)
		p.transform = Transform3D(Basis.looking_at(-out, Vector3.UP), Vector3(0, h, 0) + out * (WindmillPower.NECK_R + 0.12))
		tower.add_child(p)
		_straps(p, PLATE, WindmillPower.NECK_R)
	var barn := w.get_node_or_null("Barn") as Node3D
	if barn != null:
		# painted on the silo, 8.5 m up, on the side the deck sees
		var c := Vector3(11.0, 8.5, -2.0)
		var out := _flat_dir_local(barn, c)
		_plate_paint("silo", barn, c + out * 2.6, out, PLATE)
		# a board on the barn wall that faces the deck
		var face := _box_face(barn, Vector3(0, 3.5, 0), Vector3(8.0, 3.5, 5.5))
		var at: Vector3 = face["at"]
		var n: Vector3 = face["n"]
		if absf(n.z) > 0.5:
			at.x += 4.0          # off the doors (+Z) / the silo's side (-Z)
		at.y = 4.6
		var bp := _plate_board("barn", PLATE)
		bp.transform = Transform3D(Basis.looking_at(-n, Vector3.UP), at + n * 0.1)
		barn.add_child(bp)
	var lf := w.get_node_or_null("LastFuel") as Node3D
	if lf != null:
		var pole := lf.find_child("Pole", true, false) as Node3D
		if pole != null:
			# a board on a length of pole bolted above the sign (under it, the
			# canopy hid it from the deck), turned to the deck
			var sn := pole.get_parent() as Node3D
			sn.add_child(Build.cyl(0.1, 4.0, ToonMat.make(Color(0.5, 0.5, 0.52)), Vector3(0, 9.6, 0), Vector3.ZERO, 8, "PoleExtension"))
			var out := _flat_dir_local(sn, Vector3(0, 9.9, 0))
			var p := _plate_board("last_fuel", PLATE)
			p.transform = Transform3D(Basis.looking_at(-out, Vector3.UP), Vector3(0, 9.9, 0) + out * 0.16)
			sn.add_child(p)
	var lad := w.find_child("TowerLadder", true, false)
	if lad != null:
		# painted big on the water tower's tank, above the catwalk
		var tw := lad.get_parent() as Node3D
		var c := Vector3(0, 18.3, 0)
		var out := _flat_dir_local(tw, c)
		_plate_paint("water_tower", tw, c + out * 4.6, out, 4.2)
	var hut := w.find_child("SwitchHouse", true, false) as Node3D
	if hut != null:
		var face := _box_face(hut, Vector3(0, 1.2, 0), Vector3(1.3, 1.2, 1.2))
		var n: Vector3 = face["n"]
		var at: Vector3 = face["at"]
		at.y = 1.45
		var hp := _plate_board("switch_house", 1.9)
		hp.transform = Transform3D(Basis.looking_at(-n, Vector3.UP), at + n * 0.08)
		hut.add_child(hp)
	var lookout := w.get_node_or_null("Lookout") as Node3D
	if lookout != null:
		_direction_table(lookout)
		_rests(lookout)
		_build_patches(lookout)


## The direction from `node`'s local point towards the deck, flat, in the
## node's local frame.
func _flat_dir_local(node: Node3D, local_pt: Vector3) -> Vector3:
	var gx := _gxf(node)
	var to := _deck - gx * local_pt
	to.y = 0.0
	var l := gx.basis.inverse() * to.normalized()
	l.y = 0.0
	return l.normalized()


## Of a box's four walls (centre `c`, half size `half`, both local to
## `node`), the one facing the deck most: its middle and outward normal.
func _box_face(node: Node3D, c: Vector3, half: Vector3) -> Dictionary:
	var to := _flat_dir_local(node, c)
	var best := Vector3.FORWARD
	var dot := -2.0
	for n in [Vector3.RIGHT, Vector3.LEFT, Vector3.BACK, Vector3.FORWARD]:
		if (n as Vector3).dot(to) > dot:
			dot = (n as Vector3).dot(to)
			best = n
	return {"at": c + best * Vector3(half.x, 0, half.z), "n": best}


## A patrol board: dark, a white picture, a pale rim, bolts. Faces +Z.
func _plate_board(id: String, size: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Plate_" + id
	plates[id] = n
	n.add_child(Build.box(Vector3(size + 0.16, size + 0.16, 0.06), ToonMat.make(Color(0.80, 0.78, 0.72)), Vector3(0, 0, -0.02), Vector3.ZERO, "Rim"))
	n.add_child(Build.box(Vector3(size, size, 0.08), ToonMat.make(DARK), Vector3.ZERO, Vector3.ZERO, "Board"))
	var s := shape_node(SHAPES[plate_shape[id]], size * 0.78)
	s.position = Vector3(0, 0, 0.05)
	n.add_child(s)
	for cx in [-1.0, 1.0]:
		for cy in [-1.0, 1.0]:
			n.add_child(Build.cyl(0.05, 0.06, ToonMat.make(Color(0.5, 0.5, 0.48)), Vector3(cx * size * 0.45, cy * size * 0.45, 0.05), Vector3(90, 0, 0), 6, "Bolt"))
	return n


## Two steel straps round a round thing (the windmill's neck) holding a
## board on its front.
func _straps(board: Node3D, size: float, r: float) -> void:
	for sy in [-0.3, 0.3]:
		board.add_child(Build.cyl(r + 0.05, 0.1, ToonMat.make(Color(0.35, 0.33, 0.3)), Vector3(0, sy * size, -0.12 - r), Vector3.ZERO, 16, "Strap"))


## A picture painted straight onto a curved wall (the silo, the water tank):
## a decal, so it follows the curve like paint.
func _plate_paint(id: String, parent: Node3D, at: Vector3, out: Vector3, size: float) -> void:
	var d := Decal.new()
	d.name = "Plate_" + id
	d.texture_albedo = shape_texture(SHAPES[plate_shape[id]])
	d.size = Vector3(size, 2.0, size)
	# the decal projects along its -Y: +Y points out of the wall; the
	# texture's top is towards -Z, so +Z points down
	var y := out.normalized()
	var z := Vector3.DOWN
	var x := y.cross(z).normalized()
	d.transform = Transform3D(Basis(x, y, z), at)
	d.cull_mask = 1
	d.upper_fade = 0.0
	d.lower_fade = 0.0
	parent.add_child(d)
	plates[id] = d


## The picture as a painted square: dark ground, white shape, transparent
## outside the square (256 px).
static func shape_texture(kind: String) -> ImageTexture:
	var n := 256
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for py in n:
		for px in n:
			var x := (px + 0.5) / n * 2.0 - 1.0
			var y := 1.0 - (py + 0.5) / n * 2.0       # up is +
			var col := Color(0, 0, 0, 0)
			if absf(x) < 0.94 and absf(y) < 0.94:
				col = DARK
				if _inside(kind, x, y):
					col = WHITE
			img.set_pixel(px, py, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _inside(kind: String, x: float, y: float) -> bool:
	var r := Vector2(x, y).length()
	match kind:
		"circle": return r < 0.72
		"ring": return r < 0.72 and r > 0.40
		"square": return absf(x) < 0.62 and absf(y) < 0.62
		"diamond": return absf(x) + absf(y) < 0.74
		"cross": return (absf(x) < 0.2 and absf(y) < 0.74) or (absf(y) < 0.2 and absf(x) < 0.74)
		"triangle":
			# point up: from y = 0.66 down to y = -0.6
			if y < -0.6 or y > 0.66:
				return false
			return absf(x) < (0.66 - y) / 1.26 * 0.74
	return false


## A flat picture facing +Z, `size` m across.
static func shape_node(kind: String, size: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Shape_" + kind
	var mat := ToonMat.make(WHITE, 0.0, 0.8, WHITE * 0.25)
	var r := size * 0.5
	match kind:
		"circle":
			n.add_child(Build.cyl(r, 0.04, mat, Vector3.ZERO, Vector3(90, 0, 0), 20, "Disc"))
		"square":
			n.add_child(Build.box(Vector3(size * 0.85, size * 0.85, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Square"))
		"triangle":
			# drawn from its three corners, point up, both sides (a 3-sided
			# cylinder looked like a tilted square, so it was mistaken for the
			# diamond; a PrismMesh came out lopsided)
			var h := size * 0.85
			var w := size * 0.95
			var top := Vector3(0, h * 0.55, 0.02)
			var bl := Vector3(-w * 0.5, -h * 0.45, 0.02)
			var br := Vector3(w * 0.5, -h * 0.45, 0.02)
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			for v in [top, br, bl, top, bl, br]:
				st.set_normal(Vector3.BACK)
				st.add_vertex(v)
			n.add_child(Build.node(st.commit(), mat, Transform3D.IDENTITY, "Tri"))
		"cross":
			n.add_child(Build.box(Vector3(size, size * 0.28, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Bar"))
			n.add_child(Build.box(Vector3(size * 0.28, size, 0.04), mat, Vector3.ZERO, Vector3.ZERO, "Bar"))
		"ring":
			n.add_child(Build.cyl(r, 0.04, mat, Vector3.ZERO, Vector3(90, 0, 0), 20, "Outer"))
			n.add_child(Build.cyl(r * 0.55, 0.04, ToonMat.make(DARK, 0.0), Vector3(0, 0, 0.01), Vector3(90, 0, 0), 20, "Hole"))
		"diamond":
			n.add_child(Build.box(Vector3(size * 0.68, size * 0.68, 0.04), mat, Vector3.ZERO, Vector3(0, 0, 45), "Diamond"))
	return n


## S3: an old direction table on the deck, a pale disc with a brass rim on a
## stone post, arrows and names pointing at the places; a piece is broken
## out where the water works would be.
func _direction_table(lookout: Node3D) -> void:
	var deck_h := 6.0
	var t := Node3D.new()
	t.name = "DirectionTable"
	t.position = Vector3(1.6, deck_h + 0.125, 0.9)
	lookout.add_child(t)
	var stone := ToonMat.make(Color(0.55, 0.53, 0.50), 0.01)
	var body := StaticBody3D.new()
	t.add_child(body)
	var cs := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 1.0
	cs.shape = cyl
	cs.position = Vector3(0, 0.5, 0)
	body.add_child(cs)
	t.add_child(Build.cyl(0.14, 0.95, stone, Vector3(0, 0.47, 0), Vector3.ZERO, 8, "Post"))
	var top := Node3D.new()
	top.name = "Top"
	top.position = Vector3(0, 1.0, 0)
	t.add_child(top)
	top.add_child(Build.cyl(0.42, 0.05, ToonMat.make(Color(0.82, 0.78, 0.66), 0.01), Vector3.ZERO, Vector3.ZERO, 24, "Disc"))
	top.add_child(Build.cyl(0.44, 0.04, ToonMat.make(Color(0.62, 0.48, 0.24), 0.01), Vector3(0, -0.01, 0), Vector3.ZERO, 24, "BrassRim"))
	var names := {"windmill": "WINDMILL", "switch_house": "SWITCH HOUSE", "barn": "RED BARN",
		"last_fuel": "LAST FUEL", "water_tower": ""}
	var radius := {"windmill": 0.35, "switch_house": 0.22, "barn": 0.33, "last_fuel": 0.33, "water_tower": 0.33}
	var lx := _gxf(lookout)
	var centre := lx * t.position
	for id in names:
		var p := plates.get(id) as Node3D
		if p == null:
			continue
		var d := _gxf(p).origin - centre
		d.y = 0.0
		var ld := lx.basis.inverse() * d.normalized()
		var ang := atan2(ld.x, ld.z)
		var dir := Vector3(sin(ang), 0, cos(ang))
		if String(names[id]) == "":
			# the broken-out piece: a dark gap in the disc's edge
			top.add_child(Build.box(Vector3(0.2, 0.052, 0.17), ToonMat.make(Color(0.36, 0.34, 0.31), 0.01), dir * 0.36 + Vector3(0, 0.002, 0), Vector3(0, rad_to_deg(ang), 0), "BrokenPiece"))
			continue
		top.add_child(Build.box(Vector3(0.015, 0.012, 0.24), ToonMat.make(Color(0.25, 0.22, 0.18)), dir * 0.16 + Vector3(0, 0.03, 0), Vector3(0, rad_to_deg(ang), 0), "Arrow"))
		# the name lies flat at the arrow's tip, read from the middle
		top.add_child(Build.label3d(String(names[id]), dir * float(radius[id]) + Vector3(0, 0.032, 0), Vector3(-90, rad_to_deg(ang) + 180.0, 0), 0.026, Color(0.2, 0.17, 0.13)))
	top.add_child(Build.label3d("PINE RIDGE PATROL", Vector3(0, 0.032, 0.3), Vector3(-90, 0, 0), 0.022, Color(0.2, 0.17, 0.13)))


## Where you can lean on the rail: the strip of deck along the front and
## both sides (PlayerRig.resting steadies the binoculars there).
func _rests(lookout: Node3D) -> void:
	var deck_h := 6.0
	for spec in [[Vector3(0, deck_h + 0.125, -2.15), Vector3(3.1, 0.7, 0.5)],
			[Vector3(-2.75, deck_h + 0.125, 0), Vector3(0.5, 0.7, 2.5)],
			[Vector3(2.75, deck_h + 0.125, 0), Vector3(0.5, 0.7, 2.5)]]:
		var r := Node3D.new()
		r.name = "RailRest"
		r.position = spec[0]
		r.set_meta("half", spec[1])
		r.add_to_group("binocular_rest")
		lookout.add_child(r)


# --- the box -----------------------------------------------------------------

func _build_box(at: Vector3, deck: Vector3) -> void:
	_box = Node3D.new()
	_box.name = "SupplyBox"
	add_child(_box)
	var look := deck - at
	look.y = 0.0
	_box.transform = Transform3D(Basis.looking_at(look, Vector3.UP), at)   # -Z (the dials) faces the tower
	var steel := ToonMat.make(Color(0.30, 0.40, 0.32), 0.012)
	_box.add_child(Build.solid_box(Vector3(1.3, 0.7, 0.8), steel, Vector3(0, 0.35, 0), Vector3.ZERO, "Box"))
	_lid = Node3D.new()
	_lid.position = Vector3(0, 0.72, 0.4)
	_box.add_child(_lid)
	_lid.add_child(Build.box(Vector3(1.32, 0.08, 0.82), steel, Vector3(0, 0.04, -0.41), Vector3.ZERO, "Lid"))
	_box.add_child(Build.label3d("SUPPLY BOX - RIDGE PATROL", Vector3(0, 0.82, -0.43), Vector3(0, 180, 0), 0.07, WHITE))
	for k in 4:
		var d := Node3D.new()
		d.name = "Dial%d" % k
		# seen from the front (-Z) the box's +X is on your left: dial 1 on the left
		d.position = Vector3(0.45 - k * 0.3, 0.4, -0.42)
		d.rotation.y = PI         # pictures face out of the box's front (-Z)
		_box.add_child(d)
		d.add_child(Build.box(Vector3(0.24, 0.24, 0.02), ToonMat.make(DARK, 0.0), Vector3(0, 0, -0.01), Vector3.ZERO, "Plate"))
		_dial_faces.append(d)
		d.add_child(Build.label3d(str(k + 1), Vector3(0, -0.2, 0.01), Vector3.ZERO, 0.07, WHITE))
		var a := Build.interact_area(Vector3(0.26, 0.3, 0.3), Vector3.ZERO, "", func(_p): turn(k), "DialArea%d" % k)
		a.set_meta("tag_name", "dial %d" % (k + 1))
		a.set_meta("prompt_fn", func(_p) -> String: return "" if opened or _spinning else "Turn dial %d (%s)" % [k + 1, SHAPES[dials[k]]])
		d.add_child(a)
		_show_dial(k)
	# the handle on the right-hand end (seen from the front): pull to try
	var hx := -0.67
	var iron := ToonMat.make(Color(0.25, 0.25, 0.27), 0.01)
	_box.add_child(Build.box(Vector3(0.05, 0.05, 0.3), iron, Vector3(hx - 0.07, 0.45, 0), Vector3.ZERO, "Handle"))
	for hz in [-0.13, 0.13]:
		_box.add_child(Build.box(Vector3(0.08, 0.04, 0.04), iron, Vector3(hx - 0.03, 0.45, hz), Vector3.ZERO, "HandleArm"))
	var ha := Build.interact_area(Vector3(0.3, 0.3, 0.5), Vector3(hx - 0.1, 0.45, 0), "", func(p): try_open(p), "HandleArea")
	ha.set_meta("tag_name", "the handle")
	ha.set_meta("prompt_fn", func(_p) -> String: return "" if opened or _spinning else "Pull the handle (try the code)")
	_box.add_child(ha)
	# the patrol's sheet on a clipboard, chained to the left-hand end
	var sx := 0.67
	_box.add_child(Build.box(Vector3(0.02, 0.36, 0.26), ToonMat.make(Color(0.45, 0.32, 0.2)), Vector3(sx + 0.01, 0.42, 0), Vector3.ZERO, "Clipboard"))
	_box.add_child(Build.box(Vector3(0.012, 0.3, 0.21), ToonMat.make(Color(0.95, 0.93, 0.86)), Vector3(sx + 0.025, 0.4, 0), Vector3.ZERO, "Sheet"))
	_box.add_child(Build.label3d("RIDGE PATROL", Vector3(sx + 0.035, 0.52, 0), Vector3(0, 90, 0), 0.025, Color(0.15, 0.15, 0.2)))
	_box.add_child(Build.box(Vector3(0.015, 0.2, 0.015), ToonMat.make(Color(0.4, 0.4, 0.42)), Vector3(sx + 0.02, 0.66, 0.08), Vector3(25, 0, 0), "Chain"))
	var sa := Build.interact_area(Vector3(0.3, 0.45, 0.4), Vector3(sx + 0.1, 0.42, 0), "Read the patrol's sheet", func(p): p.say(SHEET, 16.0), "SheetArea")
	sa.set_meta("tag_name", "the patrol's sheet")
	_box.add_child(sa)
	# S1: Naresh's note, pinned on the back
	NareshNote.make(_box, "relay_box", Vector3(0.2, 0.45, 0.41), 0.0,
		"The patrol's box. My friend read the far pictures out to me from up on the deck, and I turned the dials down here. Easy with two. Read the sheet first. - N")


func turn(k: int) -> void:
	if opened or _spinning:
		return
	dials[k] = (dials[k] + 1) % SHAPES.size()
	_show_dial(k)
	Sfx.play3d("click", _dial_faces[k].global_position, -6.0)
	# in the game's log (appdata/.../logs), to check a report against
	print("[relay] dial %d -> %s; dials %s, code %s" % [k + 1, SHAPES[dials[k]], str(dials), str(code)])


## The handle: the right code opens the lid; a wrong one trips the lock's
## spring and the dials spin round to new places on their own (you see
## and hear them go).
func try_open(_p = null) -> void:
	if opened or _spinning:
		return
	if dials == code:
		_open()
		return
	_spinning = true
	Sfx.play3d("latch", _box.global_position, -2.0)
	print("[relay] wrong try %s (code %s): the dials spin" % [str(dials), str(code)])
	_say_near("Clunk. The lid holds, and the dials whirr round on their own.", 5.0, 10.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var target: Array[int] = []
	for k in 4:
		var t := rng.randi_range(0, SHAPES.size() - 1)
		while t == code[k] or t == dials[k]:
			t = rng.randi_range(0, SHAPES.size() - 1)
		target.append(t)
	var tw := create_tween()
	for step in 14:
		tw.tween_callback(func():
			for k in 4:
				if step < 8 + k * 2 or dials[k] != target[k]:
					dials[k] = (dials[k] + 1) % SHAPES.size()
					_show_dial(k)
			Sfx.play3d("click", _box.global_position, -12.0))
		tw.tween_interval(0.06 + step * 0.012)
	tw.tween_callback(func():
		for k in 4:
			dials[k] = target[k]
			_show_dial(k)
		_spinning = false
		Sfx.play3d("latch", _box.global_position, -8.0))


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
	_reward = can
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["relay_done"] = true
	_say_near("Click-CLACK: the lid springs up. Inside, a full can of fuel.", 6.0)


func _say_near(text: String, secs: float, within := 40.0) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(_box_at) < within:
			q.say(text, secs)


# --- the patrol sign under old snow, and the snow patches ---------------------

## Up the slope from the box: the patrol's sign on a tall post, its face
## crusted with old frozen snow. Too high to reach; snowballs knock the
## crust off a lump at a time (`snowball_hit`).
func _build_sign() -> void:
	var bx := _box.transform
	var at: Vector3 = bx * Vector3(-7.0, 0, 6.5)
	at.y = _ground.call(at.x, at.z)
	var s := Node3D.new()
	s.name = "PatrolSign"
	var look := _box_at - at
	look.y = 0.0
	s.transform = Transform3D(Basis.looking_at(-look, Vector3.UP), at)     # +Z towards the box
	add_child(s)
	var wood := ToonMat.make(Color(0.36, 0.27, 0.18), 0.012)
	for px in [-0.9, 0.9]:
		s.add_child(Build.cyl(0.08, 4.2, wood, Vector3(px, 2.0, -0.08), Vector3.ZERO, 6, "Post"))
	s.add_child(Build.solid_box(Vector3(2.5, 1.35, 0.08), ToonMat.make(Color(0.34, 0.46, 0.30)), Vector3(0, 3.55, 0), Vector3.ZERO, "Board"))
	# big enough to read from a throw away (6-8 m)
	s.add_child(Build.label3d("RIDGE PATROL", Vector3(0, 4.08, 0.05), Vector3.ZERO, 0.1, WHITE))
	s.add_child(Build.label3d(SIGN_TEXT, Vector3(0, 3.45, 0.05), Vector3.ZERO, 0.12, WHITE))
	# old snow: four lumps on the face, frozen on
	var snow := ToonMat.make(Color(0.88, 0.90, 0.93), 0.01)
	var rng := RandomNumberGenerator.new()
	rng.seed = 911
	for k in SNOW_CHUNKS:
		var c := Node3D.new()
		c.name = "SnowCrust%d" % k
		c.position = Vector3(-0.9 + k * 0.6, 3.5 + rng.randf_range(-0.03, 0.03), 0.08)
		s.add_child(c)
		c.add_child(Build.box(Vector3(0.6, rng.randf_range(1.0, 1.12), 0.07), snow, Vector3(0, rng.randf_range(-0.05, 0.03), 0), Vector3(0, 0, rng.randf_range(-6, 6)), "Crust"))
		c.add_child(Build.sphere(0.12, snow, Vector3(rng.randf_range(-0.12, 0.12), rng.randf_range(-0.2, 0.2), 0.05), Vector3(1.3, 0.8, 0.5), "Lump"))
		_chunks.append(c)
	# a drift at its foot, and a zone that says why you can't reach it
	s.add_child(Build.sphere(0.6, snow, Vector3(0.2, 0.0, 0.3), Vector3(1.5, 0.3, 1.0), "Drift"))
	var za := Build.interact_area(Vector3(1.6, 2.0, 1.2), Vector3(0, 1.0, 0.5), "", func(p):
		if snow_left <= 0:
			p.say("RIDGE PATROL\n" + SIGN_TEXT, 8.0), "SignReach")
	za.set_meta("prompt_fn", func(_p) -> String:
		return "Old snow frozen on the sign, out of reach" if snow_left > 0 else "Read the sign")
	s.add_child(za)
	sign_at = _gxf(s) * Vector3(0, 3.5, 0.1)


## Old snow, left where the sun never reaches: in the shade under the
## lookout's deck and its ramp. Grey-white, lumpy, dirty at the edges, half
## sunk; E makes a snowball.
func _build_patches(lookout: Node3D) -> void:
	var snow := ToonMat.make(Color(0.86, 0.88, 0.92), 0.01)
	var grey := ToonMat.make(Color(0.70, 0.71, 0.72), 0.01)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	var lx := _gxf(lookout)
	for spot in [Vector3(-1.3, 0, -0.9), Vector3(1.4, 0, 1.2), Vector3(-0.9, 0, 4.2)]:
		var at: Vector3 = lx * spot
		at.y = _ground.call(at.x, at.z)
		var p := Node3D.new()
		p.name = "SnowPatch%d" % patches.size()
		p.position = at
		p.rotation.y = rng.randf_range(0, TAU)
		add_child(p)
		# lumps of different sizes, half sunk, as old snow lies, with a
		# dirty grey rim where it's melting into the grass
		for k in 6:
			var r := rng.randf_range(0.25, 0.65)
			var off := Vector3(rng.randf_range(-0.8, 0.8), -r * 0.45, rng.randf_range(-0.6, 0.6))
			p.add_child(Build.sphere(r, snow, off, Vector3(rng.randf_range(1.1, 1.6), rng.randf_range(0.45, 0.8), rng.randf_range(0.9, 1.3)), "Lump"))
		for k in 3:
			var off2 := Vector3(rng.randf_range(-1.0, 1.0), -0.05, rng.randf_range(-0.8, 0.8))
			p.add_child(Build.sphere(0.35, grey, off2, Vector3(1.6, 0.18, 1.0), "Slush"))
		var a := Build.interact_area(Vector3(2.0, 0.7, 1.8), Vector3(0, 0.25, 0), "", func(q): make_snowball(q), "SnowArea")
		a.set_meta("tag_name", "old snow")
		a.set_meta("prompt_fn", func(q) -> String: return "Make a snowball" if q.held == null else "")
		p.add_child(a)
		patches.append(p)


## A snowball in the player's hands.
func make_snowball(p) -> void:
	if p.held != null:
		return
	var sb := Snowball.new()
	get_tree().get_first_node_in_group("world_root").add_child(sb)
	sb.global_position = p.global_position + Vector3.UP * 1.0 - p.global_transform.basis.z * 0.5
	Sfx.play3d("hit_soft", sb.global_position, -10.0)
	p.pick_up(sb)


## A snowball burst at `pos` (Snowball calls every "snow_target"): a lump
## of the sign's crust near it falls off.
func snowball_hit(pos: Vector3) -> void:
	for c in _chunks:
		if not c.visible:
			continue
		if c.global_position.distance_to(pos) < 0.7:
			_knock(c)
			return


func _knock(c: Node3D) -> void:
	c.visible = false
	snow_left -= 1
	print("[relay] snow knocked off the sign, %d left" % snow_left)
	# the lump falls away (a copy tumbles down; the sign itself stays put)
	var fall := c.duplicate() as Node3D
	fall.visible = true
	add_child(fall)
	fall.global_transform = c.global_transform
	var tw := fall.create_tween()
	tw.tween_property(fall, "global_position", c.global_position + Vector3(0, -3.4, 0.0) + c.global_transform.basis.z * 0.4, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(fall, "rotation:x", 1.2, 0.7)
	tw.tween_property(fall, "scale", Vector3(1.0, 0.2, 1.0), 0.3)
	tw.tween_callback(fall.queue_free)
	Sfx.play3d("hit_soft", c.global_position, -4.0)
	if snow_left == 0:
		for n in get_tree().get_nodes_in_group("player"):
			var q := n as PlayerRig
			if q.global_position.distance_to(sign_at) < 40.0:
				q.say("The last of the old snow drops off the sign:\n" + SIGN_TEXT, 8.0)


func _show_snow() -> void:
	for k in _chunks.size():
		_chunks[k].visible = k >= SNOW_CHUNKS - snow_left


# --- reset and save ----------------------------------------------------------

## F1 (Puzzles, or a story jump to the road choice or before): the box
## locked with the can inside, the dials back to the start, the snow back.
func reset() -> void:
	Workable.free_reward(_reward, _box_at, 6.0)
	_reward = null
	_spinning = false
	from_dict({"dials": start_dials, "opened": false, "snow_left": SNOW_CHUNKS})
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags.erase("relay_done")


func to_dict() -> Dictionary:
	return {"dials": dials.duplicate(), "opened": opened, "snow_left": snow_left}


func from_dict(d: Dictionary) -> void:
	var dd: Array = d.get("dials", dials)
	for k in 4:
		dials[k] = int(dd[k])
		_show_dial(k)
	opened = bool(d.get("opened", false))
	_lid.rotation.x = deg_to_rad(100.0) if opened else 0.0
	snow_left = int(d.get("snow_left", SNOW_CHUNKS))
	_show_snow()
