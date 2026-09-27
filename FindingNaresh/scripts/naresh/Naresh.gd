class_name Naresh
extends CharacterBody3D

## Naresh (design/NARESH.md): enthusiastic, confident, well-meaning,
## unreliable; the third pair of hands on the way home. The players give him
## jobs from a small wheel (PlayerRig, the command key V / D-pad Up): follow,
## wait, go and wait there, carry it, store it, refuel, hold it, work it, get
## in the back, get out. He walks like a player (gravity, slopes, crates in
## the way), finds his way round things on a small grid, and says what he's
## doing (text only). About every 3-6 minutes he does something by himself,
## good or bad, always announced 3 s before. Left alone (nobody within 12 m)
## the creatures can take him; he is left somewhere high and far away, and
## shouts until someone comes for him.
##
## States: IDLE (stands), FOLLOW (a player), GO (to a spot, then WAIT), WAIT,
## JOB (carry / store / refuel / hold / work / get_in), SEATED (the van's
## bench), ACT (a random act), TAKEN (waiting to be fetched), KNOCKED.

signal said(text: String)

enum State { IDLE, FOLLOW, GO, WAIT, JOB, SEATED, ACT, TAKEN, KNOCKED }

const WALK := 3.9
const JOG := 6.2
const FOLLOW_NEAR := 2.8          ## m; he stops this close behind whoever he follows
const FOLLOW_JOG := 9.0           ## m; further than this he jogs to catch up
const LEFT_BEHIND := 45.0         ## m; the one he follows drove off: he waits there
const ALONE := 12.0               ## m; nobody this close and the creatures can take him
const REACH := 1.3                ## m from where he stands to use something
const COMMAND_RANGE := 60.0       ## m; how far away he can be given a job
const HEAR := 40.0                ## m; players this close hear what he says
const ACT_GAP := Vector2(180.0, 360.0)   ## s between random acts (the user's 3-6 min)
const TELEGRAPH := 3.0            ## s from "Ooh, what's that?" to the act
const RETRY_ACT := 20.0           ## s before trying again when no act fits right now
const STAND_HEIGHT := 1.78
const GRAVITY := 22.0
const JUMP := 4.7
const CELL := 1.0                 ## m; the pathfinding grid
const PATH_RADIUS := 45.0         ## m; how far the grid search reaches
const FETCH := 9.0                ## m; a player this close to where he was left fetches him
const SHOUT_EVERY := 25.0         ## s between shouts while he waits to be fetched
const SUIT := Color(0.30, 0.62, 0.34)

var index := -1                   ## not a player (Carryable reads holders' .index)
var state: int = State.IDLE
var leader: PlayerRig = null      ## the player he follows (kept through jobs and rides)
var job := ""                     ## carry, store, refuel, hold, work, get_in
var job_target: Node = null
var _has_target := false          ## a freed target reads as null: remember there was one
var job_for: PlayerRig = null     ## who asked
var job_step := 0
var go_point := Vector3.ZERO
var held: Carryable = null
var yaw := 0.0
var van: Camper = null            ## the van he sits in (SEATED)
var pouring := false
var refuel_mistake := false       ## the scripted mistake: the next refuel uses the empty can
var act_gap := ACT_GAP
var act_t := 0.0                  ## s until the next random act
var acts_on := true
var act := ""                     ## the act running now (ACT state), or telegraphed
var act_good := true
var _tele_t := 0.0                ## > 0: an act has been announced and starts at 0
var _act_data := {}
var _last_good := false
var taken_near := ""              ## where he was left, while TAKEN
var knocked_t := 0.0
var sitting := false              ## cross-legged in the fifth rose, waiting (E4)
## What he said and did, for tests: [{"t": msec, "text": ...}], [{"id", "good", "tele", "start"}]
var lines: Array = []
var acts_log: Array = []

var _mesh_root: Node3D
var _pose_stand := {}
var _bubble: Label3D
var _bubble_t := 0.0
var _plan_vel := Vector2.ZERO
var _path := PackedVector3Array()
var _path_i := 0
var _path_goal := Vector3(INF, INF, INF)
var _cells := {}
var _stuck_t := 0.0
var _stuck_mark := Vector3.ZERO
var _jumped := false
var _shout_t := 0.0
var _pour_to: Vector3 = Vector3.ZERO
var _was_following := false
var _knock_van: PhysicsBody3D = null
var _step_phase := 0.0


func _ready() -> void:
	add_to_group("naresh")
	collision_layer = 2
	collision_mask = 1 | 8 | Carryable.LAYER
	floor_max_angle = deg_to_rad(52)
	floor_snap_length = 0.5
	set_meta("tag_name", "Naresh")
	_build()
	act_t = randf_range(act_gap.x, act_gap.y)
	yaw = rotation.y


func _build() -> void:
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = STAND_HEIGHT
	var cs := CollisionShape3D.new()
	cs.name = "Collider"
	cs.shape = cap
	cs.position = Vector3(0, STAND_HEIGHT * 0.5, 0)
	add_child(cs)
	_mesh_root = make_figure()
	add_child(_mesh_root)
	for m in _mesh_root.get_children():
		_pose_stand[m.name] = (m as Node3D).transform
	_bubble = Build.label3d("", Vector3(0, 2.25, 0), Vector3.ZERO, 0.16, Color(1, 1, 0.92))
	_bubble.name = "Speech"
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.fixed_size = true          # the same size on screen near or far (~17 px letters)
	_bubble.font_size = 48
	_bubble.outline_size = 10
	_bubble.pixel_size = 0.0006
	_bubble.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble.width = 620.0
	_bubble.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM   # grows upwards, clear of his head
	_bubble.offset = Vector2(0, 40)
	# close by the subtitle says it; the bubble shows who, from further off
	_bubble.visibility_range_begin = 7.0
	_bubble.visible = false
	add_child(_bubble)


## His body on its own (no physics, no mind): the same block-out as the
## players, taller, in green, with a red cap. Also stands in his photo (E3).
static func make_figure() -> Node3D:
	var root := Node3D.new()
	root.name = "Avatar"
	var suit := ToonMat.make(SUIT, 0.018)
	var skin := ToonMat.make(Color(0.78, 0.58, 0.42), 0.018)
	var legs := ToonMat.make(Color(0.30, 0.26, 0.22), 0.018)
	root.add_child(Build.cyl(0.28, 1.08, suit, Vector3(0, 0.64, 0), Vector3.ZERO, 10, "Torso"))
	root.add_child(Build.sphere(0.22, skin, Vector3(0, 1.41, 0), Vector3.ONE, "Head"))
	root.add_child(Build.cyl(0.24, 0.10, ToonMat.make(Color(0.85, 0.25, 0.22), 0.018), Vector3(0, 1.58, 0), Vector3.ZERO, 12, "Cap"))
	root.add_child(Build.box(Vector3(0.16, 0.72, 0.16), suit, Vector3(-0.34, 0.78, 0), Vector3.ZERO, "ArmL"))
	root.add_child(Build.box(Vector3(0.16, 0.72, 0.16), suit, Vector3(0.34, 0.78, 0), Vector3.ZERO, "ArmR"))
	root.add_child(Build.box(Vector3(0.18, 0.64, 0.18), legs, Vector3(-0.13, 0.16, 0), Vector3.ZERO, "LegL"))
	root.add_child(Build.box(Vector3(0.18, 0.64, 0.18), legs, Vector3(0.13, 0.16, 0), Vector3.ZERO, "LegR"))
	return root


