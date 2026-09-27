class_name StormFront
extends Node

## E7, the storm starts (design/BESSI.md, 31:00): with the batteries and the
## fuel found, the sky over the way you came turns black. A bank of cloud
## stands over the Beach Road towards the ghat, grey curtains of rain under
## it, lightning in it and thunder a moment later; the light goes (the mood
## falls to 0.3). The Five Roses sink back into the sand, and Naresh says his
## friend says to go north: the coast road. Milestone F drives through it.
##
## State: the story's flag "storm_on".

const AFTER := 6.0                 ## s after the second job before it starts
const DIST := 430.0                ## m from the roses towards the ghat pass
const WIDTH := 1000.0
const CLOUD_Y := 260.0
const FLASH := Vector2(4.0, 9.0)   ## s between flashes
const MOOD := 0.3

var root: Node3D
var started := false
var flashes := 0                   ## tests read these
var last_flash_ms := -1
var _t := 0.0
var _flash_t := 3.0
var _flash_light: DirectionalLight3D
var _glow_mat: StandardMaterial3D
var _thunder: AudioStreamPlayer
var _thunder_in := -1.0


func setup(b) -> void:
	add_to_group("storm_front")
	var roses: Vector3 = b.ROSE_CENTRE
	var pass_at: Vector3 = b.poi["ghat_pass"]
	var dir := Vector3(pass_at.x - roses.x, 0, pass_at.z - roses.z).normalized()
	var at := roses + dir * DIST
	root = Node3D.new()
	root.name = "StormFront"
	root.position = Vector3(at.x, 0, at.z)
	root.basis = Basis.looking_at(-dir, Vector3.UP)     # its face (+Z) towards Bessi
	b.world.add_child(root)
	b.poi["storm_front"] = root.position
	var cloud := StandardMaterial3D.new()
	cloud.albedo_color = Color(0.10, 0.11, 0.14)
	cloud.roughness = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in 9:
		var x := -WIDTH * 0.5 + WIDTH * (float(k) + 0.5) / 9.0 + rng.randf_range(-40, 40)
		var r := rng.randf_range(110.0, 170.0)
		var s := Build.sphere(1.0, cloud, Vector3(x, CLOUD_Y + rng.randf_range(-30, 40), rng.randf_range(-60, 60)), Vector3(r * 1.3, r * 0.45, r), "Cloud")
		s.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(s)
	# the rain: tall grey curtains from the cloud base to the ground
	var rain := StandardMaterial3D.new()
	rain.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	rain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rain.cull_mode = BaseMaterial3D.CULL_DISABLED
	var grad := GradientTexture2D.new()
	grad.fill_from = Vector2(0, 0)
	grad.fill_to = Vector2(0, 1)
	var g := Gradient.new()
	g.set_color(0, Color(0.25, 0.27, 0.32, 0.75))
	g.set_color(1, Color(0.35, 0.37, 0.42, 0.35))
	grad.gradient = g
	rain.albedo_texture = grad
	for k in 3:
		var q := QuadMesh.new()
		q.size = Vector2(WIDTH * 0.9, CLOUD_Y)
		var m := Build.node(q, rain, Transform3D(Basis(), Vector3(0, CLOUD_Y * 0.5, -40.0 + k * 40.0)), "Rain")
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(m)
	# lightning: a glow in the clouds and a flash of light across the land
	_glow_mat = StandardMaterial3D.new()
	_glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glow_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_glow_mat.albedo_color = Color(0.8, 0.85, 1.0, 0.0)
	var gq := QuadMesh.new()
	gq.size = Vector2(WIDTH * 0.8, CLOUD_Y * 0.9)
	root.add_child(Build.node(gq, _glow_mat, Transform3D(Basis(), Vector3(0, CLOUD_Y * 0.6, 50.0)), "Lightning"))
	_flash_light = DirectionalLight3D.new()
	_flash_light.name = "LightningLight"
	_flash_light.light_color = Color(0.85, 0.9, 1.0)
	_flash_light.light_energy = 0.0
	_flash_light.shadow_enabled = false
	root.add_child(_flash_light)
	_flash_light.rotation = Vector3(deg_to_rad(-30), 0, 0)
	_thunder = AudioStreamPlayer.new()
	_thunder.stream = load("res://audio/thunder_far.wav")
	_thunder.volume_db = -4.0
	add_child(_thunder)
	root.visible = false


func _physics_process(delta: float) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st == null or st.index_of("storm") < 0:
		return
	if not started:
		if st.flags.has("storm_on"):
			start(st, false)
		elif st.flags.has("batteries_got") and st.flags.has("drum_free"):
			_t += delta
			if _t >= AFTER:
				start(st, true)
		return
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null and mood.target > MOOD:
		mood.target = MOOD
	_flash_t -= delta
	if _flash_t <= 0.0:
		_flash_t = randf_range(FLASH.x, FLASH.y)
		_flash()
	if _thunder_in >= 0.0:
		_thunder_in -= delta
		if _thunder_in < 0.0:
			_thunder.play()


## The storm arrives. `tell`: the first time (not after a load or a jump...
## a jump tells it too, so it's seen).
func start(st: Story, tell: bool) -> void:
	started = true
	st.flags["storm_on"] = true
	root.visible = true
	_flash_t = 1.5
	var ro := get_tree().get_first_node_in_group("roses") as Roses
	if ro != null:
		ro.sink_away(not tell)
	var boot := get_tree().current_scene
	var nz: Naresh = boot.naresh if boot != null else null
	if tell:
		for n in get_tree().get_nodes_in_group("player"):
			(n as PlayerRig).say("Back the way you came the sky has gone black. Lightning over the ghat, a wall of rain on the road. Behind you the roses are sinking into the sand.", 8.0)
		if nz != null and is_instance_valid(nz):
			nz.say("My friend says we should go north.")


func _flash() -> void:
	flashes += 1
	last_flash_ms = Time.get_ticks_msec()
	var tw := create_tween()
	tw.tween_property(_flash_light, "light_energy", 2.2, 0.05)
	tw.tween_property(_flash_light, "light_energy", 0.0, 0.12)
	tw.tween_property(_flash_light, "light_energy", 1.6, 0.05)
	tw.tween_property(_flash_light, "light_energy", 0.0, 0.25)
	var tg := create_tween()
	tg.tween_property(_glow_mat, "albedo_color:a", 0.55, 0.05)
	tg.tween_property(_glow_mat, "albedo_color:a", 0.0, 0.5)
	_thunder_in = randf_range(1.2, 2.2)       # 430 m away: the sound comes after


## The story jumped back before the storm (F1): all put away.
func match_story() -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null and st.flags.has("storm_on"):
		return
	started = false
	_t = 0.0
	root.visible = false
