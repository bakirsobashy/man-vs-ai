extends PlayerState
## Finger down: move with the joystick and auto-fire at the current target (run & gun).


func enter(_msg: Dictionary) -> void:
	player.set_reload_speed(player.reload_speed_running)


func physics_update(_delta: float) -> void:
	var move := player.touch.move_vector
	player.velocity = move * player.move_speed * player.weapon.move_speed_scale() * player.slow_scale()
	player.move_and_slide()
	player.update_aim(move)
	player.try_fire()


func on_rolled(direction: Vector2) -> void:
	machine.transition_to(&"Roll", {"direction": direction})


func on_lifted() -> void:
	player.settle()
