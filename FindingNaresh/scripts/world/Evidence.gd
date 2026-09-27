class_name Evidence
extends Node

## E5, the evidence (design/BESSI.md, 28:30): there was never a friend, and
## nobody says so. Found, not told: one set of footprints in the sand from
## the photo spot up to the fifth rose; in his camp inside it, one sleeping
## bag slept in and a second still rolled in its plastic with the shop's tag;
## the camera on its little tripod with the self-timer set (that's how the
## photo was taken, alone); his notebook, where every "we" is written over an
## "I". Each only says what you see. While you look, Naresh packs up ("my
## friend's gone for a walk").
##
## State in the story's flags: "seen_<item>", "packing", "packed".

const STEP := 0.75                ## m between footprints
const CAMP_OUT := 6.5             ## m from the fifth rose's middle, towards the plaza's
const PACK_MIN := 3               ## things seen before he's done packing
const PACK_MAX_S := 120.0         ## or this long after he started
## [id, what the prompt calls it, what you see]
const ITEMS := [
	["bag", "the sleeping bag", "A sleeping bag, unrolled and slept in. A torch beside it, one water bottle, one mug."],
	["spare", "the other sleeping bag", "Another sleeping bag, still rolled up tight in its plastic. The shop's price tag is still on it."],
	["camera", "the camera", "A small camera on a little tripod. The self-timer is set to ten seconds. The last picture on it: this beach from the promenade at dusk, him at the edge of the frame."],
	["notebook", "the notebook", "<bb>His notebook, open at the last page:\n\n\"[color=#9a2c1c][s] I [/s][/color] we got to Bessi today.\n[color=#9a2c1c][s] I [/s][/color] we found the roses.\n[color=#9a2c1c][s] I [/s][/color] we are going to wait here.\""],
	["prints", "the footprints", "Footprints in the sand, from the promenade up to the roses."],
]

var camp := Vector3.ZERO
var camp_root: Node3D
var prints: MultiMeshInstance3D
var print_points: PackedVector3Array = PackedVector3Array()
var _pack_t := 0.0
var _greet_t := 0.0
const GREET_S := 3.0              ## s after "You came!" before he goes to pack


func setup(b) -> void:
	add_to_group("evidence")
	var seat: Vector3 = b.poi["naresh_seat"]
	var centre: Vector3 = b.ROSE_CENTRE
	var to_c := Vector3(centre.x - seat.x, 0, centre.z - seat.z).normalized()
	camp = Vector3(seat.x, 0, seat.z) + to_c * CAMP_OUT
	camp.y = b._h(camp.x, camp.z) + 0.08            # on the plaza stones
	b.poi["camp"] = camp
	camp_root = Node3D.new()
	camp_root.name = "Camp"
	camp_root.position = camp
	camp_root.basis = Basis.looking_at(to_c, Vector3.UP)
	b.world.add_child(camp_root)
	_camp(b)
	camp_root.visible = false
	_footprints(b, b.poi["photo_spot"], camp)


# --- the camp -------------------------------------------------------------------------