# --- talking -----------------------------------------------------------------------

## A line over his head, and on the screen of every player who can hear it
## (close by, or in the van with him). `shout` reaches everyone.
func say(text: String, shout := false) -> void:
	lines.append({"t": Time.get_ticks_msec(), "text": text})
	said.emit(text)
	_bubble.text = text
	_bubble.visible = true
	_bubble_t = 4.0
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		var near := p.global_position.distance_to(global_position) < HEAR
		var together: bool = van != null and p.vehicle == van
		if shout or near or together:
			p.hear("Naresh", text)


## True if he said something containing `part` since `since_ms`.
func said_since(part: String, since_ms: int) -> bool:
	for l in lines:
		if int(l["t"]) >= since_ms and String(l["text"]).contains(part):
			return true
	return false


const OK_LINES := ["On it!", "OK!", "Sure thing.", "Leave it to me.", "Easy."]

func _ok(extra := "") -> void:
	var t: String = OK_LINES[randi() % OK_LINES.size()]
	if randf() < 0.2:
		t = "My friend says that's a bad idea, but OK."
	say(t + ("  " + extra if extra != "" else ""))


# --- being told what to do -------------------------------------------------------

## The jobs that make sense for what `p` is looking at: [{"id", "label"}].
## `col` is what their view ray hit (or this node), `point` where.
func jobs_for(p: PlayerRig, col: Object, _point: Vector3) -> Array:
	if state == State.TAKEN:
		return []
	var out: Array = []
	if col == self:
		if state == State.SEATED:
			out.append({"id": "get_out", "label": "Get out"})
			out.append({"id": "follow", "label": "Get out and follow me"})
			return out
		if job == "hold" and state == State.JOB:
			out.append({"id": "let_go", "label": "Let go"})
		if state != State.FOLLOW or leader != p:
			out.append({"id": "follow", "label": "Follow me"})
		out.append({"id": "wait", "label": "Wait here"})
		return out
	var n := col as Node
	var item: Carryable = null
	var work: Workable = null
	var camper: Camper = null
	var filler := false
	while n != null:
		if n is Carryable and item == null:
			item = n
		if n is Workable and work == null:
			work = n
		if n.name == "FuelInlet":
			filler = true
		if n is Camper:
			camper = n
			break
		n = n.get_parent()
	if item != null and item.stowed_in == null:
		for h in item.holders:
			if h is PlayerRig:
				return []
		if item is FuelCan and (item as FuelCan).litres > 0.05 and _the_van() != null:
			out.append({"id": "refuel", "label": "Refuel the van with it"})
		out.append({"id": "carry", "label": "Bring it to me"})
		if _the_van() != null:
			out.append({"id": "store", "label": "Store it on the van"})
		return out
	if item != null and item.stowed_in != null and item is FuelCan and (item as FuelCan).litres > 0.05:
		out.append({"id": "refuel", "label": "Refuel the van with it"})
		out.append({"id": "carry", "label": "Bring it to me"})
		return out
	if work != null:
		if job == "hold" and job_target == work and state == State.JOB:
			out.append({"id": "let_go", "label": "Let go of it"})
		elif work.kind == "hold":
			out.append({"id": "hold", "label": "Hold the %s" % work.label})
		else:
			out.append({"id": "work", "label": "Work the %s" % work.label})
		return out
	if camper != null:
		if filler and _rack_can(camper, false) != null:
			out.append({"id": "refuel", "label": "Refuel the van"})
		if state == State.SEATED:
			out.append({"id": "get_out", "label": "Get out"})
		else:
			out.append({"id": "get_in", "label": "Get in the back"})
		return out
	out.append({"id": "go", "label": "Go and wait there"})
	return out


## Give him a job (from the wheel). The last command wins.
func command(p: PlayerRig, id: String, target: Node = null, point := Vector3.ZERO) -> void:
	if state == State.TAKEN:
		say("I can't get down! Come and get me!", true)
		return
	if state == State.KNOCKED:
		return
	_cancel_act(false)
	var was_seated := state == State.SEATED
	_end_job()
	job_for = p
	match id:
		"follow":
			leader = p
			if was_seated and p.vehicle == van:
				state = State.SEATED     # you're in here with me already
				say("Right behind you. Well, next to my friend.")
				return
			if was_seated:
				_get_out()
			state = State.FOLLOW
			_ok()
		"wait":
			leader = null
			state = State.WAIT
			say("I'll wait here.")
		"go":
			leader = null
			if was_seated:
				_get_out()
			go_point = point
			state = State.GO
			_ok()
		"get_out":
			if was_seated:
				_get_out()
				state = State.WAIT
				say("Out I get.")
		"let_go":
			say("Letting go!")
			state = State.FOLLOW if leader != null else State.IDLE
		"carry", "store", "refuel", "hold", "work", "get_in":
			if was_seated and id != "get_in":
				_get_out()
			_was_following = leader != null
			job = id
			job_target = target
			_has_target = target != null
			job_step = 0
			state = State.JOB
			if id == "get_in" and was_seated:
				state = State.SEATED
				job = ""
				say("I'm already in!")
				return
			_ok()


## Finish or drop the current job: let go of what he holds / works.
func _end_job() -> void:
	if state == State.JOB and job == "hold" and is_instance_valid(job_target):
		(job_target as Workable).release_by(self)
	if held != null and job != "":
		drop_held()
	pouring = false
	job = ""
	job_target = null
	_has_target = false
	job_step = 0
	_path = PackedVector3Array()


## A job is over: back to following whoever he was following, else stand.
func _job_done(line: String) -> void:
	print("[naresh] %s ends at step %d: \"%s\"" % [job, job_step, line])
	if line != "":
		say(line)
	_end_job()
	state = State.FOLLOW if _was_following and leader != null else State.IDLE


func _job_failed(line: String) -> void:
	_job_done(line)


# --- the frame ---------------------------------------------------------------------

var _last_state := -1
var _last_step := -1

func _physics_process(delta: float) -> void:
	if sitting:
		if _bubble_t > 0.0:
			_bubble_t -= delta
			if _bubble_t <= 0.0:
				_bubble.visible = false
		velocity = Vector3.ZERO
		return
	if state != _last_state:
		print("[naresh] %s -> %s (job '%s' step %d)" % [State.keys()[_last_state] if _last_state >= 0 else "-", State.keys()[state], job, job_step])
		_last_state = state
	if _bubble_t > 0.0:
		_bubble_t -= delta
		if _bubble_t <= 0.0:
			_bubble.visible = false
	if _knock_van != null and is_instance_valid(_knock_van) and _knock_van.global_position.distance_to(global_position) > 5.0:
		remove_collision_exception_with(_knock_van)
		_knock_van = null
	match state:
		State.KNOCKED:
			_knocked(delta)
			return
		State.SEATED:
			_seated(delta)
		State.TAKEN:
			_taken_wait(delta)
		State.IDLE, State.WAIT:
			_stand(delta)
		State.FOLLOW:
			_follow(delta)
		State.GO:
			if _walk_to(go_point, WALK, 0.8, delta):
				state = State.WAIT
				say("Here?")
		State.JOB:
			_do_job(delta)
		State.ACT:
			_do_act(delta)
	_random_acts(delta)


