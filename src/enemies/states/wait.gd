extends EnemyState
## Stands still for a random time, then switches to next_state (turrets between volleys).

@export_range(0.0, 10.0, 0.1, "suffix:s") var duration_min := 1.2
@export_range(0.0, 10.0, 0.1, "suffix:s") var duration_max := 1.8
@export var next_state := &"Telegraph"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	_left = randf_range(duration_min, duration_max) / enemy.attack_rate


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
