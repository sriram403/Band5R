extends "res://scripts/world/LevelScatter.gd"

## Part of LevelBuilder (see LevelLayout.gd): the places added with the 4 km
## greybox (Milestone B), as block-outs: houses, the town, P2's and Naresh's
## homes, Bessi beach, the coast places, the road bridges and the rail tunnel.

## A plain house block: walls, a pitched roof, a door facing `face`.
func _house(at: Vector3, face: Vector3, size: Vector3, wall_col: Color, roof_col: Color, nm: String) -> Node3D:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = nm
	root.position = pos
	var to := face - pos
	to.y = 0.0
	root.basis = Basis.looking_at(-to, Vector3.UP)      # front (+Z) faces `face`
	var roof := ToonMat.make(roof_col)
	root.add_child(Build.solid_box(size, ToonMat.make(wall_col), Vector3(0, size.y * 0.5, 0), Vector3.ZERO, "Walls"))
	var half := size.z * 0.5 + 0.4
	for sd in [-1.0, 1.0]:
		root.add_child(Build.box(Vector3(size.x + 1.2, 0.4, half / cos(deg_to_rad(32.0))), roof,
			Vector3(0, size.y + half * 0.31, sd * half * 0.5), Vector3(32.0 * sd, 0, 0), "Roof"))
	root.add_child(Build.box(Vector3(1.2, 2.4, 0.2), ToonMat.make(Color(0.36, 0.30, 0.26)), Vector3(0, 1.2, size.z * 0.5 + 0.05), Vector3.ZERO, "Door"))
	world.add_child(root)
	return root


func _p2_home() -> void:
	var lane := network.road("home_lane")
	var near := _snap(lane, Vector2(P2_HOME.x, P2_HOME.z))
	var h := HouseInterior.new()
	h.name = "P2Home"
	h.position = Vector3(P2_HOME.x, _h(P2_HOME.x, P2_HOME.z), P2_HOME.z)
	var to := near - h.position
	to.y = 0.0
	h.basis = Basis.looking_at(-to, Vector3.UP)
	world.add_child(h)
	poi["p2_home"] = h.position
	poi["p2_window"] = h.position + h.basis * Vector3(-2.5, 4.65, 4.0)
	# A constructed, drivable approach climbs roughly one metre in five from
	# the lane to the front door. It also gives the handbrake a clear job here.
	var road_end := near + Vector3.UP * 0.1
	var home_end := h.position + h.basis * Vector3(0, 0.1, 4.8)
	var climb := home_end - road_end
	var run := Vector2(climb.x, climb.z).length()
	var slope := atan2(climb.y, run)
	var along := Vector3(climb.x, 0, climb.z).normalized()
	var slab := Build.solid_box(Vector3(4.6, 0.25, climb.length()), ToonMat.make(Color(0.41, 0.43, 0.43)),
		Vector3.ZERO, Vector3.ZERO, "P2Driveway")
	slab.transform = Transform3D(Basis.looking_at(along, Vector3.UP) * Basis(Vector3.RIGHT, slope),
		(road_end + home_end) * 0.5)
	world.add_child(slab)
	poi["p2_drive_mid"] = slab.position


