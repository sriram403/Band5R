class_name Workable
extends StaticBody3D

## Something held or worked with your hands, by a player (hold E) or by
## Naresh (his "hold it" / "work it" jobs, design/NARESH.md):
##   "hold"  a heavy shutter, a spring lever: open only while someone holds it,
##           it falls shut again when they let go (the other one goes through)
##   "work"  a crank: the work done is kept; done at 1 (a gate stays up)
## `amount` runs 0..1; `on_amount` (a Callable taking it) moves whatever it
## drives. The gyms build the look; E6's stall shutter and boat use it too.

signal finished

@export var kind := "hold"
var label := "lever"
var verb := "hold"                  ## the prompt's verb: "Hold to <verb> the <label>"
var work_s := 1.5                   ## s of holding to open fully (hold) / of work (work)
var close_s := 1.0                  ## s to fall shut once let go (hold)
var amount := 0.0
var is_done := false
var stand := Vector3(0, 0, 1.1)     ## local: where you stand to use it
var on_amount: Callable
## More than one pair of hands (the boat, E6): it only moves while this many
## are on it at once, each counted if `helps` (Callable(who) -> bool) says so.
var need_hands := 1
var helps: Callable
## Where someone stands to use it (Callable(who) -> Vector3); else `stand`.
var stand_fn: Callable
var hands_last := 0                 ## how many helped in the last tick (prompts, tests)
var _hands: Array = []              ## who has hold of it this tick
var _last_hands: Array = []


func _ready() -> void:
	add_to_group("workable")
	set_meta("prompt", "Use the " + label)
	set_meta("prompt_fn", func(_p) -> String:
		if kind == "work" and is_done:
			return ""
		if need_hands > 1:
			return "Hold to %s the %s  (%d of %d on it)" % [verb, label, hands_last, need_hands]
		return "Hold to %s the %s" % [verb, label])
	set_meta("blocked_fn", func() -> String:
		return "The %s is done" % label if kind == "work" and is_done else "")
	set_meta("callback", func(_p): pass)
	set_meta("hold_fn", func(p, dt: float): work_by(p, dt))


## Someone holds or works it for `dt` seconds (call every tick they do).
func work_by(who: Node, dt: float) -> void:
	if not who in _hands:
		_hands.append(who)
	if kind == "work" and is_done:
		return
	if need_hands > 1:
		return                      # moved in _physics_process, when enough are on it
	var before := amount
	amount = minf(1.0, amount + dt / maxf(work_s, 0.01))
	if kind == "work":
		if int(before * 8.0) != int(amount * 8.0):
			Sfx.play3d("tick", global_position + Vector3.UP, -8.0)
		if amount >= 1.0 and not is_done:
			is_done = true
			Sfx.play3d("bong", global_position + Vector3.UP, -6.0)
			finished.emit()
	_moved()


## Naresh let go (a new job, the scripted early let-go).
func release_by(who: Node) -> void:
	_hands.erase(who)
	_last_hands.erase(who)


## Somebody had hold of it in the last tick.
func holding_now() -> bool:
	return not _hands.is_empty() or not _last_hands.is_empty()


func holders_now() -> Array:
	var out := _last_hands.duplicate()
	for h in _hands:
		if not h in out:
			out.append(h)
	return out


func stand_point() -> Vector3:
	return global_transform * stand


func stand_point_for(who: Node) -> Vector3:
	return stand_fn.call(who) if stand_fn.is_valid() else stand_point()


func _physics_process(delta: float) -> void:
	# the hands of the last tick; nobody at all: a held thing falls shut
	_last_hands = _hands
	_hands = []
	if need_hands > 1 and not is_done:
		hands_last = 0
		for h in _last_hands:
			if not helps.is_valid() or helps.call(h):
				hands_last += 1
		if hands_last >= need_hands:
			var before := amount
			amount = minf(1.0, amount + delta / maxf(work_s, 0.01))
			if int(before * 6.0) != int(amount * 6.0):
				Sfx.play3d("hit_wood_heavy", global_position + Vector3.UP, -4.0)
			if amount >= 1.0:
				is_done = true
				Sfx.play3d("bong", global_position + Vector3.UP, -6.0)
				finished.emit()
			_moved()
		elif not _last_hands.is_empty() and Engine.get_physics_frames() % 90 == 0:
			Sfx.play3d("creak", global_position + Vector3.UP, -8.0)
	if kind == "hold" and _last_hands.is_empty() and amount > 0.0:
		amount = maxf(0.0, amount - delta / maxf(close_s, 0.01))
		if amount <= 0.0:
			Sfx.play3d("hit_metal_heavy", global_position + Vector3.UP, -6.0)
		_moved()


func _moved() -> void:
	if on_amount.is_valid():
		on_amount.call(amount)


## A reward still lying where the puzzle left it goes on a reset; one that
## somebody is holding stays. Untyped: it may already be freed (picked up
## and used), and a freed object fails a typed argument.
static func free_reward(n: Variant, near: Vector3, within: float) -> void:
	if n == null or not is_instance_valid(n) or not n is Node3D:
		return
	if n is Carryable:
		var c := n as Carryable
		if not c.holders.is_empty() or c.stowed_in != null:
			return
	if (n as Node3D).global_position.distance_to(near) < within:
		n.queue_free()
