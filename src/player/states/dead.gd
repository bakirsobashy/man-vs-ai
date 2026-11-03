extends PlayerState
## Out of hearts. In the M1 greybox the RespawnTimer brings the hero back (see Player._on_respawn_timer_timeout).


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.reticle.visible = false
	player.flash_animation.play(&"dead")
	if player.auto_respawn:
		player.respawn_timer.start()
