class_name Hearing
extends RefCounted

## Sounds the creatures can hear. Anything that makes a noise calls
## `Hearing.emit(where, radius)`: a creature within `radius` metres hears it,
## walls or not (design/CREATURES.md, "Hearing"). Creatures read the sounds
## made since they last listened, by serial number, so nothing is heard twice.

## Heard-from distances (m), fixed in the stealth gym. See DESIGN.md 6.1.
const CROUCH_STEP := 2.0
const WALK_STEP := 8.0
const SPRINT_STEP := 18.0
const LANDING := 10.0
const ITEM_LANDS := 15.0          ## a thrown thing: the lure
const DOOR := 20.0
const ENGINE_IDLE := 40.0
const ENGINE_DRIVE := 60.0
const ENGINE_REV := 90.0
const HORN := 150.0

const KEEP_MS := 2000

## [{"id": int, "pos": Vector3, "radius": float, "t": msec, "what": String}]
static var recent: Array = []
static var _next_id := 1


static func emit(pos: Vector3, radius: float, what := "") -> void:
	var now := Time.get_ticks_msec()
	while not recent.is_empty() and now - int(recent[0]["t"]) > KEEP_MS:
		recent.pop_front()
	recent.append({"id": _next_id, "pos": pos, "radius": radius, "t": now, "what": what})
	_next_id += 1


## Sounds newer than serial `after_id`.
static func since(after_id: int) -> Array:
	var out := []
	for s in recent:
		if int(s["id"]) > after_id:
			out.append(s)
	return out


static func last_id() -> int:
	return _next_id - 1
