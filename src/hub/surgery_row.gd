class_name SurgeryRow
extends Button
## One body slot on the surgery panel (pre-placed in lab.tscn, one per slot). Shows the slot's tier; pressing it
## selects the slot (selected is connected to LabUI in the scene).

signal selected(slot_name: String)

@export var slot_name := "heart"
@export var slot_label := "Heart"


func refresh(catalog: ImplantCatalog) -> void:
	var tier := GameState.implant_tier(slot_name)
	var tiers := ["Human", "Mk I", "Mk II", "Mk III"]
	text = "%s\n%s" % [slot_label, tiers[tier] if catalog.has_slot(slot_name) else "—"]


func _on_pressed() -> void:
	selected.emit(slot_name)
