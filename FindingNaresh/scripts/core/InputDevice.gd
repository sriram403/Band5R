class_name InputDevice
extends RefCounted

## Per-player input abstraction.
##
## Reads hardware directly instead of going through the shared InputMap, which
## guarantees that one player's keyboard/mouse can never move the other player
## and that a controller is bound to exactly one player slot.

enum Kind { KBM, PAD }

const DEADZONE := 0.18

var kind: int = Kind.KBM
var pad: int = -1              ## joypad device id when kind == PAD
var active := true             ## false parks the device (used by the solo-test swap)
var look_sensitivity := 1.0    ## multiplies both mouse and stick look
var invert_y := false

var _mouse_delta := Vector2.ZERO
var _held: Dictionary = {}
var _prev: Dictionary = {}
## Presses seen as events since the last poll. A tap shorter than one physics
## tick would otherwise never be seen by is_key_pressed().
var _latched: Dictionary = {}

# --- Keyboard / mouse bindings -------------------------------------------------
const KEYS := {
	"fwd": KEY_W, "back": KEY_S, "left": KEY_A, "right": KEY_D,
	"sprint": KEY_SHIFT, "crouch": KEY_CTRL, "jump": KEY_SPACE,
	"interact": KEY_E, "flashlight": KEY_F, "map": KEY_M,
	"handbrake": KEY_SPACE, "ignition": KEY_X, "headlights": KEY_L,
	"horn": KEY_H, "swap_seat": KEY_C, "recover": KEY_R, "throw": KEY_G,
}
## Mouse buttons that also trigger an action (checked alongside KEYS).
const MOUSE := {"throw": MOUSE_BUTTON_LEFT}

# --- Controller bindings (Xbox layout) -----------------------------------------
const BUTTONS := {
	"jump": JOY_BUTTON_A, "interact": JOY_BUTTON_X, "crouch": JOY_BUTTON_B,
	"flashlight": JOY_BUTTON_Y, "sprint": JOY_BUTTON_LEFT_STICK,
	"map": JOY_BUTTON_DPAD_DOWN, "throw": JOY_BUTTON_RIGHT_SHOULDER, "swap_seat": JOY_BUTTON_LEFT_SHOULDER,
	"handbrake": JOY_BUTTON_B, "ignition": JOY_BUTTON_DPAD_UP,
	"headlights": JOY_BUTTON_DPAD_LEFT, "horn": JOY_BUTTON_DPAD_RIGHT,
	"recover": JOY_BUTTON_BACK,
}


static func keyboard() -> InputDevice:
	var d := InputDevice.new()
	d.kind = Kind.KBM
	return d


static func gamepad(device_id: int) -> InputDevice:
	var d := InputDevice.new()
	d.kind = Kind.PAD
	d.pad = device_id
	return d


func label() -> String:
	if kind == Kind.PAD:
		return "Gamepad %d" % pad
	return "Keyboard + Mouse"


## Short glyph used in on-screen prompts, e.g. "[E]" or "[X]".
func glyph(action: String) -> String:
	if kind == Kind.PAD:
		match action:
			"interact": return "X"
			"jump": return "A"
			"crouch": return "B"
			"flashlight": return "Y"
			"map": return "D-Down"
			"throw": return "RB"
			"sprint": return "L3"
			"swap_seat": return "LB"
			"ignition": return "D-Up"
			"headlights": return "D-Left"
			"handbrake": return "B"
			"recover": return "View"
			_: return "?"
	match action:
		"interact": return "E"
		"jump": return "Space"
		"crouch": return "Ctrl"
		"flashlight": return "F"
		"map": return "M"
		"sprint": return "Shift"
		"swap_seat": return "C"
		"ignition": return "X"
		"headlights": return "L"
		"handbrake": return "Space"
		"recover": return "R"
		"throw": return "LMB"
		_: return "?"


## Called once per physics tick by the device manager. Everything that reads
## just_pressed() runs in the physics step, so polling here means each press is
## seen exactly once: polling per render frame lost taps at 144 Hz and would
## double-fire them below 60 fps.
func poll() -> void:
	_prev = _held.duplicate()
	_held.clear()
	if not active:
		_mouse_delta = Vector2.ZERO
		_latched.clear()
		return
	for a in KEYS.keys():
		_held[a] = _raw_held(a) or _latched.has(a)
	_latched.clear()


