class_name Bessi
extends Node

## E2, Bessi beach (design/BESSI.md, 24:00 "Arrival"): an empty promenade at
## dusk. The stall lights are on and nobody is there; a radio plays softly in
## one stall; the lamps glow; the lighthouse on the rocks at the north end
## turns its beam. As the van comes into Bessi the nav loses its signal (the
## screen flickers "NO SIGNAL"). The mood falls to dusk at the beach
## (Mood.WAY_OUT "beach").
##
## The layout is set for E3's photo (W8): from PHOTO_SPOT on the promenade the
## memorial's spire stands 130 m ahead with the lighthouse 200 m beyond it,
## its lamp just over the spire's tip (the tower's height is worked out so).

const SIGNAL_R := 420.0                      ## m from the roses: no nav signal inside this
const PHOTO_SPOT := Vector2(1871, 620)       ## E3: where the photo was taken (on the promenade)
const LIGHTHOUSE := Vector2(1905, 290)       ## on the rocks, just off the north end of the beach
const MEMORIAL_AHEAD := 129.0                ## m from the photo spot to the memorial, on the line
const PROM_FROM := 315.0                     ## the promenade runs from here...
const PROM_TO := 975.0                       ## ...to here (z), along the stalls
const PROM_IN := 56.0                        ## m inland of the waterline: its landward edge
const PROM_OUT := 44.0                       ## and its seaward edge
const BEAM_TURN := 8.0                       ## s for one turn of the lighthouse beam
const STALL_Z := [330, 960, 45]              ## LevelPlaces._beach: range(330, 960, 45)
const RADIO_STALL := 4                       ## the stall with the radio (z 510, near the memorial)

var beam: Node3D
var radio: AudioStreamPlayer3D
var signal_lost := false
var lights: Array[Light3D] = []
var _roses := Vector3(1720, 0, 640)


func setup(b) -> void:
	add_to_group("bessi")
	_roses = b.ROSE_CENTRE
	var root := Node3D.new()
	root.name = "BessiArrival"
	b.world.add_child(root)
	_promenade(b, root)
	_stall_lights(b, root)
	var m := _memorial(b, root)
	_lighthouse(b, root, m)


## A waterline point: where the sand meets the sea at `z`.
static func shore_x(z: float) -> float:
	return Landscape.coast_inland(0.0, z)


func _physics_process(delta: float) -> void:
	if beam != null:
		beam.rotate_y(delta * TAU / BEAM_TURN)
	var van := get_tree().get_first_node_in_group("camper") as Camper
	if van != null:
		var c := _roses
		signal_lost = Vector2(van.global_position.x - c.x, van.global_position.z - c.z).length() < SIGNAL_R
		van.nav_signal_lost = signal_lost


# --- the promenade -----------------------------------------------------------------

## Paving slabs 10 m long along the stalls, each laid on the sand (tilted to
## it), so you walk on and off it anywhere without a step.
func _promenade(b, root: Node3D) -> void:
	var body := StaticBody3D.new()
	body.name = "Promenade"
	root.add_child(body)
	var paving := ToonMat.make(Color(0.78, 0.74, 0.66), 0.02)
	var kerb := ToonMat.make(Color(0.62, 0.60, 0.56), 0.02)
	var z := PROM_FROM
	var k := 0
	while z < PROM_TO:
		var z1 := minf(z + 10.0, PROM_TO)
		var a := _prom_point(b, z, PROM_IN)
		var c := _prom_point(b, z, PROM_OUT)
		var a1 := _prom_point(b, z1, PROM_IN)
		var c1 := _prom_point(b, z1, PROM_OUT)
		var mid := (a + c + a1 + c1) * 0.25
		var across := ((c - a) + (c1 - a1)) * 0.5
		var along := ((a1 - a) + (c1 - c)) * 0.5
		var up := along.cross(across).normalized()
		if up.y < 0.0:
			up = -up
		var basis := Basis(across.normalized(), up, along.normalized())
		basis = basis.orthonormalized()
		var size := Vector3(across.length(), 0.5, along.length() + 0.05)
		var xf := Transform3D(basis, mid + up * (0.08 - 0.25))
		var slab := Build.box(size, paving if k % 2 == 0 else kerb, Vector3.ZERO, Vector3.ZERO, "Slab%d" % k)
		slab.transform = xf
		body.add_child(slab)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		cs.transform = xf
		body.add_child(cs)
		z = z1
		k += 1
	b.poi["promenade_north"] = _prom_point(b, PROM_FROM + 20.0, (PROM_IN + PROM_OUT) * 0.5) + Vector3.UP * 0.1
	b.poi["promenade_south"] = _prom_point(b, PROM_TO - 20.0, (PROM_IN + PROM_OUT) * 0.5) + Vector3.UP * 0.1


