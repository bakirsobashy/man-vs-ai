extends EnemyState
## WARDEN's suppressive fire: turns the emitter to one side of the hero and lets its burst sweep `arc_deg` across
## him (the emitter's rotate_per_volley is set from the arc and its burst count). Set `aimed` off on the emitter.

@export var emitter: BulletEmitter
@export_range(10.0, 360.0, 1.0, "suffix:°") var arc_deg := 100.0
@export_range(0.0, 2.0, 0.05, "suffix:s") var recover_time := 0.3
@export var next_state := &"Approach"

var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	var side := 1.0 if randf() < 0.5 else -1.0
	var toward := enemy.to_player().angle() if enemy.player != null else PI * 0.5
	emitter.global_rotation = toward - deg_to_rad(arc_deg) * 0.5 * side
	emitter.rotate_per_volley_deg = arc_deg / maxf(emitter.burst - 1, 1) * side
	emitter.fire()
	_left = emitter.burst_duration() + recover_time


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		machine.transition_to(next_state)
