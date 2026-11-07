extends EnemyState
## Snipers relocate after each shot: walk to a random spot `min_distance`–`max_distance` from the hero inside the
## room's CameraBounds, for at most `max_time`.

@export_range(0.0, 400.0, 1.0, "suffix:px") var min_distance := 160.0
@export_range(0.0, 400.0, 1.0, "suffix:px") var max_distance := 260.0
@export_range(0.2, 5.0, 0.1, "suffix:s") var max_time := 1.6
## Stays this far inside the room's CameraBounds.
@export_range(0.0, 64.0, 1.0, "suffix:px") var margin := 24.0
@export_range(0.5, 3.0, 0.1) var speed_scale := 1.4
@export var next_state := &"Approach"

var _goal := Vector2.ZERO
var _left := 0.0


func enter(_msg: Dictionary) -> void:
	_left = max_time
	_goal = pick_spot()


## A random spot at sniping distance from the hero, inside the room.
func pick_spot() -> Vector2:
	var hero := enemy.player.global_position if enemy.player != null else enemy.global_position
	var room := enemy.get_parent().get_parent() as Room
	var rect := Rect2(hero - Vector2.ONE * max_distance, Vector2.ONE * max_distance * 2.0)
	if room != null and room.camera_bounds != null:
		rect = room.camera_bounds.get_global_rect().grow(-margin)
	for _i: int in 12:
		var spot := hero + Vector2.from_angle(randf() * TAU) * randf_range(min_distance, max_distance)
		if rect.has_point(spot):
			return spot
	return rect.get_center()


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0 or enemy.global_position.distance_to(_goal) < 8.0:
		machine.transition_to(next_state)
		return
	enemy.velocity = enemy.direction_toward(_goal) * enemy.move_speed * speed_scale
	enemy.move_and_slide()
