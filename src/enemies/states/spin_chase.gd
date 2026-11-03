extends EnemyState
## SCRAPJAW's grind (phase 3): spins its jaw and walks at the hero while an emitter fires a bullet spiral.

@export var emitter: BulletEmitter
@export_range(0.5, 10.0, 0.1, "suffix:s") var duration := 3.0
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var speed := 46.0
## Rotated while spinning (the sprite).
@export var spin_node: Node2D
@export_range(0.0, 1440.0, 10.0, "suffix:°/s") var spin_speed_deg := 540.0
@export var next_state := &"GrindChargeTell"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	_left = duration
	emitter.fire()


func exit() -> void:
	emitter.stop()
	if spin_node != null:
		spin_node.rotation = 0.0


func physics_update(delta: float) -> void:
	_left -= delta
	if enemy.player != null:
		enemy.velocity = enemy.direction_toward(enemy.player.global_position) * speed
		enemy.move_and_slide()
	if spin_node != null:
		spin_node.rotation += deg_to_rad(spin_speed_deg) * delta
	if _left <= 0.0:
		machine.transition_to(next_state)