func _prom_point(b, z: float, inland: float) -> Vector3:
	var x := shore_x(z) - inland
	return Vector3(x, b._h(x, z), z)


# --- lights and the radio -----------------------------------------------------------

## A warm light under each stall's awning (they're lit and nobody is there),
## and at every lamp post. They fade out with distance, so far off they cost
## nothing.
func _stall_lights(b, root: Node3D) -> void:
	var k := 0
	for z in range(STALL_Z[0], STALL_Z[1], STALL_Z[2]):
		var shore := shore_x(float(z))
		var sp := Vector3(shore - 58.0, 0, float(z))
		sp.y = b._h(sp.x, sp.z)
		var l := _light(Color(1.0, 0.78, 0.48), 1.6, 7.0)
		l.position = sp + Vector3(1.9, 2.2, 0)
		root.add_child(l)
		lights.append(l)
		var lamp := _light(Color(1.0, 0.86, 0.6), 1.2, 9.0)
		lamp.position = sp + Vector3(0, 4.3, 22.0)
		root.add_child(lamp)
		lights.append(lamp)
		if k == RADIO_STALL:
			radio = AudioStreamPlayer3D.new()
			radio.name = "Radio"
			var st := load("res://audio/radio_tune.wav") as AudioStreamWAV
			if st != null:
				st = st.duplicate() as AudioStreamWAV
				st.loop_mode = AudioStreamWAV.LOOP_FORWARD
				st.loop_begin = 0
				st.loop_end = int(st.get_length() * st.mix_rate)
				radio.stream = st
			radio.volume_db = -10.0
			radio.unit_size = 3.0
			radio.max_distance = 45.0
			radio.autoplay = true
			radio.position = sp + Vector3(1.4, 1.1, 0)
			root.add_child(radio)
			# the radio itself, on the counter
			root.add_child(Build.box(Vector3(0.36, 0.22, 0.14), ToonMat.make(Color(0.55, 0.22, 0.18)), sp + Vector3(1.55, 1.05, 0.3), Vector3(0, 70, 0), "RadioSet"))
			root.add_child(Build.box(Vector3(0.6, 0.08, 2.0), ToonMat.make(b.C_WOOD), sp + Vector3(1.55, 0.9, 0), Vector3.ZERO, "Counter"))
			b.poi["radio_stall"] = sp + Vector3(3.5, 0, 0)
		k += 1


