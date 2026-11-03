extends PlayerState
## Crouched behind cover: protected from the cover's side, fastest reload, no firing.


func enter(msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.take_cover(msg.get("spot") as CoverSpot)
	player.set_reload_speed(player.reload_speed_cover)
	player.partial_reload_timer.start()


func exit() -> void:
	player.partial_reload_timer.stop()
	player.leave_cover()


func physics_update(_delta: float) -> void:
	player.update_aim(Vector2.ZERO)


func on_touch_started() -> void:
	machine.transition_to(&"Run")
