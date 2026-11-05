class_name RampJump
extends Node3D

## The old bridge's gap (the user, 2026-10-20: the seesaw cut; a fun thing, not
## a puzzle). Somebody's old steel trailer ramp, propped on oil drums and
## railway sleepers at the edge of the gap, skid marks up it. Take a long
## run-up, about 60 km/h, and the van jumps the river.
##
## The landing is a real bang: the front-left wheel's nuts shear, the wheel
## bounces down the road and through the far hut's shutter, and the van sits
## on its hub. In by the smashed shutter (the crate and a leg-up), and inside:
## your wheel, new nuts in the toolbox, fuel, coolant, something of Naresh's.
## Back on with the jack, as with a flat.
##
## Too slow: into the shallows, a fade, back at the run-up.
##
## The frame: the origin on the near edge of the gap at the deck's top, -Z
## across it to the far edge at z = -gap_len.

const RAMP_H := 0.8              ## m: the top above the deck. Measured (ramp_bench, the 14 m gap, flat out reaches 66 km/h): 56.6 at the lip falls short, 60.9 lands clean
const RAMP_LEN := 8.0            ## m along the deck
const RAMP_W := 5.6              ## m: the van is 2.6 m wide; a wide target at 60 km/h
const RUNUP := 100.0             ## m from the restart spot to the ramp's foot
const HINT_NEAR := 60.0
const HINTS := [
	[0.0, ""],
	[30.0, "Read the note on the post by the ramp."],
	[70.0, "Reverse well back up the road, a good 100 m, and keep your foot down all the way up the ramp. The speedometer wants 60."],
	[140.0, "Line up on the ramp from far back, flat out from the start. Too slow only costs you a tow."],
]

var gap_len := 10.0
var deck_w := 8.6
var water_y := -1e9
var jumped := false              ## the van has made it over
var shutter_broken := false
var door_open := false
var box_open := false
var near_t := 0.0
var failing := false
var hub_note_said := false
var last_lip_kmh := 0.0          ## the speed at the lip of the last try (the tests read it)
var misses := 0

var near_bank := Vector3.ZERO    ## where a swimmer climbs out, either side
var far_bank := Vector3.ZERO
var van_start := Transform3D()   ## the run-up: where a miss puts the van
var far_start := Transform3D()   ## a van that drives off the far side, on the way back
var hut: Node3D
var hut_door: Node3D
var van_wheel: SpareWheel        ## the wheel, once it has landed in the hut
var ramp: Node3D
var ramp_shape: BoxShape3D
var shutter: Node3D
var splinters: Node3D
var _window := Vector3.ZERO      ## the shutter's middle (hut's frame)
var _inward := Vector3.ZERO      ## through the window, into the hut (hut's frame)
var _rubble := Vector3.ZERO      ## where the wheel gets kicked up (hut's frame)
var _launched := false           ## all four wheels off the ground over the gap
var _land_grace := 0.0
var _stuck_t := 0.0
var _flying: Node3D              ## the wheel on its way to the hut


## `xf`: the frame above. `hut_xf`: the far hut, its door on -Z towards the road.
func setup(xf: Transform3D, gap: float, width: float, panel_xf: Transform3D, hut_xf: Transform3D,
		bank_near: Vector3, bank_far: Vector3, start: Transform3D, start_far: Transform3D) -> void:
	add_to_group("ramp_jump")
	add_to_group("place_hint")
	transform = xf
	gap_len = gap
	deck_w = width
	near_bank = bank_near
	far_bank = bank_far
	van_start = start
	far_start = start_far
	if Landscape.river != null:
		water_y = Landscape.river_water_level(int(Landscape.river.nearest(xf.origin.x, xf.origin.z)["index"]))
	build_ramp(RAMP_H, RAMP_LEN)
	_build_wreck()
	_build_panel(panel_xf)
	_build_hut(xf.affine_inverse() * hut_xf)


# --- building ------------------------------------------------------------------

