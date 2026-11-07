class_name HeroVisual
extends Node2D
## Kade's paper doll (docs/technical.md §9): the body plus one pre-placed overlay node per implant slot and tier,
## named "<Slot>Mk<tier>" under Implants (HeartMk1, LegsMk3…). Only the installed tier of each slot is shown.

## Follow GameState's implants (off for previews that show other tiers).
@export var follow_game_state := true
## Cosmetics (M6): the equipped outfit tints the body. Outfits never cover the implant overlays.
@export var cosmetic_catalog: CosmeticCatalog

@onready var implants_root: Node2D = %Implants
@onready var body: CanvasItem = %Body


func _ready() -> void:
	EventBus.cosmetics_changed.connect(apply_outfit)
	apply_outfit()
	if follow_game_state:
		EventBus.implants_changed.connect(refresh)
		refresh()


func refresh() -> void:
	show_implants(GameState.implants)
	apply_outfit()


## The equipped outfit's look on the body (every paper doll shows it, previews included).
func apply_outfit() -> void:
	var outfit := cosmetic_catalog.equipped(CosmeticData.Kind.OUTFIT) if cosmetic_catalog != null else null
	body.self_modulate = outfit.tint if outfit != null else Color.WHITE


## Shows the overlay for each slot's tier and hides the rest.
func show_implants(installed: Dictionary[String, int]) -> void:
	for child: Node in implants_root.get_children():
		var overlay := child as CanvasItem
		var name_parts := String(child.name).split("Mk")
		if overlay == null or name_parts.size() != 2:
			continue
		overlay.visible = installed.get(name_parts[0].to_lower(), 0) == int(name_parts[1])
