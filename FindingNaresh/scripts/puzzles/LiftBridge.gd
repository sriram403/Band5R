class_name LiftBridge
extends Node3D

## #5, the lift bridge, round 2: the van's seesaw (design/PUZZLE_CHANGES.md
## #5 "Round 2", agreed 2026-10-19: 10 / 10 minus one). The middle of the old
## bridge is a leaf on a pivot in the middle of the river, a real seesaw.
## Its near half is heavier: with nothing on it the near end rests down on its
## support by the near bank and the far end is up. No power (the last pole
## before the hut is snapped, `PowerLine`).
##
## Every weight on the leaf turns it by weight x distance from the pivot (kg
## m): the van (2,150 kg, through its wheels), the players, and three
## concrete blocks on little carts that run on rails along both edges of the
## leaf and back along a siding on the near deck. Push a cart (hold E): the
## heavier the block, the slower it rolls. Nothing tells you when it's level;
## the old timbers only creak at the last moment.
##
## The van crosses by creeping while the other keeps it level: the blocks go
## out on the far half as the van nears the middle, and back past it to the
## near half as it goes on. There are fewer blocks than would make it easy.
## Too far-heavy with the van past the middle: the far end drops into the dry
## pit in front of the far bank and the van goes with it (start again at the
## gate). The van shoving a cart: the leaf lurches, the van is thrown back,
## the rack's cargo flies off (start again at the gate; the cargo stays where
## it landed). Too near-heavy all the way: the van drives off the raised far
## end and lands hard (a tyre bursts).
##
## The far bank's hut: door bolted inside, a window 2.3 m up (a crate and a
## leg-up), a lamp flickering inside, boot scuffs under the window. Inside,
## the lock (bolts the leaf level, only when level and still, only from
## inside) and a crate: fuel, coolant, a spare tyre.

## near end down on its support, far end up (8 degrees put the near end 0.7 m
## down: with a short flap the van beached its rear on it, 2026-10-19)
const REST_DEG := 5.0
const PIT_DEG := -14.0           ## far end on the pit's floor
const FALL_DEG := -5.0           ## the van on the far half past this: it's going in
const LOCK_DEG := 1.0
## the numbers (see PUZZLE_CHANGES #5 round 2): with the van's centre at x m
## past the pivot, level needs the blocks' pull = TAIL - 2150 x, give or take
## FRICTION; at the last metre before the front wheels reach the far bank
## (x = 4) all three blocks right at the near end only just hold it.
const TAIL := 2800.0             ## kg m: the near half's extra weight
const FRICTION := 600.0          ## kg m: the pivot's friction (smaller pulls move nothing)
const INERTIA := 10000.0         ## how slowly the big leaf gets going
const DAMP := 0.6                ## 1/s: the bearings' drag
const SLAM_W := 0.25             ## rad/s: hitting a stop faster than this is a slam
const VAN_W := 0.025             ## rad/s (1.4 deg/s): the fastest it turns with the van on it; at 3.4 deg/s it went rest-to-pit in under 4 s, too quick for anyone to react
const PLAYER_KG := 80.0
const BLOCKS := [450.0, 350.0, 250.0]   ## kg; all look alike
const SIDING := 9.0              ## m of rail on the near deck
const APRON := 2.0               ## the near flap's hinge, m back from the gap: where the old deck now ends (about 10 degrees at rest)
const CART_GAP := 1.3            ## m between carts on one rail
const RAIL_X := 3.8              ## the rails, either side of the middle
const HINT_NEAR := 50.0
const HINTS := [
	[0.0, "The bridge is a seesaw. Naresh's note is on the sign by the gate."],
	[45.0, "The fence is too high to climb alone. One crouches by it, the other jumps up off their back."],
	[150.0, "The van tips it as it crosses. Whatever goes on the front needs something on the back: the blocks on the carts."],
	[300.0, "Before the van reaches the middle, the blocks want to be out on the far half; past the middle, behind the van. Creep, stop, move a block, creep."],
	[450.0, "Someone has been climbing into the hut on the far bank. Walk over first: two people barely tip it."],
]

var angle := REST_DEG            ## degrees: + far end up
var omega := 0.0                 ## rad/s, + = far end going down
var locked := false
var crossed := false             ## the van got over
var door_open := false
var chest_open := false
var failing := false
var storm_blown := false
var slams := 0
var pull := 0.0                  ## kg m this tick (+ pulls the far end down), the near half's weight not counted
var near_t := 0.0
var leaf_len := 10.0
var deck_w := 8.6
var m := 1.0                     ## the hut side across the road (+1 / -1 local x); kept for the walks
var line: PowerLine
var barriers: Node3D
var gate: BridgeGate
var pivot: Node3D
var leaf: AnimatableBody3D
var apron: AnimatableBody3D
var apron_shape: BoxShape3D
var apron_mesh: MeshInstance3D
var panel_label: Label3D
var carts: Array = []            ## {kg, rail, z, home, node, lost}
var bolts: Array[Node3D] = []
var hut: Node3D
var hut_door: Node3D
var lamp: OmniLight3D
var water_y := -1e9
var bank_at := Vector3.ZERO      ## where a swimmer climbs out (the near bank)
var van_start := Transform3D()   ## where a restart puts the van (outside the gate)
var _travel := 0.0
var _groan_t := 0.0
var _left_raised := false
var _fall_t := 0.0
var _thrown_t := 0.0
var _shove_pending := false
var _front_was_off := false
var _flicker := 0.0


## `xf`: the near edge of the gap on the road's centre line, deck top; -Z
## over the river (x across). `hut_xf`: the far bank's hut (its door on -Z,
## facing the road). `gate_node`: the gate, already set up. `start`: the
## van's restart spot.
func setup(xf: Transform3D, length: float, width: float, panel_xf: Transform3D, power: PowerLine, barrier_root: Node3D,
		hut_xf: Transform3D, gate_node: BridgeGate, bank: Vector3, start: Transform3D) -> void:
	add_to_group("lift_bridge")
	add_to_group("place_hint")
	transform = xf
	leaf_len = length
	deck_w = width
	line = power
	barriers = barrier_root
	gate = gate_node
	bank_at = bank
	van_start = start
	m = -1.0 if (xf.affine_inverse() * panel_xf.origin).x > 0.0 else 1.0
	if Landscape.river != null:
		water_y = Landscape.river_water_level(int(Landscape.river.nearest(xf.origin.x, xf.origin.z)["index"]))
	_build_leaf()
	_build_apron()
	_build_rails_and_carts()
	_build_pit()
	_build_panel(panel_xf)
	_build_hut(xf.affine_inverse() * hut_xf)
	_apply()


