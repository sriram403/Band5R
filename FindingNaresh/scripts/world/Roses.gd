class_name Roses
extends Node

## E4, the Five Roses (design/BESSI.md, 26:30-28:00). Until the photo spot is
## found they lie sunk under the plaza (the dune is still the rose-shaped
## hill from the coast tower). Then white smoke rolls in off the sea and
## pools on the dune, and the five rise out of it, rumbling. Each has a
## carving at its base, a symbol from the journey: windmill, water drop,
## bridge, wave, star. Touch them in the order you travelled (the star is
## "here", last); each right one opens like a flower; a wrong one and the
## smoke surges and they all close again (loud, harmless). When the fifth
## opens its bloom comes down to the plaza, and Naresh is sitting in it.
##
## State lives in the story's flags (saved): "roses_up", "roses_open" (how
## many are open, in order), "naresh_met".

signal opened(k: int)

const ORDER := ["windmill", "water", "bridge", "wave", "star"]     ## the way you travelled
## Which carving each rose (ring slot 0-4, round the plaza) has: not in order
## round the ring, so it's the journey that tells you, not the layout.
const SLOT_SYMBOL := ["bridge", "star", "windmill", "wave", "water"]
const SINK := 48.0                 ## m below the plaza while sunk
const SMOKE_S := 12.0              ## s of smoke rolling in before they rise
const AFTER_PHOTO := 6.0           ## s after the photo spot is found before the smoke comes
                                   ## (so "He stood exactly here" is read first)
const RISE_S := 10.0
const OPEN_S := 2.0
const BLOOM_DOWN_S := 6.0
const MEET := 7.0                  ## m: come this close and Naresh sees you

var roses: Array = []              ## the monuments (scaled Node3D)
var bodies: Array = []             ## their plinth and stem colliders
var carvings: Array = []           ## StaticBody3D per rose
var centre := Vector3.ZERO
var phase := "sunk"                ## sunk, smoke, rising, up, done
var open_amount: Array = [0.0, 0.0, 0.0, 0.0, 0.0]
var naresh_seat := Vector3.ZERO    ## where he sits, in the fifth bloom
var _up_y: Array = []
var _t := 0.0
var _bloom_t := 0.0
var _smoke_roll: CPUParticles3D
var _smoke_pool: CPUParticles3D
var _rumble: AudioStreamPlayer3D
var _sea_at := Vector3.ZERO
var _wait_t := -1.0


func setup(b, rose_nodes: Array, rose_bodies: Array, plaza_centre: Vector3) -> void:
	add_to_group("roses")
	roses = rose_nodes
	bodies = rose_bodies
	centre = plaza_centre
	for k in roses.size():
		var r := roses[k] as Node3D
		_up_y.append(r.position.y)
		carvings.append(_carving(b, k))
	var star := roses[SLOT_SYMBOL.find("star")] as Node3D
	naresh_seat = star.position + Vector3(0, 1.0 * star.scale.y + 0.05, 0)
	b.poi["naresh_seat"] = naresh_seat
	for k in roses.size():
		b.poi["rose_" + String(SLOT_SYMBOL[k])] = (carvings[k] as Node3D).position
	# smoke off the sea: from the waterline east of the dune
	_sea_at = Vector3(Landscape.coast_inland(0.0, centre.z) + 10.0, Landscape.SEA_Y + 0.5, centre.z)
	_set_sunk(true)


# --- the carvings ---------------------------------------------------------------------

