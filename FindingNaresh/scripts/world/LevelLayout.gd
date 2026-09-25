extends RefCounted

## The world as data (part of LevelBuilder, split by job: LevelLayout ->
## LevelScatter -> LevelPlaces -> LevelLandmarks -> LevelBuilder, each extending
## the one before). This bottom layer holds the handcrafted layout tables
## (tools/gen/layout_check.py keeps a copy of them: keep the two in step), the
## builder's shared state and the small helpers every layer uses.
## Other scripts read these through LevelBuilder (LevelBuilder.PONDS, ...).

# --- layout (x east, z south; metres) -------------------------------------------
const J1 := Vector2(-600, 950)          ## Windmill Junction: the route choice
const J2 := Vector2(100, 420)           ## Last Fuel: the two routes rejoin
const J3 := Vector2(560, -250)          ## east bank, foot of the Ghat
const GHAT_PASS := Vector2(1050, -80)   ## top of the hairpins
const NARESH_JN := Vector2(-1650, -900) ## Coast Road meets West Road at Naresh's home

const HOME_LANE := [Vector2(-1565, 1452), Vector2(-1500, 1540), Vector2(-1400, 1590), Vector2(-1250, 1585),
	Vector2(-1100, 1560), Vector2(-950, 1620), Vector2(-800, 1690), Vector2(-650, 1695), Vector2(-555, 1640),
	Vector2(-525, 1500), Vector2(-550, 1300), Vector2(-585, 1100), J1]
const VALLEY_ROAD := [J1, Vector2(-700, 925), Vector2(-850, 875), Vector2(-960, 780), Vector2(-1005, 640),
	Vector2(-985, 500), Vector2(-900, 385), Vector2(-760, 305), Vector2(-600, 262), Vector2(-430, 250),
	Vector2(-250, 285), Vector2(-80, 330), Vector2(40, 385), J2]
const RIDGE_TRACK := [J1, Vector2(-520, 830), Vector2(-430, 720), Vector2(-340, 610), Vector2(-220, 520),
	Vector2(-60, 465), J2]
## J2 north past the water works, over the river (the bridge) to J3.
const PUMP_HOUSE_ROAD := [J2, Vector2(210, 300), Vector2(290, 160), Vector2(338, 20), Vector2(360, -90),
	Vector2(362, -170), Vector2(372, -215), Vector2(410, -240), Vector2(460, -250), Vector2(515, -252), J3]
## Two hairpins up the saddle between the Ghat peaks.
const GHAT_ROAD := [J3, Vector2(650, -230), Vector2(730, -160), Vector2(790, -95), Vector2(850, -45),
	Vector2(900, -5), Vector2(955, 20), Vector2(985, 0), Vector2(965, -40), Vector2(930, -70), Vector2(935, -100),
	Vector2(985, -105), Vector2(1020, -90), GHAT_PASS]
## Down from the pass to the Bessi loop (the end is snapped onto the loop).
const BEACH_ROAD := [GHAT_PASS, Vector2(1150, -70), Vector2(1260, -60), Vector2(1380, -40), Vector2(1470, 40),
	Vector2(1530, 200), Vector2(1570, 380), Vector2(1610, 520)]
## North from the Bessi loop (start snapped onto it) along the coast, over the
## estuary, west through the rail tunnel to Naresh's home.
const COAST_ROAD := [Vector2(1735, 520), Vector2(1730, 300), Vector2(1720, 60), Vector2(1700, -250),
	Vector2(1660, -600), Vector2(1640, -900), Vector2(1610, -1150), Vector2(1570, -1350), Vector2(1550, -1600),
	Vector2(1450, -1720), Vector2(1250, -1760), Vector2(950, -1740), Vector2(650, -1680), Vector2(400, -1640),
	Vector2(180, -1560), Vector2(-150, -1490), Vector2(-400, -1470), Vector2(-650, -1560), Vector2(-900, -1400),
	Vector2(-1200, -1180), Vector2(-1450, -1020), NARESH_JN]
## Naresh's home south to the homestead (the end snaps onto Homestead Lane).
const WEST_ROAD := [NARESH_JN, Vector2(-1720, -700), Vector2(-1745, -420), Vector2(-1700, -150),
	Vector2(-1640, 150), Vector2(-1590, 480), Vector2(-1560, 800), Vector2(-1575, 1050), Vector2(-1610, 1250),
	Vector2(-1640, 1380)]
## From West Road past the ending watchtower to P2's home (both ends snapped).
const TOWER_ROAD := [Vector2(-1560, 800), Vector2(-1420, 870), Vector2(-1270, 980), Vector2(-1100, 1100),
	Vector2(-900, 1270), Vector2(-720, 1450), Vector2(-560, 1580)]

## Road profiles: smoothed over this many metres, then held to a grade limit.
const ROAD_SMOOTH_M := 150.0
const ROAD_GRADE := 0.10
const GRAVEL_SMOOTH_M := 80.0
const GRAVEL_GRADE := 0.15
const GHAT_GRADE := 0.09
## Ground this far above a road means it runs in a tunnel there.
const TUNNEL_COVER := 9.0

