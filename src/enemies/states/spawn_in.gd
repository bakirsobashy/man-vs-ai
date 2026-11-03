extends EnemyState
## The enemy materializes (the spawn_in animation, 0.8 s): harmless and untargetable until it ends.

@export var next_state := &"Approach"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.spawning = true
	enemy.velocity = Vector2.ZERO
	enemy.flash_animation.play(&"spawn_in")
	_left = enemy.flash_animation.current_animation_length


func exit() -> void:
	enemy.spawning = false


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
