class_name Build
extends RefCounted

## Tiny helpers for assembling primitive-mesh props from code.
## Everything the prototype world is made of goes through here.

static func node(mesh: Mesh, mat: Material, xf := Transform3D.IDENTITY, nm := "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = nm
	mi.mesh = mesh
	mi.material_override = mat
	mi.transform = xf
	return mi


static func box(size: Vector3, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, nm := "Box") -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = size
	return node(m, mat, _xf(pos, rot), nm)


static func cyl(radius: float, height: float, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, sides := 16, nm := "Cyl") -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return node(m, mat, _xf(pos, rot), nm)


static func cone(radius: float, height: float, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, sides := 12, nm := "Cone") -> MeshInstance3D:
	var m := CylinderMesh.new()
	m.top_radius = 0.0
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = sides
	m.rings = 1
	return node(m, mat, _xf(pos, rot), nm)


static func sphere(radius: float, mat: Material, pos := Vector3.ZERO, scale := Vector3.ONE, nm := "Sphere") -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 20
	m.rings = 10
	var xf := Transform3D(Basis().scaled(scale), pos)
	return node(m, mat, xf, nm)


## Half-sphere dome, used for cartoon hills and bushes.
static func dome(radius: float, mat: Material, pos := Vector3.ZERO, scale := Vector3.ONE, nm := "Dome") -> MeshInstance3D:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.is_hemisphere = true
	m.radial_segments = 18
	m.rings = 8
	var xf := Transform3D(Basis().scaled(scale), pos)
	return node(m, mat, xf, nm)


static func plane(size: Vector2, mat: Material, pos := Vector3.ZERO, nm := "Plane") -> MeshInstance3D:
	var m := PlaneMesh.new()
	m.size = size
	return node(m, mat, Transform3D(Basis(), pos), nm)


## Wraps a mesh instance in a StaticBody3D using a convex box hull.
static func solid_box(size: Vector3, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, nm := "Solid") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = nm
	body.transform = _xf(pos, rot)
	var mi := box(size, mat)
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	return body


static func solid_cyl(radius: float, height: float, mat: Material, pos := Vector3.ZERO, rot := Vector3.ZERO, nm := "SolidCyl") -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = nm
	body.transform = _xf(pos, rot)
	body.add_child(cyl(radius, height, mat))
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = height
	cs.shape = shape
	body.add_child(cs)
	return body


## Interaction volume. Sits on collision layer 4 so the player ray can find it
## without it blocking movement.
static func interact_area(size: Vector3, pos: Vector3, prompt: String, cb: Callable, nm := "Interact") -> Area3D:
	var a := Area3D.new()
	a.name = nm
	a.position = pos
	a.collision_layer = 4
	a.collision_mask = 0
	a.monitoring = false
	a.monitorable = true
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	a.add_child(cs)
	a.set_meta("prompt", prompt)
	a.set_meta("callback", cb)
	return a


static func label3d(text: String, pos: Vector3, rot := Vector3.ZERO, size := 0.35, color := Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 96
	l.pixel_size = size / 96.0
	l.modulate = color
	l.outline_size = 18
	l.outline_modulate = Color(0.08, 0.07, 0.1)
	l.transform = _xf(pos, rot)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.double_sided = false
	l.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return l


static func _xf(pos: Vector3, rot: Vector3) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot.x), deg_to_rad(rot.y), deg_to_rad(rot.z)))
	return Transform3D(b, pos)


## Roadworks spill for the opening puncture: two broken pallet boards with nails
## standing up out of them (readable from the driver's seat), loose nails
## scattered over the lane, a split nail box and a line of cones on the left verge.
## Local frame: +X across the road (right), -Z the way traffic comes through.
## Purely visual; the trap itself is an Area3D the caller adds.
static func nail_spill(width := 7.0) -> Node3D:
	var root := Node3D.new()
	root.name = "NailSpill"
	var wood := ToonMat.make(Color(0.55, 0.40, 0.24))
	var steel := ToonMat.make(Color(0.62, 0.64, 0.66), 0.015, 0.35)
	var card := ToonMat.make(Color(0.76, 0.60, 0.38))
	var orange := ToonMat.make(Color(0.96, 0.45, 0.10))
	var white := ToonMat.make(Color(0.95, 0.95, 0.92))
	for b in 2:
		var board := Node3D.new()
		board.name = "NailBoard%d" % b
		board.position = Vector3(-1.4 + b * 2.6, 0.03, -0.6 + b * 1.3)
		board.rotation_degrees.y = 12.0 - b * 27.0
		board.add_child(box(Vector3(1.3, 0.04, 0.15), wood, Vector3.ZERO, Vector3.ZERO, "Plank"))
		for k in 6:
			board.add_child(cyl(0.012, 0.09, steel, Vector3(-0.55 + k * 0.22, 0.06, 0.02 * (k % 2)),
				Vector3(8.0 * (k % 3 - 1), 0, 6.0 * (k % 2)), 5, "Spike"))
		root.add_child(board)
	for k in 40:
		# a fixed scatter (golden-angle spiral), denser in the middle of the lane
		var a := float(k) * 2.39996
		var r := sqrt(float(k) / 40.0)
		var x := cos(a) * r * width * 0.5
		var z := sin(a) * r * 3.0
		root.add_child(box(Vector3(0.11, 0.014, 0.014), steel, Vector3(x, 0.012, z),
			Vector3(0, float(k * 47 % 180), 0), "LooseNail"))
	# on the left verge, the side keep-left traffic passes and the sign stands
	root.add_child(box(Vector3(0.36, 0.22, 0.28), card, Vector3(-width * 0.5 - 0.3, 0.11, 1.2),
		Vector3(0, 25, 70), "NailBox"))
	for k in 4:
		var c := Vector3(-width * 0.5 - 0.6, 0.0, 5.0 + k * 3.5)
		root.add_child(cone(0.2, 0.62, orange, c + Vector3(0, 0.31, 0), Vector3.ZERO, 12, "Cone"))
		root.add_child(cyl(0.125, 0.09, white, c + Vector3(0, 0.36, 0), Vector3.ZERO, 12, "ConeBand"))
		root.add_child(box(Vector3(0.44, 0.04, 0.44), orange, c + Vector3(0, 0.02, 0), Vector3.ZERO, "ConeFoot"))
	return root
