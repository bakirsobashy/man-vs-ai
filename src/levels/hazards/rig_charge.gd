class_name RigCharge
extends Node2D
## A Hacker's charge on a piece of cover (a copy added as the cover's child). It blinks red for the FuseTimer's wait
## (1.5 s), then explodes: the explosion copy goes to the drop layer and the cover breaks.

@export var explosion_scene: PackedScene


func _on_fuse_timer_timeout() -> void:
	var cover := get_parent() as Cover
	var layer := get_tree().get_first_node_in_group(&"drop_layer") as Node2D
	if explosion_scene != null and layer != null:
		var blast := explosion_scene.instantiate() as Node2D
		blast.position = layer.to_local(global_position)
		layer.add_child(blast)
	if cover != null and cover.is_intact():
		cover.take_damage(cover.hp)
	queue_free()
