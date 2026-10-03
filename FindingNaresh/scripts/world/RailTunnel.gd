class_name RailTunnel
extends Node

## F6, the old rail tunnel and R4 the torch relay (design/RETURN.md).
## The road runs through Tunnel Hill in the old rail tunnel, dark inside. Half
## way, an old FLOOD GATE is down across the road. Its winch is in the
## service gallery that runs beside the tunnel (two doors in the tunnel's
## right-hand wall, one before the gate and one after). The gallery is pitch
## dark, narrow, and one of them walks it: it hears footsteps, and sees a
## torch from far off (only very close in the dark without one). The way is
## marked at the two forks by painted arrows you can read only by torchlight:
## so walk it torch off, and switch on at the forks. The winch holds the gate
## up while someone holds it: the other drives the van through; then out by
## the far door. Down the second fork's dead end, seen only by torchlight:
## the flare gun (FlareGun, 3 flares).
##
## State in the story's flags: "gate_through" (the van is past the gate).

const IN_W := 5.4                 ## the tunnel's half-width inside (LevelPlaces._tunnel)
const IN_H := 6.2
const WALL := 0.6
const GAL_W := 2.4                ## the gallery: width inside, height
const GAL_H := 3.0
const DOOR_W := 1.8
const DOOR_H := 2.2
const DOOR_OUT := 30              ## road samples (~60 m) either side of the gate to the doors
const BRANCH := 9.0               ## m: each fork's dead end
const GATE_UP_S := 2.5            ## s of holding to raise it
const GATE_DOWN_S := 4.0          ## s it takes to sink once let go

var road: Route
var gate_i := 0
var doors: Array = []
var gate: StaticBody3D
var winch: Workable
var gun: FlareGun
var watcher: Creature
var run := Vector2i.ZERO          ## the tunnel's road samples
var _story: Story
var _off := 0.0                   ## the gallery's middle, metres right of the road's
var _concrete: Material
var _dark_mat: Material


## Flat ground where the gallery's two side passages run: they reach 9 m out
## past the gallery, into the hill beyond the tunnel's slot (flat only to
## TUNNEL_FLAT), and the hill filled their far ends: P2 walked up onto the
## terrain inside fork 1, and fork 2's flare gun sat in it (the F6 watched
## run; the old test put the player beside the gun by code). Handed to the
## terrain with the other pads, before it's built.
static func fork_pads(r: Route) -> Array:
	var d := door_indices(r)
	if d.is_empty():
		return []
	var rr := tunnel_run(r)
	var g := (rr.x + rr.y) / 2
	var out := IN_W + WALL + GAL_W + BRANCH * 0.5          # the passage's middle, m from the road's
	var list: Array = []
	for fi in [int(d[0]) + (g - int(d[0])) / 2, g + (int(d[1]) - g) / 2]:
		# a cell's diagonal past the passage: the terrain is a 5 m grid, and with
		# the pad just covering it a cell corner outside it still raised a 2 m
		# ridge across the passage (its triangles slope between the corners)
		list.append({"pos": r.point(fi) + r.right(fi) * out, "radius": BRANCH * 0.5 + Landscape.STEP * 1.5, "blend": 3.0})
	return list


## Where the gallery's two doors are (road sample indices), for the tunnel
## builder too: DOOR_OUT samples either side of the gate (the tunnel's middle),
## so the gallery is ~120 m (the tunnel itself is ~360 m).
static func door_indices(r: Route) -> Array:
	var rr := tunnel_run(r)
	var g := (rr.x + rr.y) / 2
	if g - DOOR_OUT < rr.x + 4 or g + DOOR_OUT > rr.y - 4:
		return []
	return [g - DOOR_OUT, g + DOOR_OUT]


static func tunnel_run(r: Route) -> Vector2i:
	var start := -1
	for i in r.point_count():
		if r.in_tunnel(i):
			if start < 0:
				start = i
		elif start >= 0:
			return Vector2i(start, i - 1)
	return Vector2i(start, r.point_count() - 1) if start >= 0 else Vector2i(-1, -1)


func setup(b) -> void:
	add_to_group("rail_tunnel")
	road = b.network.road("coast_road")
	run = tunnel_run(road)
	doors = door_indices(road)
	if doors.is_empty():
		push_warning("the rail tunnel is too short for the gallery")
		return
	gate_i = (run.x + run.y) / 2
	_off = IN_W + WALL + GAL_W * 0.5
	_concrete = ToonMat.make(Color(0.42, 0.42, 0.40))
	_dark_mat = ToonMat.make(Color(0.30, 0.30, 0.29))
	var body := StaticBody3D.new()
	body.name = "ServiceGallery"
	b.world.add_child(body)
	_doorways(b, body)
	_gallery(b, body)
	_gate(b)
	_winch_room(b)
	_watcher(b)
	b.poi["tunnel_gate"] = road.point(gate_i)
	b.poi["gallery_door"] = road.point(doors[0]) + road.right(doors[0]) * (IN_W - 1.0)
	b.poi["gallery_far_door"] = road.point(doors[1]) + road.right(doors[1]) * (IN_W - 1.0)
	b.poi["tunnel_in"] = road.point(run.x - 12)
	b.poi["tunnel_out"] = road.point(run.y + 12)