## Two steel trailer ramps bolted side by side, on what was lying around. Takes
## its numbers as arguments so the bench can try others.
func build_ramp(h: float, length: float) -> void:
	if ramp != null:
		remove_child(ramp)
		ramp.free()
	ramp = Node3D.new()
	ramp.name = "TrailerRamp"
	add_child(ramp)
	var steel := ToonMat.make(Color(0.34, 0.31, 0.28), 0.012)
	var rust := ToonMat.make(Color(0.46, 0.27, 0.16), 0.012)
	var ang := atan2(h, length)
	var slope := sqrt(h * h + length * length)
	# the top of the plate runs from the deck at z = length to h up at z = 0.2
	# (just back from the edge, as a real one wouldn't overhang on nothing)
	var thick := 0.14
	var mid := Vector3(0, h * 0.5, 0.2 + length * 0.5) - Vector3(0, cos(ang), -sin(ang)) * thick * 0.5
	var xf := Transform3D(Basis(Vector3.RIGHT, ang), mid)
	var body := StaticBody3D.new()
	body.name = "RampBody"
	var cs := CollisionShape3D.new()
	ramp_shape = BoxShape3D.new()
	ramp_shape.size = Vector3(RAMP_W, thick, slope)
	cs.shape = ramp_shape
	cs.transform = xf
	body.add_child(cs)
	ramp.add_child(body)
	# the plate, in two panels with a seam, and its raised side lips
	for side in [-1.0, 1.0]:
		var panel := Build.box(Vector3(RAMP_W * 0.5 - 0.04, thick, slope), steel if side < 0.0 else rust, Vector3.ZERO, Vector3.ZERO, "RampPanel")
		panel.transform = xf.translated_local(Vector3(side * RAMP_W * 0.25, 0, 0))
		ramp.add_child(panel)
		var lip := Build.box(Vector3(0.12, 0.16, slope), rust, Vector3.ZERO, Vector3.ZERO, "RampLip")
		lip.transform = xf.translated_local(Vector3(side * (RAMP_W * 0.5 - 0.06), 0.14, 0))
		ramp.add_child(lip)
	# cross-treads, a bit uneven
	var k := 0
	var z := -slope * 0.5 + 0.5
	while z < slope * 0.5:
		var tread := Build.box(Vector3(RAMP_W - 0.1, 0.02, 0.06), rust, Vector3.ZERO, Vector3.ZERO, "Tread")
		tread.transform = xf.translated_local(Vector3(0, thick * 0.5 + 0.01, z))
		ramp.add_child(tread)
		k += 1
		z += 0.62 + 0.11 * float(k % 3)
	# skid marks up it: somebody's done this before
	var skid := ToonMat.flat(Color(0.06, 0.06, 0.07))
	for s in [-1.0, 1.0]:
		for j in 2:
			var mark := Build.box(Vector3(0.24, 0.01, slope * (0.42 + 0.13 * j)), skid, Vector3.ZERO, Vector3.ZERO, "SkidMark")
			mark.transform = xf.translated_local(Vector3(s * (1.02 + 0.07 * j), thick * 0.5 + 0.022, slope * (0.2 - 0.16 * j)))
			ramp.add_child(mark)
	# what it stands on: oil drums at the high end, sleepers stacked under the middle
	var drum := ToonMat.make(Color(0.20, 0.31, 0.38), 0.012)
	var sleeper := ToonMat.make(Color(0.20, 0.15, 0.11), 0.012)
	for spec in [[-1.95, 0.55, 0.05], [-0.72, 0.62, 0.0], [0.62, 0.52, 0.09], [1.88, 0.60, 0.03]]:
		var dh := maxf(0.2, h - 0.12)
		ramp.add_child(Build.cyl(0.32, dh, drum if spec[0] < 1.0 else rust, Vector3(spec[0], dh * 0.5, spec[1]), Vector3(spec[2] * 5.0, 12.0, 0), 12, "OilDrum"))
	var under_h := h * (1.0 - (2.8 + 0.2) / length) - 0.12
	var layers := int(floor(under_h / 0.18))
	for l in layers:
		var turn := 90.0 if l % 2 == 0 else 3.0
		var offs := Vector3(0.05 * float(l % 3), 0.09 + l * 0.18, 3.0 + 0.04 * float(l % 2))
		ramp.add_child(Build.box(Vector3(2.6, 0.17, 0.26), sleeper, offs, Vector3(0, turn - 90.0 + float(l), 0), "Sleeper"))
	# S1: Naresh's note, on a post by the foot, where you stop to look at it
	var at := Vector3(RAMP_W * 0.5 + 1.0, 0, length - 1.0)
	ramp.add_child(Build.box(Vector3(0.1, 1.5, 0.1), sleeper, at + Vector3(0, 0.75, 0), Vector3.ZERO, "NotePost"))
	NareshNote.make(ramp, "rj_ramp", at + Vector3(0, 1.2, 0.06), 0.0,
		"My friend said 60 was plenty. It was. Mostly.")


