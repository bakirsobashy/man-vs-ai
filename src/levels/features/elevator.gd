class_name Elevator
extends Interactable
## The way out of a boss room. Hidden until the boss falls; its prompt starts the next level.

var revealed := false


func reveal() -> void:
	revealed = true
	visible = true


func prompt_text() -> String:
	return tr("prompt.elevator")


func can_interact(_player: Player) -> bool:
	return revealed


func interact(_player: Player) -> void:
	EventBus.level_exit_requested.emit()
