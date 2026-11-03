extends EnemyState
## A boss phase opener that speeds the robot up for good (WARDEN's Hunt drops down and strafes fast).

@export_range(1.0, 4.0, 0.05) var speed_scale := 1.8
@export var next_state := &"Approach"

var _done := false


func enter(_msg: Dictionary) -> void:
	if not _done:
		_done = true
		enemy.move_speed *= speed_scale
	machine.transition_to.call_deferred(next_state)
