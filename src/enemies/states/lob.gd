extends EnemyState
## Grenadiers and FORGEMOTHER: copy a grenade scene into the drop layer and lob it at the hero's position
## (plus up to `scatter` px of random spread per grenade after the first).

@export var grenade_scene: PackedScene
@export_range(1, 8) var count := 1
@export_range(0.0, 96.0, 1.0, "suffix:px") var scatter := 0.0
@export var next_state := &"Approach"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	lob()
	machine.transition_to.call_deferred(next_state)


## Throws `count` grenades. Returns how many were thrown.
func lob() -> int:
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if grenade_scene == null or layer == null or enemy.player == null:
		return 0
	for i: int in count:
		var spot := enemy.player.global_position
		if i > 0:
			spot += Vector2(randf_range(-scatter, scatter), randf_range(-scatter, scatter))
		var grenade := grenade_scene.instantiate() as Grenade
		layer.add_child(grenade)
		grenade.launch(enemy.global_position, spot)
	return count
