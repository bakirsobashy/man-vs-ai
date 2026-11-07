extends EnemyState
## ZERO's Zero Hour: overclocks the robot (attack_rate: every wait and tell gets shorter) and switches on every
## FirewallLaser in `edge_group`, the arena edges that close in.

@export_range(1.0, 3.0, 0.05) var attack_rate := 1.5
@export var edge_group := &"zero_edges"
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	enemy.attack_rate = maxf(enemy.attack_rate, attack_rate)
	for node: Node in get_tree().get_nodes_in_group(edge_group):
		var edge := node as FirewallLaser
		if edge != null:
			edge.set_active(true)
	EventBus.screen_shake_requested.emit(0.6)
	machine.transition_to.call_deferred(next_state)