func _light(col: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.3
	l.shadow_enabled = false
	l.distance_fade_enabled = true
	l.distance_fade_begin = 140.0
	l.distance_fade_length = 40.0
	return l


# --- the memorial and the lighthouse -------------------------------------------------

## The memorial: a stone column with a pointed spire, on a stepped base on
## the sand, 129 m from the photo spot along the line to the lighthouse.
## Returns the spire's tip.
func _memorial(b, root: Node3D) -> Vector3:
	var s := _v(b, PHOTO_SPOT)
	var l := _v(b, LIGHTHOUSE)
	var dir := Vector2(l.x - s.x, l.z - s.z).normalized()
	var at2 := PHOTO_SPOT + dir * MEMORIAL_AHEAD
	var mp := _v(b, at2)
	var stone := ToonMat.make(b.C_STONE)
	var pale := ToonMat.make((b.C_STONE as Color).lightened(0.12))
	var body := StaticBody3D.new()
	body.name = "Memorial"
	root.add_child(body)
	for spec in [[Vector3(7, 0.4, 7), 0.2], [Vector3(5, 0.4, 5), 0.6]]:
		body.add_child(Build.box(spec[0], stone, mp + Vector3(0, spec[1], 0), Vector3.ZERO, "Step"))
		body.add_child(b._box_shape(spec[0], Transform3D(Basis(), mp + Vector3(0, spec[1], 0))))
	body.add_child(Build.box(Vector3(1.4, 8.0, 1.4), pale, mp + Vector3(0, 4.8, 0), Vector3.ZERO, "Column"))
	body.add_child(b._box_shape(Vector3(1.4, 8.0, 1.4), Transform3D(Basis(), mp + Vector3(0, 4.8, 0))))
	body.add_child(Build.cone(1.0, 2.6, pale, mp + Vector3(0, 10.1, 0), Vector3(0, 45, 0), 4, "Spire"))
	var tip := mp + Vector3(0, 11.4, 0)
	b.poi["memorial"] = mp
	b.poi["memorial_spire"] = tip
	b.poi["photo_spot"] = s + Vector3.UP * 0.1
	return tip


## The lighthouse, on a rock just off the beach's north end: white with red
## bands, a gallery and a glass lantern whose beam turns. Tall enough that
## from the photo spot its lamp shows just above the memorial's spire.
func _lighthouse(b, root: Node3D, tip: Vector3) -> void:
	var at := _v(b, LIGHTHOUSE)
	var eye := _v(b, PHOTO_SPOT) + Vector3.UP * (PlayerRig.STAND_HEIGHT - 0.16)
	var d_tip := Vector2(tip.x - eye.x, tip.z - eye.z).length()
	var d_lh := Vector2(at.x - eye.x, at.z - eye.z).length()
	var lamp_y := eye.y + (tip.y - eye.y) * d_lh / d_tip + d_lh * tan(deg_to_rad(0.35))
	var rock_top := Landscape.SEA_Y + 2.5
	var tower_h := lamp_y - rock_top - 1.2
	var node := Node3D.new()
	node.name = "Lighthouse"
	node.position = Vector3(at.x, rock_top, at.z)
	root.add_child(node)
	var body := StaticBody3D.new()
	body.name = "LighthouseRock"
	node.add_child(body)
	var rock := ToonMat.make(Color(0.36, 0.34, 0.33), 0.03)
	var ground := minf(at.y, rock_top - 1.0)
	var rh := rock_top - ground + 1.0
	body.add_child(Build.cyl(9.0, rh, rock, Vector3(0, -rh * 0.5, 0), Vector3.ZERO, 12, "Rock"))
	body.add_child(Build.cyl(6.0, rh * 0.6, rock, Vector3(3.5, -rh * 0.35, 4.0), Vector3(0, 30, 0), 9, "Rock2"))
	body.add_child(b._cyl_shape(Vector3(0, -rh * 0.5, 0), 9.0, rh))
	var white := ToonMat.make(Color(0.95, 0.94, 0.90), 0.02)
	var red := ToonMat.make(Color(0.78, 0.16, 0.14), 0.02)
	var tower := CylinderMesh.new()
	tower.top_radius = 1.7
	tower.bottom_radius = 2.6
	tower.height = tower_h
	tower.radial_segments = 16
	body.add_child(Build.node(tower, white, Transform3D(Basis(), Vector3(0, tower_h * 0.5, 0)), "Tower"))
	body.add_child(b._cyl_shape(Vector3(0, tower_h * 0.5, 0), 2.2, tower_h))
	for f in [0.3, 0.62]:
		var band := CylinderMesh.new()
		var r := lerpf(2.6, 1.7, f) + 0.04
		band.top_radius = r - 0.12
		band.bottom_radius = r
		band.height = tower_h * 0.1
		band.radial_segments = 16
		body.add_child(Build.node(band, red, Transform3D(Basis(), Vector3(0, tower_h * f, 0)), "Band"))
	body.add_child(Build.cyl(2.4, 0.25, ToonMat.make(b.C_STEEL), Vector3(0, tower_h, 0), Vector3.ZERO, 16, "Gallery"))
	var glass := ToonMat.make(Color(1.0, 0.92, 0.7), 0.0, 0.5, Color(1.0, 0.85, 0.5))
	body.add_child(Build.cyl(1.2, 2.0, glass, Vector3(0, tower_h + 1.2, 0), Vector3.ZERO, 12, "Lantern"))
	body.add_child(Build.cone(1.5, 1.4, red, Vector3(0, tower_h + 2.9, 0), Vector3.ZERO, 12, "Roof"))
	var lamp := _light(Color(1.0, 0.9, 0.7), 3.0, 40.0)
	lamp.distance_fade_enabled = false
	lamp.position = Vector3(0, tower_h + 1.2, 0)
	node.add_child(lamp)
	lights.append(lamp)
	# the beam: two long soft cones, back to back, turning
	beam = Node3D.new()
	beam.name = "Beam"
	beam.position = Vector3(0, tower_h + 1.2, 0)
	node.add_child(beam)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.9, 0.65, 0.035)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true             # fog greyed it into a solid cone
	for s in [-1.0, 1.0]:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.2
		cone.bottom_radius = 7.0
		cone.height = 90.0
		cone.radial_segments = 10
		cone.cap_top = false
		cone.cap_bottom = false
		var m := Build.node(cone, mat, Transform3D(Basis(Vector3.RIGHT, s * PI * 0.5), Vector3(0, 0, -s * 45.0)), "BeamCone")
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		beam.add_child(m)
	b.poi["lighthouse"] = Vector3(at.x, rock_top, at.z)
	b.poi["lighthouse_lamp"] = Vector3(at.x, rock_top + tower_h + 1.2, at.z)


func _v(b, p: Vector2) -> Vector3:
	return Vector3(p.x, b._h(p.x, p.y), p.y)
