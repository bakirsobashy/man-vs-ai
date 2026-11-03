@icon("res://assets/art/placeholder/icon_emitter.svg")
class_name BulletEmitter
extends Marker2D
## Fires a bullet pattern from this point. Rotate the node in the editor to aim patterns that aren't aimed.

## The bullet scene to fire. A BulletPool for it must exist in the level.
@export var bullet_scene: PackedScene
## Bullets per volley, spread evenly across spread_deg.
@export_range(1, 64) var count := 1
## Total fan angle of one volley.
@export_range(0.0, 360.0, 1.0, "suffix:°") var spread_deg := 0.0
## Volleys per fire() call.
@export_range(1, 20) var burst := 1
## Time between the volleys of one burst.
@export_range(0.0, 2.0, 0.01, "suffix:s") var burst_interval := 0.15
## Aim at the first node of target_group instead of using this node's rotation.
@export var aimed := true
## Group whose first node is the aim target.
@export var target_group := &"player"
## Turns the emitter after every volley (rotating turret patterns).
@export_range(-180.0, 180.0, 0.5, "suffix:°") var rotate_per_volley_deg := 0.0

var _volleys_left := 0
var _next_volley_in := 0.0
var _pool: BulletPool


func fire() -> void:
	_volleys_left = burst
	_next_volley_in = 0.0


func stop() -> void:
	_volleys_left = 0


## Seconds from the first volley to the last.
func burst_duration() -> float:
	return (burst - 1) * burst_interval


func _physics_process(delta: float) -> void:
	if _volleys_left <= 0:
		return
	_next_volley_in -= delta
	if _next_volley_in > 0.0:
		return
	_volley()
	_volleys_left -= 1
	_next_volley_in = burst_interval
	rotation_degrees += rotate_per_volley_deg


func _volley() -> void:
	if _pool == null:
		_pool = BulletPool.find_for(get_tree(), bullet_scene)
	if _pool == null:
		return
	var base := Vector2.RIGHT.rotated(global_rotation)
	if aimed:
		var target := get_tree().get_first_node_in_group(target_group) as Node2D
		if target != null:
			base = (target.global_position - global_position).normalized()
	var spread := deg_to_rad(spread_deg)
	var step := spread / (count - 1) if count > 1 else 0.0
	var start := -spread * 0.5 if count > 1 else 0.0
	for i: int in count:
		_pool.spawn(global_position, base.rotated(start + step * i))