func _camp(b) -> void:
	var blue := ToonMat.make(Color(0.22, 0.34, 0.62), 0.02)
	var green := ToonMat.make(Color(0.30, 0.46, 0.30), 0.02)
	var dark := ToonMat.make(Color(0.12, 0.12, 0.14), 0.01)
	var paper := ToonMat.make(Color(0.95, 0.93, 0.86), 0.01)
	# the one he slept in, and his things
	var bag := _thing(b, "bag", Vector3(-1.2, 0, 0), Vector3(1.0, 0.5, 2.2))
	bag.add_child(Build.box(Vector3(0.9, 0.12, 2.0), blue, Vector3(0, 0.06, 0), Vector3.ZERO, "Bag"))
	bag.add_child(Build.box(Vector3(0.6, 0.16, 0.35), blue.duplicate(), Vector3(0, 0.14, -0.8), Vector3.ZERO, "Pillow"))
	bag.add_child(Build.cyl(0.05, 0.25, dark, Vector3(0.6, 0.12, -0.9), Vector3(0, 0, 90), 8, "Torch"))
	bag.add_child(Build.cyl(0.05, 0.12, ToonMat.make(Color(0.85, 0.3, 0.2)), Vector3(0.6, 0.06, -0.55), Vector3.ZERO, 8, "Mug"))
	# the other one: never unrolled, the tag still on it
	var spare := _thing(b, "spare", Vector3(0.1, 0, -1.0), Vector3(0.9, 0.6, 0.6))
	spare.add_child(Build.cyl(0.22, 0.8, green, Vector3(0, 0.22, 0), Vector3(0, 0, 90), 12, "Roll"))
	spare.add_child(Build.cyl(0.235, 0.78, ToonMat.make(Color(0.8, 0.85, 0.9, 1.0), 0.0), Vector3(0, 0.22, 0), Vector3(0, 0, 90), 12, "Plastic"))
	spare.add_child(Build.box(Vector3(0.1, 0.14, 0.01), paper, Vector3(0.3, 0.1, 0.24), Vector3(0, 0, 12), "PriceTag"))
	# the camera on its tripod, looking out towards the promenade
	var cam := _thing(b, "camera", Vector3(1.4, 0, 0.8), Vector3(0.6, 1.4, 0.6))
	for k in 3:
		var a := TAU * float(k) / 3.0
		cam.add_child(Build.cyl(0.02, 1.2, dark, Vector3(cos(a) * 0.18, 0.55, sin(a) * 0.18), Vector3(rad_to_deg(sin(a)) * 0.2, 0, -rad_to_deg(cos(a)) * 0.2), 5, "Leg"))
	cam.add_child(Build.box(Vector3(0.22, 0.14, 0.12), dark, Vector3(0, 1.18, 0), Vector3.ZERO, "Camera"))
	cam.add_child(Build.cyl(0.04, 0.08, dark, Vector3(0, 1.18, -0.09), Vector3(90, 0, 0), 8, "Lens"))
	var lamp := Build.sphere(0.015, ToonMat.make(Color(1, 0.2, 0.1), 0.0, 1.0, Color(1, 0.2, 0.1)), Vector3(0.08, 1.24, -0.061), Vector3.ONE, "TimerLamp")
	cam.add_child(lamp)
	# his lantern: warm light on the camp under the bloom
	var lan := Node3D.new()
	lan.name = "Lantern"
	lan.position = Vector3(0.8, 0, -0.3)
	camp_root.add_child(lan)
	lan.add_child(Build.cyl(0.08, 0.25, ToonMat.make(Color(1.0, 0.85, 0.5), 0.0, 0.8, Color(1.0, 0.7, 0.3)), Vector3(0, 0.14, 0), Vector3.ZERO, 8, "Glass"))
	lan.add_child(Build.cyl(0.1, 0.03, dark, Vector3(0, 0.28, 0), Vector3.ZERO, 8, "Cap"))
	var ll := OmniLight3D.new()
	ll.light_color = Color(1.0, 0.78, 0.45)
	ll.light_energy = 2.2
	ll.omni_range = 7.0
	ll.shadow_enabled = false
	ll.position = Vector3(0, 0.5, 0)
	lan.add_child(ll)
	# the notebook, open on his folded jacket
	var nb := _thing(b, "notebook", Vector3(-0.2, 0, 1.0), Vector3(0.7, 0.4, 0.6))
	nb.add_child(Build.box(Vector3(0.6, 0.1, 0.45), ToonMat.make(Naresh.SUIT, 0.02), Vector3(0, 0.05, 0), Vector3.ZERO, "Jacket"))
	nb.add_child(Build.box(Vector3(0.32, 0.02, 0.22), paper, Vector3(0, 0.11, 0), Vector3(0, 8, 0), "Pages"))
	nb.add_child(Build.box(Vector3(0.01, 0.025, 0.22), dark, Vector3(0, 0.115, 0), Vector3(0, 8, 0), "Spine"))


