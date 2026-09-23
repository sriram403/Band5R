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
