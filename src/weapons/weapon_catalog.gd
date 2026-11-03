class_name WeaponCatalog
extends Resource
## Every gun the chests can hold (data/weapons/weapon_catalog.tres). Chests only pick guns this save has unlocked
## (GameState.unlocked_weapons: the three free Commons, plus whatever Patch's armory sold).

@export var entries: Array[WeaponCatalogEntry] = []


## The catalog id of a weapon scene (by its file path), or &"" if it isn't listed.
func id_for_scene(scene_path: String) -> StringName:
	for entry: WeaponCatalogEntry in entries:
		if entry.scene != null and entry.scene.resource_path == scene_path:
			return entry.id
	return &""


func scene_for(id: StringName) -> PackedScene:
	for entry: WeaponCatalogEntry in entries:
		if entry.id == id and id != &"":
			return entry.scene
	return null


## A random unlocked gun of the given rarity, falling back to lower rarities; null if there's none.
func pick(rarity: WeaponCatalogEntry.Rarity) -> PackedScene:
	for level: int in range(rarity, -1, -1):
		var options: Array[WeaponCatalogEntry] = []
		for entry: WeaponCatalogEntry in entries:
			if entry.rarity == level and entry.scene != null and GameState.is_unlocked(entry.id):
				options.append(entry)
		if not options.is_empty():
			return options[randi_range(0, options.size() - 1)].scene
	return null
