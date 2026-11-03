extends EnemyState
## Dashes along the locked direction. Smashes cover it runs into (docs/content.md §2, Charger) and is
## stunned after hitting a wall or cover; otherwise stops after max_distance.

@export_range(0.0, 800.0, 1.0, "suffix:px/s") var speed := 260.0
@export_range(0.0, 600.0, 1.0, "suffix:px") var max_distance := 200.0
## Damage to heavy cover (light and medium cover breaks outright).
@export_range(0, 999) var heavy_cover_damage := 150
@export var stunned_state := &"Stunned"
@export_range(0.0, 5.0, 0.1, "suffix:s") var stun_time := 1.0
@export var next_state := &"Approach"

var _travelled := 0.0


func enter(_msg: Dictionary) -> void:
	_travelled = 0.0


func physics_update(delta: float) -> void:
	var motion := enemy.locked_direction * speed * delta
	var hit := enemy.move_and_collide(motion)
	_travelled += motion.length()
	if hit == null:
		if _travelled >= max_distance:
			machine.transition_to(next_state)
		return
	var collider := hit.get_collider()
	var cover := collider as Cover
	if cover != null:
		cover.smash(heavy_cover_damage)
	if cover != null or collider is TileMapLayer:
		EventBus.screen_shake_requested.emit(0.3)
		machine.transition_to(stunned_state, {"duration": stun_time})
	else:
		machine.transition_to(next_state)
