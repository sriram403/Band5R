class_name WindmillWire
extends Node3D

## Puzzle #2 round 2 (the user, 2026-10-07): the power you make, seen
## travelling. A small brick switch house by the windmill (a cable runs down
## a leg into it), wooden poles carrying a wire from it to the junction gate,
## and on along the road from lamp to lamp. When the fan catches the wind,
## the switch house's window lights and it hums, then a spark of light runs
## along the wire: into the gate (it opens), then on, each lamp lighting as
## it passes. S6: a big power dial on the switch house, facing the lever.

const POLE_EVERY := 12.0
const POLE_H := 6.2
const SPARK_SPEED := 20.0        ## m/s along the wire

var on := false                  ## the spark has been all the way (or a load)
var _paths: Array = []           ## [{pts: PackedVector3Array, events: [[dist, kind, i]]}]
var _spark_d := -1.0             ## m travelled along the wire, < 0 = not running
var _sparks: Array = []          ## a spark node per path
var _lamps: Array = []           ## [MeshInstance3D head, OmniLight3D]
var _lamp_off: Material
var _lamp_on: Material
var _window: MeshInstance3D
var _window_off: Material
var _window_on: Material
var _hum: NoiseLoop
var _needle: Node3D
var _on_gate: Callable
var _gate_done := false
var _wood: Material
var _wire_mat: Material


## `hut_xf`: the switch house (world, its front -Z facing the lever).
## `cable_from`: where the cable comes down the windmill's leg (world).
## `gate_post`: the gate's lamp post top (world). Lamps: three lists of world
## ground positions: up the lane to J1, then each road.
func setup(world: Node3D, hut_xf: Transform3D, cable_from: Vector3, gate_post: Vector3,
		lane: Array, ridge: Array, valley: Array, on_gate: Callable) -> void:
	name = "WindmillWire"
	world.add_child(self)
	_on_gate = on_gate
	_lamp_off = ToonMat.make(Color(0.25, 0.22, 0.18), 0.01)
	_lamp_on = ToonMat.make(Color(1.0, 0.86, 0.45), 0.01, 0.9, Color(1.0, 0.75, 0.3) * 2.5)
	_wood = ToonMat.make(Color(0.40, 0.31, 0.22), 0.012)
	_wire_mat = ToonMat.flat(Color(0.12, 0.12, 0.13))
	var rng := RandomNumberGenerator.new()
	rng.seed = 30120
	_build_hut(hut_xf, rng)
	var hut_top: Vector3 = hut_xf * Vector3(0.6, 2.9, 0.9)
	# the cable along the ground from the leg's foot to the switch house's back
	var back: Vector3 = hut_xf * Vector3(0, 0.15, 1.3)
	_ground_cable(cable_from, back)
	# poles from the switch house to the gate, never quite in a line
	var main: Array = [hut_top]
	var to_gate := gate_post - hut_top
	var flat := Vector2(to_gate.x, to_gate.z)
	var n := int(ceil(flat.length() / POLE_EVERY))
	for i in range(1, n):
		var u := float(i) / n
		var side := Vector2(-flat.y, flat.x).normalized() * rng.randf_range(-0.8, 0.8)
		var x := lerpf(hut_top.x, gate_post.x, u) + side.x
		var z := lerpf(hut_top.z, gate_post.z, u) + side.y
		main.append(_pole(Vector3(x, Landscape.ground(x, z), z), rng))
	main.append(gate_post)
	var events: Array = []
	var d := _length(main)
	events.append([d, "gate", 0])
	# on up the lane, lamp to lamp
	var k := 0
	for p in lane:
		main.append(_lamp(p, rng))
		d = _length(main)
		events.append([d, "lamp", k])
		k += 1
	_paths.append({"pts": main, "events": events})
	var branch_from: Vector3 = main[main.size() - 1]
	var branch_d := _length(main)
	for road in [ridge, valley]:
		var pts: Array = [branch_from]
		var ev: Array = []
		for p in road:
			pts.append(_lamp(p, rng))
			ev.append([branch_d + _length(pts), "lamp", k])
			k += 1
		_paths.append({"pts": pts, "events": ev, "start": branch_d})
	for path in _paths:
		_wire(path["pts"])
		var s := Node3D.new()
		s.visible = false
		var glow := Build.sphere(0.22, ToonMat.make(Color(1.0, 0.95, 0.7), 0.0, 0.9, Color(1.0, 0.85, 0.4) * 4.0), Vector3.ZERO, Vector3.ONE, "Spark")
		s.add_child(glow)
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.5)
		l.light_energy = 2.5
		l.omni_range = 6.0
		s.add_child(l)
		add_child(s)
		_sparks.append(s)
	reset()


