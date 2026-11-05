extends EnemyState
## Null Knight and ZERO: a dodge roll sideways across the incoming bullet (or around the hero). Bullets pass through
## while it lasts (Enemy.dodging), like the hero's i-frames.

@export_range(0.0, 160.0, 1.0, "suffix:px") var distance := 56.0
@export_range(0.1, 1.0, 0.05, "suffix:s") var time := 0.3
@export var next_state := &"Approach"
## Sprite tint while rolling.
@export var roll_tint := Color(1, 1, 1, 0.45)

var _direction := Vector2.RIGHT
var _left := 0.0


func enter(msg: Dictionary) -> void:
	var incoming: Vector2 = msg.get("bullet_direction", Vector2.ZERO)
	var across := incoming.orthogonal() if incoming != Vector2.ZERO else enemy.to_player().orthogonal()
	_direction = across.normalized() * (1.0 if randf() < 0.5 else -1.0)
	if _direction == Vector2.ZERO:
		_direction = Vector2.RIGHT
	_left = time
	enemy.dodging = true
	enemy.sprite.modulate = roll_tint


func exit() -> void:
	enemy.dodging = false
	enemy.sprite.modulate = Color.WHITE


func physics_update(delta: float) -> void:
	_left -= delta
	enemy.velocity = _direction * distance / time
	enemy.move_and_slide()
	if _left <= 0.0:
		machine.transition_to(next_state)