## A box between two road samples, `off` m to the right of the road's middle.
func _seg(b, body: StaticBody3D, i: int, j: int, off: float, size_xy: Vector2, y0: float, mat: Material) -> void:
	var a := road.point(i) + road.right(i) * off
	var c := road.point(j) + road.right(j) * off
	var xf := Transform3D(Basis.looking_at(c - a, Vector3.UP), (a + c) * 0.5 + Vector3.UP * (y0 + size_xy.y * 0.5))
	var size := Vector3(size_xy.x, size_xy.y, a.distance_to(c) + 0.3)
	var m := Build.box(size, mat)
	m.transform = xf
	b.world.add_child(m)
	body.add_child(b._box_shape(size, xf))


## The tunnel builder left the right-hand wall open where each door goes
## (a whole wall piece): wall it in again, leaving a doorway.
func _doorways(b, body: StaticBody3D) -> void:
	var a0 := run.x - 3
	var a1 := run.y + 3
	for d in doors:
		var i0: int = a0 + ((int(d) - a0) / 4) * 4
		var j0 := mini(i0 + 4, a1)
		var p0 := road.point(i0)
		var p1 := road.point(j0)
		var along := p0.distance_to(p1)
		var dz := road.point(d).distance_to(p0)              # where the door is along the piece
		var xf := Transform3D(Basis.looking_at(p1 - p0, Vector3.UP), p0)
		var wall_x := IN_W + WALL * 0.5
		# before the door, after it, and the lintel over it (up to the roof)
		var pieces := [[0.0, dz - DOOR_W * 0.5, 0.0, IN_H], [dz + DOOR_W * 0.5, along + 0.15, 0.0, IN_H], [dz - DOOR_W * 0.5, dz + DOOR_W * 0.5, DOOR_H, IN_H]]
		for pc in pieces:
			var z0: float = pc[0]
			var z1: float = pc[1]
			if z1 - z0 < 0.05:
				continue
			var size := Vector3(WALL, float(pc[3]) - float(pc[2]), z1 - z0)
			var lxf := xf.translated_local(Vector3(wall_x, float(pc[2]) + size.y * 0.5, -(z0 + z1) * 0.5))
			var m := Build.box(size, _concrete)
			m.transform = lxf
			b.world.add_child(m)
			body.add_child(b._box_shape(size, lxf))
		var sign := Build.label3d("SERVICE GALLERY", Vector3.ZERO, Vector3.ZERO, 0.18, Color(0.9, 0.85, 0.7))
		sign.transform = xf.translated_local(Vector3(IN_W - 0.02, DOOR_H + 0.4, -dz)) * Transform3D(Basis(Vector3.UP, deg_to_rad(-90)), Vector3.ZERO)
		sign.shaded = true
		b.world.add_child(sign)


