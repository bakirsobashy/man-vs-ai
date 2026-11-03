@icon("res://assets/art/placeholder/icon_target.svg")
class_name TargetSelector
extends Node
## Auto-aim (docs/GDD.md §4.5): the nearest visible enemy inside the weapon's Range area, kept sticky.
## Re-evaluated by the RetargetTimer node (its timeout is connected in the scene).

## Raycast used for line-of-sight checks (mask: world, cover).
@export var line_of_sight: RayCast2D
## Switch only when another enemy is closer than this share of the current target's distance.
@export_range(0.1, 1.0, 0.05) var switch_ratio := 0.7
## Drop a target that has been out of sight for this long.
@export_range(0.0, 1.0, 0.05, "suffix:s") var lost_sight_grace := 0.2

## The equipped weapon's Range area (set by the weapon's owner).
var range_area: Area2D
var current_target: Node2D
var _last_seen_at := 0.0


func _on_retarget_timer_timeout() -> void:
	if current_target != null and (not is_instance_valid(current_target) or not current_target.is_visible_in_tree() \
			or not _is_targetable(current_target)):
		current_target = null
	if range_area == null:
		current_target = null
		return
	var origin := line_of_sight.global_position
	var nearest: Node2D = null
	var nearest_distance := INF
	var current_distance := INF
	for body: Node2D in range_area.get_overlapping_bodies():
		if not body.is_in_group(&"enemies") or not body.is_visible_in_tree() or not _is_targetable(body) \
				or not _can_see(body):
			continue
		var distance := origin.distance_to(body.global_position)
		if body == current_target:
			current_distance = distance
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = body
	var now := Time.get_ticks_msec() / 1000.0
	if current_target != null and current_distance < INF:
		_last_seen_at = now
		if nearest != current_target and nearest_distance < current_distance * switch_ratio:
			current_target = nearest
		return
	if current_target != null and now - _last_seen_at <= lost_sight_grace:
		return
	current_target = nearest
	if nearest != null:
		_last_seen_at = now


func _is_targetable(body: Node2D) -> bool:
	return not body.has_method(&"is_targetable") or bool(body.call(&"is_targetable"))


func _can_see(body: Node2D) -> bool:
	line_of_sight.target_position = line_of_sight.to_local(body.global_position)
	line_of_sight.force_raycast_update()
	return not line_of_sight.is_colliding()
