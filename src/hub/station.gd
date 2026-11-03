class_name Station
extends Interactable
## A lab station (surgery chair, armory, elevator). Its prompt reports `action` through EventBus.station_used;
## the LabDirector opens the matching panel.

@export var prompt := "Use"
## surgery, armory or elevator.
@export var action := &"surgery"


func prompt_text() -> String:
	return prompt


func interact(_player: Player) -> void:
	EventBus.station_used.emit(action)
