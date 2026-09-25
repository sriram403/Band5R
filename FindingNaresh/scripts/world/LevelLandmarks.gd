extends "res://scripts/world/LevelPlaces.gd"

## Part of LevelBuilder (see LevelLayout.gd): the Milestone A landmarks (the
## homestead, windmill, Mirror Lake, barn, lookout towers, wreck, Last Fuel,
## the water works, the radio mast, the broken bridge, the Five Roses) and the
## road signs and info boards.

func _homestead() -> void:
	var lane := network.road("home_lane")
	var origin := HOMESTEAD
	origin.y = _h(origin.x, origin.z)
	var to_lane := lane.point(6) - origin
	to_lane.y = 0.0

	var root := Node3D.new()
	root.name = "Homestead"
	root.position = origin
	root.basis = Basis.looking_at(-to_lane, Vector3.UP)   # front door faces the lane

	var wall := ToonMat.make(Color(0.93, 0.88, 0.74))
	var roof := ToonMat.make(Color(0.78, 0.34, 0.26))
	var trim := ToonMat.make(Color(0.36, 0.52, 0.68))

	root.add_child(Build.solid_box(Vector3(11, 5, 8), wall, Vector3(0, 2.5, 0), Vector3.ZERO, "House"))
	root.add_child(Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, -1.55), Vector3(-34, 0, 0), "Roof1"))
	root.add_child(Build.box(Vector3(12.6, 0.5, 5.4), roof, Vector3(0, 6.2, 1.55), Vector3(34, 0, 0), "Roof2"))
	root.add_child(Build.box(Vector3(1.2, 2.6, 0.2), trim, Vector3(-2.5, 1.3, 4.05), Vector3.ZERO, "Door"))
	root.add_child(Build.box(Vector3(1.8, 1.4, 0.2), trim, Vector3(2.0, 3.0, 4.05), Vector3.ZERO, "Window"))
	root.add_child(Build.solid_cyl(0.5, 3.0, ToonMat.make(Color(0.6, 0.35, 0.3)), Vector3(3.6, 6.4, -1.0), Vector3.ZERO, "Chimney"))
	# porch
	root.add_child(Build.solid_box(Vector3(5.0, 0.25, 2.2), ToonMat.make(C_WOOD), Vector3(-1.5, 0.12, 5.2), Vector3.ZERO, "Porch"))
	for px in [-3.8, 0.8]:
		root.add_child(Build.cyl(0.1, 2.6, ToonMat.make(C_WOOD), Vector3(px, 1.3, 6.1), Vector3.ZERO, 6, "PorchPost"))
	root.add_child(Build.box(Vector3(5.4, 0.2, 2.6), roof, Vector3(-1.5, 2.7, 5.2), Vector3(8, 0, 0), "PorchRoof"))

	root.add_child(Build.solid_box(Vector3(7, 3.4, 6), ToonMat.make(Color(0.72, 0.70, 0.66)), Vector3(-10, 1.7, 1.0), Vector3.ZERO, "Garage"))
	root.add_child(Build.box(Vector3(7.6, 0.4, 6.6), roof, Vector3(-10, 3.6, 1.0), Vector3(-6, 0, 0), "GarageRoof"))
	# washing line and a vegetable patch make it look lived in
	for lx in [6.5, 12.5]:
		root.add_child(Build.cyl(0.06, 2.2, ToonMat.make(C_WOOD), Vector3(lx, 1.1, -2.0), Vector3.ZERO, 6, "LinePost"))
	root.add_child(Build.box(Vector3(6.0, 0.02, 0.02), ToonMat.make(Color(0.9, 0.9, 0.9)), Vector3(9.5, 2.1, -2.0), Vector3.ZERO, "Line"))
	var cloth := [Color(0.85, 0.35, 0.35), Color(0.95, 0.85, 0.40), Color(0.45, 0.65, 0.90)]
	for ci in 3:
		root.add_child(Build.box(Vector3(0.9, 0.9, 0.03), ToonMat.make(cloth[ci], 0.008), Vector3(7.8 + ci * 1.6, 1.6, -2.0), Vector3.ZERO, "Laundry"))
	root.add_child(Build.box(Vector3(5.0, 0.18, 3.0), ToonMat.make(Color(0.40, 0.30, 0.22)), Vector3(9.0, 0.09, 4.0), Vector3.ZERO, "VegPatch"))

	# the parents' letter, weighed down on a crate by the porch steps
	var crate_pos := Vector3(1.6, 0, 6.8)
	root.add_child(Build.solid_box(Vector3(0.7, 0.6, 0.6), ToonMat.make(C_WOOD), crate_pos + Vector3(0, 0.3, 0), Vector3.ZERO, "LetterCrate"))
	root.add_child(Build.box(Vector3(0.30, 0.01, 0.40), ToonMat.make(Color(0.97, 0.96, 0.90), 0.004), crate_pos + Vector3(0, 0.61, 0), Vector3(0, 12, 0), "Letter"))
	root.add_child(Build.box(Vector3(0.10, 0.08, 0.10), ToonMat.make(C_STONE), crate_pos + Vector3(0.08, 0.66, 0.1), Vector3.ZERO, "Paperweight"))
	var letter_area := Build.interact_area(Vector3(1.0, 1.0, 1.0), crate_pos + Vector3(0, 0.7, 0), "Read the letter", func(p):
		var st := p.get_tree().get_first_node_in_group("story") as Story
		if st != null:
			st.read_letter(p), "LetterArea")
	root.add_child(letter_area)

	var mb := Node3D.new()
	mb.name = "Mailbox"
	mb.position = Vector3(1.0, 0, 14.0)
	mb.add_child(Build.cyl(0.09, 1.3, ToonMat.make(C_WOOD), Vector3(0, 0.65, 0), Vector3.ZERO, 8, "Post"))
	mb.add_child(Build.box(Vector3(0.4, 0.35, 0.6), ToonMat.make(Color(0.85, 0.75, 0.30)), Vector3(0, 1.45, 0), Vector3.ZERO, "Box"))
	root.add_child(mb)
	world.add_child(root)
	poi["homestead"] = origin
	poi["letter"] = root.transform * (crate_pos + Vector3(0, 0.62, 0))