## S2: somebody who didn't make it: a rusted car nose-down in the shallows,
## beside the gap, where you see it from the ramp's top (and the far bank).
func _build_wreck() -> void:
	var wreck := Node3D.new()
	wreck.name = "RiverWreck"
	var at := Vector3(deck_w * 0.5 + 8.0, 0, -gap_len * 0.42)
	wreck.position = at
	add_child(wreck)
	var y := water_y - transform.origin.y if water_y > -1e8 else -5.0     # (the world is built outside the tree: no global_* here)
	var rust := ToonMat.make(Color(0.42, 0.24, 0.15), 0.012)
	var dark := ToonMat.make(Color(0.14, 0.13, 0.12), 0.012)
	var car := Node3D.new()
	car.name = "WreckCar"
	car.position = Vector3(0, y + 0.55, 0)
	car.rotation_degrees = Vector3(-24, 33, 7)
	wreck.add_child(car)
	car.add_child(Build.box(Vector3(1.7, 0.75, 4.1), rust, Vector3.ZERO, Vector3.ZERO, "WreckBody"))
	car.add_child(Build.box(Vector3(1.45, 0.62, 1.9), rust, Vector3(0, 0.66, 0.35), Vector3.ZERO, "WreckCab"))
	car.add_child(Build.box(Vector3(1.35, 0.46, 0.05), dark, Vector3(0, 0.68, -0.62), Vector3.ZERO, "WreckGlassHole"))
	var w1 := Build.cyl(0.34, 0.2, dark, Vector3(0.92, -0.26, 1.25), Vector3(0, 0, 90), 10, "WreckWheel")
	car.add_child(w1)


## The dead lever desk in the near hut's window. No power, no bridge left.
func _build_panel(xf: Transform3D) -> void:
	var panel := Node3D.new()
	panel.name = "LeverPanel"
	panel.transform = transform.affine_inverse() * xf
	add_child(panel)
	var steel := ToonMat.make(Color(0.30, 0.34, 0.32))
	panel.add_child(Build.box(Vector3(1.2, 1.0, 0.4), steel, Vector3(0, 0.5, 0), Vector3.ZERO, "Desk"))
	panel.add_child(Build.label3d("NO POWER", Vector3(0, 1.15, 0.05), Vector3(-30, 0, 0), 0.08, Color(0.95, 0.92, 0.8)))
	for spec in [["RAISE", -0.3, Color(0.2, 0.5, 0.3)], ["LOWER", 0.3, Color(0.75, 0.2, 0.18)]]:
		var nm: String = spec[0]
		var x: float = spec[1]
		panel.add_child(Build.cyl(0.03, 0.5, ToonMat.make(spec[2]), Vector3(x, 1.2, 0.0), Vector3(-20, 0, 0), 6, nm + "Handle"))
		panel.add_child(Build.label3d(nm, Vector3(x, 1.02, 0.21), Vector3.ZERO, 0.08, Color(0.95, 0.92, 0.8)))
		var a := Build.interact_area(Vector3(0.45, 0.7, 0.7), Vector3(x, 1.1, 0.1), "", func(_p): pass, nm + "Lever")
		a.set_meta("tag_name", "the %s lever" % nm.to_lower())
		a.set_meta("blocked_fn", func() -> String: return "Nothing. The line's down, and there's no bridge left to lift.")
		panel.add_child(a)


