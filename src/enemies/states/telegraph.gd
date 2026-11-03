extends EnemyState
## The attack tell: plays an AttackAnimation animation (its length is the tell, at least 0.4 s), then
## switches to next_state. Chargers lock their aim here and point aim_node along it.

## Animation in the enemy's AttackAnimation player.
@export var animation_name := &"telegraph"
@export var next_state := &"Attack"
## Remember the direction to the hero now (the attack goes there even if the hero moves).
@export var lock_aim := false
## Optional node rotated to the locked direction (a charger's aim line).
@export var aim_node: Node2D

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	if lock_aim:
		var to_player := enemy.to_player()
		enemy.locked_direction = to_player.normalized() if to_player != Vector2.ZERO else Vector2.DOWN
		if aim_node != null:
			aim_node.rotation = enemy.locked_direction.angle()
	enemy.attack_animation.play(animation_name)
	_left = enemy.attack_animation.current_animation_length


func exit() -> void:
	if _left > 0.0:
		enemy.attack_animation.play(&"RESET")


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