## The gallery: floor, roof and outer wall along the road from door to door;
## the tunnel's own wall is its inner wall. Two forks run outwards to dead
## ends; the arrows at them are painted (seen only by torchlight).
func _gallery(b, body: StaticBody3D) -> void:
	var d0: int = doors[0] - 2
	var d1: int = doors[1] + 2
	var forks := [doors[0] + (gate_i - doors[0]) / 2, gate_i + (doors[1] - gate_i) / 2]
	var i := d0
	while i < d1:
		var j := mini(i + 2, d1)
		_seg(b, body, i, j, _off, Vector2(GAL_W + WALL * 2.0, 0.3), -0.3, _dark_mat)          # floor
		_seg(b, body, i, j, _off, Vector2(GAL_W + WALL * 2.0, 0.4), GAL_H, _concrete)       # roof
		var fork_here := false
		for f in forks:
			fork_here = fork_here or (int(f) >= i and int(f) < j)
		if not fork_here:
			_seg(b, body, i, j, _off + GAL_W * 0.5 + WALL * 0.5, Vector2(WALL, GAL_H), 0.0, _concrete)
		i = j
	# the ends
	for e in [[d0, 1.0], [d1, -1.0]]:
		var pe := road.point(int(e[0])) + road.right(int(e[0])) * _off
		var f := road.forward(int(e[0]))
		var xf := Transform3D(Basis.looking_at(f, Vector3.UP), pe + Vector3.UP * GAL_H * 0.5)
		var m := Build.box(Vector3(GAL_W + WALL * 2.0, GAL_H, WALL), _concrete)
		m.transform = xf
		b.world.add_child(m)
		body.add_child(b._box_shape(Vector3(GAL_W + WALL * 2.0, GAL_H, WALL), xf))
	# the forks: a short passage outwards to a dead end
	for k in forks.size():
		var fi: int = forks[k]
		var p := road.point(fi)
		var r := road.right(fi)
		var fw := road.forward(fi)
		var base := p + r * (_off + GAL_W * 0.5)
		var xf := Transform3D(Basis.looking_at(r, Vector3.UP), base + r * BRANCH * 0.5)
		for spec in [[Vector3(GAL_W + WALL * 2.0, 0.3, BRANCH), Vector3(0, -0.15, 0), _dark_mat],
				[Vector3(GAL_W + WALL * 2.0, 0.4, BRANCH), Vector3(0, GAL_H + 0.2, 0), _concrete],
				[Vector3(WALL, GAL_H, BRANCH), Vector3(-(GAL_W * 0.5 + WALL * 0.5), GAL_H * 0.5, 0), _concrete],
				[Vector3(WALL, GAL_H, BRANCH), Vector3(GAL_W * 0.5 + WALL * 0.5, GAL_H * 0.5, 0), _concrete],
				[Vector3(GAL_W + WALL * 2.0, GAL_H, WALL), Vector3(0, GAL_H * 0.5, -BRANCH * 0.5), _concrete]]:
			var lxf := xf.translated_local(spec[1])
			var m := Build.box(spec[0], spec[2])
			m.transform = lxf
			b.world.add_child(m)
			body.add_child(b._box_shape(spec[0], lxf))
		# the outer wall either side of the fork's mouth
		for s in [-1.0, 1.0]:
			var wl := Transform3D(Basis.looking_at(fw, Vector3.UP), p + r * (_off + GAL_W * 0.5 + WALL * 0.5) + fw * s * (GAL_W * 0.5 + 0.9) + Vector3.UP * GAL_H * 0.5)
			var m := Build.box(Vector3(WALL, GAL_H, 1.8 - 0.1), _concrete)
			m.transform = wl
			b.world.add_child(m)
			body.add_child(b._box_shape(Vector3(WALL, GAL_H, 1.7), wl))
		# the painted arrow on the wall opposite the fork: the way to the gate
		var to_gate := "GATE  >>" if k == 0 else "<<  GATE"
		var arrow := Build.label3d(to_gate + "\n" + ("OUT  >>" if k == 1 else ""), Vector3.ZERO, Vector3.ZERO, 0.16, Color(0.95, 0.9, 0.75))
		arrow.transform = Transform3D(Basis.looking_at(-r, Vector3.UP), p + r * (_off - GAL_W * 0.5 + 0.02) + Vector3.UP * 1.6)
		arrow.shaded = true
		arrow.outline_size = 0           # painted on: no outline, so in the dark it's just dark wall
		arrow.modulate = Color(0.75, 0.72, 0.62)
		b.world.add_child(arrow)
		b.poi["gallery_fork_%d" % (k + 1)] = p + r * _off
		if k == 1:
			# the flare gun, in a red case at the dead end
			var case_at := base + r * (BRANCH - 1.0)
			case_at.y = p.y + 0.05
			b.world.add_child(Build.box(Vector3(0.5, 0.3, 0.35), ToonMat.make(Color(0.6, 0.15, 0.12)), case_at + Vector3(0, 0.15, 0), Vector3.ZERO, "FlareCase"))
			# solid, so the gun rests on it: without, the gun fell through the
			# lid and lay hidden inside the case's box (the F6 watched run)
			body.add_child(b._box_shape(Vector3(0.5, 0.3, 0.35), Transform3D(Basis(), case_at + Vector3(0, 0.15, 0))))
			gun = FlareGun.new()
			gun.name = "FlareGun"
			b.world.add_child(gun)
			gun.position = case_at + Vector3(0, 0.32, 0)
			b.poi["flare_gun"] = gun.position
		if k == 0:
			b.poi["gallery_dead_end"] = base + r * (BRANCH - 1.0)


