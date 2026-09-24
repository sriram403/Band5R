class_name Ambience
extends Node

## The world's nature sound: a forest bed and birdsong (CC0 recordings, see
## CREDITS.md) under the existing wind, plus water where there is water. It is
## quieter inside the van. `liveliness` (0..1) is the hook for the story's mood
## curve: lower it and the birds fall silent first, then the forest.

const BED_DB := -17.0
const BIRDS_DB := -15.0
const CAB_DB := -9.0               ## muffling with everyone inside the van
const WATER_REACH := 70.0          ## metres at which a river or lake starts to be heard

var liveliness := 1.0
var _bed: AudioStreamPlayer
var _birds: AudioStreamPlayer
var _water: Array[NoiseLoop] = []
var _cab := 0.0


func _ready() -> void:
	_bed = _loop_player("res://audio/nature_forest.mp3", "ForestBed")
	_birds = _loop_player("res://audio/nature_birds.ogg", "Birds")


func _loop_player(path: String, nm: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.name = nm
	var s := load(path)
	if s is AudioStreamMP3:
		s = (s as AudioStreamMP3).duplicate()
		s.loop = true
	elif s is AudioStreamOggVorbis:
		s = (s as AudioStreamOggVorbis).duplicate()
		s.loop = true
	p.stream = s
	p.volume_db = -80.0
	add_child(p)
	if s != null:
		p.play()
	return p


## A babbling-water emitter; call while the world is being built.
func add_water(at: Vector3, parent: Node) -> void:
	var w := NoiseLoop.new()
	w.name = "Water%d" % _water.size()
	w.kind = NoiseLoop.Kind.WATER
	w.volume_db = -4.0
	w.position = at            # the world root sits at the origin (and is not in the tree yet)
	parent.add_child(w)
	_water.append(w)


func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("player")
	var seated := 0
	for p in players:
		if (p as PlayerRig).seat != null:
			seated += 1
	var in_cab := players.size() > 0 and seated == players.size()
	_cab = lerpf(_cab, 1.0 if in_cab else 0.0, clampf(delta * 2.0, 0.0, 1.0))
	var muffle := _cab * CAB_DB
	var birds := clampf(liveliness * 2.0 - 1.0, 0.0, 1.0)     # the birds go quiet first
	var bed := clampf(liveliness * 2.0, 0.0, 1.0)
	_bed.volume_db = BED_DB + muffle + linear_to_db(maxf(bed, 0.0001))
	_birds.volume_db = BIRDS_DB + muffle + linear_to_db(maxf(birds, 0.0001))
	for w in _water:
		var near := 1e9
		for p in players:
			near = minf(near, (p as Node3D).global_position.distance_to(w.global_position))
		w.target = 1.0 if near < WATER_REACH else 0.0
