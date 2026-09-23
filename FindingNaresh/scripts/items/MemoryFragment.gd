class_name MemoryFragment
extends Node3D

## A glowing petal: a Memory Fragment. Three make a Memory Rose, and a rose
## is what the travel journal spends to save. Picked up with E; the count is
## shared by both players and lives in the story state.

var fragment_id := ""
## If set, only players whose feet are at least this high can take it (a
## fragment on a roof must be climbed to, not plucked from the ground).
var min_feet_y := -INF
var _spin: Spinner


static func create(id: String) -> MemoryFragment:
	var f := MemoryFragment.new()
	f.fragment_id = id
	f.name = "Fragment_" + id
	return f


func _ready() -> void:
	add_to_group("memory_fragment")
	_spin = Spinner.new()
	_spin.axis = Vector3.UP
	_spin.speed = 1.2
	add_child(_spin)
	var glow := ToonMat.make(Color(1.0, 0.55, 0.70), 0.0, 0.4, Color(1.0, 0.35, 0.55))
	var petal := Build.sphere(0.22, glow, Vector3(0, 0.1, 0), Vector3(0.8, 0.35, 1.3), "Petal")
	petal.rotation_degrees = Vector3(20, 0, 0)
	_spin.add_child(petal)
	_spin.add_child(Build.sphere(0.07, ToonMat.make(Color(1, 0.95, 0.7), 0.0, 0.4, Color(1, 0.9, 0.5)), Vector3(0, 0.15, 0), Vector3.ONE, "Core"))
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.55, 0.7)
	light.light_energy = 1.2
	light.omni_range = 3.0
	light.shadow_enabled = false
	light.position = Vector3(0, 0.3, 0)
	add_child(light)
	var area := Build.interact_area(Vector3(0.8, 0.8, 0.8), Vector3(0, 0.15, 0), "Take the memory fragment", func(p):
		if _reachable(p):
			_collect(p), "FragmentArea")
	area.set_meta("blocked_fn", func(p) -> String:
		return "" if _reachable(p) else "A memory fragment - out of reach up there")
	add_child(area)


func _reachable(p) -> bool:
	return (p as Node3D).global_position.y >= min_feet_y


func _collect(p) -> void:
	var st := get_tree().get_first_node_in_group("story") as Story
	if st != null:
		st.add_fragment(fragment_id, p)
	Sfx.play3d("glass", global_position, -2.0, 0.02)
	queue_free()