func _gate(b) -> void:
	var p := road.point(gate_i)
	var f := road.forward(gate_i)
	gate = StaticBody3D.new()
	gate.name = "FloodGate"
	b.world.add_child(gate)
	var steel := ToonMat.make(Color(0.36, 0.40, 0.44), 0.02)
	var size := Vector3(IN_W * 2.0, IN_H - 0.2, 0.3)
	gate.add_child(Build.box(size, steel, Vector3(0, size.y * 0.5, 0), Vector3.ZERO, "Gate"))
	gate.add_child(b._box_shape(size, Transform3D(Basis(), Vector3(0, size.y * 0.5, 0))))
	var lbl := Build.label3d("FLOOD GATE", Vector3(0, 3.0, 0.2), Vector3.ZERO, 0.4, Color(0.95, 0.75, 0.2))
	lbl.shaded = true
	gate.add_child(lbl)
	gate.transform = Transform3D(Basis.looking_at(-f, Vector3.UP), p)


func _winch_room(b) -> void:
	var p := road.point(gate_i)
	var r := road.right(gate_i)
	winch = Workable.new()
	winch.name = "GateWinch"
	winch.kind = "hold"
	winch.label = "gate winch"
	winch.verb = "hold up"
	winch.work_s = GATE_UP_S
	winch.close_s = GATE_DOWN_S
	winch.stand = Vector3(0, 0, 0.9)
	var steel := ToonMat.make(Color(0.5, 0.52, 0.55))
	var wheel := Node3D.new()
	wheel.name = "Wheel"
	winch.add_child(wheel)
	wheel.add_child(Build.cyl(0.35, 0.08, ToonMat.make(Color(0.8, 0.55, 0.15)), Vector3.ZERO, Vector3(90, 0, 0), 14, "Wheel"))
	winch.add_child(Build.box(Vector3(0.5, 1.0, 0.4), steel, Vector3(0, -0.5, -0.15), Vector3.ZERO, "Drum"))
	winch.add_child(b._box_shape(Vector3(0.7, 1.9, 0.5), Transform3D(Basis(), Vector3(0, -0.1, 0))))
	# on the gallery's inner wall (the tunnel side), facing into the gallery
	var at := p + r * (_off - GAL_W * 0.5 + 0.35) + Vector3.UP * 1.0
	winch.transform = Transform3D(Basis.looking_at(-r, Vector3.UP), at)     # its +Z (where you stand) into the gallery
	winch.on_amount = func(a: float):
		wheel.rotation.z = -a * TAU * 3.0
		gate.position.y = road.point(gate_i).y + a * (IN_H - 1.6)
	winch.set_meta("tag_name", "the gate winch")
	b.world.add_child(winch)
	var lbl := Build.label3d("FLOOD GATE WINCH", at + Vector3.UP * 1.2 + r * 0.05, Vector3.ZERO, 0.14, Color(0.95, 0.9, 0.75))
	lbl.transform = Transform3D(Basis.looking_at(-r, Vector3.UP), at + Vector3.UP * 1.2)   # text faces +Z: aim -Z away from the reader
	lbl.shaded = true
	b.world.add_child(lbl)
	b.poi["gate_winch"] = at


func _watcher(b) -> void:
	watcher = Creature.new()
	watcher.name = "GalleryCreature"
	var pts := PackedVector3Array()
	for idx in [doors[0] + 3, doors[1] - 3]:
		var q := road.point(idx) + road.right(idx) * _off
		pts.append(q)
	watcher.patrol = pts
	watcher.keeps_post = true        # it walks the gallery, it doesn't go for Naresh through the wall
	b.world.add_child(watcher)
	watcher.position = road.point(gate_i) + road.right(gate_i) * _off + Vector3.UP * 0.2
	b.poi["gallery_creature"] = watcher.position


## Inside the tunnel or the gallery?
func inside(pos: Vector3) -> bool:
	var near: Dictionary = road.nearest(pos.x, pos.z)
	var i := int(near["index"])
	if i < run.x - 2 or i > run.y + 2:
		return false
	return float(near["dist"]) < _off + GAL_W + BRANCH + 1.0


func _physics_process(_delta: float) -> void:
	if road == null or doors.is_empty():
		return
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
	# dark for whoever is on screen and underground
	var boot := get_tree().current_scene
	var views = boot.get("views")
	var under := 0.0
	for n in get_tree().get_nodes_in_group("player"):
		var pl := n as PlayerRig
		var shown: bool = views == null or pl.index >= views.size() or (views[pl.index] as Control).visible
		if shown and inside(pl.global_position):
			under = 1.0
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.dark = move_toward(mood.dark, under, _delta * 1.5)
	var van: Camper = boot.get("camper")
	if van != null and not _story.flags.has("gate_through"):
		var vi := int(road.nearest(van.global_position.x, van.global_position.z)["index"])
		if vi > gate_i + 8 and vi < run.y + 30 and inside(van.global_position) or vi > run.y and vi < run.y + 30:
			_story.flags["gate_through"] = true
