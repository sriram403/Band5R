class_name BinocularPickup
extends Node3D

## A pair of binoculars lying somewhere (the ridge lookout, the Last Fuel
## kiosk, a gym table). Taking them gives that player binoculars for good;
## hold zoom (right mouse / LT) to look through them.

var tag := ""                      ## save/test id, e.g. "gym_binoculars"


func _ready() -> void:
	set_meta("tag_name", "binoculars")
	var body := ToonMat.make(Color(0.16, 0.17, 0.16), 0.02)
	var glass := ToonMat.make(Color(0.35, 0.55, 0.65))
	for sx in [-0.055, 0.055]:
		add_child(Build.cyl(0.042, 0.15, body, Vector3(sx, 0.045, 0), Vector3(90, 0, 0), 12, "Barrel"))
		add_child(Build.cyl(0.034, 0.01, glass, Vector3(sx, 0.045, -0.076), Vector3(90, 0, 0), 12, "Lens"))
	add_child(Build.box(Vector3(0.07, 0.03, 0.06), body, Vector3(0, 0.05, 0.01), Vector3.ZERO, "Bridge"))
	var area := Build.interact_area(Vector3(0.5, 0.35, 0.5), Vector3(0, 0.1, 0), "Take the binoculars", _take, "Pickup")
	area.set_meta("tag_name", "binoculars")
	add_child(area)


func _take(pl: PlayerRig) -> void:
	if pl.has_binoculars:
		pl.say("You already have a pair.", 2.5)
		return
	pl.has_binoculars = true
	Sfx.play3d("pickup", global_position, -4.0)
	pl.say("Binoculars. Hold %s to look through them; you can tag through them too." % pl.dev.glyph("zoom"), 5.0)
	queue_free()