## The far bank's hut (`hx`: local to the frame; its door on -Z, the road side;
## the shuttered window high up on the side facing the gap).
func _build_hut(hx: Transform3D) -> void:
	var stone := ToonMat.make(Color(0.55, 0.53, 0.49), 0.012)
	var roof := ToonMat.make(Color(0.30, 0.28, 0.27), 0.012)
	var wood := ToonMat.make(Color(0.36, 0.27, 0.19), 0.012)
	hut = Node3D.new()
	hut.name = "FarHut"
	hut.transform = hx
	add_child(hut)
	# a bridge-keeper's tower hut: a tall shutter high up (a plain leg-up's feet
	# reach 1.92 m: you need the crate too, ~2.3 m)
	const W := 3.6
	const H := 4.6
	const T := 0.3
	var sill := 2.1
	var win := Vector2(1.0, 1.9)
	var to_gap := hx.affine_inverse() * Vector3(0, 0, -gap_len * 0.5)
	var ws := 1.0 if to_gap.x > 0.0 else -1.0
	hut.add_child(Build.solid_box(Vector3(W, 0.2, W), stone, Vector3(0, -0.1, 0), Vector3.ZERO, "HutFloor"))
	hut.add_child(Build.solid_box(Vector3(W + 0.4, 0.25, W + 0.4), roof, Vector3(0, H + 0.12, 0), Vector3.ZERO, "HutRoof"))
	hut.add_child(Build.solid_box(Vector3(W, H, T), stone, Vector3(0, H * 0.5, W * 0.5), Vector3.ZERO, "WallBack"))
	hut.add_child(Build.solid_box(Vector3(T, H, W), stone, Vector3(-ws * W * 0.5, H * 0.5, 0), Vector3.ZERO, "WallFar"))
	var wx := ws * W * 0.5
	hut.add_child(Build.solid_box(Vector3(T, sill, W), stone, Vector3(wx, sill * 0.5, 0), Vector3.ZERO, "WinBelow"))
	hut.add_child(Build.solid_box(Vector3(T, H - sill - win.y, W), stone, Vector3(wx, sill + win.y + (H - sill - win.y) * 0.5, 0), Vector3.ZERO, "WinAbove"))
	for sz in [-1.0, 1.0]:
		var pw := (W - win.x) * 0.5
		hut.add_child(Build.solid_box(Vector3(T, win.y, pw), stone, Vector3(wx, sill + win.y * 0.5, sz * (win.x * 0.5 + pw * 0.5)), Vector3.ZERO, "WinPier"))
	hut.add_child(Build.box(Vector3(T + 0.15, 0.08, win.x + 0.1), wood, Vector3(wx, sill + 0.02, 0), Vector3.ZERO, "Sill"))
	_window = Vector3(wx, sill + win.y * 0.5, 0)
	_inward = Vector3(-ws, 0, 0)
	# the shutter: two old leaves, barred inside; solid until the wheel comes
	shutter = Node3D.new()
	shutter.name = "HutShutter"
	hut.add_child(shutter)
	for sz in [-1.0, 1.0]:
		shutter.add_child(Build.solid_box(Vector3(0.07, win.y, win.x * 0.5 - 0.01), wood, Vector3(wx + ws * 0.04, sill + win.y * 0.5, sz * win.x * 0.25), Vector3.ZERO, "ShutterLeaf"))
	var bar_mat := ToonMat.make(Color(0.22, 0.2, 0.18), 0.012)
	shutter.add_child(Build.box(Vector3(0.05, 0.1, win.x), bar_mat, Vector3(wx + ws * 0.09, sill + win.y * 0.5, 0), Vector3.ZERO, "ShutterBar"))
	# what's left after the wheel: the leaves' stumps on their hinges
	splinters = Node3D.new()
	splinters.name = "ShutterSplinters"
	splinters.visible = false
	hut.add_child(splinters)
	for s in [[-1.0, 0.7, 12.0], [1.0, 0.48, -18.0]]:
		splinters.add_child(Build.box(Vector3(0.05, win.y * float(s[1]), 0.13), wood, Vector3(wx + ws * 0.06, sill + win.y * float(s[1]) * 0.5, float(s[0]) * (win.x * 0.5 - 0.07)), Vector3(float(s[2]), 0, 0), "ShutterStump"))
	# a heap of broken stone at the foot of that wall (spoil from the piers):
	# the wheel hits it at speed and kicks up. Low enough not to be a step.
	_rubble = Vector3(wx + ws * 1.7, 0.15, 1.9)    # off to one side: under the window is where the crate goes
	var rock := ToonMat.make(Color(0.47, 0.45, 0.42), 0.012)
	for r in [[0.0, 0.0, 0.55, 0.28], [0.5, 0.35, 0.34, 0.17], [-0.36, -0.42, 0.40, 0.19], [0.28, -0.6, 0.26, 0.13], [-0.55, 0.44, 0.30, 0.13]]:
		var stone_at := Vector3(_rubble.x + float(r[0]), float(r[3]) * 0.5 - 0.03, _rubble.z + float(r[1]))
		hut.add_child(Build.solid_box(Vector3(float(r[2]) * 1.5, float(r[3]), float(r[2]) * 1.3), rock, stone_at, Vector3(0, float(r[0]) * 90.0, float(r[1]) * 18.0), "Rubble"))
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
	da.set_meta("prompt_fn", func(p) -> String: return "Slide the bolt and open the door" if not door_open and in_hut(p) else "")
	da.set_meta("blocked_fn", func(p) -> String: return "" if door_open or in_hut(p) else "It won't move. Bolted on the inside.")
	hut_door.add_child(da)
	# the ground falls away from the hut's floor: a worn stone ramp up to the
	# door, or nobody gets in with a wheel (the walk found it stuck at the sill)
	var run := 2.4
	var world_xf := transform * hut.transform      # (the world is built outside the tree: no global_* here)
	var door_out := world_xf * Vector3(0, 0, -W * 0.5 - run)
	var rise := world_xf.origin.y - Landscape.ground(door_out.x, door_out.z)
	if rise > 0.05:
		var ang := atan2(rise, run)
		var slab := sqrt(rise * rise + run * run)
		hut.add_child(Build.solid_box(Vector3(1.5, 0.14, slab + 0.3), stone, Vector3(0, -rise * 0.5 - 0.07, -W * 0.5 - run * 0.5), Vector3(-rad_to_deg(ang), 0, 0), "DoorRamp"))
	print("[ramp] the hut's floor is %.2f m above the ground at the door" % rise)
	# a lamp left burning inside
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(ws * 0.6, 2.4, 0.6)
	lamp.omni_range = 5.0
	lamp.light_color = Color(1.0, 0.8, 0.5)
	lamp.light_energy = 1.6
	hut.add_child(lamp)
	hut.add_child(Build.sphere(0.1, ToonMat.make(Color(1.0, 0.85, 0.5), 0.0, 0.9, Color(1.0, 0.7, 0.3) * 2.0), lamp.position, Vector3.ONE, "LampGlass"))
	# inside: the keeper's workbench against the back wall, the toolbox on it
	var bench := Node3D.new()
	bench.name = "HutBench"
	bench.position = Vector3(0, 0, W * 0.5 - 0.5)
	hut.add_child(bench)
	bench.add_child(Build.solid_box(Vector3(2.0, 0.08, 0.6), wood, Vector3(0, 0.82, 0), Vector3.ZERO, "BenchTop"))
	for s in [-0.9, 0.9]:
		bench.add_child(Build.solid_box(Vector3(0.1, 0.8, 0.5), wood, Vector3(s, 0.4, 0), Vector3.ZERO, "BenchLeg"))
	var box := ToonMat.make(Color(0.68, 0.17, 0.13), 0.012)
	bench.add_child(Build.box(Vector3(0.62, 0.25, 0.28), box, Vector3(-0.35, 0.985, 0), Vector3(0, 8, 0), "Toolbox"))
	bench.add_child(Build.box(Vector3(0.26, 0.04, 0.05), ToonMat.make(Color(0.15, 0.15, 0.16)), Vector3(-0.35, 1.13, 0), Vector3(0, 8, 0), "ToolboxHandle"))
	var ta := Build.interact_area(Vector3(0.9, 0.6, 0.8), Vector3(-0.35, 1.0, -0.15), "", func(p): _open_box(p), "ToolboxArea")
	ta.set_meta("tag_name", "the toolbox")
	ta.set_meta("prompt_fn", func(p) -> String: return "Open the toolbox" if not box_open and in_hut(p) else "")
	bench.add_child(ta)
	# something of Naresh's: his tiffin on the bench. Two spoons (his friend).
	var tin := ToonMat.make(Color(0.73, 0.74, 0.72), 0.012)
	bench.add_child(Build.cyl(0.1, 0.22, tin, Vector3(0.45, 0.97, 0.03), Vector3.ZERO, 12, "Tiffin"))
	bench.add_child(Build.cyl(0.103, 0.02, tin, Vector3(0.45, 1.05, 0.03), Vector3.ZERO, 12, "TiffinClip"))
	var tf := Build.interact_area(Vector3(0.5, 0.6, 0.6), Vector3(0.45, 1.0, -0.1), "Look at the tiffin", func(p):
		p.say("Naresh's tiffin. N scratched in the lid. Two spoons inside: one used, one still in its paper.", 6.0), "TiffinArea")
	tf.set_meta("tag_name", "Naresh's tiffin")
	bench.add_child(tf)
	NareshNote.make(hut, "rj_hut", Vector3(0.75, 1.45, W * 0.5 - T * 0.5 - 0.02), 180.0,
		"Left the good nuts in the red box, and a can and a jug for whoever comes after. Your wheel's your own problem. Bolt the door when you go, he says. Who's he going to keep out?")
	# the crate outside, a few steps from the window's wall (to stand on), and
	# boot scuffs up the wall: someone's climbed in before
	var scuff := ToonMat.flat(Color(0.25, 0.22, 0.19))
	for k in 5:
		hut.add_child(Build.box(Vector3(0.02, 0.07, 0.22), scuff, Vector3(wx + ws * (T * 0.5 + 0.01), 1.3 + k * 0.2, randf_range(-0.25, 0.25)), Vector3(randf_range(-15, 15), 0, 0), "Scuff"))
	var crate := Crate.new()
	crate.name = "HutCrate"
	crate.position = Vector3(ws * (W * 0.5 + 2.2), 0.05, -1.5)
	hut.add_child(crate)
	var legup_note := Vector3(wx + ws * (T * 0.5 + 0.03), 1.55, 1.05)
	NareshNote.make(hut, "rj_legup", legup_note, 90.0 * ws,
		"Too high for one. My friend crouched by the crate (C) and I went up off his back (jump). He weighs nothing.")