## Fed every input event so very short taps are never missed between polls.
func feed_event(e: InputEvent) -> void:
	if not active or not e.is_pressed() or e.is_echo():
		return
	if kind == Kind.KBM and e is InputEventKey:
		var k := (e as InputEventKey).keycode
		for a in KEYS.keys():
			if KEYS[a] == k:
				_latched[a] = true
	elif kind == Kind.KBM and e is InputEventMouseButton:
		var mb := (e as InputEventMouseButton).button_index
		for a in MOUSE.keys():
			if MOUSE[a] == mb:
				_latched[a] = true
	elif kind == Kind.PAD and e is InputEventJoypadButton and e.device == pad:
		var b := (e as InputEventJoypadButton).button_index
		for a in BUTTONS.keys():
			if BUTTONS[a] == b:
				_latched[a] = true


func feed_mouse(rel: Vector2) -> void:
	if active and kind == Kind.KBM:
		_mouse_delta += rel


func held(action: String) -> bool:
	if not active:
		return false
	return _held.get(action, false)


func just_pressed(action: String) -> bool:
	if not active:
		return false
	return _held.get(action, false) and not _prev.get(action, false)


## x = strafe (right positive), y = forward (forward positive)
func move() -> Vector2:
	if not active:
		return Vector2.ZERO
	if kind == Kind.PAD:
		var v := Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_LEFT_X),
			-Input.get_joy_axis(pad, JOY_AXIS_LEFT_Y))
		return _dead(v)
	var v2 := Vector2(
		(1.0 if Input.is_key_pressed(KEYS["right"]) else 0.0) - (1.0 if Input.is_key_pressed(KEYS["left"]) else 0.0),
		(1.0 if Input.is_key_pressed(KEYS["fwd"]) else 0.0) - (1.0 if Input.is_key_pressed(KEYS["back"]) else 0.0))
	return v2.limit_length(1.0)


## Look delta in radians for this frame. Mouse is frame-based, stick is time-based.
func look(delta: float) -> Vector2:
	if not active:
		return Vector2.ZERO
	var out := Vector2.ZERO
	if kind == Kind.PAD:
		var v := _dead(Vector2(
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X),
			Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y)))
		# Squared response gives fine aim near centre, fast turns at the edge.
		v = Vector2(v.x * absf(v.x), v.y * absf(v.y))
		out = v * 2.9 * look_sensitivity * delta
	else:
		out = _mouse_delta * 0.0022 * look_sensitivity
		_mouse_delta = Vector2.ZERO
	if invert_y:
		out.y = -out.y
	return out


# --- Driving -------------------------------------------------------------------

func throttle() -> float:
	if not active:
		return 0.0
	if kind == Kind.PAD:
		return clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_RIGHT), 0.0, 1.0)
	return 1.0 if Input.is_key_pressed(KEYS["fwd"]) else 0.0


func brake() -> float:
	if not active:
		return 0.0
	if kind == Kind.PAD:
		return clampf(Input.get_joy_axis(pad, JOY_AXIS_TRIGGER_LEFT), 0.0, 1.0)
	return 1.0 if Input.is_key_pressed(KEYS["back"]) else 0.0


## -1 = full left, +1 = full right
func steer() -> float:
	if not active:
		return 0.0
	if kind == Kind.PAD:
		var x := Input.get_joy_axis(pad, JOY_AXIS_LEFT_X)
		if absf(x) < DEADZONE:
			return 0.0
		return signf(x) * (absf(x) - DEADZONE) / (1.0 - DEADZONE)
	return (1.0 if Input.is_key_pressed(KEYS["right"]) else 0.0) - (1.0 if Input.is_key_pressed(KEYS["left"]) else 0.0)


# --- internals -----------------------------------------------------------------

func _raw_held(action: String) -> bool:
	if kind == Kind.PAD:
		if not BUTTONS.has(action):
			return false
		return Input.is_joy_button_pressed(pad, BUTTONS[action])
	if MOUSE.has(action) and Input.is_mouse_button_pressed(MOUSE[action]):
		return true
	if not KEYS.has(action):
		return false
	return Input.is_key_pressed(KEYS[action])


func _dead(v: Vector2) -> Vector2:
	var l := v.length()
	if l < DEADZONE:
		return Vector2.ZERO
	return v.normalized() * minf((l - DEADZONE) / (1.0 - DEADZONE), 1.0)