func _length(pts: Array) -> float:
	var d := 0.0
	for i in pts.size() - 1:
		d += (pts[i + 1] as Vector3).distance_to(pts[i])
	return d


# --- running ---------------------------------------------------------------------

## The fan has caught the wind: light up the switch house and send the spark.
func power_on() -> void:
	_window.material_override = _window_on
	_hum.target = 0.6
	_spark_d = 0.0
	_gate_done = false
	Sfx.play3d("bong", _window.global_position, 0.0)


## Powered already (a save, a jump past the windmill): everything on at once.
func set_on_now() -> void:
	on = true
	_spark_d = -1.0
	_window.material_override = _window_on
	_hum.target = 0.6
	for i in _lamps.size():
		_light(i, true, false)


func reset() -> void:
	on = false
	_spark_d = -1.0
	_gate_done = false
	if _window:
		_window.material_override = _window_off
		_hum.target = 0.0
	for i in _lamps.size():
		_light(i, false, false)
	for s in _sparks:
		(s as Node3D).visible = false
	set_dial(0.0)


func set_dial(power: float) -> void:
	if _needle:
		_needle.rotation.z = deg_to_rad(lerpf(120.0, -120.0, clampf(power, 0.0, 1.0)))


func _physics_process(delta: float) -> void:
	if _spark_d < 0.0:
		return
	var before := _spark_d
	_spark_d += SPARK_SPEED * delta
	var running := false
	for i in _paths.size():
		var path: Dictionary = _paths[i]
		var start: float = path.get("start", 0.0)
		var pts: Array = path["pts"]
		var local := _spark_d - start
		var total := _length(pts)
		var s := _sparks[i] as Node3D
		s.visible = local >= 0.0 and local <= total
		if local >= 0.0 and local <= total:
			running = true
			s.global_position = _at(pts, local)
		elif local < 0.0:
			running = true
		for e in path["events"]:
			var ed: float = e[0]
			if before < ed and _spark_d >= ed:
				if e[1] == "gate" and not _gate_done:
					_gate_done = true
					if _on_gate.is_valid():
						_on_gate.call()
				elif e[1] == "lamp":
					_light(int(e[2]), true, true)
	if not running:
		_spark_d = -1.0
		on = true


## The point `d` metres along a wire through `pts`, with the sag.
func _at(pts: Array, d: float) -> Vector3:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var l := a.distance_to(b)
		if d <= l:
			var u := d / l
			return a.lerp(b, u) + Vector3.DOWN * _sag(l) * 4.0 * u * (1.0 - u)
		d -= l
	return pts[pts.size() - 1]


func _sag(span: float) -> float:
	return clampf(span * 0.03, 0.15, 0.6)


func _light(i: int, lit: bool, sound: bool) -> void:
	if i < 0 or i >= _lamps.size():
		return
	var l: Array = _lamps[i]
	(l[0] as MeshInstance3D).material_override = _lamp_on if lit else _lamp_off
	(l[1] as OmniLight3D).visible = lit
	if lit and sound:
		Sfx.play3d("click", (l[0] as Node3D).global_position, -2.0)


