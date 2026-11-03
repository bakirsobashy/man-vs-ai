@icon("res://assets/art/placeholder/icon_drops.svg")
class_name Drops
extends Node
## What its owner leaves behind: copies of authored pickup scenes, placed in the "drop_layer" node of the
## current room (or of a test level). Enemies call drop() when they die; the WaveSpawner uses one for wave rewards.

## RAM dropped every time (MB). Robots always drop RAM.
@export_range(0, 999) var ram_mb := 0
@export var ram_scene: PackedScene
## Crypto dropped every time, picked between min and max.
@export_range(0, 999) var crypto_min := 0
@export_range(0, 999) var crypto_max := 0
@export var crypto_scene: PackedScene
## Optional extra drops, each rolled separately.
@export var extras: Array[DropChance] = []
## Random offset around the drop point.
@export_range(0.0, 48.0, 1.0, "suffix:px") var scatter := 10.0


func drop(at: Vector2) -> void:
	var layer := get_tree().get_first_node_in_group(&"drop_layer")
	if layer == null:
		return
	if ram_mb > 0 and ram_scene != null:
		_spawn(layer, ram_scene, at, ram_mb)
	var crypto := randi_range(crypto_min, crypto_max)
	if crypto > 0 and crypto_scene != null:
		_spawn(layer, crypto_scene, at, crypto)
	for extra: DropChance in extras:
		if extra.scene != null and randf() < extra.chance:
			_spawn(layer, extra.scene, at, extra.amount)


func _spawn(layer: Node, scene: PackedScene, at: Vector2, amount: int) -> void:
	var pickup := scene.instantiate() as Pickup
	pickup.amount = amount
	var offset := Vector2(randf_range(-scatter, scatter), randf_range(-scatter, scatter))
	pickup.position = (layer as Node2D).to_local(at + offset) if layer is Node2D else at + offset
	layer.add_child.call_deferred(pickup)
