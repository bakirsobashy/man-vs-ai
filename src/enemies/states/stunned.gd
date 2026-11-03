extends EnemyState
## Dazed by an EMP or a charge into a wall: does nothing for the given duration, then switches to next_state.

@export_range(0.0, 5.0, 0.1, "suffix:s") var default_duration := 1.0
@export var next_state := &"Approach"
## Tint shown while stunned.
@export var stun_tint := Color(0.55, 0.8, 1.0)

var _left := 0.0


func enter(msg: Dictionary) -> void:
	_left = msg.get("duration", default_duration)
	enemy.velocity = Vector2.ZERO
	enemy.sprite.modulate = stun_tint
	if enemy.attack_animation != null:
		enemy.attack_animation.play(&"RESET")


func exit() -> void:
	enemy.sprite.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