func lamps_lit() -> int:
	var n := 0
	for l in _lamps:
		n += 1 if (l[1] as OmniLight3D).visible else 0
	return n


func lamp_count() -> int:
	return _lamps.size()


# --- the storm's leftovers ----------------------------------------------------------

## Beyond the last lamp on each road the line is down (the user, 2026-10-07:
## the street lamps go nowhere; make it look as if a storm blew the rest
## away, a hint of what's coming later). `roads`: per road, the three spots
## where the next lamps stood. The first leans hard, its wire sagging to it
## and its head hanging by the cable; the second snapped, its top in the
## grass, the glass in bits; the third only a stump. Torn branches about,
## and an uprooted tree. Nothing on the road itself.
func storm_wreck(roads: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var post := ToonMat.make(Color(0.30, 0.31, 0.33), 0.01)
	var dark := ToonMat.make(Color(0.18, 0.17, 0.16), 0.01)
	var bark := ToonMat.make(Color(0.36, 0.26, 0.18), 0.012)
	var leaf := ToonMat.make(Color(0.30, 0.45, 0.22), 0.012)
	for r in _paths.size() - 1:
		var spots: Array = roads[r] if r < roads.size() else []
		if spots.size() < 3:
			continue
		var pts: Array = _paths[r + 1]["pts"]
		var last_top: Vector3 = pts[pts.size() - 1]
		var a: Vector3 = spots[0]
		var b: Vector3 = spots[1]
		var c: Vector3 = spots[2]
		var away := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
		# 1: leaning hard away from the road, the head hanging off its arm
		var lean := Node3D.new()
		lean.position = a
		lean.basis = Basis(Vector3.UP.cross(away).normalized(), deg_to_rad(24.0)) * Basis(Vector3.UP, rng.randf_range(0, TAU))
		add_child(lean)
		lean.add_child(Build.cyl(0.08, 5.6, post, Vector3(0, 2.6, 0), Vector3.ZERO, 6, "LeaningPost"))
		var arm_end := lean.transform * Vector3(0, 5.2, 0)
		var hang := arm_end + Vector3.DOWN * 1.3
		_rod(arm_end, hang, 0.02, _wire_mat)
		add_child(Build.sphere(0.2, dark, hang + Vector3.DOWN * 0.15, Vector3(1, 0.7, 1), "DanglingHead"))
		# the wire from the last good lamp sags low to it
		var mid := (last_top + arm_end) * 0.5 + Vector3.DOWN * 2.2
		_rod(last_top, mid, 0.022, _wire_mat)
		_rod(mid, arm_end, 0.022, _wire_mat)
		# from it, a snapped end trailing on the grass towards the next
		var trail := a.lerp(b, 0.45)
		trail.y = Landscape.ground(trail.x, trail.z) + 0.04
		_rod(arm_end, trail, 0.02, _wire_mat)
		_rod(trail, trail + away * 2.5 + Vector3(0, 0.0, 0) + Vector3(-away.z, 0, away.x) * 0.8, 0.02, _wire_mat)
		# 2: snapped at head height, the top lying in the grass
		var stump_h := rng.randf_range(1.4, 2.0)
		add_child(Build.cyl(0.08, stump_h, post, b + Vector3(0, stump_h * 0.5, 0), Vector3(rng.randf_range(-4, 4), 0, rng.randf_range(-4, 4)), 6, "SnappedPost"))
		var top_dir := away.rotated(Vector3.UP, rng.randf_range(-0.6, 0.6))
		var top_mid := b + top_dir * 2.3
		top_mid.y = Landscape.ground(top_mid.x, top_mid.z) + 0.1
		var top := Build.cyl(0.08, 3.8, post, Vector3.ZERO, Vector3.ZERO, 6, "FallenTop")
		top.transform = Transform3D(Basis(Quaternion(Vector3.UP, top_dir)), top_mid)
		add_child(top)
		for k in 4:
			var shard := top_mid + top_dir * 1.9 + Vector3(rng.randf_range(-0.6, 0.6), 0, rng.randf_range(-0.6, 0.6))
			shard.y = Landscape.ground(shard.x, shard.z) + 0.03
			add_child(Build.box(Vector3(0.12, 0.03, 0.09), dark, shard, Vector3(0, rng.randf_range(0, 360), 0), "Glass"))
		# 3: just a stump
		add_child(Build.cyl(0.09, 0.5, post, c + Vector3(0, 0.22, 0), Vector3(6, 0, -3), 6, "Stump"))
		# torn branches strewn along the verge, and one tree pulled up by the roots
		for k in 7:
			var bp: Vector3 = a.lerp(c, rng.randf()) + Vector3(-away.z, 0, away.x) * rng.randf_range(0.5, 4.0)
			bp.y = Landscape.ground(bp.x, bp.z) + 0.08
			var bl := rng.randf_range(0.8, 2.2)
			var br := Build.cyl(rng.randf_range(0.03, 0.07), bl, bark, Vector3.ZERO, Vector3.ZERO, 5, "Branch")
			br.transform = Transform3D(Basis(Vector3.UP, rng.randf_range(0, TAU)) * Basis(Vector3.RIGHT, PI * 0.5 + rng.randf_range(-0.15, 0.15)), bp)
			add_child(br)
			if rng.randf() < 0.5:
				add_child(Build.sphere(rng.randf_range(0.25, 0.45), leaf, bp + Vector3.UP * 0.12, Vector3(1.3, 0.6, 1), "Leaves"))
		var tree_at: Vector3 = c + Vector3(-away.z, 0, away.x) * 7.0
		tree_at.y = Landscape.ground(tree_at.x, tree_at.z)
		var fall := away.rotated(Vector3.UP, rng.randf_range(0.6, 1.1))
		var trunk := Build.cyl(0.32, 7.5, bark, Vector3.ZERO, Vector3.ZERO, 7, "UprootedTrunk")
		trunk.transform = Transform3D(Basis(Quaternion(Vector3.UP, fall)), tree_at + fall * 3.9 + Vector3.UP * 0.35)
		add_child(trunk)
		var roots := Build.cyl(1.3, 0.35, ToonMat.make(Color(0.34, 0.27, 0.2), 0.012), Vector3.ZERO, Vector3.ZERO, 9, "RootPlate")
		roots.transform = Transform3D(Basis(Quaternion(Vector3.UP, -fall)), tree_at + Vector3.UP * 1.0 - fall * 0.1)
		add_child(roots)
		add_child(Build.sphere(2.2, leaf, tree_at + fall * 8.2 + Vector3.UP * 1.1, Vector3(1.2, 0.7, 1.0), "FallenCrown"))
		var hole := Build.cyl(1.2, 0.1, ToonMat.make(Color(0.3, 0.24, 0.18), 0.01), tree_at + Vector3.UP * 0.02, Vector3.ZERO, 9, "Hole")
		add_child(hole)


# --- building --------------------------------------------------------------------

## A wooden pole at `foot` (a little out of plumb, its own height) with a
## crossarm; returns where the wire hangs from.
func _pole(foot: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var h := POLE_H + rng.randf_range(-0.4, 0.3)
	var p := Node3D.new()
	p.position = foot
	p.rotation_degrees = Vector3(rng.randf_range(-2.5, 2.5), rng.randf_range(0, 360), rng.randf_range(-2.5, 2.5))
	add_child(p)
	p.add_child(Build.cyl(0.11, h + 0.5, _wood, Vector3(0, (h - 0.5) * 0.5, 0), Vector3.ZERO, 7, "Pole"))
	p.add_child(Build.box(Vector3(1.1, 0.1, 0.1), _wood, Vector3(0, h - 0.3, 0), Vector3.ZERO, "Crossarm"))
	p.add_child(Build.cyl(0.05, 0.12, ToonMat.make(Color(0.75, 0.8, 0.85), 0.006), Vector3(0.4, h - 0.18, 0), Vector3.ZERO, 6, "Insulator"))
	return p.transform * Vector3(0.4, h - 0.1, 0)      # this node sits at the world origin


## A street lamp on a post at `foot`; the wire comes in at its top.
func _lamp(foot: Vector3, rng: RandomNumberGenerator) -> Vector3:
	var post := ToonMat.make(Color(0.30, 0.31, 0.33), 0.01)
	var n := Node3D.new()
	n.position = foot
	n.rotation_degrees = Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
	add_child(n)
	n.add_child(Build.cyl(0.08, 5.6, post, Vector3(0, 2.6, 0), Vector3.ZERO, 6, "LampPost"))
	var head := Build.sphere(0.22, _lamp_off, Vector3(0, 5.1, 0), Vector3(1, 0.7, 1), "LampHead")
	n.add_child(head)
	var l := OmniLight3D.new()
	l.position = Vector3(0, 4.8, 0)
	l.light_color = Color(1.0, 0.85, 0.55)
	l.light_energy = 1.4
	l.omni_range = 9.0
	l.visible = false
	n.add_child(l)
	_lamps.append([head, l])
	return foot + Vector3(0, 5.4, 0)


func _wire(pts: Array) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var l := a.distance_to(b)
		var segs := 6
		for s in segs:
			var p0 := _sagged(a, b, l, float(s) / segs)
			var p1 := _sagged(a, b, l, float(s + 1) / segs)
			_rod(p0, p1, 0.022, _wire_mat)


func _sagged(a: Vector3, b: Vector3, l: float, u: float) -> Vector3:
	return a.lerp(b, u) + Vector3.DOWN * _sag(l) * 4.0 * u * (1.0 - u)


func _rod(a: Vector3, b: Vector3, r: float, mat: Material) -> void:
	var d := b - a
	if d.length() < 0.01:
		return
	var m := Build.cyl(r, d.length(), mat, Vector3.ZERO, Vector3.ZERO, 5, "Wire")
	m.transform = Transform3D(Basis(Quaternion(Vector3.UP, d.normalized())), (a + b) * 0.5)
	add_child(m)


## The cable on the ground from the windmill to the switch house: in a few
## pieces that follow the ground, held down by the odd stake.
func _ground_cable(a: Vector3, b: Vector3) -> void:
	var cable := ToonMat.make(Color(0.12, 0.12, 0.12), 0.006)
	var n := 8
	var prev := a
	for i in range(1, n + 1):
		var u := float(i) / n
		var p := a.lerp(b, u)
		if i < n:
			p.y = Landscape.ground(p.x, p.z) + 0.06
		_rod(prev, p, 0.05, cable)
		prev = p


func _build_hut(xf: Transform3D, rng: RandomNumberGenerator) -> void:
	var hut := Node3D.new()
	hut.name = "SwitchHouse"
	hut.transform = xf
	add_child(hut)
	var brick := ToonMat.make(Color(0.62, 0.36, 0.28), 0.012)
	var roofm := ToonMat.make(Color(0.30, 0.32, 0.35), 0.012)
	var doorm := ToonMat.make(Color(0.24, 0.35, 0.30), 0.012)
	hut.add_child(Build.solid_box(Vector3(2.6, 2.4, 2.4), brick, Vector3(0, 1.2, 0), Vector3.ZERO, "Walls"))
	# a low brick base where the ground slopes, so it never floats
	hut.add_child(Build.box(Vector3(2.8, 0.8, 2.6), ToonMat.make(Color(0.5, 0.45, 0.4), 0.012), Vector3(0, -0.25, 0), Vector3.ZERO, "Plinth"))
	hut.add_child(Build.box(Vector3(3.0, 0.15, 2.9), roofm, Vector3(0, 2.5, 0.05), Vector3(-4, 0, 0), "Roof"))
	hut.add_child(Build.box(Vector3(0.9, 1.9, 0.06), doorm, Vector3(-0.55, 0.95, -1.22), Vector3.ZERO, "Door"))
	hut.add_child(Build.box(Vector3(0.12, 0.16, 0.08), ToonMat.make(Color(0.75, 0.62, 0.2), 0.006), Vector3(-0.2, 1.0, -1.26), Vector3.ZERO, "Padlock"))
	_window_off = ToonMat.make(Color(0.18, 0.22, 0.26), 0.008)
	_window_on = ToonMat.make(Color(1.0, 0.85, 0.5), 0.008, 0.9, Color(1.0, 0.75, 0.35) * 2.0)
	_window = Build.box(Vector3(0.7, 0.5, 0.05), _window_off, Vector3(1.3, 1.5, -0.3), Vector3(0, 90, 0), "Window")
	hut.add_child(_window)
	hut.add_child(Build.label3d("WINDMILL No. 3\nSWITCH HOUSE", Vector3(0.45, 2.05, -1.23), Vector3(0, 180, 0), 0.11, Color(0.95, 0.92, 0.82)))
	# S6: the power dial, big enough to read from the lever
	var dial := Node3D.new()
	dial.name = "PowerDial"
	dial.position = Vector3(0.55, 1.35, -1.24)
	dial.rotation_degrees = Vector3(0, 180, 0)
	hut.add_child(dial)
	dial.add_child(Build.cyl(0.42, 0.05, ToonMat.make(Color(0.95, 0.94, 0.88), 0.008), Vector3.ZERO, Vector3(90, 0, 0), 20, "Face"))
	dial.add_child(Build.cyl(0.45, 0.04, ToonMat.make(Color(0.2, 0.2, 0.2), 0.008), Vector3(0, 0, -0.01), Vector3(90, 0, 0), 20, "Rim"))
	# the green zone at the top right: full
	dial.add_child(Build.box(Vector3(0.18, 0.06, 0.01), ToonMat.flat(Color(0.2, 0.7, 0.3)), Vector3(0.28, 0.2, 0.03), Vector3(0, 0, 35), "Full"))
	_needle = Node3D.new()
	_needle.position = Vector3(0, 0, 0.035)
	dial.add_child(_needle)
	_needle.add_child(Build.box(Vector3(0.025, 0.34, 0.01), ToonMat.flat(Color(0.8, 0.1, 0.1)), Vector3(0, 0.15, 0), Vector3.ZERO, "Needle"))
	dial.add_child(Build.label3d("POWER", Vector3(0, -0.22, 0.03), Vector3.ZERO, 0.07, Color(0.15, 0.15, 0.15)))
	# lived in: a bucket by the door, a rain barrel at the corner, a bench
	hut.add_child(Build.cyl(0.16, 0.3, ToonMat.make(Color(0.45, 0.47, 0.5), 0.008), Vector3(-1.25, 0.15, -1.55), Vector3(0, 0, 8), 8, "Bucket"))
	hut.add_child(Build.solid_cyl(0.35, 0.9, ToonMat.make(Color(0.35, 0.26, 0.18), 0.012), Vector3(-1.45, 0.45, 1.0), Vector3.ZERO, "RainBarrel"))
	hut.add_child(Build.box(Vector3(1.2, 0.08, 0.35), _wood, Vector3(0.75, 0.45, -1.45), Vector3(0, -6, 0), "BenchTop"))
	for bx in [0.3, 1.2]:
		hut.add_child(Build.box(Vector3(0.08, 0.45, 0.3), _wood, Vector3(bx, 0.22, -1.45 + (bx - 0.75) * 0.1), Vector3.ZERO, "BenchLeg"))
	_hum = NoiseLoop.new()
	_hum.name = "SwitchHum"
	_hum.kind = NoiseLoop.Kind.HUM
	_hum.volume_db = -14.0
	_hum.position = Vector3(0, 1.4, 0)
	hut.add_child(_hum)