## A stone plaque on the plinth's edge facing the plaza, with its symbol
## built from exact shapes (the triangle-vs-diamond lesson: each unmistakable).
func _carving(b, k: int) -> StaticBody3D:
	var r := roses[k] as Node3D
	var sc := r.scale.x
	var to_c := centre - r.position
	to_c.y = 0.0
	to_c = to_c.normalized()
	var at := r.position + to_c * (1.6 * sc + 0.3)
	at.y = r.position.y
	var body := StaticBody3D.new()
	body.name = "Carving%d" % k
	body.position = at
	body.basis = Basis.looking_at(-to_c, Vector3.UP)     # the face (+Z) towards the centre
	var stone := ToonMat.make(b.C_STONE.lightened(0.1), 0.02)
	body.add_child(Build.box(Vector3(1.8, 1.8, 0.35), stone, Vector3(0, 1.2, 0), Vector3.ZERO, "Plaque"))
	body.add_child(b._box_shape(Vector3(1.8, 2.4, 0.5), Transform3D(Basis(), Vector3(0, 1.2, 0))))
	var glyph := _symbol(String(SLOT_SYMBOL[k]))
	glyph.position = Vector3(0, 1.2, 0.2)
	body.add_child(glyph)
	body.set_meta("tag_name", "the %s carving" % _symbol_name(String(SLOT_SYMBOL[k])))
	body.set_meta("prompt", "Touch the carving")
	body.set_meta("prompt_fn", func(_p) -> String:
		if phase != "up" or open_amount[k] > 0.5:
			return ""
		return "Touch the carving")
	body.set_meta("callback", func(p): touch(k, p))
	var root := (roses[k] as Node3D).get_parent()
	root.add_child(body)
	return body


static func _symbol_name(s: String) -> String:
	return {"windmill": "windmill", "water": "water drop", "bridge": "bridge", "wave": "wave", "star": "star"}[s]


## The symbols, about 1.2 m across, in dark stone on the plaque's face.
func _symbol(s: String) -> Node3D:
	var n := Node3D.new()
	n.name = "Symbol_" + s
	var ink := ToonMat.make(Color(0.25, 0.22, 0.2), 0.01)
	match s:
		"windmill":
			n.add_child(Build.box(Vector3(0.14, 0.7, 0.06), ink, Vector3(0, -0.3, 0), Vector3.ZERO, "Tower"))
			for a in [45.0, 135.0]:
				n.add_child(Build.box(Vector3(1.1, 0.14, 0.06), ink, Vector3(0, 0.1, 0.02), Vector3(0, 0, a), "Blade"))
		"water":
			n.add_child(Build.sphere(0.3, ink, Vector3(0, -0.15, 0), Vector3(1, 1, 0.25), "Drop"))
			n.add_child(Build.node(_flat_poly(PackedVector2Array([Vector2(-0.27, -0.05), Vector2(0.27, -0.05), Vector2(0, 0.5)])), ink, Transform3D.IDENTITY, "Tip"))
		"bridge":
			n.add_child(Build.box(Vector3(1.2, 0.12, 0.06), ink, Vector3(0, 0.05, 0), Vector3.ZERO, "Deck"))
			for x in [-0.4, 0.4]:
				n.add_child(Build.box(Vector3(0.12, 0.6, 0.06), ink, Vector3(x, -0.25, 0), Vector3.ZERO, "Pier"))
			n.add_child(Build.box(Vector3(0.12, 0.45, 0.06), ink, Vector3(-0.4, 0.3, 0), Vector3.ZERO, "Tower"))
			n.add_child(Build.box(Vector3(0.12, 0.45, 0.06), ink, Vector3(0.4, 0.3, 0), Vector3.ZERO, "Tower"))
		"wave":
			var pts := PackedVector2Array()
			for i in 25:
				var x := -0.6 + 1.2 * float(i) / 24.0
				pts.append(Vector2(x, 0.18 * sin(x * TAU * 1.2) + 0.07))
			for i in range(24, -1, -1):
				var x := -0.6 + 1.2 * float(i) / 24.0
				pts.append(Vector2(x, 0.18 * sin(x * TAU * 1.2) - 0.07))
			n.add_child(Build.node(_flat_poly(pts), ink, Transform3D.IDENTITY, "Wave"))
		"star":
			var sp := PackedVector2Array()
			for i in 10:
				var a := PI * 0.5 + TAU * float(i) / 10.0
				var rr := 0.55 if i % 2 == 0 else 0.22
				sp.append(Vector2(cos(a), sin(a)) * rr)
			n.add_child(Build.node(_flat_poly(sp), ink, Transform3D.IDENTITY, "Star"))
	return n


