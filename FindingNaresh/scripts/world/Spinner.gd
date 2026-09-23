class_name Spinner
extends Node3D

## Tiny ambient animator: spins around a local axis (windmill blades) or blinks
## (radio mast beacon). Cheap enough to scatter wherever the world needs motion.

var axis := Vector3.FORWARD
var speed := 1.0            ## rad/s when spinning
var blink_period := 0.0     ## > 0 turns this node into a blinker instead
var _t := 0.0


func _process(delta: float) -> void:
	if blink_period > 0.0:
		_t = fmod(_t + delta, blink_period)
		visible = _t < blink_period * 0.35
	else:
		rotate_object_local(axis, speed * delta)
