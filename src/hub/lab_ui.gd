class_name LabUI
extends CanvasLayer
## The lab's panels (lab.tscn): Dr. Vorn's surgery, Patch's armory, the dialogue box, and first-implant comics.
## Every panel, row and button is a node in the scene; armory rows are copies of armory_row.tscn, one per catalog gun.
## Runs while the game is paused, and pauses it while a panel is open.

## Ram costs and effects of every installable tier.
@export var implant_catalog: ImplantCatalog
@export var weapon_catalog: WeaponCatalog
@export var armory_row_scene: PackedScene
## Patch's lines after a sale (cycled).
@export var patch_lines: LineSet
## First-install comic per slot (slot name → comic scene); slots without one just get Vorn's line.
@export var implant_comics: Dictionary[String, PackedScene] = {}

@onready var surgery_panel: Control = %SurgeryPanel
@onready var doll: HeroVisual = %Doll
@onready var implant_name: Label = %ImplantName
@onready var implant_info: Label = %ImplantInfo
@onready var install_button: HoldButton = %InstallButton
@onready var slot_rows: Control = %SlotRows
@onready var armory_panel: Control = %ArmoryPanel
@onready var armory_info: Label = %ArmoryInfo
@onready var armory_list: Control = %ArmoryList
@onready var dialogue: DialogueBox = %Dialogue
@onready var comic_layer: Control = %ComicLayer
@onready var purchase_sound: AudioStreamPlayer = %PurchaseSound

var _slot := "heart"
var _sales := 0


func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)


func open_surgery() -> void:
	_select_slot(_slot)
	_set_panel(surgery_panel, true)


func open_armory() -> void:
	if armory_list.get_child_count() == 0:
		for entry: WeaponCatalogEntry in weapon_catalog.entries:
			var row := armory_row_scene.instantiate() as ArmoryRow
			armory_list.add_child(row)
			row.show_entry(entry, _weapon_name(entry))
			row.unlock_requested.connect(_on_unlock_requested)
	_refresh_armory()
	armory_info.text = "\"Everything you unlock, I stash in the districts. Check the chests.\""
	_set_panel(armory_panel, true)


func any_panel_open() -> bool:
	return surgery_panel.visible or armory_panel.visible or comic_layer.get_child_count() > 0


## What surgery would install next in `slot_name` (null when maxed or not available yet).
func next_implant(slot_name: String) -> ImplantData:
	return implant_catalog.get_tier(slot_name, GameState.implant_tier(slot_name) + 1)


## Pays and installs the next tier of `slot_name`. Returns false if it can't.
func install(slot_name: String) -> bool:
	var implant := next_implant(slot_name)
	if implant == null or not GameState.spend_ram(implant.cost_mb):
		return false
	var first := GameState.implant_tier(slot_name) == 0
	GameState.set_implant(slot_name, implant.tier)
	GameState.add_stat("implants_installed")
	SaveManager.save_slot()
	purchase_sound.play()
	dialogue.say("Vorn", implant.vorn_line)
	var comic_flag := "implant_comic_" + slot_name
	if first and implant_comics.has(slot_name) and not GameState.has_flag(comic_flag):
		var comic := implant_comics[slot_name].instantiate() as ComicPlayer
		comic_layer.add_child(comic)
		comic.finished.connect(comic.queue_free)
	_select_slot(slot_name)
	return true


## Pays and unlocks a gun for this save's chest pool. Returns false if it can't.
func unlock(entry: WeaponCatalogEntry) -> bool:
	if GameState.is_unlocked(entry.id) or not GameState.spend_crypto(entry.unlock_cost):
		return false
	GameState.unlock_weapon(entry.id)
	SaveManager.save_slot()
	purchase_sound.play()
	_sales += 1
	armory_info.text = "\"%s\"" % patch_lines.pick(_sales - 1) if patch_lines != null else ""
	_refresh_armory()
	return true


func _select_slot(slot_name: String) -> void:
	_slot = slot_name
	for child: Node in slot_rows.get_children():
		var row := child as SurgeryRow
		if row != null:
			row.refresh(implant_catalog)
			row.button_pressed = row.slot_name == slot_name
	var tier := GameState.implant_tier(slot_name)
	var implant := next_implant(slot_name)
	var preview := GameState.implants.duplicate()
	install_button.require_hold = tier == 0
	if not implant_catalog.has_slot(slot_name):
		implant_name.text = slot_name.capitalize()
		implant_info.text = "Vorn is still building this one. (Arrives in M5.)"
		install_button.text = "Unavailable"
		install_button.disabled = true
	elif implant == null:
		var installed := implant_catalog.get_tier(slot_name, tier)
		implant_name.text = installed.display_name
		implant_info.text = "Fully upgraded."
		install_button.text = "Maxed"
		install_button.disabled = true
	else:
		preview[slot_name] = implant.tier
		implant_name.text = implant.display_name
		var warning := "\nIrreversible. This changes Kade for good." if tier == 0 else ""
		implant_info.text = "%s\nCost: %d MB (you have %d MB).%s" % [implant.description, implant.cost_mb, GameState.ram_mb, warning]
		install_button.text = ("Hold to install" if tier == 0 else "Upgrade") + " · %d MB" % implant.cost_mb
		install_button.disabled = GameState.ram_mb < implant.cost_mb
	doll.show_implants(preview)


func _refresh_armory() -> void:
	for child: Node in armory_list.get_children():
		(child as ArmoryRow).refresh()


func _weapon_name(entry: WeaponCatalogEntry) -> String:
	var gun := entry.scene.instantiate() as Weapon
	var display := gun.display_name
	gun.free()
	return display


## Panels pause the game while they're open (this layer keeps running).
func _set_panel(panel: Control, open: bool) -> void:
	panel.visible = open
	get_tree().paused = surgery_panel.visible or armory_panel.visible


func _on_currency_changed(_crypto: int, _ram_mb: int) -> void:
	if surgery_panel.visible:
		_select_slot(_slot)
	if armory_panel.visible:
		_refresh_armory()


# --- Signals connected in lab.tscn ---

func _on_slot_selected(slot_name: String) -> void:
	_select_slot(slot_name)


func _on_install_button_confirmed() -> void:
	install(_slot)


func _on_surgery_close_pressed() -> void:
	_set_panel(surgery_panel, false)


func _on_armory_close_pressed() -> void:
	_set_panel(armory_panel, false)


func _on_quick_start_pressed() -> void:
	EventBus.station_used.emit(&"elevator")


func _on_unlock_requested(entry: WeaponCatalogEntry) -> void:
	unlock(entry)