func _stand(delta: float) -> void:
	_move(Vector3.ZERO, delta)


func _follow(delta: float) -> void:
	if leader == null or not is_instance_valid(leader):
		state = State.IDLE
		return
	# they got into the van: in the back with them
	if leader.seat != null and leader.vehicle != null:
		var v: Camper = leader.vehicle
		if _flat_dist(v.global_position) > LEFT_BEHIND and v.linear_velocity.length() > 2.0:
			say("Hey! Wait for me!", true)
			leader = null
			state = State.WAIT
			return
		if _walk_to(_door_point(v), JOG if _flat_dist(v.global_position) > FOLLOW_JOG else WALK, 0.9, delta):
			_sit(v)
		return
	var to := leader.global_position - global_position
	to.y = 0.0
	if to.length() > FOLLOW_NEAR + 0.6:
		_walk_to(leader.global_position, JOG if to.length() > FOLLOW_JOG else WALK, FOLLOW_NEAR, delta)
	else:
		_path = PackedVector3Array()
		_face(leader.global_position, delta)
		_move(Vector3.ZERO, delta)


# --- jobs ---------------------------------------------------------------------

func _do_job(delta: float) -> void:
	if job_step != _last_step:
		print("[naresh] %s step %d (target %s, holding %s)" % [job, job_step, job_target.name if is_instance_valid(job_target) else "-", held.name if held else "-"])
		_last_step = job_step
	if _has_target and not is_instance_valid(job_target):
		_job_failed("Where did it go? It's gone.")
		return
	match job:
		"carry": _job_carry(delta)
		"store": _job_store(delta)
		"refuel": _job_refuel(delta)
		"hold": _job_hold(delta)
		"work": _job_work(delta)
		"get_in": _job_get_in(delta)
		_: _job_done("")


## Walk to an item and pick it up: 1 once it's in his hands, 0 on the way,
## -1 if a player has it now.
func _fetch(item: Carryable, delta: float) -> int:
	if held == item:
		return 1
	for h in item.holders:
		if h is PlayerRig:
			return -1
	if _walk_to(item.global_position, WALK, REACH, delta):
		pick_up(item)
		return 1 if held == item else 0
	return 0


## `_fetch` inside a job: false (and the job over) if someone else has it.
func _fetch_job(item: Carryable, delta: float) -> bool:
	var r := _fetch(item, delta)
	if r < 0:
		_job_failed("Oh, you've got it already.")
	return r == 1


func _job_carry(delta: float) -> void:
	var item := job_target as Carryable
	if item == null:
		_job_failed("")
		return
	if job_step == 0:
		if _fetch_job(item, delta):
			job_step = 1
		return
	if held != item:
		_job_failed("I dropped it.")
		return
	var who := job_for
	if who == null:
		_job_done("")
		return
	var at := who.global_position
	if who.seat != null and who.vehicle != null:
		at = _door_point(who.vehicle)
	if _walk_to(at, WALK, 1.7, delta):
		drop_held()
		if who.held == null and who.seat == null:
			who.pick_up(item)
			_job_done("Here you go.")
		else:
			_job_done("I'll put it down here.")


func _job_store(delta: float) -> void:
	var item := job_target as Carryable
	var v := _the_van()
	if item == null or v == null:
		_job_failed("Where's the van?")
		return
	if item.stowed_in != null and held != item:
		_job_done("It's on the rack already.")
		return
	if job_step == 0:
		if _fetch_job(item, delta):
			job_step = 1
		return
	if held != item:
		_job_failed("I dropped it.")
		return
	if _walk_to(v.rack_stand(), WALK, 0.8, delta):
		var slot := v.free_slot_for(item)
		if slot == null:
			drop_held()
			_job_done("The rack's full. I've left it by the van.")
			return
		_stow(item, slot)
		_job_done("On the rack.")


## Refuel: take the can (off the rack if it's there), pour it in at the filler,
## put the can back on the rack. With `refuel_mistake` armed he picks up the
## other, empty can instead, "pours" nothing and puts both back on the rack.
func _job_refuel(delta: float) -> void:
	var v := _the_van()
	if v == null:
		_job_failed("Where's the van?")
		return
	var can := job_target as FuelCan
	if job_step == 0:
		if can == null:
			can = _rack_can(v, false)
			if can == null:
				_job_failed("There's no fuel on the rack.")
				return
		if refuel_mistake:
			var wrong := _empty_can_near(v, can)
			if wrong != null:
				_act_data["mistake_full"] = can
				can = wrong
		job_target = can
		_has_target = true
		job_step = 1
		return
	if can == null:
		_job_failed("")
		return
	if job_step == 1:
		if _fetch_job(can, delta):
			job_step = 2
		return
	if job_step in [2, 3, 4] and held != can:
		_job_failed("I dropped it.")
		return
	if job_step == 2:
		if _walk_to(v.filler_stand(), WALK, 0.6, delta):
			job_step = 3
			_act_data["pour_t"] = 0.0
			_face(v.filler_point(), 1.0)
		return
	if job_step == 3:
		_face(v.filler_point(), delta)
		_move(Vector3.ZERO, delta)
		pouring = true
		held.pouring = true
		_pour_to = v.filler_point()
		var got := v.pour_fuel(can, delta)
		_act_data["pour_t"] = float(_act_data.get("pour_t", 0.0)) + delta
		# the mistake: nothing comes out of the empty can; he "checks it twice"
		var mistake := _act_data.has("mistake_full")
		var give_up := float(_act_data["pour_t"]) > (4.0 if mistake else 0.5) and got <= 0.0005
		if can.litres <= 0.05 and not mistake or v.fuel >= Camper.FUEL_CAPACITY - 0.1 or give_up:
			pouring = false
			held.pouring = false
			job_step = 4
		return
	if job_step == 4:
		# the can goes back on the rack
		if _walk_to(v.rack_stand(), WALK, 0.8, delta):
			var slot := v.free_slot_for(can)
			if slot != null:
				_stow(can, slot)
			else:
				drop_held()
			var full: FuelCan = _act_data.get("mistake_full")
			if full != null and is_instance_valid(full):
				job_step = 5
				job_target = full
				_has_target = true
				return
			_act_data.clear()
			_job_done("Tank's topped up!" if v.fuel >= Camper.FUEL_CAPACITY - 0.1 else "Done. The can's empty.")
		return
	if job_step == 5:
		# the full one onto the rack too, so it looks as if it was never touched
		var full := job_target as FuelCan
		if full.stowed_in != null:
			_mistake_done()
			return
		if held != full:
			_fetch_job(full, delta)
			return
		if _walk_to(v.rack_stand(), WALK, 0.8, delta):
			var slot := v.free_slot_for(full)
			if slot != null:
				_stow(full, slot)
			else:
				drop_held()
			_mistake_done()


