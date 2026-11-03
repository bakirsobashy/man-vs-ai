extends EnemyState
## GLITCH boxes the hero in: a holo_cage.tscn copy (walls with gaps at the corners) appears around the hero in the
## drop layer; the cage removes itself when its LifeTimer ends.

@export var cage_scene: PackedScene
@export var next_state := &"Fan"


func enter(_msg: Dictionary) -> void:
	enemy.velocity = Vector2.ZERO
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if cage_scene != null and layer != null and enemy.player != null:
		var cage := cage_scene.instantiate() as Node2D
		cage.position = layer.to_local(enemy.player.global_position)
		layer.add_child.call_deferred(cage)
	machine.transition_to.call_deferred(next_state)