# --- building ------------------------------------------------------------------

func _build_leaf() -> void:
	var wood := ToonMat.make(Color(0.46, 0.34, 0.24), 0.012)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	var stone := ToonMat.make(Color(0.52, 0.50, 0.47), 0.012)
	pivot = Node3D.new()
	pivot.name = "Pivot"
	pivot.position = Vector3(0, 0, -leaf_len * 0.5)
	add_child(pivot)
	# the pier in the middle of the river, the pivot's bearings on top
	add_child(Build.cyl(0.9, 7.5, stone, Vector3(0, -4.2, -leaf_len * 0.5), Vector3.ZERO, 10, "MidPier"))
	for sx in [-1.0, 1.0]:
		add_child(Build.box(Vector3(0.5, 0.5, 0.7), steel, Vector3(sx * (deck_w * 0.5 - 0.4), -0.55, -leaf_len * 0.5), Vector3.ZERO, "Bearing"))
	add_child(Build.cyl(0.18, deck_w + 0.4, steel, Vector3(0, -0.45, -leaf_len * 0.5), Vector3(0, 0, 90), 10, "Axle"))
	# the near end's support: a stone block it rests on
	var near_drop := sin(deg_to_rad(REST_DEG)) * leaf_len * 0.5
	add_child(Build.solid_box(Vector3(deck_w, 0.4, 0.8), stone, Vector3(0, -near_drop - 0.5, 0.2), Vector3.ZERO, "NearSeat"))
	leaf = AnimatableBody3D.new()
	leaf.name = "Leaf"
	leaf.sync_to_physics = true
	pivot.add_child(leaf)
	var deck := Vector3(deck_w, 0.3, leaf_len)
	leaf.add_child(Build.box(deck, wood, Vector3(0, -0.15, 0), Vector3.ZERO, "LeafDeck"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = deck
	cs.shape = sh
	cs.position = Vector3(0, -0.15, 0)
	leaf.add_child(cs)
	# low kerbs outside the rails
	for sx in [-1.0, 1.0]:
		leaf.add_child(Build.box(Vector3(0.2, 0.25, leaf_len), steel, Vector3(sx * (deck_w * 0.5 - 0.1), 0.12, 0), Vector3.ZERO, "Kerb"))
		var ks := CollisionShape3D.new()
		var kb := BoxShape3D.new()
		kb.size = Vector3(0.2, 0.25, leaf_len)
		ks.shape = kb
		ks.position = Vector3(sx * (deck_w * 0.5 - 0.1), 0.12, 0)
		leaf.add_child(ks)
	leaf.add_child(Build.box(Vector3(deck_w, 0.05, 0.5), ToonMat.make(Color(0.95, 0.75, 0.15)), Vector3(0, 0.02, -leaf_len * 0.5 + 0.25), Vector3.ZERO, "FarStripe"))
	leaf.add_child(Build.box(Vector3(deck_w - 1.6, 0.05, 0.3), ToonMat.make(Color(0.95, 0.95, 0.9)), Vector3(0, 0.02, 0), Vector3.ZERO, "MidLine"))
	# the lock's bolts at the far end, shot home from the hut
	for sx in [-1.0, 1.0]:
		var bolt := Node3D.new()
		bolt.position = Vector3(sx * (deck_w * 0.5 - 0.8), -0.2, -leaf_len * 0.5 + 0.3)
		leaf.add_child(bolt)
		bolt.add_child(Build.box(Vector3(0.18, 0.14, 0.7), steel, Vector3.ZERO, Vector3.ZERO, "BoltBar"))
		bolts.append(bolt)


## A steel flap hinged on the near deck that lies on the leaf's near end, so
## the van (and the carts) get on whatever the leaf's tilt.
func _build_apron() -> void:
	apron = AnimatableBody3D.new()
	apron.name = "Apron"
	apron.sync_to_physics = true
	apron.position = Vector3(0, 0, APRON)
	add_child(apron)
	apron_mesh = Build.box(Vector3(deck_w - 0.4, 0.08, 1.0), ToonMat.make(Color(0.36, 0.37, 0.4), 0.012), Vector3(0, -0.04, -0.5), Vector3.ZERO, "Plate")
	apron.add_child(apron_mesh)
	var cs := CollisionShape3D.new()
	apron_shape = BoxShape3D.new()
	apron_shape.size = Vector3(deck_w - 0.4, 0.08, 1.0)
	cs.shape = apron_shape
	cs.position = Vector3(0, -0.04, -0.5)
	cs.name = "PlateShape"
	apron.add_child(cs)


func _build_rails_and_carts() -> void:
	var steel := ToonMat.make(Color(0.26, 0.27, 0.29), 0.01)
	var concrete := ToonMat.make(Color(0.63, 0.62, 0.59), 0.01)
	for sx in [-1.0, 1.0]:
		for off in [-0.35, 0.35]:
			leaf.add_child(Build.box(Vector3(0.07, 0.06, leaf_len), steel, Vector3(sx * RAIL_X + off, 0.03, 0), Vector3.ZERO, "Rail"))
			add_child(Build.box(Vector3(0.07, 0.06, SIDING), steel, Vector3(sx * RAIL_X + off, 0.03, SIDING * 0.5), Vector3.ZERO, "SidingRail"))
		add_child(Build.box(Vector3(0.9, 0.5, 0.3), ToonMat.make(Color(0.8, 0.2, 0.15), 0.01), Vector3(sx * RAIL_X, 0.25, SIDING + 0.15), Vector3.ZERO, "Buffer"))
	# where they start: two on the hut's side, one across
	# the 450 and the 350 share the hut side's rail (the 350 in front: it has
	# to go out first), room to stand between them; the 250 across
	var starts := [[BLOCKS[0], -m, 5.6], [BLOCKS[1], -m, 2.8], [BLOCKS[2], m, 3.6]]
	for k in starts.size():
		var c := {"kg": float(starts[k][0]), "rail": float(starts[k][1]), "z": float(starts[k][2]), "home": float(starts[k][2]), "lost": false}
		var body := AnimatableBody3D.new()
		body.name = "Cart%d" % k
		body.sync_to_physics = false
		add_child(body)
		body.add_child(Build.box(Vector3(0.95, 0.18, 1.1), steel, Vector3(0, 0.22, 0), Vector3.ZERO, "Trolley"))
		for wx in [-0.35, 0.35]:
			for wz in [-0.4, 0.4]:
				body.add_child(Build.cyl(0.11, 0.08, steel, Vector3(wx, 0.11, wz), Vector3(0, 0, 90), 8, "Wheel"))
		# the same block on each (they look alike: you find their weight by pushing)
		body.add_child(Build.box(Vector3(0.8, 0.75, 0.8), concrete, Vector3(0, 0.69, 0), Vector3(0, k * 7.0 - 7.0, 0), "Block"))
		var bs := CollisionShape3D.new()
		var bb := BoxShape3D.new()
		bb.size = Vector3(0.95, 1.05, 1.1)
		bs.shape = bb
		bs.position = Vector3(0, 0.55, 0)
		body.add_child(bs)
		var idx := k
		body.set_meta("tag_name", "a cart")
		body.set_meta("prompt", "Hold: grab the cart, then walk")      # (what marks it usable)
		body.set_meta("callback", func(_p): pass)
		body.set_meta("prompt_fn", func(_p) -> String: return "" if carts[idx]["lost"] else "Hold: grab the cart, then walk")
		body.set_meta("hold_fn", func(p, dt: float): _push(idx, p, dt))
		c["node"] = body
		carts.append(c)


## The dry pit in front of the far bank's wall, where a far-heavy leaf ends up.
func _build_pit() -> void:
	var dark := ToonMat.make(Color(0.28, 0.27, 0.26), 0.012)
	var z0 := -leaf_len - 0.1
	var depth := 3.0
	for sx in [-1.0, 1.0]:
		add_child(Build.solid_box(Vector3(0.6, depth, 2.4), dark, Vector3(sx * (deck_w * 0.5 + 0.3), -depth * 0.5 - 0.2, z0 + 1.2), Vector3.ZERO, "PitWall"))
	add_child(Build.solid_box(Vector3(deck_w + 1.2, 0.4, 2.4), dark, Vector3(0, -depth - 0.4, z0 + 1.2), Vector3.ZERO, "PitFloor"))
	add_child(Build.solid_box(Vector3(deck_w + 1.2, depth, 0.5), dark, Vector3(0, -depth * 0.5 - 0.2, z0 - 0.25), Vector3.ZERO, "PitBack"))


## The dead lever panel in the near hut's window: the power's off.
func _build_panel(xf: Transform3D) -> void:
	var panel := Node3D.new()
	panel.name = "LeverPanel"
	panel.transform = transform.affine_inverse() * xf
	add_child(panel)
	var steel := ToonMat.make(Color(0.30, 0.34, 0.32))
	panel.add_child(Build.box(Vector3(1.2, 1.0, 0.4), steel, Vector3(0, 0.5, 0), Vector3.ZERO, "Desk"))
	panel_label = Build.label3d("NO POWER", Vector3(0, 1.15, 0.05), Vector3(-30, 0, 0), 0.08, Color(0.95, 0.92, 0.8))
	panel.add_child(panel_label)
	for spec in [["RAISE", -0.3, Color(0.2, 0.5, 0.3)], ["LOWER", 0.3, Color(0.75, 0.2, 0.18)]]:
		var nm: String = spec[0]
		var x: float = spec[1]
		panel.add_child(Build.cyl(0.03, 0.5, ToonMat.make(spec[2]), Vector3(x, 1.2, 0.0), Vector3(-20, 0, 0), 6, nm + "Handle"))
		panel.add_child(Build.label3d(nm, Vector3(x, 1.02, 0.21), Vector3.ZERO, 0.08, Color(0.95, 0.92, 0.8)))
		var a := Build.interact_area(Vector3(0.45, 0.7, 0.7), Vector3(x, 1.1, 0.1), "", func(_p): pass, nm + "Lever")
		a.set_meta("tag_name", "the %s lever" % nm.to_lower())
		a.set_meta("blocked_fn", func() -> String: return "Nothing. No power: the line's down at the last pole.")
		panel.add_child(a)


## The far bank's hut (`hx`: local to the bridge; its door on -Z, the road
## side; the window on the side facing the bridge).
func _build_hut(hx: Transform3D) -> void:
	var stone := ToonMat.make(Color(0.55, 0.53, 0.49), 0.012)
	var roof := ToonMat.make(Color(0.30, 0.28, 0.27), 0.012)
	var wood := ToonMat.make(Color(0.36, 0.27, 0.19), 0.012)
	hut = Node3D.new()
	hut.name = "FarHut"
	hut.transform = hx
	add_child(hut)
	# a bridge-keeper's tower hut: the window is a tall shutter high up (a
	# plain leg-up's feet reach 1.92 m: you need the crate too, ~2.3 m;
	# 2.2 m was a hair's breadth with the crate, 2026-10-19)
	const W := 3.6
	const H := 4.6
	const T := 0.3
	var sill := 2.1
	var win := Vector2(1.0, 1.9)
	# which local x side faces the bridge (the window's wall)
	var to_bridge := hx.affine_inverse() * Vector3(0, 0, -leaf_len * 0.5)
	var ws := 1.0 if to_bridge.x > 0.0 else -1.0
	hut.add_child(Build.solid_box(Vector3(W, 0.2, W), stone, Vector3(0, -0.1, 0), Vector3.ZERO, "HutFloor"))
	hut.add_child(Build.solid_box(Vector3(W + 0.4, 0.25, W + 0.4), roof, Vector3(0, H + 0.12, 0), Vector3.ZERO, "HutRoof"))
	hut.add_child(Build.solid_box(Vector3(W, H, T), stone, Vector3(0, H * 0.5, W * 0.5), Vector3.ZERO, "WallBack"))
	hut.add_child(Build.solid_box(Vector3(T, H, W), stone, Vector3(-ws * W * 0.5, H * 0.5, 0), Vector3.ZERO, "WallFar"))
	# the window's wall: solid below the sill and above the window, piers either side
	var wx := ws * W * 0.5
	hut.add_child(Build.solid_box(Vector3(T, sill, W), stone, Vector3(wx, sill * 0.5, 0), Vector3.ZERO, "WinBelow"))
	hut.add_child(Build.solid_box(Vector3(T, H - sill - win.y, W), stone, Vector3(wx, sill + win.y + (H - sill - win.y) * 0.5, 0), Vector3.ZERO, "WinAbove"))
	for sz in [-1.0, 1.0]:
		var pw := (W - win.x) * 0.5
		hut.add_child(Build.solid_box(Vector3(T, win.y, pw), stone, Vector3(wx, sill + win.y * 0.5, sz * (win.x * 0.5 + pw * 0.5)), Vector3.ZERO, "WinPier"))
	hut.add_child(Build.box(Vector3(T + 0.15, 0.08, win.x + 0.1), wood, Vector3(wx, sill + 0.02, 0), Vector3.ZERO, "Sill"))
	# boot scuffs up the wall under the window: someone climbed in
	var scuff := ToonMat.flat(Color(0.25, 0.22, 0.19))
	for k in 5:
		hut.add_child(Build.box(Vector3(0.02, 0.07, 0.22), scuff, Vector3(wx + ws * (T * 0.5 + 0.01), 1.3 + k * 0.2, randf_range(-0.25, 0.25)), Vector3(randf_range(-15, 15), 0, 0), "Scuff"))
	# the door wall, its door bolted from inside
	var dw := 1.1
	for sx in [-1.0, 1.0]:
		var seg := (W - dw) * 0.5
		hut.add_child(Build.solid_box(Vector3(seg, H, T), stone, Vector3(sx * (dw * 0.5 + seg * 0.5), H * 0.5, -W * 0.5), Vector3.ZERO, "WallFront"))
	hut.add_child(Build.solid_box(Vector3(dw, H - 2.2, T), stone, Vector3(0, 2.2 + (H - 2.2) * 0.5, -W * 0.5), Vector3.ZERO, "DoorHead"))
	hut_door = Node3D.new()
	hut_door.name = "HutDoor"
	hut_door.position = Vector3(-dw * 0.5, 0, -W * 0.5)
	hut.add_child(hut_door)
	hut_door.add_child(Build.solid_box(Vector3(dw - 0.04, 2.15, 0.1), wood, Vector3(dw * 0.5, 1.08, 0), Vector3.ZERO, "Door"))
	hut_door.add_child(Build.box(Vector3(0.3, 0.06, 0.08), ToonMat.make(Color(0.45, 0.25, 0.15)), Vector3(dw * 0.5 + 0.2, 1.1, 0.09), Vector3.ZERO, "Bolt"))
	var da := Build.interact_area(Vector3(dw, 2.1, 0.5), Vector3(dw * 0.5, 1.05, 0), "", func(p): _open_door(p), "HutDoorArea")
	da.set_meta("tag_name", "the hut's door")
	da.set_meta("prompt_fn", func(p) -> String: return "Slide the bolt and open the door" if not door_open and _in_hut(p) else "")
	da.set_meta("blocked_fn", func(p) -> String: return "" if door_open or _in_hut(p) else "It won't move. Bolted on the inside.")
	hut_door.add_child(da)
	# a lamp left burning inside, flickering: you see it in the window
	lamp = OmniLight3D.new()
	lamp.position = Vector3(ws * 0.6, 2.4, 0.6)
	lamp.omni_range = 5.0
	lamp.light_color = Color(1.0, 0.8, 0.5)
	lamp.light_energy = 1.6
	hut.add_child(lamp)
	hut.add_child(Build.sphere(0.1, ToonMat.make(Color(1.0, 0.85, 0.5), 0.0, 0.9, Color(1.0, 0.7, 0.3) * 2.0), lamp.position, Vector3.ONE, "LampGlass"))
	# inside: the lock lever by the far wall, the crate
	var lock := Node3D.new()
	lock.name = "LockLever"
	lock.position = Vector3(-ws * (W * 0.5 - 0.5), 0, 0.4)
	lock.rotation = Vector3(0, PI * 0.5 * ws, 0)
	hut.add_child(lock)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	lock.add_child(Build.box(Vector3(0.5, 0.9, 0.3), steel, Vector3(0, 0.45, 0), Vector3.ZERO, "LockBase"))
	lock.add_child(Build.cyl(0.035, 0.8, ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 1.2, -0.1), Vector3(-25, 0, 0), 6, "LockHandle"))
	lock.add_child(Build.label3d("LEAF LOCK", Vector3(0, 0.75, -0.16), Vector3(0, 180, 0), 0.08, Color(0.95, 0.92, 0.8)))
	var la := Build.interact_area(Vector3(0.7, 1.0, 0.8), Vector3(0, 1.1, -0.2), "", func(p): _try_lock(p), "LockArea")
	la.set_meta("tag_name", "the leaf lock")
	la.set_meta("prompt_fn", func(p) -> String: return "Throw the lock bolts" if _in_hut(p) and not locked else "")
	la.set_meta("blocked_fn", func(p) -> String:
		if not _in_hut(p):
			return ""
		if locked:
			return "The bolts are home. The bridge is locked level."
		if storm_blown:
			return "The bridge is swinging in the gale. The bolts can't reach."
		if absf(angle) > LOCK_DEG:
			return "The bridge isn't level. The bolts won't reach."
		if absf(omega) > 0.03:
			return "It's still moving."
		return "")
	lock.add_child(la)
	var chest := Node3D.new()
	chest.name = "HutChest"
	chest.position = Vector3(0, 0, W * 0.5 - 0.6)
	hut.add_child(chest)
	chest.add_child(Build.solid_box(Vector3(1.4, 0.6, 0.7), wood, Vector3(0, 0.3, 0), Vector3.ZERO, "Chest"))
	var ca := Build.interact_area(Vector3(1.4, 0.8, 0.9), Vector3(0, 0.5, 0), "", func(p): _open_chest(p), "ChestArea")
	ca.set_meta("tag_name", "the crate")
	ca.set_meta("prompt_fn", func(p) -> String: return "Open the crate" if not chest_open and _in_hut(p) else "")
	chest.add_child(ca)
	# the crate outside, a few steps from the window's wall (to stand on)
	var crate := Crate.new()
	crate.name = "HutCrate"
	crate.position = Vector3(ws * (W * 0.5 + 2.2), 0.05, -1.4)
	hut.add_child(crate)


# --- running -------------------------------------------------------------------

func _process(delta: float) -> void:
	if lamp != null:
		_flicker -= delta
		if _flicker <= 0.0:
			_flicker = randf_range(0.05, 0.4)
			lamp.light_energy = randf_range(0.6, 1.8)


func _physics_process(delta: float) -> void:
	_watch_water()
	var van: Camper = get_tree().current_scene.get("camper") if is_inside_tree() else null
	if storm_blown:
		omega = 0.0
		angle = REST_DEG - 1.0 + sin(Time.get_ticks_msec() * 0.0011) * 2.0
		if barriers != null and not barriers.visible:
			_close_road()
		_apply()
		return
	_near_time(delta)
	if van != null and van.global_position.distance_to(global_transform * Vector3(0, 0, -leaf_len * 0.5)) < leaf_len:
		# never asleep near the seesaw: a sleeping van ignores both its engine
		# and the deck moving under it (it slept as the leaf levelled, then sat
		# stuck with the engine pushing, 2026-10-19)
		van.sleeping = false
		van.on_moving_deck = 0.3
	if locked or failing:
		if van != null:
			_check_crossed(van)
		return
	pull = _pull(van)
	var net := pull - TAIL
	var a := deg_to_rad(angle)
	var a_up := deg_to_rad(REST_DEG)
	var a_pit := deg_to_rad(PIT_DEG)
	var at_up := a >= a_up - 0.0005 and net <= FRICTION
	var at_pit := a <= a_pit + 0.0005 and net >= -FRICTION
	if absf(omega) < 0.002 and (absf(net) <= FRICTION or at_up or at_pit):
		omega = 0.0
		_groan(net, delta)
	else:
		var fr := FRICTION * signf(omega if absf(omega) >= 0.002 else net)
		omega += (net - fr) / INERTIA * delta
		omega *= exp(-DAMP * delta)
		# loaded with the van it can't swing fast (and the van's springs can't
		# follow a deck that comes up quicker than this)
		if van != null and _van_on_leaf(van):
			omega = clampf(omega, -VAN_W, VAN_W)
		a -= omega * delta
		if a >= a_up:
			a = a_up
			if omega < -SLAM_W:
				_slam(true)
			omega = 0.0
		elif a <= a_pit:
			a = a_pit
			if omega > SLAM_W:
				_slam(false)
			omega = 0.0
		var was := angle
		angle = rad_to_deg(a)
		_travel += absf(angle - was)
		if _travel > 1.5:
			_travel = 0.0
			Sfx.play3d("creak", global_transform * Vector3(0, -0.4, -leaf_len * 0.5), -4.0, 0.15, 0.7 + randf() * 0.3)
		var old_xf := leaf.global_transform
		_apply()
		_carry_players(old_xf)
		if van != null:
			_carry_van(van, old_xf)
	if van != null:
		_unbury_van(van)
		_hold_parked_van(van)
		_check_van(van, delta)


## A van parked on the handbrake on the leaf (or the flap) stays put on it:
## off the leaf the game freezes a parked van (its wheel brakes alone let it
## creep downhill), but a frozen van can't ride a moving deck, so here it's
## held still relative to the deck instead (it crept 1.6 m back down the
## tipped leaf in a minute, 2026-10-19). The deck's own turning still carries it.
func _hold_parked_van(van: Camper) -> void:
	if not van.parking_brake or _thrown_t > 0.0:
		return
	var on := 0
	for w in van._wheels:
		if w.is_in_contact() and (w.get_contact_body() == leaf or w.get_contact_body() == apron):
			on += 1
	if on >= 2 and van.linear_velocity.length() < 1.0:
		van.linear_velocity = Vector3.ZERO
		van.angular_velocity = Vector3.ZERO


## Never let a wheel's hub end up under the leaf's (or flap's) surface: the
## van's wheels feel down for the ground from their hubs, so a deck that comes
## up past them is lost and the van sits stuck on its belly (2026-10-19: the
## near end rose 0.7 m through the rear wheels as the leaf levelled). Lift
## the van along the deck's normal until every hub is a wheel's radius up.
func _unbury_van(van: Camper) -> void:
	if _thrown_t > 0.0:
		_thrown_t -= get_physics_process_delta_time()
		return
	if van.global_position.distance_to(global_transform * Vector3(0, 0, -leaf_len * 0.5)) > leaf_len:
		return
	var worst := 0.0
	var normal := Vector3.UP
	for body in [leaf, apron]:
		var b := body as Node3D
		var inv := b.global_transform.affine_inverse()
		var half_len := leaf_len * 0.5 if b == leaf else apron_shape.size.z
		for w in van._wheels:
			var l: Vector3 = inv * w.global_position
			var along := l.z if b == leaf else -l.z
			var inside := absf(l.x) < deck_w * 0.5 - 0.2 and ((b == leaf and absf(along) < half_len) or (b == apron and along > 0.0 and along < half_len))
			if not inside:
				continue
			# only a hub that has truly sunk (a resting hub sits ~0.3 m up; lifting
			# at a wheel's radius floated the van, its wheels off the deck)
			var need: float = 0.15 - l.y
			if need > worst:
				worst = need
				normal = b.global_transform.basis.y.normalized()
	if worst > 0.01:
		van.global_position += normal * worst
		var v := van.linear_velocity
		var into := v.dot(normal)
		if into < 0.0:
			van.linear_velocity = v - normal * into


## Weight x distance from the pivot (+ toward the far end) of everything on
## the leaf: the van's wheels, the players, the carts.
func _pull(van: Camper) -> float:
	var inv := leaf.global_transform.affine_inverse()
	var total := 0.0
	if van != null:
		var per := Camper.MASS / float(van._wheels.size())
		for w in van._wheels:
			if w.is_in_contact() and w.get_contact_body() == leaf:
				total += per * -(inv * w.global_position).z
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming:
			continue
		var l := inv * p.global_position
		if _on_leaf(l, 1.4):
			total += PLAYER_KG * -l.z
	for c in carts:
		if not c["lost"] and float(c["z"]) < 0.0:
			total += float(c["kg"]) * -(float(c["z"]) + leaf_len * 0.5)
	return total


## A point in the leaf's frame is on its deck.
func _on_leaf(l: Vector3, above: float) -> bool:
	return absf(l.x) < deck_w * 0.5 + 0.1 and absf(l.z) < leaf_len * 0.5 + 0.1 and l.y > -0.35 and l.y < above


func _van_on_leaf(van: Camper) -> bool:
	for w in van._wheels:
		if w.is_in_contact() and (w.get_contact_body() == leaf or w.get_contact_body() == apron):
			return true
	return false


## The timbers creak only at the very last: nearly tipping.
func _groan(net: float, delta: float) -> void:
	_groan_t -= delta
	if _groan_t > 0.0:
		return
	if absf(net) > FRICTION * 0.85 and not (angle >= REST_DEG - 0.01 and net < 0.0) and not (angle <= PIT_DEG + 0.01 and net > 0.0):
		_groan_t = 1.4
		Sfx.play3d("groan", global_transform * Vector3(0, -0.3, -leaf_len * 0.5), -2.0, 0.1, 0.6)


func _slam(near_end: bool) -> void:
	slams += 1
	var at := global_transform * Vector3(0, -0.5, 0.0 if near_end else -leaf_len)
	Sfx.play3d("bang", at, 4.0)
	Sfx.play3d("hit_wood_heavy", at, 2.0)
	var inv := leaf.global_transform.affine_inverse()
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat == null and _on_leaf(inv * p.global_position, 1.4):
			p.knock(Vector3.UP * 3.0 + global_transform.basis.z * (2.0 if near_end else -2.0))
	print("[bridge] slam %d (%s end)" % [slams, "near" if near_end else "far"])


## The van this tick: in the pit, shoving a cart, landing hard off a raised
## far end, or over.
func _check_van(van: Camper, delta: float) -> void:
	var l := global_transform.affine_inverse() * van.global_position
	var on_leaf := _van_on_leaf(van)
	# into the pit
	if on_leaf and angle < FALL_DEG and l.z < -leaf_len * 0.5:
		_fall_t += delta
		if _fall_t > 0.8:
			_fail("pit")
			return
	else:
		_fall_t = 0.0
	# shoving a cart (it's in the van's way)
	var vinv := van.global_transform.affine_inverse()
	for k in carts.size():
		var c: Dictionary = carts[k]
		if c["lost"]:
			continue
		var cl := vinv * (c["node"] as Node3D).global_position
		if absf(cl.x) < 1.6 and absf(cl.z) < 3.1 and absf(cl.y) < 1.6:
			_shove(k, van)
			return
	# the front wheels coming off the far end while it's raised: a drop, a
	# hard landing (after that the leaf settling back under the rear wheels
	# is just a ramp down)
	var front_off := true
	var linv := leaf.global_transform.affine_inverse()
	for w in van._wheels:
		if String(w.name).begins_with("WheelF") and (linv * w.global_position).z > -leaf_len * 0.5 - 0.1:
			front_off = false
	if front_off and not _front_was_off and not crossed:
		if not locked and angle > 2.5:
			van.puncture()
			Sfx.play3d("bang", van.global_position, 4.0)
			_tell_near("BANG - the van drops off the raised end and lands hard on the far bank.", 5.0)
			print("[bridge] hard landing (angle %.1f)" % angle)
	_front_was_off = front_off
	_check_crossed(van)


func _check_crossed(van: Camper) -> void:
	if crossed:
		return
	var l := global_transform.affine_inverse() * van.global_position
	if l.z < -leaf_len - 3.5 and absf(l.x) < 6.0:
		crossed = true
		_open_road()
		var st = get_tree().current_scene.get("story")
		if st != null:
			st.flags["bridge_down"] = true
		print("[bridge] the van is over (locked %s, slams %d)" % [locked, slams])


## The van ran into a cart: the cart goes over the side, the leaf lurches,
## the van is thrown back and everything on its rack flies.
func _shove(k: int, van: Camper) -> void:
	if _shove_pending:
		return
	var c: Dictionary = carts[k]
	c["lost"] = true
	var node := c["node"] as Node3D
	var side := global_transform.basis.x * float(c["rail"])
	var tw := create_tween()
	tw.tween_property(node, "global_position", node.global_position + side * 2.5 + Vector3.DOWN * 6.0, 0.9).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): node.visible = false)
	Sfx.play3d("hit_metal_heavy", node.global_position, 4.0)
	Sfx.play3d("splat", node.global_position + Vector3.DOWN * 4.0, 2.0, 0.1, 0.5)
	# the leaf whips: the van goes back the way it came, hard
	var back := global_transform.basis.z.normalized()
	van.parking_brake = false
	van.freeze = false
	van.linear_velocity = back * 9.0 + Vector3.UP * 3.5
	van.angular_velocity = global_transform.basis.x * 0.8
	_thrown_t = 1.2               # the deck doesn't carry it while it's flying
	omega = -0.6
	_fling_cargo(van)
	_tell_near("The van hits a cart - it goes over the side, the bridge bucks and throws the van back. Everything on the rack goes flying.", 7.0)
	print("[bridge] the van shoved cart %d" % k)
	# one shove, one restart (two carts hit = two restarts, the second cutting
	# into whatever came next, 2026-10-19)
	if not _shove_pending:
		_shove_pending = true
		var t := get_tree().create_timer(4.5)
		t.timeout.connect(func():
			_shove_pending = false
			_fail("shove"))


