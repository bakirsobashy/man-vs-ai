extends EnemyState
## WARDEN's EMP pulses: copies `count` zone scenes (emp_zone.tscn) into the drop layer, the first on the hero and the
## rest up to `scatter` px around him. The zones warn first, then short out cover.

@export var zone_scene: PackedScene
@export_range(1, 8) var count := 1
@export_range(0.0, 160.0, 1.0, "suffix:px") var scatter := 64.0
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	drop_zones()
	machine.transition_to.call_deferred(next_state)


## Returns how many zones were placed.
func drop_zones() -> int:
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if zone_scene == null or layer == null or enemy.player == null:
		return 0
	for i: int in count:
		var spot := enemy.player.global_position
		if i > 0:
			spot += Vector2.from_angle(randf() * TAU) * randf_range(scatter * 0.5, scatter)
		var zone := zone_scene.instantiate() as Node2D
		zone.position = layer.to_local(spot)
		layer.add_child(zone)
	return count
