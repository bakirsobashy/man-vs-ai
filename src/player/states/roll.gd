extends PlayerState
## Dodge roll: invulnerable for the first part, then a vulnerable tail and a short recovery. No cooldown.

var _direction := Vector2.RIGHT
var _elapsed := 0.0


func enter(msg: Dictionary) -> void:
	_direction = msg.get("direction", Vector2.RIGHT)
	_elapsed = 0.0
	player.rolling_invulnerable = true
	player.body_animation.play(&"roll")
	player.haptic(player.haptic_roll_ms)


func exit() -> void:
	player.rolling_invulnerable = false


func physics_update(delta: float) -> void:
	_elapsed += delta
	if _elapsed < player.roll_time:
		player.velocity = _direction * (player.roll_distance / player.roll_time)
		player.move_and_slide()
		player.rolling_invulnerable = _elapsed < player.roll_time * player.iframe_ratio
	elif _elapsed < player.roll_time + player.recovery_time:
		player.velocity = Vector2.ZERO
		player.rolling_invulnerable = false
	elif player.touch.touching:
		machine.transition_to(&"Run")
	else:
		player.settle()
