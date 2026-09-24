extends "res://scripts/world/LevelLayout.gd"

## Part of LevelBuilder (see LevelLayout.gd): the scatter (trees, rocks, bushes,
## reeds, wildflowers and their colliders, in distance-culled tiles) and the
## backdrop beyond the map's edge.

const SCATTER_TILE := 500.0


func _scatter() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED

	var trunks: Array[Transform3D] = []
	var pines: Array[Transform3D] = []
	var pine_cols: Array[Color] = []
	var blobs: Array[Transform3D] = []
	var blob_cols: Array[Color] = []
	var rocks: Array[Transform3D] = []
	var rock_cols: Array[Color] = []
	var bushes: Array[Transform3D] = []
	var bush_cols: Array[Color] = []
	var reeds: Array[Transform3D] = []
	var flowers: Array[Transform3D] = []
	var flower_cols: Array[Color] = []
	var petal_palette := [Color(0.95, 0.85, 0.30), Color(0.96, 0.96, 0.92), Color(0.78, 0.45, 0.85),
		Color(0.95, 0.55, 0.30), Color(0.55, 0.70, 0.98)]

	# colliders: one static body per scatter tile, so physics queries stay local
	var colliders := Node3D.new()
	colliders.name = "TreeColliders"
	var bodies := {}

	var half := Landscape.EXTENT * 0.5 - 15.0
	# the same density as the first 1.6 km valley, whatever the world size
	var attempts := int(24000.0 * pow(Landscape.EXTENT / 1600.0, 2.0))
	# Hot loop (150 000 tries at 4 km): the grid lookups are done by hand, once
	# per try for all three layers, and the coastline is only asked about near
	# the coast. Same tests, same order, same random numbers: the same forest.
	var gn := Landscape.grid_n
	var g0 := -Landscape.EXTENT * 0.5
	var g_road := Landscape.grid_road_d
	var g_river := Landscape.grid_river_d
	var g_h := Landscape.grid_h
	var coast_x0 := 1e9               # west of this, nowhere is near the beach
	for cp in Landscape.coast:
		coast_x0 = minf(coast_x0, cp.x)
	coast_x0 -= Landscape.BEACH_W + 10.0
	for _i in attempts:
		var x := rng.randf_range(-half, half)
		var z := rng.randf_range(-half, half)
		var kind := rng.randf()
		var keep := rng.randf()
		# bilinear weights on the terrain grid (Landscape._grid_sample)
		var gfx := (x - g0) / Landscape.STEP
		var gfz := (z - g0) / Landscape.STEP
		var inside := gn > 0 and not (gfx < 0.0 or gfz < 0.0 or gfx > gn - 1 or gfz > gn - 1)
		var gk := 0
		var tx := 0.0
		var tz := 0.0
		var d: float
		if inside:
			var gix := mini(int(gfx), gn - 2)
			var giz := mini(int(gfz), gn - 2)
			tx = gfx - gix
			tz = gfz - giz
			gk = giz * gn + gix
			d = lerpf(lerpf(g_road[gk], g_road[gk + 1], tx), lerpf(g_road[gk + gn], g_road[gk + gn + 1], tx), tz)
		else:
			d = Landscape.road_distance(x, z)
		if d < 9.5:
			continue
		if x >= coast_x0 and Landscape.coast_inland(x, z) < Landscape.BEACH_W + 10.0:
			continue
		var rd: float
		if inside:
			rd = lerpf(lerpf(g_river[gk], g_river[gk + 1], tx), lerpf(g_river[gk + gn], g_river[gk + gn + 1], tx), tz)
		else:
			rd = Landscape.river_distance(x, z)
		if rd < Landscape.RIVER_HALF + 4.0:
			continue
		if _in_pond(x, z, 4.0):
			# reeds grow on the lake shore instead
			if kind < 0.5 and _near_pond_shore(x, z):
				var ys := rng.randf_range(0.7, 1.3)
				reeds.append(_xf(Vector3(x, _h(x, z) + 0.5 * ys, z), rng.randf_range(0, TAU), Vector3(1, ys, 1)))
			continue
		if _in_clearing(x, z):
			continue
		# thin the woods right beside the road so sightlines stay open, and
		# along the river so the water reads from a distance
		if d < 26.0 and keep < 0.62:
			continue
		if rd < 30.0 and keep < 0.5:
			continue
		# Woods and meadows: a slow noise field decides which is which, so the
		# land alternates between forest belts and open flowery clearings
		# instead of one uniform carpet of trees.
		var forest := _forest(x, z)
		if keep > forest:
			if kind < 0.35 and d > 8.0:
				# meadow: a little clump of wildflowers instead of a tree
				var col: Color = petal_palette[int(kind * 100.0) % petal_palette.size()]
				for f in 5:
					var fx := x + rng.randf_range(-2.5, 2.5)
					var fz := z + rng.randf_range(-2.5, 2.5)
					flowers.append(_xf(Vector3(fx, _h(fx, fz) + 0.18, fz), 0.0, Vector3.ONE * rng.randf_range(0.8, 1.3)))
					flower_cols.append(col)
			continue

		var y := lerpf(lerpf(g_h[gk], g_h[gk + 1], tx), lerpf(g_h[gk + gn], g_h[gk + gn + 1], tx), tz) if inside else _h(x, z)
		if kind < 0.46:
			var s := rng.randf_range(0.85, 1.5)
			var yaw := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.5 * s, z), yaw, Vector3(s, s, s)))
			pines.append(_xf(Vector3(x, y + 5.4 * s, z), yaw, Vector3(s, s, s)))
			pine_cols.append(C_LEAF_A.lerp(C_LEAF_C, rng.randf()))
			_tile_shape(bodies, colliders, x, z, _cylinder(0.55 * s, 6.0 * s), Vector3(x, y + 3.0, z))
		elif kind < 0.80:
			var s2 := rng.randf_range(0.9, 1.7)
			var yaw2 := rng.randf_range(0, TAU)
			trunks.append(_xf(Vector3(x, y + 1.6 * s2, z), yaw2, Vector3(s2, s2, s2)))
			blobs.append(_xf(Vector3(x, y + 4.2 * s2, z), yaw2, Vector3(s2, s2 * 0.85, s2)))
			blob_cols.append(C_LEAF_B.lerp(C_LEAF_A, rng.randf()))
			_tile_shape(bodies, colliders, x, z, _cylinder(0.6 * s2, 6.0 * s2), Vector3(x, y + 3.0, z))
		elif kind < 0.90:
			var s3 := rng.randf_range(0.5, 2.4)
			var ryaw := rng.randf_range(0, TAU)
			var rys := rng.randf_range(0.5, 0.9)
			var rzs := rng.randf_range(0.8, 1.2)
			rocks.append(_xf(Vector3(x, y + s3 * 0.25, z), ryaw, Vector3(s3, s3 * rys, s3 * rzs)))
			rock_cols.append(C_ROCK.lightened(rng.randf_range(-0.12, 0.12)))
			# A sphere rather than a box: the capsule can ride up over the low
			# ones instead of catching on a vertical edge.
			if s3 > 0.8:
				var sph := SphereShape3D.new()
				sph.radius = s3 * 0.72
				# top of the sphere matches the top of the (squashed) rock
				_tile_shape(bodies, colliders, x, z, sph, Vector3(x, y + s3 * 0.25 + s3 * rys - sph.radius, z))
		else:
			var s4 := rng.randf_range(0.7, 1.6)
			bushes.append(_xf(Vector3(x, y + 0.35 * s4, z), rng.randf_range(0, TAU),
				Vector3(s4, s4 * 0.8, s4)))
			bush_cols.append(C_LEAF_C.lerp(C_LEAF_B, rng.randf()))

	var trunk_mesh := CylinderMesh.new()
	trunk_mesh.top_radius = 0.28
	trunk_mesh.bottom_radius = 0.42
	trunk_mesh.height = 3.2
	trunk_mesh.radial_segments = 7
	trunk_mesh.rings = 1

	var pine_mesh := CylinderMesh.new()
	pine_mesh.top_radius = 0.0
	pine_mesh.bottom_radius = 2.6
	pine_mesh.height = 7.4
	pine_mesh.radial_segments = 8
	pine_mesh.rings = 1

	var blob_mesh := SphereMesh.new()
	blob_mesh.radius = 2.7
	blob_mesh.height = 5.0
	blob_mesh.radial_segments = 9
	blob_mesh.rings = 5

	var rock_mesh := SphereMesh.new()
	rock_mesh.radius = 1.0
	rock_mesh.height = 2.0
	rock_mesh.radial_segments = 6
	rock_mesh.rings = 3

	var bush_mesh := SphereMesh.new()
	bush_mesh.radius = 1.1
	bush_mesh.height = 2.0
	bush_mesh.radial_segments = 7
	bush_mesh.rings = 4

	var flower_mesh := SphereMesh.new()
	flower_mesh.radius = 0.16
	flower_mesh.height = 0.2
	flower_mesh.radial_segments = 6
	flower_mesh.rings = 2

	var reed_mesh := CylinderMesh.new()
	reed_mesh.top_radius = 0.02
	reed_mesh.bottom_radius = 0.35
	reed_mesh.height = 1.0
	reed_mesh.radial_segments = 5
	reed_mesh.rings = 1

	# Each kind is split into SCATTER_TILE tiles that are culled on their own
	# and fade out with distance: a 4 km forest in one batch drew everything,
	# everywhere, every frame.
	world.add_child(_tiled("Trunks", trunk_mesh, ToonMat.make(C_TRUNK, 0.02), trunks, [], 1500.0))
	world.add_child(_tiled("Pines", pine_mesh, ToonMat.make(Color.WHITE, 0.035), pines, pine_cols, 1500.0))
	world.add_child(_tiled("Canopies", blob_mesh, ToonMat.make(Color.WHITE, 0.035), blobs, blob_cols, 1500.0))
	world.add_child(_tiled("Rocks", rock_mesh, ToonMat.make(Color.WHITE, 0.02), rocks, rock_cols, 900.0))
	world.add_child(_tiled("Bushes", bush_mesh, ToonMat.make(Color.WHITE, 0.02), bushes, bush_cols, 700.0))
	world.add_child(_tiled("Reeds", reed_mesh, ToonMat.make(Color(0.46, 0.58, 0.28), 0.0), reeds, [], 450.0))
	world.add_child(_tiled("Wildflowers", flower_mesh, ToonMat.make(Color.WHITE, 0.0), flowers, flower_cols, 350.0, false))
	world.add_child(colliders)


