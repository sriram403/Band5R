class_name FlareGun
extends Carryable

## The hidden flare gun (design/CREATURES.md, F6): off the path in the old
## rail tunnel's gallery, seen only by torchlight. Held, the throw button
## (LMB / RB) fires a flare up from where you stand: every creature within
## SCARE_R m runs from it and keeps away for SCARE_S s. Three flares. No
## killing, ever. Flares used are kept in the story's flags ("flares_used").

const FLARES := 3
const SCARE_R := 80.0
const SCARE_S := 90.0


func _ready() -> void:
	item_name = "flare gun"
	kind = "flare_gun"
	mass = 1.3
	var red := ToonMat.make(Color(0.85, 0.22, 0.15), 0.02)
	var dark := ToonMat.make(Color(0.20, 0.20, 0.22), 0.02)
	add_child(Build.box(Vector3(0.07, 0.07, 0.30), red, Vector3(0, 0.12, -0.04), Vector3.ZERO, "Barrel"))
	add_child(Build.box(Vector3(0.06, 0.14, 0.07), dark, Vector3(0, 0.05, 0.08), Vector3(-15, 0, 0), "Grip"))
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.12, 0.2, 0.34)
	cs.shape = sh
	cs.position = Vector3(0, 0.1, 0)
	add_child(cs)
	super._ready()


func flares_left() -> int:
	var st := get_tree().get_first_node_in_group("story") as Story
	var used := int(st.flags.get("flares_used", 0)) if st != null else 0
	return maxi(0, FLARES - used)


func label() -> String:
	return "flare gun (%d left)" % flares_left()


## Fire one flare: up it goes, red and bright, and they run.
func fire(p: Node3D) -> bool:
	if flares_left() <= 0:
		if p.has_method("say"):
			p.say("Click. No flares left.", 2.5)
		return false
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null:
		st.flags["flares_used"] = int(st.flags.get("flares_used", 0)) + 1
	var from := p.global_position + Vector3.UP * 1.8
	Sfx.play3d("bang", from, 6.0)
	var flare := Node3D.new()
	flare.name = "Flare"
	get_tree().current_scene.get("world").add_child(flare)
	flare.global_position = from
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.35, 0.25)
	light.light_energy = 6.0
	light.omni_range = 70.0
	flare.add_child(light)
	var glow := StandardMaterial3D.new()
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(1.0, 0.45, 0.3)
	flare.add_child(Build.sphere(0.25, glow, Vector3.ZERO, Vector3.ONE, "Spark"))
	var tw := flare.create_tween()
	tw.tween_property(flare, "global_position", from + Vector3.UP * 24.0, 2.0)
	tw.tween_property(light, "light_energy", 0.0, 5.0)
	tw.tween_callback(flare.queue_free)
	var n := 0
	for c in get_tree().get_nodes_in_group("creature"):
		var cr := c as Creature
		if cr.global_position.distance_to(from) < SCARE_R:
			cr.scare(from, SCARE_S)
			n += 1
	_refresh_prompt()
	return true
