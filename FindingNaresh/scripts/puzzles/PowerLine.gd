class_name PowerLine
extends Node3D

## D8, the power link (design/WAY_OUT.md): the pumps at Last Fuel are dead
## because "power's been off since the turbine stopped". When the blue tank
## at the water works fills (CoolingStation solved), the old turbine by the
## intake starts turning and lamps come on one after another along the poles
## beside Pump House Road, north to the bridge's control hut. The hut is then
## powered, which the lift bridge (D9) needs.

const POLE_H := 7.0
const WAVE := 0.6                ## s between one lamp and the next lighting
const TURBINE_SPIN := 4.0        ## rad/s once running
const C_POLE := Color(0.40, 0.30, 0.22)
const C_LAMP_OFF := Color(0.42, 0.42, 0.38)
const C_LAMP_ON := Color(1.0, 0.86, 0.52)

var powered := false             ## the turbine is running
var hut_powered := false         ## the wave of lamps has reached the hut
var lamps: Array[MeshInstance3D] = []
var halos: Array[MeshInstance3D] = []   ## a soft glow round each lit lamp (seen by day)
var wheel: Node3D
var hut_lamp: MeshInstance3D
var hut_light: OmniLight3D
var _station: CoolingStation
var _lit := 0
var _t := 0.0
var _spin := 0.0
var _hum: NoiseLoop
var _mat_off: StandardMaterial3D
var _mat_on: StandardMaterial3D


## `turbine` is the turbine house (its -Z faces the river), `feet` the pole
## feet from the turbine to the hut (ground heights), `hut_lamp_at` the lamp
## inside the hut.
func setup(station: CoolingStation, turbine: Transform3D, feet: Array[Vector3], road_side: Array[Vector3], hut_lamp_at: Vector3) -> void:
	add_to_group("power_line")
	_station = station
	_mat_off = ToonMat.make(C_LAMP_OFF, 0.0)
	_mat_on = ToonMat.make(C_LAMP_ON, 0.0, 0.5, C_LAMP_ON)
	_build_turbine(turbine)
	var tops: Array[Vector3] = []
	var wood := ToonMat.make(C_POLE, 0.01)
	for k in feet.size():
		var foot := feet[k]
		var side := road_side[k]       # flat unit vector from the pole towards the road
		var pole := Node3D.new()
		pole.name = "Pole%d" % k
		pole.position = foot
		pole.basis = Basis.looking_at(side, Vector3.UP)     # -Z towards the road
		add_child(pole)
		pole.add_child(Build.cyl(0.13, POLE_H, wood, Vector3(0, POLE_H * 0.5, 0), Vector3.ZERO, 6, "Post"))
		pole.add_child(Build.box(Vector3(1.6, 0.12, 0.12), wood, Vector3(0, POLE_H - 0.4, 0), Vector3.ZERO, "CrossArm"))
		pole.add_child(Build.box(Vector3(0.08, 0.08, 1.3), wood, Vector3(0, POLE_H - 1.3, -0.6), Vector3.ZERO, "LampArm"))
		pole.add_child(Build.cyl(0.36, 0.08, wood, Vector3(0, POLE_H - 1.38, -1.2), Vector3.ZERO, 8, "LampShade"))
		var lamp := Build.sphere(0.28, _mat_off, Vector3(0, POLE_H - 1.6, -1.2), Vector3(1, 0.75, 1), "Lamp")
		pole.add_child(lamp)
		lamps.append(lamp)
		var halo := Build.sphere(1.1, ToonMat.glow(C_LAMP_ON, 0.16), lamp.position, Vector3.ONE, "Halo")
		halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		halo.visible = false
		pole.add_child(halo)
		halos.append(halo)
		tops.append(pole.transform * Vector3(0, POLE_H - 0.3, 0))
	var wire := ToonMat.make(Color(0.12, 0.12, 0.12), 0.0)
	for k in tops.size() - 1:
		var a := tops[k]
		var b := tops[k + 1]
		var mid := (a + b) * 0.5 + Vector3.DOWN * clampf(a.distance_to(b) * 0.012, 0.1, 0.6)
		_wire(a, mid, wire)
		_wire(mid, b, wire)
	hut_lamp = Build.sphere(0.16, _mat_off, hut_lamp_at, Vector3.ONE, "HutLamp")
	add_child(hut_lamp)
	hut_light = OmniLight3D.new()
	hut_light.name = "HutLight"
	hut_light.position = hut_lamp_at + Vector3.DOWN * 0.25
	hut_light.omni_range = 6.0
	hut_light.light_energy = 1.4
	hut_light.light_color = C_LAMP_ON
	hut_light.visible = false
	add_child(hut_light)
	_hum = NoiseLoop.new()
	_hum.name = "HutHum"
	_hum.kind = NoiseLoop.Kind.HUM
	_hum.volume_db = -18.0
	_hum.position = hut_lamp_at
	add_child(_hum)
	station.solved_changed.connect(func():
		if station.solved:
			power_on())


