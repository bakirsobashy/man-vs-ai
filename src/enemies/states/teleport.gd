extends EnemyState
## GLITCH blinks out, reappears at a TeleportSpot at least min_distance from the hero, and blinks in.
## The AttackAnimation's blink_out and blink_in animations fade the boss; their lengths set the timing.

@export_range(0.0, 400.0, 1.0, "suffix:px") var min_distance := 120.0
@export var next_state := &"Approach"

var _phase := 0
var _left := 0.0


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	_phase = 0
	enemy.attack_animation.play(&"blink_out")
	_left = enemy.attack_animation.current_animation_length / enemy.attack_animation.speed_scale


func exit() -> void:
	enemy.attack_animation.play(&"RESET")


func physics_update(delta: float) -> void:
	_left -= delta
	if _left > 0.0:
		return
	if _phase == 0:
		_phase = 1
		enemy.global_position = pick_spot()
		enemy.attack_animation.play(&"blink_in")
		_left = enemy.attack_animation.current_animation_length / enemy.attack_animation.speed_scale
	else:
		machine.transition_to(next_state)


## A random spot far enough from the hero (or the farthest one).
func pick_spot() -> Vector2:
	var spots := TeleportSpots.all(get_tree())
	if spots.is_empty() or enemy.player == null:
		return enemy.global_position
	var far := spots.filter(func(spot: Vector2) -> bool: return spot.distance_to(enemy.player.global_position) >= min_distance)
	if far.is_empty():
		spots.sort_custom(func(a: Vector2, b: Vector2) -> bool:
			return a.distance_to(enemy.player.global_position) > b.distance_to(enemy.player.global_position))
		return spots[0]
	return far[randi_range(0, far.size() - 1)]