## Everything stowed on the van comes off and flies.
func _fling_cargo(van: Camper) -> void:
	for slot in van.storage_slots:
		var it := van.stowed_item(slot)
		if it == null:
			continue
		it.unstow()
		it.global_position = slot.global_position + Vector3.UP * 0.4
		it.linear_velocity = global_transform.basis.z * randf_range(5.0, 9.0) + Vector3.UP * randf_range(4.0, 7.0) + global_transform.basis.x * randf_range(-3.0, 3.0)
		it.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		it._thrown = true


## Start again at the gate: a fade to black, then the bridge as it was, the
## van and both of you outside the gate. Cargo that flew stays where it fell.
func _fail(why: String) -> void:
	if failing:
		return
	failing = true
	print("[bridge] fail: %s" % why)
	var text := "The far end drops into the pit and the van goes with it." if why == "pit" else "That's the bridge's way of saying no."
	_tell_near(text, 4.0)
	var players := get_tree().get_nodes_in_group("player")
	for n in players:
		var p := n as PlayerRig
		p.fade_color = Color.BLACK
		var tw := p.create_tween()
		tw.tween_property(p, "whiteout", 1.0, 1.2)
	await get_tree().create_timer(1.8).timeout
	if not is_inside_tree():
		return
	var van: Camper = get_tree().current_scene.get("camper")
	reset_bridge()
	crossed = false               # the van is back behind the gate
	if van != null:
		for n in players:
			var p := n as PlayerRig
			if p.seat != null:
				p.force_exit = true
		await get_tree().physics_frame
		van.linear_velocity = Vector3.ZERO
		van.angular_velocity = Vector3.ZERO
		van.global_transform = van_start
		van.reset_physics_interpolation()
		van.parking_brake = true
		var k := 0
		for n in players:
			var p := n as PlayerRig
			p.global_position = van_start * Vector3(-3.2, 0.3, -1.0 + k * 1.6)
			p.velocity = Vector3.ZERO
			p.reset_physics_interpolation()
			k += 1
	await get_tree().create_timer(0.6).timeout
	for n in players:
		var p := n as PlayerRig
		var tw := p.create_tween()
		tw.tween_property(p, "whiteout", 0.0, 1.0)
		p.say("Back at the gate. The bridge has settled back the way it was.", 4.0)
	failing = false