## A flat shape from exact points (a fan from its centre), 6 cm thick look.
static func _flat_poly(pts: PackedVector2Array) -> ArrayMesh:
	var c := Vector2.ZERO
	for p in pts:
		c += p
	c /= float(pts.size())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in pts.size():
		var a := pts[i]
		var b := pts[(i + 1) % pts.size()]
		for v in [c, b, a]:
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(Vector3((v as Vector2).x, (v as Vector2).y, 0.04))
	return st.commit()


# --- sinking, the smoke and rising -------------------------------------------------------

func _set_sunk(on: bool) -> void:
	for k in roses.size():
		_place(k, -SINK if on else 0.0)


func _place(k: int, dy: float) -> void:
	var r := roses[k] as Node3D
	r.position.y = float(_up_y[k]) + dy
	(bodies[k] as Node3D).position.y = float(_up_y[k]) + dy
	(carvings[k] as Node3D).position.y = float(_up_y[k]) + dy
	r.visible = dy > -SINK + 0.5
	(carvings[k] as Node3D).visible = r.visible


## The photo spot was found: the smoke comes, then they rise.
func begin() -> void:
	if phase != "sunk":
		return
	phase = "smoke"
	_t = 0.0
	# a bank 120 m wide, low over the water, drifting in at ~20 m/s: it
	# reaches the dune (~200 m) in about 10 s and keeps coming until they rise
	_smoke_roll = _smoke(420, 13.0, Vector3(15, 1.5, 70), 0.45)
	_smoke_roll.global_position = _sea_at
	_smoke_roll.direction = (Vector3(centre.x, _sea_at.y, centre.z) - _sea_at).normalized()
	_smoke_roll.spread = 8.0
	_smoke_roll.initial_velocity_min = 17.0
	_smoke_roll.initial_velocity_max = 23.0
	_smoke_roll.damping_min = 0.3
	_smoke_roll.damping_max = 0.6
	_smoke_roll.gravity = Vector3(0, 0.05, 0)
	_smoke_roll.emitting = true
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say("Out at sea, a low white bank of smoke rolls in over the water... towards the dune.", 6.0)


