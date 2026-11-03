extends EnemyState
## Goes straight back into the current boss phase's loop (the next state after a stun or the spawn-in).

@export var phases: BossPhases


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	machine.transition_to.call_deferred(phases.loop_state())
