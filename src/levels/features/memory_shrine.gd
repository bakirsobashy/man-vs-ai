class_name MemoryShrine
extends Interactable
## A memory of Lena and Mira (docs/narrative.md §8). Opening it shows the HUD memory panel; the first time it
## also heals.

@export var memory: MemoryData

var used := false


func prompt_text() -> String:
	return "Remember" if not used else "Remember again"


func interact(player: Player) -> void:
	EventBus.memory_opened.emit(memory.title, memory.text)
	if not used:
		used = true
		player.health.heal(memory.heal)