func _wire(a: Vector3, b: Vector3, mat: Material) -> void:
	var w := Build.cyl(0.025, a.distance_to(b), mat, (a + b) * 0.5, Vector3.ZERO, 4, "Wire")
	var up := (b - a).normalized()
	var side := up.cross(Vector3.UP if absf(up.y) < 0.99 else Vector3.RIGHT).normalized()
	w.basis = Basis(side, up, side.cross(up))
	add_child(w)


func _build_turbine(xf: Transform3D) -> void:
	var house := Node3D.new()
	house.name = "Turbine"
	house.transform = xf
	add_child(house)
	var concrete := ToonMat.make(Color(0.62, 0.62, 0.60))
	house.add_child(Build.solid_box(Vector3(3.0, 2.6, 3.0), concrete, Vector3(0, 1.3, 0), Vector3.ZERO, "TurbineHouse"))
	house.add_child(Build.box(Vector3(3.3, 0.2, 3.3), ToonMat.make(Color(0.36, 0.38, 0.42)), Vector3(0, 2.7, 0), Vector3.ZERO, "TurbineRoof"))
	house.add_child(Build.label3d("TURBINE No.1", Vector3(0, 2.7, 1.72), Vector3.ZERO, 0.16, Color(0.2, 0.2, 0.25)))
	# a big flywheel on the yard side, face-on to anyone coming down the pipes,
	# so you can see it turn
	wheel = Node3D.new()
	wheel.name = "Wheel"
	wheel.position = Vector3(0, 1.4, 1.75)
	house.add_child(wheel)
	var steel := ToonMat.make(Color(0.34, 0.40, 0.44), 0.012)
	var red := ToonMat.make(Color(0.72, 0.24, 0.20), 0.012)
	wheel.add_child(Build.cyl(0.22, 0.4, steel, Vector3.ZERO, Vector3(90, 0, 0), 10, "Hub"))
	for k in 6:
		var a := TAU * k / 6.0
		var spoke := Build.box(Vector3(0.14, 1.0, 0.1), red if k == 0 else steel, Vector3(cos(a) * 0.55, sin(a) * 0.55, 0.05), Vector3.ZERO, "Spoke")
		spoke.rotation.z = a - PI * 0.5
		wheel.add_child(spoke)
	for k in 16:
		var a := TAU * (k + 0.5) / 16.0
		var rim := Build.box(Vector3(0.12, 0.44, 0.14), steel, Vector3(cos(a) * 1.08, sin(a) * 1.08, 0.05), Vector3.ZERO, "Rim")
		rim.rotation.z = a
		wheel.add_child(rim)


func _process(delta: float) -> void:
	if wheel != null:
		_spin = move_toward(_spin, TURBINE_SPIN if powered else 0.0, delta * 1.5)
		if _spin > 0.0:
			wheel.rotate_z(-_spin * delta)
	if not powered or hut_powered:
		return
	_t += delta
	while _lit < lamps.size() and _t >= WAVE * (_lit + 1):
		lamps[_lit].material_override = _mat_on
		halos[_lit].visible = true
		Sfx.play3d("click", lamps[_lit].global_position, -10.0)
		_lit += 1
	if _lit >= lamps.size() and _t >= WAVE * (_lit + 2):
		_power_hut()


## The blue tank has filled: the turbine starts and the wave of lamps runs north.
func power_on() -> void:
	if powered:
		return
	powered = true
	_t = 0.0
	Sfx.play3d("bang", wheel.global_position, -4.0)
	for n in get_tree().get_nodes_in_group("player"):
		var q := n as PlayerRig
		if q.global_position.distance_to(wheel.global_position) < 120.0:
			q.say("Down by the river the old turbine shudders and starts to turn. One by one, lamps flicker on along the poles beside the road, north towards the bridge.", 8.0)


func _power_hut() -> void:
	hut_powered = true
	hut_lamp.material_override = _mat_on
	hut_light.visible = true
	_hum.target = 1.0
	Sfx.play3d("latch", hut_lamp.global_position, -4.0)


## After a load: the state follows the station without the show.
func sync() -> void:
	if _station == null:
		return
	powered = _station.solved
	hut_powered = powered
	_lit = lamps.size() if powered else 0
	_t = 0.0
	_spin = TURBINE_SPIN if powered else 0.0
	for l in lamps:
		l.material_override = _mat_on if powered else null
	for h in halos:
		h.visible = powered
	hut_lamp.material_override = _mat_on if powered else null
	hut_light.visible = powered
	_hum.target = 1.0 if powered else 0.0
