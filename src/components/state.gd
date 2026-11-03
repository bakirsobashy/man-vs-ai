@icon("res://assets/art/placeholder/icon_state.svg")
class_name State
extends Node
## One state of a StateMachine. Add it in the scene as a child node of the StateMachine.

var machine: StateMachine


func enter(_msg: Dictionary) -> void:
	pass


func exit() -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
