class_name ChallengeConsole
extends Interactable
## Starts the challenge arena's waves (the doors lock until they're beaten).

var used := false


func prompt_text() -> String:
	return tr("prompt.challenge")


func can_interact(_player: Player) -> bool:
	return not used


func interact(_player: Player) -> void:
	used = true
	EventBus.challenge_requested.emit()
