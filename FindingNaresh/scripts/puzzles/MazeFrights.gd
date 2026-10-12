class_name MazeFrights
extends Node3D

## Puzzle #3 round 2 (the user, 2026-10-12): the frights of the barn maze's
## snow half (past the courtyard, while the snow lies). Never harmful; at most
## one every GAP seconds, never the same kind twice running.
## - The music box: a nursery tune, faint, louder the faster and more
##   carelessly you go (sprinting, whipping round); S11: when you stop and
##   listen it's louder on a wrong turn than on the way.
## - Quick turns: sprint round a corner, or spin / look back fast, and a
##   figure stands right in front of you for a moment.
## - Distractions on the ground (a doll, a red glove, a little shoe, a music
##   box): look at one a second or two, turn back, and something's there.
## - Sounds only: a crow off the hedge, a bucket clattering, three knocks on
##   wood, a door creaking, from the other side of the hedge.
## - S9 the one that follows: a scarecrow down the corridor, a cell nearer
##   each time you look away; never moves while watched.
## - S10 small footprints: fresh child-sized prints run ahead, and twice
##   they go the wrong way.
## - S13 a fright has a cost: caught running, you stumble and drop the flag.

const GAP := 10.0                ## s between frights
const SPRINTING := 5.5           ## m/s: running
const TURN_FAST := 1.0           ## rad within TURN_WINDOW, running: a corner
const SPIN := 2.0                ## rad within TURN_WINDOW: a spin / look back
const TURN_WINDOW := 0.45
const GAZE := 1.0                ## s looking at a distraction arms it
const FIGURE_S := 0.9            ## s a figure stays
const SOUND_GAP := Vector2(16.0, 32.0)

var enabled := true              ## tests switch the frights off for plain walks
var fired := 0                   ## frights so far (tests)
var last_kind := ""
var stumbles := 0

var maze: BarnMaze
var _gap_t := 0.0
var _sound_t := 20.0
var _yaws := {}                  ## player -> [[t, yaw], ...]
var _rush := {}                  ## player -> 0..1
var _last_pos := {}              ## player -> last frame's position
var _figures: Array[Node3D] = []
var _distractions: Array = []    ## {node, armed, gaze, done}
var _follower: Node3D
var _follow_cell := Vector2i(-1, -1)
var _unseen_t := 0.0
var _prints: MultiMeshInstance3D
var _music: AudioStreamPlayer
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func setup(m: BarnMaze) -> void:
	maze = m
	_rng.seed = 1012
	_build_figures()
	_build_distractions()
	_build_follower()
	_build_prints()
	_music = AudioStreamPlayer.new()
	var ws := load("res://audio/musicbox_1.wav") as AudioStreamWAV
	if ws != null:
		var loop := ws.duplicate() as AudioStreamWAV
		loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
		loop.loop_end = loop.data.size() / 2
		_music.stream = loop
	_music.volume_db = -60.0
	add_child(_music)


# --- where the walker is ---------------------------------------------------------

## Players in the snow half while the snow lies (or falls).
func in_snow_half(p: PlayerRig) -> bool:
	if p.seat != null or (maze.snow < 0.5 and not maze.snowing):
		return false
	var c := maze.cell_at(p.global_position)
	return c.x >= 0 and maze.is_back(c)


func _fwd(p: PlayerRig) -> Vector3:
	var f := -p.head.global_transform.basis.z
	return f.normalized()


func _looks_at(p: PlayerRig, at: Vector3, deg: float) -> bool:
	var to := at - p.head.global_position
	return _fwd(p).angle_to(to.normalized()) < deg_to_rad(deg)


# --- the figures ------------------------------------------------------------------

