class_name HeroVisual
extends Node2D
## Kade's paper doll (docs/technical.md §9): the body plus one pre-placed overlay node per implant slot and tier,
## named "<Slot>Mk<tier>" under Implants (HeartMk1, LegsMk3…). Only the installed tier of each slot is shown.

## Follow GameState's implants (off for previews that show other tiers).
@export var follow_game_state := true

@onready var implants_root: Node2D = %Implants


func _ready() -> void:
	if follow_game_state:
		EventBus.implants_changed.connect(refresh)
		refresh()


func refresh() -> void:
	show_implants(GameState.implants)


## Shows the overlay for each slot's tier and hides the rest.
func show_implants(installed: Dictionary[String, int]) -> void:
	for child: Node in implants_root.get_children():
		var overlay := child as CanvasItem
		var name_parts := String(child.name).split("Mk")
		if overlay == null or name_parts.size() != 2:
			continue
		overlay.visible = installed.get(name_parts[0].to_lower(), 0) == int(name_parts[1])