## Something to look at in the camp: a body you can aim at, with its prompt.
func _thing(b, id: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Evidence_" + id
	body.position = at
	var spec: Array = _spec(id)
	body.set_meta("tag_name", spec[1])
	body.set_meta("prompt", "Look at " + String(spec[1]))
	body.set_meta("callback", func(p): look(id, p))
	body.add_child(b._box_shape(size, Transform3D(Basis(), Vector3(0, size.y * 0.5, 0))))
	camp_root.add_child(body)
	return body


static func _spec(id: String) -> Array:
	for s in ITEMS:
		if s[0] == id:
			return s
	return ["", "", ""]


## A player looks: what they see, nothing more.
func look(id: String, p: PlayerRig) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null:
		st.flags["seen_" + id] = true
	p.say(String(_spec(id)[2]), 8.0)


func seen_count() -> int:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st == null:
		return 0
	var n := 0
	for s in ITEMS:
		if st.flags.has("seen_" + String(s[0])):
			n += 1
	return n


# --- the footprints -------------------------------------------------------------------

## One set, left, right, from the promenade to his camp, wandering a little.
func _footprints(b, from: Vector3, to: Vector3) -> void:
	var d := Vector3(to.x - from.x, 0, to.z - from.z)
	var n := int(d.length() / STEP)
	var dir := d.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 3
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = n
	var rng := RandomNumberGenerator.new()
	rng.seed = 51
	for i in n:
		var t := float(i) / float(maxi(n - 1, 1))
		var wander := sin(t * 9.0) * 1.2 + sin(t * 23.0) * 0.4
		var at := from + d * t + side * (wander + (0.12 if i % 2 == 0 else -0.12))
		at.y = b._h(at.x, at.z) + 0.03
		var yaw := atan2(-dir.x, -dir.z) + rng.randf_range(-0.12, 0.12)
		var xf := Transform3D(Basis(Vector3.UP, yaw).scaled(Vector3(0.12, 0.02, 0.28)), at)
		mm.set_instance_transform(i, xf)
		print_points.append(at)
	prints = MultiMeshInstance3D.new()
	prints.name = "Footprints"
	prints.multimesh = mm
	prints.material_override = ToonMat.make(Color(0.42, 0.37, 0.30), 0.0)
	prints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(prints)
	# the look prompt: a strip along the first stretch, on the sand
	var body := StaticBody3D.new()
	body.name = "Evidence_prints"
	body.collision_layer = 4           # an interactable, not something you bump into
	body.set_meta("tag_name", "the footprints")
	body.set_meta("prompt", "Look at the footprints")
	body.set_meta("callback", func(p): look("prints", p))
	var mid := from + d * 0.15
	mid.y = b._h(mid.x, mid.z)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.4, 0.2, d.length() * 0.2)
	cs.shape = sh
	body.add_child(cs)
	body.position = mid + Vector3.UP * 0.1
	body.basis = Basis(Vector3.UP, atan2(-dir.x, -dir.z))
	b.world.add_child(body)
	b.poi["footprints"] = mid


# --- while he packs -------------------------------------------------------------------

## The story jumped (F1): his packing starts over.
func match_story() -> void:
	_greet_t = 0.0
	_pack_t = 0.0

func _physics_process(delta: float) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	if st == null or ro == null:
		return
	camp_root.visible = ro.phase in ["done", "sinking", "gone"] and st.flags.has("roses_open")
	var boot := get_tree().current_scene
	var nz: Naresh = boot.naresh if boot != null else null
	if not st.flags.has("naresh_met") or nz == null or not is_instance_valid(nz):
		return
	if not st.flags.has("packing"):
		_greet_t += delta
		if _greet_t < GREET_S:
			return                  # "You came!" first
		st.flags["packing"] = true
		_pack_t = 0.0
		var p := nz.leader if nz.leader != null else (boot.players[0] as PlayerRig)
		nz.command(p, "go", null, camp + (camp - ro.naresh_seat).normalized() * -1.0)
		nz.say("Hang on, let me pack up. My friend's gone for a walk, he'll be back in a bit.")
	if st.flags.has("packed"):
		return
	_pack_t += delta
	if seen_count() >= PACK_MIN or _pack_t >= PACK_MAX_S:
		st.flags["packed"] = true
		var p2 := nz.job_for if nz.job_for != null else (boot.players[0] as PlayerRig)
		nz.command(p2, "follow")
		nz.say("All packed! He says he'll catch us up.")
