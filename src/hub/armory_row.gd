class_name ArmoryRow
extends HBoxContainer
## One gun in Patch's armory (a copy of armory_row.tscn per weapon catalog entry).

signal unlock_requested(entry: WeaponCatalogEntry)

const RARITY_NAMES: Array[String] = ["rarity.common", "rarity.rare", "rarity.epic", "rarity.legendary"]

@onready var name_label: Label = %NameLabel
@onready var rarity_label: Label = %RarityLabel
@onready var buy_button: Button = %BuyButton

var entry: WeaponCatalogEntry


func show_entry(catalog_entry: WeaponCatalogEntry, display_name: String) -> void:
	entry = catalog_entry
	name_label.text = display_name
	rarity_label.text = tr(RARITY_NAMES[entry.rarity])
	refresh()


func refresh() -> void:
	var owned := GameState.is_unlocked(entry.id)
	if owned:
		buy_button.text = tr("armory.owned")
	elif entry.unlock_hint != "":
		buy_button.text = tr(entry.unlock_hint)
	else:
		buy_button.text = tr("armory.price") % entry.unlock_cost
	buy_button.disabled = owned or entry.unlock_hint != "" or GameState.crypto < entry.unlock_cost


func _on_buy_button_pressed() -> void:
	unlock_requested.emit(entry)
