extends EnemyState
## Fires a BulletEmitter's pattern, waits for the burst plus recover_time, then switches to next_state.

@export var emitter: BulletEmitter
## Pause after the last volley.
@export_range(0.0, 5.0, 0.05, "suffix:s") var recover_time := 0.4
@export var next_state := &"Approach"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	emitter.fire()
	_left = emitter.burst_duration() + recover_time


func exit() -> void:
	emitter.stop()


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
