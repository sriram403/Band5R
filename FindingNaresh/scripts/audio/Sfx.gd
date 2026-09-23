class_name Sfx
extends RefCounted

## One-shot sound effects by name. Each name maps to a family of CC0 samples
## in res://audio (Kenney packs, see CREDITS.md); a random variant and a small
## pitch wobble are picked every time so repeats do not sound mechanical.

const FAMILIES := {
	"step_grass": "footstep_grass_", "step_road": "footstep_concrete_",
	"step_wood": "footstep_wood_", "step_gravel": "footstep0",
	"pickup": "handleSmallLeather", "drop": "dropLeather",
	"hit_metal": "impactMetal_light_", "hit_metal_heavy": "impactMetal_heavy_",
	"hit_wood": "impactWood_light_", "hit_wood_heavy": "impactWood_medium_",
	"hit_soft": "impactSoft_medium_", "bang": "impactPlate_heavy_",
	"creak": "creak", "latch": "metalLatch", "click": "metalClick",
	"door_open": "doorOpen_", "door_close": "doorClose_",
	"paper_open": "bookOpen", "paper_close": "bookClose", "stamp": "bookPlace", "page": "bookFlip",
	"bong": "bong_", "ui_move": "select_", "ui_ok": "confirmation_", "ui_back": "back_",
	"ui_error": "error_", "tick": "tick_", "pluck": "pluck_", "glass": "glass_",
}

static var _cache := {}
static var muted := false          ## the play-test can silence everything


static func streams(key: String) -> Array:
	if _cache.has(key):
		return _cache[key]
	var out := []
	var prefix: String = FAMILIES.get(key, key)
	var dir := DirAccess.open("res://audio")
	if dir != null:
		for f in dir.get_files():
			# exported builds list "x.ogg.import"; the resource is still "x.ogg"
			var name := f.trim_suffix(".import")
			if name.begins_with(prefix) and name.ends_with(".ogg"):
				var s := load("res://audio/" + name)
				if s != null and not out.has(s):
					out.append(s)
	_cache[key] = out
	return out


static func _pick(key: String) -> AudioStream:
	var list := streams(key)
	return list[randi() % list.size()] if list.size() > 0 else null


## Positional one-shot, heard by whoever is near.
static func play3d(key: String, at: Vector3, volume_db := 0.0, pitch_wobble := 0.08) -> void:
	if muted:
		return
	var s := _pick(key)
	var tree := Engine.get_main_loop() as SceneTree
	if s == null or tree == null:
		return
	var root := tree.get_first_node_in_group("world_root")
	if root == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_wobble, pitch_wobble)
	p.unit_size = 6.0
	p.max_distance = 60.0
	root.add_child(p)
	p.global_position = at
	p.finished.connect(p.queue_free)
	p.play()


## Non-positional (menus, notes, the journal).
static func play_ui(key: String, volume_db := -4.0) -> void:
	if muted:
		return
	var s := _pick(key)
	var tree := Engine.get_main_loop() as SceneTree
	if s == null or tree == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	tree.root.add_child(p)
	p.finished.connect(p.queue_free)
	p.play()