## Hold E on a cart: you've got its handle, and it goes where you walk
## along its rail, forward or back (a trolley; with "push it away from you"
## you had to squeeze between carts to pull one back). The heavier the block,
## the slower it follows, and slower still uphill on the tilted leaf.
func _push(k: int, p, dt: float) -> void:
	var c: Dictionary = carts[k]
	if c["lost"] or failing:
		return
	var pl := global_transform.affine_inverse() * (p as Node3D).global_position
	var now := Time.get_ticks_msec()
	if now - int(c.get("held_ms", 0)) > 250 or c.get("holder") != p:
		c["grip"] = float(c["z"]) - pl.z          # a new grab: where the handle is from you
		c["holder"] = p
	c["held_ms"] = now
	var want := pl.z + float(c["grip"])
	var dir := signf(want - float(c["z"]))
	if absf(want - float(c["z"])) < 0.02:
		return
	var speed := clampf(1.3 * 250.0 / float(c["kg"]), 0.45, 1.4)
	if float(c["z"]) < 0.0:
		# towards the raised end is uphill: hard work; downhill a little easier
		var grade := sin(deg_to_rad(angle)) * (-dir)
		speed *= clampf(1.0 - grade * 3.0, 0.35, 1.3)
	var z := move_toward(float(c["z"]), want, speed * dt)
	z = clampf(z, -leaf_len + 0.7, SIDING - 0.7)
	# not through another cart on the same rail
	for o in carts:
		if o != c and not o["lost"] and float(o["rail"]) == float(c["rail"]):
			var oz := float(o["z"])
			if absf(oz - z) < CART_GAP and signf(oz - float(c["z"])) == dir:
				return
	var was := float(c["z"])
	c["z"] = z
	_place_cart(c)
	if int(was / 0.6) != int(z / 0.6):
		Sfx.play3d("click", (c["node"] as Node3D).global_position, -10.0, 0.1, 0.6)