# --- running -------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	_watch_water()
	_near_time(delta)
	var boot := get_tree().current_scene
	var van: Camper = boot.get("camper") if boot != null else null
	if van == null or failing or van.freeze:
		return
	var l := global_transform.affine_inverse() * van.global_position
	if absf(l.x) > 40.0 or absf(l.z + gap_len * 0.5) > 45.0:
		_launched = false
		return
	var touching := false
	for w in van._wheels:
		if w.is_in_contact():
			touching = true
			break
	# the engine boiling (the water works skipped): it can't do this and it
	# mustn't: the coolant's on this side
	if not jumped and l.z > 0.0 and l.z < RAMP_LEN and absf(l.x) < RAMP_W * 0.5 and _too_early(van):
		_fail("boil")
		return
	if not jumped:
		if not _launched and not touching and l.z < -0.5:
			_launched = true
			last_lip_kmh = van.linear_velocity.length() * 3.6
			print("[ramp] off the lip at %.1f km/h, %.2f m off the middle" % [last_lip_kmh, l.x])
		if _launched and touching and l.z < -gap_len - 0.8 and absf(l.x) < deck_w * 0.5 + 1.0:
			_land(van)
			return
	# in the water, or hung up in the gap
	var in_river := Landscape.river_distance(van.global_position.x, van.global_position.z) < Landscape.RIVER_HALF + 1.0
	if in_river and l.y < -1.3 and l.z < RAMP_LEN + 8.0:
		_fail("shallows")
		return
	# (the rear wheels hanging off the far edge counts: a van that only just
	# made it, its back end down the hole, gets hauled out on the far side)
	if l.z < 0.0 and l.z > -gap_len - 2.2 and absf(l.x) < deck_w * 0.5 and van.linear_velocity.length() < 0.5:
		_stuck_t += delta
		if _stuck_t > 2.0:
			_fail("hung")
			return
	else:
		_stuck_t = 0.0


