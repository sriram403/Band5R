class_name Fence
extends RefCounted

## A farm fence that sits on the ground the way a person would have put it
## up (the user, 2026-10-07: "nothing should look programmatical"): posts
## about every 2.8 m but never evenly, each a little out of plumb and its
## own height, set into the ground where it stands; two rails running post
## to post, following the ground up and down. Solid to the van (a box per
## span, following the slope), but a person can't step through either.


## Builds a fence along `pts` (world positions; only x and z are used) under
## `parent` (which must sit at the world origin). `seed` keeps it the same
## every time; `gaps` are span numbers left open (a stile, a gateway).
static func build(parent: Node3D, pts: Array, seed: int, nm := "Fence", gaps: Array = []) -> Node3D:
	var root := Node3D.new()
	root.name = nm
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var wood := ToonMat.make(Color(0.45, 0.34, 0.24), 0.012)
	var wood_dark := ToonMat.make(Color(0.36, 0.27, 0.19), 0.012)
	var body := StaticBody3D.new()
	body.name = "FenceBody"
	root.add_child(body)
	# posts along the line, spacing 2.4-3.2 m, sideways wander of a few cm
	var posts: Array = []
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var flat := Vector2(b.x - a.x, b.z - a.z)
		var len := flat.length()
		var d := 0.0
		while d < len - 0.5:
			var u := d / len
			var side := Vector2(-flat.y, flat.x).normalized() * rng.randf_range(-0.06, 0.06)
			var x := lerpf(a.x, b.x, u) + side.x
			var z := lerpf(a.z, b.z, u) + side.y
			posts.append(Vector3(x, Landscape.ground(x, z), z))
			d += rng.randf_range(2.4, 3.2)
	var last: Vector3 = pts[pts.size() - 1]
	posts.append(Vector3(last.x, Landscape.ground(last.x, last.z), last.z))
	var tops: Array = []
	for i in posts.size():
		var p: Vector3 = posts[i]
		var h := rng.randf_range(1.18, 1.32)
		var lean := Vector3(rng.randf_range(-3.0, 3.0), rng.randf_range(0, 360), rng.randf_range(-3.0, 3.0))
		var post := Build.box(Vector3(0.16, h + 0.3, 0.16), wood_dark if rng.randf() < 0.3 else wood, p + Vector3(0, (h - 0.3) * 0.5, 0), lean, "Post")
		root.add_child(post)
		tops.append(h)
	# rails post to post, the lower one a bit slack here and there
	for i in posts.size() - 1:
		if i in gaps:
			continue
		var a: Vector3 = posts[i]
		var b: Vector3 = posts[i + 1]
		for rail_h in [0.55, 1.0]:
			var ha: float = rail_h + rng.randf_range(-0.04, 0.04)
			var hb: float = rail_h + rng.randf_range(-0.04, 0.04)
			_span(root, a + Vector3.UP * ha, b + Vector3.UP * hb, Vector2(0.09, 0.07), wood)
		# collision: a slab along the span, following its slope, 1.5 m tall
		var mid := (a + b) * 0.5
		var dir := b - a
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.3, 1.5, dir.length() + 0.1)
		cs.shape = box
		var f := dir.normalized()
		var basis := Basis.looking_at(f, Vector3.UP)
		cs.transform = Transform3D(basis, mid + Vector3.UP * 0.75)
		body.add_child(cs)
	root.set_meta("posts", posts)
	return root


## A beam from a to b (world), of cross-section `size` (x wide, y tall).
static func _span(parent: Node3D, a: Vector3, b: Vector3, size: Vector2, mat: Material) -> void:
	var d := b - a
	var m := Build.box(Vector3(size.x, size.y, d.length() + 0.12), mat, Vector3.ZERO, Vector3.ZERO, "Rail")
	m.transform = Transform3D(Basis.looking_at(d.normalized(), Vector3.UP), (a + b) * 0.5)
	parent.add_child(m)
