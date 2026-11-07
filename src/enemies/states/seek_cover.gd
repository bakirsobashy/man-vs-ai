extends EnemyState
## Null Knight and ZERO take cover like the hero: walk to the far side (from the hero) of the nearest intact cover
## within `search_radius`, for at most `max_time`, then attack from there. Without cover nearby it attacks at once.

@export_range(0.0, 400.0, 1.0, "suffix:px") var search_radius := 140.0
## Distance kept from the cover's center on the far side.
@export_range(0.0, 64.0, 1.0, "suffix:px") var clearance := 20.0
@export_range(0.2, 5.0, 0.1, "suffix:s") var max_time := 1.4
@export var next_state := &"Telegraph"

var _goal := Vector2.ZERO
var _left := 0.0
var cover: Cover


func enter(_msg: Dictionary) -> void:
	_left = max_time
	cover = nearest_cover()
	_goal = enemy.global_position
	if cover != null and enemy.player != null:
		_goal = cover.global_position + (cover.global_position - enemy.player.global_position).normalized() * clearance


## The nearest intact cover in range (the room's Cover node), or null.
func nearest_cover() -> Cover:
	var room := enemy.get_parent().get_parent() as Room
	var root := room.get_node_or_null(^"Cover") if room != null else null
	if root == null:
		return null
	var best: Cover = null
	var best_distance := search_radius
	for node: Node in root.get_children():
		var candidate := node as Cover
		if candidate == null or not candidate.provides_cover or not candidate.is_intact():
			continue
		var d := candidate.global_position.distance_to(enemy.global_position)
		if d < best_distance:
			best_distance = d
			best = candidate
	return best


func physics_update(delta: float) -> void:
	_left -= delta
	if _left <= 0.0 or enemy.global_position.distance_to(_goal) < 6.0:
		machine.transition_to(next_state)
		return
	enemy.velocity = enemy.direction_toward(_goal) * enemy.move_speed
	enemy.move_and_slide()
