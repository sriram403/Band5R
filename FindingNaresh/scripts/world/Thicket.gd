class_name Thicket
extends RefCounted

## A clump of growth the van can't get through, grown the way nature would
## leave it (the user, 2026-10-07): a few older trees, younger ones crowding
## round them, brambly bushes filling the gaps, rocks half sunk at odd
## angles. Denser in the middle, thinning at the edges; nothing in rows.
## Trunks and bushes are solid; the gaps between trunks stay under the van's
## 2.24 m width.


## Grows a thicket round `center` (world) about `radius` across, under
## `parent` (at the world origin). Returns it.
static func grow(parent: Node3D, center: Vector3, radius: float, seed: int, nm := "Thicket") -> Node3D:
	var root := Node3D.new()
	root.name = nm
	parent.add_child(root)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var bark := ToonMat.make(Color(0.36, 0.25, 0.17), 0.012)
	var leaf := [ToonMat.make(Color(0.27, 0.50, 0.22), 0.012), ToonMat.make(Color(0.33, 0.57, 0.25), 0.012),
		ToonMat.make(Color(0.22, 0.42, 0.22), 0.012)]
	var bush := ToonMat.make(Color(0.30, 0.46, 0.20), 0.012)
	var rockm := ToonMat.make(Color(0.52, 0.50, 0.46), 0.01)
	var body := StaticBody3D.new()
	body.name = "ThicketBody"
	root.add_child(body)
	var placed: Array = []
	# trees: a couple of old ones, then young ones that keep 1.3-2 m apart
	var tries := 0
	var count := int(radius * radius * 0.55)
	while placed.size() < count and tries < count * 12:
		tries += 1
		# denser towards the middle: the square root spreads them, the bias pulls in
		var r := radius * pow(rng.randf(), 0.75)
		var a := rng.randf() * TAU
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		var ok := true
		for q in placed:
			if Vector2(p.x - q.x, p.z - q.z).length() < rng.randf_range(1.3, 2.0):
				ok = false
				break
		if not ok:
			continue
		p.y = Landscape.ground(p.x, p.z)
		placed.append(p)
		var old := placed.size() <= 3
		var h := rng.randf_range(7.0, 10.0) if old else rng.randf_range(3.2, 6.5)
		var tr := rng.randf_range(0.22, 0.32) if old else rng.randf_range(0.10, 0.18)
		var lean := Vector3(rng.randf_range(-6, 6), 0, rng.randf_range(-6, 6))
		var t := Node3D.new()
		t.position = p
		t.rotation_degrees = lean
		root.add_child(t)
		t.add_child(Build.cyl(tr, h, bark, Vector3(0, h * 0.5 - 0.2, 0), Vector3.ZERO, 7, "Trunk"))
		var crowns := rng.randi_range(2, 3)
		for c in crowns:
			var cs := rng.randf_range(0.9, 1.6) * (1.4 if old else 1.0)
			t.add_child(Build.sphere(cs, leaf[rng.randi_range(0, 2)],
				Vector3(rng.randf_range(-0.6, 0.6), h * rng.randf_range(0.72, 0.95), rng.randf_range(-0.6, 0.6)),
				Vector3(1.0, rng.randf_range(0.8, 1.15), 1.0), "Crown"))
		var col := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = maxf(tr, 0.2)
		cyl.height = 3.0
		col.shape = cyl
		col.position = p + Vector3(0, 1.3, 0)
		body.add_child(col)
	# bushes in the gaps, bigger at the edges where the light gets in
	for i in int(count * 0.8):
		var r := radius * sqrt(rng.randf()) * 1.1
		var a := rng.randf() * TAU
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = Landscape.ground(p.x, p.z)
		var s := rng.randf_range(0.6, 1.1) * (1.0 + r / radius * 0.4)
		root.add_child(Build.sphere(s, bush, p + Vector3(0, s * 0.45, 0), Vector3(1.2, 0.75, 1.1), "Bush"))
		var col := CollisionShape3D.new()
		var sph := SphereShape3D.new()
		sph.radius = s * 0.85
		col.shape = sph
		col.position = p + Vector3(0, s * 0.35, 0)
		body.add_child(col)
	# a few rocks, half in the ground, none the same
	for i in rng.randi_range(3, 6):
		var r := radius * sqrt(rng.randf())
		var a := rng.randf() * TAU
		var p := center + Vector3(cos(a) * r, 0, sin(a) * r)
		p.y = Landscape.ground(p.x, p.z)
		var sz := Vector3(rng.randf_range(0.8, 1.8), rng.randf_range(0.6, 1.2), rng.randf_range(0.7, 1.5))
		root.add_child(Build.solid_box(sz, rockm, p + Vector3(0, sz.y * 0.2, 0),
			Vector3(rng.randf_range(-15, 15), rng.randf_range(0, 360), rng.randf_range(-15, 15)), "Rock"))
	return root