## A cart's place on its rail: on the siding (z > APRON), on the flap, or on
## the leaf (z < 0), following the leaf's tilt.
func _place_cart(c: Dictionary) -> void:
	# in the bridge's own frame (this runs from the builder too, before the
	# world is in the tree: no global transforms then)
	var node := c["node"] as Node3D
	var z := float(c["z"])
	var x := float(c["rail"]) * RAIL_X
	var lxf := pivot.transform * leaf.transform
	var xf: Transform3D
	if z >= APRON:
		xf = Transform3D(Basis(), Vector3(x, 0, z))
	elif z < 0.0:
		xf = lxf * Transform3D(Basis(), Vector3(x, 0, z + leaf_len * 0.5))
	else:
		var a := Vector3(x, 0, APRON)
		var b := lxf * Vector3(x, 0, leaf_len * 0.5)
		var u := 1.0 - z / APRON
		xf = Transform3D(lxf.basis.slerp(Basis(), 1.0 - u), a.lerp(b, u))
	node.transform = xf


## People standing on the turning leaf move with it (the engine leaves them
## behind; found at round 1).
func _carry_players(old_xf: Transform3D) -> void:
	var new_xf := leaf.global_transform
	var inv := old_xf.affine_inverse()
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming or not p.is_on_floor():
			continue
		var l := inv * p.global_position
		if _on_leaf(l, 0.6):
			p.global_position = new_xf * l