## A few houses along the lane and the town fuel station.
func _town() -> void:
	var lane := network.road("home_lane")
	var cols := [Color(0.92, 0.86, 0.70), Color(0.86, 0.72, 0.62), Color(0.78, 0.84, 0.76), Color(0.90, 0.90, 0.86)]
	var k := 0
	for i in range(170, 470, 22):
		if absi(i - 330) < 20:
			continue           # the fuel station's frontage
		var side := 1.0 if k % 2 == 0 else -1.0
		var p := lane.point(i) + lane.right(i) * side * 20.0
		_house(p, lane.point(i), Vector3(8, 5, 7), cols[k % cols.size()], Color(0.62, 0.30, 0.24) if k % 3 else Color(0.34, 0.36, 0.40), "TownHouse%d" % k)
		k += 1
	var fuel := Node3D.new()
	fuel.name = "TownFuel"
	var pos := TOWN_FUEL
	pos.y = _h(pos.x, pos.z)
	fuel.position = pos
	var to_road := _snap(lane, Vector2(pos.x, pos.z)) - pos
	to_road.y = 0.0
	fuel.basis = Basis.looking_at(-to_road, Vector3.UP)
	var white := ToonMat.make(Color(0.94, 0.93, 0.88))
	var green := ToonMat.make(Color(0.20, 0.55, 0.35))
	var body := StaticBody3D.new()
	fuel.add_child(body)
	fuel.add_child(Build.box(Vector3(16, 0.15, 12), ToonMat.make(Color(0.40, 0.40, 0.42)), Vector3(0, 0.08, 0), Vector3.ZERO, "Forecourt"))
	fuel.add_child(Build.box(Vector3(12, 0.5, 7), white, Vector3(0, 4.6, 0), Vector3.ZERO, "Canopy"))
	fuel.add_child(Build.box(Vector3(12.2, 0.3, 7.2), green, Vector3(0, 4.25, 0), Vector3.ZERO, "Stripe"))
	for px in [2.0]:
		fuel.add_child(Build.box(Vector3(0.8, 1.6, 0.5), green, Vector3(px, 0.95, 0), Vector3.ZERO, "Pump"))
		body.add_child(_box_shape(Vector3(0.8, 1.6, 0.5), Transform3D(Basis(), Vector3(px, 0.95, 0))))
	var pump := FuelSource.new()
	pump.name = "WorkingPump"
	pump.source_name = "Town Fuel pump"
	pump.pump_style = true
	pump.litres = 1000.0
	fuel.add_child(pump)
	pump.position = Vector3(-2.0, 0, 0)
	for cx in [-5.0, 5.0]:
		fuel.add_child(Build.cyl(0.2, 4.4, white, Vector3(cx, 2.2, 0), Vector3.ZERO, 8, "Column"))
		body.add_child(_cyl_shape(Vector3(cx, 2.2, 0), 0.2, 4.4))
	fuel.add_child(Build.solid_box(Vector3(8, 3.4, 5), white, Vector3(0, 1.7, -9), Vector3.ZERO, "Shop"))
	fuel.add_child(Build.label3d("TOWN FUEL  -  OPEN", Vector3(0, 4.6, 3.55), Vector3.ZERO, 0.5, Color(0.15, 0.40, 0.25)))
	world.add_child(fuel)
	poi["town_fuel"] = pos
	# Four ordinary cars patrol the busy part of Homestead Lane. Their left
	# lanes are relative to their travel direction; they yield to a blocked van.
	for car_idx in 4:
		var car := TrafficCar.new()
		car.name = "TownCar%d" % car_idx
		car.configure(lane, 170, 470, 190 + car_idx * 75, 1 if car_idx % 2 == 0 else -1)
		world.add_child(car)


## Fixed opening puncture, after Town Fuel and before P2's turning. The story
## arms it when P1 has reached the roadworks beat; old saves and route tests
## can still travel this road without a surprise flat.
func _roadworks() -> void:
	var lane := network.road("home_lane")
	var i := 520
	var p := lane.point(i)
	var f := lane.forward(i)
	var r := lane.right(i)
	var root := Node3D.new()
	root.name = "RoadworksNails"
	root.position = p
	world.add_child(root)
	var trap := Area3D.new()
	trap.name = "PunctureArea"
	trap.collision_layer = 0
	trap.collision_mask = 8
	trap.monitoring = true
	trap.position.y = 0.35
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10.0, 0.8, 10.0)
	cs.shape = box
	trap.add_child(cs)
	trap.body_entered.connect(func(body: Node3D):
		if not body is Camper:
			return
		var story := trap.get_tree().get_first_node_in_group("story") as Story
		if story == null or not story.flags.has("opening_puncture_armed") or story.flags.has("opening_puncture_done"):
			return
		story.flags["opening_puncture_done"] = true
		body.puncture())
	root.add_child(trap)
	var spill := Build.nail_spill(7.5)
	spill.basis = Basis.looking_at(Vector3(f.x, 0, f.z), Vector3.UP)   # cones on the approach
	spill.position.y = 0.04
	root.add_child(spill)
	var sign_pos := p - f * 30.0 - r * 7.0
	sign_pos.y = _h(sign_pos.x, sign_pos.z)
	root.add_child(Build.box(Vector3(0.14, 2.2, 0.14), ToonMat.make(C_WOOD),
		sign_pos - p + Vector3.UP * 1.1, Vector3.ZERO, "WarningPost"))
	root.add_child(Build.label3d("ROADWORKS\nLOOSE NAILS", sign_pos - p + Vector3.UP * 2.5,
		Vector3.ZERO, 0.6, Color(1.0, 0.78, 0.2)))
	poi["roadworks_nails"] = p