func _build_figures() -> void:
	# a mannequin in a yellow raincoat, a scarecrow with a sack face
	var a := Node3D.new()
	a.name = "FlashMannequin"
	var skin := ToonMat.make(Color(0.88, 0.84, 0.78))
	a.add_child(Build.box(Vector3(0.5, 1.0, 0.3), ToonMat.make(Color(0.85, 0.72, 0.15)), Vector3(0, 1.2, 0), Vector3.ZERO, "Coat"))
	a.add_child(Build.sphere(0.17, skin, Vector3(0, 1.88, 0), Vector3(1, 1.2, 1), "Head"))
	for s in [-1.0, 1.0]:
		a.add_child(Build.box(Vector3(0.1, 0.75, 0.1), skin, Vector3(s * 0.32, 1.25, 0.05), Vector3(-15, 0, 0), "Arm"))
		a.add_child(Build.box(Vector3(0.12, 0.7, 0.12), skin, Vector3(s * 0.12, 0.35, 0), Vector3.ZERO, "Leg"))
	var b := Node3D.new()
	b.name = "FlashScarecrow"
	var sack := ToonMat.make(Color(0.80, 0.68, 0.45))
	b.add_child(Build.cyl(0.05, 2.0, ToonMat.make(Color(0.4, 0.3, 0.2)), Vector3(0, 1.0, 0), Vector3.ZERO, 5, "Pole"))
	b.add_child(Build.box(Vector3(1.4, 0.08, 0.08), ToonMat.make(Color(0.4, 0.3, 0.2)), Vector3(0, 1.6, 0), Vector3.ZERO, "Arms"))
	b.add_child(Build.box(Vector3(0.6, 0.8, 0.3), ToonMat.make(Color(0.25, 0.12, 0.10)), Vector3(0, 1.3, 0), Vector3.ZERO, "Coat"))
	b.add_child(Build.sphere(0.24, sack, Vector3(0, 2.0, 0), Vector3.ONE, "Head"))
	for s in [-1.0, 1.0]:
		b.add_child(Build.box(Vector3(0.07, 0.07, 0.02), ToonMat.flat(Color(0.05, 0.05, 0.05)), Vector3(s * 0.08, 2.05, 0.23), Vector3.ZERO, "Eye"))
	b.add_child(Build.box(Vector3(0.2, 0.03, 0.02), ToonMat.flat(Color(0.05, 0.05, 0.05)), Vector3(0, 1.9, 0.23), Vector3.ZERO, "Mouth"))
	for f in [a, b]:
		f.visible = false
		f.top_level = true
		add_child(f)
		_figures.append(f)


## Room in front of `p`'s view for a figure (m), short of any hedge.
func room_ahead(p: PlayerRig) -> float:
	var dir := _fwd(p)
	dir.y = 0.0
	dir = dir.normalized()
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(p.head.global_position, p.head.global_position + dir * 2.6, 1, [p.get_rid()])
	var hit := space.intersect_ray(q)
	return 2.6 if hit.is_empty() else p.head.global_position.distance_to(hit["position"]) - 0.45


## A figure right in front of `p`'s view (short of any hedge), for a moment.
## Closer than ~1.8 m it's only a blur filling the view: then not now.
func flash(p: PlayerRig, kind: String) -> bool:
	if room_ahead(p) < 1.8:
		return false
	var f: Node3D = _figures[_rng.randi_range(0, _figures.size() - 1)]
	var dir := _fwd(p)
	dir.y = 0.0
	dir = dir.normalized()
	var dist := minf(2.6, room_ahead(p))
	var at := p.global_position + dir * dist
	at.y = maze.global_position.y
	f.global_transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), at)
	f.visible = true
	Sfx.play3d("sting", p.head.global_position, 2.0)
	_fired(kind)
	_cost(p)
	get_tree().create_timer(FIGURE_S).timeout.connect(func(): f.visible = false)
	print("[maze] fright '%s' at P%d" % [kind, p.index + 1])
	return true


func _fired(kind: String) -> void:
	fired += 1
	last_kind = kind
	_gap_t = GAP


## S13: caught by a fright while running, you stumble and drop the flag.
func _cost(p: PlayerRig) -> void:
	if Vector2(p.velocity.x, p.velocity.z).length() < SPRINTING:
		p.jolt()
		return
	stumbles += 1
	p.knock(-_fwd(p) * 1.5 + Vector3.UP * 1.5)
	if maze.has_flag(p):
		maze.drop_flag(p)
	p.say("You stumble back into the snow - and the flag's gone from your hand.", 3.0)


# --- the distractions ----------------------------------------------------------------