## A scatter collider: a shape straight on its tile's body, no node of its own
## (about 59 000 of them at 4 km; a CollisionShape3D each took ~0.7 s to make).
func _tile_shape(bodies: Dictionary, parent: Node3D, x: float, z: float, shape: Shape3D, at: Vector3) -> void:
	var sb := _tile_body(bodies, parent, x, z)
	var owner_id := sb.create_shape_owner(sb)
	sb.shape_owner_add_shape(owner_id, shape)
	sb.shape_owner_set_transform(owner_id, Transform3D(Basis(), at))


func _cylinder(radius: float, height: float) -> CylinderShape3D:
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	return sh


func _tile_body(bodies: Dictionary, parent: Node3D, x: float, z: float) -> StaticBody3D:
	var t := _tile(x, z)
	if not bodies.has(t):
		var sb := StaticBody3D.new()
		sb.name = "Tile%d" % t
		bodies[t] = sb
		parent.add_child(sb)
	return bodies[t]


func _tile(x: float, z: float) -> int:
	var n := int(ceil(Landscape.EXTENT / SCATTER_TILE))
	var h := Landscape.EXTENT * 0.5
	return clampi(int((z + h) / SCATTER_TILE), 0, n - 1) * n + clampi(int((x + h) / SCATTER_TILE), 0, n - 1)


