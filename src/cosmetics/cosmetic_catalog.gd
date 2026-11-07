class_name CosmeticCatalog
extends Resource
## Every cosmetic (data/cosmetics/catalog.tres). Ownership comes from Monetization (purchases are per account);
## what's equipped is saved on the slot (GameState.equipped, GameState.hidden_decor).

## GameState.equipped keys for the kinds that have one equipped item.
const KIND_KEYS: Dictionary[int, String] = {
	CosmeticData.Kind.OUTFIT: "outfit",
	CosmeticData.Kind.WEAPON_SKIN: "weapon_skin",
	CosmeticData.Kind.EMP_STYLE: "emp_style",
}

@export var items: Array[CosmeticData] = []


func items_of(kind: CosmeticData.Kind) -> Array[CosmeticData]:
	var found: Array[CosmeticData] = []
	for item: CosmeticData in items:
		if item.kind == kind:
			found.append(item)
	return found


func find(item_id: String) -> CosmeticData:
	for item: CosmeticData in items:
		if item.id == item_id:
			return item
	return null


func find_product(product_id: StringName) -> CosmeticData:
	for item: CosmeticData in items:
		if item.product_id == String(product_id):
			return item
	return null


func product_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for item: CosmeticData in items:
		if not item.is_free():
			ids.append(item.product_id)
	return ids


func is_owned(item: CosmeticData) -> bool:
	return item.is_free() or Monetization.owns(StringName(item.product_id))


## The equipped item of a kind with one slot (an owned one; the free default otherwise).
func equipped(kind: CosmeticData.Kind) -> CosmeticData:
	var chosen := find(GameState.equipped.get(KIND_KEYS.get(kind, ""), ""))
	if chosen != null and chosen.kind == kind and is_owned(chosen):
		return chosen
	for item: CosmeticData in items_of(kind):
		if item.is_free():
			return item
	return null


## Equips an owned item (or, for a decoration, shows it). Returns false if it isn't owned.
func equip(item: CosmeticData) -> bool:
	if item == null or not is_owned(item):
		return false
	if item.kind == CosmeticData.Kind.LAB_DECOR:
		GameState.hidden_decor.erase(item.id)
	else:
		GameState.equipped[KIND_KEYS[item.kind]] = item.id
	EventBus.cosmetics_changed.emit()
	return true


## Lab decorations are shown when owned, unless the player hid them.
func decor_visible(item: CosmeticData) -> bool:
	return is_owned(item) and not GameState.hidden_decor.has(item.id)


func hide_decor(item: CosmeticData) -> void:
	if not GameState.hidden_decor.has(item.id):
		GameState.hidden_decor.append(item.id)
	EventBus.cosmetics_changed.emit()
