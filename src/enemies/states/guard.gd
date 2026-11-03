extends EnemyState
## Shield-bots (docs/content.md §2): advance slowly while the frontal shield (ShieldPivot) turns toward the hero at
## turn_speed; after `duration` the shield drops for the attack (the attack window) and comes back up next time.

@export var shield_pivot: Node2D
## The shield's collision shape (enemy_shields layer: only player bullets hit it).
@export var shield_shape: CollisionShape2D
@export_range(0.0, 360.0, 1.0, "suffix:°/s") var turn_speed := 60.0
@export_range(0.0, 1.0, 0.05) var advance_ratio := 0.5
@export_range(0.5, 10.0, 0.1, "suffix:s") var duration := 2.5
@export var attack_state := &"Telegraph"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	_left = duration / enemy.attack_rate
	set_shield(true)


func physics_update(delta: float) -> void:
	if enemy.player == null:
		return
	var to_hero := enemy.to_player()
	shield_pivot.rotation = rotate_toward(shield_pivot.rotation, to_hero.angle(), deg_to_rad(turn_speed) * delta)
	if to_hero.length() > 72.0:
		enemy.velocity = enemy.direction_toward(enemy.player.global_position) * enemy.move_speed * advance_ratio
		enemy.move_and_slide()
	_left -= delta
	if _left <= 0.0:
		set_shield(false)
		machine.transition_to(attack_state)


func set_shield(up: bool) -> void:
	shield_shape.set_deferred(&"disabled", not up)
	shield_pivot.modulate.a = 1.0 if up else 0.35
