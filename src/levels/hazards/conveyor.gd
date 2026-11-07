class_name Conveyor
extends Area2D
## A conveyor belt (The Foundry): pushes the hero and walking robots on it along its local +X axis. Rotate the node in
## the editor to aim it. FORGEMOTHER's Overtime speeds belts up and reverses them through speed_scale.

## Push speed along the belt.
@export_range(0.0, 200.0, 1.0, "suffix:px/s") var push_speed := 40.0
## Multiplier (negative reverses the belt). The Belt sprite's scroll animation follows it.
@export var speed_scale := 1.0

@onready var belt_animation: AnimationPlayer = %BeltAnimation


func _physics_process(delta: float) -> void:
	var push := Vector2.RIGHT.rotated(global_rotation) * push_speed * speed_scale * delta
	for body: Node2D in get_overlapping_bodies():
		var mover := body as CharacterBody2D
		var enemy := body as Enemy
		if mover == null or (enemy != null and (enemy.spawn_kind == Enemy.SpawnKind.FLYER or enemy.is_boss)):
			continue
		mover.move_and_collide(push)


func set_speed_scale(value: float) -> void:
	speed_scale = value
	belt_animation.speed_scale = value
