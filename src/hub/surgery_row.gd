class_name SurgeryRow
extends Button
## One body slot on the surgery panel (pre-placed in lab.tscn, one per slot). Shows the slot's tier; pressing it
## selects the slot (selected is connected to LabUI in the scene).

signal selected(slot_name: String)

@export var slot_name := "heart"
@export var slot_label := "implant_slot.heart"


func refresh(catalog: ImplantCatalog) -> void:
	var tier := GameState.implant_tier(slot_name)
	var tiers: Array[String] = ["implant.tier_human", "implant.tier_mk1", "implant.tier_mk2", "implant.tier_mk3"]
	text = "%s\n%s" % [tr(slot_label), tr(tiers[tier]) if catalog.has_slot(slot_name) else "—"]


func _on_pressed() -> void:
	selected.emit(slot_name)