## One MultiMesh per scatter tile under a group node, each culled by distance.
func _tiled(nm: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array, range_end: float, shadows := true) -> Node3D:
	scatter[nm] = xforms
	var group := Node3D.new()
	group.name = nm
	var by_tile := {}
	for i in xforms.size():
		var o: Vector3 = (xforms[i] as Transform3D).origin
		var t := _tile(o.x, o.z)
		if not by_tile.has(t):
			by_tile[t] = [[], []]
		by_tile[t][0].append(xforms[i])
		if colors.size() > 0:
			by_tile[t][1].append(colors[i])
	var keys := by_tile.keys()
	keys.sort()
	for t in keys:
		var mmi := _multi("%s%d" % [nm, t], mesh, mat, by_tile[t][0], by_tile[t][1])
		mmi.visibility_range_end = range_end
		mmi.visibility_range_end_margin = range_end * 0.1
		mmi.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		if not shadows:
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		group.add_child(mmi)
	return group


## 0..1 chance a scatter spot is woodland rather than meadow. Hills and the
## land around them are wooded; the valley floor opens into meadows.
func _forest(x: float, z: float) -> float:
	var n := sin(x * 0.0061 + 0.8) * cos(z * 0.0053 - 1.3) + 0.55 * sin((x - z) * 0.0097 + 2.1)
	return clampf(0.5 + n * 0.7, 0.05, 0.98)