func _build_distractions() -> void:
	var kinds := ["doll", "glove", "shoe", "musicbox"]
	var k := 0
	# only in the snow half: spread along the way from past the courtyard
	var first := 0
	for i in maze.way.size():
		if maze.is_back(maze.way[i]):
			first = i
			break
	for f in [0.15, 0.4, 0.62, 0.85]:
		var i := clampi(first + int(f * (maze.way.size() - 1 - first)), first, maze.way.size() - 2)
		var c: Vector2i = maze.way[i]
		var n := Node3D.new()
		n.name = "Distraction_" + kinds[k]
		n.position = maze.cell_pos(c) + Vector3(_rng.randf_range(-0.8, 0.8), 0.1, _rng.randf_range(-0.8, 0.8))
		n.rotation.y = _rng.randf() * TAU
		match kinds[k]:
			"doll":
				n.add_child(Build.box(Vector3(0.18, 0.08, 0.32), ToonMat.make(Color(0.90, 0.55, 0.60)), Vector3(0, 0.04, 0), Vector3.ZERO, "Dress"))
				n.add_child(Build.sphere(0.08, ToonMat.make(Color(0.95, 0.88, 0.80)), Vector3(0, 0.07, 0.22), Vector3.ONE, "Head"))
			"glove":
				n.add_child(Build.box(Vector3(0.12, 0.04, 0.2), ToonMat.make(Color(0.85, 0.10, 0.10)), Vector3(0, 0.02, 0), Vector3(0, 0, 0), "Glove"))
			"shoe":
				n.add_child(Build.box(Vector3(0.08, 0.07, 0.17), ToonMat.make(Color(0.25, 0.35, 0.70)), Vector3(0, 0.035, 0), Vector3.ZERO, "Shoe"))
			"musicbox":
				n.add_child(Build.box(Vector3(0.2, 0.12, 0.14), ToonMat.make(Color(0.50, 0.28, 0.20), 0.004, 0.4, Color(0.3, 0.2, 0.05)), Vector3(0, 0.06, 0), Vector3.ZERO, "Box"))
		maze.add_child(n)
		_distractions.append({"node": n, "armed": false, "gaze": 0.0, "done": false})
		k += 1


func _check_distractions(p: PlayerRig, delta: float) -> void:
	for dd in _distractions:
		if dd["done"]:
			continue
		var at: Vector3 = (dd["node"] as Node3D).global_position
		if p.global_position.distance_to(at) > 7.0:
			continue
		if _looks_at(p, at, 14.0):
			dd["gaze"] = float(dd["gaze"]) + delta
			if float(dd["gaze"]) >= GAZE:
				dd["armed"] = true
		elif dd["armed"] and not _looks_at(p, at, 60.0) and _gap_t <= 0.0:
			if flash(p, "distraction"):
				dd["done"] = true


# --- S9 the one that follows -----------------------------------------------------------

func _build_follower() -> void:
	_follower = Node3D.new()
	_follower.name = "Follower"
	var sack := ToonMat.make(Color(0.70, 0.62, 0.48))
	_follower.add_child(Build.cyl(0.05, 2.2, ToonMat.make(Color(0.35, 0.28, 0.2)), Vector3(0, 1.1, 0), Vector3.ZERO, 5, "Pole"))
	_follower.add_child(Build.box(Vector3(1.5, 0.08, 0.08), ToonMat.make(Color(0.35, 0.28, 0.2)), Vector3(0, 1.7, 0), Vector3.ZERO, "Arms"))
	_follower.add_child(Build.box(Vector3(0.6, 0.85, 0.3), ToonMat.make(Color(0.12, 0.12, 0.14)), Vector3(0, 1.35, 0), Vector3.ZERO, "Coat"))
	_follower.add_child(Build.sphere(0.24, sack, Vector3(0, 2.1, 0), Vector3.ONE, "Head"))
	_follower.add_child(Build.cone(0.34, 0.4, ToonMat.make(Color(0.15, 0.12, 0.10)), Vector3(0, 2.4, 0), Vector3.ZERO, 10, "Hat"))
	_follower.visible = false
	maze.add_child(_follower)


