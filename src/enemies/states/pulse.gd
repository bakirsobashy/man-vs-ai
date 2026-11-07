extends EnemyState
## EMP-bots: after the Telegraph, a pulse shoves the hero `knockback` px away (and out of cover) if he's within
## `radius`. Rolling dodges it. Plays the AttackAnimation's `pulse` ring.

@export_range(16.0, 160.0, 1.0, "suffix:px") var radius := 56.0
@export_range(0.0, 120.0, 1.0, "suffix:px") var knockback := 48.0
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	enemy.attack_animation.play(&"pulse")
	pulse()
	machine.transition_to.call_deferred(next_state)


## True when the hero was in range and got shoved.
func pulse() -> bool:
	if enemy.player == null:
		return false
	var offset := enemy.player.global_position - enemy.global_position
	if offset.length() > radius:
		return false
	var away := offset.normalized() if offset != Vector2.ZERO else Vector2.DOWN
	return enemy.player.knock_back(away * knockback)
