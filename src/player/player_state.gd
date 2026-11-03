class_name PlayerState
extends State
## Base for the hero's states (child nodes of the Player's StateMachine). Override the touch handlers you need.

@onready var player: Player = owner as Player


func on_touch_started() -> void:
	pass


func on_rolled(_direction: Vector2) -> void:
	pass


func on_lifted() -> void:
	pass
