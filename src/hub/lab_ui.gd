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
## The cosmetics shop (M6): the catalog, one row scene per item, and the lab's Decor node (one hidden child per
## decoration, named after its id).
@export var cosmetic_catalog: CosmeticCatalog
@export var cosmetic_row_scene: PackedScene
@export var decor_root: Node2D

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
@onready var shop_panel: Control = %ShopPanel
@onready var shop_list: Control = %ShopList
@onready var shop_info: Label = %ShopInfo
## NG+: the threat level for the next new run (shown once an ending has unlocked one).
@onready var threat_box: Control = %ThreatBox
@onready var threat_label: Label = %ThreatLabel

var _slot := "heart"
var _sales := 0


## The kind of cosmetic the shop lists.
var shop_kind := CosmeticData.Kind.OUTFIT


func _ready() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.purchase_finished.connect(_on_purchase_finished)
	EventBus.purchases_restored.connect(_on_purchases_restored)
	EventBus.cosmetics_changed.connect(refresh_shop)
	refresh_threat()
	refresh_decor()


# --- Cosmetics shop (GDD §9: looks only) ---

func open_shop() -> void:
	show_shop_kind(shop_kind)
	shop_info.text = "Looks only. Nothing sold here changes the game."
	_set_panel(shop_panel, true)


## Lists the cosmetics of one kind (a cosmetic_row.tscn copy each).
func show_shop_kind(kind: CosmeticData.Kind) -> void:
	shop_kind = kind
	for child: Node in shop_list.get_children():
		shop_list.remove_child(child)
		child.queue_free()
	for item: CosmeticData in cosmetic_catalog.items_of(kind):
		var row := cosmetic_row_scene.instantiate() as CosmeticRow
		shop_list.add_child(row)
		row.show_item(item, cosmetic_catalog)
		row.action_requested.connect(_on_cosmetic_action)


## Buy (through Monetization), equip, or show / hide a decoration.
func use_cosmetic(item: CosmeticData) -> void:
	if not cosmetic_catalog.is_owned(item):
		shop_info.text = "Opening the store..."
		Monetization.purchase(StringName(item.product_id))
	elif item.kind == CosmeticData.Kind.LAB_DECOR and cosmetic_catalog.decor_visible(item):
		cosmetic_catalog.hide_decor(item)
		SaveManager.save_slot()
	else:
		cosmetic_catalog.equip(item)
		SaveManager.save_slot()


func refresh_shop() -> void:
	for child: Node in shop_list.get_children():
		var row := child as CosmeticRow
		if row != null:
			row.refresh()
	refresh_decor()


## Owned decorations stand in the lab unless hidden.
func refresh_decor() -> void:
	if decor_root == null or cosmetic_catalog == null:
		return
	for item: CosmeticData in cosmetic_catalog.items_of(CosmeticData.Kind.LAB_DECOR):
		var node := decor_root.get_node_or_null(NodePath(item.id)) as CanvasItem
		if node != null:
			node.visible = cosmetic_catalog.decor_visible(item)


func _on_cosmetic_action(item: CosmeticData) -> void:
	AudioManager.click()
	use_cosmetic(item)


func _on_purchase_finished(product_id: StringName, success: bool) -> void:
	var item := cosmetic_catalog.find_product(product_id) if cosmetic_catalog != null else null
	if item == null:
		return
	if success:
		purchase_sound.play()
		cosmetic_catalog.equip(item)
		SaveManager.save_slot()
		shop_info.text = "%s is yours." % item.display_name
	else:
		shop_info.text = "The purchase didn't go through."
	refresh_shop()


func _on_purchases_restored() -> void:
	refresh_shop()
	if shop_panel.visible:
		shop_info.text = "Purchases restored."


func _on_shop_button_pressed() -> void:
	AudioManager.click()
	open_shop()


func _on_shop_close_pressed() -> void:
	_set_panel(shop_panel, false)


func _on_restore_pressed() -> void:
	Monetization.restore_purchases()


func _on_tab_outfits_pressed() -> void:
	show_shop_kind(CosmeticData.Kind.OUTFIT)


func _on_tab_skins_pressed() -> void:
	show_shop_kind(CosmeticData.Kind.WEAPON_SKIN)


func _on_tab_lab_pressed() -> void:
	show_shop_kind(CosmeticData.Kind.LAB_DECOR)


func _on_tab_emp_pressed() -> void:
	show_shop_kind(CosmeticData.Kind.EMP_STYLE)


## Shows the threat selector once an ending has unlocked threat level 1.
func refresh_threat() -> void:
	threat_box.visible = GameState.threat_unlocked > 0
	threat_label.text = "THREAT %d" % GameState.threat_level if GameState.threat_level > 0 else "THREAT 0 (normal)"


## Steps the next run's threat level by `step`, within what's unlocked.
func change_threat(step: int) -> void:
	GameState.threat_level = clampi(GameState.threat_level + step, 0, GameState.threat_unlocked)
	SaveManager.save_slot()
	AudioManager.click()
	refresh_threat()


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
	return surgery_panel.visible or armory_panel.visible or shop_panel.visible or comic_layer.get_child_count() > 0


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
	if GameState.is_unlocked(entry.id) or entry.unlock_hint != "" or not GameState.spend_crypto(entry.unlock_cost):
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
		implant_info.text = "Vorn is still building this one."
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
	get_tree().paused = surgery_panel.visible or armory_panel.visible or shop_panel.visible


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


func _on_threat_down_pressed() -> void:
	change_threat(-1)


func _on_threat_up_pressed() -> void:
	change_threat(1)


func _on_quick_start_pressed() -> void:
	EventBus.station_used.emit(&"elevator")


func _on_unlock_requested(entry: WeaponCatalogEntry) -> void:
	unlock(entry)


func _on_settings_button_pressed() -> void:
	AudioManager.click()
	(%SettingsPanel as SettingsPanel).open()