func _too_early(van: Camper) -> bool:
	var st = get_tree().current_scene.get("story")
	if van.coolant_leak:
		return true
	return st != null and st.index < st.index_of("to_bridge")


## It made it. The bang, the wheel, the cargo.
func _land(van: Camper) -> void:
	jumped = true
	_launched = false
	var st = get_tree().current_scene.get("story")
	if st != null:
		st.flags["ramp_jumped"] = true
	var vy := van.linear_velocity.y
	var kmh := van.linear_velocity.length() * 3.6
	print("[ramp] landed at %.1f km/h, %.1f m/s down, %.2f m past the far edge" % [kmh, -vy, -(global_transform.affine_inverse() * van.global_position).z - gap_len])
	var hub := van._wheels[0].global_position
	van.snap_wheel()
	Sfx.play3d("bang", van.global_position, 8.0)
	Sfx.play3d("hit_metal_heavy", hub, 8.0)
	Sfx.play3d("crack", hub, 4.0)
	_fling_cargo(van)
	_send_wheel(hub, van.linear_velocity)
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null:
			p._shake_t = 0.4
			p.say("BANG! The front-left wheel's nuts snap. Your wheel goes bouncing off down the road...", 5.0)
		else:
			p.say("The van's over, with a bang and without a wheel. No other way across for you now: swim for it.", 6.0)


## S4: everything stowed on the rack comes off and flies on: real cargo, you
## go and pick it up. Forward with the van, so it lands on the road.
func _fling_cargo(van: Camper) -> void:
	var fwd := -global_transform.basis.z
	var side := global_transform.basis.x
	for slot in van.storage_slots:
		var it := van.stowed_item(slot)
		if it == null:
			continue
		it.unstow()
		it.global_position = slot.global_position + Vector3.UP * 0.4
		it.linear_velocity = fwd * randf_range(4.0, 8.0) + Vector3.UP * randf_range(3.0, 5.0) + side * randf_range(-1.8, 1.8)
		it.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		it._thrown = true


