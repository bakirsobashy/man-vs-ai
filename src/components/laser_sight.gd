@icon("res://assets/art/placeholder/icon_emitter.svg")
class_name LaserSight
extends Line2D
## A sniper's laser sight (Sniper, WARDEN). point_at() stretches the line from this node toward a spot until the
## first wall or cover hit by the `ray` RayCast2D (a child; mask: world and cover), so cover blocks the laser.
## Keep the node unrotated at the robot's center; the Snipe state shows and hides it.

## Longest laser, in pixels.
@export_range(32.0, 800.0, 1.0, "suffix:px") var max_length := 420.0
@export var ray: RayCast2D


## Aims the laser at `spot`. Returns where it ends.
func point_at(spot: Vector2) -> Vector2:
	var direction := (spot - global_position).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	var end := global_position + direction * max_length
	if ray != null:
		ray.target_position = ray.to_local(end)
		ray.force_raycast_update()
		if ray.is_colliding():
			end = ray.get_collision_point()
	points = PackedVector2Array([Vector2.ZERO, to_local(end)])
	return end