## Bessi beach (greybox): a promenade of stalls behind the sand, boats drawn
## up, a line of casuarinas and the memorial. Milestone E builds it properly.
func _beach() -> void:
	var root := Node3D.new()
	root.name = "BessiBeach"
	world.add_child(root)
	var stall_cols := [Color(0.90, 0.35, 0.30), Color(0.95, 0.80, 0.30), Color(0.35, 0.60, 0.85), Color(0.40, 0.75, 0.45)]
	var casu := ToonMat.make(Color(0.26, 0.40, 0.28), 0.03)
	var trunk := ToonMat.make(C_TRUNK)
	var k := 0
	for z in range(330, 960, 45):
		var shore := Landscape.coast_inland(0.0, float(z))       # the waterline's x here
		var inland := Vector3(-1, 0, 0)
		# stalls on the promenade edge, lamp posts between
		var sp := Vector3(shore - 58.0, 0, float(z))
		sp.y = _h(sp.x, sp.z)
		var stall := Build.solid_box(Vector3(3.0, 2.4, 2.4), ToonMat.make(stall_cols[k % stall_cols.size()]), sp + Vector3(0, 1.2, 0), Vector3.ZERO, "Stall%d" % k)
		root.add_child(stall)
		root.add_child(Build.box(Vector3(3.6, 0.15, 3.0), ToonMat.make(Color(0.95, 0.92, 0.84)), sp + Vector3(0.3, 2.55, 0), Vector3(0, 0, -8), "Awning"))
		var lp := sp + Vector3(0, 0, 22.0)
		root.add_child(Build.cyl(0.08, 4.5, ToonMat.make(C_STEEL), lp + Vector3(0, 2.25, 0), Vector3.ZERO, 6, "Lamp"))
		root.add_child(Build.sphere(0.3, ToonMat.make(Color(1.0, 0.92, 0.70), 0.0, 0.5, Color(1.0, 0.85, 0.5)), lp + Vector3(0, 4.6, 0), Vector3.ONE, "LampGlow"))
		# boats drawn up on the sand
		if k % 2 == 0:
			var bp := Vector3(shore - 14.0, 0, float(z) + 10.0)
			bp.y = _h(bp.x, bp.z)
			var boat := Build.box(Vector3(1.8, 0.8, 6.0), ToonMat.make(Color(0.25, 0.45, 0.70) if k % 4 == 0 else Color(0.85, 0.40, 0.25)), bp + Vector3(0, 0.4, 0), Vector3(0, 20.0 * (k % 3 - 1), 0), "Boat%d" % k)
			root.add_child(boat)
		# casuarinas behind the promenade
		for c in 2:
			var cp := Vector3(shore - 80.0 - c * 14.0, 0, float(z) + c * 20.0)
			cp.y = _h(cp.x, cp.z)
			root.add_child(Build.cyl(0.25, 5.0, trunk, cp + Vector3(0, 2.5, 0), Vector3.ZERO, 6, "CasuarinaTrunk"))
			root.add_child(Build.cone(1.6, 9.0, casu, cp + Vector3(0, 8.5, 0), Vector3.ZERO, 7, "Casuarina"))
		k += 1
	# the memorial: a plain stone column on a stepped base, facing the sea
	var shore0 := Landscape.coast_inland(0.0, 480.0)
	var mp := Vector3(shore0 - 45.0, 0, 480.0)
	mp.y = _h(mp.x, mp.z)
	root.add_child(Build.solid_box(Vector3(6, 0.6, 6), ToonMat.make(C_STONE), mp + Vector3(0, 0.3, 0), Vector3.ZERO, "MemorialBase"))
	root.add_child(Build.solid_box(Vector3(1.4, 8.0, 1.4), ToonMat.make(C_STONE.lightened(0.1)), mp + Vector3(0, 4.6, 0), Vector3.ZERO, "Memorial"))
	var bp0 := Vector3(Landscape.coast_inland(0.0, 600.0) - 30.0, 0, 600.0)
	bp0.y = _h(bp0.x, bp0.z)
	poi["beach"] = bp0
	poi["memorial"] = mp