## The wheel's flight: it isn't left to the physics (a loose wheel rarely goes
## through a metre-wide window), but it follows real bounces at real speeds:
## down the road, into the heap, up and through the shutter, onto the floor.
func _send_wheel(from: Vector3, vel: Vector3) -> void:
	_flying = Node3D.new()
	_flying.name = "FlyingWheel"
	var tyre := ToonMat.make(Color(0.13, 0.13, 0.15), 0.02, 0.98)
	_flying.add_child(Build.cyl(0.44, 0.26, tyre, Vector3.ZERO, Vector3(90, 0, 0), 16, "Tyre"))
	_flying.add_child(Build.cyl(0.20, 0.28, ToonMat.make(Color(0.82, 0.80, 0.74), 0.015, 0.5), Vector3.ZERO, Vector3(90, 0, 0), 12, "Hub"))
	get_tree().current_scene.get("world").add_child(_flying)
	_flying.global_position = from
	var kick := hut.global_transform * _rubble + Vector3.UP * 0.35
	var through := hut.global_transform * _window
	var floor_at := hut.global_transform * (_window + _inward * 1.3)
	floor_at.y = hut.global_position.y + 0.45
	var flat := kick - from
	flat.y = 0.0
	# two road bounces on the way to the heap, then the kick up
	var dist := flat.length()
	var speed := clampf(Vector2(vel.x, vel.z).length() * 0.8, 9.0, 14.0)
	var g1 := from.lerp(kick, 0.42)
	g1.y = kick.y
	var hops: Array = [[from, g1, 1.0, Sfx], [g1, kick, 0.75, Sfx]]
	var tw := create_tween()
	for h in hops:
		var a: Vector3 = h[0]
		var b: Vector3 = h[1]
		var t := maxf(0.2, a.distance_to(b) / speed)
		var height: float = h[2]
		tw.tween_method(func(u: float): _wheel_at(a, b, height, u), 0.0, 1.0, t)
		tw.tween_callback(func(): Sfx.play3d("hit_metal_heavy", b, 2.0, 0.1, 0.7))
	tw.tween_method(func(u: float): _wheel_at(kick, through, 0.5, u), 0.0, 1.0, maxf(0.34, kick.distance_to(through) / speed))
	tw.tween_callback(func():
		break_shutter(true))
	tw.tween_method(func(u: float): _wheel_at(through, floor_at, 0.1, u), 0.0, 1.0, 0.32)
	tw.tween_callback(func():
		Sfx.play3d("hit_metal_heavy", floor_at, 2.0, 0.1, 0.6)
		_flying.queue_free()
		_flying = null
		put_wheel_in_hut()
		_tell_near("...and straight through the shutter of the hut. You hear it land inside.", 5.0))
	print("[ramp] the wheel goes %.1f m to the heap at %.1f m/s" % [dist, speed])


func _wheel_at(a: Vector3, b: Vector3, height: float, u: float) -> void:
	if _flying == null:
		return
	var p := a.lerp(b, u)
	p.y += 4.0 * height * u * (1.0 - u)
	_flying.global_position = p
	_flying.rotate_object_local(Vector3(0, 0, 1), 0.5)


## The shutter gone, in the frames of its hinges. `loud`: it just happened.
func break_shutter(loud: bool) -> void:
	shutter_broken = true
	if shutter != null:
		shutter.visible = false
		for c in shutter.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", true)
	if splinters != null:
		splinters.visible = true
	if loud:
		Sfx.play3d("crack", hut.global_transform * _window, 8.0)
		print("[ramp] the wheel goes through the shutter")


func put_wheel_in_hut() -> void:
	if van_wheel != null and is_instance_valid(van_wheel):
		van_wheel.queue_free()
	van_wheel = SpareWheel.make_van_wheel()
	van_wheel.name = "VanWheel"
	get_tree().current_scene.get("world").add_child(van_wheel)
	# leaning on the wall, down on the floor
	var at := hut.global_transform * (_window + _inward * 1.3)
	at.y = hut.global_position.y + 0.45
	van_wheel.global_position = at
	van_wheel.reset_physics_interpolation()


func _open_door(p) -> void:
	if door_open or not in_hut(p):
		return
	door_open = true
	Sfx.play3d("door_open", hut_door.global_position + Vector3.UP, 0.0)
	var tw := create_tween()
	tw.tween_property(hut_door, "rotation:y", deg_to_rad(-100.0), 0.8).set_ease(Tween.EASE_OUT)


func _open_box(p) -> void:
	if box_open or not in_hut(p):
		return
	box_open = true
	Sfx.play3d("door_open", hut.global_position + Vector3.UP, -4.0, 0.1, 1.3)
	var van: Camper = get_tree().current_scene.get("camper")
	if van != null:
		van.nuts_found = true
	_spawn_reward()
	p.say("A box of new wheel nuts: pocketed. Under the bench, a can of fuel and a jug of coolant.", 5.0)


func _spawn_reward() -> void:
	var bench := hut.get_node("HutBench") as Node3D
	var items: Array[Carryable] = [FuelCan.new(), CoolantJug.new()]
	var k := 0
	for it in items:
		it.name = "HutReward%d" % k
		get_tree().current_scene.get("world").add_child(it)
		it.global_position = bench.global_transform * Vector3(-0.5 + k * 0.7, 0.3, -0.6)
		k += 1


func in_hut(p) -> bool:
	if hut == null:
		return false
	var l := hut.global_transform.affine_inverse() * (p as Node3D).global_position
	return absf(l.x) < 1.6 and absf(l.z) < 1.6 and l.y > -0.5 and l.y < 2.5


## Into the river: a player swims out on the side the van is on (the one the
## van left behind swims across to it).
func _watch_water() -> void:
	if water_y < -1e8:
		return
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.seat != null or p.swimming:
			continue
		var at := p.global_position
		if at.y < water_y - 0.15 and at.distance_to(global_transform * Vector3(0, 0, -gap_len * 0.5)) < 45.0 and Landscape.river_distance(at.x, at.z) < Landscape.RIVER_HALF + 1.0:
			print("[ramp] P%d in the river at %s" % [p.index + 1, at])
			p.fall_in_water(water_y, far_bank if jumped else near_bank)


