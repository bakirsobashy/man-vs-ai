extends PlayerState
## Dodge roll: invulnerable for the first part, then a vulnerable tail and a short recovery. No cooldown.

var _direction := Vector2.RIGHT
var _elapsed := 0.0
var _finished := false


func enter(msg: Dictionary) -> void:
	_direction = msg.get("direction", Vector2.RIGHT)
	_elapsed = 0.0
	_finished = false
	player._second_wind_used = false
	player.rolling_invulnerable = true
	player.airborne = true
	player.body_animation.play(&"roll")
	player.roll_sound.play()
	player.haptic(player.haptic_roll_ms)


func exit() -> void:
	player.rolling_invulnerable = false
	player.airborne = false


func physics_update(delta: float) -> void:
	_elapsed += delta
	if _elapsed < player.roll_time:
		player.velocity = _direction * (player.roll_distance / player.roll_time)
		player.move_and_slide()
		player.rolling_invulnerable = _elapsed < player.roll_time * player.iframe_ratio
	elif _elapsed < player.roll_time + player.recovery_time:
		player.airborne = false
		if not _finished:
			_finished = true
			player.roll_finished()
		player.velocity = Vector2.ZERO
		player.rolling_invulnerable = false
	elif player.touch.touching:
		machine.transition_to(&"Run")
	else:
		player.settle()