## Tall farm windmill at the route choice: the junction you describe to each
## other ("left at the windmill").
func _windmill(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "Windmill"
	root.position = pos
	var steel := ToonMat.make(C_STEEL, 0.012)
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var leg := Build.cyl(0.12, 14.0, steel, Vector3(cos(a) * 1.6, 6.9, sin(a) * 1.6), Vector3.ZERO, 6, "Leg")
		leg.rotation_degrees = Vector3(sin(a) * 6.5, 0, -cos(a) * 6.5)
		root.add_child(leg)
	for hy in [3.0, 7.0, 11.0]:
		var w: float = 3.2 - hy * 0.2
		root.add_child(Build.box(Vector3(w, 0.08, 0.08), steel, Vector3(0, hy, w * 0.5), Vector3.ZERO, "Brace"))
		root.add_child(Build.box(Vector3(w, 0.08, 0.08), steel, Vector3(0, hy, -w * 0.5), Vector3.ZERO, "Brace"))
	root.add_child(Build.box(Vector3(0.6, 0.6, 1.2), ToonMat.make(Color(0.72, 0.28, 0.24)), Vector3(0, 14.2, 0), Vector3.ZERO, "Head"))
	root.add_child(Build.box(Vector3(0.08, 1.4, 2.4), ToonMat.make(Color(0.72, 0.28, 0.24)), Vector3(0, 14.2, 2.0), Vector3.ZERO, "Vane"))
	var rotor := Spinner.new()
	rotor.name = "Rotor"
	rotor.position = Vector3(0, 14.2, -0.8)
	rotor.axis = Vector3.FORWARD
	rotor.speed = 0.0             # WindmillBrake turns it
	root.add_child(rotor)
	var blade := ToonMat.make(Color(0.92, 0.92, 0.88), 0.012)
	for b in 12:
		var holder := Node3D.new()
		holder.rotation = Vector3(0, 0, TAU * b / 12.0)
		holder.add_child(Build.box(Vector3(0.35, 2.2, 0.04), blade, Vector3(0, 1.5, 0), Vector3(0, 18, 0), "Blade"))
		rotor.add_child(holder)
	root.add_child(Build.solid_cyl(1.6, 1.2, ToonMat.make(C_STONE), Vector3(3.0, 0.6, 0.0), Vector3.ZERO, "Trough"))
	# solid legs (not a solid tower: you climb inside its frame), a platform
	# under the hub where the lowest blade tip comes by, and a ladder up the back
	var body := StaticBody3D.new()
	body.name = "TowerBody"
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var cs := CollisionShape3D.new()
		var cyl := CylinderShape3D.new()
		cyl.radius = 0.14
		cyl.height = 14.0
		cs.shape = cyl
		cs.position = Vector3(cos(a) * 1.6, 6.9, sin(a) * 1.6)
		cs.rotation_degrees = Vector3(sin(a) * 6.5, 0, -cos(a) * 6.5)
		body.add_child(cs)
	var deck := ToonMat.make(C_WOOD, 0.012)
	const PLAT_Y := 11.3
	root.add_child(Build.box(Vector3(2.6, 0.15, 2.2), deck, Vector3(0, PLAT_Y, 0.5), Vector3.ZERO, "Platform"))
	body.add_child(_box_shape(Vector3(2.6, 0.15, 2.2), Transform3D(Basis(), Vector3(0, PLAT_Y, 0.5))))
	for spec in [[Vector3(0.06, 1.0, 2.2), Vector3(-1.3, PLAT_Y + 0.55, 0.5)], [Vector3(0.06, 1.0, 2.2), Vector3(1.3, PLAT_Y + 0.55, 0.5)],
			[Vector3(2.6, 1.0, 0.06), Vector3(0, PLAT_Y + 0.55, -0.55)],
			[Vector3(0.9, 1.0, 0.06), Vector3(-0.85, PLAT_Y + 0.55, 1.6)], [Vector3(0.9, 1.0, 0.06), Vector3(0.85, PLAT_Y + 0.55, 1.6)]]:
		var sz: Vector3 = spec[0]
		var rail_at: Vector3 = spec[1]
		root.add_child(Build.box(Vector3(sz.x, 0.06, sz.z), steel, rail_at + Vector3(0, 0.45, 0), Vector3.ZERO, "Rail"))
		body.add_child(_box_shape(sz, Transform3D(Basis(), rail_at)))
	root.add_child(body)
	Ladder.make(root, Vector3(0, 0, 1.75), PLAT_Y + 0.15, Vector3(0, 0, -1), Vector3(0, PLAT_Y + 0.1, 1.0), "WindmillLadder")
	# the puzzle: brake lever and miller's box out front, where the blades show
	var lever_at := Vector3(-3.2, 0, -3.6)
	var box_at := Vector3(3.2, 0, -3.2)
	lever_at.y = _h(pos.x + lever_at.x, pos.z + lever_at.z) - pos.y
	box_at.y = _h(pos.x + box_at.x, pos.z + box_at.z) - pos.y
	var puzzle := WindmillBrake.new()
	puzzle.name = "WindmillBrake"
	root.add_child(puzzle)
	puzzle.setup(rotor, lever_at, box_at)
	world.add_child(root)
	poi["windmill"] = pos
	poi["windmill_ladder"] = pos + Vector3(0, 0, 2.6)
	poi["windmill_platform"] = pos + Vector3(0, PLAT_Y + 0.2, 0.3)
	poi["windmill_lever"] = pos + lever_at
	poi["windmill_box"] = pos + box_at


func _junction_signpost() -> void:
	var pos := Vector3(J1.x - 8.0, 0, J1.y + 9.0)
	pos.y = _h(pos.x, pos.z)
	var n := Node3D.new()
	n.name = "JunctionSign"
	n.position = pos
	n.add_child(Build.cyl(0.1, 3.4, ToonMat.make(C_WOOD), Vector3(0, 1.7, 0), Vector3.ZERO, 8, "Post"))
	var valley_dir := network.road("valley_road").forward(8)
	var ridge_dir := network.road("ridge_track").forward(8)
	_arrow_board(n, "VALLEY RD  >\nscenic, easy going", valley_dir, 2.9, Color(0.93, 0.90, 0.80))
	_arrow_board(n, "RIDGE TRACK  >\nshorter, steep gravel", ridge_dir, 2.3, Color(0.86, 0.72, 0.52))
	world.add_child(n)


func _arrow_board(parent: Node3D, text: String, dir: Vector3, y: float, col: Color) -> void:
	var holder := Node3D.new()
	var d := Vector3(dir.x, 0, dir.z).normalized()
	holder.basis = Basis.looking_at(Vector3(-d.z, 0, d.x), Vector3.UP)   # board runs along the road
	holder.position = Vector3(0, y, 0)
	holder.add_child(Build.box(Vector3(2.2, 0.55, 0.08), ToonMat.make(col, 0.01), Vector3(1.1, 0, 0), Vector3.ZERO, "Board"))
	holder.add_child(Build.label3d(text, Vector3(1.1, 0, 0.05), Vector3.ZERO, 0.16, Color(0.20, 0.22, 0.28)))
	var back := Build.label3d(text, Vector3(1.1, 0, -0.05), Vector3(0, 180, 0), 0.16, Color(0.20, 0.22, 0.28))
	holder.add_child(back)
	parent.add_child(holder)


func _mirror_lake_dock() -> void:
	var lake: Dictionary = PONDS[0]
	var c: Vector3 = lake["pos"]
	var shore_dir := DOCK_DIR.normalized()                    # west shore, toward the road
	var water_r := Landscape.pond_water_radius(float(lake["radius"]))
	var start := c + shore_dir * (water_r + 3.0)
	start.y = _h(start.x, start.z)
	var water_y := Landscape.base_height(c.x, c.z) + float(lake["depth"]) * 0.4
	var root := Node3D.new()
	root.name = "Dock"
	root.position = Vector3(start.x, maxf(start.y, water_y) + 0.35, start.z)
	root.basis = Basis.looking_at(-shore_dir, Vector3.UP)
	var wood := ToonMat.make(C_WOOD, 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	var deck_len := 16.0
	root.add_child(Build.box(Vector3(2.4, 0.18, deck_len), wood, Vector3(0, 0, -deck_len * 0.5), Vector3.ZERO, "Deck"))
	body.add_child(_box_shape(Vector3(2.4, 0.18, deck_len), Transform3D(Basis(), Vector3(0, 0, -deck_len * 0.5))))
	for k in 5:
		for sx in [-1.1, 1.1]:
			root.add_child(Build.cyl(0.12, 3.0, wood, Vector3(sx, -1.4, -2.0 - k * 3.4), Vector3.ZERO, 6, "Pile"))
	# a rowboat tied at the end
	var boat := Node3D.new()
	boat.position = Vector3(2.4, water_y - root.position.y + 0.15, -deck_len + 2.0)
	boat.add_child(Build.box(Vector3(1.3, 0.45, 3.4), ToonMat.make(Color(0.30, 0.52, 0.66)), Vector3.ZERO, Vector3.ZERO, "Hull"))
	boat.add_child(Build.box(Vector3(1.1, 0.06, 0.3), wood, Vector3(0, 0.2, 0.3), Vector3.ZERO, "Seat"))
	root.add_child(boat)
	world.add_child(root)
	poi["dock"] = root.position


## Faded roadside billboard for the attraction: the first time the players
## see what Bessi was supposed to be.
func _billboard() -> void:
	var road := network.road("valley_road")
	var i := 250
	var p := road.point(i) - road.right(i) * 12.0
	p.y = _h(p.x, p.z)
	var root := Node3D.new()
	root.name = "Billboard"
	root.position = p
	# Basis.looking_at points -Z at the target; the lettering is on +Z, so aim
	# -Z away from the road to turn the face toward approaching drivers.
	root.basis = Basis.looking_at(-(road.right(i) - road.forward(i) * 0.6), Vector3.UP)
	var wood := ToonMat.make(C_WOOD)
	for sx in [-3.5, 3.5]:
		root.add_child(Build.cyl(0.18, 6.0, wood, Vector3(sx, 3.0, 0), Vector3.ZERO, 8, "Leg"))
	root.add_child(Build.box(Vector3(10.0, 4.4, 0.25), ToonMat.make(Color(0.96, 0.80, 0.82)), Vector3(0, 6.6, 0), Vector3.ZERO, "Panel"))
	root.add_child(Build.label3d("BESSI & THE 5 ROSES", Vector3(0, 7.7, 0.16), Vector3.ZERO, 0.85, Color(0.72, 0.12, 0.26)))
	root.add_child(Build.label3d("the wonder of the valley  -  1 km", Vector3(0, 6.6, 0.16), Vector3.ZERO, 0.45, Color(0.35, 0.22, 0.30)))
	root.add_child(Build.label3d("BRING A FRIEND!", Vector3(0, 5.5, 0.16), Vector3.ZERO, 0.55, Color(0.20, 0.45, 0.35)))
	for k in 5:
		root.add_child(Build.sphere(0.45, ToonMat.make(C_ROSE, 0.01), Vector3(-4.0 + k * 2.0, 8.55, 0.2), Vector3(1, 1, 0.4), "PaintedRose"))
	world.add_child(root)
	poi["billboard"] = p


func _barn(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "Barn"
	root.position = pos
	root.rotation_degrees = Vector3(0, 28, 0)

	var red := ToonMat.make(Color(0.70, 0.24, 0.20))
	var white := ToonMat.make(Color(0.92, 0.90, 0.84))
	root.add_child(Build.solid_box(Vector3(16, 7, 11), red, Vector3(0, 3.5, 0), Vector3.ZERO, "BarnBody"))
	root.add_child(Build.box(Vector3(17.6, 0.6, 7.4), ToonMat.make(Color(0.42, 0.30, 0.26)), Vector3(0, 8.6, -2.1), Vector3(-38, 0, 0), "RoofA"))
	root.add_child(Build.box(Vector3(17.6, 0.6, 7.4), ToonMat.make(Color(0.42, 0.30, 0.26)), Vector3(0, 8.6, 2.1), Vector3(38, 0, 0), "RoofB"))
	root.add_child(Build.box(Vector3(4.4, 5.0, 0.2), white, Vector3(0, 2.5, 5.55), Vector3.ZERO, "Doors"))
	root.add_child(Build.solid_cyl(2.6, 13.0, ToonMat.make(Color(0.80, 0.78, 0.72)), Vector3(11.0, 6.5, -2.0), Vector3.ZERO, "Silo"))
	root.add_child(Build.dome(2.7, ToonMat.make(Color(0.60, 0.62, 0.64)), Vector3(11.0, 13.0, -2.0), Vector3.ONE, "SiloCap"))
	# hay bales out front
	for hb in 4:
		root.add_child(Build.solid_cyl(0.8, 1.2, ToonMat.make(Color(0.86, 0.74, 0.40)), Vector3(-5.0 + hb * 1.9, 0.8, 9.0), Vector3(0, 0, 90), "Hay"))
	world.add_child(root)
	poi["barn"] = pos


## Timber lookout tower on the crest of Pine Ridge: a deck 6 m up, reached by
## a walkable ramp, high enough to see over the trees to the river and the
## roses. The deck faces Bessi (-Z).
func _lookout(at: Vector3, DECK_H := 6.0, nm := "Lookout", label := "PINE RIDGE\nLOOKOUT", face := ROSE_CENTRE,
		key := "lookout") -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = nm
	root.position = pos
	var to_bessi := face - pos
	to_bessi.y = 0.0
	root.basis = Basis.looking_at(to_bessi, Vector3.UP)
	var wood := ToonMat.make(C_WOOD, 0.012)
	var dark := ToonMat.make(Color(0.40, 0.28, 0.18), 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	# legs and cross braces
	for lx in [-2.8, 2.8]:
		for lz in [-2.3, 2.3]:
			root.add_child(Build.cyl(0.16, DECK_H + 0.4, dark, Vector3(lx, (DECK_H + 0.4) * 0.5 - 0.4, lz), Vector3.ZERO, 6, "Leg"))
			body.add_child(_cyl_shape(Vector3(lx, DECK_H * 0.5, lz), 0.16, DECK_H))
	for bz in [-2.3, 2.3]:
		root.add_child(Build.box(Vector3(5.6, 0.1, 0.1), dark, Vector3(0, DECK_H * 0.45, bz), Vector3(0, 0, 38), "Brace"))
	# deck
	root.add_child(Build.box(Vector3(6.4, 0.25, 5.2), wood, Vector3(0, DECK_H, 0), Vector3.ZERO, "Deck"))
	body.add_child(_box_shape(Vector3(6.4, 0.25, 5.2), Transform3D(Basis(), Vector3(0, DECK_H, 0))))
	# Ramp from the back of the deck down to the real ground at its foot, at a
	# walkable ~28 degrees. The crest falls away behind the tower, so the run is
	# solved against the actual ground height there, not the tower's base.
	var slope := tan(deg_to_rad(28.0))
	var run := DECK_H / slope
	var foot_rel := 0.0
	for _k in 4:
		var fw := root.transform * Vector3(0, 0, 2.6 + run)
		foot_rel = _h(fw.x, fw.z) - pos.y
		run = (DECK_H - foot_rel) / slope
	var rise := DECK_H - foot_rel
	var ramp_len := sqrt(run * run + rise * rise) + 1.0
	var ang := atan2(rise, run)
	var ramp_xf := Transform3D(Basis(Vector3.RIGHT, ang), Vector3(0, (DECK_H + foot_rel) * 0.5 - 0.12, 2.6 + run * 0.5))
	var ramp := Build.box(Vector3(1.8, 0.2, ramp_len), wood)
	ramp.transform = ramp_xf
	root.add_child(ramp)
	body.add_child(_box_shape(Vector3(1.8, 0.2, ramp_len), ramp_xf))
	for sx in [-0.95, 0.95]:
		var rail_xf := Transform3D(Basis(Vector3.RIGHT, ang), Vector3(sx, (DECK_H + foot_rel) * 0.5 + 0.85, 2.6 + run * 0.5))
		var rail := Build.box(Vector3(0.08, 0.08, ramp_len), wood)
		rail.transform = rail_xf
		root.add_child(rail)
		body.add_child(_box_shape(Vector3(0.1, 1.0, ramp_len), rail_xf.translated_local(Vector3(0, -0.4, 0))))
	# open railing on the three outward sides of the deck
	var rail_y := DECK_H + 1.0
	root.add_child(Build.box(Vector3(6.4, 0.08, 0.08), wood, Vector3(0, rail_y, -2.6), Vector3.ZERO, "RailFront"))
	body.add_child(_box_shape(Vector3(6.4, 1.0, 0.1), Transform3D(Basis(), Vector3(0, DECK_H + 0.6, -2.6))))
	for sx in [-3.2, 3.2]:
		root.add_child(Build.box(Vector3(0.08, 0.08, 5.2), wood, Vector3(sx, rail_y, 0), Vector3.ZERO, "RailSide"))
		body.add_child(_box_shape(Vector3(0.1, 1.0, 5.2), Transform3D(Basis(), Vector3(sx, DECK_H + 0.6, 0))))
	for px in [-3.2, -1.1, 1.1, 3.2]:
		root.add_child(Build.box(Vector3(0.08, 1.0, 0.08), wood, Vector3(px, DECK_H + 0.55, -2.6), Vector3.ZERO, "RailPost"))
	root.add_child(Build.box(Vector3(2.2, 0.12, 0.5), wood, Vector3(-1.6, DECK_H + 0.5, 1.6), Vector3.ZERO, "Bench"))
	root.add_child(Build.cyl(0.08, 1.2, ToonMat.make(C_STEEL), Vector3(1.8, DECK_H + 0.7, -1.9), Vector3.ZERO, 6, "ScopePost"))
	root.add_child(Build.cyl(0.14, 0.55, ToonMat.make(Color(0.30, 0.50, 0.40)), Vector3(1.8, DECK_H + 1.35, -2.05), Vector3(-80, 0, 0), 8, "Scope"))
	# pitched roof
	for rs in [-1.0, 1.0]:
		root.add_child(Build.box(Vector3(3.6, 0.15, 5.8), ToonMat.make(Color(0.36, 0.44, 0.30)), Vector3(rs * 1.6, DECK_H + 3.2, 0), Vector3(0, 0, -rs * 22), "Roof"))
	for lx in [-2.8, 2.8]:
		for lz in [-2.3, 2.3]:
			root.add_child(Build.cyl(0.08, 2.6, dark, Vector3(lx, DECK_H + 1.4, lz), Vector3.ZERO, 6, "RoofPost"))
	var sign_n := Node3D.new()
	sign_n.position = Vector3(2.2, foot_rel, 2.6 + run + 1.0)
	sign_n.add_child(Build.cyl(0.08, 2.0, wood, Vector3(0, 1.0, 0), Vector3.ZERO, 6, "Post"))
	sign_n.add_child(Build.box(Vector3(1.8, 0.6, 0.08), ToonMat.make(Color(0.34, 0.46, 0.30)), Vector3(0, 1.9, 0), Vector3.ZERO, "Board"))
	sign_n.add_child(Build.label3d(label, Vector3(0, 1.9, 0.05), Vector3.ZERO, 0.2, Color(0.95, 0.92, 0.80)))
	root.add_child(sign_n)
	# the legs of a tall tower need to reach the deck
	if DECK_H > 6.5:
		for lx in [-2.8, 2.8]:
			for lz in [-2.3, 2.3]:
				body.add_child(_cyl_shape(Vector3(lx, DECK_H * 0.5, lz), 0.2, DECK_H))
	world.add_child(root)
	poi[key] = pos
	poi[key + "_deck"] = root.transform * Vector3(0, DECK_H + 0.2, -0.5)
	poi[key + "_ramp_foot"] = root.transform * Vector3(0, 0, 2.6 + run + 1.5)


## A rusted car on its roof beside the ridge track: the track is not kind.
func _wreck() -> void:
	var road := network.road("ridge_track")
	var i := 250
	var p := road.point(i) + road.right(i) * 9.0
	p.y = _h(p.x, p.z)
	var root := Node3D.new()
	root.name = "Wreck"
	root.position = p
	root.basis = Basis(Vector3.UP, 0.7) * Basis(Vector3.FORWARD, PI * 0.92)
	var rust := ToonMat.make(C_RUST)
	root.add_child(Build.box(Vector3(1.8, 0.8, 4.2), rust, Vector3(0, -0.5, 0), Vector3.ZERO, "Body"))
	root.add_child(Build.box(Vector3(1.6, 0.6, 2.2), ToonMat.make(Color(0.45, 0.28, 0.20)), Vector3(0, -1.15, -0.2), Vector3.ZERO, "Cab"))
	for wx in [-0.95, 0.95]:
		for wz in [-1.4, 1.4]:
			root.add_child(Build.cyl(0.36, 0.25, ToonMat.make(Color(0.14, 0.14, 0.15)), Vector3(wx, 0.05, wz), Vector3(0, 0, 90), 10, "Wheel"))
	var body := StaticBody3D.new()
	body.add_child(_box_shape(Vector3(1.8, 1.4, 4.2), Transform3D(Basis(), Vector3(0, -0.8, 0))))
	root.add_child(body)
	world.add_child(root)
	poi["wreck"] = p


## Abandoned fuel station where the two routes rejoin.
func _gas_station(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "LastFuel"
	root.position = pos
	var road := network.road("pump_house_road")
	var f := road.forward(6)
	root.basis = Basis.looking_at(Vector3(f.z, 0, -f.x), Vector3.UP)   # forecourt faces the road
	var white := ToonMat.make(Color(0.90, 0.88, 0.82))
	var red := ToonMat.make(Color(0.78, 0.22, 0.20))
	var body := StaticBody3D.new()
	root.add_child(body)
	root.add_child(Build.box(Vector3(14.0, 0.15, 10.0), ToonMat.make(Color(0.42, 0.42, 0.44)), Vector3(0, 0.08, 0), Vector3.ZERO, "Forecourt"))
	root.add_child(Build.box(Vector3(12.0, 0.5, 7.0), white, Vector3(0, 4.6, 0), Vector3.ZERO, "Canopy"))
	root.add_child(Build.box(Vector3(12.2, 0.3, 7.2), red, Vector3(0, 4.25, 0), Vector3.ZERO, "CanopyStripe"))
	for cx in [-5.0, 5.0]:
		root.add_child(Build.cyl(0.2, 4.4, white, Vector3(cx, 2.2, 0), Vector3.ZERO, 8, "Column"))
		body.add_child(_cyl_shape(Vector3(cx, 2.2, 0), 0.2, 4.4))
	for px in [-1.8, 1.8]:
		root.add_child(Build.box(Vector3(0.8, 1.6, 0.5), red, Vector3(px, 0.95, 0), Vector3.ZERO, "Pump"))
		root.add_child(Build.box(Vector3(0.6, 0.35, 0.02), ToonMat.flat(Color(0.12, 0.14, 0.14)), Vector3(px, 1.35, 0.26), Vector3.ZERO, "PumpDisplay"))
		body.add_child(_box_shape(Vector3(0.8, 1.6, 0.5), Transform3D(Basis(), Vector3(px, 0.95, 0))))
	root.add_child(Build.solid_box(Vector3(6.0, 3.2, 4.5), white, Vector3(0, 1.6, -8.0), Vector3.ZERO, "Kiosk"))
	root.add_child(Build.box(Vector3(2.4, 1.2, 0.05), ToonMat.make(Color(0.32, 0.46, 0.56)), Vector3(-1.2, 1.7, -5.73), Vector3.ZERO, "KioskWindow"))
	var sign_n := Node3D.new()
	sign_n.position = Vector3(7.5, 0, 5.0)
	sign_n.add_child(Build.cyl(0.14, 7.0, ToonMat.make(C_STEEL), Vector3(0, 3.5, 0), Vector3.ZERO, 8, "Pole"))
	sign_n.add_child(Build.box(Vector3(3.2, 1.6, 0.25), red, Vector3(0, 7.2, 0), Vector3.ZERO, "Sign"))
	sign_n.add_child(Build.label3d("LAST FUEL", Vector3(0, 7.35, 0.14), Vector3.ZERO, 0.5, Color(0.98, 0.95, 0.85)))
	sign_n.add_child(Build.label3d("CLOSED", Vector3(0, 6.75, 0.14), Vector3.ZERO, 0.3, Color(0.98, 0.95, 0.85)))
	root.add_child(sign_n)
	world.add_child(root)
	poi["gas_station"] = pos


## The Bessi water works: pump house, tanks and pipes down to the river. The
## cooling-station puzzle (A5) is built into this site.
func _water_facility(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "WaterFacility"
	root.position = pos
	var rp := _snap(river, Vector2(at.x, at.z))
	var to_river := Vector3(rp.x - at.x, 0, rp.z - at.z)
	root.basis = Basis.looking_at(to_river, Vector3.UP)     # -Z points at the river
	var brick := ToonMat.make(Color(0.66, 0.40, 0.32))
	var concrete := ToonMat.make(Color(0.70, 0.70, 0.68))
	var pipe := ToonMat.make(Color(0.36, 0.52, 0.60), 0.012)
	var body := StaticBody3D.new()
	root.add_child(body)
	root.add_child(Build.box(Vector3(24.0, 0.2, 20.0), concrete, Vector3(0, 0.1, 0), Vector3.ZERO, "Yard"))
	root.add_child(Build.solid_box(Vector3(9.0, 5.0, 7.0), brick, Vector3(-5.0, 2.5, 4.0), Vector3.ZERO, "PumpHouse"))
	root.add_child(Build.box(Vector3(9.8, 0.4, 7.8), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(-5.0, 5.2, 4.0), Vector3.ZERO, "PumpHouseRoof"))
	root.add_child(Build.box(Vector3(2.2, 3.0, 0.15), ToonMat.make(Color(0.30, 0.44, 0.40)), Vector3(-5.0, 1.5, 0.45), Vector3.ZERO, "PumpHouseDoor"))
	for t in 2:
		var tp := Vector3(5.0 + t * 5.5, 0, 5.0)
		root.add_child(Build.solid_cyl(2.2, 5.5, concrete, tp + Vector3(0, 2.75, 0), Vector3.ZERO, "Tank%d" % t))
		root.add_child(Build.dome(2.25, ToonMat.make(Color(0.56, 0.58, 0.60)), tp + Vector3(0, 5.5, 0), Vector3.ONE, "TankCap"))
	# intake pipes running from the pump house to the river
	for k in 2:
		var px := -6.0 + k * 2.0
		root.add_child(Build.cyl(0.35, 28.0, pipe, Vector3(px, 0.6, -14.0), Vector3(90, 0, 0), 10, "Intake"))
		body.add_child(_box_shape(Vector3(0.7, 0.7, 28.0), Transform3D(Basis(), Vector3(px, 0.6, -14.0))))
	root.add_child(Build.cyl(0.3, 11.0, pipe, Vector3(1.0, 3.0, 5.0), Vector3(0, 0, 90), 10, "TankFeed"))
	# the water tower from the prototype now belongs here
	var tower := Node3D.new()
	tower.position = Vector3(-12.0, 0, -6.0)
	for k in 4:
		var a := TAU * k / 4.0 + PI * 0.25
		var leg := Build.cyl(0.22, 15.0, ToonMat.make(C_STEEL), Vector3(cos(a) * 3.4, 7.0, sin(a) * 3.4), Vector3.ZERO, 8, "Leg%d" % k)
		leg.rotation_degrees = Vector3(sin(a) * 6.0, 0, -cos(a) * 6.0)
		tower.add_child(leg)
	tower.add_child(Build.cyl(4.6, 6.0, ToonMat.make(Color(0.86, 0.84, 0.78)), Vector3(0, 17.5, 0), Vector3.ZERO, 18, "Tank"))
	tower.add_child(Build.cone(4.9, 2.4, ToonMat.make(Color(0.72, 0.36, 0.30)), Vector3(0, 21.7, 0), Vector3.ZERO, 18, "TankRoof"))
	for side in [1.0, -1.0]:
		tower.add_child(Build.label3d("BESSI WATER CO.", Vector3(0, 17.8, 4.75 * side), Vector3(0, 0 if side > 0 else 180, 0), 0.9, Color(0.25, 0.30, 0.38)))
	body.add_child(_cyl_shape(Vector3(-12.0, 7.0, -6.0), 3.6, 14.0))
	root.add_child(tower)
	# the cooling-station puzzle lives in this yard
	var station := CoolingStation.new()
	station.name = "CoolingStation"
	root.add_child(station)

	# a low tool shed, clear of the intake pipes; something glints on its
	# roof (optional: stack crates)
	# roof top at 1.31 m: one crate (0.45) is not enough to jump up, two stacked (0.9) are
	root.add_child(Build.solid_box(Vector3(3.0, 1.25, 2.4), ToonMat.make(Color(0.52, 0.46, 0.38)), Vector3(-1.8, 0.625, -7.5), Vector3.ZERO, "ToolShed"))
	root.add_child(Build.box(Vector3(3.3, 0.12, 2.7), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(-1.8, 1.25, -7.5), Vector3.ZERO, "ShedRoof"))

	# visitor log by the pump house door
	root.add_child(Build.box(Vector3(0.45, 0.6, 0.12), ToonMat.make(Color(0.40, 0.30, 0.20)), Vector3(-7.8, 1.4, 0.4), Vector3.ZERO, "LogBox"))
	var log_area := Build.interact_area(Vector3(0.9, 1.0, 0.9), Vector3(-7.8, 1.4, 0.0), "Read the visitor log", func(p):
		p.say("VISITOR LOG - Bessi Water Co.\n\nThe last entry, nine days ago, in Naresh's handwriting:\n\"Naresh K.  -  passing through to Bessi  -  party of 2\"\n\nThe \"2\" has been scratched out and written over as a \"1\". Then scratched out again, and a \"2\" pressed so hard the pen went through the page.", 12.0), "LogArea")
	root.add_child(log_area)

	# a campsite down toward the river: one sleeping bag, two mugs
	var camp := Node3D.new()
	camp.name = "Campsite"
	camp.position = Vector3(3.0, 0, -18.0)
	root.add_child(camp)
	camp.add_child(Build.box(Vector3(0.8, 0.18, 2.0), ToonMat.make(Color(0.25, 0.45, 0.30)), Vector3(0, 0.09, 0), Vector3.ZERO, "SleepingBag"))
	for k in 5:
		var a := TAU * k / 5.0
		camp.add_child(Build.sphere(0.18, ToonMat.make(C_ROCK), Vector3(1.6 + cos(a) * 0.45, 0.08, sin(a) * 0.45), Vector3(1, 0.6, 1), "FireStone"))
	camp.add_child(Build.box(Vector3(0.5, 0.06, 0.5), ToonMat.make(Color(0.15, 0.13, 0.12)), Vector3(1.6, 0.03, 0), Vector3.ZERO, "Ashes"))
	for mx in [0.9, 1.1]:
		camp.add_child(Build.cyl(0.05, 0.1, ToonMat.make(Color(0.85, 0.3, 0.3) if mx < 1.0 else Color(0.3, 0.5, 0.85)), Vector3(mx, 0.05, 0.9), Vector3.ZERO, 8, "Mug"))
	var camp_area := Build.interact_area(Vector3(3.5, 1.2, 3.0), Vector3(0.8, 0.6, 0.3), "Look around the campsite", func(p):
		p.say("A cold fire ring. One sleeping bag, rolled out neatly - only one.\nTwo mugs, both used, set side by side as if for a conversation.\nScratched into a stone: N + ", 10.0), "CampArea")
	camp.add_child(camp_area)

	# chain-link fence on the road side, with a gate gap
	for fx in range(-11, 12, 2):
		if absf(fx) < 3:
			continue
		root.add_child(Build.cyl(0.05, 2.0, ToonMat.make(C_STEEL), Vector3(fx, 1.0, 10.0), Vector3.ZERO, 5, "FencePost"))
	world.add_child(root)
	poi["facility"] = pos
	poi["pump_handle"] = root.transform * (CoolingStation.PUMP_POS + Vector3(0, 0.9, 0))
	poi["valve_a"] = root.transform * (CoolingStation.A_POS + Vector3(0, 1.0, 0))
	poi["valve_b"] = root.transform * (CoolingStation.B_POS + Vector3(0, 1.0, 0))
	poi["shed_roof"] = root.transform * Vector3(-1.8, 1.31, -7.5)
	poi["radiator_yard"] = root.transform * Vector3(0, 0, -6.0)


func _radio_mast(at: Vector3) -> void:
	var pos := at
	pos.y = _h(pos.x, pos.z)
	var root := Node3D.new()
	root.name = "RadioMast"
	root.position = pos
	var steel := ToonMat.make(Color(0.80, 0.30, 0.26), 0.012)
	var white := ToonMat.make(Color(0.92, 0.92, 0.90), 0.012)
	var h := 42.0
	for seg in 7:
		root.add_child(Build.cyl(0.6 - seg * 0.06, h / 7.0, steel if seg % 2 == 0 else white, Vector3(0, h / 7.0 * (seg + 0.5), 0), Vector3.ZERO, 6, "Seg"))
	root.add_child(Build.solid_box(Vector3(4.0, 2.8, 3.0), ToonMat.make(Color(0.70, 0.70, 0.66)), Vector3(4.0, 1.4, 0), Vector3.ZERO, "Hut"))
	var beacon := Spinner.new()
	beacon.name = "Beacon"
	beacon.blink_period = 1.6
	beacon.position = Vector3(0, h + 0.4, 0)
	beacon.add_child(Build.sphere(0.5, ToonMat.make(Color(1.0, 0.2, 0.15), 0.0, 0.5, Color(1.0, 0.15, 0.1)), Vector3.ZERO, Vector3.ONE, "Light"))
	root.add_child(beacon)
	var body := StaticBody3D.new()
	body.add_child(_cyl_shape(Vector3(0, h * 0.5, 0), 0.6, h))
	root.add_child(body)
	world.add_child(root)
	poi["radio_mast"] = pos


## Where Pump House Road crosses the river: an old timber bridge with its middle
## span gone. Decks either side are solid; the gap is not. Barriers and signs
## stop the van before it gets there (milestone B turns this into a puzzle).
func _broken_bridge() -> void:
	var road := network.road("pump_house_road")
	var root := Node3D.new()
	root.name = "BrokenBridge"
	world.add_child(root)
	var body := StaticBody3D.new()
	body.name = "BridgeDeck"
	root.add_child(body)
	var wood := ToonMat.make(Color(0.50, 0.36, 0.24), 0.012)
	var span_idx: Array[int] = []
	for i in road.point_count():
		var p := road.point(i)
		if Landscape.river_distance(p.x, p.z) < Landscape.RIVER_HALF + 7.0:
			span_idx.append(i)
	if span_idx.is_empty():
		push_warning("Pump House Road never crosses the river")
		return
	var first := span_idx[0]
	var last := span_idx[span_idx.size() - 1]
	var mid := (first + last) / 2
	for i in range(first - 1, last + 1):
		if absi(i - mid) <= 2:
			continue               # the missing middle span
		var a := road.point(i)
		var b := road.point(i + 1)
		var c := (a + b) * 0.5
		var xf := Transform3D(Basis.looking_at(b - a, Vector3.UP), c + Vector3.UP * 0.02)
		var plank := Build.box(Vector3(Landscape.ROAD_HALF * 2.0 + 0.6, 0.3, a.distance_to(b) + 0.05), wood)
		plank.transform = xf
		root.add_child(plank)
		body.add_child(_box_shape(Vector3(Landscape.ROAD_HALF * 2.0 + 0.6, 0.3, a.distance_to(b) + 0.05), xf))
		if i % 2 == 0:
			for s in [-1.0, 1.0]:
				var post := Build.cyl(0.12, 1.2, wood, c + road.right(i) * s * (Landscape.ROAD_HALF + 0.2) + Vector3.UP * 0.6, Vector3.ZERO, 6, "RailPost")
				root.add_child(post)
	# piers under the ends of the gap, snapped timbers hanging into the water
	for gi in [mid - 3, mid + 3]:
		var gp := road.point(gi)
		root.add_child(Build.cyl(0.5, 7.0, wood, gp + Vector3.DOWN * 3.5, Vector3.ZERO, 8, "Pier"))
		var hang := Build.box(Vector3(Landscape.ROAD_HALF * 1.6, 0.25, 3.0), wood, gp + Vector3.DOWN * 1.2, Vector3.ZERO, "Snapped")
		hang.basis = Basis.looking_at(road.forward(gi), Vector3.UP) * Basis(Vector3.RIGHT, deg_to_rad(40 if gi < mid else -40))
		root.add_child(hang)
	# barrier and warning signs on both approaches
	for end in [[first - 14, 1.0], [last + 14, -1.0]]:
		var bi: int = end[0]
		var bp := road.point(bi)
		var fwd := road.forward(bi) * float(end[1])
		var bx := Transform3D(Basis.looking_at(fwd, Vector3.UP), bp + Vector3.UP * 0.5)
		var bar := Build.box(Vector3(Landscape.ROAD_HALF * 2.0, 0.25, 0.2), ToonMat.make(Color(0.95, 0.55, 0.15)), Vector3.ZERO, Vector3.ZERO, "Barrier")
		bar.transform = bx.translated_local(Vector3(0, 0.6, 0))
		root.add_child(bar)
		for s in [-1.0, 1.0]:
			root.add_child(Build.cyl(0.08, 1.2, ToonMat.make(C_STEEL), bp + road.right(bi) * s * 3.6 + Vector3.UP * 0.6, Vector3.ZERO, 6, "BarrierLeg"))
		body.add_child(_box_shape(Vector3(Landscape.ROAD_HALF * 2.0, 1.2, 0.3), bx.translated_local(Vector3(0, 0.1, 0))))
		var sign_n := Node3D.new()
		sign_n.transform = Transform3D(Basis.looking_at(fwd, Vector3.UP), bp + road.right(bi) * 5.5)
		sign_n.add_child(Build.cyl(0.07, 2.4, ToonMat.make(C_STEEL), Vector3(0, 1.2, 0), Vector3.ZERO, 6, "Post"))
		sign_n.add_child(Build.box(Vector3(1.8, 1.0, 0.06), ToonMat.make(Color(0.98, 0.82, 0.20)), Vector3(0, 2.3, 0), Vector3.ZERO, "Plate"))
		sign_n.add_child(Build.label3d("BRIDGE\nOUT", Vector3(0, 2.3, 0.05), Vector3.ZERO, 0.32, Color(0.15, 0.12, 0.10)))
		root.add_child(sign_n)
	poi["bridge"] = road.point(mid)
	poi["bridge_barrier_near"] = road.point(first - 14)


## The destination silhouette: five giant rose monuments on the central hill.
func _five_roses(at: Vector3) -> void:
	var root := Node3D.new()
	root.name = "FiveRoses"
	world.add_child(root)

	var centre := at
	centre.y = Landscape.plateau_height(MOUNDS[0])

	# Stone plaza, flush with the plateau: its top is a low 8 cm lip the
	# player's capsule rolls straight over.
	const PLAZA_R := 30.0
	const PLAZA_TOP := 0.08
	var solid := StaticBody3D.new()
	solid.name = "RosesSolid"
	root.add_child(solid)
	root.add_child(Build.cyl(PLAZA_R, 0.6, ToonMat.make(C_STONE, 0.03), centre + Vector3(0, PLAZA_TOP - 0.3, 0), Vector3.ZERO, 40, "Plaza"))
	solid.add_child(_cyl_shape(centre + Vector3(0, PLAZA_TOP - 0.3, 0), PLAZA_R, 0.6))

	for k in 5:
		var a := TAU * float(k) / 5.0 - PI * 0.5
		var p := centre + Vector3(cos(a) * 22.0, PLAZA_TOP, sin(a) * 22.0)
		var sc := 2.4 + k * 0.10
		root.add_child(_rose_monument(p, sc, a))
		# plinth and stem are solid; the bloom overhead does not need to be
		solid.add_child(_cyl_shape(p + Vector3(0, 0.5 * sc, 0), 1.6 * sc, 1.0 * sc))
		solid.add_child(_cyl_shape(p + Vector3(0, 6.6 * sc, 0), 0.42 * sc, 12.0 * sc))

	# welcome sign on the side facing the road in from the bridge
	var join: Vector3 = poi["bessi_join"]
	var to_join := join - centre
	to_join.y = 0.0
	var sign_pos := centre + to_join.normalized() * 34.0
	sign_pos.y = _h(sign_pos.x, sign_pos.z)
	var s := Node3D.new()
	s.name = "WelcomeSign"
	s.position = sign_pos
	s.basis = Basis.looking_at(-to_join, Vector3.UP)
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(-2.4, 2.0, 0), Vector3.ZERO, 8, "PostL"))
	s.add_child(Build.cyl(0.16, 4.0, ToonMat.make(C_WOOD), Vector3(2.4, 2.0, 0), Vector3.ZERO, 8, "PostR"))
	s.add_child(Build.box(Vector3(6.4, 2.2, 0.18), ToonMat.make(Color(0.93, 0.90, 0.80)), Vector3(0, 3.4, 0), Vector3.ZERO, "Board"))
	s.add_child(Build.label3d("BESSI\nand the 5 ROSES", Vector3(0, 3.5, 0.12), Vector3.ZERO, 0.52, Color(0.70, 0.16, 0.24)))
	root.add_child(s)
	poi["roses"] = centre


func _rose_monument(pos: Vector3, scale: float, yaw: float) -> Node3D:
	var n := Node3D.new()
	n.name = "Rose"
	n.position = pos
	n.rotation.y = yaw
	n.scale = Vector3.ONE * scale

	var green := ToonMat.make(Color(0.28, 0.48, 0.26), 0.03)
	n.add_child(Build.cyl(1.6, 1.0, ToonMat.make(C_STONE, 0.03), Vector3(0, 0.5, 0), Vector3.ZERO, 14, "Base"))
	n.add_child(Build.cyl(0.42, 12.0, green, Vector3(0, 6.6, 0), Vector3.ZERO, 10, "Stem"))
	for s in [-1.0, 1.0]:
		var leaf := Build.sphere(1.0, green, Vector3(s * 1.5, 5.4, 0), Vector3(1.6, 0.25, 0.8), "Leaf")
		leaf.rotation_degrees = Vector3(0, 0, s * 22.0)
		n.add_child(leaf)
	var rings := [
		{"count": 8, "radius": 3.4, "y": 12.4, "len": 5.4, "tilt": 62.0, "col": C_ROSE_DEEP},
		{"count": 7, "radius": 2.4, "y": 13.4, "len": 4.4, "tilt": 42.0, "col": C_ROSE},
		{"count": 5, "radius": 1.3, "y": 14.2, "len": 3.2, "tilt": 22.0, "col": C_ROSE.lightened(0.14)},
	]
	for ring in rings:
		var mat := ToonMat.make(ring["col"], 0.035)
		for k in int(ring["count"]):
			var a := TAU * float(k) / float(ring["count"]) + float(ring["y"])
			var petal := Build.sphere(1.0, mat, Vector3.ZERO, Vector3(1.15, 0.42, 1.55), "Petal")
			var holder := Node3D.new()
			holder.position = Vector3(cos(a) * ring["radius"], ring["y"], sin(a) * ring["radius"])
			holder.rotation_degrees = Vector3(0, -rad_to_deg(a), 0)
			petal.rotation_degrees = Vector3(float(ring["tilt"]), 0, 0)
			petal.position = Vector3(0, 0, -float(ring["len"]) * 0.28)
			petal.scale = Vector3(1.0, 1.0, float(ring["len"]) / 3.0)
			holder.add_child(petal)
			n.add_child(holder)
	n.add_child(Build.sphere(1.15, ToonMat.make(Color(0.95, 0.78, 0.32), 0.03, 0.6, Color(0.35, 0.22, 0.05)), Vector3(0, 14.4, 0), Vector3.ONE, "Core"))
	return n


func _info_board(road_name: String, i: int, offset: float, text: String) -> void:
	var road := network.road(road_name)
	var p := road.point(i)
	var r := road.right(i)
	var pos := p + r * offset
	pos.y = _h(pos.x, pos.z)
	var n := Node3D.new()
	n.name = "InfoBoard"
	n.position = pos
	n.basis = Basis.looking_at(r * signf(offset), Vector3.UP)   # faces the road
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(-1.1, 1.2, 0), Vector3.ZERO, 8, "PostL"))
	n.add_child(Build.cyl(0.11, 2.4, ToonMat.make(C_WOOD), Vector3(1.1, 1.2, 0), Vector3.ZERO, 8, "PostR"))
	n.add_child(Build.box(Vector3(3.0, 1.9, 0.12), ToonMat.make(Color(0.90, 0.87, 0.78)), Vector3(0, 2.3, 0), Vector3(-14, 0, 0), "Board"))
	n.add_child(Build.label3d(text, Vector3(0, 2.36, 0.08), Vector3(-14, 0, 0), 0.16, Color(0.22, 0.26, 0.32)))
	# Reading a board sketches the surrounding area onto the shared paper map.
	var board_xz := Vector2(pos.x, pos.z)
	var area := Build.interact_area(Vector3(3.2, 2.4, 1.2), Vector3(0, 2.2, 0.3), "Read the board", func(p):
		var ms := p.get_tree().get_first_node_in_group("map_state") as MapState
		if ms != null:
			ms.reveal_around(board_xz, MapState.BOARD_REVEAL_M)
		var title := text.get_slice("\n", 0)
		var body := text.substr(title.length() + 1).replace("\n", " ")
		p.say(title + "\n" + body + "\n\n(The area around this board is now sketched on your map - M.)", 7.0), "ReadBoard")
	n.add_child(area)
	world.add_child(n)
	poi["info_" + road_name + str(i)] = pos


func _signage() -> void:
	var picks := [
		{"road": "home_lane", "i": 40, "text": "BESSI\n6 km", "side": 1.0},
		{"road": "home_lane", "i": 330, "text": "TOWN\nFUEL", "side": 1.0},
		{"road": "ghat_road", "i": 40, "text": "HAIRPIN\nBENDS", "side": 1.0},
		{"road": "beach_road", "i": 60, "text": "BESSI\nBEACH", "side": 1.0},
		{"road": "coast_road", "i": 300, "text": "FISHING\nVILLAGE", "side": -1.0},
		{"road": "coast_road", "i": 1500, "text": "TUNNEL\nLIGHTS ON", "side": 1.0},
		{"road": "west_road", "i": 60, "text": "HOMESTEAD\n3 km", "side": 1.0},
		{"road": "valley_road", "i": 60, "text": "MIRROR\nLAKE", "side": 1.0},
		{"road": "valley_road", "i": 330, "text": "SLOW\nCATTLE", "side": 1.0},
		{"road": "ridge_track", "i": 30, "text": "STEEP\nGRADE", "side": 1.0},
		{"road": "ridge_track", "i": 180, "text": "LOOKOUT", "side": -1.0},
		{"road": "pump_house_road", "i": 60, "text": "WATER\nWORKS", "side": 1.0},
		{"road": "bessi_loop", "i": 20, "text": "BEND\nAHEAD", "side": 1.0},
	]
	for s in picks:
		var road := network.road(s["road"])
		var i: int = mini(int(s["i"]), road.point_count() - 1)
		var p := road.point(i)
		var r := road.right(i)
		var side: float = s["side"]
		var pos := p + r * (6.4 * side)
		pos.y = _h(pos.x, pos.z)
		var n := Node3D.new()
		n.name = "Sign"
		n.position = pos
		n.basis = Basis.looking_at(road.forward(i), Vector3.UP)   # lettering (+Z) faces approaching drivers
		n.add_child(Build.cyl(0.08, 2.6, ToonMat.make(Color(0.60, 0.62, 0.64)), Vector3(0, 1.3, 0), Vector3.ZERO, 8, "Post"))
		n.add_child(Build.box(Vector3(1.7, 1.1, 0.1), ToonMat.make(Color(0.94, 0.92, 0.86)), Vector3(0, 2.5, 0), Vector3.ZERO, "Plate"))
		n.add_child(Build.label3d(str(s["text"]), Vector3(0, 2.5, 0.08), Vector3.ZERO, 0.30, Color(0.20, 0.24, 0.30)))
		world.add_child(n)
