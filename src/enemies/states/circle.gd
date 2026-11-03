extends EnemyState
## Drones (docs/content.md §2): fly a circle around the hero, over walls and cover, inside the room's
## CameraBounds; attack after a random delay. Flyers have no collision mask, so they move by position.

@export_range(16.0, 240.0, 1.0, "suffix:px") var radius := 88.0
## Turning speed around the hero.
@export_range(0.0, 360.0, 1.0, "suffix:°/s") var orbit_speed_deg := 70.0
@export var attack_state := &"Telegraph"
@export_range(0.0, 10.0, 0.1, "suffix:s") var attack_delay_min := 1.4
@export_range(0.0, 10.0, 0.1, "suffix:s") var attack_delay_max := 2.4
## Stays this far inside the room's CameraBounds.
@export_range(0.0, 64.0, 1.0, "suffix:px") var margin := 20.0

var _wait := 0.0
var _direction := 1.0


func enter(_msg: Dictionary) -> void:
	_wait = randf_range(attack_delay_min, attack_delay_max) / enemy.attack_rate
	_direction = 1.0 if randf() < 0.5 else -1.0


func physics_update(delta: float) -> void:
	if enemy.player == null:
		return
	var around := enemy.global_position - enemy.player.global_position
	if around == Vector2.ZERO:
		around = Vector2.UP
	var angle := around.angle() + deg_to_rad(orbit_speed_deg) * _direction * delta
	var goal := enemy.player.global_position + Vector2.from_angle(angle) * radius
	var step := (goal - enemy.global_position).limit_length(enemy.move_speed * delta)
	enemy.global_position = _inside_room(enemy.global_position + step)
	_wait -= delta
	if _wait <= 0.0:
		machine.transition_to(attack_state)


func _inside_room(at: Vector2) -> Vector2:
	var room := enemy.get_parent().get_parent() as Room
	if room == null or room.camera_bounds == null:
		return at
	var rect := room.camera_bounds.get_global_rect().grow(-margin)
	return at.clamp(rect.position, rect.end)
