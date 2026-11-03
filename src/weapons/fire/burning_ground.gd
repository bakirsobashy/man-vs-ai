class_name BurningGround
extends Area2D
## Burning ground left by the Toaster Cannon's toast. Every robot body on it takes `damage` on each BurnTimer tick
## until LifeTimer removes it. Only robots burn (mask: enemies). Timer timeouts are connected in the scene.

@export_range(0, 50) var damage := 3


func _on_burn_timer_timeout() -> void:
	for body: Node2D in get_overlapping_bodies():
		var enemy := body as Enemy
		if enemy != null:
			enemy.take_damage(damage)


func _on_life_timer_timeout() -> void:
	queue_free()
