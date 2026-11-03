class_name WeaponCatalog
extends Resource
## Every gun the chests can hold (data/weapons/weapon_catalog.tres). In M4 only unlocked guns count.

@export var entries: Array[WeaponCatalogEntry] = []


## A random gun of the given rarity, falling back to lower rarities; null if there's none.
func pick(rarity: WeaponCatalogEntry.Rarity) -> PackedScene:
	for level: int in range(rarity, -1, -1):
		var options: Array[WeaponCatalogEntry] = []
		for entry: WeaponCatalogEntry in entries:
			if entry.rarity == level and entry.scene != null:
				options.append(entry)
		if not options.is_empty():
			return options[randi_range(0, options.size() - 1)].scene
	return null
