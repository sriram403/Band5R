class_name TagMarker
extends Node3D

## A tag: "look here". Placed by a player with the tag action on whatever they
## are looking at; both players see it in the world (through walls), in the
## tagging player's colour, with the thing's name and, for each viewer, how far
## it is from them. One tag per player: a new one replaces the old. It follows
## things that move (a can, the van, a creature) and fades after LIFE seconds.

const LIFE := 20.0
const FADE := 3.0
## How far a tag reaches. Fixed in the tagging gym: the 150 m board is still a
## clear target at 1080p and the binoculars (4x) make 200 m useful.
const RANGE := 200.0
const RANGE_ZOOMED := 400.0       ## through the binoculars
const MASK := 1 | 2 | 4 | 8 | Carryable.LAYER    ## world, players, interactables, van, items

## player index -> its live marker
static var live := {}

var owner_index := 0
var color := Color.WHITE
var thing := "there"
var target: Node3D = null            ## what it is stuck to, if that can move
var local_offset := Vector3.ZERO
var age := 0.0
var _icon: Sprite3D
var _labels: Array[Label3D] = []     ## one per viewer, each on the other player's private layer


static func place(pl: PlayerRig, at: Vector3, hit: Object) -> TagMarker:
	var old = live.get(pl.index)     # untyped: it may be a freed instance
	if old != null and is_instance_valid(old):
		old.queue_free()
	var root := pl.get_tree().get_first_node_in_group("world_root")
	if root == null:
		return null
	var m := TagMarker.new()
	m.name = "Tag%d" % (pl.index + 1)
	m.owner_index = pl.index
	m.color = pl.body_color
	m.thing = name_for(hit, pl)
	var mover := _mover(hit)
	root.add_child(m)
	m.global_position = at
	if mover != null:
		m.target = mover
		m.local_offset = mover.global_transform.affine_inverse() * at
	live[pl.index] = m
	return m


## The live tag of player i, or null.
static func of(i: int) -> TagMarker:
	var m = live.get(i)
	if m == null or not is_instance_valid(m) or (m as Node).is_queued_for_deletion():
		return null
	return m as TagMarker


## A short name for what was tagged: a `tag_name` meta anywhere up the tree
## wins, then items name themselves; the ground is just "there".
static func name_for(hit: Object, by: PlayerRig = null) -> String:
	var n := hit as Node
	var depth := 0
	while n != null and depth < 6:
		if n.has_meta("tag_name"):
			return str(n.get_meta("tag_name"))
		if n is Carryable:
			return (n as Carryable).label()
		if n is Camper:
			return "the van"
		if n is PlayerRig:
			return "P%d" % ((n as PlayerRig).index + 1) if n != by else "here"
		if n.has_meta("prompt"):
			return "that"
		n = n.get_parent()
		depth += 1
	return "there"


static func _mover(hit: Object) -> Node3D:
	var n := hit as Node
	while n != null:
		if n is RigidBody3D or n is CharacterBody3D:
			return n as Node3D
		if n is StaticBody3D or n is Area3D:
			return null
		n = n.get_parent()
	return null


func _ready() -> void:
	_icon = Sprite3D.new()
	_icon.name = "Icon"
	_icon.texture = _diamond()
	_icon.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_icon.fixed_size = true
	_icon.no_depth_test = true
	_icon.shaded = false
	_icon.pixel_size = 0.0015        # 64 px texture -> about 36 px at 900 px tall
	_icon.offset = Vector2(0, 54)    # a pin: its point hovers just above the spot, never hiding it
	_icon.modulate = color
	_icon.render_priority = 10
	add_child(_icon)
	# The name and distance differ per viewer: each label lives on the OTHER
	# player's private layer, which only this viewer's camera draws.
	for viewer in 2:
		var l := Label3D.new()
		l.name = "Label%d" % (viewer + 1)
		l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		l.fixed_size = true
		l.no_depth_test = true
		l.font_size = 40
		l.outline_size = 8
		l.pixel_size = 0.0011            # about 17 px tall text, any distance
		l.offset = Vector2(0, 160)       # above the pin
		l.modulate = color.lightened(0.35)
		l.outline_modulate = Color(0, 0, 0, 0.8)
		l.render_priority = 11
		l.layers = 1 << (2 - viewer)
		add_child(l)
		_labels.append(l)
	Sfx.play_ui("tick", -6.0)


func _process(delta: float) -> void:
	age += delta
	if target != null:
		if is_instance_valid(target):
			global_position = target.global_transform * local_offset
		else:
			target = null
	if age >= LIFE:
		if live.get(owner_index) == self:
			live.erase(owner_index)
		queue_free()
		return
	var a := clampf((LIFE - age) / FADE, 0.0, 1.0)
	# a short pop when placed so the partner notices it appear
	var pop := 1.0 + 0.6 * maxf(0.0, 1.0 - age * 4.0)
	_icon.scale = Vector3.ONE * pop
	_icon.modulate.a = a
	var players := get_tree().get_nodes_in_group("player")
	for viewer in 2:
		var l := _labels[viewer]
		l.modulate.a = a
		l.outline_modulate.a = a * 0.8
		var who := "P%d" % (owner_index + 1)
		var dist := ""
		for p in players:
			if (p as PlayerRig).index == viewer:
				var d := (p as PlayerRig).global_position.distance_to(global_position)
				dist = "  %d m" % roundi(d)
		l.text = "%s: %s%s" % [who, thing, dist]


## Seconds left before it is gone.
func time_left() -> float:
	return maxf(0.0, LIFE - age)


func _diamond() -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	var c := s * 0.5
	for y in s:
		for x in s:
			var d := absf(x + 0.5 - c) + absf(y + 0.5 - c)
			var v := Color(0, 0, 0, 0)
			if d < c - 2.0:
				v = Color(1, 1, 1, 1) if d < c - 9.0 else Color(0.08, 0.08, 0.08, 1)
				if d < 10.0:
					v = Color(0.08, 0.08, 0.08, 1)     # hollow centre: the spot stays visible
			v.a *= clampf(c - 2.0 - d + 1.0, 0.0, 1.0)
			img.set_pixel(x, y, v)
	return ImageTexture.create_from_image(img)
