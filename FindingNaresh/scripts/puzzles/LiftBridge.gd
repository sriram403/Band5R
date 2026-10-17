class_name LiftBridge
extends Node3D

## #5, the lift bridge: the seesaw (design/PUZZLE_CHANGES.md #5, round 1b,
## agreed 2026-10-17). The middle of the old bridge is a bascule leaf (French
## for "seesaw"). The power's off (the last pole before the hut is snapped,
## `PowerLine`) and the brake is off, so the leaf just sits on its axle,
## heavier at the back: it rests tipped up at UP_DEG, the counterweight down
## on its pit floor.
##
## Weight on the leaf pulls it down by weight x distance from the axle
## (kg m, like a real seesaw). The leaf moves when the pull beats the back
## end's excess by more than the axle's friction:
## - one player alone at the tip isn't enough; both out there, slowly, is;
## - too much too fast (both + stones) and it slams onto the far bank;
## - stones near the axle do almost nothing (the crew's heap there is the lure);
## - the lock bolts are thrown from the machinery house, off the leaf: whoever
##   goes loses their weight, and the leaf rises unless stones at the tip
##   replace them.
## The machinery house is barred from inside: in through its hatch with a
## leg-up (fun mechanic 5, `PlayerRig`). Off the open tip, or off a slamming
## leaf, into the river: you're soaked and swim back to the near bank.

const UP_DEG := 30.0             ## resting up: the counterweight on its pit floor
## Tuned from where people really stand "at the tip" (~8.7 m out, measured
## in the `bridge` test; players 80 kg, stones 25 kg): one player alone, or
## one + one stone (914), holds nothing down; one + two stones (~1140)
## holds it down (T - F = 1050); both players (1390) bring it down in ~5 s
## (T + F = 1250); both + a stone slam it.
const TAIL := 1150.0             ## kg m: how much heavier the back end is
const FRICTION := 100.0          ## kg m: the axle's friction (smaller pulls move nothing)
const INERTIA := 3000.0          ## kg m s^2 per rad: how slowly the big leaf gets going
const DAMP := 0.25               ## 1/s: the bearings' drag on a moving leaf
const SLAM_W := 0.2              ## rad/s: landing faster than this is a slam (both + a stone: ~0.28; both alone: ~0.13)
const PLAYER_KG := 80.0
const LOCK_DEG := 0.6            ## flat enough for the bolts
const CW_LOW := -2.3             ## counterweight centre height (local) with the leaf up
const CW_HIGH := -0.55           ## ... and with it down (its top just below the floor)
const CW_SIZE := Vector3(1.8, 1.0, 2.0)
const HATCH_Z := Vector2(3.75, 4.85)   ## the hatch in the house's road-side wall (local z)
const HATCH_Y := Vector2(1.5, 3.4)     ## its sill and head: one jump doesn't reach the sill
const DOOR := Vector2(-0.2, 1.4)       ## z range of the door from the deck
const HINT_NEAR := 45.0
## the hints (hold H) by the bridge, clearer the longer you've been there (s)
const HINTS := [
	[0.0, "The power's off here. Read Naresh's notes: in the hut, and on the machinery house across the road."],
	[60.0, "The leaf sits on its axle like a seesaw. Weight far out on it pulls it down; near the axle, weight does almost nothing."],
	[150.0, "One of you alone isn't heavy enough. Both walk out to the far end, slowly, and it comes down."],
	[240.0, "Whoever throws the lock steps off the leaf, and it rises again. First leave stones right at the tip in their place."],
]

var angle := UP_DEG              ## degrees, 0 = down on the far bank
var omega := 0.0                 ## rad/s, positive = coming down
var locked := false
var door_open := false
## F2: the storm and the gale have the leaf up again: a dead end on the old
## road. Nothing locks; the barriers are back.
var storm_blown := false
var slams := 0
var pull := 0.0                  ## kg m this tick: everything on the leaf, before the back end
var near_t := 0.0                ## s someone has been at the bridge (the hints)
var m := 1.0                     ## local X side of the machinery house (the hut is on -m)
var leaf_len := 10.0
var deck_w := 8.6
var line: PowerLine
var barriers: Node3D
var leaf: AnimatableBody3D
var counterweight: AnimatableBody3D
var gear: Node3D
var door: Node3D
var panel_label: Label3D
var bolts: Array[Node3D] = []
var stones: Array[BridgeStone] = []
var water_y := -1e9              ## the river's surface under the bridge
var bank_at := Vector3.ZERO      ## where a swimmer climbs out (the near bank)
var _travel := 0.0               ## degrees moved since the last creak
var _groan_t := 0.0
var _hut_at := Vector3.ZERO


