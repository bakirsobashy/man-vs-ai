extends EnemyState
## Snipers and WARDEN: the laser sight tracks the hero for `aim_time` (the tell; cover blocks the laser), holds still
## for the last `lock_time`, then the emitter fires along the locked line. Threat Sight adds its bonus to the tell.

@export var laser: LaserSight
## Fires along the locked line (set `aimed` off on it).
@export var emitter: BulletEmitter
@export_range(0.4, 3.0, 0.05, "suffix:s") var aim_time := 1.0
## The laser stops following the hero this long before the shot.
@export_range(0.0, 1.0, 0.05, "suffix:s") var lock_time := 0.25
@export_range(0.0, 2.0, 0.05, "suffix:s") var recover_time := 0.3
@export var next_state := &"Relocate"
## Laser color while tracking, then once locked.
@export var track_color := Color(1, 0.2, 0.2, 0.45)
@export var lock_color := Color(1, 0.3, 0.3, 1)

var _left := 0.0
var _recover := 0.0
var _fired := false
var _aim := Vector2.ZERO


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	_left = aim_time / enemy.attack_rate + Player.telegraph_bonus
	_recover = recover_time
	_fired = false
	_aim = enemy.player.global_position if enemy.player != null else enemy.global_position + Vector2.DOWN
	laser.visible = true
	laser.default_color = track_color
	laser.point_at(_aim)


func exit() -> void:
	laser.visible = false


func physics_update(delta: float) -> void:
	if _fired:
		_recover -= delta
		if _recover <= 0.0:
			machine.transition_to(next_state)
		return
	_left -= delta
	if _left > lock_time and enemy.player != null:
		_aim = enemy.player.global_position
	else:
		laser.default_color = lock_color
	laser.point_at(_aim)
	if _left <= 0.0:
		_fire()


func _fire() -> void:
	_fired = true
	laser.visible = false
	emitter.global_rotation = (_aim - emitter.global_position).angle()
	emitter.fire()
