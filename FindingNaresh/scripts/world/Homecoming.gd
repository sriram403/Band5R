class_name Homecoming
extends Node

## F8, the end of the return (design/RETURN.md, decisions 3 and 4; DESIGN.md
## beats 9-10). Naresh's home: the van pulls up with him, he gets out and
## walks to the door; his mother hugs him; his sister looks at the empty space
## beside him on the path and says nothing. If every optional thing was done
## (the barn maze, the lookout relay, the flare gun, every Memory Fragment)
## she gives you the tracker, "for next time" (nobody says it exists). He
## goes in. The light comes back (mood 0.7), and on the West Road home it's
## full sun. From the ending watchtower's deck a small light stands over every
## place the journey went; the optional ones you skipped stay dark. Near home,
## both phones: "Naresh has left his house, heading to LiveStander." The end.
##
## State in the story's flags: "naresh_home_done", "tracker", "tower_view",
## "end_reached".

const ARRIVE := 40.0                  ## m from the house the van counts as there
const HOME_MOOD := 0.7
const SUN_MOOD := 1.0
const END_NEAR := 250.0               ## m from either home the end comes

var house := Vector3.ZERO
var door := Vector3.ZERO
var lights: Array[Node3D] = []
var _optional := {}                   ## light -> the flag/test that lights it
var _story: Story
var _stage := 0
var _t := 0.0
var _mother: Node3D
var _sister: Node3D
var _fragments := {}                  ## every fragment id the world has (or had)
var _end: CanvasLayer
var _end_t := -1.0


func setup(b) -> void:
	add_to_group("homecoming")
	house = b.poi["naresh_home"]
	var road: Route = b.network.road("coast_road")
	# the door faces the road: from the house towards its nearest road point
	var best := INF
	var at := house
	for i in road.point_count():
		var q := road.point(i)
		var d := Vector2(q.x - house.x, q.z - house.z).length()
		if d < best:
			best = d
			at = q
	var to := Vector3(at.x - house.x, 0, at.z - house.z).normalized()
	door = house + to * 6.5
	door.y = b._h(door.x, door.z)
	b.poi["naresh_door"] = door
	b.poi["naresh_home_road"] = at
	_family(b, to)
	_site_lights(b)


func _family(b, out: Vector3) -> void:
	var side := Vector3.UP.cross(out).normalized()
	var specs := [["Mother", door + side * 0.8, 1.62, Color(0.75, 0.25, 0.35)], ["Sister", door - side * 0.9, 1.45, Color(0.30, 0.45, 0.75)]]
	for sp in specs:
		var n := Node3D.new()
		n.name = "Naresh" + String(sp[0])
		var h: float = sp[2]
		n.add_child(Build.cyl(0.22, h * 0.75, ToonMat.make(sp[3]), Vector3(0, h * 0.375, 0), Vector3.ZERO, 10, "Body"))
		n.add_child(Build.sphere(0.15, ToonMat.make(Color(0.62, 0.45, 0.33)), Vector3(0, h * 0.87, 0), Vector3.ONE, "Head"))
		n.position = sp[1]
		n.basis = Basis.looking_at(out, Vector3.UP)
		n.visible = false
		b.world.add_child(n)
		if sp[0] == "Mother":
			_mother = n
		else:
			_sister = n


## A small warm light high over each place the journey went (seen from the
## ending watchtower). The optional ones only if you did them.
func _site_lights(b) -> void:
	var p: Dictionary = b.poi
	var sites := [["windmill", "j1"], ["facility", ""], ["bridge", ""], ["coast_tower", ""], ["roses", ""],
		["fishing_village", ""], ["salt_gantry", ""], ["estuary_bridge", ""], ["tunnel_portal", ""], ["radio_mast", ""],
		["barn", "maze"], ["lookout_deck", "relay"], ["tunnel_gate", "flare"]]
	var warm := StandardMaterial3D.new()
	warm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	warm.albedo_color = Color(1.0, 0.85, 0.45)
	warm.disable_fog = true
	for s in sites:
		var key: String = s[0]
		if not p.has(key):
			key = String(s[1]) if p.has(String(s[1])) else ""
		if key == "":
			continue
		var at: Vector3 = p[key]
		at.y = maxf(at.y, Landscape.ground(at.x, at.z)) + 40.0
		var l := Build.sphere(7.0, warm, at, Vector3.ONE, "SiteLight_" + key)     # a few pixels at 2-3 km
		l.visible = false
		b.world.add_child(l)
		lights.append(l)
		if String(s[1]) in ["maze", "relay", "flare"]:
			_optional[l] = s[1]