const ROSE_CENTRE := Vector3(1720, 0, 640)
const BESSI_CENTRE := Vector2(1720, 640)
const BESSI_SCALE := 0.85
static var BESSI_LOOP_SHAPE := PackedVector2Array([
	Vector2(0, -150), Vector2(85, -128), Vector2(140, -55), Vector2(150, 30), Vector2(112, 105),
	Vector2(35, 152), Vector2(-48, 148), Vector2(-120, 95), Vector2(-152, 15), Vector2(-130, -70),
	Vector2(-62, -140),
])

## The river rises in the south hills, runs north through the middle and
## turns east to the sea (the estuary).
const RIVER := [Vector2(600, 1130), Vector2(560, 900), Vector2(520, 650), Vector2(482, 380), Vector2(466, 150),
	Vector2(456, -100), Vector2(462, -400), Vector2(480, -900), Vector2(455, -1250), Vector2(560, -1420),
	Vector2(900, -1470), Vector2(1300, -1520), Vector2(1760, -1480), Vector2(1950, -1470)]

## The waterline, south-going; the sea lies east of it.
const COAST := [Vector2(1850, -2100), Vector2(1800, -1500), Vector2(1740, -1000), Vector2(1770, -500),
	Vector2(1840, 0), Vector2(1900, 400), Vector2(1930, 700), Vector2(1890, 1200), Vector2(1900, 2100)]

const PONDS := [
	{"pos": Vector3(-850, 0, 660), "radius": 110.0, "depth": 7.0},    # Mirror Lake
	{"pos": Vector3(-1600, 0, 1545), "radius": 20.0, "depth": 2.4},   # homestead duck pond
]

const TUNNEL_HILL := 3        ## index in MOUNDS: the Coast Road runs under it
const MOUNDS := [
	# the roses' dune by the beach: flat top for the plaza
	{"pos": ROSE_CENTRE, "radius": 90.0, "height": 6.0, "plateau": 30.0},
	# Pine Ridge: the ridge track climbs straight over it
	{"pos": Vector3(-330, 0, 640), "radius": 210.0, "height": 30.0},
	# Radio Hill: the mast on top is a landmark from the north of the map
	{"pos": Vector3(-600, 0, -1300), "radius": 240.0, "height": 55.0},
	# Tunnel Hill: the old rail tunnel runs under it
	{"pos": Vector3(0, 0, -1520), "radius": 240.0, "height": 48.0},
	# the Ghat: two peaks with the hairpin pass between, and an east shoulder
	{"pos": Vector3(990, 0, -320), "radius": 320.0, "height": 110.0},
	{"pos": Vector3(1180, 0, 190), "radius": 320.0, "height": 95.0},
	{"pos": Vector3(1380, 0, -60), "radius": 380.0, "height": 30.0},
	# the south hills (the river's source)
	{"pos": Vector3(600, 0, 1320), "radius": 280.0, "height": 45.0},
	# the ending watchtower's hill
	{"pos": Vector3(-1300, 0, 900), "radius": 300.0, "height": 30.0},
	# hills that fill the land out
	{"pos": Vector3(-1900, 0, 250), "radius": 260.0, "height": 50.0},
	{"pos": Vector3(-1050, 0, -350), "radius": 300.0, "height": 35.0},
	{"pos": Vector3(-250, 0, -650), "radius": 260.0, "height": 30.0},
	{"pos": Vector3(1250, 0, 1150), "radius": 260.0, "height": 35.0},
	{"pos": Vector3(750, 0, -1000), "radius": 220.0, "height": 28.0},
]

const HOMESTEAD := Vector3(-1600, 0, 1480)   ## P1's home
const P2_HOME := Vector3(-490, 0, 1590)
const TOWN_FUEL := Vector3(-1250, 0, 1598)     ## forecourt meets the lane verge
const WINDMILL := Vector3(-640, 0, 990)
const LOOKOUT := Vector3(-340, 0, 665)
const BARN := Vector3(-500, 0, 205)
const GAS_STATION := Vector3(130, 0, 470)   ## Last Fuel, at J2
const FACILITY := Vector3(405, 0, -150)     ## pump house yard, on the west bank
const COAST_TOWER := Vector3(1395, 0, -85)
const FISHING_VILLAGE := Vector3(1715, 0, -620)
const SALT_PANS := Vector3(1690, 0, -1120)
const RADIO_MAST := Vector3(-600, 0, -1300)
const NARESH_HOME := Vector3(-1605, 0, -950)
const END_TOWER := Vector3(-1300, 0, 900)