## Soft smoke: big camera-facing puffs with a round, fading edge (spheres
## read as floating balls), fading in and out over their life.
func _smoke(amount: int, life: float, box: Vector3, alpha: float) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = life
	var tex := GradientTexture2D.new()
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.55))
	tex.gradient = g
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_texture = tex
	mat.albedo_color = Color(0.95, 0.96, 1.0, alpha)
	mat.vertex_color_use_as_albedo = true
	mat.disable_receive_shadows = true
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	quad.material = mat
	p.mesh = quad
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.set_color(1, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.add_point(0.75, Color(1, 1, 1, 0.8))
	p.color_ramp = fade
	p.one_shot = false
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = box
	p.gravity = Vector3(0, -0.2, 0)
	p.scale_amount_min = 4.0
	p.scale_amount_max = 9.0
	p.damping_min = 1.5
	p.damping_max = 2.5
	var root := get_tree().get_first_node_in_group("world_root")
	root.add_child(p)
	return p


## Back as at the start: sunk, closed, no smoke, the fifth bloom back up
## its stem (the dev menu, tests: the photo test sets them off).
func reset() -> void:
	phase = "sunk"
	_t = 0.0
	_bloom_t = 0.0
	_wait_t = -1.0
	for k in open_amount.size():
		open_amount[k] = 0.0
	for p in [_smoke_roll, _smoke_pool]:
		if p != null and is_instance_valid(p):
			p.queue_free()
	_smoke_roll = null
	_smoke_pool = null
	if _rumble != null and is_instance_valid(_rumble):
		_rumble.queue_free()
	_rumble = null
	var star_k := SLOT_SYMBOL.find("star")
	var r := roses[star_k] as Node3D
	(r.get_node("Bloom") as Node3D).position.y = 0.0
	var stem := r.get_node("Stem") as Node3D
	stem.scale.y = 1.0
	stem.position.y = 6.6
	var core := r.get_node("Bloom").get_node_or_null("Core") as Node3D
	if core != null:
		core.scale = Vector3.ONE
	for c in r.get_children():
		if c.name.begins_with("Leaf"):
			(c as Node3D).visible = true
	((bodies[star_k] as Node).get_node("StemShape") as CollisionShape3D).disabled = false
	_show_open(1.0)
	_set_sunk(true)


## Straight up, as after a load.
func rise_now() -> void:
	phase = "up"
	_set_sunk(false)
	_pool(true)


func _pool(on: bool) -> void:
	if on and _smoke_pool == null:
		_smoke_pool = _smoke(160, 9.0, Vector3(30, 0.6, 30), 0.3)
		_smoke_pool.global_position = centre + Vector3(0, 0.6, 0)
		_smoke_pool.initial_velocity_min = 0.2
		_smoke_pool.initial_velocity_max = 0.8
		_smoke_pool.emitting = true
	elif not on and _smoke_pool != null:
		_smoke_pool.emitting = false


func _physics_process(delta: float) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st == null or st.index_of("roses") < 0:
		return
	# the story's state, after a load or a jump
	if phase == "sunk" and st.flags.has("roses_up"):
		rise_now()
		for k in int(st.flags.get("roses_open", 0)):
			open_amount[SLOT_SYMBOL.find(ORDER[k])] = 1.0
		if st.flags.has("naresh_met"):
			phase = "done"
			_bloom_t = BLOOM_DOWN_S
	if phase == "sunk" and st.flags.has("photo_spot"):
		if _wait_t < 0.0:
			_wait_t = AFTER_PHOTO
		_wait_t -= delta
		if _wait_t <= 0.0:
			begin()
	match phase:
		"smoke":
			_t += delta
			if _t >= SMOKE_S:
				phase = "rising"
				_t = 0.0
				_smoke_roll.emitting = false
				_pool(true)
				_rumble = AudioStreamPlayer3D.new()
				_rumble.stream = load("res://audio/rumble_rise.wav")
				_rumble.unit_size = 40.0
				_rumble.max_distance = 400.0
				_rumble.volume_db = 4.0
				add_child(_rumble)
				_rumble.global_position = centre
				_rumble.play()
		"rising":
			_t += delta
			var k := smoothstep(0.0, 1.0, _t / RISE_S)
			for i in roses.size():
				_place(i, -SINK * (1.0 - k))
			if _t >= RISE_S:
				phase = "up"
				st.flags["roses_up"] = true
				for n in get_tree().get_nodes_in_group("player"):
					(n as PlayerRig).say("Out of the smoke: five stone roses, taller than houses, in a ring on the dune. Each has a carving at its foot.", 7.0)
	_show_open(delta)
	if phase == "done" or (phase == "up" and int(st.flags.get("roses_open", 0)) >= 5):
		_bring_bloom_down(delta, st)


# --- the order puzzle -------------------------------------------------------------------

## Someone touches rose k's carving.
func touch(k: int, p: PlayerRig) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if phase != "up" or st == null:
		return
	var n := int(st.flags.get("roses_open", 0))
	if n >= 5 or open_amount[k] > 0.5:
		return
	if SLOT_SYMBOL[k] == ORDER[n]:
		st.flags["roses_open"] = n + 1
		Sfx.play3d("bong", (carvings[k] as Node3D).global_position + Vector3.UP * 2.0, 2.0)
		opened.emit(k)
		if n + 1 < 5:
			p.say("The %s. The rose above it opens, petal by petal." % _symbol_name(String(SLOT_SYMBOL[k])), 4.0)
	else:
		# wrong: the smoke surges and they all close
		st.flags["roses_open"] = 0
		Sfx.play3d("bang", centre + Vector3.UP * 3.0, 6.0)
		var puff := _smoke(60, 2.5, Vector3(24, 2, 24), 0.7)
		puff.global_position = centre + Vector3(0, 1.0, 0)
		puff.initial_velocity_min = 3.0
		puff.initial_velocity_max = 7.0
		puff.direction = Vector3.UP
		puff.spread = 60.0
		var tw := puff.create_tween()
		tw.tween_interval(1.2)
		tw.tween_property(puff, "emitting", false, 0.0)
		tw.tween_interval(3.0)
		tw.tween_callback(puff.queue_free)
		for n2 in get_tree().get_nodes_in_group("player"):
			(n2 as PlayerRig).say("The smoke surges up round your feet with a boom, and the roses close again.", 4.0)


## Opening (or closing after a wrong one): each rose's petals fold out.
func _show_open(delta: float) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	var n := int(st.flags.get("roses_open", 0)) if st != null else 0
	for k in roses.size():
		var want := 1.0 if ORDER.find(SLOT_SYMBOL[k]) < n else 0.0
		open_amount[k] = move_toward(open_amount[k], want, delta / OPEN_S)
		var bloom := (roses[k] as Node3D).get_node_or_null("Bloom")
		if bloom == null:
			continue
		for h in bloom.get_children():
			if h.has_meta("tilt") and h.get_child_count() > 0:
				(h.get_child(0) as Node3D).rotation_degrees.x = float(h.get_meta("tilt")) + 38.0 * float(open_amount[k])


## The fifth: its bloom comes down its stem to the plaza, open, with Naresh
## sitting in it.
func _bring_bloom_down(delta: float, st: Story) -> void:
	var star_k := SLOT_SYMBOL.find("star")
	var r := roses[star_k] as Node3D
	var bloom := r.get_node("Bloom") as Node3D
	var stem := r.get_node("Stem") as Node3D
	_bloom_t = minf(BLOOM_DOWN_S, _bloom_t + delta)
	var k := smoothstep(0.0, 1.0, _bloom_t / BLOOM_DOWN_S)
	bloom.position.y = -11.4 * k            # from 12.4-14.4 (rose units) to just over the plinth
	stem.scale.y = lerpf(1.0, 0.08, k)
	stem.position.y = lerpf(6.6, 1.1, k)
	# the heart of the flower shrinks away: he sits where it was; the leaves go
	var core := bloom.get_node_or_null("Core") as Node3D
	if core != null:
		core.scale = Vector3.ONE * maxf(0.01, 1.0 - k)
	for c in r.get_children():
		if c.name.begins_with("Leaf"):
			(c as Node3D).visible = k < 0.6
	var shape := (bodies[star_k] as Node).get_node("StemShape") as CollisionShape3D
	shape.disabled = k > 0.5
	if _bloom_t >= BLOOM_DOWN_S and phase != "done":
		phase = "done"
		_seat_naresh(st)
	if phase == "done" and not st.flags.has("naresh_met"):
		_await_meeting(st)


func _seat_naresh(_st: Story) -> void:
	var boot := get_tree().current_scene
	if boot == null:
		return
	var nz: Naresh = boot.naresh
	if nz == null or not is_instance_valid(nz):
		nz = Naresh.spawn(boot.world, naresh_seat, 0.0)
		boot.naresh = nz
	nz.sit_at(Transform3D(Basis.looking_at(Vector3(centre.x - naresh_seat.x, 0, centre.z - naresh_seat.z).normalized(), Vector3.UP), naresh_seat))
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say("The fifth rose sinks down its stem and opens on the plaza. There's someone sitting in it, cross-legged.", 7.0)


func _await_meeting(st: Story) -> void:
	var boot := get_tree().current_scene
	var nz: Naresh = boot.naresh if boot != null else null
	if nz == null:
		return
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if p.global_position.distance_to(naresh_seat) < MEET:
			st.flags["naresh_met"] = true
			nz.stand_from_seat(p)
			nz.say("You came! He said you would.")
			return
