class_name HoloCage
extends Node2D
## GLITCH's holo-walls around the hero. Its walls block movement and bullets; the gaps at the corners don't.
## LifeTimer (connected in the scene) removes it.


func _on_life_timer_timeout() -> void:
	queue_free()
