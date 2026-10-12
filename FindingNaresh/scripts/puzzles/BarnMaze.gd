class_name BarnMaze
extends Node3D

## Puzzle #3, the barn maze (design/PUZZLE_CHANGES.md #3, optional, Valley
## Road). A big hedge maze behind the barn: 14 x 14 cells of 3.5 m, hedges
## 3 m tall, a few loops so a hand on the wall doesn't get you through. The
## guide climbs the barn's silo (13 m) and sees the near half like a map, the
## far half only as hedge tops; the walker carries a flag on a pole that shows
## above the hedges. About a dozen landmarks inside (tall ones both see, low
## ones only the walker sees, twins to confuse, painted arrows only the guide
## can read). Five pits under rotten boards: dark squares from the silo, one
## more straw patch at eye level; a fall puts you out of the drain by the
## front gate. When the walker reaches the courtyard in the middle it snows
## hard: the guide sees nothing and guides from memory; the snow covers the
## pits. It clears when the walker gets to the feed chest (a spare tyre, fuel,
## coolant, and Naresh's note that teaches the push out of the van). Jump
## scares pop out of the hedges at turns, only when you walk back out of a
## wrong turn.
##
## Local frame: +Z is the near edge (the barn and the silo), the way in is on
## it; the chest is in the far corner, with a back gate in the -X edge.

const N := 18                    ## cells a side (63 m; round 2, the user 2026-10-12)
const CELL := 3.5                ## m
const HEDGE_H := 3.0
const HEDGE_T := 0.5
const SEED := 20261008
const BRAIDS := 22               ## walls knocked through for loops
const CENTRE := [Vector2i(8, 8), Vector2i(9, 8), Vector2i(8, 9), Vector2i(9, 9)]
const PIT_FALL_S := 1.3          ## s from the crack to climbing out of the drain
const SNOW_IN := 10.0            ## s for the snow to come on
const CLEAR_S := 180.0           ## s of sun after it clears
const PRINT_LIFE := 30.0         ## S1: s a footprint in the snow lasts
const SCARE_WAIT := 20.0         ## s before a scare can pop again

var walls_h: Array = []          ## [x][z] wall on the -Z side of cell (x, z); z == N is the near edge
var walls_v: Array = []          ## [x][z] wall on the -X side of cell (x, z); x == N is the +X edge
var entrance := Vector2i(12, N - 1)  ## the cell by the gap in the near (+Z) edge
var goal := Vector2i(0, 1)       ## the feed chest; the back gate is in its -X side
var way: Array[Vector2i] = []    ## the shortest way in to the chest
var dist := {}                   ## cell -> steps from the way in

var chest_open := false
var back_open := false
var snowing := false             ## the heavy snow is on (from the middle to the chest)
var snow_done := false           ## it has snowed and cleared (once per go)
var snow := 0.0                  ## 0..1 how much lies (the floor, the hedge tops)
var pits: Array = []             ## {cell, centre (local), half (Vector2), cover, hole, open_t}
var scares: Array = []           ## {cell, from, node, kind, t, done, hide, show}
var marks := {}                  ## landmark name -> its cell
var door_plan: Array = []        ## {kind, front, back}: round 2's doors, all in the snow half
var doors: Array = []            ## the MazeDoor nodes
var back_from := 0               ## dist beyond which a cell is in the snow half
var _door_cells := {}
var falls := 0                   ## pit falls this go (tests)
var scares_fired := 0

var _rewards: Array = []
var _used := {}                  ## cells with a landmark (no pit there)
var _chest_lid: Node3D
var _back_gate: Node3D
var _back_body: StaticBody3D
var _snow_floor: MeshInstance3D
var _snow_floor_mat: StandardMaterial3D
var _caps: MeshInstance3D
var _bell: Node3D
var _crows: Array[Node3D] = []
var _crows_t := 0.0
var _flags := {}                 ## player -> flag node (the walker's flag on a pole)
var _last_cell := {}             ## player -> last cell (the scares)
var _prints: Array = []          ## [node, age]
var _last_print := {}            ## player -> where the last footprint went
var _falling := {}               ## player -> true while falling
var _weather: Node
var frights: MazeFrights
var _lamp_light: OmniLight3D
var _lamp_bulb: MeshInstance3D
var _zone_layer := 0
var _curtain: MeshInstance3D