func _near_time(delta: float) -> void:
	if jumped:
		return
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_position) < HINT_NEAR + 60.0:
			near_t += delta
			return


## Hold H by the ramp: what to try, clearer the longer you're stuck.
func hint_for(i: int) -> String:
	if jumped or i < 0:
		return ""
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.index == i and q.global_position.distance_to(global_position) < HINT_NEAR + 60.0:
			var text := ""
			for h in HINTS:
				if near_t >= float(h[0]):
					text = String(h[1])
			return text
	return ""


## A miss: a fade, some swearing and a tow, then back at the run-up, the van
## pointing at the ramp, whoever was aboard still aboard.
func _fail(why: String) -> void:
	if failing:
		return
	failing = true
	if why != "boil":
		misses += 1
	print("[ramp] fail: %s (the lip at %.1f km/h)" % [why, last_lip_kmh])
	var text := "Short! The van's nose goes into the shallows and the river comes in through the doors."
	if why == "hung":
		text = "The van hangs off the far edge by its belly, then slides back into the shallows."
	elif why == "boil":
		text = "The engine's boiling. It chokes halfway up the ramp and the van rolls off the side. Sort the coolant first."
	var back_far := jumped
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
	_launched = false
	_stuck_t = 0.0
	if van != null:
		var to := far_start if back_far else van_start
		van.linear_velocity = Vector3.ZERO
		van.angular_velocity = Vector3.ZERO
		van.global_transform = to
		van.reset_physics_interpolation()
		# on the handbrake: the road runs downhill to the ramp, and a van left
		# to roll used up its own run-up (it then only made 57 km/h: the walk)
		van.parking_brake = true
		var k := 0
		for n in players:
			var p := n as PlayerRig
			if p.seat == null:
				# (out of the river too: a swimmer put beside the van stayed in
				# swimming mode)
				p.swimming = false
				p.global_position = to * Vector3(-3.2, 0.3, -1.0 + k * 1.6)
				p.velocity = Vector3.ZERO
				p.reset_physics_interpolation()
			k += 1
	await get_tree().create_timer(0.6).timeout
	var line := "A long, wet hour and a tow rope later, the van's back on the road, handbrake on. Try it faster." if not back_far else "A long, wet hour and a tow rope later, the van's back on the road."
	if why == "boil":
		line = "You let it roll back down the road and cool. It still needs that coolant."
	for n in players:
		var p := n as PlayerRig
		var tw := p.create_tween()
		tw.tween_property(p, "whiteout", 0.0, 1.0)
		p.say(line, 4.0)
	failing = false


func _tell_near(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(global_position) < 140.0:
			q.say(text, secs)


# --- jumps and saving ------------------------------------------------------------

## F1 (Puzzles, or a story jump here or before): everything fresh.
func reset() -> void:
	near_t = 0.0
	failing = false
	misses = 0
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).whiteout = 0.0
	if is_inside_tree():
		var world: Node = get_tree().current_scene.get("world")
		for k in 2:
			var it := world.find_child("HutReward%d" % k, true, false)
			if it != null:
				it.queue_free()
	from_dict({})


## A story jump past the jump: over, the wheel back on. The hut as if you'd
## been through it.
func solve_quietly() -> void:
	jumped = true
	door_open = true
	if hut_door != null:
		hut_door.rotation.y = deg_to_rad(-100.0)
	break_shutter(false)
	if van_wheel != null and is_instance_valid(van_wheel):
		van_wheel.queue_free()
		van_wheel = null


## A story jump to the "wheel" step: just landed, the wheel in the hut.
func just_landed() -> void:
	reset()
	jumped = true
	break_shutter(false)
	put_wheel_in_hut()


func to_dict() -> Dictionary:
	return {"jumped": jumped, "shutter_broken": shutter_broken, "door_open": door_open, "box_open": box_open}


func from_dict(d: Dictionary) -> void:
	jumped = bool(d.get("jumped", false))
	shutter_broken = bool(d.get("shutter_broken", false))
	door_open = bool(d.get("door_open", false))
	box_open = bool(d.get("box_open", false))
	_launched = false
	_stuck_t = 0.0
	if hut_door != null:
		hut_door.rotation.y = deg_to_rad(-100.0) if door_open else 0.0
	if shutter != null:
		shutter.visible = not shutter_broken
		for c in shutter.find_children("*", "CollisionShape3D", true, false):
			(c as CollisionShape3D).set_deferred("disabled", shutter_broken)
	if splinters != null:
		splinters.visible = shutter_broken
	if not shutter_broken and van_wheel != null and is_instance_valid(van_wheel):
		van_wheel.queue_free()
		van_wheel = null