func _flag(f: String) -> bool:
	return _story != null and _story.flags.has(f)


func _physics_process(delta: float) -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
		if _story == null:
			return
		for f in get_tree().get_nodes_in_group("memory_fragment"):
			_fragments[(f as MemoryFragment).fragment_id] = true
		for id in _story.collected:
			_fragments[id] = true
	if _end_t >= 0.0:
		_end_t += delta
		return
	var boot := get_tree().current_scene
	var van: Camper = boot.get("camper")
	if van == null or not _flag("mast_done"):
		return
	if not _flag("naresh_home_done"):
		_arrive(delta, boot, van)
		return
	# the West Road: full sun
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null and van.global_position.distance_to(house) > 300.0:
		mood.target = maxf(mood.target, SUN_MOOD)
	_tower_view()
	_near_home(delta, boot, van)


func _arrive(delta: float, boot: Node, van: Camper) -> void:
	var nz: Naresh = boot.get("naresh")
	if nz == null or not is_instance_valid(nz):
		return
	match _stage:
		0:
			if Vector2(van.global_position.x - door.x, van.global_position.z - door.z).length() < ARRIVE and van.linear_velocity.length() < 1.5:
				_stage = 1
				_t = 0.0
				var p: PlayerRig = boot.players[0]
				nz.command(p, "go", null, door + (door - house).normalized() * 1.6)
				_mother.visible = true
				_sister.visible = true
		1:
			_t += delta
			if nz.global_position.distance_to(door) < 3.5 or _t > 25.0:
				_stage = 2
				_t = 0.0
				_tell("The door opens before he reaches it. His mother. She doesn't say anything at first; she just holds him, for a long time.", 8.0)
		2:
			_t += delta
			if _t > 8.0:
				_stage = 3
				_t = 0.0
				_tell("His sister is in the doorway behind her. She looks past him, at the empty space beside him on the path, for a long moment. She says nothing.", 8.0)
		3:
			_t += delta
			if _t > 8.0:
				_stage = 4
				_t = 0.0
				if all_optional():
					_story.flags["tracker"] = true
					_tell("As you turn to go, his sister presses something small into your hand: a tracker, the kind you clip to a bag. \"For next time.\"", 8.0)
				nz.say("Thanks for coming to get me. We'll be all right now.")
		4:
			_t += delta
			if _t > 5.0:
				_stage = 5
				_home(nz)


## He goes in; the return is over.
func _home(nz: Naresh) -> void:
	_story.flags["naresh_home_done"] = true
	nz.leader = null                 # (not "wait": he'd say "I'll wait here" after his goodbye)
	nz.velocity = Vector3.ZERO
	nz.global_position = house + Vector3.UP * 0.3
	nz.visible = false
	nz.process_mode = Node.PROCESS_MODE_DISABLED
	_mother.visible = false
	_sister.visible = false
	Creature.on_return = false
	for c in get_tree().get_nodes_in_group("creature"):
		(c as Creature).scare(house, 600.0)
	var mood := get_tree().get_first_node_in_group("mood") as Mood
	if mood != null:
		mood.target = maxf(mood.target, HOME_MOOD)
	_tell("The door closes. Behind you the light is coming back: the clouds are breaking. The West Road runs home from here.", 7.0)


## Every optional puzzle (design/RETURN.md decision 4): the barn maze, the
## lookout relay, the flare gun found, every Memory Fragment.
func all_optional() -> bool:
	var maze := get_tree().get_first_node_in_group("barn_maze")
	var relay := get_tree().get_first_node_in_group("lookout_relay")
	var maze_ok: bool = maze != null and bool(maze.get("chest_open"))
	var relay_ok: bool = relay != null and bool(relay.get("opened"))
	var frags_ok := not _fragments.is_empty()
	for id in _fragments:
		frags_ok = frags_ok and id in _story.collected
	return maze_ok and relay_ok and _flag("flare_gun_found") and frags_ok