func _mistake_done() -> void:
	refuel_mistake = false
	_act_data.clear()
	_job_done("Done. I even checked it twice.")


func _job_hold(delta: float) -> void:
	var w := job_target as Workable
	if w == null:
		_job_failed("")
		return
	if job_step == 0:
		if _walk_to(w.stand_point(), WALK, 0.6, delta):
			job_step = 1
			say("Got it! Go on, I've got it.")
		return
	_face(w.global_position, delta)
	_move(Vector3.ZERO, delta)
	w.work_by(self, delta)


func _job_work(delta: float) -> void:
	var w := job_target as Workable
	if w == null:
		_job_failed("")
		return
	if w.is_done:
		_job_done("It's done!" if job_step > 0 else "That's already done.")
		return
	if job_step == 0:
		if _walk_to(w.stand_point(), WALK, 0.6, delta):
			job_step = 1
		return
	_face(w.global_position, delta)
	_move(Vector3.ZERO, delta)
	w.work_by(self, delta)


func _job_get_in(delta: float) -> void:
	var v := _the_van()
	if v == null:
		_job_failed("Where's the van?")
		return
	if _walk_to(_door_point(v), WALK, 0.9, delta):
		_sit(v)
		job = ""
		job_target = null
		say("Comfy. There's room for my friend too.")


# --- the van's bench ----------------------------------------------------------------

func _the_van() -> Camper:
	if van != null:
		return van
	var best: Camper = null
	for c in get_tree().get_nodes_in_group("camper"):
		if best == null or (c as Node3D).global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
			best = c
	return best


## Where he gets in: by the passenger door, a step behind it.
func _door_point(v: Camper) -> Vector3:
	return v.global_transform * Vector3(2.0, -0.6, -0.9)


func _sit(v: Camper) -> void:
	if held != null:
		drop_held()
	van = v
	state = State.SEATED
	(get_node("Collider") as CollisionShape3D).disabled = true
	velocity = Vector3.ZERO
	_plan_vel = Vector2.ZERO
	_path = PackedVector3Array()
	v.bench_by = self
	_set_seated_pose(true)
	_follow_bench()
	reset_physics_interpolation()
	Sfx.play3d("door_close", global_position, -6.0)
	Hearing.emit(v.global_position, Hearing.DOOR, "door")


func _get_out() -> void:
	if van == null:
		return
	var v := van
	var at := v.global_transform * Vector3(2.1, 0.2, -0.2)
	var space := get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 3.0, at + Vector3.DOWN * 6.0, 1, [v.get_rid()])
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		at = (hit["position"] as Vector3) + Vector3.UP * 0.1
	v.bench_by = null
	van = null
	_set_seated_pose(false)
	yaw = v.global_rotation.y + PI * 0.5
	global_transform = Transform3D(Basis(Vector3.UP, yaw), at)
	velocity = v.linear_velocity
	(get_node("Collider") as CollisionShape3D).disabled = false
	reset_physics_interpolation()
	Sfx.play3d("door_open", global_position, -6.0)
	Hearing.emit(v.global_position, Hearing.DOOR, "door")
	state = State.IDLE


func _seated(_delta: float) -> void:
	if van == null or not is_instance_valid(van):
		state = State.IDLE
		return
	_follow_bench()
	velocity = Vector3.ZERO
	# whoever he follows got out and walked off: out he gets, after them
	if leader != null and leader.seat == null and van.linear_velocity.length() < 1.0 \
			and leader.global_position.distance_to(van.global_position) > 4.0:
		_get_out()
		state = State.FOLLOW


func _follow_bench() -> void:
	var b := van.bench
	global_transform = Transform3D(b.global_transform.basis, b.global_position)
	yaw = b.global_rotation.y


## The players' seated pose (PlayerRig.SEATED_POSE), hips on the bench.
func _set_seated_pose(on: bool) -> void:
	for m in _mesh_root.get_children():
		var nd := m as Node3D
		if on and PlayerRig.SEATED_POSE.has(nd.name):
			var p: Array = PlayerRig.SEATED_POSE[nd.name]
			var e: Vector3 = p[1]
			nd.transform = Transform3D(Basis.from_euler(e * (PI / 180.0)).scaled(p[2]), p[0])
		elif on and nd.name == "Cap":
			nd.transform = Transform3D(Basis.from_scale(Vector3(0.72, 0.72, 0.72)), Vector3(0, 0.73, 0.02))
		elif _pose_stand.has(nd.name):
			nd.transform = _pose_stand[nd.name]


# --- in the fifth rose (E4) ---------------------------------------------------------

## Sat still at `xf` (the rose's plinth), no collisions, no random acts,
## until someone comes (Roses calls stand_from_seat).
func sit_at(xf: Transform3D) -> void:
	_cancel_act(false)
	_end_job()
	if van != null:
		_get_out()
	leader = null
	state = State.IDLE
	sitting = true
	acts_on = false
	global_transform = xf
	yaw = xf.basis.get_euler().y
	(get_node("Collider") as CollisionShape3D).disabled = true
	_set_seated_pose(true)
	reset_physics_interpolation()


## Up and down off the plinth, beside `p`, following them.
func stand_from_seat(p: PlayerRig) -> void:
	if not sitting:
		return
	sitting = false
	_set_seated_pose(false)
	var dir := p.global_position - global_position
	dir.y = 0.0
	var at := global_position + dir.normalized() * minf(dir.length() - 1.5, 5.5)
	var q := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 4.0, at + Vector3.DOWN * 8.0, 1, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	at.y = (hit["position"] as Vector3).y + 0.1 if not hit.is_empty() else Landscape.ground(at.x, at.z) + 0.1
	global_position = at
	(get_node("Collider") as CollisionShape3D).disabled = false
	reset_physics_interpolation()
	leader = p
	state = State.FOLLOW
	acts_on = true
	act_t = randf_range(act_gap.x, act_gap.y)


# --- holding things (the Carryable interface, like a player's) --------------------

func pick_up(item: Carryable) -> void:
	if held != null or not item.holders.is_empty():
		return
	held = item
	item.grab(self)
	Sfx.play3d("pickup", item.global_position, -6.0)


func drop_held() -> void:
	if held == null:
		return
	var it := held
	held = null
	pouring = false
	it.pouring = false
	it.release(self)
	Sfx.play3d("drop", it.global_position, -8.0)


## Onto a rack slot out of his hands (let go properly first, or the item
## still counts him as holding it and nobody can pick it up again).
func _stow(item: Carryable, slot: Node3D) -> void:
	if held == item:
		held = null
		pouring = false
		item.pouring = false
		item.release(self)
	item.stow(slot)
	Sfx.play3d("drop", item.global_position, -8.0)


func hold_point(item: Carryable) -> Vector3:
	if pouring and item.pouring:
		return _pour_to + Vector3.UP * 0.25
	var b := Basis(Vector3.UP, yaw)
	if item.two_handed:
		return global_position + b * Vector3(0, 0.9, -1.0)
	return global_position + b * Vector3(0.36, lerpf(1.05, 0.8, item.heaviness()), -0.55)