func _fishing_village() -> void:
	var root := Node3D.new()
	root.name = "FishingVillage"
	world.add_child(root)
	var c := FISHING_VILLAGE
	var road := network.road("coast_road")
	var face := _snap(road, Vector2(c.x, c.z))
	var cols := [Color(0.62, 0.78, 0.86), Color(0.90, 0.84, 0.64), Color(0.86, 0.62, 0.56)]
	var offs := [Vector3(-14, 0, -20), Vector3(-14, 0, 2), Vector3(-12, 0, 24), Vector3(10, 0, -14)]
	for i in offs.size():
		_house(c + offs[i], face, Vector3(6, 3.4, 5), cols[i % cols.size()], Color(0.40, 0.36, 0.30), "Hut%d" % i)
	# the net shed (locked) and nets drying on poles
	var shed := _house(c + Vector3(12, 0, 12), c + Vector3(40, 0, 12), Vector3(8, 4, 6), Color(0.50, 0.42, 0.34), Color(0.30, 0.28, 0.26), "NetShed")
	shed.add_child(Build.label3d("NETS - PRIVATE", Vector3(0, 3.0, 3.1), Vector3.ZERO, 0.3, Color(0.95, 0.92, 0.85)))
	for k in 3:
		var np := c + Vector3(24, 0, -10 + k * 8)
		np.y = _h(np.x, np.z)
		root.add_child(Build.cyl(0.06, 2.4, ToonMat.make(C_WOOD), np + Vector3(0, 1.2, 0), Vector3.ZERO, 5, "NetPole"))
		root.add_child(Build.box(Vector3(0.04, 1.6, 6.0), ToonMat.make(Color(0.30, 0.45, 0.40)), np + Vector3(0, 1.4, 3.0), Vector3.ZERO, "Net"))
	var shore := Landscape.coast_inland(0.0, c.z)
	for k in 3:
		var bp := Vector3(shore - 10.0, 0, c.z - 20.0 + k * 16.0)
		bp.y = _h(bp.x, bp.z)
		root.add_child(Build.box(Vector3(1.8, 0.8, 6.5), ToonMat.make(Color(0.80, 0.30, 0.25) if k != 1 else Color(0.25, 0.45, 0.65)), bp + Vector3(0, 0.4, 0), Vector3(0, 10.0 * k, 0), "Boat"))
	poi["fishing_village"] = Vector3(c.x, _h(c.x, c.z), c.z)
	poi["net_shed"] = shed.position