func _tower_view() -> void:
	if _flag("tower_view"):
		return
	var deck: Vector3 = get_tree().current_scene.get("builder").poi.get("end_tower_deck", Vector3.INF)
	for n in get_tree().get_nodes_in_group("player"):
		var pl := n as Node3D
		if pl.global_position.distance_to(deck) < 4.0:
			_story.flags["tower_view"] = true
			var dark := 0
			for l in lights:
				var on := true
				if _optional.has(l):
					match String(_optional[l]):
						"maze":
							var m := get_tree().get_first_node_in_group("barn_maze")
							on = m != null and bool(m.get("chest_open"))
						"relay":
							var r := get_tree().get_first_node_in_group("lookout_relay")
							on = r != null and bool(r.get("opened"))
						"flare":
							on = _flag("flare_gun_found")
				l.visible = on
				if not on:
					dark += 1
			var text := "From the top you can see the whole way you came: a small warm light stands over every place it happened, from the windmill to the mast."
			if dark > 0:
				text += " Some lights out there are still dark."
			_tell(text, 9.0)
			return


func _near_home(delta: float, boot: Node, van: Camper) -> void:
	if _flag("end_reached"):
		return
	var poi: Dictionary = boot.get("builder").poi
	for k in ["homestead", "p2_home"]:
		if poi.has(k) and van.global_position.distance_to(poi[k]) < END_NEAR:
			_story.flags["end_reached"] = true
			for who in 2:
				_story._send_phone(who, "Location sharing", "Naresh has left his house, heading to LiveStander.")
			_tell("Both your phones buzz at once.\n\nLocation sharing: Naresh has left his house, heading to LiveStander.", 8.0)
			var tw := create_tween()
			tw.tween_interval(9.0)
			tw.tween_callback(show_end)
			return


func show_end() -> void:
	if _end != null:
		return
	_end_t = 0.0
	_end = CanvasLayer.new()
	_end.layer = 90
	_end.name = "EndScreen"
	get_tree().current_scene.add_child(_end)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_end.add_child(bg)
	var lbl := Label.new()
	lbl.text = "FINDING NARESH\nBessi and the 5 Roses\n\nEnd of part one\n\n\nPart two: LiveStander\n\n\n(E / A to go back to the title)"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 34)
	lbl.modulate = Color(1, 1, 1, 0)
	_end.add_child(lbl)
	var tw := create_tween()
	tw.tween_property(bg, "color:a", 1.0, 3.0)
	tw.tween_property(lbl, "modulate:a", 1.0, 2.0)


func _unhandled_input(ev: InputEvent) -> void:
	if _end == null or _end_t < 5.0:
		return
	var go: bool = (ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_E) or \
		(ev is InputEventJoypadButton and ev.pressed and (ev as InputEventJoypadButton).button_index == JOY_BUTTON_A)
	if go:
		get_tree().reload_current_scene()


func _tell(text: String, secs: float) -> void:
	for n in get_tree().get_nodes_in_group("player"):
		(n as PlayerRig).say(text, secs)


## After a load or a story jump.
func match_story() -> void:
	if _story == null:
		_story = get_tree().get_first_node_in_group("story") as Story
	if _story == null:
		return
	_stage = 5 if _flag("naresh_home_done") else 0
	_t = 0.0
	var nz: Naresh = get_tree().current_scene.get("naresh")
	if nz != null and is_instance_valid(nz):
		var home := _flag("naresh_home_done")
		nz.visible = not home
		nz.process_mode = Node.PROCESS_MODE_DISABLED if home else Node.PROCESS_MODE_INHERIT
		if home:
			nz.global_position = house + Vector3.UP * 0.3
	if _flag("naresh_home_done"):
		Creature.on_return = false
	_mother.visible = false
	_sister.visible = false
	if not _flag("tower_view"):
		for l in lights:
			l.visible = false