# --- walking ------------------------------------------------------------------------

## Walk towards `goal` (round things in the way). True once within `arrive`.
func _walk_to(goal: Vector3, speed: float, arrive: float, delta: float) -> bool:
	var to := goal - global_position
	to.y = 0.0
	if to.length() <= arrive:
		_path = PackedVector3Array()
		_move(Vector3.ZERO, delta)
		_stuck_t = 0.0
		return true
	if _path.is_empty() or _path_goal.distance_to(goal) > 1.5:
		_plan(goal)
	var aim := goal
	if not _path.is_empty():
		# skip ahead to the furthest point in plain view
		while _path_i < _path.size() - 1 and _clear(global_position, _path[_path_i + 1]):
			_path_i += 1
		aim = _path[_path_i]
		var d := aim - global_position
		d.y = 0.0
		if d.length() < 0.6 and _path_i < _path.size() - 1:
			_path_i += 1
			aim = _path[_path_i]
	var dir := aim - global_position
	dir.y = 0.0
	_face(global_position + dir, delta)
	_move(dir.normalized() * speed if dir.length() > 0.05 else Vector3.ZERO, delta)
	# stuck: jump once, plan again; still stuck: give up on it
	_stuck_t += delta
	if _stuck_t > 1.2:
		if global_position.distance_to(_stuck_mark) < 0.3:
			if not _jumped and is_on_floor():
				velocity.y = JUMP
				_jumped = true
				_path = PackedVector3Array()
				_cells.clear()
			else:
				_stuck_long(goal)
		else:
			_jumped = false
		_stuck_mark = global_position
		_stuck_t = 0.0
	return false


var _stuck_count := 0

func _stuck_long(goal: Vector3) -> void:
	_stuck_count += 1
	_path = PackedVector3Array()
	_cells.clear()
	if _stuck_count < 4:
		return
	_stuck_count = 0
	_jumped = false
	if state == State.FOLLOW and leader != null:
		# never lost for good: he turns up a few steps behind you
		var back := leader.global_transform.basis.z
		back.y = 0.0
		var at := leader.global_position + back.normalized() * 2.5
		at.y = Landscape.ground(at.x, at.z) + 0.2
		global_position = at
		reset_physics_interpolation()
		say("Found a way round!")
		return
	if state == State.JOB:
		_job_failed("I can't get there.")
	elif state == State.GO:
		state = State.WAIT
		say("I can't get any closer than this.")
	elif state == State.ACT:
		_cancel_act(true)
	var _g := goal