## `xf`: the axle on the road's centre line, deck top; -Z towards the far
## bank. `machinery_side`: +1 or -1, the local X side away from the hut.
## `panel_xf` is global: the dead lever panel inside the hut window.
## `stone_spots`: global spots for the river stones on the near bank (the
## heap by the axle is placed here). `bank`: where a swimmer climbs out.
func setup(xf: Transform3D, length: float, width: float, machinery_side: float, panel_xf: Transform3D, power: PowerLine, barrier_root: Node3D, stone_spots: Array[Vector3], bank: Vector3) -> void:
	add_to_group("lift_bridge")
	add_to_group("place_hint")
	transform = xf
	leaf_len = length
	deck_w = width
	m = machinery_side
	line = power
	barriers = barrier_root
	bank_at = bank
	_hut_at = panel_xf.origin
	var ri := int(Landscape.river.nearest(xf.origin.x, xf.origin.z)["index"]) if Landscape.river != null else -1
	if ri >= 0:
		water_y = Landscape.river_water_level(ri)
	_build_leaf()
	_build_machinery_house()
	_build_panel(panel_xf)
	_build_stones(stone_spots)
	_apply()


# --- building ------------------------------------------------------------------

func _build_leaf() -> void:
	var wood := ToonMat.make(Color(0.46, 0.34, 0.24), 0.012)
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	leaf = AnimatableBody3D.new()
	leaf.name = "Leaf"
	leaf.sync_to_physics = true
	add_child(leaf)
	var deck := Vector3(deck_w, 0.3, leaf_len)
	leaf.add_child(Build.box(deck, wood, Vector3(0, -0.15, -leaf_len * 0.5), Vector3.ZERO, "LeafDeck"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = deck
	cs.shape = sh
	cs.position = Vector3(0, -0.15, -leaf_len * 0.5)
	leaf.add_child(cs)
	# low steel kerbs along the edges (a stone can still bounce over them)
	for sx in [-1.0, 1.0]:
		leaf.add_child(Build.box(Vector3(0.25, 0.3, leaf_len), steel, Vector3(sx * (deck_w * 0.5 - 0.12), 0.15, -leaf_len * 0.5), Vector3.ZERO, "LeafGirder"))
		var gs := CollisionShape3D.new()
		var gb := BoxShape3D.new()
		gb.size = Vector3(0.25, 0.3, leaf_len)
		gs.shape = gb
		gs.position = Vector3(sx * (deck_w * 0.5 - 0.12), 0.15, -leaf_len * 0.5)
		leaf.add_child(gs)
	leaf.add_child(Build.box(Vector3(deck_w, 0.06, 0.6), ToonMat.make(Color(0.95, 0.75, 0.15)), Vector3(0, 0.03, -leaf_len + 0.3), Vector3.ZERO, "NoseStripe"))
	# chalk marks the crew left along the deck every 2 m (from the axle), so
	# "how far out" can be said
	var chalk := ToonMat.flat(Color(0.92, 0.92, 0.88))
	for k in range(2, int(leaf_len) + 1, 2):
		leaf.add_child(Build.box(Vector3(0.7, 0.012, 0.06), chalk, Vector3(-deck_w * 0.5 + 0.7, 0.006, -float(k)), Vector3(0, randf_range(-4, 4), 0), "Chalk"))
		leaf.add_child(Build.label3d("%d" % k, Vector3(-deck_w * 0.5 + 1.25, 0.02, -float(k) + 0.15), Vector3(-90, 0, 0), 0.22, Color(0.92, 0.92, 0.88)))
	# the lock bolts at the tip: they shoot forward into the far deck
	for sx in [-1.0, 1.0]:
		var bolt := Node3D.new()
		bolt.name = "Bolt"
		bolt.position = Vector3(sx * (deck_w * 0.5 - 0.6), -0.2, -leaf_len + 0.25)
		leaf.add_child(bolt)
		bolt.add_child(Build.box(Vector3(0.18, 0.14, 0.7), steel, Vector3.ZERO, Vector3.ZERO, "BoltBar"))
		bolts.append(bolt)
	# the axle, out to the machinery house
	add_child(Build.cyl(0.2, deck_w * 0.5 + 3.4, steel, Vector3(m * (deck_w * 0.5 + 3.4) * 0.5, -0.4, 0), Vector3(0, 0, 90), 10, "Axle"))
	# the repair notice on a post at the near end, where everyone walks past it
	var notice := Node3D.new()
	notice.name = "RepairNotice"
	notice.position = Vector3(-m * (deck_w * 0.5 - 0.4), 0, 3.2)
	notice.rotation = Vector3(0, deg_to_rad(-15.0 * m), 0)
	add_child(notice)
	notice.add_child(Build.cyl(0.05, 1.5, steel, Vector3(0, 0.75, 0), Vector3.ZERO, 6, "Post"))
	notice.add_child(Build.box(Vector3(0.9, 0.5, 0.03), ToonMat.make(Color(0.95, 0.93, 0.85)), Vector3(0, 1.4, 0), Vector3.ZERO, "Board"))
	notice.add_child(Build.label3d("LEAF UNDER REPAIR\nNOSE PLATE OFF\nBRAKE RELEASED", Vector3(0, 1.4, 0.02), Vector3.ZERO, 0.07, Color(0.15, 0.12, 0.1)))


func _build_machinery_house() -> void:
	var wall := ToonMat.make(Color(0.56, 0.54, 0.50))
	var steel := ToonMat.make(Color(0.30, 0.32, 0.34), 0.012)
	var inner := deck_w * 0.5 + 0.3          # the house's wall on the road side
	var outer := inner + 3.4
	var cx := m * (inner + outer) * 0.5
	const Z0 := -1.2
	const Z1 := 5.0
	const H := 4.6
	var house := Node3D.new()
	house.name = "MachineryHouse"
	add_child(house)
	# floor with the counterweight pit cut out of it
	var pit_x := Vector2(m * (inner + 0.1), m * (inner + 0.1 + CW_SIZE.x))
	var px0 := minf(pit_x.x, pit_x.y)
	var px1 := maxf(pit_x.x, pit_x.y)
	var pz0 := 1.6
	var pz1 := pz0 + CW_SIZE.z
	var fx0 := minf(m * inner, m * outer)
	var fx1 := maxf(m * inner, m * outer)
	for r in [Rect2(fx0, Z0, fx1 - fx0, pz0 - Z0), Rect2(fx0, pz1, fx1 - fx0, Z1 - pz1),
			Rect2(fx0, pz0, px0 - fx0, pz1 - pz0), Rect2(px1, pz0, fx1 - px1, pz1 - pz0)]:
		if r.size.x > 0.01 and r.size.y > 0.01:
			house.add_child(Build.solid_box(Vector3(r.size.x, 0.2, r.size.y), ToonMat.make(Color(0.48, 0.47, 0.45)), Vector3(r.position.x + r.size.x * 0.5, -0.1, r.position.y + r.size.y * 0.5), Vector3.ZERO, "HouseFloor"))
	# a rail round the pit (nobody falls in by accident)
	var rail := ToonMat.make(Color(0.95, 0.75, 0.15), 0.01)
	var pcx := (px0 + px1) * 0.5
	for spec in [[Vector3(px1 - px0 + 0.1, 0.9, 0.06), Vector3(pcx, 0.45, pz0 - 0.05)], [Vector3(px1 - px0 + 0.1, 0.9, 0.06), Vector3(pcx, 0.45, pz1 + 0.05)],
			[Vector3(0.06, 0.9, pz1 - pz0), Vector3(m * (inner + 0.15 + CW_SIZE.x), 0.45, (pz0 + pz1) * 0.5)]]:
		house.add_child(Build.solid_box(spec[0], rail, spec[1], Vector3.ZERO, "PitRail"))
	# walls: back (+Z), outer, and the road side with the barred door and,
	# further along, the hatch high up; the river end (-Z) is open over the water
	house.add_child(Build.solid_box(Vector3(fx1 - fx0, H, 0.2), wall, Vector3(cx, H * 0.5, Z1), Vector3.ZERO, "HouseBack"))
	house.add_child(Build.solid_box(Vector3(0.2, H, Z1 - Z0), wall, Vector3(m * outer, H * 0.5, (Z0 + Z1) * 0.5), Vector3.ZERO, "HouseOuter"))
	var wx := m * inner
	house.add_child(Build.solid_box(Vector3(0.2, H, DOOR.x - Z0), wall, Vector3(wx, H * 0.5, (Z0 + DOOR.x) * 0.5), Vector3.ZERO, "HouseInnerA"))
	house.add_child(Build.solid_box(Vector3(0.2, H - 2.4, DOOR.y - DOOR.x), wall, Vector3(wx, 2.4 + (H - 2.4) * 0.5, (DOOR.x + DOOR.y) * 0.5), Vector3.ZERO, "HouseDoorHead"))
	house.add_child(Build.solid_box(Vector3(0.2, H, HATCH_Z.x - DOOR.y), wall, Vector3(wx, H * 0.5, (DOOR.y + HATCH_Z.x) * 0.5), Vector3.ZERO, "HouseInnerB"))
	house.add_child(Build.solid_box(Vector3(0.2, HATCH_Y.x, HATCH_Z.y - HATCH_Z.x), wall, Vector3(wx, HATCH_Y.x * 0.5, (HATCH_Z.x + HATCH_Z.y) * 0.5), Vector3.ZERO, "HatchBelow"))
	house.add_child(Build.solid_box(Vector3(0.2, H - HATCH_Y.y, HATCH_Z.y - HATCH_Z.x), wall, Vector3(wx, HATCH_Y.y + (H - HATCH_Y.y) * 0.5, (HATCH_Z.x + HATCH_Z.y) * 0.5), Vector3.ZERO, "HatchAbove"))
	house.add_child(Build.solid_box(Vector3(0.2, H, Z1 - HATCH_Z.y), wall, Vector3(wx, H * 0.5, (HATCH_Z.y + Z1) * 0.5), Vector3.ZERO, "HouseInnerC"))
	# the hatch's shutter, hooked open against the wall, and a sill
	house.add_child(Build.box(Vector3(0.32, 0.08, HATCH_Z.y - HATCH_Z.x + 0.1), ToonMat.make(Color(0.42, 0.30, 0.20)), Vector3(wx, HATCH_Y.x + 0.02, (HATCH_Z.x + HATCH_Z.y) * 0.5), Vector3.ZERO, "HatchSill"))
	house.add_child(Build.box(Vector3(0.05, HATCH_Y.y - HATCH_Y.x, HATCH_Z.y - HATCH_Z.x), ToonMat.make(Color(0.42, 0.30, 0.20)), Vector3(wx - m * 0.55, (HATCH_Y.x + HATCH_Y.y) * 0.5, HATCH_Z.y + 0.55), Vector3(0, 90, 0), "HatchShutter"))
	# the keeper's ladder lies broken in the grass below it
	house.add_child(Build.box(Vector3(0.45, 0.06, 2.4), ToonMat.make(Color(0.50, 0.38, 0.26)), Vector3(wx - m * 0.9, 0.05, HATCH_Z.y + 0.6), Vector3(0, 12 * m, 4), "BrokenLadder"))
	house.add_child(Build.box(Vector3(0.45, 0.06, 1.0), ToonMat.make(Color(0.50, 0.38, 0.26)), Vector3(wx - m * 1.6, 0.05, HATCH_Z.y - 1.4), Vector3(0, -30 * m, 6), "BrokenLadderEnd"))
	house.add_child(Build.solid_box(Vector3(fx1 - fx0 + 0.4, 0.2, Z1 - Z0 + 0.4), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(cx, H + 0.1, (Z0 + Z1) * 0.5), Vector3.ZERO, "HouseRoof"))
	house.add_child(Build.label3d("MACHINERY", Vector3(m * (inner - 0.12), 2.9, 0.6), Vector3(0, -90 * m, 0), 0.22, Color(0.95, 0.92, 0.8)))
	# the door: barred from inside, so it only opens from in there
	door = Node3D.new()
	door.name = "DoorHinge"
	door.position = Vector3(wx, 0, DOOR.y)
	house.add_child(door)
	var leaf_w := DOOR.y - DOOR.x
	door.add_child(Build.solid_box(Vector3(0.08, 2.35, leaf_w - 0.04), ToonMat.make(Color(0.40, 0.30, 0.22)), Vector3(0, 1.18, -leaf_w * 0.5), Vector3.ZERO, "Door"))
	var bar := Build.box(Vector3(0.08, 0.12, leaf_w + 0.3), ToonMat.make(Color(0.35, 0.25, 0.18)), Vector3(m * 0.12, 1.15, -leaf_w * 0.5), Vector3.ZERO, "DoorBar")
	door.add_child(bar)
	var da := Build.interact_area(Vector3(1.4, 2.2, leaf_w), Vector3(0, 1.1, -leaf_w * 0.5), "", func(p): _open_door(p), "DoorArea")
	da.set_meta("tag_name", "the machinery house door")
	da.set_meta("prompt_fn", func(p) -> String:
		return "Lift the bar and open the door" if not door_open and _inside_house(p) else "")
	da.set_meta("blocked_fn", func(p) -> String:
		if door_open or _inside_house(p):
			return ""
		return "Barred from the inside. There's a hatch higher up the wall.")
	door.add_child(da)
	NareshNote.make(house, "lb_door", Vector3(wx - m * 0.13, 1.55, DOOR.y + 0.35), -90.0 * m,
		"Barred from inside, and the keeper's ladder's in bits. My friend crouched by the wall under the hatch and I jumped up off their back. Easy.")
	# the gear on the axle by the outer wall, turning as the leaf moves
	gear = Node3D.new()
	gear.name = "Gear"
	gear.position = Vector3(m * (outer - 0.5), -0.4, 0)
	house.add_child(gear)
	gear.add_child(Build.cyl(1.25, 0.25, steel, Vector3.ZERO, Vector3(0, 0, 90), 20, "GearDisc"))
	for k in 18:
		var a := TAU * k / 18.0
		var tooth := Build.box(Vector3(0.25, 0.3, 0.22), steel, Vector3(0, sin(a) * 1.35, cos(a) * 1.35), Vector3.ZERO, "Tooth")
		tooth.rotation.x = PI * 0.5 - a
		gear.add_child(tooth)
	gear.add_child(Build.box(Vector3(0.27, 1.1, 0.14), ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 0.55, 0), Vector3.ZERO, "Mark"))
	# the lock lever, by the back wall where you can see out of the door to the leaf
	var lever := Node3D.new()
	lever.name = "LockLever"
	# (by the outer wall: a climber drops in from the hatch by the inner one)
	lever.position = Vector3(m * (inner + 2.6), 0, Z1 - 0.35)
	house.add_child(lever)
	lever.add_child(Build.box(Vector3(0.5, 0.9, 0.3), steel, Vector3(0, 0.45, 0), Vector3.ZERO, "LockBase"))
	lever.add_child(Build.cyl(0.035, 0.8, ToonMat.make(Color(0.75, 0.2, 0.18)), Vector3(0, 1.2, -0.1), Vector3(-25, 0, 0), 6, "LockHandle"))
	lever.add_child(Build.label3d("LEAF LOCK", Vector3(0, 0.75, -0.16), Vector3(0, 180, 0), 0.08, Color(0.95, 0.92, 0.8)))
	var la := Build.interact_area(Vector3(0.7, 1.0, 0.8), Vector3(0, 1.1, -0.2), "", func(_p): _try_lock(), "LockArea")
	la.set_meta("tag_name", "the leaf lock")
	la.set_meta("prompt_fn", func(_p) -> String: return "" if locked else "Throw the lock bolts")
	la.set_meta("blocked_fn", func() -> String:
		if locked:
			return "The bolts are home. The leaf's locked down."
		if storm_blown:
			return "The leaf's up in the gale. The bolts can't reach."
		if angle > LOCK_DEG:
			return "The leaf isn't down. The bolts won't reach the far side."
		if absf(omega) > 0.03:
			return "It's still moving."
		return "")
	lever.add_child(la)
	NareshNote.make(lever, "lb_lock", Vector3(0.28, 0.75, -0.16), 180.0,
		"The bolts only go in when it's flat and still. And whoever throws them isn't out there holding it down. Took us ages to work that one out.")
	# the counterweight: concrete in its pit, down on the floor of it now
	counterweight = AnimatableBody3D.new()
	counterweight.name = "Counterweight"
	counterweight.sync_to_physics = true
	counterweight.position = Vector3(pcx, CW_LOW, (pz0 + pz1) * 0.5)
	house.add_child(counterweight)
	var cw_size := CW_SIZE - Vector3(0.1, 0, 0.1)
	counterweight.add_child(Build.box(cw_size, ToonMat.make(Color(0.62, 0.62, 0.60)), Vector3.ZERO, Vector3.ZERO, "Block"))
	counterweight.add_child(Build.box(Vector3(cw_size.x + 0.02, 0.08, 0.3), ToonMat.make(Color(0.95, 0.75, 0.15)), Vector3(0, CW_SIZE.y * 0.5 - 0.02, -cw_size.z * 0.5 + 0.15), Vector3.ZERO, "Stripe"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = cw_size
	cs.shape = sh
	counterweight.add_child(cs)
	counterweight.set_meta("tag_name", "the counterweight")


## The dead lever panel in the hut window: the power's off.
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
		var col: Color = spec[2]
		panel.add_child(Build.cyl(0.03, 0.5, ToonMat.make(col), Vector3(x, 1.2, 0.0), Vector3(-20, 0, 0), 6, nm + "Handle"))
		panel.add_child(Build.label3d(nm, Vector3(x, 1.02, 0.21), Vector3.ZERO, 0.08, Color(0.95, 0.92, 0.8)))
		var a := Build.interact_area(Vector3(0.45, 0.7, 0.7), Vector3(x, 1.1, 0.1), "", func(_p): pass, nm + "Lever")
		a.set_meta("tag_name", "the %s lever" % nm.to_lower())
		a.set_meta("blocked_fn", func() -> String: return "Nothing. No power: the line's down at the last pole.")
		panel.add_child(a)
	NareshNote.make(panel, "lb_hut", Vector3(0.45, 1.02, 0.21), 0.0,
		"No power - the line's snapped at the last pole. Doesn't matter. The brake's off and the leaf just sits on its axle, heavier at the back end. Like a seesaw.")


## The crew's heap of stones by the axle (where they do nothing), and the
## river stones on the near bank.
func _build_stones(spots: Array[Vector3]) -> void:
	var heap: Array[Vector3] = []
	var hx := -m * 2.6
	for k in 8:
		var row := k % 4
		var layer := k / 4
		heap.append(transform * Vector3(hx + (row % 2) * 0.62 - 0.3 + layer * 0.2, 0.16 + layer * 0.27, 1.2 + (row / 2) * 0.5 + layer * 0.15))
	# (built before the world is in the tree: local transforms only)
	var inv := transform.affine_inverse()
	for p in heap + spots:
		var s := BridgeStone.new()
		s.name = "BridgeStone%d" % stones.size()
		s.transform = inv * Transform3D(Basis(Vector3.UP, randf() * TAU), p)
		s.home = s.transform
		add_child(s)
		s.sleeping = true
		stones.append(s)


# --- running -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_watch_water()
	if storm_blown:
		# whatever a load set, it stays up, swaying in the gale
		locked = false
		omega = 0.0
		angle = UP_DEG - 2.0 + sin(Time.get_ticks_msec() * 0.0011) * 2.0
		if barriers != null and not barriers.visible:
			_close_road()
		_apply()
		return
	_near_time(delta)
	if locked:
		return
	_carry_stones()
	pull = _pull()
	var net := pull - TAIL           # kg m; positive pulls the nose down
	var a := deg_to_rad(angle)
	var resting_up := angle >= UP_DEG - 0.001 and net <= FRICTION
	var resting_down := angle <= 0.001 and net >= -FRICTION
	if absf(omega) < 0.002 and (absf(net) <= FRICTION or resting_up or resting_down):
		omega = 0.0
		_groan(net, delta)
		return
	var fr := FRICTION * signf(omega if absf(omega) >= 0.002 else net)
	omega += (net - fr) / INERTIA * delta
	omega *= exp(-DAMP * delta)
	a -= omega * delta
	var a_up := deg_to_rad(UP_DEG)
	if a <= 0.0:
		a = 0.0
		if omega > SLAM_W:
			_slam()
			omega = -omega * 0.25
		else:
			if omega > 0.05:
				Sfx.play3d("hit_wood_heavy", global_transform * Vector3(0, 0, -leaf_len), -2.0)
			omega = 0.0
	elif a >= a_up:
		a = a_up
		if omega < -0.15:
			Sfx.play3d("hit_metal_heavy", counterweight.global_position, -2.0)
			_tell_near("THUD - the counterweight hits the bottom of its pit and the leaf jolts up.", 3.0)
		omega = 0.0
	var was := angle
	angle = rad_to_deg(a)
	_travel += absf(angle - was)
	if _travel > 2.0:
		_travel = 0.0
		Sfx.play3d("creak", global_position + Vector3(m * (deck_w * 0.5 + 1.5), 0.5, 0), -4.0, 0.15, 0.8 + randf() * 0.3)
	var old_xf := leaf.global_transform
	_apply()
	_carry_players(old_xf)


## People standing on the turning leaf move with it (the engine left them
## behind: standing still, P1 slid from 8.2 to 7.9 m out in 3 s as the
## leaf came down, and the lost weight stalled it, 2026-10-17).
func _carry_players(old_xf: Transform3D) -> void:
	var new_xf := leaf.global_transform
	var inv := old_xf.affine_inverse()
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming or not p.is_on_floor():
			continue
		var l := inv * p.global_position
		if _on_leaf(l, 0.6) < 0.0:
			continue
		p.global_position = new_xf * l


## Weight x distance from the axle of everyone and everything on the leaf.
func _pull() -> float:
	var inv := leaf.global_transform.affine_inverse()
	var total := 0.0
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming:
			continue
		var d := _on_leaf(inv * p.global_position, 1.4)
		if d < 0.0:
			continue
		total += PLAYER_KG * d
		if p.held is BridgeStone:
			total += BridgeStone.WEIGHT * d
	for s in stones:
		if s.lost or not s.holders.is_empty():
			continue
		var d := _on_leaf(inv * s.global_position, 0.8)
		if d >= 0.0:
			total += BridgeStone.WEIGHT * d
	return total


## Stones lying still on the leaf ride along with it (`BridgeStone.ride`):
## heavy rough stones don't skate about on timber, and weight that slid
## away by itself made the leaf stop halfway for no reason you could see
## (the first `bridge` runs, 2026-10-17).
func _carry_stones() -> void:
	var lxf := leaf.global_transform
	var inv := lxf.affine_inverse()
	for s in stones:
		if s.lost or not s.holders.is_empty():
			continue
		if s.riding:
			s.global_transform = lxf * s.ride_xf
		elif s.linear_velocity.length() < 0.25 and _on_leaf(inv * s.global_position, 0.5) >= 0.0:
			s.ride(leaf)


## Distance from the axle (m) of a point on the leaf (leaf-local), or -1.
func _on_leaf(l: Vector3, above: float) -> float:
	if absf(l.x) > deck_w * 0.5 + 0.1 or l.z > 0.15 or l.z < -leaf_len - 0.15 or l.y < -0.35 or l.y > above:
		return -1.0
	return clampf(-l.z, 0.0, leaf_len)


## Close to moving but held by the friction: the old timbers groan, so you
## know you're nearly there.
func _groan(net: float, delta: float) -> void:
	_groan_t -= delta
	if _groan_t > 0.0:
		return
	var near_down := angle > 1.0 and net > FRICTION * 0.4
	var near_up := angle < UP_DEG - 1.0 and net < -FRICTION * 0.4
	if near_down or near_up:
		_groan_t = 2.2
		Sfx.play3d("groan", global_transform * Vector3(0, 0, -leaf_len * 0.5), -6.0, 0.1, 0.7)


func _slam() -> void:
	slams += 1
	var tip := global_transform * Vector3(0, 0, -leaf_len)
	Sfx.play3d("bang", tip, 4.0)
	Sfx.play3d("hit_wood_heavy", tip, 2.0)
	_tell_near("BANG - the leaf slams down onto the far bank and bounces.", 4.0)
	var down := -leaf.global_transform.basis.z.normalized()      # along the leaf, out to the tip
	var inv := leaf.global_transform.affine_inverse()
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or _on_leaf(inv * p.global_position, 1.4) < 0.0:
			continue
		p.knock(down * 2.5 + Vector3.UP * 3.0)
	# loose stones jump; out near the tip they can go over the kerb
	for s in stones:
		if s.lost or not s.holders.is_empty():
			continue
		var d := _on_leaf(inv * s.global_position, 0.8)
		if d < 0.0:
			continue
		s.unride()
		var side := leaf.global_transform.basis.x * randf_range(-1.0, 1.0) * (d / leaf_len) * 4.0
		s.apply_central_impulse((Vector3.UP * 3.5 + down * 1.5 + side) * BridgeStone.WEIGHT * 0.5)
	print("[bridge] slam %d" % slams)


func _try_lock() -> void:
	if locked or storm_blown or angle > LOCK_DEG or absf(omega) > 0.03:
		return
	_lock()


func _lock() -> void:
	locked = true
	angle = 0.0
	omega = 0.0
	_apply()
	for s in stones:
		s.unride()
	for b in bolts:
		var tw := create_tween()
		tw.tween_property(b, "position:z", -leaf_len - 0.15, 0.25)
	Sfx.play3d("hit_metal_heavy", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	Sfx.play3d("latch", global_transform * Vector3(0, 0, -leaf_len), 0.0)
	_open_road()
	_tell_near("CLANK - the lock bolts shoot home into the far side. The leaf's locked down; the road's open.", 7.0)
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["bridge_down"] = true
	print("[bridge] locked (slams %d)" % slams)


func _open_door(p) -> void:
	if door_open or not _inside_house(p):
		return
	door_open = true
	Sfx.play3d("door_open", door.global_position + Vector3.UP, 0.0)
	var tw := create_tween()
	tw.tween_property(door, "rotation:y", deg_to_rad(-100.0 * m), 0.8).set_ease(Tween.EASE_OUT)


func _inside_house(p) -> bool:
	var l := global_transform.affine_inverse() * (p as Node3D).global_position
	return l.x * m > deck_w * 0.5 + 0.3


## Into the river: a player is soaked and swims back to the near bank; a
## stone sinks for good.
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
	for s in stones:
		if s.lost or not s.holders.is_empty():
			continue
		var sp := s.global_position
		if sp.y < water_y - 0.1 and Landscape.river_distance(sp.x, sp.z) < Landscape.RIVER_HALF + 1.0:
			s.sink()


func _near_time(delta: float) -> void:
	if locked:
		return
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_position) < HINT_NEAR:
			near_t += delta
			return


## Hold H by the bridge: what to try, clearer the longer you're stuck.
func hint_for(i: int) -> String:
	if locked or storm_blown or i < 0:
		return ""
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.index == i and q.global_position.distance_to(global_position) < HINT_NEAR:
			var text := ""
			for h in HINTS:
				if near_t >= float(h[0]):
					text = String(h[1])
			return text
	return ""


func _apply() -> void:
	leaf.rotation = Vector3(deg_to_rad(angle), 0, 0)
	gear.rotation.x = deg_to_rad(angle * 2.0)
	var t := 1.0 - clampf(angle / UP_DEG, 0.0, 1.0)
	counterweight.position.y = lerpf(CW_LOW, CW_HIGH, t)


## The storm (F2) or its end: up and dead, or back as the story left it.
func storm_blow(on: bool) -> void:
	storm_blown = on
	if on:
		_close_road()
		return
	var st = get_tree().current_scene.get("story")
	if st != null and st.flags.has("bridge_down"):
		from_dict({"locked": true, "door_open": door_open})
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


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 80.0:
			q.say(text, secs)


# --- saving --------------------------------------------------------------------

func to_dict() -> Dictionary:
	return {"locked": locked, "door_open": door_open, "slams": slams}


## F1 (Puzzles, or a story jump to the bridge or before): the leaf up, the
## door barred, the stones back where the crew left them.
func reset() -> void:
	near_t = 0.0
	for s in stones:
		s.put_home()
	from_dict({})


## A load: locked or up (a leaf held halfway by weight isn't saved: the
## weights aren't).
func from_dict(d: Dictionary) -> void:
	locked = bool(d.get("locked", false))
	door_open = bool(d.get("door_open", false)) or locked
	slams = int(d.get("slams", 0))
	angle = 0.0 if locked else UP_DEG
	omega = 0.0
	if door != null:
		door.rotation.y = deg_to_rad(-100.0 * m) if door_open else 0.0
	for b in bolts:
		b.position.z = -leaf_len - 0.15 if locked else -leaf_len + 0.25
	if barriers != null:
		barriers.visible = not locked
		for c in barriers.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).disabled = locked
	_apply()