## The van on the turning leaf moves with it. Its wheels are springs that
## feel down for the ground from their hubs; the near end rising 0.7 m as
## the leaf levelled came up past the rear hubs, the wheels lost the deck
## and the van sat on its belly, stuck (the first crossing, 2026-10-19). With
## three or four wheels on the leaf it rides along; driving still moves it.
func _carry_van(van: Camper, old_xf: Transform3D) -> void:
	if _thrown_t > 0.0:
		return
	# (the flap counts: the rear wheels were on it when the near end came up)
	var on := 0
	for w in van._wheels:
		if w.is_in_contact() and (w.get_contact_body() == leaf or w.get_contact_body() == apron):
			on += 1
	if on < 3:
		return
	var move := leaf.global_transform * old_xf.affine_inverse()
	van.global_transform = move * van.global_transform
	van.linear_velocity = move.basis * van.linear_velocity


func _try_lock(p) -> void:
	if locked or storm_blown or not _in_hut(p) or absf(angle) > LOCK_DEG or absf(omega) > 0.03:
		return
	locked = true
	angle = 0.0
	omega = 0.0
	_apply()
	for b in bolts:
		var tw := create_tween()
		tw.tween_property(b, "position:z", -leaf_len * 0.5 - 0.3, 0.25)
	Sfx.play3d("hit_metal_heavy", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	Sfx.play3d("latch", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	_tell_near("CLANK - the bolts shoot home into the far bank. The bridge is locked level.", 6.0)
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["bridge_locked"] = true
	print("[bridge] locked (crossed %s)" % crossed)


func _open_door(p) -> void:
	if door_open or not _in_hut(p):
		return
	door_open = true
	Sfx.play3d("door_open", hut_door.global_position + Vector3.UP, 0.0)
	var tw := create_tween()
	tw.tween_property(hut_door, "rotation:y", deg_to_rad(-100.0), 0.8).set_ease(Tween.EASE_OUT)


func _open_chest(p) -> void:
	if chest_open or not _in_hut(p):
		return
	chest_open = true
	Sfx.play3d("door_open", hut.global_position + Vector3.UP, -4.0, 0.1, 1.3)
	_spawn_reward()
	p.say("In the crate: a full can of fuel, a jug of coolant, and a spare tyre.", 5.0)


func _spawn_reward() -> void:
	var chest := hut.get_node("HutChest") as Node3D
	var items: Array[Carryable] = [FuelCan.new(), CoolantJug.new(), SpareWheel.new()]
	var k := 0
	for it in items:
		it.name = "HutReward%d" % k
		get_tree().current_scene.get("world").add_child(it)
		it.global_position = chest.global_transform * Vector3(-0.45 + k * 0.45, 0.85, 0)
		k += 1


func _in_hut(p) -> bool:
	if hut == null:
		return false
	var l := hut.global_transform.affine_inverse() * (p as Node3D).global_position
	return absf(l.x) < 1.6 and absf(l.z) < 1.6 and l.y > -0.5 and l.y < 2.5


## Into the river (off the side of the leaf, or the carts' tumble): a player
## swims to the near bank, soaked.
func _watch_water() -> void:
	if water_y < -1e8:
		return
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming:
			continue
		var at := p.global_position
		if at.y < water_y - 0.15 and at.distance_to(global_position) < 40.0 and Landscape.river_distance(at.x, at.z) < Landscape.RIVER_HALF + 1.0:
			print("[bridge] P%d in the river at %s" % [p.index + 1, at])
			p.fall_in_water(water_y, bank_at)


func _near_time(delta: float) -> void:
	if crossed:
		return
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_transform * Vector3(0, 0, -leaf_len * 0.5)) < HINT_NEAR + 20.0:
			near_t += delta
			return


## Hold H by the bridge: what to try, clearer the longer you're stuck.
func hint_for(i: int) -> String:
	if crossed or storm_blown or i < 0:
		return ""
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.index == i and q.global_position.distance_to(global_transform * Vector3(0, 0, -leaf_len * 0.5)) < HINT_NEAR + 20.0:
			var text := ""
			for h in HINTS:
				if near_t >= float(h[0]):
					text = String(h[1])
			return text
	return ""


func _apply() -> void:
	# the leaf itself turns (it sits on the pivot's origin): a moving body
	# follows its own transform, not its parent's - turning the pivot moved
	# the picture while the deck you drive on stayed at rest (2026-10-19)
	leaf.rotation = Vector3(deg_to_rad(angle), 0, 0)
	# the flap from its hinge on the near deck down (or up) onto the leaf's near end
	var t := pivot.transform * leaf.transform * Vector3(0, 0, leaf_len * 0.5 - 0.5)
	var h := Vector3(0, 0, APRON)
	var d := t - h
	var len := d.length()
	apron.rotation = Vector3(atan2(d.y, -d.z), 0, 0)
	apron_shape.size.z = len
	(apron.get_node("PlateShape") as CollisionShape3D).position.z = -len * 0.5
	apron_mesh.scale.z = len
	apron_mesh.position.z = -len * 0.5
	for c in carts:
		if not c["lost"]:
			_place_cart(c)


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 90.0:
			q.say(text, secs)


## The storm (F2) or its end: up and dead, or back as the story left it.
func storm_blow(on: bool) -> void:
	storm_blown = on
	if on:
		_close_road()
		return
	if barriers != null:
		_open_road()
	var st = get_tree().current_scene.get("story")
	if st != null and st.flags.has("bridge_locked"):
		locked = true
		angle = 0.0
	_apply()


func _close_road() -> void:
	if barriers != null:
		barriers.visible = true
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", false)


func _open_road() -> void:
	if barriers != null:
		barriers.visible = false
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", true)


# --- saving --------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"locked": locked, "crossed": crossed, "door_open": door_open, "chest_open": chest_open, "slams": slams}


## The leaf back at rest, the carts home, the gate down (a restart keeps the
## hut as you left it).
func reset_bridge() -> void:
	angle = 0.0 if locked else REST_DEG
	omega = 0.0
	_fall_t = 0.0
	for c in carts:
		c["lost"] = false
		c["z"] = c["home"]
		(c["node"] as Node3D).visible = true
	if gate != null:
		gate.reset()
	_apply()


## F1 (Puzzles, or a story jump to the bridge or before): everything fresh.
func reset() -> void:
	near_t = 0.0
	failing = false
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).whiteout = 0.0
	for k in 3:
		var it: Node = get_tree().current_scene.get("world").find_child("HutReward%d" % k, true, false) if is_inside_tree() else null
		if it != null:
			it.queue_free()
	from_dict({})


func from_dict(d: Dictionary) -> void:
	locked = bool(d.get("locked", false))
	crossed = bool(d.get("crossed", false))
	door_open = bool(d.get("door_open", false))
	chest_open = bool(d.get("chest_open", false))
	slams = int(d.get("slams", 0))
	if hut_door != null:
		hut_door.rotation.y = deg_to_rad(-100.0) if door_open else 0.0
	for b in bolts:
		b.position.z = -leaf_len * 0.5 - 0.3 if locked else -leaf_len * 0.5 + 0.3
	reset_bridge()
	if barriers != null:
		barriers.visible = false
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).disabled = true