func _move(dir: Vector3, delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	var accel := 12.0 if is_on_floor() else 5.0
	_plan_vel = _plan_vel.move_toward(Vector2(dir.x, dir.z), accel * delta * 6.0)
	velocity.x = _plan_vel.x
	velocity.z = _plan_vel.y
	move_and_slide()
	rotation.y = yaw
	# walking into loose things nudges them, as for the players
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var rb := hit.get_collider() as RigidBody3D
		if rb != null and not rb.freeze and rb != held and not rb is VehicleBody3D:
			var push := -hit.get_normal()
			push.y = 0.0
			rb.apply_central_impulse(push.normalized() * 55.0 * delta)
	var planar := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and planar > 0.8:
		_step_phase += delta * planar * 0.55
		if _step_phase >= 1.0:
			_step_phase -= 1.0
			Sfx.play3d("step_grass", global_position, -12.0 + minf(planar, 6.0))
			Hearing.emit(global_position, Hearing.WALK_STEP if planar < WALK + 0.5 else Hearing.SPRINT_STEP, "step")
	# the safety net: never under the ground
	var g := Landscape.ground(global_position.x, global_position.z)
	if global_position.y < g - 3.0:
		global_position.y = g + 0.5
		velocity = Vector3.ZERO
		reset_physics_interpolation()


func _face(at: Vector3, delta: float) -> void:
	var d := at - global_position
	if Vector2(d.x, d.z).length() < 0.05:
		return
	yaw = lerp_angle(yaw, atan2(-d.x, -d.z), 1.0 - exp(-delta * 9.0))
	rotation.y = yaw


func _flat_dist(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()


## A clear walk from a to b: rays at knee and chest height, and at the sides.
func _clear(a: Vector3, b: Vector3) -> bool:
	var space := get_world_3d().direct_space_state
	var dir := b - a
	dir.y = 0.0
	if dir.length() < 0.01:
		return true
	var side := Vector3(-dir.z, 0, dir.x).normalized() * 0.3
	var ex: Array[RID] = [get_rid()]
	if held != null:
		ex.append(held.get_rid())
	for off in [Vector3(0, 0.45, 0), Vector3(0, 1.3, 0), side + Vector3(0, 0.8, 0), -side + Vector3(0, 0.8, 0)]:
		var from: Vector3 = a + off
		var to: Vector3 = Vector3(b.x, a.y, b.z) + off
		var q := PhysicsRayQueryParameters3D.create(from, to, 1 | 8, ex)
		if not space.intersect_ray(q).is_empty():
			return false
	return true


## A path round what's in the way: A* on a 1 m grid near him (cells tested
## against the world as he reaches them), then walked point to point.
func _plan(goal: Vector3) -> void:
	_path_goal = goal
	_path_i = 0
	if _clear(global_position, goal):
		_path = PackedVector3Array([goal])
		return
	var start := _cell(global_position)
	var end := _cell(goal)
	var centre := (global_position + goal) * 0.5
	var came := {start: start}
	var cost := {start: 0.0}
	var heap: Array = [[0.0, start]]
	var found := false
	var expanded := 0
	var best := start
	var best_h := INF
	while not heap.is_empty() and expanded < 2500:
		var cur: Vector2i = _heap_pop(heap)[1]
		expanded += 1
		var h0 := Vector2(cur - end).length()
		if h0 < best_h:
			best_h = h0
			best = cur
		if cur == end:
			found = true
			break
		for dx in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				if dx == 0 and dz == 0:
					continue
				var nb := cur + Vector2i(dx, dz)
				var wc := _world(nb)
				if Vector2(wc.x - centre.x, wc.z - centre.z).length() > PATH_RADIUS:
					continue
				if nb != end and _blocked(nb):
					continue
				if dx != 0 and dz != 0 and (_blocked(cur + Vector2i(dx, 0)) or _blocked(cur + Vector2i(0, dz))):
					continue      # no squeezing past a corner
				var c: float = cost[cur] + (1.414 if dx != 0 and dz != 0 else 1.0)
				if not cost.has(nb) or c < cost[nb]:
					cost[nb] = c
					came[nb] = cur
					_heap_push(heap, [c + Vector2(nb - end).length(), nb])
	var last := end if found else best
	var pts := PackedVector3Array()
	var k := last
	while k != start:
		pts.append(_world(k))
		k = came[k]
	pts.reverse()
	if found:
		pts.append(goal)
	_path = pts


func _cell(p: Vector3) -> Vector2i:
	return Vector2i(int(floor(p.x / CELL)), int(floor(p.z / CELL)))


func _world(c: Vector2i) -> Vector3:
	var x := (c.x + 0.5) * CELL
	var z := (c.y + 0.5) * CELL
	return Vector3(x, Landscape.ground(x, z), z)


func _blocked(c: Vector2i) -> bool:
	if _cells.has(c):
		return _cells[c]
	var at := _world(c)
	var sh := CylinderShape3D.new()
	sh.radius = 0.4
	sh.height = 1.1
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = sh
	q.transform = Transform3D(Basis(), at + Vector3.UP * 1.0)
	q.collision_mask = 1 | 8
	q.exclude = [get_rid()]
	var b := not get_world_3d().direct_space_state.intersect_shape(q, 1).is_empty()
	_cells[c] = b
	return b


static func _heap_push(h: Array, e: Array) -> void:
	h.append(e)
	var i := h.size() - 1
	while i > 0:
		var p := (i - 1) / 2
		if float(h[p][0]) <= float(h[i][0]):
			break
		var t = h[p]
		h[p] = h[i]
		h[i] = t
		i = p


static func _heap_pop(h: Array) -> Array:
	var top: Array = h[0]
	var last: Array = h.pop_back()
	if not h.is_empty():
		h[0] = last
		var i := 0
		while true:
			var l := i * 2 + 1
			var r := l + 1
			var m := i
			if l < h.size() and float(h[l][0]) < float(h[m][0]):
				m = l
			if r < h.size() and float(h[r][0]) < float(h[m][0]):
				m = r
			if m == i:
				break
			var t = h[m]
			h[m] = h[i]
			h[i] = t
			i = m
	return top


# --- random acts ---------------------------------------------------------------------

## [id, good, the line 3 s before, what he says as it starts]
const ACTS := [
	["find_can", true, "Wait... I think I know something.", "My friend knew it was here!"],
	["spot_creature", true, "Hold on...", "Someone's watching us. There."],
	["hold_door", true, "Oh, let me help.", "I'll get that for you."],
	["fix_tyre", true, "I can fix that!", "Leave the wheel to me."],
	["wander", false, "Ooh, what's that over there?", "Hang on, I want to show my friend something."],
	["honk", false, "What does this button do?", "Beep beep!"],
	["headlights", false, "Isn't it dark?", "Let's have some light!"],
	["tarp_off", false, "The poor van can't breathe under that.", "There. Let it breathe a bit."],
	["drop_it", false, "This is heavier than it looks...", "Oops. Slippery."],
]


## Somewhere a random act must never happen (a timed puzzle step): any node
## in the "naresh_calm" group, with a "radius" meta, round him or a player.
func _in_calm_zone() -> bool:
	for z in get_tree().get_nodes_in_group("naresh_calm"):
		var c := (z as Node3D).global_position
		var r := float(z.get_meta("radius", 8.0))
		if Vector2(c.x - global_position.x, c.z - global_position.z).length() < r:
			return true
		for n in get_tree().get_nodes_in_group("player"):
			var p := (n as Node3D).global_position
			if Vector2(c.x - p.x, c.z - p.z).length() < r:
				return true
	return false


func _random_acts(delta: float) -> void:
	if not acts_on or state in [State.TAKEN, State.KNOCKED] or state == State.ACT:
		return
	if _tele_t > 0.0:
		_tele_t -= delta
		if _tele_t <= 0.0:
			_start_act()
		return
	act_t -= delta
	if act_t > 0.0:
		return
	if _in_calm_zone():
		act_t = RETRY_ACT
		return
	var pick := _choose_act()
	if pick.is_empty():
		act_t = RETRY_ACT
		return
	act = pick[0]
	act_good = pick[1]
	_tele_t = TELEGRAPH
	acts_log.append({"id": act, "good": act_good, "tele": Time.get_ticks_msec(), "start": -1})
	say(pick[2])


## An act that fits right now, roughly half good and half bad.
func _choose_act() -> Array:
	var good: Array = []
	var bad: Array = []
	for a in ACTS:
		if _act_possible(a[0]):
			(good if a[1] else bad).append(a)
	var from: Array = bad if _last_good else good
	if from.is_empty():
		from = good if not good.is_empty() else bad
	if from.is_empty():
		return []
	return from[randi() % from.size()]


func _act_possible(id: String) -> bool:
	var v := _the_van()
	var seated := state == State.SEATED
	match id:
		"find_can":
			return not seated and held == null and _hidden_can() != null
		"spot_creature":
			return _creature_near(60.0) != null
		"hold_door":
			return not seated and held == null and _door_to_hold() != null
		"fix_tyre":
			return not seated and v != null and v.tyre_flat and v.linear_velocity.length() < 0.5 \
				and v.global_position.distance_to(global_position) < 30.0
		"wander":
			return not seated and held == null and state != State.JOB
		"honk":
			return v != null and v.battery > 0.05 and (seated or v.global_position.distance_to(global_position) < 12.0)
		"headlights":
			return v != null and not v.headlights_on and _dark() and (seated or v.global_position.distance_to(global_position) < 12.0)
		"tarp_off":
			return not seated and v != null and v.attack.tarped and v.global_position.distance_to(global_position) < 25.0
		"drop_it":
			return held != null and state == State.JOB and job in ["carry", "store"]
	return false


func _dark() -> bool:
	var m := get_tree().get_first_node_in_group("mood") as Mood
	return m != null and m.light() >= 1


func _hidden_can() -> FuelCan:
	for n in get_tree().get_nodes_in_group("naresh_find"):
		var c := n as FuelCan
		if c != null and c.holders.is_empty() and c.stowed_in == null and c.global_position.distance_to(global_position) < 80.0:
			return c
	return null


func _creature_near(r: float) -> Creature:
	for n in get_tree().get_nodes_in_group("creature"):
		var c := n as Creature
		if c != null and not c.dormant and c.global_position.distance_to(global_position) < r:
			return c
	return null


## A door or shutter a player on foot is standing at, that nobody holds.
func _door_to_hold() -> Workable:
	for n in get_tree().get_nodes_in_group("workable"):
		var w := n as Workable
		if w == null or w.kind != "hold" or w.holding_now():
			continue
		if w.global_position.distance_to(global_position) > 14.0:
			continue
		for pn in get_tree().get_nodes_in_group("player"):
			var p := pn as PlayerRig
			if p.seat == null and p.global_position.distance_to(w.global_position) < 5.0:
				return w
	return null


## Start an act now (dev menu, tests): skips the timer, still announced.
func act_now(id := "") -> bool:
	if state == State.ACT or _tele_t > 0.0 or state in [State.TAKEN, State.KNOCKED]:
		return false
	if id == "":
		var pick := _choose_act()
		if pick.is_empty():
			return false
		id = pick[0]
	for a in ACTS:
		if a[0] == id and _act_possible(id):
			act = id
			act_good = a[1]
			_tele_t = TELEGRAPH
			acts_log.append({"id": act, "good": act_good, "tele": Time.get_ticks_msec(), "start": -1})
			say(a[2])
			return true
	return false


func _start_act() -> void:
	if not _act_possible(act):
		act = ""
		act_t = RETRY_ACT
		return
	for a in ACTS:
		if a[0] == act:
			say(a[3])
	if not acts_log.is_empty():
		acts_log[-1]["start"] = Time.get_ticks_msec()
	_last_good = act_good
	_act_data = {"prev_state": state, "prev_leader": leader, "t": 0.0}
	var v := _the_van()
	match act:
		"honk":
			v.attack.honk_for(1.4)
			_act_over()
		"headlights":
			v.set_headlights(true)
			_act_over()
		"drop_it":
			var it := held
			drop_held()
			if it != null:
				it.linear_velocity = Vector3.UP * 1.5
				it._thrown = true      # it lands loudly
			_act_over()
		"spot_creature":
			var c := _creature_near(60.0)
			var who := leader if leader != null else _nearest_player()
			if c != null and who != null:
				TagMarker.place(who, c.global_position + Vector3.UP * 2.0, c)
			_act_over()
		_:
			if state == State.JOB:
				_end_job()
			state = State.ACT
			if act == "wander":
				_act_data["to"] = _wander_spot()
			elif act == "find_can":
				_act_data["can"] = _hidden_can()
			elif act == "hold_door":
				_act_data["door"] = _door_to_hold()
	act_t = randf_range(act_gap.x, act_gap.y)


## An act that finished at once: whatever he was doing carries on.
func _act_over() -> void:
	act = ""


func _cancel_act(say_it: bool) -> void:
	_tele_t = 0.0
	if state == State.ACT:
		if _act_data.has("door") and is_instance_valid(_act_data["door"]):
			(_act_data["door"] as Workable).release_by(self)
		if held != null:
			drop_held()
		state = State.FOLLOW if _act_data.get("prev_leader") != null else State.IDLE
		leader = _act_data.get("prev_leader")
		if say_it:
			say("Never mind.")
	act = ""


func _act_back(line: String) -> void:
	if line != "":
		say(line)
	var prev: PlayerRig = _act_data.get("prev_leader")
	act = ""
	_act_data.clear()
	leader = prev
	state = State.FOLLOW if prev != null else State.IDLE


func _do_act(delta: float) -> void:
	_act_data["t"] = float(_act_data.get("t", 0.0)) + delta
	var t: float = _act_data["t"]
	match act:
		"wander":
			var to: Vector3 = _act_data["to"]
			if t > 45.0 or (_walk_to(to, WALK, 1.0, delta) and t > 30.0):
				_act_back("OK, OK, coming!")
			elif _flat_dist(to) <= 1.0:
				_act_data["there"] = true
				_move(Vector3.ZERO, delta)
		"find_can":
			var can: FuelCan = _act_data.get("can")
			if can == null or not is_instance_valid(can):
				_act_back("")
				return
			if held != can:
				if _fetch(can, delta) < 0:
					_act_back("Oh, you found it too.")
				return
			var v := _the_van()
			var who: PlayerRig = _act_data.get("prev_leader")
			if who == null:
				who = _nearest_player()
			var at := v.rack_stand() if v != null else (who.global_position if who != null else global_position)
			if _walk_to(at, WALK, 0.9 if v != null else 1.7, delta):
				var slot := v.free_slot_for(can) if v != null else null
				if slot != null:
					_stow(can, slot)
				else:
					drop_held()
				can.remove_from_group("naresh_find")
				_act_back("A fuel can! Don't ask me how I knew.")
		"hold_door":
			var w: Workable = _act_data.get("door")
			if w == null or t > 25.0:
				if w != null:
					w.release_by(self)
				_act_back("My arms are tired.")
				return
			if _flat_dist(w.stand_point()) > 0.7:
				_walk_to(w.stand_point(), JOG, 0.6, delta)
			else:
				_face(w.global_position, delta)
				_move(Vector3.ZERO, delta)
				w.work_by(self, delta)
		"fix_tyre":
			var v := _the_van()
			if v == null or not v.tyre_flat:
				_act_back("")
				return
			var at := v.global_transform * Vector3(-2.2, -0.6, -Camper.WHEELBASE)
			if _flat_dist(at) > 0.8:
				_walk_to(at, WALK, 0.7, delta)
				_act_data["work"] = 0.0
			else:
				_face(v.global_position, delta)
				_move(Vector3.ZERO, delta)
				_act_data["work"] = float(_act_data.get("work", 0.0)) + delta
				if int(_act_data["work"] * 2.0) % 3 == 0 and fmod(float(_act_data["work"]), 0.5) < delta:
					Sfx.play3d("hit_metal", at + Vector3.UP * 0.5, -10.0)
				if float(_act_data["work"]) > 20.0:
					v.naresh_fix_tyre()
					_act_back("Fixed it! Sort of. Don't go too fast.")
		"tarp_off":
			var v := _the_van()
			if v == null or not v.attack.tarped:
				_act_back("")
				return
			if _walk_to(v.global_transform * Vector3(0, -0.6, 4.4), WALK, 0.9, delta):
				v.attack.set_tarp(false)
				Hearing.emit(v.global_position, Hearing.DOOR, "tarp")
				_act_back("There. Let it breathe a bit.")
		_:
			_act_back("")


## Somewhere 45-70 m off in the open, away from the players.
func _wander_spot() -> Vector3:
	var best := global_position
	var best_score := -INF
	for k in 12:
		var a := randf() * TAU
		var d := randf_range(45.0, 70.0)
		var at := global_position + Vector3(cos(a), 0, sin(a)) * d
		at.y = Landscape.ground(at.x, at.z)
		if Landscape.EXTENT > 0.0 and (absf(at.x) > Landscape.EXTENT * 0.5 - 30.0 or absf(at.z) > Landscape.EXTENT * 0.5 - 30.0):
			continue
		var score := 0.0
		for n in get_tree().get_nodes_in_group("player"):
			score += minf((n as Node3D).global_position.distance_to(at), 80.0)
		if _clear(global_position, at):
			score += 40.0
		if score > best_score:
			best_score = score
			best = at
	return best


func _nearest_player() -> PlayerRig:
	var best: PlayerRig = null
	for n in get_tree().get_nodes_in_group("player"):
		var p := n as PlayerRig
		if best == null or p.global_position.distance_to(global_position) < best.global_position.distance_to(global_position):
			best = p
	return best


# --- cans --------------------------------------------------------------------------

## A can on the van's rack: with fuel in it (or an empty one if `empty`).
func _rack_can(v: Camper, empty: bool) -> FuelCan:
	for s in v.storage_slots:
		var it := v.stowed_item(s) as FuelCan
		if it != null and (it.litres <= 0.05) == empty:
			return it
	return null


## The empty can he'll mistake for the full one: on the rack or near the van.
func _empty_can_near(v: Camper, not_this: FuelCan) -> FuelCan:
	var c := _rack_can(v, true)
	if c != null and c != not_this:
		return c
	for n in get_tree().get_nodes_in_group("carryable"):
		var f := n as FuelCan
		if f != null and f != not_this and f.litres <= 0.05 and f.holders.is_empty() and f.global_position.distance_to(v.global_position) < 12.0:
			return f
	return null


# --- being taken ---------------------------------------------------------------------

## Nobody within 12 m (DESIGN.md 7): only then can a creature take him.
func alone() -> bool:
	for n in get_tree().get_nodes_in_group("player"):
		if (n as Node3D).global_position.distance_to(global_position) < ALONE:
			return false
	return true


func can_be_taken() -> bool:
	return state not in [State.TAKEN, State.SEATED, State.KNOCKED] and alone()


## A creature takes him: a wisp of smoke, and he's left somewhere high and
## far off (200-400 m), where he waits and shouts until someone fetches him.
func take(by: Node3D = null) -> void:
	if not can_be_taken():
		return
	_cancel_act(false)
	_end_job()
	var from := global_position
	var root := get_tree().get_first_node_in_group("world_root")
	if root != null:
		var puff := Taken.smoke(28, 1.6, 0.9)
		puff.direction = Vector3.UP
		puff.spread = 35.0
		puff.initial_velocity_min = 1.0
		puff.initial_velocity_max = 2.6
		puff.one_shot = true
		root.add_child(puff)
		puff.global_position = from + Vector3.UP
		puff.emitting = true
		puff.finished.connect(puff.queue_free)
	Sfx.play3d("whoosh", from + Vector3.UP, 4.0)
	var drop := _choose_drop(from)
	var at: Vector3 = drop["pos"]
	taken_near = drop["near"]
	leader = null
	state = State.TAKEN
	global_position = at + Vector3.UP * 0.2
	velocity = Vector3.ZERO
	_plan_vel = Vector2.ZERO
	var back := from - at
	if Vector2(back.x, back.z).length() > 1.0:
		yaw = atan2(-back.x, -back.z)
		rotation.y = yaw
	reset_physics_interpolation()
	_shout_t = 2.0
	var _b := by


## The builder's naresh_drops (high places, 200-400 m off), else its drop points.
func _choose_drop(from: Vector3) -> Dictionary:
	var boot := get_tree().current_scene
	var b = boot.get("builder") if boot != null else null
	var pts: Array = []
	if b != null:
		pts = b.naresh_drops if not b.naresh_drops.is_empty() else b.drop_points
	var best := {}
	var best_d := INF
	for d in pts:
		var dist := (d["pos"] as Vector3).distance_to(from)
		if dist >= 200.0 and dist <= 400.0 and dist < best_d:
			best = d
			best_d = dist
	if best.is_empty():
		for d in pts:
			var dist := (d["pos"] as Vector3).distance_to(from)
			if best.is_empty() or absf(dist - 300.0) < absf((best["pos"] as Vector3).distance_to(from) - 300.0):
				best = d
	if best.is_empty():
		return {"pos": from, "near": "here"}
	return best


func _taken_wait(delta: float) -> void:
	_move(Vector3.ZERO, delta)
	_shout_t -= delta
	if _shout_t <= 0.0:
		_shout_t = SHOUT_EVERY
		say("Over here! By %s! My friend's with me, don't worry." % taken_near, true)
		Sfx.play3d("whoosh", global_position + Vector3.UP * 2.0, -12.0)
	var p := _nearest_player()
	if p != null and p.global_position.distance_to(global_position) < FETCH:
		# down he climbs, to your side
		var side := p.global_transform.basis.x
		side.y = 0.0
		var at := p.global_position + side.normalized() * 1.6
		at.y = maxf(p.global_position.y, Landscape.ground(at.x, at.z)) + 0.2
		global_position = at
		reset_physics_interpolation()
		leader = p
		state = State.FOLLOW
		say("There you are! How did I get up there?")


# --- hit by the van ------------------------------------------------------------------

func knock(impulse: Vector3, v: PhysicsBody3D = null) -> void:
	if state in [State.SEATED, State.KNOCKED, State.TAKEN]:
		return
	_cancel_act(false)
	_end_job()
	if v != null:
		_knock_van = v
		add_collision_exception_with(v)
	velocity = impulse
	_plan_vel = Vector2.ZERO
	knocked_t = clampf(0.9 + impulse.length() * 0.12, 1.2, 4.0)
	_act_data["knock_prev"] = leader
	state = State.KNOCKED
	Sfx.play3d("hit_soft", global_position + Vector3.UP, 4.0)
	PlayerRig._dust_puff(global_position + Vector3.UP * 0.6, impulse.length())


func _knocked(delta: float) -> void:
	knocked_t -= delta
	velocity.y -= GRAVITY * delta
	if is_on_floor():
		var h := Vector2(velocity.x, velocity.z).move_toward(Vector2.ZERO, 16.0 * delta)
		velocity.x = h.x
		velocity.z = h.y
	move_and_slide()
	_mesh_root.rotation = Vector3(-PI * 0.5, 0, 0)
	if knocked_t <= 0.0 and is_on_floor():
		_mesh_root.rotation = Vector3.ZERO
		leader = _act_data.get("knock_prev")
		_act_data.erase("knock_prev")
		state = State.FOLLOW if leader != null else State.IDLE
		say("Ow! I'm fine! My friend says you drive like my mum.")


# --- saving ----------------------------------------------------------------------------

func save_state() -> Dictionary:
	return {
		"pos": [global_position.x, global_position.y, global_position.z],
		"yaw": yaw,
		"state": State.keys()[state],
		"leader": leader.index if leader != null else -1,
		"seated": state == State.SEATED,
		"act_t": act_t,
		"taken_near": taken_near,
		"mistake": refuel_mistake,
	}


## Back as saved. A load never loses him: somewhere bad (under the map, in the
## sea) puts him on the van's bench.
func load_state(d: Dictionary, players: Array, camper: Camper) -> void:
	_end_job()
	_cancel_act(false)
	if van != null:
		_get_out()
	var a: Array = d.get("pos", [0, 0, 0])
	var at := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var li := int(d.get("leader", -1))
	leader = players[li] if li >= 0 and li < players.size() else null
	act_t = float(d.get("act_t", act_t))
	refuel_mistake = bool(d.get("mistake", false))
	var st := String(d.get("state", "IDLE"))
	var bad := at.y < Landscape.ground(at.x, at.z) - 3.0 or Landscape.coast_inland(at.x, at.z) < -15.0
	if (bool(d.get("seated", false)) or bad) and camper != null:
		_sit(camper)
		return
	global_position = at
	yaw = float(d.get("yaw", 0.0))
	rotation.y = yaw
	reset_physics_interpolation()
	if st == "TAKEN":
		taken_near = String(d.get("taken_near", "here"))
		state = State.TAKEN
		_shout_t = 3.0
	elif leader != null:
		state = State.FOLLOW
	elif st == "WAIT" or st == "GO" or st == "JOB":
		state = State.WAIT
	else:
		state = State.IDLE


## Spawns him into the world (dev menu, gyms, the fifth rose).
static func spawn(root: Node, at: Vector3, facing := 0.0) -> Naresh:
	var n := Naresh.new()
	n.name = "Naresh"
	root.add_child(n)
	n.global_position = at
	n.yaw = facing
	n.rotation.y = facing
	n.reset_physics_interpolation()
	return n
