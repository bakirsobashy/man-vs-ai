extends PlayerState
## Finger up and no cover in range: stand still, exposed, and reload.


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.set_reload_speed(player.reload_speed_standing)
	player.partial_reload_timer.start()


func exit() -> void:
	player.partial_reload_timer.stop()


func physics_update(_delta: float) -> void:
	player.update_aim(Vector2.ZERO)


func on_touch_started() -> void:
	machine.transition_to(&"Run")