func _place_follower(c: Vector2i, toward: Vector3) -> void:
	_follow_cell = c
	_follower.position = maze.cell_pos(c)
	var d := toward - _follower.global_position
	_follower.rotation.y = atan2(d.x, d.z)


func _follow(p: PlayerRig, delta: float) -> void:
	var pc := maze.cell_at(p.global_position)
	if _follow_cell.x < 0:
		# first sight: a few cells further along the way, down your corridor
		var i := maze.way.find(pc)
		if i < 0:
			return
		_place_follower(maze.way[mini(i + 5, maze.way.size() - 2)], p.global_position)
		_follower.visible = true
		return
	_follower.visible = true
	if _looks_at(p, _follower.global_position + Vector3.UP * 1.5, 70.0):
		_unseen_t = 0.0
		return
	_unseen_t += delta
	if _unseen_t < 1.5:
		return
	_unseen_t = 0.0
	var pth := maze.path(_follow_cell, pc)
	if pth.size() <= 3:
		return
	var nxt: Vector2i = pth[1]
	# never step into view
	if _looks_at(p, maze.global_transform * maze.cell_pos(nxt) + Vector3.UP * 1.5, 75.0):
		return
	_place_follower(nxt, p.global_position)


# --- S10 small footprints --------------------------------------------------------------

## Child-sized prints along the way through the snow half; at two junctions
## they turn off down a wrong turn (and the right way has none for a stretch).
func _build_prints() -> void:
	var pts: Array[Vector3] = []
	var way: Array[Vector2i] = maze.way
	var start := 0
	for i in way.size():
		if maze.is_back(way[i]):
			start = i
			break
	var detours := 0
	var skip := 0
	for i in range(start, way.size() - 1):
		var c: Vector2i = way[i]
		if detours < 2 and i > start + 3 and maze.neighbours(c).size() >= 3:
			# off down a wrong turn, to its end
			for n in maze.neighbours(c):
				if n != way[i + 1] and n != way[i - 1] and not n in way:
					var cur := n
					var prev := c
					pts.append(maze.cell_pos(c))
					for k in 5:
						pts.append(maze.cell_pos(cur))
						var nexts := maze.neighbours(cur).filter(func(x): return x != prev)
						if nexts.is_empty():
							break
						prev = cur
						cur = nexts[0]
					detours += 1
					skip = 3
					break
		if skip > 0:
			skip -= 1
			continue
		pts.append(maze.cell_pos(c))
	var xfs: Array[Transform3D] = []
	var side := 1.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		if a.distance_to(b) > BarnMaze.CELL * 1.5:
			continue
		var d := (b - a).normalized()
		var n := int(a.distance_to(b) / 0.45)
		for k in n:
			var at := a + d * (k * 0.45) + Vector3(-d.z, 0, d.x) * 0.09 * side + Vector3(0, 0.1, 0)
			side = -side
			xfs.append(Transform3D(Basis(Vector3.UP, atan2(d.x, d.z)), at))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var m := BoxMesh.new()
	m.size = Vector3(0.08, 0.01, 0.16)
	mm.mesh = m
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	_prints = MultiMeshInstance3D.new()
	_prints.name = "SmallPrints"
	_prints.multimesh = mm
	_prints.material_override = ToonMat.flat(Color(0.62, 0.66, 0.74))
	_prints.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_prints.visible = false
	maze.add_child(_prints)


# --- the music box ---------------------------------------------------------------------

func _update_music(walker: PlayerRig, delta: float) -> void:
	var target := -60.0
	if walker != null:
		var r: float = _rush.get(walker, 0.0)
		target = lerpf(-32.0, -6.0, r)
		# S11: standing still, a wrong turn sounds louder than the way
		var still := Vector2(walker.velocity.x, walker.velocity.z).length() < 0.5
		var c := maze.cell_at(walker.global_position)
		if still and c.x >= 0:
			target = maxf(target, -14.0 if not c in maze.way else -30.0)
	_music.volume_db = move_toward(_music.volume_db, target, 30.0 * delta)
	var on := _music.volume_db > -55.0 and not Sfx.muted
	if on and not _music.playing and _music.stream != null:
		_music.play()
	elif not on and _music.playing:
		_music.stop()


