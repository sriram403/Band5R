class_name FuelSource
extends Node3D

## An opening fuel drum or the working Town Fuel pump. A carried empty can
## fills while E is held, with its weight and label changing as it fills.

var source_name := "fuel drum"
var pump_style := false
var litres := 120.0
var flow_rate := 5.0


func _ready() -> void:
	var main := ToonMat.make(Color(0.20, 0.55, 0.35) if pump_style else Color(0.68, 0.17, 0.12))
	var trim := ToonMat.make(Color(0.19, 0.20, 0.22))
	if pump_style:
		add_child(Build.solid_box(Vector3(0.8, 1.6, 0.55), main, Vector3(0, 0.8, 0), Vector3.ZERO, "PumpBody"))
		add_child(Build.box(Vector3(0.5, 0.38, 0.04), trim, Vector3(0, 1.13, 0.3), Vector3.ZERO, "Meter"))
	else:
		add_child(Build.solid_cyl(0.65, 1.35, main, Vector3(0, 0.68, 0), Vector3.ZERO, "Tank"))
		for y in [0.18, 1.18]:
			add_child(Build.cyl(0.67, 0.07, trim, Vector3(0, y, 0), Vector3.ZERO, 16, "Rim"))
	add_child(Build.box(Vector3(0.18, 0.24, 0.3), trim, Vector3(0, 1.4, 0.18), Vector3.ZERO, "Spout"))
	var area := Build.interact_area(Vector3(1.2, 1.4, 0.45), Vector3(0, 0.85, 0.75),
		"Bring an empty fuel can", func(_p): pass, "FillCan")
	area.set_meta("held_prompt_fn", func(_p, item) -> String:
		if not item is FuelCan:
			return ""
		if litres <= 0.01:
			return "%s is empty" % source_name
		if item.litres >= FuelCan.CAPACITY - 0.01:
			return "Fuel can is full"
		return "Hold to fill can at %s" % source_name)
	area.set_meta("held_action", func(_p, item, dt: float, _first: bool):
		if not item is FuelCan or litres <= 0.0:
			return
		var moved: float = minf(flow_rate * dt, minf(litres, FuelCan.CAPACITY - item.litres))
		item.litres += moved
		item._update_mass()
		item._refresh_prompt()
		litres -= moved
		if pump_style and moved > 0.0:
			var story := get_tree().get_first_node_in_group("story") as Story
			if story != null:
				story.flags["town_fuel_filled"] = true)
	add_child(area)