## Salt pans: a grid of shallow white beds between low mud dikes.
func _salt_pans() -> void:
	var root := Node3D.new()
	root.name = "SaltPans"
	var c := SALT_PANS
	c.y = _h(c.x, c.z)
	root.position = c
	world.add_child(root)
	var salt := ToonMat.make(Color(0.93, 0.93, 0.90), 0.0)
	var brine := ToonMat.water(Color(0.62, 0.74, 0.80, 0.9))
	var dike := ToonMat.make(Landscape.MUD)
	for ix in 5:
		for iz in 5:
			var p := Vector3(-30 + ix * 15, 0.05, -30 + iz * 15)
			root.add_child(Build.box(Vector3(13, 0.06, 13), salt if (ix + iz) % 3 else brine, p, Vector3.ZERO, "Pan"))
	for k in 6:
		root.add_child(Build.box(Vector3(1.2, 0.7, 76), dike, Vector3(-37.5 + k * 15, 0.35, 0), Vector3.ZERO, "Dike"))
		root.add_child(Build.box(Vector3(76, 0.7, 1.2), dike, Vector3(0, 0.35, -37.5 + k * 15), Vector3.ZERO, "Dike"))
	# salt heaps and the watchman's hut
	for k in 3:
		root.add_child(Build.cone(2.5, 2.2, salt, Vector3(44, 1.1, -20 + k * 12), Vector3.ZERO, 8, "SaltHeap"))
	root.add_child(Build.solid_box(Vector3(3, 2.6, 3), ToonMat.make(Color(0.70, 0.64, 0.56)), Vector3(46, 1.3, 22), Vector3.ZERO, "Hut"))
	poi["salt_pans"] = c


## A whole road bridge where a road crosses the river (the estuary).
func _road_bridge(road_name: String, key: String) -> void:
	var road := network.road(road_name)
	var root := Node3D.new()
	root.name = "Bridge_" + key
	world.add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var deck_mat := ToonMat.make(Color(0.62, 0.62, 0.60), 0.012)
	var rail := ToonMat.make(C_STEEL)
	var span: Array[int] = []
	for i in road.point_count():
		if Landscape.over_river(road.point(i)):
			span.append(i)
	if span.is_empty():
		push_warning("%s never crosses the river" % road_name)
		return
	for i in range(span[0] - 1, span[span.size() - 1] + 1):
		var a := road.point(i)
		var b := road.point(i + 1)
		var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5 + Vector3.UP * 0.02)
		var sz := Vector3(Landscape.ROAD_HALF * 2.0 + 1.0, 0.4, a.distance_to(b) + 0.05)
		var slab := Build.box(sz, deck_mat)
		slab.transform = xf
		root.add_child(slab)
		body.add_child(_box_shape(sz, xf))
		for sd in [-1.0, 1.0]:
			var rx := xf.translated_local(Vector3(sd * (Landscape.ROAD_HALF + 0.35), 0.6, 0))
			var r := Build.box(Vector3(0.15, 0.9, sz.z), rail)
			r.transform = rx
			root.add_child(r)
			body.add_child(_box_shape(Vector3(0.2, 1.0, sz.z), rx))
	var mid := span[span.size() / 2]
	for gi in [span[0] + 2, mid, span[span.size() - 1] - 2]:
		root.add_child(Build.cyl(0.9, 9.0, deck_mat, road.point(gi) + Vector3.DOWN * 4.6, Vector3.ZERO, 10, "Pier"))
	poi[key] = road.point(mid)