## How carelessly `p` moves: sprinting and whipping round raise it, standing
## still and looking let it fall.
func _update_rush(p: PlayerRig, dyaw: float, delta: float) -> void:
	var r: float = _rush.get(p, 0.0)
	var spd := Vector2(p.velocity.x, p.velocity.z).length()
	if spd > SPRINTING:
		r += 0.25 * delta
	if dyaw > TURN_FAST:
		r += 0.15
	if spd < 0.5:
		r -= 0.35 * delta
	else:
		r -= 0.04 * delta
	_rush[p] = clampf(r, 0.0, 1.0)


# --- the loop ---------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if maze == null:
		return
	_t += delta
	_gap_t = maxf(0.0, _gap_t - delta)
	_prints.visible = maze.snow > 0.5
	var walker: PlayerRig = null
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if not in_snow_half(p):
			_yaws.erase(p)
			continue
		walker = p
		var hist: Array = _yaws.get(p, [])
		# a teleport (out of the drain, F1) turns you round: not a spin
		var last: Vector3 = _last_pos.get(p, p.global_position)
		_last_pos[p] = p.global_position
		if last.distance_to(p.global_position) > 3.0:
			hist.clear()
		hist.append([_t, p.yaw])
		while hist.size() > 1 and _t - float(hist[0][0]) > TURN_WINDOW:
			hist.pop_front()
		_yaws[p] = hist
		var dyaw := absf(angle_difference(float(hist[0][1]), p.yaw))
		_update_rush(p, dyaw, delta)
		if not enabled:
			continue
		_follow(p, delta)
		_check_distractions(p, delta)
		if _gap_t > 0.0:
			continue
		var spd := Vector2(p.velocity.x, p.velocity.z).length()
		if dyaw > SPIN and last_kind != "spin":
			if flash(p, "spin"):
				hist.clear()
		elif spd > SPRINTING and dyaw > TURN_FAST and last_kind != "corner":
			if flash(p, "corner"):
				hist.clear()
		else:
			_sound_t -= delta
			if _sound_t <= 0.0 and spd > 0.5:
				_sound_t = _rng.randf_range(SOUND_GAP.x, SOUND_GAP.y)
				_sound(p)
	if walker == null or maze.snow_done and maze.snow < 0.5:
		_follower.visible = false
	_update_music(walker if enabled else null, delta)


## A sound from the other side of a hedge: a crow, a bucket, three knocks,
## a door creaking.
func _sound(p: PlayerRig) -> void:
	var kinds := ["crow", "bucket", "knocks", "creak"]
	var k: String = kinds[_rng.randi_range(0, kinds.size() - 1)]
	if k == last_kind:
		k = kinds[(kinds.find(k) + 1) % kinds.size()]
	var side := Vector3(-_fwd(p).z, 0, _fwd(p).x) * (1.0 if _rng.randf() < 0.5 else -1.0)
	var at := p.head.global_position + side * 4.0
	match k:
		"crow":
			Sfx.play3d("caw", at, 6.0)
		"bucket":
			Sfx.play3d("hit_metal", at, 6.0)
			get_tree().create_timer(0.25).timeout.connect(func(): Sfx.play3d("hit_metal_heavy", at, 4.0))
			get_tree().create_timer(0.6).timeout.connect(func(): Sfx.play3d("hit_metal", at, 2.0))
		"knocks":
			for i in 3:
				get_tree().create_timer(0.45 * i).timeout.connect(func(): Sfx.play3d("hit_wood_heavy", at, 6.0))
		"creak":
			Sfx.play3d("creak", at, 6.0, 0.1, 0.7)
	_fired(k)
	print("[maze] fright sound '%s' at P%d" % [k, p.index + 1])


func reset() -> void:
	fired = 0
	stumbles = 0
	last_kind = ""
	_gap_t = 0.0
	_sound_t = 20.0
	_rush.clear()
	_yaws.clear()
	_follow_cell = Vector2i(-1, -1)
	_follower.visible = false
	for dd in _distractions:
		dd["armed"] = false
		dd["gaze"] = 0.0
		dd["done"] = false
	for f in _figures:
		f.visible = false
	_music.stop()
	_music.volume_db = -60.0