func _multi(nm: String, mesh: Mesh, mat: Material, xforms: Array, colors: Array) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = colors.size() > 0
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
		if colors.size() > 0:
			mm.set_instance_color(i, colors[i])
	var node := MultiMeshInstance3D.new()
	node.name = nm
	node.multimesh = mm
	var m := mat
	if colors.size() > 0 and m is StandardMaterial3D:
		var sm: StandardMaterial3D = (m as StandardMaterial3D).duplicate()
		sm.vertex_color_use_as_albedo = true
		m = sm
	node.material_override = m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	return node


func _backdrop() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SCATTER_SEED + 7
	var root := Node3D.new()
	root.name = "Backdrop"
	var far := ToonMat.make(Color(0.46, 0.55, 0.60), 0.0, 1.0)
	var far2 := ToonMat.make(Color(0.55, 0.63, 0.68), 0.0, 1.0)
	var snow := ToonMat.make(Color(0.90, 0.92, 0.95), 0.0, 1.0)
	# Hazy blue-green, between the valley's greens and the far blue peaks: a
	# saturated green read as odd blobs floating on the horizon.
	var ridge_mat := ToonMat.make(Color(0.39, 0.50, 0.49), 0.0, 1.0)
	var ridge_trees: Array[Transform3D] = []
	for i in 64:
		var a := TAU * float(i) / 64.0 + rng.randf_range(-0.04, 0.04)
		var hgt := rng.randf_range(140.0, 330.0)
		if cos(a) > 0.2 and Landscape.coast.size() > 0:
			continue               # the east is open sea to the horizon
		var rad := hgt * rng.randf_range(0.7, 1.1)
		var style := i % 4
		# forested ridges are long and low: stretched along the horizon
		var stretch := 1.9 if style == 3 else 1.0
		# Every mountain stands wholly outside the playable map (its base
		# starts beyond the terrain's corner), so none can sit on a road.
		var dist := Landscape.EXTENT * 0.72 + rad * stretch + rng.randf_range(20.0, 260.0)
		var pos := Vector3(cos(a) * dist, hgt * 0.35 - 30.0, sin(a) * dist)
		var mi: MeshInstance3D
		if style == 3:
			# a long, low wooded ridge with a ragged line of tree tops, so it reads
			# as distant forest rather than a smooth green blob
			var dm := SphereMesh.new()
			dm.radius = rad
			dm.height = rad * 2.0
			dm.is_hemisphere = true
			dm.radial_segments = 24
			dm.rings = 8
			var ys := hgt * 0.42 / rad
			var xf := Transform3D(Basis(Vector3.UP, -a - PI * 0.5) * Basis.from_scale(Vector3(stretch, ys, 1.0)), Vector3(pos.x, -30.0, pos.z))
			mi = Build.node(dm, ridge_mat, xf, "Hill%d" % i)
			for k in 34:
				var u := rng.randf_range(-0.92, 0.92)
				var v := rng.randf_range(-0.55, 0.55)
				var top := sqrt(maxf(0.0, 1.0 - u * u - v * v))
				if top < 0.15:
					continue
				var at := xf * Vector3(u * rad, top * rad, v * rad)
				var th := rng.randf_range(55.0, 90.0)
				var tr := th * rng.randf_range(0.24, 0.30)
				ridge_trees.append(Transform3D(Basis.from_scale(Vector3(tr, th, tr)), at + Vector3.UP * (th * 0.38)))
		else:
			mi = Build.cone(rad, hgt, far2 if style == 0 else far, pos, Vector3(0, rng.randf_range(0, 360), 0), 6 + style * 2, "Peak%d" % i)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(mi)
		if style == 1 and hgt > 200.0:
			# a twin summit: a smaller cone leaning off the shoulder
			var twin := Build.cone(rad * 0.6, hgt * 0.7, far, pos + Vector3(rad * 0.45, -hgt * 0.1, rad * 0.2), Vector3.ZERO, 7, "Twin%d" % i)
			twin.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(twin)
		if hgt > 250.0 and style != 3:
			# snow cap: the top quarter of the same cone
			var cap := Build.cone(rad * 0.25, hgt * 0.25, snow, pos + Vector3(0, hgt * 0.375 + 0.5, 0), Vector3.ZERO, 9, "Snow%d" % i)
			cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(cap)
	world.add_child(root)
	# the ridge tree tops: one multimesh, a single draw call
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 1.0
	cone.height = 1.0
	cone.radial_segments = 6
	cone.rings = 1
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cone
	mm.instance_count = ridge_trees.size()
	for k in ridge_trees.size():
		mm.set_instance_transform(k, ridge_trees[k])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "BackdropTrees"
	mmi.multimesh = mm
	mmi.material_override = ToonMat.make(Color(0.31, 0.43, 0.42), 0.0, 1.0)
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(mmi)
	_world_edge()


## Invisible walls just inside the terrain's edge: the valley ends, you cannot
## walk or drive off the world into the backdrop.
func _world_edge() -> void:
	var body := StaticBody3D.new()
	body.name = "WorldEdge"
	var e := Landscape.EXTENT * 0.5 - 6.0
	for side in [[Vector3(e, 0, 0), Vector3(2, 400, e * 2)], [Vector3(-e, 0, 0), Vector3(2, 400, e * 2)],
			[Vector3(0, 0, e), Vector3(e * 2, 400, 2)], [Vector3(0, 0, -e), Vector3(e * 2, 400, 2)]]:
		body.add_child(_box_shape(side[1], Transform3D(Basis(), side[0])))
	# the sea: wade in knee-deep, no further
	for i in COAST.size() - 1:
		var a := Vector3(COAST[i].x + 18.0, 0, COAST[i].y)
		var b := Vector3(COAST[i + 1].x + 18.0, 0, COAST[i + 1].y)
		var mid := (a + b) * 0.5
		body.add_child(_box_shape(Vector3(2, 400, a.distance_to(b) + 4.0),
			Transform3D(Basis.looking_at(b - a, Vector3.UP), mid)))
	world.add_child(body)