## Where a road runs through a tunnel: walls and a roof over its slot in the
## hill, earth heaped over the roof up to the hillside, and portal faces.
func _tunnel(road_name: String) -> void:
	var road := network.road(road_name)
	if road.tunnel.is_empty():
		return
	var root := Node3D.new()
	root.name = "Tunnel_" + road_name
	world.add_child(root)
	var body := StaticBody3D.new()
	root.add_child(body)
	var concrete := ToonMat.make(Color(0.50, 0.50, 0.48))
	var earth := ToonMat.make(Landscape.GRASS_DARK.lerp(Landscape.DRY, 0.3))
	var portal := ToonMat.make(Color(0.46, 0.40, 0.36))
	const IN_W := 5.4        # half-width inside
	const IN_H := 6.2        # clear height
	var runs: Array = []
	var start := -1
	for i in road.point_count() + 1:
		var t := i < road.point_count() and road.in_tunnel(i)
		if t and start < 0:
			start = i
		elif not t and start >= 0:
			runs.append([start, i - 1])
			start = -1
	for run in runs:
		var a0: int = run[0] - 3
		var a1: int = run[1] + 3
		var i := a0
		while i < a1:
			var j := mini(i + 4, a1)
			var a := road.point(i)
			var b := road.point(j)
			var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), (a + b) * 0.5)
			var seg_len := a.distance_to(b) + 0.3
			for sd in [-1.0, 1.0]:
				var wx := xf.translated_local(Vector3(sd * (IN_W + 0.3), IN_H * 0.5, 0))
				var w := Build.box(Vector3(0.6, IN_H, seg_len), concrete)
				w.transform = wx
				root.add_child(w)
				body.add_child(_box_shape(Vector3(0.6, IN_H, seg_len), wx))
			var rx := xf.translated_local(Vector3(0, IN_H + 0.3, 0))
			var roof := Build.box(Vector3(IN_W * 2.0 + 1.2, 0.6, seg_len), concrete)
			roof.transform = rx
			root.add_child(roof)
			body.add_child(_box_shape(Vector3(IN_W * 2.0 + 1.2, 0.6, seg_len), rx))
			# earth over the roof, up to the lower of the hillsides beside it
			var c := (a + b) * 0.5
			var r := road.right(i)
			var side_h := minf(Landscape.base_height(c.x + r.x * 17.0, c.z + r.z * 17.0), Landscape.base_height(c.x - r.x * 17.0, c.z - r.z * 17.0))
			var fill := side_h - (c.y + IN_H + 0.6)
			if fill > 0.5:
				var fx := xf.translated_local(Vector3(0, IN_H + 0.6 + fill * 0.5, 0))
				var e := Build.box(Vector3(34.0, fill, seg_len), earth)
				e.transform = fx
				root.add_child(e)
				body.add_child(_box_shape(Vector3(34.0, fill, seg_len), fx))
			i = j
		# portal faces at both ends
		for end in [[a0, 1.0], [a1, -1.0]]:
			var pi: int = end[0]
			var pp := road.point(pi)
			var f := road.forward(pi) * float(end[1])
			var face_h := maxf(Landscape.base_height(pp.x, pp.z) - pp.y, IN_H + 3.0) + 2.0
			var px := Transform3D(Basis.looking_at(f, Vector3.UP), pp)
			for sd in [-1.0, 1.0]:
				var side := px.translated_local(Vector3(sd * (IN_W + 5.5), face_h * 0.5, 0))
				var sb := Build.box(Vector3(10.0, face_h, 1.2), portal)
				sb.transform = side
				root.add_child(sb)
				body.add_child(_box_shape(Vector3(10.0, face_h, 1.2), side))
			var top_h := face_h - IN_H
			var top := px.translated_local(Vector3(0, IN_H + top_h * 0.5, 0))
			var tb := Build.box(Vector3(IN_W * 2.0 + 1.0, top_h, 1.2), portal)
			tb.transform = top
			root.add_child(tb)
			var lbl := Build.label3d("OLD RAIL TUNNEL  1911", Vector3.ZERO, Vector3.ZERO, 0.6, Color(0.92, 0.88, 0.78))
			lbl.transform = px.translated_local(Vector3(0, IN_H + 1.2, 0.65))
			root.add_child(lbl)
		poi["tunnel"] = road.point((run[0] + run[1]) / 2)
		poi["tunnel_portal"] = road.point(a1 + 12)


func _naresh_home() -> void:
	var face := Vector3(NARESH_JN.x, 0, NARESH_JN.y)
	var h := _house(NARESH_HOME, face, Vector3(12, 6, 9), Color(0.95, 0.88, 0.80), Color(0.55, 0.22, 0.22), "NareshHome")
	h.add_child(Build.solid_box(Vector3(1.2, 1.0, 12), ToonMat.make(Color(0.36, 0.55, 0.30)), Vector3(-8, 0.5, 4), Vector3.ZERO, "Hedge"))
	h.add_child(Build.box(Vector3(3.0, 0.12, 2.0), ToonMat.make(Color(0.40, 0.30, 0.22)), Vector3(5, 0.06, 8), Vector3.ZERO, "Garden"))
	poi["naresh_home"] = h.position
