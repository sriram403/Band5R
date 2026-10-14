class_name Snowball
extends Carryable

## A snowball (#4, the lookout: fun mechanic no. 4). Made from old snow (E
## at a patch), thrown hard and fast with the throw key (G / LMB / pad RB).
## It bursts on whatever it hits: a puff of snow, a soft thud, and it tells
## what it hit: your partner gets a jolt and a line, Naresh complains, the
## van keeps a white splat for a while, a snow target (the patrol sign)
## loses a lump. Creatures hear it land like any thrown thing (a lure).
## Held too long away from the snow it melts.

const R := 0.09
const SPEED := 17.0              ## m/s: a good overarm throw
const MELT_S := 240.0            ## s in your hands (or lying about) before it's gone

var _life := MELT_S
var _thrower = null
var _burst := false


func _ready() -> void:
	item_name = "snowball"
	kind = "snowball"
	mass = 0.3
	add_child(Build.sphere(R, ToonMat.make(Color(0.94, 0.96, 0.99), 0.01), Vector3.ZERO, Vector3.ONE, "Ball"))
	var cs := CollisionShape3D.new()
	var sh := SphereShape3D.new()
	sh.radius = R
	cs.shape = sh
	add_child(cs)
	super._ready()
	max_contacts_reported = 4


func throw_from(p, dir: Vector3) -> void:
	release(p)
	if not holders.is_empty():
		return
	_thrower = p
	add_collision_exception_with(p)
	# you throw at what you're looking at: from the hand (low and to the
	# right of your eyes) towards the spot under the crosshair, lobbed just
	# enough to drop onto it (a flat line from the eye missed by the hand's
	# offset, 2026-10-14)
	var eye: Vector3 = p.head.global_position if p.get("head") != null else global_position
	var reach := 40.0
	var q := PhysicsRayQueryParameters3D.create(eye, eye + dir.normalized() * reach, 1 | 2 | 8 | LAYER | 64)
	q.exclude = [get_rid(), (p as CollisionObject3D).get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var target: Vector3 = hit["position"] if not hit.is_empty() else eye + dir.normalized() * reach
	var to := target - global_position
	var t := to.length() / SPEED
	linear_velocity = to / maxf(t, 0.01) + Vector3.UP * (0.5 * 9.8 * t)
	_thrown = true


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_life -= delta
	if _life < 10.0:
		scale = Vector3.ONE * maxf(0.2, _life / 10.0)
	if _life <= 0.0:
		for h in holders.duplicate():
			if h.has_method("drop_held") and h.get("held") == self:
				h.drop_held()
		queue_free()


func _on_hit(body: Node) -> void:
	if _burst or not _thrown or not holders.is_empty():
		super._on_hit(body)
		return
	_burst = true
	var at := global_position
	_puff(at)
	Sfx.play3d("hit_soft", at, -2.0)
	Hearing.emit(at, Hearing.ITEM_LANDS, "item")
	var who := ""
	if body is PlayerRig and body != _thrower:
		var q := body as PlayerRig
		q.set("_shake_t", 0.18)
		q.say("SPLAT! A snowball, right in the neck.", 3.0)
		who = "P%d" % (q.index + 1)
	elif body is Naresh:
		(body as Naresh).say(["Oi! That's cold!", "Hey! Not fair, I'm working!", "Right. You're getting one back."].pick_random())
		who = "Naresh"
	else:
		var van := _van_of(body)
		if van != null:
			_splat_on(van, at)
			who = "the van"
	if _thrower is PlayerRig and who != "":
		(_thrower as PlayerRig).say("Got %s!" % who, 2.0)
	for t in get_tree().get_nodes_in_group("snow_target"):
		t.snowball_hit(at)
	print("[snowball] burst at %s on %s" % [str(at), body.name if body else "?"])
	queue_free()


func _van_of(n: Node) -> Node3D:
	while n != null:
		if n is Camper:
			return n as Node3D
		n = n.get_parent()
	return null


## Snow bursting: a quick puff of white bits that drop.
func _puff(at: Vector3) -> void:
	var root := get_tree().get_first_node_in_group("world_root")
	if root == null:
		return
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = 18
	p.lifetime = 0.7
	p.explosiveness = 1.0
	p.direction = Vector3.UP
	p.spread = 80.0
	p.initial_velocity_min = 1.0
	p.initial_velocity_max = 3.0
	p.gravity = Vector3(0, -9.0, 0)
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	var m := BoxMesh.new()
	m.size = Vector3(0.05, 0.05, 0.05)
	m.material = ToonMat.make(Color(0.95, 0.97, 1.0))
	p.mesh = m
	root.add_child(p)
	p.global_position = at
	p.emitting = true
	get_tree().create_timer(1.5).timeout.connect(p.queue_free)


## A white splat stuck on the van where it hit; it melts away in a minute.
func _splat_on(van: Node3D, at: Vector3) -> void:
	var s := Build.sphere(0.14, ToonMat.make(Color(0.95, 0.97, 1.0), 0.01), Vector3.ZERO, Vector3(1.4, 1.0, 0.5), "SnowSplat")
	van.add_child(s)
	s.global_position = at
	var tw := s.create_tween()
	tw.tween_interval(30.0)
	tw.tween_property(s, "scale", Vector3(0.3, 0.2, 0.1), 30.0)
	tw.tween_callback(s.queue_free)