## Flat pads under buildings (centre, flat radius, blend distance).
const PADS := [
	{"pos": FACILITY, "radius": 22.0, "blend": 14.0},
	{"pos": GAS_STATION, "radius": 14.0, "blend": 10.0},
	{"pos": HOMESTEAD, "radius": 20.0, "blend": 12.0},
	{"pos": BARN, "radius": 14.0, "blend": 10.0},
	{"pos": P2_HOME, "radius": 16.0, "blend": 10.0, "height_offset": 10.2, "driveway": true},
	{"pos": TOWN_FUEL, "radius": 14.0, "blend": 10.0},
	{"pos": NARESH_HOME, "radius": 18.0, "blend": 10.0},
	{"pos": FISHING_VILLAGE, "radius": 30.0, "blend": 12.0},
	{"pos": SALT_PANS, "radius": 42.0, "blend": 12.0},
]

## Places kept clear of scattered trees (centre, radius).
const CLEARINGS := [
	[Vector2(1720, 640), 70.0], [Vector2(405, -150), 34.0], [Vector2(130, 470), 26.0],
	[Vector2(-1590, 1475), 75.0], [Vector2(-640, 990), 30.0], [Vector2(-340, 665), 30.0],
	[Vector2(-600, -1300), 24.0], [Vector2(-500, 205), 32.0], [Vector2(-490, 1590), 30.0],
	[Vector2(-1250, 1600), 150.0], [Vector2(1395, -85), 40.0], [Vector2(1715, -620), 60.0],
	[Vector2(1690, -1120), 60.0], [Vector2(-1605, -950), 36.0], [Vector2(-1300, 900), 36.0],
]

const DOCK_DIR := Vector3(-1, 0, 0.1)   ## Mirror Lake's dock runs out from this shore

const SCATTER_SEED := 20260810
## World size in metres (square). `-- --extent=<m>` overrides it for load tests.
const WORLD_EXTENT := 4000.0

# Colours -----------------------------------------------------------------------
const C_TRUNK := Color(0.38, 0.26, 0.18)
const C_LEAF_A := Color(0.30, 0.56, 0.24)
const C_LEAF_B := Color(0.41, 0.66, 0.28)
const C_LEAF_C := Color(0.24, 0.45, 0.26)
const C_ROCK := Color(0.52, 0.51, 0.49)
const C_ROSE := Color(0.83, 0.14, 0.24)
const C_ROSE_DEEP := Color(0.60, 0.08, 0.18)
const C_STONE := Color(0.66, 0.63, 0.58)
const C_WOOD := Color(0.55, 0.38, 0.25)
const C_RUST := Color(0.58, 0.32, 0.20)
const C_STEEL := Color(0.62, 0.66, 0.68)

var network: RoadNetwork
var route: Route                 ## the Bessi loop (kept for the lap test)
var river: Route
var world: Node3D
var camper_spawn := Transform3D.IDENTITY
var player_spawns: Array[Transform3D] = []
var poi: Dictionary = {}         ## named points of interest, for tests and later systems
## Scatter transforms by kind ("Rocks", "Trunks", ...), kept for tests and
## later systems: a headless run cannot read them back from the MultiMeshes.
var scatter: Dictionary = {}


# --- helpers -------------------------------------------------------------------

func _h(x: float, z: float) -> float:
	return Landscape.ground(x, z)


func _in_pond(x: float, z: float, margin: float) -> bool:
	for p in PONDS:
		var c: Vector3 = p["pos"]
		if Vector2(x - c.x, z - c.z).length() < float(p["radius"]) + margin:
			return true
	return false


func _near_pond_shore(x: float, z: float) -> bool:
	for p in PONDS:
		var c: Vector3 = p["pos"]
		var wr := Landscape.pond_water_radius(float(p["radius"]))
		var d := Vector2(x - c.x, z - c.z).length()
		if d > wr - 2.0 and d < wr + 4.0:
			return true
	return false


## Keep landmark footprints clear of scattered trees.
func _in_clearing(x: float, z: float) -> bool:
	for cl in CLEARINGS:
		if (Vector2(x, z) - (cl[0] as Vector2)).length() < float(cl[1]):
			return true
	return false


func _xf(pos: Vector3, yaw: float, scale: Vector3) -> Transform3D:
	var b := Basis(Vector3.UP, yaw).scaled(scale)
	return Transform3D(b, pos)


## The road sample nearest a point (where a joining road meets it).
func _snap(r: Route, p: Vector2) -> Vector3:
	var near := r.nearest(p.x, p.y)
	if float(near["dist"]) < 1e8:
		return r.point(int(near["index"]))
	var best := r.point(0)
	for i in r.point_count():
		var q := r.point(i)
		if Vector2(q.x - p.x, q.z - p.y).length() < Vector2(best.x - p.x, best.z - p.y).length():
			best = q
	return best


func _tree_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	cs.position = pos
	return cs


func _cyl_shape(pos: Vector3, radius: float, height: float) -> CollisionShape3D:
	return _tree_shape(pos, radius, height)


func _box_shape(size: Vector3, xf: Transform3D) -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.transform = xf
	return cs
