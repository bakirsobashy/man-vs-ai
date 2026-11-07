class_name CosmeticRow
extends HBoxContainer
## One cosmetic in the lab shop (a copy of cosmetic_row.tscn per item of the listed kind). The button says what a tap
## does: buy (the price), equip, "Equipped", or show / hide for a lab decoration.

signal action_requested(item: CosmeticData)

@onready var name_label: Label = %NameLabel
@onready var detail_label: Label = %DetailLabel
@onready var action_button: Button = %ActionButton

var item: CosmeticData
var catalog: CosmeticCatalog


func show_item(cosmetic: CosmeticData, from: CosmeticCatalog) -> void:
	item = cosmetic
	catalog = from
	name_label.text = cosmetic.display_name
	detail_label.text = cosmetic.description
	refresh()


func refresh() -> void:
	action_button.disabled = false
	if not catalog.is_owned(item):
		action_button.text = item.price_label
	elif item.kind == CosmeticData.Kind.LAB_DECOR:
		action_button.text = "Hide" if catalog.decor_visible(item) else "Show"
	elif catalog.equipped(item.kind) == item:
		action_button.text = "Equipped"
		action_button.disabled = true
	else:
		action_button.text = "Equip"


func _on_action_button_pressed() -> void:
	action_requested.emit(item)
