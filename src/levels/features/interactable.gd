@icon("res://assets/art/placeholder/icon_interact.svg")
class_name Interactable
extends Area2D
## Something the hero uses through the HUD prompt (layer: interactables). The hero's InteractSensor shows
## prompt_text() for the nearest one it can use; tapping the prompt calls interact().


func prompt_text() -> String:
	return ""


func can_interact(_player: Player) -> bool:
	return true


func interact(_player: Player) -> void:
	pass