## S4: from afar (the ridge lookout, the valley road) a squall of snow hangs
## over the barn until the maze has had its snow; up close it's the real snow.
const CURTAIN_SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
uniform float amount = 1.0;
float hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}
void fragment() {
	float streak = noise(vec2(UV.x * 90.0, UV.y * 6.0 + TIME * 0.9)) * 0.6 + noise(vec2(UV.x * 23.0, UV.y * 2.0 + TIME * 0.4)) * 0.4;
	float fade = smoothstep(0.0, 0.25, UV.y) * smoothstep(1.0, 0.7, UV.y);
	ALBEDO = vec3(0.82, 0.84, 0.88);
	ALPHA = clamp((0.32 + streak * 0.4) * fade * amount, 0.0, 1.0);
}
"""
const CURTAIN_NEAR := 160.0      ## m: closer than this, the real snow


## `xf`: the maze's middle on the ground, in the barn's frame.
func setup(xf: Transform3D) -> void:
	add_to_group("barn_maze")
	transform = xf
	_generate()
	_build()


# --- the layout ---------------------------------------------------------------------

## A maze carved depth-first, then a few walls knocked through for loops. The
## seed is searched (the same every time) until the way to the chest passes
## the courtyard in the middle and is long enough to be a real walk.
func _generate() -> void:
	for s in 400:
		_carve(SEED + s)
		way = path(entrance, goal)
		var through := false
		for c in way:
			if c in CENTRE:
				through = true
		if through and way.size() >= 80:
			break
	# the back gate: out of the last cell's -X side
	walls_v[goal.x][goal.y] = false
	_distances()
	_plan_doors()


func _distances() -> void:
	dist = {}
	var q: Array[Vector2i] = [entrance]
	dist[entrance] = 0
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		for n in neighbours(c):
			if not dist.has(n):
				dist[n] = int(dist[c]) + 1
				q.append(n)


## Is the cell in the snow half (past the courtyard)?
func is_back(c: Vector2i) -> bool:
	return int(dist.get(c, 0)) > back_from


## Round 2's doors, all in the snow half: 3 real ones on the way (the first
## two shut behind you, S12), 1 that leads round a loop back to itself, 4
## fake ones at the ends of dead ends.
func _plan_doors() -> void:
	door_plan = []
	_door_cells = {}
	var ci := 0
	for i in way.size():
		if way[i] in CENTRE:
			ci = i
	back_from = int(dist[way[ci]]) + 1
	var k := 0
	# spread over the snow half of the way (fractions of the whole way piled
	# two doors onto one edge when the courtyard came late: 2026-10-12)
	var span := way.size() - 3 - (ci + 2)
	for f in [0.15, 0.5, 0.85]:
		var i := ci + 2 + int(f * span)
		door_plan.append({"kind": "oneway" if k < 2 else "real", "front": way[i], "back": way[i + 1]})
		_door_cells[way[i]] = true
		_door_cells[way[i + 1]] = true
		k += 1
	# the loop: an open edge off the way whose cells are joined another way round
	var found := false
	for x in N:
		for z in N:
			if found:
				break
			var a := Vector2i(x, z)
			if not is_back(a) or _door_cells.has(a):
				continue
			for d in [Vector2i(1, 0), Vector2i(0, 1)]:
				var b: Vector2i = a + d
				if not _inside(b) or wall_between(a, b) or not is_back(b) or _door_cells.has(b):
					continue
				var ia := way.find(a)
				var ib := way.find(b)
				if ia >= 0 and ib >= 0 and absi(ia - ib) == 1:
					continue
				_set_wall(a, b, true)
				var round := path(a, b).size()
				_set_wall(a, b, false)
				if round >= 7 and round <= 16:
					var fr := a if int(dist[a]) <= int(dist[b]) else b
					door_plan.append({"kind": "loop", "front": fr, "back": b if fr == a else a})
					_door_cells[a] = true
					_door_cells[b] = true
					found = true
					break
	# the fakes: at the far end of dead ends in the snow half
	var ends: Array[Vector2i] = []
	for x in N:
		for z in N:
			var c := Vector2i(x, z)
			if is_back(c) and neighbours(c).size() == 1 and not c in way and not _door_cells.has(c) and c != goal:
				ends.append(c)
	var picked := 0
	var j := 0
	while picked < 4 and j < ends.size():
		var c: Vector2i = ends[j]
		var d: Vector2i = c - neighbours(c)[0]
		door_plan.append({"kind": "fake", "front": c, "back": c + d})
		_door_cells[c] = true
		picked += 1
		j += maxi(1, ends.size() / 4)


func _set_wall(a: Vector2i, b: Vector2i, on: bool) -> void:
	if a.x != b.x:
		walls_v[maxi(a.x, b.x)][a.y] = on
	else:
		walls_h[a.x][maxi(a.y, b.y)] = on


## The boundary point between two neighbouring cells (local).
func edge_pos(a: Vector2i, b: Vector2i) -> Vector3:
	return (cell_pos(a) + cell_pos(b)) * 0.5


## The door between two cells, if there is one.
func door_between(a: Vector2i, b: Vector2i) -> MazeDoor:
	for d in doors:
		var md := d as MazeDoor
		if (md.cell_front == a and md.cell_back == b) or (md.cell_front == b and md.cell_back == a):
			return md
	return null


func _carve(seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	walls_h = []
	walls_v = []
	for x in N + 1:
		walls_h.append([])
		walls_v.append([])
		for z in N + 1:
			walls_h[x].append(true)
			walls_v[x].append(true)
	var seen := {}
	var stack: Array[Vector2i] = [entrance]
	seen[entrance] = true
	while not stack.is_empty():
		var c: Vector2i = stack[stack.size() - 1]
		var options: Array[Vector2i] = []
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if _inside(n) and not seen.has(n):
				options.append(n)
		if options.is_empty():
			stack.pop_back()
			continue
		var n: Vector2i = options[rng.randi_range(0, options.size() - 1)]
		_open(c, n)
		seen[n] = true
		stack.append(n)
	# the courtyard in the middle: one open square
	_open(CENTRE[0], CENTRE[1])
	_open(CENTRE[2], CENTRE[3])
	_open(CENTRE[0], CENTRE[2])
	_open(CENTRE[1], CENTRE[3])
	# loops: knock through a few inner walls, away from the edges
	var made := 0
	var tries := 0
	while made < BRAIDS and tries < 500:
		tries += 1
		var a := Vector2i(rng.randi_range(1, N - 2), rng.randi_range(1, N - 2))
		var d: Vector2i = [Vector2i(1, 0), Vector2i(0, 1)][rng.randi_range(0, 1)]
		var b := a + d
		if not _inside(b) or not wall_between(a, b):
			continue
		_open(a, b)
		made += 1
	walls_h[entrance.x][N] = false       # the way in, on the near edge


func _inside(c: Vector2i) -> bool:
	return c.x >= 0 and c.x < N and c.y >= 0 and c.y < N


func _open(a: Vector2i, b: Vector2i) -> void:
	if a.x != b.x:
		walls_v[maxi(a.x, b.x)][a.y] = false
	else:
		walls_h[a.x][maxi(a.y, b.y)] = false


## The middle of a cell, local.
func cell_pos(c: Vector2i) -> Vector3:
	var half := N * CELL * 0.5
	return Vector3(-half + (c.x + 0.5) * CELL, 0, -half + (c.y + 0.5) * CELL)


## Is there a wall between two neighbouring cells?
func wall_between(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x:
		return walls_v[maxi(a.x, b.x)][a.y]
	return walls_h[a.x][maxi(a.y, b.y)]


## Is there a wall on side `d` (a unit step) of cell `c`, edges included?
func wall_side(c: Vector2i, d: Vector2i) -> bool:
	if d.x != 0:
		return walls_v[c.x + maxi(d.x, 0)][c.y]
	return walls_h[c.x][c.y + maxi(d.y, 0)]


func neighbours(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var n: Vector2i = c + d
		if _inside(n) and not wall_between(c, n):
			out.append(n)
	return out


## The way from one cell to another (breadth-first), cells in order.
func path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var prev := {from: from}
	var q: Array[Vector2i] = [from]
	while not q.is_empty():
		var c: Vector2i = q.pop_front()
		if c == to:
			break
		for n in neighbours(c):
			if not prev.has(n):
				prev[n] = c
				q.append(n)
	var out: Array[Vector2i] = []
	if not prev.has(to):
		return out
	var c := to
	while c != from:
		out.push_front(c)
		c = prev[c]
	out.push_front(from)
	return out


## Which cell a point (global) is in, or (-1, -1) outside the maze.
func cell_at(p: Vector3) -> Vector2i:
	var l := global_transform.affine_inverse() * p
	var half := N * CELL * 0.5
	var c := Vector2i(floori((l.x + half) / CELL), floori((l.z + half) / CELL))
	return c if _inside(c) else Vector2i(-1, -1)


## Outside the near edge, by the way in, facing in (local).
func gate_spot() -> Vector3:
	return cell_pos(entrance) + Vector3(0, 0, CELL * 0.5 + 2.6)


## Outside the back gate (local).
func back_spot() -> Vector3:
	return cell_pos(goal) + Vector3(-CELL * 0.5 - 2.5, 0, 0)


# --- building it ---------------------------------------------------------------------

func _build() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_hedges(rng)
	_floor(rng)
	_front_gate()
	_landmarks(rng)
	_place_pits()
	_place_scares()
	_courtyard()
	_chest()
	_build_doors()
	_marks()
	_track()
	_build_curtain()
	frights = MazeFrights.new()
	frights.name = "Frights"
	add_child(frights)
	frights.setup(self)


func _build_doors() -> void:
	doors = []
	for dp in door_plan:
		var a: Vector2i = dp["front"]
		var b: Vector2i = dp["back"]
		var mid := edge_pos(a, b)
		var f := cell_pos(a) - mid
		f.y = 0.0
		var at := mid
		if dp["kind"] == "fake":
			at += f.normalized() * (HEDGE_T * 0.5 + 0.05)   # on the hedge's face
		doors.append(MazeDoor.make(self, String(dp["kind"]), at, atan2(f.x, f.z), a, b))


## Round 2: marks you can see from the silo and the track: a red lantern on
## a tall pole over the chest's bay; at the exit a windsock mast, an EXIT
## board and a lamp over the back gate that lights when the snow comes.
func _marks() -> void:
	var pole := ToonMat.make(Color(0.40, 0.30, 0.22), 0.01)
	var red := ToonMat.make(Color(0.85, 0.12, 0.10), 0.006, 0.5, Color(0.9, 0.15, 0.1))
	var c := cell_pos(goal) + Vector3(1.2, 0, 1.2)
	add_child(Build.cyl(0.08, 8.0, pole, c + Vector3(0, 4.0, 0), Vector3.ZERO, 6, "ChestPole"))
	add_child(Build.box(Vector3(0.3, 0.42, 0.3), red, c + Vector3(0, 8.2, 0), Vector3.ZERO, "ChestLantern"))
	add_child(Build.box(Vector3(1.1, 0.5, 0.03), ToonMat.make(Color(0.85, 0.12, 0.10), 0.0), c + Vector3(0.6, 7.5, 0), Vector3.ZERO, "ChestPennant"))
	var out := back_spot() + Vector3(0.6, 0, 2.6)
	var mast := Storm.make_windsock(out + Vector3(-1.5, 0, 0))
	mast.name = "ExitWindsock"
	add_child(mast)
	var board := Node3D.new()
	board.name = "ExitBoard"
	board.position = back_spot() + Vector3(0.9, 0, -2.6)
	board.rotation.y = -PI * 0.5            # facing out (-X), towards the track
	add_child(board)
	for sx in [-0.7, 0.7]:
		board.add_child(Build.cyl(0.06, 1.8, pole, Vector3(sx, 0.9, 0), Vector3.ZERO, 5, "Post"))
	board.add_child(Build.box(Vector3(1.8, 0.7, 0.06), ToonMat.make(Color(0.92, 0.88, 0.75)), Vector3(0, 1.6, 0), Vector3.ZERO, "Board"))
	board.add_child(Build.label3d("EXIT", Vector3(0, 1.6, 0.04), Vector3.ZERO, 0.5, Color(0.70, 0.10, 0.08)))
	var lamp := Node3D.new()
	lamp.name = "ExitLamp"
	lamp.position = cell_pos(goal) + Vector3(-CELL * 0.5 - 0.6, 0, -1.9)
	add_child(lamp)
	lamp.add_child(Build.cyl(0.07, 3.6, pole, Vector3(0, 1.8, 0), Vector3.ZERO, 6, "Post"))
	lamp.add_child(Build.box(Vector3(0.6, 0.06, 0.06), pole, Vector3(0.3, 3.55, 0), Vector3.ZERO, "Arm"))
	_lamp_bulb = Build.sphere(0.14, ToonMat.make(Color(0.95, 0.85, 0.55), 0.004), Vector3(0.55, 3.4, 0), Vector3.ONE, "Bulb")
	lamp.add_child(_lamp_bulb)
	_lamp_light = OmniLight3D.new()
	_lamp_light.position = Vector3(0.55, 3.3, 0)
	_lamp_light.light_color = Color(1.0, 0.85, 0.55)
	_lamp_light.omni_range = 14.0
	_lamp_light.light_energy = 0.0
	lamp.add_child(_lamp_light)


func _lamp(on: bool) -> void:
	_lamp_light.light_energy = 2.5 if on else 0.0
	_lamp_bulb.material_override = ToonMat.make(Color(1.0, 0.9, 0.6), 0.004, 0.5, Color(1.0, 0.8, 0.4)) if on else null


## A worn dirt track from the barn yard round the maze's west side to the
## back gate, for the van (round 2: the guide drives round in the snow).
const TRACK := [Vector3(-4, 0, 60), Vector3(-20, 0, 55), Vector3(-37, 0, 35), Vector3(-37, 0, -22), Vector3(-34, 0, -26)]


func _track() -> void:
	var dirt := ToonMat.make(Color(0.46, 0.38, 0.27), 0.0)
	var rut := ToonMat.make(Color(0.34, 0.28, 0.20), 0.0)
	for i in TRACK.size() - 1:
		var a: Vector3 = TRACK[i]
		var b: Vector3 = TRACK[i + 1]
		var mid := (a + b) * 0.5
		var length := a.distance_to(b) + 3.0
		var yaw := rad_to_deg(atan2(b.x - a.x, b.z - a.z))
		var seg := Node3D.new()
		seg.name = "Track%d" % i
		seg.position = mid
		seg.rotation_degrees.y = yaw
		add_child(seg)
		seg.add_child(Build.box(Vector3(3.4, 0.02, length), dirt, Vector3(0, 0.025, 0), Vector3.ZERO, "Dirt"))
		for sx in [-0.85, 0.85]:
			seg.add_child(Build.box(Vector3(0.4, 0.02, length), rut, Vector3(sx, 0.035, 0), Vector3.ZERO, "Rut"))


func _build_curtain() -> void:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 75.0
	cyl.bottom_radius = 60.0
	cyl.height = 140.0
	cyl.radial_segments = 24
	cyl.cap_top = false
	cyl.cap_bottom = false
	var sh := Shader.new()
	sh.code = CURTAIN_SHADER
	var m := ShaderMaterial.new()
	m.shader = sh
	_curtain = MeshInstance3D.new()
	_curtain.name = "SnowCurtain"
	_curtain.mesh = cyl
	_curtain.material_override = m
	_curtain.position = Vector3(0, 60.0, 0)
	_curtain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_curtain)


func _show_curtain() -> void:
	var near := false
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_position) < CURTAIN_NEAR:
			near = true
	_curtain.visible = not near and not snow_done


## The hedges as one mesh: every wall two slightly ragged blocks (height,
## width and colour vary), plus the white caps the snow puts on them.
func _hedges(rng: RandomNumberGenerator) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var caps := SurfaceTool.new()
	caps.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new()
	body.name = "MazeWalls"
	add_child(body)
	var half := N * CELL * 0.5
	var segs: Array = []
	for x in N + 1:
		for z in N + 1:
			if x < N and walls_h[x][z]:
				segs.append([Vector3(-half + (x + 0.5) * CELL, 0, -half + z * CELL), true])
			if z < N and walls_v[x][z]:
				segs.append([Vector3(-half + x * CELL, 0, -half + (z + 0.5) * CELL), false])
	# round 2: a door in an open edge has hedge either side of its frame
	var fill := (CELL + HEDGE_T - MazeDoor.W - 0.32) * 0.5
	for dp in door_plan:
		if dp["kind"] == "fake":
			continue
		var a: Vector2i = dp["front"]
		var b: Vector2i = dp["back"]
		var mid := edge_pos(a, b)
		var wall_along_x: bool = a.x == b.x
		for sgn in [-1.0, 1.0]:
			var off: float = (MazeDoor.W * 0.5 + 0.16 + fill * 0.5) * sgn
			segs.append([mid + (Vector3(off, 0, 0) if wall_along_x else Vector3(0, 0, off)), wall_along_x, fill])
	for sg in segs:
		var at: Vector3 = sg[0]
		var along_x: bool = sg[1]
		var length: float = sg[2] if sg.size() > 2 else CELL + HEDGE_T
		for k in (2 if sg.size() <= 2 else 1):
			var h := HEDGE_H + rng.randf_range(-0.18, 0.22)
			var t := HEDGE_T + rng.randf_range(-0.05, 0.06)
			var parts := 2 if sg.size() <= 2 else 1
			var off := (k - 0.5) * length * 0.5 if parts == 2 else 0.0
			var c := at + (Vector3(off, 0, 0) if along_x else Vector3(0, 0, off))
			var plen := length / parts
			var size := Vector3(plen + 0.02, h, t) if along_x else Vector3(t, h, plen + 0.02)
			var col := Color(0.24, 0.40, 0.20).lerp(Color(0.33, 0.50, 0.24), rng.randf())
			_box(st, c + Vector3.UP * h * 0.5, size, col)
			_box(caps, c + Vector3.UP * (h + 0.07), Vector3(size.x + 0.06, 0.16, size.z + 0.06), Color(0.93, 0.95, 0.98))
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(length, HEDGE_H, HEDGE_T) if along_x else Vector3(HEDGE_T, HEDGE_H, length)
		cs.shape = sh
		cs.position = at + Vector3.UP * HEDGE_H * 0.5
		body.add_child(cs)
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var mi := MeshInstance3D.new()
	mi.name = "Hedges"
	mi.mesh = st.commit()
	mi.material_override = mat
	add_child(mi)
	_caps = MeshInstance3D.new()
	_caps.name = "SnowCaps"
	_caps.mesh = caps.commit()
	_caps.material_override = mat
	_caps.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_caps.visible = false
	add_child(_caps)


## A box into a SurfaceTool, normals set per face (winding-proof with an
## unculled material).
static func _box(st: SurfaceTool, c: Vector3, s: Vector3, col: Color) -> void:
	var h := s * 0.5
	var faces := [
		[Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)], [Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)], [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
		[Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)], [Vector3(0, 0, -1), Vector3(1, 0, 0), Vector3(0, 1, 0)]]
	for f in faces:
		var n: Vector3 = f[0]
		var u: Vector3 = f[1]
		var v: Vector3 = f[2]
		var p := c + n * h
		var a := p + (-u * h.dot(u.abs()) - v * h.dot(v.abs()))
		var b := p + (u * h.dot(u.abs()) - v * h.dot(v.abs()))
		var cc := p + (u * h.dot(u.abs()) + v * h.dot(v.abs()))
		var d := p + (-u * h.dot(u.abs()) + v * h.dot(v.abs()))
		for q in [a, cc, b, a, d, cc]:
			st.set_color(col)
			st.set_normal(n)
			st.add_vertex(q)


## Loose straw on the paths (round patches, light and dark), so a pit's
## square cover is one more patch at eye level; and the snow sheet that
## settles over all of it.
func _floor(rng: RandomNumberGenerator) -> void:
	var patches := MultiMesh.new()
	patches.transform_format = MultiMesh.TRANSFORM_3D
	patches.use_colors = true
	var disc := CylinderMesh.new()
	disc.top_radius = 1.0
	disc.bottom_radius = 1.0
	disc.height = 0.02
	disc.radial_segments = 10
	patches.mesh = disc
	var xfs: Array = []
	var cols: Array = []
	# straw blown in off the fields: clumps where the wind dropped it, mostly
	# along the hedge feet, not a pattern
	for x in N:
		for z in N:
			if rng.randf() < 0.35:
				continue
			var c := cell_pos(Vector2i(x, z))
			var clump := c + Vector3(rng.randf_range(-1.1, 1.1), 0.0, rng.randf_range(-1.1, 1.1))
			for k in rng.randi_range(1, 4):
				var p := clump + Vector3(rng.randf_range(-0.5, 0.5), 0.012 + k * 0.002, rng.randf_range(-0.5, 0.5))
				var r := rng.randf_range(0.15, 0.55)
				xfs.append(Transform3D(Basis().rotated(Vector3.UP, rng.randf() * TAU).scaled(Vector3(r * rng.randf_range(1.0, 2.2), 1, r)), p))
				cols.append(Color(0.84, 0.72, 0.42).lerp(Color(0.66, 0.54, 0.30), rng.randf()))
	patches.instance_count = xfs.size()
	for i in xfs.size():
		patches.set_instance_transform(i, xfs[i])
		patches.set_instance_color(i, cols[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = "Straw"
	mmi.multimesh = patches
	var sm := StandardMaterial3D.new()
	sm.vertex_color_use_as_albedo = true
	sm.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	sm.roughness = 1.0
	mmi.material_override = sm
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)
	_snow_floor_mat = StandardMaterial3D.new()
	_snow_floor_mat.albedo_color = Color(0.94, 0.96, 1.0, 0.0)
	_snow_floor_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_snow_floor_mat.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	_snow_floor_mat.roughness = 1.0
	var size := N * CELL + 2.0
	_snow_floor = Build.plane(Vector2(size, size), _snow_floor_mat, Vector3(0, 0.08, 0), "SnowFloor")
	_snow_floor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_snow_floor.visible = false
	add_child(_snow_floor)


## The way in: a painted arch, the flag rack, Naresh's note, the drain in the
## ditch you climb out of after a pit.
func _front_gate() -> void:
	var wood := ToonMat.make(Color(0.50, 0.36, 0.24), 0.012)
	var paint := ToonMat.make(Color(0.86, 0.80, 0.62))
	var arch := Node3D.new()
	arch.name = "FrontGate"
	arch.position = cell_pos(entrance) + Vector3(0, 0, CELL * 0.5)
	add_child(arch)
	for s in [-1.0, 1.0]:
		arch.add_child(Build.solid_box(Vector3(0.22, 3.6, 0.22), wood, Vector3(s * 1.65, 1.8, 0.35), Vector3.ZERO, "ArchPost"))
	arch.add_child(Build.box(Vector3(3.8, 0.8, 0.1), paint, Vector3(0, 3.4, 0.5), Vector3(0, 0, -1.5), "ArchBoard"))
	arch.add_child(Build.label3d("HEDGE MAZE", Vector3(0, 3.48, 0.56), Vector3(0, 0, -1.5), 0.42, Color(0.55, 0.16, 0.12)))
	arch.add_child(Build.label3d("feed chest at the far end  -  take a flag", Vector3(0, 3.12, 0.56), Vector3(0, 0, -1.5), 0.14, Color(0.25, 0.20, 0.16)))
	# the flag rack: two cattle poles with red rags, leaning in a frame
	var rack := Node3D.new()
	rack.name = "FlagRack"
	rack.position = Vector3(2.7, 0, 1.3)
	arch.add_child(rack)
	rack.add_child(Build.box(Vector3(0.9, 0.1, 0.1), wood, Vector3(0, 1.2, 0), Vector3.ZERO, "RackBar"))
	for s in [-0.3, 0.3]:
		rack.add_child(Build.cyl(0.03, 4.5, ToonMat.make(Color(0.80, 0.72, 0.45), 0.006), Vector3(s, 2.2, -0.15), Vector3(-6, 0, 0), 5, "RackPole"))
		rack.add_child(Build.box(Vector3(0.4, 0.3, 0.02), ToonMat.make(Color(0.85, 0.12, 0.10), 0.0), Vector3(s + 0.2, 4.2, -0.35), Vector3.ZERO, "RackRag"))
	var a := Build.interact_area(Vector3(1.3, 2.0, 1.0), Vector3(0, 1.0, 0), "Take a flag", func(p): give_flag(p), "FlagArea")
	a.set_meta("tag_name", "the flag rack")
	a.set_meta("prompt_fn", func(p) -> String: return "Put the flag back" if _flags.has(p) else "Take a flag (it shows above the hedges)")
	rack.add_child(a)
	NareshNote.make(arch, "maze_gate", Vector3(-1.65, 1.5, 0.48), 0.0,
		"Took me three goes. The hay hides holes - I went through twice. From the silo you can see them. Take a flag so the one up top can see you.")
	# the drain: a concrete pipe end in a ditch beside the way in
	var drain := Node3D.new()
	drain.name = "Drain"
	drain.position = Vector3(-4.2, 0, 2.2)
	arch.add_child(drain)
	drain.add_child(Build.box(Vector3(2.6, 0.04, 0.9), ToonMat.make(Color(0.30, 0.25, 0.18)), Vector3(0, 0.02, 0), Vector3.ZERO, "Ditch"))
	drain.add_child(Build.cyl(0.45, 0.8, ToonMat.make(Color(0.62, 0.62, 0.60)), Vector3(-0.9, 0.3, -0.6), Vector3(90, 0, 0), 12, "Pipe"))
	drain.add_child(Build.cyl(0.36, 0.82, ToonMat.flat(Color(0.05, 0.05, 0.06)), Vector3(-0.9, 0.3, -0.6), Vector3(90, 0, 0), 12, "PipeHole"))


## A landmark node in a cell, pushed against one of its hedges (never where
## the way goes), its front facing into the cell.
func _mark(c: Vector2i, nm: String, tag: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Mark_" + nm
	var off := Vector3.ZERO
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if wall_side(c, d):
			off = Vector3(d.x, 0, d.y) * (CELL * 0.5 - HEDGE_T * 0.5 - 0.55)
			n.rotation.y = atan2(float(-d.x), float(-d.y))
			break
	n.position = cell_pos(c) + off
	n.set_meta("tag_name", tag)
	add_child(n)
	marks[nm] = c
	_used[c] = true
	return n


## The cell at fraction `f` along the way.
func _on_way(f: float) -> Vector2i:
	return way[clampi(int(round(f * (way.size() - 1))), 1, way.size() - 2)]


func _dead_ends() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for x in N:
		for z in N:
			var c := Vector2i(x, z)
			if neighbours(c).size() == 1 and not c in way and c != goal and c != entrance and not _door_cells.has(c):
				out.append(c)
	return out


func _landmarks(rng: RandomNumberGenerator) -> void:
	var rust := ToonMat.make(Color(0.55, 0.32, 0.20))
	var wood := ToonMat.make(Color(0.52, 0.38, 0.24), 0.012)
	var dark := ToonMat.make(Color(0.20, 0.17, 0.15))
	var straw := ToonMat.make(Color(0.86, 0.74, 0.40))
	var cloth := ToonMat.make(Color(0.36, 0.30, 0.46))
	# tall ones, seen by both (the guide's anchors)
	var m := _mark(_on_way(0.14), "rooster", "the weathervane rooster")
	m.add_child(Build.cyl(0.07, 6.0, rust, Vector3(0, 3.0, 0), Vector3.ZERO, 6, "Pole"))
	m.add_child(Build.box(Vector3(0.9, 0.06, 0.06), rust, Vector3(0, 5.4, 0), Vector3.ZERO, "NS"))
	m.add_child(Build.box(Vector3(0.06, 0.06, 0.9), rust, Vector3(0, 5.4, 0), Vector3.ZERO, "EW"))
	m.add_child(Build.box(Vector3(0.7, 0.55, 0.08), ToonMat.make(Color(0.20, 0.20, 0.22)), Vector3(0, 6.3, 0), Vector3.ZERO, "Rooster"))
	m.add_child(Build.box(Vector3(0.18, 0.22, 0.09), ToonMat.make(Color(0.78, 0.15, 0.12)), Vector3(0.28, 6.62, 0), Vector3.ZERO, "Comb"))
	m = _mark(_on_way(0.33), "horse", "the carousel horse")
	var white := ToonMat.make(Color(0.95, 0.92, 0.86))
	m.add_child(Build.cyl(0.05, 4.2, ToonMat.make(Color(0.86, 0.72, 0.30), 0.008, 0.4), Vector3(0, 2.1, 0), Vector3.ZERO, 8, "BrassPole"))
	m.add_child(Build.box(Vector3(0.35, 0.45, 1.2), white, Vector3(0, 2.3, 0), Vector3.ZERO, "HorseBody"))
	m.add_child(Build.box(Vector3(0.25, 0.6, 0.3), white, Vector3(0, 2.75, 0.62), Vector3(-30, 0, 0), "HorseNeck"))
	m.add_child(Build.box(Vector3(0.36, 0.08, 0.5), ToonMat.make(Color(0.80, 0.18, 0.30)), Vector3(0, 2.55, -0.05), Vector3.ZERO, "Saddle"))
	for s in [-1.0, 1.0]:
		m.add_child(Build.box(Vector3(0.08, 0.6, 0.08), white, Vector3(s * 0.12, 1.85, s * 0.4), Vector3(s * 20, 0, 0), "Leg"))
	m = _mark(_on_way(0.70), "tree", "the dead tree")
	var bark := ToonMat.make(Color(0.36, 0.30, 0.26))
	m.add_child(Build.solid_cyl(0.25, 4.5, bark, Vector3(0, 2.25, 0), Vector3(0, 0, 4), "Trunk"))
	for k in 4:
		var yaw := k * 1.7
		m.add_child(Build.cyl(0.07, 2.0, bark, Vector3(cos(yaw) * 0.6, 4.0 + k * 0.3, sin(yaw) * 0.6), Vector3(sin(yaw) * 50, 0, -cos(yaw) * 50), 5, "Branch"))
	for k in 5:
		var crow := Node3D.new()
		crow.name = "Crow%d" % k
		var yaw := k * 1.25
		crow.position = Vector3(cos(yaw) * 1.1, 4.6 + (k % 3) * 0.35, sin(yaw) * 1.1)
		crow.add_child(Build.sphere(0.13, ToonMat.make(Color(0.08, 0.08, 0.10), 0.006), Vector3.ZERO, Vector3(1, 0.9, 1.5), "Body"))
		crow.set_meta("home", crow.position)
		m.add_child(crow)
		_crows.append(crow)
	m = _mark(_on_way(0.86), "elevator", "the hay elevator")
	m.add_child(Build.box(Vector3(0.7, 0.12, 6.5), rust, Vector3(0, 2.6, 0.4), Vector3(38, 0, 0), "Ramp"))
	for s in [-0.3, 0.3]:
		m.add_child(Build.box(Vector3(0.08, 2.4, 0.08), rust, Vector3(s, 1.2, 1.4), Vector3.ZERO, "Leg"))
	# low ones, only the walker sees them: the plank before a turn, the broken
	# chair just after it on the right way, its twin (whole) the wrong way
	var turn := _turn_after(0.55)
	m = _mark(way[turn - 1], "plank", "the wooden plank")
	m.add_child(Build.box(Vector3(CELL - HEDGE_T, 0.03, 0.7), ToonMat.make(Color(0.24, 0.19, 0.13)), Vector3(0, 0.02, 0), Vector3.ZERO, "Ditch"))
	m.add_child(Build.box(Vector3(0.45, 0.07, 1.4), wood, Vector3(0.3, 0.07, 0), Vector3(0, 8, 0), "Plank"))
	_align_across(m, way[turn - 2], way[turn - 1])
	_chair(_mark(way[mini(turn + 2, way.size() - 2)], "broken_chair", "the broken chair"), true)
	var twin := _branch_near(way[turn])
	if twin.x >= 0:
		_chair(_mark(twin, "chair", "a chair"), false)
	m = _mark(_on_way(0.62), "well", "the old well")
	m.add_child(Build.solid_cyl(0.6, 0.8, ToonMat.make(Color(0.62, 0.60, 0.56)), Vector3(0, 0.4, 0), Vector3.ZERO, "Well"))
	for s in [-1.0, 1.0]:
		m.add_child(Build.box(Vector3(0.08, 1.6, 0.08), wood, Vector3(s * 0.55, 1.2, 0), Vector3.ZERO, "Post"))
	m.add_child(Build.box(Vector3(1.2, 0.08, 0.08), wood, Vector3(0, 1.95, 0), Vector3.ZERO, "Beam"))
	m.add_child(Build.cyl(0.14, 0.24, ToonMat.make(Color(0.45, 0.47, 0.50)), Vector3(0, 1.4, 0), Vector3.ZERO, 8, "Bucket"))
	m = _mark(_on_way(0.77), "bathtub", "the bathtub of flowers")
	m.add_child(Build.solid_box(Vector3(0.75, 0.55, 1.5), ToonMat.make(Color(0.94, 0.94, 0.92)), Vector3(0, 0.38, 0), Vector3.ZERO, "Tub"))
	var petals := [Color(0.90, 0.30, 0.45), Color(0.95, 0.80, 0.25), Color(0.65, 0.40, 0.85)]
	for k in 7:
		m.add_child(Build.sphere(0.12, ToonMat.make(petals[k % 3], 0.0), Vector3(rng.randf_range(-0.25, 0.25), 0.72, rng.randf_range(-0.6, 0.6)), Vector3.ONE, "Flower"))
	m = _mark(_on_way(0.93), "phonebox", "the red phone box")
	m.add_child(Build.solid_box(Vector3(0.95, 2.4, 0.95), ToonMat.make(Color(0.80, 0.12, 0.10)), Vector3(0, 1.2, 0), Vector3.ZERO, "Box"))
	m.add_child(Build.box(Vector3(0.7, 1.2, 0.02), ToonMat.make(Color(0.70, 0.82, 0.86)), Vector3(0, 1.3, 0.48), Vector3.ZERO, "Glass"))
	m.add_child(Build.label3d("TELEPHONE", Vector3(0, 2.22, 0.49), Vector3.ZERO, 0.1, Color.WHITE))
	m = _mark(_on_way(0.24), "tyres", "the stack of tyres")
	for k in 4:
		m.add_child(Build.cyl(0.42, 0.24, dark, Vector3(rng.randf_range(-0.05, 0.05), 0.12 + k * 0.24, 0), Vector3.ZERO, 14, "Tyre"))
	# twins: the scarecrow with a lantern on the way, one without in a dead end
	_scarecrow(_mark(_on_way(0.45), "scarecrow_lantern", "the scarecrow with the lantern"), true, straw, cloth)
	var de := _dead_ends()
	if de.size() > 0:
		_scarecrow(_mark(de[de.size() / 2], "scarecrow", "a scarecrow"), false, straw, cloth)
	# painted arrows on the ground at junctions on the way, two of them wrong
	var painted := 0
	for i in range(2, way.size() - 2):
		if painted >= 6 or neighbours(way[i]).size() < 3 or i % 3 != 0:
			continue
		var to: Vector2i = way[i + 1]
		if painted == 2 or painted == 4:
			for n in neighbours(way[i]):
				if n != way[i + 1] and n != way[i - 1]:
					to = n
					break
		var d := to - way[i]
		var arrow := Node3D.new()
		arrow.name = "Arrow%d" % painted
		arrow.position = cell_pos(way[i]) + Vector3(0, 0.03, 0)
		arrow.rotation.y = atan2(float(d.x), float(d.y))
		var paint := ToonMat.flat(Color(0.95, 0.93, 0.85))
		arrow.add_child(Build.box(Vector3(0.25, 0.01, 1.2), paint, Vector3(0, 0, -0.2), Vector3.ZERO, "Shaft"))
		arrow.add_child(Build.box(Vector3(0.22, 0.01, 0.7), paint, Vector3(0.18, 0, 0.45), Vector3(0, 40, 0), "HeadL"))
		arrow.add_child(Build.box(Vector3(0.22, 0.01, 0.7), paint, Vector3(-0.18, 0, 0.45), Vector3(0, -40, 0), "HeadR"))
		add_child(arrow)
		painted += 1


## Index of the first turn on the way after fraction `f` of it.
func _turn_after(f: float) -> int:
	for i in range(maxi(3, int(f * way.size())), way.size() - 3):
		if (way[i] - way[i - 1]) != (way[i + 1] - way[i]):
			return i
	return way.size() / 2


## A cell next to `c` that is off the way (a wrong turn), or (-1, -1).
func _branch_near(c: Vector2i) -> Vector2i:
	for n in neighbours(c):
		if not n in way:
			return n
	return Vector2i(-1, -1)


## The ditch lies across the way from `a` into `b`, in the middle of `b`.
func _align_across(m: Node3D, a: Vector2i, b: Vector2i) -> void:
	var d := b - a
	m.rotation.y = atan2(float(d.x), float(d.y)) + PI * 0.5
	m.position = cell_pos(b)


func _chair(m: Node3D, broken: bool) -> void:
	var wood := ToonMat.make(Color(0.60, 0.42, 0.26), 0.01)
	m.add_child(Build.box(Vector3(0.5, 0.06, 0.5), wood, Vector3(0, 0.48, 0), Vector3(0, 0, 9 if broken else 0), "Seat"))
	m.add_child(Build.box(Vector3(0.5, 0.6, 0.06), wood, Vector3(0, 0.8, -0.22), Vector3(-12 if broken else 0, 0, 0), "Back"))
	for k in 4:
		var x := 0.2 if k % 2 == 0 else -0.2
		var z := 0.2 if k < 2 else -0.2
		if broken and k == 1:
			m.add_child(Build.box(Vector3(0.05, 0.2, 0.05), wood, Vector3(x, 0.05, z + 0.3), Vector3(80, 0, 0), "LegOff"))
			continue
		m.add_child(Build.box(Vector3(0.05, 0.48, 0.05), wood, Vector3(x, 0.24, z), Vector3.ZERO, "Leg"))


func _scarecrow(m: Node3D, lantern: bool, straw: Material, cloth: Material) -> void:
	var pole := ToonMat.make(Color(0.45, 0.33, 0.2))
	m.add_child(Build.cyl(0.05, 2.3, pole, Vector3(0, 1.15, 0), Vector3.ZERO, 5, "Pole"))
	m.add_child(Build.box(Vector3(1.5, 0.08, 0.08), pole, Vector3(0, 1.75, 0), Vector3.ZERO, "Arms"))
	m.add_child(Build.box(Vector3(0.55, 0.75, 0.3), cloth, Vector3(0, 1.45, 0), Vector3.ZERO, "Coat"))
	m.add_child(Build.sphere(0.2, straw, Vector3(0, 2.15, 0), Vector3.ONE, "Head"))
	m.add_child(Build.cone(0.3, 0.35, ToonMat.make(Color(0.30, 0.22, 0.16)), Vector3(0, 2.4, 0), Vector3.ZERO, 10, "Hat"))
	if lantern:
		m.add_child(Build.box(Vector3(0.16, 0.24, 0.16), ToonMat.make(Color(0.95, 0.75, 0.30), 0.006, 0.5, Color(1.0, 0.7, 0.3)), Vector3(0.7, 1.55, 0), Vector3.ZERO, "Lantern"))


# --- the pits ------------------------------------------------------------------------

## Five pits: two on the way (to one side of a straight run, room to step
## round), three in dead ends. Rotten boards and loose hay over a dark hole.
func _place_pits() -> void:
	var on_way: Array[int] = []
	for i in range(4, way.size() - 3):
		var c := way[i]
		if (c - way[i - 1]) != (way[i + 1] - c) or c in CENTRE or _used.has(c):
			continue
		if on_way.is_empty() and i > way.size() / 4 or on_way.size() == 1 and i > way.size() * 2 / 3:
			on_way.append(i)
	for i in on_way:
		var c := way[i]
		var d := way[i + 1] - c
		var off := Vector3(d.y, 0, d.x) * 0.75          # across the way
		var half := Vector2(0.7, 1.0) if d.x == 0 else Vector2(1.0, 0.7)
		_pit(c, cell_pos(c) + off, half)
	var de := _dead_ends()
	var picked := 0
	var k := 0
	while picked < 3 and k < de.size():
		if not _used.has(de[k]):
			_pit(de[k], cell_pos(de[k]), Vector2(0.9, 0.9))
			picked += 1
		k += maxi(1, de.size() / 4)


func _pit(c: Vector2i, at: Vector3, half: Vector2) -> void:
	_used[c] = true
	var cover := Node3D.new()
	cover.name = "PitCover%d" % pits.size()
	cover.position = at
	add_child(cover)
	cover.add_child(Build.box(Vector3(half.x * 2.0, 0.04, half.y * 2.0), ToonMat.make(Color(0.40, 0.32, 0.19), 0.0), Vector3(0, 0.03, 0), Vector3.ZERO, "Hay"))
	for k in 3:
		cover.add_child(Build.box(Vector3(half.x * 2.0 - 0.1, 0.03, 0.18), ToonMat.make(Color(0.34, 0.28, 0.20), 0.0),
			Vector3(0, 0.055, -half.y + 0.3 + k * (half.y * 2.0 - 0.6) / 2.0), Vector3(0, 0, 2.0 - k * 2.0), "Board"))
	var hole := Build.box(Vector3(half.x * 2.0, 0.02, half.y * 2.0), ToonMat.flat(Color(0.02, 0.02, 0.03)), at + Vector3(0, 0.025, 0), Vector3.ZERO, "PitHole%d" % pits.size())
	hole.visible = false
	add_child(hole)
	pits.append({"cell": c, "centre": at, "half": half, "cover": cover, "hole": hole, "open_t": 0.0})


func _check_pits(delta: float) -> void:
	for pt in pits:
		if pt["open_t"] > 0.0:
			pt["open_t"] -= delta
			if pt["open_t"] <= 0.0:
				(pt["cover"] as Node3D).position.y = 0.0
				(pt["cover"] as Node3D).visible = true
				(pt["hole"] as Node3D).visible = false
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if _falling.has(p) or p.seat != null or p.ladder != null or p.knocked_t > 0.0 or not p.is_on_floor():
			continue
		var l := global_transform.affine_inverse() * p.global_position
		if l.y > 0.6:
			continue
		for pt in pits:
			var c: Vector3 = pt["centre"]
			var h: Vector2 = pt["half"]
			if absf(l.x - c.x) < h.x - 0.12 and absf(l.z - c.z) < h.y - 0.12:
				_fall_in(p, pt)
				break


## The boards crack, you drop into the dark, and you climb out of the drain
## by the front gate, straw everywhere.
func _fall_in(p: PlayerRig, pt: Dictionary) -> void:
	falls += 1
	_falling[p] = true
	var cover := pt["cover"] as Node3D
	var at := cover.global_position
	Sfx.play3d("crack", at, 6.0)
	print("[maze] P%d fell into a pit at %s" % [p.index + 1, str(pt["cell"])])
	var tw := create_tween()
	tw.tween_property(cover, "position:y", -0.8, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): cover.visible = false)
	(pt["hole"] as Node3D).visible = true
	pt["open_t"] = 8.0
	p.taken_hold = PIT_FALL_S + 0.6
	p.fade_color = Color(0.0, 0.0, 0.0)
	var drop := create_tween()
	drop.tween_interval(0.15)
	drop.tween_property(p, "whiteout", 1.0, 0.3)
	drop.parallel().tween_property(p, "global_position", p.global_position + Vector3.DOWN * 1.4, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	drop.tween_interval(PIT_FALL_S - 0.45)
	drop.tween_callback(func(): _out_of_drain(p))
	drop.tween_property(p, "whiteout", 0.0, 0.7)
	drop.tween_callback(func():
		p.fade_color = PlayerRig.WHITE_FADE
		_falling.erase(p))
	var other := _other(p)
	if other != null and other.global_position.distance_to(at) < 90.0:
		other.say("CRACK - P%d went through the floor!" % (p.index + 1), 3.0)


func _out_of_drain(p: PlayerRig) -> void:
	p.global_position = _ground(global_transform * (gate_spot() + Vector3(-1.2, 0, 0.4)))
	p.velocity = Vector3.ZERO
	p.yaw = global_rotation.y        # facing in: local -Z
	p.rotation.y = p.yaw
	p.reset_physics_interpolation()
	p.taken_hold = 0.6
	p.straw(4.0)
	Sfx.play3d("hit_soft", p.global_position, 0.0)
	p.say("You climb out of a drain by the front gate, straw in your hair. Back to the start.", 4.0)


func _ground(p: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p + Vector3.UP * 4.0, p + Vector3.DOWN * 6.0)
	q.collision_mask = 1
	var hit := space.intersect_ray(q)
	return (hit["position"] as Vector3) + Vector3.UP * 0.1 if not hit.is_empty() else p + Vector3.UP * 0.3


func _other(p: PlayerRig) -> PlayerRig:
	for n in get_tree().get_nodes_in_group("player"):
		if n != p:
			return n as PlayerRig
	return null


# --- the jump scares -----------------------------------------------------------------

## Five turns off the way (wrong turns, dead ends): walking back out of one,
## something pops out of the hedge straight ahead of you. Never on the way in.
func _place_scares() -> void:
	var kinds := ["scarecrow", "crow", "cow", "mannequin", "lantern"]
	var cands: Array = []
	for x in N:
		for z in N:
			var c := Vector2i(x, z)
			if c in way or c in CENTRE or not dist.has(c) or _used.has(c):
				continue
			for n in neighbours(c):
				# walking back = from the deeper cell n into c; the hedge straight ahead
				if int(dist[n]) != int(dist[c]) + 1:
					continue
				var d := c - n
				if wall_side(c, d):
					cands.append([c, n, d])
	var used := {}
	var step := maxi(1, cands.size() / kinds.size())
	var k := 0
	var i := 0
	while k < kinds.size() and i < cands.size():
		var cd: Array = cands[i]
		i += step
		if used.has(cd[0]):
			i = i - step + 1
			continue
		used[cd[0]] = true
		_scare(cd[0], cd[1], cd[2], kinds[k])
		k += 1


func _scare(c: Vector2i, from: Vector2i, d: Vector2i, kind: String) -> void:
	var root := Node3D.new()
	root.name = "Scare_" + kind
	# in the hedge ahead of you as you walk back, facing you
	root.position = cell_pos(c) + Vector3(d.x, 0, d.y) * (CELL * 0.5)
	root.rotation.y = atan2(float(-d.x), float(-d.y))
	add_child(root)
	var fig := Node3D.new()
	fig.name = "Figure"
	root.add_child(fig)
	var hide := Vector3(0, 0, -0.02)
	var show := Vector3(0, 0, 0.75)
	match kind:
		"scarecrow":
			_scarecrow(fig, false, ToonMat.make(Color(0.86, 0.74, 0.40)), ToonMat.make(Color(0.30, 0.14, 0.12)))
			fig.scale = Vector3(1, 1, 0.6)
		"crow":
			var black := ToonMat.make(Color(0.06, 0.06, 0.08), 0.008)
			fig.add_child(Build.sphere(0.18, black, Vector3(0, 1.8, 0), Vector3(1.4, 0.9, 1.2), "Crow"))
			for s in [-1.0, 1.0]:
				fig.add_child(Build.box(Vector3(0.6, 0.04, 0.22), black, Vector3(s * 0.4, 1.85, 0), Vector3(0, 0, s * 25), "Wing"))
			show = Vector3(0, 0.3, 1.6)
		"cow":
			fig.add_child(Build.box(Vector3(0.5, 0.55, 0.42), ToonMat.make(Color(0.95, 0.94, 0.90)), Vector3(0, 1.3, 0), Vector3.ZERO, "Head"))
			fig.add_child(Build.box(Vector3(0.52, 0.25, 0.3), ToonMat.make(Color(0.12, 0.10, 0.10)), Vector3(0, 1.45, 0.0), Vector3.ZERO, "Patch"))
			fig.add_child(Build.box(Vector3(0.45, 0.25, 0.12), ToonMat.make(Color(0.90, 0.62, 0.62)), Vector3(0, 1.12, 0.15), Vector3.ZERO, "Nose"))
			for s in [-1.0, 1.0]:
				fig.add_child(Build.cone(0.05, 0.22, ToonMat.make(Color(0.92, 0.88, 0.75)), Vector3(s * 0.22, 1.66, 0), Vector3(0, 0, -s * 40), 6, "Horn"))
			show = Vector3(0, 0, 0.55)
		"mannequin":
			var skin := ToonMat.make(Color(0.88, 0.84, 0.78))
			fig.add_child(Build.box(Vector3(0.5, 0.95, 0.3), ToonMat.make(Color(0.85, 0.72, 0.15)), Vector3(0, 1.25, 0), Vector3.ZERO, "Raincoat"))
			fig.add_child(Build.sphere(0.17, skin, Vector3(0, 1.92, 0), Vector3(1, 1.2, 1), "Head"))
			for s in [-1.0, 1.0]:
				fig.add_child(Build.box(Vector3(0.1, 0.7, 0.1), skin, Vector3(s * 0.32, 1.3, 0), Vector3.ZERO, "Arm"))
		"lantern":
			fig.add_child(Build.box(Vector3(0.02, 0.9, 0.02), ToonMat.make(Color(0.3, 0.25, 0.2)), Vector3(0, 2.4, 0), Vector3.ZERO, "Rope"))
			fig.add_child(Build.box(Vector3(0.24, 0.34, 0.24), ToonMat.make(Color(0.95, 0.75, 0.30), 0.006, 0.5, Color(1.0, 0.7, 0.3)), Vector3(0, 1.8, 0), Vector3.ZERO, "Lantern"))
			show = Vector3(0, 0, 0.6)
	fig.position = hide
	scares.append({"cell": c, "from": from, "node": fig, "kind": kind, "t": 0.0, "done": false, "hide": hide, "show": show})


func _check_scares(delta: float) -> void:
	for sc in scares:
		sc["t"] = maxf(0.0, float(sc["t"]) - delta)
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		var c := cell_at(p.global_position)
		var was: Vector2i = _last_cell.get(p, Vector2i(-1, -1))
		_last_cell[p] = c
		if c == was or c.x < 0:
			continue
		for sc in scares:
			if sc["cell"] == c and sc["from"] == was and float(sc["t"]) <= 0.0:
				pop(sc, p)


## A scare pops out at `p` (tests call it too).
func pop(sc: Dictionary, p: PlayerRig) -> void:
	sc["t"] = SCARE_WAIT
	scares_fired += 1
	var fig := sc["node"] as Node3D
	var tw := create_tween()
	tw.tween_property(fig, "position", sc["show"], 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if sc["kind"] == "lantern":
		tw.tween_property(fig, "rotation:z", 0.5, 0.4)
		tw.tween_property(fig, "rotation:z", -0.4, 0.5)
		tw.tween_property(fig, "rotation:z", 0.0, 0.5)
	else:
		tw.tween_interval(2.5)
	tw.tween_property(fig, "position", sc["hide"], 0.6)
	var at := fig.global_position + Vector3.UP * 1.5
	match sc["kind"]:
		"crow": Sfx.play3d("caw", at, 6.0)
		"cow": Sfx.play3d("moo", at, 6.0)
		_: Sfx.play3d("hit_soft", at, 4.0)
	if not sc["done"]:
		sc["done"] = true
		Sfx.play3d("sting", p.global_position + Vector3.UP * 1.6, 2.0)
	p.jolt()
	print("[maze] scare '%s' popped at P%d" % [sc["kind"], p.index + 1])


# --- the courtyard, the bell, the chest ---------------------------------------------

## S2: the farm bell in the middle. E rings it; the guide hears where it is
## from the silo, even in the snow.
func _courtyard() -> void:
	_bell = Node3D.new()
	_bell.name = "FarmBell"
	_bell.position = (cell_pos(CENTRE[0]) + cell_pos(CENTRE[3])) * 0.5
	add_child(_bell)
	var wood := ToonMat.make(Color(0.45, 0.32, 0.22), 0.012)
	for s in [-1.0, 1.0]:
		_bell.add_child(Build.solid_box(Vector3(0.18, 2.6, 0.18), wood, Vector3(s * 0.8, 1.3, 0), Vector3.ZERO, "Post"))
	_bell.add_child(Build.box(Vector3(1.9, 0.18, 0.2), wood, Vector3(0, 2.6, 0), Vector3.ZERO, "Beam"))
	_bell.add_child(Build.cone(0.4, 0.55, ToonMat.make(Color(0.70, 0.55, 0.25), 0.01, 0.35), Vector3(0, 2.15, 0), Vector3.ZERO, 14, "Bell"))
	var a := Build.interact_area(Vector3(1.6, 2.0, 1.2), Vector3(0, 1.0, 0), "Ring the bell", func(p): ring(p), "BellArea")
	a.set_meta("tag_name", "the bell")
	_bell.add_child(a)
	NareshNote.make(_bell, "maze_bell", Vector3(0.8, 1.4, 0.1), 0.0,
		"Half way. Ring this and whoever's up top can hear where you are. He rang it for ages.")


func ring(_p = null) -> void:
	Sfx.play3d("bell", _bell.global_position + Vector3.UP * 2.2, 14.0)
	var b := _bell.get_node("Bell") as Node3D
	var tw := create_tween()
	tw.tween_property(b, "rotation:z", 0.35, 0.15)
	tw.tween_property(b, "rotation:z", -0.25, 0.25)
	tw.tween_property(b, "rotation:z", 0.0, 0.3)


func _chest() -> void:
	var chest := Node3D.new()
	chest.name = "FeedChest"
	chest.position = cell_pos(goal) + Vector3(0.6, 0, -0.6)
	add_child(chest)
	var wood := ToonMat.make(Color(0.48, 0.34, 0.22), 0.012)
	chest.add_child(Build.solid_box(Vector3(1.4, 0.7, 0.8), wood, Vector3(0, 0.35, 0), Vector3.ZERO, "Chest"))
	_chest_lid = Node3D.new()
	_chest_lid.position = Vector3(0, 0.73, -0.4)
	chest.add_child(_chest_lid)
	_chest_lid.add_child(Build.box(Vector3(1.42, 0.08, 0.82), wood, Vector3(0, 0.04, 0.41), Vector3.ZERO, "Lid"))
	var a := Build.interact_area(Vector3(1.6, 1.0, 1.2), Vector3(0, 0.5, 0.2), "Open the feed chest", func(p): open_chest(p), "ChestArea")
	a.set_meta("tag_name", "the feed chest")
	a.set_meta("prompt_fn", func(_p) -> String: return "" if chest_open else "Open the feed chest")
	chest.add_child(a)
	# the back gate in the -X hedge of the last cell: opens from inside, outwards
	_back_gate = Node3D.new()
	_back_gate.name = "BackGate"
	_back_gate.position = cell_pos(goal) + Vector3(-CELL * 0.5, 0, CELL * 0.5 - HEDGE_T * 0.5)
	add_child(_back_gate)
	var gw := ToonMat.make(Color(0.55, 0.40, 0.26), 0.012)
	var leaf := Node3D.new()
	leaf.name = "Leaf"
	_back_gate.add_child(leaf)
	var span := CELL - HEDGE_T
	for k in 4:
		leaf.add_child(Build.box(Vector3(0.1, 0.12, span), gw, Vector3(0, 0.3 + k * 0.42, -span * 0.5), Vector3.ZERO, "Rail"))
	for z in [-0.05, -span * 0.5, -span + 0.05]:
		leaf.add_child(Build.box(Vector3(0.12, 1.7, 0.12), gw, Vector3(0, 0.85, z), Vector3.ZERO, "Stile"))
	_back_body = StaticBody3D.new()
	_back_body.name = "BackGateBody"
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.3, 2.0, span)
	cs.shape = sh
	cs.position = Vector3(0, 1.0, -span * 0.5)
	_back_body.add_child(cs)
	leaf.add_child(_back_body)
	var g := Build.interact_area(Vector3(1.2, 2.0, 2.4), Vector3(0.7, 1.0, -span * 0.5), "Open the back gate", func(p): open_back(p), "BackGateArea")
	g.set_meta("tag_name", "the back gate")
	g.set_meta("prompt_fn", func(_p) -> String: return "" if back_open else "Open the back gate")
	_back_gate.add_child(g)
	_zone_layer = g.collision_layer


## A spent use zone stops catching the look ray (the open back gate's zone
## hid the spare lying behind it: nothing could be picked up there).
func _zones() -> void:
	(_back_gate.get_node("BackGateArea") as Area3D).collision_layer = 0 if back_open else _zone_layer
	(find_child("ChestArea", true, false) as Area3D).collision_layer = 0 if chest_open else _zone_layer


func open_back(_p = null) -> void:
	if back_open:
		return
	back_open = true
	_zones()
	Sfx.play3d("latch", _back_gate.global_position + Vector3.UP, 0.0)
	Sfx.play3d("creak", _back_gate.global_position + Vector3.UP, 0.0)
	var leaf := _back_gate.get_node("Leaf") as Node3D
	create_tween().tween_property(leaf, "rotation:y", deg_to_rad(100.0), 1.2).set_trans(Tween.TRANS_SINE)
	_back_body.process_mode = Node.PROCESS_MODE_DISABLED


func open_chest(p: PlayerRig) -> void:
	if chest_open:
		return
	chest_open = true
	_zones()
	var tw := create_tween()
	tw.tween_property(_chest_lid, "rotation:x", deg_to_rad(-105.0), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play3d("latch", _chest_lid.global_position, 0.0)
	var root := get_tree().get_first_node_in_group("world_root")
	var base := cell_pos(goal) + Vector3(0.6, 0, -0.6)
	var wheel := SpareWheel.new()
	wheel.name = "MazeSpare"
	root.add_child(wheel)
	wheel.global_position = global_transform * (base + Vector3(-1.3, 0.5, 1.0))
	var can := FuelCan.create(10.0)
	can.name = "MazeFuel"
	root.add_child(can)
	can.global_position = global_transform * (base + Vector3(0.0, 0.9, 1.0))
	var jug := CoolantJug.new()
	jug.name = "MazeCoolant"
	root.add_child(jug)
	jug.global_position = global_transform * (base + Vector3(0.8, 0.9, 1.0))
	_rewards = [wheel, can, jug]
	# pinned inside the lid: you see it as it opens (in front of the chest its
	# read zone hid the spare from the look: 2026-10-12)
	var note := NareshNote.make(_chest_lid, "maze_push", Vector3(0.35, 0.1, 0.5), 0.0,
		"If the one driving won't stop for snacks: shove them out. In the van, G (pad: hold RB). He did it to me twice.")
	note.rotation_degrees = Vector3(-90, 0, 0)
	_rewards.append(note)
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["maze_done"] = true
		st.flags["push"] = true
	p.say("Inside the feed chest: a spare tyre, a can of fuel and a jug of coolant. And a note.", 6.0)
	print("[maze] chest opened by P%d" % (p.index + 1))
	_end_snow()


# --- the walker's flag ---------------------------------------------------------------

## A bamboo cattle pole with a red rag, worn on your back: its tip shows above
## the hedges. Your own camera doesn't draw it.
func give_flag(p: PlayerRig) -> void:
	if _flags.has(p):
		_drop_flag(p)
		return
	var f := Node3D.new()
	f.name = "WalkerFlag%d" % (p.index + 1)
	var layer := 1 << (1 + p.index)
	var pole := Build.cyl(0.03, 4.4, ToonMat.make(Color(0.80, 0.72, 0.45), 0.0), Vector3(0, 2.4, 0), Vector3.ZERO, 5, "Pole")
	var rag := Build.box(Vector3(0.6, 0.4, 0.02), ToonMat.make(Color(0.90, 0.10, 0.08), 0.0, 1.0, Color(0.5, 0.0, 0.0)), Vector3(0.3, 4.35, 0), Vector3.ZERO, "Rag")
	for mi in [pole, rag]:
		(mi as MeshInstance3D).layers = layer
		f.add_child(mi)
	f.top_level = true
	p.add_child(f)
	_flags[p] = f
	_rack_poles()
	Sfx.play3d("pickup", p.global_position + Vector3.UP, 0.0)
	p.say("You take a flag on a pole: it sticks up above the hedges, so the one on the silo can see where you are.", 4.0)


func _drop_flag(p) -> void:
	if _flags.has(p):
		var f = _flags[p]
		if is_instance_valid(f):
			(f as Node).queue_free()
		_flags.erase(p)
		_rack_poles()


## The rack shows the poles still in it.
func _rack_poles() -> void:
	var rack := find_child("FlagRack", true, false)
	if rack == null:
		return
	var k := 0
	for n in rack.get_children():
		if String(n.name).begins_with("RackPole") or String(n.name).begins_with("RackRag"):
			(n as Node3D).visible = (k / 2) >= _flags.size()
			k += 1


## S13: dropped in the snow (a fright while running): it lies there until
## someone picks it up again.
func drop_flag(p: PlayerRig) -> void:
	_drop_flag(p)
	var lying := Node3D.new()
	lying.name = "DroppedFlag"
	add_child(lying)
	lying.global_position = p.global_position + Vector3(0, 0.05, 0)
	lying.rotation = Vector3(0, p.yaw, PI * 0.5)
	lying.add_child(Build.cyl(0.03, 4.4, ToonMat.make(Color(0.80, 0.72, 0.45), 0.0), Vector3(0, 2.2, 0), Vector3.ZERO, 5, "Pole"))
	lying.add_child(Build.box(Vector3(0.6, 0.4, 0.02), ToonMat.make(Color(0.90, 0.10, 0.08), 0.0), Vector3(0.3, 4.2, 0), Vector3.ZERO, "Rag"))
	var a := Build.interact_area(Vector3(1.2, 1.2, 1.2), Vector3.ZERO, "Pick up the flag", func(q):
		give_flag(q)
		lying.queue_free(), "FlagArea")
	a.top_level = true
	lying.add_child(a)
	a.global_position = lying.global_position + Vector3.UP * 0.4


func has_flag(p: PlayerRig) -> bool:
	return _flags.has(p)


func _move_flags() -> void:
	for p in _flags.keys():
		if not is_instance_valid(p):
			_flags.erase(p)
			continue
		var q := p as PlayerRig
		if q.seat != null or q.global_position.distance_to(global_position) > 70.0:
			_drop_flag(q)
			continue
		var f := _flags[q] as Node3D
		var o := q.get_global_transform_interpolated().origin
		f.global_transform = Transform3D(Basis(Vector3.UP, q.yaw), o + Basis(Vector3.UP, q.yaw) * Vector3(0, 0, 0.25))


# --- the snow ------------------------------------------------------------------------

func _weather_node() -> Node:
	if _weather == null or not is_instance_valid(_weather):
		_weather = get_tree().get_first_node_in_group("weather")
	return _weather


## The walker reached the courtyard: the snow comes on hard.
func start_snow() -> void:
	if snowing or snow_done:
		return
	snowing = true
	print("[maze] the snow starts")
	var w := _weather_node()
	if w != null:
		w.set("heavy_target", 1.0)
	_lamp(true)
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 90.0:
			q.say("The sky goes dark over the maze, the wind gets up... and it starts to snow. Hard.", 5.0)
	var st = get_tree().current_scene.get("story")
	if st != null and not st.flags.has("maze_snow_text"):
		st.flags["maze_snow_text"] = true
		for who in 2:
			st._send_phone(who, "Naresh (an old text)", "it's SNOWING. in the valley. he says it's a sign")


func _end_snow() -> void:
	if not snowing:
		return
	snowing = false
	snow_done = true
	print("[maze] the snow clears")
	var w := _weather_node()
	if w != null:
		w.set("heavy_target", 0.0)
		w.call("clear_spell", CLEAR_S)


func _physics_process(delta: float) -> void:
	_check_pits(delta)
	_check_scares(delta)
	if not snowing and not snow_done:
		for n in get_tree().get_nodes_in_group("player"):
			if cell_at((n as Node3D).global_position) in CENTRE:
				start_snow()
				break
	elif snowing:
		for n in get_tree().get_nodes_in_group("player"):
			if cell_at((n as Node3D).global_position) == goal:
				_end_snow()
				break
	# the snow settles while it falls (~20 s), and melts in the sun after (~90 s)
	if snowing:
		snow = move_toward(snow, 1.0, delta / (SNOW_IN * 2.0))
	else:
		snow = move_toward(snow, 0.0, delta / 90.0)
	_show_snow()
	_footprints(delta)
	_crows_check(delta)
	_show_curtain()
	_oneways()


## S12: a one-way door swings shut and latches once you're through.
func _oneways() -> void:
	for d in doors:
		var md := d as MazeDoor
		if md.kind != "oneway" or not md.is_open:
			continue
		var through := false
		var in_way := false
		for n in get_tree().get_nodes_in_group("player"):
			var sd := md.side_of((n as Node3D).global_position)
			if sd < -1.8 and (n as Node3D).global_position.distance_to(md.global_position) < 6.0:
				through = true
			if absf(sd) < 0.9 and (n as Node3D).global_position.distance_to(md.global_position) < 2.0:
				in_way = true
		if through and not in_way:
			md.slam(true)


func _process(_delta: float) -> void:
	_move_flags()


func _show_snow() -> void:
	_snow_floor.visible = snow > 0.01
	_snow_floor_mat.albedo_color.a = clampf(snow * 1.3, 0.0, 1.0)
	_caps.visible = snow > 0.05
	_caps.position.y = lerpf(-0.22, 0.0, clampf(snow * 1.5, 0.0, 1.0))


## S1: footprints in the snow, gone again after half a minute.
func _footprints(delta: float) -> void:
	for pr in _prints:
		pr[1] += delta
		var f := clampf(1.0 - (float(pr[1]) - PRINT_LIFE * 0.6) / (PRINT_LIFE * 0.4), 0.0, 1.0)
		(pr[0] as Node3D).scale = Vector3(f, 1, f)
	while not _prints.is_empty() and float(_prints[0][1]) > PRINT_LIFE:
		(_prints[0][0] as Node).queue_free()
		_prints.pop_front()
	if snow < 0.5:
		return
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or cell_at(p.global_position).x < 0:
			continue
		var last: Vector3 = _last_print.get(p, Vector3(1e9, 0, 0))
		if last.distance_to(p.global_position) < 0.75:
			continue
		_last_print[p] = p.global_position
		var rel := p.yaw - global_rotation.y
		var side := 0.13 if _prints.size() % 2 == 0 else -0.13
		var l := global_transform.affine_inverse() * p.global_position
		var fp := Build.box(Vector3(0.13, 0.01, 0.3), ToonMat.flat(Color(0.70, 0.74, 0.82)),
			Vector3(l.x, 0.095, l.z) + Basis(Vector3.UP, rel) * Vector3(side, 0, 0), Vector3(0, rad_to_deg(rel), 0), "Print")
		fp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(fp)
		_prints.append([fp, 0.0])
		if _prints.size() > 160:
			(_prints[0][0] as Node).queue_free()
			_prints.pop_front()


## The crows on the dead tree lift off when someone passes underneath.
func _crows_check(delta: float) -> void:
	_crows_t = maxf(0.0, _crows_t - delta)
	if _crows.is_empty() or _crows_t > 0.0:
		return
	var tree := _crows[0].get_parent() as Node3D
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(tree.global_position) < 5.0:
			_crows_t = 40.0
			Sfx.play3d("caw", tree.global_position + Vector3.UP * 4.5, 6.0)
			for cr in _crows:
				var home: Vector3 = cr.get_meta("home")
				var tw := create_tween()
				tw.tween_property(cr, "position", home + Vector3(randf_range(-8, 8), 12.0, randf_range(-8, 8)), 2.0)
				tw.tween_callback(func(): cr.visible = false)
				tw.tween_interval(30.0)
				tw.tween_callback(func():
					cr.position = home
					cr.visible = true)
			return


# --- reset / save --------------------------------------------------------------------

## F1 (Puzzles, or a story jump to the road choice or before): the chest
## shut and full again, the gates shut, the snow ready to come.
func reset() -> void:
	for n in _rewards:
		Workable.free_reward(n, global_transform * cell_pos(goal), 8.0)
	_rewards = []
	for p in _flags.keys():
		_drop_flag(p)
	from_dict({})
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags.erase("maze_done")
		st.flags.erase("maze_snow_text")
		st.flags.erase("push")


func to_dict() -> Dictionary:
	return {"chest_open": chest_open, "snow_done": snow_done, "back_open": back_open}


func from_dict(d: Dictionary) -> void:
	chest_open = bool(d.get("chest_open", false))
	snow_done = bool(d.get("snow_done", d.get("dust_done", false)))
	snowing = false
	snow = 0.0
	falls = 0
	scares_fired = 0
	_show_snow()
	var w := _weather_node()
	if w != null:
		w.set("heavy_target", 0.0)
	_chest_lid.rotation.x = deg_to_rad(-105.0) if chest_open else 0.0
	back_open = bool(d.get("back_open", false))
	(_back_gate.get_node("Leaf") as Node3D).rotation.y = deg_to_rad(100.0) if back_open else 0.0
	_back_body.process_mode = Node.PROCESS_MODE_DISABLED if back_open else Node.PROCESS_MODE_INHERIT
	_zones()
	for pt in pits:
		pt["open_t"] = 0.0
		(pt["cover"] as Node3D).position.y = 0.0
		(pt["cover"] as Node3D).visible = true
		(pt["hole"] as Node3D).visible = false
	for sc in scares:
		sc["t"] = 0.0
		sc["done"] = false
		(sc["node"] as Node3D).position = sc["hide"]
	for pr in _prints:
		(pr[0] as Node).queue_free()
	_prints.clear()
	for dr in doors:
		(dr as MazeDoor).reset()
	for n in get_children():
		if String(n.name).begins_with("DroppedFlag"):
			n.queue_free()
	_lamp(false)
	if frights != null:
		frights.reset()
